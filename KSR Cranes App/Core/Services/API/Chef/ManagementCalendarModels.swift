import Foundation

// MARK: - Unified Management Calendar Models

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
    
    var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(date)
    }
    
    var isUrgent: Bool {
        priority == .critical || (date.timeIntervalSinceNow < 48 * 3600) // Within 48 hours
    }
}

enum CalendarEventType: String, CaseIterable, Codable {
    case leave = "LEAVE"
    case project = "PROJECT"
    case task = "TASK"
    case milestone = "MILESTONE"
    case resource = "RESOURCE"
    case maintenance = "MAINTENANCE"
    case deadline = "DEADLINE"
    case workPlan = "WORK_PLAN"
    
    var displayName: String {
        switch self {
        case .leave: return "Leave"
        case .project: return "Project"
        case .task: return "Task"
        case .milestone: return "Milestone"
        case .resource: return "Resource"
        case .maintenance: return "Maintenance"
        case .deadline: return "Deadline"
        case .workPlan: return "Work Plan"
        }
    }
    
    var color: String {
        switch self {
        case .leave: return "#FF9500" // Orange
        case .project: return "#007AFF" // Blue
        case .task: return "#34C759" // Green
        case .milestone: return "#AF52DE" // Purple
        case .resource: return "#8E8E93" // Gray
        case .maintenance: return "#FF3B30" // Red
        case .deadline: return "#FF2D92" // Pink
        case .workPlan: return "#00C7BE" // Teal
        }
    }
}

enum EventCategory: String, Codable {
    case workforce = "WORKFORCE"
    case project = "PROJECT"
    case equipment = "EQUIPMENT"
    case business = "BUSINESS"
    case compliance = "COMPLIANCE"
    case operatorAssignment = "OPERATOR_ASSIGNMENT"  // ✅ FIXED: Added missing category
    
    var displayName: String {
        switch self {
        case .workforce: return "Workforce"
        case .project: return "Project"
        case .equipment: return "Equipment"
        case .business: return "Business"
        case .compliance: return "Compliance"
        case .operatorAssignment: return "Operator Assignment"
        }
    }
}

enum EventPriority: String, CaseIterable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

enum EventStatus: String, Codable {
    case planned = "PLANNED"
    case inProgress = "IN_PROGRESS"  // Added missing case
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    case overdue = "OVERDUE"
    
    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .overdue: return "Overdue"
        }
    }
}

struct ResourceRequirement: Codable {
    let skillType: String?
    let workerCount: Int
    let craneType: String?
    let certificationRequired: Bool?
    let estimatedHours: Double?
    let urgency: EventPriority?
    
    var isSkillMatch: Bool {
        // Will be calculated based on available workers
        return true
    }
    
    // Provide defaults for missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        skillType = try container.decodeIfPresent(String.self, forKey: .skillType)
        workerCount = try container.decodeIfPresent(Int.self, forKey: .workerCount) ?? 1
        craneType = try container.decodeIfPresent(String.self, forKey: .craneType)
        certificationRequired = try container.decodeIfPresent(Bool.self, forKey: .certificationRequired) ?? false
        estimatedHours = try container.decodeIfPresent(Double.self, forKey: .estimatedHours) ?? 0.0
        urgency = try container.decodeIfPresent(EventPriority.self, forKey: .urgency) ?? .medium
    }
}

struct ConflictInfo: Codable {
    let conflictType: ConflictType
    let conflictingEventId: String
    let severity: CalendarConflictSeverity
    let description: String
    let resolution: String?
    let affectedWorkers: [Int]
    
    var isResolvable: Bool {
        severity != .critical && resolution != nil
    }
}

enum ConflictType: String, Codable {
    case workerUnavailable = "WORKER_UNAVAILABLE"
    case equipmentDoubleBooked = "EQUIPMENT_DOUBLE_BOOKED"
    case skillsMismatch = "SKILLS_MISMATCH"
    case capacityExceeded = "CAPACITY_EXCEEDED"
    case deadlineConflict = "DEADLINE_CONFLICT"
    case leaveConflict = "LEAVE_CONFLICT"
    
    var displayName: String {
        switch self {
        case .workerUnavailable: return "Worker Unavailable"
        case .equipmentDoubleBooked: return "Equipment Double Booked"
        case .skillsMismatch: return "Skills Mismatch"
        case .capacityExceeded: return "Capacity Exceeded"
        case .deadlineConflict: return "Deadline Conflict"
        case .leaveConflict: return "Leave Conflict"
        }
    }
}

