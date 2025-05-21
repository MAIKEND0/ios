//
//  ManagerWorkPlansView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 20/05/2025.
//  Updated with enhanced UI/UX on 21/05/2025.
//

import SwiftUI

struct ManagerWorkPlansView: View {
    @StateObject private var viewModel = ManagerWorkPlansViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEditWorkPlan: Bool = false
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
                    WorkPlanWeekSelector(viewModel: viewModel, weekRangeText: viewModel.weekRangeText)
                        .padding(.horizontal)

                    // Work Plans
                    WorkPlansSection(viewModel: viewModel, showEditWorkPlan: $showEditWorkPlan, selectedWorkPlan: $selectedWorkPlan)
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Work Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.loadData() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
            }
            .onAppear { viewModel.loadData() }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
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
                if let workPlan = selectedWorkPlan, workPlan.status == "DRAFT" {
                    EditWorkPlanView(workPlan: workPlan, isPresented: $showEditWorkPlan)
                }
            }
        }
    }

    private var searchFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search by task title...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchQuery) { _, newValue in
                    viewModel.searchQuery = newValue
                }
            Picker("Status", selection: $selectedStatus) {
                Text("All").tag("All")
                Text("Draft").tag("DRAFT")
                Text("Published").tag("PUBLISHED")
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStatus) { _, newValue in
                viewModel.selectedStatus = newValue
            }
        }
    }
}

struct WorkPlansSection: View {
    @ObservedObject var viewModel: ManagerWorkPlansViewModel
    @Binding var showEditWorkPlan: Bool
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
            } else {
                ForEach(viewModel.filteredWorkPlans) { plan in
                    WorkPlanCard(plan: plan, showEditWorkPlan: $showEditWorkPlan, selectedWorkPlan: $selectedWorkPlan)
                }
            }
        }
    }
}

struct WorkPlanCard: View {
    let plan: WorkPlanAPIService.WorkPlan
    @Binding var showEditWorkPlan: Bool
    @Binding var selectedWorkPlan: WorkPlanAPIService.WorkPlan?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.task_title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(plan.status)
                    .font(.caption)
                    .foregroundColor(plan.status == "PUBLISHED" ? .green : .gray)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color.ksrYellow)
            }
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
            Text("Week \(plan.weekNumber), \(plan.year)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Created by: \(plan.creator_name ?? "Unknown")")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(plan.assignments.count) employees")
                .font(.caption)
                .foregroundColor(.secondary)
            if isExpanded {
                if let description = plan.description, !description.isEmpty {
                    Text("Description: \(description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let additionalInfo = plan.additional_info, !additionalInfo.isEmpty {
                    Text("Additional Info: \(additionalInfo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
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
                }
                if !plan.assignments.isEmpty {
                    Text("Assignments:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    ForEach(plan.assignments) { assignment in
                        Text("Employee \(assignment.employee_id): \(DateFormatter.isoDate.string(from: assignment.work_date)) \(assignment.start_time ?? "") - \(assignment.end_time ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Button(action: {
                selectedWorkPlan = plan
                showEditWorkPlan = plan.status == "DRAFT"
            }) {
                Text(plan.status == "DRAFT" ? "Edit" : "View")
                    .font(.caption)
                    .foregroundColor(Color.ksrYellow)
            }
            .disabled(plan.status != "DRAFT")
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
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
