import SwiftUI

struct WorkerDashboardView: View {
    // Używaj state object dla instancji ViewModel
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @State private var showWorkHoursForm = false
    @State private var showFilterOptions = false
    @State private var searchText = ""
    
    // Kolory dostosowane do webowej wersji
    private let gradientGreen = LinearGradient(
        colors: [Color(hex: "66bb6a"), Color(hex: "43a047")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let gradientBlue = LinearGradient(
        colors: [Color(hex: "29b6f6"), Color(hex: "0288d1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let gradientOrange = LinearGradient(
        colors: [Color(hex: "ffa726"), Color(hex: "fb8c00")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let gradientPink = LinearGradient(
        colors: [Color(hex: "ec407a"), Color(hex: "d81b60")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // SEKCJA 1: Karty podsumowania
                    summaryCardsSection
                    
                    // SEKCJA 2: Moje zadania
                    tasksHeaderSection
                    
                    // Faktycznie zadania
                    if viewModel.tasksViewModel.tasks.isEmpty {
                        noTasksView
                    } else {
                        tasksList
                    }
                    
                    // SEKCJA 3: Ostatnie godziny
                    recentWorkHoursView
                    
                    // SEKCJA 4: Ogłoszenia
                    announcementsView
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // obsługa powiadomień
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(Color.ksrDarkGray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showFilterOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showWorkHoursForm) {
                WeeklyWorkEntryForm(
                    employeeId: AuthService.shared.getEmployeeId() ?? "",
                    taskId: viewModel.getSelectedTaskId(),
                    selectedMonday: Calendar.current.startOfWeek(for: Date())
                )
            }
        }
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Karta 1: Godziny w tym tygodniu
            summaryCard(
                title: "Hours This Week",
                value: String(format: "%.1f", viewModel.hoursViewModel.totalWeeklyHours),
                background: gradientGreen
            )
            
            // Karta 2: Godziny w tym miesiącu
            summaryCard(
                title: "Hours This Month",
                value: String(format: "%.1f", viewModel.hoursViewModel.totalMonthlyHours),
                background: gradientBlue
            )
            
            // Karta 3: Aktywne zadania
            summaryCard(
                title: "Active Tasks",
                value: "\(viewModel.tasksViewModel.tasks.count)",
                background: gradientOrange
            )
            
            // Karta 4: Godziny w tym roku
            summaryCard(
                title: "Hours This Year",
                value: String(format: "%.1f", viewModel.hoursViewModel.totalYearlyHours),
                background: gradientPink
            )
        }
    }
    
    private func summaryCard(title: String, value: String, background: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.white.opacity(0.9))
            
            Text(value)
                .font(Font.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(background)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    // MARK: - Tasks Header Section
    private var tasksHeaderSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Tasks")
                    .font(Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrDarkGray)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        // Wyszukiwanie
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.ksrDarkGray)
                    }
                    
                    Button {
                        withAnimation {
                            showFilterOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color.ksrDarkGray)
                    }
                }
            }
            
            if showFilterOptions {
                HStack {
                    TextField("Search tasks...", text: $searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.trailing)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - No Tasks View
    private var noTasksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(Font.largeTitle)
                .foregroundColor(Color.gray)
            
            Text("No tasks assigned yet")
                .font(Font.headline)
                .foregroundColor(Color.ksrMediumGray)
                
            Text("When tasks are assigned to you, they will appear here")
                .font(Font.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.ksrMediumGray)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Tasks List
    private var tasksList: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.tasksViewModel.tasks, id: \.task_id) { task in
                taskCard(task: task)
            }
        }
    }
    
    private func taskCard(task: APIService.Task) -> some View {
        // Znajdź wpisy godzin związane z tym zadaniem
        let taskEntries = viewModel.hoursViewModel.entries.filter {
            $0.task_id == task.task_id
        }
        
        // Oblicz łączną liczbę godzin
        let totalHours = taskEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseMinutes = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseMinutes) / 3600)
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            // Nagłówek
            HStack {
                Text(task.title)
                    .font(Font.headline)
                    .foregroundColor(Color.ksrDarkGray)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        // Pokaż kalendarz
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.ksrMediumGray)
                    }
                    
                    Button {
                        // Pokaż dokumenty
                    } label: {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.ksrMediumGray)
                    }
                    
                    Button {
                        // Przejdź do szczegółów
                    } label: {
                        Image(systemName: "folder")
                            .foregroundColor(Color.ksrMediumGray)
                    }
                }
            }
            
            // Opis
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(Font.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                    .lineLimit(2)
            }
            
            // Informacje o godzinach
            HStack {
                Text("Logged Hours:")
                    .font(Font.caption)
                    .foregroundColor(Color.ksrMediumGray)
                
                Text("\(totalHours, specifier: "%.2f") hrs")
                    .font(Font.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrYellow)
            }
            
            // Przyciski akcji
            HStack {
                Spacer()
                
                Button {
                    // Ustaw zadanie i pokaż formularz godzin
                    showWorkHoursForm = true
                } label: {
                    Text("Log Hours")
                        .font(Font.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.ksrYellow)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: – Ostatnie godziny
    private var recentWorkHoursView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Hours")
                    .font(Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrDarkGray)
                Spacer()
                NavigationLink(destination: WorkerWorkHoursView()) {
                    Text("View all")
                        .font(Font.caption)
                        .foregroundColor(Color.ksrYellow)
                }
            }

            if viewModel.hoursViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.hoursViewModel.entries.isEmpty {
                Text("No hours recorded yet")
                    .foregroundColor(Color.ksrMediumGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.hoursViewModel.entries.prefix(3)) { entry in
                    workHourCard(entry: entry)
                }
            }

            Button {
                showWorkHoursForm = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Hours")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ksrYellow)
                .foregroundColor(Color.black)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: – Ogłoszenia
    private var announcementsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Announcements")
                    .font(Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.ksrDarkGray)
                Spacer()
                NavigationLink(destination: Text("Announcements List")) {
                    Text("View all")
                        .font(Font.caption)
                        .foregroundColor(Color.ksrYellow)
                }
            }

            if viewModel.isLoadingAnnouncements {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.announcements.isEmpty {
                Text("No announcements")
                    .foregroundColor(Color.ksrMediumGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.announcements) { ann in
                    announcementCard(announcement: ann)
                }
            }
        }
    }

    @ViewBuilder
    private func workHourCard(entry: APIService.WorkHourEntry) -> some View {
        // Używamy obliczania godzin z WeeklyWorkEntryViewModel
        let hours = computeEntryDuration(
            start: entry.start_time,
            end: entry.end_time,
            pauseMinutes: entry.pause_minutes ?? 0
        )
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.workDateFormatted)
                    .font(Font.headline)
                    .foregroundColor(Color.ksrDarkGray)
                Spacer()
                Text("\(hours, specifier: "%.2f")h")
                    .font(Font.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrYellow)
            }
            HStack {
                Text("\(entry.startTimeFormatted ?? "-") – \(entry.endTimeFormatted ?? "-")")
                    .font(Font.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                Spacer()
                if let isDraft = entry.is_draft, isDraft {
                    Text("Draft")
                        .font(Font.caption2).bold()
                        .padding(4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(Color.orange)
                        .cornerRadius(4)
                } else {
                    Text(entry.status ?? "Pending")
                        .font(Font.caption2).bold()
                        .padding(4)
                        .background(Color.ksrYellow.opacity(0.2))
                        .foregroundColor(Color.ksrYellow)
                        .cornerRadius(4)
                }
            }
            
            if let tasks = entry.tasks {
                Text("Task: \(tasks.title)")
                    .font(Font.caption)
                    .foregroundColor(Color.secondary)
            } else {
                Text("Task: \(entry.task_id)")
                    .font(Font.caption)
                    .foregroundColor(Color.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func announcementCard(announcement: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(announcement.title)
                    .font(Font.headline)
                    .foregroundColor(Color.ksrDarkGray)
                
                Spacer()
                
                // Etykieta priorytetu
                priorityLabel(for: announcement.priority)
            }
            
            Text(announcement.content)
                .font(Font.subheadline)
                .foregroundColor(Color.ksrMediumGray)
                .lineLimit(2)
                
            HStack {
                Image(systemName: "calendar")
                    .font(Font.caption)
                    .foregroundColor(Color.gray)
                
                Text(formatDate(announcement.publishedAt))
                    .font(Font.caption)
                    .foregroundColor(Color.gray)
                
                if let expiresAt = announcement.expiresAt {
                    Spacer()
                    Image(systemName: "clock")
                        .font(Font.caption)
                        .foregroundColor(Color.gray)
                    Text("Expires: \(formatDate(expiresAt))")
                        .font(Font.caption)
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func priorityLabel(for priority: AnnouncementPriority) -> some View {
        let (color, text) = priorityConfig(for: priority)
        return Text(text)
            .font(Font.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private func priorityConfig(for priority: AnnouncementPriority) -> (Color, String) {
        switch priority {
        case .high:
            return (Color.red, "High")
        case .normal:
            return (Color.blue, "Normal")
        case .low:
            return (Color.gray, "Low")
        }
    }
    
    // MARK: - Helper funkcje
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func computeEntryDuration(start: Date?, end: Date?, pauseMinutes: Int) -> Double {
        guard let start = start, let end = end else { return 0 }
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(pauseMinutes) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
}

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
    }
}
