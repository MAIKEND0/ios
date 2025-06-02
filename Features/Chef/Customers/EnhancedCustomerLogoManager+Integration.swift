//
//  EnhancedCustomerLogoManager+Integration.swift
//  KSR Cranes App
//
//  Integration between EnhancedCustomerLogoManager and API
//

import Foundation
import SwiftUI
import Combine

// MARK: - Logo Operation Progress Tracking

class LogoOperationTracker: ObservableObject {
    @Published var activeOperations: [Int: LogoOperationProgress] = [:]
    
    struct LogoOperationProgress {
        let customerId: Int
        let operationType: LogoOperationType
        var progress: Double
        var startTime: Date
        var error: LogoOperationError?
        
        enum LogoOperationType {
            case upload
            case delete
        }
    }
    
    func startOperation(customerId: Int, type: LogoOperationProgress.LogoOperationType) {
        activeOperations[customerId] = LogoOperationProgress(
            customerId: customerId,
            operationType: type,
            progress: 0.0,
            startTime: Date()
        )
    }
    
    func updateProgress(customerId: Int, progress: Double) {
        activeOperations[customerId]?.progress = progress
    }
    
    func completeOperation(customerId: Int, error: LogoOperationError? = nil) {
        if let error = error {
            activeOperations[customerId]?.error = error
        } else {
            activeOperations.removeValue(forKey: customerId)
        }
    }
    
    func isOperationActive(customerId: Int) -> Bool {
        return activeOperations[customerId] != nil
    }
    
    func getProgress(customerId: Int) -> Double {
        return activeOperations[customerId]?.progress ?? 0.0
    }
}

// MARK: - Logo Cache Manager

class LogoCacheManager: ObservableObject {
    private var imageCache: NSCache<NSString, UIImage> = NSCache()
    private var urlCache: NSCache<NSString, NSString> = NSCache()
    
    init() {
        imageCache.countLimit = 100 // Limit cache to 100 images
        urlCache.countLimit = 200   // Limit URL cache to 200 entries
    }
    
    func cacheImage(_ image: UIImage, for customerId: Int) {
        let key = NSString(string: "customer_\(customerId)")
        imageCache.setObject(image, forKey: key)
    }
    
    func getCachedImage(for customerId: Int) -> UIImage? {
        let key = NSString(string: "customer_\(customerId)")
        return imageCache.object(forKey: key)
    }
    
    func cacheLogoUrl(_ url: String, for customerId: Int) {
        let key = NSString(string: "customer_\(customerId)_url")
        urlCache.setObject(NSString(string: url), forKey: key)
    }
    
    func getCachedLogoUrl(for customerId: Int) -> String? {
        let key = NSString(string: "customer_\(customerId)_url")
        return urlCache.object(forKey: key) as String?
    }
    
    func removeCachedData(for customerId: Int) {
        let imageKey = NSString(string: "customer_\(customerId)")
        let urlKey = NSString(string: "customer_\(customerId)_url")
        
        imageCache.removeObject(forKey: imageKey)
        urlCache.removeObject(forKey: urlKey)
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
        urlCache.removeAllObjects()
    }
}

// MARK: - Global Logo Management

class GlobalLogoManager: ObservableObject {
    static let shared = GlobalLogoManager()
    
    @Published var operationTracker = LogoOperationTracker()
    @Published var cacheManager = LogoCacheManager()
    
    private init() {}
    
    func uploadLogoForCustomer(_ customerId: Int, image: UIImage, completion: @escaping (Result<String, LogoOperationError>) -> Void) {
        operationTracker.startOperation(customerId: customerId, type: .upload)
        
        let logoManager = EnhancedCustomerLogoManager()
        logoManager.selectedImage = image
        
        logoManager.uploadLogo(for: customerId) { result in
            switch result {
            case .success(let logoUrl):
                self.cacheManager.cacheImage(image, for: customerId)
                self.cacheManager.cacheLogoUrl(logoUrl, for: customerId)
                self.operationTracker.completeOperation(customerId: customerId)
                completion(.success(logoUrl))
                
            case .failure(let error):
                self.operationTracker.completeOperation(customerId: customerId, error: error)
                completion(.failure(error))
                
            case .progress(let progress):
                self.operationTracker.updateProgress(customerId: customerId, progress: progress)
            }
        }
    }
    
    func deleteLogoForCustomer(_ customerId: Int, completion: @escaping (Result<Void, LogoOperationError>) -> Void) {
        operationTracker.startOperation(customerId: customerId, type: .delete)
        
        let logoManager = EnhancedCustomerLogoManager()
        
        logoManager.deleteLogo(for: customerId) { result in
            switch result {
            case .success:
                self.cacheManager.removeCachedData(for: customerId)
                self.operationTracker.completeOperation(customerId: customerId)
                completion(.success(()))
                
            case .failure(let error):
                self.operationTracker.completeOperation(customerId: customerId, error: error)
                completion(.failure(error))
                
            case .progress:
                break // Delete operations don't typically have progress
            }
        }
    }
    
    func isOperationInProgress(for customerId: Int) -> Bool {
        return operationTracker.isOperationActive(customerId: customerId)
    }
    
    func getOperationProgress(for customerId: Int) -> Double {
        return operationTracker.getProgress(customerId: customerId)
    }
}

// MARK: - Logo Optimization Helper

struct LogoOptimizer {
    static func optimizeImageForUpload(_ image: UIImage, maxSize: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        let size = image.size
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage
    }
    
    static func compressImage(_ image: UIImage, maxSizeInBytes: Int = 1024 * 1024) -> Data? {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxSizeInBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}

// MARK: - Usage Examples in Views

/*
// Example usage in CreateCustomerView:

@StateObject private var logoManager = EnhancedCustomerLogoManager()
@StateObject private var globalLogoManager = GlobalLogoManager.shared

// In the upload action:
if let image = logoManager.selectedImage {
    globalLogoManager.uploadLogoForCustomer(customer.customer_id, image: image) { result in
        switch result {
        case .success(let logoUrl):
            // Update UI with new logo URL
            logoManager.logoUrl = logoUrl
        case .failure(let error):
            // Show error to user
            viewModel.showAlert(title: "Upload Failed", message: error.localizedDescription)
        }
    }
}

// Example usage in CustomersListView for showing upload progress:

ForEach(customers) { customer in
    CustomerListCard(customer: customer) {
        // Card action
    }
    .overlay(
        globalLogoManager.isOperationInProgress(for: customer.customer_id) ?
        LogoUploadProgressOverlay(progress: globalLogoManager.getOperationProgress(for: customer.customer_id)) :
        nil
    )
}
*/
