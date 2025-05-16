//
//  TimesheetReportsView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 18/05/2025.
//

import SwiftUI
import PDFKit

struct TimesheetReportsView: View {
    @StateObject private var viewModel = TimesheetReportsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimesheet: ManagerAPIService.Timesheet?
    @State private var selectedTab: Tab = .tasks // Zakładki: Tasks lub Workers
    @State private var searchText = "" // Wyszukiwanie
    
    // Wyliczenie dla zakładek
    private enum Tab: String, CaseIterable {
        case tasks = "Tasks"
        case workers = "Workers"
    }
    
    // Grupowanie timesheetów
    private var groupedByTasks: [Int: [ManagerAPIService.Timesheet]] {
        Dictionary(grouping: filteredTimesheets) { $0.task_id }
    }
    
    private var groupedByWorkers: [Int: [ManagerAPIService.Timesheet]] {
        Dictionary(grouping: filteredTimesheets) { $0.employee_id ?? 0 }
    }
    
    // Filtrowanie timesheetów na podstawie wyszukiwania
    private var filteredTimesheets: [ManagerAPIService.Timesheet] {
        if searchText.isEmpty {
            return viewModel.timesheets
        } else {
            let lowercasedSearch = searchText.lowercased()
            return viewModel.timesheets.filter { timesheet in
                let taskTitle = timesheet.Tasks?.title.lowercased() ?? ""
                let workerName = timesheet.Employees?.name.lowercased() ?? ""
                let weekNumber = String(timesheet.weekNumber)
                let year = String(timesheet.year)
                return taskTitle.contains(lowercasedSearch) ||
                       workerName.contains(lowercasedSearch) ||
                       weekNumber.contains(lowercasedSearch) ||
                       year.contains(lowercasedSearch)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Picker dla zakładek
                Picker("View", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Pole wyszukiwania
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Lista timesheetów
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .padding(.top, 50)
                    } else if filteredTimesheets.isEmpty {
                        EmptyStateView()
                    } else {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            if selectedTab == .tasks {
                                ForEach(groupedByTasks.keys.sorted(), id: \.self) { taskId in
                                    if let timesheets = groupedByTasks[taskId],
                                       let task = timesheets.first?.Tasks {
                                        TimesheetSectionView(
                                            title: task.title.isEmpty ? "Brak tytułu" : task.title,
                                            icon: "folder.fill",
                                            timesheets: timesheets,
                                            onSelect: { selectedTimesheet = $0 }
                                        )
                                    }
                                }
                            } else {
                                ForEach(groupedByWorkers.keys.sorted(), id: \.self) { employeeId in
                                    if let timesheets = groupedByWorkers[employeeId],
                                       let worker = timesheets.first?.Employees {
                                        TimesheetSectionView(
                                            title: worker.name.isEmpty ? "Nieprzypisany" : worker.name,
                                            icon: "person.fill",
                                            timesheets: timesheets,
                                            onSelect: { selectedTimesheet = $0 }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(backgroundColor)
            .navigationTitle("Signed Timesheets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.loadData() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
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
            .sheet(item: $selectedTimesheet) { timesheet in
                if let url = URL(string: timesheet.timesheetUrl) {
                    PDFViewer(source: .url(url))
                        .presentationDetents([.large])
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(.systemBackground)
    }
}

// Komponent pola wyszukiwania
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search by task, worker, week...", text: $text)
                .foregroundColor(.primary)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Komponent widoku pustego stanu
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Timesheets Found")
                .font(.headline)
                .foregroundColor(.ksrMediumGray)
            Text("No signed timesheets are available or match your search.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.ksrMediumGray)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}

// Komponent sekcji timesheetów
struct TimesheetSectionView: View {
    let title: String
    let icon: String
    let timesheets: [ManagerAPIService.Timesheet]
    let onSelect: (ManagerAPIService.Timesheet) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Section(header: sectionHeader) {
            ForEach(timesheets) { timesheet in
                TimesheetCardView(timesheet: timesheet)
                    .onTapGesture { onSelect(timesheet) }
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.ksrYellow)
                .font(.title3)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemBackground))
        .cornerRadius(8)
    }
}

// Komponent karty timesheeta
struct TimesheetCardView: View {
    let timesheet: ManagerAPIService.Timesheet
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.ksrYellow)
                Text("Week \(timesheet.weekNumber), \(timesheet.year)")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .ksrDarkGray)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            Text("Task ID: \(timesheet.task_id)")
                .font(.subheadline)
                .foregroundColor(.ksrMediumGray)
            Text("Created: \(timesheet.created_at, format: .dateTime.day().month().year())")
                .font(.subheadline)
                .foregroundColor(.ksrMediumGray)
            if let taskTitle = timesheet.Tasks?.title {
                Text("Task: \(taskTitle)")
                    .font(.subheadline)
                    .foregroundColor(.ksrMediumGray)
            }
            if let workerName = timesheet.Employees?.name {
                Text("Worker: \(workerName)")
                    .font(.subheadline)
                    .foregroundColor(.ksrMediumGray)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : .white
    }
}

struct TimesheetReportsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimesheetReportsView()
                .preferredColorScheme(.light)
            TimesheetReportsView()
                .preferredColorScheme(.dark)
        }
    }
}
