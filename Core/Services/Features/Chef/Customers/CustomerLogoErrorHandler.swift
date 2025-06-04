//
//  CustomerLogoErrorHandler.swift
//  KSR Cranes App
//
//  Enhanced error handling for logo operations
//

import Foundation
import SwiftUI
import Combine

// MARK: - Logo Operation Errors

enum LogoOperationError: LocalizedError {
    case invalidImageFormat
    case imageTooLarge(actualSize: Int, maxSize: Int)
    case networkTimeout
    case insufficientStorage
    case unauthorizedAccess
    case serverUnavailable
    case corruptedImage
    case uploadCancelled
    case s3ServiceError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageFormat:
            return "Invalid image format. Please use JPG, PNG, GIF, WEBP, or SVG."
        case .imageTooLarge(let actualSize, let maxSize):
            let actualMB = Double(actualSize) / (1024 * 1024)
            let maxMB = Double(maxSize) / (1024 * 1024)
            return String(format: "Image is too large (%.1f MB). Maximum size is %.1f MB.", actualMB, maxMB)
        case .networkTimeout:
            return "Upload timed out. Please check your connection and try again."
        case .insufficientStorage:
            return "Server storage is full. Please contact support."
        case .unauthorizedAccess:
            return "You don't have permission to upload logos. Please log in again."
        case .serverUnavailable:
            return "Logo service is temporarily unavailable. Please try again later."
        case .corruptedImage:
            return "The image file appears to be corrupted. Please try a different image."
        case .uploadCancelled:
            return "Upload was cancelled."
        case .s3ServiceError(let message):
            return "Storage service error: \(message)"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidImageFormat:
            return "Try converting your image to JPG or PNG format."
        case .imageTooLarge:
            return "Resize your image or reduce its quality before uploading."
        case .networkTimeout:
            return "Check your internet connection and try uploading again."
        case .insufficientStorage:
            return "Contact your system administrator."
        case .unauthorizedAccess:
            return "Try logging out and logging back in."
        case .serverUnavailable:
            return "Wait a few minutes and try again."
        case .corruptedImage:
            return "Try taking a new photo or use a different image."
        case .uploadCancelled:
            return "Start the upload process again if needed."
        case .s3ServiceError:
            return "This is a temporary issue. Please try again."
        case .unknown:
            return "If the problem persists, contact support."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkTimeout, .serverUnavailable, .s3ServiceError, .unknown:
            return true
        case .invalidImageFormat, .imageTooLarge, .unauthorizedAccess, .corruptedImage, .uploadCancelled, .insufficientStorage:
            return false
        }
    }
}

// MARK: - Logo Operation Result

enum LogoOperationResult {
    case success(logoUrl: String)
    case failure(LogoOperationError)
    case progress(Double) // 0.0 to 1.0
}

// MARK: - Enhanced Logo Manager with Better Error Handling

class EnhancedCustomerLogoManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var logoUrl: String?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: LogoOperationError?
    @Published var uploadSuccess = false
    @Published var retryCount = 0
    
    // Made internal so extensions can access them
    internal let apiService = ChefAPIService.shared
    internal var cancellables = Set<AnyCancellable>()
    internal let maxRetries = 3
    internal let maxImageSize = 5 * 1024 * 1024 // 5MB
    
    // MARK: - Image Validation
    
    private func validateImage(_ image: UIImage) -> LogoOperationError? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return .corruptedImage
        }
        
        if imageData.count > maxImageSize {
            return .imageTooLarge(actualSize: imageData.count, maxSize: maxImageSize)
        }
        
        return nil
    }
    
    // MARK: - Upload with Retry Logic
    
    func uploadLogo(for customerId: Int, completion: @escaping (LogoOperationResult) -> Void) {
        guard let image = selectedImage else {
            completion(.failure(.corruptedImage))
            return
        }
        
        // Validate image first
        if let validationError = validateImage(image) {
            completion(.failure(validationError))
            return
        }
        
        startUpload(for: customerId, image: image, attempt: 1, completion: completion)
    }
    
    private func startUpload(for customerId: Int, image: UIImage, attempt: Int, completion: @escaping (LogoOperationResult) -> Void) {
        isUploading = true
        uploadProgress = 0.0
        lastError = nil
        retryCount = attempt - 1
        
        #if DEBUG
        print("[EnhancedLogoManager] Upload attempt \(attempt) for customer \(customerId)")
        #endif
        
        // Simulate progress updates (in real implementation, track actual upload progress)
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                if let self = self, self.isUploading && self.uploadProgress < 0.9 {
                    self.uploadProgress += 0.05
                    completion(.progress(self.uploadProgress))
                } else {
                    timer.invalidate()
                }
            }
        }
        
        apiService.uploadCustomerLogoWithPresignedUrl(customerId: customerId, image: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    progressTimer.invalidate()
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                    
                    if case .failure(let apiError) = result {
                        let logoError = self?.mapAPIErrorToLogoError(apiError) ?? .unknown(apiError.localizedDescription)
                        self?.lastError = logoError
                        
                        // Retry logic for retryable errors
                        if logoError.isRetryable && attempt < self?.maxRetries ?? 0 {
                            #if DEBUG
                            print("[EnhancedLogoManager] Retrying upload, attempt \(attempt + 1)")
                            #endif
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempt)) {
                                self?.startUpload(for: customerId, image: image, attempt: attempt + 1, completion: completion)
                            }
                        } else {
                            completion(.failure(logoError))
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    progressTimer.invalidate()
                    self?.uploadProgress = 1.0
                    self?.logoUrl = response.data.logo_url
                    self?.uploadSuccess = true
                    self?.selectedImage = nil
                    self?.retryCount = 0
                    
                    completion(.success(logoUrl: response.data.logo_url))
                    
                    #if DEBUG
                    print("[EnhancedLogoManager] Upload successful: \(response.data.logo_url)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Delete with Error Handling
    
    func deleteLogo(for customerId: Int, completion: @escaping (LogoOperationResult) -> Void) {
        isUploading = true
        lastError = nil
        
        apiService.deleteCustomerLogo(customerId: customerId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isUploading = false
                    
                    if case .failure(let apiError) = result {
                        let logoError = self?.mapAPIErrorToLogoError(apiError) ?? .unknown(apiError.localizedDescription)
                        self?.lastError = logoError
                        completion(.failure(logoError))
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.logoUrl = nil
                    self?.selectedImage = nil
                    completion(.success(logoUrl: ""))
                    
                    #if DEBUG
                    print("[EnhancedLogoManager] Logo deleted successfully")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Error Mapping
    
    internal func mapAPIErrorToLogoError(_ apiError: BaseAPIService.APIError) -> LogoOperationError {
        switch apiError {
        case .networkError(let error):
            if (error as NSError).code == NSURLErrorTimedOut {
                return .networkTimeout
            }
            return .unknown(error.localizedDescription)
            
        case .serverError(let code, let message):
            switch code {
            case 401:
                return .unauthorizedAccess
            case 413:
                return .imageTooLarge(actualSize: maxImageSize + 1, maxSize: maxImageSize)
            case 503:
                return .serverUnavailable
            case 507:
                return .insufficientStorage
            default:
                if message.contains("S3") || message.contains("storage") {
                    return .s3ServiceError(message)
                }
                return .unknown(message)
            }
            
        case .invalidURL, .invalidResponse:
            return .unknown("Invalid request configuration")
            
        case .decodingError:
            return .unknown("Invalid server response")
            
        case .unknown:
            return .unknown("Unknown error occurred")
        }
    }
    
    // MARK: - Utility Methods
    
    func reset() {
        selectedImage = nil
        logoUrl = nil
        lastError = nil
        uploadSuccess = false
        isUploading = false
        uploadProgress = 0.0
        retryCount = 0
        cancellables.removeAll()
    }
    
    func canRetry() -> Bool {
        guard let error = lastError else { return false }
        return error.isRetryable && retryCount < maxRetries
    }
    
    func getProgressPercentage() -> Int {
        return Int(uploadProgress * 100)
    }
}

// MARK: - Logo Error Alert View

struct LogoErrorAlertView: View {
    let error: LogoOperationError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Error Details
            VStack(spacing: 8) {
                Text("Upload Failed")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
                
                if error.isRetryable, let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.ksrPrimary)
                    .cornerRadius(8)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

// MARK: - Upload Progress View

struct LogoUploadProgressView: View {
    let progress: Double
    let retryCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .ksrPrimary))
            
            HStack {
                Text("Uploading logo...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            if retryCount > 0 {
                Text("Retry attempt \(retryCount)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct LogoErrorAlertView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LogoErrorAlertView(
                error: .imageTooLarge(actualSize: 6291456, maxSize: 5242880),
                onRetry: { },
                onDismiss: { }
            )
            
            LogoErrorAlertView(
                error: .networkTimeout,
                onRetry: { },
                onDismiss: { }
            )
            
            LogoUploadProgressView(progress: 0.65, retryCount: 1)
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
