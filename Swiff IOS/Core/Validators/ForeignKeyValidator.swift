//
//  ForeignKeyValidator.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 4.1: Foreign key validation and referential integrity
//

import Foundation
import SwiftData

// MARK: - Foreign Key Error

enum ForeignKeyError: LocalizedError {
    case personNotFound(UUID)
    case groupNotFound(UUID)
    case subscriptionNotFound(UUID)
    case transactionNotFound(UUID)
    case orphanedRecord(entityType: String, id: UUID)
    case cascadeDeleteFailed(entityType: String, reason: String)
    case invalidReference(from: String, to: String, id: UUID)
    case multipleReferencesExist(entityType: String, count: Int)

    var errorDescription: String? {
        switch self {
        case .personNotFound(let id):
            return "Person with ID '\(id)' not found"
        case .groupNotFound(let id):
            return "Group with ID '\(id)' not found"
        case .subscriptionNotFound(let id):
            return "Subscription with ID '\(id)' not found"
        case .transactionNotFound(let id):
            return "Transaction with ID '\(id)' not found"
        case .orphanedRecord(let entityType, let id):
            return "Orphaned \(entityType) record found with ID '\(id)'"
        case .cascadeDeleteFailed(let entityType, let reason):
            return "Failed to cascade delete \(entityType): \(reason)"
        case .invalidReference(let from, let to, let id):
            return "Invalid reference from \(from) to \(to) with ID '\(id)'"
        case .multipleReferencesExist(let entityType, let count):
            return "Cannot delete: \(count) \(entityType) records still reference this entity"
        }
    }
}

// MARK: - Cascade Rule

enum CascadeRule {
    case restrict  // Prevent deletion if references exist
    case cascade   // Delete all dependent records
    case setNull   // Set foreign key to null
    case ignore    // No action (dangerous - use with caution)
}

// MARK: - Reference Info

struct ReferenceInfo {
    let entityType: String
    let entityId: UUID
    let referencedEntityType: String
    let referencedEntityId: UUID
    let fieldName: String
}

// MARK: - Orphan Detection Result

struct OrphanDetectionResult {
    let orphanedRecords: [ReferenceInfo]
    let totalOrphans: Int

    var hasOrphans: Bool {
        return totalOrphans > 0
    }

    var summary: String {
        if hasOrphans {
            return "Found \(totalOrphans) orphaned record(s)"
        } else {
            return "No orphaned records found"
        }
    }
}

// MARK: - Foreign Key Validator

@MainActor
class ForeignKeyValidator {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Person Validation

    /// Validate that a person exists
    func validatePersonExists(_ personId: UUID) throws {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate<PersonModel> { person in
                person.id == personId
            }
        )

