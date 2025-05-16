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
                    title: "Approved Hours",  // Zmieniony tekst na krótszy
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
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.ksrYellow)
                    Text("Pending Weeks for Approval")
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

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else if viewModel.pendingEntriesByTask.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(Color.gray)
                        Text("No hours pending approval")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        Text("No hours have been submitted for your tasks in the selected week. Try changing the week or contact workers.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    let tasks = Dictionary(grouping: viewModel.pendingEntriesByTask, by: { $0.taskId })
                    ForEach(tasks.keys.sorted(), id: \.self) { taskId in
                        let taskWeeks = tasks[taskId]!
                        let taskTitle = taskWeeks.first?.taskTitle ?? "Task ID: \(taskId)"
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.ksrYellow)
                                Text(taskTitle)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
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
                                    WeekCard(taskWeekEntry: taskWeekEntry)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(DashboardStyles.gradientPending)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ksrYellow, lineWidth: 2)
            )
        }
    }
}
