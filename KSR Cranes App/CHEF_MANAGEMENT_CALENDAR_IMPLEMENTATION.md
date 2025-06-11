# Chef Management Calendar Implementation Plan

## Overview

This document outlines the implementation plan for creating an **Interactive Management Calendar** for the Chef role in the KSR Cranes application. The calendar will provide comprehensive workforce planning capabilities, integrating projects, leave management, task assignments, and resource allocation into a unified interface.

## Current System Analysis

### Existing Strong Foundation

✅ **Leave Management System** (Fully Implemented)
- Complete leave request workflow (vacation, sick, personal days)
- Team leave calendar with color-coded indicators
- Real-time approval/rejection functionality
- Danish employment law compliance

✅ **Project Management System**
- Project timeline APIs with start/end dates
- Task assignments and deadlines
- Worker-to-project assignments
- Business timeline events and milestones

✅ **Worker Management System**
- Complete CRUD operations for workers
- Status tracking (active, inactive, sick leave, vacation, terminated)
- Skills and rate management
- Document and profile image handling

✅ **Calendar Infrastructure**
- Sophisticated calendar components (Worker + Chef calendars)
- Month/week navigation with smooth animations
- Multi-event display with color coding
- Real-time data loading and refresh

## Proposed Solution: Unified Management Calendar

### Architecture Overview

```
ChefManagementCalendarView
├── CalendarControlsHeader
│   ├── LayerToggleButtons (Projects, Leave, Tasks, Resources)
│   ├── FilterControls (Teams, Status, Priority)
│   └── ViewModeSelector (Month, Week, Timeline)
├── UnifiedCalendarGrid
│   ├── MultiLayerDayView
│   │   ├── ProjectEventsLayer
│   │   ├── LeaveEventsLayer
│   │   ├── TaskDeadlinesLayer
│   │   └── ResourceAvailabilityLayer
│   └── DragDropInteractionHandler
├── SelectedDateDetailPanel
│   ├── EventsList (Projects, Leave, Tasks)
│   ├── ResourceAvailability
│   ├── ConflictWarnings
│   └── QuickActionButtons
└── ResourceAllocationPanel
    ├── WorkerAvailabilityMatrix
    ├── SkillsMatchingView
    └── CapacityPlanningChart
```

## Implementation Phases

### Phase 1: Data Layer Enhancement

#### 1.1 Unified Calendar Data Model

```swift
// New file: Core/Services/API/Chef/ManagementCalendarModels.swift

struct ManagementCalendarEvent: Identifiable, Codable {
    let id: String
    let date: Date
    let endDate: Date?
    let type: CalendarEventType
    let category: EventCategory
    let title: String
    let description: String
    let priority: EventPriority
    let status: EventStatus
    let resourceRequirements: [ResourceRequirement]
    let relatedEntities: RelatedEntities
    let conflicts: [ConflictInfo]
    let actionRequired: Bool
    let metadata: EventMetadata
}

enum CalendarEventType: String, CaseIterable, Codable {
    case leave = "LEAVE"
    case project = "PROJECT"
    case task = "TASK"
    case milestone = "MILESTONE"
    case resource = "RESOURCE"
    case maintenance = "MAINTENANCE"
    case deadline = "DEADLINE"
}

enum EventCategory: String, Codable {
    case workforce = "WORKFORCE"
    case project = "PROJECT"
    case equipment = "EQUIPMENT"
    case business = "BUSINESS"
    case compliance = "COMPLIANCE"
}

enum EventPriority: String, CaseIterable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
}

struct ResourceRequirement: Codable {
    let skillType: String
    let workerCount: Int
    let craneType: String?
    let certificationRequired: Bool
    let estimatedHours: Double
}

struct ConflictInfo: Codable {
    let conflictType: ConflictType
    let conflictingEventId: String
    let severity: ConflictSeverity
    let resolution: String?
}

enum ConflictType: String, Codable {
    case workerUnavailable = "WORKER_UNAVAILABLE"
    case equipmentDoubleBooked = "EQUIPMENT_DOUBLE_BOOKED"
    case skillsMismatch = "SKILLS_MISMATCH"
    case capacityExceeded = "CAPACITY_EXCEEDED"
    case deadlineConflict = "DEADLINE_CONFLICT"
}

struct RelatedEntities: Codable {
    let projectId: Int?
    let taskId: Int?
    let workerId: Int?
    let leaveRequestId: Int?
    let equipmentId: Int?
}
```

#### 1.2 Calendar Data Aggregation Service

