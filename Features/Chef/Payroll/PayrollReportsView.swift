//
//  PayrollReportsView.swift
//  KSR Cranes App
//
//  Created by Assistant on 04/06/2025.
//

import SwiftUI

struct PayrollReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Reports overview
                    reportsOverviewSection
                    
                    // Quick report cards
                    quickReportsSection
                    
                    // Custom report builder
                    customReportSection
                    
                    // Recent reports
                    recentReportsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.ksrBackground)
            .navigationTitle("Payroll Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export All") {
                        // TODO: Implement export functionality
                    }
                    .foregroundColor(.ksrPrimary)
                }
            }
        }
    }
    
    // MARK: - Reports Overview
    private var reportsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reports Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ReportStatCard(
                    title: "This Month",
                    value: "245K kr",
                    subtitle: "Total payroll",
                    icon: "banknote.fill",
                    color: .ksrSuccess
                )
                
                ReportStatCard(
                    title: "Employees",
                    value: "23",
                    subtitle: "Active workers",
                    icon: "person.3.fill",
                    color: .ksrInfo
                )
                
                ReportStatCard(
                    title: "Hours",
                    value: "1,847",
                    subtitle: "Total this month",
                    icon: "clock.fill",
                    color: .ksrWarning
                )
                
                ReportStatCard(
                    title: "Batches",
                    value: "8",
                    subtitle: "Processed",
                    icon: "tray.full.fill",
                    color: .ksrPrimary
                )
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Quick Reports
    private var quickReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Reports")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible())
            ], spacing: 12) {
                QuickReportCard(
                    title: "Monthly Payroll Summary",
                    description: "Complete payroll breakdown for current month",
                    icon: "doc.text.fill",
                    color: .ksrPrimary
                ) {
                    // Generate monthly report
                }
                
                QuickReportCard(
                    title: "Employee Hours Report",
                    description: "Detailed hours breakdown by employee",
                    icon: "clock.arrow.circlepath",
                    color: .ksrInfo
                ) {
                    // Generate hours report
                }
                
                QuickReportCard(
                    title: "Project Cost Analysis",
                    description: "Labor costs breakdown by project",
                    icon: "chart.bar.fill",
                    color: .ksrWarning
                ) {
                    // Generate cost analysis
                }
                
                QuickReportCard(
                    title: "Zenegy Sync Report",
                    description: "Integration status and sync history",
                    icon: "arrow.triangle.2.circlepath",
                    color: .ksrSuccess
                ) {
                    // Generate sync report
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Custom Report Builder
    private var customReportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Report Builder")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            VStack(spacing: 12) {
                Text("Create custom reports with specific date ranges, employees, and projects")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button {
                    // Navigate to custom report builder
                } label: {
                    HStack {
                        Image(systemName: "plus.rectangle.on.folder")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Build Custom Report")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.ksrPrimary)
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Recent Reports
    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Reports")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ksrTextPrimary)
            
            VStack(spacing: 0) {
                RecentReportRow(
                    title: "November 2024 Payroll",
                    subtitle: "Generated 2 days ago • 234K kr",
                    icon: "doc.text.fill",
                    date: "Nov 28, 2024"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                
                RecentReportRow(
                    title: "Employee Hours Analysis",
                    subtitle: "Generated 1 week ago • 23 employees",
                    icon: "clock.fill",
                    date: "Nov 21, 2024"
                )
                
                Divider()
                    .padding(.horizontal, 16)
                
                RecentReportRow(
                    title: "Project Cost Breakdown",
                    subtitle: "Generated 2 weeks ago • 12 projects",
                    icon: "chart.bar.fill",
                    date: "Nov 14, 2024"
                )
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    // MARK: - Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Report Stat Card
struct ReportStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.1))
        )
    }
}

// MARK: - Quick Report Card
struct QuickReportCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ksrTextPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Report Row
struct RecentReportRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let date: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ksrInfo.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.ksrInfo)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ksrTextPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Button("Download") {
                    // Download report
                }
                .font(.caption2)
                .foregroundColor(.ksrPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
struct PayrollReportsView_Previews: PreviewProvider {
    static var previews: some View {
        PayrollReportsView()
    }
}
