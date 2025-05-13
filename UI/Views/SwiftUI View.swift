//
//  SwiftUI View.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct WorkHoursView: View {
    @StateObject private var viewModel = WorkHoursViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.workHourEntries.isEmpty {
                    Text("No work hours found")
                        .foregroundColor(Color.ksrMediumGray)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.workHourEntries) { entry in
                            workHourCard(entry: entry)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Work Hours")
            .onAppear {
                viewModel.loadWorkHours()
            }
        }
    }
    
    func workHourCard(entry: WorkHourEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(entry.date))
                    .font(.headline)
                    .foregroundColor(Color.ksrDarkGray)
                
                Spacer()
                
                Text(entry.formattedTotalHours)
                    .font(.headline)
                    .foregroundColor(Color.ksrYellow)
            }
            
            HStack {
                Text("\(formatTime(entry.startTime)) - \(formatTime(entry.endTime))")
                    .font(.subheadline)
                    .foregroundColor(Color.ksrMediumGray)
                
                Spacer()
                
                Text("Project ID: \(entry.projectId)")
                    .font(.caption)
                    .foregroundColor(Color.ksrMediumGray)
            }
            
            if let description = entry.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color.ksrDarkGray)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.ksrLightGray)
        .cornerRadius(10)
    }
    
    // Helper functions
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WorkHoursView_Previews: PreviewProvider {
    static var previews: some View {
        WorkHoursView()
    }
}
