//
//  TransactionListView.swift
//  Swiff IOS
//
//  Grouped transaction list with section title and dividers
//

import SwiftUI

// MARK: - Transaction List View

/// A grouped list of transactions with a section title.
/// Displays transactions in a card with dividers between items.
struct TransactionListView: View {
    let sectionTitle: String
    let transactions: [Transaction]
    var onTransactionTap: ((Transaction) -> Void)? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text(sectionTitle)
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.bottom, 12)

            // Transaction list
            VStack(spacing: 0) {
                ForEach(transactions) { transaction in
                    TransactionRowView(transaction: transaction) {
                        onTransactionTap?(transaction)
                    }

                    // Divider between items (not after last item)
                    if transaction.id != transactions.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview("TransactionListView") {
    ScrollView {
        VStack(spacing: 24) {
            TransactionListView(
                sectionTitle: "Today",
                transactions: [
                    Transaction(
                        id: UUID(),
                        title: "Transfer to Access Bank",
                        subtitle: "Bank transfer",
                        amount: -1000.00,
                        category: .transfer,
                        date: Date(),
                        isRecurring: false,
                        tags: []
                    ),
                    Transaction(
                        id: UUID(),
                        title: "Salary Deposit",
                        subtitle: "Monthly income",
                        amount: 5000.00,
                        category: .income,
                        date: Date().addingTimeInterval(-3600),
                        isRecurring: false,
                        tags: []
                    ),
                    Transaction(
                        id: UUID(),
                        title: "Online Purchase",
                        subtitle: "Shopping",
                        amount: -150.00,
                        category: .shopping,
                        date: Date().addingTimeInterval(-7200),
                        isRecurring: false,
                        tags: [],
                        paymentStatus: .pending
                    )
                ]
            )

            TransactionListView(
                sectionTitle: "Yesterday",
                transactions: [
                    Transaction(
                        id: UUID(),
                        title: "Grocery Store",
                        subtitle: "Groceries",
                        amount: -75.50,
                        category: .groceries,
                        date: Date().addingTimeInterval(-86400),
                        isRecurring: false,
                        tags: []
                    ),
                    Transaction(
                        id: UUID(),
                        title: "Gas Station",
                        subtitle: "Transportation",
                        amount: -45.00,
                        category: .transportation,
                        date: Date().addingTimeInterval(-90000),
                        isRecurring: false,
                        tags: []
                    )
                ]
            )
        }
        .padding()
    }
    .background(Color.wiseGroupedBackground)
}
