//
//  AnalyticsService.swift
//  Swiff IOS
//
//  Created by Agent 6 and Agent 14, Merged by Integration Agent Alpha on 11/21/25.
//  Comprehensive analytics service for subscription tracking, forecasting, and insights
//
//  MERGE STATUS: COMPLETED
//  - Agent 6 methods: calculateSpendingTrends, calculateYearOverYear, getTrendAnalysis, generateSampleData
//  - Agent 14 methods: All caching infrastructure, forecasting, detection algorithms, recommendations
//  - All unique methods from both agents preserved
//

import Foundation
import Combine
import SwiftUI

// MARK: - AGENT 6 + AGENT 14: Unified Analytics Service

/// Main analytics service providing spending trends, forecasting, and recommendations
@MainActor
class AnalyticsService: ObservableObject {

    // MARK: - Singleton
    static let shared = AnalyticsService()

    // MARK: - Dependencies
    private let dataManager = DataManager.shared

    // MARK: - AGENT 14: Cache Properties
    private var cachedSpendingTrends: [DateRange: [DateValue]] = [:]
    private var cachedSpendingDataPoints: [DateRange: [SpendingDataPoint]] = [:] // AGENT 6
    private var cachedCategoryBreakdown: [CategorySpending]?
    private var cachedMonthlyAverage: Double?
    private var cachedForecast: (months: Int, values: [ForecastValue])?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    // MARK: - AGENT 14: Published Properties
    @Published var isCalculating = false
    @Published var lastError: Error?

    // MARK: - Initialization
    private init() {}

    // MARK: - AGENT 14: Cache Management

    /// Clear all cached analytics data
    func clearCache() {
        cachedSpendingTrends.removeAll()
        cachedSpendingDataPoints.removeAll()
        cachedCategoryBreakdown = nil
        cachedMonthlyAverage = nil
        cachedForecast = nil
        cacheTimestamp = nil
        print("📊 Analytics cache cleared")
    }

