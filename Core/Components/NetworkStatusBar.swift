import SwiftUI
import Network

struct NetworkStatusBar: View {
    @StateObject private var monitor = NetworkStatusMonitor()
    let style: Style
    
    @State private var isExpanded = false
    @State private var showingDetails = false
    @Environment(\.colorScheme) var colorScheme
    
    enum Style {
        case floating
        case inline
        case toolbar
    }
    
    init(style: Style = .floating) {
        self.style = style
    }
    
    var statusColor: Color {
        switch monitor.connectionType {
        case .wifi:
            return .green
        case .cellular:
            return .blue
        case .none:
            return .red
        }
    }
    
    var statusIcon: String {
        switch monitor.connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .none:
            return "wifi.slash"
        }
    }
    
    var statusText: String {
        switch monitor.connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .none:
            return "Offline"
        }
    }
    
    var body: some View {
        switch style {
        case .floating:
            floatingView
        case .inline:
            inlineView
        case .toolbar:
            toolbarView
        }
    }
    
    private var floatingView: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor)
                .animation(.easeInOut, value: monitor.connectionType)
            
            if isExpanded {
                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, isExpanded ? 12 : 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            
            if isExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isExpanded = false
                    }
                }
            }
        }
    }
    
    private var inlineView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .scaleEffect(monitor.connectionType == .none ? 2 : 1)
                        .opacity(monitor.connectionType == .none ? 0 : 1)
                        .animation(
                            monitor.connectionType == .none ?
                            Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false) :
                            .default,
                            value: monitor.connectionType
                        )
                )
            
            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var toolbarView: some View {
        Button(action: { showingDetails = true }) {
            Image(systemName: statusIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(statusColor)
                .animation(.easeInOut, value: monitor.connectionType)
        }
        .sheet(isPresented: $showingDetails) {
            NetworkDetailsSheet(
                connectionType: monitor.connectionType,
                isPresented: $showingDetails
            )
        }
    }
}

// Network monitor class
class NetworkStatusMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    @Published var connectionType: ConnectionType = .none
    
    enum ConnectionType {
        case wifi
        case cellular
        case none
    }
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self?.connectionType = .wifi
                    } else if path.usesInterfaceType(.cellular) {
                        self?.connectionType = .cellular
                    } else {
                        self?.connectionType = .none
                    }
                } else {
                    self?.connectionType = .none
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// Network details sheet
struct NetworkDetailsSheet: View {
    let connectionType: NetworkStatusMonitor.ConnectionType
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Status icon
                Image(systemName: connectionType == .none ? "wifi.slash" : "wifi")
                    .font(.system(size: 60))
                    .foregroundColor(connectionType == .none ? .red : .green)
                    .padding()
                
                // Status text
                VStack(spacing: 8) {
                    Text(connectionType == .none ? "You're Offline" : "Connected")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(statusDescription)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Connection info
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(
                        icon: "network",
                        title: "Connection",
                        value: connectionTypeText
                    )
                    
                    InfoRow(
                        icon: "arrow.up.arrow.down.circle",
                        title: "Data Sync",
                        value: connectionType == .none ? "Paused" : "Active"
                    )
                    
                    InfoRow(
                        icon: "clock",
                        title: "Offline Mode",
                        value: connectionType == .none ? "Enabled" : "Disabled"
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Network Status")
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
    
    private var statusDescription: String {
        switch connectionType {
        case .wifi:
            return "Connected via Wi-Fi. All features available."
        case .cellular:
            return "Connected via cellular. Data usage may apply."
        case .none:
            return "No internet connection. Changes will sync when online."
        }
    }
    
    private var connectionTypeText: String {
        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .none:
            return "No Connection"
        }
    }
}

// Info row component
private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// View modifiers for easy integration
struct NetworkStatusModifier: ViewModifier {
    let style: NetworkStatusBar.Style
    let position: Position
    
    enum Position {
        case top
        case bottom
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if position == .top {
                    HStack {
                        if style == .floating {
                            Spacer()
                        }
                        NetworkStatusBar(style: style)
                            .padding(.horizontal, style == .inline ? 0 : 16)
                            .padding(.top, style == .inline ? 0 : 8)
                        if style == .floating {
                            Spacer()
                        }
                    }
                    Spacer()
                } else {
                    Spacer()
                    HStack {
                        if style == .floating {
                            Spacer()
                        }
                        NetworkStatusBar(style: style)
                            .padding(.horizontal, style == .inline ? 0 : 16)
                            .padding(.bottom, style == .inline ? 0 : 8)
                        if style == .floating {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func networkStatus(_ style: NetworkStatusBar.Style = .floating, position: NetworkStatusModifier.Position = .top) -> some View {
        modifier(NetworkStatusModifier(style: style, position: position))
    }
}

// Preview
struct NetworkStatusBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            NetworkStatusBar(style: .floating)
            NetworkStatusBar(style: .inline)
            NetworkStatusBar(style: .toolbar)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        
        // Example integration
        NavigationView {
            Text("Content")
                .navigationTitle("Example")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NetworkStatusBar(style: .toolbar)
                    }
                }
        }
        .previewDisplayName("Toolbar Integration")
    }
}