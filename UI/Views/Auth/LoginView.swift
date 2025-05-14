//
//  LoginView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // 1) Tło ekranowe
                Color.ksrDarkGray
                    .ignoresSafeArea()

                // 2) ScrollView z logo i formularzem
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo + nagłówki
                        VStack(spacing: 16) {
                            Image("KSRLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                            Text("KSR CRANES")
                                .font(.largeTitle).bold()
                                .foregroundColor(.white)

                            Text("Employee Portal")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 60)

                        // Formularz logowania
                        VStack(spacing: 20) {
                            // Email
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.caption).bold()
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Wpisz swój email", text: $viewModel.email)
                                    .textContentType(.username)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding()
                                    .background(Color.ksrLightGray)
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                            }

                            // Hasło
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hasło")
                                    .font(.caption).bold()
                                    .foregroundColor(.white.opacity(0.8))

                                SecureField("Wpisz swoje hasło", text: $viewModel.password)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color.ksrLightGray)
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                            }

                            // Komunikat o błędzie
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Przycisk logowania
                            Button(action: { viewModel.login() }) {
                                HStack {
                                    Spacer()
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Zaloguj się")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.ksrYellow)
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.isLoading)

                            // Zapomniałeś hasła?
                            Button("Zapomniałeś hasła?") {
                                viewModel.forgotPassword()
                            }
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 20)

                        // Wersja aplikacji
                        Text("v1.0.0")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 16)
                    }
                }
                // unikanie zasłonięcia przez klawiaturę
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            // 3) Tapnij gdziekolwiek, aby ukryć klawiaturę.
            //    Na ZStack, nie na tle Color, żeby nie blokować pola.
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
            // 4) Po zalogowaniu przechodzimy dalej
            .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
                RoleBasedRootView(userRole: viewModel.userRole)
            }
            // 5) Alert do „Zapomniałeś hasła?”
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
