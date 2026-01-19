//
//  TransactionDetailsCard.swift
//  Swiff IOS
//
//  Nested card component showing transaction breakdown details
//  Used in timeline bubbles to display bill total, payer, and amounts owed
//

import SwiftUI

// MARK: - Transaction Details Card

struct TransactionDetailsCard: View {
    let billTotal: Double
    let paidBy: String
    let youOwe: Double

    var body: some View {
        VStack(spacing: 6) {
            DetailRow(label: "Bill total", value: formatCurrency(billTotal), isHighlighted: false)
            DetailRow(label: "Paid by", value: paidBy, isHighlighted: false)

            // You owe - consistent font, muted red
            HStack {
                Text("You owe")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
                Spacer()
                Text(formatCurrency(youOwe))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.amountNegative)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.wiseCardBackground)
        .cornerRadius(8)
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    let isHighlighted: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.wiseSecondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isHighlighted ? .amountNegative : .wisePrimaryText)
        }
    }
}

// MARK: - Preview

#Preview("Transaction Details Card") {
    VStack(spacing: 16) {
        TransactionDetailsCard(
            billTotal: 180.00,
            paidBy: "Emma Wilson",
            youOwe: 60.00
        )

        TransactionDetailsCard(
            billTotal: 450.00,
            paidBy: "James Chen",
            youOwe: 150.00
        )

        TransactionDetailsCard(
            billTotal: 90.00,
            paidBy: "You",
            youOwe: 0.00
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}
