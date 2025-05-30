// TimesheetReportsView.swift
// KSR Cranes App
// Created by Maksymilian Marcinowski on 18/05/2025.
// Visual improvements added - Modern design with enhanced UI

import SwiftUI
import UIKit
import PDFKit

// MARK: - Missing Supporting Components (local versions to avoid conflicts)

struct TimeFilterChip: View {
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

struct TimesheetTabButton: View {
    let tab: TimesheetReportsView.TimesheetTab
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimesheetsLoadingView: View {
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

struct TimesheetsEmptyStateView: View {
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
                    "Signed timesheets will appear here once they're processed."
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

// MARK: - Main View

struct TimesheetReportsView: View {
    @StateObject private var viewModel = TimesheetReportsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimesheet: ManagerAPIService.Timesheet?
    @State private var selectedTab: TimesheetTab = .tasks
    @State private var searchText = ""
    @State private var selectedFilter: TimeFilter = .all
    
    enum TimesheetTab: String, CaseIterable {
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
    
    private var groupedByTasks: [Int: [ManagerAPIService.Timesheet]] {
        Dictionary(grouping: filteredTimesheets) { $0.task_id }
    }
    
    private var groupedByWorkers: [Int: [ManagerAPIService.Timesheet]] {
        Dictionary(grouping: filteredTimesheets) { $0.employee_id ?? 0 }
    }
    
    private var filteredTimesheets: [ManagerAPIService.Timesheet] {
        var timesheets = viewModel.timesheets
        
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
                    return timesheet.year == yearComponent && (timesheet.weekNumber >= (monthComponent - 1) * 4)
                case .recent:
                    return calendar.dateInterval(of: .day, for: timesheet.created_at)?.start ?? timesheet.created_at >= calendar.date(byAdding: .day, value: -30, to: now) ?? now
                case .all:
                    return true
                }
            }
        }
        
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
                    headerStatsSection
                    searchAndFilterSection
                    tabSelectionSection
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
                            viewModel.loadTimesheets()
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
                viewModel.loadTimesheets()
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadTimesheets()
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
    
    private var headerStatsSection: some View {
        HStack(spacing: 16) {
            ManagerTimesheetStatCard(
                title: "Total Timesheets",
                value: "\(viewModel.timesheets.count)",
                icon: "doc.text.fill",
                color: .ksrYellow
            )
            
            ManagerTimesheetStatCard(
                title: "This Week",
                value: "\(thisWeekCount)",
                icon: "calendar.badge.clock",
                color: .ksrSuccess
            )
            
            ManagerTimesheetStatCard(
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
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search timesheets, tasks, workers...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        // Remove UIApplication.shared.hideKeyboard() call as it conflicts with existing implementation
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeFilter.allCases, id: \.id) { filter in
                        TimeFilterChip(
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
    
    private var tabSelectionSection: some View {
        HStack(spacing: 12) {
            ForEach(TimesheetTab.allCases, id: \.id) { tab in
                TimesheetTabButton(
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
    
    private var taskGroupedView: some View {
        LazyVStack(spacing: 20) {
            ForEach(groupedByTasks.keys.sorted(), id: \.self) { taskId in
                if let timesheets = groupedByTasks[taskId] {
                    ManagerTimesheetGroupCard(
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
    
    private var workerGroupedView: some View {
        LazyVStack(spacing: 20) {
            ForEach(groupedByWorkers.keys.sorted(), id: \.self) { employeeId in
                if let timesheets = groupedByWorkers[employeeId] {
                    let workerName = timesheets.first?.Employees?.name ?? ""
                    ManagerTimesheetGroupCard(
                        title: workerName.isEmpty ? "Unknown Worker" : workerName,
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

// MARK: - Manager-specific Supporting Views

struct ManagerTimesheetStatCard: View {
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

struct ManagerTimesheetGroupCard: View {
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
                
                HStack(spacing: 20) {
                    TimesheetStatItem(icon: "doc.text", value: "\(timesheets.count) sheets", color: color)
                    
                    let weekRange = getWeekRange()
                    if !weekRange.isEmpty {
                        TimesheetStatItem(icon: "calendar", value: weekRange, color: .ksrInfo)
                    }
                }
            }
            .padding(20)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(timesheets.prefix(10)) { timesheet in
                            ManagerTimesheetListItem(timesheet: timesheet) {
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

struct ManagerTimesheetListItem: View {
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
                    
                    let tempDir = NSTemporaryDirectory()
                    let filename = "Timesheet_\(Int(Date().timeIntervalSince1970)).pdf"
                    let tempPath = (tempDir as NSString).appendingPathComponent(filename)
                    let tempURL = URL(fileURLWithPath: tempPath)
                    
                    do {
                        try data.write(to: tempURL)
                        
                        guard FileManager.default.fileExists(atPath: tempURL.path) else {
                            showDownloadAlert = true
                            return
                        }
                        
                        #if DEBUG
                        print("[PDFViewerWithActions] Created temp file: \(tempURL.path)")
                        #endif
                        
                        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            
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

// MARK: - UIApplication Extension removed to avoid conflicts
// (hideKeyboard functionality should be defined elsewhere in the project)

// MARK: - Preview
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
