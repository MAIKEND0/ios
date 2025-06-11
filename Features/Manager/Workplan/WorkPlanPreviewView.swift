//
//  WorkPlanPreviewView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 21/05/2025.
//  Updated to fix type errors on 21/05/2025.
//  Updated to display only day of week in Employees and Schedule on 22/05/2025.
//  Fixed timezone issue in Calendar for date calculation on 22/05/2025.
//  Beautiful redesign on 23/05/2025.
//

import SwiftUI

struct WorkPlanPreviewView<VM: WorkPlanViewModel & WeekSelectorViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var isPresented: Bool
    let onConfirm: (() -> Void)?
    let isReadOnly: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: VM, isPresented: Binding<Bool>, onConfirm: (() -> Void)? = nil, isReadOnly: Bool = false) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.onConfirm = onConfirm
        self.isReadOnly = isReadOnly
    }

    // Formatter do wyświetlania nazwy dnia tygodnia
    private let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Pełna nazwa dnia, np. Monday
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        return formatter
    }()

    // Calendar z ustawionym UTC
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC
        return calendar
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section z gradientem
                    headerSection
                    
                    // Main Content
                    VStack(spacing: 20) {
                        // Week Section
                        weekSection
                        
                        // Employees and Schedule
                        employeesSection
                        
                        // Description and Additional Info
                        if !viewModel.description.isEmpty || !viewModel.additionalInfo.isEmpty {
                            detailsSection
                        }
                        
                        // Attachment Section
                        if viewModel.attachment != nil {
                            attachmentSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color.black : Color(.systemBackground),
                        colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.secondarySystemBackground).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle(isReadOnly ? "Work Plan Details" : "Work Plan Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isReadOnly ? "Close" : "Edit") {
                        isPresented = false
                    }
                    .foregroundColor(isReadOnly ? .blue : .orange)
                    .fontWeight(.semibold)
                }
                
                if !isReadOnly, let confirmAction = onConfirm {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Confirm") {
                            confirmAction()
                            isPresented = false
                        }
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.ksrYellow,
                    Color.ksrYellow.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
            
            // Content
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Title
                Text(isReadOnly ? "Work Plan Details" : "Work Plan Preview")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text(isReadOnly ? "View work plan details and schedule" : "Review your work plan before publishing")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
        }
        .frame(height: 220)
    }
    
    // MARK: - Week Section
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("WEEK SCHEDULE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            Text(viewModel.weekRangeText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Employees Section
    private var employeesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.ksrYellow)
                
                Text("EMPLOYEES & SCHEDULE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Spacer()
                
                Text("\(viewModel.assignments.count) \(viewModel.assignments.count == 1 ? "employee" : "employees")")
                    .font(.caption)
                    .foregroundColor(Color.ksrYellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ksrYellow.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if viewModel.assignments.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No employees assigned")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Add employees to your work plan to see their schedules here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Employee cards
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.assignments) { assignment in
                        EmployeePreviewCard(
                            assignment: assignment,
                            calendar: calendar,
                            dayOfWeekFormatter: dayOfWeekFormatter,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                
                Text("ADDITIONAL DETAILS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            if !viewModel.description.isEmpty {
                WorkPlanDetailRow(
                    title: "Description",
                    content: viewModel.description,
                    icon: "text.alignleft",
                    color: .blue
                )
            }
            
            if !viewModel.additionalInfo.isEmpty {
                WorkPlanDetailRow(
                    title: "Additional Information",
                    content: viewModel.additionalInfo,
                    icon: "plus.circle",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Attachment Section
    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paperclip.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Text("ATTACHMENT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            if let attachment = viewModel.attachment {
                HStack(spacing: 12) {
                    // File icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                    
                    // File info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attachment.fileName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Document attached")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Ready")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.tertiarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Employee Preview Card
struct EmployeePreviewCard: View {
    let assignment: WorkPlanAssignment
    let calendar: Calendar
    let dayOfWeekFormatter: DateFormatter
    let colorScheme: ColorScheme
    
    private var employeeName: String {
        assignment.availableEmployees.first { $0.employee_id == assignment.employee_id }?.name ?? "Unknown Employee"
    }
    
    private var activeSchedule: [(day: String, startTime: String, endTime: String)] {
        assignment.dailyHours.enumerated().compactMap { index, hours in
            guard hours.isActive else { return nil }
            let date = calendar.date(byAdding: .day, value: index, to: assignment.weekStart)!
            let dayName = dayOfWeekFormatter.string(from: date)
            return (
                day: dayName,
                startTime: DateFormatter.time.string(from: hours.start_time),
                endTime: DateFormatter.time.string(from: hours.end_time)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Employee header
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ksrYellow, Color.ksrYellow.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.ksrYellow.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Employee info
                VStack(alignment: .leading, spacing: 4) {
                    Text(employeeName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(activeSchedule.count) working \(activeSchedule.count == 1 ? "day" : "days")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Assigned")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Schedule
            if !activeSchedule.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SCHEDULE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Array(activeSchedule.enumerated()), id: \.offset) { _, schedule in
                            ScheduleDayCard(
                                day: schedule.day,
                                startTime: schedule.startTime,
                                endTime: schedule.endTime,
                                colorScheme: colorScheme
                            )
                        }
                    }
                }
            }
            
            // Notes
            if !assignment.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTES")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(assignment.notes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.quaternarySystemFill))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color(.systemGray5).opacity(0.4) : Color.white,
                            colorScheme == .dark ? Color(.systemGray5).opacity(0.2) : Color(.secondarySystemBackground).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.ksrYellow.opacity(0.2), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Schedule Day Card
struct ScheduleDayCard: View {
    let day: String
    let startTime: String
    let endTime: String
    let colorScheme: ColorScheme
    
    private var dayColor: Color {
        switch day.lowercased() {
        case "monday": return .blue
        case "tuesday": return .green
        case "wednesday": return .orange
        case "thursday": return .purple
        case "friday": return .pink
        case "saturday": return .red
        case "sunday": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Day indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(dayColor)
                    .frame(width: 6, height: 6)
                
                Text(String(day.prefix(3)).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(dayColor)
                    .tracking(0.5)
            }
            
            // Time
            Text("\(startTime) - \(endTime)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(dayColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(dayColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Detail Row
struct WorkPlanDetailRow: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(title.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(color.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

struct WorkPlanPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        WorkPlanPreviewView(
            viewModel: CreateWorkPlanViewModel(),
            isPresented: .constant(true),
            onConfirm: {},
            isReadOnly: false
        )
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode - Creator")
        
        WorkPlanPreviewView(
            viewModel: CreateWorkPlanViewModel(),
            isPresented: .constant(true),
            isReadOnly: true
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode - Read Only")
    }
}
