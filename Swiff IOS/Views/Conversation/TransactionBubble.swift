//
//  TransactionBubble.swift
//  Swiff IOS
//
//  Transaction bubble for person conversation view
//  Shows transaction details in chat-style format
//

import SwiftUI

struct TransactionBubble: View {
    let transaction: Transaction
    let person: Person
    var onSettleTap: (() -> Void)?
    var onRemindTap: (() -> Void)?

    // Determine if this is incoming or outgoing based on transaction type
    private var bubbleType: BubbleType {
        // If transaction is positive (income), it's incoming (money to you)
        // If transaction is negative (expense), it's outgoing (money from you)
        transaction.isExpense ? .outgoing : .incoming
    }

    private var isSettled: Bool {
        transaction.paymentStatus == .completed
    }

    var body: some View {
        VStack(alignment: bubbleType == .incoming ? .leading : .trailing, spacing: 8) {
            // Main bubble content
            ConversationBubbleView(type: bubbleType) {
                VStack(alignment: bubbleType == .incoming ? .leading : .trailing, spacing: 8) {
                    // Category icon + title row
                    HStack(spacing: 8) {
                        if bubbleType == .incoming {
                            categoryIcon
                        }

                        VStack(alignment: bubbleType == .incoming ? .leading : .trailing, spacing: 4) {
                            Text(transaction.title)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text(transaction.subtitle)
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        if bubbleType == .outgoing {
                            categoryIcon
                        }
                    }

                    // Amount
                    Text(formattedAmount)
                        .font(.spotifyNumberMedium)
                        .fontWeight(.bold)
                        .foregroundColor(amountColor)

                    // Settlement status badge (if unsettled)
                    if !isSettled {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text("Pending")
                                .font(.spotifyCaptionSmall)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.wiseWarning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.wiseWarning.opacity(0.15))
                        )
                    }
                }
            }
            .padding(.horizontal, 16)

            // Timestamp
            Text(relativeTime)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, bubbleType == .incoming ? 20 : 16)

            // Quick action buttons (only for unsettled transactions)
            if !isSettled {
                QuickActionButtonGroup(
                    buttons: actionButtons,
                    alignment: bubbleType == .incoming ? .leading : .trailing,
                    spacing: 8
                )
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: bubbleType == .incoming ? .leading : .trailing)
    }

    // MARK: - Computed Properties

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(transaction.category.color.opacity(0.2))
                .frame(width: 24, height: 24)

            Image(systemName: transaction.category.icon)
                .font(.system(size: 12))
                .foregroundColor(transaction.category.color)
        }
    }

    private var formattedAmount: String {
        let sign = transaction.isExpense ? "- " : "+ "
        return "\(sign)\(transaction.formattedAmount)"
    }

    private var amountColor: Color {
        transaction.isExpense ? AmountColors.negative : AmountColors.positive
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: transaction.date, relativeTo: Date())
    }

    private var actionButtons: [QuickActionConfig] {
        var buttons: [QuickActionConfig] = []

        // Show Settle button for incoming transactions (person owes you)
        if bubbleType == .incoming, let onSettleTap = onSettleTap {
            buttons.append(
                QuickActionConfig(
                    title: "Settle",
                    icon: "checkmark.circle.fill",
                    style: .primary,
                    isCompact: true,
                    action: onSettleTap
                )
            )
        }

        // Show Remind button
        if let onRemindTap = onRemindTap {
            buttons.append(
                QuickActionConfig(
                    title: "Remind",
                    icon: "bell.fill",
                    style: .secondary,
                    isCompact: true,
                    action: onRemindTap
                )
            )
        }

        return buttons
    }
}

// MARK: - Preview

#Preview("TransactionBubble - Incoming Pending") {
    ScrollView {
        VStack(spacing: 16) {
            TransactionBubble(
                transaction: MockData.incomeTransaction,
                person: MockData.personOwedMoney,
                onSettleTap: {},
                onRemindTap: {}
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("TransactionBubble - Outgoing") {
    ScrollView {
        VStack(spacing: 16) {
            TransactionBubble(
                transaction: MockData.expenseTransaction,
                person: MockData.personOwingMoney,
                onSettleTap: {},
                onRemindTap: {}
            )

            TransactionBubble(
                transaction: MockData.diningTransaction,
                person: MockData.personFriend
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("TransactionBubble - Various Categories") {
    ScrollView {
        VStack(spacing: 16) {
            TransactionBubble(
                transaction: MockData.groceryTransaction,
                person: MockData.personSettled
            )

            TransactionBubble(
                transaction: MockData.transportTransaction,
                person: MockData.personFamily
            )

            TransactionBubble(
                transaction: MockData.entertainmentTransaction,
                person: MockData.personCoworker
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
