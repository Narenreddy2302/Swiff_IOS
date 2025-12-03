//
//  EnhancedSettingsView.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Comprehensive settings view with all 12 Agent 8 enhancements
//  This is the complete Settings Tab Enhancement implementation
//

import SwiftUI
import PhotosUI
import Combine

struct EnhancedSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var showingProfileEdit = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingDeleteAccountAlert = false
    @State private var deleteAccountConfirmationText = ""
    @State private var versionTapCount = 0

    // Task 8.10: Haptic feedback settings
    @AppStorage("enableHaptics") private var enableHaptics: Bool = true
    @AppStorage("enableButtonHaptics") private var enableButtonHaptics: Bool = true
    @AppStorage("enableNavigationHaptics") private var enableNavigationHaptics: Bool = true
    @AppStorage("enableSuccessHaptics") private var enableSuccessHaptics: Bool = true

    // Task 8.11: Accessibility settings
    @AppStorage("customFontSize") private var customFontSize: Double = 1.0
    @AppStorage("enableReduceMotion") private var enableReduceMotion: Bool = false
    @AppStorage("enableHighContrast") private var enableHighContrast: Bool = false
    @AppStorage("enableLargeButtons") private var enableLargeButtons: Bool = false

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.3"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "42"

    var body: some View {
        NavigationView {
            List {
                // Task 8.1: Profile Section with avatar, name, email, edit navigation
                profileSection

                // Task 8.2: Security Settings Section (PIN, biometrics, auto-lock)
                SecuritySettingsSection(userSettings: userSettings)

                // Task 8.3: Notification Settings Section (subscription reminders, trial alerts, price changes)
                NotificationSettingsSection()

                // Task 8.4: Appearance Settings Section (theme mode, app icon picker)
                AppearanceSettingsSection()

                // Task 8.5: Currency selection picker with common currencies
                currencySection

                // Task 8.10: Haptic feedback toggles
                hapticFeedbackSection

                // Task 8.11: Accessibility settings (reduce motion, font size)
                accessibilitySection

                // Task 8.6: Data Management Section (backup, restore, export, clear data)
                DataManagementSection()

                // Task 8.7: Advanced Settings Section (cache, debug, developer options)
                AdvancedSettingsSection()

                // Task 8.8: About section with version, privacy policy, terms of service
                // Task 8.9: Developer options easter egg (10 taps on version)
                aboutSection

                // Task 8.12: Danger zone with account deletion option
                dangerZoneSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if enableHaptics {
                            HapticManager.shared.selection()
                        }
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            UserProfileEditView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            TextField("Type DELETE to confirm", text: $deleteAccountConfirmationText)
            Button("Cancel", role: .cancel) {
                deleteAccountConfirmationText = ""
            }
            Button("Delete Account", role: .destructive) {
                handleAccountDeletion()
            }
            .disabled(deleteAccountConfirmationText != "DELETE")
        } message: {
            Text("This action is permanent and cannot be undone. All your data will be permanently deleted. Type DELETE to confirm.")
        }
    }

    // MARK: - Profile Section
    // Task 8.1: Implement profile section with avatar, name, email, edit navigation
    private var profileSection: some View {
        Section {
            Button(action: {
                if enableHaptics {
                    HapticManager.shared.selection()
                }
                showingProfileEdit = true
            }) {
                HStack(spacing: 16) {
                    // Profile Avatar (64pt)
                    AvatarView(
                        avatarType: profileManager.profile.avatarType,
                        size: .xlarge,
                        style: .solid
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profileManager.profile.name.isEmpty ? "Set Your Name" : profileManager.profile.name)
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Text(profileManager.profile.email.isEmpty ? "Tap to edit profile" : profileManager.profile.email)
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("PROFILE")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Currency Section
    // Task 8.5: Create currency selection picker with common currencies
    private var currencySection: some View {
        Section {
            Picker("Display Currency", selection: $userSettings.selectedCurrency) {
                ForEach(["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR"], id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: userSettings.selectedCurrency) { _, _ in
                if enableHaptics {
                    HapticManager.shared.selection()
                }
            }
        } header: {
            Text("DISPLAY")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Currency used for displaying amounts throughout the app")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Haptic Feedback Section
    // Task 8.10: Implement haptic feedback toggles
    private var hapticFeedbackSection: some View {
        Section {
            Toggle(isOn: $enableHaptics) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Haptics")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Provide tactile feedback throughout the app")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .onChange(of: enableHaptics) { _, newValue in
                if newValue {
                    HapticManager.shared.success()
                }
            }

            if enableHaptics {
                Toggle(isOn: $enableButtonHaptics) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Button Haptics")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Haptic feedback when tapping buttons")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)
                .padding(.leading, 16)

                Toggle(isOn: $enableNavigationHaptics) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Navigation Haptics")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Haptic feedback when navigating between screens")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)
                .padding(.leading, 16)

                Toggle(isOn: $enableSuccessHaptics) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Success Haptics")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Haptic feedback for successful actions")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)
                .padding(.leading, 16)
            }
        } header: {
            Text("HAPTIC FEEDBACK")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Customize tactile feedback for different interactions")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Accessibility Section
    // Task 8.11: Add accessibility settings (reduce motion, font size)
    private var accessibilitySection: some View {
        Section {
            // Font Size Control
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Font Size")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text("\(Int(customFontSize * 100))%")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                HStack(spacing: 8) {
                    Text("A")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)

                    Slider(value: $customFontSize, in: 0.8...1.4, step: 0.1)
                        .tint(.wiseForestGreen)

                    Text("A")
                        .font(.system(size: 20))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(.vertical, 8)

            // Reduce Motion Toggle
            Toggle(isOn: $enableReduceMotion) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reduce Motion")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Minimize animations and transitions")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .onChange(of: enableReduceMotion) { _, _ in
                if enableHaptics {
                    HapticManager.shared.selection()
                }
            }

            // High Contrast Toggle
            Toggle(isOn: $enableHighContrast) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Increase Contrast")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Enhance color contrast for better readability")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .onChange(of: enableHighContrast) { _, _ in
                if enableHaptics {
                    HapticManager.shared.selection()
                }
            }

            // Large Buttons Toggle
            Toggle(isOn: $enableLargeButtons) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Larger Touch Targets")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Increase size of buttons and interactive elements")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .onChange(of: enableLargeButtons) { _, _ in
                if enableHaptics {
                    HapticManager.shared.selection()
                }
            }

            // System Accessibility Settings Link
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.wiseBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Accessibility Settings")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Configure VoiceOver, Display, and more")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        } header: {
            Text("ACCESSIBILITY")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Customize the app for your accessibility needs")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - About Section
    // Task 8.8: Create About section with version, privacy policy, terms of service
    // Task 8.9: Add developer options easter egg (10 taps on version)
    private var aboutSection: some View {
        Section {
            // Version with developer options easter egg (10 taps)
            Button(action: {
                handleVersionTap()
            }) {
                HStack {
                    Text("Version")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                if enableHaptics {
                    HapticManager.shared.selection()
                }
                showingPrivacyPolicy = true
            }) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            Button(action: {
                if enableHaptics {
                    HapticManager.shared.selection()
                }
                showingTermsOfService = true
            }) {
                HStack {
                    Text("Terms of Service")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Acknowledgements
            Button(action: {
                // Future: Show acknowledgements
            }) {
                HStack {
                    Text("Acknowledgements")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        } header: {
            Text("ABOUT")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Danger Zone Section
    // Task 8.12: Create danger zone with account deletion option
    private var dangerZoneSection: some View {
        Section {
            Button(action: {
                if enableHaptics {
                    HapticManager.shared.warning()
                }
                showingDeleteAccountAlert = true
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.wiseError)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete Account")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseError)
                        Text("Permanently delete your account and all data")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseError.opacity(0.7))
                    }
                    Spacer()
                }
            }
        } header: {
            Text("DANGER ZONE")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseError)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("⚠️ Warning: This action cannot be undone")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseError)
                Text("Deleting your account will permanently remove all your data including subscriptions, transactions, people, groups, and settings. This action is irreversible.")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
    }

    // MARK: - Helper Methods

    // Task 8.9: Developer Options (10 taps on version)
    private func handleVersionTap() {
        if enableHaptics {
            HapticManager.shared.light()
        }

        versionTapCount += 1
        userSettings.versionTapCount = versionTapCount

        if versionTapCount >= 10 && !userSettings.developerOptionsEnabled {
            userSettings.developerOptionsEnabled = true
            if enableHaptics {
                HapticManager.shared.success()
            }
            ToastManager.shared.showSuccess("Developer Options Unlocked!")
            // Reset counter
            versionTapCount = 0
            userSettings.versionTapCount = 0
        } else if versionTapCount >= 10 {
            // Reset counter if already enabled
            versionTapCount = 0
            userSettings.versionTapCount = 0
        }
    }

    // Task 8.12: Handle account deletion
    private func handleAccountDeletion() {
        guard deleteAccountConfirmationText == "DELETE" else {
            if enableHaptics {
                HapticManager.shared.error()
            }
            ToastManager.shared.showError("Please type DELETE to confirm")
            return
        }

        // Perform account deletion
        do {
            // Clear all data
            try dataManager.clearAllData()

            // Reset all settings
            userSettings.resetToDefaults()

            // Clear profile
            profileManager.resetProfile()

            // Clear other preferences
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

            if enableHaptics {
                HapticManager.shared.success()
            }

            ToastManager.shared.showSuccess("Account deleted successfully")

            // Dismiss settings and show onboarding
            dismiss()

        } catch {
            if enableHaptics {
                HapticManager.shared.error()
            }
            ToastManager.shared.showError("Failed to delete account: \(error.localizedDescription)")
        }

        deleteAccountConfirmationText = ""
    }
}

#Preview {
    EnhancedSettingsView()
        .environmentObject(DataManager.shared)
}
