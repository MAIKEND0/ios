//
//  WorkerDocumentModels.swift
//  KSR Cranes App
//  Data models for worker document management
//

import Foundation
import SwiftUI

// MARK: - Dynamic Coding Key for flexible JSON parsing

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Document Category Enum

enum DocumentCategory: String, CaseIterable, Codable {
    case contracts = "contracts"
    case certificates = "certificates"
    case licenses = "licenses"
    case reports = "reports"
    case photos = "photos"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .contracts: return "Contracts"
        case .certificates: return "Certificates"
        case .licenses: return "Licenses"
        case .reports: return "Reports"
        case .photos: return "Photos"
        case .general: return "General"
        }
    }
    
    var systemImage: String {
        switch self {
        case .contracts: return "doc.text.fill"
        case .certificates: return "rosette"
        case .licenses: return "checkmark.seal.fill"
        case .reports: return "chart.bar.doc.horizontal.fill"
        case .photos: return "photo.fill"
        case .general: return "folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .contracts: return .blue
        case .certificates: return .green
        case .licenses: return .orange
        case .reports: return .purple
        case .photos: return .pink
        case .general: return .gray
        }
    }
}

// MARK: - Worker Document Model

struct WorkerDocument: Codable, Identifiable {
    let key: String
    let name: String
    let lastModified: Date?
    let size: Int64?
    let url: String
    let category: String
    let `extension`: String
    let isFolder: Bool
    
    // Custom date decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decode(String.self, forKey: .key)
        name = try container.decode(String.self, forKey: .name)
        size = try container.decodeIfPresent(Int64.self, forKey: .size)
        url = try container.decode(String.self, forKey: .url)
        category = try container.decode(String.self, forKey: .category)
        `extension` = try container.decode(String.self, forKey: .extension)
        isFolder = try container.decode(Bool.self, forKey: .isFolder)
        
        // Parse date from ISO string
        if let lastModifiedString = try container.decodeIfPresent(String.self, forKey: .lastModified) {
            let formatter = ISO8601DateFormatter()
            lastModified = formatter.date(from: lastModifiedString)
        } else {
            lastModified = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case key, name, lastModified, size, url, category, `extension`, isFolder
    }
    
    // Computed properties for backwards compatibility
    var id: String { key }
    var fileName: String { name }
    var originalFileName: String { name }
    var fileSize: Int64 { size ?? 0 }
    var documentUrl: String { url }
    var uploadedAt: Date { lastModified ?? Date() }
    var categoryEnum: DocumentCategory? { 
        // First try to get category from folder structure
        // Format: documents/{workerId}/{category}/{fileName}
        let pathParts = key.split(separator: "/")
        if pathParts.count >= 3 {
            let folderCategory = String(pathParts[2])
            if let validCategory = DocumentCategory(rawValue: folderCategory) {
                return validCategory
            }
        }
        
        // Fallback to server-provided category
        // Handle server inconsistency - map "documents" to "general"
        let normalizedCategory = category == "documents" ? "general" : category
        return DocumentCategory(rawValue: normalizedCategory) 
    }
    
    var fileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var fileExtension: String {
        return `extension`.uppercased()
    }
    
    var isImage: Bool {
        let imageExtensions = ["JPG", "JPEG", "PNG", "GIF", "WEBP", "HEIC"]
        return imageExtensions.contains(fileExtension)
    }
    
    var isPDF: Bool {
        return fileExtension == "PDF"
    }
    
    var fileTypeIcon: String {
        let ext = fileExtension.uppercased()
        switch ext {
        case "PDF":
            return "doc.text.fill"
        case "DOC", "DOCX":
            return "doc.text"
        case "XLS", "XLSX":
            return "tablecells"
        case "PPT", "PPTX":
            return "rectangle.on.rectangle"
        case "TXT":
            return "doc.plaintext"
        case "ZIP", "RAR", "7Z":
            return "archivebox.fill"
        case "JPG", "JPEG", "PNG", "GIF", "WEBP", "HEIC":
            return "photo.fill"
        case "MP4", "MOV", "AVI":
            return "video.fill"
        case "MP3", "WAV", "M4A":
            return "waveform"
        case "JS", "TS", "HTML", "CSS", "JSON":
            return "chevron.left.forwardslash.chevron.right"
        case "SWIFT":
            return "swift"
        default:
            return "doc.fill"
        }
    }
    
    var fileTypeIconColor: Color {
        let ext = fileExtension.uppercased()
        switch ext {
        case "PDF":
            return .red
        case "DOC", "DOCX":
            return .blue
        case "XLS", "XLSX":
            return .green
        case "PPT", "PPTX":
            return .orange
        case "JPG", "JPEG", "PNG", "GIF", "WEBP", "HEIC":
            return .pink
        case "JS", "TS", "HTML", "CSS", "JSON", "SWIFT":
            return .yellow
        case "ZIP", "RAR", "7Z":
            return .brown
        case "MP4", "MOV", "AVI":
            return .purple
        case "MP3", "WAV", "M4A":
            return .cyan
        default:
            return .gray
        }
    }
    
