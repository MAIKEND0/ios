//
//  DocumentBulkActionsSheet.swift
//  KSR Cranes App
//  Sheet for bulk document operations
//

import SwiftUI
import Foundation

struct BulkActionsSheet: View {
    @ObservedObject var viewModel: WorkerDocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDeleteConfirmation = false
    @State private var showingMoveToCategory = false
    @State private var selectedMoveCategory: DocumentCategory = .general
    
    var selectedCount: Int {
        viewModel.selectedDocuments.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Actions
                actionsView
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(backgroundGradient)
            .navigationTitle("Bulk Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            })
        }
        .confirmationDialog(
            "Delete Documents",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete \(selectedCount) Documents", role: .destructive) {
                viewModel.deleteSelectedDocuments()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(selectedCount) documents? This action cannot be undone.")
        }
        .sheet(isPresented: $showingMoveToCategory) {
            MoveToCategorySheet(
                selectedCategory: $selectedMoveCategory,
                onMove: {
                    viewModel.moveSelectedDocuments(to: selectedMoveCategory)
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.ksrPrimary)
            
            Text("\(selectedCount) Documents Selected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text("Choose an action to perform on the selected documents")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Actions
    
    private var actionsView: some View {
        VStack(spacing: 16) {
            // Move to Category
            BulkActionButton(
                title: "Move to Category",
                subtitle: "Change the category for selected documents",
                icon: "folder.fill",
                color: Color.ksrInfo
            ) {
                showingMoveToCategory = true
            }
            
            // Select All
            BulkActionButton(
                title: "Select All",
                subtitle: "Select all visible documents",
                icon: "checkmark.circle.fill",
                color: Color.ksrSuccess
            ) {
                viewModel.selectAllDocuments()
                dismiss()
            }
            
            // Deselect All
            BulkActionButton(
                title: "Deselect All",
                subtitle: "Clear current selection",
                icon: "circle",
                color: Color.ksrWarning
            ) {
                viewModel.deselectAllDocuments()
                dismiss()
            }
            
            // Delete Selected
            BulkActionButton(
                title: "Delete Selected",
                subtitle: "Permanently delete selected documents",
                icon: "trash.fill",
                color: .red,
                isDestructive: true
            ) {
                showingDeleteConfirmation = true
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
}

// MARK: - Bulk Action Button

struct BulkActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : (colorScheme == .dark ? .white : .primary))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Move to Category Sheet

struct MoveToCategorySheet: View {
    @Binding var selectedCategory: DocumentCategory
    let onMove: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                moveCategoryHeaderView
                
                // Category Selection
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(DocumentCategory.allCases, id: \.self) { category in
                        CategoryMoveCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                
                Spacer()
                
                // Move Button
                Button {
                    onMove()
                } label: {
                    Text("Move Documents")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.ksrPrimary)
                        .cornerRadius(12)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
            .background(backgroundGradient)
            .navigationTitle("Move Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var moveCategoryHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.ksrPrimary)
            
            Text("Move to Category")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text("Select the new category for the selected documents")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
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
}

// MARK: - Category Move Card

struct CategoryMoveCard: View {
    let category: DocumentCategory
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(category.color))
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(category.color) : Color(category.color).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color(category.color).opacity(0.5), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Filter Sheet

struct CategoryFilterSheet: View {
    @Binding var selectedCategory: DocumentCategory?
    let categories: [DocumentCategory]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.ksrPrimary)
                    
                    Text("Filter by Category")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("Select a category to filter documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                
                // All Categories Option
                Button {
                    selectedCategory = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedCategory == nil ? .white : Color.ksrPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(selectedCategory == nil ? Color.ksrPrimary : Color.ksrPrimary.opacity(0.2))
                            )
                        
                        Text("All Categories")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Spacer()
                        
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.ksrPrimary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Category Options
                LazyVStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: category.systemImage)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(selectedCategory == category ? .white : Color(category.color))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(selectedCategory == category ? Color(category.color) : Color(category.color).opacity(0.2))
                                    )
                                
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Spacer()
                                
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(category.color))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .background(backgroundGradient)
            .navigationTitle("Filter Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
}