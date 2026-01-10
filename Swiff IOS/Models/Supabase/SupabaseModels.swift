//
//  SupabaseModels.swift
//  Swiff IOS
//
//  Codable models for Supabase database tables
//

import Foundation

// MARK: - Base Protocol

/// Protocol for all Supabase syncable models
protocol SupabaseSyncable: Codable, Identifiable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var deletedAt: Date? { get }
    var syncVersion: Int { get }
}

// MARK: - Person Model

struct SupabasePerson: SupabaseSyncable {
    let id: UUID
    let userId: UUID
    var name: String
    var email: String?
    var phone: String?
    var balance: Decimal
    var avatarType: String?
    var avatarEmoji: String?
    var avatarInitials: String?
    var avatarColorIndex: Int?
    var contactId: String?
    var preferredPaymentMethod: String?
    var notificationPreferences: NotificationPreferencesData?
    var relationshipType: String?
    var notes: String?
    var personSource: String?  // "manual", "contact", or "app_user"
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, email, phone, balance
        case avatarType = "avatar_type"
        case avatarEmoji = "avatar_emoji"
        case avatarInitials = "avatar_initials"
        case avatarColorIndex = "avatar_color_index"
        case contactId = "contact_id"
        case preferredPaymentMethod = "preferred_payment_method"
        case notificationPreferences = "notification_preferences"
        case relationshipType = "relationship_type"
        case notes
        case personSource = "person_source"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

struct NotificationPreferencesData: Codable, Sendable {
    var enableReminders: Bool
    var reminderFrequency: Int
    var preferredContactMethod: String

    enum CodingKeys: String, CodingKey {
        case enableReminders = "enable_reminders"
        case reminderFrequency = "reminder_frequency"
        case preferredContactMethod = "preferred_contact_method"
    }
}

// MARK: - Account Model

struct SupabaseAccount: SupabaseSyncable {
    let id: UUID
    let userId: UUID
    var name: String
    var number: String?
    var type: String
    var isDefault: Bool
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, number, type
        case isDefault = "is_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Group Model

struct SupabaseGroup: SupabaseSyncable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var emoji: String?
    var totalAmount: Decimal
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, description, emoji
        case totalAmount = "total_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Group Member Model

struct SupabaseGroupMember: SupabaseSyncable {
    let id: UUID
    let groupId: UUID
    var personId: UUID?
    var memberUserId: UUID?
    var isAdmin: Bool
    var joinedAt: Date
    var invitationStatus: String?
    var invitedAt: Date?
    var respondedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case personId = "person_id"
        case memberUserId = "member_user_id"
        case isAdmin = "is_admin"
        case joinedAt = "joined_at"
        case invitationStatus = "invitation_status"
        case invitedAt = "invited_at"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Group Expense Model

struct SupabaseGroupExpense: SupabaseSyncable {
    let id: UUID
    let groupId: UUID
    var title: String
    var amount: Decimal
    var paidByPersonId: UUID?
    var paidByUserId: UUID?
    var splitBetweenPersonIds: [UUID]
    var splitBetweenUserIds: [UUID]
    var category: String
    var date: Date
    var notes: String?
    var receiptPath: String?
    var isSettled: Bool
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case title, amount
        case paidByPersonId = "paid_by_person_id"
        case paidByUserId = "paid_by_user_id"
        case splitBetweenPersonIds = "split_between_person_ids"
        case splitBetweenUserIds = "split_between_user_ids"
        case category, date, notes
        case receiptPath = "receipt_path"
        case isSettled = "is_settled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Subscription Model

struct SupabaseSubscription: SupabaseSyncable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var price: Decimal
    var billingCycle: String
    var category: String
    var icon: String?
    var color: String?
    var nextBillingDate: Date?
    var isActive: Bool
    var isShared: Bool
    var paymentMethod: String?
    var lastBillingDate: Date?
    var totalSpent: Decimal
    var notes: String?
    var website: String?
    var cancellationDate: Date?

    // Trial fields
    var isFreeTrial: Bool
    var trialStartDate: Date?
    var trialEndDate: Date?
    var trialDuration: Int?
    var willConvertToPaid: Bool
    var priceAfterTrial: Decimal?

    // Reminder fields
    var enableRenewalReminder: Bool
    var reminderDaysBefore: Int?
    var reminderTime: Date?
    var lastReminderSent: Date?

    // Usage tracking
    var lastUsedDate: Date?
    var usageCount: Int

    // Price history
    var lastPriceChange: Date?

    // Cancellation info
    var autoRenew: Bool
    var cancellationDeadline: Date?
    var cancellationInstructions: String?
    var cancellationDifficulty: String?