enum CalendarConflictSeverity: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    var color: String {
        switch self {
        case .low: return "#34C759" // Green
        case .medium: return "#FF9500" // Orange
        case .high: return "#FF3B30" // Red
        case .critical: return "#8B0000" // Dark Red
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

struct RelatedEntities: Codable {
    let projectId: Int?
    let taskId: Int?
    let workerId: Int?
    let leaveRequestId: Int?
    let equipmentId: Int?
    let workPlanId: Int?
    
    var hasRelatedEntities: Bool {
        projectId != nil || taskId != nil || workerId != nil || 
        leaveRequestId != nil || equipmentId != nil || workPlanId != nil
    }
}

struct EventMetadata: Codable {
    let createdBy: Int?
    let createdAt: Date?
    let lastModifiedBy: Int?
    let lastModifiedAt: Date?
    let estimatedDuration: TimeInterval?
    let actualDuration: TimeInterval?
    let costEstimate: Double?
    let notes: String?
    let attachments: [String]?
    
    var efficiency: Double? {
        guard let estimated = estimatedDuration,
              let actual = actualDuration,
              estimated > 0 else { return nil }
        return estimated / actual
    }
}

// MARK: - Worker Availability Models

struct WorkerAvailabilityMatrix: Codable {
    let dateRange: DateRange
    let workers: [WorkerAvailabilityRow]
    let summary: AvailabilitySummary
    let lastUpdated: Date
    
    func getAvailability(workerId: Int, date: Date) -> DayAvailability? {
        return workers.first { $0.worker.id == workerId }?
                     .dailyAvailability[date.iso8601String]
    }
}

struct WorkerAvailabilityRow: Identifiable, Codable {
    let id: Int
    let worker: WorkerForCalendar
    let dailyAvailability: [String: DayAvailability] // Key: YYYY-MM-DD
    let weeklyStats: WeeklyStats
    let monthlyStats: MonthlyStats?
    
    func getAvailability(for date: Date) -> DayAvailability? {
        return dailyAvailability[date.iso8601String]
    }
    
    var utilizationTrend: UtilizationTrend {
        let utilizations = dailyAvailability.values.map { $0.utilization }
        let average = utilizations.reduce(0, +) / Double(utilizations.count)
        
        if average >= 0.9 { return .overutilized }
        if average >= 0.7 { return .optimal }
        if average >= 0.5 { return .underutilized }
        return .minimal
    }
}

enum UtilizationTrend: String, Codable {
    case overutilized = "OVERUTILIZED"
    case optimal = "OPTIMAL"
    case underutilized = "UNDERUTILIZED"
    case minimal = "MINIMAL"
    
    var color: String {
        switch self {
        case .overutilized: return "#FF3B30" // Red
        case .optimal: return "#34C759" // Green
        case .underutilized: return "#FF9500" // Orange
        case .minimal: return "#8E8E93" // Gray
        }
    }
}

struct WorkerForCalendar: Identifiable, Codable {
    let id: Int
    let name: String
    let role: String
    let email: String
    let phone: String?
    let skills: [WorkerSkill]
    let profilePictureUrl: String?
    let isActive: Bool
    let hireDate: Date?
    
    var primarySkills: [WorkerSkill] {
        skills.filter { $0.level == .expert || $0.level == .advanced }
    }
    
    var displayName: String {
        name.components(separatedBy: " ").prefix(2).joined(separator: " ")
    }
}

struct WorkerSkill: Codable {
    let skillType: String
    let level: CalendarSkillLevel
    let certified: Bool
    let certificationExpires: Date?
    let yearsExperience: Int?
    
    var isExpiringSoon: Bool {
        guard let expiryDate = certificationExpires else { return false }
        return expiryDate.timeIntervalSinceNow < 30 * 24 * 3600 // 30 days
    }
}

enum CalendarSkillLevel: String, CaseIterable, Codable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    case expert = "EXPERT"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

struct DayAvailability: Codable {
    let status: AvailabilityStatus
    let assignedHours: Double
    let maxCapacity: Double
    let projects: [ProjectAssignment]
    let tasks: [CalendarTaskAssignment]
    let leaveInfo: LeaveInfo?
    let conflicts: [ConflictInfo]
    let workPlan: WorkPlanInfo?
    
    var utilization: Double {
        guard maxCapacity > 0 else { return 0 }
        return min(assignedHours / maxCapacity, 1.0)
    }
    
    var isOverloaded: Bool {
        assignedHours > maxCapacity
    }
    
    var availableHours: Double {
        max(0, maxCapacity - assignedHours)
    }
}

enum AvailabilityStatus: String, CaseIterable, Codable {
    case available = "AVAILABLE"
    case assigned = "ASSIGNED"
    case onLeave = "ON_LEAVE"
    case sick = "SICK"
    case overloaded = "OVERLOADED"
    case partiallyBusy = "PARTIALLY_BUSY"
    case unavailable = "UNAVAILABLE"
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .assigned: return "Assigned"
        case .onLeave: return "On Leave"
        case .sick: return "Sick"
        case .overloaded: return "Overloaded"
        case .partiallyBusy: return "Partially Busy"
        case .unavailable: return "Unavailable"
        }
    }
    