```swift
// New file: Core/Services/API/Chef/ManagementCalendarAPIService.swift

class ManagementCalendarAPIService: BaseAPIService {
    
    func fetchUnifiedCalendarData(
        startDate: Date,
        endDate: Date,
        eventTypes: [CalendarEventType] = CalendarEventType.allCases,
        includeConflicts: Bool = true
    ) -> AnyPublisher<[ManagementCalendarEvent], APIError> {
        // Aggregate data from multiple sources
    }
    
    func fetchResourceAvailability(
        startDate: Date,
        endDate: Date,
        skillFilter: String? = nil
    ) -> AnyPublisher<[WorkerAvailability], APIError> {
        // Get worker availability matrix
    }
    
    func detectSchedulingConflicts(
        for event: ManagementCalendarEvent
    ) -> AnyPublisher<[ConflictInfo], APIError> {
        // Conflict detection and resolution suggestions
    }
    
    func updateEventSchedule(
        eventId: String,
        newStartDate: Date,
        newEndDate: Date? = nil
    ) -> AnyPublisher<ManagementCalendarEvent, APIError> {
        // Drag & drop scheduling updates
    }
}
```

#### 1.3 Server API Endpoints

```typescript
// New file: server/api/app/chef/management-calendar/route.ts

export async function GET(request: Request) {
    // Unified calendar data aggregation
    // Combines: projects, leave, tasks, milestones, deadlines
    // Returns: ManagementCalendarEvent[]
}

// New file: server/api/app/chef/management-calendar/conflicts/route.ts

export async function POST(request: Request) {
    // Conflict detection for scheduling changes
    // Validates: worker availability, equipment conflicts, skill requirements
    // Returns: ConflictInfo[] with resolution suggestions
}

// New file: server/api/app/chef/management-calendar/resources/route.ts

export async function GET(request: Request) {
    // Resource availability matrix
    // Returns: Worker availability, skills, current assignments
}
```

### Phase 2: Core Calendar Component

#### 2.1 Unified Calendar View

```swift
// New file: Features/Chef/ManagementCalendar/ChefManagementCalendarView.swift

struct ChefManagementCalendarView: View {
    @StateObject private var viewModel = ChefManagementCalendarViewModel()
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var activeEventTypes: Set<CalendarEventType> = Set(CalendarEventType.allCases)
    @State private var viewMode: CalendarViewMode = .month
    @State private var showingResourcePanel = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Controls Header
                CalendarControlsHeaderView(
                    activeEventTypes: $activeEventTypes,
                    viewMode: $viewMode,
                    showingResourcePanel: $showingResourcePanel
                )
                
                // Main Calendar Area
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Calendar Grid
                        UnifiedCalendarGridView(
                            selectedDate: $selectedDate,
                            displayedMonth: $displayedMonth,
                            activeEventTypes: activeEventTypes,
                            viewMode: viewMode,
                            events: viewModel.calendarEvents
                        )
                        .frame(width: showingResourcePanel ? geometry.size.width * 0.65 : geometry.size.width)
                        
                        // Resource Panel (Collapsible)
                        if showingResourcePanel {
                            ResourceAllocationPanelView()
                                .frame(width: geometry.size.width * 0.35)
                                .transition(.move(edge: .trailing))
                        }
                    }
                }
                
                // Selected Date Detail Panel
                SelectedDateDetailPanelView(
                    selectedDate: selectedDate,
                    events: viewModel.eventsForDate(selectedDate),
                    onEventUpdate: viewModel.updateEvent
                )
                .frame(height: 200)
            }
        }
        .navigationTitle("Management Calendar")
        .onAppear {
            viewModel.loadCalendarData()
        }
    }
}
```

#### 2.2 Multi-Layer Day View

```swift
// Features/Chef/ManagementCalendar/Components/MultiLayerDayView.swift

struct MultiLayerDayView: View {
    let date: Date
    let events: [ManagementCalendarEvent]
    let activeEventTypes: Set<CalendarEventType>
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    let onDrop: (ManagementCalendarEvent) -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Date Number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Event Indicators (Layered)
                ZStack {
                    // Background conflicts
                    if hasConflicts {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.red, lineWidth: 2)
                            .background(Color.red.opacity(0.1))
                    }
                    
                    // Event type indicators
                    VStack(spacing: 1) {
                        ForEach(visibleEventTypes, id: \.self) { eventType in
                            EventTypeIndicatorView(
                                eventType: eventType,
                                count: eventsByType[eventType]?.count ?? 0,
                                hasConflicts: eventsByType[eventType]?.contains { $0.conflicts.isNotEmpty } ?? false
                            )
                        }
                    }
                }
                .frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            // Handle drag & drop scheduling
            handleDrop(providers)
        }
    }
    
    private var eventsByType: [CalendarEventType: [ManagementCalendarEvent]] {
        Dictionary(grouping: filteredEvents, by: \.type)
    }
    
    private var filteredEvents: [ManagementCalendarEvent] {
        events.filter { activeEventTypes.contains($0.type) }
    }
    
    private var hasConflicts: Bool {
        filteredEvents.contains { !$0.conflicts.isEmpty }
    }
}
```

