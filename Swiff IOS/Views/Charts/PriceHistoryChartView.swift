//
//  PriceHistoryChartView.swift
//  Swiff IOS
//
//  Created by Agent 9 for Price History Tracking
//  Interactive chart showing subscription price changes over time
//

import SwiftUI
import Charts

// MARK: - Price History Chart View

struct PriceHistoryChartView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let subscription: Subscription
    @State private var priceHistory: [PriceChange] = []
    @State private var selectedDataPoint: PriceDataPoint?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statisticsSection
                chartSection
                priceChangesListSection
            }
            .padding(.vertical, 20)
        }
        .background(Color.wiseBackground)
        .navigationTitle("Price History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPriceHistory()
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hexString: subscription.color).opacity(0.3),
                            Color(hexString: subscription.color).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: subscription.icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color(hexString: subscription.color))
                )

            Text(subscription.name)
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)

            Text("Price History Overview")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(.horizontal, 16)
    }

    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            let stats = calculateStatistics()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Current Price",
                    value: subscription.price.asCurrency,
                    color: .wiseBlue
                )

                StatCard(
                    title: "Original Price",
                    value: stats.originalPrice.asCurrency,
                    color: .wiseSecondaryText
                )

                StatCard(
                    title: "Total Change",
                    value: stats.totalChangeFormatted,
                    subtitle: stats.totalPercentageFormatted,
                    color: stats.totalChange >= 0 ? .wiseError : .wiseBrightGreen
                )

                StatCard(
                    title: "Price Changes",
                    value: "\(stats.changeCount)",
                    subtitle: stats.changeCount > 0 ? "changes recorded" : "no changes",
                    color: .wiseForestGreen
                )

                if stats.changeCount > 0 {
                    StatCard(
                        title: "Average Price",
                        value: stats.averagePrice.asCurrency,
                        color: .wiseSecondaryText
                    )

                    StatCard(
                        title: "Largest Change",
                        value: stats.largestChangeFormatted,
                        subtitle: stats.largestPercentageFormatted,
                        color: stats.largestChange >= 0 ? .wiseError : .wiseBrightGreen
                    )
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var chartSection: some View {
        if !dataPoints.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Price Trend")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .foregroundStyle(lineGradient)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .foregroundStyle(areaGradient)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .foregroundStyle(point.isIncrease ? Color.wiseError : Color.wiseBrightGreen)
                        .symbolSize(100)

                        if let selected = selectedDataPoint, selected.id == point.id {
                            RuleMark(x: .value("Date", point.date))
                                .foregroundStyle(Color.wiseSecondaryText.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        }
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(price.asCurrency)
                                    .font(.spotifyCaptionMedium)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let location = value.location
                                        if let date: Date = proxy.value(atX: location.x) {
                                            if let point = findClosestPoint(to: date) {
                                                selectedDataPoint = point
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            selectedDataPoint = nil
                                        }
                                    }
                            )
                    }
                }

                // Selected point info
                if let selected = selectedDataPoint {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selected.date, style: .date)
                                .font(.spotifyLabelSmall)
                                .foregroundColor(.wiseSecondaryText)

                            Text(selected.price.asCurrency)
                                .font(.spotifyNumberLarge)
                                .foregroundColor(.wisePrimaryText)
                        }

                        Spacer()

                        if selected.changePercentage != nil {
                            CompactPriceChangeBadge(
                                priceChange: PriceChange(
                                    subscriptionId: subscription.id,
                                    oldPrice: selected.previousPrice ?? selected.price,
                                    newPrice: selected.price,
                                    detectedAutomatically: true
                                )
                            )
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
                }

                Text("Tap on the chart to see price details")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        } else {
            emptyChartView
        }
    }

    private var emptyChartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText)

            Text("No Price Changes Yet")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text("When prices change, you'll see a detailed chart here")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var priceChangesListSection: some View {
        if !priceHistory.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("All Price Changes")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                VStack(spacing: 0) {
                    ForEach(priceHistory) { change in
                        PriceChangeRow(priceChange: change)

                        if change.id != priceHistory.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Data Processing

    private var dataPoints: [PriceDataPoint] {
        var points: [PriceDataPoint] = []

        // Add initial price (from subscription creation)
        let initialPrice = priceHistory.last?.oldPrice ?? subscription.price
        points.append(PriceDataPoint(
            date: subscription.createdDate,
            price: initialPrice,
            isIncrease: false,
            changePercentage: nil as Double?,
            previousPrice: nil as Double?
        ))

        // Add all price changes
        for change in priceHistory.reversed() {
            let previousPrice = points.last?.price ?? initialPrice
            let changePercentage = ((change.newPrice - previousPrice) / previousPrice) * 100

            points.append(PriceDataPoint(
                date: change.changeDate,
                price: change.newPrice,
                isIncrease: change.newPrice > previousPrice,
                changePercentage: changePercentage,
                previousPrice: previousPrice
            ))
        }

        return points
    }

    private var lineGradient: LinearGradient {
        let hasIncreases = priceHistory.contains { $0.isIncrease }
        let color = hasIncreases ? Color.wiseError : Color.wiseBrightGreen

        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var areaGradient: LinearGradient {
        let hasIncreases = priceHistory.contains { $0.isIncrease }
        let color = hasIncreases ? Color.wiseError : Color.wiseBrightGreen

        return LinearGradient(
            colors: [color.opacity(0.3), color.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func findClosestPoint(to date: Date) -> PriceDataPoint? {
        return dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func calculateStatistics() -> PriceStatistics {
        let originalPrice = priceHistory.last?.oldPrice ?? subscription.price
        let currentPrice = subscription.price
        let totalChange = currentPrice - originalPrice
        let totalPercentage = originalPrice > 0 ? ((totalChange / originalPrice) * 100) : 0

        let allPrices = dataPoints.map { $0.price }
        let averagePrice = allPrices.isEmpty ? 0 : allPrices.reduce(0, +) / Double(allPrices.count)

        var largestChange: Double = 0
        var largestPercentage: Double = 0

        for change in priceHistory {
            let changeAmount = abs(change.changeAmount)
            let _ = abs(change.changePercentage)

            if changeAmount > abs(largestChange) {
                largestChange = change.changeAmount
                largestPercentage = change.changePercentage
            }
        }

        return PriceStatistics(
            originalPrice: originalPrice,
            currentPrice: currentPrice,
            totalChange: totalChange,
            totalPercentage: totalPercentage,
            changeCount: priceHistory.count,
            averagePrice: averagePrice,
            largestChange: largestChange,
            largestPercentage: largestPercentage
        )
    }

    private func loadPriceHistory() {
        priceHistory = dataManager.getPriceHistory(for: subscription.id)
    }
}

// MARK: - Supporting Types
// Note: PriceDataPoint is defined in AnalyticsModels.swift

struct PriceStatistics {
    let originalPrice: Double
    let currentPrice: Double
    let totalChange: Double
    let totalPercentage: Double
    let changeCount: Int
    let averagePrice: Double
    let largestChange: Double
    let largestPercentage: Double

    var totalChangeFormatted: String {
        let sign = totalChange >= 0 ? "+" : "-"
        return "\(sign)\(abs(totalChange).asCurrency)"
    }

    var totalPercentageFormatted: String {
        let sign = totalPercentage >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, totalPercentage)
    }

    var largestChangeFormatted: String {
        let sign = largestChange >= 0 ? "+" : "-"
        return "\(sign)\(abs(largestChange).asCurrency)"
    }

    var largestPercentageFormatted: String {
        let sign = largestPercentage >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, largestPercentage)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)

            Text(value)
                .font(.spotifyNumberLarge)
                .fontWeight(.bold)
                .foregroundColor(color)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
}

#Preview("Price History Chart View") {
    NavigationView {
        PriceHistoryChartView(subscription: MockData.activeSubscription)
            .environmentObject(DataManager.shared)
    }
}
