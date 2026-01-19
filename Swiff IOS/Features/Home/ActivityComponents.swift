//
//  ActivityComponents.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter: ActivityFilter = .all
    @State private var showingFilterSheet = false
    @State private var selectedTransaction: Transaction?

    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case expenses = "Expenses"
        case income = "Income"
        case recurring = "Recurring"
    }

    var recentTransactions: [Transaction] {
        var filtered = dataManager.transactions

        switch selectedFilter {
        case .all:
            break
        case .expenses:
            filtered = filtered.filter { $0.isExpense }
        case .income:
            filtered = filtered.filter { !$0.isExpense }
        case .recurring:
            filtered = filtered.filter { $0.isRecurring }
        }

        return Array(
            filtered
                .sorted(by: { $0.date > $1.date })
                .prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(Theme.Fonts.headerLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button(action: { showingFilterSheet = true }) {
                    HStack(spacing: 4) {
                        Text(selectedFilter.rawValue)
                            .font(Theme.Fonts.labelMedium)
                        Image(systemName: "chevron.down")
                            .font(Theme.Fonts.captionMedium)
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.border)
                    .clipShape(Capsule())
                }
            }

            // Recent transactions
            if recentTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))

                    Text("No transactions yet")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, transaction in
                        FeedTransactionRow(
                            transaction: transaction,
                            isLastInGroup: index == recentTransactions.count - 1,
                            onTap: {
                                selectedTransaction = transaction
                                HapticManager.shared.light()
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            ActivityFilterSheet(selectedFilter: $selectedFilter, isPresented: $showingFilterSheet)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailSheet(transaction: transaction)
                .environmentObject(dataManager)
        }
    }
}

// MARK: - Activity Filter Sheet
struct ActivityFilterSheet: View {
    @Binding var selectedFilter: RecentActivitySection.ActivityFilter
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(RecentActivitySection.ActivityFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        isPresented = false
                    }) {
                        HStack {
                            Text(filter.rawValue)
                                .font(Theme.Fonts.bodyMedium)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.brandPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Recent Activity Section") {
    RecentActivitySection()
        .environmentObject(DataManager.shared)
        .padding()
        .background(Theme.Colors.background)
}
