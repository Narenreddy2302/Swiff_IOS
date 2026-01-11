//
//  TestDataGenerator.swift
//  Swiff IOSTests
//
//  Helper for generating test data in unit and integration tests
//  This is only available in the test target, not the main app
//

import Foundation
@testable import Swiff_IOS

/// Test data generator for creating mock objects in tests
/// Replaces SampleDataGenerator for test-only usage
enum SampleDataGenerator {

    // MARK: - Person Generation

    static func generatePerson(name: String = "Test Person") -> Person {
        Person(
            id: UUID(),
            name: name,
            email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@test.com",
            phone: "555-0100",
            avatarType: .initials,
            notes: "Test person generated for testing"
        )
    }

    static func generatePeople(count: Int) -> [Person] {
        (0..<count).map { i in
            generatePerson(name: "Test Person \(i)")
        }
    }

    // MARK: - Subscription Generation

    static func generateSubscription(name: String = "Test Subscription", price: Double = 9.99) -> Subscription {
        Subscription(
            id: UUID(),
            name: name,
            price: price,
            currency: "USD",
            billingCycle: .monthly,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            category: .entertainment,
            notes: "Test subscription",
            isActive: true,
            enableRenewalReminder: true,
            reminderDaysBefore: 3,
            usageCount: 0
        )
    }

    static func generateSubscriptions(count: Int) -> [Subscription] {
        let categories: [SubscriptionCategory] = [.entertainment, .productivity, .utilities, .finance, .health, .shopping, .social, .education]
        let cycles: [BillingCycle] = [.monthly, .yearly, .weekly, .quarterly]

        return (0..<count).map { i in
            var sub = generateSubscription(name: "Subscription \(i)", price: Double.random(in: 1.99...99.99))
            sub.category = categories[i % categories.count]
            sub.billingCycle = cycles[i % cycles.count]
            sub.isActive = Bool.random()
            return sub
        }
    }

    // MARK: - Transaction Generation

    static func generateTransaction(title: String = "Test Transaction", amount: Double = -25.00) -> Transaction {
        Transaction(
            id: UUID(),
            title: title,
            subtitle: "Test subtitle",
            amount: amount,
            category: amount >= 0 ? .income : .shopping,
            date: Date(),
            isRecurring: false,
            tags: [],
            notes: "Test transaction"
        )
    }

    static func generateTransactions(count: Int) -> [Transaction] {
        let categories: [TransactionCategory] = [.income, .shopping, .food, .transport, .entertainment, .utilities, .health, .other]

        return (0..<count).map { i in
            let isIncome = i % 5 == 0
            let amount = isIncome ? Double.random(in: 100...5000) : -Double.random(in: 5...500)
            let daysAgo = Int.random(in: 0...365)
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            return Transaction(
                id: UUID(),
                title: "Transaction \(i)",
                subtitle: "Test subtitle",
                amount: amount,
                category: categories[i % categories.count],
                date: date,
                isRecurring: false,
                tags: [],
                notes: ""
            )
        }
    }

    static func generateFilterableTransactions() -> [Transaction] {
        // Generate transactions with specific patterns for filter testing
        var transactions: [Transaction] = []
        let categories: [TransactionCategory] = [.income, .shopping, .food, .transport, .entertainment]

        for i in 0..<500 {
            let category = categories[i % categories.count]
            let isIncome = category == .income
            let amount = isIncome ? Double.random(in: 100...1000) : -Double.random(in: 10...200)
            let daysAgo = i % 60 // Spread over 60 days
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            transactions.append(Transaction(
                id: UUID(),
                title: "Filterable Transaction \(i)",
                subtitle: "Filter test",
                amount: amount,
                category: category,
                date: date,
                isRecurring: false,
                tags: [],
                notes: ""
            ))
        }

        return transactions
    }

    // MARK: - Group Generation

    static func generateGroup(name: String, members: [UUID]) -> Group {
        Group(
            name: name,
            description: "Test group",
            emoji: "👥",
            members: members
        )
    }

    static func generateGroupExpense(
        title: String,
        amount: Double,
        paidBy: UUID,
        splitBetween: [UUID]
    ) -> GroupExpense {
        GroupExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splitBetween: splitBetween,
            category: .other,
            notes: "Test expense"
        )
    }

    // MARK: - Large Dataset Generation

    struct LargeDataset {
        let people: [Person]
        let subscriptions: [Subscription]
        let transactions: [Transaction]
        let groups: [Group]
    }

    static func generateLargeDataset(
        peopleCount: Int,
        subscriptionsCount: Int,
        transactionsCount: Int,
        groupsCount: Int
    ) -> LargeDataset {
        let people = generatePeople(count: peopleCount)
        let subscriptions = generateSubscriptions(count: subscriptionsCount)
        let transactions = generateTransactions(count: transactionsCount)

        let groups = (0..<groupsCount).map { i in
            let memberCount = min(5, people.count)
            let memberIds = Array(people.prefix(memberCount)).map { $0.id }
            return generateGroup(name: "Group \(i)", members: memberIds)
        }

        return LargeDataset(
            people: people,
            subscriptions: subscriptions,
            transactions: transactions,
            groups: groups
        )
    }
}
