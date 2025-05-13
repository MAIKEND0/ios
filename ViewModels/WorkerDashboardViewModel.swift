//
//  WorkerDashboardViewModel.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import Foundation
import Combine

class WorkerDashboardViewModel: ObservableObject {
    @Published var workHoursViewModel = WorkHoursViewModel()
    @Published var announcements: [Announcement] = []
    @Published var isLoadingAnnouncements: Bool = false
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Load work hours
        workHoursViewModel.loadWorkHours()
        
        // Load announcements
        loadAnnouncements()
    }
    
    func loadAnnouncements() {
        isLoadingAnnouncements = true
        
        // Example announcements
        announcements = Announcement.examples
        isLoadingAnnouncements = false
        
        // In a real app, this would be a network call
    }
}
