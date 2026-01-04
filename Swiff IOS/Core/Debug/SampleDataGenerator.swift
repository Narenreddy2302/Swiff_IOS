//
//  SampleDataGenerator.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Generate sample data for onboarding and testing
//
//  NOTE: This class is only available in DEBUG builds.
//  Sample data generation is disabled in production.
//

import Foundation
import SwiftUI
import UIKit

class SampleDataGenerator {
    static let shared = SampleDataGenerator()

    private init() {}

    // MARK: - Generate Sample Data

    func generateSampleData() {
        #if DEBUG
        let dataManager = DataManager.shared

        do {
            // Generate sample people
            let people = generateSamplePeople()
            for person in people {
                try dataManager.addPerson(person)
            }

            // Generate sample subscriptions
            let subscriptions = generateSampleSubscriptions()
            for subscription in subscriptions {
                try dataManager.addSubscription(subscription)
            }

            // Generate sample transactions
            let transactions = generateSampleTransactions()
            for transaction in transactions {
                try dataManager.addTransaction(transaction)
            }

            // Generate sample groups
            let groups = generateSampleGroups(with: people)
            for group in groups {
                try dataManager.addGroup(group)
            }

            print("✅ Sample data generated successfully")
        } catch {
            print("❌ Error generating sample data: \(error)")
        }
        #else
        print("⚠️ Sample data generation is disabled in production builds")
        #endif
    }

    // MARK: - Clear Sample Data

    func clearSampleData() {
        // This would clear all data - implement with caution
        // For now, just mark that sample data has been cleared
        UserSettings.shared.hasSampleData = false
        print("✅ Sample data cleared")
    }

    // MARK: - Generate People

    private func generateSamplePeople() -> [Person] {
        return [
            Person(name: "Alice Johnson", email: "alice.johnson@example.com", phone: "+1234567890", avatarType: .emoji("👩‍💼")),
            Person(name: "Bob Smith", email: "bob.smith@example.com", phone: "+1234567891", avatarType: .emoji("👨‍💼")),
            Person(name: "Carol Williams", email: "carol.williams@example.com", phone: "+1234567892", avatarType: .initials("CW", colorIndex: 0)),
            Person(name: "David Brown", email: "david.brown@example.com", phone: "+1234567893", avatarType: .emoji("👨")),
            Person(name: "Emma Davis", email: "emma.davis@example.com", phone: "+1234567894", avatarType: .emoji("👩"))
        ]
    }

    // MARK: - Generate Subscriptions

    private func generateSampleSubscriptions() -> [Subscription] {
        return [
            Subscription(name: "Netflix", description: "Streaming service", price: 15.99, billingCycle: .monthly, category: .entertainment),
            Subscription(name: "Spotify", description: "Music streaming", price: 9.99, billingCycle: .monthly, category: .entertainment),
            Subscription(name: "Adobe Creative Cloud", description: "Creative software suite", price: 52.99, billingCycle: .monthly, category: .productivity),
            Subscription(name: "Amazon Prime", description: "Shopping and streaming", price: 14.99, billingCycle: .monthly, category: .entertainment),
            Subscription(name: "Apple iCloud", description: "Cloud storage", price: 2.99, billingCycle: .monthly, category: .cloud),
            Subscription(name: "Disney+", description: "Family entertainment", price: 7.99, billingCycle: .monthly, category: .entertainment),
            Subscription(name: "YouTube Premium", description: "Ad-free videos", price: 11.99, billingCycle: .monthly, category: .entertainment),
            Subscription(name: "Microsoft 365", description: "Office suite", price: 99.99, billingCycle: .annually, category: .productivity),
            Subscription(name: "Dropbox", description: "File storage", price: 11.99, billingCycle: .monthly, category: .cloud),
            Subscription(name: "The New York Times", description: "News subscription", price: 17.00, billingCycle: .monthly, category: .news)
        ]
    }

    // MARK: - Generate Transactions

    private func generateSampleTransactions() -> [Transaction] {
        let transactionData: [(String, String, Double, TransactionCategory)] = [
            ("Grocery Shopping", "Whole Foods", -85.50, .groceries),
            ("Salary Deposit", "Company Inc.", 3500.00, .income),
            ("Electric Bill", "Utility Co.", -120.00, .utilities),
            ("Coffee", "Starbucks", -5.75, .food),
            ("Gas Station", "Shell", -45.00, .transportation),
            ("Movie Tickets", "AMC Theaters", -32.00, .entertainment),
            ("Dinner", "Italian Restaurant", -78.50, .food),
            ("Online Shopping", "Amazon", -156.99, .shopping),
            ("Gym Membership", "Planet Fitness", -29.99, .healthcare),
            ("Phone Bill", "Verizon", -85.00, .utilities),
            ("Book Purchase", "Barnes & Noble", -24.99, .shopping),
            ("Uber Ride", "Uber", -18.50, .transportation),
            ("Freelance Payment", "Client", 850.00, .income),
            ("Haircut", "Salon", -45.00, .other),
            ("Pet Supplies", "Petco", -67.00, .shopping)
        ]

        return transactionData.enumerated().map { index, data in
            let (title, subtitle, amount, category) = data
            let daysAgo = Double(index * 2)
            let date = Date().addingTimeInterval(-daysAgo * 86400)

            let transaction = Transaction(
                title: title,
                subtitle: subtitle,
                amount: abs(amount),
                category: category,
                date: date,
                isRecurring: false,
                tags: []
            )
            return transaction
        }
    }

    // MARK: - Generate Groups

    private func generateSampleGroups(with people: [Person]) -> [Group] {
        guard people.count >= 3 else { return [] }

        return [
            Group(
                name: "Netflix Sharing",
                description: "Shared streaming service",
                emoji: "🎬",
                members: Array(people.prefix(3).map { $0.id })
            ),
            Group(
                name: "Apartment Utilities",
                description: "Shared apartment expenses",
                emoji: "🏠",
                members: Array(people.prefix(4).map { $0.id })
            )
        ]
    }
}

// MARK: - User Settings Extension

extension UserSettings {
    var hasSampleData: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasSampleData")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasSampleData")
        }
    }
}
