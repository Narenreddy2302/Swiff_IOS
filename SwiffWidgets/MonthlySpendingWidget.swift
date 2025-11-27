//
//  MonthlySpendingWidget.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Widget showing monthly spending statistics
//

import WidgetKit
import SwiftUI
import Charts

// MARK: - Timeline Provider

struct MonthlySpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlySpendingEntry {
        let spending = WidgetDataService.shared.loadMonthlySpending()
        return MonthlySpendingEntry(date: Date(), spending: spending)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlySpendingEntry) -> Void) {
        let spending = WidgetDataService.shared.loadMonthlySpending()
        let entry = MonthlySpendingEntry(date: Date(), spending: spending)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlySpendingEntry>) -> Void) {
        let spending = WidgetDataService.shared.loadMonthlySpending()
        let entry = MonthlySpendingEntry(date: Date(), spending: spending)

        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)

        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct MonthlySpendingEntry: TimelineEntry {
    let date: Date
    let spending: WidgetMonthlySpending
}

// MARK: - Widget Views

struct MonthlySpendingWidgetEntryView: View {
    var entry: MonthlySpendingProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallMonthlySpendingView(spending: entry.spending)
        case .systemMedium:
            MediumMonthlySpendingView(spending: entry.spending)
        case .systemLarge:
            LargeMonthlySpendingView(spending: entry.spending)
        default:
            SmallMonthlySpendingView(spending: entry.spending)
        }
    }
}

// MARK: - Small Widget (2x2)

struct SmallMonthlySpendingView: View {
    let spending: WidgetMonthlySpending

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: spending.trendDirection.color).opacity(0.1),
                    Color(hex: spending.trendDirection.color).opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Spending")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text(spending.formattedCurrentMonth)
                    .font(.system(size: 32, weight: .bold))

                HStack(spacing: 6) {
                    Text(spending.trendDirection.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: spending.trendDirection.color))

                    Text(spending.formattedPercentageChange)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: spending.trendDirection.color))
                }

                Text("vs last month")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
    }
}

// MARK: - Medium Widget (4x2)

struct MediumMonthlySpendingView: View {
    let spending: WidgetMonthlySpending

    var last6Months: [WidgetMonthlySpending.MonthData] {
        Array(spending.monthlyHistory.suffix(6))
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("This Month")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text(spending.formattedCurrentMonth)
                    .font(.system(size: 24, weight: .bold))

                HStack(spacing: 4) {
                    Text(spending.trendDirection.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: spending.trendDirection.color))

                    Text(spending.formattedPercentageChange)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: spending.trendDirection.color))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(spending.topCategories.prefix(2)) { category in
                        HStack {
                            Text(category.category)
                                .font(.system(size: 10))
                                .lineLimit(1)

                            Spacer()

                            Text(category.formattedPercentage)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(red: 0.0, green: 0.725, blue: 1.0))
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 4) {
                Text("Last 6 Months")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(last6Months, id: \.month) { data in
                            BarMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.amount)
                            )
                            .foregroundStyle(Color(red: 0.0, green: 0.725, blue: 1.0).gradient)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 80)
                } else {
                    SimplifiedBarChart(data: last6Months)
                        .frame(height: 80)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Large Widget (4x4)

struct LargeMonthlySpendingView: View {
    let spending: WidgetMonthlySpending

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Spending")
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 8) {
                        Text(spending.formattedCurrentMonth)
                            .font(.system(size: 24, weight: .bold))

                        HStack(spacing: 4) {
                            Text(spending.trendDirection.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: spending.trendDirection.color))

                            Text(spending.formattedPercentageChange)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: spending.trendDirection.color))
                        }
                    }
                }

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.0, green: 0.725, blue: 1.0))
            }
            .padding(16)

            Divider()

            VStack(spacing: 12) {
                Text("Last 12 Months")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(spending.monthlyHistory, id: \.month) { data in
                            BarMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.amount)
                            )
                            .foregroundStyle(Color(red: 0.0, green: 0.725, blue: 1.0).gradient)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text("$\(Int(amount))")
                                        .font(.system(size: 9))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let month = value.as(String.self) {
                                    Text(month)
                                        .font(.system(size: 9))
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 16)
                } else {
                    SimplifiedBarChart(data: spending.monthlyHistory)
                        .frame(height: 120)
                        .padding(.horizontal, 16)
                }

                Divider()

                VStack(spacing: 8) {
                    Text("Top Categories")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(spending.topCategories) { category in
                        HStack {
                            Text(category.category)
                                .font(.system(size: 11))

                            Spacer()

                            Text(category.formattedAmount)
                                .font(.system(size: 11, weight: .semibold))

                            Text(category.formattedPercentage)
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.0, green: 0.725, blue: 1.0))
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)

            Spacer()
        }
    }
}

// MARK: - Simplified Bar Chart (Fallback for iOS < 16)

struct SimplifiedBarChart: View {
    let data: [WidgetMonthlySpending.MonthData]

    var maxAmount: Double {
        data.map { $0.amount }.max() ?? 100
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data, id: \.month) { item in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color(red: 0.0, green: 0.725, blue: 1.0).gradient)
                        .frame(width: 16, height: CGFloat(item.amount / maxAmount) * 80)
                        .cornerRadius(2)

                    Text(item.month)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Widget Configuration

struct MonthlySpendingWidget: Widget {
    let kind: String = WidgetConfiguration.monthlySpendingWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlySpendingProvider()) { entry in
            MonthlySpendingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Monthly Spending")
        .description("Track your monthly subscription spending and trends.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
