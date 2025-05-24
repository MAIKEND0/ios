// Core/Extensions/UIApplication+Extensions.swift
import UIKit

extension UIApplication {
    /// Ukrywa klawiaturę w całej aplikacji
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Znajduje aktywne okno aplikacji
    var activeWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// Znajduje najwyższy widok kontrolera w hierarchii
    var topViewController: UIViewController? {
        guard let rootViewController = activeWindow?.rootViewController else {
            return nil
        }
        
        return findTopViewController(from: rootViewController)
    }
    
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return findTopViewController(from: presented)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return findTopViewController(from: navigationController.visibleViewController ?? navigationController)
        }
        
        if let tabBarController = viewController as? UITabBarController {
            return findTopViewController(from: tabBarController.selectedViewController ?? tabBarController)
        }
        
        return viewController
    }
}
