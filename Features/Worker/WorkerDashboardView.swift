import SwiftUI

struct WorkerDashboardView: View {
    // Use StateObject for the main ViewModel to persist it across view refreshes
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @State private var showWorkHoursForm = false
    @State private var showFilterOptions = false
    @State private var searchText = ""
    @State private var hasAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    
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
                    if viewModel.tasksViewModel.isLoading {
                        // Show loading indicator while loading tasks
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 150)
                    } else if viewModel.tasksViewModel.tasks.isEmpty {
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
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // obsługa powiadomień
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showFilterOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                // Load data when view appears
                viewModel.loadData()
                
                // Set the flag so we know the view has appeared
                hasAppeared = true
            }
            // Force refresh when we come back to this view from another tab
            // Updated for iOS 17 compatibility
            .onChange(of: hasAppeared) { _, _ in
                viewModel.loadData()
            }
            // Add timer to periodically refresh data
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                // Refresh data every 30 seconds
                viewModel.loadData()
            }
            .sheet(isPresented: $showWorkHoursForm) {
                WeeklyWorkEntryForm(
                    employeeId: AuthService.shared.getEmployeeId() ?? "",
                    taskId: viewModel.getSelectedTaskId(),
                    selectedMonday: Calendar.current.startOfWeek(for: Date())
                )
            }
            // Add refreshable modifier to allow pull-to-refresh
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
                    // Delay slightly to make refresh feel natural
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
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
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        // Wyszukiwanie
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                    
                    Button {
                        withAnimation {
                            showFilterOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                    
                    // Add refresh button
                    Button {
                        viewModel.loadData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
            }
            
            if showFilterOptions {
                HStack {
                    TextField("Search tasks...", text: $searchText)
                        .padding(8)
                        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6))
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
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                
            Text("When tasks are assigned to you, they will appear here")
                .font(Font.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                .padding(.horizontal)
            
            // Add a manual refresh button
            Button {
                viewModel.loadData()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Tasks")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.ksrYellow.opacity(0.2))
                .foregroundColor(Color.ksrYellow)
                .cornerRadius(8)
            }
            .padding(.top, 8)
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
    
    // Helper struct to represent weekly status
    struct WeekStatus: Identifiable {
        let id = UUID()
        let weekNumber: Int
        let year: Int
        let hours: Double
        let status: EntryStatus
        
        var weekLabel: String {
            return "Week \(weekNumber)"
        }
        
        var statusIcon: (Image, Color) {
            switch status {
            case .draft:
                return (Image(systemName: "pencil.circle"), .orange)
            case .pending:
                return (Image(systemName: "clock"), .blue)
            case .submitted:
                return (Image(systemName: "paperplane"), .purple)
            case .confirmed:
                return (Image(systemName: "checkmark.circle"), .green)
            case .rejected:
                return (Image(systemName: "xmark.circle"), .red)
            }
        }
    }
    
    private func taskCard(task: APIService.Task) -> some View {
        // Find entries related to this task
        let taskEntries = viewModel.hoursViewModel.entries.filter {
            $0.task_id == task.task_id
        }
        
        // Calculate total hours
        let totalHours = taskEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseMinutes = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseMinutes) / 3600)
        }
        
        // Get weeks statuses for the last 4 weeks
        let weekStatuses = getWeekStatuses(for: task.task_id, count: 4)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Nagłówek
            HStack {
                Text(task.title)
                    .font(Font.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        // Pokaż kalendarz
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                    
                    Button {
                        // Pokaż dokumenty
                    } label: {
                        Image(systemName: "doc.text")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                    
                    Button {
                        // Przejdź do szczegółów
                    } label: {
                        Image(systemName: "folder")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                }
            }
            
            // Opis
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(Font.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    .lineLimit(2)
            }
            
            // Weekly history section
            VStack(spacing: 8) {
                Text("Recent Hours")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                
                // History rows for weeks
                if weekStatuses.isEmpty {
                    Text("No recent hour entries")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                } else {
                    ForEach(weekStatuses) { weekStatus in
                        weekStatusRow(weekStatus)
                    }
                }
            }
            .padding(10)
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.5))
            .cornerRadius(8)
            
            // Informacje o godzinach
            HStack {
                Text("Total Logged Hours:")
                    .font(Font.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                
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
                    viewModel.setSelectedTaskId(task.task_id)
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
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
    }
    
    // Function to generate week statuses for a task (would normally come from API)
    private func getWeekStatuses(for taskId: Int, count: Int) -> [WeekStatus] {
        var statuses = [WeekStatus]()
        let calendar = Calendar.current
        let currentDate = Date()
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Check if there are draft entries in the current week
        let hasDrafts = viewModel.hoursViewModel.entries.contains { entry in
            guard entry.task_id == taskId,
                  let isDraft = entry.is_draft, isDraft,
                  let startTime = entry.start_time else {
                return false
            }
            
            let entryWeek = calendar.component(.weekOfYear, from: startTime)
            let entryYear = calendar.component(.year, from: startTime)
            return entryWeek == currentWeek && entryYear == currentYear
        }
        
        // Add current week with appropriate status
        statuses.append(WeekStatus(
            weekNumber: currentWeek,
            year: currentYear,
            hours: getHoursForWeek(taskId: taskId, weekNumber: currentWeek, year: currentYear),
            status: hasDrafts ? .draft : .pending
        ))
        
        // Add previous weeks (these would typically have confirmed or rejected status)
        for i in 1..<count {
            var dateComponents = DateComponents()
            dateComponents.weekOfYear = -i
            guard let weekDate = calendar.date(byAdding: dateComponents, to: currentDate) else {
                continue
            }
            
            let weekNumber = calendar.component(.weekOfYear, from: weekDate)
            let year = calendar.component(.year, from: weekDate)
            
            // Simulate different statuses for different weeks
            let status: EntryStatus
            switch i {
            case 1:
                status = .submitted
            case 2:
                status = .confirmed
            case 3:
                status = .rejected
            default:
                status = .confirmed
            }
            
            statuses.append(WeekStatus(
                weekNumber: weekNumber,
                year: year,
                hours: getHoursForWeek(taskId: taskId, weekNumber: weekNumber, year: year),
                status: status
            ))
        }
        
        return statuses
    }
    
    // Function to calculate hours for a specific week
    private func getHoursForWeek(taskId: Int, weekNumber: Int, year: Int) -> Double {
        let calendar = Calendar.current
        
        // Filter entries for the specified task and week
        return viewModel.hoursViewModel.entries.reduce(0.0) { sum, entry in
            guard entry.task_id == taskId,
                  let start = entry.start_time,
                  let end = entry.end_time else {
                return sum
            }
            
            let entryWeek = calendar.component(.weekOfYear, from: start)
            let entryYear = calendar.component(.year, from: start)
            
            if entryWeek == weekNumber && entryYear == year {
                let interval = end.timeIntervalSince(start)
                let pauseMinutes = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseMinutes) / 3600)
            }
            
            return sum
        }
    }
    
    // Week status row component
    private func weekStatusRow(_ weekStatus: WeekStatus) -> some View {
        HStack {
            // Week label
            Text(weekStatus.weekLabel)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(width: 70, alignment: .leading)
            
            // Hours
            Text("\(weekStatus.hours, specifier: "%.2f") hrs")
                .font(.caption)
                .foregroundColor(Color.ksrYellow)
                .frame(width: 80)
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                weekStatus.statusIcon.0
                    .foregroundColor(weekStatus.statusIcon.1)
                    .font(.caption)
                
                Text(weekStatus.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(weekStatus.statusIcon.1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: – Ostatnie godziny
    private var recentWorkHoursView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Hours")
                    .font(Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
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
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
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
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
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
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
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
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text("\(hours, specifier: "%.2f")h")
                    .font(Font.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ksrYellow)
            }
            HStack {
                Text("\(entry.startTimeFormatted ?? "-") – \(entry.endTimeFormatted ?? "-")")
                    .font(Font.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
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
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func announcementCard(announcement: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(announcement.title)
                    .font(Font.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                // Etykieta priorytetu
                priorityLabel(for: announcement.priority)
            }
            
            Text(announcement.content)
                .font(Font.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
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
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
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
        Group {
            WorkerDashboardView()
                .preferredColorScheme(.light)
            
            WorkerDashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
