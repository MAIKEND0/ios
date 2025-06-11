import SwiftUI

struct SyncStatusBadge: View {
    let status: SyncStatus
    let pendingChanges: Int
    @State private var isAnimating = false
    
    enum SyncStatus {
        case synced
        case syncing
        case pending
        case error
        case offline
        
        var color: Color {
            switch self {
            case .synced: return .ksrSuccess
            case .syncing: return .ksrInfo
            case .pending: return .ksrWarning
            case .error: return .ksrError
            case .offline: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .synced: return "checkmark.circle.fill"
            case .syncing: return "arrow.triangle.2.circlepath"
            case .pending: return "clock.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .offline: return "wifi.slash"
            }
        }
        
        var text: String {
            switch self {
            case .synced: return "Synced"
            case .syncing: return "Syncing"
            case .pending: return "Pending"
            case .error: return "Error"
            case .offline: return "Offline"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .rotationEffect(status == .syncing ? .degrees(isAnimating ? 360 : 0) : .degrees(0))
                .animation(
                    status == .syncing ?
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false) :
                    .default,
                    value: isAnimating
                )
            
            Text(status.text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            
            if pendingChanges > 0 && status != .synced {
                Text("(\(pendingChanges))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color)
                .shadow(color: status.color.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            if status == .syncing {
                isAnimating = true
            }
        }
        .onChange(of: status) { newStatus in
            if newStatus == .syncing {
                isAnimating = true
            } else {
                isAnimating = false
            }
        }
    }
}

// Preview
struct SyncStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncStatusBadge(status: .synced, pendingChanges: 0)
            SyncStatusBadge(status: .syncing, pendingChanges: 3)
            SyncStatusBadge(status: .pending, pendingChanges: 5)
            SyncStatusBadge(status: .error, pendingChanges: 2)
            SyncStatusBadge(status: .offline, pendingChanges: 7)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}