//
//  HomeComponents.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Financial Overview Grid
struct FinancialOverviewGrid: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager
    @State private var showingBalanceDetail = false
    @State private var animatedBalance: Double = 0
    @State private var animatedIncome: Double = 0
    @State private var animatedExpenses: Double = 0
    @State private var animatedSubscriptions: Double = 0

    var totalBalance: Double {
        // Calculate total balance from people balances
        let peopleBalance = dataManager.people.reduce(0.0) { total, person in
            total + person.balance
        }
        // Add net monthly income
        let netIncome = dataManager.getNetMonthlyIncome()
        return peopleBalance + netIncome
    }

    // Simple trend calculation (mock data - in production, you'd compare with last month)
    func calculateTrend(for type: String) -> (percentage: Double, isPositive: Bool) {
        // For demo purposes, using random trend between -15% and +15%
        // In production, you would calculate actual change from previous month
        switch type {
        case "balance":
            return (5.2, true)  // +5.2%
        case "subscriptions":
            return (-2.1, false)  // -2.1%
        case "income":
            return (8.5, true)  // +8.5%
        case "expenses":
            return (3.4, true)  // +3.4%
        default:
            return (0, true)
        }
    }

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ], spacing: 8
        ) {
            // Balance Card
            Button(action: {
                HapticManager.shared.light()
                showingBalanceDetail = true
            }) {
                EnhancedFinancialCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: Theme.Colors.brandPrimary,
                    title: "BALANCE",
                    amount: String(format: "$%.0f", animatedBalance),
                    trend: calculateTrend(for: "balance")
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Subscriptions Card (replaced Difference)
            Button(action: {
                HapticManager.shared.light()
                selectedTab = 3  // Switch to Subscriptions tab
            }) {
                EnhancedFinancialCard(
                    icon: "creditcard.circle.fill",
                    iconColor: Theme.Colors.brandSecondary,
                    title: "SUBSCRIPTIONS",
                    amount: String(format: "$%.0f/mo", animatedSubscriptions),
                    trend: calculateTrend(for: "subscriptions")
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Income Card
            EnhancedFinancialCard(
                icon: "arrow.up.circle.fill",
                iconColor: Theme.Colors.brandPrimary,
                title: "INCOME",
                amount: String(format: "$%.0f", animatedIncome),
                trend: calculateTrend(for: "income")
            )

            // Expenses Card
            EnhancedFinancialCard(
                icon: "arrow.down.circle.fill",
                iconColor: Theme.Colors.statusError,
                title: "EXPENSES",
                amount: String(format: "$%.0f", animatedExpenses),
                trend: calculateTrend(for: "expenses")
            )
        }
        .onAppear {
            // Animate numbers on appear
            withAnimation(.easeOut(duration: 0.8)) {
                animatedBalance = totalBalance
                animatedSubscriptions = dataManager.calculateTotalMonthlyCost()
                animatedIncome = dataManager.calculateMonthlyIncome()
                animatedExpenses = dataManager.calculateMonthlyExpenses()
            }
        }
        .onChange(of: dataManager.dataRevision) { oldValue, newValue in
            // Real-time update: Animate financial values when any data changes
            withAnimation(.easeOut(duration: 0.5)) {
                animatedBalance = totalBalance
                animatedSubscriptions = dataManager.calculateTotalMonthlyCost()
                animatedIncome = dataManager.calculateMonthlyIncome()
                animatedExpenses = dataManager.calculateMonthlyExpenses()
            }
        }
        .sheet(isPresented: $showingBalanceDetail) {
            BalanceDetailView()
        }
    }
}

// MARK: - Financial Card
struct FinancialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String

    var body: some View {
        SwiffCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)

                    Spacer()
                }

                Text(title)
                    .font(Theme.Fonts.captionSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .textCase(.uppercase)

                Text(amount)
                    .font(Theme.Fonts.numberLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Enhanced Financial Card (with trends)
struct EnhancedFinancialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    let trend: (percentage: Double, isPositive: Bool)

    var body: some View {
        SwiffCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)

                    Spacer()

                    // Trend indicator
                    HStack(spacing: 2) {
                        Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(
                                trend.isPositive
                                    ? Theme.Colors.brandPrimary : Theme.Colors.statusError)

                        Text(String(format: "%.1f%%", abs(trend.percentage)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(
                                trend.isPositive
                                    ? Theme.Colors.brandPrimary : Theme.Colors.statusError)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                (trend.isPositive
                                    ? Theme.Colors.brandPrimary : Theme.Colors.statusError)
                                    .opacity(0.1)
                            )
                    )
                }

                Text(title)
                    .font(Theme.Fonts.captionSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .textCase(.uppercase)

                Text(amount)
                    .font(Theme.Fonts.numberLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Subscriptions Card
struct SubscriptionsCard: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        Button(action: {
            selectedTab = 3  // Switch to Subscriptions tab
        }) {
            SwiffCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "creditcard.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.brandSecondary)

                        Spacer()
                    }

                    Text("SUBSCRIPTIONS")
                        .font(Theme.Fonts.captionSmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .textCase(.uppercase)

                    Text(String(format: "$%.0f/mo", dataManager.calculateTotalMonthlyCost()))
                        .font(Theme.Fonts.numberLarge)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
