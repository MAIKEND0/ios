//
//  ManagerDashboardView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 16/05/2025.
//

import SwiftUI
import PDFKit

struct ManagerDashboardView: View {
    @StateObject private var viewModel = ManagerDashboardViewModel()
    @State private var showFilterOptions = false
    @State private var searchText = ""
    @State private var hasAppeared = false
    @State private var showSignatureModal = false
    @State private var showReceiptView = false
    @State private var showRejectionReasonModal = false
    @State private var rejectionReason = ""
    @State private var selectedTaskWeek: ManagerDashboardViewModel.TaskWeekEntry?
    @State private var selectedEntry: ManagerAPIService.WorkHourEntry?
    @State private var timesheetUrl: String?
    @State private var signatureImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isRejectionReasonFocused: Bool
    @State private var isPulsing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ManagerDashboardSections.PendingTasksSection(
                        viewModel: viewModel,
                        onSelectTaskWeek: { taskWeek in
                            selectedTaskWeek = taskWeek
                            showSignatureModal = true
                        },
                        onSelectEntry: { entry in
                            selectedEntry = entry
                            showRejectionReasonModal = true
                        }
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(isPulsing ? 0.5 : 0.2))
                            .shadow(color: isPulsing ? Color.green.opacity(0.6) : .clear, radius: isPulsing ? 8 : 0)
                            .scaleEffect(isPulsing ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                    )
                    .onAppear {
                        updatePulsingState()
                    }
                    .onChange(of: viewModel.allPendingEntriesByTask) { _, newValue in
                        updatePulsingState()
                        #if DEBUG
                        print("[ManagerDashboardView] allPendingEntriesByTask changed, count: \(newValue.count), isPulsing: \(isPulsing)")
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

                    ManagerDashboardSections.SummaryCardsSection(viewModel: viewModel)
                    ManagerDashboardSections.WeekSelectorSection(viewModel: viewModel)
                    ManagerDashboardSections.TasksSection(viewModel: viewModel)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Manager Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Obsługa powiadomień (do rozbudowy)
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showFilterOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                    }
                }
            }
            .onAppear {
                viewModel.viewAppeared()
                hasAppeared = true
                #if DEBUG
                print("[ManagerDashboardView] View appeared, initial entries count: \(viewModel.allPendingEntriesByTask.count)")
                #endif
            }
            .onDisappear {
                viewModel.viewDisappeared()
            }
            .onChange(of: hasAppeared) { newValue, _ in
                if newValue {
                    viewModel.loadData()
                }
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.loadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .fullScreenCover(isPresented: $showSignatureModal) {
                SignatureModalViewController(
                    isPresented: $showSignatureModal,
                    content: SignatureModalView(isPresented: $showSignatureModal) { signatureImage in
                        if let taskWeek = selectedTaskWeek, let image = signatureImage {
                            self.signatureImage = image
                            self.showSignatureModal = false
                            viewModel.approveTaskWeekWithSignature(taskWeek, signatureImage: image) { url in
                                self.timesheetUrl = url
                                #if DEBUG
                                print("[ManagerDashboardView] Timesheet URL: \(url ?? "nil")")
                                #endif
                                self.showReceiptView = url != nil
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showReceiptView) {
                if let url = timesheetUrl, let fileURL = URL(string: url), let data = try? Data(contentsOf: fileURL), let signature = signatureImage {
                    TimesheetReceiptView(entry: selectedEntry, timesheetData: data, signatureImage: signature)
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
            .sheet(isPresented: $showRejectionReasonModal) {
                VStack(spacing: 20) {
                    Text("Reason for Rejection")
                        .font(.headline)
                    TextEditor(text: $rejectionReason)
                        .frame(height: 100)
                        .border(Color.gray, width: 1)
                        .padding()
                        .focused($isRejectionReasonFocused)
                        .keyboardType(.default)
                        .autocapitalization(.sentences)
                        .disableAutocorrection(true)
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            showRejectionReasonModal = false
                            rejectionReason = ""
                            isRejectionReasonFocused = false
                        }
                        .foregroundColor(.red)
                        Button("Submit") {
                            if let entry = selectedEntry {
                                viewModel.rejectEntry(entry, rejectionReason: rejectionReason)
                                showRejectionReasonModal = false
                                rejectionReason = ""
                                isRejectionReasonFocused = false
                            }
                        }
                        .disabled(rejectionReason.isEmpty)
                    }
                }
                .padding()
                .onAppear {
                    isRejectionReasonFocused = true
                }
            }
        }
    }
    
    private func updatePulsingState() {
        let shouldPulse = !viewModel.allPendingEntriesByTask.isEmpty
        if isPulsing != shouldPulse {
            isPulsing = shouldPulse
            #if DEBUG
            print("[ManagerDashboardView] Updated isPulsing to \(isPulsing), entries count: \(viewModel.allPendingEntriesByTask.count)")
            #endif
        }
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
