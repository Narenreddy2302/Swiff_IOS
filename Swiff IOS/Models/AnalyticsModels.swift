//
//  AnalyticsModels.swift
//  Swiff IOS
//
//  Created by Agent 14 on 11/21/25.
//  Analytics data models and supporting types for AnalyticsService and ChartDataService
//

import Foundation
import SwiftUI
import Combine
import Charts

// MARK: - Date Range

/// Date range for analytics queries
enum DateRange: Hashable {
    case week
    case month
    case quarter
    case year
    case custom(start: Date, end: Date)

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .custom(let start, _):
            return start
        }
    }

    var endDate: Date {
        switch self {
        case .custom(_, let end):
            return end
        default:
            return Date()
        }
    }

    var displayName: String {
        switch self {
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .quarter: return "Last 90 Days"
        case .year: return "Last Year"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

// MARK: - Analytics Data Models

/// Date-value pair for trend data
struct DateValue: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Double

    init(date: Date, amount: Double) {
        self.id = UUID()
        self.date = date
        self.amount = amount
    }
}

/// Category spending breakdown
struct CategorySpending: Identifiable, Codable {
    let id: UUID
    let category: SubscriptionCategory
    let totalAmount: Double
    let percentage: Double
    let count: Int

    // AGENT 6: Backward compatibility with string-based category
    var categoryString: String { category.rawValue }
    var amount: Double { totalAmount }
    var color: Color { category.color }
    var icon: String { category.icon }

    init(category: SubscriptionCategory, totalAmount: Double, percentage: Double, count: Int) {
        self.id = UUID()
        self.category = category
        self.totalAmount = totalAmount
        self.percentage = percentage
        self.count = count
    }

    // AGENT 6: String-based initializer
    init(category: String, amount: Double, count: Int, percentage: Double, color: Color, icon: String) {
        self.id = UUID()
        self.category = SubscriptionCategory.allCases.first { $0.rawValue == category } ?? .other
        self.totalAmount = amount
        self.percentage = percentage
        self.count = count
    }
}

/// Forecast value with confidence interval
struct ForecastValue: Identifiable, Codable {
    let id: UUID
    let date: Date
    let predictedAmount: Double
    let confidence: Double // 0.0 to 1.0
    let lowerBound: Double
    let upperBound: Double

    // AGENT 6: Backward compatibility properties
    var confidenceLow: Double { lowerBound }
    var confidenceHigh: Double { upperBound }

    init(date: Date, predictedAmount: Double, confidence: Double, lowerBound: Double, upperBound: Double) {
        self.id = UUID()
        self.date = date
        self.predictedAmount = predictedAmount
        self.confidence = confidence
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    // AGENT 6: Alternative initializer
    init(date: Date, predictedAmount: Double, confidenceLow: Double, confidenceHigh: Double) {
        self.id = UUID()
        self.date = date
        self.predictedAmount = predictedAmount
        self.lowerBound = confidenceLow
        self.upperBound = confidenceHigh
        // Calculate confidence based on variance
        let variance = (confidenceHigh - confidenceLow) / predictedAmount
        self.confidence = max(0.3, 1.0 - variance)
    }
}

/// Savings suggestion types
enum SuggestionType: String, Codable {
    case unused = "Unused Subscription"
    case annualConversion = "Switch to Annual"
    case priceIncrease = "Price Increase Detected"
    case alternative = "Alternative Available"
    case trialEnding = "Trial Ending Soon"

    // AGENT 6: Backward compatibility aliases (use computed static vars instead of duplicate cases)
    static var unusedSubscription: SuggestionType { .unused }
    static var switchToAnnual: SuggestionType { .annualConversion }
}

/// Savings suggestion
struct SavingsSuggestion: Identifiable, Codable {
    let id: UUID
    let type: SuggestionType
    let subscription: Subscription
    let potentialSavings: Double
    let description: String
    let priority: SuggestionPriority

    // AGENT 6: Backward compatibility properties
    var title: String { type.rawValue }
    var subscriptionId: UUID { subscription.id }

    init(type: SuggestionType, subscription: Subscription, potentialSavings: Double, description: String, priority: SuggestionPriority = .medium) {
        self.id = UUID()
        self.type = type
        self.subscription = subscription
        self.potentialSavings = potentialSavings
        self.description = description
        self.priority = priority
    }

    // AGENT 6: Alternative initializer
    init(type: SuggestionType, title: String, description: String, potentialSavings: Double, subscriptionId: UUID, priority: SuggestionPriority) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.potentialSavings = potentialSavings
        self.priority = priority
        // Note: Need to look up subscription from DataManager
        // For now, create a placeholder - this should be fixed in service layer
        var placeholderSub = Subscription(
            name: title,
            description: description,
            price: potentialSavings / 12,
            billingCycle: .monthly,
            category: .other
        )
        placeholderSub.id = subscriptionId
        self.subscription = placeholderSub
    }
}

/// Suggestion priority
enum SuggestionPriority: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

/// Annual conversion suggestion
struct AnnualSuggestion: Identifiable, Codable {
    let id: UUID
    let subscription: Subscription
    let currentMonthlyCost: Double
    let annualCost: Double
    let monthlySavings: Double
    let annualSavings: Double
    let breakEvenMonths: Int

    init(subscription: Subscription, currentMonthlyCost: Double, annualCost: Double) {
        self.id = UUID()
        self.subscription = subscription
        self.currentMonthlyCost = currentMonthlyCost
        self.annualCost = annualCost
        self.monthlySavings = (currentMonthlyCost * 12 - annualCost) / 12
        self.annualSavings = currentMonthlyCost * 12 - annualCost
        // Calculate break-even months (typical annual plans save 2 months)
        self.breakEvenMonths = Int(ceil(annualCost / currentMonthlyCost))
    }
}

// MARK: - Chart Data Models

/// Trend data point for line charts
struct TrendDataPoint: Identifiable, Codable, Plottable {
    let id: UUID
    let date: Date
    let amount: Double
    let label: String?

    init(date: Date, amount: Double, label: String? = nil) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.label = label
    }
    
    // Plottable conformance
    var primitivePlottable: Date {
        date
    }
    
    init?(primitivePlottable: Date) {
        self.id = UUID()
        self.date = primitivePlottable
        self.amount = 0
        self.label = nil
    }
}

