//
//  PrivacySecurityPage.swift
//  Swiff IOS
//
//  Privacy and security settings page
//

import SwiftUI
import LocalAuthentication

struct PrivacySecurityPage: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared

    @State private var showChangePassword = false
    @State private var showDeleteDataAlert = false
    @State private var biometricType: LABiometryType = .none

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Security Section
                securitySection

                // App Lock Section
                appLockSection

                // Data Privacy Section
                dataPrivacySection

                // Danger Zone
                dangerZoneSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.wiseGroupedBackground)
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            checkBiometricType()
        }
        .sheet(isPresented: $showChangePassword) {
            ProfileChangePasswordSheet()
        }
        .alert("Delete All Data?", isPresented: $showDeleteDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your data including transactions, subscriptions, and settings. This action cannot be undone.")
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "SECURITY")

            VStack(spacing: 0) {
                // Two-Factor Authentication
                SecurityToggleRow(
                    icon: "shield.checkered",
                    iconColor: .wiseBrightGreen,
                    title: "Two-Factor Authentication",
                    subtitle: "Add extra security to your account",
                    isOn: $userSettings.biometricAuthEnabled,
                    showDivider: true
                )

                // Biometric Login
                SecurityToggleRow(
                    icon: biometricIcon,
                    iconColor: .wiseBlue,
                    title: biometricTitle,
                    subtitle: "Use \(biometricDescription) to unlock",
                    isOn: $userSettings.biometricAuthEnabled,
                    showDivider: true
                )

                // Login Alerts
                SecurityToggleRow(
                    icon: "bell.badge.fill",
                    iconColor: .wiseOrange,
                    title: "Login Alerts",
                    subtitle: "Get notified of new logins",
                    isOn: $userSettings.notificationsEnabled,
                    showDivider: true
                )

                // Change Password
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showChangePassword = true
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.wisePurple.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.wisePurple)
                            )

                        Text("Change Password")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - App Lock Section

    private var appLockSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "APP LOCK")

            VStack(spacing: 0) {
                // Auto Lock
                SecurityToggleRow(
                    icon: "lock.fill",
                    iconColor: .wiseForestGreen,
                    title: "Auto Lock",
                    subtitle: "Lock app when in background",
                    isOn: $userSettings.autoLockEnabled,
                    showDivider: true
                )

                // Lock Timeout
                if userSettings.autoLockEnabled {
                    HStack {
                        Text("Lock After")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Picker("", selection: $userSettings.autoLockDuration) {
                            Text("Immediately").tag(0)
                            Text("1 minute").tag(60)
                            Text("5 minutes").tag(300)
                            Text("15 minutes").tag(900)
                        }
                        .pickerStyle(.menu)
                        .tint(.wiseSecondaryText)
                    }
                    .padding(16)

                    Divider().padding(.leading, 16)
                }

                // Require on Launch
                SecurityToggleRow(
                    icon: "arrow.right.circle.fill",
                    iconColor: .wiseBlue,
                    title: "Require on Launch",
                    subtitle: "Always require authentication on app start",
                    isOn: $userSettings.pinLockEnabled,
                    showDivider: false
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Data Privacy Section

    private var dataPrivacySection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "DATA PRIVACY")

            VStack(spacing: 0) {
                // Hide Balances
                SecurityToggleRow(
                    icon: "eye.slash.fill",
                    iconColor: .wiseSecondaryText,
                    title: "Hide Balances",
                    subtitle: "Hide amounts on home screen",
                    isOn: $userSettings.hideBalances,
                    showDivider: true
                )

                // Analytics
                SecurityToggleRow(
                    icon: "chart.bar.fill",
                    iconColor: .wiseBrightGreen,
                    title: "Analytics",
                    subtitle: "Help improve Swiff with anonymous data",
                    isOn: $userSettings.analyticsEnabled,
                    showDivider: true
                )

                // iCloud Sync
                SecurityToggleRow(
                    icon: "icloud.fill",
                    iconColor: .wiseBlue,
                    title: "iCloud Sync",
                    subtitle: "Sync data across your devices",
                    isOn: $userSettings.iCloudSyncEnabled,
                    showDivider: false
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "DANGER ZONE")

            Button(action: {
                HapticManager.shared.impact(.medium)
                showDeleteDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    Text("Delete All Data")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.medium)
                }
                .foregroundColor(.wiseError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Properties

    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.fill"
        }
    }

    private var biometricTitle: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Login"
        }
    }

    private var biometricDescription: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "biometrics"
        }
    }

    // MARK: - Helper Functions

    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }

    private func deleteAllData() {
        do {
            try DataManager.shared.clearAllData()
            HapticManager.shared.notification(.success)
            ToastManager.shared.showSuccess("All data deleted")
        } catch {
            HapticManager.shared.notification(.error)
            ToastManager.shared.showError("Failed to delete data")
        }
    }
}

// MARK: - Security Toggle Row

struct SecurityToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(iconColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.wisePrimaryButton)
            }
            .padding(16)

            if showDivider {
                Divider().padding(.leading, 68)
            }
        }
    }
}

// MARK: - Profile Change Password Sheet

struct ProfileChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                } header: {
                    Text("Current Password")
                }

                Section {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                } header: {
                    Text("New Password")
                } footer: {
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.wiseSecondaryText)
                }

                if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                    Section {
                        Text("Passwords do not match")
                            .foregroundColor(.wiseError)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePassword()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func savePassword() {
        HapticManager.shared.notification(.success)
        ToastManager.shared.showSuccess("Password changed successfully")
        dismiss()
    }
}

#Preview("Privacy Security Page") {
    NavigationView {
        PrivacySecurityPage()
    }
}
