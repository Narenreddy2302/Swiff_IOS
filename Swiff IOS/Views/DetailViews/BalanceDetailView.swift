//
//  BalanceDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed balance breakdown view
//

import SwiftUI
import Combine

struct BalanceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    var totalBalance: Double {
        let peopleBalance = dataManager.people.reduce(0.0) { $0 + $1.balance }
        let netIncome = dataManager.getNetMonthlyIncome()
        return peopleBalance + netIncome
    }

    var peopleBalances: [(person: Person, balance: Double)] {
        dataManager.people
            .map { (person: $0, balance: $0.balance) }
            .filter { $0.balance != 0 }
            .sorted { abs($0.balance) > abs($1.balance) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Balance Card
                    VStack(spacing: 12) {
                        Text("Total Balance")
                            .font(.spotifyHeadingSmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(String(format: "$%.2f", totalBalance))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(totalBalance >= 0 ? .wiseBrightGreen : .wiseError)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                    // Breakdown Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Balance Breakdown")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Net Income/Expenses
                        BalanceBreakdownRow(
                            title: "Net This Month",
                            subtitle: "Income - Expenses",
                            amount: dataManager.getNetMonthlyIncome(),
                            icon: "chart.bar.fill",
                            iconColor: .wiseBlue
                        )

                        // People Balances
                        if !peopleBalances.isEmpty {
                            Divider()
                                .padding(.vertical, 8)

                            Text("People Balances")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.wiseSecondaryText)

                            ForEach(peopleBalances, id: \.person.id) { item in
                                PersonBalanceRow(person: item.person, balance: item.balance)
                            }
                        }

                        // Summary Stats
                        Divider()
                            .padding(.vertical, 8)

                        Text("Summary")
                            .font(.spotifyLabelLarge)
                            .foregroundColor(.wiseSecondaryText)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You Owe")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(String(format: "$%.2f", calculateTotalOwed()))
                                    .font(.spotifyNumberMedium)
                                    .foregroundColor(.wiseError)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("You're Owed")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                Text(String(format: "$%.2f", calculateTotalOwedToYou()))
                                    .font(.spotifyNumberMedium)
                                    .foregroundColor(.wiseBrightGreen)
                            }
                        }
                        .padding(16)
                        .background(Color.wiseBorder.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding(16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Balance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }

    private func calculateTotalOwed() -> Double {
        dataManager.people.filter { $0.balance < 0 }.reduce(0.0) { $0 + abs($1.balance) }
    }

    private func calculateTotalOwedToYou() -> Double {
        dataManager.people.filter { $0.balance > 0 }.reduce(0.0) { $0 + $1.balance }
    }
}

// MARK: - Balance Breakdown Row
struct BalanceBreakdownRow: View {
    let title: String
    let subtitle: String
    let amount: Double
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(subtitle)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(String(format: "$%.2f", amount))
                .font(.spotifyNumberMedium)
                .foregroundColor(amount >= 0 ? .wiseBrightGreen : .wiseError)
        }
        .padding(12)
        .background(Color.wiseBorder.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Person Balance Row
struct PersonBalanceRow: View {
    let person: Person
    let balance: Double

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(person: person, size: .large, style: .solid)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(balance > 0 ? "owes you" : "you owe")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", abs(balance)))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(balance > 0 ? .wiseBrightGreen : .wiseError)
            }
        }
        .padding(12)
        .background(Color.wiseBorder.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    BalanceDetailView()
        .environmentObject(DataManager.shared)
}
