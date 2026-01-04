//
//  SchemaV2.swift
//  Swiff IOS
//
//  Created by Agent 13 - Data Model Enhancements
//  Schema Version 2 with comprehensive model enhancements
//

import Foundation
import SwiftData
import Combine

/// Schema Version 2 - Enhanced models with all Agent 13 fields
///
/// This schema includes:
/// - Transaction: Added merchantCategory, isRecurringCharge, paymentMethod, location, notes
/// - Person: Added contactId, preferredPaymentMethod, notificationPreferences, relationshipType, notes
/// - Subscription: Added autoRenew, cancellationDeadline, cancellationInstructions, cancellationDifficulty,
///                 alternativeSuggestions, retentionOffers, documents
///
/// Migration from V1 to V2:
/// - All new fields have default values
/// - No data loss during migration
/// - Lightweight migration is supported

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            TransactionModelV2.self,
            PersonModelV2.self,
            SubscriptionModelV2.self,
            SharedSubscriptionModelV2.self,
            GroupModelV2.self,
            GroupExpenseModelV2.self
        ]
    }

    // MARK: - Transaction Model V2

    @Model
    final class TransactionModelV2 {
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

        // V1 fields
        var merchant: String?
        var paymentStatusRaw: String
        var receiptData: Data?
        var linkedSubscriptionId: UUID?

        // V2 fields - Agent 13
        var merchantCategory: String?
        var isRecurringCharge: Bool
        var paymentMethodRaw: String?
        var location: String?
        var notes: String

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
            linkedSubscriptionId: UUID? = nil,
            merchantCategory: String? = nil,
            isRecurringCharge: Bool = false,
            paymentMethodRaw: String? = nil,
            location: String? = nil,
            notes: String = ""
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
            self.merchantCategory = merchantCategory
            self.isRecurringCharge = isRecurringCharge
            self.paymentMethodRaw = paymentMethodRaw
            self.location = location
            self.notes = notes
        }
    }

    // MARK: - Person Model V2

    @Model
    final class PersonModelV2 {
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

        // V2 fields - Agent 13
        var contactId: String?
        var preferredPaymentMethodRaw: String?
        var notificationPreferencesData: Data?
        var relationshipType: String?
        var personNotes: String?

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
            avatarColorIndex: Int = 0,
            contactId: String? = nil,
            preferredPaymentMethodRaw: String? = nil,
            notificationPreferencesData: Data? = nil,
            relationshipType: String? = nil,
            personNotes: String? = nil
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
            self.contactId = contactId
            self.preferredPaymentMethodRaw = preferredPaymentMethodRaw
            self.notificationPreferencesData = notificationPreferencesData
            self.relationshipType = relationshipType
            self.personNotes = personNotes
        }
    }

    // MARK: - Subscription Model V2

    @Model
    final class SubscriptionModelV2 {
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

        // Trial fields
        var isFreeTrial: Bool
        var trialStartDate: Date?
        var trialEndDate: Date?
        var trialDuration: Int?
        var willConvertToPaid: Bool
        var priceAfterTrial: Double?

        // Reminder fields
        var enableRenewalReminder: Bool
        var reminderDaysBefore: Int
        var reminderTime: Date?
        var lastReminderSent: Date?

        // Usage tracking
        var lastUsedDate: Date?
        var usageCount: Int

        // Price history
        var lastPriceChange: Date?

        // V2 fields - Agent 13
        var autoRenew: Bool
        var cancellationDeadline: Date?
        var cancellationInstructions: String?
        var cancellationDifficultyRaw: String?
        var alternativeSuggestions: [String]
        var retentionOffersData: Data?
        var documentsData: Data?

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
            lastPriceChange: Date? = nil,
            autoRenew: Bool = true,
            cancellationDeadline: Date? = nil,
            cancellationInstructions: String? = nil,
            cancellationDifficultyRaw: String? = nil,
            alternativeSuggestions: [String] = [],
            retentionOffersData: Data? = nil,
            documentsData: Data? = nil
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
            self.autoRenew = autoRenew
            self.cancellationDeadline = cancellationDeadline
            self.cancellationInstructions = cancellationInstructions
            self.cancellationDifficultyRaw = cancellationDifficultyRaw
            self.alternativeSuggestions = alternativeSuggestions
            self.retentionOffersData = retentionOffersData
            self.documentsData = documentsData
        }
    }

    // MARK: - Shared Subscription Model V2

    @Model
    final class SharedSubscriptionModelV2 {
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

    // MARK: - Group Model V2 (No changes from V1)

    @Model
    final class GroupModelV2 {
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

    // MARK: - Group Expense Model V2 (No changes from V1)

    @Model
    final class GroupExpenseModelV2 {
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
