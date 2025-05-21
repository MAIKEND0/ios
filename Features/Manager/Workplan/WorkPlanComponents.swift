import SwiftUI

protocol WeekSelectorViewModel: ObservableObject {
    var weekRangeText: String { get }
    func changeWeek(by offset: Int)
}

protocol WorkPlanViewModel: ObservableObject {
    var assignments: [WorkPlanAssignment] { get set }
    var description: String { get set }
    var additionalInfo: String { get set }
    var attachment: WorkPlanAPIService.Attachment? { get }
    var showAlert: Bool { get set }
    var alertTitle: String { get set }
    var alertMessage: String { get set }
    func saveDraft()
    func publish()
    func setAttachment(from url: URL)
    func copyHoursToOtherEmployees(from assignment: WorkPlanAssignment)
}

struct WorkPlanAssignment: Identifiable {
    let id: UUID = UUID()
    let employee_id: Int
    var availableEmployees: [ManagerAPIService.Worker]
    let weekStart: Date
    var dailyHours: [DailyHours]
    var notes: String
    
    mutating func copyHoursToAllDays() {
        guard let firstActiveDay = dailyHours.first(where: { $0.isActive }) else { return }
        let newHours = DailyHours(
            isActive: true,
            start_time: firstActiveDay.start_time,
            end_time: firstActiveDay.end_time
        )
        dailyHours = Array(repeating: newHours, count: dailyHours.count)
    }
}

extension WorkPlanAssignment {
    func toRequestAssignments() -> [WorkPlanAPIService.WorkPlanAssignmentRequest] {
        dailyHours.enumerated().compactMap { index, hours in
            guard hours.isActive, hours.start_time != hours.end_time else { return nil }
            let work_date = Calendar.current.date(byAdding: .day, value: index, to: weekStart)!
            
            // Formatter do daty w formacie ISO-8601
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Formatter do czasu
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            // Pobierz godziny i minuty z start_time i end_time
            let startTimeString = timeFormatter.string(from: hours.start_time)
            let endTimeString = timeFormatter.string(from: hours.end_time)
            
            // Połącz datę i czas w pełny format ISO-8601
            let dateString = dateFormatter.string(from: work_date)
            let isoStartTime = "\(dateString)T\(startTimeString):00.000Z"
            let isoEndTime = "\(dateString)T\(endTimeString):00.000Z"
            
            return WorkPlanAPIService.WorkPlanAssignmentRequest(
                employee_id: employee_id,
                work_date: work_date,
                start_time: isoStartTime,
                end_time: isoEndTime,
                notes: notes.isEmpty ? nil : notes
            )
        }
    }
}

// Reszta pliku pozostaje bez zmian
struct DailyHours: Identifiable, Equatable {
    let id: UUID = UUID()
    var isActive: Bool
    var start_time: Date
    var end_time: Date
    
    static func == (lhs: DailyHours, rhs: DailyHours) -> Bool {
        lhs.isActive == rhs.isActive &&
        lhs.start_time == rhs.start_time &&
        lhs.end_time == rhs.end_time
    }
}

struct WorkPlanWeekSelector<VM: WeekSelectorViewModel>: View {
    @ObservedObject var viewModel: VM
    @Environment(\.colorScheme) private var colorScheme
    
    let weekRangeText: String
    
    init(viewModel: VM, weekRangeText: String) {
        self.viewModel = viewModel
        self.weekRangeText = weekRangeText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Week")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            HStack {
                Button(action: {
                    viewModel.changeWeek(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.ksrYellow)
                }
                Text(weekRangeText)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                Button(action: {
                    viewModel.changeWeek(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.ksrYellow)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 {
                            viewModel.changeWeek(by: -1)
                        } else if value.translation.width < -50 {
                            viewModel.changeWeek(by: 1)
                        }
                    }
            )
        }
    }
}

