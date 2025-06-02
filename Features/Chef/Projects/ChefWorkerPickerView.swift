//
//  ChefWorkerPickerView.swift
//  KSR Cranes App
//
//  Worker selection view for task assignment - FIXED with real API endpoints
//

import SwiftUI
import Combine
import Foundation

struct ChefWorkerPickerView: View {
    @Binding var selectedWorkers: [AvailableWorker]
    let projectId: Int?
    let excludeTaskId: Int?
    let requiredCraneTypes: [Int]?
    
    @StateObject private var viewModel = ChefWorkerPickerViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var showAvailabilityOnly = false
    
    init(
        selectedWorkers: Binding<[AvailableWorker]>,
        projectId: Int? = nil,
        excludeTaskId: Int? = nil,
        requiredCraneTypes: [Int]? = nil
    ) {
        self._selectedWorkers = selectedWorkers
        self.projectId = projectId
        self.excludeTaskId = excludeTaskId
        self.requiredCraneTypes = requiredCraneTypes
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Controls
                searchAndFilterSection
                
                // Workers List
                if viewModel.isLoading && viewModel.workers.isEmpty {
                    loadingView
                } else if filteredWorkers.isEmpty {
                    emptyStateView
                } else {
                    workersList
                }
            }
            .background(backgroundGradient)
            .navigationTitle("Select Workers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done (\(selectedWorkers.count))") {
                        dismiss()
                    }
                    .foregroundColor(.ksrYellow)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pass the current selections to maintain state
                viewModel.initialSelectedWorkers = selectedWorkers
                viewModel.loadAvailableWorkers(
                    projectId: projectId,
                    excludeTaskId: excludeTaskId,
                    requiredCraneTypes: requiredCraneTypes
                )
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
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            searchBarView
            
            // Filter Controls
            filterControlsView
            
