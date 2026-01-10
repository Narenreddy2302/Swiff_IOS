//
//  PersistenceService.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Comprehensive data service layer for SwiftData persistence
//

import Combine
import Foundation
import SwiftData

// MARK: - Persistence Errors
// Note: Schema versioning and migration plan are defined in MigrationPlanV1toV2.swift

enum PersistenceError: LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case entityNotFound(id: UUID)
    case validationFailed(reason: String)
    case contextError
    case relationshipError(reason: String)
    case migrationFailed(underlying: Error)
    case containerCreationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .entityNotFound(let id):
            return "Entity with ID \(id) not found"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .contextError:
            return "SwiftData context error"
        case .relationshipError(let reason):
            return "Relationship error: \(reason)"
        case .migrationFailed(let error):
            return "Data migration failed: \(error.localizedDescription)"
        case .containerCreationFailed(let error):
            return "Failed to create model container: \(error.localizedDescription)"
        }
    }
}

// MARK: - Persistence Service

@MainActor
public class PersistenceService {
    // MARK: - Singleton

    public static let shared = PersistenceService()

    // Public access to model container for app-wide use
    private(set) var modelContainer: ModelContainer!

    private var modelContext: ModelContext {
        return modelContainer.mainContext
    }

    // Track initialization state
    private(set) var isInitialized: Bool = false
    private(set) var initializationError: Error?

    // MARK: - Schema Definition (Single Source of Truth)

    static let appSchema = Schema([
        PersonModel.self,
        GroupModel.self,
        GroupExpenseModel.self,
        SubscriptionModel.self,
        SharedSubscriptionModel.self,
        TransactionModel.self,
        PriceChangeModel.self,
        SplitBillModel.self,
        AccountModel.self,
    ])

    // MARK: - Initialization

    private init() {
        // Perform synchronous initialization with schema mismatch detection
        do {
            self.modelContainer = try Self.createModelContainer()
            self.isInitialized = true
            print("✅ PersistenceService initialized successfully")
        } catch {
            print("❌ Failed to initialize PersistenceService: \(error)")

            // Check if this is a schema mismatch error
            if Self.isSchemaError(error) {
                print("⚠️ Schema mismatch detected - attempting database reset")

                // Delete old database file
                Self.deleteDatabase()

                // Retry with clean database
                do {
                    self.modelContainer = try Self.createModelContainer()
                    self.isInitialized = true
                    print("✅ Database reset successful - PersistenceService initialized")
                } catch {
                    print("❌ CRITICAL: Failed to initialize even after database reset: \(error)")
                    self.initializationError = error
                    // Create in-memory fallback
                    self.modelContainer = try! Self.createInMemoryContainer()
                    self.isInitialized = true
                    print("⚠️ Using in-memory database - data will not persist")
                }
            } else {
                self.initializationError = error
                // Create in-memory fallback
                self.modelContainer = try! Self.createInMemoryContainer()
                self.isInitialized = true
                print("⚠️ Using in-memory database - data will not persist")
            }
        }
    }

    // MARK: - Helper Methods

