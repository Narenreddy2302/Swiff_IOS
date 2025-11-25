//
//  WidgetConfiguration.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Configuration for widget extension
//

import Foundation

enum WidgetConfiguration {
    // App Group identifier for data sharing
    // IMPORTANT: Enable this in both main app and widget extension capabilities
    static let appGroupIdentifier = "group.com.yourcompany.swiff"

    // Widget kinds
    static let upcomingRenewalsWidgetKind = "UpcomingRenewalsWidget"
    static let monthlySpendingWidgetKind = "MonthlySpendingWidget"
    static let quickActionsWidgetKind = "QuickActionsWidget"

    // Deep link URLs
    static let deepLinkScheme = "swiff"
    static let addTransactionAction = "add-transaction"
    static let addSubscriptionAction = "add-subscription"
    static let viewSubscriptionsAction = "view-subscriptions"
    static let viewAnalyticsAction = "view-analytics"

    static func deepLinkURL(for action: String) -> URL? {
        return URL(string: "\(deepLinkScheme)://action/\(action)")
    }

    // Widget refresh intervals
    static let refreshInterval: TimeInterval = 3600 // 1 hour
    static let midnightRefreshEnabled = true
}
