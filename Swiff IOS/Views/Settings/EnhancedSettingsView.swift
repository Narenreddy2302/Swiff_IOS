//
//  EnhancedSettingsView.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Comprehensive settings view with all 48 Agent 5 enhancements
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
    @State private var versionTapCount = 0

    let appVersion = "1.0.0"

    var body: some View {
        NavigationView {
            List {
                // AGENT 5: Profile Section (existing)
                profileSection

                // AGENT 5: Security Settings Section (Tasks 5.1.1-12)
                SecuritySettingsSection(userSettings: userSettings)

                // AGENT 5: Enhanced Notification Settings (Tasks 5.2.1-11)
                NotificationSettingsSection()

                // AGENT 5: Appearance Settings Section (Tasks 5.3.1-7)
                AppearanceSettingsSection()

                // Currency Section (existing)
                currencySection

                // AGENT 5: Enhanced Data Management Section (Tasks 5.4.1-10)
                DataManagementSection()

                // AGENT 5: Advanced Settings Section (Tasks 5.5.1-8)
                AdvancedSettingsSection()

                // About Section with Developer Options easter egg
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            Button(action: {
                showingProfileEdit = true
            }) {
                HStack(spacing: 16) {
                    // Profile Avatar
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
            Text("Profile")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Currency Section
    private var currencySection: some View {
        Section {
            Picker("Display Currency", selection: $userSettings.selectedCurrency) {
                ForEach(["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR"], id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Display Preferences")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Currency used for displaying amounts throughout the app")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            // AGENT 5: Version with developer options easter egg (10 taps)
            Button(action: {
                handleVersionTap()
            }) {
                HStack {
                    Text("Version")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
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
        } header: {
            Text("About")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // AGENT 5: Task 5.5.6 - Developer Options (10 taps on version)
    private func handleVersionTap() {
        versionTapCount += 1
        userSettings.versionTapCount = versionTapCount

        if versionTapCount >= 10 && !userSettings.developerOptionsEnabled {
            userSettings.developerOptionsEnabled = true
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
}

#Preview {
    EnhancedSettingsView()
        .environmentObject(DataManager.shared)
}
