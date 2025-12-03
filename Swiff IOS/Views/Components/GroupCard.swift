//
//  GroupCard.swift
//  Swiff IOS
//
//  Card-based group display with emoji, member count, and expenses
//

import SwiftUI

// MARK: - Group Card

/// Card-based group display with emoji circle, member count, and total expenses.
/// Shows summary: "4 members • 12 expenses"
struct GroupCard: View {
    let group: Group
    var onTap: (() -> Void)? = nil

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

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Outlined Emoji Circle
                Circle()
                    .stroke(Color.wiseBlue, lineWidth: 2)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(group.emoji)
                            .font(.system(size: 24))
                    )

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    // Group Name
                    Text(group.name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    // Summary Line
                    HStack(spacing: 4) {
                        Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text("•")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Total Amount
                Text(amountText)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Preview

#Preview("GroupCard") {
    VStack(spacing: 12) {
        GroupCard(
            group: Group(
                name: "Vacation Trip",
                description: "Summer vacation expenses",
                emoji: "🏖️",
                members: [UUID(), UUID(), UUID(), UUID()]
            )
        )
    }
    .padding()
    .background(Color.wiseGroupedBackground)
}
