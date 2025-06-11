//
//  DocumentViewerSheet.swift
//  KSR Cranes App
//  Sheet for viewing documents (PDFs, images, etc.)
//

import SwiftUI
import PDFKit
import Foundation

struct DocumentViewerSheet: View {
    let document: WorkerDocument
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var documentData: Data?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if let data = documentData {
                    documentContentView(data)
                } else {
                    errorView("Unable to load document")
                }
            }
            .navigationTitle(document.originalFileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            shareDocument()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            openInExternalApp()
                        } label: {
                            Label("Open in App", systemImage: "square.and.arrow.up.on.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(documentData == nil)
                }
            }
        }
        .onAppear {
            loadDocument()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = documentData {
                DocumentShareSheet(items: [data])
            }
        }
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading document...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error Loading Document")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadDocument()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.ksrPrimary)
            .cornerRadius(8)
        }
        .padding(.horizontal, 32)
    }
    
    private func documentContentView(_ data: Data) -> some View {
        Group {
            if document.isPDF {
                PDFViewer(source: .data(data))
            } else if document.isImage {
                ImageViewer(imageData: data)
            } else {
                UnsupportedFileView(document: document)
            }
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
    
    private func loadDocument() {
        guard let url = URL(string: document.documentUrl) else {
            loadError = "Invalid document URL"
            isLoading = false
            return
        }
        
        isLoading = true
        loadError = nil
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    loadError = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    loadError = "No data received"
                    return
                }
                
                documentData = data
            }
        }.resume()
    }
    
    private func shareDocument() {
        showingShareSheet = true
    }
    
    private func openInExternalApp() {
        guard let data = documentData else { return }
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.originalFileName)
        
        do {
            try data.write(to: tempURL)
            UIApplication.shared.open(tempURL)
        } catch {
            print("Failed to create temporary file: \(error)")
        }
    }
}

// MARK: - Image Viewer

struct ImageViewer: View {
    let imageData: Data
    @State private var scale: CGFloat = 1.0
    @State private var lastMagnification: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastMagnification * value
                                    }
                                    .onEnded { value in
                                        lastMagnification = scale
                                        if scale < 1 {
                                            withAnimation(.spring()) {
                                                scale = 1
                                                lastMagnification = 1
                                            }
                                        } else if scale > 5 {
                                            withAnimation(.spring()) {
                                                scale = 5
                                                lastMagnification = 5
                                            }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    lastMagnification = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                    lastMagnification = 2
                                }
                            }
                        }
                } else {
                    Text("Unable to display image")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Unsupported File View

struct UnsupportedFileView: View {
    let document: WorkerDocument
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: getFileIcon())
                .font(.system(size: 64))
                .foregroundColor(document.categoryEnum?.color ?? Color.ksrPrimary)
            
            VStack(spacing: 8) {
                Text(document.originalFileName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text(document.fileExtension)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(document.categoryEnum?.color ?? Color.ksrPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((document.categoryEnum?.color ?? Color.ksrPrimary).opacity(0.2))
                    )
            }
            
            VStack(spacing: 12) {
                InfoRow(title: "Size", value: document.fileSizeFormatted)
                InfoRow(title: "Category", value: document.categoryEnum?.displayName ?? document.category)
                InfoRow(title: "Uploaded", value: document.uploadedAtFormatted)
                
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            
            Text("This file type cannot be previewed within the app. Use the share button to open it in another app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 16)
    }
    
    private func getFileIcon() -> String {
        switch document.fileExtension.lowercased() {
        case "txt", "rtf":
            return "doc.text.fill"
        case "xls", "xlsx", "csv":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "rectangle.stack.fill"
        case "zip", "rar":
            return "archivebox.fill"
        case "mp3", "wav", "m4a":
            return "music.note"
        case "mp4", "mov", "avi":
            return "video.fill"
        default:
            return "doc.fill"
        }
    }
}

// MARK: - Share Sheet

struct DocumentShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Info Row for Unsupported Files

private struct InfoRow: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
    }
}