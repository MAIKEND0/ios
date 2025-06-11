//
//  ChefEditBillingRatesView.swift
//  KSR Cranes App
//
//  Edit/Create billing rates sheet view
//

import SwiftUI
import Combine

struct ChefEditBillingRatesView: View {
    let projectId: Int
    let existingSettings: ChefBillingSettings?
    let onSave: (BillingSettingsRequest) -> Void
    
    @StateObject private var viewModel: EditBillingRatesViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: BillingField?
    
    enum BillingField: Hashable {
        case normalRate, weekendRate
        case overtimeRate1, overtimeRate2
        case weekendOvertimeRate1, weekendOvertimeRate2
    }
    
    init(
        projectId: Int,
        existingSettings: ChefBillingSettings?,
        onSave: @escaping (BillingSettingsRequest) -> Void
    ) {
        self.projectId = projectId
        self.existingSettings = existingSettings
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: EditBillingRatesViewModel(existingSettings: existingSettings))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Effective Period
                    effectivePeriodSection
                    
                    // Standard Rates
                    standardRatesSection
                    
                    // Overtime Rates
                    overtimeRatesSection
                    
                    // Weekend Overtime Rates
                    weekendOvertimeSection
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle(existingSettings == nil ? "Create Billing Rates" : "Edit Billing Rates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBillingSettings()
                    }
                    .foregroundColor(viewModel.isFormValid ? Color.ksrYellow : .secondary)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.ksrYellow)
            
            Text(existingSettings == nil ? "Create New Billing Rates" : "Update Billing Rates")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Set hourly rates for different work types and overtime")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var effectivePeriodSection: some View {
        BillingFormSection(title: "Effective Period", icon: "calendar") {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        DatePicker(
                            "",
                            selection: $viewModel.effectiveFrom,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Toggle("", isOn: $viewModel.hasEndDate)
                                .labelsHidden()
                            
                            if viewModel.hasEndDate {
                                DatePicker(
                                    "",
                                    selection: $viewModel.effectiveTo,
                                    in: viewModel.effectiveFrom...,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(CompactDatePickerStyle())
                            } else {
                                Text("Ongoing")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
                
                if let error = viewModel.dateError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var standardRatesSection: some View {
        BillingFormSection(title: "Standard Rates (DKK/hour)", icon: "clock.fill") {
            VStack(spacing: 16) {
                Text("Base hourly rates for regular and weekend work")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    BillingRateField(
                        title: "Normal Rate",
                        text: $viewModel.normalRate,
                        placeholder: "0.00",
                        focusedField: $focusedField,
                        fieldType: .normalRate,
                        errorMessage: viewModel.normalRateError
                    )
                    
                    BillingRateField(
                        title: "Weekend Rate",
                        text: $viewModel.weekendRate,
                        placeholder: "0.00",
                        focusedField: $focusedField,
                        fieldType: .weekendRate,
                        errorMessage: viewModel.weekendRateError
                    )
                }
            }
        }
    }
    
    private var overtimeRatesSection: some View {
        BillingFormSection(title: "Overtime Rates (DKK/hour)", icon: "clock.badge.plus") {
            VStack(spacing: 16) {
                Text("Hourly rates for overtime work (typically 1.5x and 2x normal rate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    BillingRateField(
                        title: "Overtime 1",
                        text: $viewModel.overtimeRate1,
                        placeholder: "0.00",
                        focusedField: $focusedField,
                        fieldType: .overtimeRate1,
                        errorMessage: viewModel.overtimeRate1Error
                    )
                    
                    BillingRateField(
                        title: "Overtime 2",
                        text: $viewModel.overtimeRate2,
                        placeholder: "0.00",
                        focusedField: $focusedField,
                        fieldType: .overtimeRate2,
                        errorMessage: viewModel.overtimeRate2Error
                    )
                }
            }
        }
    }
    
    private var weekendOvertimeSection: some View {
        BillingFormSection(title: "Weekend Overtime (DKK/hour)", icon: "clock.badge.exclamationmark") {
            VStack(spacing: 16) {
                Text("Premium rates for overtime work during weekends and holidays")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    BillingRateField(
                        title: "Weekend OT 1",
                        text: $viewModel.weekendOvertimeRate1,
                        placeholder: "0.00",
                        focusedField: $focusedField,
                        fieldType: .weekendOvertimeRate1,
                        errorMessage: viewModel.weekendOvertimeRate1Error
                    )
                    
                    BillingRateField(
                        title: "Weekend OT 2",
                        text: $viewModel.weekendOvertimeRate2,
                        placeholder: "0.00",
                        focusedField: $focusedField,
                        fieldType: .weekendOvertimeRate2,
                        errorMessage: viewModel.weekendOvertimeRate2Error
                    )
                }
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button {
                saveBillingSettings()
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(viewModel.isLoading ? "Saving..." : "Save Billing Rates")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            viewModel.isFormValid && !viewModel.isLoading
                                ? Color.ksrYellow
                                : Color.gray
                        )
                )
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.top, 8)
    }
    
    private func saveBillingSettings() {
        focusedField = nil
        
        let request = viewModel.createBillingSettingsRequest()
        onSave(request)
        dismiss()
    }
}

// MARK: - EditBillingRatesViewModel

class EditBillingRatesViewModel: ObservableObject {
    // Date fields
    @Published var effectiveFrom = Date()
    @Published var effectiveTo = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year default
    @Published var hasEndDate = false
    
    // Rate fields
    @Published var normalRate = ""
    @Published var weekendRate = ""
    @Published var overtimeRate1 = ""
    @Published var overtimeRate2 = ""
    @Published var weekendOvertimeRate1 = ""
    @Published var weekendOvertimeRate2 = ""
    
