import SwiftUI

// Komponent ekranu wyświetlającego godziny pracy pracownika
struct WorkerWorkHoursView: View {
    @StateObject private var viewModel = WorkerWorkHoursViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Nawigacja między tygodniami ---
                HStack {
                    Button { viewModel.previousWeek() } label: {
                        Image(systemName: "chevron.left")
                            .font(Font.title2)
                    }
                    Spacer()
                    Text(formatWeekHeader(viewModel.weekStart))
                        .font(Font.headline)
                    Spacer()
                    Button { viewModel.nextWeek() } label: {
                        Image(systemName: "chevron.right")
                            .font(Font.title2)
                    }
                }
                .padding()

                Divider()

                // --- Zawartość ---
                Group {
                    if viewModel.isLoading {
                        // Poprawione: Używamy ProgressView() bez wartości, aby stworzyć prosty spinner
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                Text("Ładowanie…")
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            )
                    }
                    else if let err = viewModel.errorMessage {  // Poprawione: errorMessage zamiast error
                        Text(err)
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else if viewModel.entries.isEmpty {
                        Text("Brak wpisów w tym tygodniu")
                            .foregroundColor(Color.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else {
                        List(viewModel.entries) { entry in
                            HStack {
                                Text(formatDate(entry.work_date))
                                Spacer()
                                Text("\(entry.startTimeFormatted ?? "-")–\(entry.endTimeFormatted ?? "-")")
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                        .refreshable {
                            viewModel.loadEntries()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Godziny pracy")
            .onAppear { viewModel.loadEntries() }
        }
    }
    
    // Funkcje pomocnicze do formatowania dat
    private func formatWeekHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Tydz.' W (dd.MM.yyyy)"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct WorkerWorkHoursView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerWorkHoursView()
    }
}