    var color: String {
        switch self {
        case .available: return "#34C759" // Green
        case .assigned: return "#FF9500" // Orange
        case .onLeave: return "#007AFF" // Blue
        case .sick: return "#FF3B30" // Red
        case .overloaded: return "#8B0000" // Dark Red
        case .partiallyBusy: return "#AF52DE" // Purple
        case .unavailable: return "#8E8E93" // Gray
        }
    }
}

struct ProjectAssignment: Identifiable, Codable {
    let id: Int
    let projectId: Int
    let projectName: String
    let taskId: Int?
    let taskName: String?
    let hours: Double
    let priority: EventPriority
    let deadline: Date?
    
    var isUrgent: Bool {
        guard let deadline = deadline else { return false }
        return deadline.timeIntervalSinceNow < 7 * 24 * 3600 // Within 7 days
    }
}

struct CalendarTaskAssignment: Identifiable, Codable {
    let id: Int
    let taskId: Int
    let taskName: String
    let projectName: String
    let hours: Double
    let deadline: Date?
    let requiredSkills: [String]
    let craneModel: String?
    
    var status: CalendarTaskStatus {
        guard let deadline = deadline else { return .inProgress }
        
        if deadline < Date() {
            return .overdue
        } else if deadline.timeIntervalSinceNow < 24 * 3600 {
            return .urgent
        }
        return .inProgress
    }
}

enum CalendarTaskStatus: String, Codable {
    case planned = "PLANNED"
    case inProgress = "IN_PROGRESS"
    case urgent = "URGENT"
    case overdue = "OVERDUE"
    case completed = "COMPLETED"
    
    var color: String {
        switch self {
        case .planned: return "#8E8E93" // Gray
        case .inProgress: return "#007AFF" // Blue
        case .urgent: return "#FF9500" // Orange
        case .overdue: return "#FF3B30" // Red
        case .completed: return "#34C759" // Green
        }
    }
}

struct LeaveInfo: Codable {
    let leaveRequestId: Int
    let type: CalendarLeaveType
    let isHalfDay: Bool
    let reason: String?
    let approvedBy: String?
    let approvedAt: Date?
    
    var displayName: String {
        let typeString = type.displayName
        return isHalfDay ? "\(typeString) (Half Day)" : typeString
    }
}

enum CalendarLeaveType: String, CaseIterable, Codable {
    case vacation = "VACATION"
    case sick = "SICK"
    case personal = "PERSONAL"
    case parental = "PARENTAL"
    case compensatory = "COMPENSATORY"
    case emergency = "EMERGENCY"
    
    var displayName: String {
        switch self {
        case .vacation: return "Vacation"
        case .sick: return "Sick Leave"
        case .personal: return "Personal Day"
        case .parental: return "Parental Leave"
        case .compensatory: return "Compensatory Time"
        case .emergency: return "Emergency Leave"
        }
    }
}

struct WorkPlanInfo: Codable {
    let workPlanId: Int
    let description: String?
    let createdBy: String
    let startTime: String?
    let endTime: String?
    let estimatedHours: Double?
}

struct WeeklyStats: Codable {
    let totalHours: Double
    let utilization: Double
    let projectCount: Int
    let taskCount: Int
    let averageDaily: Double
    let peakDay: String?
    let efficiency: Double?
    
