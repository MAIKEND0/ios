//
//  WeekDetailView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import SwiftUI

struct WeekDetailView: View {
    let taskWeekEntry: ManagerDashboardViewModel.TaskWeekEntry
    let onApproveWithSignature: () -> Void
    let onReject: (ManagerAPIService.WorkHourEntry) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Nagłówek tygodnia
                HStack {
                    Text("Week \(taskWeekEntry.weekNumber), \(String(taskWeekEntry.year))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    Spacer()
                    if taskWeekEntry.canBeConfirmed {
                        Button(action: onApproveWithSignature) {
                            Text("Approve with Signature")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        .disabled(taskWeekEntry.entries.allSatisfy { $0.confirmation_status == "confirmed" })
                    }
                }

                // Lista wpisów
                ForEach(taskWeekEntry.entries) { entry in
                    entryCard(entry: entry)
                }
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
        .navigationTitle("Week Details")
    }

    private func entryCard(entry: ManagerAPIService.WorkHourEntry) -> some View {
        let hours = computeEntryDuration(
            start: entry.start_time,
            end: entry.end_time,
            pauseMinutes: entry.pause_minutes ?? 0
        )
        // Mapowanie statusu na poprawną wartość
        let displayStatus = {
            let statusString = entry.status?.lowercased() ?? "pending"
            return statusString == "submitte" ? "Submitted" : (["draft", "pending", "submitted", "confirmed", "rejected"].contains(statusString) ? statusString.capitalized : "Pending")
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.workDateFormatted)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text("\(hours, specifier: "%.2f")h")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrYellow)
            }
            HStack {
                Text("\(entry.startTimeFormatted ?? "-") – \(entry.endTimeFormatted ?? "-")")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                Spacer()
                Text(displayStatus)
                    .font(.caption2)
                    .bold()
                    .padding(4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(4)
            }
            if let pauseMinutes = entry.pause_minutes {
                HStack {
                    Text("Pause:")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Spacer()
                    Text("\(pauseMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
            }
            if let km = entry.km {
                HStack {
                    Text("Km:")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Spacer()
                    Text("\(km, specifier: "%.2f") km")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
            }
            if let tasks = entry.tasks {
                Text("Task: \(tasks.title)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Task ID: \(entry.task_id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let employee = entry.employees {
                Text("Worker: \(employee.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Worker ID: \(entry.employee_id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let description = entry.description, !description.isEmpty {
                Text("Notes: \(description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 12) {
                Button(action: {
                    onReject(entry)
                }) {
                    Text("Reject")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .disabled(entry.confirmation_status == "confirmed")
            }
            .padding(.top, 8)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
    }

    private func computeEntryDuration(start: Date?, end: Date?, pauseMinutes: Int) -> Double {
        guard let start = start, let end = end else { return 0 }
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(pauseMinutes) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
}
