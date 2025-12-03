//
//  TransactionCard.swift
//  Swiff IOS
//
//  Card-based transaction display with outlined icon, status, and amount
//

import SwiftUI

// MARK: - Transaction Card

/// Card-based transaction display with outlined icon, status, and amount.
/// Shows status line format: "Successful • Visa • 3366 • 12th July, 2024"
struct TransactionCard: View {
    let transaction: Transaction
    let context: CardContext
    var subscription: Subscription? = nil
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var statusColor: Color {
        transaction.paymentStatus.color
    }

    private var statusText: String {
        transaction.paymentStatus.displayText
    }

    private var iconName: String {
        context.icon(for: transaction, subscription: subscription)
    }

    private var iconColor: Color {
        context.color(for: transaction, subscription: subscription)
    }

    private var amountText: String {
        transaction.formattedAmount
    }

    private var amountColor: Color {
        transaction.isExpense ? .wisePrimaryText : .wiseBrightGreen
    }

    private var paymentMethodText: String {
        transaction.paymentMethod?.shortName ?? "Card"
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Outlined Icon Circle
                OutlinedIconCircle(
                    icon: iconName,
                    color: iconColor,
                    size: 48,
                    strokeWidth: 2,
                    iconSize: 20
                )

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(transaction.title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    // Status Line
                    statusLine
                }

                Spacer(minLength: 8)

                // Amount
                Text(amountText)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(amountColor)
                    .lineLimit(1)
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(CardButtonStyle())
    }

    // MARK: - Status Line View

    @ViewBuilder
    private var statusLine: some View {
        HStack(spacing: 4) {
            // Status
            Text(statusText)
                .font(.spotifyBodySmall)
                .foregroundColor(statusColor)

            Text("•")
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)

            // Payment Method
            Text(paymentMethodText)
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)

            Text("•")
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)

            // Date
            Text(transaction.date.cardFormattedDate)
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)
        }
        .lineLimit(1)
    }
}

// MARK: - Preview

#Preview("TransactionCard") {
    VStack(spacing: 12) {
        TransactionCard(
            transaction: Transaction(
                id: UUID(),
                title: "Transfer to Access Bank",
                subtitle: "Bank transfer",
                amount: -1000.00,
                category: .transfer,
                date: Date(),
                isRecurring: false,
                tags: []
            ),
            context: .feed
        )
    }
    .padding()
    .background(Color.wiseGroupedBackground)
}