            // Stats
            statsView
        }
        .padding()
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.ksrSecondary)
            
            TextField("Search workers...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.ksrSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.ksrLightGray.opacity(colorScheme == .dark ? 0.3 : 1))
        .cornerRadius(10)
    }
    
    private var filterControlsView: some View {
        HStack {
            // Selection Count
            if !selectedWorkers.isEmpty {
                selectionCountView
            }
            
            Spacer()
            
            // Show Available Only Toggle
            availabilityToggleView
            
            // Clear All Button
            if !selectedWorkers.isEmpty {
                clearAllButton
            }
        }
    }
    
    private var selectionCountView: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.ksrSuccess)
            Text("\(selectedWorkers.count) selected")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.ksrSuccess.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var availabilityToggleView: some View {
        HStack(spacing: 8) {
            Text("Available only")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Toggle("", isOn: $showAvailabilityOnly)
                .labelsHidden()
                .scaleEffect(0.8)
        }
    }
    
    private var clearAllButton: some View {
        Button("Clear All") {
            selectedWorkers.removeAll()
        }
        .font(.subheadline)
        .foregroundColor(.ksrError)
    }
    
    private var statsView: some View {
        Group {
            if !viewModel.workers.isEmpty {
                HStack(spacing: 16) {
                    ChefStatChip(
                        label: "Total",
                        value: "\(viewModel.workers.count)",
                        color: .ksrInfo
                    )
                    
                    ChefStatChip(
                        label: "Available",
                        value: "\(viewModel.totalAvailable)",
                        color: .ksrSuccess
                    )
                    
                    if viewModel.totalWithConflicts > 0 {
                        ChefStatChip(
                            label: "Conflicts",
                            value: "\(viewModel.totalWithConflicts)",
                            color: .ksrWarning
                        )
                    }
                    
                    if !requiredCraneTypes.isNilOrEmpty {
                        ChefStatChip(
                            label: "Qualified",
                            value: "\(filteredWorkersBySkills.count)",
                            color: .ksrInfo
                        )
                    }
                }
            }
        }
    }
    
    // ✅ IMPROVED: Better filtering logic with isActiveEmployee
    private var filteredWorkers: [AvailableWorker] {
        var workers = viewModel.workers
        
        // ✅ FIXED: Filter by active employees only using isActiveEmployee
        workers = workers.filter { $0.employee.isActiveEmployee }
        
        // Filter by required crane types first
        if let craneTypes = requiredCraneTypes, !craneTypes.isEmpty {
            workers = workers.filter { worker in
                worker.craneTypes.contains { craneType in
                    craneTypes.contains(craneType.id)
                }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            workers = workers.filter { worker in
                worker.employee.name.localizedCaseInsensitiveContains(searchText) ||
                worker.employee.email.localizedCaseInsensitiveContains(searchText) ||
                worker.craneTypes.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by availability
        if showAvailabilityOnly {
            workers = workers.filter { worker in
                worker.availability.isAvailable
            }
        }
        
        return workers
    }
    
    // Helper property for crane type filtering stats
    private var filteredWorkersBySkills: [AvailableWorker] {
        guard let craneTypes = requiredCraneTypes, !craneTypes.isEmpty else {
            return viewModel.workers
        }
        
        return viewModel.workers.filter { worker in
            worker.craneTypes.contains { craneType in
                craneTypes.contains(craneType.id)
            }
        }
    }
    
    private var workersList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredWorkers, id: \.employee.id) { worker in
                    workerCardView(for: worker)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private func workerCardView(for worker: AvailableWorker) -> some View {
        ChefWorkerPickerCard(
            worker: worker,
            isSelected: isWorkerSelected(worker.employee.id),
            requiredCraneTypes: requiredCraneTypes,
            onToggle: {
                toggleWorkerSelection(worker)
            }
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                .scaleEffect(1.2)
            
            Text("Loading available workers...")
                .font(.headline)
                .foregroundColor(.ksrTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.ksrYellow.opacity(0.6))
            
            emptyStateTextView
            
            if showAvailabilityOnly || !requiredCraneTypes.isNilOrEmpty {
                showAllWorkersButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateTextView: some View {
        VStack(spacing: 8) {
            Text("No Workers Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            if showAvailabilityOnly {
                Text("No available workers match your criteria")
                    .font(.body)
                    .foregroundColor(.ksrTextSecondary)
                    .multilineTextAlignment(.center)
            } else if !searchText.isEmpty {
                Text("No workers match '\(searchText)'")
                    .font(.body)
                    .foregroundColor(.ksrTextSecondary)
            } else if !requiredCraneTypes.isNilOrEmpty {
                Text("No workers have the required crane certifications")
                    .font(.body)
                    .foregroundColor(.ksrTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No workers available for assignment")
                    .font(.body)
                    .foregroundColor(.ksrTextSecondary)
            }
        }
    }
    
    private var showAllWorkersButton: some View {
        Button("Show All Workers") {
            showAvailabilityOnly = false
            searchText = ""
        }
        .font(.headline)
        .foregroundColor(.black)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.ksrYellow)
        .cornerRadius(25)
    }
    
    private func isWorkerSelected(_ workerId: Int) -> Bool {
        return selectedWorkers.contains { selectedWorker in
            selectedWorker.employee.id == workerId
        }
    }
    
    private func toggleWorkerSelection(_ worker: AvailableWorker) {
        let workerId = worker.employee.id
        if let index = selectedWorkers.firstIndex(where: { selectedWorker in
            selectedWorker.employee.id == workerId
        }) {
            selectedWorkers.remove(at: index)
        } else {
            selectedWorkers.append(worker)
        }
    }
}

// MARK: - ViewModel with Real API Calls - ✅ FINAL FIXED VERSION

class ChefWorkerPickerViewModel: ObservableObject {
    @Published var workers: [AvailableWorker] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var totalAvailable = 0
    @Published var totalWithConflicts = 0
    
    var initialSelectedWorkers: [AvailableWorker] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // ✅ Main entry point for loading workers
    func loadAvailableWorkers(
        projectId: Int? = nil,
        excludeTaskId: Int? = nil,
        requiredCraneTypes: [Int]? = nil,
        date: Date? = nil
    ) {
        isLoading = true
        errorMessage = ""
        
        #if DEBUG
        print("[ChefWorkerPickerViewModel] Loading available workers...")
        if let projectId = projectId {
            print("[ChefWorkerPickerViewModel] Project ID: \(projectId)")
        }
        if let excludeTaskId = excludeTaskId {
            print("[ChefWorkerPickerViewModel] Excluding task ID: \(excludeTaskId)")
        } else {
            print("[ChefWorkerPickerViewModel] Creating new task - no exclusions")
        }
        if let craneTypes = requiredCraneTypes {
            print("[ChefWorkerPickerViewModel] Required crane types: \(craneTypes)")
        }
        #endif
        
        // Choose the right API endpoint based on context
        if let excludeTaskId = excludeTaskId {
            // Editing existing task - use task-based API
            loadWorkersForExistingTask(excludeTaskId, requiredCraneTypes: requiredCraneTypes)
        } else if let projectId = projectId {
            // Creating new task - use project-based API
            loadWorkersForProject(projectId)
        } else {
            // Error - need either task ID or project ID
            self.displayError("Project ID is required for loading workers")
            isLoading = false
        }
    }
    
    // ✅ FIXED: Pass requiredCraneTypes as parameter to avoid scope issues
    private func loadWorkersForExistingTask(_ taskId: Int, requiredCraneTypes: [Int]?) {
        #if DEBUG
        print("[ChefWorkerPickerViewModel] 📞 API Call: Loading workers for existing task \(taskId)")
        #endif
        
        // Use the existing method from documents - fetchAvailableWorkers with taskId
        ChefProjectsAPIService.shared.fetchAvailableWorkers(
            taskId: taskId,
            date: nil,
            requiredCraneTypes: requiredCraneTypes,
            includeAvailability: true
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] (completion: Subscribers.Completion<ChefProjectsAPIService.APIError>) in
                self?.isLoading = false
                
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [ChefWorkerPickerViewModel] Failed to load workers for task: \(error)")
                    #endif
                    self?.displayError("Failed to load workers: \(error.localizedDescription)")
                    
                case .finished:
                    #if DEBUG
                    print("✅ Successfully loaded workers for existing task")
                    #endif
                }
            },
            receiveValue: { [weak self] (response: AvailableWorkersResponse) in
                #if DEBUG
                print("🔍 [DEBUG] Workers count: \(response.workers.count)")
                if let firstWorker = response.workers.first {
                    print("🔍 [DEBUG] First worker structure:")
                    print("   - Employee ID: \(firstWorker.employee.employeeId)")
                    print("   - Name: \(firstWorker.employee.name)")
                    print("   - Email: \(firstWorker.employee.email)")
                    print("   - Role: \(firstWorker.employee.role)")
                    print("   - Is Activated: \(firstWorker.employee.isActivated?.description ?? "nil")")
                    print("   - Is Active Employee: \(firstWorker.employee.isActiveEmployee)")
                    print("   - Crane types: \(firstWorker.craneTypes.count)")
                    print("   - Is Available: \(firstWorker.availability.isAvailable)")
                }
                #endif
                
                self?.workers = response.workers
                self?.totalAvailable = response.totalAvailable
                self?.totalWithConflicts = response.totalWithConflicts
                
                #if DEBUG
                print("[ChefWorkerPickerViewModel] ✅ Loaded \(response.workers.count) workers for task")
                print("   - Available: \(response.totalAvailable)")
                print("   - With conflicts: \(response.totalWithConflicts)")
                #endif
            }
        )
        .store(in: &cancellables)
    }
    
    // ✅ FIXED: Use correct return type - AvailableWorkersResponse
    private func loadWorkersForProject(_ projectId: Int) {
        #if DEBUG
        print("[ChefWorkerPickerViewModel] 📞 API Call: Loading workers for project \(projectId)")
        #endif
        
        // Use the project-specific method that returns AvailableWorkersResponse
        ChefProjectsAPIService.shared.fetchAvailableWorkersForProject(projectId: projectId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<ChefProjectsAPIService.APIError>) in
                    self?.isLoading = false
                    
                    switch completion {
                    case .failure(let error):
                        #if DEBUG
                        print("❌ [ChefWorkerPickerViewModel] Failed to load workers for project: \(error)")
                        #endif
                        self?.displayError("Failed to load workers: \(error.localizedDescription)")
                        
                    case .finished:
                        #if DEBUG
                        print("✅ Successfully loaded workers for project")
                        #endif
                    }
                },
                receiveValue: { [weak self] (response: AvailableWorkersResponse) in
                    #if DEBUG
                    print("🔍 [DEBUG] Project workers count: \(response.workers.count)")
                    if let firstWorker = response.workers.first {
                        print("🔍 [DEBUG] First project worker structure:")
                        print("   - Employee ID: \(firstWorker.employee.employeeId)")
                        print("   - Name: \(firstWorker.employee.name)")
                        print("   - Email: \(firstWorker.employee.email)")
                        print("   - Role: \(firstWorker.employee.role)")
                        print("   - Is Activated: \(firstWorker.employee.isActivated?.description ?? "nil")")
                        print("   - Is Active Employee: \(firstWorker.employee.isActiveEmployee)")
                        print("   - Crane types: \(firstWorker.craneTypes.count)")
                        print("   - Is Available: \(firstWorker.availability.isAvailable)")
                    }
                    #endif
                    
                    self?.workers = response.workers
                    self?.totalAvailable = response.totalAvailable
                    self?.totalWithConflicts = response.totalWithConflicts
                    
                    #if DEBUG
                    print("[ChefWorkerPickerViewModel] ✅ Loaded \(response.workers.count) workers for project")
                    print("   - Available: \(response.totalAvailable)")
                    print("   - With conflicts: \(response.totalWithConflicts)")
                    #endif
                }
            )
            .store(in: &cancellables)
    }
    
    // ✅ ADDED: Helper method to calculate stats (not needed anymore since we get stats from API)
    private func calculateStats(_ workers: [AvailableWorker]) {
        totalAvailable = workers.count { $0.availability.isAvailable }
        totalWithConflicts = workers.count { !$0.availability.isAvailable }
        
        #if DEBUG
        print("   - Available: \(totalAvailable)")
        print("   - With conflicts: \(totalWithConflicts)")
        #endif
    }
    
    // ✅ Display error message
    private func displayError(_ message: String) {
        errorMessage = message
        showError = true
        
        #if DEBUG
        print("❌ [ChefWorkerPickerViewModel] Error: \(message)")
        #endif
    }
}

