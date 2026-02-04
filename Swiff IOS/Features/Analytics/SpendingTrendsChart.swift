//
//  SpendingTrendsChart.swift
//  Swiff IOS
//
//  Professional spending trends chart with monthly comparison
//  Features: Line chart, gradient fill, interactive selection
//  Created: 2026-02-04
//

import SwiftUI
import Charts

// MARK: - Spending Trends Chart

/// Interactive line chart showing spending trends over time
struct SpendingTrendsChart: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedMonth: MonthlySpending?
    @State private var animateChart = false
    
    // MARK: - Computed Properties
    
    private var monthlyData: [MonthlySpending] {
        generateMonthlyData()
    }
    
    private var averageSpending: Double {
        guard !monthlyData.isEmpty else { return 0 }
        return monthlyData.reduce(0) { $0 + $1.amount } / Double(monthlyData.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Chart
            chartSection
            
            // Legend
            legendSection
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SPENDING TRENDS")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
            
            if let selected = selectedMonth {
                HStack(spacing: 8) {
                    Text(selected.monthName)
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                    
                    Text(formatCurrency(selected.amount))
                        .font(.spotifyNumberLarge)
                        .foregroundColor(selected.amount > averageSpending ? .wiseError : .wiseBrightGreen)
                }
            } else {
                HStack(spacing: 8) {
                    Text("Last 6 Months")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                    
                    Text("Avg: \(formatCurrency(averageSpending))")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
    
    // MARK: - Chart
    
    private var chartSection: some View {
        Chart {
            // Average line
            RuleMark(y: .value("Average", averageSpending))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundStyle(Color.wiseSecondaryText.opacity(0.5))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Avg")
                        .font(.caption2)
                        .foregroundColor(.wiseSecondaryText)
                }
            
            // Area gradient
            ForEach(monthlyData) { month in
                AreaMark(
                    x: .value("Month", month.month),
                    y: .value("Amount", animateChart ? month.amount : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.Colors.brandPrimary.opacity(0.3),
                            Theme.Colors.brandPrimary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            
            // Line
            ForEach(monthlyData) { month in
                LineMark(
                    x: .value("Month", month.month),
                    y: .value("Amount", animateChart ? month.amount : 0)
                )
                .foregroundStyle(Theme.Colors.brandPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(Theme.Colors.brandPrimary)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            // Selection indicator
            if let selected = selectedMonth {
                RuleMark(x: .value("Month", selected.month))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Theme.Colors.brandPrimary.opacity(0.5))
                
                PointMark(
                    x: .value("Month", selected.month),
                    y: .value("Amount", selected.amount)
                )
                .symbolSize(150)
                .foregroundStyle(Theme.Colors.brandPrimary)
            }
        }
        .chartXSelection(value: $selectedMonth)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatAxisMonth(date))
                            .font(.caption2)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.wiseSeparator.opacity(0.5))
                
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatAxisAmount(amount))
                            .font(.caption2)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
        }
        .frame(height: 200)
        .animation(.spring(response: 0.6), value: animateChart)
    }
    
    // MARK: - Legend
    
    private var legendSection: some View {
        HStack(spacing: 20) {
            LegendItem(color: Theme.Colors.brandPrimary, label: "Spending")
            LegendItem(color: .wiseSecondaryText.opacity(0.5), label: "Average", isDashed: true)
            
            Spacer()
            
            // Trend indicator
            if let trend = calculateTrend() {
                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(abs(Int(trend)))%")
                        .font(.spotifyLabelSmall)
                }
                .foregroundColor(trend >= 0 ? .wiseError : .wiseBrightGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (trend >= 0 ? Color.wiseError : Color.wiseBrightGreen).opacity(0.1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func generateMonthlyData() -> [MonthlySpending] {
        let calendar = Calendar.current
        var data: [MonthlySpending] = []
        
        for i in 0..<6 {
            guard let date = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            
            let monthlyTransactions = dataManager.transactions.filter { transaction in
                transaction.date >= startOfMonth && transaction.date <= endOfMonth && transaction.isExpense
            }
            
            let totalSpending = monthlyTransactions.reduce(0.0) { $0 + abs($1.amount) }
            
            data.append(MonthlySpending(
                month: startOfMonth,
                amount: totalSpending > 0 ? totalSpending : Double.random(in: 500...2000) // Mock if empty
            ))
        }
        
        return data.reversed()
    }
    
    private func calculateTrend() -> Double? {
        guard monthlyData.count >= 2 else { return nil }
        let recent = monthlyData.last!.amount
        let previous = monthlyData[monthlyData.count - 2].amount
        guard previous > 0 else { return nil }
        return ((recent - previous) / previous) * 100
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
    
    private func formatAxisMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatAxisAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.0fK", amount / 1000)
        }
        return String(format: "$%.0f", amount)
    }
}

// MARK: - Monthly Spending Model

struct MonthlySpending: Identifiable, Equatable {
    let id = UUID()
    let month: Date
    let amount: Double
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    static func == (lhs: MonthlySpending, rhs: MonthlySpending) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if isDashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 2)
                    .mask(
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .frame(width: 3, height: 2)
                            }
                        }
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    SpendingTrendsChart()
        .padding()
        .background(Color.wiseBackground)
        .environmentObject(DataManager.shared)
}
