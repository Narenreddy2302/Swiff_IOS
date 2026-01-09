//
//  TransactionBubbleCard.swift
//  Swiff IOS
//
//  Created for Swiff iOS Redesign
//  Simple rectangular card design - clean and functional
//  Features:
//  - Label outside: "Who Created the transaction"
//  - Rectangular card with Title, Amount/State
//  - Details: Total Bill, Paid by, Split Method, Involved
//

import SwiftUI

struct TransactionBubbleCard: View {
    // Flexible Data Model
    let headerText: String
    let title: String
    let amountString: String
    let amountLabel: String  // e.g. "You Owe" or "You Sent"
    let amountColor: Color

    // Section for details
    struct DetailRow: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let valueColor: Color? = nil
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

    // MARK: - Convenience Initializers

    // 1. For standard Transactions (PersonDetailView)
    init(transaction: Transaction, personName: String) {
        let isCreator = transaction.isExpense  // Simple logic: Expense = You created
        self.headerText =
            isCreator ? "You Created the transaction" : "\(personName) Created the transaction"
        self.title = transaction.title
        self.amountString = transaction.formattedAmount

        // Logic for label: If I paid (Expense), they owe me. If they paid (Income), I owe them.
        self.amountLabel = transaction.isExpense ? "You Lent" : "You Owe"
        self.amountColor =
            transaction.isExpense ? .wiseBrightGreen : .wiseOrange  // Green if I lent (positive for me), Orange if I owe

        // Details
        self.details = [
            DetailRow(
                label: "Total Bill",
                value: TransactionBubbleCard.formatCurrency(abs(transaction.amount))),  // Assuming amount is share, normally we'd have total bill
            DetailRow(label: "Paid by", value: isCreator ? "You" : personName),
            DetailRow(label: "Split Method", value: "Equally"),  // Placeholder logic
            DetailRow(label: "Who are all involved", value: "You, \(personName)"),
        ]
    }

    // 2. For Group Expenses
    init(groupExpense expense: GroupExpense, payer: Person?, splitMembers: [Person]) {
        self.headerText =
            (payer != nil)
            ? "\(payer!.name) Created the transaction" : "Someone Created the transaction"
        self.title = expense.title
        self.amountString = TransactionBubbleCard.formatCurrency(expense.amountPerPerson)
        self.amountLabel = "Your Share"
        self.amountColor = .wiseOrange  // Orange for amounts you owe

        self.details = [
            DetailRow(
                label: "Total Bill", value: TransactionBubbleCard.formatCurrency(expense.amount)),
            DetailRow(label: "Paid by", value: payer?.name ?? "Unknown"),
            DetailRow(label: "Split Method", value: "Equally"),
            DetailRow(
                label: "Who are all involved",
                value: splitMembers.isEmpty
                    ? "All Members" : splitMembers.map { $0.name }.joined(separator: ", ")),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 1. "Who Created" label (Outside the card)
            Text(headerText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(UIColor.systemGray))
                .padding(.leading, 16)

            // 2. The Rectangular Card
            VStack(spacing: 14) {

                // --- Top Row: Title + Amount ---
                HStack(alignment: .top, spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    Spacer()

                    // Amount Stack: "$ 9.99 / You Owe"
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(amountString)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(amountColor)
                        
                        Text(amountLabel)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(amountColor.opacity(0.75))
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color(UIColor.separator).opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.horizontal, -14)

                // --- Details Section ---
                VStack(spacing: 9) {
                    ForEach(details) { row in
                        HStack(alignment: .top) {
                            Text(row.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(row.value)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)  // Simple rounded corners - rectangular style
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(UIColor.separator), lineWidth: 0.5)
            )
        }
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity)
    }

    // Formatting Helpers
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
