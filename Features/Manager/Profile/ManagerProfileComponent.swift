// ManagerProfileComponent.swift
import SwiftUI

struct StatusIndicatorRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}

struct PersonalInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct ProfessionalInfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.ksrYellow)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct RateInfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.ksrSuccess)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ksrSuccess)
            }
            
            Spacer()
        }
    }
}

struct ManagementOverviewRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.ksrYellow)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct TeamStatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
    }
}

struct TeamPerformanceRow: View {
    let metric: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isPositive ? .ksrSuccess : .ksrError)
                
                Text(trend)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositive ? .ksrSuccess : .ksrError)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill((isPositive ? Color.ksrSuccess : Color.ksrError).opacity(0.1))
            )
        }
    }
}

struct AppInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let hasArrow: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.ksrYellow)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 🔥 ZMIENIONA NAZWA: ExternalCertificationCard -> CertificationCard
struct CertificationCard: View {
    let certification: ManagerCertification  // 🔥 ZMIENIONY TYP
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "award.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.ksrYellow)
                
                Spacer()
                
                statusIndicator
            }
            
            Text(certification.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .lineLimit(2)
            
            Text(certification.issuingOrganization)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let expiry = certification.expiryDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("Expires: \(DateFormatter.mediumDate.string(from: expiry))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(certification.statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(certification.statusColor)
            .frame(width: 8, height: 8)
    }
}

struct ContractInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ProfileTabButton: View {
    let tab: ManagerProfileView.ProfileTab
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? tab.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsTabContent: View {
    @Binding var showingLogoutConfirmation: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ProfileSectionCard(title: "App Settings", icon: "gearshape.fill", color: .ksrMediumGray) {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsRow(
                        title: "Notifications",
                        icon: "bell.fill",
                        hasArrow: true
                    ) {
                        // Navigate to notifications settings
                    }
                    
                    SettingsRow(
                        title: "Privacy Settings",
                        icon: "hand.raised.fill",
                        hasArrow: true
                    ) {
                        // Navigate to privacy settings
                    }
                    
                    SettingsRow(
                        title: "About App",
                        icon: "info.circle.fill",
                        hasArrow: true
                    ) {
                        // Show about dialog
                    }
                }
            }
            
            ProfileSectionCard(title: "App Information", icon: "info.circle", color: .ksrInfo) {
                VStack(alignment: .leading, spacing: 12) {
                    AppInfoRow(label: "Version", value: "1.0.0")
                    AppInfoRow(label: "Build", value: "2025.05.24")
                    AppInfoRow(label: "Last Updated", value: "May 24, 2025")
                }
            }
            
            ProfileSectionCard(title: "Manager Support", icon: "person.crop.circle.badge.questionmark", color: .ksrWarning) {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsRow(
                        title: "Contract Support",
                        icon: "doc.text.fill",
                        hasArrow: true
                    ) {
                        // Navigate to contract support
                    }
                    
                    SettingsRow(
                        title: "Technical Support",
                        icon: "wrench.and.screwdriver.fill",
                        hasArrow: true
                    ) {
                        // Navigate to technical support
                    }
                    
                    SettingsRow(
                        title: "Report Issue",
                        icon: "exclamationmark.bubble.fill",
                        hasArrow: true
                    ) {
                        // Navigate to issue reporting
                    }
                }
            }
            
            ProfileSectionCard(title: "Account", icon: "person.circle", color: .ksrError) {
                Button(action: {
                    print("Logout button tapped") // Debug
                    showingLogoutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.ksrError)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Logout")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.ksrError)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }
}

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let yearMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

// 🔥 ZMIENIONY PREVIEW - używa nowych nazw
struct ManagerProfileComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StatusIndicatorRow(
                label: "Contract Status",
                value: "Active",
                color: .ksrSuccess
            )
            
            CertificationCard(  // 🔥 ZMIENIONA NAZWA
                certification: ManagerCertification(  // 🔥 ZMIENIONY TYP
                    name: "Project Management Professional",
                    issuingOrganization: "PMI",
                    issueDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()),
                    certificateNumber: "PMP-2023-001"
                )
            )
            
            ContractInfoCard(
                title: "Contract Type",
                value: "Fixed-term Contract",
                icon: "doc.text.fill",
                color: .ksrInfo
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