    // JSONB fields
    var alternativeSuggestions: [String]?
    var retentionOffers: [RetentionOfferData]?
    var documents: [SubscriptionDocumentData]?

    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, description, price
        case billingCycle = "billing_cycle"
        case category, icon, color
        case nextBillingDate = "next_billing_date"
        case isActive = "is_active"
        case isShared = "is_shared"
        case paymentMethod = "payment_method"
        case lastBillingDate = "last_billing_date"
        case totalSpent = "total_spent"
        case notes, website
        case cancellationDate = "cancellation_date"
        case isFreeTrial = "is_free_trial"
        case trialStartDate = "trial_start_date"
        case trialEndDate = "trial_end_date"
        case trialDuration = "trial_duration"
        case willConvertToPaid = "will_convert_to_paid"
        case priceAfterTrial = "price_after_trial"
        case enableRenewalReminder = "enable_renewal_reminder"
        case reminderDaysBefore = "reminder_days_before"
        case reminderTime = "reminder_time"
        case lastReminderSent = "last_reminder_sent"
        case lastUsedDate = "last_used_date"
        case usageCount = "usage_count"
        case lastPriceChange = "last_price_change"
        case autoRenew = "auto_renew"
        case cancellationDeadline = "cancellation_deadline"
        case cancellationInstructions = "cancellation_instructions"
        case cancellationDifficulty = "cancellation_difficulty"
        case alternativeSuggestions = "alternative_suggestions"
        case retentionOffers = "retention_offers"
        case documents
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

struct RetentionOfferData: Codable, Identifiable, Sendable {
    var id: UUID
    var offerDescription: String
    var discountedPrice: Decimal?
    var offerDate: Date?
    var accepted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case offerDescription = "offer_description"
        case discountedPrice = "discounted_price"
        case offerDate = "offer_date"
        case accepted
    }
}

struct SubscriptionDocumentData: Codable, Identifiable, Sendable {
    var id: UUID
    var type: String
    var name: String
    var dateAdded: Date

    enum CodingKeys: String, CodingKey {
        case id, type, name
        case dateAdded = "date_added"
    }
}

// MARK: - Shared Subscription Model

struct SupabaseSharedSubscription: SupabaseSyncable {
    let id: UUID
    let subscriptionId: UUID
    let sharedByUserId: UUID
    var sharedWithPersonId: UUID?
    var sharedWithUserId: UUID?
    var costSplitType: String
    var individualCost: Decimal?
    var percentage: Decimal?
    var isAccepted: Bool
    var invitationStatus: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case subscriptionId = "subscription_id"
        case sharedByUserId = "shared_by_user_id"
        case sharedWithPersonId = "shared_with_person_id"
        case sharedWithUserId = "shared_with_user_id"
        case costSplitType = "cost_split_type"
        case individualCost = "individual_cost"
        case percentage
        case isAccepted = "is_accepted"
        case invitationStatus = "invitation_status"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Price Change Model

struct SupabasePriceChange: SupabaseSyncable {
    let id: UUID
    let subscriptionId: UUID
    var oldPrice: Decimal
    var newPrice: Decimal
    var changeDate: Date
    var reason: String?
    var detectedAutomatically: Bool
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case subscriptionId = "subscription_id"
        case oldPrice = "old_price"
        case newPrice = "new_price"
        case changeDate = "change_date"
        case reason
        case detectedAutomatically = "detected_automatically"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Subscription Event Model

struct SupabaseSubscriptionEvent: SupabaseSyncable {
    let id: UUID
    let subscriptionId: UUID
    var eventType: String
    var eventDate: Date
    var title: String
    var subtitle: String?
    var amount: Decimal?
    var metadata: [String: String]?
    var isSystemMessage: Bool
    var relatedPersonId: UUID?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case subscriptionId = "subscription_id"
        case eventType = "event_type"
        case eventDate = "event_date"
        case title, subtitle, amount, metadata
        case isSystemMessage = "is_system_message"
        case relatedPersonId = "related_person_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Transaction Model

struct SupabaseTransaction: SupabaseSyncable {
    let id: UUID
    let userId: UUID
    var title: String
    var subtitle: String?
    var amount: Decimal
    var category: String
    var date: Date
    var transactionType: String?
    var isRecurring: Bool
    var isRecurringCharge: Bool
    var tags: [String]
    var merchant: String?
    var merchantCategory: String?
    var paymentStatus: String
    var linkedSubscriptionId: UUID?
    var splitBillId: UUID?
    var relatedPersonId: UUID?
    var paymentMethod: String?
    var accountId: UUID?
    var location: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, subtitle, amount, category, date
        case transactionType = "transaction_type"
        case isRecurring = "is_recurring"
        case isRecurringCharge = "is_recurring_charge"
        case tags, merchant
        case merchantCategory = "merchant_category"
        case paymentStatus = "payment_status"
        case linkedSubscriptionId = "linked_subscription_id"
        case splitBillId = "split_bill_id"
        case relatedPersonId = "related_person_id"
        case paymentMethod = "payment_method"
        case accountId = "account_id"
        case location, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Split Bill Model

struct SupabaseSplitBill: SupabaseSyncable {
    let id: UUID
    let userId: UUID
    var title: String
    var totalAmount: Decimal
    var paidByPersonId: UUID?
    var paidByUserId: UUID?
    var splitType: String
    var notes: String?
    var category: String
    var date: Date
    var groupId: UUID?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case totalAmount = "total_amount"
        case paidByPersonId = "paid_by_person_id"
        case paidByUserId = "paid_by_user_id"
        case splitType = "split_type"
        case notes, category, date
        case groupId = "group_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Split Participant Model

struct SupabaseSplitParticipant: SupabaseSyncable {
    let id: UUID
    let splitBillId: UUID
    var personId: UUID?
    var participantUserId: UUID?
    var amount: Decimal
    var hasPaid: Bool
    var paymentDate: Date?
    var percentage: Decimal?
    var shares: Int?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id
        case splitBillId = "split_bill_id"
        case personId = "person_id"
        case participantUserId = "participant_user_id"
        case amount
        case hasPaid = "has_paid"
        case paymentDate = "payment_date"
        case percentage, shares
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Invitation Model

struct SupabaseInvitation: Codable, Identifiable, Sendable {
    let id: UUID
    let inviterUserId: UUID
    var inviteeEmail: String
    var inviteeUserId: UUID?
    var invitationType: String
    var resourceId: UUID
    var status: String
    var token: String?
    var expiresAt: Date?
    let createdAt: Date
    var updatedAt: Date
    var respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case inviterUserId = "inviter_user_id"
        case inviteeEmail = "invitee_email"
        case inviteeUserId = "invitee_user_id"
        case invitationType = "invitation_type"
        case resourceId = "resource_id"
        case status, token
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case respondedAt = "responded_at"
    }
}

// MARK: - Model Converters Extension

extension SupabasePerson {
    /// Create from domain Person model
    init(from person: Person, userId: UUID) {
        self.id = person.id
        self.userId = userId
        self.name = person.name
        self.email = person.email.isEmpty ? nil : person.email
        self.phone = person.phone.isEmpty ? nil : person.phone
        self.balance = Decimal(person.balance)
        self.avatarType = person.avatarType.supabaseValue
        self.avatarEmoji = person.avatarType.emojiValue
        self.avatarInitials = person.avatarType.initialsValue
        self.avatarColorIndex = person.avatarType.colorIndexValue
        self.contactId = person.contactId
        self.preferredPaymentMethod = person.preferredPaymentMethod?.rawValue
        self.notificationPreferences = NotificationPreferencesData(
            enableReminders: person.notificationPreferences.enableReminders,
            reminderFrequency: person.notificationPreferences.reminderFrequency,
            preferredContactMethod: person.notificationPreferences.preferredContactMethod.rawValue
        )
        self.relationshipType = person.relationshipType
        self.notes = person.notes
        self.createdAt = person.createdDate
        self.updatedAt = person.lastModifiedDate
        self.deletedAt = nil
        self.syncVersion = 1
    }

