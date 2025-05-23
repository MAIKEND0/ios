//
//  ManagerWorkPlansView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 20/05/2025.
//  Updated with enhanced UI/UX and debug logging on 21/05/2025.
//  Updated week selector and fixed errors on 22/05/2025.
//  Improved WorkPlanCard design and fixed year/employees display on 22/05/2025.
//  Fixed work_date formatting in Assignments on 22/05/2025.
//  Optimized work_date formatting using DateFormatter.isoDate on 22/05/2025.
//  Simplified WorkPlanCard by removing formatWorkDate on 22/05/2025.
//  Changed work_date to display day of week on 22/05/2025.
//  Added debug logging for work_date in Assignments on 22/05/2025.
//  Added fallback for invalid work_date on 22/05/2025.
//  Cleared cache onAppear to refresh data on 22/05/2025.
//  Fixed clearCache call in onAppear on 22/05/2025.
//  Fixed day sorting to start from Monday on 22/05/2025.
//  Added Edit button for all work plan statuses on 22/05/2025.
//  Fixed state management for selectedWorkPlan on 22/05/2025.
//

import SwiftUI

struct ManagerWorkPlansView: View {
    @StateObject private var viewModel = ManagerWorkPlansViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEditWorkPlan: Bool = false
    @State private var showPreviewWorkPlan: Bool = false
    @State private var selectedWorkPlan: WorkPlanAPIService.WorkPlan?
    @State private var searchQuery = ""
    @State private var selectedStatus: String = "All"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Search and Filter
                    searchFilterSection
                        .padding(.horizontal)

                    // Week Selector
                    WorkPlanWeekSelector(viewModel: viewModel, isWeekInFuture: viewModel.isWeekInFuture())
                        .padding(.horizontal)

                    // Work Plans
                    WorkPlansSection(
                        viewModel: viewModel,
                        showEditWorkPlan: $showEditWorkPlan,
                        showPreviewWorkPlan: $showPreviewWorkPlan,
                        selectedWorkPlan: $selectedWorkPlan
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Work Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.forceRefresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                // Jawne wywołanie metod w bloku onAppear
                DispatchQueue.main.async {
                    self.viewModel.clearCache() // Czyszczenie cache przy pojawieniu się widoku
                    self.viewModel.loadData()
                }
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.forceRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showEditWorkPlan) {
                // Debug przed sprawdzeniem selectedWorkPlan
                let _ = print("[ManagerWorkPlansView] Opening edit sheet, selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
                
                if let workPlan = selectedWorkPlan {
                    EditWorkPlanView(workPlan: workPlan, isPresented: $showEditWorkPlan)
                        .onAppear {
                            print("[ManagerWorkPlansView] EditWorkPlanView appeared for: \(workPlan.task_title)")
                        }
                } else {
                    VStack {
                        Text("Error: No work plan selected for editing")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("selectedWorkPlan is nil")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("Close") {
                            showEditWorkPlan = false
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showPreviewWorkPlan) {
                // Debug przed sprawdzeniem selectedWorkPlan
                let _ = print("[ManagerWorkPlansView] Opening preview sheet, selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
                
                if let workPlan = selectedWorkPlan {
                    let previewViewModel = EditWorkPlanViewModel()
                    WorkPlanPreviewView(
                        viewModel: previewViewModel,
                        isPresented: $showPreviewWorkPlan,
                        onConfirm: {}
                    )
                    .onAppear {
                        print("[ManagerWorkPlansView] Initializing preview for work plan: \(workPlan.task_title), status: \(workPlan.status)")
                        previewViewModel.initializeWithWorkPlan(workPlan)
                    }
                } else {
                    VStack {
                        Text("Error: No work plan selected")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("selectedWorkPlan is nil")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("Close") {
                            showPreviewWorkPlan = false
                        }
                        .padding()
                    }
                }
            }
            .onChange(of: showEditWorkPlan) { oldValue, newValue in
                print("[ManagerWorkPlansView] showEditWorkPlan changed from: \(oldValue) to: \(newValue), selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
            }
            .onChange(of: showPreviewWorkPlan) { oldValue, newValue in
                print("[ManagerWorkPlansView] showPreviewWorkPlan changed from: \(oldValue) to: \(newValue), selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
            }
        }
    }

    private var searchFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search by task title...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchQuery) { _, newValue in
                    print("[ManagerWorkPlansView] searchQuery changed to: \(newValue)")
                    viewModel.searchQuery = newValue
                }
            Picker("Status", selection: $selectedStatus) {
                Text("All").tag("All")
                Text("Draft").tag("DRAFT")
                Text("Published").tag("PUBLISHED")
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStatus) { _, newValue in
                print("[ManagerWorkPlansView] selectedStatus changed to: \(newValue)")
                viewModel.selectedStatus = newValue
            }
            Button(action: {
                viewModel.loadData(fetchAll: true)
            }) {
                Text("Fetch All Work Plans")
                    .foregroundColor(Color.ksrYellow)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
            }
        }
    }
}

struct WorkPlansSection: View {
    @ObservedObject var viewModel: ManagerWorkPlansViewModel
    @Binding var showEditWorkPlan: Bool
    @Binding var showPreviewWorkPlan: Bool
    @Binding var selectedWorkPlan: WorkPlanAPIService.WorkPlan?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Work Plans")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.filteredWorkPlans.isEmpty {
                Text("No work plans found")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Debug: \(viewModel.workPlans.count) total plans, \(viewModel.filteredWorkPlans.count) filtered, week: \(viewModel.selectedWeek.weekNumber), year: \(viewModel.selectedWeek.year), searchQuery: '\(viewModel.searchQuery)', selectedStatus: \(viewModel.selectedStatus)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                ForEach(viewModel.filteredWorkPlans) { plan in
                    Text("Debug: \(plan.task_title), Status: \(plan.status), Week: \(plan.weekNumber), Year: \(plan.year)")
                        .font(.caption)
                        .foregroundColor(.red)
                    WorkPlanCard(
                        plan: plan,
                        viewModel: viewModel,
                        showEditWorkPlan: $showEditWorkPlan,
                        showPreviewWorkPlan: $showPreviewWorkPlan,
                        selectedWorkPlan: $selectedWorkPlan
                    )
                }
            }
        }
    }
}

