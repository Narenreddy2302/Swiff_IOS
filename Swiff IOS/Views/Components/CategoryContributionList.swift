import SwiftUI

struct CategoryContributionList: View {
    let data: [ChartDataItem]
    let total: Double
    let isIncome: Bool

    @Binding var selectedCategory: String?

    private var dataWithPercentages: [ChartDataItem] {
        guard total > 0 else { return data }

        return data.map { item in
            var updatedItem = item
            updatedItem.percentage = (item.amount / total) * 100
            return updatedItem
        }.sorted { $0.amount > $1.amount } // Sort by amount descending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            Text("CATEGORY BREAKDOWN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.wiseSecondaryText)
                .tracking(0.5)

            // Category List
            VStack(spacing: 12) {
                ForEach(dataWithPercentages) { item in
                    CategoryRow(
                        item: item,
                        isIncome: isIncome,
                        isSelected: selectedCategory == item.category
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCategory == item.category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = item.category
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
}

// MARK: - Category Row (Unified Design with Progress Bar)

struct CategoryRow: View {
    let item: ChartDataItem
    let isIncome: Bool
    let isSelected: Bool

    private var gradientColor: Color {
        GradientColorHelper.gradientColor(for: item.percentage, isIncome: isIncome)
    }

    private var subtitleText: String {
        isIncome ? "Income" : "Expense"
    }

    var body: some View {
        UnifiedListRowWithProgress(
            title: item.category,
            subtitle: subtitleText,
            value: formatCurrency(item.amount),
            valueColor: gradientColor,
            percentage: item.percentage,
            valueLabel: String(format: "%.1f%%", item.percentage),
            isSelected: isSelected
        ) {
            UnifiedIconCircle(
                icon: item.icon ?? "circle.fill",
                color: gradientColor
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - Previews

struct CategoryContributionList_Previews: PreviewProvider {
    @State static var selectedCategory: String? = nil

    static var previews: some View {
        VStack(spacing: 20) {
            // Income Example
            CategoryContributionList(
                data: [
                    ChartDataItem(category: "Salary", amount: 5000, color: .green, icon: "dollarsign.circle.fill", percentage: 71.4),
                    ChartDataItem(category: "Freelance", amount: 1500, color: .green, icon: "briefcase.fill", percentage: 21.4),
                    ChartDataItem(category: "Investment", amount: 500, color: .green, icon: "chart.line.uptrend.xyaxis", percentage: 7.2)
                ],
                total: 7000,
                isIncome: true,
                selectedCategory: .constant(nil)
            )

            // Expense Example
            CategoryContributionList(
                data: [
                    ChartDataItem(category: "Food & Dining", amount: 450, color: .red, icon: "fork.knife", percentage: 45.0),
                    ChartDataItem(category: "Transportation", amount: 300, color: .red, icon: "car.fill", percentage: 30.0),
                    ChartDataItem(category: "Entertainment", amount: 150, color: .red, icon: "tv.fill", percentage: 15.0),
                    ChartDataItem(category: "Shopping", amount: 100, color: .red, icon: "bag.fill", percentage: 10.0)
                ],
                total: 1000,
                isIncome: false,
                selectedCategory: .constant("Food & Dining")
            )
        }
        .padding()
        .background(Color.wiseBackground)
    }
}
