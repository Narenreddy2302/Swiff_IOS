//
//  MigrationPlanV1toV2.swift
//  Swiff IOS
//
//  Created by Agent 13 - Data Model Enhancements
//  Migration plan from Schema V1 to Schema V2
//

import Foundation
import SwiftData

/// Migration Plan for Swiff iOS Database
///
/// This plan defines all schema versions and migration stages for the app.
/// Currently supports migration from V1 (base) to V2 (enhanced models).
enum SwiffMigrationPlan: SchemaMigrationPlan {

    /// All schema versions in chronological order
    static var schemas: [any VersionedSchema.Type] {
        [
            SwiffSchemaV1.self,
            SchemaV2.self
        ]
    }

    /// Migration stages between versions
    static var stages: [MigrationStage] {
        [
            // V1 → V2: Lightweight migration (all new fields are optional/have defaults)
            migrateV1toV2
        ]
    }

    /// Migration from V1 to V2: Add enhanced fields to Transaction, Person, and Subscription models
    ///
    /// This is a **lightweight migration** because:
    /// - All new fields are optional or have default values
    /// - No data transformations are required
    /// - No property renames or type changes
    /// - No relationship changes
    ///
    /// SwiftData will automatically:
    /// - Add new columns with NULL values for optionals
    /// - Add new columns with default values for non-optionals
    /// - Preserve all existing data
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SwiffSchemaV1.self,
        toVersion: SchemaV2.self
    )
}

