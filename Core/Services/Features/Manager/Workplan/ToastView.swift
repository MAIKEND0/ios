import SwiftUI

// MARK: - Toast Types
enum ToastType: Equatable {
    case success
    case error
    case info
    case warning
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Toast Data
struct ToastData: Equatable {
    let type: ToastType
    let title: String
    let message: String
    let duration: TimeInterval
    let id: UUID = UUID() // Dodaj unique ID
    
    init(type: ToastType, title: String, message: String, duration: TimeInterval = 4.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }
    
    // EQUATABLE CONFORMANCE
    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.title == rhs.title &&
               lhs.message == rhs.message &&
               lhs.duration == rhs.duration
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastData
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: toast.type.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(toast.type.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(toast.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Message
                    Text(toast.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color.secondary.opacity(0.2)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color(.systemBackground) : Color.white,
                            colorScheme == .dark ? Color(.systemGray6).opacity(0.8) : Color(.secondarySystemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
                    radius: 20,
                    x: 0,
                    y: 8
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [toast.type.color.opacity(0.6), toast.type.color.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
        .scaleEffect(isShowing ? 1.0 : 0.8)
        .opacity(isShowing ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isShowing)
        .onAppear {
            // Auto dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = toast, isShowing {
                        VStack {
                            Spacer()
                            
                            ToastView(toast: toast, isShowing: $isShowing)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 50)
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                }
                .ignoresSafeArea(.keyboard)
            )
            .onChange(of: toast) { _, newValue in
                if newValue != nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isShowing = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
            .onChange(of: isShowing) { _, newValue in
                if !newValue {
                    // Clear toast after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        toast = nil
                    }
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
