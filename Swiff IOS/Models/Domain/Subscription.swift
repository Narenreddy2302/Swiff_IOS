//
//  Subscription.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Combine
import Foundation

// MARK: - Balance Status for Shared Subscriptions

enum BalanceStatus: String, Codable {
    case owesYou = "owes-you"
    case youOwe = "you-owe"
    case settled = "settled"

    var displayText: String {
        switch self {
        case .owesYou: return "They owe you"
        case .youOwe: return "You owe"
        case .settled: return "Settled"
        }
    }
}

// MARK: - Subscription Model

struct Subscription: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var price: Double
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var icon: String  // SF Symbol name
    var color: String  // Hex color code
    var nextBillingDate: Date
    var isActive: Bool
    var isShared: Bool
    var sharedWith: [UUID]  // Person or Group IDs
    var paymentMethod: PaymentMethod
    var createdDate: Date
    var lastBillingDate: Date?
    var totalSpent: Double
    var notes: String
    var website: String?
    var cancellationDate: Date?

    // AGENT 8: Trial tracking fields
    var isFreeTrial: Bool
    var trialStartDate: Date?
    var trialEndDate: Date?
    var trialDuration: Int?  // days - AGENT 8
    var willConvertToPaid: Bool
    var priceAfterTrial: Double?

    // Usage tracking fields
    var lastUsedDate: Date?
    var usageCount: Int

    // Price history
    var lastPriceChange: Date?

    // Reminder fields
    var enableRenewalReminder: Bool
    var reminderDaysBefore: Int
    var reminderTime: Date?
    var lastReminderSent: Date?

    // Agent 13: Data Model Enhancements - Additional fields
    var autoRenew: Bool  // Auto-renewal enabled
    var cancellationDeadline: Date?  // Must cancel by this date
    var cancellationInstructions: String?  // How to cancel
    var cancellationDifficulty: CancellationDifficulty?  // How hard is it to cancel
    var alternativeSuggestions: [String]  // Competitor/alternative names
    var retentionOffers: [RetentionOffer]  // Offers to retain subscription
    var documents: [SubscriptionDocument]  // Contracts, receipts, etc.

    init(
        name: String, description: String, price: Double, billingCycle: BillingCycle,
        category: SubscriptionCategory, icon: String = "app.fill", color: String = "#007AFF"
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.price = price
        self.billingCycle = billingCycle
        self.category = category
        self.icon = icon
        self.color = color
        self.nextBillingDate = billingCycle.calculateNextBilling(from: Date())
        self.isActive = true
        self.isShared = false
        self.sharedWith = []
        self.paymentMethod = .creditCard
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
        self.trialDuration = nil  // AGENT 8
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
        self.cancellationDifficulty = nil
        self.alternativeSuggestions = []
        self.retentionOffers = []
        self.documents = []
    }

    var monthlyEquivalent: Double {
        switch billingCycle {
        case .daily: return price * 30.44
        case .weekly: return price * 4.33
        case .biweekly: return price * 2.17
        case .monthly: return price
        case .quarterly: return price / 3
        case .semiAnnually: return price / 6
        case .yearly: return price / 12
        case .annually: return price / 12
        case .lifetime: return 0
        }
    }

    var nextBillingAmount: Double {
        return price
    }

    var costPerPerson: Double {
        if isShared && !sharedWith.isEmpty {
            return monthlyEquivalent / Double(sharedWith.count + 1)  // +1 for the owner
        }
        return monthlyEquivalent
    }

    // Trial computed properties
    var daysUntilTrialEnd: Int? {
        guard let end = trialEndDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: end)
        return components.day
    }

    var isTrialExpired: Bool {
        guard let end = trialEndDate else { return false }
        return Date() > end
    }

    var trialStatus: String {
        guard isFreeTrial else { return "" }

        if isTrialExpired {
            return "Trial Expired"
        }

        guard let days = daysUntilTrialEnd else { return "Active Trial" }

        if days == 0 {
            return "Trial ends today"
        } else if days == 1 {
            return "Trial ends tomorrow"
        } else if days < 7 {
            return "Trial ends in \(days) days"
        } else {
            return "Active Trial"
        }
    }

    // MARK: - Supabase Conversion

    /// Converts this domain model to a Supabase-compatible model for API upload
    /// - Parameter userId: The authenticated user's ID from Supabase
    /// - Returns: SupabaseSubscription ready for API insertion/update
    func toSupabaseModel(userId: UUID) -> SupabaseSubscription {
        return SupabaseSubscription(
            id: self.id,
            userId: userId,
            name: self.name,
            description: self.description.isEmpty ? nil : self.description,
            price: Decimal(self.price),
            billingCycle: self.billingCycle.rawValue,
            category: self.category.rawValue,
            icon: self.icon,
            color: self.color,
            nextBillingDate: self.nextBillingDate,
            isActive: self.isActive,
            isShared: self.isShared,
            paymentMethod: self.paymentMethod.rawValue,
            lastBillingDate: self.lastBillingDate,
            totalSpent: Decimal(self.totalSpent),
            notes: self.notes.isEmpty ? nil : self.notes,
            website: self.website,
            cancellationDate: self.cancellationDate,
            isFreeTrial: self.isFreeTrial,
            trialStartDate: self.trialStartDate,
            trialEndDate: self.trialEndDate,
            trialDuration: self.trialDuration,
            willConvertToPaid: self.willConvertToPaid,
            priceAfterTrial: self.priceAfterTrial != nil ? Decimal(self.priceAfterTrial!) : nil,
            enableRenewalReminder: self.enableRenewalReminder,
            reminderDaysBefore: self.reminderDaysBefore,
            reminderTime: self.reminderTime,
            lastReminderSent: self.lastReminderSent,
            lastUsedDate: self.lastUsedDate,
            usageCount: self.usageCount,
            lastPriceChange: self.lastPriceChange,
            autoRenew: self.autoRenew,
            cancellationDeadline: self.cancellationDeadline,
            cancellationInstructions: self.cancellationInstructions,
            cancellationDifficulty: self.cancellationDifficulty?.rawValue,
            alternativeSuggestions: self.alternativeSuggestions.isEmpty ? nil : self.alternativeSuggestions,
            retentionOffers: nil,  // Complex type - handle separately if needed
            documents: nil,  // Complex type - handle separately if needed
            createdAt: self.createdDate,
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
    }
}

