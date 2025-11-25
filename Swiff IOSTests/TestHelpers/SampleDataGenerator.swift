//
//  SampleDataGenerator.swift
//  Swiff IOSTests
//
//  Created by Test Agent 15 on 11/21/25.
//  Test helper for generating sample data for testing
//

import Foundation
@testable import Swiff_IOS

/// Helper class for generating sample data for tests
class SampleDataGenerator {

    // MARK: - Person Generation

    static func generatePerson(
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        avatarType: AvatarType? = nil
    ) -> Person {
        let generatedName = name ?? "Test Person \(UUID().uuidString.prefix(8))"
        return Person(
            name: generatedName,
            email: email ?? "\(generatedName.replacingOccurrences(of: " ", with: ".").lowercased())@test.com",
            phone: phone ?? "+1 (555) \(Int.random(in: 100...999))-\(Int.random(in: 1000...9999))",
            avatarType: avatarType ?? .emoji("👤")
        )
    }

    static func generatePeople(count: Int) -> [Person] {
        return (0..<count).map { index in
            generatePerson(name: "Test Person \(index + 1)")
        }
    }

    // MARK: - Subscription Generation

    static func generateSubscription(
        name: String? = nil,
        price: Double? = nil,
        billingCycle: BillingCycle? = nil,
        category: SubscriptionCategory? = nil,
        isActive: Bool = true
    ) -> Subscription {
        var subscription = Subscription(
            name: name ?? "Test Subscription \(UUID().uuidString.prefix(8))",
            description: "Test subscription description",
            price: price ?? Double.random(in: 5.99...99.99),
            billingCycle: billingCycle ?? .monthly,
            category: category ?? .entertainment,
            icon: "app.fill",
            color: "#007AFF"
        )
        subscription.isActive = isActive
        return subscription
    }

    static func generateSubscriptions(count: Int) -> [Subscription] {
        return (0..<count).map { index in
            generateSubscription(name: "Subscription \(index + 1)")
        }
    }

    static func generateActiveSubscriptions(count: Int) -> [Subscription] {
        return generateSubscriptions(count: count).map { var sub = $0; sub.isActive = true; return sub }
    }

    static func generateInactiveSubscriptions(count: Int) -> [Subscription] {
        return generateSubscriptions(count: count).map { var sub = $0; sub.isActive = false; return sub }
    }

    // MARK: - Transaction Generation

    static func generateTransaction(
        title: String? = nil,
        amount: Double? = nil,
        category: TransactionCategory? = nil,
        date: Date? = nil,
        isRecurring: Bool = false
    ) -> Transaction {
        return Transaction(
            id: UUID(),
            title: title ?? "Test Transaction \(UUID().uuidString.prefix(8))",
            subtitle: "Test subtitle",
            amount: amount ?? Double.random(in: -500...500),
            category: category ?? .other,
            date: date ?? Date(),
            isRecurring: isRecurring,
            tags: ["test"]
        )
    }

    static func generateTransactions(count: Int) -> [Transaction] {
        return (0..<count).map { index in
            let daysAgo = index % 30
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return generateTransaction(
                title: "Transaction \(index + 1)",
                date: date
            )
        }
    }

    static func generateIncomeTransactions(count: Int) -> [Transaction] {
        return (0..<count).map { index in
            generateTransaction(
                title: "Income \(index + 1)",
                amount: Double.random(in: 100...5000),
                category: .income
            )
        }
    }

    static func generateExpenseTransactions(count: Int) -> [Transaction] {
        return (0..<count).map { index in
            generateTransaction(
                title: "Expense \(index + 1)",
                amount: -Double.random(in: 10...500),
                category: .shopping
            )
        }
    }

    // MARK: - Group Generation

    static func generateGroup(
        name: String? = nil,
        members: [UUID]? = nil,
        expenses: [GroupExpense]? = nil
    ) -> Group {
        let memberIds = members ?? [UUID(), UUID()]
        return Group(
            name: name ?? "Test Group \(UUID().uuidString.prefix(8))",
            description: "Test group description",
            emoji: "👥",
            members: memberIds
        )
    }

    static func generateGroups(count: Int, memberCount: Int = 2) -> [Group] {
        return (0..<count).map { index in
            let members = (0..<memberCount).map { _ in UUID() }
            return generateGroup(name: "Group \(index + 1)", members: members)
        }
    }

    // MARK: - GroupExpense Generation

    static func generateGroupExpense(
        title: String? = nil,
        amount: Double? = nil,
        paidBy: UUID? = nil,
        splitBetween: [UUID]? = nil
    ) -> GroupExpense {
        let payer = paidBy ?? UUID()
        let splitters = splitBetween ?? [payer, UUID()]

        return GroupExpense(
            title: title ?? "Test Expense \(UUID().uuidString.prefix(8))",
            amount: amount ?? Double.random(in: 10...500),
            paidBy: payer,
            splitBetween: splitters,
            category: .other,
            notes: "Test expense notes",
            receipt: nil,
            isSettled: false
        )
    }

    // MARK: - PriceChange Generation

    static func generatePriceChange(
        subscriptionId: UUID? = nil,
        oldPrice: Double? = nil,
        newPrice: Double? = nil,
        detectedAutomatically: Bool = true
    ) -> PriceChange {
        let oldAmount = oldPrice ?? Double.random(in: 5...50)
        let newAmount = newPrice ?? oldAmount + Double.random(in: 1...10)

        return PriceChange(
            subscriptionId: subscriptionId ?? UUID(),
            oldPrice: oldAmount,
            newPrice: newAmount,
            detectedAutomatically: detectedAutomatically
        )
    }

    // MARK: - Large Dataset Generation

