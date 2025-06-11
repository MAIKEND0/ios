//
//  LeaveRequestFiltersView.swift
//  KSR Cranes App
//
//  Filter interface for leave requests
//

import SwiftUI

struct LeaveRequestFiltersView: View {
    @Binding var selectedStatus: LeaveStatus?
    @Binding var selectedType: LeaveType?
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Filter
                LeaveFilterSection(title: "Status") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(LeaveStatus.allCases, id: \.self) { status in
                            LeaveFilterChip(
                                title: status.displayName,
                                isSelected: selectedStatus == status
                            ) {
                                selectedStatus = selectedStatus == status ? nil : status
                            }
                        }
                    }
                }
                
                // Type Filter
                LeaveFilterSection(title: "Type") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(LeaveType.allCases, id: \.self) { type in
                            LeaveFilterChip(
                                title: type.displayName,
                                isSelected: selectedType == type
                            ) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Apply Filters") {
                        onApply()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Clear All Filters") {
                        selectedStatus = nil
                        selectedType = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LeaveFilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
    }
}

struct LeaveFilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Leave Balance Detail View

struct LeaveBalanceDetailView: View {
    let balance: LeaveBalance?
    let publicHolidays: [PublicHoliday]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let balance = balance {
                    // Main Balance Card
                    DetailedBalanceCard(balance: balance)
                    
                    // Carry Over Information
                    if balance.carry_over_days > 0 {
                        CarryOverCard(balance: balance)
                    }
                    
                    // Public Holidays
                    PublicHolidaysCard(holidays: publicHolidays)
                    
                    // Leave Policy Info
                    LeavePolicyInfoCard()
                } else {
                    LeaveEmptyStateView(
                        title: "Ingen saldodata",
                        subtitle: "Kan ikke indlæse orlovssaldo",
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }
            .padding()
        }
    }
}

struct DetailedBalanceCard: View {
    let balance: LeaveBalance
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Detailed Balance")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                BalanceRow(
                    title: "Vacation Total",
                    value: balance.vacation_days_total,
                    color: .blue
                )
                
                BalanceRow(
                    title: "Vacation Used",
                    value: balance.vacation_days_used,
                    color: .red
                )
                
                BalanceRow(
                    title: "Vacation Remaining",
                    value: balance.vacation_days_remaining,
                    color: .green,
                    isHighlighted: true
                )
                
                Divider()
                
                BalanceRow(
                    title: "Personal Days Total",
                    value: balance.personal_days_total,
                    color: .orange
                )
                
                BalanceRow(
                    title: "Personal Days Used",
                    value: balance.personal_days_used,
                    color: .red
                )
                
                BalanceRow(
                    title: "Personal Days Remaining",
                    value: balance.personal_days_remaining,
                    color: .orange,
                    isHighlighted: true
                )
                
                Divider()
                
                BalanceRow(
                    title: "Sick Days Used",
                    value: balance.sick_days_used,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BalanceRow: View {
    let title: String
    let value: Int
    let color: Color
    let isHighlighted: Bool
    
    init(title: String, value: Int, color: Color, isHighlighted: Bool = false) {
        self.title = title
        self.value = value
        self.color = color
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(isHighlighted ? .headline : .subheadline)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value)")
                .font(isHighlighted ? .title2 : .subheadline)
                .fontWeight(isHighlighted ? .bold : .semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, isHighlighted ? 4 : 2)
    }
}

struct CarryOverCard: View {
    let balance: LeaveBalance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.forward.circle")
                    .foregroundColor(.blue)
                Text("Carry Over Days")
                    .font(.headline)
            }
            
            Text("You have \(balance.carry_over_days) day(s) carried over from last year.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let expiryDate = balance.carry_over_expires {
                Text("Expires: \(expiryDate, formatter: DateFormatter.mediumDate)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PublicHolidaysCard: View {
    let holidays: [PublicHoliday]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundColor(.purple)
                Text("Public Holidays")
                    .font(.headline)
            }
            
            if holidays.isEmpty {
                Text("No public holidays found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(holidays) { holiday in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(holiday.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if let description = holiday.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(holiday.date, formatter: DateFormatter.dayMonth)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                
                                Text(holiday.date, formatter: DateFormatter.weekday)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if holiday.id != holidays.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - DateFormatter Extensions for Holidays

extension DateFormatter {
    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}

struct LeavePolicyInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Leave Policy")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                PolicyInfoRow(title: "Vacation", info: "25 days annually (Danish standard)")
                PolicyInfoRow(title: "Notice", info: "Minimum 14 days for vacation")
                PolicyInfoRow(title: "Sick Leave", info: "Unlimited with medical certificate")
                PolicyInfoRow(title: "Personal Days", info: "5 days annually")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PolicyInfoRow: View {
    let title: String
    let info: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(info)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}


#if DEBUG
struct LeaveRequestFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        LeaveRequestFiltersView(
            selectedStatus: .constant(.pending),
            selectedType: .constant(.vacation),
            onApply: {}
        )
    }
}
#endif