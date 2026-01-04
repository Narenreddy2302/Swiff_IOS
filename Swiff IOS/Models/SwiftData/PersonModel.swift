//
//  PersonModel.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  SwiftData entity for Person persistence
//

import Combine
import Foundation
import SwiftData

@Model
final class PersonModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var phone: String
    var balance: Double
    var createdDate: Date
    var lastModifiedDate: Date

    // Avatar data
    var avatarTypeRaw: String  // "photo", "emoji", "initials"
    var avatarData: Data?  // For photo avatars
    var avatarEmoji: String?  // For emoji avatars
    var avatarInitials: String?  // For initials avatars
    var avatarColorIndex: Int

    // Agent 13: Data Model Enhancements - Additional fields
    var contactId: String?
    var preferredPaymentMethodRaw: String?
    var notificationPreferencesData: Data?  // Encoded NotificationPreferences
    var relationshipType: String?
    var personNotes: String?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var groups: [GroupModel] = []

    @Relationship(deleteRule: .nullify)
    var transactions: [TransactionModel] = []

    // Note: Expense relationships are managed from GroupExpenseModel side to avoid circular references
    // paidExpenses and participatingExpenses can be computed using queries when needed

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phone: String,
        avatarType: AvatarType,
        balance: Double = 0.0,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        contactId: String? = nil,
        preferredPaymentMethod: PaymentMethod? = nil,
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        relationshipType: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.balance = balance
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate

        // Handle avatar type
        switch avatarType {
        case .photo(let data):
            self.avatarTypeRaw = "photo"
            self.avatarData = data
            self.avatarEmoji = nil
            self.avatarInitials = nil
            self.avatarColorIndex = 0
        case .emoji(let emoji):
            self.avatarTypeRaw = "emoji"
            self.avatarData = nil
            self.avatarEmoji = emoji
            self.avatarInitials = nil
            self.avatarColorIndex = 0
        case .initials(let initials, let colorIndex):
            self.avatarTypeRaw = "initials"
            self.avatarData = nil
            self.avatarEmoji = nil
            self.avatarInitials = initials
            self.avatarColorIndex = colorIndex
        }

        // Agent 13: Set additional fields
        self.contactId = contactId
        self.preferredPaymentMethodRaw = preferredPaymentMethod?.rawValue
        self.relationshipType = relationshipType
        self.personNotes = notes

        // Encode notification preferences
        // Use a simple encoding approach that avoids MainActor isolation issues
        self.notificationPreferencesData = Self.encodeNotificationPreferences(
            notificationPreferences)
    }

    // Convert to domain model
    func toDomain() -> Person {
        let avatarType: AvatarType
        switch avatarTypeRaw {
        case "photo":
            avatarType = .photo(avatarData ?? Data())
        case "emoji":
            avatarType = .emoji(avatarEmoji ?? "👤")
        case "initials":
            avatarType = .initials(avatarInitials ?? "", colorIndex: avatarColorIndex)
        default:
            avatarType = .emoji("👤")
        }

        // Decode notification preferences using static helper to avoid MainActor isolation issues
        let notifPrefs = Self.decodeNotificationPreferences(notificationPreferencesData)

        // Decode preferred payment method
        let prefPaymentMethod =
            preferredPaymentMethodRaw != nil
            ? PaymentMethod(rawValue: preferredPaymentMethodRaw!) : nil

        var person = Person(
            name: name,
            email: email,
            phone: phone,
            avatarType: avatarType,
            contactId: contactId,
            preferredPaymentMethod: prefPaymentMethod,
            notificationPreferences: notifPrefs,
            relationshipType: relationshipType,
            notes: personNotes
        )

        // Preserve critical fields that were lost in original implementation
        person.id = self.id
        person.balance = self.balance
        person.createdDate = self.createdDate
        person.lastModifiedDate = self.lastModifiedDate

        return person
    }

    /// Convenience initializer from domain model
    convenience init(from person: Person) {
        self.init(
            id: person.id,
            name: person.name,
            email: person.email,
            phone: person.phone,
            avatarType: person.avatarType,
            balance: person.balance,
            createdDate: person.createdDate,
            lastModifiedDate: person.lastModifiedDate,
            contactId: person.contactId,
            preferredPaymentMethod: person.preferredPaymentMethod,
            notificationPreferences: person.notificationPreferences,
            relationshipType: person.relationshipType,
            notes: person.notes
        )
    }

    // MARK: - Computed Expense Properties

    /// Get expenses paid by this person (computed to avoid circular reference)
    func getPaidExpenses(from context: ModelContext) -> [GroupExpenseModel] {
        let personId = self.id
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate<GroupExpenseModel> { expense in
                expense.paidByID == personId
            }
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get expenses this person participates in (computed to avoid circular reference)
    func getParticipatingExpenses(from context: ModelContext) -> [GroupExpenseModel] {
        let personId = self.id
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate<GroupExpenseModel> { expense in
                expense.splitBetweenIDs.contains(personId)
            }
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Static Encoding/Decoding Helpers

    /// Encode NotificationPreferences to Data
    /// NotificationPreferences is Sendable and Codable, so this is safe in any context
    nonisolated private static func encodeNotificationPreferences(_ prefs: NotificationPreferences)
        -> Data?
    {
        try? JSONEncoder().encode(prefs)
    }

    /// Decode NotificationPreferences from Data
    /// NotificationPreferences is Sendable and Codable, so this is safe in any context
    nonisolated private static func decodeNotificationPreferences(_ data: Data?)
        -> NotificationPreferences
    {
        guard let data = data,
            let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data)
        else {
            return NotificationPreferences(
                enableReminders: true, reminderFrequency: 7, preferredContactMethod: .inApp)
        }
        return prefs
    }

}
