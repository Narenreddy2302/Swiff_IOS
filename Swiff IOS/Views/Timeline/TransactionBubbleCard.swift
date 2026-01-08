//
//  TransactionBubbleCard.swift
//  Swiff IOS
//
//  Created for Swiff iOS Redesign
//  Matches precise design from user request:
//  - Label outside: "Who Created the transaction"
//  - Card with Title, Amount/State
//  - Details: Total, Paid by, Split Method, Involved
//

import SwiftUI

struct TransactionBubbleCard: View {
    // Flexible Data Model for current & future uses
    let headerText: String
    let title: String
    let amountString: String
    let amountLabel: String  // e.g. "You Owe" or "You Sent"
    let amountColor: Color

    // Dynamic List of details
    struct DetailRow: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
    let details: [DetailRow]

    init(
        headerText: String,
        title: String,
        amountString: String,
        amountLabel: String,
        amountColor: Color = Theme.Colors.amountNegative,
        details: [DetailRow]
    ) {
        self.headerText = headerText
        self.title = title
        self.amountString = amountString
        self.amountLabel = amountLabel
        self.amountColor = amountColor
        self.details = details
    }

    // Convenience init for Transaction (backward compatibility / ease of use)
    init(transaction: Transaction, personName: String) {
        // Determine header
        let isCreator = transaction.isExpense  // Simple logic: Expense = You created
        self.headerText =
            isCreator ? "You Created the transaction" : "\(personName) Created the transaction"

        self.title = transaction.title
        self.amountString = transaction.formattedAmount
        self.amountLabel = "You Owe"
        self.amountColor = Theme.Colors.amountNegative  // Matching image color (Orange/Red)

        // Mock Details
        self.details = [
            DetailRow(
                label: "Total Bill",
                value: TransactionBubbleCard.formatCurrency(abs(transaction.amount * 3))),
            DetailRow(label: "Paid by", value: isCreator ? "You" : personName),
            DetailRow(label: "Split Method", value: "Equally"),
            DetailRow(label: "Who are all involved", value: "You, \(personName)"),
        ]
    }

    // Convenience init for Payment items
    init(payment amount: Double, direction: PaymentDirection, description: String, personName: String, date: Date) {
        self.headerText = direction == .outgoing
            ? "You sent a payment"
            : "\(personName) sent a payment"
        self.title = description.isEmpty ? "Payment" : description
        self.amountString = TransactionBubbleCard.formatCurrency(amount)
        self.amountLabel = direction == .outgoing ? "You Sent" : "You Received"
        self.amountColor = direction == .outgoing
            ? Theme.Colors.amountNegative
            : Theme.Colors.amountPositive
        self.details = [
            DetailRow(label: "Amount", value: TransactionBubbleCard.formatCurrency(amount)),
            DetailRow(label: "Date", value: TransactionBubbleCard.formatDate(date)),
        ]
    }

    // Convenience init for PaidBill items
    init(paidBill personName: String, date: Date) {
        self.headerText = "\(personName) paid the bill"
        self.title = "Bill Paid"
        self.amountString = ""
        self.amountLabel = "Confirmed"
        self.amountColor = Theme.Colors.amountPositive
        self.details = [
            DetailRow(label: "Paid by", value: personName),
            DetailRow(label: "Date", value: TransactionBubbleCard.formatDate(date)),
        ]
    }

    // Convenience init for GroupExpense items
    init(groupExpense expense: GroupExpense, payer: Person?, splitMembers: [Person]) {
        self.headerText = payer != nil
            ? "\(payer!.name) Created the transaction"
            : "Someone Created the transaction"
        self.title = expense.title
        self.amountString = TransactionBubbleCard.formatCurrency(expense.amountPerPerson)
        self.amountLabel = "You Owe"
        self.amountColor = Theme.Colors.amountNegative
        self.details = [
            DetailRow(label: "Total Bill", value: TransactionBubbleCard.formatCurrency(expense.amount)),
            DetailRow(label: "Paid by", value: payer?.name ?? "Unknown"),
            DetailRow(label: "Split Method", value: "Equally"),
            DetailRow(label: "Who are all involved", value: "\(splitMembers.count) members"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 1. "Who Created" label
            Text(headerText)
                .font(.system(size: 13, weight: .medium))  // Slightly larger than caption
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.leading, 8)  // Align with curve start roughly

            // 2. The Card
            VStack(spacing: 20) {  // Spacing between Header Row and Details
                // Header Row
                HStack(alignment: .top) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // Amount / Label e.g. "$ 9.99 / You Own"
                    HStack(spacing: 4) {
                        Text("\(amountString) /")
                            .font(.system(size: 16, weight: .bold))
                        Text(amountLabel)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(amountColor)
                }

                // Details
                VStack(spacing: 10) {
                    ForEach(details) { row in
                        HStack(alignment: .top) {
                            Text(row.label)
                                .font(.system(size: 14, weight: .bold))  // Bold Label
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            Text(row.value)
                                .font(.system(size: 14, weight: .bold))  // Bold Value
                                .foregroundColor(Theme.Colors.textPrimary)  // Dark text for value
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .padding(20)  // Generous padding inside card
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))  // Specific large radius
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Theme.Colors.border, lineWidth: 1.5)  // Distinct border
            )
        }
        .padding(.vertical, 4)
    }

    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
