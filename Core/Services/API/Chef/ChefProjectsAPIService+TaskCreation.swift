//
//  ChefProjectsAPIService+TaskCreation.swift
//  KSR Cranes App
//
//  Extension for easier task creation with worker assignment - CLEAN
//

import Foundation
import Combine

// MARK: - Enhanced Task Creation Methods

extension ChefProjectsAPIService {
    
    /// Combined method to create task and assign workers in one operation
    /// This is a convenience method that handles the common workflow
    func createTaskWithWorkers(
        projectId: Int,
        task: CreateTaskRequest,
        workerAssignments: [CreateTaskAssignmentRequest]
    ) -> AnyPublisher<TaskCreationResult, APIError> {
        
        #if DEBUG
        print("[ChefProjectsAPIService] Creating task with \(workerAssignments.count) workers: \(task.title)")
        #endif
        
        return createTask(projectId: projectId, task: task)
            .flatMap { [weak self] createdTask -> AnyPublisher<TaskCreationResult, APIError> in
                guard let self = self else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                // If no workers to assign, return successful result with task only
                guard !workerAssignments.isEmpty else {
                    let result = TaskCreationResult(
                        task: createdTask,
                        assignments: [],
                        assignmentErrors: []
                    )
                    return Just(result)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                }
                
                // Assign workers to the created task
                return self.assignWorkersToTask(taskId: createdTask.id, assignments: workerAssignments)
                    .map { assignments in
                        TaskCreationResult(
                            task: createdTask,
                            assignments: assignments,
                            assignmentErrors: []
                        )
                    }
                    .catch { assignmentError -> AnyPublisher<TaskCreationResult, APIError> in
                        // Task was created but worker assignment failed
                        // Return partial success with error info
                        let result = TaskCreationResult(
                            task: createdTask,
                            assignments: [],
                            assignmentErrors: [assignmentError.localizedDescription]
                        )
                        return Just(result)
                            .setFailureType(to: APIError.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Get available workers for project (without task exclusion)
    /// ✅ FIXED: Use proper project endpoint instead of invalid task endpoint
    func fetchAvailableWorkersForProject(
        projectId: Int,
        date: Date? = nil,
        requiredCraneTypes: [Int]? = nil,
        includeAvailability: Bool = true
    ) -> AnyPublisher<AvailableWorkersResponse, APIError> {
        
        #if DEBUG
        print("[ChefProjectsAPIService] Fetching workers for project \(projectId)")
        #endif
        
        // ✅ FIXED: Use proper project endpoint
        var endpoint = "/api/app/chef/projects/\(projectId)/available-workers"
        var queryParams: [String] = []
        
        if let date = date {
            queryParams.append("date=\(DateFormatter.isoDate.string(from: date))")
        }
        
        if let craneTypes = requiredCraneTypes, !craneTypes.isEmpty {
            queryParams.append("crane_types=\(craneTypes.map(String.init).joined(separator: ","))")
        }
        
        if includeAvailability {
            queryParams.append("include_availability=true")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        #if DEBUG
        print("[ChefProjectsAPIService] API endpoint: \(endpoint)")
        #endif
        
        return makeRequest(endpoint: endpoint, method: "GET", body: Optional<String>.none)
            .decode(type: AvailableWorkersResponse.self, decoder: jsonDecoder())
            .mapError { ($0 as? APIError) ?? .decodingError($0) }
            .eraseToAnyPublisher()
    }
    
    /// Bulk assign multiple workers with better error handling
    func bulkAssignWorkersToTask(
        taskId: Int,
        workers: [AvailableWorker],
        defaultCraneModel: CraneModel? = nil
    ) -> AnyPublisher<BulkAssignmentResult, APIError> {
        
        let assignments = workers.map { worker in
            CreateTaskAssignmentRequest(
                employeeId: worker.employee.employeeId,
                craneModelId: worker.craneTypes.first?.id ?? defaultCraneModel?.id,
                skipCertificateValidation: nil,
                skipCraneTypeValidation: nil,
                workDate: nil,
                status: nil,
                notes: nil
            )
        }
        
        return assignWorkersToTask(taskId: taskId, assignments: assignments)
            .map { taskAssignments in
                BulkAssignmentResult(
                    successful: taskAssignments,
                    failed: [],
                    totalRequested: workers.count
                )
            }
            .catch { error -> AnyPublisher<BulkAssignmentResult, APIError> in
                // In a real implementation, we might want to try individual assignments
                // to see which ones succeed and which fail
                let result = BulkAssignmentResult(
                    successful: [],
                    failed: workers.map { FailedAssignment(worker: $0, error: error.localizedDescription) },
                    totalRequested: workers.count
                )
                return Just(result)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Validate worker assignments before creating task
    func validateWorkerAssignments(
        workers: [AvailableWorker],
        requiredCraneTypes: [Int]? = nil,
        requiredCertificates: [Int]? = nil,
        taskDate: Date? = nil
    ) -> WorkerAssignmentValidation {
        
        var validation = WorkerAssignmentValidation()
        
        for worker in workers {
            // Check availability
            if !worker.availability.isAvailable {
                validation.unavailableWorkers.append(worker)
                continue
            }
            
            var hasMissingSkills = false
            
            // Check required crane types
            if let required = requiredCraneTypes, !required.isEmpty {
                let hasAllCraneTypes = required.allSatisfy { requiredType in
                    worker.craneTypes.contains { $0.id == requiredType }
                }
                
                if !hasAllCraneTypes {
                    hasMissingSkills = true
                }
            }
            
            // Check required certificates
            if let requiredCerts = requiredCertificates, !requiredCerts.isEmpty {
                // Check if worker has certificates data
                if let workerCertificates = worker.certificates {
                    let hasAllCertificates = requiredCerts.allSatisfy { requiredCertId in
                        workerCertificates.contains { cert in
                            cert.certificateTypeId == requiredCertId && 
                            cert.isCertified &&
                            (cert.certificationExpires == nil || cert.certificationExpires! > Date())
                        }
                    }
                    
                    if !hasAllCertificates {
                        hasMissingSkills = true
                    }
                } else {
                    // No certificates data available, worker is missing skills
                    hasMissingSkills = true
                }
            }
            
            // Classify worker
            if hasMissingSkills {
                validation.workersWithMissingSkills.append(worker)
            } else {
                validation.validWorkers.append(worker)
            }
            
            // Check for potential conflicts
            if let conflicts = worker.availability.conflictingTasks, !conflicts.isEmpty {
                validation.workersWithConflicts.append(worker)
            }
        }
        
        return validation
    }
}

// MARK: - Supporting Models

struct TaskCreationResult {
    let task: ProjectTask
    let assignments: [TaskAssignment]
    let assignmentErrors: [String]
    
    var isFullySuccessful: Bool {
        return assignmentErrors.isEmpty
    }
    
    var hasPartialFailure: Bool {
        return !assignmentErrors.isEmpty && !assignments.isEmpty
    }
    
    var successMessage: String {
        if isFullySuccessful {
            if assignments.isEmpty {
                return "Task '\(task.title)' created successfully."
            } else {
                return "Task '\(task.title)' created with \(assignments.count) workers assigned."
            }
        } else if hasPartialFailure {
            return "Task '\(task.title)' created but some worker assignments failed."
        } else {
            return "Task '\(task.title)' created but no workers could be assigned."
        }
    }
}

struct BulkAssignmentResult {
    let successful: [TaskAssignment]
    let failed: [FailedAssignment]
    let totalRequested: Int
    
    var successRate: Double {
        guard totalRequested > 0 else { return 0.0 }
        return Double(successful.count) / Double(totalRequested)
    }
    
    var isFullySuccessful: Bool {
        return failed.isEmpty && successful.count == totalRequested
    }
}

struct FailedAssignment {
    let worker: AvailableWorker
    let error: String
}

struct WorkerAssignmentValidation {
    var validWorkers: [AvailableWorker] = []
    var unavailableWorkers: [AvailableWorker] = []
    var workersWithMissingSkills: [AvailableWorker] = []
    var workersWithConflicts: [AvailableWorker] = []
    
    var hasIssues: Bool {
        return !unavailableWorkers.isEmpty ||
               !workersWithMissingSkills.isEmpty ||
               !workersWithConflicts.isEmpty
    }
    
    var canProceed: Bool {
        return !validWorkers.isEmpty
    }
    
    var issuesSummary: String {
        var issues: [String] = []
        
        if !unavailableWorkers.isEmpty {
            issues.append("\(unavailableWorkers.count) unavailable")
        }
        
        if !workersWithMissingSkills.isEmpty {
            issues.append("\(workersWithMissingSkills.count) missing required skills")
        }
        
        if !workersWithConflicts.isEmpty {
            issues.append("\(workersWithConflicts.count) have schedule conflicts")
        }
        
        return issues.joined(separator: ", ")
    }
}

// ✅ REMOVED: Extension CreateTaskViewModel - methods moved to main class file
