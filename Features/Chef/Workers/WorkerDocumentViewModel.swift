//
//  WorkerDocumentViewModel.swift
//  KSR Cranes App
//  ViewModel for worker document management
//

import Foundation
import Combine
import UIKit
import UniformTypeIdentifiers

class WorkerDocumentViewModel: ObservableObject {
    @Published var documents: [WorkerDocument] = []
    @Published var documentStats: WorkerDocumentStats?
    @Published var filteredDocuments: [WorkerDocument] = []
    @Published var selectedCategory: DocumentCategory?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var searchText = ""
    
    // Upload progress tracking
    @Published var uploadProgresses: [String: DocumentUploadProgress] = [:]
    @Published var isUploading = false
    
    // Selection for bulk operations
    @Published var selectedDocuments: Set<String> = []
    @Published var isSelectionMode = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = WorkerDocumentAPIService.shared
    
    let workerId: Int
    
    init(workerId: Int) {
        self.workerId = workerId
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Filter documents when search text or category changes
        Publishers.CombineLatest3($documents, $searchText, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { [weak self] documents, searchText, category in
                self?.filterDocuments(documents, searchText: searchText, category: category) ?? []
            }
            .assign(to: \.filteredDocuments, on: self)
            .store(in: &cancellables)
    }
    
    private func filterDocuments(
        _ documents: [WorkerDocument],
        searchText: String,
        category: DocumentCategory?
    ) -> [WorkerDocument] {
        return documents.filter { document in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                document.originalFileName.localizedCaseInsensitiveContains(searchText)
            
            // Category filter
            let matchesCategory = category == nil || document.categoryEnum == category
            
            return matchesSearch && matchesCategory
        }.sorted { $0.uploadedAt > $1.uploadedAt }
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard !isLoading else { return }
        
        #if DEBUG
        print("[WorkerDocumentViewModel] Loading documents for worker: \(workerId)")
        #endif
        
        isLoading = true
        
        apiService.fetchWorkerDocumentStats(workerId: workerId)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "loading documents")
                }
            },
            receiveValue: { [weak self] stats in
                #if DEBUG
                print("[WorkerDocumentViewModel] ✅ Loaded \(stats.documents.count) documents")
                for doc in stats.documents {
                    print("  - Document: \(doc.name)")
                    print("    Key: \(doc.key)")
                    print("    Server Category: \(doc.category)")
                    print("    Computed Category: \(doc.categoryEnum?.rawValue ?? "nil")")
                }
                #endif
                self?.documents = stats.documents
                self?.documentStats = stats
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshData() {
        loadData()
    }
    
    // MARK: - Document Upload
    
    func uploadDocument(
        fileData: Data,
        fileName: String,
        mimeType: String,
        category: DocumentCategory,
        description: String? = nil,
        tags: [String]? = nil
    ) {
        let uploadId = UUID().uuidString
        
        // Create upload progress tracking
        let progress = DocumentUploadProgress(
            documentId: uploadId,
            fileName: fileName,
            progress: 0.0,
            isComplete: false,
            error: nil
        )
        
        uploadProgresses[uploadId] = progress
        isUploading = true
        
        let uploadRequest = UploadWorkerDocumentRequest(
            category: category,
            description: description,
            tags: tags
        )
        
        #if DEBUG
        print("[WorkerDocumentViewModel] 📤 Uploading document: \(fileName)")
        #endif
        
        apiService.uploadWorkerDocument(
            workerId: workerId,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            uploadRequest: uploadRequest
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isUploading = false
                self?.uploadProgresses.removeValue(forKey: uploadId)
                
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "uploading document")
                }
            },
            receiveValue: { [weak self] response in
                if response.success {
                    self?.showSuccess(response.message)
                    self?.refreshStats()
                    self?.loadData() // Reload the documents list to get the new ones
                    
                    #if DEBUG
                    print("[WorkerDocumentViewModel] ✅ Documents uploaded: \(response.uploaded.count)")
                    for uploadedDoc in response.uploaded {
                        print("[WorkerDocumentViewModel] ✅ Uploaded: \(uploadedDoc.name)")
                    }
                    #endif
                } else {
                    self?.showError("Failed to upload document: \(response.message)")
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Document Operations
    
    func updateDocument(
        _ document: WorkerDocument,
        category: DocumentCategory? = nil,
        description: String? = nil,
        tags: [String]? = nil
    ) {
        let updateRequest = UpdateWorkerDocumentRequest(
            category: category,
            description: description,
            tags: tags
        )
        
        apiService.updateWorkerDocument(
            workerId: workerId,
            documentId: document.id,
            updateRequest: updateRequest
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "updating document")
                }
            },
            receiveValue: { [weak self] updatedDocument in
                if let index = self?.documents.firstIndex(where: { $0.id == updatedDocument.id }) {
                    self?.documents[index] = updatedDocument
                    self?.showSuccess("Document updated successfully")
                    
                    #if DEBUG
                    print("[WorkerDocumentViewModel] ✅ Document updated: \(updatedDocument.originalFileName)")
                    #endif
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func deleteDocument(_ document: WorkerDocument) {
        apiService.deleteWorkerDocument(workerId: workerId, documentId: document.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "deleting document")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.documents.removeAll { $0.id == document.id }
                        self?.showSuccess("Document deleted successfully")
                        self?.refreshStats()
                        
                        #if DEBUG
                        print("[WorkerDocumentViewModel] ✅ Document deleted: \(document.originalFileName)")
                        #endif
                    } else {
                        self?.showError("Failed to delete document: \(response.message)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func downloadDocument(_ document: WorkerDocument) {
        apiService.getDocumentDownloadURL(workerId: workerId, documentId: document.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "getting download URL")
                    }
                },
                receiveValue: { downloadUrl in
                    if let url = URL(string: downloadUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Bulk Operations
    
    func toggleDocumentSelection(_ documentId: String) {
        if selectedDocuments.contains(documentId) {
            selectedDocuments.remove(documentId)
        } else {
            selectedDocuments.insert(documentId)
        }
    }
    
    func selectAllDocuments() {
        selectedDocuments = Set(filteredDocuments.map { $0.id })
    }
    
    func deselectAllDocuments() {
        selectedDocuments.removeAll()
    }
    
    func deleteSelectedDocuments() {
        let documentIds = Array(selectedDocuments)
        
        apiService.deleteMultipleDocuments(workerId: workerId, documentIds: documentIds)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAPIError(error, context: "deleting selected documents")
                    }
                },
                receiveValue: { [weak self] responses in
                    let successfulDeletions = responses.filter { $0.success }
                    let successfulIds = successfulDeletions.compactMap { $0.documentId }
                    
                    self?.documents.removeAll { successfulIds.contains($0.id) }
                    self?.selectedDocuments.removeAll()
                    self?.isSelectionMode = false
                    
                    self?.showSuccess("Deleted \(successfulDeletions.count) documents successfully")
                    self?.refreshStats()
                    
                    #if DEBUG
                    print("[WorkerDocumentViewModel] ✅ Deleted \(successfulDeletions.count) documents")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    func moveSelectedDocuments(to category: DocumentCategory) {
        let documentIds = Array(selectedDocuments)
        
        apiService.moveDocumentsToCategory(
            workerId: workerId,
            documentIds: documentIds,
            newCategory: category
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "moving documents")
                }
            },
            receiveValue: { [weak self] updatedDocuments in
                // Update documents in the array
                for updatedDoc in updatedDocuments {
                    if let index = self?.documents.firstIndex(where: { $0.id == updatedDoc.id }) {
                        self?.documents[index] = updatedDoc
                    }
                }
                
                self?.selectedDocuments.removeAll()
                self?.isSelectionMode = false
                self?.showSuccess("Moved \(updatedDocuments.count) documents to \(category.displayName)")
                self?.refreshStats()
                
                #if DEBUG
                print("[WorkerDocumentViewModel] ✅ Moved \(updatedDocuments.count) documents to \(category.displayName)")
                #endif
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Helpers
    
    private func refreshStats() {
        apiService.fetchWorkerDocumentStats(workerId: workerId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("[WorkerDocumentViewModel] Failed to refresh stats: \(error)")
                        #endif
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.documentStats = stats
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleAPIError(_ error: WorkerDocumentAPIService.APIError, context: String) {
        #if DEBUG
        print("[WorkerDocumentViewModel] ❌ API Error (\(context)): \(error)")
        #endif
        
        let message: String
        switch error {
        case .networkError:
            message = "Network error. Please check your connection and try again."
        case .serverError(let code, let serverMessage):
            message = "Server error (\(code)): \(serverMessage)"
        case .decodingError:
            message = "Error processing server response. Please try again."
        default:
            message = "An unexpected error occurred. Please try again."
        }
        
        showError(message)
    }
    
    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Success"
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Computed Properties
    
    var documentsByCategory: [DocumentCategory: [WorkerDocument]] {
        let grouped = Dictionary(grouping: documents) { $0.categoryEnum ?? .general }
        #if DEBUG
        print("[DEBUG] Documents by category:")
        for (category, docs) in grouped {
            print("  \(category.rawValue): \(docs.count) documents")
        }
        #endif
        return grouped
    }
    
    var hasDocuments: Bool {
        return !documents.isEmpty
    }
    
    var totalDocumentSize: Int64 {
        return documents.reduce(0) { $0 + $1.fileSize }
    }
    
    var totalDocumentSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalDocumentSize, countStyle: .file)
    }
    
    // MARK: - File Type Validation
    
    func isValidFileType(_ fileExtension: String) -> Bool {
        let allowedExtensions = [
            "pdf", "doc", "docx", "txt", "rtf",
            "jpg", "jpeg", "png", "gif", "webp", "heic",
            "xls", "xlsx", "csv",
            "ppt", "pptx",
            "zip", "rar"
        ]
        return allowedExtensions.contains(fileExtension.lowercased())
    }
    
    func getFileIcon(for mimeType: String) -> String {
        switch mimeType.lowercased() {
        case let type where type.contains("pdf"):
            return "doc.fill"
        case let type where type.contains("image"):
            return "photo.fill"
        case let type where type.contains("video"):
            return "video.fill"
        case let type where type.contains("audio"):
            return "music.note"
        case let type where type.contains("text"):
            return "doc.text.fill"
        case let type where type.contains("spreadsheet"), let type where type.contains("excel"):
            return "tablecells.fill"
        case let type where type.contains("presentation"), let type where type.contains("powerpoint"):
            return "rectangle.stack.fill"
        case let type where type.contains("zip"), let type where type.contains("archive"):
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }
}