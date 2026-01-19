//
//  ForgotPasswordView.swift
//  Swiff IOS
//
//  Password reset request form
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authService: SupabaseAuthService

    @State private var email: String = ""
    @State private var emailError: String?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    let onBackToLogin: () -> Void

    init(onBackToLogin: @escaping () -> Void) {
        self.onBackToLogin = onBackToLogin
    }

    private var isFormValid: Bool {
        !email.isEmpty && EmailValidator.isValid(email)
    }

        var body: some View {
            ZStack {
                AuthBackground()
                
                VStack(spacing: 32) {
                    // Back Button
                    HStack {
                        Button(action: onBackToLogin) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(Theme.Fonts.bodyMedium)
                            }
                            .foregroundColor(Theme.Colors.brandPrimary)
                        }
    
                        Spacer()
                    }
    
                    if showSuccess {
                        // Success State
                        successView
                    } else {
                        // Form State
                        formView
                    }
    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
    
        // MARK: - Form View
    
        private var formView: some View {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.Colors.brandPrimary)
                            .frame(width: 80, height: 80)
                            .shadow(color: Theme.Colors.brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                        Image(systemName: "key.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Theme.Colors.textOnPrimary)
                    }
    
                    AuthHeader(
                        "Reset Password",
                        subtitle: "Enter your email address and we'll send you a link to reset your password"
                    )
                }
                .padding(.top, 40)
    
                // Error Banner
                if showError {
                    AuthErrorBanner(errorMessage) {
                        withAnimation {
                            showError = false
                        }
                    }
                }
    
                // Email Field
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
    
                // Send Reset Link Button
                AuthButton(
                    "Send Reset Link",
                    isLoading: authService.isLoading,
                    isDisabled: !isFormValid
                ) {
                    Task {
                        await sendResetLink()
                    }
                }
            }
        }
    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.Colors.success)
                }

                VStack(spacing: 12) {
                    Text("Email Sent")
                        .font(Theme.Fonts.displayMedium)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("We've sent a password reset link to")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(email)
                        .font(Theme.Fonts.headerSmall)
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
            .padding(.top, 40)

            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("What's next?")
                    .font(Theme.Fonts.headerSmall)
                    .foregroundColor(Theme.Colors.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    InstructionText(text: "Check your email inbox (and spam folder)")
                    InstructionText(text: "Click the reset link in the email")
                    InstructionText(text: "Create a new password")
                    InstructionText(text: "Sign in with your new password")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.secondaryBackground)
            )

            // Back to Login Button
            AuthButton("Back to Sign In") {
                onBackToLogin()
            }

            // Didn't receive email
            VStack(spacing: 8) {
                Text("Didn't receive the email?")
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                AuthLinkButton("Send Again") {
                    withAnimation {
                        showSuccess = false
                    }
                }
            }
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

    // MARK: - Send Reset Link

    private func sendResetLink() async {
        emailError = nil
        showError = false

        guard EmailValidator.isValid(email) else {
            emailError = "Please enter a valid email address"
            return
        }

        do {
            try await authService.sendPasswordReset(email: email)
            await MainActor.run {
                withAnimation {
                    showSuccess = true
                }
            }
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
            case .passwordResetFailed(let message):
                if message.lowercased().contains("network") ||
                   message.lowercased().contains("connection") {
                    errorMessage = "Unable to connect. Please check your internet connection."
                } else if message.lowercased().contains("not found") ||
                          message.lowercased().contains("no user") {
                    // Don't reveal if email exists - for security
                    // Show success anyway to prevent email enumeration
                    showSuccess = true
                    return
                } else {
                    errorMessage = "Failed to send reset email. Please try again."
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

// MARK: - Instruction Text

private struct InstructionText: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.brandPrimary)
                .frame(width: 16)

            Text(text)
                .font(Theme.Fonts.bodySmall)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

#Preview {
    ForgotPasswordView(onBackToLogin: {})
        .environmentObject(SupabaseAuthService.shared)
}
