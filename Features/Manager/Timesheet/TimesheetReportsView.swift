//
//  TimesheetReportsView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 18/05/2025.
//  Visual improvements added - Modern design with enhanced UI

import SwiftUI
import UIKit
import PDFKit

struct TimesheetReportsView: View {
    @StateObject private var viewModel = TimesheetReportsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimesheet: ManagerAPIService.Timesheet?
    @State private var selectedTab: Tab = .tasks
    @State private var searchText = ""
    @State private var selectedFilter: TimeFilter = .all
    
    enum Tab: String, CaseIterable, Identifiable {
        case tasks = "By Tasks"
        case workers = "By Workers"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .tasks: return "folder.fill"
            case .workers: return "person.3.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .tasks: return .ksrYellow
            case .workers: return .ksrInfo
            }
        }
    }
    
    enum TimeFilter: String, CaseIterable, Identifiable {
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
    
    // Grupowanie timesheetów
    private var groupedByTasks: [Int: [ManagerAPIService.Timesheet]] {
        Dictionary(grouping: filteredTimesheets) { $0.task_id }
    }
    
    private var groupedByWorkers: [Int: [ManagerAPIService.Timesheet]] {
        Dictionary(grouping: filteredTimesheets) { $0.employee_id ?? 0 }
    }
    
    // Filtrowanie timesheetów
    private var filteredTimesheets: [ManagerAPIService.Timesheet] {
        var timesheets = viewModel.timesheets
        
        // Apply time filter
        if selectedFilter != .all {
            let calendar = Calendar.current
            let now = Date()
            
            timesheets = timesheets.filter { timesheet in
                switch selectedFilter {
                case .thisWeek:
                    let weekOfYear = calendar.component(.weekOfYear, from: now)
                    let yearComponent = calendar.component(.year, from: now)
                    return timesheet.weekNumber == weekOfYear && timesheet.year == yearComponent
                case .thisMonth:
                    let monthComponent = calendar.component(.month, from: now)
                    let yearComponent = calendar.component(.year, from: now)
                    // Approximate week-to-month conversion
                    return timesheet.year == yearComponent && (timesheet.weekNumber >= (monthComponent - 1) * 4)
                case .recent:
                    // Last 30 days
                    return calendar.dateInterval(of: .day, for: timesheet.created_at)?.start ?? timesheet.created_at >= calendar.date(byAdding: .day, value: -30, to: now) ?? now
                case .all:
                    return true
                }
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            timesheets = timesheets.filter { timesheet in
                let taskTitle = timesheet.Tasks?.title.lowercased() ?? ""
                let workerName = timesheet.Employees?.name.lowercased() ?? ""
                let weekNumber = String(timesheet.weekNumber)
                let year = String(timesheet.year)
                return taskTitle.contains(lowercasedSearch) ||
                       workerName.contains(lowercasedSearch) ||
                       weekNumber.contains(lowercasedSearch) ||
                       year.contains(lowercasedSearch)
            }
        }
        
        return timesheets.sorted { $0.created_at > $1.created_at }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Header with statistics
                    headerStatsSection
                    
                    // Search and filter section
                    searchAndFilterSection
                    
                    // Tab selection
                    tabSelectionSection
                    
                    // Timesheets content
                    timesheetsContentSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("Signed Timesheets")
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
                    PDFViewerWithActions(
                        url: url,
                        onClose: { selectedTimesheet = nil }
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }
    
    // MARK: - Background Gradient
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
        HStack(spacing: 16) {
            TimesheetStatCard(
                title: "Total Timesheets",
                value: "\(viewModel.timesheets.count)",
                icon: "doc.text.fill",
                color: .ksrYellow
            )
            
            TimesheetStatCard(
                title: "This Week",
                value: "\(thisWeekCount)",
                icon: "calendar.badge.clock",
                color: .ksrSuccess
            )
            
            TimesheetStatCard(
                title: "Active Tasks",
                value: "\(uniqueTasksCount)",
                icon: "folder.fill",
                color: .ksrInfo
            )
        }
    }
    
    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let yearComponent = calendar.component(.year, from: now)
        
        return viewModel.timesheets.filter { timesheet in
            timesheet.weekNumber == weekOfYear && timesheet.year == yearComponent
        }.count
    }
    
    private var uniqueTasksCount: Int {
        Set(viewModel.timesheets.map { $0.task_id }).count
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search timesheets, tasks, workers...", text: $searchText)
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
            
            // Time Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeFilter.allCases, id: \.id) { filter in
                        TimeFilterChip(
                            filter: filter,
                            isSelected: selectedFilter == filter
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
    
    // MARK: - Tab Selection Section
    private var tabSelectionSection: some View {
        HStack(spacing: 12) {
            ForEach(Tab.allCases, id: \.id) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
    }
    
    // MARK: - Timesheets Content Section
    private var timesheetsContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(filteredTimesheets.count) timesheets")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Group {
                if viewModel.isLoading {
                    TimesheetsLoadingView()
                } else if filteredTimesheets.isEmpty {
                    TimesheetsEmptyStateView(hasTimesheets: !viewModel.timesheets.isEmpty)
                } else {
                    if selectedTab == .tasks {
                        taskGroupedView
                    } else {
                        workerGroupedView
                    }
                }
            }
        }
    }
    
    // MARK: - Task Grouped View
    private var taskGroupedView: some View {
        LazyVStack(spacing: 20) {
            ForEach(groupedByTasks.keys.sorted(), id: \.self) { taskId in
                if let timesheets = groupedByTasks[taskId] {
                    TimesheetGroupCard(
                        title: timesheets.first?.Tasks?.title ?? "Unknown Task",
                        subtitle: "Task ID: \(taskId)",
                        icon: "folder.fill",
                        color: .ksrYellow,
                        timesheets: timesheets,
                        onSelect: { selectedTimesheet = $0 }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: filteredTimesheets.count)
    }
    
    // MARK: - Worker Grouped View
    private var workerGroupedView: some View {
        LazyVStack(spacing: 20) {
            ForEach(groupedByWorkers.keys.sorted(), id: \.self) { employeeId in
                if let timesheets = groupedByWorkers[employeeId] {
                    TimesheetGroupCard(
                        title: timesheets.first?.Employees?.name ?? "Unknown Worker",
                        subtitle: "Employee ID: \(employeeId)",
                        icon: "person.fill",
                        color: .ksrInfo,
                        timesheets: timesheets,
                        onSelect: { selectedTimesheet = $0 }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: filteredTimesheets.count)
    }
}

// MARK: - PDF Viewer with Actions Component

struct PDFViewerWithActions: View {
    let url: URL
    let onClose: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDownloading = false
    @State private var showDownloadAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PDFViewer(source: PDFSource.url(url))
                
                // Simple loading overlay
                if isDownloading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.ksrYellow)
                        
                        Text("Preparing PDF...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.9) : Color(.systemGray5).opacity(0.9))
                    )
                }
            }
            .navigationTitle("Timesheet PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onClose()
                    }
                    .foregroundColor(.ksrYellow)
                    .disabled(isDownloading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            printPDF()
                        } label: {
                            Image(systemName: "printer")
                                .foregroundColor(.ksrInfo)
                        }
                        .disabled(isDownloading)
                        
                        Button {
                            sharePDF()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.ksrSuccess)
                        }
                        .disabled(isDownloading)
                    }
                }
            }
            .alert("Download Failed", isPresented: $showDownloadAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to download PDF for sharing. Please try again.")
            }
        }
    }
    
    private func printPDF() {
        Task {
            await MainActor.run {
                isDownloading = true
            }
            
            do {
                #if DEBUG
                print("[PDFViewerWithActions] Quick download for printing...")
                #endif
                
                let data = try await URLSession.shared.data(from: url).0
                
                await MainActor.run {
                    isDownloading = false
                    let printController = UIPrintInteractionController.shared
                    printController.printingItem = data
                    printController.present(animated: true) { controller, completed, error in
                        #if DEBUG
                        if let error = error {
                            print("[PDFViewerWithActions] Printing failed: \(error)")
                        } else if completed {
                            print("[PDFViewerWithActions] Printing completed")
                        }
                        #endif
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    showDownloadAlert = true
                }
                #if DEBUG
                print("[PDFViewerWithActions] Failed to download PDF for printing: \(error)")
                #endif
            }
        }
    }
    
    private func sharePDF() {
        Task {
            await MainActor.run {
                isDownloading = true
            }
            
            do {
                #if DEBUG
                print("[PDFViewerWithActions] Quick download for sharing...")
                #endif
                
                let data = try await URLSession.shared.data(from: url).0
                
                #if DEBUG
                print("[PDFViewerWithActions] Downloaded \(data.count) bytes")
                #endif
                
                await MainActor.run {
                    isDownloading = false
                    
                    // Create temporary file with proper extension
                    let tempDir = NSTemporaryDirectory()
                    let filename = "Timesheet_\(Int(Date().timeIntervalSince1970)).pdf"
                    let tempPath = (tempDir as NSString).appendingPathComponent(filename)
                    let tempURL = URL(fileURLWithPath: tempPath)
                    
                    do {
                        try data.write(to: tempURL)
                        
                        // Verify file was created
                        guard FileManager.default.fileExists(atPath: tempURL.path) else {
                            showDownloadAlert = true
                            return
                        }
                        
                        #if DEBUG
                        print("[PDFViewerWithActions] Created temp file: \(tempURL.path)")
                        #endif
                        
                        // Use the existing ShareSheet from TimesheetReceiptView
                        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                        
                        // Present directly using UIApplication
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            
                            // Find the topmost presented view controller
                            var topVC = rootVC
                            while let presentedVC = topVC.presentedViewController {
                                topVC = presentedVC
                            }
                            
                            topVC.present(activityVC, animated: true)
                            
                            #if DEBUG
                            print("[PDFViewerWithActions] Presented activity controller directly")
                            #endif
                        }
                        
                    } catch {
                        showDownloadAlert = true
                        #if DEBUG
                        print("[PDFViewerWithActions] Failed to create temp file: \(error)")
                        #endif
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    showDownloadAlert = true
                }
                #if DEBUG
                print("[PDFViewerWithActions] Failed to download PDF for sharing: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Simple ShareSheet for PDF Data

struct ShareSheetForPDF: UIViewControllerRepresentable {
    let pdfData: Data
    let filename: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a simple activity controller with just the data
        let controller = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: nil
        )
        
        // Set completion handler to debug
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            #if DEBUG
            print("[ShareSheetForPDF] Activity: \(activityType?.rawValue ?? "nil"), completed: \(completed)")
            if let error = error {
                print("[ShareSheetForPDF] Error: \(error)")
            }
            #endif
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Supporting Views

struct TimesheetStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TimeFilterChip: View {
    let filter: TimesheetReportsView.TimeFilter
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? filter.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabButton: View {
    let tab: TimesheetReportsView.Tab
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tab.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimesheetGroupCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let timesheets: [ManagerAPIService.Timesheet]
    let onSelect: (ManagerAPIService.Timesheet) -> Void
    
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
                
                // Quick stats
                HStack(spacing: 20) {
                    TimesheetStatItem(icon: "doc.text", value: "\(timesheets.count) sheets", color: color)
                    
                    let weekRange = getWeekRange()
                    if !weekRange.isEmpty {
                        TimesheetStatItem(icon: "calendar", value: weekRange, color: .ksrInfo)
                    }
                }
            }
            .padding(20)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(timesheets.prefix(10)) { timesheet in
                            TimesheetListItem(timesheet: timesheet) {
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
    
    private func getWeekRange() -> String {
        let weeks = timesheets.map { "W\($0.weekNumber)" }
        let uniqueWeeks = Array(Set(weeks)).sorted()
        if uniqueWeeks.count <= 3 {
            return uniqueWeeks.joined(separator: ", ")
        } else {
            return "\(uniqueWeeks.first ?? "")–\(uniqueWeeks.last ?? "")"
        }
    }
}

struct TimesheetStatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct TimesheetListItem: View {
    let timesheet: ManagerAPIService.Timesheet
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
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.ksrYellow)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Week \(timesheet.weekNumber), \(timesheet.year)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("Created: \(dateFormatter.string(from: timesheet.created_at))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundColor(.ksrInfo)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimesheetsLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading timesheets...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct TimesheetsEmptyStateView: View {
    let hasTimesheets: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasTimesheets ? "magnifyingglass" : "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasTimesheets ? "No timesheets found" : "No signed timesheets")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(hasTimesheets ?
                     "No timesheets match your current search or filter criteria." :
                     "No signed timesheets are available for your projects yet."
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

struct TimesheetReportsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimesheetReportsView()
                .preferredColorScheme(.light)
            TimesheetReportsView()
                .preferredColorScheme(.dark)
        }
    }
}
