// WorkerDashboardView.swift - Updated with shared NotificationService
import SwiftUI

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @ObservedObject private var notificationService = NotificationService.shared // ✅ Use shared instance
    @State private var showWorkHoursForm = false
    @State private var showFilterOptions = false
    @State private var showNotifications = false
    @State private var searchText = ""
    @State private var hasAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Kolory dostosowane do webowej wersji (same as before)
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
    private let gradientPurple = LinearGradient(
        colors: [Color(hex: "ab47bc"), Color(hex: "8e24aa")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let gradientTeal = LinearGradient(
        colors: [Color(hex: "26a69a"), Color(hex: "00897b")],
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
                // ✅ Enhanced notification bell with better badge
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNotifications.toggle()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: notificationService.unreadCount > 0 ? "bell.badge.fill" : "bell")
                                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                                .font(.title3)
                            
                            if notificationService.unreadCount > 0 {
                                Text(notificationService.unreadCount > 99 ? "99+" : "\(notificationService.unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, notificationService.unreadCount > 9 ? 4 : 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(
                                                notificationService.getUrgentUnreadNotifications().count > 0 ?
                                                Color.red : Color.orange
                                            )
                                    )
                                    .offset(x: 8, y: -8)
                                    .scaleEffect(notificationService.unreadCount > 0 ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.3), value: notificationService.unreadCount)
                            }
                        }
                    }
                    .disabled(notificationService.isLoading)
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
                if !hasAppeared {
                    viewModel.loadData()
                    notificationService.fetchNotifications()
                    notificationService.fetchUnreadCount()
                    hasAppeared = true
                }
            }
            .onChange(of: hasAppeared) { _, _ in
                if hasAppeared {
                    viewModel.loadData()
                    notificationService.refreshIfNeeded()
                }
            }
            .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
                #if DEBUG
                print("[WorkerDashboardView] Timer triggered refresh")
                #endif
                viewModel.loadData()
                notificationService.refreshIfNeeded()
            }
            .sheet(isPresented: $showWorkHoursForm) {
                WeeklyWorkEntryForm(
                    employeeId: AuthService.shared.getEmployeeId() ?? "",
                    taskId: viewModel.getSelectedTaskId(),
                    selectedMonday: Calendar.current.startOfWeek(for: Date())
                )
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .refreshable {
                #if DEBUG
                print("[WorkerDashboardView] Pull-to-refresh triggered")
                #endif
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
                    notificationService.forceRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
            }
            // ✅ Listen to notification actions
            .onReceive(NotificationCenter.default.publisher(for: .openWorkEntryForm)) { notification in
                if let userInfo = notification.userInfo,
                   let taskId = userInfo["taskId"] as? Int {
                    viewModel.setSelectedTaskId(taskId)
                    showWorkHoursForm = true
                }
            }
        }
    }
    
    // Rest of the implementation stays exactly the same...
    // All the sections: summaryCardsSection, tasksHeaderSection, etc.
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: "Hours This Week",
                value: String(format: "%.1f", viewModel.totalWeeklyHours),
                background: gradientGreen
            )
            summaryCard(
                title: "Km This Week",
                value: String(format: "%.2f", viewModel.totalWeeklyKm),
                background: gradientPurple
            )
            summaryCard(
                title: "Hours This Month",
                value: String(format: "%.1f", viewModel.totalMonthlyHours),
                background: gradientBlue
            )
            summaryCard(
                title: "Km This Month",
                value: String(format: "%.2f", viewModel.totalMonthlyKm),
                background: gradientTeal
            )
            summaryCard(
                title: "Active Tasks",
                value: "\(viewModel.tasksViewModel.tasks.count)",
                background: gradientOrange
            )
            summaryCard(
                title: "Hours This Year",
                value: String(format: "%.1f", viewModel.totalYearlyHours),
                background: gradientPink
            )
        }
    }
    
    private func summaryCard(title: String, value: String, background: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(background)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    // MARK: - Tasks Header Section
    private var tasksHeaderSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Tasks")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        // Wyszukiwanie (do zaimplementowania)
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
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No tasks assigned yet")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
            Text("When tasks are assigned to you, they will appear here")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                .padding(.horizontal)
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
    
    // MARK: - Task Card
    private func taskCard(task: WorkerAPIService.Task) -> some View {
        let taskEntries = viewModel.hoursViewModel.entries.filter { $0.task_id == task.task_id }
        
        #if DEBUG
        print("[WorkerDashboardView] Task \(task.title) (ID: \(task.task_id)) has \(taskEntries.count) entries")
        #endif
        
        let totalHours = taskEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
        
        let totalKm = taskEntries.reduce(0.0) { sum, entry in
            guard let km = entry.km else { return sum }
            return sum + km
        }
        
        let weekStatuses = getWeekStatuses(for: task.task_id, entries: taskEntries, count: 4)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        // Pokaż kalendarz (do zaimplementowania)
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                    Button {
                        // Pokaż dokumenty (do zaimplementowania)
                    } label: {
                        Image(systemName: "doc.text")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                    Button {
                        // Przejdź do szczegółów (do zaimplementowania)
                    } label: {
                        Image(systemName: "folder")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    }
                }
            }
            
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    .lineLimit(2)
            }
            
            VStack(spacing: 8) {
                Text("Recent Hours")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                    .background(colorScheme == .dark ? .gray.opacity(0.3) : .gray.opacity(0.2))
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
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Total Logged Hours:")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        Text("\(totalHours, specifier: "%.2f") hrs")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ksrYellow)
                    }
                    HStack {
                        Text("Total Logged Km:")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        Text("\(totalKm, specifier: "%.2f") km")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ksrYellow)
                    }
                }
                Spacer()
            }
            
            HStack {
                Spacer()
                Button {
                    viewModel.setSelectedTaskId(task.task_id)
                    showWorkHoursForm = true
                } label: {
                    Text("Log Hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
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
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Week Status
    struct WeekStatus: Identifiable {
        let id = UUID()
        let weekNumber: Int
        let year: Int
        let hours: Double
        let km: Double
        let status: EntryStatus
        
        var weekLabel: String {
            "Week \(weekNumber)"
        }
        
        var statusIcon: (Image, Color) {
            switch status {
            case .draft: return (Image(systemName: "pencil.circle"), .orange)
            case .pending: return (Image(systemName: "clock"), .blue)
            case .submitted: return (Image(systemName: "paperplane"), .purple)
            case .confirmed: return (Image(systemName: "checkmark.circle"), .green)
            case .rejected: return (Image(systemName: "xmark.circle"), .red)
            }
        }
    }
    
    private func effectiveStatus(for entry: WorkerAPIService.WorkHourEntry) -> EntryStatus {
        if let confirmationStatus = entry.confirmation_status, confirmationStatus != "pending" {
            switch confirmationStatus {
            case "confirmed": return .confirmed
            case "rejected": return .rejected
            default: break
            }
        }
        if entry.is_draft == true {
            return .draft
        }
        if let status = entry.status {
            switch status {
            case "submitted": return .submitted
            case "pending": return .pending
            default: break
            }
        }
        return .pending
    }
    
    private func getWeekStatuses(for taskId: Int, entries: [WorkerAPIService.WorkHourEntry], count: Int) -> [WeekStatus] {
        var statuses: [WeekStatus] = []
        let calendar = Calendar.current
        let currentDate = Date()
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        let currentWeekEntries = entries.filter { entry in
            guard entry.task_id == taskId, let startTime = entry.start_time else { return false }
            return calendar.component(.weekOfYear, from: startTime) == currentWeek &&
                   calendar.component(.year, from: startTime) == currentYear
        }
        
        let currentWeekHours = currentWeekEntries.reduce(0.0) { sum, entry in
            guard let startTime = entry.start_time, let endTime = entry.end_time else { return sum }
            let interval = endTime.timeIntervalSince(startTime)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
        
        let currentWeekKm = currentWeekEntries.reduce(0.0) { sum, entry in
            guard let km = entry.km else { return sum }
            return sum + km
        }
        
        let currentWeekStatus: EntryStatus = {
            if currentWeekEntries.isEmpty { return .pending }
            if currentWeekEntries.contains(where: { effectiveStatus(for: $0) == .rejected }) { return .rejected }
            if currentWeekEntries.contains(where: { effectiveStatus(for: $0) == .confirmed }) { return .confirmed }
            if currentWeekEntries.contains(where: { effectiveStatus(for: $0) == .submitted }) { return .submitted }
            if currentWeekEntries.contains(where: { effectiveStatus(for: $0) == .draft }) { return .draft }
            return .pending
        }()
        
        statuses.append(WeekStatus(
            weekNumber: currentWeek,
            year: currentYear,
            hours: currentWeekHours,
            km: currentWeekKm,
            status: currentWeekStatus
        ))
        
        for i in 1..<count {
            var dateComponents = DateComponents()
            dateComponents.weekOfYear = -i
            guard let weekDate = calendar.date(byAdding: dateComponents, to: currentDate) else { continue }
            
            let weekNumber = calendar.component(.weekOfYear, from: weekDate)
            let year = calendar.component(.year, from: weekDate)
            
            let weekEntries = entries.filter { entry in
                guard entry.task_id == taskId, let startTime = entry.start_time else { return false }
                return calendar.component(.weekOfYear, from: startTime) == weekNumber &&
                       calendar.component(.year, from: startTime) == year
            }
            
            let weekHours = weekEntries.reduce(0.0) { sum, entry in
                guard let startTime = entry.start_time, let endTime = entry.end_time else { return sum }
                let interval = endTime.timeIntervalSince(startTime)
                let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                return sum + max(0, (interval - pauseSeconds) / 3600)
            }
            
            let weekKm = weekEntries.reduce(0.0) { sum, entry in
                guard let km = entry.km else { return sum }
                return sum + km
            }
            
            let status: EntryStatus = {
                if weekEntries.isEmpty { return .pending }
                if weekEntries.contains(where: { effectiveStatus(for: $0) == .rejected }) { return .rejected }
                if weekEntries.contains(where: { effectiveStatus(for: $0) == .confirmed }) { return .confirmed }
                if weekEntries.contains(where: { effectiveStatus(for: $0) == .submitted }) { return .submitted }
                if weekEntries.contains(where: { effectiveStatus(for: $0) == .draft }) { return .draft }
                return .pending
            }()
            
            statuses.append(WeekStatus(
                weekNumber: weekNumber,
                year: year,
                hours: weekHours,
                km: weekKm,
                status: status
            ))
        }
        
        return statuses
    }
    
    private func weekStatusRow(_ weekStatus: WeekStatus) -> some View {
        HStack {
            Text(weekStatus.weekLabel)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(width: 70, alignment: .leading)
            VStack(alignment: .leading) {
                Text("\(weekStatus.hours, specifier: "%.2f") hrs")
                    .font(.caption)
                    .foregroundColor(Color.ksrYellow)
                Text("\(weekStatus.km, specifier: "%.2f") km")
                    .font(.caption)
                    .foregroundColor(Color.ksrYellow)
            }
            .frame(width: 80)
            Spacer()
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
    
    // MARK: - Recent Work Hours
    private var recentWorkHoursView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Hours")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                NavigationLink(destination: WorkerWorkHoursView()) {
                    Text("View all")
                        .font(.caption)
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
                .foregroundColor(.black)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Announcements
    private var announcementsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Announcements")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                NavigationLink(destination: Text("Announcements List")) {
                    Text("View all")
                        .font(.caption)
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
    
    private func announcementCard(announcement: WorkerAPIService.Announcement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(announcement.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                priorityLabel(for: announcement.priority)
            }
            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                .lineLimit(2)
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatDate(announcement.publishedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                if let expiresAt = announcement.expiresAt {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Expires: \(formatDate(expiresAt))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : .white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func priorityLabel(for priority: WorkerAPIService.AnnouncementPriority) -> some View {
        let (color, text) = priorityConfig(for: priority)
        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private func priorityConfig(for priority: WorkerAPIService.AnnouncementPriority) -> (Color, String) {
        switch priority {
        case .high: return (.red, "High")
        case .normal: return (.blue, "Normal")
        case .low: return (.gray, "Low")
        }
    }
    
    private func statusLabel(for status: EntryStatus) -> (String, Color) {
        switch status {
        case .draft: return ("Draft", .orange)
        case .pending: return ("Pending", .blue)
        case .submitted: return ("Submitted", .purple)
        case .confirmed: return ("Confirmed", .green)
        case .rejected: return ("Rejected", .red)
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func computeEntryDuration(start: Date?, end: Date?, pauseMinutes: Int) -> Double {
        guard let start, let end else { return 0 }
        let interval = end.timeIntervalSince(start)
        let pauseSeconds = Double(pauseMinutes) * 60
        return max(0, (interval - pauseSeconds) / 3600)
    }
    
    // MARK: - Work Hour Card with enhanced rejection handling
    private func workHourCard(entry: WorkerAPIService.WorkHourEntry) -> some View {
        let hours = computeEntryDuration(
            start: entry.start_time,
            end: entry.end_time,
            pauseMinutes: entry.pause_minutes ?? 0
        )
        let entryStatus = effectiveStatus(for: entry)
        
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
                if let isDraft = entry.is_draft, isDraft {
                    Text("Draft")
                        .font(.caption2).bold()
                        .padding(4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                } else {
                    let (label, color) = statusLabel(for: entryStatus)
                    Text(label)
                        .font(.caption2).bold()
                        .padding(4)
                        .background(color.opacity(0.2))
                        .foregroundColor(color)
                        .cornerRadius(4)
                }
            }
            if let tasks = entry.tasks {
                Text("Task: \(tasks.title)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Task: \(entry.task_id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Kilometers: \(entry.kmFormatted)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // ✅ Enhanced rejection reason display
            if entryStatus == .rejected, let reason = entry.rejection_reason {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Rejected:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.1))
                        .cornerRadius(4)
                    
                    // Quick action button for rejected entries
                    Button {
                        viewModel.setSelectedTaskId(entry.task_id)
                        showWorkHoursForm = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                            Text("Fix & Resubmit")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                    .padding(.top, 2)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            // Add subtle border for rejected entries
            RoundedRectangle(cornerRadius: 10)
                .stroke(entryStatus == .rejected ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            if entryStatus == .rejected {
                viewModel.setSelectedTaskId(entry.task_id)
                showWorkHoursForm = true
            }
        }
    }
    
    // All other helper methods remain the same...
    // [Include all other methods from the original file]
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
