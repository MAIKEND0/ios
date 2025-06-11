//
//  WorkerDocumentManagerView.swift
//  KSR Cranes App
//  Complete document management interface for workers
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import Foundation

struct WorkerDocumentManagerView: View {
    let worker: WorkerForChef
    @StateObject private var viewModel: WorkerDocumentViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCategoryFilter = false
    @State private var showingUploadSheet = false
    @State private var showingBulkActionsSheet = false
    @State private var selectedDocumentForViewing: WorkerDocument?
    
    init(worker: WorkerForChef) {
        self.worker = worker
        self._viewModel = StateObject(wrappedValue: WorkerDocumentViewModel(workerId: worker.id))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                if viewModel.isLoading && viewModel.documents.isEmpty {
                    loadingView
                } else if viewModel.documents.isEmpty {
                    emptyStateView
                } else {
                    documentsContentView
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isSelectionMode {
                        Button("Cancel") {
                            viewModel.isSelectionMode = false
                            viewModel.deselectAllDocuments()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSelectionMode {
                        Menu {
                            Button {
                                showingBulkActionsSheet = true
                            } label: {
                                Label("Bulk Actions", systemImage: "ellipsis.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        Menu {
                            Button {
                                showingUploadSheet = true
                            } label: {
                                Label("Upload Document", systemImage: "plus.circle")
                            }
                            
                            Button {
                                showingPhotoPicker = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            Button {
                                viewModel.isSelectionMode = true
                            } label: {
                                Label("Select Multiple", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search documents...")
        }
        .onAppear {
            viewModel.loadData()
        }
        .refreshable {
            viewModel.refreshData()
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .sheet(isPresented: $showingUploadSheet) {
            DocumentUploadSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCategoryFilter) {
            CategoryFilterSheet(
                selectedCategory: $viewModel.selectedCategory,
                categories: DocumentCategory.allCases
            )
        }
        .sheet(isPresented: $showingBulkActionsSheet) {
            BulkActionsSheet(viewModel: viewModel)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
        .sheet(item: $selectedDocumentForViewing) { document in
            DocumentViewerSheet(document: document)
        }
    }
    
    // MARK: - Content Views
    
    private var documentsContentView: some View {
        VStack(spacing: 0) {
            // Statistics and filters
            if let stats = viewModel.documentStats {
                documentStatsView(stats)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            
            // Category filters
            categoryFiltersView
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            // Documents list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredDocuments) { document in
                        DocumentCard(
                            document: document,
                            isSelected: viewModel.selectedDocuments.contains(document.id),
                            isSelectionMode: viewModel.isSelectionMode,
                            onTap: {
                                if viewModel.isSelectionMode {
                                    viewModel.toggleDocumentSelection(document.id)
                                } else {
                                    openDocument(document)
                                }
                            },
                            onLongPress: {
                                if !viewModel.isSelectionMode {
                                    viewModel.isSelectionMode = true
                                    viewModel.toggleDocumentSelection(document.id)
                                }
                            },
                            onDelete: {
                                viewModel.deleteDocument(document)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    private func documentStatsView(_ stats: WorkerDocumentStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatsCard(
                    title: "Total",
                    value: "\(stats.totalDocuments)",
                    icon: "doc.fill",
                    color: Color.ksrPrimary
                )
                
                StatsCard(
                    title: "Size",
                    value: stats.totalSizeFormatted,
                    icon: "externaldrive.fill",
                    color: Color.ksrInfo
                )
                
                StatsCard(
                    title: "Categories",
                    value: "\(stats.categoryCounts.count)",
                    icon: "folder.fill",
                    color: Color.ksrSuccess
                )
            }
        }
    }
    
    private var categoryFiltersView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Categories")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                
                Button("Clear Filter") {
                    viewModel.selectedCategory = nil
                }
                .font(.caption)
                .foregroundColor(Color.ksrPrimary)
                .disabled(viewModel.selectedCategory == nil)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DocumentCategory.allCases, id: \.self) { category in
                        let count = viewModel.documentsByCategory[category]?.count ?? 0
                        #if DEBUG
                        let _ = print("[DEBUG] Category \(category.rawValue): \(count) documents")
                        #endif
                        
                        CategoryFilterChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category,
                            count: count
                        ) {
                            #if DEBUG
                            print("[DEBUG] Selected category: \(category.rawValue)")
                            #endif
                            viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Documents")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text("Upload your first document to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingUploadSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload Document")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.ksrPrimary)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading documents...")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    
    private func openDocument(_ document: WorkerDocument) {
        selectedDocumentForViewing = document
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data {
                        viewModel.uploadDocument(
                            fileData: data,
                            fileName: "photo_\(Date().timeIntervalSince1970).jpg",
                            mimeType: "image/jpeg",
                            category: .photos,
                            description: "Photo taken on \(DateFormatter.shortDate.string(from: Date()))"
                        )
                    }
                case .failure(let error):
                    print("Failed to load photo: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DocumentCard: View {
    let document: WorkerDocument
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox (when in selection mode)
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.ksrPrimary : .secondary)
            }
            
            // Document icon based on file type
            Image(systemName: document.fileTypeIcon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(document.fileTypeIconColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(document.fileTypeIconColor.opacity(0.2))
                )
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.originalFileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                
                
                HStack {
                    Text(document.categoryEnum?.displayName ?? document.category)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(document.categoryEnum?.color ?? Color.ksrPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((document.categoryEnum?.color ?? Color.ksrPrimary).opacity(0.2))
                        )
                    
                    Text(document.fileSizeFormatted)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(document.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action menu (when not in selection mode)
            if !isSelectionMode {
                Menu {
                    Button {
                        onTap()
                    } label: {
                        Label("Open", systemImage: "eye")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.ksrPrimary : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

struct CategoryFilterChip: View {
    let category: DocumentCategory
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .medium))
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white : category.color)
                    )
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : category.color.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
        )
    }
}