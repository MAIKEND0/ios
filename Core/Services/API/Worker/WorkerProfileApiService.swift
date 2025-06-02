// Core/Services/API/WorkerProfileAPIService.swift
import Foundation
import Combine
import UIKit

final class WorkerProfileAPIService: BaseAPIService {
    static let shared = WorkerProfileAPIService()

    private override init() {
        super.init()
    }

    // MARK: - Profile Data Methods

    func fetchWorkerBasicData(employeeId: String) -> AnyPublisher<WorkerBasicData, APIError> {
        let basicData = WorkerBasicData(
            employeeId: Int(employeeId) ?? 0,
            name: AuthService.shared.getEmployeeName() ?? "Unknown",
            email: "worker@ksrcranes.dk",
            role: AuthService.shared.getEmployeeRole() ?? "arbejder"
        )
        
        return Just(basicData)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }

    func updateWorkerContactInfo(employeeId: String, contactData: WorkerContactUpdate) -> AnyPublisher<BasicResponse, APIError> {
        let response = BasicResponse(success: true, message: "Contact updated successfully")
        return Just(response)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Stats Methods

    func calculateWorkerStats(workEntries: [WorkerAPIService.WorkHourEntry]) -> WorkerStats {
        let now = Date()
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
        
        let thisWeekEntries = workEntries.filter { $0.work_date >= startOfWeek }
        let currentWeekHours = thisWeekEntries.reduce(0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let hours = end.timeIntervalSince(start) / 3600
            let pause = Double(entry.pause_minutes ?? 0) / 60
            return sum + max(0, hours - pause)
        }
        
        let thisMonthEntries = workEntries.filter { $0.work_date >= startOfMonth }
        let currentMonthHours = thisMonthEntries.reduce(0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let hours = end.timeIntervalSince(start) / 3600
            let pause = Double(entry.pause_minutes ?? 0) / 60
            return sum + max(0, hours - pause)
        }
        
        let pending = workEntries.filter { $0.confirmation_status == "pending" }.count
        let approved = workEntries.filter { $0.confirmation_status == "confirmed" }.count
        let rejected = workEntries.filter { $0.confirmation_status == "rejected" }.count
        let total = max(1, pending + approved + rejected)
        
        return WorkerStats(
            currentWeekHours: currentWeekHours,
            currentMonthHours: currentMonthHours,
            pendingEntries: pending,
            approvedEntries: approved,
            rejectedEntries: rejected,
            approvalRate: Double(approved) / Double(total)
        )
    }

    // MARK: - Profile Picture Methods

    func uploadWorkerProfilePicture(employeeId: String, image: UIImage) -> AnyPublisher<AvatarUploadResponse, APIError> {
        guard let url = URL(string: baseURL + "/api/app/worker/profile/\(employeeId)/avatar") else {
            return Fail(outputType: AvatarUploadResponse.self, failure: APIError.invalidURL)
                .eraseToAnyPublisher()
        }

        let resizedImage = resizeImageIfNeeded(image: image, maxWidth: 800, maxHeight: 800)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            return Fail(outputType: AvatarUploadResponse.self, failure: APIError.decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])))
                .eraseToAnyPublisher()
        }

        let maxSize = 5 * 1024 * 1024 // 5MB
        if imageData.count > maxSize {
            return Fail(outputType: AvatarUploadResponse.self, failure: APIError.decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image too large. Maximum size is 5MB."])))
                .eraseToAnyPublisher()
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        refreshTokenFromKeychain()
        applyAuthToken(to: &request)
        
        #if DEBUG
        print("[WorkerProfileAPIService] 🔍 DEBUG INFO:")
        print("- URL: \(url.absoluteString)")
        print("- Method: POST")
        print("- Auth token exists: \(authToken != nil)")
        print("- Auth token preview: \(authToken?.prefix(30) ?? "nil")")
        print("- Employee ID: \(employeeId)")
        print("- Content-Type: multipart/form-data; boundary=\(boundary)")
        if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
            print("- Authorization header: \(authHeader.prefix(50))...")
        } else {
            print("- Authorization header: MISSING!")
        }
        #endif

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        #if DEBUG
        print("[WorkerProfileAPIService] Uploading profile picture for worker \(employeeId), size: \(imageData.count) bytes")
        #endif

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                #if DEBUG
                print("[WorkerProfileAPIService] Profile picture upload status: \(httpResponse.statusCode)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("[WorkerProfileAPIService] Response: \(responseStr.prefix(500))")
                }
                #endif

                if (200...299).contains(httpResponse.statusCode) {
                    return data
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(httpResponse.statusCode, errorMessage)
                }
            }
            .decode(type: AvatarUploadResponse.self, decoder: jsonDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }

    func getWorkerProfilePicture(employeeId: String) -> AnyPublisher<ProfilePictureResponse, APIError> {
        let endpoint = "/api/app/worker/profile/\(employeeId)/avatar?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ProfilePictureResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func deleteWorkerProfilePicture(employeeId: String) -> AnyPublisher<AvatarDeleteResponse, APIError> {
        let endpoint = "/api/app/worker/profile/\(employeeId)/avatar"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: AvatarDeleteResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Helper Methods

    private func resizeImageIfNeeded(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let size = image.size
        if size.width <= maxWidth && size.height <= maxHeight {
            return image
        }
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image
    }
}

// MARK: - Response Models

struct AvatarUploadResponse: Codable {
    let success: Bool
    let message: String
    let data: AvatarData?

    struct AvatarData: Codable {
        let workerId: Int
        let name: String
        let profilePictureUrl: String?

        private enum CodingKeys: String, CodingKey {
            case workerId
            case name
            case profilePictureUrl
        }
    }
}

struct ProfilePictureResponse: Codable {
    let success: Bool
    let data: AvatarData

    struct AvatarData: Codable {
        let workerId: Int
        let name: String
        let profilePictureUrl: String?

        private enum CodingKeys: String, CodingKey {
            case workerId
            case name
            case profilePictureUrl
        }
    }
}

struct AvatarDeleteResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Minimal Models

struct WorkerBasicData: Codable {
    let employeeId: Int
    let name: String
    let email: String
    let role: String
    var address: String?
    var phoneNumber: String?
    var emergencyContact: String?
    var profilePictureUrl: String?
    var isActivated: Bool = true
}

struct WorkerStats: Codable {
    let currentWeekHours: Double
    let currentMonthHours: Double
    let pendingEntries: Int
    let approvedEntries: Int
    let rejectedEntries: Int
    let approvalRate: Double
    
    var efficiencyPercentage: Int {
        return min(100, max(0, Int(approvalRate * 100)))
    }
    
    var weeklyHoursFormatted: String {
        return String(format: "%.1f", currentWeekHours)
    }
    
    var monthlyHoursFormatted: String {
        return String(format: "%.1f", currentMonthHours)
    }
}

struct WorkerContactUpdate: Codable {
    let address: String?
    let phoneNumber: String?
    let emergencyContact: String?
}

struct BasicResponse: Codable {
    let success: Bool
    let message: String
}
