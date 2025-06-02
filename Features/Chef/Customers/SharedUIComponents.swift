//
//  SharedUIComponents.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import SwiftUI

// MARK: - Date Formatter Extensions
extension DateFormatter {
    static let customerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Customer-Specific Row Components

struct CustomerProjectRow: View {
    let project: ProjectDetail
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let status = project.status {
                        Text(status.capitalized)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(statusColor.opacity(0.2))
                            )
                    }
                    
                    if let startDate = project.start_date {
                        Text(DateFormatter.customerDateFormatter.string(from: startDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch project.status?.lowercased() {
        case "aktiv": return Color.ksrSuccess
        case "afsluttet": return Color.ksrInfo
        case "afventer": return Color.ksrWarning
        default: return Color.ksrPrimary
        }
    }
}

struct CustomerHiringRequestRow: View {
    let request: HiringRequestSummary
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.projectName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(request.status.capitalized)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.2))
                        )
                    
                    Text(DateFormatter.customerDateFormatter.string(from: request.startDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch request.status.lowercased() {
        case "approved": return Color.ksrSuccess
        case "pending": return Color.ksrWarning
        case "rejected": return Color.red
        case "completed": return Color.ksrInfo
        default: return Color.ksrPrimary
        }
    }
}