#### 2.3 Event Type Indicator Component

```swift
// Features/Chef/ManagementCalendar/Components/EventTypeIndicatorView.swift

struct EventTypeIndicatorView: View {
    let eventType: CalendarEventType
    let count: Int
    let hasConflicts: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(eventTypeColor)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(hasConflicts ? .red : .clear, lineWidth: 1)
                )
            
            if count > 1 {
                Text("\(count)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var eventTypeColor: Color {
        switch eventType {
        case .leave: return .orange
        case .project: return .blue
        case .task: return .green
        case .milestone: return .purple
        case .resource: return .gray
        case .maintenance: return .red
        case .deadline: return .pink
        }
    }
}
```

### Phase 3: Interactive Features

#### 3.1 Drag & Drop Scheduling

```swift
// Features/Chef/ManagementCalendar/Components/DragDropSchedulingHandler.swift

struct DragDropSchedulingHandler {
    let viewModel: ChefManagementCalendarViewModel
    
    func handleEventDrop(
        event: ManagementCalendarEvent,
        toDate: Date,
        completion: @escaping (Result<ManagementCalendarEvent, Error>) -> Void
    ) {
        // 1. Validate the proposed schedule change
        viewModel.validateScheduleChange(event: event, newDate: toDate) { validation in
            switch validation {
            case .success(let conflicts):
                if conflicts.isEmpty {
                    // No conflicts - proceed with update
                    updateEventSchedule(event: event, newDate: toDate, completion: completion)
                } else {
                    // Show conflict resolution dialog
                    showConflictResolutionDialog(conflicts: conflicts) { resolution in
                        if resolution == .proceed {
                            updateEventSchedule(event: event, newDate: toDate, completion: completion)
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateEventSchedule(
        event: ManagementCalendarEvent,
        newDate: Date,
        completion: @escaping (Result<ManagementCalendarEvent, Error>) -> Void
    ) {
        viewModel.updateEventSchedule(eventId: event.id, newStartDate: newDate)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { updatedEvent in
                    completion(.success(updatedEvent))
                }
            )
    }
}
```

#### 3.2 Resource Allocation Panel

```swift
// Features/Chef/ManagementCalendar/Components/ResourceAllocationPanelView.swift

struct ResourceAllocationPanelView: View {
    @StateObject private var viewModel = ResourceAllocationViewModel()
    @State private var selectedWorker: Worker?
    @State private var selectedDateRange: ClosedRange<Date>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Resource Allocation")
                    .font(.headline)
                Spacer()
                Button("Optimize") {
                    viewModel.optimizeResourceAllocation()
                }
            }
            
            // Worker Availability Matrix
            WorkerAvailabilityMatrixView(
                workers: viewModel.workers,
                dateRange: viewModel.currentDateRange,
                selectedWorker: $selectedWorker,
                selectedDateRange: $selectedDateRange
            )
            
            // Skills Matching Section
            SkillsMatchingView(
                requiredSkills: viewModel.currentSkillRequirements,
                availableWorkers: viewModel.availableWorkers
            )
            
            // Capacity Planning Chart
            CapacityPlanningChartView(
                capacityData: viewModel.capacityData,
                warningThreshold: 0.8,
                criticalThreshold: 0.95
            )
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
```

#### 3.3 Conflict Detection & Resolution