    /// Generate a large dataset for performance testing
    static func generateLargeDataset(
        peopleCount: Int = 100,
        subscriptionsCount: Int = 500,
        transactionsCount: Int = 5000,
        groupsCount: Int = 50
    ) -> (people: [Person], subscriptions: [Subscription], transactions: [Transaction], groups: [Group]) {
        print("📊 Generating large dataset...")
        print("   People: \(peopleCount)")
        print("   Subscriptions: \(subscriptionsCount)")
        print("   Transactions: \(transactionsCount)")
        print("   Groups: \(groupsCount)")

        let people = generatePeople(count: peopleCount)
        let subscriptions = generateSubscriptions(count: subscriptionsCount)
        let transactions = generateTransactions(count: transactionsCount)
        let groups = generateGroups(count: groupsCount)

        print("✅ Large dataset generated")

        return (people, subscriptions, transactions, groups)
    }

    // MARK: - Search Test Data

    /// Generate data specifically for search testing
    static func generateSearchableData() -> (people: [Person], subscriptions: [Subscription], transactions: [Transaction]) {
        let people = [
            generatePerson(name: "Alice Anderson"),
            generatePerson(name: "Bob Baker"),
            generatePerson(name: "Charlie Chen"),
            generatePerson(name: "Diana Davis"),
            generatePerson(name: "Eve Evans")
        ]

        let subscriptions = [
            generateSubscription(name: "Netflix", category: .entertainment),
            generateSubscription(name: "Spotify", category: .entertainment),
            generateSubscription(name: "Gym Membership", category: .health),
            generateSubscription(name: "iCloud Storage", category: .utilities),
            generateSubscription(name: "Adobe Creative Cloud", category: .productivity)
        ]

        let transactions = [
            generateTransaction(title: "Salary", amount: 5000, category: .income),
            generateTransaction(title: "Rent Payment", amount: -1500, category: .utilities),
            generateTransaction(title: "Grocery Shopping", amount: -150, category: .groceries),
            generateTransaction(title: "Restaurant", amount: -75, category: .dining),
            generateTransaction(title: "Gas Station", amount: -50, category: .transport)
        ]

        return (people, subscriptions, transactions)
    }

    // MARK: - Filter Test Data

    /// Generate data for filter testing with specific categories
    static func generateFilterableTransactions() -> [Transaction] {
        var transactions: [Transaction] = []

        // Generate transactions for each category
        let categories: [TransactionCategory] = [.income, .shopping, .dining, .transport, .groceries, .utilities, .entertainment, .health, .other]

        for category in categories {
            for i in 0..<5 {
                transactions.append(generateTransaction(
                    title: "\(category.rawValue) Transaction \(i + 1)",
                    category: category
                ))
            }
        }

        return transactions
    }

    /// Generate subscriptions for filter testing with specific categories
    static func generateFilterableSubscriptions() -> [Subscription] {
        var subscriptions: [Subscription] = []

        let categories: [SubscriptionCategory] = [.entertainment, .productivity, .health, .utilities, .education, .shopping, .gaming, .news, .finance, .other]

        for category in categories {
            // Active subscription
            subscriptions.append(generateSubscription(
                name: "\(category.rawValue) Active",
                category: category,
                isActive: true
            ))

            // Inactive subscription
            subscriptions.append(generateSubscription(
                name: "\(category.rawValue) Inactive",
                category: category,
                isActive: false
            ))
        }

        return subscriptions
    }

    // MARK: - Sorting Test Data

    /// Generate data for sorting tests with varied dates and amounts
    static func generateSortableTransactions() -> [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        return [
            generateTransaction(title: "Oldest", amount: -100, date: calendar.date(byAdding: .day, value: -30, to: now)!),
            generateTransaction(title: "Middle", amount: -50, date: calendar.date(byAdding: .day, value: -15, to: now)!),
            generateTransaction(title: "Newest", amount: -25, date: now),
            generateTransaction(title: "Largest Amount", amount: -500, date: calendar.date(byAdding: .day, value: -7, to: now)!),
            generateTransaction(title: "Smallest Amount", amount: -10, date: calendar.date(byAdding: .day, value: -3, to: now)!)
        ]
    }

    // MARK: - Edge Cases

    /// Generate edge case data for testing boundaries
    static func generateEdgeCaseData() -> (subscriptions: [Subscription], transactions: [Transaction]) {
        var edgeSubscriptions: [Subscription] = []
        var edgeTransactions: [Transaction] = []

        // Very expensive subscription
        edgeSubscriptions.append(generateSubscription(name: "Expensive", price: 9999.99))

        // Very cheap subscription
        edgeSubscriptions.append(generateSubscription(name: "Cheap", price: 0.99))

        // Different billing cycles
        for cycle in [BillingCycle.weekly, .monthly, .quarterly, .semiAnnually, .annually, .lifetime] {
            edgeSubscriptions.append(generateSubscription(name: "Test \(cycle)", billingCycle: cycle))
        }

        // Zero amount transaction
        edgeTransactions.append(generateTransaction(title: "Zero Amount", amount: 0))

        // Very large transaction
        edgeTransactions.append(generateTransaction(title: "Large", amount: 99999.99))

        // Very small transaction
        edgeTransactions.append(generateTransaction(title: "Small", amount: -0.01))

        return (edgeSubscriptions, edgeTransactions)
    }

    // MARK: - Cleanup Helpers

    /// Clear all test data from persistence (use with caution!)
    static func clearAllTestData(dataManager: DataManager) throws {
        // Delete all entities - this would need implementation in DataManager
        // For now, this is a placeholder
        print("⚠️ Clear test data not yet implemented")
    }
}
