//
//  MockDataProvider.swift
//  Swiff IOS
//
//  Provides async mock data seeding for DEBUG builds
//  Called from Swiff_IOSApp.swift to populate test data when database is empty
//

import Foundation

/// Provider for seeding mock data in DEBUG builds
/// Uses actor for thread-safe access
@MainActor
final class MockDataProvider {
    static let shared = MockDataProvider()

    private init() {}

    /// Seeds mock data only if the database is empty
    /// This prevents overwriting user data while still providing sample data for testing
    func seedIfEmpty() async {
        let dataManager = DataManager.shared

        // Check if any data exists - if so, don't seed
        let hasData = !dataManager.people.isEmpty ||
                      !dataManager.subscriptions.isEmpty ||
                      !dataManager.groups.isEmpty

        guard !hasData else {
            #if DEBUG
            print("[MockDataProvider] Database already has data, skipping seed")
            #endif
            return
        }

        #if DEBUG
        print("[MockDataProvider] Seeding mock data...")
        #endif

        // Seed people
        for person in MockData.people {
            do {
                try dataManager.addPerson(person)
            } catch {
                #if DEBUG
                print("[MockDataProvider] Failed to add person \(person.name): \(error)")
                #endif
            }
        }

        // Seed subscriptions
        for subscription in MockData.subscriptions {
            do {
                try dataManager.addSubscription(subscription)
            } catch {
                #if DEBUG
                print("[MockDataProvider] Failed to add subscription \(subscription.name): \(error)")
                #endif
            }
        }

        // Seed groups
        for group in MockData.groups {
            do {
                try dataManager.addGroup(group)
            } catch {
                #if DEBUG
                print("[MockDataProvider] Failed to add group \(group.name): \(error)")
                #endif
            }
        }

        #if DEBUG
        print("[MockDataProvider] Mock data seeded successfully")
        #endif
    }
}
