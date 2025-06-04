//
//  TimePeriodNavigation.swift
//  KSR Cranes App
//
//  System nawigacji po okresach czasowych dla Dashboard
//

import Foundation
import SwiftUI

// MARK: - Time Period Types
enum TimePeriodType: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case twoWeeks = "14 Days"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .week: return "calendar.day.timeline.left"
        case .month: return "calendar"
        case .twoWeeks: return "calendar.badge.clock"
        case .custom: return "calendar.badge.plus"
        }
    }
    
    var shortName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .twoWeeks: return "14D"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Time Period Model
struct TimePeriod {
    let type: TimePeriodType
    let startDate: Date
    let endDate: Date
    let referenceDate: Date // For navigation
    
    var displayName: String {
        let formatter = DateFormatter()
        
        switch type {
        case .week:
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
            
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: referenceDate)
            
        case .twoWeeks:
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
            
        case .custom:
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
        }
    }
    
    var shortDisplayName: String {
        let formatter = DateFormatter()
        
        switch type {
        case .week:
            formatter.dateFormat = "MMM d"
            return formatter.string(from: startDate)
            
        case .month:
            formatter.dateFormat = "MMM"
            return formatter.string(from: referenceDate)
            
        case .twoWeeks:
            formatter.dateFormat = "MMM d"
            return formatter.string(from: startDate)
            
        case .custom:
            return "Custom"
        }
    }
    
    // Check if date falls within this period
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        let startOnly = calendar.startOfDay(for: startDate)
        let endOnly = calendar.startOfDay(for: endDate)
        
        return dateOnly >= startOnly && dateOnly <= endOnly
    }
}

// MARK: - Time Period Manager
class TimePeriodManager: ObservableObject {
    @Published var currentPeriod: TimePeriod
    @Published var selectedType: TimePeriodType = .month
    @Published var availablePeriods: [TimePeriod] = []
    
    private let calendar = Calendar.current
    
    init(initialDate: Date = Date()) {
        self.currentPeriod = TimePeriodManager.createPeriod(type: .month, referenceDate: initialDate)
        self.generateAvailablePeriods(around: initialDate)
    }
    
    // MARK: - Period Creation
    static func createPeriod(type: TimePeriodType, referenceDate: Date) -> TimePeriod {
        let calendar = Calendar.current
        
        switch type {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? referenceDate
            return TimePeriod(type: type, startDate: startOfWeek, endDate: endOfWeek, referenceDate: referenceDate)
            
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? referenceDate
            return TimePeriod(type: type, startDate: startOfMonth, endDate: endOfMonth, referenceDate: referenceDate)
            
        case .twoWeeks:
            // Start from Monday of current week, extend 14 days
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
            let endDate = calendar.date(byAdding: .day, value: 13, to: startOfWeek) ?? referenceDate
            return TimePeriod(type: type, startDate: startOfWeek, endDate: endDate, referenceDate: referenceDate)
            
        case .custom:
            // Default to current month for custom
            return createPeriod(type: .month, referenceDate: referenceDate)
        }
    }
    