/// Price data point for price history charts
struct PriceDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let price: Double
    let note: String?
    let isIncrease: Bool
    let changePercentage: Double?
    let previousPrice: Double?

    init(date: Date, price: Double, note: String? = nil, isIncrease: Bool = false, changePercentage: Double? = nil, previousPrice: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.price = price
        self.note = note
        self.isIncrease = isIncrease
        self.changePercentage = changePercentage
        self.previousPrice = previousPrice
    }
}

/// Monthly payment data for payment history charts
struct MonthlyData: Identifiable, Codable {
    let id: UUID
    let month: Date
    let monthLabel: String
    let totalPaid: Double
    let totalReceived: Double

    var netBalance: Double {
        totalReceived - totalPaid
    }

    init(id: UUID = UUID(), month: Date, monthLabel: String, totalPaid: Double, totalReceived: Double) {
        self.id = id
        self.month = month
        self.monthLabel = monthLabel
        self.totalPaid = totalPaid
        self.totalReceived = totalReceived
    }
}

/// Category data for bar charts
struct CategoryData: Identifiable, Codable, Plottable {
    let id: UUID
    let category: String
    let amount: Double
    let color: String // Hex color
    let count: Int

    init(category: String, amount: Double, color: String, count: Int) {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.color = color
        self.count = count
    }

    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }
    
    // Plottable conformance
    var primitivePlottable: String {
        category
    }
    
    init?(primitivePlottable: String) {
        self.id = UUID()
        self.category = primitivePlottable
        self.amount = 0
        self.color = "#808080"
        self.count = 0
    }
}

/// Subscription comparison data
struct SubscriptionData: Identifiable, Codable {
    let id: UUID
    let subscription: Subscription
    let amount: Double
    let percentageOfTotal: Double

    init(subscription: Subscription, amount: Double, percentageOfTotal: Double) {
        self.id = UUID()
        self.subscription = subscription
        self.amount = amount
        self.percentageOfTotal = percentageOfTotal
    }
}

// MonthlyComparisonData removed - use MonthlyData instead
// Typealias for backward compatibility where needed
typealias MonthlyComparisonData = MonthlyData

/// Category share for pie charts
struct CategoryShare: Identifiable, Codable, Plottable {
    let id: UUID
    let category: String
    let amount: Double
    let percentage: Double
    let color: String

    init(category: String, amount: Double, percentage: Double, color: String) {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.percentage = percentage
        self.color = color
    }

    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }
    
    // Plottable conformance
    var primitivePlottable: String {
        category
    }
    
    init?(primitivePlottable: String) {
        self.id = UUID()
        self.category = primitivePlottable
        self.amount = 0
        self.percentage = 0
        self.color = "#808080"
    }
}

/// Monthly total aggregation
struct MonthlyTotal: Identifiable, Codable {
    let id: UUID
    let monthYear: String
    let date: Date
    let total: Double
    let transactionCount: Int

    init(monthYear: String, date: Date, total: Double, transactionCount: Int) {
        self.id = UUID()
        self.monthYear = monthYear
        self.date = date
        self.total = total
        self.transactionCount = transactionCount
    }
}

/// Category total aggregation
struct CategoryTotal: Identifiable, Codable {
    let id: UUID
    let category: String
    let total: Double
    let transactionCount: Int
    let averageAmount: Double

    init(category: String, total: Double, transactionCount: Int) {
        self.id = UUID()
        self.category = category
        self.total = total
        self.transactionCount = transactionCount
        self.averageAmount = transactionCount > 0 ? total / Double(transactionCount) : 0
    }
}

// MARK: - Statistics Models

