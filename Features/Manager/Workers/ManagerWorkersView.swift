// ManagerWorkersView.swift
// KSR Cranes App
// Created by Maksymilian Marcinowski on 17/05/2025.
// Visual improvements added - Integrates TimesheetReportsView in Timesheets tab

import SwiftUI
import UIKit

struct ManagerWorkersView: View {
    @StateObject private var viewModel = ManagerWorkersViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMainTab: MainTab = .operators
    @State private var searchText = ""
    
    enum MainTab: String, TabProtocol {
        case operators = "Operators"
        case timesheets = "Timesheets"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .operators: return "person.3.fill"
            case .timesheets: return "doc.text.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .operators: return .ksrYellow
            case .timesheets: return .ksrInfo
            }
        }
    }
    
    var filteredWorkers: [ManagerAPIService.Worker] {
        let workers = viewModel.workers
        
        if searchText.isEmpty || selectedMainTab != .operators {
            return workers
        } else {
            return workers.filter { worker in
                worker.name.localizedCaseInsensitiveContains(searchText) ||
                worker.email?.localizedCaseInsensitiveContains(searchText) == true ||
                worker.phone_number?.localizedCaseInsensitiveContains(searchText) == true ||
                String(worker.employee_id).localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerStatsSection
                    searchSection
                    mainTabSelectionSection
                    
                    if selectedMainTab == .operators {
                        operatorsContentSection
                    } else {
                        TimesheetReportsView()
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("Crane Operators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colorScheme == .dark ? .white : Color.primary)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(viewModel.isLoading)
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
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerStatsSection: some View {
        HStack(spacing: 16) {
            OperatorStatCard(
                title: "Hired Operators",
                value: "\(viewModel.workers.count)",
                icon: "person.3.fill",
                color: .ksrYellow
            )
            
            OperatorStatCard(
                title: "Active Tasks",
                value: "\(viewModel.workers.reduce(0) { $0 + $1.assignedTasks.count })",
                icon: "list.clipboard.fill",
                color: .ksrSuccess
            )
            
            OperatorStatCard(
                title: "Available Now",
                value: "\(viewModel.workers.filter { $0.assignedTasks.isEmpty }.count)",
                icon: "person.fill.checkmark",
                color: .ksrInfo
            )
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField(selectedMainTab == .operators ? "Search operators..." : "Search timesheets, tasks, workers...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        UIApplication.shared.hideKeyboard()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
    }
    
    private var mainTabSelectionSection: some View {
        HStack(spacing: 12) {
            ForEach(MainTab.allCases, id: \.id) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedMainTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMainTab = tab
                        if tab == .timesheets {
                            searchText = ""
                        }
                    }
                }
            }
        }
    }
    
    private var operatorsContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(filteredWorkers.count) operators")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Group {
                if viewModel.isLoading {
                    OperatorsLoadingView()
                } else if filteredWorkers.isEmpty {
                    OperatorsEmptyStateView(hasOperators: !viewModel.workers.isEmpty)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredWorkers) { craneOperator in
                            OperatorCard(craneOperator: craneOperator)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: filteredWorkers.count)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct OperatorStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct OperatorCard: View {
    let craneOperator: ManagerAPIService.Worker
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    private var hasActiveTasks: Bool {
        !craneOperator.assignedTasks.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Profile image with fallback
                    Group {
                        if let profileUrl = craneOperator.profilePictureUrl, !profileUrl.isEmpty {
                            WorkerCachedProfileImage(
                                employeeId: String(craneOperator.employee_id),
                                currentImageUrl: profileUrl,
                                size: 50
                            )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.ksrYellow)
                                .frame(width: 50, height: 50)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(craneOperator.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(hasActiveTasks ? Color.ksrSuccess : Color.ksrInfo)
                                    .frame(width: 8, height: 8)
                                
                                Text(hasActiveTasks ? "Working" : "Available")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(hasActiveTasks ? Color.ksrSuccess : Color.ksrInfo)
                            }
                        }
                        
                        Text("ID: \(craneOperator.employee_id)")
                            .font(.subheadline)
                            .foregroundColor(Color.ksrYellow)
                            .fontWeight(.medium)
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 20) {
                    OperatorInfoItem(
                        icon: "list.clipboard",
                        value: "\(craneOperator.assignedTasks.count) tasks",
                        color: .ksrInfo
                    )
                    
                    if craneOperator.email != nil {
                        OperatorInfoItem(icon: "envelope", value: "Email", color: .ksrSuccess)
                    }
                    
                    if craneOperator.phone_number != nil {
                        OperatorInfoItem(icon: "phone", value: "Phone", color: .ksrWarning)
                    }
                }
            }
            .padding(20)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let email = craneOperator.email {
                            ContactInfoRow(icon: "envelope.fill", label: "Email", value: email, color: .ksrInfo)
                        }
                        
                        if let phone = craneOperator.phone_number {
                            ContactInfoRow(icon: "phone.fill", label: "Phone", value: phone, color: .ksrSuccess)
                        }
                        
                        if !craneOperator.assignedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Tasks (\(craneOperator.assignedTasks.count))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                ForEach(craneOperator.assignedTasks.prefix(5)) { task in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.ksrYellow)
                                            .frame(width: 6, height: 6)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.title)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .fontWeight(.medium)
                                            
                                            if let project = task.project {
                                                Text(project.title)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                
                                if craneOperator.assignedTasks.count > 5 {
                                    Text("and \(craneOperator.assignedTasks.count - 5) more...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 14)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ksrSuccess)
                                    .font(.system(size: 16))
                                
                                Text("Available for new assignments")
                                    .font(.subheadline)
                                    .foregroundColor(.ksrSuccess)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((hasActiveTasks ? Color.ksrSuccess : Color.ksrInfo).opacity(0.3), lineWidth: 1)
        )
    }
}

struct OperatorInfoItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct OperatorsLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading crane operators...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct OperatorsEmptyStateView: View {
    let hasOperators: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasOperators ? "magnifyingglass" : "crane")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasOperators ? "No operators found" : "No hired operators")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(hasOperators ?
                     "No operators match your current search criteria." :
                     "No crane operators are currently hired for your construction site."
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, 40)
    }
}

struct ManagerWorkersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ManagerWorkersView()
                .preferredColorScheme(.light)
            ManagerWorkersView()
                .preferredColorScheme(.dark)
        }
    }
}
