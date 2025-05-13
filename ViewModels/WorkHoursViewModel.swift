//
//  WorkHoursViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//
import Foundation
import Combine
import SwiftUI

class WorkHoursViewModel: ObservableObject {
    @Published var workHourEntries: [WorkHourEntry] = []
    @Published var isLoading: Bool = false
    
    init() {
        // Load sample data
    }
    
    func loadWorkHours() {
        isLoading = true
        
        // Create some example entries
        let calendar = Calendar.current
        let today = Date()
        
        let entry1 = WorkHourEntry.example
        
        var entry2 = WorkHourEntry.example
        entry2.id = "2"
        entry2.date = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        entry2.startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: entry2.date) ?? entry2.date
        entry2.endTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: entry2.date) ?? entry2.date
        entry2.description = "Crane inspection"
        
        workHourEntries = [entry1, entry2]
        isLoading = false
        
        // In a real app, this would be a network call
    }
}
