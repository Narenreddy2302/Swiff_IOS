//
//  AnalyticsView.swift
//  Swiff IOS
//
//  Redesigned with pie charts only and clean UI
//  Updated: 2025-01-22
//

import SwiftUI
import Charts
import Combine

/// Main analytics dashboard showing spending insights with pie charts
struct AnalyticsView: View {

    // MARK: - Properties
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var chartDataService = ChartDataService.shared
    @EnvironmentObject var dataManager: DataManager

    @State private var selectedDateRange: DateRange = .month

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with title (consistent with other screens)
                    headerSection

                    // Date Range Selector
                    dateRangeSelector
                        .padding(.horizontal, 16)

                    // Three Pie Charts Section
                    incomeBreakdownChart
                    expenseBreakdownChart
                    billSplittingChart

                    // Subscription Analytics Summary
                    subscriptionSummarySection

                    // Insights & Recommendations
                    savingsOpportunitiesSection
                }
                .padding(.bottom, 100)
            }
            .background(Color.wiseBackground)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text("Analytics")
                .font(.spotifyDisplayLarge)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            // Search and Refresh Buttons (matching design system)
            HStack(spacing: 16) {
                Button(action: {
                    // Search action (can be implemented later)
                    HapticManager.shared.light()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.wisePrimaryText)
                }

                HeaderActionButton(icon: "arrow.clockwise", color: .wiseForestGreen) {
                    HapticManager.shared.light()
                    refreshData()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - Date Range Selector

    private var dateRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPillButton("7 Days", isSelected: selectedDateRange == .week) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDateRange = .week
                        chartDataService.clearCache()
                    }
                }

                FilterPillButton("30 Days", isSelected: selectedDateRange == .month) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDateRange = .month
                        chartDataService.clearCache()
                    }
                }

                FilterPillButton("90 Days", isSelected: selectedDateRange == .quarter) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDateRange = .quarter
                        chartDataService.clearCache()
                    }
                }

                FilterPillButton("1 Year", isSelected: selectedDateRange == .year) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDateRange = .year
                        chartDataService.clearCache()
                    }
                }
            }
        }
    }

    // MARK: - Income Breakdown Pie Chart

    private var incomeBreakdownChart: some View {
        let incomeData = prepareIncomeData()

        return VStack(spacing: 0) {
            if incomeData.isEmpty {
                emptyChartPlaceholder(title: "Income Breakdown", icon: "arrow.down.circle")
            } else {
                CustomPieChartView(
                    title: "Income Breakdown",
                    data: incomeData,
                    showLegend: true,
                    showCenterValue: true
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Expense Breakdown Pie Chart

    private var expenseBreakdownChart: some View {
        let expenseData = prepareExpenseData()

        return VStack(spacing: 0) {
            if expenseData.isEmpty {
                emptyChartPlaceholder(title: "Expense Breakdown", icon: "arrow.up.circle")
            } else {
                CustomPieChartView(
                    title: "Expense Breakdown",
                    data: expenseData,
                    showLegend: true,
                    showCenterValue: true
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Bill Splitting Pie Chart

    private var billSplittingChart: some View {
        let billSplittingData = prepareBillSplittingData()

        return VStack(spacing: 0) {
            if billSplittingData.isEmpty {
                emptyChartPlaceholder(title: "Bill Splitting Breakdown", icon: "person.2.fill")
            } else {
                CustomPieChartView(
                    title: "Bill Splitting Breakdown",
                    data: billSplittingData,
                    showLegend: true,
                    showCenterValue: true
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Subscription Summary Section

    private var subscriptionSummarySection: some View {
        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        let totalMonthlyCost = analyticsService.getTotalMonthlyCost()
        let averageCost = analyticsService.getAverageCostPerSubscription()

        return VStack(alignment: .leading, spacing: 12) {
            Text("SUBSCRIPTION OVERVIEW")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                CompactStatisticsCard(
                    icon: "star.circle.fill",
                    title: "Active",
                    value: "\(activeSubscriptions.count)",
                    iconBackgroundColor: .wiseBrightGreen
                )

                CompactStatisticsCard(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly",
                    value: formatCurrency(totalMonthlyCost),
                    iconBackgroundColor: .wiseBlue
                )

                CompactStatisticsCard(
                    icon: "chart.bar.fill",
                    title: "Average",
                    value: formatCurrency(averageCost),
                    iconBackgroundColor: .wisePurple
                )

                CompactStatisticsCard(
                    icon: "calendar.circle.fill",
                    title: "This Month",
                    value: formatCurrency(totalMonthlyCost),
                    iconBackgroundColor: .wiseOrange
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Savings Opportunities Section

    private var savingsOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Opportunities")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)

            let suggestions = analyticsService.generateSavingsOpportunities()

            if suggestions.isEmpty {
                emptyInsightsView
                    .padding(.horizontal, 16)
            } else {
                ForEach(suggestions.prefix(5)) { suggestion in
                    SavingsSuggestionCard(suggestion: suggestion)
                        .padding(.horizontal, 16)
                }
            }

            // Unused Subscriptions
            let unusedSubs = analyticsService.detectUnusedSubscriptions(threshold: 30)
            if !unusedSubs.isEmpty {
                unusedSubscriptionsCard(subscriptions: unusedSubs)
                    .padding(.horizontal, 16)
            }

            // Annual Conversion Suggestions
            let annualSuggestions = analyticsService.suggestAnnualConversions()
            if !annualSuggestions.isEmpty {
                annualConversionCard(suggestions: annualSuggestions)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty States

    private func emptyChartPlaceholder(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.wiseMidGray.opacity(0.5))

            Text(title)
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)

            Text("No data available for the selected period")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.wiseBrightGreen)

            Text("You're doing great!")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text("No savings opportunities detected at this time.")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Insight Cards

    private func unusedSubscriptionsCard(subscriptions: [Subscription]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.wiseOrange.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.wiseOrange)
                            .font(.system(size: 20))
                    )

                Text("Unused Subscriptions")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }

            Text("\(subscriptions.count) subscription\(subscriptions.count == 1 ? "" : "s") haven't been used recently")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)

            ForEach(subscriptions.prefix(3)) { subscription in
                HStack {
                    Text(subscription.name)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text(formatCurrency(subscription.monthlyEquivalent) + "/mo")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseError)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func annualConversionCard(suggestions: [AnnualSuggestion]) -> some View {
        let totalSavings = suggestions.reduce(0.0) { $0 + $1.annualSavings }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.wiseBrightGreen.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "arrow.2.circlepath.circle.fill")
                            .foregroundColor(.wiseBrightGreen)
                            .font(.system(size: 20))
                    )

                Text("Switch to Annual Plans")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }

            Text("Save \(formatCurrency(totalSavings)) per year")
                .font(.spotifyNumberLarge)
                .foregroundColor(.wiseBrightGreen)

            Text("\(suggestions.count) subscription\(suggestions.count == 1 ? "" : "s") could save money with annual billing")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Data Preparation

    private func prepareIncomeData() -> [ChartDataItem] {
        let transactions = dataManager.transactions.filter { !$0.isExpense }
        let categoryTotals = Dictionary(grouping: transactions) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        return categoryTotals.map { category, amount in
            ChartDataItem(
                category: category.rawValue,
                amount: amount,
                color: ChartColorPalette.categoryColor(for: category.rawValue),
                icon: category.icon
            )
        }.sorted { $0.amount > $1.amount }
    }

    private func prepareExpenseData() -> [ChartDataItem] {
        let transactions = dataManager.transactions.filter { $0.isExpense }
        let categoryTotals = Dictionary(grouping: transactions) { $0.category }
            .mapValues { $0.reduce(0) { abs($0) + abs($1.amount) } }

        return categoryTotals.map { category, amount in
            ChartDataItem(
                category: category.rawValue,
                amount: amount,
                color: ChartColorPalette.categoryColor(for: category.rawValue),
                icon: category.icon
            )
        }.sorted { $0.amount > $1.amount }
    }

    private func prepareBillSplittingData() -> [ChartDataItem] {
        // Group bill splitting transactions by person
        let billSplits = dataManager.transactions.filter {
            $0.category.rawValue.lowercased().contains("shared") ||
            $0.category.rawValue.lowercased().contains("split")
        }

        if billSplits.isEmpty {
            return []
        }

        let categoryTotals = Dictionary(grouping: billSplits) { $0.category }
            .mapValues { $0.reduce(0) { abs($0) + abs($1.amount) } }

        return categoryTotals.map { category, amount in
            ChartDataItem(
                category: category.rawValue,
                amount: amount,
                color: ChartColorPalette.categoryColor(for: category.rawValue),
                icon: category.icon
            )
        }.sorted { $0.amount > $1.amount }
    }

    // MARK: - Helper Methods

    private func refreshData() {
        analyticsService.clearCache()
        chartDataService.clearCache()
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Savings Suggestion Card

struct SavingsSuggestionCard: View {
    let suggestion: SavingsSuggestion
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        HStack(spacing: 16) {
            // Icon with proper spacing (no overlap)
            Circle()
                .fill(colorForType(suggestion.type).opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: iconForType(suggestion.type))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colorForType(suggestion.type))
                )

            // Content with proper spacing
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.type.rawValue)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                Text(suggestion.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)

                if suggestion.potentialSavings > 0 {
                    Text("Save \(formatCurrency(suggestion.potentialSavings))")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseBrightGreen)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func iconForType(_ type: SuggestionType) -> String {
        switch type {
        case .unused, .unusedSubscription: return "pause.circle.fill"
        case .annualConversion, .switchToAnnual: return "arrow.2.circlepath.circle.fill"
        case .priceIncrease: return "arrow.up.circle.fill"
        case .alternative: return "lightbulb.fill"
        case .trialEnding: return "hourglass"
        }
    }

    private func colorForType(_ type: SuggestionType) -> Color {
        switch type {
        case .unused, .unusedSubscription: return .wiseOrange
        case .annualConversion, .switchToAnnual: return .wiseBrightGreen
        case .priceIncrease: return .wiseError
        case .alternative: return .wiseBlue
        case .trialEnding: return .wisePurple
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Preview

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(DataManager.shared)
    }
}
