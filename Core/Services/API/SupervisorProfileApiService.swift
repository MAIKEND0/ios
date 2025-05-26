//
//  SupervisorProfileAPIService.swift
//  KSR Cranes App
//
//  Created on 24/05/2025.
//

import Foundation
import Combine
import UIKit

final class SupervisorProfileAPIService: BaseAPIService {
    static let shared = SupervisorProfileAPIService()

    private override init() {
        super.init()
    }

    // MARK: - Profile Avatar Methods

    struct AvatarUploadResponse: Codable {
        let success: Bool
        let message: String
        let data: AvatarData?

        struct AvatarData: Codable {
            let supervisorId: Int
            let name: String
            let profilePictureUrl: String?

            private enum CodingKeys: String, CodingKey {
                case supervisorId
                case name
                case profilePictureUrl
            }
        }
    }

    struct ProfilePictureResponse: Codable {
        let success: Bool
        let data: AvatarData

        struct AvatarData: Codable {
            let supervisorId: Int
            let name: String
            let profilePictureUrl: String?

            private enum CodingKeys: String, CodingKey {
                case supervisorId
                case name
                case profilePictureUrl
            }
        }
    }

    struct AvatarDeleteResponse: Codable {
        let success: Bool
        let message: String
    }

    /// Upload profile picture for supervisor
    func uploadProfilePicture(supervisorId: String, image: UIImage) -> AnyPublisher<AvatarUploadResponse, APIError> {
        guard let url = URL(string: baseURL + "/api/app/supervisor/profile/\(supervisorId)/avatar") else {
            return Fail(outputType: AvatarUploadResponse.self, failure: APIError.invalidURL)
                .eraseToAnyPublisher()
        }

        // Resize image if too large
        let resizedImage = resizeImageIfNeeded(image: image, maxWidth: 800, maxHeight: 800)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            return Fail(outputType: AvatarUploadResponse.self, failure: APIError.decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])))
                .eraseToAnyPublisher()
        }

        // Check file size (max 5MB)
        let maxSize = 5 * 1024 * 1024 // 5MB
        if imageData.count > maxSize {
            return Fail(outputType: AvatarUploadResponse.self, failure: APIError.decodingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image too large. Maximum size is 5MB."])))
                .eraseToAnyPublisher()
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        applyAuthToken(to: &request)

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        #if DEBUG
        print("[SupervisorProfileAPIService] Uploading profile picture for supervisor \(supervisorId), size: \(imageData.count) bytes")
        #endif

        return session.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<AvatarUploadResponse, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(outputType: AvatarUploadResponse.self, failure: APIError.invalidResponse)
                        .eraseToAnyPublisher()
                }

                #if DEBUG
                print("[SupervisorProfileAPIService] Profile picture upload status: \(httpResponse.statusCode)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("[SupervisorProfileAPIService] Response: \(responseStr)")
                }
                #endif

                if (200...299).contains(httpResponse.statusCode) {
                    return Just(data)
                        .decode(type: AvatarUploadResponse.self, decoder: self.jsonDecoder())
                        .mapError { APIError.decodingError($0) }
                        .eraseToAnyPublisher()
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return Fail(outputType: AvatarUploadResponse.self, failure: APIError.serverError(httpResponse.statusCode, errorMessage))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    /// Get current profile picture URL
    func getProfilePicture(supervisorId: String) -> AnyPublisher<ProfilePictureResponse, APIError> {
        let endpoint = "/api/app/supervisor/profile/\(supervisorId)/avatar?cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ProfilePictureResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    /// Delete profile picture
    func deleteProfilePicture(supervisorId: String) -> AnyPublisher<AvatarDeleteResponse, APIError> {
        let endpoint = "/api/app/supervisor/profile/\(supervisorId)/avatar"
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
