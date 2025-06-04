//
//  EquipmentSelectorViews.swift
//  KSR Cranes App
//
//  ✅ COMPLETELY FIXED - Navigation and UI Refresh Issues Resolved
//

import SwiftUI
import Combine
import Foundation

// MARK: - Hierarchical Equipment Selector - ✅ FIXED VERSION

struct HierarchicalEquipmentSelectorView: View {
    @Binding var selectedEquipment: SelectedEquipment
    let allowMultipleTypes: Bool
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HierarchicalEquipmentViewModel()
    @State private var currentStep: EquipmentSelectionStep = .category
    
    // ✅ ADDED: Force refresh triggers
    @State private var refreshTrigger = UUID()
    @State private var stepContentId = UUID()
    
    enum EquipmentSelectionStep: Int, CaseIterable {
        case category = 0
        case type = 1
        case brand = 2
        case model = 3
        
        var title: String {
            switch self {
            case .category: return "Select Category"
            case .type: return "Select Type"
            case .brand: return "Select Brand"
            case .model: return "Select Model"
            }
        }
        
        var icon: String {
            switch self {
            case .category: return "folder.fill"
            case .type: return "wrench.and.screwdriver.fill"
            case .brand: return "building.2.fill"
            case .model: return "wrench.adjustable"
            }
        }
        
        var description: String {
            switch self {
            case .category: return "Choose equipment category"
            case .type: return "Choose specific crane type"
            case .brand: return "Choose manufacturer"
            case .model: return "Choose exact model"
            }
        }
    }
    
