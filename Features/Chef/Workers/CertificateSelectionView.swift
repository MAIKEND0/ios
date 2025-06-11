//
//  CertificateSelectionView.swift
//  KSR Cranes App
//  Certificate selection interface for worker creation/editing
//

import SwiftUI

struct CertificateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = CertificateSelectionViewModel()
    
    let selectedStates: [CertificateSelectionState]
    let onSave: ([CertificateSelectionState]) -> Void
    let title: String
    
    init(selectedStates: [CertificateSelectionState], onSave: @escaping ([CertificateSelectionState]) -> Void, title: String = "Manage Certificates") {
        self.selectedStates = selectedStates
        self.onSave = onSave
        self.title = title
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.certificateTypes.isEmpty {
                    emptyStateView
                } else {
                    certificateListView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave(viewModel.selectionStates)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await viewModel.loadCertificateTypes()
                viewModel.updateExistingSelections(selectedStates)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading certificates...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Certificates Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No certificate types are currently configured in the system.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Certificate List View
    
    private var certificateListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                headerSection
                
                // Certificate Types
                ForEach(viewModel.certificateTypes) { certificateType in
                    CertificateSelectionCard(
                        certificateType: certificateType,
                        selectionState: getSelectionState(for: certificateType),
                        onSelectionChanged: { state in
                            updateSelectionState(state)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(backgroundGradient)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.ksrPrimary)
                
                Text("Danish Crane Certificates")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            
            Text("Select the certificates this worker possesses according to Danish regulations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Methods
    
    private func getSelectionState(for certificateType: CertificateType) -> CertificateSelectionState {
        return viewModel.selectionStates.first { $0.certificateType.id == certificateType.id } 
            ?? CertificateSelectionState(certificateType: certificateType)
    }
    
    private func updateSelectionState(_ state: CertificateSelectionState) {
        if let index = viewModel.selectionStates.firstIndex(where: { $0.certificateType.id == state.certificateType.id }) {
            viewModel.selectionStates[index] = state
        } else {
            viewModel.selectionStates.append(state)
        }
    }
    
    
    // MARK: - Background
    
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

// MARK: - Certificate Selection Card

struct CertificateSelectionCard: View {
    let certificateType: CertificateType
    @State var selectionState: CertificateSelectionState
    let onSelectionChanged: (CertificateSelectionState) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Certificate Card
            certificateHeaderCard
            
            // Expandable Details Section
            if showingDetails && selectionState.isSelected {
                certificateDetailsSection
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selectionState.isSelected ? certificateType.color : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: selectionState.isSelected)
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
    
    // MARK: - Certificate Header Card
    
    private var certificateHeaderCard: some View {
        HStack(spacing: 16) {
            // Certificate Icon
            ZStack {
                Circle()
                    .fill(certificateType.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: certificateType.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(certificateType.color)
            }
            
            // Certificate Info
            VStack(alignment: .leading, spacing: 4) {
                Text(certificateType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Text(certificateType.code)
                    .font(.subheadline)
                    .foregroundColor(certificateType.color)
                    .fontWeight(.medium)
                
                if let description = certificateType.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Selection Toggle
            Button {
                selectionState.isSelected.toggle()
                if selectionState.isSelected {
                    showingDetails = true
                } else {
                    showingDetails = false
                    // Reset details when deselected
                    selectionState.isCertified = true // Keep as certified by default
                    selectionState.certificationExpires = nil
                    selectionState.yearsExperience = 0
                    selectionState.skillLevel = .expert
                    selectionState.certificationNumber = ""
                    selectionState.notes = ""
                }
                onSelectionChanged(selectionState)
            } label: {
                Image(systemName: selectionState.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectionState.isSelected ? certificateType.color : .secondary)
            }
        }
        .padding(20)
        .contentShape(Rectangle())
        .onTapGesture {
            selectionState.isSelected.toggle()
            if selectionState.isSelected {
                showingDetails = true
            } else {
                showingDetails = false
            }
            onSelectionChanged(selectionState)
        }
    }
    
    // MARK: - Certificate Details Section
    
    private var certificateDetailsSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Certified Toggle
                HStack {
                    Text("Currently Certified")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Toggle("", isOn: $selectionState.isCertified)
                        .onChange(of: selectionState.isCertified) {
                            onSelectionChanged(selectionState)
                        }
                }
                
                if selectionState.isCertified {
                    // Certification Number
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Certification Number")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter certification number...", text: $selectionState.certificationNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: selectionState.certificationNumber) {
                                onSelectionChanged(selectionState)
                            }
                    }
                    
                    // Expiry Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expiry Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        DatePicker(
                            "Expiry Date",
                            selection: Binding(
                                get: { selectionState.certificationExpires ?? Date().addingTimeInterval(365 * 24 * 60 * 60) },
                                set: { selectionState.certificationExpires = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .onChange(of: selectionState.certificationExpires) {
                            onSelectionChanged(selectionState)
                        }
                    }
                }
                
                // Years of Experience
                VStack(alignment: .leading, spacing: 8) {
                    Text("Years of Experience: \(selectionState.yearsExperience)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Slider(
                        value: Binding(
                            get: { Double(selectionState.yearsExperience) },
                            set: { 
                                selectionState.yearsExperience = Int($0)
                                print("[CertificateSelectionView] 📊 Slider set years experience to: \(Int($0))")
                            }
                        ),
                        in: 0...30,
                        step: 1
                    )
                    .accentColor(certificateType.color)
                    .onChange(of: selectionState.yearsExperience) {
                        print("[CertificateSelectionView] 📊 Years experience changed to: \(selectionState.yearsExperience)")
                        onSelectionChanged(selectionState)
                    }
                }
                
                // Skill Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Skill Level", selection: $selectionState.skillLevel) {
                        ForEach(CertificateSkillLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                Text(level.displayName)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectionState.skillLevel) {
                        onSelectionChanged(selectionState)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Additional notes...", text: $selectionState.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .onChange(of: selectionState.notes) {
                            onSelectionChanged(selectionState)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Preview

struct CertificateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CertificateSelectionView(
            selectedStates: [],
            onSave: { updatedStates in
                print("Preview: Updated certificates: \(updatedStates.count)")
            }
        )
        .preferredColorScheme(.light)
    }
}