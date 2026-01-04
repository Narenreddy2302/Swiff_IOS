//
//  DeepLinkHandler.swift
//  Swiff IOS
//
//  Created by Agent 10 on 11/21/25.
//  Deep link handler for widget interactions
//

import SwiftUI
import Combine

// MARK: - Deep Link Type

enum DeepLinkType: Equatable {
    case addTransaction
    case addSubscription
    case viewSubscriptions
    case viewFeed
    case viewSubscription(id: String)
    case markAsPaid(id: String)
    case none

    init(url: URL) {
        guard url.scheme == "swiff",
              url.host == "action" else {
            self = .none
            return
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let action = pathComponents.first else {
            self = .none
            return
        }

        switch action {
        case "add-transaction":
            self = .addTransaction
        case "add-subscription":
            self = .addSubscription
        case "view-subscriptions":
            self = .viewSubscriptions
        case "view-feed":
            self = .viewFeed
        case "view-subscription":
            if pathComponents.count > 1 {
                self = .viewSubscription(id: pathComponents[1])
            } else {
                self = .viewSubscriptions
            }
        case "mark-as-paid":
            if pathComponents.count > 1 {
                self = .markAsPaid(id: pathComponents[1])
            } else {
                self = .none
            }
        default:
            self = .none
        }
    }
}

// MARK: - Deep Link Handler

@MainActor
class DeepLinkHandler: ObservableObject {
    @Published var currentDeepLink: DeepLinkType = .none
    @Published var showAddTransaction = false
    @Published var showAddSubscription = false
    @Published var selectedTab: Int = 0
    @Published var selectedSubscriptionId: String?

    /// Handle incoming deep link URL
    func handle(url: URL) {
        let deepLink = DeepLinkType(url: url)
        currentDeepLink = deepLink

        print("📲 Deep link received: \(url)")
        print("📲 Parsed as: \(deepLink)")

        // Process the deep link
        process(deepLink)
    }

    /// Process deep link type and update app state
    private func process(_ deepLink: DeepLinkType) {
        // Reset all states
        resetStates()

        // Small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Tab order: Home(0) - People(1) - +(2) - Subscriptions(3) - Feed(4)
            switch deepLink {
            case .addTransaction:
                self.showAddTransaction = true

            case .addSubscription:
                self.showAddSubscription = true

            case .viewSubscriptions:
                self.selectedTab = 3 // Subscriptions tab

            case .viewFeed:
                self.selectedTab = 4 // Feed tab

            case .viewSubscription(let id):
                self.selectedSubscriptionId = id
                self.selectedTab = 3 // Navigate to subscriptions tab

            case .markAsPaid(let id):
                // MOCK: In production, this would mark the subscription as paid
                print("⚠️ MOCK: Mark subscription \(id) as paid")
                self.selectedSubscriptionId = id
                self.selectedTab = 3

            case .none:
                break
            }
        }
    }

    /// Reset all navigation states
    private func resetStates() {
        showAddTransaction = false
        showAddSubscription = false
        selectedSubscriptionId = nil
    }

    /// Clear current deep link
    func clearDeepLink() {
        currentDeepLink = .none
    }
}

// MARK: - View Extension for Deep Linking

extension View {
    /// Add deep link handling to a view
    func handleDeepLinks(handler: DeepLinkHandler) -> some View {
        self
            .onOpenURL { url in
                handler.handle(url: url)
            }
            .environmentObject(handler)
    }
}

// MARK: - Deep Link Helper

struct DeepLinkHelper {
    /// Generate deep link URL
    static func makeURL(for type: DeepLinkType) -> URL? {
        switch type {
        case .addTransaction:
            return URL(string: "swiff://action/add-transaction")
        case .addSubscription:
            return URL(string: "swiff://action/add-subscription")
        case .viewSubscriptions:
            return URL(string: "swiff://action/view-subscriptions")
        case .viewFeed:
            return URL(string: "swiff://action/view-feed")
        case .viewSubscription(let id):
            return URL(string: "swiff://action/view-subscription/\(id)")
        case .markAsPaid(let id):
            return URL(string: "swiff://action/mark-as-paid/\(id)")
        case .none:
            return nil
        }
    }

    /// Test deep link handling
    static func testDeepLink(_ type: DeepLinkType) {
        guard let url = makeURL(for: type) else {
            print("❌ Failed to create URL for deep link: \(type)")
            return
        }

        print("✅ Test deep link URL: \(url)")

        // In production, this would open the URL
        // UIApplication.shared.open(url)
    }
}

// MARK: - Deep Link Examples

extension DeepLinkHelper {
    static let examples: [(name: String, url: URL?)] = [
        ("Add Transaction", makeURL(for: .addTransaction)),
        ("Add Subscription", makeURL(for: .addSubscription)),
        ("View Subscriptions", makeURL(for: .viewSubscriptions)),
        ("View Feed", makeURL(for: .viewFeed)),
        ("View Specific Subscription", makeURL(for: .viewSubscription(id: "test-id"))),
        ("Mark As Paid", makeURL(for: .markAsPaid(id: "test-id")))
    ]
}
