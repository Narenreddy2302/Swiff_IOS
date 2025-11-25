//
//  SpotlightIndexingService.swift
//  Swiff IOS
//
//  Created by Agent 12 on 11/21/25.
//  CoreSpotlight integration for system-wide search of app content
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Spotlight Indexing Service

/// Service for indexing app content in iOS Spotlight search
/// This allows users to search for subscriptions, people, and transactions from the system search
@MainActor
class SpotlightIndexingService {

    // MARK: - Singleton

    static let shared = SpotlightIndexingService()

    // MARK: - Constants

    private let personDomainIdentifier = "com.swiff.person"
    private let subscriptionDomainIdentifier = "com.swiff.subscription"
    private let transactionDomainIdentifier = "com.swiff.transaction"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Index all app content in Spotlight
    func indexAllContent(people: [Person], subscriptions: [Subscription], transactions: [Transaction]) async {
        print("SpotlightIndexingService: Starting full index...")

        // Index in batches to avoid overwhelming the system
        await indexPeople(people)
        await indexSubscriptions(subscriptions)
        await indexTransactions(transactions)

        print("SpotlightIndexingService: Full index completed")
    }

    /// Index a single person
    func indexPerson(_ person: Person) async {
        let searchableItem = createSearchableItem(for: person)
        await indexItems([searchableItem])
    }

    /// Index multiple people
    func indexPeople(_ people: [Person]) async {
        let items = people.map { createSearchableItem(for: $0) }
        await indexItems(items)
        print("SpotlightIndexingService: Indexed \(items.count) people")
    }

    /// Index a single subscription
    func indexSubscription(_ subscription: Subscription) async {
        let searchableItem = createSearchableItem(for: subscription)
        await indexItems([searchableItem])
    }

    /// Index multiple subscriptions
    func indexSubscriptions(_ subscriptions: [Subscription]) async {
        let items = subscriptions.map { createSearchableItem(for: $0) }
        await indexItems(items)
        print("SpotlightIndexingService: Indexed \(items.count) subscriptions")
    }

    /// Index a single transaction
    func indexTransaction(_ transaction: Transaction) async {
        let searchableItem = createSearchableItem(for: transaction)
        await indexItems([searchableItem])
    }

    /// Index multiple transactions
    func indexTransactions(_ transactions: [Transaction]) async {
        // Only index recent transactions (last 90 days) to avoid cluttering Spotlight
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let recentTransactions = transactions.filter { $0.date >= ninetyDaysAgo }

        let items = recentTransactions.map { createSearchableItem(for: $0) }
        await indexItems(items)
        print("SpotlightIndexingService: Indexed \(items.count) recent transactions")
    }

    /// Remove a person from Spotlight index
    func removePerson(_ personId: UUID) async {
        await removeItems(withIdentifiers: [personIdentifier(personId)])
    }

    /// Remove a subscription from Spotlight index
    func removeSubscription(_ subscriptionId: UUID) async {
        await removeItems(withIdentifiers: [subscriptionIdentifier(subscriptionId)])
    }

    /// Remove a transaction from Spotlight index
    func removeTransaction(_ transactionId: UUID) async {
        await removeItems(withIdentifiers: [transactionIdentifier(transactionId)])
    }

    /// Remove all indexed content
    func clearAllIndexedContent() async {
        do {
            try await CSSearchableIndex.default().deleteAllSearchableItems()
            print("SpotlightIndexingService: Cleared all indexed content")
        } catch {
            print("SpotlightIndexingService: Error clearing indexed content - \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods - Create Searchable Items

    private func createSearchableItem(for person: Person) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .contact)

        // Basic attributes
        attributeSet.title = person.name
        attributeSet.contentDescription = person.email
        attributeSet.emailAddresses = [person.email]
        attributeSet.phoneNumbers = [person.phone]

        // Additional metadata - append balance to description
        if person.balance != 0 {
            let balanceText = person.balance > 0 ? "You owe $\(abs(person.balance))" : "Owes you $\(abs(person.balance))"
            attributeSet.contentDescription = "\(person.email) • \(balanceText)"
        }

        // Keywords for better search
        attributeSet.keywords = [
            "person",
            "contact",
            person.name,
            person.email,
            "balance",
            person.balance > 0 ? "debt" : "owed"
        ]

        // Thumbnail (if available)
        // Note: In production, you would generate this from the avatar
        // attributeSet.thumbnailData = generateAvatarImageData(for: person)

        let item = CSSearchableItem(
            uniqueIdentifier: personIdentifier(person.id),
            domainIdentifier: personDomainIdentifier,
            attributeSet: attributeSet
        )

        return item
    }

    private func createSearchableItem(for subscription: Subscription) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        // Basic attributes
        attributeSet.title = subscription.name
        attributeSet.contentDescription = subscription.description

        // Subscription-specific metadata
        let billingCycleName: String = subscription.billingCycle.shortName
        let priceText = String(format: "$%.2f per %@", subscription.price, billingCycleName)
        attributeSet.contentDescription = "\(subscription.description) • \(priceText)"

        // Status
        let statusText = subscription.isActive ? "Active" : (subscription.cancellationDate != nil ? "Cancelled" : "Paused")

        // Keywords for better search
        var keywords = [
            "subscription",
            subscription.name,
            subscription.category.rawValue,
            subscription.billingCycle.rawValue,
            statusText,
            priceText
        ]

        if subscription.isFreeTrial {
            keywords.append("trial")
            keywords.append("free trial")
        }

        if subscription.isShared {
            keywords.append("shared")
        }

        attributeSet.keywords = keywords

        // Dates
        attributeSet.contentCreationDate = subscription.createdDate
        attributeSet.contentModificationDate = subscription.createdDate

        // Rating/importance (active subscriptions are more important)
        attributeSet.rating = NSNumber(value: subscription.isActive ? 5 : 3)

        let item = CSSearchableItem(
            uniqueIdentifier: subscriptionIdentifier(subscription.id),
            domainIdentifier: subscriptionDomainIdentifier,
            attributeSet: attributeSet
        )

        // Set expiration date (refresh after 30 days)
        item.expirationDate = Date().addingTimeInterval(30 * 24 * 60 * 60)

        return item
    }

