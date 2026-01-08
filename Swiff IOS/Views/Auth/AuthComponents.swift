//
//  AuthComponents.swift
//  Swiff IOS
//
//  Reusable authentication UI components
//

import SwiftUI

// MARK: - Auth Background

struct AuthBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            // Subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.Colors.green1.opacity(colorScheme == .dark ? 0.1 : 0.5),
                    Theme.Colors.background
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Abstract shape for visual interest
            GeometryReader { proxy in
                Circle()
                    .fill(Theme.Colors.brandPrimary.opacity(0.05))
                    .frame(width: proxy.size.width * 0.8)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.width * 0.2)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Swiff Logo

struct SwiffLogo: View {
    var size: CGFloat = 64
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(Theme.Colors.brandPrimary)
                .frame(width: size, height: size)
                .shadow(color: Theme.Colors.brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                
            Image(systemName: "dollarsign")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(Theme.Colors.textOnPrimary)
        }
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let errorMessage: String?
    let icon: String?

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        errorMessage: String? = nil,
        icon: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.errorMessage = errorMessage
        self.icon = icon
    }

    private var hasError: Bool {
        errorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                TextField(placeholder, text: $text)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(
                        hasError ? Theme.Colors.systemError : Theme.Colors.border.opacity(0.5),
                        lineWidth: hasError ? 2 : 1
                    )
            )

            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(Theme.Fonts.bodySmall)
                }
                .foregroundColor(Theme.Colors.systemError)
            }
        }
    }
}

// MARK: - Auth Secure Field

struct AuthSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let errorMessage: String?
    @State private var isSecure: Bool = true

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.errorMessage = errorMessage
    }

    private var hasError: Bool {
        errorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.textTertiary)

                SwiftUI.Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(Theme.Fonts.bodyLarge)
                .foregroundColor(Theme.Colors.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(
                        hasError ? Theme.Colors.systemError : Theme.Colors.border.opacity(0.5),
                        lineWidth: hasError ? 2 : 1
                    )
            )

            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(Theme.Fonts.bodySmall)
                }
                .foregroundColor(Theme.Colors.systemError)
            }
        }
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String

    private var requirements: [PasswordRequirement] {
        [
            PasswordRequirement(
                label: "At least 8 characters",
                isMet: password.count >= 8
            ),
            PasswordRequirement(
                label: "One uppercase letter",
                isMet: password.contains(where: { $0.isUppercase })
            ),
            PasswordRequirement(
                label: "One lowercase letter",
                isMet: password.contains(where: { $0.isLowercase })
            ),
            PasswordRequirement(
                label: "One number",
                isMet: password.contains(where: { $0.isNumber })
            )
        ]
    }

    var allRequirementsMet: Bool {
        requirements.allSatisfy { $0.isMet }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(requirements) { requirement in
                HStack(spacing: 8) {
                    Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundColor(requirement.isMet ? Theme.Colors.success : Theme.Colors.textTertiary)

                    Text(requirement.label)
                        .font(Theme.Fonts.bodySmall)
                        .foregroundColor(requirement.isMet ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                }
            }
        }
    }
}

private struct PasswordRequirement: Identifiable {
    let id = UUID()
    let label: String
    let isMet: Bool
}

// MARK: - Auth Button

struct AuthButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary))
                        .scaleEffect(0.9)
                }

                Text(title)
                    .font(Theme.Fonts.headerSmall)
            }
            .foregroundColor(Theme.Colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(isDisabled ? Theme.Colors.buttonDisabled : Theme.Colors.buttonPrimary)
                    .shadow(color: isDisabled ? Color.clear : Theme.Colors.buttonPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(isLoading || isDisabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Auth Secondary Button

struct AuthSecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.headerSmall)
                .foregroundColor(Theme.Colors.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.buttonSecondary)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Auth Link Button

struct AuthLinkButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.brandPrimary)
        }
    }
}

// MARK: - Auth Error Banner

struct AuthErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?

    init(_ message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))

            Text(message)
                .font(Theme.Fonts.bodyMedium)
                .multilineTextAlignment(.leading)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .foregroundColor(.white)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.systemError)
        )
    }
}

// MARK: - Auth Success Banner

struct AuthSuccessBanner: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))

            Text(message)
                .font(Theme.Fonts.bodyMedium)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .foregroundColor(.white)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.success)
        )
    }
}

// MARK: - Auth Divider

struct AuthDivider: View {
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Theme.Colors.border)
                .frame(height: 1)

            Text(text)
                .font(Theme.Fonts.bodySmall)
                .foregroundColor(Theme.Colors.textTertiary)

            Rectangle()
                .fill(Theme.Colors.border)
                .frame(height: 1)
        }
    }
}

// MARK: - Auth Header

struct AuthHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.Fonts.displayMedium)
                .foregroundColor(Theme.Colors.textPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Email Validation Helper

struct EmailValidator {
    static func isValid(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Password Validation Helper

struct PasswordValidator {
    static func isValid(_ password: String) -> Bool {
        let hasMinLength = password.count >= 8
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumber = password.contains(where: { $0.isNumber })

        return hasMinLength && hasUppercase && hasLowercase && hasNumber
    }

    static func validate(_ password: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if password.count < 8 {
            errors.append("Password must be at least 8 characters")
        }
        if !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain at least one uppercase letter")
        }
        if !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain at least one lowercase letter")
        }
        if !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain at least one number")
        }

        return (errors.isEmpty, errors)
    }
}

// MARK: - Previews

#Preview("Auth Components") {
    ScrollView {
        VStack(spacing: 24) {
            AuthHeader("Welcome Back", subtitle: "Sign in to your account")

            AuthTextField(
                title: "Email",
                placeholder: "your.email@example.com",
                text: .constant("test@example.com"),
                keyboardType: .emailAddress,
                icon: "envelope.fill"
            )

            AuthTextField(
                title: "Email with Error",
                placeholder: "your.email@example.com",
                text: .constant("invalid"),
                keyboardType: .emailAddress,
                errorMessage: "Please enter a valid email address",
                icon: "envelope.fill"
            )

            AuthSecureField(
                title: "Password",
                placeholder: "Enter your password",
                text: .constant("Test1234")
            )

            PasswordStrengthIndicator(password: "Test12")

            AuthButton("Sign In", isLoading: false) {}

            AuthButton("Loading...", isLoading: true) {}

            AuthSecondaryButton("Create Account") {}

            AuthLinkButton("Forgot Password?") {}

            AuthErrorBanner("Invalid credentials. Please try again.")

            AuthSuccessBanner("Password reset email sent!")

            AuthDivider(text: "or")
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
