//
//  SignUpView.swift
//  Swiff IOS
//
//  Account registration form
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: SupabaseAuthService

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var acceptedTerms: Bool = false

    @State private var nameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?

    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let onSignIn: () -> Void
    let onSignUpSuccess: (String) -> Void // Passes email for verification view

    init(
        onSignIn: @escaping () -> Void,
        onSignUpSuccess: @escaping (String) -> Void
    ) {
        self.onSignIn = onSignIn
        self.onSignUpSuccess = onSignUpSuccess
    }

    private var isFormValid: Bool {
        !name.isEmpty &&
        EmailValidator.isValid(email) &&
        PasswordValidator.isValid(password) &&
        password == confirmPassword &&
        acceptedTerms
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
                            "Create Account",
                            subtitle: "Start tracking your finances today"
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
                        // Name
                        AuthTextField(
                            title: "Full Name",
                            placeholder: "Enter your name",
                            text: $name,
                            keyboardType: .default,
                            errorMessage: nameError,
                            icon: "person.fill"
                        )
                        .onChange(of: name) { _, newValue in
                            validateName(newValue)
                        }

                        // Email
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

                        // Password
                        VStack(alignment: .leading, spacing: 12) {
                            AuthSecureField(
                                title: "Password",
                                placeholder: "Create a password",
                                text: $password,
                                errorMessage: passwordError
                            )
                            .onChange(of: password) { _, _ in
                                validatePasswords()
                            }

                            PasswordStrengthIndicator(password: password)
                        }

                        // Confirm Password
                        AuthSecureField(
                            title: "Confirm Password",
                            placeholder: "Confirm your password",
                            text: $confirmPassword,
                            errorMessage: confirmPasswordError
                        )
                        .onChange(of: confirmPassword) { _, _ in
                            validatePasswords()
                        }

                        // Terms Acceptance
                        TermsCheckbox(isAccepted: $acceptedTerms)
                    }

                    // Create Account Button
                    AuthButton(
                        "Create Account",
                        isLoading: authService.isLoading,
                        isDisabled: !isFormValid
                    ) {
                        Task {
                            await signUp()
                        }
                    }

                    // Divider
                    AuthDivider(text: "or")

                    // Sign In
                    VStack(spacing: 8) {
                        Text("Already have an account?")
                            .font(Theme.Fonts.bodyMedium)
                            .foregroundColor(Theme.Colors.textSecondary)

                        AuthSecondaryButton("Sign In") {
                            onSignIn()
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

    private func validateName(_ name: String) {
        if name.isEmpty {
            nameError = nil
        } else if name.count < 2 {
            nameError = "Name must be at least 2 characters"
        } else {
            nameError = nil
        }
    }

    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
        } else if !EmailValidator.isValid(email) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }

    private func validatePasswords() {
        // Validate password strength
        if password.isEmpty {
            passwordError = nil
        } else if !PasswordValidator.isValid(password) {
            passwordError = "Password doesn't meet requirements"
        } else {
            passwordError = nil
        }

        // Validate password match
        if confirmPassword.isEmpty {
            confirmPasswordError = nil
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords don't match"
        } else {
            confirmPasswordError = nil
        }
    }

    // MARK: - Sign Up

    private func signUp() async {
        // Clear previous errors
        nameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        showError = false

        // Validate all inputs
        guard !name.isEmpty, name.count >= 2 else {
            nameError = "Please enter your name"
            return
        }

        guard EmailValidator.isValid(email) else {
            emailError = "Please enter a valid email address"
            return
        }

        guard PasswordValidator.isValid(password) else {
            passwordError = "Password doesn't meet requirements"
            return
        }

        guard password == confirmPassword else {
            confirmPasswordError = "Passwords don't match"
            return
        }

        guard acceptedTerms else {
            withAnimation {
                errorMessage = "Please accept the Terms of Service and Privacy Policy"
                showError = true
            }
            return
        }

        // Attempt sign up
        do {
            try await authService.signUp(email: email, password: password, name: name)
            // Success - but might need email verification
            onSignUpSuccess(email)
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
            case .emailConfirmationRequired:
                // This is actually success - user needs to verify email
                onSignUpSuccess(email)
                return
            case .signUpFailed(let message):
                if message.lowercased().contains("already") ||
                   message.lowercased().contains("exists") ||
                   message.lowercased().contains("registered") {
                    errorMessage = "An account with this email already exists."
                    emailError = "Email already in use"
                } else if message.lowercased().contains("network") ||
                          message.lowercased().contains("connection") {
                    errorMessage = "Unable to connect. Please check your internet connection."
                } else if message.lowercased().contains("password") {
                    errorMessage = "Password doesn't meet security requirements."
                    passwordError = message
                } else {
                    errorMessage = "Sign up failed. Please try again."
                }
            case .networkError:
                errorMessage = "Unable to connect. Please check your internet connection."
            default:
                errorMessage = error.localizedDescription
            }
            showError = true
        }
    }
}

// MARK: - Terms Checkbox

private struct TermsCheckbox: View {
    @Binding var isAccepted: Bool

    var body: some View {
        Button(action: { isAccepted.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isAccepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(isAccepted ? Theme.Colors.brandPrimary : Theme.Colors.textTertiary)

                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SignUpView(
        onSignIn: {},
        onSignUpSuccess: { _ in }
    )
    .environmentObject(SupabaseAuthService.shared)
}
