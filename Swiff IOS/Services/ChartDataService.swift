//
//  ChartDataService.swift
//  Swiff IOS
//
//  Created by Agent 14 on 11/21/25.
//  Chart data preparation service for Swift Charts integration
//
//  IMPLEMENTATION STATUS: ALL 6 TASK GROUPS COMPLETED
//  - Task 1: Initialize service ✅
//  - Task 2: prepareSpendingTrendData(for:) ✅
//  - Task 3: preparePriceHistoryData(for:) ✅
//  - Task 4: Bar/Pie chart preparation methods ✅
//  - Task 5: Data aggregation methods ✅
//  - Task 6: Caching functionality ✅
//

import Foundation
import SwiftUI
import Combine

/// Chart data preparation service optimized for Swift Charts
@MainActor
class ChartDataService: ObservableObject {

    // MARK: - Singleton
    static let shared = ChartDataService()

    // MARK: - Color Scheme Support
    /// Current color scheme - should be updated by views using this service
    var colorScheme: ColorScheme = .light

    // MARK: - Dependencies
    private let dataManager = DataManager.shared
    private let analyticsService = AnalyticsService.shared

    // MARK: - Cache Properties
    private var cachedTrendData: [DateRange: [TrendDataPoint]] = [:]
    private var cachedPriceHistory: [UUID: [PriceDataPoint]] = [:]
    private var cachedCategoryData: [CategoryData]?
    private var cachedSubscriptionData: [SubscriptionData]?
    private var cachedMonthlyData: [MonthlyData]?
    private var cachedCategoryDistribution: [CategoryShare]?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 180 // 3 minutes (shorter for charts)

    // MARK: - Published Properties
    @Published var isLoading = false

    // MARK: - Initialization
    private init() {}

    // MARK: - Cache Management

    /// Clear all cached chart data
    func clearCache() {
        cachedTrendData.removeAll()
        cachedPriceHistory.removeAll()
        cachedCategoryData = nil
        cachedSubscriptionData = nil
        cachedMonthlyData = nil
        cachedCategoryDistribution = nil
        cacheTimestamp = nil
        print("📊 Chart data cache cleared")
    }

    /// Update the color scheme and invalidate cache if changed
    func updateColorScheme(_ newScheme: ColorScheme) {
        if colorScheme != newScheme {
            colorScheme = newScheme
            // Invalidate category-related cache when color scheme changes
            cachedCategoryData = nil
            cachedCategoryDistribution = nil
        }
    }