        let results = try modelContext.fetch(descriptor)
        guard !results.isEmpty else {
            throw ForeignKeyError.personNotFound(personId)
        }
    }

    /// Validate multiple person IDs exist
    func validatePersonsExist(_ personIds: [UUID]) throws {
        for personId in personIds {
            try validatePersonExists(personId)
        }
    }

    /// Get person or throw error
    func getPerson(_ personId: UUID) throws -> PersonModel {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate<PersonModel> { person in
                person.id == personId
            }
        )

        let results = try modelContext.fetch(descriptor)
        guard let person = results.first else {
            throw ForeignKeyError.personNotFound(personId)
        }

        return person
    }

    // MARK: - Group Validation

    /// Validate that a group exists
    func validateGroupExists(_ groupId: UUID) throws {
        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate<GroupModel> { group in
                group.id == groupId
            }
        )

        let results = try modelContext.fetch(descriptor)
        guard !results.isEmpty else {
            throw ForeignKeyError.groupNotFound(groupId)
        }
    }

    /// Get group or throw error
    func getGroup(_ groupId: UUID) throws -> GroupModel {
        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate<GroupModel> { group in
                group.id == groupId
            }
        )

        let results = try modelContext.fetch(descriptor)
        guard let group = results.first else {
            throw ForeignKeyError.groupNotFound(groupId)
        }

        return group
    }

    // MARK: - Subscription Validation

    /// Validate that a subscription exists
    func validateSubscriptionExists(_ subscriptionId: UUID) throws {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate<SubscriptionModel> { subscription in
                subscription.id == subscriptionId
            }
        )

        let results = try modelContext.fetch(descriptor)
        guard !results.isEmpty else {
            throw ForeignKeyError.subscriptionNotFound(subscriptionId)
        }
    }

    /// Get subscription or throw error
    func getSubscription(_ subscriptionId: UUID) throws -> SubscriptionModel {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate<SubscriptionModel> { subscription in
                subscription.id == subscriptionId
            }
        )

        let results = try modelContext.fetch(descriptor)
        guard let subscription = results.first else {
            throw ForeignKeyError.subscriptionNotFound(subscriptionId)
        }

        return subscription
    }

    // MARK: - Orphan Detection

    /// Detect orphaned subscriptions (person deleted but subscriptions remain)
    func detectOrphanedSubscriptions() throws -> OrphanDetectionResult {
        var orphans: [ReferenceInfo] = []

        // Get all subscriptions
        let subscriptionDescriptor = FetchDescriptor<SubscriptionModel>()
        let subscriptions = try modelContext.fetch(subscriptionDescriptor)

        // Get all valid person IDs
        let personDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(personDescriptor)
        let validPersonIds = Set(people.map { $0.id })

        // Check each subscription
        for subscription in subscriptions {
            if let personId = subscription.personId, !validPersonIds.contains(personId) {
                let info = ReferenceInfo(
                    entityType: "Subscription",
                    entityId: subscription.id,
                    referencedEntityType: "Person",
                    referencedEntityId: personId,
                    fieldName: "personId"
                )
                orphans.append(info)
            }
        }

        return OrphanDetectionResult(
            orphanedRecords: orphans,
            totalOrphans: orphans.count
        )
    }

    /// Detect orphaned transactions (person deleted but transactions remain)
    func detectOrphanedTransactions() throws -> OrphanDetectionResult {
        var orphans: [ReferenceInfo] = []

        // Get all transactions
        let transactionDescriptor = FetchDescriptor<TransactionModel>()
        let transactions = try modelContext.fetch(transactionDescriptor)

        // Get all valid person IDs
        let personDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(personDescriptor)
        let validPersonIds = Set(people.map { $0.id })

        // Check each transaction
        for transaction in transactions {
            // Check payer
            if let payerId = transaction.payerId, !validPersonIds.contains(payerId) {
                let info = ReferenceInfo(
                    entityType: "Transaction",
                    entityId: transaction.id,
                    referencedEntityType: "Person",
                    referencedEntityId: payerId,
                    fieldName: "payerId"
                )
                orphans.append(info)
            }

            // Check payee
            if let payeeId = transaction.payeeId, !validPersonIds.contains(payeeId) {
                let info = ReferenceInfo(
                    entityType: "Transaction",
                    entityId: transaction.id,
                    referencedEntityType: "Person",
                    referencedEntityId: payeeId,
                    fieldName: "payeeId"
                )
                orphans.append(info)
            }
        }

        return OrphanDetectionResult(
            orphanedRecords: orphans,
            totalOrphans: orphans.count
        )
    }

    /// Detect all orphaned records
    func detectAllOrphans() throws -> OrphanDetectionResult {
        let subscriptionOrphans = try detectOrphanedSubscriptions()
        let transactionOrphans = try detectOrphanedTransactions()

        let allOrphans = subscriptionOrphans.orphanedRecords + transactionOrphans.orphanedRecords

        return OrphanDetectionResult(
            orphanedRecords: allOrphans,
            totalOrphans: allOrphans.count
        )
    }

    // MARK: - Reference Counting

    /// Count how many subscriptions reference a person
    func countSubscriptions(forPerson personId: UUID) throws -> Int {
        let subscriptions = try modelContext.fetch(FetchDescriptor<SubscriptionModel>())
        return subscriptions.filter { $0.personId == personId }.count
    }

    /// Count how many transactions reference a person
    func countTransactions(forPerson personId: UUID) throws -> Int {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate<TransactionModel> { transaction in
                transaction.payerId == personId || transaction.payeeId == personId
            }
        )

        let transactions = try modelContext.fetch(descriptor)
        return transactions.count
    }

    /// Count total references to a person
    func countReferences(forPerson personId: UUID) throws -> Int {
        let subscriptionCount = try countSubscriptions(forPerson: personId)
        let transactionCount = try countTransactions(forPerson: personId)

        return subscriptionCount + transactionCount
    }

    // MARK: - Cascade Delete

    /// Delete person with cascade rule
    func deletePerson(_ personId: UUID, cascadeRule: CascadeRule = .restrict) throws {
        // First, validate person exists
        let person = try getPerson(personId)

        // Check for references
        let referenceCount = try countReferences(forPerson: personId)

        switch cascadeRule {
        case .restrict:
            // Prevent deletion if references exist
            guard referenceCount == 0 else {
                throw ForeignKeyError.multipleReferencesExist(
                    entityType: "dependent",
                    count: referenceCount
                )
            }

            modelContext.delete(person)

        case .cascade:
            // Delete all dependent records first
            try deleteDependentRecords(forPerson: personId)

            // Then delete the person
            modelContext.delete(person)

        case .setNull:
            // Not applicable for required foreign keys
            // Would need to modify schema to support optional foreign keys
            throw ForeignKeyError.cascadeDeleteFailed(
                entityType: "Person",
                reason: "SetNull not supported for required foreign keys"
            )

        case .ignore:
            // Just delete, leaving orphans (dangerous!)
            modelContext.delete(person)
        }

        try modelContext.save()
    }

    /// Delete all dependent records for a person
    private func deleteDependentRecords(forPerson personId: UUID) throws {
        // Delete subscriptions
        let subscriptions = try modelContext.fetch(FetchDescriptor<SubscriptionModel>())
        for subscription in subscriptions where subscription.personId == personId {
            modelContext.delete(subscription)
        }

        // Delete transactions
        let transactions = try modelContext.fetch(FetchDescriptor<TransactionModel>())
        for transaction in transactions where transaction.payerId == personId || transaction.payeeId == personId {
            modelContext.delete(transaction)
        }
    }

    // MARK: - Orphan Cleanup

    /// Clean up orphaned subscriptions
    func cleanupOrphanedSubscriptions() throws -> Int {
        let result = try detectOrphanedSubscriptions()

        guard result.hasOrphans else {
            return 0
        }

        // Delete orphaned subscriptions
        for orphan in result.orphanedRecords {
            // Capture the ID in a local constant for the predicate
            let targetId = orphan.entityId
            let descriptor = FetchDescriptor<SubscriptionModel>(
                predicate: #Predicate<SubscriptionModel> { subscription in
                    subscription.id == targetId
                }
            )

            if let subscription = try modelContext.fetch(descriptor).first {
                modelContext.delete(subscription)
            }
        }

        try modelContext.save()

        return result.totalOrphans
    }

    /// Clean up orphaned transactions
    func cleanupOrphanedTransactions() throws -> Int {
        let result = try detectOrphanedTransactions()

        guard result.hasOrphans else {
            return 0
        }

        // Delete orphaned transactions
        for orphan in result.orphanedRecords {
            // Capture the ID in a local constant for the predicate
            let targetId = orphan.entityId
            let descriptor = FetchDescriptor<TransactionModel>(
                predicate: #Predicate<TransactionModel> { transaction in
                    transaction.id == targetId
                }
            )

            if let transaction = try modelContext.fetch(descriptor).first {
                modelContext.delete(transaction)
            }
        }

        try modelContext.save()

        return result.totalOrphans
    }

    /// Clean up all orphaned records
    func cleanupAllOrphans() throws -> Int {
        let subscriptionsCleaned = try cleanupOrphanedSubscriptions()
        let transactionsCleaned = try cleanupOrphanedTransactions()

        return subscriptionsCleaned + transactionsCleaned
    }

    // MARK: - Validation Helpers

    /// Validate before creating a subscription
    func validateSubscriptionCreation(personId: UUID) throws {
        try validatePersonExists(personId)
    }

    /// Validate before creating a transaction
    func validateTransactionCreation(payerId: UUID, payeeId: UUID) throws {
        try validatePersonExists(payerId)
        try validatePersonExists(payeeId)
    }

    /// Comprehensive validation of all foreign keys
    func validateAllForeignKeys() throws -> [String] {
        var errors: [String] = []

        // Check for orphaned subscriptions
        let subscriptionOrphans = try detectOrphanedSubscriptions()
        if subscriptionOrphans.hasOrphans {
            errors.append("Found \(subscriptionOrphans.totalOrphans) orphaned subscription(s)")
        }

        // Check for orphaned transactions
        let transactionOrphans = try detectOrphanedTransactions()
        if transactionOrphans.hasOrphans {
            errors.append("Found \(transactionOrphans.totalOrphans) orphaned transaction(s)")
        }

        return errors
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Validate person exists before creating subscription:
 ```swift
 let validator = ForeignKeyValidator(modelContext: context)

 do {
     try validator.validatePersonExists(personId)
     // Safe to create subscription
 } catch ForeignKeyError.personNotFound(let id) {
     print("Person not found: \(id)")
 }
 ```

 2. Delete person with cascade:
 ```swift
 do {
     // This will delete the person and all dependent records
     try validator.deletePerson(personId, cascadeRule: .cascade)
 } catch {
     print("Delete failed: \(error)")
 }
 ```

 3. Detect orphaned records:
 ```swift
 let result = try validator.detectAllOrphans()

 if result.hasOrphans {
     print(result.summary)

     for orphan in result.orphanedRecords {
         print("Orphan: \(orphan.entityType) [\(orphan.entityId)]")
         print("  References: \(orphan.referencedEntityType) [\(orphan.referencedEntityId)]")
     }
 }
 ```

 4. Clean up orphans:
 ```swift
 let cleanedCount = try validator.cleanupAllOrphans()
 print("Cleaned up \(cleanedCount) orphaned record(s)")
 ```

 5. Count references before delete:
 ```swift
 let refCount = try validator.countReferences(forPerson: personId)

 if refCount > 0 {
     print("Warning: This person has \(refCount) dependent record(s)")
     // Ask user for confirmation
 }
 ```
 */
