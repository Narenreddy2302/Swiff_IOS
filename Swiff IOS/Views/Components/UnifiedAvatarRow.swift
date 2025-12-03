//
//  UnifiedAvatarRow.swift
//  Swiff IOS
//
//  Created for Unified List View Design System - Phase 1
//  List row variant using AvatarView for people/contacts
//

import SwiftUI

// MARK: - Unified Avatar Row

/// List row variant that uses AvatarView instead of icon circles.
/// Primarily used for displaying people, contacts, or personalized items.
/// Maintains the same flat design as UnifiedListRowV2.
struct UnifiedAvatarRow: View {
    // Required parameters
    let avatarType: AvatarType        // .photo(Data), .emoji(String), .initials(String, colorIndex: Int)
    let title: String                 // Main text (e.g., person name)
    let subtitle: String              // Subtitle (e.g., email, balance info)
    let value: String                 // Amount or value text
    let valueColor: Color             // Color for value text

    // Optional parameters
    var showChevron: Bool = false     // Show navigation chevron
    var onTap: (() -> Void)? = nil    // Tap handler

    // Animation state
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback on tap
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Avatar (48x48)
                AvatarView(
                    avatarType: avatarType,
                    size: .large,        // 48x48
                    style: .solid
                )

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Value
                Text(value)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(valueColor)
                    .lineLimit(1)

                // Optional Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Preview

#Preview("UnifiedAvatarRow Examples") {
    ScrollView {
        VStack(spacing: 0) {
            Text("People / Contacts List")
                .font(.spotifyHeadingLarge)
                .padding()

            // Person with initials avatar - owes you
            UnifiedAvatarRow(
                avatarType: .initials("JD", colorIndex: 0),
                title: "John Doe",
                subtitle: "john.doe@email.com",
                value: "+ $150.00",
                valueColor: .wiseBrightGreen,
                showChevron: true,
                onTap: { print("Tapped John") }
            )

            Divider()
                .padding(.leading, 76)

            // Person with initials avatar - you owe
            UnifiedAvatarRow(
                avatarType: .initials("AS", colorIndex: 1),
                title: "Alice Smith",
                subtitle: "alice.smith@email.com",
                value: "– $75.50",
                valueColor: .wiseError,
                showChevron: true,
                onTap: { print("Tapped Alice") }
            )

            Divider()
                .padding(.leading, 76)

            // Person with emoji avatar - balanced
            UnifiedAvatarRow(
                avatarType: .emoji("🎉"),
                title: "Bob Johnson",
                subtitle: "bob@email.com",
                value: "$0.00",
                valueColor: .wiseSecondaryText,
                showChevron: true,
                onTap: { print("Tapped Bob") }
            )

            Divider()
                .padding(.leading, 76)

            // Person with different color initials
            UnifiedAvatarRow(
                avatarType: .initials("MK", colorIndex: 2),
                title: "Maria Kim",
                subtitle: "maria.kim@email.com",
                value: "+ $200.00",
                valueColor: .wiseBrightGreen,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Person with emoji
            UnifiedAvatarRow(
                avatarType: .emoji("🚀"),
                title: "Tech Team",
                subtitle: "Group • 5 members",
                value: "+ $450.00",
                valueColor: .wiseBrightGreen,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Person with initials - small debt
            UnifiedAvatarRow(
                avatarType: .initials("RP", colorIndex: 3),
                title: "Rachel Park",
                subtitle: "rachel@email.com",
                value: "– $12.00",
                valueColor: .wiseError,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Person with emoji avatar
            UnifiedAvatarRow(
                avatarType: .emoji("🏠"),
                title: "Roommates",
                subtitle: "Shared expenses",
                value: "+ $320.50",
                valueColor: .wiseBrightGreen,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Person with initials
            UnifiedAvatarRow(
                avatarType: .initials("TW", colorIndex: 4),
                title: "Tom Wilson",
                subtitle: "tom.wilson@email.com",
                value: "$0.00",
                valueColor: .wiseSecondaryText,
                showChevron: true
            )

            Spacer()
        }
    }
    .background(Color.wiseBackground)
}

#Preview("UnifiedAvatarRow Mixed Styles") {
    VStack(spacing: 0) {
        Text("Mixed Avatar Styles")
            .font(.spotifyHeadingMedium)
            .padding()

        // Initials
        UnifiedAvatarRow(
            avatarType: .initials("JD", colorIndex: 0),
            title: "John Doe",
            subtitle: "Owes you for dinner",
            value: "+ $45.00",
            valueColor: .wiseBrightGreen,
            showChevron: true
        )

        Divider()
            .padding(.leading, 76)

        // Emoji
        UnifiedAvatarRow(
            avatarType: .emoji("🎨"),
            title: "Creative Team",
            subtitle: "Shared subscription",
            value: "– $15.00",
            valueColor: .wiseError,
            showChevron: true
        )

        Divider()
            .padding(.leading, 76)

        // Different color initials
        UnifiedAvatarRow(
            avatarType: .initials("SK", colorIndex: 5),
            title: "Sarah Kim",
            subtitle: "Coffee split",
            value: "+ $4.50",
            valueColor: .wiseBrightGreen,
            showChevron: true
        )

        Spacer()
    }
    .background(Color.wiseBackground)
}

#Preview("UnifiedAvatarRow Compact") {
    VStack(spacing: 0) {
        UnifiedAvatarRow(
            avatarType: .initials("AB", colorIndex: 1),
            title: "Anna Brown",
            subtitle: "anna@email.com",
            value: "+ $100.00",
            valueColor: .wiseBrightGreen,
            showChevron: true
        )

        Divider()
            .padding(.leading, 76)

        UnifiedAvatarRow(
            avatarType: .emoji("✈️"),
            title: "Travel Group",
            subtitle: "Trip expenses",
            value: "– $425.00",
            valueColor: .wiseError,
            showChevron: true
        )
    }
    .background(Color.wiseBackground)
}
