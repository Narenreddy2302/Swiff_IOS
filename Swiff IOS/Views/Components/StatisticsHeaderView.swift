//
//  StatisticsHeaderView.swift
//  Swiff IOS
//
//  Created for Page 2 Task 2.5
//  Collapsible statistics header showing transaction summary
//

import SwiftUI

struct StatisticsHeaderView: View {
    let transactions: [Transaction]
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header - Always visible
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Statistics")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.wisePrimaryText)

                        Text("\(transactions.count) transaction\(transactions.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    // Expand/Collapse icon
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.wiseBlue)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())

            // Expandable content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)

                    // Statistics Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Total Amount
                        StatisticCard(
                            title: "Total",
                            value: formattedTotalAmount,
                            color: totalAmount >= 0 ? .wiseBrightGreen : .wiseError,
                            icon: "dollarsign.circle.fill"
                        )

                        // Average Amount
                        StatisticCard(
                            title: "Average",
                            value: formattedAverageAmount,
                            color: .wiseBlue,
                            icon: "chart.bar.fill"
                        )

                        // Count
                        StatisticCard(
                            title: "Count",
                            value: "\(transactions.count)",
                            color: .wiseForestGreen,
                            icon: "number.circle.fill"
                        )
                    }
                    .padding(.horizontal, 20)

                    // Income vs Expenses breakdown
                    HStack(spacing: 12) {
                        // Income
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.wiseBrightGreen)
                                Text("Income")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            Text(formattedIncomeAmount)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.wiseBrightGreen)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBrightGreen.opacity(0.1))
                        )

                        // Expenses
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.wiseError)
                                Text("Expenses")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            Text(formattedExpenseAmount)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.wiseError)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseError.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Computed Properties

    private var totalAmount: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    private var incomeAmount: Double {
        transactions.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
    }

    private var expenseAmount: Double {
        abs(transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount })
    }

    private var averageAmount: Double {
        guard !transactions.isEmpty else { return 0 }
        return abs(totalAmount) / Double(transactions.count)
    }

    private var formattedTotalAmount: String {
        formatCurrency(totalAmount)
    }

    private var formattedIncomeAmount: String {
        formatCurrency(incomeAmount)
    }

    private var formattedExpenseAmount: String {
        formatCurrency(expenseAmount)
    }

    private var formattedAverageAmount: String {
        formatCurrency(averageAmount)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0.00"
    }
}

// MARK: - Statistic Card Component
struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Preview
#Preview("Collapsed") {
    StatisticsHeaderView(transactions: [
        Transaction(title: "Coffee", subtitle: "Morning coffee", amount: -5.50, category: .food, date: Date(), isRecurring: false, tags: []),
        Transaction(title: "Salary", subtitle: "Monthly salary", amount: 5000, category: .income, date: Date(), isRecurring: true, tags: []),
        Transaction(title: "Groceries", subtitle: "Weekly shopping", amount: -120.30, category: .groceries, date: Date(), isRecurring: false, tags: []),
        Transaction(title: "Gas", subtitle: "Fuel", amount: -45.00, category: .transportation, date: Date(), isRecurring: false, tags: [])
    ])
    .background(Color.gray.opacity(0.1))
}

#Preview("Expanded") {
    StatisticsHeaderView(transactions: [
        Transaction(title: "Coffee", subtitle: "Morning coffee", amount: -5.50, category: .food, date: Date(), isRecurring: false, tags: []),
        Transaction(title: "Salary", subtitle: "Monthly salary", amount: 5000, category: .income, date: Date(), isRecurring: true, tags: []),
        Transaction(title: "Groceries", subtitle: "Weekly shopping", amount: -120.30, category: .groceries, date: Date(), isRecurring: false, tags: []),
        Transaction(title: "Gas", subtitle: "Fuel", amount: -45.00, category: .transportation, date: Date(), isRecurring: false, tags: []),
        Transaction(title: "Freelance", subtitle: "Project payment", amount: 1500, category: .income, date: Date(), isRecurring: false, tags: []),
        Transaction(title: "Dinner", subtitle: "Restaurant", amount: -85.20, category: .dining, date: Date(), isRecurring: false, tags: [])
    ])
    .background(Color.gray.opacity(0.1))
}

#Preview("Empty") {
    StatisticsHeaderView(transactions: [])
        .background(Color.gray.opacity(0.1))
}
