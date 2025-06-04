import SwiftUI

struct WeekDetailsModal: View {
    let taskWeekEntry: ManagerDashboardViewModel.TaskWeekEntry
    @Binding var isPresented: Bool
    let onApproveWeek: () -> Void
    let onRejectWeek: ([Int], String) -> Void  // [problematic entry IDs], reason
    
    @State private var showRejectionModal = false
    @State private var problematicEntries: Set<Int> = []
    @State private var rejectionReason = ""
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isRejectionReasonFocused: Bool
    
    private var sortedEntries: [ManagerAPIService.WorkHourEntry] {
        taskWeekEntry.entries.sorted { $0.work_date < $1.work_date }
    }
    
    private var totalHours: Double {
        taskWeekEntry.entries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with week info
                weekHeaderSection
                
                // Entries list (read-only preview)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Days in this week:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(sortedEntries, id: \.entry_id) { entry in
                                DayPreviewCard(entry: entry)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
                
                // Action buttons (approve entire week OR reject entire week)
                actionButtonsSection
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Week \(taskWeekEntry.weekNumber)/\(taskWeekEntry.year)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showRejectionModal) {
                rejectionModal
            }
        }
    }
    
    // MARK: - Week Header Section
    private var weekHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(taskWeekEntry.taskTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    if let employeeName = taskWeekEntry.entries.first?.employees?.name {
                        Text("Employee: \(employeeName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(taskWeekEntry.entries.count) entries")
                        .font(.subheadline)
                        .foregroundColor(Color.ksrWarning)
                        .fontWeight(.medium)
                    
                    Text("\(String(format: "%.1f", totalHours))h total")
                        .font(.subheadline)
                        .foregroundColor(Color.ksrWarning)
                        .fontWeight(.medium)
                }
            }
            
            if taskWeekEntry.totalKm > 0 {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                    Text("Total distance: \(String(format: "%.1f", taskWeekEntry.totalKm)) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Week summary stats
            HStack(spacing: 16) {
                StatBadge(
                    icon: "calendar.badge.checkmark",
                    label: "Week Status",
                    value: "Pending Review",
                    color: Color.ksrWarning
                )
                
                StatBadge(
                    icon: "clock.fill",
                    label: "Total Hours",
                    value: "\(String(format: "%.1f", totalHours))h",
                    color: Color.ksrInfo
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.ksrWarning.opacity(0.1), Color.ksrWarning.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Approve entire week
            Button {
                onApproveWeek()
                isPresented = false
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Approve Entire Week")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("All \(taskWeekEntry.entries.count) entries will be approved")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [Color.ksrSuccess, Color.ksrSuccess.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Reject entire week (with option to mark problematic days)
            Button {
                showRejectionModal = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reject Entire Week")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Mark problematic days and provide feedback")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color(.systemGray6).opacity(0.2))
    }
    
    // MARK: - Rejection Modal
    private var rejectionModal: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reject Entire Week")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("All entries will be returned for correction")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Week summary
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color.ksrWarning)
                            Text("Week \(taskWeekEntry.weekNumber), \(taskWeekEntry.year)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.orange)
                            Text("All \(taskWeekEntry.entries.count) entries will be rejected")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
                    )
                }
                
                Divider()
                
                // Mark problematic days section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mark Problematic Days (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Select which days have issues to help the employee focus on corrections:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(sortedEntries, id: \.entry_id) { entry in
                                ProblematicDayRow(
                                    entry: entry,
                                    isMarked: problematicEntries.contains(entry.entry_id),
                                    onToggle: {
                                        if problematicEntries.contains(entry.entry_id) {
                                            problematicEntries.remove(entry.entry_id)
                                        } else {
                                            problematicEntries.insert(entry.entry_id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                Divider()
                
                // Reason input
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rejection Reason")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Explain what needs to be corrected. Be specific to help the employee.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $rejectionReason)
                        .frame(height: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        )
                        .focused($isRejectionReasonFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(rejectionReason.isEmpty ? Color.red.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    if rejectionReason.isEmpty {
                        Text("Rejection reason is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reject Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showRejectionModal = false
                        rejectionReason = ""
                        problematicEntries.removeAll()
                        isRejectionReasonFocused = false
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reject Week") {
                        onRejectWeek(Array(problematicEntries), rejectionReason)
                        showRejectionModal = false
                        rejectionReason = ""
                        problematicEntries.removeAll()
                        isPresented = false
                        isRejectionReasonFocused = false
                    }
                    .disabled(rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                isRejectionReasonFocused = true
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Day Preview Card (Read-only)
struct DayPreviewCard: View {
    let entry: ManagerAPIService.WorkHourEntry
    @Environment(\.colorScheme) private var colorScheme
    
    private var entryHours: Double {
        guard let start = entry.start_time, let end = entry.end_time else { return 0 }
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: entry.work_date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Day indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.ksrInfo)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.ksrInfo.opacity(0.3))
                    .frame(width: 2, height: 40)
            }
            
            // Day info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayOfWeek)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text(entry.workDateFormatted)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(String(format: "%.1f", entryHours))h")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.ksrWarning)
                        
                        if let start = entry.startTimeFormatted, let end = entry.endTimeFormatted {
                            Text("\(start) - \(end)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Additional details
                HStack(spacing: 16) {
                    if let pauseMinutes = entry.pause_minutes, pauseMinutes > 0 {
                        Label("\(pauseMinutes) min", systemImage: "pause.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let km = entry.km, km > 0 {
                        Label("\(String(format: "%.1f", km)) km", systemImage: "car.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    let displayStatus = entry.status?.capitalized ?? "Pending"
                    Text(displayStatus)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ksrWarning.opacity(0.2))
                        .foregroundColor(Color.ksrWarning)
                        .cornerRadius(4)
                }
                
                if let description = entry.description, !description.isEmpty {
                    Text("Notes: \(description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Problematic Day Row (for rejection modal)
struct ProblematicDayRow: View {
    let entry: ManagerAPIService.WorkHourEntry
    let isMarked: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: entry.work_date)
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isMarked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(isMarked ? .red : .secondary)
                
                // Day info
                HStack {
                    Text(dayOfWeek)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .frame(width: 30, alignment: .leading)
                    
                    Text(entry.workDateFormatted)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let start = entry.startTimeFormatted, let end = entry.endTimeFormatted {
                        Text("\(start)-\(end)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isMarked ? Color.red.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isMarked ? Color.red.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge Component
struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// Extensions już istnieją w WorkHourEntry+Extensions.swift
