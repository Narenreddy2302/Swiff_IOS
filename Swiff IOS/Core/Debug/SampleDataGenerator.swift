//
//  SampleDataGenerator.swift
//  Swiff IOS
//
//  Generates sample data during onboarding for new users
//  Uses MockData as the source for sample data
//

import Foundation

/// Generates sample data for new users during onboarding
/// This is separate from MockDataProvider which is used for DEBUG builds only
@MainActor
final class SampleDataGenerator {
    static let shared = SampleDataGenerator()

    private init() {}

    /// Generates sample data from MockData and adds it to DataManager
    /// Called during onboarding when user selects "Start with sample data"
    func generateSampleData() {
        let dataManager = DataManager.shared

        print("[SampleDataGenerator] Generating sample data...")

        // Add sample people
        for person in MockData.people {
            do {
                try dataManager.addPerson(person)
            } catch {
                print("[SampleDataGenerator] Failed to add person \(person.name): \(error)")
            }
        }

        // Add sample subscriptions
        for subscription in MockData.subscriptions {
            do {
                try dataManager.addSubscription(subscription)
            } catch {
                print("[SampleDataGenerator] Failed to add subscription \(subscription.name): \(error)")
            }
        }

        // Add sample groups
        for group in MockData.groups {
            do {
                try dataManager.addGroup(group)
            } catch {
                print("[SampleDataGenerator] Failed to add group \(group.name): \(error)")
            }
        }

        // Add sample transactions if available
        for transaction in MockData.transactions {
            do {
                try dataManager.addTransaction(transaction)
            } catch {
                print("[SampleDataGenerator] Failed to add transaction \(transaction.title): \(error)")
            }
        }

        print("[SampleDataGenerator] Sample data generation complete")
    }

    /// Clears all sample data (useful for resetting the app)
    func clearSampleData() {
        let dataManager = DataManager.shared

        print("[SampleDataGenerator] Clearing sample data...")

        // Clear all data
        dataManager.people.removeAll()
        dataManager.subscriptions.removeAll()
        dataManager.groups.removeAll()
        dataManager.transactions.removeAll()

        // Save changes
        dataManager.saveAllData()

        // Update settings
        UserSettings.shared.hasSampleData = false

        print("[SampleDataGenerator] Sample data cleared")
    }
}