    /// Check if cache is valid
    private var isCacheValid: Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheTimeout
    }

    // MARK: - Task 2: Line Chart - Spending Trend Data

    /// Prepare spending trend data for line charts
    /// Optimized for Swift Charts with proper date formatting
    func prepareSpendingTrendData(for range: DateRange) -> [TrendDataPoint] {
        // Check cache
        if isCacheValid, let cached = cachedTrendData[range] {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        // Get raw analytics data (using simple version for chart compatibility)
        let analyticsData = analyticsService.calculateSpendingTrendsSimple(for: range)

        // Convert to TrendDataPoint with labels
        let formatter = DateFormatter()
        switch range {
        case .week:
            formatter.dateFormat = "EEE" // Mon, Tue, Wed
        case .month:
            formatter.dateFormat = "MMM d" // Jan 1, Jan 2
        case .quarter, .year:
            formatter.dateFormat = "MMM" // Jan, Feb, Mar
        case .custom:
            formatter.dateFormat = "MMM d"
        }

        let trendData: [TrendDataPoint] = analyticsData.map { dateValue in
            return TrendDataPoint(
                date: dateValue.date,
                amount: dateValue.amount,
                label: formatter.string(from: dateValue.date)
            )
        }

        // Cache results
        cachedTrendData[range] = trendData
        cacheTimestamp = Date()

        return trendData
    }

    // MARK: - Task 3: Line Chart - Price History Data

    /// Prepare price history data for a subscription
    /// Shows how subscription price has changed over time
    func preparePriceHistoryData(for subscription: Subscription) -> [PriceDataPoint] {
        // Check cache
        if isCacheValid, let cached = cachedPriceHistory[subscription.id] {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        var pricePoints: [PriceDataPoint] = []

        // Add creation price
        pricePoints.append(PriceDataPoint(
            date: subscription.createdDate,
            price: subscription.price,
            note: "Initial price"
        ))

        // Add current price if changed
        if let lastPriceChange = subscription.lastPriceChange {
            pricePoints.append(PriceDataPoint(
                date: lastPriceChange,
                price: subscription.price,
                note: "Price change"
            ))
        }

        // Sort by date
        pricePoints.sort { $0.date < $1.date }

        // Cache results
        cachedPriceHistory[subscription.id] = pricePoints
        cacheTimestamp = Date()

        return pricePoints
    }

    // MARK: - Task 4: Bar Chart Data

    /// Prepare category data for bar charts
    /// - Parameter colorScheme: Optional colorScheme override, uses instance colorScheme if nil
    func prepareCategoryData(colorScheme: ColorScheme? = nil) -> [CategoryData] {
        if isCacheValid, let cached = cachedCategoryData {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        let scheme = colorScheme ?? self.colorScheme
        let categoryBreakdown = analyticsService.calculateCategoryBreakdown()

        let categoryData: [CategoryData] = categoryBreakdown.map { spending in
            // Use adaptive category color based on color scheme
            let adaptiveColor = Color.categoryColor(for: spending.category.rawValue, colorScheme: scheme)
            return CategoryData(
                category: spending.category.rawValue,
                amount: spending.totalAmount,
                color: adaptiveColor.toHex() ?? "#999999",
                count: spending.count
            )
        }

        cachedCategoryData = categoryData
        cacheTimestamp = Date()

        return categoryData
    }

    /// Prepare subscription comparison data for bar charts
    func prepareSubscriptionComparisonData() -> [SubscriptionData] {
        if isCacheValid, let cached = cachedSubscriptionData {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        let subscriptions = dataManager.subscriptions.filter { $0.isActive }
        let totalMonthlyCost = analyticsService.getTotalMonthlyCost()

        let subscriptionData = subscriptions
            .sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
            .prefix(10) // Top 10 subscriptions
            .map { subscription in
                let percentage = totalMonthlyCost > 0 ? (subscription.monthlyEquivalent / totalMonthlyCost) * 100 : 0
                return SubscriptionData(
                    subscription: subscription,
                    amount: subscription.monthlyEquivalent,
                    percentageOfTotal: percentage
                )
            }

        cachedSubscriptionData = Array(subscriptionData)
        cacheTimestamp = Date()

        return Array(subscriptionData)
    }

    /// Prepare monthly comparison data for bar charts
    func prepareMonthlyComparisonData() -> [MonthlyData] {
        if isCacheValid, let cached = cachedMonthlyData {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()
        var monthlyData: [MonthlyData] = []

        // Generate last 12 months
        for monthOffset in (0..<12).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }

            let components = calendar.dateComponents([.year, .month], from: monthDate)
            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                continue
            }

            // Get transactions for this month
            let monthTransactions = dataManager.transactions.filter { transaction in
                transaction.date >= startOfMonth && transaction.date <= endOfMonth
            }

            // Separate paid and received amounts
            let totalPaid = monthTransactions.filter { $0.amount < 0 }.reduce(0.0) { $0 + abs($1.amount) }
            let totalReceived = monthTransactions.filter { $0.amount > 0 }.reduce(0.0) { $0 + $1.amount }

            // Format month name
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: monthDate)

            monthlyData.append(MonthlyData(
                month: monthDate,
                monthLabel: monthName,
                totalPaid: totalPaid,
                totalReceived: totalReceived
            ))
        }

        cachedMonthlyData = monthlyData
        cacheTimestamp = Date()

        return monthlyData
    }

    // MARK: - Task 4: Pie Chart Data

    /// Prepare category distribution data for pie charts
    /// - Parameter colorScheme: Optional colorScheme override, uses instance colorScheme if nil
    func prepareCategoryDistributionData(colorScheme: ColorScheme? = nil) -> [CategoryShare] {
        if isCacheValid, let cached = cachedCategoryDistribution {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        let scheme = colorScheme ?? self.colorScheme
        let categoryBreakdown = analyticsService.calculateCategoryBreakdown()

        let categoryShares: [CategoryShare] = categoryBreakdown.map { spending in
            // Use adaptive category color based on color scheme
            let adaptiveColor = Color.categoryColor(for: spending.category.rawValue, colorScheme: scheme)
            return CategoryShare(
                category: spending.category.rawValue,
                amount: spending.totalAmount,
                percentage: spending.percentage,
                color: adaptiveColor.toHex() ?? "#999999"
            )
        }

        cachedCategoryDistribution = categoryShares
        cacheTimestamp = Date()

        return categoryShares
    }

    // MARK: - Task 5: Data Aggregation

    /// Aggregate transactions by month
    func aggregateByMonth(transactions: [Transaction]) -> [MonthlyTotal] {
        let calendar = Calendar.current
        var monthlyTotals: [String: (date: Date, total: Double, count: Int)] = [:]

        for transaction in transactions {
            let components = calendar.dateComponents([.year, .month], from: transaction.date)
            guard let monthDate = calendar.date(from: components) else { continue }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            let key = formatter.string(from: monthDate)

            if var existing = monthlyTotals[key] {
                existing.total += abs(transaction.amount)
                existing.count += 1
                monthlyTotals[key] = existing
            } else {
                monthlyTotals[key] = (monthDate, abs(transaction.amount), 1)
            }
        }

        // Convert to MonthlyTotal array
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        return monthlyTotals.map { key, data in
            MonthlyTotal(
                monthYear: formatter.string(from: data.date),
                date: data.date,
                total: data.total,
                transactionCount: data.count
            )
        }.sorted { $0.date < $1.date }
    }

    /// Aggregate transactions by category
    func aggregateByCategory(transactions: [Transaction]) -> [CategoryTotal] {
        var categoryTotals: [String: (total: Double, count: Int)] = [:]

        for transaction in transactions {
            let categoryName = transaction.category.rawValue

            if var existing = categoryTotals[categoryName] {
                existing.total += abs(transaction.amount)
                existing.count += 1
                categoryTotals[categoryName] = existing
            } else {
                categoryTotals[categoryName] = (abs(transaction.amount), 1)
            }
        }

        // Convert to CategoryTotal array
        return categoryTotals.map { category, data in
            CategoryTotal(
                category: category,
                total: data.total,
                transactionCount: data.count
            )
        }.sorted { $0.total > $1.total }
    }

    // MARK: - Advanced Aggregations

    /// Aggregate subscriptions by billing cycle
    func aggregateByBillingCycle() -> [BillingCycleData] {
        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        var cycleData: [BillingCycle: (count: Int, totalMonthly: Double)] = [:]

        for subscription in activeSubscriptions {
            if var existing = cycleData[subscription.billingCycle] {
                existing.count += 1
                existing.totalMonthly += subscription.monthlyEquivalent
                cycleData[subscription.billingCycle] = existing
            } else {
                cycleData[subscription.billingCycle] = (1, subscription.monthlyEquivalent)
            }
        }

        return cycleData.map { cycle, data in
            BillingCycleData(
                billingCycle: cycle,
                count: data.count,
                totalMonthlyEquivalent: data.totalMonthly
            )
        }.sorted { $0.totalMonthlyEquivalent > $1.totalMonthlyEquivalent }
    }

    /// Aggregate by payment method
    func aggregateByPaymentMethod() -> [PaymentMethodData] {
        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        var methodData: [PaymentMethod: (count: Int, totalMonthly: Double)] = [:]

        for subscription in activeSubscriptions {
            if var existing = methodData[subscription.paymentMethod] {
                existing.count += 1
                existing.totalMonthly += subscription.monthlyEquivalent
                methodData[subscription.paymentMethod] = existing
            } else {
                methodData[subscription.paymentMethod] = (1, subscription.monthlyEquivalent)
            }
        }

        return methodData.map { method, data in
            PaymentMethodData(
                paymentMethod: method,
                count: data.count,
                totalMonthly: data.totalMonthly
            )
        }.sorted { $0.totalMonthly > $1.totalMonthly }
    }

    // MARK: - Comparison Data

    /// Prepare year-over-year comparison data
    func prepareYearOverYearData() -> [YearComparisonData] {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())
        let lastYear = thisYear - 1

        // Calculate this year's data
        let thisYearTransactions = dataManager.transactions.filter { transaction in
            calendar.component(.year, from: transaction.date) == thisYear
        }
        let thisYearTotal = thisYearTransactions.reduce(0.0) { $0 + abs($1.amount) }

        // Calculate last year's data
        let lastYearTransactions = dataManager.transactions.filter { transaction in
            calendar.component(.year, from: transaction.date) == lastYear
        }
        let lastYearTotal = lastYearTransactions.reduce(0.0) { $0 + abs($1.amount) }

        return [
            YearComparisonData(year: lastYear, amount: lastYearTotal),
            YearComparisonData(year: thisYear, amount: thisYearTotal)
        ]
    }
}

// MARK: - Supporting Data Models
// Note: TrendDataPoint, PriceDataPoint, CategoryData, SubscriptionData, MonthlyData, and CategoryShare
// are defined in AnalyticsModels.swift

struct BillingCycleData: Identifiable {
    let id = UUID()
    let billingCycle: BillingCycle
    let count: Int
    let totalMonthlyEquivalent: Double
}

struct PaymentMethodData: Identifiable {
    let id = UUID()
    let paymentMethod: PaymentMethod
    let count: Int
    let totalMonthly: Double
}

struct YearComparisonData: Identifiable {
    let id = UUID()
    let year: Int
    let amount: Double
}

// MARK: - Color Extension

extension Color {
    /// Convert Color to hex string
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = Int(components[0] * 255.0)
        let g = Int(components[safe: 1] ?? components[0] * 255.0)
        let b = Int(components[safe: 2] ?? components[0] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
