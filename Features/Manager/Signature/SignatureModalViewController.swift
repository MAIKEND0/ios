// SignatureModalViewController.swift
import SwiftUI

struct SignatureModalViewController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let content: SignatureModalView
    
    func makeUIViewController(context: Context) -> UINavigationController {
        // Ustaw orientację poziomą przed pokazaniem
        OrientationManager.shared.lockOrientation(.landscape)
        
        let viewController = SignatureModalUIViewController(isPresented: $isPresented)
        let hostingController = UIHostingController(rootView: content)
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)
        hostingController.view.frame = viewController.view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Osadzamy w UINavigationController dla lepszej kontroli
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Aktualizacja nie jest potrzebna
    }
    
    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: ()) {
        // Przywracamy domyślną orientację po zamknięciu
        OrientationManager.shared.lockOrientation(.portrait)
    }
}

// Pomocniczy UIViewController do zarządzania orientacją
class SignatureModalUIViewController: UIViewController {
    private var isPresented: Binding<Bool>
    
    init(isPresented: Binding<Bool>) {
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isPresented.wrappedValue = false
    }
}
