//
//  WidgetDataService.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Data service for widgets with App Groups support
//

import Foundation
import WidgetKit

// MARK: - Widget Data Models

/// Subscription data for widgets
struct WidgetSubscription: Codable, Identifiable {
    let id: UUID
    let name: String
    let price: Double
    let nextBillingDate: Date
    let icon: String
    let color: String
    let category: String
    let isActive: Bool

    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: nextBillingDate)
        return components.day ?? 0
    }

    var renewalCountdown: String {
        let days = daysUntilRenewal
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 0 {
            return "Overdue"
        } else {
            return "In \(days) days"
        }
    }

    var formattedPrice: String {
        return price.asCurrencyString
    }
}

/// Monthly spending data for widgets
struct WidgetMonthlySpending: Codable {
    let currentMonth: Double
    let previousMonth: Double
    let monthlyHistory: [MonthData] // Last 12 months
    let categoryBreakdown: [CategorySpending]
    let topCategories: [CategorySpending] // Top 3

    var percentageChange: Double {
        guard previousMonth > 0 else { return 0 }
        return ((currentMonth - previousMonth) / previousMonth) * 100
    }

    var trendDirection: TrendDirection {
        if percentageChange > 5 {
            return .up
        } else if percentageChange < -5 {
            return .down
        } else {
            return .stable
        }
    }

    var formattedCurrentMonth: String {
        return currentMonth.asCurrencyString
    }

    var formattedPercentageChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percentageChange)
    }

    struct MonthData: Codable {
        let month: String
        let amount: Double
    }

    struct CategorySpending: Codable, Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
        let percentage: Double

        var formattedAmount: String {
            return amount.asCurrencyString
        }

        var formattedPercentage: String {
            return String(format: "%.0f%%", percentage)
        }
    }

    enum TrendDirection: String, Codable {
        case up = "↑"
        case down = "↓"
        case stable = "→"

        var color: String {
            switch self {
            case .up: return "#E74C3C" // Red
            case .down: return "#2ECC71" // Green
            case .stable: return "#95A5A6" // Gray
            }
        }
    }
}

// MARK: - Widget Data Service

/// Service for reading and writing widget data using App Groups
class WidgetDataService {
    static let shared = WidgetDataService()

    private let appGroupIdentifier = WidgetConfiguration.appGroupIdentifier
    private let userDefaults: UserDefaults?

    // Storage keys
    private let upcomingRenewalsKey = "widget.upcomingRenewals"
    private let monthlySpendingKey = "widget.monthlySpending"
    private let lastUpdateKey = "widget.lastUpdate"

    private init() {
        // MOCK: In a real implementation, this would use the actual App Group
        // For now, we'll use standard UserDefaults
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)

