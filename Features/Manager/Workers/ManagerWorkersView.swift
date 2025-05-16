//
//  ManagerWorkersView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import SwiftUI

struct ManagerWorkersView: View {
    @StateObject private var viewModel = ManagerWorkersViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Sekcja listy pracowników
                    workersSection
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Assigned Workers")
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
    
    private var workersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workers")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if viewModel.workers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.largeTitle)
                        .foregroundColor(Color.gray)
                    Text("No assigned workers")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                    Text("No workers are assigned to your supervised tasks.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.workers) { worker in
                        workerCard(worker: worker)
                    }
                }
            }
        }
    }
    
    private func workerCard(worker: ManagerAPIService.Worker) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(worker.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                Spacer()
                Text("ID: \(worker.employee_id)")
                    .font(.caption)
                    .foregroundColor(Color.ksrYellow)
            }
            if let email = worker.email {
                Text("Email: \(email)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
            }
            if let phone = worker.phone_number {
                Text("Phone: \(phone)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
            }
            Text("Assigned Tasks: \(worker.assignedTasks.map { $0.title }.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
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
