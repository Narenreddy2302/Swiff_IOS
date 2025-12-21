//
//  AnalyticsInsightsPage.swift
//  Swiff IOS
//
//  Analytics and insights settings page
//

import SwiftUI

struct AnalyticsInsightsPage: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var showExportSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Stats Section
                quickStatsSection

                // Trends Section
                trendsSection

                // Export Section
                exportSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.wiseGroupedBackground)
        .navigationTitle("Analytics & Insights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showExportSheet) {
            ExportAnalyticsSheet()
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "OVERVIEW")

            VStack(spacing: 12) {
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    AnalyticsStatCard(
                        icon: "arrow.up.circle.fill",
                        title: "Total Expenses",
                        value: formatCurrency(totalExpenses),
                        iconColor: .wiseError
                    )

                    AnalyticsStatCard(
                        icon: "arrow.down.circle.fill",
                        title: "Total Income",
                        value: formatCurrency(totalIncome),
                        iconColor: .wiseBrightGreen
                    )

                    AnalyticsStatCard(
                        icon: "creditcard.fill",
                        title: "Subscriptions",
                        value: "\(activeSubscriptions)",
                        iconColor: .wiseBlue
                    )

                    AnalyticsStatCard(
                        icon: "list.bullet",
                        title: "Transactions",
                        value: "\(totalTransactions)",
                        iconColor: .wisePurple
                    )
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Trends Section

    private var trendsSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "SPENDING TRENDS")

            VStack(spacing: 0) {
                // This Month vs Last Month
                TrendRow(
                    title: "This Month",
                    value: formatCurrency(thisMonthSpending),
                    trend: monthlyTrend,
                    showDivider: true
                )

                // Average Monthly
                TrendRow(
                    title: "Monthly Average",
                    value: formatCurrency(averageMonthlySpending),
                    trend: nil,
                    showDivider: true
                )

                // Subscription Cost
                TrendRow(
                    title: "Monthly Subscriptions",
                    value: formatCurrency(monthlySubscriptionCost),
                    trend: nil,
                    showDivider: false
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader(title: "DATA EXPORT")

            VStack(spacing: 0) {
                // Export Analytics
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showExportSheet = true
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.wiseForestGreen.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.wiseForestGreen)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Analytics Report")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Download your spending insights")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.leading, 68)

                // View Full Analytics
                NavigationLink(destination: AnalyticsView().environmentObject(dataManager)) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.wiseBlue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.wiseBlue)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("View Full Analytics")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Detailed spending breakdown")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Computed Properties

    private var totalExpenses: Double {
        dataManager.transactions
            .filter { $0.isExpense }
            .reduce(0) { $0 + abs($1.amount) }
    }

    private var totalIncome: Double {
        dataManager.transactions
            .filter { !$0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    private var activeSubscriptions: Int {
        dataManager.subscriptions.filter { $0.isActive }.count
    }

    private var totalTransactions: Int {
        dataManager.transactions.count
    }

    private var thisMonthSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        return dataManager.transactions
            .filter { $0.isExpense && $0.date >= startOfMonth }
            .reduce(0) { $0 + abs($1.amount) }
    }

    private var lastMonthSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) else {
            return 0
        }

        return dataManager.transactions
            .filter { $0.isExpense && $0.date >= startOfLastMonth && $0.date < startOfThisMonth }
            .reduce(0) { $0 + abs($1.amount) }
    }

    private var monthlyTrend: Double? {
        guard lastMonthSpending > 0 else { return nil }
        return ((thisMonthSpending - lastMonthSpending) / lastMonthSpending) * 100
    }

    private var averageMonthlySpending: Double {
        guard !dataManager.transactions.isEmpty else { return 0 }

        let expenses = dataManager.transactions.filter { $0.isExpense }
        guard !expenses.isEmpty else { return 0 }

        let calendar = Calendar.current
        let dates = expenses.map { $0.date }
        guard let earliest = dates.min(), let latest = dates.max() else { return 0 }

        let months = max(1, calendar.dateComponents([.month], from: earliest, to: latest).month ?? 1)
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }

        return totalExpenses / Double(months)
    }

    private var monthlySubscriptionCost: Double {
        dataManager.subscriptions
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.monthlyEquivalent }
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Views

struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(title)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.wiseGroupedBackground)
        .cornerRadius(12)
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let trend: Double?
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                HStack(spacing: 8) {
                    Text(value)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)

                    if let trend = trend {
                        HStack(spacing: 2) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))

                            Text(String(format: "%.1f%%", abs(trend)))
                                .font(.spotifyCaptionSmall)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(trend >= 0 ? .wiseError : .wiseBrightGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((trend >= 0 ? Color.wiseError : Color.wiseBrightGreen).opacity(0.15))
                        )
                    }
                }
            }
            .padding(16)

            if showDivider {
                Divider().padding(.leading, 16)
            }
        }
    }
}

// MARK: - Export Analytics Sheet

struct ExportAnalyticsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedPeriod: ExportPeriod = .thisMonth

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"
    }

    enum ExportPeriod: String, CaseIterable {
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
        case allTime = "All Time"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Format Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("FORMAT")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Period Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("TIME PERIOD")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    VStack(spacing: 0) {
                        ForEach(ExportPeriod.allCases, id: \.self) { period in
                            Button(action: {
                                selectedPeriod = period
                            }) {
                                HStack {
                                    Text(period.rawValue)
                                        .font(.spotifyBodyLarge)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()

                                    if selectedPeriod == period {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.wisePrimaryButton)
                                    }
                                }
                                .padding(16)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if period != ExportPeriod.allCases.last {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                }

                Spacer()

                // Export Button
                Button(action: {
                    HapticManager.shared.notification(.success)
                    ToastManager.shared.showSuccess("Analytics report exported")
                    dismiss()
                }) {
                    Text("Export Report")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color.wiseGroupedBackground)
            .navigationTitle("Export Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

#Preview("Analytics Insights Page") {
    NavigationView {
        AnalyticsInsightsPage()
            .environmentObject(DataManager.shared)
    }
}
