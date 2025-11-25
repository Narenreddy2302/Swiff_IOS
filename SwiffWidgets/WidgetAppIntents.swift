//
//  WidgetAppIntents.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  App Intents for iOS 17+ interactive widgets
//

import Foundation
import AppIntents
import WidgetKit

// MARK: - Add Transaction Intent

@available(iOS 17.0, *)
struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Transaction"
    static var description = IntentDescription("Quickly add a new transaction")

    @MainActor
    func perform() async throws -> some IntentResult {
        // MOCK: In production, this would interact with the data layer
        print("📱 App Intent: Add Transaction triggered")

        // Open the app with deep link
        if let url = WidgetConfiguration.deepLinkURL(for: WidgetConfiguration.addTransactionAction) {
            // This would typically open the app
            print("Opening URL: \(url)")
        }

        return .result()
    }
}

// MARK: - Add Subscription Intent

@available(iOS 17.0, *)
struct AddSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Subscription"
    static var description = IntentDescription("Quickly add a new subscription")

    @MainActor
    func perform() async throws -> some IntentResult {
        print("📱 App Intent: Add Subscription triggered")

        if let url = WidgetConfiguration.deepLinkURL(for: WidgetConfiguration.addSubscriptionAction) {
            print("Opening URL: \(url)")
        }

        return .result()
    }
}

// MARK: - View Subscriptions Intent

@available(iOS 17.0, *)
struct ViewSubscriptionsIntent: AppIntent {
    static var title: LocalizedStringResource = "View Subscriptions"
    static var description = IntentDescription("Open subscriptions list")

    @MainActor
    func perform() async throws -> some IntentResult {
        print("📱 App Intent: View Subscriptions triggered")

        if let url = WidgetConfiguration.deepLinkURL(for: WidgetConfiguration.viewSubscriptionsAction) {
            print("Opening URL: \(url)")
        }

        return .result()
    }
}

// MARK: - Mark as Paid Intent

@available(iOS 17.0, *)
struct MarkAsPaidIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark as Paid"
    static var description = IntentDescription("Mark a subscription as paid")

    @Parameter(title: "Subscription ID")
    var subscriptionId: String

    init() {
        self.subscriptionId = ""
    }

    init(subscriptionId: String) {
        self.subscriptionId = subscriptionId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        print("📱 App Intent: Mark as Paid for subscription \(subscriptionId)")

        // MOCK: In production, this would:
        // 1. Find the subscription by ID
        // 2. Update its status to paid
        // 3. Update the next billing date
        // 4. Save to persistent storage
        // 5. Reload widgets

        // Simulate marking as paid
        // DataManager.shared.markSubscriptionAsPaid(id: UUID(uuidString: subscriptionId))

        // Reload widgets to reflect changes
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

// MARK: - Refresh Widget Intent

@available(iOS 17.0, *)
struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    static var description = IntentDescription("Manually refresh widget data")

    @MainActor
    func perform() async throws -> some IntentResult {
        print("📱 App Intent: Refresh Widget triggered")

        // Reload all widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

// MARK: - Widget Configuration Intent (for customization)

@available(iOS 17.0, *)
struct WidgetConfigurationIntent: AppIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description = IntentDescription("Customize widget appearance and data")

    @Parameter(title: "Show Categories")
    var showCategories: Bool?

    @Parameter(title: "Sort Order")
    var sortOrder: SortOrder?

    init() {}

    init(showCategories: Bool?, sortOrder: SortOrder?) {
        self.showCategories = showCategories
        self.sortOrder = sortOrder
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        print("📱 App Intent: Widget Configuration")
        print("  Show Categories: \(showCategories ?? false)")
        print("  Sort Order: \(sortOrder?.rawValue ?? "default")")

        // Save configuration to UserDefaults
        if let showCategories = showCategories {
            UserDefaults(suiteName: WidgetConfiguration.appGroupIdentifier)?
                .set(showCategories, forKey: "widget.showCategories")
        }

        if let sortOrder = sortOrder {
            UserDefaults(suiteName: WidgetConfiguration.appGroupIdentifier)?
                .set(sortOrder.rawValue, forKey: "widget.sortOrder")
        }

        // Reload widgets with new configuration
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }

    enum SortOrder: String, AppEnum {
        case date
        case price
        case name

        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Sort Order")

        static var caseDisplayRepresentations: [SortOrder: DisplayRepresentation] = [
            .date: "By Date",
            .price: "By Price",
            .name: "By Name"
        ]
    }
}