/// Schema Version 1: Base Schema (Original Implementation)
///
/// This represents the original schema before Agent 13 enhancements
enum SwiffSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            TransactionModelV1.self,
            PersonModelV1.self,
            SubscriptionModelV1.self,
            SharedSubscriptionModelV1.self,
            GroupModelV1.self,
            GroupExpenseModelV1.self
        ]
    }

    // MARK: - Transaction Model V1 (Base Version)

    @Model
    final class TransactionModelV1 {
        @Attribute(.unique) var id: UUID
        var title: String
        var subtitle: String
        var amount: Double
        var categoryRaw: String
        var date: Date
        var isRecurring: Bool
        var tags: [String]
        var payerId: UUID?
        var payeeId: UUID?

        // Page 2 Enhancements
        var merchant: String?
        var paymentStatusRaw: String
        var receiptData: Data?
        var linkedSubscriptionId: UUID?

        init(
            id: UUID = UUID(),
            title: String,
            subtitle: String,
            amount: Double,
            categoryRaw: String,
            date: Date = Date(),
            isRecurring: Bool = false,
            tags: [String] = [],
            merchant: String? = nil,
            paymentStatusRaw: String = "Completed",
            receiptData: Data? = nil,
            linkedSubscriptionId: UUID? = nil
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.amount = amount
            self.categoryRaw = categoryRaw
            self.date = date
            self.isRecurring = isRecurring
            self.tags = tags
            self.merchant = merchant
            self.paymentStatusRaw = paymentStatusRaw
            self.receiptData = receiptData
            self.linkedSubscriptionId = linkedSubscriptionId
        }
    }

    // MARK: - Person Model V1 (Base Version)

    @Model
    final class PersonModelV1 {
        @Attribute(.unique) var id: UUID
        var name: String
        var email: String
        var phone: String
        var balance: Double
        var createdDate: Date
        var lastModifiedDate: Date

        // Avatar data
        var avatarTypeRaw: String
        var avatarData: Data?
        var avatarEmoji: String?
        var avatarInitials: String?
        var avatarColorIndex: Int

        init(
            id: UUID = UUID(),
            name: String,
            email: String,
            phone: String,
            balance: Double = 0.0,
            createdDate: Date = Date(),
            lastModifiedDate: Date = Date(),
            avatarTypeRaw: String = "emoji",
            avatarData: Data? = nil,
            avatarEmoji: String? = "👤",
            avatarInitials: String? = nil,
            avatarColorIndex: Int = 0
        ) {
            self.id = id
            self.name = name
            self.email = email
            self.phone = phone
            self.balance = balance
            self.createdDate = createdDate
            self.lastModifiedDate = lastModifiedDate
            self.avatarTypeRaw = avatarTypeRaw
            self.avatarData = avatarData
            self.avatarEmoji = avatarEmoji
            self.avatarInitials = avatarInitials
            self.avatarColorIndex = avatarColorIndex
        }
    }

    // MARK: - Subscription Model V1 (Base Version)

    @Model
    final class SubscriptionModelV1 {
        @Attribute(.unique) var id: UUID
        var name: String
        var subscriptionDescription: String
        var price: Double
        var billingCycleRaw: String
        var categoryRaw: String
        var icon: String
        var color: String
        var nextBillingDate: Date
        var isActive: Bool
        var isShared: Bool
        var sharedWithIDs: [UUID]
        var paymentMethodRaw: String
        var createdDate: Date
        var lastBillingDate: Date?
        var totalSpent: Double
        var notes: String
        var website: String?
        var cancellationDate: Date?
        var personId: UUID?

        // Trial fields (from Agent 8)
        var isFreeTrial: Bool
        var trialStartDate: Date?
        var trialEndDate: Date?
        var trialDuration: Int?
        var willConvertToPaid: Bool
        var priceAfterTrial: Double?

        // Reminder fields (from Agent 7)
        var enableRenewalReminder: Bool
        var reminderDaysBefore: Int
        var reminderTime: Date?
        var lastReminderSent: Date?

        // Usage tracking
        var lastUsedDate: Date?
        var usageCount: Int

        // Price history (from Agent 9)
        var lastPriceChange: Date?

        init(
            id: UUID = UUID(),
            name: String,
            subscriptionDescription: String,
            price: Double,
            billingCycleRaw: String = "Monthly",
            categoryRaw: String = "Other",
            icon: String = "app.fill",
            color: String = "#007AFF",
            nextBillingDate: Date = Date(),
            isActive: Bool = true,
            isShared: Bool = false,
            sharedWithIDs: [UUID] = [],
            paymentMethodRaw: String = "Credit Card",
            createdDate: Date = Date(),
            lastBillingDate: Date? = nil,
            totalSpent: Double = 0.0,
            notes: String = "",
            website: String? = nil,
            cancellationDate: Date? = nil,
            personId: UUID? = nil,
            isFreeTrial: Bool = false,
            trialStartDate: Date? = nil,
            trialEndDate: Date? = nil,
            trialDuration: Int? = nil,
            willConvertToPaid: Bool = true,
            priceAfterTrial: Double? = nil,
            enableRenewalReminder: Bool = true,
            reminderDaysBefore: Int = 3,
            reminderTime: Date? = nil,
            lastReminderSent: Date? = nil,
            lastUsedDate: Date? = nil,
            usageCount: Int = 0,
            lastPriceChange: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.subscriptionDescription = subscriptionDescription
            self.price = price
            self.billingCycleRaw = billingCycleRaw
            self.categoryRaw = categoryRaw
            self.icon = icon
            self.color = color
            self.nextBillingDate = nextBillingDate
            self.isActive = isActive
            self.isShared = isShared
            self.sharedWithIDs = sharedWithIDs
            self.paymentMethodRaw = paymentMethodRaw
            self.createdDate = createdDate
            self.lastBillingDate = lastBillingDate
            self.totalSpent = totalSpent
            self.notes = notes
            self.website = website
            self.cancellationDate = cancellationDate
            self.personId = personId
            self.isFreeTrial = isFreeTrial
            self.trialStartDate = trialStartDate
            self.trialEndDate = trialEndDate
            self.trialDuration = trialDuration
            self.willConvertToPaid = willConvertToPaid
            self.priceAfterTrial = priceAfterTrial
            self.enableRenewalReminder = enableRenewalReminder
            self.reminderDaysBefore = reminderDaysBefore
            self.reminderTime = reminderTime
            self.lastReminderSent = lastReminderSent
            self.lastUsedDate = lastUsedDate
            self.usageCount = usageCount
            self.lastPriceChange = lastPriceChange
        }
    }

    // MARK: - Shared Subscription Model V1

    @Model
    final class SharedSubscriptionModelV1 {
        @Attribute(.unique) var id: UUID
        var subscriptionID: UUID
        var sharedByID: UUID
        var sharedWithIDs: [UUID]
        var costSplitRaw: String
        var individualCost: Double
        var isAccepted: Bool
        var createdDate: Date
        var notes: String

        init(
            id: UUID = UUID(),
            subscriptionID: UUID,
            sharedByID: UUID,
            sharedWithIDs: [UUID] = [],
            costSplitRaw: String = "Split Equally",
            individualCost: Double = 0.0,
            isAccepted: Bool = false,
            createdDate: Date = Date(),
            notes: String = ""
        ) {
            self.id = id
            self.subscriptionID = subscriptionID
            self.sharedByID = sharedByID
            self.sharedWithIDs = sharedWithIDs
            self.costSplitRaw = costSplitRaw
            self.individualCost = individualCost
            self.isAccepted = isAccepted
            self.createdDate = createdDate
            self.notes = notes
        }
    }

    // MARK: - Group Model V1

    @Model
    final class GroupModelV1 {
        @Attribute(.unique) var id: UUID
        var name: String
        var groupDescription: String
        var createdDate: Date
        var memberIDs: [UUID]

        init(
            id: UUID = UUID(),
            name: String,
            groupDescription: String = "",
            createdDate: Date = Date(),
            memberIDs: [UUID] = []
        ) {
            self.id = id
            self.name = name
            self.groupDescription = groupDescription
            self.createdDate = createdDate
            self.memberIDs = memberIDs
        }
    }

    // MARK: - Group Expense Model V1

    @Model
    final class GroupExpenseModelV1 {
        @Attribute(.unique) var id: UUID
        var groupID: UUID
        var title: String
        var amount: Double
        var paidByID: UUID
        var splitBetweenIDs: [UUID]
        var date: Date
        var notes: String

        init(
            id: UUID = UUID(),
            groupID: UUID,
            title: String,
            amount: Double,
            paidByID: UUID,
            splitBetweenIDs: [UUID] = [],
            date: Date = Date(),
            notes: String = ""
        ) {
            self.id = id
            self.groupID = groupID
            self.title = title
            self.amount = amount
            self.paidByID = paidByID
            self.splitBetweenIDs = splitBetweenIDs
            self.date = date
            self.notes = notes
        }
    }
}