    /// Create the persistent ModelContainer
    private static func createModelContainer() throws -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(
            for: appSchema,
            configurations: [modelConfiguration]
        )
    }

    /// Create an in-memory ModelContainer as fallback
    private static func createInMemoryContainer() throws -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: appSchema,
            configurations: [modelConfiguration]
        )
    }

    /// Check if error is related to schema mismatch
    private static func isSchemaError(_ error: Error) -> Bool {
        let errorDescription = error.localizedDescription.lowercased()
        return errorDescription.contains("schema") || errorDescription.contains("model")
            || errorDescription.contains("metadata") || errorDescription.contains("reflection")
    }

    /// Delete the database file from disk
    private static func deleteDatabase() {
        let fileManager = FileManager.default
        guard
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            print("⚠️ Could not locate documents directory")
            return
        }

        let dbPath = documentsPath.appendingPathComponent("default.store")
        let dbShmPath = documentsPath.appendingPathComponent("default.store-shm")
        let dbWalPath = documentsPath.appendingPathComponent("default.store-wal")

        // Delete all database files
        try? fileManager.removeItem(at: dbPath)
        try? fileManager.removeItem(at: dbShmPath)
        try? fileManager.removeItem(at: dbWalPath)

        print("🗑️ Deleted old database files")
    }

    /// Reset database manually (for development/testing)
    func resetDatabase() {
        print("🗑️ Manually resetting database...")

        Self.deleteDatabase()

        // Reinitialize
        do {
            self.modelContainer = try Self.createModelContainer()
            self.isInitialized = true
            self.initializationError = nil
            print("✅ Database reset complete")
        } catch {
            print("❌ Failed to reinitialize after reset: \(error)")
            self.modelContainer = try! Self.createInMemoryContainer()
            self.initializationError = error
        }
    }

    /// Initialize with custom container (for testing)
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Person Operations

    func savePerson(_ person: Person) throws {
        try validatePerson(person)

        // Check if person already exists
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == person.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingPerson = existing {
                // Update existing person - basic fields
                existingPerson.name = person.name
                existingPerson.email = person.email
                existingPerson.phone = person.phone
                existingPerson.balance = person.balance
                existingPerson.lastModifiedDate = Date()

                // Update avatar
                switch person.avatarType {
                case .photo(let data):
                    existingPerson.avatarTypeRaw = "photo"
                    existingPerson.avatarData = data
                    existingPerson.avatarEmoji = nil
                    existingPerson.avatarInitials = nil
                case .emoji(let emoji):
                    existingPerson.avatarTypeRaw = "emoji"
                    existingPerson.avatarData = nil
                    existingPerson.avatarEmoji = emoji
                    existingPerson.avatarInitials = nil
                case .initials(let initials, let colorIndex):
                    existingPerson.avatarTypeRaw = "initials"
                    existingPerson.avatarData = nil
                    existingPerson.avatarEmoji = nil
                    existingPerson.avatarInitials = initials
                    existingPerson.avatarColorIndex = colorIndex
                case .contactPhoto:
                    existingPerson.avatarTypeRaw = "contact_photo"
                    existingPerson.avatarData = nil
                    existingPerson.avatarEmoji = nil
                    existingPerson.avatarInitials = nil
                }

                // Update additional fields
                existingPerson.contactId = person.contactId
                existingPerson.preferredPaymentMethodRaw = person.preferredPaymentMethod?.rawValue
                existingPerson.relationshipType = person.relationshipType
                existingPerson.personNotes = person.notes
                existingPerson.personSourceRaw = person.personSource.rawValue

                // Update notification preferences
                if let encoded = try? JSONEncoder().encode(person.notificationPreferences) {
                    existingPerson.notificationPreferencesData = encoded
                }
            } else {
                // Create new person
                let personModel = PersonModel(from: person)
                modelContext.insert(personModel)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchAllPeople() throws -> [Person] {
        let descriptor = FetchDescriptor<PersonModel>(
            sortBy: [SortDescriptor(\PersonModel.name, order: .forward)]
        )

        do {
            let people = try modelContext.fetch(descriptor)
            return people.map { $0.toDomain() }
        } catch {
            print("❌ Error fetching people: \(error)")
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchPerson(byID id: UUID) throws -> Person? {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func updatePerson(_ person: Person) throws {
        try validatePerson(person)

        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == person.id }
        )

        do {
            guard let existingPerson = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: person.id)
            }

            // Update basic fields
            existingPerson.name = person.name
            existingPerson.email = person.email
            existingPerson.phone = person.phone
            existingPerson.balance = person.balance
            existingPerson.lastModifiedDate = Date()

            // Update avatar
            switch person.avatarType {
            case .photo(let data):
                existingPerson.avatarTypeRaw = "photo"
                existingPerson.avatarData = data
                existingPerson.avatarEmoji = nil
                existingPerson.avatarInitials = nil
            case .emoji(let emoji):
                existingPerson.avatarTypeRaw = "emoji"
                existingPerson.avatarData = nil
                existingPerson.avatarEmoji = emoji
                existingPerson.avatarInitials = nil
            case .initials(let initials, let colorIndex):
                existingPerson.avatarTypeRaw = "initials"
                existingPerson.avatarData = nil
                existingPerson.avatarEmoji = nil
                existingPerson.avatarInitials = initials
                existingPerson.avatarColorIndex = colorIndex
            case .contactPhoto:
                existingPerson.avatarTypeRaw = "contact_photo"
                existingPerson.avatarData = nil
                existingPerson.avatarEmoji = nil
                existingPerson.avatarInitials = nil
            }

            // Update additional fields
            existingPerson.contactId = person.contactId
            existingPerson.preferredPaymentMethodRaw = person.preferredPaymentMethod?.rawValue
            existingPerson.relationshipType = person.relationshipType
            existingPerson.personNotes = person.notes
            existingPerson.personSourceRaw = person.personSource.rawValue

            // Update notification preferences
            if let encoded = try? JSONEncoder().encode(person.notificationPreferences) {
                existingPerson.notificationPreferencesData = encoded
            }

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    func deletePerson(id: UUID) throws {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let person = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(person)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func fetchPeopleWithBalances() throws -> [Person] {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.balance != 0 }
        )

        do {
            let people = try modelContext.fetch(descriptor)
            return people.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func searchPeople(byName searchTerm: String) throws -> [Person] {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { person in
                person.name.localizedStandardContains(searchTerm)
            }
        )

        do {
            let people = try modelContext.fetch(descriptor)
            return people.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Subscription Operations

    func saveSubscription(_ subscription: Subscription) throws {
        try validateSubscription(subscription)

        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == subscription.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingSub = existing {
                // Update existing subscription
                existingSub.name = subscription.name
                existingSub.subscriptionDescription = subscription.description
                existingSub.price = subscription.price
                existingSub.billingCycleRaw = subscription.billingCycle.rawValue
                existingSub.categoryRaw = subscription.category.rawValue
                existingSub.icon = subscription.icon
                existingSub.color = subscription.color
                existingSub.nextBillingDate = subscription.nextBillingDate
                existingSub.isActive = subscription.isActive
                existingSub.isShared = subscription.isShared
                existingSub.sharedWithIDs = subscription.sharedWith
                existingSub.notes = subscription.notes
                existingSub.website = subscription.website
                existingSub.totalSpent = subscription.totalSpent
            } else {
                // Create new subscription
                let subscriptionModel = SubscriptionModel(from: subscription)
                modelContext.insert(subscriptionModel)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchAllSubscriptions() throws -> [Subscription] {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            sortBy: [SortDescriptor(\SubscriptionModel.name, order: .forward)]
        )

        do {
            let subscriptions = try modelContext.fetch(descriptor)
            return subscriptions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchSubscription(byID id: UUID) throws -> Subscription? {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func updateSubscription(_ subscription: Subscription) throws {
        try validateSubscription(subscription)

        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == subscription.id }
        )

        do {
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: subscription.id)
            }

            existing.name = subscription.name
            existing.price = subscription.price
            existing.isActive = subscription.isActive

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    func deleteSubscription(id: UUID) throws {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let subscription = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(subscription)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func fetchActiveSubscriptions() throws -> [Subscription] {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.isActive == true }
        )

        do {
            let subscriptions = try modelContext.fetch(descriptor)
            return subscriptions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchSubscriptionsRenewingSoon(days: Int) throws -> [Subscription] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now

        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { subscription in
                subscription.isActive && subscription.nextBillingDate >= now
                    && subscription.nextBillingDate <= futureDate
            }
        )

        do {
            let subscriptions = try modelContext.fetch(descriptor)
            return subscriptions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Shared Subscription Operations

    func saveSharedSubscription(_ sharedSubscription: SharedSubscription) throws {
        let descriptor = FetchDescriptor<SharedSubscriptionModel>(
            predicate: #Predicate { $0.id == sharedSubscription.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingShared = existing {
                // Update existing shared subscription
                existingShared.subscriptionID = sharedSubscription.subscriptionId
                existingShared.sharedByID = sharedSubscription.sharedBy
                existingShared.sharedWithIDs = sharedSubscription.sharedWith
                existingShared.costSplitRaw = sharedSubscription.costSplit.rawValue
                existingShared.individualCost = sharedSubscription.individualCost
                existingShared.isAccepted = sharedSubscription.isAccepted
                existingShared.notes = sharedSubscription.notes
            } else {
                // Create new shared subscription
                let sharedModel = SharedSubscriptionModel(from: sharedSubscription)

                // Link to base subscription if exists
                let subDescriptor = FetchDescriptor<SubscriptionModel>(
                    predicate: #Predicate { $0.id == sharedSubscription.subscriptionId }
                )
                if let baseSubscription = try modelContext.fetch(subDescriptor).first {
                    sharedModel.subscription = baseSubscription
                }

                modelContext.insert(sharedModel)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchAllSharedSubscriptions() throws -> [SharedSubscription] {
        let descriptor = FetchDescriptor<SharedSubscriptionModel>(
            sortBy: [SortDescriptor(\SharedSubscriptionModel.createdDate, order: .reverse)]
        )

        do {
            let sharedSubscriptions = try modelContext.fetch(descriptor)
            return sharedSubscriptions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchSharedSubscription(byID id: UUID) throws -> SharedSubscription? {
        let descriptor = FetchDescriptor<SharedSubscriptionModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func updateSharedSubscription(_ sharedSubscription: SharedSubscription) throws {
        let descriptor = FetchDescriptor<SharedSubscriptionModel>(
            predicate: #Predicate { $0.id == sharedSubscription.id }
        )

        do {
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: sharedSubscription.id)
            }

            existing.sharedWithIDs = sharedSubscription.sharedWith
            existing.costSplitRaw = sharedSubscription.costSplit.rawValue
            existing.individualCost = sharedSubscription.individualCost
            existing.isAccepted = sharedSubscription.isAccepted
            existing.notes = sharedSubscription.notes

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    func deleteSharedSubscription(id: UUID) throws {
        let descriptor = FetchDescriptor<SharedSubscriptionModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let sharedSubscription = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(sharedSubscription)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func fetchSharedSubscriptionsForPerson(personId: UUID) throws -> [SharedSubscription] {
        // Fetch all and filter in memory since SwiftData predicates can't check array contains
        let descriptor = FetchDescriptor<SharedSubscriptionModel>()

        do {
            let allShared = try modelContext.fetch(descriptor)
            let filtered = allShared.filter { shared in
                shared.sharedByID == personId || shared.sharedWithIDs.contains(personId)
            }
            return filtered.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Transaction Operations

    func saveTransaction(_ transaction: Transaction) throws {
        try validateTransaction(transaction)

        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == transaction.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingTxn = existing {
                // Update existing transaction
                existingTxn.title = transaction.title
                existingTxn.subtitle = transaction.subtitle
                existingTxn.amount = transaction.amount
                existingTxn.categoryRaw = transaction.category.rawValue
                existingTxn.date = transaction.date
                existingTxn.isRecurring = transaction.isRecurring
                existingTxn.tags = transaction.tags
            } else {
                // Create new transaction
                let transactionModel = TransactionModel(from: transaction)
                modelContext.insert(transactionModel)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchAllTransactions() throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionModel>(
            sortBy: [SortDescriptor(\TransactionModel.date, order: .reverse)]
        )

        do {
            let transactions = try modelContext.fetch(descriptor)
            return transactions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchTransaction(byID id: UUID) throws -> Transaction? {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func updateTransaction(_ transaction: Transaction) throws {
        try validateTransaction(transaction)

        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == transaction.id }
        )

        do {
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: transaction.id)
            }

            existing.title = transaction.title
            existing.subtitle = transaction.subtitle
            existing.amount = transaction.amount
            existing.categoryRaw = transaction.category.rawValue

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    func deleteTransaction(id: UUID) throws {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let transaction = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(transaction)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func fetchTransactions(inDateRange range: ClosedRange<Date>) throws -> [Transaction] {
        let startDate = range.lowerBound
        let endDate = range.upperBound

        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            },
            sortBy: [SortDescriptor(\TransactionModel.date, order: .reverse)]
        )

        do {
            let transactions = try modelContext.fetch(descriptor)
            return transactions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchCurrentMonthTransactions() throws -> [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now))
        else {
            throw PersistenceError.validationFailed(reason: "Failed to calculate start of month")
        }

        guard
            let endOfMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else {
            throw PersistenceError.validationFailed(reason: "Failed to calculate end of month")
        }

        return try fetchTransactions(inDateRange: startOfMonth...endOfMonth)
    }

    func fetchRecurringTransactions() throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.isRecurring == true }
        )

        do {
            let transactions = try modelContext.fetch(descriptor)
            return transactions.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Group Operations

    func saveGroup(_ group: Group) throws {
        try validateGroup(group)

        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == group.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingGroup = existing {
                // Update existing group
                existingGroup.name = group.name
                existingGroup.groupDescription = group.description
                existingGroup.emoji = group.emoji
                existingGroup.totalAmount = group.totalAmount

                // Update members relationship
                let memberDescriptor = FetchDescriptor<PersonModel>(
                    predicate: #Predicate { person in
                        group.members.contains(person.id)
                    }
                )
                existingGroup.members = try modelContext.fetch(memberDescriptor)
            } else {
                // Create new group
                let groupModel = GroupModel(from: group, context: modelContext)
                modelContext.insert(groupModel)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchAllGroups() throws -> [Group] {
        let descriptor = FetchDescriptor<GroupModel>(
            sortBy: [SortDescriptor(\GroupModel.name, order: .forward)]
        )

        do {
            let groups = try modelContext.fetch(descriptor)
            return groups.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchGroup(byID id: UUID) throws -> Group? {
        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func updateGroup(_ group: Group) throws {
        try validateGroup(group)

        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == group.id }
        )

        do {
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: group.id)
            }

            existing.name = group.name
            existing.groupDescription = group.description
            existing.totalAmount = group.totalAmount

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    func deleteGroup(id: UUID) throws {
        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let group = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(group)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func fetchGroupsWithUnsettledExpenses() throws -> [Group] {
        let descriptor = FetchDescriptor<GroupModel>()

        do {
            let groups = try modelContext.fetch(descriptor)
            let groupsWithUnsettled = groups.filter { group in
                group.expenses.contains { !$0.isSettled }
            }
            return groupsWithUnsettled.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Group Expense Operations

    func saveGroupExpense(_ expense: GroupExpense, forGroup groupID: UUID) throws {
        try validateGroupExpense(expense)

        // Fetch the group
        let groupDescriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == groupID }
        )

        do {
            guard let group = try modelContext.fetch(groupDescriptor).first else {
                throw PersistenceError.entityNotFound(id: groupID)
            }

            // Check if expense already exists
            let expenseDescriptor = FetchDescriptor<GroupExpenseModel>(
                predicate: #Predicate { $0.id == expense.id }
            )

            let existing = try modelContext.fetch(expenseDescriptor).first

            if let existingExpense = existing {
                // Update existing expense
                existingExpense.title = expense.title
                existingExpense.amount = expense.amount
                existingExpense.categoryRaw = expense.category.rawValue
                existingExpense.notes = expense.notes
                existingExpense.isSettled = expense.isSettled
            } else {
                // Create new expense
                let expenseModel = GroupExpenseModel(from: expense, context: modelContext)
                expenseModel.group = group
                modelContext.insert(expenseModel)
            }

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchUnsettledExpenses() throws -> [GroupExpense] {
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate { $0.isSettled == false }
        )

        do {
            let expenses = try modelContext.fetch(descriptor)
            return expenses.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func settleExpense(id: UUID) throws {
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let expense = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            expense.isSettled = true
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    // MARK: - Split Bill Operations

    func saveSplitBill(_ splitBill: SplitBill) throws {
        let descriptor = FetchDescriptor<SplitBillModel>(
            predicate: #Predicate { $0.id == splitBill.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingSplitBill = existing {
                // Update existing split bill
                existingSplitBill.title = splitBill.title
                existingSplitBill.totalAmount = splitBill.totalAmount
                existingSplitBill.paidById = splitBill.paidById
                existingSplitBill.splitTypeRaw = splitBill.splitType.rawValue
                existingSplitBill.participantsData =
                    (try? JSONEncoder().encode(splitBill.participants)) ?? Data()
                existingSplitBill.notes = splitBill.notes
                existingSplitBill.categoryRaw = splitBill.category.rawValue
                existingSplitBill.date = splitBill.date
                existingSplitBill.groupId = splitBill.groupId
            } else {
                // Create new split bill
                let splitBillModel = SplitBillModel(from: splitBill)
                modelContext.insert(splitBillModel)

                // Set up relationships if applicable
                let payerDescriptor = FetchDescriptor<PersonModel>(
                    predicate: #Predicate { $0.id == splitBill.paidById }
                )
                if let payer = try? modelContext.fetch(payerDescriptor).first {
                    splitBillModel.paidBy = payer
                }

                if let groupId = splitBill.groupId {
                    let groupDescriptor = FetchDescriptor<GroupModel>(
                        predicate: #Predicate { $0.id == groupId }
                    )
                    if let group = try? modelContext.fetch(groupDescriptor).first {
                        splitBillModel.group = group
                    }
                }
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func updateSplitBill(_ splitBill: SplitBill) throws {
        let descriptor = FetchDescriptor<SplitBillModel>(
            predicate: #Predicate { $0.id == splitBill.id }
        )

        do {
            guard let existingSplitBill = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: splitBill.id)
            }

            // Update all fields
            existingSplitBill.title = splitBill.title
            existingSplitBill.totalAmount = splitBill.totalAmount
            existingSplitBill.paidById = splitBill.paidById
            existingSplitBill.splitTypeRaw = splitBill.splitType.rawValue
            existingSplitBill.participantsData =
                (try? JSONEncoder().encode(splitBill.participants)) ?? Data()
            existingSplitBill.notes = splitBill.notes
            existingSplitBill.categoryRaw = splitBill.category.rawValue
            existingSplitBill.date = splitBill.date
            existingSplitBill.groupId = splitBill.groupId

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    func deleteSplitBill(id: UUID) throws {
        let descriptor = FetchDescriptor<SplitBillModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let splitBill = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(splitBill)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func fetchAllSplitBills() throws -> [SplitBill] {
        let descriptor = FetchDescriptor<SplitBillModel>(
            sortBy: [SortDescriptor(\SplitBillModel.date, order: .reverse)]
        )

        do {
            let splitBills = try modelContext.fetch(descriptor)
            return splitBills.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchSplitBill(byID id: UUID) throws -> SplitBill? {
        let descriptor = FetchDescriptor<SplitBillModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchSplitBillsForPerson(personId: UUID) throws -> [SplitBill] {
        let descriptor = FetchDescriptor<SplitBillModel>(
            predicate: #Predicate { $0.paidById == personId },
            sortBy: [SortDescriptor(\SplitBillModel.date, order: .reverse)]
        )

        do {
            let splitBills = try modelContext.fetch(descriptor)
            return splitBills.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchSplitBillsForGroup(groupId: UUID) throws -> [SplitBill] {
        let descriptor = FetchDescriptor<SplitBillModel>(
            predicate: #Predicate { $0.groupId == groupId },
            sortBy: [SortDescriptor(\SplitBillModel.date, order: .reverse)]
        )

        do {
            let splitBills = try modelContext.fetch(descriptor)
            return splitBills.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Price Change Operations (AGENT 9)

    func savePriceChange(_ priceChange: PriceChange) throws {
        let descriptor = FetchDescriptor<PriceChangeModel>(
            predicate: #Predicate { $0.id == priceChange.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingChange = existing {
                // Update existing price change
                existingChange.oldPrice = priceChange.oldPrice
                existingChange.newPrice = priceChange.newPrice
                existingChange.changeDate = priceChange.changeDate
                existingChange.reason = priceChange.reason
                existingChange.detectedAutomatically = priceChange.detectedAutomatically
            } else {
                // Create new price change
                let priceChangeModel = PriceChangeModel(from: priceChange)
                modelContext.insert(priceChangeModel)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    func fetchAllPriceChanges() throws -> [PriceChange] {
        let descriptor = FetchDescriptor<PriceChangeModel>(
            sortBy: [SortDescriptor(\PriceChangeModel.changeDate, order: .reverse)]
        )

        do {
            let priceChanges = try modelContext.fetch(descriptor)
            return priceChanges.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchPriceChanges(forSubscription subscriptionId: UUID) throws -> [PriceChange] {
        let descriptor = FetchDescriptor<PriceChangeModel>(
            predicate: #Predicate { $0.subscriptionId == subscriptionId },
            sortBy: [SortDescriptor(\PriceChangeModel.changeDate, order: .reverse)]
        )

        do {
            let priceChanges = try modelContext.fetch(descriptor)
            return priceChanges.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func fetchRecentPriceIncreases(days: Int = 30) throws -> [PriceChange] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<PriceChangeModel>(
            predicate: #Predicate { change in
                change.changeDate >= cutoffDate && change.newPrice > change.oldPrice
            },
            sortBy: [SortDescriptor(\PriceChangeModel.changeDate, order: .reverse)]
        )

        do {
            let priceChanges = try modelContext.fetch(descriptor)
            return priceChanges.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    func deletePriceChange(id: UUID) throws {
        let descriptor = FetchDescriptor<PriceChangeModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let priceChange = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(priceChange)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    func deletePriceChanges(forSubscription subscriptionId: UUID) throws {
        let descriptor = FetchDescriptor<PriceChangeModel>(
            predicate: #Predicate { $0.subscriptionId == subscriptionId }
        )

        do {
            let priceChanges = try modelContext.fetch(descriptor)
            for priceChange in priceChanges {
                modelContext.delete(priceChange)
            }
            try saveContext()
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Context Management

    func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    /// Perform background task with a new context
    func performBackgroundTask<T>(_ block: @escaping @Sendable (ModelContext) throws -> T)
        async throws -> T
    {
        guard let container = modelContainer else {
            throw PersistenceError.contextError
        }

        let backgroundContext = ModelContext(container)

        return try await Task.detached {
            do {
                let result = try block(backgroundContext)
                try backgroundContext.save()
                return result
            } catch {
                throw PersistenceError.saveFailed(underlying: error)
            }
        }.value
    }

    // MARK: - Validation Methods

    private func validatePerson(_ person: Person) throws {
        // Name is always required
        guard !person.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PersistenceError.validationFailed(reason: "Person name cannot be empty")
        }

        // Email is optional - but if provided, must be valid format
        // This allows importing contacts who only have phone numbers
        let trimmedEmail = person.email.trimmingCharacters(in: .whitespaces)
        if !trimmedEmail.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailPredicate.evaluate(with: trimmedEmail) else {
                throw PersistenceError.validationFailed(reason: "Invalid email format")
            }
        }
    }

    private func validateSubscription(_ subscription: Subscription) throws {
        guard !subscription.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PersistenceError.validationFailed(reason: "Subscription name cannot be empty")
        }

        guard subscription.price > 0 else {
            throw PersistenceError.validationFailed(
                reason: "Subscription price must be greater than 0")
        }
    }

    private func validateTransaction(_ transaction: Transaction) throws {
        guard !transaction.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PersistenceError.validationFailed(reason: "Transaction title cannot be empty")
        }

        guard transaction.amount != 0 else {
            throw PersistenceError.validationFailed(reason: "Transaction amount cannot be 0")
        }
    }

    private func validateGroup(_ group: Group) throws {
        guard !group.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PersistenceError.validationFailed(reason: "Group name cannot be empty")
        }

        guard !group.members.isEmpty else {
            throw PersistenceError.validationFailed(reason: "Group must have at least one member")
        }
    }

    private func validateGroupExpense(_ expense: GroupExpense) throws {
        guard !expense.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PersistenceError.validationFailed(reason: "Expense title cannot be empty")
        }

        guard expense.amount > 0 else {
            throw PersistenceError.validationFailed(reason: "Expense amount must be greater than 0")
        }

        guard !expense.splitBetween.isEmpty else {
            throw PersistenceError.validationFailed(
                reason: "Expense must be split between at least one person")
        }
    }

    // MARK: - Statistics and Analytics

    func calculateTotalMonthlyCost() throws -> Double {
        let activeSubscriptions = try fetchActiveSubscriptions()

        return activeSubscriptions.reduce(0.0) { total, subscription in
            let monthlyEquivalent: Double

            switch subscription.billingCycle {
            case .daily: monthlyEquivalent = subscription.price * 30
            case .weekly: monthlyEquivalent = subscription.price * 4.33
            case .biweekly: monthlyEquivalent = subscription.price * 2.17
            case .monthly: monthlyEquivalent = subscription.price
            case .quarterly: monthlyEquivalent = subscription.price / 3
            case .semiAnnually: monthlyEquivalent = subscription.price / 6
            case .yearly, .annually: monthlyEquivalent = subscription.price / 12
            case .lifetime: monthlyEquivalent = 0
            }

            return total + monthlyEquivalent
        }
    }

    func calculateMonthlyIncome() throws -> Double {
        let currentMonthTransactions = try fetchCurrentMonthTransactions()
        let income = currentMonthTransactions.filter { $0.amount > 0 }
        return income.reduce(0.0) { $0 + $1.amount }
    }

    func calculateMonthlyExpenses() throws -> Double {
        let currentMonthTransactions = try fetchCurrentMonthTransactions()
        let expenses = currentMonthTransactions.filter { $0.amount < 0 }
        return abs(expenses.reduce(0.0) { $0 + $1.amount })
    }

    // MARK: - Account Operations

    /// Save a new account or update existing
    func saveAccount(_ account: Account) throws {
        try validateAccount(account)

        let descriptor = FetchDescriptor<AccountModel>(
            predicate: #Predicate { $0.id == account.id }
        )

        do {
            let existing = try modelContext.fetch(descriptor).first

            if let existingAccount = existing {
                // Update existing account
                existingAccount.update(from: account)
            } else {
                // Create new account
                let accountModel = AccountModel(from: account)
                modelContext.insert(accountModel)
            }

            // If this account is set as default, unset other defaults
            if account.isDefault {
                try setDefaultAccount(id: account.id)
            }

            try saveContext()
        } catch {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }

    /// Fetch all accounts
    func fetchAllAccounts() throws -> [Account] {
        let descriptor = FetchDescriptor<AccountModel>(
            sortBy: [SortDescriptor(\AccountModel.name, order: .forward)]
        )

        do {
            let accounts = try modelContext.fetch(descriptor)
            return accounts.map { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    /// Fetch account by ID
    func fetchAccount(byID id: UUID) throws -> Account? {
        let descriptor = FetchDescriptor<AccountModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    /// Update an existing account
    func updateAccount(_ account: Account) throws {
        try validateAccount(account)

        let descriptor = FetchDescriptor<AccountModel>(
            predicate: #Predicate { $0.id == account.id }
        )

        do {
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: account.id)
            }

            existing.update(from: account)

            // If this account is set as default, unset other defaults
            if account.isDefault {
                try setDefaultAccount(id: account.id)
            }

            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    /// Delete an account
    func deleteAccount(id: UUID) throws {
        let descriptor = FetchDescriptor<AccountModel>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            guard let account = try modelContext.fetch(descriptor).first else {
                throw PersistenceError.entityNotFound(id: id)
            }

            modelContext.delete(account)
            try saveContext()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.deleteFailed(underlying: error)
        }
    }

    /// Get the default account
    func fetchDefaultAccount() throws -> Account? {
        let descriptor = FetchDescriptor<AccountModel>(
            predicate: #Predicate { $0.isDefault == true }
        )

        do {
            return try modelContext.fetch(descriptor).first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(underlying: error)
        }
    }

    /// Set an account as the default (unsets all others)
    private func setDefaultAccount(id: UUID) throws {
        let allAccountsDescriptor = FetchDescriptor<AccountModel>()

        do {
            let allAccounts = try modelContext.fetch(allAccountsDescriptor)
            for account in allAccounts {
                account.isDefault = (account.id == id)
            }
        } catch {
            throw PersistenceError.updateFailed(underlying: error)
        }
    }

    /// Validate account data
    private func validateAccount(_ account: Account) throws {
        guard !account.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PersistenceError.validationFailed(reason: "Account name cannot be empty")
        }
    }
}
