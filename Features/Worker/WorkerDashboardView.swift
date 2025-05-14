//
//  WorkerDashboardView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @State private var showWorkHoursForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    statsView
                    recentWorkHoursView
                    announcementsView
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // obsługa powiadomień
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showWorkHoursForm) {
                WeeklyWorkEntryForm(
                    employeeId: AuthService.shared.getEmployeeId() ?? "",
                    taskId:        viewModel.selectedTaskId ?? "",
                    selectedMonday: Calendar.current.startOfWeek(for: Date())
                )
            }
        }
    }

    // MARK: – Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Witaj,")
                    .font(.title3)
                    .foregroundColor(.ksrMediumGray)
                Text(AuthService.shared.getEmployeeName() ?? "Operator")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.ksrDarkGray)
            }
            Spacer()
            ZStack {
                Rectangle()
                    .fill(Color.ksrYellow)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                Text("KSR")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal)
    }

    // MARK: – Stats
    private var statsView: some View {
        HStack(spacing: 15) {
            statCard(
                title: "Godziny w tym tygodniu",
                value: String(format: "%.1f", viewModel.hoursViewModel.totalWeeklyHours),
                icon:  "clock.fill",
                color: .ksrYellow
            )
            statCard(
                title: "Zadania",
                value: "\(viewModel.tasksViewModel.tasks.count)",
                icon:  "list.bullet",
                color: .ksrDarkGray
            )
        }
        .padding(.horizontal)
    }

    // MARK: – Ostatnie godziny
    private var recentWorkHoursView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ostatnie godziny")
                    .font(.headline)
                    .foregroundColor(.ksrDarkGray)
                Spacer()
                NavigationLink(destination: WorkHoursView()) {
                    Text("Zobacz wszystkie")
                        .font(.caption)
                        .foregroundColor(.ksrYellow)
                }
            }
            .padding(.horizontal)

            if viewModel.hoursViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.hoursViewModel.workHourEntries.isEmpty {
                Text("Brak zapisanych godzin")
                    .foregroundColor(.ksrMediumGray)
                    .padding()
            } else {
                ForEach(viewModel.hoursViewModel.workHourEntries) { entry in
                    workHourCard(entry: entry)
                }
            }

            Button {
                showWorkHoursForm = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Dodaj godziny")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ksrYellow)
                .foregroundColor(.black)
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }

    // MARK: – Ogłoszenia
    private var announcementsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ogłoszenia")
                    .font(.headline)
                    .foregroundColor(.ksrDarkGray)
                Spacer()
                NavigationLink(destination: Text("Lista ogłoszeń")) {
                    Text("Zobacz wszystkie")
                        .font(.caption)
                        .foregroundColor(.ksrYellow)
                }
            }
            .padding(.horizontal)

            if viewModel.isLoadingAnnouncements {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.announcements.isEmpty {
                Text("Brak ogłoszeń")
                    .foregroundColor(.ksrMediumGray)
                    .padding()
            } else {
                ForEach(viewModel.announcements) { ann in
                    announcementCard(announcement: ann)
                }
            }
        }
    }

    // MARK: – Pomocnicze komponenty

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.ksrMediumGray)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ksrDarkGray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    private func workHourCard(entry: WorkHourEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.formattedDate)
                    .font(.headline)
                    .foregroundColor(.ksrDarkGray)
                Spacer()
                Text(entry.formattedTotalHours)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrYellow)
            }
            HStack {
                Text("\(entry.formattedStartTime) – \(entry.formattedEndTime)")
                    .font(.subheadline)
                    .foregroundColor(.ksrMediumGray)
                Spacer()
                if entry.isDraft {
                    Text("Wersja robocza")
                        .font(.caption2).bold()
                        .padding(4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                } else {
                    Text(entry.status.rawValue.capitalized)
                        .font(.caption2).bold()
                        .padding(4)
                        .background(Color.ksrYellow.opacity(0.2))
                        .foregroundColor(.ksrYellow)
                        .cornerRadius(4)
                }
            }
            if let desc = entry.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.ksrDarkGray.opacity(0.8))
                    .lineLimit(3)
            }
            Text("Projekt: \(entry.projectId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func announcementCard(announcement: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(announcement.title)
                    .font(.headline)
                    .foregroundColor(.ksrDarkGray)
                Spacer()
                Text(announcement.publishedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.ksrMediumGray)
            }
            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(.ksrMediumGray)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
    }
}