```swift
// Features/Chef/ManagementCalendar/ConflictResolution/ConflictDetectionEngine.swift

class ConflictDetectionEngine {
    
    func detectConflicts(for event: ManagementCalendarEvent, in calendar: [ManagementCalendarEvent]) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []
        
        // 1. Worker availability conflicts
        conflicts.append(contentsOf: detectWorkerConflicts(event: event, calendar: calendar))
        
        // 2. Equipment double-booking conflicts
        conflicts.append(contentsOf: detectEquipmentConflicts(event: event, calendar: calendar))
        
        // 3. Skills mismatch conflicts
        conflicts.append(contentsOf: detectSkillsConflicts(event: event))
        
        // 4. Capacity exceeded conflicts
        conflicts.append(contentsOf: detectCapacityConflicts(event: event, calendar: calendar))
        
        // 5. Deadline conflicts
        conflicts.append(contentsOf: detectDeadlineConflicts(event: event, calendar: calendar))
        
        return conflicts
    }
    
    private func detectWorkerConflicts(event: ManagementCalendarEvent, calendar: [ManagementCalendarEvent]) -> [ConflictInfo] {
        // Check if required workers are available during event timeframe
        // Consider: leave requests, other project assignments, sick days
    }
    
    private func detectEquipmentConflicts(event: ManagementCalendarEvent, calendar: [ManagementCalendarEvent]) -> [ConflictInfo] {
        // Check crane and equipment availability
        // Consider: maintenance schedules, other project assignments
    }
    
    private func detectSkillsConflicts(event: ManagementCalendarEvent) -> [ConflictInfo] {
        // Verify required skills are available
        // Consider: certifications, experience levels
    }
    
    func generateResolutionSuggestions(for conflicts: [ConflictInfo]) -> [ResolutionSuggestion] {
        // AI-powered conflict resolution suggestions
        // Options: reschedule, reassign workers, adjust project scope
    }
}
```

### Phase 4: Advanced Features

#### 4.1 Predictive Scheduling

```swift
// Features/Chef/ManagementCalendar/AI/PredictiveSchedulingEngine.swift

class PredictiveSchedulingEngine {
    
    func suggestOptimalSchedule(
        for project: Project,
        constraints: SchedulingConstraints
    ) -> SchedulingSuggestion {
        // AI-powered scheduling optimization
        // Considers: worker availability, skills, historical performance, weather, holidays
    }
    
    func predictResourceNeeds(
        for dateRange: ClosedRange<Date>
    ) -> ResourcePrediction {
        // Predict future resource requirements based on:
        // - Historical patterns
        // - Seasonal trends
        // - Planned projects
        // - Expected leave patterns
    }
    
    func identifySchedulingRisks(
        for calendar: [ManagementCalendarEvent]
    ) -> [SchedulingRisk] {
        // Identify potential issues:
        // - Understaffing periods
        // - Critical skill shortages
        // - Equipment bottlenecks
        // - Deadline conflicts
    }
}
```

#### 4.2 Performance Analytics

```swift
// Features/Chef/ManagementCalendar/Analytics/CalendarAnalyticsView.swift

struct CalendarAnalyticsView: View {
    @StateObject private var viewModel = CalendarAnalyticsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Utilization Metrics
                UtilizationMetricsCard(
                    workerUtilization: viewModel.workerUtilization,
                    equipmentUtilization: viewModel.equipmentUtilization,
                    capacityTrends: viewModel.capacityTrends
                )
                
                // Schedule Efficiency
                ScheduleEfficiencyCard(
                    onTimePerformance: viewModel.onTimePerformance,
                    rescheduleRate: viewModel.rescheduleRate,
                    conflictResolutionTime: viewModel.conflictResolutionTime
                )
                
                // Resource Optimization
                ResourceOptimizationCard(
                    skillsUtilization: viewModel.skillsUtilization,
                    crossTrainingOpportunities: viewModel.crossTrainingOpportunities,
                    capacityGaps: viewModel.capacityGaps
                )
                
                // Predictive Insights
                PredictiveInsightsCard(
                    upcomingBottlenecks: viewModel.upcomingBottlenecks,
                    seasonalTrends: viewModel.seasonalTrends,
                    optimizationSuggestions: viewModel.optimizationSuggestions
                )
            }
            .padding()
        }
        .navigationTitle("Calendar Analytics")
    }
}
```

## Integration with Existing Systems

### 4.1 AppStateManager Integration

```swift
// Core/Managers/AppStateManager.swift (Enhancement)

class AppStateManager: ObservableObject {
    // ... existing code ...
    
    @Published var managementCalendarViewModel: ChefManagementCalendarViewModel?
    
    private func preloadChefViewModels() {
        // ... existing chef viewmodels ...
        
        // Add management calendar preloading
        Task { @MainActor in
            self.managementCalendarViewModel = ChefManagementCalendarViewModel()
            await self.managementCalendarViewModel?.initialize()
        }
    }
}
```

### 4.2 Navigation Integration

```swift
// UI/Views/Navigation/RoleBasedRootView.swift (Enhancement)

// Add to Chef TabView:
TabView {
    // ... existing tabs ...
    
    ChefManagementCalendarView()
        .environmentObject(appStateManager.managementCalendarViewModel ?? ChefManagementCalendarViewModel())
        .tabItem {
            Image(systemName: "calendar.circle")
            Text("Calendar")
        }
}
```

