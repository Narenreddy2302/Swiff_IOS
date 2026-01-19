//
//  TransactionSection.swift
//  Swiff IOS
//
//  Legacy section container - kept for backward compatibility
//  New design uses inline rendering in RecentActivityView
//

import SwiftUI

struct TransactionSection: View {
    @EnvironmentObject var dataManager: DataManager
    let date: Date
    let transactions: [Transaction]
    let onDelete: (Transaction) -> Void
    @State private var selectedTransaction: Transaction?

    private var sectionTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sectionDay = calendar.startOfDay(for: date)
        let daysDifference = calendar.dateComponents([.day], from: sectionDay, to: today).day ?? 0

        switch daysDifference {
        case 0: return "TODAY"
        case 1: return "YESTERDAY"
        case 2...6: return "THIS WEEK"
        case 7...13: return "LAST WEEK"
        default: return "OLDER"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            FeedSectionHeader(title: sectionTitle)

            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                FeedTransactionRow(
                    transaction: transaction,
                    isLastInGroup: index == transactions.count - 1,
                    onTap: {
                        selectedTransaction = transaction
                        HapticManager.shared.light()
                    }
                )
                .padding(.horizontal, 20)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        HapticManager.shared.heavy()
                        onDelete(transaction)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailSheet(transaction: transaction)
                .environmentObject(dataManager)
        }
    }
}

// MARK: - Preview

#Preview("TransactionSection") {
    NavigationView {
        ScrollView {
            VStack(spacing: 0) {
                TransactionSection(
                    date: Date(),
                    transactions: [
                        Transaction(
                            title: "Starbucks Coffee",
                            subtitle: "Food & Dining",
                            amount: -6.50,
                            category: .food,
                            date: Date(),
                            isRecurring: false,
                            tags: [],
                            merchant: "Starbucks"
                        ),
                        Transaction(
                            title: "Uber Ride",
                            subtitle: "Transportation",
                            amount: -24.00,
                            category: .transportation,
                            date: Date(),
                            isRecurring: false,
                            tags: [],
                            merchant: "Uber"
                        ),
                        Transaction(
                            title: "Freelance Payment",
                            subtitle: "Income",
                            amount: 500.00,
                            category: .income,
                            date: Date(),
                            isRecurring: true,
                            tags: ["Freelance"]
                        ),
                    ],
                    onDelete: { _ in }
                )

                TransactionSection(
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    transactions: [
                        Transaction(
                            title: "Grocery Store",
                            subtitle: "Shopping",
                            amount: -85.00,
                            category: .groceries,
                            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                            isRecurring: false,
                            tags: [],
                            merchant: "Whole Foods"
                        )
                    ],
                    onDelete: { _ in }
                )
            }
        }
        .background(Color.white)
    }
    .environmentObject(DataManager.shared)
}
