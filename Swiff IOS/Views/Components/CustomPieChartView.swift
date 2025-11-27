//
//  CustomPieChartView.swift
//  Swiff IOS
//
//  Custom pie chart component for statistics page
//

import SwiftUI
import Charts

// MARK: - Chart Data Models

struct ChartDataItem: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let color: Color
    let icon: String?

    var percentage: Double = 0.0
}

// MARK: - Custom Pie Chart View

struct CustomPieChartView: View {
    let title: String
    let data: [ChartDataItem]
    let showLegend: Bool
    let showCenterValue: Bool

    @State private var selectedCategory: String?

    init(
        title: String,
        data: [ChartDataItem],
        showLegend: Bool = true,
        showCenterValue: Bool = true
    ) {
        self.title = title
        self.data = data
        self.showLegend = showLegend
        self.showCenterValue = showCenterValue
    }

    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }

    private var dataWithPercentages: [ChartDataItem] {
        data.map { item in
            var newItem = item
            newItem.percentage = totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0
            return newItem
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text(title)
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)

            // Chart
            ZStack {
                // Pie Chart
                Chart(dataWithPercentages) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2.0
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.color)
                    .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.3)
                }
                .frame(height: 220)
                .chartAngleSelection(value: $selectedCategory)

                // Center Value (optional)
                if showCenterValue {
                    VStack(spacing: 4) {
                        Text("TOTAL")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(formatCurrency(totalAmount))
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
            }

            // Legend (optional)
            if showLegend {
                VStack(spacing: 12) {
                    ForEach(dataWithPercentages) { item in
                        HStack(spacing: 12) {
                            // Color indicator
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)

                            // Icon (optional)
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(item.color)
                            }

                            // Category name
                            Text(item.category)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            // Amount and percentage
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatCurrency(item.amount))
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.wisePrimaryText)

                                Text(String(format: "%.1f%%", item.percentage))
                                    .font(.caption)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            selectedCategory == item.category ?
                            item.color.opacity(0.1) : Color.clear
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = selectedCategory == item.category ? nil : item.category
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Compact Pie Chart (without legend)

struct CompactPieChartView: View {
    let data: [ChartDataItem]
    let size: CGFloat

    init(data: [ChartDataItem], size: CGFloat = 180) {
        self.data = data
        self.size = size
    }

    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            Chart(data) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2.0
                )
                .cornerRadius(4)
                .foregroundStyle(item.color)
            }
            .frame(width: size, height: size)

            VStack(spacing: 4) {
                Text("TOTAL")
                    .font(.caption)
                    .foregroundColor(.wiseSecondaryText)

                Text(formatCurrency(totalAmount))
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }
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

// MARK: - Chart Colors Helper

struct ChartColorPalette {
    static let colors: [Color] = [
        .wiseBlue,
        .wiseBrightGreen,
        .wiseOrange,
        .wisePurple,
        Color(red: 0.3, green: 0.7, blue: 0.9),  // Light blue
        Color(red: 0.8, green: 0.4, blue: 0.6),  // Pink
        Color(red: 0.4, green: 0.8, blue: 0.7),  // Teal
        Color(red: 0.9, green: 0.7, blue: 0.3),  // Yellow
        Color(red: 0.6, green: 0.5, blue: 0.9),  // Lavender
        Color(red: 0.9, green: 0.5, blue: 0.4),  // Coral
    ]

    static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }

    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "entertainment", "streaming":
            return .wisePurple
        case "food", "groceries", "dining":
            return .wiseOrange
        case "transportation", "travel":
            return .wiseBlue
        case "utilities", "bills":
            return Color(red: 0.3, green: 0.7, blue: 0.9)
        case "shopping", "retail":
            return Color(red: 0.8, green: 0.4, blue: 0.6)
        case "health", "fitness":
            return .wiseBrightGreen
        case "education", "learning":
            return Color(red: 0.4, green: 0.8, blue: 0.7)
        case "income", "salary":
            return .wiseBrightGreen
        case "bill splitting", "shared":
            return .wiseBlue
        default:
            return .wiseMidGray
        }
    }
}

// MARK: - Previews

#Preview("Income Breakdown") {
    let sampleData = [
        ChartDataItem(
            category: "Salary",
            amount: 5000,
            color: ChartColorPalette.categoryColor(for: "Salary"),
            icon: "dollarsign.circle.fill"
        ),
        ChartDataItem(
            category: "Freelance",
            amount: 1500,
            color: ChartColorPalette.categoryColor(for: "Freelance"),
            icon: "briefcase.fill"
        ),
        ChartDataItem(
            category: "Investments",
            amount: 800,
            color: ChartColorPalette.categoryColor(for: "Investments"),
            icon: "chart.line.uptrend.xyaxis"
        ),
        ChartDataItem(
            category: "Other",
            amount: 300,
            color: ChartColorPalette.categoryColor(for: "Other"),
            icon: "ellipsis.circle.fill"
        )
    ]

    return ScrollView {
        CustomPieChartView(
            title: "Income Breakdown",
            data: sampleData
        )
        .padding()
    }
}

#Preview("Expense Breakdown") {
    let sampleData = [
        ChartDataItem(
            category: "Subscriptions",
            amount: 1200,
            color: ChartColorPalette.categoryColor(for: "Entertainment"),
            icon: "star.circle.fill"
        ),
        ChartDataItem(
            category: "Groceries",
            amount: 800,
            color: ChartColorPalette.categoryColor(for: "Food"),
            icon: "cart.fill"
        ),
        ChartDataItem(
            category: "Transportation",
            amount: 500,
            color: ChartColorPalette.categoryColor(for: "Transportation"),
            icon: "car.fill"
        ),
        ChartDataItem(
            category: "Utilities",
            amount: 350,
            color: ChartColorPalette.categoryColor(for: "Utilities"),
            icon: "bolt.fill"
        ),
        ChartDataItem(
            category: "Shopping",
            amount: 600,
            color: ChartColorPalette.categoryColor(for: "Shopping"),
            icon: "bag.fill"
        )
    ]

    return ScrollView {
        CustomPieChartView(
            title: "Expense Breakdown",
            data: sampleData
        )
        .padding()
    }
}

#Preview("Bill Splitting") {
    let sampleData = [
        ChartDataItem(
            category: "Rent",
            amount: 1500,
            color: ChartColorPalette.categoryColor(for: "Bills"),
            icon: "house.fill"
        ),
        ChartDataItem(
            category: "Utilities",
            amount: 200,
            color: ChartColorPalette.categoryColor(for: "Utilities"),
            icon: "bolt.fill"
        ),
        ChartDataItem(
            category: "Internet",
            amount: 80,
            color: ChartColorPalette.categoryColor(for: "Utilities"),
            icon: "wifi"
        ),
        ChartDataItem(
            category: "Groceries",
            amount: 350,
            color: ChartColorPalette.categoryColor(for: "Food"),
            icon: "cart.fill"
        )
    ]

    return ScrollView {
        CustomPieChartView(
            title: "Bill Splitting Breakdown",
            data: sampleData
        )
        .padding()
    }
}

#Preview("Compact Chart") {
    let sampleData = [
        ChartDataItem(category: "A", amount: 1200, color: .wiseBlue, icon: nil),
        ChartDataItem(category: "B", amount: 800, color: .wiseBrightGreen, icon: nil),
        ChartDataItem(category: "C", amount: 500, color: .wiseOrange, icon: nil),
        ChartDataItem(category: "D", amount: 350, color: .wisePurple, icon: nil)
    ]

    CompactPieChartView(data: sampleData, size: 200)
        .padding()
}
