
//
//  CertificateSelectionView.swift
//  KSR Cranes App
//  Certificate selection interface for task creation
//

import SwiftUI

struct TaskCertificateSelectionView: View {
    @Binding var selectedCertificates: [CertificateType]
    @Binding var isPresented: Bool
    let availableCertificates: [CertificateType]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    
    var filteredCertificates: [CertificateType] {
        if searchText.isEmpty {
            return availableCertificates
        }
        
        let lowercasedSearch = searchText.lowercased()
        return availableCertificates.filter { certificate in
            certificate.nameEn.lowercased().contains(lowercasedSearch) ||
            certificate.nameDa.lowercased().contains(lowercasedSearch) ||
            certificate.code.lowercased().contains(lowercasedSearch) ||
            (certificate.description?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search certificates...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Certificate list
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCertificates) { certificate in
                            TaskCertificateRow(
                                certificate: certificate,
                                isSelected: selectedCertificates.contains { $0.id == certificate.id },
                                onToggle: { toggleCertificate(certificate) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Selected count
                    if !selectedCertificates.isEmpty {
                        HStack {
                            Text("\(selectedCertificates.count) certificate(s) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Clear All") {
                                selectedCertificates.removeAll()
                            }
                            .font(.subheadline)
                            .foregroundColor(.ksrError)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Select Required Certificates")
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
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrYellow)
                }
            }
        }
    }
    
    private func toggleCertificate(_ certificate: CertificateType) {
        if let index = selectedCertificates.firstIndex(where: { $0.id == certificate.id }) {
            selectedCertificates.remove(at: index)
        } else {
            selectedCertificates.append(certificate)
        }
    }
}

// MARK: - Certificate Selection Row

struct TaskCertificateRow: View {
    let certificate: CertificateType
    let isSelected: Bool
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Certificate icon
                Image(systemName: certificate.icon)
                    .font(.title2)
                    .foregroundColor(certificate.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(certificate.color.opacity(0.1))
                    )
                
                // Certificate info
                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.nameEn)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(certificate.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let description = certificate.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .ksrSuccess : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ksrSuccess : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct TaskCertificateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TaskCertificateSelectionView(
            selectedCertificates: .constant([]),
            isPresented: .constant(true),
            availableCertificates: []
        )
    }
}
