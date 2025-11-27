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

// MARK: - Category Row

struct CategoryRow: View {
    let item: ChartDataItem
    let isIncome: Bool
    let isSelected: Bool

    private var gradientColor: Color {
        GradientColorHelper.gradientColor(for: item.percentage, isIncome: isIncome)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Row: Icon, Name, Amount
            HStack(spacing: 12) {
                // Category Icon with colored background
                ZStack {
                    Circle()
                        .fill(gradientColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    if let icon = item.icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(gradientColor)
                    }
                }

                // Category Name
                Text(item.category)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                // Amount and Percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(item.amount))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.wisePrimaryText)

                    Text(String(format: "%.1f%%", item.percentage))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.wiseMidGray.opacity(0.1))
                        .frame(height: 6)

                    // Progress with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientColor.opacity(0.6),
                                    gradientColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (item.percentage / 100),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? gradientColor.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? gradientColor.opacity(0.4) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
