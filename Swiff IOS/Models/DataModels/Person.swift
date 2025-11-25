//
//  Person.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Foundation
import Combine

// MARK: - Person Model

struct Person: Identifiable, Codable {
    var id = UUID()
    var name: String
    var email: String
    var phone: String
    var avatarType: AvatarType  // New flexible avatar system
    var balance: Double // Overall balance with this person
    var createdDate: Date
    var lastModifiedDate: Date

    // Agent 13: Data Model Enhancements - Additional fields
    var contactId: String?                          // iOS Contacts identifier for linking
    var preferredPaymentMethod: PaymentMethod?      // Person's preferred payment method
    var notificationPreferences: NotificationPreferences  // How to notify this person
    var relationshipType: String?                   // e.g., "Friend", "Family", "Coworker", "Other"
    var notes: String?                              // User notes about this person

    // Legacy support for emoji string
    @available(*, deprecated, message: "Use avatarType instead")
    var avatar: String {
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

    init(
        name: String,
        email: String,
        phone: String,
        avatarType: AvatarType,
        contactId: String? = nil,
        preferredPaymentMethod: PaymentMethod? = nil,
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        relationshipType: String? = nil,
        notes: String? = nil
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
    }

    // Convenience init for emoji (backward compatibility)
    init(name: String, email: String, phone: String, avatar: String) {
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

        guard let lastTransaction = personTransactions.sorted(by: { $0.date > $1.date }).first else {
            return "No activity"
        }

        let days = Calendar.current.dateComponents([.day], from: lastTransaction.date, to: Date()).day ?? 0

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
}
