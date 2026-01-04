//
//  TransactionListView.swift
//  Swiff IOS
//
//  Grouped transaction list with section title and dividers
//  Updated to match reference design
//

import SwiftUI

// MARK: - Transaction List View

/// A grouped list of transactions with a section title.
/// Displays transactions in a white card with dividers between items.
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
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Transaction list in card
            VStack(spacing: 0) {
                ForEach(transactions) { transaction in
                    ListRowFactory.row(for: transaction) {
                        onTransactionTap?(transaction)
                    }
                    .background(Color.wiseCardBackground)

                    // Divider between items (not after last item)
                    if transaction.id != transactions.last?.id {
                        Divider()
                            .padding(.leading, 84)  // Align with text
                            .background(Color.wiseCardBackground)
                    }
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
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
        .padding(.vertical)
    }
    .background(Color.wiseTertiaryBackground)
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
    .background(Color.wiseTertiaryBackground)
}
