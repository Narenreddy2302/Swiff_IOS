//
//  MockDataCleaner.swift
//  Swiff IOS
//
//  One-time service to remove previously seeded mock data from the database
//  Uses stable UUIDs to surgically delete only mock data entries
//

import Foundation

/// One-time cleaner to remove previously seeded mock data
@MainActor
final class MockDataCleaner {
    static let shared = MockDataCleaner()

    private let clearingKey = "mockDataCleared_v1"

    private init() {}

    // Known mock data UUIDs from MockData.swift
    private let mockPersonIds: [UUID] = [
        UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
    ]

    private let mockSubscriptionIds: [UUID] = [
        UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
    ]

    private let mockGroupIds: [UUID] = [
        UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
        UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
    ]

    /// Clears mock data if not already done
    func clearMockDataIfNeeded() {
        // Skip if already cleared
        guard !UserDefaults.standard.bool(forKey: clearingKey) else {
            return
        }

        let dataManager = DataManager.shared

        print("[MockDataCleaner] Clearing previously seeded mock data...")

        // Delete mock people
        for id in mockPersonIds {
            try? dataManager.deletePerson(id: id)
        }

        // Delete mock subscriptions
        for id in mockSubscriptionIds {
            try? dataManager.deleteSubscription(id: id)
        }

        // Delete mock groups
        for id in mockGroupIds {
            try? dataManager.deleteGroup(id: id)
        }

        // Mark as cleared
        UserDefaults.standard.set(true, forKey: clearingKey)

        print("[MockDataCleaner] Mock data cleared successfully")
    }
}
