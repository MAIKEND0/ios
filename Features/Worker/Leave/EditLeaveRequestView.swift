//
//  EditLeaveRequestView.swift
//  KSR Cranes App
//
//  Edit existing leave requests for Workers
//  Allows editing pending and rejected requests
//

import SwiftUI
import Combine

struct EditLeaveRequestView: View {
    let request: LeaveRequest
    let onComplete: (Bool) -> Void
    
    @StateObject private var viewModel: EditLeaveRequestViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(request: LeaveRequest, onComplete: @escaping (Bool) -> Void) {
        self.request = request
        self.onComplete = onComplete
        self._viewModel = StateObject(wrappedValue: EditLeaveRequestViewModel(request: request))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Edit status message
                    if request.status == .rejected {
                        RejectedStatusCard(reason: request.rejection_reason)
                    } else {
                        PendingStatusCard()
                    }
                    
                    // Leave Type (readonly for approved requests)
                    LeaveTypeDisplayView(type: viewModel.selectedLeaveType)
                    
                    // Date Selection
                    DateRangeSelectionView(
                        startDate: $viewModel.startDate,
                        endDate: $viewModel.endDate,
                        isHalfDay: $viewModel.isHalfDay,
                        leaveType: viewModel.selectedLeaveType
                    )
                    
                    // Work Days Calculation
                    if let workDays = viewModel.workDaysCount {
                        WorkDaysDisplayView(
                            workDays: workDays,
                            isHalfDay: viewModel.isHalfDay,
                            dateRange: viewModel.formattedDateRange
                        )
                    }
                    
                    // Reason Input
                    ReasonInputView(
                        reason: $viewModel.reason,
                        leaveType: viewModel.selectedLeaveType
                    )
                    
                    // Validation Errors
                    if !viewModel.validationErrors.isEmpty {
                        ValidationErrorsView(errors: viewModel.validationErrors)
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Leave Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(!viewModel.isValidRequest || viewModel.isLoading)
                }
            }
            .alert("Changes Saved", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK") {
                    onComplete(true)
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "Your leave request has been updated.")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Saving changes...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func saveChanges() {
        viewModel.saveChanges { success in
            if !success {
                onComplete(false)
            }
            // Success case is handled by the alert
        }
    }
}

// MARK: - Status Cards

struct RejectedStatusCard: View {
    let reason: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Request Rejected")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            if let reason = reason, !reason.isEmpty {
                Text("Reason: \(reason)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Make your changes and resubmit for approval.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PendingStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Editing Pending Request")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text("Changes will require new approval from your manager.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Leave Type Display (Non-editable)

struct LeaveTypeDisplayView: View {
    let type: LeaveType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leave Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: iconForType)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("(Cannot change)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var iconForType: String {
        switch type {
        case .vacation: return "sun.max"
        case .sick: return "cross.case"
        case .personal: return "person"
        case .parental: return "figure.and.child.holdinghands"
        case .compensatory: return "clock.arrow.circlepath"
        case .emergency: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Edit Leave Request ViewModel

@MainActor
class EditLeaveRequestViewModel: ObservableObject {
    @Published var selectedLeaveType: LeaveType
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var isHalfDay: Bool
    @Published var reason: String
    
    @Published var isLoading = false
    @Published var validationErrors: [String] = []
    @Published var workDaysCount: Int?
    @Published var isValidRequest = false
    @Published var showingSuccessAlert = false
    @Published var successMessage: String?
    
    private let originalRequest: LeaveRequest
    private let apiService = WorkerLeaveAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(request: LeaveRequest) {
        self.originalRequest = request
        self.selectedLeaveType = request.type
        self.startDate = request.start_date
        self.endDate = request.end_date
        self.isHalfDay = request.half_day
        self.reason = request.reason ?? ""
        
        setupValidation()
    }
    
    // MARK: - Validation Setup
    
    private func setupValidation() {
        // Validate dates and calculate work days
        Publishers.CombineLatest3(
            $startDate,
            $endDate,
            $isHalfDay
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] start, end, halfDay in
            self?.validateRequest(start: start, end: end, halfDay: halfDay)
        }
        .store(in: &cancellables)
    }
    
    private func validateRequest(start: Date, end: Date, halfDay: Bool) {
        validationErrors.removeAll()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Basic date validation
        if end < start {
            validationErrors.append("End date must be after start date")
            isValidRequest = false
            workDaysCount = nil
            return
        }
        
        // Leave type specific validation (similar to CreateLeaveRequestViewModel)
        switch selectedLeaveType {
        case .sick:
            let maxPastDays = 3
            let maxFutureDays = 3
            let earliestAllowed = calendar.date(byAdding: .day, value: -maxPastDays, to: today) ?? today
            let latestAllowed = calendar.date(byAdding: .day, value: maxFutureDays, to: today) ?? today
            
            if start < earliestAllowed {
                validationErrors.append("Sick leave cannot be reported more than \(maxPastDays) days in the past")
            }
            if start > latestAllowed {
                validationErrors.append("Sick leave cannot be scheduled more than \(maxFutureDays) days in advance")
            }
            
        case .vacation:
            let requiredAdvanceDays = 14
            let minAdvanceDate = calendar.date(byAdding: .day, value: requiredAdvanceDays, to: today) ?? today
            
            if start < minAdvanceDate {
                validationErrors.append("Vacation requests must be submitted at least \(requiredAdvanceDays) days in advance")
            }
            
        case .personal:
            let _ = calendar.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
            if start < Date() {
                validationErrors.append("Personal days require at least 24 hours advance notice")
            }
            
        default:
            if start < today {
                validationErrors.append("\(selectedLeaveType.displayName) cannot be scheduled in the past")
            }
        }
        
        // Calculate work days
        let workDays = calculateWorkDaysLocal(from: start, to: end)
        workDaysCount = halfDay ? max(1, Int(ceil(Double(workDays) / 2))) : workDays
        
        if workDays == 0 {
            validationErrors.append("Selected dates contain no work days (weekends and holidays are excluded)")
        }
        
        // Set validation result
        isValidRequest = validationErrors.isEmpty
        
        if !isValidRequest {
            workDaysCount = nil
        }
    }
    
    private func calculateWorkDaysLocal(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        var workDays = 0
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Count only Monday (2) to Friday (6)
            if weekday >= 2 && weekday <= 6 {
                workDays += 1
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return workDays
    }
    
    // MARK: - Actions
    
    func saveChanges(completion: @escaping (Bool) -> Void) {
        guard isValidRequest else {
            completion(false)
            return
        }
        
        isLoading = true
        
        guard let employeeIdString = AuthService.shared.getEmployeeId(),
              let employeeId = Int(employeeIdString) else {
            validationErrors.append("Unable to identify user")
            completion(false)
            return
        }
        
        let updates = UpdateLeaveRequestRequest(
            employee_id: employeeId,
            id: nil, // Will be set by API service
            start_date: startDate,
            end_date: endDate,
            half_day: isHalfDay,
            reason: reason.isEmpty ? nil : reason
        )
        
        apiService.updateLeaveRequest(id: originalRequest.id, updates: updates)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        self?.validationErrors.append("Update failed: \(error.localizedDescription)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.successMessage = "Your leave request has been updated and is now pending approval."
                    self?.showingSuccessAlert = true
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
}

#if DEBUG
struct EditLeaveRequestView_Previews: PreviewProvider {
    static var previews: some View {
        Text("EditLeaveRequestView Preview")
            .previewDisplayName("Edit Leave Request")
    }
}
#endif