//
//  WidgetModels.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Data models for widget communication
//

import Foundation

// MARK: - Widget Subscription Model

struct WidgetSubscription: Codable, Identifiable {
    let id: UUID
    let name: String
    let price: Double
    let billingCycle: String // "monthly", "annually", etc.
    let category: String
    let icon: String // SF Symbol name
    let color: String // Hex color code
    let nextBillingDate: Date
    let isActive: Bool

    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextBillingDate)
        return max(0, components.day ?? 0)
    }

    var renewalText: String {
        let days = daysUntilRenewal
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "In \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return "In \(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            return "In \(days) days"
        }
    }

    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }
}

// MARK: - Widget Monthly Spending Model

struct WidgetMonthlySpending: Codable {
    let currentMonth: Double
    let lastMonth: Double
    let monthlyData: [MonthlyData] // Last 12 months
    let topCategories: [CategorySpending]

    var percentageChange: Double {
        guard lastMonth > 0 else { return 0 }
        return ((currentMonth - lastMonth) / lastMonth) * 100
    }

    var trendIcon: String {
        if percentageChange > 5 {
            return "arrow.up.right"
        } else if percentageChange < -5 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }

    var trendColor: String {
        if percentageChange > 5 {
            return "#FF3B30" // Red for increase
        } else if percentageChange < -5 {
            return "#34C759" // Green for decrease
        } else {
            return "#8E8E93" // Gray for neutral
        }
    }

    var formattedCurrentMonth: String {
        return String(format: "$%.2f", currentMonth)
    }

    var formattedPercentageChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percentageChange)
    }
}

struct MonthlyData: Codable, Identifiable {
    let id = UUID()
    let month: String // "Jan", "Feb", etc.
    let amount: Double
    let date: Date

    enum CodingKeys: String, CodingKey {
        case month, amount, date
    }
}

struct CategorySpending: Codable, Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let icon: String
    let color: String

    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }

    var formattedPercentage: String {
        return String(format: "%.0f%%", percentage)
    }

    enum CodingKeys: String, CodingKey {
        case category, amount, percentage, icon, color
    }
}

// MARK: - Widget Quick Action Model

struct WidgetQuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: String
    let deepLink: String
}
