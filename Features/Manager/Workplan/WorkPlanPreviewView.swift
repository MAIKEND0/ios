//
//  WorkPlanPreviewView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 21/05/2025.
//  Updated to fix type errors on 21/05/2025.
//  Updated to display only day of week in Employees and Schedule on 22/05/2025.
//  Added debug logging for work_date in Employees and Schedule on 22/05/2025.
//  Fixed timezone issue in Calendar for date calculation on 22/05/2025.
//

import SwiftUI

struct WorkPlanPreviewView<VM: WorkPlanViewModel & WeekSelectorViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @Environment(\.colorScheme) private var colorScheme

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
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    Text("Work Plan Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    // Week
                    Text("Week: \(viewModel.weekRangeText)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    // Employees and Schedule
                    employeesSection
                        .padding(.horizontal)

                    // Description
                    if !viewModel.description.isEmpty {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        Text(viewModel.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    // Additional Info
                    if !viewModel.additionalInfo.isEmpty {
                        Text("Additional Info")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        Text(viewModel.additionalInfo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    // Attachment
                    if let attachment = viewModel.attachment {
                        Text("Attachment")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        Text(attachment.fileName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Edit") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Confirm") {
                        onConfirm()
                        isPresented = false
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }

    private var employeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Employees and Schedule")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if viewModel.assignments.isEmpty {
                Text("No employees assigned")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(viewModel.assignments) { assignment in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(assignment.availableEmployees.first { $0.employee_id == assignment.employee_id }?.name ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        ForEach(assignment.dailyHours.indices.filter { assignment.dailyHours[$0].isActive }, id: \.self) { index in
                            let date = calendar.date(byAdding: .day, value: index, to: assignment.weekStart)!
                            let hours = assignment.dailyHours[index]
                            // Log debugujący
                            Text("Debug date: \(DateFormatter.isoDate.string(from: date)) -> \(dayOfWeekFormatter.string(from: date))")
                                .font(.caption)
                                .foregroundColor(.red)
                                .italic()
                            Text("\(dayOfWeekFormatter.string(from: date)): \(DateFormatter.time.string(from: hours.start_time)) - \(DateFormatter.time.string(from: hours.end_time))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !assignment.notes.isEmpty {
                            Text("Notes: \(assignment.notes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct WorkPlanPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        WorkPlanPreviewView(
            viewModel: CreateWorkPlanViewModel(),
            isPresented: .constant(true),
            onConfirm: {}
        )
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        WorkPlanPreviewView(
            viewModel: CreateWorkPlanViewModel(),
            isPresented: .constant(true),
            onConfirm: {}
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