// MARK: - Shared Member Model

/// Represents a member in a shared subscription for display purposes
struct SharedMember: Identifiable, Codable {
    var id = UUID()
    let name: String

    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Shared Subscription Model

struct SharedSubscription: Identifiable, Codable {
    var id = UUID()
    let subscriptionId: UUID
    var sharedBy: UUID  // Person ID
    var sharedWith: [UUID]  // Person or Group IDs
    var costSplit: CostSplitType
    var individualCost: Double
    var isAccepted: Bool
    var createdDate: Date
    var notes: String

    // Balance tracking for shared subscriptions
    var balance: Double  // Positive = they owe you, Negative = you owe
    var balanceStatus: BalanceStatus  // Derived from balance sign

    // Display data for shared subscription row
    var billingCycle: BillingCycle
    var nextBillingDate: Date
    var members: [SharedMember]

    init(subscriptionId: UUID, sharedBy: UUID, sharedWith: [UUID], costSplit: CostSplitType)
    {
        self.subscriptionId = subscriptionId
        self.sharedBy = sharedBy
        self.sharedWith = sharedWith
        self.costSplit = costSplit
        self.individualCost = 0.0
        self.isAccepted = false
        self.createdDate = Date()
        self.notes = ""
        self.balance = 0.0
        self.balanceStatus = .settled
        self.billingCycle = .monthly
        self.nextBillingDate = Date()
        self.members = []
    }

    // MARK: - Supabase Conversion

    /// Converts this domain model to a Supabase-compatible model for API upload
    /// - Parameter userId: The authenticated user's ID from Supabase
    /// - Returns: SupabaseSharedSubscription ready for API insertion/update
    func toSupabaseModel(userId: UUID) -> SupabaseSharedSubscription {
        return SupabaseSharedSubscription(
            id: self.id,
            subscriptionId: self.subscriptionId,
            sharedByUserId: userId,
            sharedWithPersonId: self.sharedWith.first,  // First person in the share list
            sharedWithUserId: nil,  // Set if sharing with another Supabase user
            costSplitType: self.costSplit.rawValue,
            individualCost: Decimal(self.individualCost),
            percentage: nil,  // Calculate if needed based on costSplit type
            isAccepted: self.isAccepted,
            invitationStatus: self.isAccepted ? "accepted" : "pending",
            notes: self.notes.isEmpty ? nil : self.notes,
            createdAt: self.createdDate,
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
    }
}
