//
//  HomeComponents.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Currency Formatting Helper
private func formatCurrencyCompact(_ amount: Double, showDecimals: Bool = false) -> String {
    let currencyCode = UserSettings.shared.selectedCurrency
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.minimumFractionDigits = showDecimals ? 2 : 0
    formatter.maximumFractionDigits = showDecimals ? 2 : 0
    return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(Int(amount))"
}

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
                FinancialCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: Theme.Colors.brandPrimary,
                    title: "BALANCE",
                    amount: formatCurrencyCompact(animatedBalance)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Subscriptions Card
            Button(action: {
                HapticManager.shared.light()
                selectedTab = 3  // Switch to Subscriptions tab
            }) {
                FinancialCard(
                    icon: "creditcard.circle.fill",
                    iconColor: Theme.Colors.brandSecondary,
                    title: "SUBSCRIPTIONS",
                    amount: "\(formatCurrencyCompact(animatedSubscriptions))/mo"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Income Card
            FinancialCard(
                icon: "arrow.up.circle.fill",
                iconColor: Theme.Colors.brandPrimary,
                title: "INCOME",
                amount: formatCurrencyCompact(animatedIncome)
            )

            // Expenses Card
            FinancialCard(
                icon: "arrow.down.circle.fill",
                iconColor: Theme.Colors.statusError,
                title: "EXPENSES",
                amount: formatCurrencyCompact(animatedExpenses)
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
                .environmentObject(dataManager)
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

// MARK: - Enhanced Financial Card (used by other views)
struct EnhancedFinancialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    var trend: (percentage: Double, isUp: Bool, isGood: Bool)? = nil

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
