//
//  WorkerDocumentAPIService.swift
//  KSR Cranes App
//  API service for worker document management
//

import Foundation
import Combine
import UIKit

final class WorkerDocumentAPIService: BaseAPIService {
    static let shared = WorkerDocumentAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Document List Management
    
    func fetchWorkerDocuments(
        workerId: Int,
        category: DocumentCategory? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) -> AnyPublisher<WorkerDocumentsResponse, APIError> {
        var endpoint = "/api/app/chef/workers/\(workerId)/documents"
        var queryParams: [String] = []
        
        if let category = category {
            queryParams.append("category=\(category.rawValue)")
        }
        if let limit = limit {
            queryParams.append("limit=\(limit)")
        }
        if let offset = offset {
            queryParams.append("offset=\(offset)")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: WorkerDocumentsResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchWorkerDocumentStats(workerId: Int) -> AnyPublisher<WorkerDocumentStats, APIError> {
        // Use the main documents endpoint which returns both documents and stats
        let endpoint = "/api/app/chef/workers/\(workerId)/documents"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                // Debug: Print raw JSON
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Raw JSON Response: \(jsonString)")
                }
                return data
            }
            .decode(type: WorkerDocumentStats.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Document CRUD Operations
    
    func uploadWorkerDocument(
        workerId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        uploadRequest: UploadWorkerDocumentRequest
    ) -> AnyPublisher<UploadWorkerDocumentResponse, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/documents"
        
        return uploadFileWithFormData(
            endpoint: endpoint,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            category: uploadRequest.category
        )
        .decode(type: UploadWorkerDocumentResponse.self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
    }
    
    func updateWorkerDocument(
        workerId: Int,
        documentId: String,
        updateRequest: UpdateWorkerDocumentRequest
    ) -> AnyPublisher<WorkerDocument, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/documents"
        
        // Create request body that includes the document key
        let requestBody = [
            "fromKey": documentId,
            "newCategory": updateRequest.category
        ].compactMapValues { $0 }
        
        return makeRequestWithRetry(endpoint: endpoint, method: "PATCH", body: requestBody)
            .decode(type: WorkerDocument.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func deleteWorkerDocument(workerId: Int, documentId: String) -> AnyPublisher<DeleteWorkerDocumentResponse, APIError> {
        // Properly encode the document key as a query parameter
        guard let encodedKey = documentId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "/api/app/chef/workers/\(workerId)/documents?key=\(encodedKey)"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteWorkerDocumentResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Document Access
    
    func getDocumentDownloadURL(workerId: Int, documentId: String) -> AnyPublisher<String, APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/documents/\(documentId)/download"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .tryMap { data in
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let downloadUrl = json["download_url"] as? String {
                    return downloadUrl
                } else {
                    throw APIError.decodingError(NSError(domain: "DocumentAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
                }
            }
            .mapError { ($0 as? APIError) ?? .unknown }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Bulk Operations
    
    func deleteMultipleDocuments(workerId: Int, documentIds: [String]) -> AnyPublisher<[DeleteWorkerDocumentResponse], APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/documents/bulk-delete"
        let request = ["document_ids": documentIds]
        
        return makeRequest(endpoint: endpoint, method: "POST", body: request)
            .decode(type: [DeleteWorkerDocumentResponse].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func moveDocumentsToCategory(
        workerId: Int,
        documentIds: [String],
        newCategory: DocumentCategory
    ) -> AnyPublisher<[WorkerDocument], APIError> {
        let endpoint = "/api/app/chef/workers/\(workerId)/documents/bulk-move"
        let request = BulkMoveRequest(documentIds: documentIds, newCategory: newCategory.rawValue)
        
        return makeRequest(endpoint: endpoint, method: "PATCH", body: request)
            .decode(type: [WorkerDocument].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - File Upload Helper
    
    private func uploadFileWithFormData(
        endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        category: String
    ) -> AnyPublisher<Data, APIError> {
        
        guard let baseURL = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add category as form field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append(category.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Apply authentication
        request = addAuthToken(to: request)
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { APIError.networkError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Debug helpers

#if DEBUG
extension WorkerDocumentAPIService {
    func testDocumentUpload(workerId: Int) {
        // Create test document data
        let testContent = "This is a test document for worker \(workerId)"
        guard let testData = testContent.data(using: .utf8) else { return }
        
        let uploadRequest = UploadWorkerDocumentRequest(
            category: .general,
            description: "Test document upload",
            tags: ["test", "api"]
        )
        
        _ = uploadWorkerDocument(
            workerId: workerId,
            fileData: testData,
            fileName: "test_document.txt",
            mimeType: "text/plain",
            uploadRequest: uploadRequest
        )
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("✅ Test document upload finished")
                case .failure(let error):
                    print("❌ Test document upload failed: \(error)")
                }
            },
            receiveValue: { response in
                print("✅ Test document uploaded: \(response.success)")
            }
        )
    }
}
#endif