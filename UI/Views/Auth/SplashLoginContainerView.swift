//
//  SplashLoginContainerView.swift
//  KSR Cranes App
//

import SwiftUI

struct SplashLoginContainerView: View {
    @State private var showLogin = false
    @State private var animateSplashLogo = false
    @State private var splashOpacity: Double = 1

    var body: some View {
        ZStack {
            // tło
            Color.ksrDarkGray
                .ignoresSafeArea()

            // 1) Splash na wierzchu, fade-out
            VStack {
                Spacer()
                Image("KSRLogo")
                    .resizable().scaledToFit().frame(width: 150, height: 150)
                    .scaleEffect(animateSplashLogo ? 1 : 0.8)
                    .opacity(animateSplashLogo ? 1 : 0.5)
                    .rotationEffect(.degrees(animateSplashLogo ? 0 : -90))
                    .offset(y: animateSplashLogo ? 0 : 30)
                Text("KSR CRANES")
                    .font(.title).fontWeight(.bold).foregroundColor(.white)
                    .scaleEffect(animateSplashLogo ? 1 : 0.8)
                    .opacity(animateSplashLogo ? 1 : 0.5)
                    .offset(y: animateSplashLogo ? 0 : 30)
                Spacer()
                Text("© 2025 KSR Cranes")
                    .font(.caption).foregroundColor(.white.opacity(0.6))
                    .opacity(animateSplashLogo ? 1 : 0)
                    .padding(.bottom, 20)
            }
            .opacity(splashOpacity)

            // 2) Po splashu od razu LoginView (z pełnym flow MVVM)
            if showLogin {
                LoginView()
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
        .onAppear {
            // start animacji logo
            withAnimation(.easeOut(duration: 1)) { animateSplashLogo = true }
            // po 1.5s fade splash i pokaż login
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    splashOpacity = 0
                }
                showLogin = true
            }
        }
    }
}

struct SplashLoginContainerView_Previews: PreviewProvider {
    static var previews: some View {
        SplashLoginContainerView()
            .preferredColorScheme(.dark)
    }
}
