//
//  WorkerDetailView.swift
//  KSR Cranes App
//  Detailed view for individual worker management
//

import SwiftUI

struct WorkerDetailView: View {
    let worker: WorkerForChef
    @ObservedObject var viewModel: ChefWorkersViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditWorker = false
    @State private var showingStatusSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDocumentManager = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with profile
                workerHeaderSection
                
                // Quick Actions
                quickActionsSection
                
                // Documents Section
                documentsSection
                
                // Stats Overview
                if let stats = worker.stats {
                    statsOverviewSection(stats)
                }
                
                // Certificates Section
                if let certificates = worker.certificates, !certificates.isEmpty {
                    certificatesSection(certificates)
                }
                
                // Employment Information
                employmentInfoSection
                
                // Contact Information
                contactInfoSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(backgroundGradient)
        .navigationTitle(worker.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: 
            Menu {
                Button {
                    showingEditWorker = true
                } label: {
                    Label("Edit Worker", systemImage: "pencil")
                }
                
                Button {
                    showingStatusSheet = true
                } label: {
                    Label("Change Status", systemImage: "person.circle")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Worker", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
        )
        .sheet(isPresented: $showingEditWorker) {
            EditWorkerView(worker: worker) { updatedWorker in
                viewModel.updateWorker(updatedWorker)
            }
        }
        .confirmationDialog("Change Worker Status", isPresented: $showingStatusSheet) {
            ForEach(WorkerStatus.allCases, id: \.self) { status in
                if status != worker.status {
                    Button(status.displayName) {
                        viewModel.updateWorkerStatus(worker, newStatus: status)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Delete Worker", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteWorker(worker)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(worker.name)? This action cannot be undone.")
        }
        .sheet(isPresented: $showingDocumentManager) {
            WorkerDocumentManagerView(worker: worker)
        }
    }
    
    // MARK: - Header Section
    
    private var workerHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Image and Basic Info
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.ksrLightGray)
                        .frame(width: 100, height: 100)
                    
                    if let profileUrl = worker.profile_picture_url, !profileUrl.isEmpty {
                        AsyncImage(url: URL(string: profileUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Text(worker.initials)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                    } else {
                        Text(worker.initials)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(worker.status.color, lineWidth: 3)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(worker.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    HStack {
                        Label(worker.statusDisplayName, systemImage: worker.status.systemImage)
                            .font(.subheadline)
                            .foregroundColor(worker.status.color)
                    }
                    
                    Text(worker.employmentDisplayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(worker.hourly_rate)) DKK/hour")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ksrWarning)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                WorkerQuickActionButton(
                    title: "Edit Info",
                    icon: "pencil.circle.fill",
                    color: Color.ksrInfo
                ) {
                    showingEditWorker = true
                }
                
                WorkerQuickActionButton(
                    title: "Change Status",
                    icon: "person.circle.fill",
                    color: Color.ksrPrimary
                ) {
                    showingStatusSheet = true
                }
                
                WorkerQuickActionButton(
                    title: "View Tasks",
                    icon: "list.bullet.circle.fill",
                    color: Color.ksrSuccess
                ) {
                    // TODO: Navigate to worker tasks
                }
                
                WorkerQuickActionButton(
                    title: "Timesheet",
                    icon: "clock.circle.fill",
                    color: Color.ksrWarning
                ) {
                    // TODO: Navigate to worker timesheet
                }
            }
        }
    }
    
    // MARK: - Documents Section
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documents")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                .padding(.horizontal, 4)
            
            Button {
                showingDocumentManager = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color.ksrPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.ksrPrimary.opacity(0.2))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manage Documents")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text("Upload, view, and organize worker documents")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
    
    // MARK: - Stats Overview
    
    private func statsOverviewSection(_ stats: WorkerQuickStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(
                    title: "This Week",
                    value: "\(stats.hoursThisWeekFormatted)h",
                    icon: "clock.fill",
                    color: Color.ksrInfo
                )
                
                StatCard(
                    title: "This Month",
                    value: "\(String(format: "%.1f", stats.hours_this_month ?? 0))h",
                    icon: "calendar.circle.fill",
                    color: Color.ksrSuccess
                )
                
                StatCard(
                    title: "Active Tasks",
                    value: "\(stats.active_tasks ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: Color.ksrSuccess
                )
                
                StatCard(
                    title: "Approval Rate",
                    value: "\(stats.approvalRatePercentage)%",
                    icon: "checkmark.circle.fill",
                    color: Color.ksrWarning
                )
            }
        }
    }
    
