//
//  UniversalListRow.swift
//  Swiff IOS
//
//  Created for Unified Professional Design System
//  The single source of truth for all list rows in the application.
//  Supports Transactions, People, Subscriptions, and Groups.
//

import SwiftUI

// MARK: - Icon Configuration
enum UniversalIconConfig {
    case system(name: String, color: Color)
    case initials(text: String, backgroundColor: Color)
    case emoji(text: String, backgroundColor: Color)
    // Add image case later if needed
}

// MARK: - Universal List Row
struct UniversalListRow: View {
    // Content
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color

    // Optional Content
    var valueLabel: String? = nil
    var icon: UniversalIconConfig
    var showChevron: Bool = false
    var onTap: (() -> Void)? = nil

    // Layout Constants - Matching screenshot exactly
    private let avatarSize: CGFloat = 56  // Avatar size from screenshot
    private let verticalPadding: CGFloat = 10  // Compact vertical spacing
    private let horizontalPadding: CGFloat = 16

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Avatar Area
                iconView

                // Main Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255))  // iOS system gray
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Right Side Content
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(valueColor)
                        .lineLimit(1)

                    if let label = valueLabel {
                        Text(label)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(
                                Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
                            )  // iOS system gray
                            .lineLimit(1)
                    }
                }

                // Navigation Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wiseSecondaryText.opacity(0.7))
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .contentShape(Rectangle())  // Ensures full row is tappable
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            switch icon {
            case .system(let name, let color):
                Circle()
                    .fill(color.opacity(0.15))  // Softer background
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Image(systemName: name)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(color)
                    )

            case .initials(let text, let backgroundColor):
                Circle()
                    .fill(backgroundColor)
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay {
                        if text.lowercased() == "uber" {
                            Text(text)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            // Regular initials for other entries
                            Text(InitialsGenerator.generate(from: text))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

            case .emoji(let text, let backgroundColor):
                Circle()
                    .fill(backgroundColor)
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Text(text)
                            .font(.system(size: 26))
                    )
            }
        }
    }
}

// MARK: - Preview
#Preview("Universal Row Variants") {
    VStack(spacing: 0) {
        // Transaction - Income
        UniversalListRow(
            title: "Apple Inc.",
            subtitle: "Salary • Direct Deposit",
            value: "+$3,500.00",
            valueColor: .wiseBrightGreen,
            valueLabel: "Today",
            icon: .system(name: "apple.logo", color: .wiseBrightGreen)
        )

        AlignedDivider()

        // Transaction - Expense
        UniversalListRow(
            title: "Starbucks Coffee",
            subtitle: "Food & Dining • 10:30 AM",
            value: "-$6.50",
            valueColor: .wisePrimaryText,
            valueLabel: nil,
            icon: .initials(text: "SC", backgroundColor: InitialsAvatarColors.yellow)
        )

        AlignedDivider()

        // Person
        UniversalListRow(
            title: "Sarah Miller",
            subtitle: "Owes you • Last active 2h ago",
            value: "$45.00",
            valueColor: .wiseBrightGreen,
            valueLabel: nil,
            icon: .initials(text: "SM", backgroundColor: InitialsAvatarColors.purple),
            showChevron: true
        )

        AlignedDivider()

        // Group
        UniversalListRow(
            title: "Trip to Paris",
            subtitle: "4 members • Settled",
            value: "$0.00",
            valueColor: .wiseSecondaryText,
            valueLabel: nil,
            icon: .emoji(text: "🇫🇷", backgroundColor: .wiseBlue.opacity(0.1)),
            showChevron: true
        )
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}
