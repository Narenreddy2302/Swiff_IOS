//
//  Person.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Combine
import Foundation

// MARK: - Person Source Enum

/// Tracks the origin of a Person record for auto-linking when contacts join the app
public enum PersonSource: String, Codable, CaseIterable, Sendable {
    case manual = "manual"       // Manually created by user
    case contact = "contact"     // Imported from iOS contacts (no app account)
    case appUser = "app_user"    // Has a verified Swiff account

    public var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .contact: return "Contact"
        case .appUser: return "App User"
        }
    }
}

// MARK: - Person Model

public struct Person: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var email: String
    public var phone: String
    public var avatarType: AvatarType  // New flexible avatar system
    public var balance: Double  // Overall balance with this person
    public var createdDate: Date
    public var lastModifiedDate: Date

    // Agent 13: Data Model Enhancements - Additional fields
    public var contactId: String?  // iOS Contacts identifier for linking
    public var preferredPaymentMethod: PaymentMethod?  // Person's preferred payment method
    public var notificationPreferences: NotificationPreferences  // How to notify this person
    public var relationshipType: String?  // e.g., "Friend", "Family", "Coworker", "Other"
    public var notes: String?  // User notes about this person

    // Contact Due Feature: Track person origin for auto-linking
    public var personSource: PersonSource  // Origin of this person record

    // Legacy support for emoji string
    @available(*, deprecated, message: "Use avatarType instead")
    public var avatar: String {
        get {
            if case .emoji(let emoji) = avatarType {
                return emoji
            }
            return "👤"
        }
        set {
            avatarType = .emoji(newValue)
        }
    }

    public init(
        name: String,
        email: String,
        phone: String,
        avatarType: AvatarType,
        contactId: String? = nil,
        preferredPaymentMethod: PaymentMethod? = nil,
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        relationshipType: String? = nil,
        notes: String? = nil,
        personSource: PersonSource = .manual
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarType = avatarType
        self.balance = 0.0
        let now = Date()
        self.createdDate = now
        self.lastModifiedDate = now
        self.contactId = contactId
        self.preferredPaymentMethod = preferredPaymentMethod
        self.notificationPreferences = notificationPreferences
        self.relationshipType = relationshipType
        self.notes = notes
        self.personSource = personSource
    }

    // Convenience init for emoji (backward compatibility)
    public init(name: String, email: String, phone: String, avatar: String) {
        self.init(name: name, email: email, phone: phone, avatarType: .emoji(avatar))
    }

    // Generate initials from name
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }

    // Get avatar color index
    var avatarColorIndex: Int {
        AvatarColorPalette.colorIndex(for: name)
    }

    // Last activity date display helper
    func lastActivityText(transactions: [Transaction]) -> String {
        let personTransactions = transactions.filter { transaction in
            transaction.title.contains(name) || transaction.subtitle.contains(name)
        }

        guard let lastTransaction = personTransactions.sorted(by: { $0.date > $1.date }).first
        else {
            return "No activity"
        }

        let days =
            Calendar.current.dateComponents([.day], from: lastTransaction.date, to: Date()).day ?? 0

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) \(weeks == 1 ? "week" : "weeks") ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months) \(months == 1 ? "month" : "months") ago"
        } else {
            let years = days / 365
            return "\(years) \(years == 1 ? "year" : "years") ago"
        }
    }

    // Last transaction details for feed-style display
    // Returns: "Split dinner • 2 days ago" or "No activity"
    func lastTransactionDetails(transactions: [Transaction]) -> String {
        let personTransactions = transactions.filter { transaction in
            transaction.title.contains(name) || transaction.subtitle.contains(name)
        }

        guard let lastTransaction = personTransactions.sorted(by: { $0.date > $1.date }).first
        else {
            return "No activity"
        }

        let title = lastTransaction.subtitle.isEmpty ? lastTransaction.title : lastTransaction.subtitle
        let timeText = lastActivityText(transactions: transactions)

        return "\(title) • \(timeText)"
    }

    // MARK: - Supabase Conversion

    /// Converts this domain model to a Supabase-compatible model for API upload
    /// - Parameter userId: The authenticated user's ID from Supabase
    /// - Returns: SupabasePerson ready for API insertion/update
    public func toSupabaseModel(userId: UUID) -> SupabasePerson {
        // Convert avatar type to Supabase format
        var avatarTypeStr: String?
        var avatarEmoji: String?
        var avatarInitials: String?
        var avatarColorIdx: Int?

        switch avatarType {
        case .emoji(let emoji):
            avatarTypeStr = "emoji"
            avatarEmoji = emoji
        case .initials(let initials, let colorIndex):
            avatarTypeStr = "initials"
            avatarInitials = initials
            avatarColorIdx = colorIndex
        case .photo:
            avatarTypeStr = "photo"
        case .contactPhoto:
            avatarTypeStr = "contact_photo"
        }

        // Convert notification preferences
        let notifPrefsData = NotificationPreferencesData(
            enableReminders: notificationPreferences.enableReminders,
            reminderFrequency: notificationPreferences.reminderFrequency.days,
            preferredContactMethod: notificationPreferences.preferredContactMethod.rawValue
        )

        return SupabasePerson(
            id: self.id,
            userId: userId,
            name: self.name,
            email: self.email.isEmpty ? nil : self.email,
            phone: self.phone.isEmpty ? nil : self.phone,
            balance: Decimal(self.balance),
            avatarType: avatarTypeStr,
            avatarEmoji: avatarEmoji,
            avatarInitials: avatarInitials,
            avatarColorIndex: avatarColorIdx,
            contactId: self.contactId,
            preferredPaymentMethod: self.preferredPaymentMethod?.rawValue,
            notificationPreferences: notifPrefsData,
            relationshipType: self.relationshipType,
            notes: self.notes,
            personSource: self.personSource.rawValue,
            createdAt: self.createdDate,
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
    }
}
