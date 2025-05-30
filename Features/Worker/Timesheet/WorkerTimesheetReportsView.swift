//
//  WorkerTimesheetReportsView.swift
//  KSR Cranes App
//

import SwiftUI

// Move TimeFilter outside the view for access by ViewModel
enum WorkerTimesheetTimeFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case recent = "Recent"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar.badge.plus"
        case .recent: return "clock.arrow.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .ksrInfo
        case .thisWeek: return .ksrSuccess
        case .thisMonth: return .ksrWarning
        case .recent: return .ksrYellow
        }
    }
}

struct WorkerTimesheetReportsView: View {
    @StateObject private var viewModel = WorkerTimesheetReportsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimesheet: WorkerAPIService.WorkerTimesheet?
    @State private var selectedView: ViewType = .list
    @State private var searchText = ""
    @State private var selectedFilter: WorkerTimesheetTimeFilter = .all
    
    enum ViewType: String, CaseIterable, Identifiable {
        case list = "List"
        case byTask = "By Task"
        case byMonth = "By Month"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .byTask: return "folder.fill"
            case .byMonth: return "calendar"
            }
        }
        
        var color: Color {
            switch self {
            case .list: return .ksrInfo
            case .byTask: return .ksrYellow
            case .byMonth: return .ksrSuccess
            }
        }
    }
    
    private var filteredTimesheets: [WorkerAPIService.WorkerTimesheet] {
        viewModel.filterTimesheets(searchText: searchText, timeFilter: selectedFilter)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Header Stats Section
                    headerStatsSection
                    
                    // Search and Filter Section
                    searchAndFilterSection
                    
                    // View Type Selection
                    viewTypeSelectionSection
                    
                    // Content Section
                    contentSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("My Timesheets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.primary)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(item: $selectedTimesheet) { timesheet in
                if let url = URL(string: timesheet.timesheetUrl) {
                    TimesheetPDFViewer(
                        url: url,
                        title: "Week \(timesheet.weekNumber), \(timesheet.year)",
                        onClose: { selectedTimesheet = nil }
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Stats Section
    private var headerStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                WorkerTimesheetStatCard(
                    title: "Total Timesheets",
                    value: "\(viewModel.timesheets.count)",
                    icon: "doc.text.fill",
                    color: .ksrPrimary
                )
                
                WorkerTimesheetStatCard(
                    title: "This Week",
                    value: "\(viewModel.thisWeekCount)",
                    icon: "calendar.badge.clock",
                    color: .ksrSuccess
                )
                
                WorkerTimesheetStatCard(
                    title: "This Month",
                    value: "\(viewModel.thisMonthCount)",
                    icon: "calendar.badge.plus",
                    color: .ksrWarning
                )
                
                WorkerTimesheetStatCard(
                    title: "Tasks",
                    value: "\(viewModel.uniqueTasksCount)",
                    icon: "folder.fill",
                    color: .ksrInfo
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ksrPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search timesheets, tasks...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        UIApplication.shared.hideKeyboard()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
            
            // Time Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WorkerTimesheetTimeFilter.allCases, id: \.id) { filter in
                        WorkerTimeFilterChip(
                            text: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            color: filter.color
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - View Type Selection
    private var viewTypeSelectionSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ViewType.allCases, id: \.id) { viewType in
                    ViewTypeChip(
                        viewType: viewType,
                        isSelected: selectedView == viewType
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedView = viewType
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Signed Timesheets")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                Text("\(filteredTimesheets.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Group {
                if viewModel.isLoading {
                    WorkerTimesheetsLoadingView(message: "Loading your timesheets...")
                } else if filteredTimesheets.isEmpty {
                    WorkerTimesheetsEmptyStateView(hasTimesheets: !viewModel.timesheets.isEmpty)
                } else {
                    switch selectedView {
                    case .list:
                        listView
                    case .byTask:
                        taskGroupedView
                    case .byMonth:
                        monthGroupedView
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ksrInfo.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - List View
    private var listView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredTimesheets) { timesheet in
                WorkerTimesheetListItem(timesheet: timesheet) {
                    selectedTimesheet = timesheet
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: filteredTimesheets.count)
    }
    
    // MARK: - Task Grouped View
    private var taskGroupedView: some View {
        LazyVStack(spacing: 20) {
            let groupedByTask = Dictionary(grouping: filteredTimesheets) { $0.task_id }
            ForEach(groupedByTask.keys.sorted(), id: \.self) { taskId in
                if let timesheets = groupedByTask[taskId] {
                    WorkerTimesheetGroupCard(
                        title: timesheets.first?.Tasks?.title ?? "Unknown Task",
                        subtitle: "Task ID: \(taskId)",
                        icon: "folder.fill",
                        color: .ksrYellow,
                        timesheets: timesheets,
                        onSelect: { selectedTimesheet = $0 }
                    )
                }
            }
        }
    }
    
    // MARK: - Month Grouped View
    private var monthGroupedView: some View {
        LazyVStack(spacing: 20) {
            let groupedByMonth = Dictionary(grouping: filteredTimesheets) { timesheet in
                let calendar = Calendar.current
                let date = calendar.date(from: DateComponents(
                    year: timesheet.year,
                    weekOfYear: timesheet.weekNumber
                )) ?? timesheet.created_at
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: date)
            }
            
            ForEach(groupedByMonth.keys.sorted(by: >), id: \.self) { month in
                if let timesheets = groupedByMonth[month] {
                    WorkerTimesheetGroupCard(
                        title: month,
                        subtitle: "\(timesheets.count) timesheets",
                        icon: "calendar",
                        color: .ksrSuccess,
                        timesheets: timesheets,
                        onSelect: { selectedTimesheet = $0 }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct WorkerTimeFilterChip: View {
    let text: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerTimesheetsLoadingView: View {
    let message: String
    
    init(message: String = "Loading timesheets...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct WorkerTimesheetsEmptyStateView: View {
    let hasTimesheets: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasTimesheets ? "magnifyingglass" : "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasTimesheets ? "No timesheets found" : "No timesheets available")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(hasTimesheets ?
                    "No timesheets match your current search or filter criteria." :
                    "Your approved timesheets will appear here once they're processed by your manager."
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, 40)
    }
}

struct WorkerTimesheetStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ViewTypeChip: View {
    let viewType: WorkerTimesheetReportsView.ViewType
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: viewType.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(viewType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? viewType.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerTimesheetListItem: View {
    let timesheet: WorkerAPIService.WorkerTimesheet
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.ksrYellow)
                    .frame(width: 32)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Week \(timesheet.weekNumber), \(timesheet.year)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Spacer()
                        
                        Text(dateFormatter.string(from: timesheet.created_at))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let taskTitle = timesheet.Tasks?.title {
                        Text(taskTitle)
                            .font(.caption)
                            .foregroundColor(.ksrInfo)
                            .lineLimit(1)
                    }
                }
                
                // Arrow
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
                    .foregroundColor(.ksrInfo)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ksrYellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerTimesheetGroupCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let timesheets: [WorkerAPIService.WorkerTimesheet]
    let onSelect: (WorkerAPIService.WorkerTimesheet) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .lineLimit(2)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(timesheets.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(timesheets.prefix(10)) { timesheet in
                            WorkerTimesheetListItem(timesheet: timesheet) {
                                onSelect(timesheet)
                            }
                        }
                        
                        if timesheets.count > 10 {
                            Text("and \(timesheets.count - 10) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Extension for hiding keyboard has been moved to UIApplication+Extensions.swift

// MARK: - Preview
struct WorkerTimesheetReportsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkerTimesheetReportsView()
                .preferredColorScheme(.light)
            
            WorkerTimesheetReportsView()
                .preferredColorScheme(.dark)
        }
    }
}