struct WorkPlanEmployeeSection<VM: WorkPlanViewModel>: View {
    @ObservedObject var viewModel: VM
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign Hours")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if viewModel.assignments.isEmpty {
                Text("No employees selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(viewModel.assignments.enumerated()), id: \.offset) { index, _ in
                    WorkPlanAssignmentRow(
                        assignment: Binding(
                            get: { viewModel.assignments[index] },
                            set: { viewModel.assignments[index] = $0 }
                        ),
                        onCopyToOthers: { assignment in
                            viewModel.copyHoursToOtherEmployees(from: assignment)
                        }
                    )
                }
            }
        }
    }
}

struct WorkPlanAssignmentRow: View {
    @Binding var assignment: WorkPlanAssignment
    let onCopyToOthers: (WorkPlanAssignment) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var validationError: String?

    var body: some View {
        WorkPlanAssignmentContent(
            employeeName: assignment.availableEmployees.first { $0.employee_id == assignment.employee_id }?.name ?? "Unknown",
            notes: $assignment.notes,
            weekStart: assignment.weekStart,
            dailyHours: $assignment.dailyHours,
            copyHoursAction: {
                assignment.copyHoursToAllDays()
            },
            copyToOthersAction: {
                onCopyToOthers(assignment)
            }
        )
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            validationError != nil ?
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red, lineWidth: 2) :
                nil
        )
        .onChange(of: assignment.dailyHours) { _, newValue in
            validateHours(newValue)
        }
    }

    private func validateHours(_ dailyHours: [DailyHours]) {
        for hours in dailyHours where hours.isActive {
            if hours.start_time >= hours.end_time {
                validationError = "End time must be after start time"
                return
            }
        }
        validationError = nil
    }
}

struct WorkPlanAssignmentContent: View {
    let employeeName: String
    @Binding var notes: String
    let weekStart: Date
    @Binding var dailyHours: [DailyHours]
    let copyHoursAction: () -> Void
    let copyToOthersAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Employee: \(employeeName)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Notes")
                .font(.caption)
                .fontWeight(.bold)
            TextField("Enter notes...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 60)
            
            ForEach(dailyHours.indices, id: \.self) { index in
                let date = Calendar.current.date(byAdding: .day, value: index, to: weekStart)!
                WorkPlanDayHoursRow(
                    date: date,
                    hours: $dailyHours[index]
                )
            }
            
            HStack {
                Button(action: copyHoursAction) {
                    Text("Copy to All Days")
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                }
                Button(action: copyToOthersAction) {
                    Text("Copy to Other Employees")
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                }
            }
        }
    }
}

struct WorkPlanDayHoursRow: View {
    let date: Date
    @Binding var hours: DailyHours
    @Environment(\.colorScheme) private var colorScheme
    @State private var localIsActive: Bool
    
    init(date: Date, hours: Binding<DailyHours>) {
        self.date = date
        self._hours = hours
        self._localIsActive = State(initialValue: hours.wrappedValue.isActive)
    }
    
    var body: some View {
        HStack {
            Text(formattedDate(date))
                .font(.caption)
                .foregroundColor(.primary)
                .frame(minWidth: 120, alignment: .leading)
            Spacer()
            Toggle("", isOn: $localIsActive)
                .labelsHidden()
                .onChange(of: localIsActive) { _, newValue in
                    hours.isActive = newValue
                }
            if localIsActive {
                DatePicker("", selection: $hours.start_time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("-")
                DatePicker("", selection: $hours.end_time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct WorkPlanActionButtons<VM: WorkPlanViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Button("Save Draft") {
                viewModel.saveDraft()
                isPresented = false
            }
            .foregroundColor(Color.ksrYellow)
            Button("Publish") {
                viewModel.publish()
                isPresented = false
            }
            .foregroundColor(.green)
        }
    }
}

struct EmployeeCard: View {
    let employee: ManagerAPIService.Worker
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            Text(employee.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.ksrYellow : Color.gray.opacity(0.2), lineWidth: 2)
        )
    }
}