    // MARK: - Employment Information
    
    private var employmentInfoSection: some View {
        InfoSection(title: "Employment Information", icon: "briefcase.fill") {
            VStack(spacing: 16) {
                InfoRow(
                    title: "Employment Type",
                    value: worker.employmentDisplayName,
                    icon: "briefcase.fill"
                )
                
                InfoRow(
                    title: "Hourly Rate",
                    value: "\(Int(worker.hourly_rate)) DKK",
                    icon: "banknote.fill"
                )
                
                InfoRow(
                    title: "Status",
                    value: worker.statusDisplayName,
                    icon: worker.status.systemImage,
                    valueColor: worker.status.color
                )
                
                InfoRow(
                    title: "Start Date",
                    value: DateFormatter.shortDate.string(from: worker.created_at),
                    icon: "calendar.badge.plus"
                )
                
                if let lastActive = worker.last_active {
                    InfoRow(
                        title: "Last Active",
                        value: DateFormatter.shortDate.string(from: lastActive),
                        icon: "clock.arrow.circlepath"
                    )
                }
            }
        }
    }
    
    // MARK: - Contact Information
    
    private var contactInfoSection: some View {
        InfoSection(title: "Contact Information", icon: "person.crop.circle.fill") {
            VStack(spacing: 16) {
                InfoRow(
                    title: "Email",
                    value: worker.email,
                    icon: "envelope.fill"
                )
                
                if let phone = worker.phone {
                    InfoRow(
                        title: "Phone",
                        value: phone,
                        icon: "phone.fill"
                    )
                }
                
                if let address = worker.address {
                    InfoRow(
                        title: "Address",
                        value: address,
                        icon: "location.fill"
                    )
                }
            }
        }
    }
    
    // MARK: - Certificates Section
    
    private func certificatesSection(_ certificates: [WorkerCertificate]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.ksrPrimary)
                
                Text("Certificates & Qualifications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            
            VStack(spacing: 12) {
                ForEach(certificates) { certificate in
                    HStack(spacing: 12) {
                        // Certificate icon
                        Image(systemName: certificate.icon)
                            .font(.system(size: 24))
                            .foregroundColor(certificate.color)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(certificate.color.opacity(0.1))
                            )
                        
                        // Certificate info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(certificate.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            
                            HStack(spacing: 8) {
                                // Status
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(certificate.statusColor)
                                        .frame(width: 6, height: 6)
                                    Text(certificate.statusText)
                                        .font(.caption)
                                        .foregroundColor(certificate.statusColor)
                                }
                                
                                if certificate.certificationExpires != nil {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Expires: \(certificate.expiryDateFormatted)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if certificate.yearsExperience > 0 {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(certificate.yearsExperience) years exp")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
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

// MARK: - Supporting Components

struct WorkerQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 4, x: 0, y: 2)
        )
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.ksrPrimary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor == .primary ? (colorScheme == .dark ? .white : .primary) : valueColor)
            }
            
            Spacer()
        }
    }
}



// MARK: - Preview

struct WorkerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkerDetailView(
                worker: WorkerForChef(
                    id: 1,
                    name: "Preview Worker",
                    email: "preview@ksrcranes.dk",
                    phone: "+45 12345678",
                    address: "Preview Address",
                    hourly_rate: 400.0,
                    employment_type: .fuld_tid,
                    role: .arbejder,
                    status: .aktiv,
                    profile_picture_url: nil,
                    created_at: Date(),
                    last_active: Date(),
                    stats: WorkerQuickStats(
                        hours_this_week: 38.5,
                        hours_this_month: 165.0,
                        active_tasks: 2,
                        completed_tasks: 15,
                        total_tasks: 17,
                        approval_rate: 0.95,
                        last_timesheet_date: Date()
                    )
                ),
                viewModel: ChefWorkersViewModel()
            )
        }
        .preferredColorScheme(.light)
    }
}