## Database Schema Enhancements

### 5.1 Calendar Events Table

```sql
-- New table: CalendarEvents
CREATE TABLE CalendarEvents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_type ENUM('LEAVE', 'PROJECT', 'TASK', 'MILESTONE', 'RESOURCE', 'MAINTENANCE', 'DEADLINE') NOT NULL,
    category ENUM('WORKFORCE', 'PROJECT', 'EQUIPMENT', 'BUSINESS', 'COMPLIANCE') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    priority ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT 'MEDIUM',
    status ENUM('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED') DEFAULT 'PLANNED',
    action_required BOOLEAN DEFAULT FALSE,
    related_project_id INT,
    related_task_id INT,
    related_employee_id INT,
    related_leave_request_id INT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (related_project_id) REFERENCES Projects(id),
    FOREIGN KEY (related_task_id) REFERENCES Tasks(id),
    FOREIGN KEY (related_employee_id) REFERENCES Employees(employee_id),
    FOREIGN KEY (related_leave_request_id) REFERENCES LeaveRequests(id)
);
```

### 5.2 Resource Conflicts Table

```sql
-- New table: ResourceConflicts
CREATE TABLE ResourceConflicts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    conflict_type ENUM('WORKER_UNAVAILABLE', 'EQUIPMENT_DOUBLE_BOOKED', 'SKILLS_MISMATCH', 'CAPACITY_EXCEEDED', 'DEADLINE_CONFLICT') NOT NULL,
    severity ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
    conflicting_event_id INT,
    resolution_status ENUM('PENDING', 'RESOLVED', 'IGNORED') DEFAULT 'PENDING',
    resolution_notes TEXT,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    
    FOREIGN KEY (event_id) REFERENCES CalendarEvents(id),
    FOREIGN KEY (conflicting_event_id) REFERENCES CalendarEvents(id)
);
```

## Implementation Timeline

### Week 1: Foundation
- [ ] Create unified data models and API service
- [ ] Implement basic server endpoints for calendar aggregation
- [ ] Set up database schema enhancements

### Week 2: Core Calendar
- [ ] Build unified calendar view component
- [ ] Implement multi-layer day view with event indicators
- [ ] Add calendar controls and filtering

### Week 3: Interactive Features
- [ ] Implement drag & drop scheduling
- [ ] Add conflict detection engine
- [ ] Create resource allocation panel

### Week 4: Advanced Features & Polish
- [ ] Add predictive scheduling suggestions
- [ ] Implement analytics dashboard
- [ ] Performance optimization and testing

## Testing Strategy

### Unit Tests
- Calendar event model validation
- Conflict detection logic
- Resource allocation algorithms
- Date range calculations

### Integration Tests
- API endpoint functionality
- Calendar data aggregation
- Drag & drop interaction handling
- Real-time data synchronization

### User Acceptance Tests
- Workforce planning scenarios
- Project scheduling workflows
- Conflict resolution processes
- Mobile responsiveness

## Performance Considerations

### Data Loading Optimization
- **Lazy Loading**: Load only visible calendar data
- **Caching Strategy**: Cache frequently accessed data
- **Background Refresh**: Update data without blocking UI
- **Pagination**: Implement pagination for large datasets

### Real-time Updates
- **WebSocket Integration**: Real-time calendar updates
- **Optimistic Updates**: Immediate UI feedback for user actions
- **Conflict Resolution**: Automatic conflict detection and alerts

## Success Metrics

### Operational Efficiency
- **Scheduling Time Reduction**: Target 50% reduction in manual scheduling time
- **Conflict Prevention**: Target 80% reduction in scheduling conflicts
- **Resource Utilization**: Target 15% improvement in worker utilization

### User Experience
- **User Adoption**: Target 90% adoption rate within 30 days
- **Task Completion**: Target 25% faster completion of scheduling tasks
- **User Satisfaction**: Target 4.5/5 satisfaction score

## Conclusion

This implementation plan leverages the existing strong foundation in the KSR Cranes application to create a comprehensive management calendar. The phased approach ensures minimal disruption to current operations while delivering immediate value to Chef users for workforce planning and resource management.

The solution addresses the specific needs identified:
- **Trwające projekty**: Project timeline visualization with start/end dates
- **Urlopy chorobowe dni**: Integration with existing leave management system
- **Zadania i assignments**: Task deadlines and worker assignments
- **Lepsze zarządzanie pracownikami**: Resource allocation and conflict detection

The interactive calendar will significantly improve workforce planning capabilities while maintaining the high quality and performance standards established in the KSR Cranes application.