/// Migration Testing Utilities
extension SwiffMigrationPlan {

    /// Verify that migration was successful
    ///
    /// - Parameter context: ModelContext after migration
    /// - Returns: True if migration succeeded, false otherwise
    @MainActor
    static func verifyMigration(context: ModelContext) async throws -> Bool {
        // Verify all models are accessible
        let transactionDescriptor = FetchDescriptor<SchemaV2.TransactionModelV2>()
        let personDescriptor = FetchDescriptor<SchemaV2.PersonModelV2>()
        let subscriptionDescriptor = FetchDescriptor<SchemaV2.SubscriptionModelV2>()

        do {
            _ = try context.fetch(transactionDescriptor)
            _ = try context.fetch(personDescriptor)
            _ = try context.fetch(subscriptionDescriptor)
            return true
        } catch {
            print("❌ Migration verification failed: \(error)")
            return false
        }
    }

    /// Get migration summary
    static func getMigrationSummary() -> String {
        """
        SwiffMigrationPlan Summary:

        Schema Versions: \(schemas.count)
        - V1.0.0: Base schema (6 models)
        - V2.0.0: Enhanced schema with Agent 13 fields

        Migration Stages: \(stages.count)
        - V1 → V2: Lightweight migration (automatic)

        New Fields in V2:

        Transaction Model:
        - merchantCategory: String?
        - isRecurringCharge: Bool (default: false)
        - paymentMethodRaw: String?
        - location: String?
        - notes: String (default: "")

        Person Model:
        - contactId: String?
        - preferredPaymentMethodRaw: String?
        - notificationPreferencesData: Data?
        - relationshipType: String?
        - personNotes: String?

        Subscription Model:
        - autoRenew: Bool (default: true)
        - cancellationDeadline: Date?
        - cancellationInstructions: String?
        - cancellationDifficultyRaw: String?
        - alternativeSuggestions: [String] (default: [])
        - retentionOffersData: Data?
        - documentsData: Data?

        Migration Type: Lightweight (automatic, no data transformation required)
        Data Loss Risk: None (all existing data preserved)
        """
    }
}