    var uploadedAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: uploadedAt)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: uploadedAt, relativeTo: Date())
    }
}

// MARK: - Document Upload Request

struct UploadWorkerDocumentRequest: Codable {
    let category: String
    let description: String?
    let tags: [String]?
    
    init(category: DocumentCategory, description: String? = nil, tags: [String]? = nil) {
        self.category = category.rawValue
        self.description = description
        self.tags = tags
    }
}

// MARK: - Document Update Request

struct UpdateWorkerDocumentRequest: Codable {
    let category: String?
    let description: String?
    let tags: [String]?
    
    init(category: DocumentCategory? = nil, description: String? = nil, tags: [String]? = nil) {
        self.category = category?.rawValue
        self.description = description
        self.tags = tags
    }
}

// MARK: - Bulk Operations Request

struct BulkMoveRequest: Codable {
    let documentIds: [String]
    let newCategory: String
    
    enum CodingKeys: String, CodingKey {
        case documentIds = "document_ids"
        case newCategory = "new_category"
    }
}

// MARK: - Document Response Models

struct WorkerDocumentsResponse: Codable {
    let documents: [WorkerDocument]
    let totalCount: Int
    let categories: [String: Int] // Server returns object, not array
    
    // Computed property for backwards compatibility
    var categoryCounts: [DocumentCategoryCount] {
        return categories.map { DocumentCategoryCount(category: $0.key, count: $0.value) }
    }
    
    enum CodingKeys: String, CodingKey {
        case documents
        case totalCount = "total_count"
        case categories
    }
}

struct DocumentCategoryCount: Codable {
    let category: String
    let count: Int
    
    var categoryEnum: DocumentCategory? {
        return DocumentCategory(rawValue: category)
    }
    
    var displayName: String {
        return categoryEnum?.displayName ?? category.capitalized
    }
}

struct UploadWorkerDocumentResponse: Codable {
    let success: Bool
    let message: String
    let uploaded: [UploadedDocumentInfo]
    let workerId: Int
    
    enum CodingKeys: String, CodingKey {
        case success, message, uploaded
        case workerId = "worker_id"
    }
}

struct UploadedDocumentInfo: Codable {
    let name: String
    let key: String
    let category: String
    let size: Int
    let contentType: String
}

struct DeleteWorkerDocumentResponse: Codable {
    let success: Bool
    let message: String
    let documentId: String?
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case documentId = "document_id"
    }
}

// MARK: - Document Statistics

struct WorkerDocumentStats: Codable {
    let workerId: Int
    let workerName: String
    let documents: [WorkerDocument]
    let categories: [String: Int] // Server returns object, not array
    let totalCount: Int
    
    // Custom decoder to handle conflicting "documents" field in categories
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        workerId = try container.decode(Int.self, forKey: .workerId)
        workerName = try container.decode(String.self, forKey: .workerName)
        documents = try container.decode([WorkerDocument].self, forKey: .documents)
        totalCount = try container.decode(Int.self, forKey: .totalCount)
        
        // Handle categories - server returns arrays of documents, we need counts
        do {
            categories = try container.decode([String: Int].self, forKey: .categories)
        } catch {
            // Server returns arrays of documents, convert to counts
            print("[DEBUG] Categories decoding failed, parsing arrays to counts: \(error)")
            let categoriesContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .categories)
            var categoriesDict: [String: Int] = [:]
            
            for key in categoriesContainer.allKeys {
                // Try to decode as array and count the items
                if let documentsArray = try? categoriesContainer.decode([WorkerDocument].self, forKey: key) {
                    categoriesDict[key.stringValue] = documentsArray.count
                } else if let count = try? categoriesContainer.decode(Int.self, forKey: key) {
                    // Fallback to direct count if it's already a number
                    categoriesDict[key.stringValue] = count
                }
            }
            categories = categoriesDict
        }
    }
    
    // Computed properties for backwards compatibility
    var totalDocuments: Int {
        return totalCount
    }
    
    var totalSize: Int64 {
        return documents.reduce(0) { $0 + $1.fileSize }
    }
    
    var categoryCounts: [DocumentCategoryCount] {
        return categories.map { DocumentCategoryCount(category: $0.key, count: $0.value) }
    }
    
    var recentUploads: [WorkerDocument] {
        return Array(documents.sorted { $0.uploadedAt > $1.uploadedAt }.prefix(5))
    }
    
    var oldestDocument: WorkerDocument? {
        return documents.min { $0.uploadedAt < $1.uploadedAt }
    }
    
    var newestDocument: WorkerDocument? {
        return documents.max { $0.uploadedAt < $1.uploadedAt }
    }
    
    var totalSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    enum CodingKeys: String, CodingKey {
        case workerId = "worker_id"
        case workerName = "worker_name"
        case documents
        case categories
        case totalCount = "total_count"
    }
}

// MARK: - File Upload Progress

struct DocumentUploadProgress {
    let documentId: String
    let fileName: String
    let progress: Double
    let isComplete: Bool
    let error: String?
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
}