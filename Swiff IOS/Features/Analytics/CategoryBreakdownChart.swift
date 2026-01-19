//
//  CategoryBreakdownChart.swift
//  Swiff IOS
//
//  Created by Agent 6 on 11/21/25.
//  Interactive category breakdown with pie and bar chart options
//

import SwiftUI
import Charts
import Combine

struct CategoryBreakdownChart: View {

    // MARK: - Properties
    enum ChartDisplayType {
        case pie, bar
    }

    let chartType: ChartDisplayType

    @StateObject private var chartDataService = ChartDataService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedCategory: CategoryData?
    @State private var highlightedCategory: String?

    // MARK: - Body
    var body: some View {
        let categoryData = chartDataService.prepareCategoryData(colorScheme: colorScheme)

        VStack(alignment: .leading, spacing: 16) {
            if chartType == .pie {
                pieChartView(data: categoryData)
            } else {
                barChartView(data: categoryData)
            }
        }
    }

    // MARK: - Pie Chart

    private func pieChartView(data: [CategoryData]) -> some View {
        VStack(spacing: 16) {
            // Selected Category Info
            if let selected = selectedCategory {
                selectedCategoryInfo(selected)
            } else {
                totalSpendingInfo(data)
            }

            // Pie Chart
            Chart(data) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2.0
                )
                .foregroundStyle(item.swiftUIColor)
                .opacity(selectedCategory == nil || selectedCategory?.id == item.id ? 1.0 : 0.5)
                .cornerRadius(4)
            }
            .chartAngleSelection(value: $selectedCategory)
            .chartLegend(position: .bottom, alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(data.prefix(6)) { item in
                        legendItem(for: item)
                    }
                }
            }
            .frame(height: 220)
        }
    }

    // MARK: - Bar Chart

    private func barChartView(data: [CategoryData]) -> some View {
        VStack(spacing: 16) {
            // Selected Category Info
            if let selected = selectedCategory {
                selectedCategoryInfo(selected)
            } else {
                totalSpendingInfo(data)
            }

            // Bar Chart
            Chart(data.sorted(by: { $0.amount > $1.amount }).prefix(8)) { item in
                BarMark(
                    x: .value("Amount", item.amount),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(item.swiftUIColor.gradient)
                .cornerRadius(6)
                .opacity(selectedCategory == nil || selectedCategory?.id == item.id ? 1.0 : 0.5)
                .annotation(position: .trailing, alignment: .leading) {
                    if selectedCategory?.id == item.id || selectedCategory == nil {
                        Text(dataManager.formatCurrency(item.amount))
                            .font(.caption.weight(.semibold))
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
                        if let category = value.as(String.self) {
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.wiseCharcoal)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
    }

    // MARK: - Info Views

    private func selectedCategoryInfo(_ category: CategoryData) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(category.swiftUIColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.category)
                    .font(.headline)
                    .foregroundColor(.wiseCharcoal)

                HStack(spacing: 8) {
                    Text(dataManager.formatCurrency(category.amount))
                        .font(.title3.bold())
                        .foregroundColor(.wiseCharcoal)

                    let total = chartDataService.prepareCategoryData(colorScheme: colorScheme).reduce(0.0) { $0 + $1.amount }
                    let percentage = total > 0 ? (category.amount / total) * 100 : 0

                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.wiseMidGray)
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedCategory = nil
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
                .fill(category.swiftUIColor.opacity(0.1))
        )
    }

    private func totalSpendingInfo(_ data: [CategoryData]) -> some View {
        let total = data.reduce(0.0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 4) {
            Text(dataManager.formatCurrency(total))
                .font(.title3.bold())
                .foregroundColor(.wiseCharcoal)

            Text("Total Spending by Category")
                .font(.subheadline)
                .foregroundColor(.wiseMidGray)
        }
    }

    // MARK: - Legend Item

    private func legendItem(for item: CategoryData) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                if selectedCategory?.id == item.id {
                    selectedCategory = nil
                } else {
                    selectedCategory = item
                }
            }
        }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(item.swiftUIColor)
                    .frame(width: 8, height: 8)

                Text(item.category)
                    .font(.caption)
                    .foregroundColor(.wiseCharcoal)
                    .lineLimit(1)

                Spacer()

                let total = chartDataService.prepareCategoryData(colorScheme: colorScheme).reduce(0.0) { $0 + $1.amount }
                let percentage = total > 0 ? (item.amount / total) * 100 : 0

                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.wiseMidGray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedCategory?.id == item.id ? item.swiftUIColor.opacity(0.1) : Color.clear)
            )
        }
    }

    // MARK: - Helper Methods

    private func formatAxisAmount(_ amount: Double) -> String {
        let currency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
        let symbol = currency.symbol
        if amount >= 1000 {
            return String(format: "%@%.0fk", symbol, amount / 1000)
        } else {
            return amount.asCurrency
        }
    }
}

// MARK: - Category Share Pie Chart (Alternative)

struct CategorySharePieChart: View {
    @StateObject private var chartDataService = ChartDataService.shared
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedSegment: CategoryShare?

    var body: some View {
        let categoryShares = chartDataService.prepareCategoryDistributionData(colorScheme: colorScheme)

        VStack(spacing: 16) {
            // Title and Total
            if let selected = selectedSegment {
                selectedSegmentInfo(selected)
            } else {
                headerInfo(categoryShares)
            }

            // Pie Chart with Swift Charts
            Chart(categoryShares) { share in
                SectorMark(
                    angle: .value("Percentage", share.percentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 2.0
                )
                .foregroundStyle(share.swiftUIColor.gradient)
                .opacity(selectedSegment == nil || selectedSegment?.id == share.id ? 1.0 : 0.4)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartAngleSelection(value: $selectedSegment)

            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(categoryShares.prefix(5)) { share in
                    legendRow(share: share)
                }
            }
        }
    }

    private func headerInfo(_ shares: [CategoryShare]) -> some View {
        let total = shares.reduce(0.0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 4) {
            Text(dataManager.formatCurrency(total))
                .font(.title2.bold())
                .foregroundColor(.wiseCharcoal)

            Text("\(shares.count) Categories")
                .font(.subheadline)
                .foregroundColor(.wiseMidGray)
        }
    }

    private func selectedSegmentInfo(_ share: CategoryShare) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(share.swiftUIColor)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(share.category)
                    .font(.headline)
                    .foregroundColor(.wiseCharcoal)

                HStack(spacing: 8) {
                    Text(dataManager.formatCurrency(share.amount))
                        .font(.title3.bold())
                        .foregroundColor(.wiseCharcoal)

                    Text(String(format: "%.1f%%", share.percentage))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.wiseMidGray)
                }
            }

            Spacer()
        }
    }

    private func legendRow(share: CategoryShare) -> some View {
        HStack {
            Circle()
                .fill(share.swiftUIColor)
                .frame(width: 10, height: 10)

            Text(share.category)
                .font(.subheadline)
                .foregroundColor(.wiseCharcoal)

            Spacer()

            Text(String(format: "%.1f%%", share.percentage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.wiseMidGray)
        }
    }
}

// MARK: - Preview

struct CategoryBreakdownChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            CategoryBreakdownChart(chartType: .pie)
                .frame(height: 300)

            CategoryBreakdownChart(chartType: .bar)
                .frame(height: 300)
        }
        .environmentObject(DataManager.shared)
        .padding()
    }
}
