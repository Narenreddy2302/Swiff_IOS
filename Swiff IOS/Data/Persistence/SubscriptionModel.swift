//
//  SubscriptionModel.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  SwiftData entities for Subscription and SharedSubscription persistence
//

import Foundation
import SwiftData

@Model
final class SubscriptionModel {
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

    // AGENT 8: Trial tracking fields
    var isFreeTrial: Bool
    var trialStartDate: Date?
    var trialEndDate: Date?
    var trialDuration: Int? // days - AGENT 8
    var willConvertToPaid: Bool
    var priceAfterTrial: Double?

    // Reminder fields
    var enableRenewalReminder: Bool
    var reminderDaysBefore: Int
    var reminderTime: Date?
    var lastReminderSent: Date?

    // Usage tracking fields
    var lastUsedDate: Date?
    var usageCount: Int

    // Price history
    var lastPriceChange: Date?

    // Agent 13: Data Model Enhancements - Additional fields
    var autoRenew: Bool
    var cancellationDeadline: Date?
    var cancellationInstructions: String?
    var cancellationDifficultyRaw: String?
    var alternativeSuggestions: [String]
    var retentionOffersData: Data?  // Encoded [RetentionOffer]
    var documentsData: Data?        // Encoded [SubscriptionDocument]

    // Supabase sync metadata
    var syncVersion: Int = 1
    var deletedAt: Date?
    var pendingSync: Bool = false
    var lastSyncedAt: Date?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var sharedSubscriptions: [SharedSubscriptionModel]?

    init(id: UUID = UUID(), name: String, description: String, price: Double, billingCycle: BillingCycle, category: SubscriptionCategory, icon: String = "app.fill", color: String = "#007AFF") {
        self.id = id
        self.name = name
        self.subscriptionDescription = description
        self.price = price
        self.billingCycleRaw = billingCycle.rawValue
        self.categoryRaw = category.rawValue
        self.icon = icon
        self.color = color
        self.nextBillingDate = billingCycle.calculateNextBilling(from: Date())
        self.isActive = true
        self.isShared = false
        self.sharedWithIDs = []
        self.paymentMethodRaw = PaymentMethod.creditCard.rawValue
        self.createdDate = Date()
        self.lastBillingDate = nil
        self.totalSpent = 0.0
        self.notes = ""
        self.website = nil
        self.cancellationDate = nil

        // Initialize trial fields - AGENT 8
        self.isFreeTrial = false
        self.trialStartDate = nil
        self.trialEndDate = nil
        self.trialDuration = nil // AGENT 8
        self.willConvertToPaid = true
        self.priceAfterTrial = nil

        // Initialize reminder fields
        self.enableRenewalReminder = true
        self.reminderDaysBefore = 3
        self.reminderTime = nil
        self.lastReminderSent = nil

        // Initialize usage tracking
        self.lastUsedDate = nil
        self.usageCount = 0

        // Initialize price history
        self.lastPriceChange = nil

        // Agent 13: Initialize additional fields
        self.autoRenew = true
        self.cancellationDeadline = nil
        self.cancellationInstructions = nil
        self.cancellationDifficultyRaw = nil
        self.alternativeSuggestions = []
        self.retentionOffersData = nil
        self.documentsData = nil

        self.sharedSubscriptions = []
    }

    // Convert to domain model
    func toDomain() -> Subscription {
        let billingCycle = BillingCycle(rawValue: billingCycleRaw) ?? .monthly
        let category = SubscriptionCategory(rawValue: categoryRaw) ?? .other
        let paymentMethod = PaymentMethod(rawValue: paymentMethodRaw) ?? .creditCard

        var subscription = Subscription(
            name: name,
            description: subscriptionDescription,
            price: price,
            billingCycle: billingCycle,
            category: category,
            icon: icon,
            color: color
        )
        subscription.id = id
        subscription.nextBillingDate = nextBillingDate
        subscription.isActive = isActive
        subscription.isShared = isShared
        subscription.sharedWith = sharedWithIDs
        subscription.paymentMethod = paymentMethod
        subscription.createdDate = createdDate
        subscription.lastBillingDate = lastBillingDate
        subscription.totalSpent = totalSpent
        subscription.notes = notes
        subscription.website = website
        subscription.cancellationDate = cancellationDate

        // Map trial fields - AGENT 8
        subscription.isFreeTrial = isFreeTrial
        subscription.trialStartDate = trialStartDate
        subscription.trialEndDate = trialEndDate
        subscription.trialDuration = trialDuration // AGENT 8
        subscription.willConvertToPaid = willConvertToPaid
        subscription.priceAfterTrial = priceAfterTrial

        // Map reminder fields
        subscription.enableRenewalReminder = enableRenewalReminder
        subscription.reminderDaysBefore = reminderDaysBefore
        subscription.reminderTime = reminderTime
        subscription.lastReminderSent = lastReminderSent

        // Map usage tracking
        subscription.lastUsedDate = lastUsedDate
        subscription.usageCount = usageCount

        // Map price history
        subscription.lastPriceChange = lastPriceChange

        // Agent 13: Map additional fields
        subscription.autoRenew = autoRenew
        subscription.cancellationDeadline = cancellationDeadline
        subscription.cancellationInstructions = cancellationInstructions
        subscription.cancellationDifficulty = cancellationDifficultyRaw != nil ? CancellationDifficulty(rawValue: cancellationDifficultyRaw!) : nil

        // Decode retention offers
        if let data = retentionOffersData,
           let decoded = try? JSONDecoder().decode([RetentionOffer].self, from: data) {
            subscription.retentionOffers = decoded
        } else {
            subscription.retentionOffers = []
        }

        // Decode documents
        if let data = documentsData,
           let decoded = try? JSONDecoder().decode([SubscriptionDocument].self, from: data) {
            subscription.documents = decoded
        } else {
            subscription.documents = []
        }

        subscription.alternativeSuggestions = alternativeSuggestions

        return subscription
    }