    // State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Validation Errors
    @Published var dateError: String?
    @Published var normalRateError: String?
    @Published var weekendRateError: String?
    @Published var overtimeRate1Error: String?
    @Published var overtimeRate2Error: String?
    @Published var weekendOvertimeRate1Error: String?
    @Published var weekendOvertimeRate2Error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        return dateError == nil &&
               normalRateError == nil &&
               weekendRateError == nil &&
               overtimeRate1Error == nil &&
               overtimeRate2Error == nil &&
               weekendOvertimeRate1Error == nil &&
               weekendOvertimeRate2Error == nil &&
               hasAtLeastOneRate()
    }
    
    init(existingSettings: ChefBillingSettings?) {
        if let settings = existingSettings {
            populateFromExistingSettings(settings)
        }
        setupValidation()
    }
    
    private func populateFromExistingSettings(_ settings: ChefBillingSettings) {
        effectiveFrom = settings.effectiveFrom
        if let effectiveTo = settings.effectiveTo {
            self.effectiveTo = effectiveTo
            hasEndDate = true
        } else {
            hasEndDate = false
        }
        
        normalRate = formatDecimal(settings.normalRate)
        weekendRate = formatDecimal(settings.weekendRate)
        overtimeRate1 = formatDecimal(settings.overtimeRate1)
        overtimeRate2 = formatDecimal(settings.overtimeRate2)
        weekendOvertimeRate1 = formatDecimal(settings.weekendOvertimeRate1)
        weekendOvertimeRate2 = formatDecimal(settings.weekendOvertimeRate2)
    }
    
    private func formatDecimal(_ decimal: Decimal) -> String {
        if decimal == 0 {
            return ""
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: decimal as NSDecimalNumber) ?? ""
    }
    
    private func setupValidation() {
        // Date validation
        Publishers.CombineLatest3($effectiveFrom, $effectiveTo, $hasEndDate)
            .sink { [weak self] start, end, hasEnd in
                self?.validateDates(start: start, end: end, hasEnd: hasEnd)
            }
            .store(in: &cancellables)
        
        // Rate validations
        $normalRate.sink { [weak self] value in
            self?.validateRate(value, error: \.normalRateError, fieldName: "Normal rate")
        }.store(in: &cancellables)
        
        $weekendRate.sink { [weak self] value in
            self?.validateRate(value, error: \.weekendRateError, fieldName: "Weekend rate")
        }.store(in: &cancellables)
        
        $overtimeRate1.sink { [weak self] value in
            self?.validateRate(value, error: \.overtimeRate1Error, fieldName: "Overtime 1 rate")
        }.store(in: &cancellables)
        
        $overtimeRate2.sink { [weak self] value in
            self?.validateRate(value, error: \.overtimeRate2Error, fieldName: "Overtime 2 rate")
        }.store(in: &cancellables)
        
        $weekendOvertimeRate1.sink { [weak self] value in
            self?.validateRate(value, error: \.weekendOvertimeRate1Error, fieldName: "Weekend OT 1 rate")
        }.store(in: &cancellables)
        
        $weekendOvertimeRate2.sink { [weak self] value in
            self?.validateRate(value, error: \.weekendOvertimeRate2Error, fieldName: "Weekend OT 2 rate")
        }.store(in: &cancellables)
    }
    
    private func validateDates(start: Date, end: Date, hasEnd: Bool) {
        if hasEnd && start >= end {
            dateError = "End date must be after start date"
        } else {
            dateError = nil
        }
    }
    
    private func validateRate(_ value: String, error: ReferenceWritableKeyPath<EditBillingRatesViewModel, String?>, fieldName: String) {
        if !value.isEmpty {
            if Decimal(string: value) == nil {
                self[keyPath: error] = "\(fieldName) must be a valid number"
            } else if let decimal = Decimal(string: value), decimal < 0 {
                self[keyPath: error] = "\(fieldName) cannot be negative"
            } else {
                self[keyPath: error] = nil
            }
        } else {
            self[keyPath: error] = nil
        }
    }
    
    private func hasAtLeastOneRate() -> Bool {
        return !normalRate.isEmpty || !weekendRate.isEmpty ||
               !overtimeRate1.isEmpty || !overtimeRate2.isEmpty ||
               !weekendOvertimeRate1.isEmpty || !weekendOvertimeRate2.isEmpty
    }
    
    func createBillingSettingsRequest() -> BillingSettingsRequest {
        return BillingSettingsRequest(
            normalRate: Decimal(string: normalRate) ?? 0,
            weekendRate: Decimal(string: weekendRate) ?? 0,
            overtimeRate1: Decimal(string: overtimeRate1) ?? 0,
            overtimeRate2: Decimal(string: overtimeRate2) ?? 0,
            weekendOvertimeRate1: Decimal(string: weekendOvertimeRate1) ?? 0,
            weekendOvertimeRate2: Decimal(string: weekendOvertimeRate2) ?? 0,
            effectiveFrom: effectiveFrom,
            effectiveTo: hasEndDate ? effectiveTo : nil
        )
    }
}

// MARK: - Supporting Components

struct BillingFormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ksrYellow)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct BillingRateField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @FocusState.Binding var focusedField: ChefEditBillingRatesView.BillingField?
    let fieldType: ChefEditBillingRatesView.BillingField
    let errorMessage: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isFocused: Bool {
        focusedField == fieldType
    }
    
    private var hasError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if hasError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }
            
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    hasError ? Color.red :
                                    isFocused ? Color.ksrYellow :
                                    Color.clear,
                                    lineWidth: hasError || isFocused ? 2 : 0
                                )
                        )
                )
                .focused($focusedField, equals: fieldType)
            
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}
