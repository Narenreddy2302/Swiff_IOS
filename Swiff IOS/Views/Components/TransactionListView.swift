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
                .font(.system(size: 20, weight: .bold))
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
                        AlignedDivider()
                    }
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview("TransactionListView - Mixed") {
    ScrollView {
        VStack(spacing: 24) {
            TransactionListView(
                sectionTitle: "Recent",
                transactions: [
                    MockData.incomeTransaction,
                    MockData.expenseTransaction,
                    MockData.pendingTransaction
                ]
            )

            TransactionListView(
                sectionTitle: "This Week",
                transactions: [
                    MockData.groceryTransaction,
                    MockData.diningTransaction,
                    MockData.transportTransaction
                ]
            )
        }
        .padding()
    }
    .background(Color.wiseGroupedBackground)
}

#Preview("TransactionListView - Edge Cases") {
    ScrollView {
        TransactionListView(
            sectionTitle: "All Transactions",
            transactions: [
                MockData.largeTransaction,
                MockData.smallTransaction,
                MockData.entertainmentTransaction
            ]
        )
        .padding()
    }
    .background(Color.wiseGroupedBackground)
}
