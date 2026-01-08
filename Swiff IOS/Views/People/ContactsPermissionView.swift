//
//  ContactsPermissionView.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  View shown when contacts permission is needed
//

import SwiftUI

struct ContactsPermissionView: View {
    @StateObject private var permissionManager = SystemPermissionManager.shared
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.brandPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(Theme.Colors.brandPrimary)
            }

            // Title
            Text("Connect Your Contacts")
                .font(.spotifyHeadingLarge)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            // Description
            Text("See which of your contacts are on Swiff and easily invite friends to split bills together.")
                .font(.spotifyBodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                // Allow Access Button
                Button(action: requestPermission) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Text("Allow Access")
                        }
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(Theme.Colors.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.brandPrimary)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)

                // Settings Button (shown if denied)
                if permissionManager.contactsStatus == .denied {
                    Button(action: openSettings) {
                        Text("Open Settings")
                            .font(.spotifyLabelLarge)
                            .foregroundColor(Theme.Colors.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.Colors.border)
                            .cornerRadius(12)
                    }

                    Text("Contacts access was denied. You can enable it in Settings.")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.Colors.background)
        .onChange(of: permissionManager.contactsStatus) { oldValue, newValue in
            // When permission is granted, trigger contacts sync
            if newValue == .authorized {
                Task {
                    await ContactSyncManager.shared.syncContacts()
                }
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            do {
                _ = try await permissionManager.requestContactsPermission()
            } catch {
                // Error handled by permission manager state
            }
            isRequesting = false
        }
    }

    private func openSettings() {
        permissionManager.openAppSettings()
    }
}

#Preview {
    ContactsPermissionView()
}
