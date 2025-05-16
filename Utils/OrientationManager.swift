// OrientationManager.swift
import SwiftUI

class OrientationManager: NSObject {
    static let shared = OrientationManager()
    
    var orientationLock: UIInterfaceOrientationMask = .portrait
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        orientationLock = orientation
        self.applyOrientation()
    }
    
    func applyOrientation() {
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if orientationLock == .landscape {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                } else {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
                
                // Używaj nowszego API dla iOS 15+
                if #available(iOS 15.0, *) {
                    windowScene.windows.forEach { window in
                        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                } else {
                    // Starsze API dla iOS < 15
                    UIApplication.shared.windows.forEach { window in
                        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
            }
        } else {
            // Starszy sposób dla iOS < 16
            if orientationLock == .landscape {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}

// Adaptor do połączenia z AppDelegate
class OrientationManagerDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationManager.shared.orientationLock
    }
}
