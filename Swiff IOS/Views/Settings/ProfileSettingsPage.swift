//
//  ProfileSettingsPage.swift
//  Swiff IOS
//
//  Profile settings page for managing profile info, notifications, and storage
//

import SwiftUI
import PhotosUI

struct ProfileSettingsPage: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var notificationManager = NotificationManager.shared

    // Edit states
    @State private var showEditName = false
    @State private var showEditEmail = false
    @State private var showEditPhone = false
    @State private var showChangePhoto = false
    @State private var showClearCacheAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Section
                profileSection

                // Notifications Section
                notificationsSection

                // Storage Section
                storageSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.wiseGroupedBackground)
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEditName) {
            ProfileEditFieldSheet(
                title: "Edit Name",
                value: Binding(
                    get: { profileManager.profile.name },
                    set: { newValue in
                        var profile = profileManager.profile
                        profile.name = newValue
                        profileManager.updateProfile(profile)
                    }
                ),
                placeholder: "Enter name",
                keyboardType: .default
            )
        }
        .sheet(isPresented: $showEditEmail) {
            ProfileEditFieldSheet(
                title: "Edit Email",
                value: Binding(
                    get: { profileManager.profile.email },
                    set: { newValue in
                        var profile = profileManager.profile
                        profile.email = newValue
                        profileManager.updateProfile(profile)
                    }
                ),
                placeholder: "Enter email",
                keyboardType: .emailAddress
            )
        }
        .sheet(isPresented: $showEditPhone) {
            ProfileEditFieldSheet(
                title: "Edit Phone",
                value: Binding(
                    get: { profileManager.profile.phone },
                    set: { newValue in
                        var profile = profileManager.profile
                        profile.phone = newValue
                        profileManager.updateProfile(profile)
                    }
                ),
                placeholder: "Enter phone",
                keyboardType: .phonePad
            )
        }
        .sheet(isPresented: $showChangePhoto) {
            ProfileChangePhotoSheet(profileManager: profileManager)
        }
        .alert("Clear Cache?", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear temporary files and cached data. Your personal data will not be affected.")
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "PROFILE")

            VStack(spacing: 0) {
                // Profile photo
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showChangePhoto = true
                }) {
                    HStack(spacing: 16) {
                        AvatarView(
                            avatarType: profileManager.profile.avatarType,
                            size: .large,
                            style: .solid
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Photo")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Tap to change")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.leading, 76)

                // Name
                SettingsRowButton(
                    label: "Name",
                    value: profileManager.profile.name.isEmpty ? "Add name" : profileManager.profile.name,
                    showDivider: true
                ) {
                    showEditName = true
                }

                // Email
                SettingsRowButton(
                    label: "Email",
                    value: profileManager.profile.email.isEmpty ? "Add email" : profileManager.profile.email,
                    showDivider: true
                ) {
                    showEditEmail = true
                }

                // Phone
                SettingsRowButton(
                    label: "Phone",
                    value: profileManager.profile.phone.isEmpty ? "Add phone" : profileManager.profile.phone,
                    showDivider: false
                ) {
                    showEditPhone = true
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "NOTIFICATIONS")

            VStack(spacing: 0) {
                // System notifications permission
                if !notificationManager.isAuthorized {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        Task {
                            if notificationManager.permissionStatus == .denied {
                                notificationManager.openSettings()
                            } else {
                                _ = await notificationManager.requestPermission()
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.wiseWarning.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.wiseWarning)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Notifications")
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wisePrimaryText)
                                Text("Allow Swiff to send alerts")
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.wiseSecondaryText.opacity(0.5))
                        }
                        .padding(16)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider().padding(.leading, 68)
                }

                // Transaction alerts
                SettingsToggleRow(
                    title: "Transaction alerts",
                    isOn: $userSettings.notificationsEnabled,
                    showDivider: true
                )

                // Security alerts
                SettingsToggleRow(
                    title: "Security alerts",
                    isOn: Binding(
                        get: { userSettings.notificationsEnabled },
                        set: { userSettings.notificationsEnabled = $0 }
                    ),
                    showDivider: true
                )

                // Weekly summary
                SettingsToggleRow(
                    title: "Weekly summary",
                    isOn: $userSettings.subscriptionReminders,
                    showDivider: true
                )

                // Promotions
                SettingsToggleRow(
                    title: "Promotions",
                    isOn: $userSettings.paymentReminders,
                    showDivider: false
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "STORAGE")

            VStack(spacing: 0) {
                // Storage info
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.wiseBlue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "externaldrive.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.wiseBlue)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Usage")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                        Text(getStorageSize())
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()
                }
                .padding(16)

                Divider().padding(.leading, 68)

                // Clear cache button
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showClearCacheAlert = true
                }) {
                    HStack {
                        Text("Clear Cache")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wiseError)

                        Spacer()

                        Text(getCacheSize())
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Functions

    private func getStorageSize() -> String {
        // Calculate approximate storage used
        return "< 1 MB"
    }

    private func getCacheSize() -> String {
        return "0 KB"
    }

    private func clearCache() {
        HapticManager.shared.notification(.success)
        ToastManager.shared.showSuccess("Cache cleared")
    }
}

// MARK: - Reusable Components

struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

struct SettingsRowButton: View {
    let label: String
    let value: String
    let showDivider: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            VStack(spacing: 0) {
                HStack {
                    Text(label)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    Text(value)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))
                        .padding(.leading, 8)
                }
                .padding(16)

                if showDivider {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.wisePrimaryButton)
            }
            .padding(16)

            if showDivider {
                Divider().padding(.leading, 16)
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileSettingsPage()
    }
}