    init(selectedEquipment: Binding<SelectedEquipment>, allowMultipleTypes: Bool = false) {
        self._selectedEquipment = selectedEquipment
        self.allowMultipleTypes = allowMultipleTypes
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                // Step Content - ✅ FIXED: Added refresh IDs
                stepContent
                    .id("step-\(currentStep.rawValue)-\(stepContentId)")
                
                // Navigation Buttons
                navigationButtons
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Equipment Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSelectionAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrYellow)
                    .disabled(!viewModel.hasValidSelection)
                }
            }
            .onAppear {
                #if DEBUG
                print("[HierarchicalEquipmentSelector] 🔍 Initializing with equipment: \(selectedEquipment)")
                #endif
                viewModel.initialize(with: selectedEquipment)
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Step Progress Indicator
            HStack(spacing: 8) {
                ForEach(EquipmentSelectionStep.allCases, id: \.self) { step in
                    stepIndicator(for: step)
                }
            }
            .padding(.horizontal)
            
            // Current Step Info
            VStack(spacing: 8) {
                Image(systemName: currentStep.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.ksrYellow)
                
                Text(currentStep.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(currentStep.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private func stepIndicator(for step: EquipmentSelectionStep) -> some View {
        Circle()
            .fill(stepIndicatorColor(for: step))
            .frame(width: 32, height: 32)
            .overlay(
                Group {
                    if step.rawValue < currentStep.rawValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(step.rawValue + 1)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(step == currentStep ? .white : .secondary)
                    }
                }
            )
    }
    
    private func stepIndicatorColor(for step: EquipmentSelectionStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return .ksrSuccess
        } else if step == currentStep {
            return .ksrYellow
        } else {
            return Color(.systemGray4)
        }
    }
    
    // MARK: - Step Content - ✅ FIXED
    
    private var stepContent: some View {
        ScrollView {
            VStack(spacing: 12) { // ✅ CHANGED: VStack instead of LazyVStack for better refresh
                // ✅ ADDED: Debug info in DEBUG mode
                #if DEBUG
                debugInfoView
                #endif
                
                switch currentStep {
                case .category:
                    categorySelectionContent
                case .type:
                    typeSelectionContent
                case .brand:
                    brandSelectionContent
                case .model:
                    modelSelectionContent
                }
            }
            .padding()
        }
    }
    
    // ✅ ADDED: Debug info view
    #if DEBUG
    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔍 DEBUG INFO")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Group {
                Text("Current Step: \(currentStep.title) (\(currentStep.rawValue))")
                Text("Allow Multiple: \(allowMultipleTypes ? "Yes" : "No")")
                Text("Selected Category: \(viewModel.selectedCategoryId?.description ?? "None")")
                Text("Selected Types: \(viewModel.selectedTypeIds)")
                Text("Available Types Count: \(viewModel.availableTypes.count)")
                Text("Loading Types: \(viewModel.isLoadingTypes ? "Yes" : "No")")
                Text("Show Next Button: \(shouldShowNextButton ? "Yes" : "No")")
                Text("Can Advance: \(canAdvanceFromCurrentStep ? "Yes" : "No")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
    #endif
    
    // MARK: - Category Selection
    
    private var categorySelectionContent: some View {
        Group {
            if viewModel.isLoadingCategories {
                loadingView("Loading categories...")
            } else if viewModel.categories.isEmpty {
                emptyStateView("No categories available", "Check your connection and try again")
            } else {
                ForEach(viewModel.categories) { category in
                    CategorySelectionCard(
                        category: category,
                        isSelected: viewModel.selectedCategoryId == category.id,
                        onSelect: {
                            #if DEBUG
                            print("[HierarchicalEquipmentSelector] 📁 Selected category: \(category.name) (ID: \(category.id))")
                            #endif
                            viewModel.selectCategory(category.id)
                            forceUIRefresh()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Type Selection - ✅ COMPLETELY FIXED
    
    private var typeSelectionContent: some View {
        Group {
            if viewModel.isLoadingTypes {
                loadingView("Loading crane types...")
            } else if viewModel.availableTypes.isEmpty {
                emptyStateView("No crane types available", "No types found for selected category")
            } else {
                ForEach(viewModel.availableTypes) { type in
                    TypeSelectionCard(
                        type: type,
                        isSelected: allowMultipleTypes
                            ? viewModel.selectedTypeIds.contains(type.id)
                            : viewModel.selectedTypeIds.first == type.id,
                        onSelect: {
                            #if DEBUG
                            print("[HierarchicalEquipmentSelector] 🔧 Selected type: \(type.name) (ID: \(type.id))")
                            #endif
                            if allowMultipleTypes {
                                viewModel.toggleType(type.id)
                            } else {
                                viewModel.selectSingleType(type.id)
                            }
                            forceUIRefresh()
                        }
                    )
                }
                
                // ✅ FIXED: Show continue button for multiple types
                if allowMultipleTypes && !viewModel.selectedTypeIds.isEmpty {
                    continueButton
                }
            }
        }
    }
    
    // MARK: - Brand Selection
    
    private var brandSelectionContent: some View {
        Group {
            if viewModel.isLoadingBrands {
                loadingView("Loading brands...")
            } else if viewModel.availableBrands.isEmpty {
                emptyStateView("No brands available", "No brands have models for selected types")
            } else {
                skipBrandOption
                
                ForEach(viewModel.availableBrands) { brand in
                    BrandSelectionCard(
                        brand: brand,
                        isSelected: viewModel.selectedBrandId == brand.id,
                        onSelect: {
                            #if DEBUG
                            print("[HierarchicalEquipmentSelector] 🏢 Selected brand: \(brand.name) (ID: \(brand.id))")
                            #endif
                            viewModel.selectBrand(brand.id)
                            forceUIRefresh()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Model Selection
    
    private var modelSelectionContent: some View {
        Group {
            if viewModel.isLoadingModels {
                loadingView("Loading models...")
            } else if viewModel.availableModels.isEmpty {
                emptyStateView("No models available", "No models found for current selection")
            } else {
                skipModelOption
                
                ForEach(viewModel.availableModels) { model in
                    ModelSelectionCard(
                        model: model,
                        isSelected: viewModel.selectedModelId == model.id,
                        onSelect: {
                            #if DEBUG
                            print("[HierarchicalEquipmentSelector] 🚁 Selected model: \(model.name) (ID: \(model.id))")
                            #endif
                            viewModel.selectModel(model.id)
                            forceUIRefresh()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var skipBrandOption: some View {
        Button {
            #if DEBUG
            print("[HierarchicalEquipmentSelector] ⏭️ Skipping brand selection")
            #endif
            viewModel.selectedBrandId = nil
            advanceToNextStep()
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ksrInfo)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Any Brand")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Skip brand selection - show all models")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.ksrInfo, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var skipModelOption: some View {
        Button {
            #if DEBUG
            print("[HierarchicalEquipmentSelector] ⏭️ Skipping model selection")
            #endif
            viewModel.selectedModelId = nil
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ksrSuccess)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Any Compatible Model")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Don't specify exact model - any will do")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.ksrSuccess, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var continueButton: some View {
        Button {
            #if DEBUG
            print("[HierarchicalEquipmentSelector] ➡️ Continuing with \(viewModel.selectedTypeIds.count) types")
            #endif
            advanceToNextStep()
        } label: {
            HStack {
                Text("Continue with \(viewModel.selectedTypeIds.count) type\(viewModel.selectedTypeIds.count == 1 ? "" : "s")")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.ksrYellow)
            .cornerRadius(12)
        }
        .padding(.top)
    }
    
    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func emptyStateView(_ title: String, _ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.ksrWarning)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    // MARK: - Navigation Buttons - ✅ COMPLETELY FIXED
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep != .category {
                Button {
                    goToPreviousStep()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.ksrSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                .disabled(viewModel.isLoading)
            }
            
            Spacer()
            
            // ✅ COMPLETELY FIXED: Navigation button logic
            if shouldShowNextButton {
                Button {
                    advanceToNextStep()
                } label: {
                    HStack {
                        Text(getNextButtonTitle())
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.ksrYellow)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isLoading || !canAdvanceFromCurrentStep)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // ✅ COMPLETELY FIXED: Navigation logic
    private var shouldShowNextButton: Bool {
        switch currentStep {
        case .category:
            return viewModel.selectedCategoryId != nil
        case .type:
            // ✅ FIXED: Show button if single selection OR allowMultiple but manual advance needed
            if allowMultipleTypes {
                return false // Use continue button instead for multiple selection
            } else {
                return !viewModel.selectedTypeIds.isEmpty
            }
        case .brand:
            return true // Brand is optional, always show Next
        case .model:
            return false // Final step
        }
    }
    
    private var canAdvanceFromCurrentStep: Bool {
        switch currentStep {
        case .category:
            return viewModel.selectedCategoryId != nil
        case .type:
            return !viewModel.selectedTypeIds.isEmpty
        case .brand:
            return true // Brand is optional
        case .model:
            return true // Model is optional
        }
    }
    
    private var canSkipCurrentStep: Bool {
        switch currentStep {
        case .category, .type:
            return false // Required steps
        case .brand, .model:
            return true // Optional steps
        }
    }
    
    private func getNextButtonTitle() -> String {
        switch currentStep {
        case .category:
            return "Select Types"
        case .type:
            return "Choose Brand"
        case .brand:
            return "Choose Model"
        case .model:
            return "Done"
        }
    }
    
    // MARK: - Navigation Logic - ✅ ENHANCED
    
    private func advanceToNextStep() {
        guard let nextStep = EquipmentSelectionStep(rawValue: currentStep.rawValue + 1) else {
            #if DEBUG
            print("[HierarchicalEquipmentSelector] ✅ Reached final step")
            #endif
            return
        }
        
        #if DEBUG
        print("[HierarchicalEquipmentSelector] ➡️ Advancing from \(currentStep.title) to \(nextStep.title)")
        #endif
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextStep
        }
        
        // ✅ FORCE UI REFRESH
        forceUIRefresh()
        
        // Load data for next step
        switch nextStep {
        case .type:
            #if DEBUG
            print("[HierarchicalEquipmentSelector] 🔄 Loading types for category: \(viewModel.selectedCategoryId?.description ?? "none")")
            #endif
            viewModel.loadTypesForSelectedCategory()
        case .brand:
            viewModel.loadBrandsForSelectedTypes()
        case .model:
            viewModel.loadModelsForSelection()
        default:
            break
        }
    }
    
    private func goToPreviousStep() {
        guard let previousStep = EquipmentSelectionStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        
        #if DEBUG
        print("[HierarchicalEquipmentSelector] ⬅️ Going back from \(currentStep.title) to \(previousStep.title)")
        #endif
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = previousStep
        }
        
        // ✅ FORCE UI REFRESH
        forceUIRefresh()
        
        // Reset selections that depend on current step
        switch previousStep {
        case .category:
            // Don't reset anything when going back to category
            break
        case .type:
            viewModel.resetBrandsAndBelow()
        case .brand:
            viewModel.resetModels()
        case .model:
            // Can't go back from final step
            break
        }
    }
    
    // ✅ NEW: Force UI refresh method
    private func forceUIRefresh() {
        stepContentId = UUID()
        refreshTrigger = UUID()
        
        // Also trigger view model refresh
        DispatchQueue.main.async {
            self.viewModel.objectWillChange.send()
        }
    }
    
    private func saveSelectionAndDismiss() {
        let finalSelection = viewModel.createSelectedEquipment()
        
        #if DEBUG
        print("[HierarchicalEquipmentSelector] 💾 Saving selection: \(finalSelection)")
        #endif
        
        selectedEquipment = finalSelection
        dismiss()
    }
}

// MARK: - Selection Card Components (unchanged)

struct CategorySelectionCard: View {
    let category: CraneCategoryAPIResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Category Icon
                if let iconUrl = category.iconUrl, !iconUrl.isEmpty {
                    AsyncImage(url: URL(string: iconUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.ksrYellow)
                    }
                    .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.ksrYellow)
                        .frame(width: 40, height: 40)
                }
                
                // Category Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = category.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let count = category._count?.craneTypes {
                        Text("\(count) crane types")
                            .font(.caption)
                            .foregroundColor(.ksrInfo)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrYellow : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TypeSelectionCard: View {
    let type: CraneTypeAPIResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Type Icon
                if let iconUrl = type.iconUrl, !iconUrl.isEmpty {
                    AsyncImage(url: URL(string: iconUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.ksrInfo)
                    }
                    .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.title2)
                        .foregroundColor(.ksrInfo)
                        .frame(width: 40, height: 40)
                }
                
                // Type Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = type.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text(type.code)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrInfo)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.ksrInfo.opacity(0.1))
                            )
                        
                        if let count = type._count?.craneModels {
                            Text("\(count) models")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .ksrSuccess : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrInfo : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct BrandSelectionCard: View {
    let brand: CraneBrandAPIResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Brand Logo
                if let logoUrl = brand.logoUrl, !logoUrl.isEmpty {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.ksrSecondary)
                    }
                    .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(.ksrSecondary)
                        .frame(width: 40, height: 40)
                }
                
                // Brand Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(brand.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = brand.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if let year = brand.foundedYear {
                            Text("Est. \(year)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let count = brand._count?.craneModels {
                            Text("\(count) models")
                                .font(.caption)
                                .foregroundColor(.ksrSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ksrSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrSecondary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModelSelectionCard: View {
    let model: CraneModelAPIResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    // Model Icon
                    Image(systemName: "wrench.adjustable")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .ksrWarning)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.ksrWarning : Color.ksrWarning.opacity(0.1))
                        )
                    
                    // Model Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let brandName = model.brand_name {
                            Text(brandName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(model.code)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.ksrWarning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.ksrWarning.opacity(0.1))
                                )
                            
                            if let typeName = model.type_name {
                                Text(typeName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .ksrSuccess : .secondary)
                }
                
                // Specifications
                if model.maxLoadCapacity != nil || model.maxHeight != nil || model.maxRadius != nil {
                    HStack(spacing: 16) {
                        if let capacity = model.maxLoadCapacity {
                            SpecInfo(icon: "scalemass.fill", label: "Capacity", value: "\(capacity) t")
                        }
                        
                        if let height = model.maxHeight {
                            SpecInfo(icon: "arrow.up.to.line", label: "Height", value: "\(height) m")
                        }
                        
                        if let radius = model.maxRadius {
                            SpecInfo(icon: "arrow.left.and.right", label: "Radius", value: "\(radius) m")
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrWarning : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct SpecInfo: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.ksrInfo)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Selected Equipment Model

struct SelectedEquipment: Codable {
    var categoryId: Int?
    var typeIds: [Int]
    var brandId: Int?
    var modelId: Int?
    
    var hasSelection: Bool {
        return !typeIds.isEmpty || modelId != nil
    }
    
    var isComplete: Bool {
        return !typeIds.isEmpty
    }
}

// MARK: - View Model - ✅ ENHANCED WITH BETTER REFRESH

class HierarchicalEquipmentViewModel: ObservableObject {
    @Published var categories: [CraneCategoryAPIResponse] = []
    @Published var availableTypes: [CraneTypeAPIResponse] = []
    @Published var availableBrands: [CraneBrandAPIResponse] = []
    @Published var availableModels: [CraneModelAPIResponse] = []
    
    @Published var selectedCategoryId: Int?
    @Published var selectedTypeIds: [Int] = []
    @Published var selectedBrandId: Int?
    @Published var selectedModelId: Int?
    
    @Published var isLoadingCategories = false
    @Published var isLoadingTypes = false
    @Published var isLoadingBrands = false
    @Published var isLoadingModels = false
    
    private var cancellables = Set<AnyCancellable>()
    
    var isLoading: Bool {
        isLoadingCategories || isLoadingTypes || isLoadingBrands || isLoadingModels
    }
    
    var hasValidSelection: Bool {
        return !selectedTypeIds.isEmpty
    }
    
    func initialize(with selection: SelectedEquipment) {
        selectedCategoryId = selection.categoryId
        selectedTypeIds = selection.typeIds
        selectedBrandId = selection.brandId
        selectedModelId = selection.modelId
        
        loadCategories()
        
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔍 Initializing with:")
        print("   - Category ID: \(selection.categoryId?.description ?? "none")")
        print("   - Type IDs: \(selection.typeIds)")
        print("   - Brand ID: \(selection.brandId?.description ?? "none")")
        print("   - Model ID: \(selection.modelId?.description ?? "none")")
        #endif
    }
    
    func loadCategories() {
        isLoadingCategories = true
        
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Loading categories...")
        #endif
        
        EquipmentAPIService.shared.fetchCraneCategories(includeTypesCount: true)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingCategories = false
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("❌ [HierarchicalEquipmentViewModel] Failed to load categories: \(error)")
                        #endif
                    } else {
                        #if DEBUG
                        print("✅ [HierarchicalEquipmentViewModel] Categories loaded successfully")
                        #endif
                    }
                },
                receiveValue: { [weak self] categories in
                    #if DEBUG
                    print("[HierarchicalEquipmentViewModel] 📁 Loaded \(categories.count) categories")
                    categories.forEach { category in
                        print("   - \(category.name) (ID: \(category.id))")
                    }
                    #endif
                    self?.categories = categories
                }
            )
            .store(in: &cancellables)
    }
    
    func selectCategory(_ id: Int) {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 📁 Selecting category ID: \(id)")
        #endif
        selectedCategoryId = id
        selectedTypeIds = []
        selectedBrandId = nil
        selectedModelId = nil
        
        // Clear dependent data
        availableTypes = []
        availableBrands = []
        availableModels = []
        
        // Force UI update
        objectWillChange.send()
    }
    
    func toggleType(_ id: Int) {
        if selectedTypeIds.contains(id) {
            selectedTypeIds.removeAll { $0 == id }
            #if DEBUG
            print("[HierarchicalEquipmentViewModel] ➖ Removed type ID: \(id)")
            #endif
        } else {
            selectedTypeIds.append(id)
            #if DEBUG
            print("[HierarchicalEquipmentViewModel] ➕ Added type ID: \(id)")
            #endif
        }
        
        selectedBrandId = nil
        selectedModelId = nil
        
        // Clear dependent data
        availableBrands = []
        availableModels = []
        
        // Force UI update
        objectWillChange.send()
    }
    
    func selectSingleType(_ id: Int) {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔧 Selecting single type ID: \(id)")
        #endif
        selectedTypeIds = [id]
        selectedBrandId = nil
        selectedModelId = nil
        
        // Clear dependent data
        availableBrands = []
        availableModels = []
        
        // Force UI update
        objectWillChange.send()
    }
    
    func selectBrand(_ id: Int) {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🏢 Selecting brand ID: \(id)")
        #endif
        selectedBrandId = id
        selectedModelId = nil
        
        // Clear dependent data
        availableModels = []
        
        // Force UI update
        objectWillChange.send()
    }
    
    func selectModel(_ id: Int) {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🚁 Selecting model ID: \(id)")
        #endif
        selectedModelId = id
        
        // Force UI update
        objectWillChange.send()
    }
    
    func loadTypesForSelectedCategory() {
        guard let categoryId = selectedCategoryId else {
            #if DEBUG
            print("[HierarchicalEquipmentViewModel] ⚠️ No category selected")
            #endif
            return
        }
        
        isLoadingTypes = true
        
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Loading types for category: \(categoryId)")
        #endif
        
        EquipmentAPIService.shared.fetchTypesForCategory(categoryId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingTypes = false
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("❌ [HierarchicalEquipmentViewModel] Failed to load types: \(error)")
                        #endif
                    } else {
                        #if DEBUG
                        print("✅ [HierarchicalEquipmentViewModel] Types loaded successfully")
                        #endif
                    }
                },
                receiveValue: { [weak self] types in
                    #if DEBUG
                    print("[HierarchicalEquipmentViewModel] 🔧 Loaded \(types.count) types")
                    types.forEach { type in
                        print("   - \(type.name) (ID: \(type.id))")
                    }
                    #endif
                    
                    // ✅ ENHANCED: Multiple UI refresh attempts
                    self?.objectWillChange.send()
                    self?.availableTypes = types
                    
                    // Force multiple refresh attempts
                    DispatchQueue.main.async {
                        self?.objectWillChange.send()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.objectWillChange.send()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadBrandsForSelectedTypes() {
        guard !selectedTypeIds.isEmpty else {
            #if DEBUG
            print("[HierarchicalEquipmentViewModel] ⚠️ No types selected")
            #endif
            return
        }
        
        isLoadingBrands = true
        let firstTypeId = selectedTypeIds[0]
        
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Loading brands for type: \(firstTypeId)")
        #endif
        
        EquipmentAPIService.shared.fetchBrandsForType(firstTypeId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingBrands = false
                    if case .failure(let error) = completion {
                        #if DEBUG
                        print("❌ [HierarchicalEquipmentViewModel] Failed to load brands: \(error)")
                        #endif
                    } else {
                        #if DEBUG
                        print("✅ [HierarchicalEquipmentViewModel] Brands loaded successfully")
                        #endif
                    }
                },
                receiveValue: { [weak self] brands in
                    #if DEBUG
                    print("[HierarchicalEquipmentViewModel] 🏢 Loaded \(brands.count) brands")
                    brands.forEach { brand in
                        print("   - \(brand.name) (ID: \(brand.id))")
                    }
                    #endif
                    self?.availableBrands = brands
                    self?.objectWillChange.send()
                }
            )
            .store(in: &cancellables)
    }
    
    func loadModelsForSelection() {
        guard !selectedTypeIds.isEmpty else {
            #if DEBUG
            print("[HierarchicalEquipmentViewModel] ⚠️ No types selected for model loading")
            #endif
            return
        }
        
        isLoadingModels = true
        let firstTypeId = selectedTypeIds[0]
        
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Loading models for type: \(firstTypeId), brand: \(selectedBrandId?.description ?? "any")")
        #endif
        
        EquipmentAPIService.shared.fetchModelsForTypeAndBrand(
            typeId: firstTypeId,
            brandId: selectedBrandId
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingModels = false
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [HierarchicalEquipmentViewModel] Failed to load models: \(error)")
                    #endif
                } else {
                    #if DEBUG
                    print("✅ [HierarchicalEquipmentViewModel] Models loaded successfully")
                    #endif
                }
            },
            receiveValue: { [weak self] models in
                #if DEBUG
                print("[HierarchicalEquipmentViewModel] 🚁 Loaded \(models.count) models")
                models.forEach { model in
                    print("   - \(model.name) (ID: \(model.id))")
                }
                #endif
                self?.availableModels = models
                self?.objectWillChange.send()
            }
        )
        .store(in: &cancellables)
    }
    
    func resetAllSelections() {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Resetting all selections")
        #endif
        selectedCategoryId = nil
        selectedTypeIds = []
        selectedBrandId = nil
        selectedModelId = nil
        
        availableTypes = []
        availableBrands = []
        availableModels = []
        
        objectWillChange.send()
    }
    
    func resetTypesAndBelow() {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Resetting types and below")
        #endif
        selectedTypeIds = []
        selectedBrandId = nil
        selectedModelId = nil
        
        availableTypes = []
        availableBrands = []
        availableModels = []
        
        objectWillChange.send()
    }
    
    func resetBrandsAndBelow() {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Resetting brands and below")
        #endif
        selectedBrandId = nil
        selectedModelId = nil
        
        availableBrands = []
        availableModels = []
        
        objectWillChange.send()
    }
    
    func resetModels() {
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 🔄 Resetting models")
        #endif
        selectedModelId = nil
        availableModels = []
        
        objectWillChange.send()
    }
    
    func createSelectedEquipment() -> SelectedEquipment {
        let equipment = SelectedEquipment(
            categoryId: selectedCategoryId,
            typeIds: selectedTypeIds,
            brandId: selectedBrandId,
            modelId: selectedModelId
        )
        
        #if DEBUG
        print("[HierarchicalEquipmentViewModel] 💾 Creating final equipment selection: \(equipment)")
        #endif
        
        return equipment
    }
}

// MARK: - Remaining legacy views for backward compatibility (unchanged)

struct RealCraneTypeSelectorView: View {
    @Binding var selectedCraneTypes: [Int]?
    let allowMultipleSelection: Bool
    
    @StateObject private var viewModel = CraneTypeSelectorViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    
    init(selectedCraneTypes: Binding<[Int]?>, allowMultipleSelection: Bool = true) {
        self._selectedCraneTypes = selectedCraneTypes
        self.allowMultipleSelection = allowMultipleSelection
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBarView
                
                if viewModel.isLoading && viewModel.craneTypes.isEmpty {
                    loadingView
                } else if filteredCraneTypes.isEmpty {
                    emptyStateView
                } else {
                    craneTypesList
                }
                
                if !selectedTypeIds.isEmpty {
                    selectionSummary
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Crane Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { saveSelection() }
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrYellow)
                        .disabled(selectedTypeIds.isEmpty)
                }
            }
            .onAppear {
                viewModel.loadCraneTypes()
                initializeSelection()
            }
        }
    }
    
    private var selectedTypeIds: Set<Int> {
        Set(selectedCraneTypes ?? [])
    }
    
    private var filteredCraneTypes: [CraneTypeAPIResponse] {
        if searchText.isEmpty {
            return viewModel.craneTypes
        } else {
            return viewModel.craneTypes.filter { type in
                type.name.localizedCaseInsensitiveContains(searchText) ||
                type.code.localizedCaseInsensitiveContains(searchText) ||
                (type.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search crane types...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading crane types...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(.ksrYellow.opacity(0.6))
            
            Text("No Crane Types Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            if searchText.isEmpty {
                Text("No crane types are available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No crane types match '\(searchText)'")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Clear Search") {
                    searchText = ""
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.ksrYellow)
                .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var craneTypesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCraneTypes, id: \.id) { craneType in
                    CraneTypeSelectionCard(
                        craneType: craneType,
                        isSelected: selectedTypeIds.contains(craneType.id),
                        allowMultipleSelection: allowMultipleSelection,
                        onToggle: {
                            toggleCraneType(craneType.id)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var selectionSummary: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Types")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(selectedTypeIds.count) crane type\(selectedTypeIds.count == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedTypeIds.count > 0 {
                    Button("Clear All") {
                        selectedCraneTypes = []
                    }
                    .font(.subheadline)
                    .foregroundColor(.ksrError)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private func initializeSelection() {
        if selectedCraneTypes == nil {
            selectedCraneTypes = []
        }
    }
    
    private func toggleCraneType(_ typeId: Int) {
        var currentSelection = selectedCraneTypes ?? []
        
        if allowMultipleSelection {
            if currentSelection.contains(typeId) {
                currentSelection.removeAll { $0 == typeId }
            } else {
                currentSelection.append(typeId)
            }
        } else {
            currentSelection = currentSelection.contains(typeId) ? [] : [typeId]
        }
        
        selectedCraneTypes = currentSelection
    }
    
    private func saveSelection() {
        dismiss()
    }
}

struct RealCraneModelSelectorView: View {
    @Binding var selectedCraneModel: CraneModel?
    let filterByTypes: [Int]?
    
    @StateObject private var viewModel = CraneModelSelectorViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedBrandId: Int?
    
    init(selectedCraneModel: Binding<CraneModel?>, filterByTypes: [Int]? = nil) {
        self._selectedCraneModel = selectedCraneModel
        self.filterByTypes = filterByTypes
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filtersView
                
                if viewModel.isLoading && viewModel.craneModels.isEmpty {
                    loadingView
                } else if filteredCraneModels.isEmpty {
                    emptyStateView
                } else {
                    craneModelsList
                }
                
                if selectedCraneModel != nil {
                    currentSelectionView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Crane Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrYellow)
                }
            }
            .onAppear {
                viewModel.loadCraneModels(filterByTypes: filterByTypes)
                viewModel.loadBrands()
            }
        }
    }
    
    private var filteredCraneModels: [CraneModelAPIResponse] {
        var models = viewModel.craneModels
        
        if !searchText.isEmpty {
            models = models.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.code.localizedCaseInsensitiveContains(searchText) ||
                (model.brand_name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (model.type_name?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let brandId = selectedBrandId {
            models = models.filter { $0.brandId == brandId }
        }
        
        return models
    }
    
    private var filtersView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search crane models...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            if !viewModel.brands.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        BrandFilterChip(
                            title: "All Brands",
                            isSelected: selectedBrandId == nil,
                            onSelect: { selectedBrandId = nil }
                        )
                        
                        ForEach(viewModel.brands, id: \.id) { brand in
                            BrandFilterChip(
                                title: brand.name,
                                isSelected: selectedBrandId == brand.id,
                                onSelect: { selectedBrandId = brand.id }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading crane models...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.adjustable")
                .font(.system(size: 60))
                .foregroundColor(.ksrWarning.opacity(0.6))
            
            Text("No Crane Models Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            if searchText.isEmpty && selectedBrandId == nil {
                Text("No crane models are available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No models match your current filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Clear Filters") {
                    searchText = ""
                    selectedBrandId = nil
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.ksrYellow)
                .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var craneModelsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCraneModels, id: \.id) { craneModel in
                    CraneModelSelectionCard(
                        craneModel: craneModel,
                        isSelected: selectedCraneModel?.id == craneModel.id,
                        onSelect: {
                            selectedCraneModel = convertToCraneModel(craneModel)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var currentSelectionView: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Model")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let model = selectedCraneModel {
                        Text(model.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Clear") {
                    selectedCraneModel = nil
                }
                .font(.subheadline)
                .foregroundColor(.ksrError)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private func convertToCraneModel(_ apiModel: CraneModelAPIResponse) -> CraneModel {
        let modelDict: [String: Any] = [
            "id": apiModel.id,
            "brand_id": apiModel.brandId,
            "type_id": apiModel.typeId,
            "name": apiModel.name,
            "code": apiModel.code,
            "description": apiModel.description ?? NSNull(),
            "max_load_capacity": apiModel.maxLoadCapacity ?? NSNull(),
            "max_height": apiModel.maxHeight ?? NSNull(),
            "max_radius": apiModel.maxRadius ?? NSNull(),
            "engine_power": apiModel.enginePower ?? NSNull(),
            "specifications": NSNull(),
            "image_url": apiModel.imageUrl ?? NSNull(),
            "brochure_url": apiModel.brochureUrl ?? NSNull(),
            "video_url": apiModel.videoUrl ?? NSNull(),
            "release_year": apiModel.releaseYear ?? NSNull(),
            "is_discontinued": apiModel.isDiscontinued,
            "is_active": apiModel.isActive,
            "brand_name": apiModel.brand_name ?? NSNull(),
            "type_name": apiModel.type_name ?? NSNull()
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: modelDict)
            let decoder = JSONDecoder.ksrApiDecoder
            return try decoder.decode(CraneModel.self, from: jsonData)
        } catch {
            print("⚠️ Failed to convert CraneModelAPIResponse to CraneModel: \(error)")
            
            let fallbackDict: [String: Any] = [
                "id": apiModel.id,
                "brand_id": apiModel.brandId,
                "type_id": apiModel.typeId,
                "name": apiModel.name,
                "code": apiModel.code,
                "is_discontinued": false,
                "is_active": true
            ]
            
            do {
                let fallbackData = try JSONSerialization.data(withJSONObject: fallbackDict)
                return try JSONDecoder.ksrApiDecoder.decode(CraneModel.self, from: fallbackData)
            } catch {
                fatalError("Critical error: Cannot create CraneModel from API response. Error: \(error)")
            }
        }
    }
}

// MARK: - Supporting View Models

class CraneTypeSelectorViewModel: ObservableObject {
    @Published var craneTypes: [CraneTypeAPIResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadCraneTypes() {
        isLoading = true
        errorMessage = nil
        
        EquipmentAPIService.shared.fetchCraneTypes(includeModelsCount: true)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to load crane types: \(error.localizedDescription)"
                        print("❌ Failed to load crane types: \(error)")
                    }
                },
                receiveValue: { [weak self] types in
                    self?.craneTypes = types
                }
            )
            .store(in: &cancellables)
    }
}

class CraneModelSelectorViewModel: ObservableObject {
    @Published var craneModels: [CraneModelAPIResponse] = []
    @Published var brands: [CraneBrandAPIResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadCraneModels(filterByTypes: [Int]? = nil) {
        isLoading = true
        errorMessage = nil
        
        EquipmentAPIService.shared.fetchCraneModels()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to load crane models: \(error.localizedDescription)"
                        print("❌ Failed to load crane models: \(error)")
                    }
                },
                receiveValue: { [weak self] models in
                    if let filterTypes = filterByTypes, !filterTypes.isEmpty {
                        self?.craneModels = models.filter { model in
                            filterTypes.contains(model.typeId)
                        }
                    } else {
                        self?.craneModels = models
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadBrands() {
        EquipmentAPIService.shared.fetchCraneBrands()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load brands: \(error)")
                    }
                },
                receiveValue: { [weak self] brands in
                    self?.brands = brands
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Components

struct CraneTypeSelectionCard: View {
    let craneType: CraneTypeAPIResponse
    let isSelected: Bool
    let allowMultipleSelection: Bool
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                if let iconUrl = craneType.iconUrl, !iconUrl.isEmpty {
                    AsyncImage(url: URL(string: iconUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.ksrInfo)
                    }
                    .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.title2)
                        .foregroundColor(.ksrInfo)
                        .frame(width: 50, height: 50)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(craneType.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let description = craneType.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text(craneType.code)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrInfo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.ksrInfo.opacity(0.1))
                            )
                        
                        if let count = craneType._count?.craneModels {
                            Text("\(count) models")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .ksrSuccess : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrSuccess : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct CraneModelSelectionCard: View {
    let craneModel: CraneModelAPIResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "wrench.adjustable")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .ksrWarning)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.ksrWarning : Color.ksrWarning.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(craneModel.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let brandName = craneModel.brand_name {
                            Text(brandName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            Text(craneModel.code)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.ksrWarning)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.ksrWarning.opacity(0.1))
                                )
                            
                            if let typeName = craneModel.type_name {
                                Text(typeName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .ksrSuccess : .secondary)
                }
                
                if craneModel.maxLoadCapacity != nil || craneModel.maxHeight != nil || craneModel.maxRadius != nil {
                    HStack(spacing: 16) {
                        if let capacity = craneModel.maxLoadCapacity {
                            SpecificationView(
                                icon: "scalemass.fill",
                                label: "Capacity",
                                value: "\(capacity) t"
                            )
                        }
                        
                        if let height = craneModel.maxHeight {
                            SpecificationView(
                                icon: "arrow.up.to.line",
                                label: "Height",
                                value: "\(height) m"
                            )
                        }
                        
                        if let radius = craneModel.maxRadius {
                            SpecificationView(
                                icon: "arrow.left.and.right",
                                label: "Radius",
                                value: "\(radius) m"
                            )
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrWarning : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct BrandFilterChip: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.ksrYellow : Color(.systemGray5))
                )
        }
    }
}

struct SpecificationView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.ksrInfo)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}
