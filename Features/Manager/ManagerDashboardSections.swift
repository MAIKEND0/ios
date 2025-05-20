//
//  ManagerDashboardSections.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import SwiftUI

// MARK: - Sekcje ManagerDashboardView
struct ManagerDashboardSections {
    // Sekcja kart podsumowania
    struct SummaryCardsSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        
        var body: some View {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard(
                    title: "Pending Hours",
                    value: "\(viewModel.pendingHoursCount)",
                    icon: "clock.fill",
                    background: DashboardStyles.gradientGreen
                )
                SummaryCard(
                    title: "Active Workers",
                    value: "\(viewModel.activeWorkersCount)",
                    icon: "person.2.fill",
                    background: DashboardStyles.gradientBlue
                )
                SummaryCard(
                    title: "Approved Hours",
                    value: String(format: "%.1f", viewModel.totalApprovedHours),
                    icon: "checkmark.circle.fill",
                    background: DashboardStyles.gradientOrange
                )
                SummaryCard(
                    title: "Tasks Assigned",
                    value: "\(viewModel.supervisorTasks.count)",
                    icon: "briefcase.fill",
                    background: DashboardStyles.gradientPurple
                )
            }
        }
    }

    // Sekcja selektora tygodnia
    struct WeekSelectorSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.ksrYellow)
                    Text("Selected Week")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                }
                HStack {
                    Button(action: {
                        viewModel.changeWeek(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.ksrYellow)
                    }
                    Text(weekRangeText)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .frame(maxWidth: .infinity)
                    Button(action: {
                        viewModel.changeWeek(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.ksrYellow)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.15) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        
        private var weekRangeText: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: viewModel.selectedMonday)!
            return "\(formatter.string(from: viewModel.selectedMonday)) - \(formatter.string(from: endOfWeek))"
        }
    }
    
    // Sekcja zadań
    struct TasksSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .foregroundColor(Color.ksrYellow)
                    Text("Supervised Tasks")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    Spacer()
                    Button {
                        viewModel.loadData()
                    } label: {
                        Text("Refresh")
                            .font(.caption)
                            .foregroundColor(Color.ksrYellow)
                    }
                }
                .padding(.bottom, 4)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else if viewModel.supervisorTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.largeTitle)
                            .foregroundColor(Color.gray)
                        Text("No supervised tasks")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        Text("You are not assigned as a supervisor to any tasks. Contact the administrator if this is incorrect.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 16) {
                        ForEach(viewModel.supervisorTasks) { task in
                            TaskCard(task: task, pendingEntriesByTask: viewModel.pendingEntriesByTask)
                        }
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.15) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // Sekcja godzin do zatwierdzenia
    struct PendingTasksSection: View {
        @ObservedObject var viewModel: ManagerDashboardViewModel
        @Environment(\.colorScheme) private var colorScheme
        let onSelectTaskWeek: (ManagerDashboardViewModel.TaskWeekEntry) -> Void
        let onSelectEntry: (ManagerAPIService.WorkHourEntry) -> Void
        @State private var expandedTasks: Set<Int> = [] // Śledzenie rozwiniętych zadań
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18, weight: .bold))
                    Text("Pending Approvals")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    Spacer()
                    Button {
                        viewModel.loadData()
                    } label: {
                        Text("Refresh")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if viewModel.allPendingEntriesByTask.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(Color.gray)
                        Text("No hours pending approval")
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    let tasks = Dictionary(grouping: viewModel.allPendingEntriesByTask, by: { $0.taskId })
                    ForEach(tasks.keys.sorted(), id: \.self) { taskId in
                        let taskWeeks = tasks[taskId]!
                        let taskTitle = taskWeeks.first?.taskTitle ?? "Task ID: \(taskId)"
                        let totalPendingHours = calculateTotalPendingHours(for: taskWeeks)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Nagłówek zadania
                            TaskHeaderView(
                                taskId: taskId,
                                taskTitle: taskTitle,
                                totalPendingHours: totalPendingHours,
                                isExpanded: expandedTasks.contains(taskId),
                                toggleExpansion: {
                                    withAnimation(.easeInOut) {
                                        if expandedTasks.contains(taskId) {
                                            expandedTasks.remove(taskId)
                                        } else {
                                            expandedTasks.insert(taskId)
                                        }
                                    }
                                }
                            )
                            
                            // Rozwinięte tygodnie
                            if expandedTasks.contains(taskId) {
                                ForEach(taskWeeks) { taskWeekEntry in
                                    NavigationLink(
                                        destination: WeekDetailView(
                                            taskWeekEntry: taskWeekEntry,
                                            onApproveWithSignature: {
                                                onSelectTaskWeek(taskWeekEntry)
                                            },
                                            onReject: { entry in
                                                onSelectEntry(entry)
                                            }
                                        )
                                    ) {
                                        CompactWeekRow(taskWeekEntry: taskWeekEntry)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DashboardStyles.gradientGreen.opacity(colorScheme == .dark ? 0.7 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.8), lineWidth: 2)
            )
        }
        
        private func calculateTotalPendingHours(for taskWeeks: [ManagerDashboardViewModel.TaskWeekEntry]) -> Double {
            taskWeeks.reduce(0.0) { sum, week in
                sum + week.entries.reduce(0.0) { innerSum, entry in
                    guard let start = entry.start_time, let end = entry.end_time else { return innerSum }
                    let interval = end.timeIntervalSince(start)
                    let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                    return innerSum + max(0, (interval - pauseSeconds) / 3600)
                }
            }
        }
    }
    
    // Widok nagłówka zadania
    struct TaskHeaderView: View {
        let taskId: Int
        let taskTitle: String
        let totalPendingHours: Double
        let isExpanded: Bool
        let toggleExpansion: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            Button(action: toggleExpansion) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text(taskTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f h", totalPendingHours))
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(radius: 2)
                )
            }
        }
    }
    
    // Kompaktowy wiersz dla tygodnia
    struct CompactWeekRow: View {
        let taskWeekEntry: ManagerDashboardViewModel.TaskWeekEntry
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            let totalHours = taskWeekEntry.entries.reduce(0.0) { sum, entry in
                guard let start = entry.start_time, let end = entry.end_time else { return sum }
                let interval = end.timeIntervalSince(start)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                Text("Week \(taskWeekEntry.weekNumber), \(taskWeekEntry.year)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text("\(taskWeekEntry.entries.count) entries, \(String(format: "%.1f", totalHours))h")
                    .font(.caption)
                    .foregroundColor(.green)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemBackground))
            )
        }
    }
}
