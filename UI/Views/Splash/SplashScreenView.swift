//
//  SplashScreenView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var yOffset: CGFloat = 30
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity)
        } else {
            ZStack {
                Color.ksrDarkGray
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Używamy faktycznego logo KSR
                    Image("KSRLogo") // Upewnij się, że dodałeś plik KSRLogo do Assets.xcassets
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(size)
                        .opacity(opacity)
                        .rotationEffect(.degrees(rotation))
                        .offset(y: yOffset)
                    
                    Text("KSR CRANES")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(size)
                        .opacity(opacity)
                        .offset(y: yOffset)
                    
                    Spacer()
                    
                    if !isActive {
                        Text("© 2025 KSR Cranes")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 20)
                            .opacity(opacity)
                    }
                }
                .padding()
            }
            .onAppear {
                // Animacja pojawiania się i przesunięcia w górę
                withAnimation(.easeOut(duration: 1.0)) {
                    self.size = 1.0
                    self.opacity = 1.0
                    self.yOffset = 0
                }
                
                // Animacja obrotu
                withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                    self.rotation = 360
                }
                
                // Przejście do głównej aplikacji po opóźnieniu
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
