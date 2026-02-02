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

// MARK: - Widget Data Service

/// Service for reading and writing widget data using App Groups
class WidgetDataService {
    static let shared = WidgetDataService()

    private let appGroupIdentifier = WidgetConfiguration.appGroupIdentifier
    private let userDefaults: UserDefaults?

    // Storage keys
    private let upcomingRenewalsKey = "widget.upcomingRenewals"
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

}