    // MARK: - Navigation
    func navigateToPrevious() {
        let newReferenceDate: Date
        
        switch selectedType {
        case .week:
            newReferenceDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .month:
            newReferenceDate = calendar.date(byAdding: .month, value: -1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .twoWeeks:
            newReferenceDate = calendar.date(byAdding: .day, value: -14, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .custom:
            newReferenceDate = calendar.date(byAdding: .month, value: -1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        }
        
        currentPeriod = TimePeriodManager.createPeriod(type: selectedType, referenceDate: newReferenceDate)
        generateAvailablePeriods(around: newReferenceDate)
    }
    
    func navigateToNext() {
        let newReferenceDate: Date
        
        switch selectedType {
        case .week:
            newReferenceDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .month:
            newReferenceDate = calendar.date(byAdding: .month, value: 1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .twoWeeks:
            newReferenceDate = calendar.date(byAdding: .day, value: 14, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        case .custom:
            newReferenceDate = calendar.date(byAdding: .month, value: 1, to: currentPeriod.referenceDate) ?? currentPeriod.referenceDate
        }
        
        currentPeriod = TimePeriodManager.createPeriod(type: selectedType, referenceDate: newReferenceDate)
        generateAvailablePeriods(around: newReferenceDate)
    }
    
    func navigateToToday() {
        let today = Date()
        currentPeriod = TimePeriodManager.createPeriod(type: selectedType, referenceDate: today)
        generateAvailablePeriods(around: today)
    }
    
    func changePeriodType(to newType: TimePeriodType) {
        selectedType = newType
        currentPeriod = TimePeriodManager.createPeriod(type: newType, referenceDate: currentPeriod.referenceDate)
        generateAvailablePeriods(around: currentPeriod.referenceDate)
    }
    
    func selectPeriod(_ period: TimePeriod) {
        currentPeriod = period
        selectedType = period.type
    }
    
    // MARK: - Available Periods Generation
    private func generateAvailablePeriods(around referenceDate: Date) {
        var periods: [TimePeriod] = []
        
        // Generate 6 months worth of periods (3 before, current, 2 after)
        for i in -3...2 {
            let date: Date
            
            switch selectedType {
            case .week:
                date = calendar.date(byAdding: .weekOfYear, value: i, to: referenceDate) ?? referenceDate
            case .month:
                date = calendar.date(byAdding: .month, value: i, to: referenceDate) ?? referenceDate
            case .twoWeeks:
                date = calendar.date(byAdding: .day, value: i * 14, to: referenceDate) ?? referenceDate
            case .custom:
                date = calendar.date(byAdding: .month, value: i, to: referenceDate) ?? referenceDate
            }
            
            periods.append(TimePeriodManager.createPeriod(type: selectedType, referenceDate: date))
        }
        
        availablePeriods = periods
    }
    
    // MARK: - Utility Methods
    var isCurrentPeriod: Bool {
        let today = Date()
        return currentPeriod.contains(today)
    }
    
    var canNavigateNext: Bool {
        let today = Date()
        return currentPeriod.endDate < today || isCurrentPeriod
    }
    
    func findBestPeriodForData(_ entries: [WorkerAPIService.WorkHourEntry]) -> TimePeriod? {
        guard !entries.isEmpty else { return nil }
        
        // Find the most recent entry
        let sortedEntries = entries.sorted { $0.work_date > $1.work_date }
        guard let latestEntry = sortedEntries.first else { return nil }
        
        // Create period around the latest entry
        return TimePeriodManager.createPeriod(type: selectedType, referenceDate: latestEntry.work_date)
    }
    
    func getEntriesForCurrentPeriod(_ entries: [WorkerAPIService.WorkHourEntry]) -> [WorkerAPIService.WorkHourEntry] {
        return entries.filter { currentPeriod.contains($0.work_date) }
    }
    
    func getStatsForCurrentPeriod(_ entries: [WorkerAPIService.WorkHourEntry]) -> (hours: Double, km: Double, entryCount: Int) {
        let periodEntries = getEntriesForCurrentPeriod(entries)
        
        let totalHours = periodEntries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }
        
        let totalKm = periodEntries.reduce(0.0) { sum, entry in
            return sum + (entry.km ?? 0.0)
        }
        
        return (hours: totalHours, km: totalKm, entryCount: periodEntries.count)
    }
}

// MARK: - Time Period Navigation View
struct TimePeriodNavigationView: View {
    @ObservedObject var periodManager: TimePeriodManager
    @State private var showingPeriodPicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Period Type Selector
            HStack(spacing: 8) {
                ForEach(TimePeriodType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            periodManager.changePeriodType(to: type)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text(type.shortName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(periodManager.selectedType == type ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(periodManager.selectedType == type ? Color.blue : Color.gray.opacity(0.2))
                        )
                    }
                }
            }
            
            // Navigation Controls
            HStack {
                // Previous button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        periodManager.navigateToPrevious()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                
                Spacer()
                
                // Current period display + picker
                Button {
                    showingPeriodPicker = true
                } label: {
                    VStack(spacing: 2) {
                        Text(periodManager.currentPeriod.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if periodManager.isCurrentPeriod {
                            Text("Current")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Next button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        periodManager.navigateToNext()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(periodManager.canNavigateNext ? .blue : .gray)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                .disabled(!periodManager.canNavigateNext)
                
                // Today button
                if !periodManager.isCurrentPeriod {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            periodManager.navigateToToday()
                        }
                    } label: {
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .sheet(isPresented: $showingPeriodPicker) {
            PeriodPickerView(periodManager: periodManager)
        }
    }
}

// MARK: - Period Picker View
struct PeriodPickerView: View {
    @ObservedObject var periodManager: TimePeriodManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Select") {
                    ForEach(periodManager.availablePeriods, id: \.startDate) { period in
                        Button {
                            periodManager.selectPeriod(period)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(period.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(period.type.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if period.startDate == periodManager.currentPeriod.startDate {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Smart Period Suggestion View
struct SmartPeriodSuggestionView: View {
    let entries: [WorkerAPIService.WorkHourEntry]
    let periodManager: TimePeriodManager
    
    private var suggestedPeriod: TimePeriod? {
        return periodManager.findBestPeriodForData(entries)
    }
    
    var body: some View {
        if let suggested = suggestedPeriod,
           suggested.startDate != periodManager.currentPeriod.startDate,
           !entries.isEmpty {
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    periodManager.selectPeriod(suggested)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    
                    Text("Show period with data (\(suggested.shortDisplayName))")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
