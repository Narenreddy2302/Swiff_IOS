//
//  SubscriptionComparisonChart.swift
//  Swiff IOS
//
//  Created by Agent 6 on 11/21/25.
//  Bar chart comparing top subscriptions by monthly cost
//

import SwiftUI
import Charts
import Combine

struct SubscriptionComparisonChart: View {

    // MARK: - Properties
    @StateObject private var chartDataService = ChartDataService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedSubscription: SubscriptionData?
    @State private var showMonthlyView = true // Toggle between monthly and annual

    // MARK: - Body
    var body: some View {
        let subscriptionData = chartDataService.prepareSubscriptionComparisonData()

        VStack(alignment: .leading, spacing: 16) {
            // Header with Toggle
            header

            // Selected Subscription Info
            if let selected = selectedSubscription {
                selectedSubscriptionInfo(selected)
            } else {
                summaryInfo(subscriptionData)
            }

            // Bar Chart
            if !subscriptionData.isEmpty {
                Chart(subscriptionData) { item in
                    BarMark(
                        x: .value("Amount", showMonthlyView ? item.amount : item.amount * 12),
                        y: .value("Subscription", item.subscription.name)
                    )
                    .foregroundStyle(item.subscription.category.color.gradient)
                    .cornerRadius(6)
                    .opacity(selectedSubscription == nil || selectedSubscription?.id == item.id ? 1.0 : 0.4)
                    .annotation(position: .trailing, alignment: .leading) {
                        if subscriptionData.count <= 5 {
                            Text(dataManager.formatCurrency(showMonthlyView ? item.amount : item.amount * 12))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.wiseCharcoal)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.wiseMidGray.opacity(0.2))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatAxisAmount(amount))
                                    .font(.caption2)
                                    .foregroundColor(.wiseMidGray)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.wiseCharcoal)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(max(200, subscriptionData.count * 35)))
            } else {
                emptyStateView
            }

            // Savings Insight
            if showMonthlyView == false && !subscriptionData.isEmpty {
                annualSavingsInsight
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Top Subscriptions")
                .font(.headline)
                .foregroundColor(.wiseCharcoal)

            Spacer()

            // Monthly/Annual Toggle
            Picker("View", selection: $showMonthlyView) {
                Text("Monthly").tag(true)
                Text("Annual").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
    }

    // MARK: - Info Views

    private func selectedSubscriptionInfo(_ data: SubscriptionData) -> some View {
        HStack(spacing: 12) {
            // Category Color Indicator
            Circle()
                .fill(data.subscription.category.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(data.subscription.name)
                    .font(.headline)
                    .foregroundColor(.wiseCharcoal)

                HStack(spacing: 8) {
                    Text(dataManager.formatCurrency(showMonthlyView ? data.amount : data.amount * 12))
                        .font(.title3.bold())
                        .foregroundColor(.wiseCharcoal)

                    Text(showMonthlyView ? "/month" : "/year")
                        .font(.subheadline)
                        .foregroundColor(.wiseMidGray)

                    Text("•")
                        .foregroundColor(.wiseMidGray)

                    Text(String(format: "%.1f%%", data.percentageOfTotal))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.wiseMidGray)
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedSubscription = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.wiseMidGray)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(data.subscription.category.color.opacity(0.1))
        )
    }

    private func summaryInfo(_ data: [SubscriptionData]) -> some View {
        let total = data.reduce(0.0) { $0 + $1.amount }

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dataManager.formatCurrency(showMonthlyView ? total : total * 12))
                    .font(.title3.bold())
                    .foregroundColor(.wiseCharcoal)

                Text("Top \(data.count) Total" + (showMonthlyView ? " /month" : " /year"))
                    .font(.subheadline)
                    .foregroundColor(.wiseMidGray)
            }

            Spacer()

            if !showMonthlyView && total > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(dataManager.formatCurrency(total))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.wiseBrightGreen)

                    Text("Monthly Avg")
                        .font(.caption)
                        .foregroundColor(.wiseMidGray)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.wiseMidGray.opacity(0.5))

            Text("No active subscriptions")
                .font(.headline)
                .foregroundColor(.wiseCharcoal)

            Text("Add your first subscription to see insights")
                .font(.subheadline)
                .foregroundColor(.wiseMidGray)
        }
        .frame(height: 200)
    }

    private var annualSavingsInsight: some View {
        let annualSuggestions = analyticsService.suggestAnnualConversions()
        let totalSavings = annualSuggestions.reduce(0.0) { $0 + $1.annualSavings }

        return VStack {
            if totalSavings > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.wiseBrightGreen)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Potential Annual Savings")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.wiseCharcoal)

                        Text("Save \(dataManager.formatCurrency(totalSavings)) by switching to annual plans")
                            .font(.caption)
                            .foregroundColor(.wiseMidGray)
                    }

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBrightGreen.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func formatAxisAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.0fk", amount / 1000)
        } else {
            return String(format: "$%.0f", amount)
        }
    }
}

// MARK: - Subscription Comparison Grid (Alternative View)

struct SubscriptionComparisonGrid: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        let topSubscriptions = analyticsService.getMostExpensiveSubscriptions(limit: 6)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(topSubscriptions) { subscription in
                subscriptionCard(subscription)
            }
        }
    }

    private func subscriptionCard(_ subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Category
            HStack {
                Circle()
                    .fill(subscription.category.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: subscription.category.icon)
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    )

                Spacer()

                Text(subscription.billingCycle.shortName)
                    .font(.caption2)
                    .foregroundColor(.wiseMidGray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseBackground)
                    )
            }

            // Name
            Text(subscription.name)
                .font(.headline)
                .foregroundColor(.wiseCharcoal)
                .lineLimit(1)

            // Price
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(dataManager.formatCurrency(subscription.monthlyEquivalent))
                    .font(.title3.bold())
                    .foregroundColor(.wiseCharcoal)

                Text("/mo")
                    .font(.caption)
                    .foregroundColor(.wiseMidGray)
            }

            // Category
            Text(subscription.category.rawValue)
                .font(.caption)
                .foregroundColor(.wiseMidGray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .shadow(color: Color.wiseShadowColor, radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

struct SubscriptionComparisonChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            SubscriptionComparisonChart()
                .frame(height: 300)

            SubscriptionComparisonGrid()
        }
        .environmentObject(DataManager.shared)
        .padding()
    }
}
