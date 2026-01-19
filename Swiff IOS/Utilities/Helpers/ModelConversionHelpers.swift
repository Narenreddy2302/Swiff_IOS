//
//  ModelConversionHelpers.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Utility class for batch model conversions and database seeding
//

import SwiftData
import Foundation
import Combine

/// Utility class for batch model conversions between domain and SwiftData models
class ModelConverter {

    // MARK: - Batch Insertion Methods

    /// Convert and insert array of domain Person models to SwiftData
    static func insertPeople(_ people: [Person], into context: ModelContext) {
        for person in people {
            let model = PersonModel(from: person)
            context.insert(model)
        }
    }

    /// Convert and insert array of domain Subscription models to SwiftData
    static func insertSubscriptions(_ subscriptions: [Subscription], into context: ModelContext) {
        for subscription in subscriptions {
            let model = SubscriptionModel(from: subscription)
            context.insert(model)
        }
    }

    /// Convert and insert array of domain Transaction models to SwiftData
    static func insertTransactions(_ transactions: [Transaction], into context: ModelContext) {
        for transaction in transactions {
            let model = TransactionModel(from: transaction)
            context.insert(model)
        }
    }

    /// Convert and insert array of domain SharedSubscription models to SwiftData
    static func insertSharedSubscriptions(_ sharedSubscriptions: [SharedSubscription], into context: ModelContext) {
        for sharedSub in sharedSubscriptions {
            let model = SharedSubscriptionModel(from: sharedSub)
            context.insert(model)
        }
    }

    /// Convert and insert array of domain Group models to SwiftData
    /// - Note: Requires people to exist first for relationships
    static func insertGroups(_ groups: [Group], into context: ModelContext) {
        for group in groups {
            let model = GroupModel(from: group, context: context)
            context.insert(model)
        }
    }

    // MARK: - Fetch and Convert Methods

    /// Fetch all PersonModels and convert to domain models
    static func fetchPeople(from context: ModelContext) throws -> [Person] {
        let descriptor = FetchDescriptor<PersonModel>()
        let personModels = try context.fetch(descriptor)
        return personModels.map { $0.toDomain() }
    }

    /// Fetch all SubscriptionModels and convert to domain models
    static func fetchSubscriptions(from context: ModelContext) throws -> [Subscription] {
        let descriptor = FetchDescriptor<SubscriptionModel>()
        let subscriptionModels = try context.fetch(descriptor)
        return subscriptionModels.map { $0.toDomain() }
    }

    /// Fetch all GroupModels and convert to domain models
    static func fetchGroups(from context: ModelContext) throws -> [Group] {
        let descriptor = FetchDescriptor<GroupModel>()
        let groupModels = try context.fetch(descriptor)
        return groupModels.map { $0.toDomain() }
    }

    /// Fetch all TransactionModels and convert to domain models
    static func fetchTransactions(from context: ModelContext) throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionModel>()
        let transactionModels = try context.fetch(descriptor)
        return transactionModels.map { $0.toDomain() }
    }

    // MARK: - Database Seeding

    /// Seed database with sample data
    /// - Note: This should only be called on first launch when database is empty
    static func seedSampleData(context: ModelContext) throws {
        // Check if database already has data
        let peopleDescriptor = FetchDescriptor<PersonModel>()
        let existingPeople = try context.fetch(peopleDescriptor)

        guard existingPeople.isEmpty else {
            print("Database already contains data. Skipping seed.")
            return
        }

        print("Seeding database with sample data...")

        // Note: Sample data arrays will need to be accessed from ContentView
        // or defined here. For now, this is the structure:

        // 1. Insert people first (no dependencies)
        // insertPeople(samplePeople, into: context)

        // 2. Insert subscriptions (no dependencies)
        // insertSubscriptions(sampleSubscriptions, into: context)

        // 3. Insert transactions (optional dependency on people)
        // insertTransactions(sampleTransactions, into: context)

        // 4. Insert groups (depends on people existing)
        // insertGroups(sampleGroups, into: context)

        // Save context
        try context.save()
        print("Sample data seeded successfully!")
    }

    /// Clear all data from database (useful for testing/reset)
    static func clearAllData(context: ModelContext) throws {
        // Delete all people
        try context.delete(model: PersonModel.self)

        // Delete all groups
        try context.delete(model: GroupModel.self)

        // Delete all group expenses
        try context.delete(model: GroupExpenseModel.self)

        // Delete all subscriptions
        try context.delete(model: SubscriptionModel.self)

        // Delete all shared subscriptions
        try context.delete(model: SharedSubscriptionModel.self)

        // Delete all transactions
        try context.delete(model: TransactionModel.self)

        // Save changes
        try context.save()
        print("All data cleared from database!")
    }

    // MARK: - Validation Helpers

    /// Validate if database is empty
    static func isDatabaseEmpty(context: ModelContext) throws -> Bool {
        let peopleCount = try context.fetchCount(FetchDescriptor<PersonModel>())
        let groupsCount = try context.fetchCount(FetchDescriptor<GroupModel>())
        let subscriptionsCount = try context.fetchCount(FetchDescriptor<SubscriptionModel>())

        return peopleCount == 0 && groupsCount == 0 && subscriptionsCount == 0
    }

    /// Get database statistics
    static func getDatabaseStats(context: ModelContext) throws -> DatabaseStats {
        return DatabaseStats(
            peopleCount: try context.fetchCount(FetchDescriptor<PersonModel>()),
            groupsCount: try context.fetchCount(FetchDescriptor<GroupModel>()),
            expensesCount: try context.fetchCount(FetchDescriptor<GroupExpenseModel>()),
            subscriptionsCount: try context.fetchCount(FetchDescriptor<SubscriptionModel>()),
            transactionsCount: try context.fetchCount(FetchDescriptor<TransactionModel>())
        )
    }
}

// MARK: - Supporting Types

struct DatabaseStats {
    let peopleCount: Int
    let groupsCount: Int
    let expensesCount: Int
    let subscriptionsCount: Int
    let transactionsCount: Int

    var totalRecords: Int {
        peopleCount + groupsCount + expensesCount + subscriptionsCount + transactionsCount
    }

    var description: String {
        """
        Database Statistics:
        - People: \(peopleCount)
        - Groups: \(groupsCount)
        - Group Expenses: \(expensesCount)
        - Subscriptions: \(subscriptionsCount)
        - Transactions: \(transactionsCount)
        - Total Records: \(totalRecords)
        """
    }
}
