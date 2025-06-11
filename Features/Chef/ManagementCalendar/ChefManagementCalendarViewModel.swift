import Foundation
import Combine
import SwiftUI

@MainActor
class ChefManagementCalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var calendarEvents: [ManagementCalendarEvent] = []
    @Published var workerAvailabilityMatrix: WorkerAvailabilityMatrix?
    @Published var selectedDate = Date()
    @Published var displayedMonth = Date()
    @Published var activeEventTypes: Set<CalendarEventType> = Set(CalendarEventType.allCases)
    @Published var viewMode: CalendarViewMode = .month
    @Published var showingResourcePanel = false
    @Published var selectedEvent: ManagementCalendarEvent?
    @Published var calendarSummary: CalendarSummary?
    
    // Loading & Error States
    @Published var isLoading = false
    @Published var isLoadingMatrix = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    
    // Filters & Search
    @Published var searchText = ""
    @Published var selectedPriority: EventPriority?
    @Published var selectedWorkerIds: Set<Int> = []
    @Published var selectedProjectIds: Set<Int> = []
    @Published var showingConflictsOnly = false
    
    // Drag & Drop State
    @Published var draggedEvent: ManagementCalendarEvent?
    @Published var dropTargetDate: Date?
    @Published var dragValidationResult: CalendarValidationResult?
    
    // MARK: - Private Properties
    
    private let apiService = ManagementCalendarAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // Date range management
    private var currentDateRange: DateRange {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.end ?? displayedMonth
        
        // Extend range to include previous/next month for better context
        let extendedStart = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
        let extendedEnd = calendar.date(byAdding: .month, value: 1, to: endOfMonth) ?? endOfMonth
        
        return DateRange(startDate: extendedStart, endDate: extendedEnd)
    }
    
    // MARK: - Computed Properties
    
    var filteredEvents: [ManagementCalendarEvent] {
        var events = calendarEvents
        
        // Filter by active event types
        events = events.filter { activeEventTypes.contains($0.type) }
        
        // Filter by search text
        if !searchText.isEmpty {
            events = events.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by priority
        if let selectedPriority = selectedPriority {
            events = events.filter { $0.priority == selectedPriority }
        }
        
        // Filter by selected workers
        if !selectedWorkerIds.isEmpty {
            events = events.filter { event in
                selectedWorkerIds.contains { workerId in
                    event.relatedEntities.workerId == workerId ||
                    event.resourceRequirements.contains { req in
                        // Check if worker is suitable for requirement (simplified)
                        true // Would need actual skill matching
                    }
                }
            }
        }
        
        // Filter by selected projects
        if !selectedProjectIds.isEmpty {
            events = events.filter { event in
                if let projectId = event.relatedEntities.projectId {
                    return selectedProjectIds.contains(projectId)
                }
                return false
            }
        }
        
        // Filter by conflicts only
        if showingConflictsOnly {
            events = events.filter { !$0.conflicts.isEmpty }
        }
        
        return events
    }
    
    var eventsForSelectedDate: [ManagementCalendarEvent] {
        let calendar = Calendar.current
        return filteredEvents.filter { event in
            calendar.isDate(event.date, inSameDayAs: selectedDate) ||
            (event.endDate != nil && selectedDate >= event.date && selectedDate <= event.endDate!)
        }
    }
    
    var upcomingDeadlines: [ManagementCalendarEvent] {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        return filteredEvents.filter { event in
            event.type == .deadline || event.type == .task &&
            event.date <= nextWeek &&
            event.status != .completed
        }.sorted { $0.date < $1.date }
    }
    
    var criticalConflicts: [ConflictInfo] {
        return calendarEvents.flatMap { $0.conflicts }
            .filter { $0.severity == .critical || $0.severity == .high }
            .sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadInitialData()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Auto-reload when displayed month changes
        $displayedMonth
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCalendarData()
                }
            }
            .store(in: &cancellables)
        
        // Auto-reload when active event types change
        $activeEventTypes
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCalendarData()
                }
            }
            .store(in: &cancellables)
        
        // Clear selected event when filters change
        Publishers.CombineLatest4(
            $searchText,
            $selectedPriority,
            $selectedWorkerIds,
            $showingConflictsOnly
        )
        .sink { [weak self] _, _, _, _ in
            self?.selectedEvent = nil
        }
        .store(in: &cancellables)
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshCalendarData()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        Task {
            await loadCalendarData()
            await loadWorkerAvailabilityMatrix()
            await loadCalendarSummary()
        }
    }
    
    func loadCalendarData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchUnifiedCalendarData(
                startDate: currentDateRange.startDate,
                endDate: currentDateRange.endDate,
                eventTypes: Array(activeEventTypes),
                includeConflicts: true,
                includeMetadata: true
            ).asyncValue()
            
            calendarEvents = response.events
            workerAvailabilityMatrix = response.workerAvailability
            calendarSummary = response.summary
            lastUpdated = response.lastUpdated
            
            print("📅 [ChefCalendar] Loaded \(calendarEvents.count) events")
            
        } catch {
            handleError(error, context: "Loading calendar data")
        }
        
        isLoading = false
    }
    
    func loadWorkerAvailabilityMatrix() async {
        guard !isLoadingMatrix else { return }
        
        isLoadingMatrix = true
        
        do {
            let matrix = try await apiService.fetchWorkerAvailabilityMatrix(
                startDate: currentDateRange.startDate,
                endDate: currentDateRange.endDate,
                workerIds: selectedWorkerIds.isEmpty ? nil : Array(selectedWorkerIds)
            ).asyncValue()
            
            workerAvailabilityMatrix = matrix
            
            print("👥 [ChefCalendar] Loaded availability matrix for \(matrix.workers.count) workers")
            
        } catch {
            handleError(error, context: "Loading worker availability")
        }
        
        isLoadingMatrix = false
    }
    
    func loadCalendarSummary() async {
        do {
            let summary = try await apiService.getCalendarSummary(for: selectedDate).asyncValue()
            calendarSummary = summary
        } catch {
            handleError(error, context: "Loading calendar summary")
        }
    }
    
    func refreshCalendarData() async {
        await loadCalendarData()
        await loadWorkerAvailabilityMatrix()
        await loadCalendarSummary()
    }
    
    // MARK: - Navigation & Selection
    
    func selectDate(_ date: Date) {
        selectedDate = date
        
        // Update displayed month if needed
        let calendar = Calendar.current
        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = date
        }
        
        // Load summary for selected date
        Task {
            await loadCalendarSummary()
        }
    }
    
    func navigateToMonth(_ direction: CalendarNavigation) {
        let calendar = Calendar.current
        let component: Calendar.Component = viewMode == .month ? .month : .weekOfYear
        let value = direction == .previous ? -1 : 1
        
        if let newDate = calendar.date(byAdding: component, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    func navigateToToday() {
        let today = Date()
        displayedMonth = today
        selectedDate = today
    }
    
    func selectEvent(_ event: ManagementCalendarEvent) {
        selectedEvent = event
        selectedDate = event.date
    }
    
    // MARK: - Event Management
    
    func createEvent(
        type: CalendarEventType,
        title: String,
        description: String,
        date: Date,
        endDate: Date? = nil,
        priority: EventPriority = .medium,
        relatedProjectId: Int? = nil,
        relatedTaskId: Int? = nil
    ) async {
        let relatedEntities = RelatedEntities(
            projectId: relatedProjectId,
            taskId: relatedTaskId,
            workerId: nil,
            leaveRequestId: nil,
            equipmentId: nil,
            workPlanId: nil
        )
        
        do {
            let newEvent = try await apiService.createCalendarEvent(
                type: type,
                title: title,
                description: description,
                startDate: date,
                endDate: endDate,
                priority: priority,
                resourceRequirements: [],
                relatedEntities: relatedEntities
            ).asyncValue()
            
            // Add to local array and reload
            calendarEvents.append(newEvent)
            await refreshCalendarData()
            
        } catch {
            handleError(error, context: "Creating event")
        }
    }
    
    func updateEventSchedule(_ event: ManagementCalendarEvent, newDate: Date, newEndDate: Date? = nil) async {
        do {
            // Validate schedule change first
            let validationResult = try await apiService.validateScheduleChange(
                event: event,
                newDate: newDate,
                newEndDate: newEndDate
            ).asyncValue()
            
            if validationResult.isValid {
                let updatedEvent = try await apiService.updateEventSchedule(
                    eventId: event.id,
                    newStartDate: newDate,
                    newEndDate: newEndDate
                ).asyncValue()
                
                // Update local array
                if let index = calendarEvents.firstIndex(where: { $0.id == event.id }) {
                    calendarEvents[index] = updatedEvent
                }
                
                await refreshCalendarData()
                
            } else {
                errorMessage = "Schedule change validation failed: \(validationResult.errors.joined(separator: ", "))"
            }
            
        } catch {
            handleError(error, context: "Updating event schedule")
        }
    }
    
    // MARK: - Worker Assignment
    
    func assignWorkerToTask(workerId: Int, taskId: Int, craneModelId: Int? = nil) async {
        do {
            let response = try await apiService.assignWorkerToTask(
                workerId: workerId,
                taskId: taskId,
                craneModelId: craneModelId
            ).asyncValue()
            
            if response.success {
                await refreshCalendarData()
                print("✅ [Assignment] Successfully assigned worker \(workerId) to task \(taskId)")
                
                if !response.conflicts.isEmpty {
                    errorMessage = "Assignment created conflicts: \(response.conflicts.map { $0.description }.joined(separator: ", "))"
                }
            } else {
                errorMessage = "Failed to assign worker to task"
            }
            
        } catch {
            handleError(error, context: "Assigning worker to task")
        }
    }
    
    func getWorkerAssignmentSuggestions(for taskId: Int, requiredSkills: [String], estimatedHours: Double) async -> [WorkerAssignmentSuggestion] {
        do {
            let suggestions = try await apiService.suggestOptimalWorkerAssignment(
                for: taskId,
                requiredSkills: requiredSkills,
                estimatedHours: estimatedHours
            ).asyncValue()
            
            return suggestions.sorted { $0.matchScore > $1.matchScore }
            
        } catch {
            handleError(error, context: "Getting worker assignment suggestions")
            return []
        }
    }
    
    // MARK: - Drag & Drop Support
    
    func startDrag(event: ManagementCalendarEvent) {
        draggedEvent = event
        dragValidationResult = nil
    }
    
    func updateDropTarget(date: Date?) {
        dropTargetDate = date
        
        if let draggedEvent = draggedEvent, let targetDate = date {
            Task {
                await validateDrop(event: draggedEvent, targetDate: targetDate)
            }
        }
    }
    
    func validateDrop(event: ManagementCalendarEvent, targetDate: Date) async {
        do {
            let result = try await apiService.validateScheduleChange(
                event: event,
                newDate: targetDate
            ).asyncValue()
            
            dragValidationResult = result
            
        } catch {
            print("❌ [DragValidation] Error validating drop: \(error)")
        }
    }
    
    func completeDrop() async {
        guard let draggedEvent = draggedEvent,
              let targetDate = dropTargetDate,
              let validationResult = dragValidationResult,
              validationResult.isValid else {
            endDrag()
            return
        }
        
        await updateEventSchedule(draggedEvent, newDate: targetDate)
        endDrag()
    }
    
    func endDrag() {
        draggedEvent = nil
        dropTargetDate = nil
        dragValidationResult = nil
    }
    
    // MARK: - Filtering & Search
    
    func toggleEventType(_ type: CalendarEventType) {
        if activeEventTypes.contains(type) {
            activeEventTypes.remove(type)
        } else {
            activeEventTypes.insert(type)
        }
    }
    
    func toggleWorkerSelection(_ workerId: Int) {
        if selectedWorkerIds.contains(workerId) {
            selectedWorkerIds.remove(workerId)
        } else {
            selectedWorkerIds.insert(workerId)
        }
    }
    
    func clearAllFilters() {
        searchText = ""
        selectedPriority = nil
        selectedWorkerIds.removeAll()
        selectedProjectIds.removeAll()
        showingConflictsOnly = false
        activeEventTypes = Set(CalendarEventType.allCases)
    }
    
    // MARK: - Utility Methods
    
    func getEventsForDate(_ date: Date) -> [ManagementCalendarEvent] {
        let calendar = Calendar.current
        return filteredEvents.filter { event in
            calendar.isDate(event.date, inSameDayAs: date) ||
            (event.endDate != nil && date >= event.date && date <= event.endDate!)
        }
    }
    
    func getWorkerAvailability(workerId: Int, date: Date) -> DayAvailability? {
        return workerAvailabilityMatrix?.getAvailability(workerId: workerId, date: date)
    }
    
    func formatEventDuration(_ event: ManagementCalendarEvent) -> String {
        guard let duration = event.duration else { return "No duration" }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error, context: String) {
        let errorDescription: String
        
        if let apiError = error as? BaseAPIService.APIError {
            switch apiError {
            case .invalidURL:
                errorDescription = "Invalid URL"
            case .invalidResponse:
                errorDescription = "Invalid response from server"
            case .networkError(let description):
                errorDescription = "Network error: \(description)"
            case .decodingError(let description):
                errorDescription = "Data parsing error: \(description)"
            case .serverError(_, let message):
                errorDescription = "Server error: \(message)"
            case .unknown:
                errorDescription = "Unknown error occurred"
            }
        } else {
            errorDescription = error.localizedDescription
        }
        
        errorMessage = "\(context): \(errorDescription)"
        print("❌ [ChefCalendar] \(context): \(errorDescription)")
    }
}

// MARK: - Supporting Enums

enum CalendarViewMode: String, CaseIterable {
    case month = "MONTH"
    case week = "WEEK"
    case timeline = "TIMELINE"
    case agenda = "AGENDA"
    
    var displayName: String {
        switch self {
        case .month: return "Month"
        case .week: return "Week"
        case .timeline: return "Timeline"
        case .agenda: return "Agenda"
        }
    }
    
    var icon: String {
        switch self {
        case .month: return "calendar"
        case .week: return "calendar.day.timeline.left"
        case .timeline: return "chart.xyaxis.line"
        case .agenda: return "list.bullet"
        }
    }
}

enum CalendarNavigation {
    case previous
    case next
}

// MARK: - Combine Extensions

extension Publisher {
    func asyncValue() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}