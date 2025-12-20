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

#Preview("Transaction Bubbles") {
    ScrollView {
        VStack(spacing: 16) {
            // Incoming (person owes you) - unsettled
            TransactionBubble(
                transaction: Transaction(
                    title: "Dinner at La Piazza",
                    subtitle: "Split bill payment",
                    amount: 45.50,
                    category: .food,
                    date: Date().addingTimeInterval(-3600),
                    isRecurring: false,
                    tags: [],
                    paymentStatus: .pending
                ),
                person: Person(
                    name: "Alex Thompson",
                    email: "alex@example.com",
                    phone: "+1234567890",
                    avatarType: .initials("AT", colorIndex: 0)
                ),
                onSettleTap: {},
                onRemindTap: {}
            )

            // Outgoing (you owe person) - unsettled
            TransactionBubble(
                transaction: Transaction(
                    title: "Concert tickets",
                    subtitle: "Ticket reimbursement",
                    amount: -125.00,
                    category: .entertainment,
                    date: Date().addingTimeInterval(-7200),
                    isRecurring: false,
                    tags: [],
                    paymentStatus: .pending
                ),
                person: Person(
                    name: "Maria Santos",
                    email: "maria@example.com",
                    phone: "+1234567890",
                    avatarType: .initials("MS", colorIndex: 2)
                ),
                onSettleTap: {},
                onRemindTap: {}
            )

            // Incoming - settled
            TransactionBubble(
                transaction: Transaction(
                    title: "Grocery split",
                    subtitle: "Whole Foods payment",
                    amount: 38.75,
                    category: .groceries,
                    date: Date().addingTimeInterval(-86400),
                    isRecurring: false,
                    tags: [],
                    paymentStatus: .completed
                ),
                person: Person(
                    name: "Jordan Lee",
                    email: "jordan@example.com",
                    phone: "+1234567890",
                    avatarType: .initials("JL", colorIndex: 4)
                )
            )

            // Outgoing - settled
            TransactionBubble(
                transaction: Transaction(
                    title: "Uber ride",
                    subtitle: "Trip reimbursement",
                    amount: -22.50,
                    category: .transportation,
                    date: Date().addingTimeInterval(-172800),
                    isRecurring: false,
                    tags: [],
                    paymentStatus: .completed
                ),
                person: Person(
                    name: "David Kim",
                    email: "david@example.com",
                    phone: "+1234567890",
                    avatarType: .initials("DK", colorIndex: 1)
                )
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
