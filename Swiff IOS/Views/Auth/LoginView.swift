//
//  LoginView.swift
//  Swiff IOS
//
//  Email/password login form
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: SupabaseAuthService

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let onForgotPassword: () -> Void
    let onSignUp: () -> Void

    init(
        onForgotPassword: @escaping () -> Void,
        onSignUp: @escaping () -> Void
    ) {
        self.onForgotPassword = onForgotPassword
        self.onSignUp = onSignUp
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && EmailValidator.isValid(email)
    }

    var body: some View {
        ZStack {
            AuthBackground()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 24) {
                        SwiffLogo(size: 80)

                        AuthHeader(
                            "Welcome Back",
                            subtitle: "Sign in to continue managing your finances"
                        )
                    }
                    .padding(.top, 60)

                    // Error Banner
                    if showError {
                        AuthErrorBanner(errorMessage) {
                            withAnimation {
                                showError = false
                            }
                        }
                    }

                    // Form Fields
                    VStack(spacing: 20) {
                        AuthTextField(
                            title: "Email",
                            placeholder: "your.email@example.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            errorMessage: emailError,
                            icon: "envelope.fill"
                        )
                        .onChange(of: email) { _, newValue in
                            validateEmail(newValue)
                        }

                        VStack(alignment: .trailing, spacing: 8) {
                            AuthSecureField(
                                title: "Password",
                                placeholder: "Enter your password",
                                text: $password,
                                errorMessage: passwordError
                            )

                            AuthLinkButton("Forgot Password?") {
                                onForgotPassword()
                            }
                        }
                    }

                    // Sign In Button
                    AuthButton(
                        "Sign In",
                        isLoading: authService.isLoading,
                        isDisabled: !isFormValid
                    ) {
                        Task {
                            await signIn()
                        }
                    }

                    // Divider
                    AuthDivider(text: "or")

                    // Create Account
                    VStack(spacing: 8) {
                        Text("Don't have an account?")
                            .font(Theme.Fonts.bodyMedium)
                            .foregroundColor(Theme.Colors.textSecondary)

                        AuthSecondaryButton("Create Account") {
                            onSignUp()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Validation

    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
        } else if !EmailValidator.isValid(email) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }

    // MARK: - Sign In

    private func signIn() async {
        // Clear previous errors
        emailError = nil
        passwordError = nil
        showError = false

        // Validate inputs
        guard EmailValidator.isValid(email) else {
            emailError = "Please enter a valid email address"
            return
        }

        guard !password.isEmpty else {
            passwordError = "Please enter your password"
            return
        }

        // Attempt sign in
        do {
            try await authService.signIn(email: email, password: password)
            // Success - auth state change will trigger navigation
        } catch let error as AuthError {
            handleAuthError(error)
        } catch {
            withAnimation {
                errorMessage = "An unexpected error occurred. Please try again."
                showError = true
            }
        }
    }

    private func handleAuthError(_ error: AuthError) {
        withAnimation {
            switch error {
            case .signInFailed(let message):
                if message.lowercased().contains("invalid") ||
                   message.lowercased().contains("credentials") ||
                   message.lowercased().contains("password") {
                    errorMessage = "Invalid email or password. Please try again."
                } else if message.lowercased().contains("network") ||
                          message.lowercased().contains("connection") {
                    errorMessage = "Unable to connect. Please check your internet connection."
                } else if message.lowercased().contains("email") &&
                          message.lowercased().contains("confirm") {
                    errorMessage = "Please verify your email before signing in."
                } else {
                    errorMessage = "Sign in failed. Please try again."
                }
            case .emailConfirmationRequired:
                errorMessage = "Please verify your email before signing in."
            case .networkError:
                errorMessage = "Unable to connect. Please check your internet connection."
            default:
                errorMessage = error.localizedDescription
            }
            showError = true
        }
    }
}

#Preview {
    LoginView(
        onForgotPassword: {},
        onSignUp: {}
    )
    .environmentObject(SupabaseAuthService.shared)
}
