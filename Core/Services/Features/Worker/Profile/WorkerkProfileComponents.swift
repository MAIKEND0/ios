// Features/Worker/Profile/WorkerProfileComponents.swift
import SwiftUI

// MARK: - Worker Stat Card
struct WorkerStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Worker Profile Tab Button
struct WorkerProfileTabButton: View {
    let tab: WorkerProfileView.ProfileTab
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? tab.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Worker Profile Section Card
struct WorkerProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Worker App Info Row
struct WorkerAppInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Worker Task Card
struct WorkerTaskCard: View {
    let task: WorkerAPIService.Task
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                
                if let project = task.project {
                    Text(project.title)
                        .font(.caption)
                        .foregroundColor(.ksrInfo)
                }
                
                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let deadline = task.deadline {
                    let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                    Text("\(daysUntilDeadline) days")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(daysUntilDeadline < 3 ? Color.ksrError.opacity(0.2) : Color.ksrSuccess.opacity(0.2))
                        )
                        .foregroundColor(daysUntilDeadline < 3 ? .ksrError : .ksrSuccess)
                }
                
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.ksrSuccess)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Worker Work Entry Row
struct WorkerWorkEntryRow: View {
    let entry: WorkerAPIService.WorkHourEntry
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ FORMATTER POZA ViewBuilder
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatter.string(from: entry.work_date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(entry.tasks?.title ?? "Unknown Task")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let start = entry.start_time, let end = entry.end_time {
                    let hours = end.timeIntervalSince(start) / 3600
                    let pauseHours = Double(entry.pause_minutes ?? 0) / 60
                    let workHours = max(0, hours - pauseHours)
                    
                    Text(String(format: "%.1fh", workHours))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrInfo)
                } else {
                    Text("0.0h")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrMediumGray)
                }
                
                let statusText = entry.confirmation_status?.capitalized ?? "Draft"
                let statusColor = getStatusColor(entry.confirmation_status)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor.opacity(0.2))
                    )
                    .foregroundColor(statusColor)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getStatusColor(_ status: String?) -> Color {
        switch status {
        case "confirmed": return .ksrSuccess
        case "rejected": return .ksrError
        case "submitted": return .ksrWarning
        default: return .ksrMediumGray
        }
    }
}

// MARK: - Tab Content Views
struct WorkerOverviewTab: View {
    @ObservedObject var viewModel: WorkerProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            WorkerProfileSectionCard(title: "Personal Information", icon: "person.fill", color: .ksrYellow) {
                VStack(alignment: .leading, spacing: 12) {
                    WorkerAppInfoRow(label: "Employee ID", value: "\(viewModel.basicData.employeeId)")
                    WorkerAppInfoRow(label: "Email", value: viewModel.basicData.email)
                    if let phone = viewModel.basicData.phoneNumber {
                        WorkerAppInfoRow(label: "Phone", value: phone)
                    }
                    if let address = viewModel.basicData.address {
                        WorkerAppInfoRow(label: "Address", value: address)
                    }
                }
            }
            
            WorkerProfileSectionCard(title: "Work Summary", icon: "chart.bar.fill", color: .ksrInfo) {
                VStack(spacing: 12) {
                    WorkerAppInfoRow(label: "This Week", value: viewModel.stats.weeklyHoursFormatted + "h")
                    WorkerAppInfoRow(label: "This Month", value: viewModel.stats.monthlyHoursFormatted + "h")
                    WorkerAppInfoRow(label: "Approval Rate", value: viewModel.approvalRateFormatted)
                }
            }
        }
        .padding(.top, 20)
    }
}

struct WorkerTasksTab: View {
    @ObservedObject var viewModel: WorkerProfileViewModel
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            WorkerProfileSectionCard(title: "Task Summary", icon: "list.bullet", color: .ksrInfo) {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(viewModel.currentTasks.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ksrInfo)
                        Text("Total Tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            if !viewModel.recentTasksForDisplay.isEmpty {
                WorkerProfileSectionCard(title: "Current Tasks", icon: "play.circle", color: .ksrSuccess) {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.recentTasksForDisplay) { task in
                            WorkerTaskCard(task: task)
                        }
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

struct WorkerHoursTab: View {
    @ObservedObject var viewModel: WorkerProfileViewModel
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            WorkerProfileSectionCard(title: "Hours Summary", icon: "clock.fill", color: .ksrSuccess) {
                VStack(spacing: 12) {
                    WorkerAppInfoRow(label: "This Week", value: viewModel.stats.weeklyHoursFormatted + "h")
                    WorkerAppInfoRow(label: "This Month", value: viewModel.stats.monthlyHoursFormatted + "h")
                    WorkerAppInfoRow(label: "Pending Approvals", value: "\(viewModel.stats.pendingEntries)")
                    WorkerAppInfoRow(label: "Approval Rate", value: viewModel.approvalRateFormatted)
                }
            }
            
            if !viewModel.recentWorkEntriesForDisplay.isEmpty {
                WorkerProfileSectionCard(title: "Recent Entries", icon: "clock.badge.fill", color: .ksrInfo) {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.recentWorkEntriesForDisplay) { entry in
                            WorkerWorkEntryRow(entry: entry)
                        }
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

struct WorkerSettingsTab: View {
    @Binding var showingLogoutConfirmation: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            WorkerProfileSectionCard(title: "App Information", icon: "info.circle", color: .ksrInfo) {
                VStack(alignment: .leading, spacing: 12) {
                    WorkerAppInfoRow(label: "Version", value: "1.0.0")
                    WorkerAppInfoRow(label: "Build", value: "2025.05.24")
                    WorkerAppInfoRow(label: "Last Updated", value: "May 24, 2025")
                }
            }
            
            WorkerProfileSectionCard(title: "Account", icon: "person.circle", color: .ksrError) {
                Button(action: {
                    showingLogoutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.ksrError)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Logout")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrError)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Edit Profile View (UŻYWA PATTERN'U Z MANAGER PROFILE)
struct WorkerEditProfileView: View {
    @ObservedObject var viewModel: WorkerProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var editableData: WorkerBasicData
    @State private var isUpdating = false
    
    init(viewModel: WorkerProfileViewModel) {
        self.viewModel = viewModel
        self._editableData = State(initialValue: viewModel.basicData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Address", text: Binding(
                        get: { editableData.address ?? "" },
                        set: { editableData.address = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("Phone Number", text: Binding(
                        get: { editableData.phoneNumber ?? "" },
                        set: { editableData.phoneNumber = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("Emergency Contact", text: Binding(
                        get: { editableData.emergencyContact ?? "" },
                        set: { editableData.emergencyContact = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Worker Details")) {
                    WorkerAppInfoRow(label: "Employee ID", value: "\(editableData.employeeId)")
                    WorkerAppInfoRow(label: "Email", value: editableData.email)
                    WorkerAppInfoRow(label: "Role", value: "Crane Operator")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveChanges() }.disabled(isUpdating)
            )
            .disabled(isUpdating)
            .overlay(
                Group {
                    if isUpdating {
                        ProgressView("Updating...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
        }
    }
    
    private func saveChanges() {
        isUpdating = true
        viewModel.updateProfile(editableData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isUpdating = false
            dismiss()
        }
    }
}
