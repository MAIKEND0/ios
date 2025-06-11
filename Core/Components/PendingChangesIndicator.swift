import SwiftUI

struct PendingChangesIndicator: View {
    let count: Int
    let lastSyncTime: Date?
    let style: Style
    
    @State private var isPulsing = false
    @Environment(\.colorScheme) var colorScheme
    
    enum Style {
        case badge
        case card
        case minimal
    }
    
    init(count: Int, lastSyncTime: Date? = nil, style: Style = .badge) {
        self.count = count
        self.lastSyncTime = lastSyncTime
        self.style = style
    }
    
    var timeSinceSync: String? {
        guard let lastSyncTime = lastSyncTime else { return nil }
        let interval = Date().timeIntervalSince(lastSyncTime)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    var body: some View {
        switch style {
        case .badge:
            badgeView
        case .card:
            cardView
        case .minimal:
            minimalView
        }
    }
    
    private var badgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(count > 0 ? .white : .secondary)
            
            Text("\(count) pending")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(count > 0 ? .white : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(count > 0 ? Color.ksrWarning : Color.gray.opacity(0.2))
                .shadow(color: count > 0 ? Color.ksrWarning.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPulsing && count > 0 ? 1.05 : 1.0)
        .animation(
            count > 0 ?
            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) :
            .default,
            value: isPulsing
        )
        .onAppear {
            if count > 0 {
                isPulsing = true
            }
        }
        .onChange(of: count) { newCount in
            isPulsing = newCount > 0
        }
    }
    
    private var cardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pending Changes")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let timeSinceSync = timeSinceSync {
                        Text("Last synced \(timeSinceSync)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(count > 0 ? Color.ksrWarning : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("\(count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(count > 0 ? .white : .secondary)
                }
            }
            
            if count > 0 {
                Text("Changes will sync when connection is restored")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    private var minimalView: some View {
        Group {
            if count > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.ksrWarning)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.ksrWarning.opacity(0.3), lineWidth: 2)
                                .scaleEffect(isPulsing ? 2 : 1)
                                .opacity(isPulsing ? 0 : 1)
                                .animation(
                                    Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                    value: isPulsing
                                )
                        )
                    
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.ksrWarning)
                }
                .onAppear {
                    isPulsing = true
                }
            }
        }
    }
}

// Toolbar item modifier
struct PendingChangesToolbarModifier: ViewModifier {
    let pendingCount: Int
    let lastSyncTime: Date?
    @State private var showingDetails = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetails = true }) {
                        PendingChangesIndicator(count: pendingCount, style: .minimal)
                    }
                    .disabled(pendingCount == 0)
                }
            }
            .sheet(isPresented: $showingDetails) {
                PendingChangesDetailSheet(
                    pendingCount: pendingCount,
                    lastSyncTime: lastSyncTime,
                    isPresented: $showingDetails
                )
            }
    }
}

// Detail sheet for pending changes
struct PendingChangesDetailSheet: View {
    let pendingCount: Int
    let lastSyncTime: Date?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                PendingChangesIndicator(
                    count: pendingCount,
                    lastSyncTime: lastSyncTime,
                    style: .card
                )
                
                VStack(alignment: .leading, spacing: 16) {
                    Label("Changes are saved locally", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.green)
                    
                    Label("Will sync when online", systemImage: "wifi")
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                    
                    Label("No data will be lost", systemImage: "lock.shield.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.purple)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pending Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    func pendingChangesToolbar(pendingCount: Int, lastSyncTime: Date? = nil) -> some View {
        modifier(PendingChangesToolbarModifier(pendingCount: pendingCount, lastSyncTime: lastSyncTime))
    }
}

// Preview
struct PendingChangesIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PendingChangesIndicator(count: 5, style: .badge)
            PendingChangesIndicator(count: 0, style: .badge)
            PendingChangesIndicator(count: 3, lastSyncTime: Date().addingTimeInterval(-3600), style: .card)
            PendingChangesIndicator(count: 2, style: .minimal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}