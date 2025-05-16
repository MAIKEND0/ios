//
//  AppDelegate.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 18/05/2025.
//

import UIKit

// USUŃ atrybut @main stąd!
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Dodaj tę zmienną statyczną do kontrolowania orientacji
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    // ... istniejący kod ...
    
    // Dodaj tę metodę, aby kontrolować orientacje w aplikacji
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    // ... pozostała część istniejącego kodu ...
}