// MARK: - Enhanced Worker Picker Card

struct ChefWorkerPickerCard: View {
    let worker: AvailableWorker
    let isSelected: Bool
    let requiredCraneTypes: [Int]?
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Check if worker has all required crane types
    private var hasRequiredSkills: Bool {
        guard let required = requiredCraneTypes, !required.isEmpty else { return true }
        return required.allSatisfy { requiredType in
            worker.craneTypes.contains { $0.id == requiredType }
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Selection Indicator
                selectionIndicator
                
                // Worker Avatar
                workerAvatar
                
                // Worker Info
                workerInfoView
                
                Spacer()
                
                // Skills indicator
                if !requiredCraneTypes.isNilOrEmpty {
                    skillsIndicator
                }
            }
            .padding()
            .background(cardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundColor(isSelected ? .ksrSuccess : .ksrSecondary)
    }
    
    private var workerAvatar: some View {
        Group {
            if let profileUrl = worker.employee.profilePictureUrl {
                AsyncImage(url: URL(string: profileUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.ksrSecondary)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.ksrSecondary)
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
    }
    
    private var workerInfoView: some View {
        VStack(alignment: .leading, spacing: 6) {
            workerHeaderView
            workerEmailView
            craneTypesView
            availabilityDetailsView
        }
    }
    
    private var workerHeaderView: some View {
        HStack {
            Text(worker.employee.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            ChefAvailabilityBadge(availability: worker.availability)
        }
    }
    
    private var workerEmailView: some View {
        Text(worker.employee.email)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private var craneTypesView: some View {
        Group {
            if !worker.craneTypes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(worker.craneTypes.prefix(3)), id: \.id) { craneType in
                            craneTypeChip(craneType)
                        }
                        
                        if worker.craneTypes.count > 3 {
                            Text("+\(worker.craneTypes.count - 3)")
                                .font(.caption)
                                .foregroundColor(.ksrSecondary)
                        }
                    }
                }
            }
        }
    }
    
    private func craneTypeChip(_ craneType: CraneType) -> some View {
        let isRequired = requiredCraneTypes?.contains(craneType.id) ?? false
        
        return Text(craneType.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isRequired ? Color.ksrSuccess.opacity(0.2) : Color.ksrInfo.opacity(0.1))
            .foregroundColor(isRequired ? .ksrSuccess : .ksrInfo)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRequired ? Color.ksrSuccess : Color.clear, lineWidth: 1)
            )
    }
    
    private var skillsIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: hasRequiredSkills ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.title3)
                .foregroundColor(hasRequiredSkills ? .ksrSuccess : .ksrWarning)
            
            Text(hasRequiredSkills ? "Qualified" : "Missing Skills")
                .font(.caption2)
                .foregroundColor(hasRequiredSkills ? .ksrSuccess : .ksrWarning)
                .multilineTextAlignment(.center)
        }
    }
    
    private var availabilityDetailsView: some View {
        Group {
            if !worker.availability.isAvailable {
                availabilityDetails
            }
        }
    }
    
    // Rozdzielony widok dostępności - rozwiązanie dla błędu kompilacji
    private var availabilityDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            conflictTasksView
            maxHoursView
            nextAvailableView
        }
    }
    
    @ViewBuilder
    private var conflictTasksView: some View {
        if let conflicts = worker.availability.conflictingTasks, !conflicts.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.ksrWarning)
                
                Text("Conflicts with \(conflicts.count) task\(conflicts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.ksrWarning)
            }
        }
    }
    
    @ViewBuilder
    private var maxHoursView: some View {
        if worker.availability.workHoursThisWeek >= worker.availability.maxWeeklyHours {
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.ksrError)
                
                Text("Max weekly hours reached (\(Int(worker.availability.workHoursThisWeek))h)")
                    .font(.caption)
                    .foregroundColor(.ksrError)
            }
        }
    }
    
    @ViewBuilder
    private var nextAvailableView: some View {
        if let nextAvailable = worker.availability.nextAvailableDate {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.ksrInfo)
                
                Text("Available from \(nextAvailable, style: .date)")
                    .font(.caption)
                    .foregroundColor(.ksrInfo)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.ksrSuccess :
                        (!hasRequiredSkills && !requiredCraneTypes.isNilOrEmpty) ? Color.ksrWarning.opacity(0.5) :
                        Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Supporting Views

struct ChefStatChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct ChefAvailabilityBadge: View {
    let availability: WorkerAvailability
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: availability.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.caption)
            
            Text(availability.isAvailable ? "Available" : "Conflict")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(availability.isAvailable ? .ksrSuccess : .ksrWarning)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((availability.isAvailable ? Color.ksrSuccess : Color.ksrWarning).opacity(0.15))
        )
    }
}

// MARK: - Utility Extensions

extension Array where Element == Int {
    var isNilOrEmpty: Bool {
        return isEmpty
    }
}

extension Optional where Wrapped == Array<Int> {
    var isNilOrEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let array):
            return array.isEmpty
        }
    }
}

// ✅ HELPER: Collection count extension for filtering
extension Collection {
    func count(where predicate: (Element) -> Bool) -> Int {
        return self.filter(predicate).count
    }
}