    var utilizationLevel: UtilizationLevel {
        if utilization >= 1.0 { return .overloaded }
        if utilization >= 0.8 { return .high }
        if utilization >= 0.6 { return .medium }
        if utilization >= 0.3 { return .low }
        return .minimal
    }
}

struct MonthlyStats: Codable {
    let totalHours: Double
    let averageUtilization: Double
    let projectsCompleted: Int
    let tasksCompleted: Int
    let leaveDays: Int
    let overtime: Double
    let trend: UtilizationTrend
}

enum UtilizationLevel: String, Codable {
    case minimal = "MINIMAL"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case overloaded = "OVERLOADED"
    
    var color: String {
        switch self {
        case .minimal: return "#8E8E93" // Gray
        case .low: return "#34C759" // Green
        case .medium: return "#007AFF" // Blue
        case .high: return "#FF9500" // Orange
        case .overloaded: return "#FF3B30" // Red
        }
    }
}

struct AvailabilitySummary: Codable {
    let totalWorkers: Int
    let availableToday: Int
    let onLeaveToday: Int
    let sickToday: Int
    let overloadedToday: Int
    let averageUtilization: Double
    let criticalSkillGaps: [String]
    let upcomingDeadlines: Int
    
    var healthScore: Double {
        let availabilityRatio = Double(availableToday) / Double(totalWorkers)
        let utilizationScore = min(averageUtilization, 1.0)
        let gapPenalty = Double(criticalSkillGaps.count) * 0.1
        
        return max(0, min(1, (availabilityRatio + utilizationScore) / 2 - gapPenalty))
    }
}

struct DateRange: Codable {
    let startDate: Date
    let endDate: Date
    
    var days: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var weeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
    }
    
    // Regular initializer for creating DateRange instances
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // ✅ FIXED: Custom decoding for multiple date formats from server
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let startDateString = try container.decode(String.self, forKey: .startDate)
        let endDateString = try container.decode(String.self, forKey: .endDate)
        
        // Try multiple date formats
        let formatters: [DateFormatter] = [
            // ISO8601 with timezone
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            // Simple date format
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            // ISO8601 without timezone
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]
        
        var startDate: Date?
        var endDate: Date?
        
        // Try each formatter until one works
        for formatter in formatters {
            if startDate == nil {
                startDate = formatter.date(from: startDateString)
            }
            if endDate == nil {
                endDate = formatter.date(from: endDateString)
            }
            if startDate != nil && endDate != nil {
                break
            }
        }
        
        guard let start = startDate, let end = endDate else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode dates from: \(startDateString), \(endDateString)"
                )
            )
        }
        
        self.startDate = start
        self.endDate = end
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        try container.encode(formatter.string(from: startDate), forKey: .startDate)
        try container.encode(formatter.string(from: endDate), forKey: .endDate)
    }
    
    enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
    }
}

// MARK: - API Request/Response Models

struct ManagementCalendarRequest: Codable {
    let startDate: Date
    let endDate: Date
    let eventTypes: [CalendarEventType]?
    let includeConflicts: Bool
    let includeMetadata: Bool
    let workerIds: [Int]?
    let projectIds: [Int]?
    
    init(startDate: Date, endDate: Date, eventTypes: [CalendarEventType]? = nil, 
         includeConflicts: Bool = true, includeMetadata: Bool = true,
         workerIds: [Int]? = nil, projectIds: [Int]? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.eventTypes = eventTypes
        self.includeConflicts = includeConflicts
        self.includeMetadata = includeMetadata
        self.workerIds = workerIds
        self.projectIds = projectIds
    }
}

struct ManagementCalendarResponse: Codable {
    let events: [ManagementCalendarEvent]
    let workerAvailability: WorkerAvailabilityMatrix?
    let summary: CalendarSummary
    let conflicts: [ConflictInfo]
    let lastUpdated: Date
    let cacheHitRate: Double?
}

struct CalendarSummary: Codable {
    let totalEvents: Int
    let eventsByType: [String: Int]
    let eventsByPriority: [String: Int]
    let conflictCount: Int
    let capacityUtilization: Double
    let upcomingDeadlines: Int
    let workersOnLeave: Int
    let availableWorkers: Int
}

// MARK: - Extensions

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}