/// Subscription statistics
struct SubscriptionStatistics: Codable {
    let totalActive: Int
    let totalInactive: Int
    let totalMonthlyCost: Double
    let totalAnnualCost: Double
    let mostExpensiveCategory: String
    let averageCostPerSubscription: Double
    let upcomingRenewals7Days: Int
    let upcomingRenewals30Days: Int
    let freeTrials: Int
    let trialsEndingSoon: Int
}

/// Spending statistics
struct SpendingStatistics: Codable {
    let currentMonth: Double
    let lastMonth: Double
    let monthlyAverage: Double
    let yearlyTotal: Double
    let percentageChange: Double
    let trend: SpendingTrend
}

/// Spending trend
enum SpendingTrend: String, Codable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .increasing: return .wiseError
        case .decreasing: return .wiseBrightGreen
        case .stable: return .wiseBlue
        }
    }
}

// MARK: - AGENT 6: Additional Analytics Models

/// Spending data point with separate subscription and transaction amounts
struct SpendingDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let subscriptionsAmount: Double
    let transactionsAmount: Double
    let isSignificant: Bool
    let annotation: String?

    init(date: Date, amount: Double, subscriptionsAmount: Double, transactionsAmount: Double, isSignificant: Bool, annotation: String?) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.subscriptionsAmount = subscriptionsAmount
        self.transactionsAmount = transactionsAmount
        self.isSignificant = isSignificant
        self.annotation = annotation
    }
}

/// Year-over-year comparison with detailed analytics
struct YearOverYearComparison: Codable {
    let thisYearTotal: Double
    let lastYearTotal: Double
    let percentageChange: Double
    let thisYearMonthlyAverage: Double
    let lastYearMonthlyAverage: Double
    let thisYearSubscriptionCount: Int
    let lastYearSubscriptionCount: Int
    let growingCategories: [CategoryGrowth]
    let decliningCategories: [CategoryGrowth]
}

/// Category growth analysis
struct CategoryGrowth: Identifiable, Codable {
    let id: UUID
    let category: String
    let thisYear: Double
    let lastYear: Double
    let percentageChange: Double
    let colorHex: String  // Store as hex string for Codable compliance

    var color: Color {  // Computed property for SwiftUI Color
        Color(hex: colorHex) ?? .gray
    }

    init(category: String, thisYear: Double, lastYear: Double, percentageChange: Double, color: Color) {
        self.id = UUID()
        self.category = category
        self.thisYear = thisYear
        self.lastYear = lastYear
        self.percentageChange = percentageChange
        // Extract hex from category if it's a known category, otherwise default gray
        if let transactionCat = TransactionCategory.allCases.first(where: { $0.rawValue == category }) {
            self.colorHex = transactionCat.hexColor
        } else {
            self.colorHex = "#808080"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, category, thisYear, lastYear, percentageChange, colorHex
    }
}

/// Subscription statistics data with detailed rankings
struct SubscriptionStatisticsData: Codable {
    let totalActive: Int
    let totalMonthly: Double
    let totalYearly: Double
    let averageCost: Double
    let mostExpensive: [SubscriptionAnalytics]
    let leastUsed: [SubscriptionAnalytics]
    let recentlyAdded: [SubscriptionAnalytics]
    let trialsEnding: [SubscriptionAnalytics]
}

/// Subscription analytics with usage metrics
struct SubscriptionAnalytics: Identifiable, Codable {
    let id: UUID
    let name: String
    let monthlyAmount: Double
    let yearlyAmount: Double
    let billingCycle: String
    let category: String
    let icon: String
    let colorHex: String  // Hex color string for Codable compliance
    let usageCount: Int
    let lastUsedDate: Date?
    let createdDate: Date
    let isFreeTrial: Bool
    let trialEndDate: Date?

    var color: Color {  // Computed property for SwiftUI Color
        Color(hex: colorHex) ?? .gray
    }

    init(id: UUID, name: String, monthlyAmount: Double, yearlyAmount: Double, billingCycle: String, category: String, icon: String, color: String, usageCount: Int, lastUsedDate: Date?, createdDate: Date, isFreeTrial: Bool, trialEndDate: Date?) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.yearlyAmount = yearlyAmount
        self.billingCycle = billingCycle
        self.category = category
        self.icon = icon
        self.colorHex = color  // Store as hex string
        self.usageCount = usageCount
        self.lastUsedDate = lastUsedDate
        self.createdDate = createdDate
        self.isFreeTrial = isFreeTrial
        self.trialEndDate = trialEndDate
    }
}

/// Trend analysis with predictions
struct TrendAnalysis: Codable {
    let slope: Double
    let percentageChange: Double
    let isIncreasing: Bool
    let prediction: Double
}

/// Extended savings suggestion priority (backward compatibility)
extension SuggestionPriority {
    static let urgent: SuggestionPriority = .critical
}

// MARK: - Color Extension
// Note: init(hex:) is defined in SupportingTypes.swift
