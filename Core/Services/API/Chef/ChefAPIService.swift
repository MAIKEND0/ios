//
//  ChefAPIService.swift
//  KSR Cranes App
//  Updated with logo upload support + ACL
//

import Foundation
import Combine
import UIKit

final class ChefAPIService: BaseAPIService {
    static let shared = ChefAPIService()

    private override init() {
        super.init()
    }

    // MARK: - Dashboard Stats
    func fetchChefDashboardStats() -> AnyPublisher<ChefDashboardStats, APIError> {
        let endpoint = "/api/app/chef/dashboard/stats"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: ChefDashboardStats.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Customers Management
    
    func fetchCustomers(search: String? = nil, limit: Int? = nil, offset: Int? = nil, includeLogo: Bool = true) -> AnyPublisher<[Customer], APIError> {
        var endpoint = "/api/app/chef/customers"
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
        if includeLogo {
            queryParams.append("include_logo=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [Customer].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func createCustomer(_ customerData: CreateCustomerRequest) -> AnyPublisher<Customer, APIError> {
        let endpoint = "/api/app/chef/customers"
        return makeRequest(endpoint: endpoint, method: "POST", body: customerData)
            .decode(type: Customer.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func fetchCustomer(id: Int) -> AnyPublisher<CustomerDetail, APIError> {
        let endpoint = "/api/app/chef/customers/\(id)"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CustomerDetail.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func updateCustomer(id: Int, data: UpdateCustomerRequest) -> AnyPublisher<Customer, APIError> {
        let endpoint = "/api/app/chef/customers/\(id)"
        return makeRequest(endpoint: endpoint, method: "PUT", body: data)
            .decode(type: Customer.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func deleteCustomer(id: Int) -> AnyPublisher<DeleteCustomerResponse, APIError> {
        let endpoint = "/api/app/chef/customers/\(id)"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteCustomerResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Logo Management
    
    func uploadCustomerLogo(customerId: Int, image: UIImage, fileName: String? = nil) -> AnyPublisher<LogoUploadResponse, APIError> {
        let endpoint = "/api/app/chef/customers/\(customerId)/logo"
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: APIError.unknown)
                .eraseToAnyPublisher()
        }
        
        let actualFileName = fileName ?? "logo_\(Date().timeIntervalSince1970).jpg"
        
        return uploadFile(
            endpoint: endpoint,
            method: "POST",
            fieldName: "logo",
            fileName: actualFileName,
            fileData: imageData,
            mimeType: "image/jpeg",
            additionalFields: Optional<String>.none // Explicitly provide nil with type
        )
        .decode(type: LogoUploadResponse.self, decoder: jsonDecoder())
        .mapError { ($0 as? APIError) ?? .decodingError($0) }
        .eraseToAnyPublisher()
    }
    
    func getPresignedLogoUploadUrl(customerId: Int, fileName: String, contentType: String, fileSize: Int) -> AnyPublisher<PresignedUrlResponse, APIError> {
        let endpoint = "/api/app/chef/customers/\(customerId)/logo/presigned"
        let queryParams = [
            "fileName=\(fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "contentType=\(contentType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "fileSize=\(fileSize)"
        ].joined(separator: "&")
        
        let fullEndpoint = "\(endpoint)?\(queryParams)"
        
        return makeRequest(endpoint: fullEndpoint, method: "GET", body: Optional<String>.none)
            .decode(type: PresignedUrlResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // 🔥 UPDATED: Dodano ACL header dla publicznego dostępu
    func uploadLogoWithPresignedUrl(uploadUrl: String, imageData: Data, contentType: String) -> AnyPublisher<Void, APIError> {
        guard let url = URL(string: uploadUrl) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("max-age=31536000", forHTTPHeaderField: "Cache-Control")
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl") // 🔥 DODANO: ACL header
        request.httpBody = imageData
        
        #if DEBUG
        print("[ChefAPIService] === UPLOAD REQUEST ===")
        print("[ChefAPIService] URL: \(uploadUrl)")
        print("[ChefAPIService] Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("[ChefAPIService]   \(key): \(value)")
        }
        print("[ChefAPIService] Body size: \(imageData.count) bytes")
        print("[ChefAPIService] ================================")
        #endif
        
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<Void, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                #if DEBUG
                print("[ChefAPIService] === UPLOAD RESPONSE ===")
                print("[ChefAPIService] Status: \(httpResponse.statusCode)")
                if !data.isEmpty {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[ChefAPIService] Body: \(responseString)")
                    }
                }
                print("[ChefAPIService] ===================================")
                #endif
                
                if (200...299).contains(httpResponse.statusCode) {
                    return Just(())
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Upload failed with status \(httpResponse.statusCode)"
                    return Fail(error: APIError.serverError(httpResponse.statusCode, errorMessage))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func confirmLogoUpload(customerId: Int, logoKey: String, logoUrl: String) -> AnyPublisher<LogoUploadResponse, APIError> {
        let endpoint = "/api/app/chef/customers/\(customerId)/logo/confirm"
        let confirmData = LogoConfirmRequest(logo_key: logoKey, logo_url: logoUrl)
        
        return makeRequest(endpoint: endpoint, method: "PUT", body: confirmData)
            .decode(type: LogoUploadResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func deleteCustomerLogo(customerId: Int) -> AnyPublisher<DeleteCustomerResponse, APIError> {
        let endpoint = "/api/app/chef/customers/\(customerId)/logo"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteCustomerResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    // Complete logo upload workflow using presigned URL (recommended for large files)
    func uploadCustomerLogoWithPresignedUrl(customerId: Int, image: UIImage, fileName: String? = nil) -> AnyPublisher<LogoUploadResponse, APIError> {
        let actualFileName = fileName ?? "logo_\(Date().timeIntervalSince1970).jpg"
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        let contentType = "image/jpeg"
        let fileSize = imageData.count
        
        #if DEBUG
        print("[ChefAPIService] Starting logo upload for customer \(customerId)")
        print("[ChefAPIService] File: \(actualFileName), Size: \(fileSize) bytes")
        #endif
        
        return getPresignedLogoUploadUrl(
            customerId: customerId,
            fileName: actualFileName,
            contentType: contentType,
            fileSize: fileSize
        )
        .flatMap { [weak self] presignedResponse -> AnyPublisher<LogoUploadResponse, APIError> in
            guard let self = self else {
                return Fail(error: APIError.unknown).eraseToAnyPublisher()
            }
            
            #if DEBUG
            print("[ChefAPIService] Got presigned URL, uploading file...")
            #endif
            
            return self.uploadLogoWithPresignedUrl(
                uploadUrl: presignedResponse.data.upload_url,
                imageData: imageData,
                contentType: contentType
            )
            .flatMap { _ -> AnyPublisher<LogoUploadResponse, APIError> in
                #if DEBUG
                print("[ChefAPIService] Upload successful, confirming...")
                #endif
                
                return self.confirmLogoUpload(
                    customerId: customerId,
                    logoKey: presignedResponse.data.logo_key,
                    logoUrl: presignedResponse.data.logo_url
                )
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Search and Stats (existing methods remain the same)
    
    func searchCustomers(query: String, limit: Int = 20, offset: Int = 0, includeProjects: Bool = false, includeStats: Bool = false) -> AnyPublisher<CustomerSearchResponse, APIError> {
        let endpoint = "/api/app/chef/customers/search"
        let queryParams = [
            "q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "limit=\(limit)",
            "offset=\(offset)",
            "include_projects=\(includeProjects)",
            "include_stats=\(includeStats)"
        ].joined(separator: "&")
        
        let fullEndpoint = "\(endpoint)?\(queryParams)"
        
        return makeRequest(endpoint: fullEndpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CustomerSearchResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func advancedSearchCustomers(_ searchRequest: AdvancedCustomerSearchRequest) -> AnyPublisher<CustomerSearchResponse, APIError> {
        let endpoint = "/api/app/chef/customers/search"
        return makeRequest(endpoint: endpoint, method: "POST", body: searchRequest)
            .decode(type: CustomerSearchResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetchCustomerStats(includeMonthlyGrowth: Bool = false, topCustomersLimit: Int = 10, recentCustomersLimit: Int = 10) -> AnyPublisher<CustomerStats, APIError> {
        let endpoint = "/api/app/chef/customers/stats"
        let queryParams = [
            "include_monthly_growth=\(includeMonthlyGrowth)",
            "top_customers_limit=\(topCustomersLimit)",
            "recent_customers_limit=\(recentCustomersLimit)"
        ].joined(separator: "&")
        
        let fullEndpoint = "\(endpoint)?\(queryParams)"
        
        return makeRequest(endpoint: fullEndpoint, method: "GET", body: Optional<String>.none)
            .decode(type: CustomerStats.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Logo Data Models
// (Struktury już istnieją w projekcie - usunięte duplikaty)

// MARK: - File Upload Extension

extension BaseAPIService {
    func uploadFile<T: Encodable>(
        endpoint: String,
        method: String,
        fieldName: String,
        fileName: String,
        fileData: Data,
        mimeType: String,
        additionalFields: T? = nil
    ) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        applyAuthToken(to: &request)
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add additional fields if provided
        if let additionalFields = additionalFields {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let fieldsData = try encoder.encode(additionalFields)
                if let fieldsDict = try JSONSerialization.jsonObject(with: fieldsData) as? [String: Any] {
                    for (key, value) in fieldsDict {
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                        body.append("\(value)\r\n".data(using: .utf8)!)
                    }
                }
            } catch {
                return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        #if DEBUG
        print("[BaseAPIService] Uploading file: \(method) \(url)")
        print("[BaseAPIService] File size: \(fileData.count) bytes")
        #endif
        
        return session.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, resp -> AnyPublisher<Data, APIError> in
                guard let http = resp as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                #if DEBUG
                print("[BaseAPIService] Upload response status: \(http.statusCode)")
                if let respStr = String(data: data, encoding: .utf8) {
                    print("[BaseAPIService] Upload response: \(respStr.prefix(200))")
                }
                #endif
                
                if (200...299).contains(http.statusCode) {
                    return Just(data)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } else if http.statusCode == 401 {
                    #if DEBUG
                    print("[BaseAPIService] ⚠️ 401 Unauthorized during upload")
                    #endif
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .authenticationFailure, object: nil)
                    }
                    return Fail(error: APIError.serverError(401, "Authentication expired. Please log in again."))
                        .eraseToAnyPublisher()
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    let msg = raw.isEmpty ? "Upload failed with code \(http.statusCode)" : "\(raw.prefix(200))…"
                    return Fail(error: APIError.serverError(http.statusCode, msg))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Convenience method for uploads without additional fields
    func uploadFile(
        endpoint: String,
        method: String,
        fieldName: String,
        fileName: String,
        fileData: Data,
        mimeType: String
    ) -> AnyPublisher<Data, APIError> {
        return uploadFile(
            endpoint: endpoint,
            method: method,
            fieldName: fieldName,
            fileName: fileName,
            fileData: fileData,
            mimeType: mimeType,
            additionalFields: Optional<String>.none
        )
    }
}

// MARK: - Preview Helper

#if DEBUG
extension CustomersViewModel {
    static func preview() -> CustomersViewModel {
        let viewModel = CustomersViewModel()
        viewModel.customers = Customer.mockData
        return viewModel
    }
}
#endif
