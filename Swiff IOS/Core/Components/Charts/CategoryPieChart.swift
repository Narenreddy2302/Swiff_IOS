import SwiftUI
import Charts

struct CategoryPieChart: View {
    let data: [ChartDataItem]
    let total: Double
    let isIncome: Bool
    let dateRange: String

    @State private var selectedCategory: String?

    private var dataWithPercentages: [ChartDataItem] {
        guard total > 0 else { return data }

        return data.map { item in
            var updatedItem = item
            updatedItem.percentage = (item.amount / total) * 100
            return updatedItem
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Chart Container
            ZStack {
                // Pie Chart
                Chart(dataWithPercentages) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.618),  // Golden ratio for aesthetic donut
                        angularInset: 2.0
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.color)
                    .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.3)
                }
                .frame(height: 280)
                .chartBackground { _ in
                    Color.clear
                }
                .chartLegend(.hidden)

                // Center Total Display
                VStack(spacing: 4) {
                    Text(isIncome ? "TOTAL INCOME" : "TOTAL EXPENSES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.wiseSecondaryText)
                        .tracking(0.5)

                    Text(formatCurrency(total))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isIncome ? .wiseForestGreen : .wiseError)

                    Text(dateRange)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.wiseMidGray)
                }
            }
            .padding(.vertical, 20)
        }
        .padding(20)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = nil
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// Preview
struct CategoryPieChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Income Example
            CategoryPieChart(
                data: [
                    ChartDataItem(category: "Salary", amount: 5000, color: .green, icon: "dollarsign.circle.fill", percentage: 71.4),
                    ChartDataItem(category: "Freelance", amount: 1500, color: .green, icon: "briefcase.fill", percentage: 21.4),
                    ChartDataItem(category: "Investment", amount: 500, color: .green, icon: "chart.line.uptrend.xyaxis", percentage: 7.2)
                ],
                total: 7000,
                isIncome: true,
                dateRange: "Last 30 Days"
            )

            // Expense Example
            CategoryPieChart(
                data: [
                    ChartDataItem(category: "Food & Dining", amount: 450, color: .red, icon: "fork.knife", percentage: 45.0),
                    ChartDataItem(category: "Transportation", amount: 300, color: .red, icon: "car.fill", percentage: 30.0),
                    ChartDataItem(category: "Entertainment", amount: 150, color: .red, icon: "tv.fill", percentage: 15.0),
                    ChartDataItem(category: "Shopping", amount: 100, color: .red, icon: "bag.fill", percentage: 10.0)
                ],
                total: 1000,
                isIncome: false,
                dateRange: "Last 30 Days"
            )
        }
        .padding()
        .background(Color.wiseBackground)
    }
}
