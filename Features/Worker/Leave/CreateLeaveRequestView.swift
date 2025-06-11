//
//  CreateLeaveRequestView.swift
//  KSR Cranes App
//
//  Create Leave Request Interface for Workers
//  Handles form validation and submission following Danish employment rules
//

import SwiftUI

struct CreateLeaveRequestView: View {
    @StateObject private var viewModel = CreateLeaveRequestViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Leave Balance Display
                    if viewModel.selectedLeaveType == .vacation || viewModel.selectedLeaveType == .personal {
                        LeaveBalanceInfoView(viewModel: viewModel)
                    }
                    
                    // Leave Type Selection
                    LeaveTypeSelectionView(selectedType: $viewModel.selectedLeaveType)
                    
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
                    
                    // Emergency Leave Toggle
                    if viewModel.selectedLeaveType == .sick {
                        EmergencyLeaveToggleView(isEmergency: $viewModel.isEmergencyLeave)
                    }
                    
                    // Validation Errors
                    if !viewModel.validationErrors.isEmpty {
                        ValidationErrorsView(errors: viewModel.validationErrors)
                    }
                    
                    // Quick Actions
                    QuickActionsView(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("New Leave Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitRequest()
                    }
                    .disabled(!viewModel.isValidRequest || viewModel.isLoading)
                }
            }
            .alert("Request Submitted Successfully", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK") {
                    onComplete(true)
                    dismiss()
                }
            } message: {
                VStack(alignment: .leading, spacing: 4) {
                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .fontWeight(.medium)
                    } else {
                        Text("Your leave request has been submitted for approval.")
                    }
                    
                    if let details = viewModel.submitSuccessDetails {
                        Text(details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Submitting...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func submitRequest() {
        viewModel.submitRequest { success in
            if !success {
                onComplete(false)
            }
            // Success case is handled by the alert
        }
    }
}

// MARK: - Leave Type Selection

struct LeaveTypeSelectionView: View {
    @Binding var selectedType: LeaveType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leave Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(LeaveType.allCases, id: \.self) { type in
                    LeaveTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LeaveTypeCard: View {
    let type: LeaveType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForType)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .blue)
            
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue : Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
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

// MARK: - Date Range Selection

struct DateRangeSelectionView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isHalfDay: Bool
    let leaveType: LeaveType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dates")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }
                
                VStack(alignment: .leading) {
                    Text("To")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            
            if leaveType.canBeHalfDay {
                Toggle("Half Day", isOn: $isHalfDay)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onChange(of: startDate) { _, newValue in
            if endDate < newValue {
                endDate = newValue
            }
        }
    }
}

// MARK: - Work Days Display

struct WorkDaysDisplayView: View {
    let workDays: Int
    let isHalfDay: Bool
    let dateRange: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Work Days")
                    .font(.headline)
                Spacer()
                Text(isHalfDay ? "0.5" : "\(workDays)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(dateRange)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Reason Input

struct ReasonInputView: View {
    @Binding var reason: String
    let leaveType: LeaveType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reason")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if leaveType == .sick || leaveType == .emergency {
                    Text("(required)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("(optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            TextEditor(text: $reason)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Emergency Leave Toggle

struct EmergencyLeaveToggleView: View {
    @Binding var isEmergency: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Emergency Sick Leave", isOn: $isEmergency)
                .font(.subheadline)
            
            Text("Mark as emergency if you cannot give 24 hours notice")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Validation Errors

struct ValidationErrorsView: View {
    let errors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Validation Errors")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            ForEach(Array(errors.enumerated()), id: \.offset) { index, error in
                Text("• \(error)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    @ObservedObject var viewModel: CreateLeaveRequestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                LeaveQuickActionButton(
                    title: "1 Week Vacation",
                    subtitle: "5 work days",
                    icon: "sun.max"
                ) {
                    viewModel.setQuickVacation(days: 5)
                }
                
                LeaveQuickActionButton(
                    title: "2 Week Vacation",
                    subtitle: "10 work days",
                    icon: "sun.max.fill"
                ) {
                    viewModel.setQuickVacation(days: 10)
                }
                
                LeaveQuickActionButton(
                    title: "Personal Day",
                    subtitle: "Tomorrow",
                    icon: "person"
                ) {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    viewModel.setDateRange(start: tomorrow, end: tomorrow)
                    viewModel.selectedLeaveType = .personal
                }
                
                LeaveQuickActionButton(
                    title: "Sick Day",
                    subtitle: "Today",
                    icon: "cross.case"
                ) {
                    let today = Date()
                    viewModel.setDateRange(start: today, end: today)
                    viewModel.selectedLeaveType = .sick
                    viewModel.isEmergencyLeave = true
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LeaveQuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Leave Balance Info

struct LeaveBalanceInfoView: View {
    @ObservedObject var viewModel: CreateLeaveRequestViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Vacation Days
            if viewModel.selectedLeaveType == .vacation {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text("Vacation Days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(viewModel.availableVacationDays)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Personal Days
            if viewModel.selectedLeaveType == .personal {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("Personal Days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(viewModel.availablePersonalDays)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

#if DEBUG
struct CreateLeaveRequestView_Previews: PreviewProvider {
    static var previews: some View {
        CreateLeaveRequestView { _ in }
    }
}
#endif