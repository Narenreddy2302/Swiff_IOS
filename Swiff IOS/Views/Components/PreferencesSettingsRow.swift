//
//  PreferencesSettingsRow.swift
//  Swiff IOS
//
//  Reusable row component for the Preferences section
//

import SwiftUI

struct PreferencesSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon circle - standardized 40pt
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(iconColor)
                    )

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(2)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wiseSecondaryText.opacity(0.5))
            }
            .padding(16)

            // Divider
            if showDivider {
                Divider()
                    .padding(.leading, 68) // 16 (padding) + 40 (icon) + 12 (spacing)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        PreferencesSettingsRow(
            icon: "person.fill",
            iconColor: .wiseBlue,
            title: "Profile Settings",
            subtitle: "Profile, notifications & storage",
            showDivider: true
        )

        PreferencesSettingsRow(
            icon: "lock.shield.fill",
            iconColor: .wiseForestGreen,
            title: "Privacy & Security",
            subtitle: "Control access and security settings",
            showDivider: true
        )

        PreferencesSettingsRow(
            icon: "arrow.up.forward.square.fill",
            iconColor: .wiseBrightGreen,
            title: "Analytics & Insights",
            subtitle: "View spending insights and trends",
            showDivider: true
        )

        PreferencesSettingsRow(
            icon: "questionmark.circle.fill",
            iconColor: .wiseOrange,
            title: "Help & Support",
            subtitle: "Get help using Swiff",
            showDivider: false
        )
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseGroupedBackground)
}
