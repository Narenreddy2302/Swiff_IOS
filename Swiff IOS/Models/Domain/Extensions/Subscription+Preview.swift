//
//  Subscription+Preview.swift
//  Swiff IOS
//
//  Preview extensions for Subscription model
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension Subscription {

    // MARK: - By State

    /// Active monthly subscription
    static var previewActive: Subscription {
        MockDataProvider.shared.subscriptionNetflix
    }

    /// Yearly billing subscription
    static var previewYearly: Subscription {
        MockDataProvider.shared.subscriptionMicrosoft365
    }

    /// Inactive/Cancelled subscription
    static var previewCancelled: Subscription {
        MockDataProvider.shared.subscriptionHBOMax
    }

    /// Free trial subscription (ending soon)
    static var previewTrial: Subscription {
        MockDataProvider.shared.subscriptionSpotify
    }

    /// Expired trial subscription
    static var previewTrialExpired: Subscription {
        MockDataProvider.shared.subscriptionAdobeCreative
    }

    /// Paused subscription
    static var previewPaused: Subscription {
        MockDataProvider.shared.subscriptionAppleMusic
    }

    // MARK: - Edge Cases

    /// Cheap subscription ($0.99)
    static var previewCheap: Subscription {
        MockDataProvider.shared.subscriptionICloud
    }

    /// Expensive subscription ($9,999+)
    static var previewExpensive: Subscription {
        MockDataProvider.shared.subscriptionEnterprise
    }

    /// Subscription due today
    static var previewDueToday: Subscription {
        MockDataProvider.shared.subscriptionGym
    }

    /// Subscription with long name
    static var previewLongName: Subscription {
        MockDataProvider.shared.subscriptionNYT
    }

    /// Shared subscription
    static var previewShared: Subscription {
        MockDataProvider.shared.sharedSubscriptionBase[0]
    }

    // MARK: - By Category

    /// Entertainment subscription
    static var previewEntertainment: Subscription {
        MockDataProvider.shared.subscriptionNetflix
    }

    /// Productivity subscription
    static var previewProductivity: Subscription {
        MockDataProvider.shared.subscriptionMicrosoft365
    }

    /// Music subscription
    static var previewMusic: Subscription {
        MockDataProvider.shared.subscriptionSpotify
    }

    /// Fitness subscription
    static var previewFitness: Subscription {
        MockDataProvider.shared.subscriptionGym
    }

    /// Cloud storage subscription
    static var previewCloud: Subscription {
        MockDataProvider.shared.subscriptionICloud
    }

    /// News subscription
    static var previewNews: Subscription {
        MockDataProvider.shared.subscriptionNYT
    }

    // MARK: - Collections

    /// All personal subscriptions (10)
    static var previewPersonalList: [Subscription] {
        MockDataProvider.shared.personalSubscriptions
    }

    /// All shared subscriptions base (5)
    static var previewSharedList: [Subscription] {
        MockDataProvider.shared.sharedSubscriptionBase
    }

    /// All subscriptions (15)
    static var previewAllList: [Subscription] {
        MockDataProvider.shared.allSubscriptions
    }

    /// Active subscriptions only
    static var previewActiveList: [Subscription] {
        MockDataProvider.shared.allSubscriptions.filter { $0.isActive }
    }

    /// Inactive subscriptions only
    static var previewInactiveList: [Subscription] {
        MockDataProvider.shared.allSubscriptions.filter { !$0.isActive }
    }

    /// Trial subscriptions
    static var previewTrialList: [Subscription] {
        MockDataProvider.shared.allSubscriptions.filter { $0.isFreeTrial }
    }

    /// Empty list for empty state
    static var previewEmpty: [Subscription] {
        []
    }

    // MARK: - Random

    /// Random subscription
    static var previewRandom: Subscription {
        MockDataProvider.shared.allSubscriptions.randomElement() ?? previewActive
    }
}
#endif
