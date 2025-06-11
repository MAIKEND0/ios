import SwiftUI

struct OfflineIndicatorView: View {
    let message: String
    let showRetryButton: Bool
    let onRetry: (() -> Void)?
    
    @State private var isVisible = false
    @Environment(\.colorScheme) var colorScheme
    
    init(message: String = "You're offline", showRetryButton: Bool = true, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.showRetryButton = showRetryButton
        self.onRetry = onRetry
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isVisible {
                HStack {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if showRetryButton, let onRetry = onRetry {
                        Button(action: onRetry) {
                            Text("Retry")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.ksrPrimary)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Rectangle()
                        .fill(backgroundColor)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    // Static factory methods for common scenarios
    static func standard() -> OfflineIndicatorView {
        OfflineIndicatorView()
    }
    
    static func withCustomMessage(_ message: String) -> OfflineIndicatorView {
        OfflineIndicatorView(message: message)
    }
    
    static func noRetry(message: String = "Working offline") -> OfflineIndicatorView {
        OfflineIndicatorView(message: message, showRetryButton: false)
    }
}

// Banner modifier for easy integration
struct OfflineBannerModifier: ViewModifier {
    let isOffline: Bool
    let message: String
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if isOffline {
                OfflineIndicatorView(
                    message: message,
                    showRetryButton: onRetry != nil,
                    onRetry: onRetry
                )
            }
            
            content
        }
    }
}

extension View {
    func offlineBanner(isOffline: Bool, message: String = "You're offline", onRetry: (() -> Void)? = nil) -> some View {
        modifier(OfflineBannerModifier(isOffline: isOffline, message: message, onRetry: onRetry))
    }
}

// Preview
struct OfflineIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            OfflineIndicatorView()
            
            Spacer()
            
            Text("Content below banner")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
        .previewDisplayName("With Retry")
        
        VStack(spacing: 0) {
            OfflineIndicatorView.noRetry()
            
            Spacer()
            
            Text("Content below banner")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
        .previewDisplayName("Without Retry")
    }
}