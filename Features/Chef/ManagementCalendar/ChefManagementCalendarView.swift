import SwiftUI
import PDFKit

struct ChefManagementCalendarView: View {
    @StateObject private var viewModel = ChefManagementCalendarViewModel()
    @State private var showingFilters = false
    @State private var showingEventCreation = false
    @State private var showingWorkerAssignment = false
    @State private var showingExportOptions = false
    @State private var selectedTaskForAssignment: Int?
    @State private var isFullScreenMode = false
    @State private var dividerPosition: CGFloat = 0.6 // 60% calendar, 40% resources
    @State private var isDraggingDivider = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                let shouldUseFullScreen = isLandscape && isFullScreenMode
                
                if shouldUseFullScreen {
                    // Full Screen Horizontal Mode
                    fullScreenHorizontalLayout(geometry: geometry)
                        .navigationBarHidden(true)
                } else {
                    // Standard Portrait Mode
                    standardPortraitLayout(geometry: geometry)
                }
            }
        }
        .navigationTitle("Management Calendar")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingFilters) {
            CalendarFiltersSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEventCreation) {
            CreateEventSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingWorkerAssignment) {
            WorkerAssignmentSheet(
                viewModel: viewModel,
                taskId: selectedTaskForAssignment
            )
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.loadInitialData()
        }
        .onChange(of: UIDevice.current.orientation) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Auto-enable full screen in landscape
                if newValue.isLandscape && !isFullScreenMode {
                    isFullScreenMode = true
                }
            }
        }
    }
    
    // MARK: - Standard Portrait Layout
    
    @ViewBuilder
    private func standardPortraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Calendar Controls Header - Fixed height
            CalendarControlsHeaderView(
                viewModel: viewModel,
                showingFilters: $showingFilters,
                showingEventCreation: $showingEventCreation,
                isFullScreenMode: $isFullScreenMode
            )
            .frame(height: 180) // Fixed header height
            
            // Main Content Area - Flexible
            HStack(spacing: 0) {
                // Calendar Grid - Scrollable
                ScrollView {
                    CalendarMainContentView(
                        viewModel: viewModel,
                        showingWorkerAssignment: $showingWorkerAssignment,
                        selectedTaskForAssignment: $selectedTaskForAssignment,
                        isFullScreenMode: false
                    )
                    .padding(.bottom, 220) // Space for detail panel
                }
                .frame(width: viewModel.showingResourcePanel ? 
                       geometry.size.width * 0.65 : geometry.size.width)
                .refreshable {
                    await viewModel.refreshCalendarData()
                }
                
                // Resource Panel (Collapsible)
                if viewModel.showingResourcePanel {
                    ResourceAllocationPanelView(viewModel: viewModel, isFullScreenMode: false)
                        .frame(width: geometry.size.width * 0.35)
                        .transition(.move(edge: .trailing))
                }
            }
            .frame(maxHeight: .infinity)
            
            // Selected Date Detail Panel - Fixed at bottom
            SelectedDateDetailPanelView(viewModel: viewModel)
                .frame(height: 200)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .top
                )
        }
    }
    
    // MARK: - Full Screen Horizontal Layout
    
    @ViewBuilder
    private func fullScreenHorizontalLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Compact Header for Full Screen Mode
            FullScreenCalendarHeaderView(
                viewModel: viewModel,
                showingFilters: $showingFilters,
                showingEventCreation: $showingEventCreation,
                showingExportOptions: $showingExportOptions,
                isFullScreenMode: $isFullScreenMode
            )
            .frame(height: 120) // Compact header
            
            // Split Screen Content
            HStack(spacing: 0) {
                // Left: Enhanced Calendar Section
                VStack(spacing: 0) {
                    ScrollView {
                        EnhancedLandscapeCalendarView(
                            viewModel: viewModel,
                            showingWorkerAssignment: $showingWorkerAssignment,
                            selectedTaskForAssignment: $selectedTaskForAssignment
                        )
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await viewModel.refreshCalendarData()
                    }
                    
                    // Inline Selected Date Details
                    if !viewModel.eventsForSelectedDate.isEmpty {
                        InlineSelectedDateView(viewModel: viewModel)
                            .frame(height: 100)
                            .background(Color(.systemGray6))
                    }
                }
                .frame(width: geometry.size.width * dividerPosition)
                
                // Resizable Divider
                ResizableDivider(
                    position: $dividerPosition,
                    isDragging: $isDraggingDivider,
                    geometry: geometry
                )
                
                // Right: Enhanced Resource Management Panel
                EnhancedResourceManagementPanel(
                    viewModel: viewModel,
                    geometry: geometry
                )
                .frame(width: geometry.size.width * (1 - dividerPosition))
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .onTapGesture(count: 2) {
            // Double-tap to exit full screen
            withAnimation(.easeInOut(duration: 0.3)) {
                isFullScreenMode = false
            }
        }
    }
}

// MARK: - Calendar Controls Header