        // If App Group is not available, fallback to standard UserDefaults
        if self.userDefaults == nil {
            print("⚠️ App Group not available. Using standard UserDefaults for widget data.")
            // In production, this would be: UserDefaults(suiteName: appGroupIdentifier)
        }
    }

    // MARK: - Upcoming Renewals

    /// Save upcoming renewals to shared storage
    func saveUpcomingRenewals(_ subscriptions: [WidgetSubscription]) {
        guard let data = try? JSONEncoder().encode(subscriptions) else {
            print("❌ Failed to encode upcoming renewals")
            return
        }

        let storage = userDefaults ?? UserDefaults.standard
        storage.set(data, forKey: upcomingRenewalsKey)
        storage.set(Date(), forKey: lastUpdateKey)
        print("✅ Saved \(subscriptions.count) upcoming renewals to widget storage")
    }

    /// Load upcoming renewals from shared storage
    func loadUpcomingRenewals() -> [WidgetSubscription] {
        let storage = userDefaults ?? UserDefaults.standard

        guard let data = storage.data(forKey: upcomingRenewalsKey),
              let subscriptions = try? JSONDecoder().decode([WidgetSubscription].self, from: data) else {
            print("⚠️ No upcoming renewals found in widget storage. Using mock data.")
            return mockUpcomingRenewals()
        }

        return subscriptions
    }

    // MARK: - Monthly Spending

    /// Save monthly spending to shared storage
    func saveMonthlySpending(_ spending: WidgetMonthlySpending) {
        guard let data = try? JSONEncoder().encode(spending) else {
            print("❌ Failed to encode monthly spending")
            return
        }

        let storage = userDefaults ?? UserDefaults.standard
        storage.set(data, forKey: monthlySpendingKey)
        storage.set(Date(), forKey: lastUpdateKey)
        print("✅ Saved monthly spending to widget storage")
    }

    /// Load monthly spending from shared storage
    func loadMonthlySpending() -> WidgetMonthlySpending {
        let storage = userDefaults ?? UserDefaults.standard

        guard let data = storage.data(forKey: monthlySpendingKey),
              let spending = try? JSONDecoder().decode(WidgetMonthlySpending.self, from: data) else {
            print("⚠️ No monthly spending found in widget storage. Using mock data.")
            return mockMonthlySpending()
        }

        return spending
    }

    // MARK: - Last Update

    func getLastUpdateTime() -> Date? {
        let storage = userDefaults ?? UserDefaults.standard
        return storage.object(forKey: lastUpdateKey) as? Date
    }

    // MARK: - Widget Reload

    /// Trigger widget reload (call from main app when data changes)
    static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ All widgets reloaded")
    }

    static func reloadWidget(_ kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        print("✅ Widget '\(kind)' reloaded")
    }

    // MARK: - Mock Data

    /// Mock upcoming renewals for testing
    private func mockUpcomingRenewals() -> [WidgetSubscription] {
        let calendar = Calendar.current

        return [
            WidgetSubscription(
                id: UUID(),
                name: "Netflix",
                price: 15.99,
                nextBillingDate: calendar.date(byAdding: .day, value: 2, to: Date())!,
                icon: "tv.fill",
                color: "#E50914",
                category: "Entertainment",
                isActive: true
            ),
            WidgetSubscription(
                id: UUID(),
                name: "Spotify",
                price: 9.99,
                nextBillingDate: calendar.date(byAdding: .day, value: 5, to: Date())!,
                icon: "music.note",
                color: "#1DB954",
                category: "Entertainment",
                isActive: true
            ),
            WidgetSubscription(
                id: UUID(),
                name: "Apple iCloud",
                price: 2.99,
                nextBillingDate: calendar.date(byAdding: .day, value: 7, to: Date())!,
                icon: "icloud.fill",
                color: "#007AFF",
                category: "Utilities",
                isActive: true
            ),
            WidgetSubscription(
                id: UUID(),
                name: "Adobe Creative Cloud",
                price: 54.99,
                nextBillingDate: calendar.date(byAdding: .day, value: 12, to: Date())!,
                icon: "paintbrush.fill",
                color: "#FF0000",
                category: "Productivity",
                isActive: true
            ),
            WidgetSubscription(
                id: UUID(),
                name: "Amazon Prime",
                price: 14.99,
                nextBillingDate: calendar.date(byAdding: .day, value: 15, to: Date())!,
                icon: "shippingbox.fill",
                color: "#FF9900",
                category: "Shopping",
                isActive: true
            ),
            WidgetSubscription(
                id: UUID(),
                name: "Notion",
                price: 8.00,
                nextBillingDate: calendar.date(byAdding: .day, value: 18, to: Date())!,
                icon: "doc.text.fill",
                color: "#000000",
                category: "Productivity",
                isActive: true
            ),
            WidgetSubscription(
                id: UUID(),
                name: "Disney+",
                price: 7.99,
                nextBillingDate: calendar.date(byAdding: .day, value: 20, to: Date())!,
                icon: "sparkles.tv.fill",
                color: "#113CCF",
                category: "Entertainment",
                isActive: true
            )
        ]
    }

    /// Mock monthly spending for testing
    private func mockMonthlySpending() -> WidgetMonthlySpending {
        let monthlyHistory = [
            WidgetMonthlySpending.MonthData(month: "Jan", amount: 245.50),
            WidgetMonthlySpending.MonthData(month: "Feb", amount: 267.80),
            WidgetMonthlySpending.MonthData(month: "Mar", amount: 289.20),
            WidgetMonthlySpending.MonthData(month: "Apr", amount: 256.40),
            WidgetMonthlySpending.MonthData(month: "May", amount: 278.90),
            WidgetMonthlySpending.MonthData(month: "Jun", amount: 302.15),
            WidgetMonthlySpending.MonthData(month: "Jul", amount: 295.60),
            WidgetMonthlySpending.MonthData(month: "Aug", amount: 312.45),
            WidgetMonthlySpending.MonthData(month: "Sep", amount: 298.70),
            WidgetMonthlySpending.MonthData(month: "Oct", amount: 325.80),
            WidgetMonthlySpending.MonthData(month: "Nov", amount: 342.50),
            WidgetMonthlySpending.MonthData(month: "Dec", amount: 358.90)
        ]

        let categoryBreakdown = [
            WidgetMonthlySpending.CategorySpending(category: "Entertainment", amount: 125.50, percentage: 35),
            WidgetMonthlySpending.CategorySpending(category: "Productivity", amount: 89.20, percentage: 25),
            WidgetMonthlySpending.CategorySpending(category: "Utilities", amount: 67.80, percentage: 19),
            WidgetMonthlySpending.CategorySpending(category: "Shopping", amount: 45.60, percentage: 13),
            WidgetMonthlySpending.CategorySpending(category: "Health", amount: 30.80, percentage: 8)
        ]

        return WidgetMonthlySpending(
            currentMonth: 358.90,
            previousMonth: 342.50,
            monthlyHistory: monthlyHistory,
            categoryBreakdown: categoryBreakdown,
            topCategories: Array(categoryBreakdown.prefix(3))
        )
    }
}
