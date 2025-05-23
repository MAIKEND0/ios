//
//  WorkPlanAPIService.swift
//  KSR Cranes App
//
//  Updated with delete functionality on 23/05/2025.
//

import Foundation
import Combine
import SwiftUI

final class WorkPlanAPIService: BaseAPIService {
    static let shared = WorkPlanAPIService()

    private override init() {
        super.init()
    }

    func createWorkPlan(plan: WorkPlanRequest) -> AnyPublisher<WorkPlanResponse, APIError> {
        let endpoint = "/api/app/work-plans"
        return makeRequest(endpoint: endpoint, method: "POST", body: plan)
            .decode(type: WorkPlanResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func updateWorkPlan(workPlanId: Int, plan: WorkPlanRequest) -> AnyPublisher<WorkPlanResponse, APIError> {
        let endpoint = "/api/app/work-plans?id=\(workPlanId)"
        return makeRequest(endpoint: endpoint, method: "PUT", body: plan)
            .decode(type: WorkPlanResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func deleteWorkPlan(workPlanId: Int) -> AnyPublisher<DeleteWorkPlanResponse, APIError> {
        let endpoint = "/api/app/work-plans?id=\(workPlanId)"
        return makeRequest(endpoint: endpoint, method: "DELETE", body: Optional<String>.none)
            .decode(type: DeleteWorkPlanResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }

    func fetchWorkPlans(supervisorId: Int, weekNumber: Int?, year: Int?) -> AnyPublisher<[WorkPlan], APIError> {
        var endpoint = "/api/app/work-plans?supervisorId=\(supervisorId)"
        if let week = weekNumber, let year = year {
            endpoint += "&weekNumber=\(week)&year=\(year)"
        }
        endpoint += "&cacheBust=\(Int(Date().timeIntervalSince1970))"
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: [WorkPlan].self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Types
extension WorkPlanAPIService {
    struct DeleteWorkPlanResponse: Codable {
        let success: Bool
        let message: String
    }
    
    // Rest of the existing types remain the same...
    struct WorkPlan: Codable, Identifiable {
        let id: Int
        let work_plan_id: Int
        let task_id: Int
        let task_title: String
        let weekNumber: Int
        let year: Int
        let status: String
        let creator_name: String?
        let description: String?
        let additional_info: String?
        let attachment_url: String?
        let assignments: [WorkPlanAssignment]
        
        enum CodingKeys: String, CodingKey {
            case work_plan_id, task_id, task_title, weekNumber, year, status, creator_name, description, additional_info, attachment_url, assignments
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            work_plan_id = try container.decode(Int.self, forKey: .work_plan_id)
            id = work_plan_id
            task_id = try container.decode(Int.self, forKey: .task_id)
            task_title = try container.decode(String.self, forKey: .task_title)
            weekNumber = try container.decode(Int.self, forKey: .weekNumber)
            year = try container.decode(Int.self, forKey: .year)
            status = try container.decode(String.self, forKey: .status)
            creator_name = try container.decodeIfPresent(String.self, forKey: .creator_name)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            additional_info = try container.decodeIfPresent(String.self, forKey: .additional_info)
            attachment_url = try container.decodeIfPresent(String.self, forKey: .attachment_url)
            assignments = try container.decodeIfPresent([WorkPlanAssignment].self, forKey: .assignments) ?? []
        }
        
        init(
            id: Int,
            work_plan_id: Int,
            task_id: Int,
            task_title: String,
            weekNumber: Int,
            year: Int,
            status: String,
            creator_name: String?,
            description: String?,
            additional_info: String?,
            attachment_url: String?,
            assignments: [WorkPlanAssignment]
        ) {
            self.id = id
            self.work_plan_id = work_plan_id
            self.task_id = task_id
            self.task_title = task_title
            self.weekNumber = weekNumber
            self.year = year
            self.status = status
            self.creator_name = creator_name
            self.description = description
            self.additional_info = additional_info
            self.attachment_url = attachment_url
            self.assignments = assignments
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(work_plan_id, forKey: .work_plan_id)
            try container.encode(task_id, forKey: .task_id)
            try container.encode(task_title, forKey: .task_title)
            try container.encode(weekNumber, forKey: .weekNumber)
            try container.encode(year, forKey: .year)
            try container.encode(status, forKey: .status)
            try container.encodeIfPresent(creator_name, forKey: .creator_name)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(additional_info, forKey: .additional_info)
            try container.encodeIfPresent(attachment_url, forKey: .attachment_url)
            try container.encode(assignments, forKey: .assignments)
        }
    }

    struct WorkPlanAssignment: Codable, Identifiable {
        let id: Int
        let assignment_id: Int
        let employee_id: Int
        let work_date: Date
        let start_time: String?
        let end_time: String?
        let notes: String?
        
        enum CodingKeys: String, CodingKey {
            case assignment_id, employee_id, work_date, start_time, end_time, notes
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            assignment_id = try container.decode(Int.self, forKey: .assignment_id)
            id = assignment_id
            employee_id = try container.decode(Int.self, forKey: .employee_id)
            
            // Dekodowanie work_date
            let dateString = try container.decode(String.self, forKey: .work_date)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            
            if let date = isoFormatter.date(from: dateString) {
                work_date = date
            } else if let date = simpleFormatter.date(from: dateString) {
                work_date = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .work_date,
                    in: container,
                    debugDescription: "Nie można rozkodować daty: \(dateString)"
                )
            }
            
            // Simplified time parsing - API now returns VARCHAR(5) "HH:mm" format
            start_time = try container.decodeIfPresent(String.self, forKey: .start_time)
            end_time = try container.decodeIfPresent(String.self, forKey: .end_time)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            
            #if DEBUG
            print("[WorkPlanAssignment] Assignment \(assignment_id): start_time='\(start_time ?? "nil")', end_time='\(end_time ?? "nil")'")
            #endif
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(assignment_id, forKey: .assignment_id)
            try container.encode(employee_id, forKey: .employee_id)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            try container.encode(formatter.string(from: work_date), forKey: .work_date)
            
            try container.encodeIfPresent(start_time, forKey: .start_time)
            try container.encodeIfPresent(end_time, forKey: .end_time)
            try container.encodeIfPresent(notes, forKey: .notes)
        }
    }

    struct WorkPlanRequest: Codable {
        let task_id: Int
        let weekNumber: Int
        let year: Int
        let status: String
        let description: String?
        let additional_info: String?
        let attachment: Attachment?
        let assignments: [WorkPlanAssignmentRequest]
    }

    struct WorkPlanAssignmentRequest: Codable {
        let employee_id: Int
        let work_date: Date
        let start_time: String?
        let end_time: String?
        let notes: String?
    }

    struct Attachment: Codable {
        let fileName: String
        let fileData: String // base64
    }

    struct WorkPlanResponse: Codable {
        let work_plan_id: Int
        let message: String
        let attachment_url: String?
    }
}

extension WorkPlanAPIService.WorkPlanRequest {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(task_id, forKey: .task_id)
        try container.encode(weekNumber, forKey: .weekNumber)
        try container.encode(year, forKey: .year)
        try container.encode(status, forKey: .status)
        
        if let desc = description, !desc.isEmpty {
            try container.encode(desc, forKey: .description)
        }
        
        if let info = additional_info, !info.isEmpty {
            try container.encode(info, forKey: .additional_info)
        }
        
        try container.encodeIfPresent(attachment, forKey: .attachment)
        try container.encode(assignments, forKey: .assignments)
    }
    
    private enum CodingKeys: String, CodingKey {
        case task_id, weekNumber, year, status, description, additional_info, attachment, assignments
    }
}

extension WorkPlanAPIService.WorkPlanAssignmentRequest {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(employee_id, forKey: .employee_id)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: work_date)
        try container.encode(dateString, forKey: .work_date)
        
        try container.encodeIfPresent(start_time, forKey: .start_time)
        try container.encodeIfPresent(end_time, forKey: .end_time)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
    
    private enum CodingKeys: String, CodingKey {
        case employee_id, work_date, start_time, end_time, notes
    }
}
