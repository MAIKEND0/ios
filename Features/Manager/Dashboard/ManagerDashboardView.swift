import SwiftUI
import PDFKit

struct ManagerDashboardView: View {
    @StateObject private var viewModel = ManagerDashboardViewModel()
    @State private var showFilterOptions = false
    @State private var searchText = ""
    @State private var hasAppeared = false
    @State private var showSignatureModal = false
    @State private var showReceiptView = false
    @State private var showWeekDetailsModal = false
    @State private var selectedTaskWeek: ManagerDashboardViewModel.TaskWeekEntry?
    @State private var timesheetUrl: String?
    @State private var signatureImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                mainContentView
            }
            .background(dashboardBackground)
            .navigationTitle("Manager Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarContent
                }
            }
            .onAppear {
                handleViewAppear()
            }
            .onDisappear {
                viewModel.viewDisappeared()
            }
            .onChange(of: hasAppeared) { newValue, _ in
                if newValue {
                    viewModel.loadData()
                }
            }
            .onChange(of: viewModel.allPendingEntriesByTask) { _, _ in
                updatePulsingState()
                #if DEBUG
                print("[ManagerDashboardView] allPendingEntriesByTask changed, count: \(viewModel.allPendingEntriesByTask.count), isPulsing: \(isPulsing)")
                #endif
            }
            .onReceive(viewModel.$isLoading) { isLoading in
                if !isLoading {
                    updatePulsingState()
                    #if DEBUG
                    print("[ManagerDashboardView] isLoading changed to false, entries count: \(viewModel.allPendingEntriesByTask.count), isPulsing: \(isPulsing)")
                    #endif
                }
            }
            .refreshable {
                await refreshData()
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $showWeekDetailsModal) {
                weekDetailsModalContent
            }
            .fullScreenCover(isPresented: $showSignatureModal) {
                signatureModalContent
            }
            .sheet(isPresented: $showReceiptView) {
                receiptViewContent
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quick Stats Header
            ManagerDashboardSections.SummaryCardsSection(viewModel: viewModel)
            
            // Compact Pending Approvals
            ManagerDashboardSections.CompactPendingSection(
                viewModel: viewModel,
                isPulsing: isPulsing,
                onViewWeekDetails: { taskWeek in
                    selectedTaskWeek = taskWeek
                    showWeekDetailsModal = true
                }
            )
            
            // Navigation Cards Row
            navigationCardsSection
            
            // Week Selector (Compact)
            ManagerDashboardSections.CompactWeekSelectorSection(viewModel: viewModel)
            
            // Tasks Section (Enhanced but less overwhelming)
            ManagerDashboardSections.TasksSection(viewModel: viewModel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.loadData()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(viewModel.isLoading)
            
            Button {
                // Obsługa powiadomień (do rozbudowy)
            } label: {
                Image(systemName: "bell")
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
        }
    }
    
    // MARK: - Modal Contents
    private var weekDetailsModalContent: some View {
        Group {
            if let taskWeek = selectedTaskWeek {
                WeekDetailsModal(
                    taskWeekEntry: taskWeek,
                    isPresented: $showWeekDetailsModal,
                    onApproveWeek: {
                        // Zatwierdzenie całego tygodnia z podpisem
                        showSignatureModal = true
                    },
                    onRejectWeek: { problematicEntryIds, rejectionReason in
                        // Odrzucenie całego tygodnia z oznaczonymi problematycznymi dniami
                        viewModel.rejectTaskWeek(taskWeek, problematicEntryIds: problematicEntryIds, rejectionReason: rejectionReason)
                    }
                )
            }
        }
    }
    
    private var signatureModalContent: some View {
        SignatureModalViewController(
            isPresented: $showSignatureModal,
            content: SignatureModalView(isPresented: $showSignatureModal) { signatureImage in
                if let image = signatureImage, let taskWeek = selectedTaskWeek {
                    self.signatureImage = image
                    self.showSignatureModal = false
                    
                    // Zawsze zatwierdzamy cały tydzień
                    viewModel.approveTaskWeekWithSignature(taskWeek, signatureImage: image) { url in
                        self.timesheetUrl = url
                        self.showReceiptView = url != nil
                    }
                }
            }
        )
    }
    
    private var receiptViewContent: some View {
        Group {
            if let url = timesheetUrl,
               let fileURL = URL(string: url),
               let data = try? Data(contentsOf: fileURL),
               let signature = signatureImage {
                TimesheetReceiptView(entry: nil, timesheetData: data, signatureImage: signature)
                    .onAppear {
                        #if DEBUG
                        print("[ManagerDashboardView] TimesheetReceiptView opened with URL: \(url)")
                        #endif
                    }
            } else {
                VStack {
                    Text("Failed to load PDF")
                        .font(.headline)
                        .foregroundColor(.red)
                    Button("Close") {
                        showReceiptView = false
                        timesheetUrl = nil
                    }
                    .padding()
                    .background(Color.ksrYellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                .onAppear {
                    #if DEBUG
                    print("[ManagerDashboardView] Failed to load PDF")
                    #endif
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleViewAppear() {
        viewModel.viewAppeared()
        hasAppeared = true
        updatePulsingState()
        #if DEBUG
        print("[ManagerDashboardView] View appeared, initial entries count: \(viewModel.allPendingEntriesByTask.count)")
        #endif
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            viewModel.loadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Dashboard Background
    private var dashboardBackground: some View {
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
    
    // MARK: - Navigation Cards Section
    private var navigationCardsSection: some View {
        HStack(spacing: 12) {
            // Work Plans Card
            NavigationLink(destination: ManagerWorkPlansView()) {
                NavigationCard(
                    title: "Work Plans",
                    icon: "calendar.badge.clock",
                    color: Color.ksrInfo,
                    subtitle: "Manage schedules"
                )
            }
            
            // Projects Card
            NavigationLink(destination: ManagerProjectsView()) {
                NavigationCard(
                    title: "Projects",
                    icon: "building.2.fill",
                    color: Color.ksrWarning,
                    subtitle: "View all projects"
                )
            }
            
            // Workers Card
            NavigationLink(destination: ManagerWorkersView()) {
                NavigationCard(
                    title: "Workers",
                    icon: "person.3.fill",
                    color: Color.ksrSuccess,
                    subtitle: "Crane operators"
                )
            }
        }
    }
    
    private func updatePulsingState() {
        let shouldPulse = !viewModel.allPendingEntriesByTask.isEmpty
        if isPulsing != shouldPulse {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = shouldPulse
            }
            #if DEBUG
            print("[ManagerDashboardView] Updated isPulsing to \(isPulsing), entries count: \(viewModel.allPendingEntriesByTask.count)")
            #endif
        }
    }
}

// MARK: - Navigation Card Component
struct NavigationCard: View {
    let title: String
    let icon: String
    let color: Color
    let subtitle: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ManagerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ManagerDashboardView()
                .preferredColorScheme(.light)
            ManagerDashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