    /// Convenience initializer from domain model
    convenience init(from subscription: Subscription) {
        self.init(
            id: subscription.id,
            name: subscription.name,
            description: subscription.description,
            price: subscription.price,
            billingCycle: subscription.billingCycle,
            category: subscription.category,
            icon: subscription.icon,
            color: subscription.color
        )
        // Set additional properties
        self.nextBillingDate = subscription.nextBillingDate
        self.isActive = subscription.isActive
        self.isShared = subscription.isShared
        self.sharedWithIDs = subscription.sharedWith
        self.createdDate = subscription.createdDate
        self.lastBillingDate = subscription.lastBillingDate
        self.totalSpent = subscription.totalSpent
        self.notes = subscription.notes
        self.website = subscription.website
        self.cancellationDate = subscription.cancellationDate

        // Set trial fields - AGENT 8
        self.isFreeTrial = subscription.isFreeTrial
        self.trialStartDate = subscription.trialStartDate
        self.trialEndDate = subscription.trialEndDate
        self.trialDuration = subscription.trialDuration // AGENT 8
        self.willConvertToPaid = subscription.willConvertToPaid
        self.priceAfterTrial = subscription.priceAfterTrial

        // Set reminder fields
        self.enableRenewalReminder = subscription.enableRenewalReminder
        self.reminderDaysBefore = subscription.reminderDaysBefore
        self.reminderTime = subscription.reminderTime
        self.lastReminderSent = subscription.lastReminderSent

        // Set usage tracking
        self.lastUsedDate = subscription.lastUsedDate
        self.usageCount = subscription.usageCount

        // Set price history
        self.lastPriceChange = subscription.lastPriceChange

        // Agent 13: Set additional fields
        self.autoRenew = subscription.autoRenew
        self.cancellationDeadline = subscription.cancellationDeadline
        self.cancellationInstructions = subscription.cancellationInstructions
        self.cancellationDifficultyRaw = subscription.cancellationDifficulty?.rawValue
        self.alternativeSuggestions = subscription.alternativeSuggestions

        // Encode retention offers
        if let encoded = try? JSONEncoder().encode(subscription.retentionOffers) {
            self.retentionOffersData = encoded
        }

        // Encode documents
        if let encoded = try? JSONEncoder().encode(subscription.documents) {
            self.documentsData = encoded
        }
    }
}

@Model
final class SharedSubscriptionModel {
    @Attribute(.unique) var id: UUID
    var subscriptionID: UUID
    var sharedByID: UUID
    var sharedWithIDs: [UUID]
    var costSplitRaw: String
    var individualCost: Double
    var isAccepted: Bool
    var createdDate: Date
    var notes: String

    // Supabase sync fields - for compatibility
    var subscriptionId: UUID { subscriptionID }
    var ownerUserId: UUID { sharedByID }
    var totalCost: Double { individualCost * Double(sharedWithIDs.count + 1) }
    var yourShare: Double { individualCost }

    // Supabase sync metadata
    var syncVersion: Int = 1
    var deletedAt: Date?
    var pendingSync: Bool = false
    var lastSyncedAt: Date?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var subscription: SubscriptionModel?

    init(id: UUID = UUID(), subscriptionID: UUID, sharedByID: UUID, sharedWithIDs: [UUID], costSplit: CostSplitType) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.sharedByID = sharedByID
        self.sharedWithIDs = sharedWithIDs
        self.costSplitRaw = costSplit.rawValue
        self.individualCost = 0.0
        self.isAccepted = false
        self.createdDate = Date()
        self.notes = ""
        self.subscription = nil
    }

    // Convert to domain model
    func toDomain() -> SharedSubscription {
        let costSplit = CostSplitType(rawValue: costSplitRaw) ?? .equal

        var sharedSub = SharedSubscription(
            subscriptionId: subscriptionID,
            sharedBy: sharedByID,
            sharedWith: sharedWithIDs,
            costSplit: costSplit
        )
        sharedSub.id = id
        sharedSub.individualCost = individualCost
        sharedSub.isAccepted = isAccepted
        sharedSub.createdDate = createdDate
        sharedSub.notes = notes

        return sharedSub
    }

    /// Convenience initializer from domain model
    convenience init(from sharedSub: SharedSubscription) {
        self.init(
            id: sharedSub.id,
            subscriptionID: sharedSub.subscriptionId,
            sharedByID: sharedSub.sharedBy,
            sharedWithIDs: sharedSub.sharedWith,
            costSplit: sharedSub.costSplit
        )
        self.individualCost = sharedSub.individualCost
        self.isAccepted = sharedSub.isAccepted
        self.createdDate = sharedSub.createdDate
        self.notes = sharedSub.notes
    }
}
