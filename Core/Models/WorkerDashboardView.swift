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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome,")
                                .font(.title3)
                                .foregroundColor(Color.ksrMediumGray)
                            
                            // Pobierz nazwę użytkownika z AuthService jeśli jest dostępna
                            if let userName = UserDefaults.standard.string(forKey: "employee_name") {
                                Text(userName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.ksrDarkGray)
                            } else {
                                Text("Operator")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.ksrDarkGray)
                            }
                        }
                        Spacer()
                        
                        // Company logo or avatar
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
                    .padding()
                    
                    // Stats summary
                    HStack(spacing: 15) {
                        statCard(title: "Hours This Week", value: String(format: "%.1f", viewModel.hoursViewModel.totalWeeklyHours), icon: "clock.fill", color: Color.ksrYellow)
                        statCard(title: "Active Projects", value: "2", icon: "folder.fill", color: Color.ksrDarkGray)
                    }
                    .padding(.horizontal)
                    
                    // Recent work hours
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Recent Work Hours")
                                .font(.headline)
                                .foregroundColor(Color.ksrDarkGray)
                            
                            Spacer()
                            
                            NavigationLink(destination: WorkHoursView()) {
                                Text("View All")
                                    .font(.caption)
                                    .foregroundColor(Color.ksrYellow)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.hoursViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if viewModel.hoursViewModel.workHourEntries.isEmpty {
                            Text("No entries found")
                                .foregroundColor(Color.ksrMediumGray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.hoursViewModel.workHourEntries) { entry in
                                workHourCard(entry: entry)
                            }
                        }
                        
                        Button(action: {
                            showWorkHoursForm = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add New Work Hours")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ksrYellow)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Announcements
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Announcements")
                                .font(.headline)
                                .foregroundColor(Color.ksrDarkGray)
                            
                            Spacer()
                            
                            NavigationLink(destination: Text("Announcements List")) {
                                Text("View All")
                                    .font(.caption)
                                    .foregroundColor(Color.ksrYellow)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isLoadingAnnouncements {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if viewModel.announcements.isEmpty {
                            Text("No announcements")
                                .foregroundColor(Color.ksrMediumGray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.announcements) { announcement in
                                announcementCard(announcement: announcement)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Notifications action
                    }) {
                        Image(systemName: "bell")
                            .foregroundColor(Color.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showWorkHoursForm) {
                if let employeeId = AuthService.shared.getEmployeeId() {
                    WeeklyWorkEntryForm(
                        employeeId: employeeId,
                        taskId: viewModel.getSelectedTaskId(), // Pobiera aktywne zadanie
                        selectedMonday: getMondayOfCurrentWeek()
                    )
                } else {
                    // Fallback dla przypadku gdy nie ma zalogowanego użytkownika
                    WeeklyWorkEntryForm(
                        employeeId: "emp-456", // Domyślne ID
                        taskId: "task-123",    // Domyślne ID zadania
                        selectedMonday: getMondayOfCurrentWeek()
                    )
                }
            }
        }
    }
    
    // Helper function do pobierania poniedziałku bieżącego tygodnia
    func getMondayOfCurrentWeek() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Sunday=1, Monday=2, ..., Saturday=7
        let daysToSubtract = (weekday + 6) % 7
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
    }
    
    // Helper views
    
    func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.ksrMediumGray)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.ksrDarkGray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func workHourCard(entry: WorkHourEntry) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(formatDate(entry.date))
                    .font(.headline)
                    .foregroundColor(Color.ksrDarkGray)
                
                Spacer()
                
                Text(entry.formattedTotalHours)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrYellow)
            }
            
            Text("\(formatTime(entry.startTime)) - \(formatTime(entry.endTime))")
                .font(.subheadline)
                .foregroundColor(Color.ksrMediumGray)
            
            if let description = entry.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.ksrMediumGray)
                    .lineLimit(2)
            }
            
            // Status indikator
            HStack {
                Spacer()
                
                if entry.isDraft {
                    Text("Draft")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(5)
                } else {
                    Text(entry.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(entry.status).opacity(0.2))
                        .foregroundColor(statusColor(entry.status))
                        .cornerRadius(5)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    func announcementCard(announcement: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(announcement.title)
                    .font(.headline)
                    .foregroundColor(Color.ksrDarkGray)
                
                Spacer()
                
                Text(formatDate(announcement.publishedAt))
                    .font(.caption)
                    .foregroundColor(Color.ksrMediumGray)
            }
            
            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(Color.ksrMediumGray)
                .lineLimit(2)
            
            HStack {
                Spacer()
                
                Text(priorityText(announcement.priority))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(announcement.priority).opacity(0.2))
                    .foregroundColor(priorityColor(announcement.priority))
                    .cornerRadius(5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Helper functions
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func priorityText(_ priority: AnnouncementPriority) -> String {
        switch priority {
        case .low:
            return "Low"
        case .normal:
            return "Medium"
        case .high:
            return "High"
        }
    }
    
    func priorityColor(_ priority: AnnouncementPriority) -> Color {
        switch priority {
        case .low:
            return Color.gray
        case .normal:
            return Color.ksrYellow
        case .high:
            return Color.red
        }
    }
    
    func statusColor(_ status: EntryStatus) -> Color {
        switch status {
        case .draft:
            return Color.orange
        case .pending:
            return Color.blue
        case .submitted:
            return Color.purple
        case .confirmed:
            return Color.green
        case .rejected:
            return Color.red
        }
    }
}

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
    }
}
