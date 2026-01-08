//
//  EmailVerificationPendingView.swift
//  Swiff IOS
//
//  Shown after signup to prompt email verification
//

import SwiftUI

struct EmailVerificationPendingView: View {
    @EnvironmentObject var authService: SupabaseAuthService

    let email: String
    let onBackToLogin: () -> Void
    let onUseDifferentEmail: () -> Void
    let onVerified: () -> Void

    @State private var isResending: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isCheckingVerification: Bool = false
    @State private var cooldownRemaining: Int = 0

    private let cooldownDuration: Int = 60

    var body: some View {
        ZStack {
            AuthBackground()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.Colors.brandPrimary.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.brandPrimary)
                    }

                    VStack(spacing: 12) {
                        Text("Check Your Email")
                            .font(Theme.Fonts.displayMedium)
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text("We've sent a verification link to")
                            .font(Theme.Fonts.bodyMedium)
                            .foregroundColor(Theme.Colors.textSecondary)

                        Text(email)
                            .font(Theme.Fonts.headerSmall)
                            .foregroundColor(Theme.Colors.brandPrimary)
                    }
                }

                // Success Banner
                if showSuccess {
                    AuthSuccessBanner("Verification email sent!")
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Error Banner
                if showError {
                    AuthErrorBanner(errorMessage) {
                        withAnimation {
                            showError = false
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Instructions
                VStack(spacing: 16) {
                    InstructionRow(
                        number: "1",
                        text: "Open the email from Swiff"
                    )

                    InstructionRow(
                        number: "2",
                        text: "Click the verification link"
                    )

                    InstructionRow(
                        number: "3",
                        text: "Return to the app and sign in"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.secondaryBackground)
                )

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    // Resend Email Button
                    Button(action: resendEmail) {
                        HStack(spacing: 8) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.brandPrimary))
                                    .scaleEffect(0.8)
                            }

                            if cooldownRemaining > 0 {
                                Text("Resend in \(cooldownRemaining)s")
                            } else {
                                Text("Resend Verification Email")
                            }
                        }
                        .font(Theme.Fonts.headerSmall)
                        .foregroundColor(cooldownRemaining > 0 ? Theme.Colors.textTertiary : Theme.Colors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                                .fill(Theme.Colors.buttonSecondary)
                        )
                    }
                    .disabled(isResending || cooldownRemaining > 0)
                    .buttonStyle(ScaleButtonStyle())

                    // I've Verified Button
                    AuthButton(
                        "I've Verified My Email",
                        isLoading: isCheckingVerification
                    ) {
                        Task {
                            await checkVerification()
                        }
                    }

                    // Other options
                    HStack(spacing: 24) {
                        AuthLinkButton("Use Different Email") {
                            onUseDifferentEmail()
                        }

                        AuthLinkButton("Back to Login") {
                            onBackToLogin()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Actions

    private func resendEmail() {
        guard cooldownRemaining == 0 else { return }

        isResending = true
        showError = false
        showSuccess = false

        Task {
            do {
                try await authService.resendVerificationEmail(email: email)
                await MainActor.run {
                    isResending = false
                    withAnimation {
                        showSuccess = true
                    }
                    startCooldown()

                    // Hide success after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    withAnimation {
                        errorMessage = "Failed to send verification email. Please try again."
                        showError = true
                    }
                }
            }
        }
    }

    private func startCooldown() {
        cooldownRemaining = cooldownDuration

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if cooldownRemaining > 0 {
                cooldownRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func checkVerification() async {
        isCheckingVerification = true
        showError = false

        do {
            // Try to refresh session - if email is verified, this will succeed
            try await authService.refreshSession()

            await MainActor.run {
                isCheckingVerification = false
                // Check if now authenticated (email verified)
                if authService.isAuthenticated {
                    onVerified()
                } else {
                    withAnimation {
                        errorMessage = "Email not yet verified. Please check your inbox and click the verification link."
                        showError = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                isCheckingVerification = false
                withAnimation {
                    errorMessage = "Email not yet verified. Please check your inbox and click the verification link."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Instruction Row

private struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.brandPrimary)
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(Theme.Fonts.labelMedium)
                    .foregroundColor(Theme.Colors.textOnPrimary)
            }

            Text(text)
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()
        }
    }
}

#Preview {
    EmailVerificationPendingView(
        email: "user@example.com",
        onBackToLogin: {},
        onUseDifferentEmail: {},
        onVerified: {}
    )
    .environmentObject(SupabaseAuthService.shared)
}