struct WorkPlanCard: View {
    let plan: WorkPlanAPIService.WorkPlan
    @ObservedObject var viewModel: ManagerWorkPlansViewModel
    @Binding var showEditWorkPlan: Bool
    @Binding var showPreviewWorkPlan: Bool
    @Binding var selectedWorkPlan: WorkPlanAPIService.WorkPlan?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded: Bool = false

    // Formatter do wyświetlania nazwy dnia tygodnia
    private let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Pełna nazwa dnia, np. Monday
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current // Use current timezone instead of UTC
        return formatter
    }()

    // Formatter do debugowania pełnej daty
    private let debugDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // Oblicz unikalną liczbę pracowników
    private var uniqueEmployeeCount: Int {
        Set(plan.assignments.map { $0.employee_id }).count
    }

    // Gradient dla statusu
    private var statusGradient: LinearGradient {
        plan.status == "PUBLISHED" ?
            LinearGradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
            LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Get Monday start of the week for this work plan
    private var weekMondayStart: Date {
        if let weekDate = WeekUtils.date(from: plan.weekNumber, year: plan.year) {
            return WeekUtils.startOfWeek(for: weekDate)
        }
        return viewModel.selectedWeek.startDate
    }
    
    // Function to get day of week index (0 = Monday, 6 = Sunday)
    private func dayOfWeekIndex(for date: Date) -> Int {
        let calendar = WeekUtils.mondayFirstCalendar
        let weekday = calendar.component(.weekday, from: date)
        // Convert to Monday-first (Monday = 0, Sunday = 6)
        return weekday == 1 ? 6 : weekday - 2
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(statusGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrYellow.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                // Nagłówek z ikoną i tytułem
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.ksrYellow)
                        .padding(6)
                        .background(Color.ksrYellow.opacity(0.2))
                        .clipShape(Circle())
                    
                    Text(plan.task_title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(plan.status)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(plan.status == "PUBLISHED" ? .green : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(plan.status == "PUBLISHED" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.ksrYellow)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }

                // Podstawowe informacje
                HStack {
                    Text("Week \(plan.weekNumber), \(String(format: "%d", plan.year))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(uniqueEmployeeCount) \(uniqueEmployeeCount == 1 ? "employee" : "employees")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Created by: \(plan.creator_name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Rozwijana sekcja
                if isExpanded {
                    Divider()
                        .padding(.vertical, 4)
                    
                    if let description = plan.description, !description.isEmpty {
                        Text("Description: \(description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.bottom, 4)
                    }
                    if let additionalInfo = plan.additional_info, !additionalInfo.isEmpty {
                        Text("Additional Info: \(additionalInfo)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.bottom, 4)
                    }
                    if let attachmentUrl = plan.attachment_url {
                        HStack {
                            Text("Attachment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Link(destination: URL(string: attachmentUrl)!) {
                                Image(systemName: "paperclip")
                                    .foregroundColor(Color.ksrYellow)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    if !plan.assignments.isEmpty {
                        Text("Assignments:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.bottom, 2)
                        
                        // Group assignments by employee and sort by day of week (Monday first)
                        let assignmentsByEmployee = Dictionary(grouping: plan.assignments, by: { $0.employee_id })
                        ForEach(assignmentsByEmployee.keys.sorted(), id: \.self) { employeeId in
                            if let assignments = assignmentsByEmployee[employeeId] {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Employee ID \(employeeId)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    // Sort assignments by day of week (Monday = 0, Sunday = 6)
                                    let sortedAssignments = assignments.sorted { assignment1, assignment2 in
                                        let day1 = dayOfWeekIndex(for: assignment1.work_date)
                                        let day2 = dayOfWeekIndex(for: assignment2.work_date)
                                        return day1 < day2
                                    }
                                    
                                    ForEach(sortedAssignments) { assignment in
                                        // Debug logging
                                        Text("Debug work_date: \(debugDateFormatter.string(from: assignment.work_date)), day index: \(dayOfWeekIndex(for: assignment.work_date))")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .italic()
                                        
                                        // Display assignment
                                        let displayDate = isValidWorkDate(assignment.work_date) ? assignment.work_date : weekMondayStart
                                        Text("\(dayOfWeekFormatter.string(from: displayDate)): \(assignment.start_time ?? "N/A") - \(assignment.end_time ?? "N/A")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if let notes = assignment.notes, !notes.isEmpty {
                                            Text("Notes: \(notes)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // Przyciski akcji - zawsze pokazuj View i Edit
                HStack(spacing: 8) {
                    // Przycisk View (Preview)
                    Button(action: {
                        print("[WorkPlanCard] Tapped View for plan: \(plan.task_title)")
                        print("[WorkPlanCard] Before setting selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
                        selectedWorkPlan = plan
                        print("[WorkPlanCard] After setting selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
                        
                        // Małe opóźnienie żeby state się zaaplikował
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("[WorkPlanCard] Opening preview sheet for: \(selectedWorkPlan?.task_title ?? "nil")")
                            showPreviewWorkPlan = true
                        }
                    }) {
                        Text("View")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    // Przycisk Edit - zawsze dostępny
                    Button(action: {
                        print("[WorkPlanCard] Tapped Edit for plan: \(plan.task_title)")
                        print("[WorkPlanCard] Before setting selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
                        selectedWorkPlan = plan
                        print("[WorkPlanCard] After setting selectedWorkPlan: \(selectedWorkPlan?.task_title ?? "nil")")
                        
                        // Małe opóźnienie żeby state się zaaplikował
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("[WorkPlanCard] Opening edit sheet for: \(selectedWorkPlan?.task_title ?? "nil")")
                            showEditWorkPlan = true
                        }
                    }) {
                        Text("Edit")
                            .font(.caption)
                            .foregroundColor(Color.ksrYellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ksrYellow.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
        .padding(.vertical, 4)
    }

    // Funkcja sprawdzająca, czy data jest poprawna (nie jest w 1970 roku)
    private func isValidWorkDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year >= 2020 // Zakładamy, że daty przed 2020 są niepoprawne
    }
}

struct ManagerWorkPlansView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerWorkPlansView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        ManagerWorkPlansView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