struct CalendarControlsHeaderView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingFilters: Bool
    @Binding var showingEventCreation: Bool
    @Binding var isFullScreenMode: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Controls Row
            HStack {
                // View Mode Selector
                ViewModeSelector(selectedMode: $viewModel.viewMode)
                
                Spacer()
                
                // Full Screen Toggle (landscape only)
                GeometryReader { geo in
                    if geo.size.width > geo.size.height {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isFullScreenMode.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isFullScreenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                Text(isFullScreenMode ? "Exit" : "Full Screen")
                            }
                            .font(.caption)
                            .foregroundColor(isFullScreenMode ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isFullScreenMode ? Color.purple : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(width: 100, height: 32)
                
                // Resource Panel Toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.showingResourcePanel.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                        Text("Resources")
                    }
                    .font(.caption)
                    .foregroundColor(viewModel.showingResourcePanel ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.showingResourcePanel ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // Calendar Navigation
            HStack {
                // Previous Month
                Button(action: { viewModel.navigateToMonth(.previous) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Current Month/Year
                VStack(spacing: 2) {
                    Text(viewModel.displayedMonth, format: .dateTime.month(.wide).year())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let summary = viewModel.calendarSummary {
                        Text("\(summary.totalEvents) events • \(summary.availableWorkers) available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Next Month
                Button(action: { viewModel.navigateToMonth(.next) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Action Buttons Row
            HStack(spacing: 12) {
                // Today Button
                Button("Today") {
                    viewModel.navigateToToday()
                }
                .buttonStyle(.bordered)
                
                // Filters
                Button(action: { showingFilters = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filters")
                        
                        // Filter count badge
                        if !viewModel.searchText.isEmpty || 
                           viewModel.selectedPriority != nil ||
                           !viewModel.selectedWorkerIds.isEmpty ||
                           viewModel.showingConflictsOnly {
                            Text("\(activeFilterCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                // Refresh Button
                Button(action: {
                    Task {
                        await viewModel.refreshCalendarData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isLoading)
                
                // Create Event
                Button(action: { showingEventCreation = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Create")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Event Type Filter Chips
            EventTypeFilterChips(viewModel: viewModel)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if !viewModel.searchText.isEmpty { count += 1 }
        if viewModel.selectedPriority != nil { count += 1 }
        if !viewModel.selectedWorkerIds.isEmpty { count += 1 }
        if viewModel.showingConflictsOnly { count += 1 }
        return count
    }
}

// MARK: - View Mode Selector

struct ViewModeSelector: View {
    @Binding var selectedMode: CalendarViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Button(mode.displayName) {
                    selectedMode = mode
                }
                .font(.caption)
                .foregroundColor(selectedMode == mode ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedMode == mode ? Color.blue : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(2)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Event Type Filter Chips

struct EventTypeFilterChips: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CalendarEventType.allCases, id: \.self) { eventType in
                    EventTypeChip(
                        eventType: eventType,
                        isSelected: viewModel.activeEventTypes.contains(eventType),
                        count: eventCountForType(eventType)
                    ) {
                        viewModel.toggleEventType(eventType)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func eventCountForType(_ type: CalendarEventType) -> Int {
        viewModel.calendarEvents.filter { $0.type == type }.count
    }
}

struct EventTypeChip: View {
    let eventType: CalendarEventType
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: eventType.color))
                    .frame(width: 8, height: 8)
                
                Text(eventType.displayName)
                    .font(.caption)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: eventType.color) : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Calendar Main Content

struct CalendarMainContentView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingWorkerAssignment: Bool
    @Binding var selectedTaskForAssignment: Int?
    let isFullScreenMode: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.calendarEvents.isEmpty {
                // Loading State
                CalendarLoadingView()
            } else {
                switch viewModel.viewMode {
                case .month:
                    MonthCalendarView(
                        viewModel: viewModel,
                        showingWorkerAssignment: $showingWorkerAssignment,
                        selectedTaskForAssignment: $selectedTaskForAssignment
                    )
                case .week:
                    WeekCalendarView(
                        viewModel: viewModel,
                        showingWorkerAssignment: $showingWorkerAssignment,
                        selectedTaskForAssignment: $selectedTaskForAssignment
                    )
                case .timeline:
                    TimelineCalendarView(
                        viewModel: viewModel,
                        showingWorkerAssignment: $showingWorkerAssignment,
                        selectedTaskForAssignment: $selectedTaskForAssignment
                    )
                case .agenda:
                    AgendaCalendarView(
                        viewModel: viewModel,
                        showingWorkerAssignment: $showingWorkerAssignment,
                        selectedTaskForAssignment: $selectedTaskForAssignment
                    )
                }
            }
            
            // Add some spacing at bottom to prevent overlap with tab bar
            Spacer()
                .frame(height: 20)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingWorkerAssignment: Bool
    @Binding var selectedTaskForAssignment: Int?
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            WeekdayHeaders()
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(calendarDates, id: \.self) { date in
                    ManagementCalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        events: viewModel.getEventsForDate(date),
                        onTap: { 
                            // Only allow selection of current month dates
                            if calendar.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month) {
                                viewModel.selectDate(date)
                            }
                        },
                        onEventTap: { event in
                            if event.type == .task {
                                selectedTaskForAssignment = event.relatedEntities.taskId
                                showingWorkerAssignment = true
                            } else {
                                viewModel.selectEvent(event)
                            }
                        }
                    )
                    .frame(height: 85) // Slightly taller for better touch target
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private var calendarDates: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end)
        else { return [] }
        
        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
}

// MARK: - Calendar Day View

struct ManagementCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let events: [ManagementCalendarEvent]
    let onTap: () -> Void
    let onEventTap: (ManagementCalendarEvent) -> Void
    
    private let calendar = Calendar.current
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            VStack(spacing: 2) {
                // Date Number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Event Indicators
                VStack(spacing: 1) {
                    ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { index, event in
                        EventIndicatorView(event: event) {
                            onEventTap(event)
                        }
                    }
                    
                    if events.count > 3 {
                        Text("+\(events.count - 3)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .disabled(!isCurrentMonth) // Disable tap for dates outside current month
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue.opacity(0.2)
        } else if !isCurrentMonth {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 1
    }
}

// MARK: - Event Indicator View

struct EventIndicatorView: View {
    let event: ManagementCalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 2) {
                Circle()
                    .fill(Color(hex: event.type.color))
                    .frame(width: 4, height: 4)
                
                Text(event.title)
                    .font(.system(size: 8))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !event.conflicts.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.red)
                }
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(Color(hex: event.type.color).opacity(0.2))
            .cornerRadius(3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Weekday Headers

struct WeekdayHeaders: View {
    private let weekdays = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK: - Loading View

struct CalendarLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading calendar data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Placeholder Views (To be implemented)

struct WeekCalendarView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingWorkerAssignment: Bool
    @Binding var selectedTaskForAssignment: Int?
    
    private let calendar = Calendar.current
    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 60
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Week dates header
                weekHeaderView
                
                // Scrollable content with hours and days
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Time column
                        timeColumnView
                        
                        // Days columns
                        ForEach(weekDays, id: \.self) { date in
                            dayColumnView(for: date)
                        }
                    }
                }
            }
        }
    }
    
    private var weekHeaderView: some View {
        HStack(spacing: 0) {
            // Empty space for time column
            Color.clear
                .frame(width: timeColumnWidth)
            
            // Day headers
            ForEach(weekDays, id: \.self) { date in
                VStack(spacing: 4) {
                    Text(dayFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.title3)
                        .fontWeight(calendar.isDateInToday(date) ? .bold : .medium)
                        .foregroundColor(calendar.isDateInToday(date) ? .ksrPrimary : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    calendar.isDate(date, inSameDayAs: viewModel.selectedDate) ?
                    Color.ksrPrimary.opacity(0.1) : Color.clear
                )
                .onTapGesture {
                    viewModel.selectDate(date)
                }
            }
        }
        .background(Color(.systemGray6))
    }
    
    private var timeColumnView: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text("\(hour):00")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: timeColumnWidth, height: hourHeight)
                    .overlay(
                        Divider()
                            .frame(height: 1)
                            .background(Color(.systemGray5)),
                        alignment: .top
                    )
            }
        }
        .background(Color(.systemGray6))
    }
    
    private func dayColumnView(for date: Date) -> some View {
        let dayEvents = viewModel.getEventsForDate(date)
        
        return ZStack(alignment: .topLeading) {
            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: hourHeight)
                        .overlay(
                            Divider()
                                .frame(height: 1)
                                .background(Color(.systemGray5)),
                            alignment: .top
                        )
                }
            }
            
            // Events overlay
            ForEach(dayEvents) { event in
                if let eventHour = calendar.component(.hour, from: event.date) as Int? {
                    WeekEventView(
                        event: event,
                        hourHeight: hourHeight,
                        onTap: {
                            if event.type == .task {
                                selectedTaskForAssignment = event.relatedEntities.taskId
                                showingWorkerAssignment = true
                            } else {
                                viewModel.selectEvent(event)
                            }
                        }
                    )
                    .offset(y: CGFloat(eventHour) * hourHeight)
                }
            }
        }
        .frame(width: 120)
        .background(
            calendar.isDate(date, inSameDayAs: Date()) ?
            Color.ksrPrimary.opacity(0.05) : Color.clear
        )
    }
    
    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: viewModel.displayedMonth) else {
            return []
        }
        
        var days: [Date] = []
        var date = weekInterval.start
        
        while date < weekInterval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}

// Week Event View Component
struct WeekEventView: View {
    let event: ManagementCalendarEvent
    let hourHeight: CGFloat
    let onTap: () -> Void
    
    private var duration: CGFloat {
        // Calculate event duration in hours (minimum 1 hour for visibility)
        if let endDate = event.endDate {
            let hours = endDate.timeIntervalSince(event.date) / 3600
            return max(1, hours) * hourHeight
        }
        return hourHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(2)
            
            if duration > hourHeight {
                Text(event.type.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(4)
        .frame(width: 110, height: duration - 4, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: event.type.color).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: event.type.color), lineWidth: 1)
                )
        )
        .onTapGesture(perform: onTap)
    }
}

struct TimelineCalendarView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingWorkerAssignment: Bool
    @Binding var selectedTaskForAssignment: Int?
    
    private let calendar = Calendar.current
    private let dayWidth: CGFloat = 40
    private let rowHeight: CGFloat = 44
    private let projectColumnWidth: CGFloat = 200
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Timeline header with dates
                timelineHeaderView
                
                // Projects/Tasks rows
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Project names column
                        projectNamesColumn
                        
                        // Timeline grid
                        timelineGridView
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var timelineHeaderView: some View {
        HStack(spacing: 0) {
            // Empty space for project column
            Text("Projects / Tasks")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: projectColumnWidth, alignment: .leading)
                .padding(.horizontal)
            
            // Date headers
            ForEach(timelineDates, id: \.self) { date in
                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.caption2)
                        .fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                    
                    Text(monthFormatter.string(from: date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: dayWidth)
                .foregroundColor(calendar.isDateInToday(date) ? .ksrPrimary : .primary)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var projectNamesColumn: some View {
        VStack(spacing: 0) {
            ForEach(groupedEvents) { group in
                HStack(spacing: 8) {
                    // Project icon
                    Image(systemName: group.type.icon)
                        .foregroundColor(Color(hex: group.type.color))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if !group.subtitle.isEmpty {
                            Text(group.subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: projectColumnWidth, height: rowHeight, alignment: .leading)
                .padding(.horizontal)
                .background(
                    group.id == viewModel.selectedEvent?.id ?
                    Color.ksrPrimary.opacity(0.1) : Color.clear
                )
            }
        }
        .background(Color(.systemGray6))
    }
    
    private var timelineGridView: some View {
        ZStack(alignment: .topLeading) {
            // Grid background
            timelineGridBackground
            
            // Event bars
            ForEach(Array(groupedEvents.enumerated()), id: \.element.id) { index, group in
                if let startIndex = dateIndex(for: group.startDate),
                   let endIndex = dateIndex(for: group.endDate ?? group.startDate) {
                    
                    TimelineEventBar(
                        event: group,
                        startOffset: CGFloat(startIndex) * dayWidth,
                        width: CGFloat(endIndex - startIndex + 1) * dayWidth,
                        onTap: {
                            if group.type == .task {
                                selectedTaskForAssignment = group.relatedTaskId
                                showingWorkerAssignment = true
                            } else {
                                // Convert TimelineEvent back to ManagementCalendarEvent
                                if let event = viewModel.filteredEvents.first(where: { $0.id == group.id }) {
                                    viewModel.selectEvent(event)
                                }
                            }
                        }
                    )
                    .offset(y: CGFloat(index) * rowHeight)
                }
            }
        }
    }
    
    private var timelineGridBackground: some View {
        HStack(spacing: 0) {
            ForEach(timelineDates, id: \.self) { date in
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: dayWidth)
                    .overlay(
                        Rectangle()
                            .fill(calendar.isDateInWeekend(date) ? Color(.systemGray5) : Color.clear)
                            .opacity(0.3)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            }
        }
        .frame(height: CGFloat(groupedEvents.count) * rowHeight)
    }
    
    private var timelineDates: [Date] {
        let range = calendar.dateInterval(of: .month, for: viewModel.displayedMonth) ?? DateInterval(start: Date(), duration: 0)
        var dates: [Date] = []
        var date = range.start
        
        while date <= range.end {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
    }
    
    private var groupedEvents: [TimelineEvent] {
        // Group events by project/type for timeline display
        var groups: [TimelineEvent] = []
        
        // Group by projects
        let projectEvents = viewModel.filteredEvents.filter { $0.type == .project }
        for event in projectEvents {
            groups.append(TimelineEvent(from: event))
        }
        
        // Group by tasks
        let taskEvents = viewModel.filteredEvents.filter { $0.type == .task }
        for event in taskEvents {
            groups.append(TimelineEvent(from: event))
        }
        
        // Add other event types
        let otherEvents = viewModel.filteredEvents.filter { $0.type != .project && $0.type != .task }
        for event in otherEvents {
            groups.append(TimelineEvent(from: event))
        }
        
        return groups.sorted { $0.startDate < $1.startDate }
    }
    
    private func dateIndex(for date: Date) -> Int? {
        timelineDates.firstIndex { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
}

// Timeline Event Model
struct TimelineEvent: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let type: CalendarEventType
    let startDate: Date
    let endDate: Date?
    let priority: EventPriority
    let hasConflicts: Bool
    let relatedTaskId: Int?
    
    init(from event: ManagementCalendarEvent) {
        self.id = event.id
        self.title = event.title
        self.subtitle = event.description
        self.type = event.type
        self.startDate = event.date
        self.endDate = event.endDate
        self.priority = event.priority
        self.hasConflicts = !event.conflicts.isEmpty
        self.relatedTaskId = event.relatedEntities.taskId
    }
}

// Timeline Event Bar Component
struct TimelineEventBar: View {
    let event: TimelineEvent
    let startOffset: CGFloat
    let width: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            if event.hasConflicts {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
            Text(event.title)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.white)
            
            if event.priority == .high || event.priority == .critical {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .frame(width: width - 4, height: 36)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: event.type.color))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .offset(x: startOffset + 2)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Agenda View

struct AgendaCalendarView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingWorkerAssignment: Bool
    @Binding var selectedTaskForAssignment: Int?
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedEventsByDay, id: \.date) { dayGroup in
                    Section(header: AgendaDayHeaderView(date: dayGroup.date, eventCount: dayGroup.events.count)) {
                        ForEach(dayGroup.events) { event in
                            AgendaEventRow(
                                event: event,
                                isSelected: event.id == viewModel.selectedEvent?.id,
                                onTap: {
                                    if event.type == .task {
                                        selectedTaskForAssignment = event.relatedEntities.taskId
                                        showingWorkerAssignment = true
                                    } else {
                                        viewModel.selectEvent(event)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var groupedEventsByDay: [DayEventGroup] {
        let grouped = Dictionary(grouping: viewModel.filteredEvents) { event in
            calendar.startOfDay(for: event.date)
        }
        
        return grouped.map { date, events in
            DayEventGroup(date: date, events: events.sorted { $0.date < $1.date })
        }
        .sorted { $0.date < $1.date }
    }
}

struct DayEventGroup: Identifiable {
    let date: Date
    let events: [ManagementCalendarEvent]
    
    var id: Date { date }
}

struct AgendaDayHeaderView: View {
    let date: Date
    let eventCount: Int
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: date))
                    .font(.headline)
                    .foregroundColor(calendar.isDateInToday(date) ? .ksrPrimary : .primary)
                
                Text("\(eventCount) event\(eventCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if calendar.isDateInToday(date) {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.ksrPrimary)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
}

struct AgendaEventRow: View {
    let event: ManagementCalendarEvent
    let isSelected: Bool
    let onTap: () -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                timeColumn
                eventTypeIndicator
                eventDetails
                chevronIcon
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(backgroundView)
            .overlay(overlayBorder)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var timeColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(timeFormatter.string(from: event.date))
                .font(.caption)
                .fontWeight(.medium)
            
            if let endDate = event.endDate {
                Text(timeFormatter.string(from: endDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 60)
    }
    
    private var eventTypeIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: event.type.color))
            .frame(width: 4)
    }
    
    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleRow
            
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            metaInformation
        }
    }
    
    private var titleRow: some View {
        HStack {
            Text(event.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            if event.priority == .high || event.priority == .critical {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(event.priority == .critical ? .red : .orange)
            }
            
            if !event.conflicts.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var metaInformation: some View {
        HStack(spacing: 12) {
            Label(event.type.displayName, systemImage: event.type.icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let projectId = event.relatedEntities.projectId {
                Label("Project #\(projectId)", systemImage: "folder")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if event.actionRequired {
                Label("Action Required", systemImage: "bell.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(Color(.tertiaryLabel))
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.ksrPrimary.opacity(0.1) : Color(.secondarySystemBackground))
    }
    
    private var overlayBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.ksrPrimary : Color.clear, lineWidth: 1)
    }
}

// Add icon property to CalendarEventType
extension CalendarEventType {
    var icon: String {
        switch self {
        case .leave: return "person.fill.xmark"
        case .project: return "folder.fill"
        case .task: return "checkmark.square.fill"
        case .milestone: return "flag.fill"
        case .resource: return "person.3.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .deadline: return "calendar.badge.exclamationmark"
        case .workPlan: return "calendar.badge.plus"
        }
    }
}

struct ResourceAllocationPanelView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let isFullScreenMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resource Allocation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let summary = viewModel.calendarSummary {
                        Text("\(summary.availableWorkers) workers available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.loadWorkerAvailabilityMatrix()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isLoadingMatrix)
            }
            
            Divider()
            
            if viewModel.isLoadingMatrix {
                // Loading State
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading worker availability...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let matrix = viewModel.workerAvailabilityMatrix {
                // Worker Availability Matrix
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Summary Stats
                        WorkerAvailabilitySummaryView(summary: matrix.summary)
                        
                        Divider()
                        
                        // Workers List
                        ForEach(matrix.workers) { workerRow in
                            WorkerAvailabilityRowView(
                                workerRow: workerRow,
                                selectedDate: viewModel.selectedDate
                            )
                        }
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No worker data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Load Worker Data") {
                        Task {
                            await viewModel.loadWorkerAvailabilityMatrix()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Worker Availability Summary

struct WorkerAvailabilitySummaryView: View {
    let summary: AvailabilitySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Team Overview")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                SummaryStatCard(
                    title: "Available Today",
                    value: "\(summary.availableToday)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                SummaryStatCard(
                    title: "On Leave",
                    value: "\(summary.onLeaveToday)",
                    color: .orange,
                    icon: "person.slash"
                )
                
                SummaryStatCard(
                    title: "Sick",
                    value: "\(summary.sickToday)",
                    color: .red,
                    icon: "cross.circle.fill"
                )
                
                SummaryStatCard(
                    title: "Overloaded",
                    value: "\(summary.overloadedToday)",
                    color: .purple,
                    icon: "exclamationmark.triangle.fill"
                )
            }
            
            // Utilization Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Team Utilization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(summary.averageUtilization * 100, specifier: "%.0f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: summary.averageUtilization)
                    .progressViewStyle(LinearProgressViewStyle(tint: utilizationColor))
            }
        }
    }
    
    private var utilizationColor: Color {
        if summary.averageUtilization >= 0.9 { return .red }
        if summary.averageUtilization >= 0.7 { return .orange }
        return .green
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - Worker Availability Row

struct WorkerAvailabilityRowView: View {
    let workerRow: WorkerAvailabilityRow
    let selectedDate: Date
    
    private var dayAvailability: DayAvailability? {
        workerRow.getAvailability(for: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Worker Info Header
            HStack(spacing: 8) {
                // Profile Picture or Initials
                AsyncImage(url: URL(string: workerRow.worker.profilePictureUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text(workerRow.worker.displayName.prefix(2).uppercased())
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(workerRow.worker.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(workerRow.worker.role.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Availability Status
                if let availability = dayAvailability {
                    AvailabilityStatusBadge(status: availability.status)
                }
            }
            
            // Availability Details for Selected Date
            if let availability = dayAvailability {
                VStack(spacing: 4) {
                    // Hours & Utilization
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Hours: \(availability.assignedHours, specifier: "%.1f")/\(availability.maxCapacity, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: availability.utilization)
                                .progressViewStyle(LinearProgressViewStyle(tint: utilizationColor(availability.utilization)))
                        }
                        
                        Spacer()
                        
                        Text("\(availability.utilization * 100, specifier: "%.0f")%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    // Current Assignments
                    if !availability.projects.isEmpty || !availability.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(availability.projects.prefix(2)) { project in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 4)
                                    
                                    Text(project.projectName)
                                        .font(.caption2)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(project.hours, specifier: "%.1f")h")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            ForEach(availability.tasks.prefix(1)) { task in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 4, height: 4)
                                    
                                    Text(task.taskName)
                                        .font(.caption2)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(task.hours, specifier: "%.1f")h")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Leave Info
                    if let leaveInfo = availability.leaveInfo {
                        HStack(spacing: 4) {
                            Image(systemName: "person.slash")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Text(leaveInfo.displayName)
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func utilizationColor(_ utilization: Double) -> Color {
        if utilization >= 1.0 { return .red }
        if utilization >= 0.8 { return .orange }
        return .green
    }
}

struct AvailabilityStatusBadge: View {
    let status: AvailabilityStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: status.color))
            .cornerRadius(4)
    }
}

struct SelectedDateDetailPanelView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @State private var isPanelExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Always visible
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedDate, format: .dateTime.weekday(.wide).month().day())
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Text("\(viewModel.eventsForSelectedDate.count) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let summary = viewModel.calendarSummary {
                            Text("\(summary.availableWorkers) workers available")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Expand/Collapse Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPanelExpanded.toggle()
                    }
                }) {
                    Image(systemName: isPanelExpanded ? "chevron.down" : "chevron.up")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Content - Collapsible
            if isPanelExpanded {
                VStack(spacing: 0) {
                    Divider()
                    
                    if viewModel.eventsForSelectedDate.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("No events scheduled")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.eventsForSelectedDate) { event in
                                    EnhancedEventRowView(event: event) {
                                        viewModel.selectEvent(event)
                                        // Add haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .frame(maxHeight: 120) // Limit height
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            isPanelExpanded = !viewModel.eventsForSelectedDate.isEmpty
        }
        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
            // Auto-expand if there are events, collapse if empty
            withAnimation(.easeInOut(duration: 0.3)) {
                isPanelExpanded = !viewModel.eventsForSelectedDate.isEmpty
            }
        }
    }
}

// Enhanced Event Row with better visual design
struct EnhancedEventRowView: View {
    let event: ManagementCalendarEvent
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Event Type Indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: event.type.color))
                    .frame(width: 4, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title and Type
                    HStack {
                        Text(event.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(event.type.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: event.type.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Description
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Priority and Conflicts
                    HStack(spacing: 8) {
                        // Priority Badge
                        HStack(spacing: 2) {
                            Circle()
                                .fill(priorityColor)
                                .frame(width: 6, height: 6)
                            
                            Text(event.priority.displayName)
                                .font(.caption2)
                                .foregroundColor(priorityColor)
                        }
                        
                        // Conflicts Warning
                        if !event.conflicts.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                
                                Text("\(event.conflicts.count) conflict\(event.conflicts.count == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        // Duration if available
                        if let endDate = event.endDate {
                            let duration = Calendar.current.dateComponents([.day], from: event.date, to: endDate).day ?? 0
                            if duration > 0 {
                                Text("\(duration) day\(duration == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var priorityColor: Color {
        switch event.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct EventRowView: View {
    let event: ManagementCalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: event.type.color))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(event.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(event.priority.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
    
    private var priorityColor: Color {
        switch event.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Supporting Views (Placeholders)

struct CalendarFiltersSheet: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Filters")
                    .font(.title2)
                    .padding()
                
                Text("Coming Soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Calendar Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Apply") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct CreateEventSheet: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Event")
                    .font(.title2)
                    .padding()
                
                Text("Coming Soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct WorkerAssignmentSheet: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let taskId: Int?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Worker Assignment")
                    .font(.title2)
                    .padding()
                
                if let taskId = taskId {
                    Text("Task ID: \(taskId)")
                        .foregroundColor(.secondary)
                }
                
                Text("Coming Soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Assign Worker")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Assign") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Full Screen Horizontal Components

struct FullScreenCalendarHeaderView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingFilters: Bool
    @Binding var showingEventCreation: Bool
    @Binding var showingExportOptions: Bool
    @Binding var isFullScreenMode: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact Top Controls
            HStack {
                // Calendar Navigation
                HStack(spacing: 16) {
                    Button(action: { viewModel.navigateToMonth(.previous) }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 2) {
                        Text(viewModel.displayedMonth, format: .dateTime.month(.wide).year())
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let summary = viewModel.calendarSummary {
                            Text("\(summary.totalEvents) events • \(summary.availableWorkers) available")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { viewModel.navigateToMonth(.next) }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Quick Actions
                HStack(spacing: 8) {
                    Button("Today") {
                        viewModel.navigateToToday()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: { showingEventCreation = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button(action: { showingExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isFullScreenMode = false
                        }
                    }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Compact Event Type Filters
            EventTypeFilterChips(viewModel: viewModel)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct EnhancedLandscapeCalendarView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Binding var showingWorkerAssignment: Bool
    @Binding var selectedTaskForAssignment: Int?
    @State private var calendarMode: LandscapeCalendarMode = .month
    @State private var zoomLevel: CalendarZoomLevel = .normal
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Calendar Controls
            LandscapeCalendarControlsView(
                calendarMode: $calendarMode,
                zoomLevel: $zoomLevel,
                viewModel: viewModel
            )
            
            // Dynamic Calendar Content
            ScrollView {
                switch calendarMode {
                case .month:
                    monthViewContent
                case .multiWeek:
                    multiWeekViewContent
                case .timeline:
                    timelineViewContent
                }
            }
            .animation(.easeInOut(duration: 0.3), value: calendarMode)
            .animation(.easeInOut(duration: 0.2), value: zoomLevel)
        }
    }
    
    @ViewBuilder
    private var monthViewContent: some View {
        VStack(spacing: 0) {
            // Enhanced Weekday Headers
            LandscapeWeekdayHeaders()
            
            // Zoomable Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                ForEach(calendarDates, id: \.self) { date in
                    EnhancedCalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        events: viewModel.getEventsForDate(date),
                        onTap: { 
                            if calendar.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month) {
                                viewModel.selectDate(date)
                            }
                        },
                        onEventTap: { event in
                            if event.type == .task {
                                selectedTaskForAssignment = event.relatedEntities.taskId
                                showingWorkerAssignment = true
                            } else {
                                viewModel.selectEvent(event)
                            }
                        }
                    )
                    .frame(height: dayCellHeight)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private var multiWeekViewContent: some View {
        VStack(spacing: 16) {
            ForEach(multiWeekRanges, id: \.self) { weekRange in
                WeekRowView(
                    weekRange: weekRange,
                    viewModel: viewModel,
                    selectedDate: viewModel.selectedDate,
                    onDateTap: { date in
                        viewModel.selectDate(date)
                    },
                    onEventTap: { event in
                        if event.type == .task {
                            selectedTaskForAssignment = event.relatedEntities.taskId
                            showingWorkerAssignment = true
                        } else {
                            viewModel.selectEvent(event)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var timelineViewContent: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(timelineEvents, id: \.id) { event in
                TimelineEventRow(
                    event: event,
                    isSelected: viewModel.selectedEvent?.id == event.id,
                    onTap: {
                        viewModel.selectEvent(event)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Computed Properties
    
    private var gridSpacing: CGFloat {
        switch zoomLevel {
        case .compact: return 1
        case .normal: return 3
        case .spacious: return 6
        }
    }
    
    private var dayCellHeight: CGFloat {
        switch zoomLevel {
        case .compact: return 80
        case .normal: return 120
        case .spacious: return 160
        }
    }
    
    private var multiWeekRanges: [ClosedRange<Date>] {
        let monthStart = calendar.dateInterval(of: .month, for: viewModel.displayedMonth)?.start ?? viewModel.displayedMonth
        let monthEnd = calendar.dateInterval(of: .month, for: viewModel.displayedMonth)?.end ?? viewModel.displayedMonth
        
        var weeks: [ClosedRange<Date>] = []
        var currentDate = monthStart
        
        while currentDate < monthEnd {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
            let weekEnd = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.end ?? currentDate
            
            weeks.append(weekStart...weekEnd)
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? monthEnd
        }
        
        return weeks
    }
    
    private var timelineEvents: [ManagementCalendarEvent] {
        viewModel.filteredEvents
            .filter { event in
                calendar.isDate(event.date, equalTo: viewModel.displayedMonth, toGranularity: .month)
            }
            .sorted { $0.date < $1.date }
    }
    
    private var calendarDates: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end)
        else { return [] }
        
        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
}

struct LandscapeWeekdayHeaders: View {
    private let weekdays = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}

struct EnhancedCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let events: [ManagementCalendarEvent]
    let onTap: () -> Void
    let onEventTap: (ManagementCalendarEvent) -> Void
    
    private let calendar = Calendar.current
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 4) {
                // Date Number (larger for landscape)
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 18, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Enhanced Event Indicators (more events visible)
                VStack(spacing: 2) {
                    ForEach(Array(events.prefix(5).enumerated()), id: \.offset) { index, event in
                        EnhancedEventIndicatorView(event: event) {
                            onEventTap(event)
                        }
                    }
                    
                    if events.count > 5 {
                        Text("+\(events.count - 5) more")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isSelected ? 1.03 : (isPressed ? 0.97 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .disabled(!isCurrentMonth)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue.opacity(0.3)
        } else if !isCurrentMonth {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 1
    }
}

struct EnhancedEventIndicatorView: View {
    let event: ManagementCalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 3) {
                Circle()
                    .fill(Color(hex: event.type.color))
                    .frame(width: 6, height: 6)
                
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if event.priority == .high || event.priority == .critical {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(event.priority == .critical ? .red : .orange)
                }
                
                if !event.conflicts.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                }
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(hex: event.type.color).opacity(0.25))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResizableDivider: View {
    @Binding var position: CGFloat
    @Binding var isDragging: Bool
    let geometry: GeometryProxy
    
    private let minPosition: CGFloat = 0.4
    private let maxPosition: CGFloat = 0.7
    
    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.blue.opacity(0.6) : Color(.systemGray4))
            .frame(width: 4)
            .background(
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20) // Larger touch area
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let newPosition = position + (value.translation.width / geometry.size.width)
                        position = max(minPosition, min(maxPosition, newPosition))
                    }
                    .onEnded { _ in
                        isDragging = false
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
            )
            .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
}

struct InlineSelectedDateView: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.selectedDate, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.eventsForSelectedDate.count) event\(viewModel.eventsForSelectedDate.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.eventsForSelectedDate.prefix(6)) { event in
                        CompactEventCard(event: event) {
                            viewModel.selectEvent(event)
                        }
                    }
                    
                    if viewModel.eventsForSelectedDate.count > 6 {
                        Button("+\(viewModel.eventsForSelectedDate.count - 6) more") {
                            // Handle showing more events
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
    }
}

struct CompactEventCard: View {
    let event: ManagementCalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: event.type.color))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(event.type.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !event.conflicts.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: event.type.color).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedResourceManagementPanel: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header
            EnhancedResourcePanelHeader(viewModel: viewModel)
                .frame(height: 80)
            
            Divider()
            
            if viewModel.isLoadingMatrix {
                // Loading State
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading worker availability...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let matrix = viewModel.workerAvailabilityMatrix {
                // Enhanced Resource Content
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // Enhanced Summary Stats
                        EnhancedWorkersummaryView(summary: matrix.summary)
                        
                        Divider()
                        
                        // Enhanced Workers List
                        ForEach(matrix.workers) { workerRow in
                            EnhancedWorkerAvailabilityCard(
                                workerRow: workerRow,
                                selectedDate: viewModel.selectedDate
                            )
                        }
                    }
                    .padding()
                }
            } else {
                // Enhanced Empty State
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No worker data available")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Load worker availability data to view resource allocation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Load Worker Data") {
                        Task {
                            await viewModel.loadWorkerAvailabilityMatrix()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(Color(.systemGray6))
    }
}

struct EnhancedResourcePanelHeader: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resource Management")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let summary = viewModel.calendarSummary {
                        HStack(spacing: 12) {
                            Label("\(summary.availableWorkers)", systemImage: "person.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label("Available", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Button(action: {
                        Task {
                            await viewModel.loadWorkerAvailabilityMatrix()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoadingMatrix)
                    
                    Text("Refresh")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct EnhancedWorkersummaryView: View {
    let summary: AvailabilitySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Enhanced 2x2 Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                EnhancedSummaryCard(
                    title: "Available",
                    value: "\(summary.availableToday)",
                    color: .green,
                    icon: "checkmark.circle.fill",
                    subtitle: "Ready to work"
                )
                
                EnhancedSummaryCard(
                    title: "On Leave",
                    value: "\(summary.onLeaveToday)",
                    color: .orange,
                    icon: "figure.walk",
                    subtitle: "Vacation/Personal"
                )
                
                EnhancedSummaryCard(
                    title: "Sick",
                    value: "\(summary.sickToday)",
                    color: .red,
                    icon: "cross.circle.fill",
                    subtitle: "Medical leave"
                )
                
                EnhancedSummaryCard(
                    title: "Overloaded",
                    value: "\(summary.overloadedToday)",
                    color: .purple,
                    icon: "exclamationmark.triangle.fill",
                    subtitle: "Over capacity"
                )
            }
            
            // Enhanced Team Utilization
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Team Utilization")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(summary.averageUtilization * 100, specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(utilizationColor)
                }
                
                ProgressView(value: summary.averageUtilization)
                    .progressViewStyle(LinearProgressViewStyle(tint: utilizationColor))
                    .scaleEffect(y: 1.5)
                
                Text(utilizationDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var utilizationColor: Color {
        if summary.averageUtilization >= 0.9 { return .red }
        if summary.averageUtilization >= 0.7 { return .orange }
        return .green
    }
    
    private var utilizationDescription: String {
        if summary.averageUtilization >= 0.9 { return "Team at maximum capacity" }
        if summary.averageUtilization >= 0.7 { return "Team well utilized" }
        return "Team has available capacity"
    }
}

struct EnhancedSummaryCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EnhancedWorkerAvailabilityCard: View {
    let workerRow: WorkerAvailabilityRow
    let selectedDate: Date
    
    private var dayAvailability: DayAvailability? {
        workerRow.getAvailability(for: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced Worker Header
            HStack(spacing: 12) {
                // Larger Profile Picture
                AsyncImage(url: URL(string: workerRow.worker.profilePictureUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text(workerRow.worker.displayName.prefix(2).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workerRow.worker.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(workerRow.worker.role.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let availability = dayAvailability {
                        Text("\(availability.assignedHours, specifier: "%.1f")h assigned")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Enhanced Status Badge
                if let availability = dayAvailability {
                    EnhancedAvailabilityBadge(
                        status: availability.status,
                        utilization: availability.utilization
                    )
                }
            }
            
            // Enhanced Availability Details
            if let availability = dayAvailability {
                VStack(spacing: 8) {
                    // Enhanced Utilization Bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Capacity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(availability.assignedHours, specifier: "%.1f") / \(availability.maxCapacity, specifier: "%.1f") hours")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: availability.utilization)
                            .progressViewStyle(LinearProgressViewStyle(tint: utilizationColor(availability.utilization)))
                            .scaleEffect(y: 1.2)
                    }
                    
                    // Enhanced Assignments
                    if !availability.projects.isEmpty || !availability.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Assignments")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ForEach(availability.projects.prefix(3)) { project in
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 16)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(project.projectName)
                                            .font(.caption)
                                            .lineLimit(1)
                                        
                                        Text("Project")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(project.hours, specifier: "%.1f")h")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            ForEach(availability.tasks.prefix(2)) { task in
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.green)
                                        .frame(width: 4, height: 16)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(task.taskName)
                                            .font(.caption)
                                            .lineLimit(1)
                                        
                                        Text("Task")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(task.hours, specifier: "%.1f")h")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    
                    // Enhanced Leave Info
                    if let leaveInfo = availability.leaveInfo {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(leaveInfo.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                
                                Text("On leave today")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func utilizationColor(_ utilization: Double) -> Color {
        if utilization >= 1.0 { return .red }
        if utilization >= 0.8 { return .orange }
        return .green
    }
}

struct EnhancedAvailabilityBadge: View {
    let status: AvailabilityStatus
    let utilization: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: status.color))
                .cornerRadius(6)
            
            if status == .available {
                Text("\(utilization * 100, specifier: "%.0f")%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(utilizationTextColor)
            }
        }
    }
    
    private var utilizationTextColor: Color {
        if utilization >= 1.0 { return .red }
        if utilization >= 0.8 { return .orange }
        return .green
    }
}

// MARK: - Enhanced Landscape Calendar Supporting Components

enum LandscapeCalendarMode: String, CaseIterable {
    case month = "MONTH"
    case multiWeek = "MULTI_WEEK"
    case timeline = "TIMELINE"
    
    var displayName: String {
        switch self {
        case .month: return "Month"
        case .multiWeek: return "Multi-Week"
        case .timeline: return "Timeline"
        }
    }
    
    var icon: String {
        switch self {
        case .month: return "calendar"
        case .multiWeek: return "calendar.badge.plus"
        case .timeline: return "list.bullet"
        }
    }
}

enum CalendarZoomLevel: String, CaseIterable {
    case compact = "COMPACT"
    case normal = "NORMAL"
    case spacious = "SPACIOUS"
    
    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .normal: return "Normal"
        case .spacious: return "Spacious"
        }
    }
    
    var icon: String {
        switch self {
        case .compact: return "minus.magnifyingglass"
        case .normal: return "magnifyingglass"
        case .spacious: return "plus.magnifyingglass"
        }
    }
}

struct LandscapeCalendarControlsView: View {
    @Binding var calendarMode: LandscapeCalendarMode
    @Binding var zoomLevel: CalendarZoomLevel
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    
    var body: some View {
        HStack {
            // Calendar Mode Selector
            HStack(spacing: 0) {
                ForEach(LandscapeCalendarMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            calendarMode = mode
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.caption)
                            Text(mode.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(calendarMode == mode ? .white : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(calendarMode == mode ? Color.blue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(2)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
            
            // Zoom Controls
            HStack(spacing: 8) {
                ForEach(CalendarZoomLevel.allCases, id: \.self) { level in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomLevel = level
                        }
                    }) {
                        Image(systemName: level.icon)
                            .font(.caption)
                            .foregroundColor(zoomLevel == level ? .white : .secondary)
                            .padding(6)
                            .background(zoomLevel == level ? Color.blue : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct WeekRowView: View {
    let weekRange: ClosedRange<Date>
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    let selectedDate: Date
    let onDateTap: (Date) -> Void
    let onEventTap: (ManagementCalendarEvent) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Week Header
            HStack {
                Text(weekHeaderText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(weekEvents.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Week Days Row
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    Button(action: {
                        onDateTap(date)
                    }) {
                        VStack(spacing: 4) {
                            // Day number
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14, weight: isToday(date) ? .bold : .medium))
                                .foregroundColor(textColor(for: date))
                            
                            // Event indicators
                            VStack(spacing: 1) {
                                ForEach(eventsForDate(date).prefix(2), id: \.id) { event in
                                    Button(action: {
                                        onEventTap(event)
                                    }) {
                                        HStack(spacing: 2) {
                                            Circle()
                                                .fill(Color(hex: event.type.color))
                                                .frame(width: 3, height: 3)
                                            
                                            Text(event.title)
                                                .font(.system(size: 8))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 2)
                                        .padding(.vertical, 1)
                                        .background(Color(hex: event.type.color).opacity(0.2))
                                        .cornerRadius(2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if eventsForDate(date).count > 2 {
                                    Text("+\(eventsForDate(date).count - 2)")
                                        .font(.system(size: 7, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(backgroundColor(for: date))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(borderColor(for: date), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var weekHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startText = formatter.string(from: weekRange.lowerBound)
        let endText = formatter.string(from: weekRange.upperBound)
        return "\(startText) - \(endText)"
    }
    
    private var weekDates: [Date] {
        var dates: [Date] = []
        var currentDate = weekRange.lowerBound
        
        while currentDate <= weekRange.upperBound {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? weekRange.upperBound
        }
        
        return dates
    }
    
    private var weekEvents: [ManagementCalendarEvent] {
        viewModel.filteredEvents.filter { event in
            weekRange.contains(event.date)
        }
    }
    
    private func eventsForDate(_ date: Date) -> [ManagementCalendarEvent] {
        return viewModel.getEventsForDate(date)
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func textColor(for date: Date) -> Color {
        if isToday(date) {
            return .white
        } else if isSelected(date) {
            return .blue
        } else {
            return .primary
        }
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if isToday(date) {
            return .blue
        } else if isSelected(date) {
            return .blue.opacity(0.2)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private func borderColor(for date: Date) -> Color {
        if isSelected(date) || isToday(date) {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
}

struct TimelineEventRow: View {
    let event: ManagementCalendarEvent
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time indicator
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.date, format: .dateTime.hour().minute())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(event.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60, alignment: .leading)
                
                // Event type indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: event.type.color))
                    .frame(width: 4, height: 40)
                
                // Event content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Priority badge
                        HStack(spacing: 2) {
                            Circle()
                                .fill(priorityColor)
                                .frame(width: 6, height: 6)
                            
                            Text(event.priority.displayName)
                                .font(.caption2)
                                .foregroundColor(priorityColor)
                        }
                    }
                    
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Related entities
                    HStack(spacing: 8) {
                        if let projectId = event.relatedEntities.projectId {
                            Label("Project \(projectId)", systemImage: "folder")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        if let taskId = event.relatedEntities.taskId {
                            Label("Task \(taskId)", systemImage: "checkmark.square")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        if !event.conflicts.isEmpty {
                            Label("\(event.conflicts.count) conflicts", systemImage: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                Image(systemName: event.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(event.status == .completed ? .green : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var priorityColor: Color {
        switch event.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Export Functionality

struct ExportOptionsSheet: View {
    @ObservedObject var viewModel: ChefManagementCalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var exportFormat: CalendarExportFormat = .pdf
    @State private var dateRange: CalendarExportDateRange = .currentMonth
    @State private var includeDetails = true
    @State private var includeWorkerInfo = true
    @State private var isExporting = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFURL: URL?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(CalendarExportFormat.allCases, id: \.self) { format in
                            HStack {
                                Image(systemName: format.icon)
                                Text(format.displayName)
                            }
                            .tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Date Range")) {
                    Picker("Range", selection: $dateRange) {
                        ForEach(CalendarExportDateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                Section(header: Text("Options")) {
                    Toggle("Include Event Details", isOn: $includeDetails)
                    Toggle("Include Worker Information", isOn: $includeWorkerInfo)
                }
                
                Section {
                    Button(action: {
                        exportCalendar()
                    }) {
                        if isExporting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Exporting...")
                            }
                        } else {
                            Text("Export Calendar")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(
                    pdfURL: pdfURL,
                    onShare: {
                        showingPDFPreview = false
                        presentShareSheet(fileURL: pdfURL)
                    },
                    onDismiss: {
                        showingPDFPreview = false
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: pdfURL)
                    }
                )
            }
        }
    }
    
    private func exportCalendar() {
        isExporting = true
        
        Task {
            do {
                let fileURL = try await generateCalendarFile()
                
                await MainActor.run {
                    isExporting = false
                    
                    if exportFormat == .pdf {
                        // Show PDF preview for PDF exports
                        generatedPDFURL = fileURL
                        showingPDFPreview = true
                    } else {
                        // Direct share for other formats
                        presentationMode.wrappedValue.dismiss()
                        presentShareSheet(fileURL: fileURL)
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    print("❌ [Export] Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateCalendarFile() async throws -> URL {
        switch exportFormat {
        case .pdf:
            return try await generatePDFCalendar()
        case .excel:
            return try await generateExcelCalendar()
        case .csv:
            return try await generateCSVCalendar()
        }
    }
    
    private func generatePDFCalendar() async throws -> URL {
        let pdfGenerator = SimplePDFGenerator(
            viewModel: viewModel,
            dateRange: getSelectedDateRange(),
            includeDetails: includeDetails,
            includeWorkerInfo: includeWorkerInfo
        )
        
        return try await pdfGenerator.generatePDF()
    }
    
    private func generateExcelCalendar() async throws -> URL {
        let excelGenerator = CalendarExcelGenerator(
            viewModel: viewModel,
            dateRange: getSelectedDateRange(),
            includeDetails: includeDetails,
            includeWorkerInfo: includeWorkerInfo
        )
        
        return try await excelGenerator.generateExcel()
    }
    
    private func generateCSVCalendar() async throws -> URL {
        let csvGenerator = CalendarCSVGenerator(
            viewModel: viewModel,
            dateRange: getSelectedDateRange(),
            includeDetails: includeDetails,
            includeWorkerInfo: includeWorkerInfo
        )
        
        return try await csvGenerator.generateCSV()
    }
    
    private func getSelectedDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .currentMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (start, end)
        case .nextMonth:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
            let start = calendar.dateInterval(of: .month, for: nextMonth)?.start ?? now
            let end = calendar.dateInterval(of: .month, for: nextMonth)?.end ?? now
            return (start, end)
        case .currentQuarter:
            let start = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            let end = calendar.dateInterval(of: .quarter, for: now)?.end ?? now
            return (start, end)
        case .customRange:
            // For now, default to current month
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (start, end)
        }
    }
    
    private func presentShareSheet(fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        window.rootViewController?.present(activityVC, animated: true)
    }
}

enum CalendarExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case excel = "EXCEL"
    case csv = "CSV"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF Report"
        case .excel: return "Excel Spreadsheet"
        case .csv: return "CSV Data"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .excel: return "tablecells"
        case .csv: return "doc.text"
        }
    }
}

enum CalendarExportDateRange: String, CaseIterable {
    case currentMonth = "CURRENT_MONTH"
    case nextMonth = "NEXT_MONTH"
    case currentQuarter = "CURRENT_QUARTER"
    case customRange = "CUSTOM_RANGE"
    
    var displayName: String {
        switch self {
        case .currentMonth: return "Current Month"
        case .nextMonth: return "Next Month"
        case .currentQuarter: return "Current Quarter"
        case .customRange: return "Custom Range"
        }
    }
}

// MARK: - Extensions

// Note: Color hex init extension is already defined in Extensions/Color+Extensions.swift

#Preview {
    ChefManagementCalendarView()
}