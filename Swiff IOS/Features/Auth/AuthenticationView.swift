//
//  AuthenticationView.swift
//  Swiff IOS
//
//  Container view managing authentication flow navigation
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: SupabaseAuthService

    @State private var currentScreen: AuthScreen = .login
    @State private var pendingVerificationEmail: String = ""

    enum AuthScreen {
        case login
        case signUp
        case forgotPassword
        case emailVerification
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            switch currentScreen {
            case .login:
                LoginView(
                    onForgotPassword: {
                        withAnimation(.smooth) {
                            currentScreen = .forgotPassword
                        }
                    },
                    onSignUp: {
                        withAnimation(.smooth) {
                            currentScreen = .signUp
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )

            case .signUp:
                SignUpView(
                    onSignIn: {
                        withAnimation(.smooth) {
                            currentScreen = .login
                        }
                    },
                    onSignUpSuccess: { email in
                        pendingVerificationEmail = email
                        withAnimation(.smooth) {
                            currentScreen = .emailVerification
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )

            case .forgotPassword:
                ForgotPasswordView(
                    onBackToLogin: {
                        withAnimation(.smooth) {
                            currentScreen = .login
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )

            case .emailVerification:
                EmailVerificationPendingView(
                    email: pendingVerificationEmail,
                    onBackToLogin: {
                        withAnimation(.smooth) {
                            currentScreen = .login
                        }
                    },
                    onUseDifferentEmail: {
                        withAnimation(.smooth) {
                            currentScreen = .signUp
                        }
                    },
                    onVerified: {
                        // Auth state change will handle navigation
                        // This is called when user confirms verification
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
        .animation(
            UIAccessibility.isReduceMotionEnabled ? .none : .smooth,
            value: currentScreen
        )
    }
}

// MARK: - Auth Screen Extension for Identifiable

extension AuthenticationView.AuthScreen: Equatable {}

#Preview {
    AuthenticationView()
        .environmentObject(SupabaseAuthService.shared)
}
