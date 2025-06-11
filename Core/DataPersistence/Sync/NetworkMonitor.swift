//
//  NetworkMonitor.swift
//  KSR Cranes App
//
//  Created by Sync Engine on 06/11/2025.
//

import Foundation
import Network
import Combine

/// Monitors network connectivity and quality
final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    
    // MARK: - Properties
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.ksrcranes.networkmonitor")
    
    /// Current network path
    private(set) var currentPath: NWPath?
    
    /// Network quality assessment
    var networkQuality: NetworkQuality {
        guard isConnected else { return .none }
        
        switch connectionType {
        case .wifi:
            return isConstrained ? .fair : .excellent
        case .cellular:
            return isExpensive ? .poor : .good
        case .wiredEthernet:
            return .excellent
        default:
            return .unknown
        }
    }
    
    /// Check if sync should be allowed based on network conditions
    var shouldAllowSync: Bool {
        return isConnected && !isConstrained
    }
    
    /// Check if large downloads should be allowed
    var shouldAllowLargeDownloads: Bool {
        return isConnected && !isExpensive && !isConstrained
    }
    
    // MARK: - Initialization
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        
        monitor.start(queue: queue)
        
        #if DEBUG
        print("[NetworkMonitor] ✅ Started network monitoring")
        #endif
    }
    
    private func stopMonitoring() {
        monitor.cancel()
        
        #if DEBUG
        print("[NetworkMonitor] 🛑 Stopped network monitoring")
        #endif
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        currentPath = path
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }
        
        #if DEBUG
        print("[NetworkMonitor] 📶 Network status updated:")
        print("  - Connected: \(isConnected)")
        print("  - Type: \(connectionType?.description ?? "Unknown")")
        print("  - Expensive: \(isExpensive)")
        print("  - Constrained: \(isConstrained)")
        print("  - Quality: \(networkQuality)")
        #endif
        
        // Post notification for other components
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: [
                "isConnected": isConnected,
                "quality": networkQuality.rawValue
            ]
        )
    }
    
    // MARK: - Public Methods
    
    /// Wait for network connection with timeout
    func waitForConnection(timeout: TimeInterval = 10) async -> Bool {
        if isConnected { return true }
        
        return await withCheckedContinuation { continuation in
            let observerBox = ObserverBox()
            let resolvedBox = ResolvedBox()
            
            // Create timeout task
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await MainActor.run {
                    if !resolvedBox.isResolved {
                        resolvedBox.isResolved = true
                        if let observer = observerBox.observer {
                            NotificationCenter.default.removeObserver(observer)
                        }
                        continuation.resume(returning: false)
                    }
                }
            }
            
            observerBox.observer = NotificationCenter.default.addObserver(
                forName: .networkStatusChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                if let self = self, self.isConnected && !resolvedBox.isResolved {
                    resolvedBox.isResolved = true
                    if let observer = observerBox.observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    continuation.resume(returning: true)
                }
            }
            
            // Check one more time in case connection was established during setup
            if isConnected && !resolvedBox.isResolved {
                resolvedBox.isResolved = true
                if let observer = observerBox.observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                continuation.resume(returning: true)
            }
        }
    }
    
    /// Check if a specific host is reachable
    func isHostReachable(_ host: String) async -> Bool {
        guard isConnected else { return false }
        
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.ksrcranes.hostreachability")
            
            monitor.pathUpdateHandler = { path in
                let isReachable = path.status == .satisfied
                monitor.cancel()
                continuation.resume(returning: isReachable)
            }
            
            monitor.start(queue: queue)
            
            // Timeout after 5 seconds
            queue.asyncAfter(deadline: .now() + 5) {
                monitor.cancel()
                continuation.resume(returning: false)
            }
        }
    }
}

// MARK: - Network Quality

enum NetworkQuality: Int, CaseIterable {
    case none = 0
    case poor = 1
    case fair = 2
    case good = 3
    case excellent = 4
    case unknown = -1
    
    var description: String {
        switch self {
        case .none: return "No Connection"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        case .unknown: return "Unknown"
        }
    }
    
    var minimumBandwidthMbps: Double? {
        switch self {
        case .none: return nil
        case .poor: return 0.5
        case .fair: return 1.0
        case .good: return 5.0
        case .excellent: return 10.0
        case .unknown: return nil
        }
    }
}

// MARK: - Extensions

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}

// MARK: - Helper Classes for Concurrency

private final class ObserverBox: @unchecked Sendable {
    var observer: NSObjectProtocol?
    init() {}
}

private final class ResolvedBox: @unchecked Sendable {
    var isResolved = false
    init() {}
}