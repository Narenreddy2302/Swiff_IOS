//
//  GroupCard.swift
//  Swiff IOS
//
//  Clean row-based group display with emoji avatar
//  Updated to match new unified list design
//

import SwiftUI

// MARK: - Group Card

/// Clean row-based group display with emoji in colored circle.
/// Shows emoji avatar, group name, member/expense counts, and total amount.
/// Design: 44x44 avatar with emoji, 14pt gap, clean row layout.
struct GroupCard: View {
    let group: Group

    // MARK: - Computed Properties

    private var memberCount: Int {
        group.members.count
    }

    private var expenseCount: Int {
        group.expenses.count
    }

    private var totalAmount: Double {
        group.totalAmount > 0 ? group.totalAmount : group.expenses.reduce(0.0) { $0 + $1.amount }
    }

    private var amountText: String {
        String(format: "$%.2f", totalAmount)
    }

    private var summaryText: String {
        "\(memberCount) member\(memberCount == 1 ? "" : "s") • \(expenseCount) expense\(expenseCount == 1 ? "" : "s")"
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            // Emoji avatar in blue circle
            emojiAvatar

            // Text Content
            VStack(alignment: .leading, spacing: 3) {
                // Group Name
                Text(group.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                // Summary Line
                Text(summaryText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Total Amount
            Text(amountText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Emoji Avatar

    private var emojiAvatar: some View {
        Circle()
            .fill(Color.wiseBlue)
            .frame(width: 44, height: 44)
            .overlay(
                Text(group.emoji)
                    .font(.system(size: 22))
            )
    }
}

// MARK: - Preview

#Preview("GroupCard - New Design") {
    VStack(spacing: 0) {
        GroupCard(
            group: Group(
                name: "Dinner Club",
                description: "Monthly dinner group",
                emoji: "🍽️",
                members: [UUID()]
            )
        )

        AlignedDivider()

        GroupCard(
            group: Group(
                name: "Study Buddies",
                description: "Study group expenses",
                emoji: "📚",
                members: [UUID(), UUID(), UUID(), UUID()]
            )
        )

        AlignedDivider()

        GroupCard(
            group: Group(
                name: "Weekend Getaway",
                description: "Trip expenses",
                emoji: "🏖️",
                members: [UUID(), UUID()]
            )
        )
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.wiseGroupedBackground)
}
