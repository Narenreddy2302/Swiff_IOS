//
//  SharedSubscription+Preview.swift
//  Swiff IOS
//
//  Preview extensions for SharedSubscription model
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension SharedSubscription {

    // MARK: - By Balance Status

    /// They owe you (positive balance)
    static var previewOwesYou: SharedSubscription {
        MockDataProvider.shared.sharedYouTube
    }

    /// You owe them (negative balance)
    static var previewYouOwe: SharedSubscription {
        MockDataProvider.shared.sharedDisney
    }

    /// Settled (zero balance)
    static var previewSettled: SharedSubscription {
        MockDataProvider.shared.sharedAppleOne
    }

    /// Large balance amount
    static var previewLargeBalance: SharedSubscription {
        MockDataProvider.shared.sharedHulu
    }

    /// Pending/unaccepted
    static var previewPending: SharedSubscription {
        MockDataProvider.shared.sharedParamount
    }

    // MARK: - By Member Count

    /// Shared with multiple people (3+)
    static var previewMultipleMembers: SharedSubscription {
        MockDataProvider.shared.sharedYouTube // 3 members
    }

    /// Shared with many people (4+)
    static var previewManyMembers: SharedSubscription {
        MockDataProvider.shared.sharedAppleOne // 4 members
    }

    /// Shared with one person
    static var previewSingleMember: SharedSubscription {
        MockDataProvider.shared.sharedHulu // 1 member
    }

    // MARK: - Collections

    /// All shared subscriptions (5)
    static var previewList: [SharedSubscription] {
        MockDataProvider.shared.allSharedSubscriptions
    }

    /// Shared subscriptions where they owe you
    static var previewOwedList: [SharedSubscription] {
        MockDataProvider.shared.allSharedSubscriptions.filter { $0.balanceStatus == .owesYou }
    }

    /// Shared subscriptions where you owe them
    static var previewOwingList: [SharedSubscription] {
        MockDataProvider.shared.allSharedSubscriptions.filter { $0.balanceStatus == .youOwe }
    }

    /// Settled shared subscriptions
    static var previewSettledList: [SharedSubscription] {
        MockDataProvider.shared.allSharedSubscriptions.filter { $0.balanceStatus == .settled }
    }

    /// Accepted shared subscriptions
    static var previewAcceptedList: [SharedSubscription] {
        MockDataProvider.shared.allSharedSubscriptions.filter { $0.isAccepted }
    }

    /// Empty list for empty state
    static var previewEmpty: [SharedSubscription] {
        []
    }

    // MARK: - Random

    /// Random shared subscription
    static var previewRandom: SharedSubscription {
        MockDataProvider.shared.allSharedSubscriptions.randomElement() ?? previewOwesYou
    }
}
#endif
