//
//  ManagerDashboardComponents.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 17/05/2025.
//

import SwiftUI

// MARK: - Gradienty i style
struct DashboardStyles {
    static let gradientGreen = LinearGradient(
        colors: [Color(hex: "66bb6a"), Color(hex: "43a047")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientBlue = LinearGradient(
        colors: [Color(hex: "29b6f6"), Color(hex: "0288d1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientOrange = LinearGradient(
        colors: [Color(hex: "ffa726"), Color(hex: "fb8c00")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientPurple = LinearGradient(
        colors: [Color(hex: "9575cd"), Color(hex: "5e35b1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientPending = LinearGradient(
        colors: [Color(hex: "90a4ae"), Color(hex: "546e7a")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Karta podsumowania
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let background: LinearGradient
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            // Ikona w kółku po lewej stronie
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            // Treść po prawej stronie
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.white.opacity(0.9))
                    .lineLimit(1)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(background)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Karta tygodnia
struct WeekCard: View {
    let taskWeekEntry: ManagerDashboardViewModel.TaskWeekEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let totalHours = taskWeekEntry.entries.reduce(0.0) { sum, entry in
            guard let start = entry.start_time, let end = entry.end_time else { return sum }
            let interval = end.timeIntervalSince(start)
            let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
            return sum + max(0, (interval - pauseSeconds) / 3600)
        }

        return VStack(alignment: .leading, spacing: 12) {
            // Nagłówek z tygodniem i rokiem
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ksrYellow)
                
                Text("Week \(taskWeekEntry.weekNumber), \(String(taskWeekEntry.year))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
            }
            
            Divider()
                .padding(.leading, 24)
            
            // Szczegóły (liczba wpisów i godziny)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundColor(Color.ksrYellow)
                        Text("\(taskWeekEntry.entries.count) entries")
                            .font(.subheadline)
                            .foregroundColor(Color.ksrYellow)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(Color.ksrYellow)
                        Text("Total: \(totalHours, specifier: "%.2f")h")
                            .font(.subheadline)
                            .foregroundColor(Color.ksrYellow)
                    }
                    
                    if taskWeekEntry.totalKm > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "car")
                                .font(.caption)
                                .foregroundColor(Color.ksrYellow)
                            Text("Distance: \(taskWeekEntry.totalKm, specifier: "%.2f") km")
                                .font(.subheadline)
                                .foregroundColor(Color.ksrYellow)
                        }
                    }
                }
                Spacer()
                // Ikona wskazująca klikalność
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ksrYellow)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.ksrYellow.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle()) // Zapewnia, że cała karta jest klikalna
    }
}

// MARK: - Karta zadania
struct TaskCard: View {
    let task: ManagerAPIService.Task
    let pendingEntriesByTask: [ManagerDashboardViewModel.TaskWeekEntry]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Nagłówek z ikonką
            HStack(spacing: 12) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.ksrYellow)
                    .frame(width: 30, height: 30)
                    .background(Color.ksrYellow.opacity(0.2))
                    .cornerRadius(8)
                
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                
                Spacer()
                
                let pendingEntries = pendingEntriesByTask
                    .filter { $0.taskId == task.task_id }
                    .flatMap { $0.entries }
                    .count
                
                HStack(spacing: 4) {
                    Text("\(pendingEntries) pending")
                        .font(.caption)
                        .foregroundColor(pendingEntries > 0 ? Color.ksrYellow : .gray)
                    
                    Image(systemName: pendingEntries > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(pendingEntries > 0 ? Color.ksrYellow : .green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.leading, 58)
            
            // Informacje o zadaniu
            VStack(alignment: .leading, spacing: 8) {
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        .lineLimit(2)
                }
                
                HStack {
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Project: \(project.title)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let deadline = task.deadlineDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(deadline, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                let taskEntries = pendingEntriesByTask
                    .filter { $0.taskId == task.task_id }
                    .flatMap { $0.entries }
                let totalHours = taskEntries.reduce(0.0) { sum, entry in
                    guard let start = entry.start_time, let end = entry.end_time else { return sum }
                    let interval = end.timeIntervalSince(start)
                    let pauseSeconds = Double(entry.pause_minutes ?? 0) * 60
                    return sum + max(0, (interval - pauseSeconds) / 3600)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                    Text("Total Pending Hours: \(totalHours, specifier: "%.2f")h")
                        .font(.caption)
                        .foregroundColor(Color.ksrYellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 2, x: 0, y: 1)
    }
}
