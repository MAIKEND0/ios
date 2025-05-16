//
//  KSR_Cranes_AppApp.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

@main
struct KSR_Cranes_AppApp: App {
    // Użyj dedykowanego OrientationManagerDelegate
    @UIApplicationDelegateAdaptor(OrientationManagerDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashLoginContainerView()
        }
    }
}
