import Foundation
import Combine

final class ManagementCalendarAPIService: BaseAPIService {
    static let shared = ManagementCalendarAPIService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Retry Configuration
    
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    // MARK: - Unified Calendar Data
    
    func fetchUnifiedCalendarData(
        startDate: Date,
        endDate: Date,
        eventTypes: [CalendarEventType] = CalendarEventType.allCases,
        includeConflicts: Bool = true,
        includeMetadata: Bool = true
    ) -> AnyPublisher<ManagementCalendarResponse, APIError> {
        
        let request = ManagementCalendarRequest(
            startDate: startDate,
            endDate: endDate,
            eventTypes: eventTypes,
            includeConflicts: includeConflicts,
            includeMetadata: includeMetadata
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/management-calendar/unified",
            method: "POST",
            body: request
        )
        .retry(maxRetryAttempts) // Add retry logic for network failures
        .tryMap { data in
            try self.jsonDecoder().decode(ManagementCalendarResponse.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(
            receiveSubscription: { _ in
                print("📡 [ManagementCalendar] Fetching calendar data...")
            },
            receiveOutput: { response in
                print("📅 [ManagementCalendar] Loaded \(response.events.count) events for date range \(startDate.iso8601String) - \(endDate.iso8601String)")
                print("📊 [ManagementCalendar] Summary: \(response.summary.totalEvents) total events, \(response.conflicts.count) conflicts")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ [ManagementCalendar] Failed to load calendar data: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Worker Availability Matrix
    
    func fetchWorkerAvailabilityMatrix(
        startDate: Date,
        endDate: Date,
        workerIds: [Int]? = nil,
        skillFilter: String? = nil
    ) -> AnyPublisher<WorkerAvailabilityMatrix, APIError> {
        
        var endpoint = "/api/app/chef/workers/availability"
        var queryItems: [String] = [
            "start_date=\(startDate.iso8601String)",
            "end_date=\(endDate.iso8601String)"
        ]
        
        if let workerIds = workerIds, !workerIds.isEmpty {
            queryItems.append("worker_ids=\(workerIds.map(String.init).joined(separator: ","))")
        }
        
        if let skillFilter = skillFilter {
            queryItems.append("skill_filter=\(skillFilter)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<String>.none
        )
        .retry(maxRetryAttempts) // Add retry logic for network failures
        .tryMap { data in
            try self.jsonDecoder().decode(WorkerAvailabilityMatrix.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { matrix in
            print("👥 [WorkerMatrix] Loaded availability for \(matrix.workers.count) workers")
            print("📈 [WorkerMatrix] Average utilization: \(String(format: "%.1f", matrix.summary.averageUtilization * 100))%")
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Conflict Detection
    
    func detectSchedulingConflicts(
        for event: ManagementCalendarEvent
    ) -> AnyPublisher<[ConflictInfo], APIError> {
        
        struct ConflictRequest: Codable {
            let event_id: String
            let date: String
            let end_date: String
            let resource_requirements: [ResourceRequirement]
        }
        
        let requestBody = ConflictRequest(
            event_id: event.id,
            date: event.date.iso8601String,
            end_date: event.endDate?.iso8601String ?? event.date.iso8601String,
            resource_requirements: event.resourceRequirements
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/management-calendar/conflicts",
            method: "POST",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode([ConflictInfo].self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { conflicts in
            if !conflicts.isEmpty {
                print("⚠️ [ConflictDetection] Found \(conflicts.count) conflicts for event: \(event.title)")
                for conflict in conflicts {
                    print("   - \(conflict.conflictType.displayName): \(conflict.description)")
                }
            }
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Event Management
    
    func updateEventSchedule(
        eventId: String,
        newStartDate: Date,
        newEndDate: Date? = nil,
        validateConflicts: Bool = true
    ) -> AnyPublisher<ManagementCalendarEvent, APIError> {
        
        struct UpdateScheduleRequest: Codable {
            let event_id: String
            let new_start_date: String
            let new_end_date: String?
            let validate_conflicts: Bool
        }
        
        let requestBody = UpdateScheduleRequest(
            event_id: eventId,
            new_start_date: newStartDate.iso8601String,
            new_end_date: newEndDate?.iso8601String,
            validate_conflicts: validateConflicts
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/management-calendar/events/\(eventId)/schedule",
            method: "PUT",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode(ManagementCalendarEvent.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { updatedEvent in
            print("✅ [EventUpdate] Updated schedule for: \(updatedEvent.title)")
            print("📅 [EventUpdate] New date: \(newStartDate.iso8601String)")
        })
        .eraseToAnyPublisher()
    }
    
    func createCalendarEvent(
        type: CalendarEventType,
        title: String,
        description: String,
        startDate: Date,
        endDate: Date? = nil,
        priority: EventPriority = .medium,
        resourceRequirements: [ResourceRequirement] = [],
        relatedEntities: RelatedEntities
    ) -> AnyPublisher<ManagementCalendarEvent, APIError> {
        
        struct CreateEventRequest: Codable {
            let type: String
            let title: String
            let description: String
            let start_date: String
            let end_date: String?
            let priority: String
            let resource_requirements: [ResourceRequirement]
            let related_entities: RelatedEntities
        }
        
        let requestBody = CreateEventRequest(
            type: type.rawValue,
            title: title,
            description: description,
            start_date: startDate.iso8601String,
            end_date: endDate?.iso8601String,
            priority: priority.rawValue,
            resource_requirements: resourceRequirements,
            related_entities: relatedEntities
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/management-calendar/events",
            method: "POST",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode(ManagementCalendarEvent.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { event in
            print("✨ [EventCreation] Created new \(type.displayName): \(title)")
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Resource Planning
    
    func suggestOptimalWorkerAssignment(
        for taskId: Int,
        requiredSkills: [String],
        estimatedHours: Double,
        deadline: Date? = nil
    ) -> AnyPublisher<[WorkerAssignmentSuggestion], APIError> {
        
        struct AssignmentSuggestionRequest: Codable {
            let task_id: Int
            let required_skills: [String]
            let estimated_hours: Double
            let deadline: String?
        }
        
        let requestBody = AssignmentSuggestionRequest(
            task_id: taskId,
            required_skills: requiredSkills,
            estimated_hours: estimatedHours,
            deadline: deadline?.iso8601String
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/tasks/\(taskId)/assignment-suggestions",
            method: "POST",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode([WorkerAssignmentSuggestion].self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { suggestions in
            print("💡 [AssignmentSuggestion] Found \(suggestions.count) suitable workers for task \(taskId)")
            for suggestion in suggestions.prefix(3) {
                print("   - \(suggestion.worker.name): \(String(format: "%.0f", suggestion.matchScore * 100))% match")
            }
        })
        .eraseToAnyPublisher()
    }
    
    func getCapacityAnalysis(
        for dateRange: DateRange,
        includeProjections: Bool = true
    ) -> AnyPublisher<CapacityAnalysis, APIError> {
        
        var endpoint = "/api/app/chef/capacity/analysis"
        let queryItems = [
            "start_date=\(dateRange.startDate.iso8601String)",
            "end_date=\(dateRange.endDate.iso8601String)",
            "include_projections=\(includeProjections)"
        ]
        
        endpoint += "?" + queryItems.joined(separator: "&")
        
        return makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<String>.none
        )
        .tryMap { data in
            try self.jsonDecoder().decode(CapacityAnalysis.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { analysis in
            print("📊 [CapacityAnalysis] Current utilization: \(String(format: "%.1f", analysis.currentUtilization * 100))%")
            if analysis.bottlenecks.count > 0 {
                print("🚨 [CapacityAnalysis] Found \(analysis.bottlenecks.count) capacity bottlenecks")
            }
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Task Assignment Management
    
    func assignWorkerToTask(
        workerId: Int,
        taskId: Int,
        craneModelId: Int? = nil,
        estimatedHours: Double? = nil,
        notes: String? = nil
    ) -> AnyPublisher<TaskAssignmentResponse, APIError> {
        
        struct TaskAssignmentRequest: Codable {
            let employee_id: Int
            let crane_model_id: Int?
            let estimated_hours: Double?
            let notes: String?
        }
        
        let requestBody = TaskAssignmentRequest(
            employee_id: workerId,
            crane_model_id: craneModelId,
            estimated_hours: estimatedHours,
            notes: notes
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/tasks/\(taskId)/assignments",
            method: "POST",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode(TaskAssignmentResponse.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { response in
            print("👤 [TaskAssignment] Assigned worker \(workerId) to task \(taskId)")
            if !response.conflicts.isEmpty {
                print("⚠️ [TaskAssignment] Assignment created \(response.conflicts.count) conflicts")
            }
        })
        .eraseToAnyPublisher()
    }
    
    func removeWorkerFromTask(
        assignmentId: Int,
        reason: String? = nil
    ) -> AnyPublisher<EmptyResponse, APIError> {
        
        struct RemoveAssignmentRequest: Codable {
            let reason: String?
        }
        
        let requestBody = reason != nil ? RemoveAssignmentRequest(reason: reason) : nil
        
        return makeRequest(
            endpoint: "/api/app/chef/task-assignments/\(assignmentId)",
            method: "DELETE",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode(EmptyResponse.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { _ in
            print("❌ [TaskAssignment] Removed assignment \(assignmentId)")
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Calendar Summary & Analytics
    
    func getCalendarSummary(
        for date: Date = Date()
    ) -> AnyPublisher<CalendarSummary, APIError> {
        
        let endpoint = "/api/app/chef/management-calendar/summary?date=\(date.iso8601String)"
        
        return makeRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<String>.none
        )
        .retry(maxRetryAttempts) // Add retry logic for network failures
        .tryMap { data in
            try self.jsonDecoder().decode(CalendarSummary.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { summary in
            print("📋 [CalendarSummary] \(summary.totalEvents) events, \(summary.availableWorkers) workers available")
        })
        .eraseToAnyPublisher()
    }
    
    func refreshCalendarCache(
        for dateRange: DateRange
    ) -> AnyPublisher<CacheRefreshResponse, APIError> {
        
        struct CacheRefreshRequest: Codable {
            let start_date: String
            let end_date: String
        }
        
        let requestBody = CacheRefreshRequest(
            start_date: dateRange.startDate.iso8601String,
            end_date: dateRange.endDate.iso8601String
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/management-calendar/refresh",
            method: "POST",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode(CacheRefreshResponse.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { response in
            print("🔄 [CacheRefresh] Refreshed \(response.eventsUpdated) events")
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Validation Helpers
    
    func validateScheduleChange(
        event: ManagementCalendarEvent,
        newDate: Date,
        newEndDate: Date? = nil
    ) -> AnyPublisher<CalendarValidationResult, APIError> {
        
        struct ValidationRequest: Codable {
            let event_id: String
            let current_start_date: String
            let new_start_date: String
            let new_end_date: String?
            let resource_requirements: [ResourceRequirement]
        }
        
        let requestBody = ValidationRequest(
            event_id: event.id,
            current_start_date: event.date.iso8601String,
            new_start_date: newDate.iso8601String,
            new_end_date: newEndDate?.iso8601String ?? event.endDate?.iso8601String,
            resource_requirements: event.resourceRequirements
        )
        
        return makeRequest(
            endpoint: "/api/app/chef/management-calendar/validate",
            method: "POST",
            body: requestBody
        )
        .tryMap { data in
            try self.jsonDecoder().decode(CalendarValidationResult.self, from: data)
        }
        .mapError { error in
            (error as? APIError) ?? .decodingError(error)
        }
        .handleEvents(receiveOutput: { result in
            if !result.isValid {
                print("❌ [Validation] Schedule change validation failed: \(result.errors.joined(separator: ", "))")
            } else if !result.warnings.isEmpty {
                print("⚠️ [Validation] Schedule change has warnings: \(result.warnings.joined(separator: ", "))")
            }
        })
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Models

struct WorkerAssignmentSuggestion: Codable {
    let worker: WorkerForCalendar
    let matchScore: Double
    let availableHours: Double
    let skillMatch: [SkillMatch]
    let conflicts: [ConflictInfo]
    let estimatedStartDate: Date?
    let notes: String?
    
    var isOptimal: Bool {
        matchScore >= 0.8 && conflicts.isEmpty
    }
}

struct SkillMatch: Codable {
    let requiredSkill: String
    let workerSkillLevel: CalendarSkillLevel
    let isMatch: Bool
    let isCertified: Bool
    let experienceYears: Int?
}

struct TaskAssignmentResponse: Codable {
    let assignmentId: Int
    let success: Bool
    let conflicts: [ConflictInfo]
    let warnings: [String]
    let estimatedImpact: AssignmentImpact?
}

struct AssignmentImpact: Codable {
    let utilizationChange: Double
    let projectDelay: TimeInterval?
    let affectedWorkers: [Int]
    let recommendedActions: [String]
}

struct CapacityAnalysis: Codable {
    let dateRange: DateRange
    let currentUtilization: Double
    let projectedUtilization: Double?
    let bottlenecks: [CapacityBottleneck]
    let recommendations: [CapacityRecommendation]
    let skillGaps: [SkillGap]
}

struct CapacityBottleneck: Codable {
    let date: Date
    let type: BottleneckType
    let severity: CalendarConflictSeverity
    let affectedWorkers: [Int]
    let description: String
    let suggestedResolution: String?
}

enum BottleneckType: String, Codable {
    case overallCapacity = "OVERALL_CAPACITY"
    case specificSkill = "SPECIFIC_SKILL"
    case equipmentShortage = "EQUIPMENT_SHORTAGE"
    case keyPersonnel = "KEY_PERSONNEL"
}

struct CapacityRecommendation: Codable {
    let type: RecommendationType
    let priority: EventPriority
    let description: String
    let estimatedImpact: String
    let implementationEffort: String
}

enum RecommendationType: String, Codable {
    case redistributeWork = "REDISTRIBUTE_WORK"
    case adjustDeadlines = "ADJUST_DEADLINES"
    case increaseCapacity = "INCREASE_CAPACITY"
    case crossTrain = "CROSS_TRAIN"
    case outsource = "OUTSOURCE"
}

struct SkillGap: Codable {
    let skill: String
    let currentCapacity: Int
    let requiredCapacity: Int
    let gap: Int
    let criticalProjects: [String]
    let trainingOptions: [String]
}


struct ScheduleAlternative: Codable {
    let newStartDate: Date
    let newEndDate: Date?
    let score: Double
    let reasoning: String
    let tradeOffs: [String]
}

struct CacheRefreshResponse: Codable {
    let success: Bool
    let eventsUpdated: Int
    let workersUpdated: Int
    let conflictsResolved: Int
    let refreshedAt: Date
    let nextScheduledRefresh: Date?
}

struct EmptyResponse: Codable {
    let success: Bool
    let message: String?
}

struct CalendarValidationResult: Codable {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    let conflicts: [ConflictInfo]
    let suggestedAlternatives: [ScheduleAlternative]?
}