    /// Convert to domain Person model
    func toDomain() -> Person {
        let resolvedAvatarType = avatarType.flatMap {
            AvatarType.from(supabaseValue: $0, emoji: avatarEmoji, initials: avatarInitials, colorIndex: avatarColorIndex)
        } ?? .initials(name, colorIndex: avatarColorIndex ?? 0)

        let resolvedNotificationPrefs: NotificationPreferences
        if let prefs = notificationPreferences {
            resolvedNotificationPrefs = NotificationPreferences(
                enableReminders: prefs.enableReminders,
                reminderFrequency: prefs.reminderFrequency,
                preferredContactMethod: ContactMethod(rawValue: prefs.preferredContactMethod) ?? .inApp
            )
        } else {
            resolvedNotificationPrefs = NotificationPreferences()
        }

        var person = Person(
            name: name,
            email: email ?? "",
            phone: phone ?? "",
            avatarType: resolvedAvatarType,
            contactId: contactId,
            preferredPaymentMethod: preferredPaymentMethod.flatMap { PaymentMethod(rawValue: $0) },
            notificationPreferences: resolvedNotificationPrefs,
            relationshipType: relationshipType,
            notes: notes
        )
        // Set properties that aren't in the initializer
        person.id = id
        person.balance = NSDecimalNumber(decimal: balance).doubleValue
        person.createdDate = createdAt
        person.lastModifiedDate = updatedAt
        return person
    }
}

// MARK: - AvatarType Extensions

extension AvatarType {
    var supabaseValue: String {
        switch self {
        case .photo: return "photo"
        case .emoji: return "emoji"
        case .initials: return "initials"
        }
    }

    var emojiValue: String? {
        if case .emoji(let emoji) = self { return emoji }
        return nil
    }

    var initialsValue: String? {
        if case .initials(let initials, _) = self { return initials }
        return nil
    }

    var colorIndexValue: Int? {
        if case .initials(_, let colorIndex) = self { return colorIndex }
        return nil
    }

    static func from(supabaseValue: String, emoji: String?, initials: String?, colorIndex: Int?) -> AvatarType? {
        switch supabaseValue {
        case "photo":
            return .photo(Data())
        case "emoji":
            return emoji.map { .emoji($0) }
        case "initials":
            return .initials(initials ?? "", colorIndex: colorIndex ?? 0)
        default:
            return nil
        }
    }
}
