// UI/Views/Worker/WorkerWorkHoursView.swift
// KSR Cranes App
//
// Created by Maksymilian Marcinowski on 14/05/2025.
//

import SwiftUI

struct WorkerWorkHoursView: View {
    @StateObject private var vm = WorkerWorkHoursViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Nawigacja między tygodniami ---
                HStack {
                    Button { vm.previousWeek() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    Spacer()
                    Text(DateFormatter.weekHeader.string(from: vm.weekStart))
                        .font(.headline)
                    Spacer()
                    Button { vm.nextWeek() } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                }
                .padding()

                Divider()

                // --- Zawartość ---
                Group {
                    if vm.isLoading {
                        ProgressView("Ładowanie…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else if let err = vm.error {
                        Text(err)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else if vm.entries.isEmpty {
                        Text("Brak wpisów w tym tygodniu")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else {
                        List(vm.entries) { entry in
                            HStack {
                                Text(entry.workDateFormatted)
                                Spacer()
                                Text("\(entry.startTimeFormatted ?? "-")–\(entry.endTimeFormatted ?? "-")")
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                        .refreshable {
                            vm.loadEntries()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Godziny pracy")
            .onAppear { vm.loadEntries() }
        }
    }
}

struct WorkerWorkHoursView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerWorkHoursView()
            .preferredColorScheme(.light)
    }
}

// Tylko nagłówek tygodnia – resztę bierzesz z DateFormatter+ISO.swift
private extension DateFormatter {
    /// “Tydz. 23 (10.05.2025)”
    static let weekHeader: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "'Tydz.' W (dd.MM.yyyy)"
        return df
    }()
}