    /// Check if cache is valid
    private var isCacheValid: Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheTimeout
    }

    // MARK: - AGENT 6 + AGENT 14: Spending Trends Calculation

    /// Calculate spending trends for a date range (Agent 6 version with detailed breakdown)
    /// Returns data points with separate subscription and transaction amounts
    func calculateSpendingTrends(for dateRange: DateRange) -> [SpendingDataPoint] {
        // Check cache first
        if isCacheValid, let cached = cachedSpendingDataPoints[dateRange] {
            return cached
        }

        let startDate = dateRange.startDate
        let endDate = dateRange.endDate

        // Get all subscriptions and transactions in date range
        let subscriptions = dataManager.subscriptions.filter { $0.isActive }
        let transactions = dataManager.transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }

        // Group by date buckets (daily, weekly, or monthly depending on range)
        let bucketSize = determineBucketSize(for: dateRange)
        var dataPoints: [Date: (subscriptions: Double, transactions: Double)] = [:]

        // Process subscriptions - calculate monthly equivalent for each date
        let calendar = Calendar.current
        var currentDate = startDate
        while currentDate <= endDate {
            let monthlyTotal = subscriptions.reduce(0.0) { total, sub in
                total + sub.monthlyEquivalent
            }
            dataPoints[currentDate] = (monthlyTotal, 0.0)
            currentDate = calendar.date(byAdding: bucketSize.component, value: 1, to: currentDate) ?? endDate
        }

        // Process transactions
        for transaction in transactions {
            let bucketDate = bucketDate(for: transaction.date, bucketSize: bucketSize)
            if var existing = dataPoints[bucketDate] {
                existing.transactions += abs(transaction.amount)
                dataPoints[bucketDate] = existing
            } else {
                dataPoints[bucketDate] = (0.0, abs(transaction.amount))
            }
        }

        // Convert to SpendingDataPoint array
        let sortedPoints = dataPoints.sorted { $0.key < $1.key }
        let totalAverage = dataPoints.values.map { $0.subscriptions + $0.transactions }.reduce(0, +) / Double(max(dataPoints.count, 1))

        let result = sortedPoints.map { date, amounts in
            let totalAmount = amounts.subscriptions + amounts.transactions
            let isSignificant = totalAmount > (totalAverage * 1.5)
            let annotation = isSignificant ? "High spending" : nil

            return SpendingDataPoint(
                date: date,
                amount: totalAmount,
                subscriptionsAmount: amounts.subscriptions,
                transactionsAmount: amounts.transactions,
                isSignificant: isSignificant,
                annotation: annotation
            )
        }

        // Cache results
        cachedSpendingDataPoints[dateRange] = result
        cacheTimestamp = Date()

        return result
    }

    /// Calculate spending trends (Agent 14 version - simpler DateValue format)
    /// Used by chart components that expect DateValue format
    func calculateSpendingTrendsSimple(for dateRange: DateRange) -> [DateValue] {
        // Check cache first
        if isCacheValid, let cached = cachedSpendingTrends[dateRange] {
            return cached
        }

        let subscriptions = dataManager.subscriptions.filter { $0.isActive }
        let startDate = dateRange.startDate
        let endDate = dateRange.endDate

        // Generate date points based on range
        let calendar = Calendar.current
        var dates: [Date] = []
        var currentDate = startDate

        // Determine interval based on range
        let component: Calendar.Component
        switch dateRange {
        case .week:
            component = .day
        case .month:
            component = .day
        case .quarter:
            component = .weekOfYear
        case .year:
            component = .month
        case .custom:
            let daysDiff = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            component = daysDiff > 90 ? .month : (daysDiff > 30 ? .weekOfYear : .day)
        }

        // Generate date array
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: component, value: 1, to: currentDate) ?? endDate
        }

        // Calculate spending for each date point
        let trends = dates.map { date -> DateValue in
            let spending = calculateSpending(for: subscriptions, at: date)
            return DateValue(date: date, amount: spending)
        }

        // Cache results
        cachedSpendingTrends[dateRange] = trends
        cacheTimestamp = Date()

        return trends
    }

    /// Helper: Calculate spending at a specific date
    private func calculateSpending(for subscriptions: [Subscription], at date: Date) -> Double {
        subscriptions.reduce(0.0) { total, subscription in
            // Only count if subscription was active at this date
            guard subscription.createdDate <= date else { return total }
            if let cancellationDate = subscription.cancellationDate, cancellationDate < date {
                return total
            }
            return total + subscription.monthlyEquivalent
        }
    }

    // MARK: - AGENT 14: Monthly Average

    /// Calculate monthly average spending
    /// Returns average monthly cost across all active subscriptions
    func calculateMonthlyAverage() -> Double {
        if isCacheValid, let cached = cachedMonthlyAverage {
            return cached
        }

        let monthlyTotal = getTotalMonthlyCost()
        cachedMonthlyAverage = monthlyTotal
        cacheTimestamp = Date()

        return monthlyTotal
    }

    // MARK: - AGENT 6: Year Over Year Comparison

    /// Calculate year-over-year comparison with detailed category analysis
    func calculateYearOverYear() -> YearOverYearComparison {
        let calendar = Calendar.current
        let now = Date()

        // Get date boundaries
        guard let thisYearStart = calendar.date(from: calendar.dateComponents([.year], from: now)),
              let lastYearStart = calendar.date(byAdding: .year, value: -1, to: thisYearStart),
              let lastYearEnd = calendar.date(byAdding: .day, value: -1, to: thisYearStart) else {
            return createEmptyYoYComparison()
        }

        // This year calculations
        let thisYearTransactions = dataManager.transactions.filter {
            $0.date >= thisYearStart && $0.date <= now
        }
        let thisYearTotal = thisYearTransactions.reduce(0.0) { $0 + abs($1.amount) }
        let thisYearMonthsPassed = calendar.dateComponents([.month], from: thisYearStart, to: now).month ?? 1
        let thisYearMonthlyAvg = thisYearTotal / Double(max(thisYearMonthsPassed, 1))

        // Last year calculations
        let lastYearTransactions = dataManager.transactions.filter {
            $0.date >= lastYearStart && $0.date <= lastYearEnd
        }
        let lastYearTotal = lastYearTransactions.reduce(0.0) { $0 + abs($1.amount) }
        let lastYearMonthlyAvg = lastYearTotal / 12.0

        // Percentage change
        let percentageChange = lastYearTotal > 0 ? ((thisYearTotal - lastYearTotal) / lastYearTotal) * 100 : 0

        // Subscription counts
        let thisYearSubs = dataManager.subscriptions.filter {
            $0.createdDate >= thisYearStart
        }.count
        let lastYearSubs = dataManager.subscriptions.filter {
            $0.createdDate >= lastYearStart && $0.createdDate < thisYearStart
        }.count

        // Category growth analysis
        let (growing, declining) = calculateCategoryGrowth(
            thisYearTransactions: thisYearTransactions,
            lastYearTransactions: lastYearTransactions
        )

        return YearOverYearComparison(
            thisYearTotal: thisYearTotal,
            lastYearTotal: lastYearTotal,
            percentageChange: percentageChange,
            thisYearMonthlyAverage: thisYearMonthlyAvg,
            lastYearMonthlyAverage: lastYearMonthlyAvg,
            thisYearSubscriptionCount: thisYearSubs,
            lastYearSubscriptionCount: lastYearSubs,
            growingCategories: growing,
            decliningCategories: declining
        )
    }

    /// AGENT 14: Calculate year-over-year change (simpler version)
    /// Returns percentage change (positive = increase, negative = decrease)
    func calculateYearOverYearChange() -> Double {
        let currentYear = calculateSpendingForYear(Date())
        let lastYear = calculateSpendingForYear(Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date())

        guard lastYear > 0 else { return 0 }

        let change = ((currentYear - lastYear) / lastYear) * 100
        return change
    }

    /// Helper: Calculate total spending for a year
    private func calculateSpendingForYear(_ date: Date) -> Double {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
            return 0
        }

        return dataManager.subscriptions.reduce(0.0) { total, subscription in
            // Check if subscription was active during this year
            guard subscription.createdDate <= endOfYear else { return total }
            if let cancellationDate = subscription.cancellationDate, cancellationDate < startOfYear {
                return total
            }

            // Calculate months active in this year
            let subscriptionStart = max(subscription.createdDate, startOfYear)
            let subscriptionEnd = min(subscription.cancellationDate ?? endOfYear, endOfYear)

            let monthsActive = calendar.dateComponents([.month], from: subscriptionStart, to: subscriptionEnd).month ?? 0

            return total + (subscription.monthlyEquivalent * Double(max(monthsActive, 1)))
        }
    }

    // MARK: - AGENT 6 + AGENT 14: Category Breakdown

    /// Calculate category breakdown with spending percentages
    func calculateCategoryBreakdown() -> [CategorySpending] {
        if isCacheValid, let cached = cachedCategoryBreakdown {
            return cached
        }

        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        let totalMonthlyCost = getTotalMonthlyCost()

        // Group by category
        var categoryMap: [SubscriptionCategory: (total: Double, count: Int)] = [:]

        for subscription in activeSubscriptions {
            let monthly = subscription.monthlyEquivalent
            if let existing = categoryMap[subscription.category] {
                categoryMap[subscription.category] = (existing.total + monthly, existing.count + 1)
            } else {
                categoryMap[subscription.category] = (monthly, 1)
            }
        }

        // Convert to CategorySpending
        let breakdown = categoryMap.map { category, data in
            CategorySpending(
                category: category,
                totalAmount: data.total,
                percentage: totalMonthlyCost > 0 ? (data.total / totalMonthlyCost) * 100 : 0,
                count: data.count
            )
        }.sorted { $0.totalAmount > $1.totalAmount }

        cachedCategoryBreakdown = breakdown
        cacheTimestamp = Date()

        return breakdown
    }

    /// Get top N categories by spending
    func getTopCategories(limit: Int) -> [CategorySpending] {
        let breakdown = calculateCategoryBreakdown()
        return Array(breakdown.prefix(limit))
    }

    // MARK: - AGENT 14: Subscription Analytics

    /// Get total monthly cost of all active subscriptions
    func getTotalMonthlyCost() -> Double {
        return dataManager.calculateTotalMonthlyCost()
    }

    /// Get average cost per subscription
    func getAverageCostPerSubscription() -> Double {
        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        guard !activeSubscriptions.isEmpty else { return 0 }

        let total = getTotalMonthlyCost()
        return total / Double(activeSubscriptions.count)
    }

    /// Get most expensive subscriptions
    func getMostExpensiveSubscriptions(limit: Int) -> [Subscription] {
        return dataManager.subscriptions
            .filter { $0.isActive }
            .sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - AGENT 6: Additional Rankings

    private func getLeastUsedSubscriptions(limit: Int) -> [Subscription] {
        return dataManager.subscriptions
            .filter { $0.isActive }
            .sorted { $0.usageCount < $1.usageCount }
            .prefix(limit)
            .map { $0 }
    }

    private func getRecentlyAddedSubscriptions(limit: Int) -> [Subscription] {
        return dataManager.subscriptions
            .filter { $0.isActive }
            .sorted { $0.createdDate > $1.createdDate }
            .prefix(limit)
            .map { $0 }
    }

    private func getTrialsEndingSoon(within days: Int) -> [Subscription] {
        let calendar = Calendar.current
        let now = Date()

        return dataManager.subscriptions.filter { subscription in
            guard subscription.isFreeTrial,
                  let endDate = subscription.trialEndDate else {
                return false
            }

            let daysUntilEnd = calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
            return daysUntilEnd >= 0 && daysUntilEnd <= days
        }.sorted { ($0.trialEndDate ?? Date.distantFuture) < ($1.trialEndDate ?? Date.distantFuture) }
    }

    // MARK: - AGENT 6 + AGENT 14: Forecasting

    /// Forecast spending for future months using linear regression
    /// Algorithm: Uses simple moving average with trend analysis
    func forecastSpending(months: Int) -> [ForecastValue] {
        // Check cache
        if isCacheValid, let cached = cachedForecast, cached.months == months {
            return cached.values
        }

        // Get historical data (last 12 months)
        let historicalTrends = calculateSpendingTrendsSimple(for: .year)

        guard historicalTrends.count >= 3 else {
            // Not enough data, use current spending
            let currentMonthly = getTotalMonthlyCost()
            return generateFlatForecast(months: months, amount: currentMonthly)
        }

        // Calculate trend using simple linear regression
        let (slope, intercept) = calculateLinearRegression(from: historicalTrends)

        let calendar = Calendar.current
        var forecasts: [ForecastValue] = []

        for month in 1...months {
            guard let futureDate = calendar.date(byAdding: .month, value: month, to: Date()) else { continue }

            // Predict using linear model
            let x = Double(historicalTrends.count + month)
            let predicted = max(0, slope * x + intercept)

            // Calculate confidence (decreases over time)
            let confidence = max(0.3, 1.0 - (Double(month) * 0.08))

            // Calculate bounds (±20% with decreasing confidence)
            let variance = predicted * 0.2 * (1.0 - confidence)
            let lowerBound = max(0, predicted - variance)
            let upperBound = predicted + variance

            forecasts.append(ForecastValue(
                date: futureDate,
                predictedAmount: predicted,
                confidence: confidence,
                lowerBound: lowerBound,
                upperBound: upperBound
            ))
        }

        cachedForecast = (months, forecasts)
        cacheTimestamp = Date()

        return forecasts
    }

    /// Predict next month's spending
    func predictNextMonthSpending() -> Double {
        let forecast = forecastSpending(months: 1)
        return forecast.first?.predictedAmount ?? getTotalMonthlyCost()
    }

    /// Helper: Calculate linear regression
    private func calculateLinearRegression(from trends: [DateValue]) -> (slope: Double, intercept: Double) {
        let n = Double(trends.count)
        var sumX = 0.0
        var sumY = 0.0
        var sumXY = 0.0
        var sumXX = 0.0

        for (index, trend) in trends.enumerated() {
            let x = Double(index)
            let y = trend.amount
            sumX += x
            sumY += y
            sumXY += x * y
            sumXX += x * x
        }

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        return (slope, intercept)
    }

    /// Helper: Generate flat forecast
    private func generateFlatForecast(months: Int, amount: Double) -> [ForecastValue] {
        let calendar = Calendar.current
        var forecasts: [ForecastValue] = []

        for month in 1...months {
            guard let futureDate = calendar.date(byAdding: .month, value: month, to: Date()) else { continue }

            forecasts.append(ForecastValue(
                date: futureDate,
                predictedAmount: amount,
                confidence: 0.5,
                lowerBound: amount * 0.9,
                upperBound: amount * 1.1
            ))
        }

        return forecasts
    }

    // MARK: - AGENT 14: Detection Algorithms

    /// Detect unused subscriptions based on usage threshold
    /// Threshold: Number of days without usage
    func detectUnusedSubscriptions(threshold: Int = 30) -> [Subscription] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -threshold, to: Date()) ?? Date()

        return dataManager.subscriptions.filter { subscription in
            guard subscription.isActive else { return false }

            // Check last used date
            if let lastUsed = subscription.lastUsedDate {
                return lastUsed < cutoffDate
            }

            // If never used and created more than threshold days ago
            return subscription.createdDate < cutoffDate && subscription.usageCount == 0
        }
    }

    /// Detect price increases within specified days
    func detectPriceIncreases(within days: Int = 30) -> [Subscription] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return dataManager.subscriptions.filter { subscription in
            guard subscription.isActive else { return false }
            guard let lastPriceChange = subscription.lastPriceChange else { return false }

            return lastPriceChange >= cutoffDate
        }
    }

    /// Detect trials ending soon within specified days
    func detectTrialsEndingSoon(within days: Int = 7) -> [Subscription] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        return dataManager.subscriptions.filter { subscription in
            guard subscription.isActive, subscription.isFreeTrial else { return false }
            guard let trialEndDate = subscription.trialEndDate else { return false }

            return trialEndDate <= futureDate && trialEndDate >= Date()
        }
    }

    // MARK: - AGENT 6 + AGENT 14: Savings Opportunities

    /// Generate comprehensive savings opportunities
    func generateSavingsOpportunities() -> [SavingsSuggestion] {
        var suggestions: [SavingsSuggestion] = []

        // Unused subscriptions
        let unused = detectUnusedSubscriptions(threshold: 60)
        for subscription in unused {
            let annualSavings = subscription.monthlyEquivalent * 12
            suggestions.append(SavingsSuggestion(
                type: .unused,
                subscription: subscription,
                potentialSavings: annualSavings,
                description: "You haven't used this subscription in 60 days. Consider cancelling to save \(annualSavings.asCurrency)/year.",
                priority: annualSavings > 100 ? .high : .medium
            ))
        }

        // Annual conversion opportunities
        let annualOpportunities = suggestAnnualConversions()
        for opportunity in annualOpportunities {
            suggestions.append(SavingsSuggestion(
                type: .annualConversion,
                subscription: opportunity.subscription,
                potentialSavings: opportunity.annualSavings,
                description: "Switch to annual billing and save \(opportunity.annualSavings.asCurrency)/year (\(opportunity.monthlySavings.asCurrency)/month).",
                priority: opportunity.annualSavings > 50 ? .high : .medium
            ))
        }

        // Price increases
        let priceIncreases = detectPriceIncreases(within: 30)
        for subscription in priceIncreases {
            suggestions.append(SavingsSuggestion(
                type: .priceIncrease,
                subscription: subscription,
                potentialSavings: 0,
                description: "Price recently increased. Review if you still need this subscription.",
                priority: .medium
            ))
        }

        // Trials ending soon
        let trialsEnding = detectTrialsEndingSoon(within: 7)
        for subscription in trialsEnding {
            let cost = subscription.priceAfterTrial ?? subscription.price
            suggestions.append(SavingsSuggestion(
                type: .trialEnding,
                subscription: subscription,
                potentialSavings: cost * 12,
                description: "Trial ends soon. Cancel before \(subscription.trialEndDate?.formatted() ?? "trial end") to avoid charges.",
                priority: .urgent
            ))
        }

        return suggestions.sorted { $0.potentialSavings > $1.potentialSavings }
    }

    /// Suggest subscriptions for cancellation
    func suggestCancellations() -> [Subscription] {
        let unused = detectUnusedSubscriptions(threshold: 90)
        let trialsEnding = detectTrialsEndingSoon(within: 3)

        var candidates = Set<UUID>()
        unused.forEach { candidates.insert($0.id) }
        trialsEnding.forEach { candidates.insert($0.id) }

        return dataManager.subscriptions.filter { candidates.contains($0.id) }
    }

    /// Suggest annual conversions with savings calculations
    /// Assumes typical 16% discount for annual plans (2 months free)
    func suggestAnnualConversions() -> [AnnualSuggestion] {
        let monthlySubscriptions = dataManager.subscriptions.filter {
            $0.isActive && $0.billingCycle == .monthly && $0.price >= 5.0
        }

        return monthlySubscriptions.map { subscription in
            let currentMonthlyCost = subscription.price
            let annualCost = currentMonthlyCost * 10 // Typical: 10 months price for 12 months service

            return AnnualSuggestion(
                subscription: subscription,
                currentMonthlyCost: currentMonthlyCost,
                annualCost: annualCost
            )
        }.filter { $0.annualSavings > 10 } // Only suggest if saving at least $10/year
         .sorted { $0.annualSavings > $1.annualSavings }
    }

    // MARK: - AGENT 6 + AGENT 14: Statistics

    /// Get comprehensive subscription statistics (Agent 14 format)
    func getSubscriptionStatistics() -> SubscriptionStatistics {
        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        let inactiveSubscriptions = dataManager.subscriptions.filter { !$0.isActive }

        let categoryBreakdown = calculateCategoryBreakdown()
        let mostExpensiveCategory = categoryBreakdown.first?.category.rawValue ?? "None"

        let renewals7 = dataManager.subscriptions.filter { subscription in
            guard subscription.isActive else { return false }
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
            return daysUntil <= 7 && daysUntil >= 0
        }.count

        let renewals30 = dataManager.subscriptions.filter { subscription in
            guard subscription.isActive else { return false }
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
            return daysUntil <= 30 && daysUntil >= 0
        }.count

        let freeTrials = dataManager.subscriptions.filter { $0.isActive && $0.isFreeTrial }.count
        let trialsEnding = detectTrialsEndingSoon(within: 7).count

        return SubscriptionStatistics(
            totalActive: activeSubscriptions.count,
            totalInactive: inactiveSubscriptions.count,
            totalMonthlyCost: getTotalMonthlyCost(),
            totalAnnualCost: getTotalMonthlyCost() * 12,
            mostExpensiveCategory: mostExpensiveCategory,
            averageCostPerSubscription: getAverageCostPerSubscription(),
            upcomingRenewals7Days: renewals7,
            upcomingRenewals30Days: renewals30,
            freeTrials: freeTrials,
            trialsEndingSoon: trialsEnding
        )
    }

    /// Get comprehensive subscription statistics (Agent 6 format with detailed rankings)
    func getSubscriptionStatisticsData() -> SubscriptionStatisticsData {
        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }

        // Calculate totals
        let totalMonthly = activeSubscriptions.reduce(0.0) { $0 + $1.monthlyEquivalent }
        let totalYearly = totalMonthly * 12
        let averageCost = activeSubscriptions.isEmpty ? 0 : totalMonthly / Double(activeSubscriptions.count)

        // Get rankings
        let mostExpensive = getMostExpensiveSubscriptions(limit: 5)
        let leastUsed = getLeastUsedSubscriptions(limit: 5)
        let recentlyAdded = getRecentlyAddedSubscriptions(limit: 5)
        let trialsEnding = getTrialsEndingSoon(within: 7)

        return SubscriptionStatisticsData(
            totalActive: activeSubscriptions.count,
            totalMonthly: totalMonthly,
            totalYearly: totalYearly,
            averageCost: averageCost,
            mostExpensive: convertToAnalytics(mostExpensive),
            leastUsed: convertToAnalytics(leastUsed),
            recentlyAdded: convertToAnalytics(recentlyAdded),
            trialsEnding: convertToAnalytics(trialsEnding)
        )
    }

    /// Get spending statistics with trend analysis
    func getSpendingStatistics() -> SpendingStatistics {
        let currentMonth = getTotalMonthlyCost()
        let monthlyAverage = calculateMonthlyAverage()

        // Calculate last month (simplified - uses current active subscriptions)
        let lastMonth = currentMonth // Could be enhanced with historical data

        let yearlyTotal = currentMonth * 12
        let percentageChange = lastMonth > 0 ? ((currentMonth - lastMonth) / lastMonth) * 100 : 0

        // Determine trend
        let trend: SpendingTrend
        if abs(percentageChange) < 5 {
            trend = .stable
        } else if percentageChange > 0 {
            trend = .increasing
        } else {
            trend = .decreasing
        }

        return SpendingStatistics(
            currentMonth: currentMonth,
            lastMonth: lastMonth,
            monthlyAverage: monthlyAverage,
            yearlyTotal: yearlyTotal,
            percentageChange: percentageChange,
            trend: trend
        )
    }

    /// AGENT 6: Get trend analysis for current spending
    func getTrendAnalysis(for dateRange: DateRange) -> TrendAnalysis {
        let data = calculateSpendingTrends(for: dateRange)

        guard data.count >= 2 else {
            return TrendAnalysis(slope: 0, percentageChange: 0, isIncreasing: false, prediction: 0)
        }

        let (slope, intercept) = calculateLinearRegressionFromDataPoints(data: data)

        // Calculate percentage change from first to last
        let firstAmount = data.first?.amount ?? 0
        let lastAmount = data.last?.amount ?? 0
        let percentageChange = firstAmount > 0 ? ((lastAmount - firstAmount) / firstAmount) * 100 : 0

        // Predict next period
        let prediction = slope * Double(data.count + 1) + intercept

        return TrendAnalysis(
            slope: slope,
            percentageChange: percentageChange,
            isIncreasing: slope > 0,
            prediction: max(0, prediction)
        )
    }

    // MARK: - Private Helper Methods

    private func determineBucketSize(for dateRange: DateRange) -> (component: Calendar.Component, days: Int) {
        switch dateRange {
        case .week:
            return (.day, 1)
        case .month:
            return (.day, 1)
        case .quarter:
            return (.weekOfYear, 7)
        case .year:
            return (.month, 30)
        case .custom:
            return (.weekOfYear, 7)
        }
    }

    private func bucketDate(for date: Date, bucketSize: (component: Calendar.Component, days: Int)) -> Date {
        let calendar = Calendar.current

        switch bucketSize.component {
        case .day:
            return calendar.startOfDay(for: date)
        case .weekOfYear:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        default:
            return date
        }
    }

    private func calculateLinearRegressionFromDataPoints(data: [SpendingDataPoint]) -> (slope: Double, intercept: Double) {
        let n = Double(data.count)
        guard n > 0 else { return (0, 0) }

        var sumX = 0.0
        var sumY = 0.0
        var sumXY = 0.0
        var sumX2 = 0.0

        for (index, point) in data.enumerated() {
            let x = Double(index)
            let y = point.amount
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }

        let denominator = (n * sumX2 - sumX * sumX)
        guard denominator != 0 else { return (0, sumY / n) }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        return (slope, intercept)
    }

    private func calculateCategoryGrowth(
        thisYearTransactions: [Transaction],
        lastYearTransactions: [Transaction]
    ) -> (growing: [CategoryGrowth], declining: [CategoryGrowth]) {
        var thisYearByCategory: [String: Double] = [:]
        var lastYearByCategory: [String: Double] = [:]

        // Group this year
        for transaction in thisYearTransactions {
            let category = transaction.category.rawValue
            thisYearByCategory[category, default: 0] += abs(transaction.amount)
        }

        // Group last year
        for transaction in lastYearTransactions {
            let category = transaction.category.rawValue
            lastYearByCategory[category, default: 0] += abs(transaction.amount)
        }

        // Calculate growth
        var allGrowth: [CategoryGrowth] = []
        let allCategories = Set(thisYearByCategory.keys).union(Set(lastYearByCategory.keys))

        for category in allCategories {
            let thisYear = thisYearByCategory[category] ?? 0
            let lastYear = lastYearByCategory[category] ?? 0
            let change = lastYear > 0 ? ((thisYear - lastYear) / lastYear) * 100 : 0

            let transactionCategory = TransactionCategory.allCases.first { $0.rawValue == category } ?? .other

            allGrowth.append(CategoryGrowth(
                category: category,
                thisYear: thisYear,
                lastYear: lastYear,
                percentageChange: change,
                color: transactionCategory.color
            ))
        }

        // Sort and split
        let sorted = allGrowth.sorted { $0.percentageChange > $1.percentageChange }
        let growing = Array(sorted.filter { $0.percentageChange > 5 }.prefix(5))
        let declining = Array(sorted.filter { $0.percentageChange < -5 }.suffix(5))

        return (growing, declining)
    }

    private func createEmptyYoYComparison() -> YearOverYearComparison {
        return YearOverYearComparison(
            thisYearTotal: 0,
            lastYearTotal: 0,
            percentageChange: 0,
            thisYearMonthlyAverage: 0,
            lastYearMonthlyAverage: 0,
            thisYearSubscriptionCount: 0,
            lastYearSubscriptionCount: 0,
            growingCategories: [],
            decliningCategories: []
        )
    }

    private func convertToAnalytics(_ subscriptions: [Subscription]) -> [SubscriptionAnalytics] {
        return subscriptions.map { subscription in
            SubscriptionAnalytics(
                id: subscription.id,
                name: subscription.name,
                monthlyAmount: subscription.monthlyEquivalent,
                yearlyAmount: subscription.monthlyEquivalent * 12,
                billingCycle: subscription.billingCycle.rawValue,
                category: subscription.category.rawValue,
                icon: subscription.icon,
                color: subscription.color,
                usageCount: subscription.usageCount,
                lastUsedDate: subscription.lastUsedDate,
                createdDate: subscription.createdDate,
                isFreeTrial: subscription.isFreeTrial,
                trialEndDate: subscription.trialEndDate
            )
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - AGENT 6: Sample Data Generator

extension AnalyticsService {
    /// Generate sample spending data for demonstration
    func generateSampleData(months: Int = 12) -> [SpendingDataPoint] {
        var dataPoints: [SpendingDataPoint] = []
        let calendar = Calendar.current

        for month in 0..<months {
            let date = calendar.date(byAdding: .month, value: -months + month, to: Date()) ?? Date()

            // Generate realistic variation
            let baseAmount = 1500.0
            let variation = Double.random(in: -300...500)
            let subscriptionsAmount = 800.0 + Double.random(in: -100...200)
            let transactionsAmount = baseAmount + variation - subscriptionsAmount

            let isSignificant = variation > 300

            dataPoints.append(SpendingDataPoint(
                date: date,
                amount: subscriptionsAmount + transactionsAmount,
                subscriptionsAmount: subscriptionsAmount,
                transactionsAmount: transactionsAmount,
                isSignificant: isSignificant,
                annotation: isSignificant ? "High spending month" : nil
            ))
        }

        return dataPoints
    }
}
