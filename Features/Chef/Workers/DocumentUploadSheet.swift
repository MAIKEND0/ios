//
//  DocumentUploadSheet.swift
//  KSR Cranes App
//  Sheet for uploading new documents
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct DocumentUploadSheet: View {
    @ObservedObject var viewModel: WorkerDocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategory: DocumentCategory = .general
    @State private var description: String = ""
    @State private var tags: String = ""
    @State private var showingDocumentPicker = false
    @State private var selectedDocument: URL?
    @State private var selectedFileName: String = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Upload Area
                    uploadAreaView
                    
                    // Document Details Form
                    if selectedDocument != nil {
                        documentDetailsForm
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload") {
                        uploadDocument()
                    }
                    .disabled(selectedDocument == nil || isProcessing)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: allowedFileTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    // MARK: - Upload Area
    
    private var uploadAreaView: some View {
        VStack(spacing: 20) {
            if selectedDocument != nil {
                // Selected file display
                selectedFileView
            } else {
                // Upload prompt
                uploadPromptView
            }
        }
    }
    
    private var uploadPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 64))
                .foregroundColor(Color.ksrPrimary.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("Select Document")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("Choose a file from your device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                showingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("Browse Files")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.ksrPrimary)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ksrPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
        )
    }
    
    private var selectedFileView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: getFileIcon(for: selectedFileName))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.ksrPrimary)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.ksrPrimary.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedFileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .lineLimit(2)
                    
                    if let fileSize = getFileSize(url: selectedDocument!) {
                        Text(fileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    selectedDocument = nil
                    selectedFileName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
            )
            
            Button {
                showingDocumentPicker = true
            } label: {
                Text("Choose Different File")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrPrimary)
            }
        }
    }
    
    // MARK: - Document Details Form
    
    private var documentDetailsForm: some View {
        VStack(spacing: 20) {
            Text("Document Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Category Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(DocumentCategory.allCases, id: \.self) { category in
                            DocumentCategorySelectionCard(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    TextField("Add a description for this document", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    TextField("Separate tags with commas", text: $tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Example: contract, 2024, important")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Functions
    
    private var allowedFileTypes: [UTType] {
        return [
            .pdf, .plainText, .rtf,
            .jpeg, .png, .gif, .webP, .heic,
            .commaSeparatedText, .spreadsheet,
            .presentation,
            .zip, .archive
        ]
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedDocument = url
                selectedFileName = url.lastPathComponent
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }
    
    private func uploadDocument() {
        guard let selectedDocument = selectedDocument else { return }
        
        isProcessing = true
        
        // Start secure access to the file URL (required for iCloud files)
        let accessGranted = selectedDocument.startAccessingSecurityScopedResource()
        
        defer {
            if accessGranted {
                selectedDocument.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let fileData = try Data(contentsOf: selectedDocument)
            let mimeType = getMimeType(for: selectedDocument)
            let tagsArray = tags.isEmpty ? nil : tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            viewModel.uploadDocument(
                fileData: fileData,
                fileName: selectedFileName,
                mimeType: mimeType,
                category: selectedCategory,
                description: description.isEmpty ? nil : description,
                tags: tagsArray
            )
            
            dismiss()
            
        } catch {
            print("Failed to read file data: \(error)")
            isProcessing = false
        }
    }
    
    private func getFileIcon(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "webp", "heic":
            return "photo.fill"
        case "mp4", "mov", "avi":
            return "video.fill"
        case "mp3", "wav", "m4a":
            return "music.note"
        case "txt", "rtf":
            return "doc.text.fill"
        case "xls", "xlsx", "csv":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "rectangle.stack.fill"
        case "zip", "rar":
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }
    
    private func getMimeType(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return "application/pdf"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic":
            return "image/heic"
        case "txt":
            return "text/plain"
        case "rtf":
            return "text/rtf"
        case "csv":
            return "text/csv"
        case "zip":
            return "application/zip"
        default:
            return "application/octet-stream"
        }
    }
    
    private func getFileSize(url: URL) -> String? {
        // Start secure access to the file URL (required for iCloud files)
        let accessGranted = url.startAccessingSecurityScopedResource()
        
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
        } catch {
            print("Failed to get file size: \(error)")
        }
        return nil
    }
}

// MARK: - Category Selection Card

struct DocumentCategorySelectionCard: View {
    let category: DocumentCategory
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(category.color))
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(category.color) : Color(category.color).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color(category.color).opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}