    private func createSearchableItem(for transaction: Transaction) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        // Basic attributes
        attributeSet.title = transaction.title
        attributeSet.contentDescription = transaction.subtitle

        // Transaction-specific metadata
        let amountText = String(format: "%@$%.2f", transaction.isExpense ? "-" : "+", abs(transaction.amount))
        attributeSet.contentDescription = "\(transaction.subtitle) • \(amountText) • \(transaction.category.rawValue)"

        // Keywords for better search
        var keywords = [
            "transaction",
            transaction.title,
            transaction.subtitle,
            transaction.category.rawValue,
            amountText,
            transaction.isExpense ? "expense" : "income"
        ]

        // Add tags as keywords
        keywords.append(contentsOf: transaction.tags)

        // Add payment status
        keywords.append(transaction.paymentStatus.rawValue)

        attributeSet.keywords = keywords

        // Dates
        attributeSet.contentCreationDate = transaction.date
        attributeSet.contentModificationDate = transaction.date

        // Rating based on recency
        let daysSinceTransaction = Calendar.current.dateComponents([.day], from: transaction.date, to: Date()).day ?? 0
        let rating = max(1, 5 - (daysSinceTransaction / 7)) // Decrease rating over time
        attributeSet.rating = NSNumber(value: rating)

        let item = CSSearchableItem(
            uniqueIdentifier: transactionIdentifier(transaction.id),
            domainIdentifier: transactionDomainIdentifier,
            attributeSet: attributeSet
        )

        // Set expiration date (keep for 90 days)
        item.expirationDate = transaction.date.addingTimeInterval(90 * 24 * 60 * 60)

        return item
    }

    // MARK: - Private Methods - Indexing Operations

    private func indexItems(_ items: [CSSearchableItem]) async {
        do {
            try await CSSearchableIndex.default().indexSearchableItems(items)
        } catch {
            print("SpotlightIndexingService: Error indexing items - \(error.localizedDescription)")
        }
    }

    private func removeItems(withIdentifiers identifiers: [String]) async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: identifiers)
        } catch {
            print("SpotlightIndexingService: Error removing items - \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods - Identifier Generation

    private func personIdentifier(_ id: UUID) -> String {
        return "person-\(id.uuidString)"
    }

    private func subscriptionIdentifier(_ id: UUID) -> String {
        return "subscription-\(id.uuidString)"
    }

    private func transactionIdentifier(_ id: UUID) -> String {
        return "transaction-\(id.uuidString)"
    }

    // MARK: - Public Methods - Result Handling

    /// Parse a Spotlight search result identifier and extract the entity type and ID
    static func parseSpotlightIdentifier(_ identifier: String) -> (type: String, id: UUID)? {
        let components = identifier.split(separator: "-")
        guard components.count == 6 else { return nil } // UUID has 5 parts plus type prefix

        let type = String(components[0])
        let uuidString = components.dropFirst().joined(separator: "-")

        guard let uuid = UUID(uuidString: uuidString) else { return nil }

        return (type: type, id: uuid)
    }
}

// MARK: - Spotlight Result Navigation

/// Helper struct for handling navigation from Spotlight results
struct SpotlightResultNavigation {
    enum EntityType: String {
        case person
        case subscription
        case transaction
    }

    let entityType: EntityType
    let entityId: UUID

    init?(from identifier: String) {
        guard let parsed = SpotlightIndexingService.parseSpotlightIdentifier(identifier) else {
            return nil
        }

        guard let type = EntityType(rawValue: parsed.type) else {
            return nil
        }

        self.entityType = type
        self.entityId = parsed.id
    }
}

// MARK: - DataManager Extension for Auto-Indexing

extension DataManager {
    /// Enable automatic Spotlight indexing when data changes
    func enableSpotlightIndexing() {
        // Index all existing content
        Task {
            await SpotlightIndexingService.shared.indexAllContent(
                people: people,
                subscriptions: subscriptions,
                transactions: transactions
            )
        }
    }

    /// Update Spotlight index after adding a person
    func indexPersonInSpotlight(_ person: Person) {
        Task {
            await SpotlightIndexingService.shared.indexPerson(person)
        }
    }

    /// Update Spotlight index after adding a subscription
    func indexSubscriptionInSpotlight(_ subscription: Subscription) {
        Task {
            await SpotlightIndexingService.shared.indexSubscription(subscription)
        }
    }

    /// Update Spotlight index after adding a transaction
    func indexTransactionInSpotlight(_ transaction: Transaction) {
        Task {
            await SpotlightIndexingService.shared.indexTransaction(transaction)
        }
    }

    /// Remove person from Spotlight index
    func removePersonFromSpotlight(_ personId: UUID) {
        Task {
            await SpotlightIndexingService.shared.removePerson(personId)
        }
    }

    /// Remove subscription from Spotlight index
    func removeSubscriptionFromSpotlight(_ subscriptionId: UUID) {
        Task {
            await SpotlightIndexingService.shared.removeSubscription(subscriptionId)
        }
    }

    /// Remove transaction from Spotlight index
    func removeTransactionFromSpotlight(_ transactionId: UUID) {
        Task {
            await SpotlightIndexingService.shared.removeTransaction(transactionId)
        }
    }
}
