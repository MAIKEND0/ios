//
//  WeeklyWorkEntryForm.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct WeeklyWorkEntryForm: View {
    @StateObject private var viewModel: WeeklyWorkEntryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(employeeId: String, taskId: String, selectedMonday: Date) {
        _viewModel = StateObject(wrappedValue: WeeklyWorkEntryViewModel(
            employeeId: employeeId,
            taskId: taskId,
            selectedMonday: selectedMonday
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.ksrLightGray.opacity(0.3).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Ostrzeżenie o przyszłym tygodniu jeśli potrzebne
                        if viewModel.isFutureWeek {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Nie możesz logować godzin dla przyszłego tygodnia")
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.yellow.opacity(0.3))
                            .cornerRadius(10)
                        }
                        
                        // Karty dni tygodnia
                        ForEach(Array(viewModel.weekData.enumerated()), id: \.element.id) { index, entry in
                            dayCard(for: entry, at: index)
                                .padding(.horizontal)
                        }
                        
                        // Podsumowanie
                        VStack(alignment: .leading) {
                            Text("Całkowity czas: \(viewModel.totalWeeklyHours, specifier: "%.2f") godzin")
                                .font(.headline)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Przyciski akcji
                        HStack {
                            Button(action: {
                                viewModel.isReviewShowing = true
                            }) {
                                Text("Podgląd i Prześlij")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.ksrYellow)
                                    .cornerRadius(10)
                            }
                            .disabled(viewModel.isFutureWeek || viewModel.hasInvalidTime)
                            
                            Button(action: {
                                viewModel.saveDraft()
                            }) {
                                Text("Zapisz Wersję Roboczą")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.ksrYellow, lineWidth: 2)
                                    )
                            }
                            .disabled(viewModel.isFutureWeek)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Loading indicator
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationTitle("Logowanie godzin")
            .navigationBarItems(leading: Button("Powrót") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $viewModel.isReviewShowing) {
                reviewView()
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
    
    // Karta dnia
    private func dayCard(for entry: WorkHourEntry, at index: Int) -> some View {
        VStack(spacing: 0) {
            // Nagłówek karty
            HStack {
                Text("\(entry.dayOfWeek) - \(viewModel.formatDate(entry.date))")
                    .font(.headline)
                Spacer()
                
                if entry.totalHours > 0 {
                    Text(entry.formattedTotalHours)
                        .font(.subheadline)
                        .foregroundColor(Color.ksrYellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.ksrLightGray)
            .cornerRadius(10, corners: [.topLeft, .topRight])
            
            // Zawartość karty
            VStack(spacing: 12) {
                if viewModel.isFutureDay(entry.date) {
                    // Informacja o przyszłym dniu
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                        Text("Nie można logować godzin dla przyszłych dat")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding()
                } else {
                    // Przyciski kopiuj/wklej
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            viewModel.copyEntry(at: index)
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Kopiuj")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.ksrLightGray)
                            .cornerRadius(4)
                        }
                        
                        Button(action: {
                            viewModel.pasteEntry(to: index)
                        }) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Wklej")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.ksrLightGray)
                            .cornerRadius(4)
                        }
                        .disabled(viewModel.copiedEntry == nil)
                    }
                    .padding(.horizontal)
                    
                    // Pola godzin
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Czas rozpoczęcia")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { entry.startTime ?? Date() },
                                    set: { viewModel.updateEntry(at: index, field: "startTime", value: $0) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Czas zakończenia")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { entry.endTime ?? Date() },
                                    set: { viewModel.updateEntry(at: index, field: "endTime", value: $0) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Pole przerwy
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Przerwa (minuty)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Picker("", selection: Binding(
                                get: { entry.pauseMinutes },
                                set: { viewModel.updateEntry(at: index, field: "pauseMinutes", value: $0) }
                            )) {
                                ForEach(0..<61) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 80)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Pole opisu
                    VStack(alignment: .leading) {
                        Text("Opis")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("Wprowadź opis wykonanej pracy...", text: Binding(
                            get: { entry.description ?? "" },
                            set: { viewModel.updateEntry(at: index, field: "description", value: $0) }
                        ))
                        .padding(8)
                        .background(Color.ksrLightGray.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // Widok podsumowania
    private func reviewView() -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Nagłówek
                    Text("Całkowity czas: \(viewModel.totalWeeklyHours, specifier: "%.2f") godzin")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.ksrLightGray)
                        .cornerRadius(10)
                    
                    // Lista wpisów
                    ForEach(viewModel.weekData.filter { $0.totalHours > 0 }) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(entry.dayOfWeek) - \(viewModel.formatDate(entry.date))")
                                .font(.headline)
                            
                            HStack {
                                Text("Start: \(viewModel.formatTime(entry.startTime))")
                                Spacer()
                                Text("Koniec: \(viewModel.formatTime(entry.endTime))")
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Text("Przerwa: \(entry.pauseMinutes) min")
                                Spacer()
                                Text("Razem: \(entry.formattedTotalHours)")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            
                            if let description = entry.description, !description.isEmpty {
                                Text("Opis: \(description)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    
                    // Przycisk zatwierdzenia
                    Button(action: {
                        viewModel.submitEntries()
                    }) {
                        Text("Zatwierdź i Prześlij")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.ksrYellow)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Podgląd wpisów")
            .navigationBarItems(trailing: Button("Anuluj") {
                viewModel.isReviewShowing = false
            })
        }
    }
}

// Helper do zaokrąglenia tylko niektórych rogów
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
