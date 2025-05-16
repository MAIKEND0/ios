//
//  ManagerProjectsView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import SwiftUI

struct ManagerProjectsView: View {
    @StateObject private var viewModel = ManagerProjectsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedStatusFilter: ProjectStatusFilter = .all
    
    enum ProjectStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case pending = "Pending"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Sekcja filtrowania
                    filterSection
                    
                    // Sekcja projektów
                    projectsSection
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
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
        }
    }
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter Projects")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            Picker("Status", selection: $selectedStatusFilter) {
                ForEach(ProjectStatusFilter.allCases) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedStatusFilter) { newValue, _ in // Poprawiono na nową składnię
                viewModel.filterProjects(by: newValue)
            }
        }
    }
    
    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projects")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if viewModel.filteredProjects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(Color.gray)
                    Text("No projects found")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Text("No projects are assigned to your supervised tasks.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.filteredProjects) { project in
                        projectCard(project: project)
                    }
                }
            }
        }
    }
    
    private func projectCard(project: ManagerAPIService.Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text(project.status?.rawValue.capitalized ?? "Unknown")
                    .font(.caption)
                    .padding(4)
                    .background(project.statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            if let description = project.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    .lineLimit(2)
            }
            if let address = project.fullAddress {
                Text("Address: \(address)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Workers: \(project.assignedWorkersCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Tasks: \(project.tasks.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            if let startDate = project.start_date {
                Text("Start: \(startDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let endDate = project.end_date {
                Text("End: \(endDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // Lista zadań
            if !project.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    ForEach(project.tasks) { task in
                        Text("• \(task.title)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

struct ManagerProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ManagerProjectsView()
                .preferredColorScheme(.light)
            ManagerProjectsView()
                .preferredColorScheme(.dark)
        }
    }
}
