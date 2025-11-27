//
//  QuickActionRow.swift
//  Swiff IOS
//
//  Reusable action list item with icon, title, subtitle, and chevron indicator
//

import SwiftUI

// MARK: - QuickActionRow Component

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    init(
        icon: String,
        title: String,
        iconColor: Color,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            HStack(spacing: 12) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wiseGray)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .cardShadow()
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
        .accessibilityLabel(title + (subtitle != nil ? ", \(subtitle!)" : ""))
        .accessibilityHint("Double tap to \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("Quick Action Rows") {
    VStack(spacing: 16) {
        QuickActionRow(
            icon: "person.crop.circle.fill",
            title: "Edit Profile",
            iconColor: .wiseForestGreen,
            subtitle: "Update your personal information"
        ) {
            print("Edit Profile tapped")
        }

        QuickActionRow(
            icon: "bell.fill",
            title: "Notifications",
            iconColor: .wiseBlue,
            subtitle: "Manage your notification preferences"
        ) {
            print("Notifications tapped")
        }

        QuickActionRow(
            icon: "lock.fill",
            title: "Privacy & Security",
            iconColor: .wiseOrange
        ) {
            print("Privacy tapped")
        }
    }
    .padding()
    .background(Color.wiseBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        QuickActionRow(
            icon: "creditcard.fill",
            title: "Payment Methods",
            iconColor: .wisePurple,
            subtitle: "Add or remove payment cards"
        ) {
            print("Payment Methods tapped")
        }

        QuickActionRow(
            icon: "questionmark.circle.fill",
            title: "Help & Support",
            iconColor: .wiseAccentBlue,
            subtitle: "Get help with your account"
        ) {
            print("Help tapped")
        }
    }
    .padding()
    .background(Color.wiseBackground)
    .preferredColorScheme(.dark)
}

#Preview("Different Colors") {
    ScrollView {
        VStack(spacing: 12) {
            QuickActionRow(
                icon: "chart.bar.fill",
                title: "Analytics",
                iconColor: .wiseForestGreen,
                subtitle: "View your spending insights"
            ) {}

            QuickActionRow(
                icon: "calendar.badge.clock",
                title: "Subscription Calendar",
                iconColor: .wiseBlue,
                subtitle: "See all upcoming renewals"
            ) {}

            QuickActionRow(
                icon: "dollarsign.circle.fill",
                title: "Budget Manager",
                iconColor: .wiseOrange,
                subtitle: "Set and track your budgets"
            ) {}

            QuickActionRow(
                icon: "person.2.fill",
                title: "Shared Expenses",
                iconColor: .wisePurple,
                subtitle: "Manage group subscriptions"
            ) {}

            QuickActionRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Sync Data",
                iconColor: .wiseGreen,
                subtitle: "Last synced 2 minutes ago"
            ) {}

            QuickActionRow(
                icon: "doc.text.fill",
                title: "Export Reports",
                iconColor: .wiseSecondaryText
            ) {}
        }
        .padding()
    }
    .background(Color.wiseBackground)
}
