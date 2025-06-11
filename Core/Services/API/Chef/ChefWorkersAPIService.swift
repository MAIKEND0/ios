//
//  ChefWorkersAPIService.swift
//  KSR Cranes App
//  Workers management for Chef role
//

import Foundation
import Combine
import UIKit

final class ChefWorkersAPIService: BaseAPIService {
    static let shared = ChefWorkersAPIService()

    private override init() {
        super.init()
    }

    // MARK: - Workers List Management
    
    func fetchWorkers(
        search: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        includeProfileImage: Bool = true,
        includeStats: Bool = true,
        includeCertificates: Bool = false
    ) -> AnyPublisher<[WorkerForChef], APIError> {
        var endpoint = "/api/app/chef/workers"
        var queryParams: [String] = []
        
        if let search = search, !search.isEmpty {
            queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        if let limit = limit {
            queryParams.append("limit=\(limit)")
        }
        if let offset = offset {
            queryParams.append("offset=\(offset)")
        }
        if includeProfileImage {
            queryParams.append("include_profile_image=true")
        }
        if includeStats {
            queryParams.append("include_stats=true")
        }
        if includeCertificates {
            queryParams.append("include_certificates=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkerForChef].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchWorkerDetail(id: Int) -> AnyPublisher<WorkerDetailForChef, APIError> {
        let endpoint = "/api/app/chef/workers/\(id)"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerDetailForChef.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker CRUD Operations
    
    func createWorker(_ workerData: CreateWorkerRequest) -> AnyPublisher<WorkerForChef, APIError> {
        let endpoint = "/api/app/chef/workers"
        return makeRequestWithRetry(endpoint: endpoint, method: "POST", body: workerData)
            .decode(type: WorkerForChef.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func updateWorker(id: Int, data: UpdateWorkerRequest) -> AnyPublisher<WorkerForChef, APIError> {
        let endpoint = "/api/app/chef/workers/\(id)"
        return makeRequestWithRetry(endpoint: endpoint, method: "PUT", body: data)
            .decode(type: WorkerForChef.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func deleteWorker(id: Int) -> AnyPublisher<DeleteWorkerResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(id)"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteWorkerResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Profile Image Management
    
    func uploadWorkerProfileImage(
        workerId: Int, 
        image: UIImage, 
        fileName: String? = nil
    ) -> AnyPublisher<WorkerProfileImageUploadResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/profile-image"
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: APIError.unknown)
                .eraseToAnyPublisher()
        }
        
        let actualFileName = fileName ?? "profile_\(Date().timeIntervalSince1970).jpg"
        
        return uploadFile(
            endpoint: endpoint,
            method: "POST",
            fieldName: "profile_image",
            fileName: actualFileName,
            fileData: imageData,
            mimeType: "image/jpeg"
        )
        .decode(type: WorkerProfileImageUploadResponse.self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
    }
    
    func deleteWorkerProfileImage(workerId: Int) -> AnyPublisher<DeleteWorkerResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/profile-image"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteWorkerResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Rates Management
    
    func fetchWorkerRates(workerId: Int) -> AnyPublisher<[WorkerRate], APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/rates"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkerRate].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func updateWorkerRates(workerId: Int, rates: [UpdateWorkerRateRequest]) -> AnyPublisher<[WorkerRate], APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/rates"
        return makeRequestWithRetry(endpoint: endpoint, method: "PUT", body: rates)
            .decode(type: [WorkerRate].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Stats and Performance
    
    func fetchWorkerStats(workerId: Int, fromDate: Date? = nil, toDate: Date? = nil) -> AnyPublisher<WorkerStatsForChef, APIError> {
        var endpoint = "/api/app/chef/workers/\(workerId)/stats"
        var queryParams: [String] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        if let fromDate = fromDate {
            queryParams.append("from_date=\(dateFormatter.string(from: fromDate))")
        }
        if let toDate = toDate {
            queryParams.append("to_date=\(dateFormatter.string(from: toDate))")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerStatsForChef.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchWorkersStats(includeInactive: Bool = false) -> AnyPublisher<WorkersOverallStats, APIError> {
        var endpoint = "/api/app/chef/workers/stats"
        if includeInactive {
            endpoint += "?include_inactive=true"
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkersOverallStats.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Search and Filters
    
    func searchWorkers(query: String, limit: Int = 20, offset: Int = 0) -> AnyPublisher<WorkerSearchResponse, APIError> {
        let endpoint = "/api/app/chef/workers/search"
        let queryParams = [
            "q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "limit=\(limit)",
            "offset=\(offset)"
        ].joined(separator: "&")
        
        let fullEndpoint = "\(endpoint)?\(queryParams)"
        
        return makeRequest(endpoint: fullEndpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerSearchResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func advancedSearchWorkers(_ searchRequest: AdvancedWorkerSearchRequest) -> AnyPublisher<WorkerSearchResponse, APIError> {
        let endpoint = "/api/app/chef/workers/search"
        return makeRequest(endpoint: endpoint, method: "POST", body: searchRequest)
            .decode(type: WorkerSearchResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Status Management
    
    func updateWorkerStatus(workerId: Int, status: WorkerStatus) -> AnyPublisher<WorkerForChef, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/status"
        let statusData = UpdateWorkerStatusRequest(status: status.rawValue)
        
        return makeRequest(endpoint: endpoint, method: "PUT", body: statusData)
            .decode(type: WorkerForChef.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Assignments
    
    func fetchWorkerAssignments(workerId: Int, includeCompleted: Bool = false) -> AnyPublisher<[WorkerAssignment], APIError> {
        var endpoint = "/api/app/chef/workers/\(workerId)/assignments"
        if includeCompleted {
            endpoint += "?include_completed=true"
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkerAssignment].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Debug helpers

#if DEBUG
extension ChefWorkersAPIService {
    func testWorkerCreation() {
        let testWorker = CreateWorkerRequest(
            name: "Test Worker",
            email: "test@example.com",
            phone: "+45 12345678",
            address: "Test Address",
            hourly_rate: 350.0,
            employment_type: "fuld_tid",
            role: "arbejder",
            status: "aktiv"
        )
        
        _ = createWorker(testWorker)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Test worker creation finished")
                    case .failure(let error):
                        print("❌ Test worker creation failed: \(error)")
                    }
                },
                receiveValue: { worker in
                    print("✅ Test worker created: \(worker.name)")
                }
            )
    }
}
#endif