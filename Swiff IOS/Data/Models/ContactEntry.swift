//
//  ContactEntry.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Model representing a device contact with app account status
//

import Foundation

/// Represents a contact from the user's device with app account status
struct ContactEntry: Identifiable, Equatable, Hashable, Codable {

    // MARK: - Properties

    /// Unique identifier from CNContact
    let id: String

    /// Contact's full name as saved in the user's phone
    let name: String

    /// Normalized phone numbers in E.164 format
    let phoneNumbers: [String]

    /// Primary email address (if available)
    let email: String?

    /// Thumbnail image data from contact
    let thumbnailImageData: Data?

    /// Whether this contact has a Swiff account
    var hasAppAccount: Bool

    /// The matched user's ID in our system (if they have an account)
    var matchedUserId: UUID?

    /// The phone number that matched (if they have an account)
    var matchedPhone: String?

    // MARK: - Computed Properties

    /// Primary phone number (first in list)
    var primaryPhone: String? {
        phoneNumbers.first
    }

    /// Initials for avatar fallback
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[components.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first?.prefix(2) {
            return String(first).uppercased()
        }
        return "?"
    }

    /// Check if contact has any phone number
    var hasPhoneNumber: Bool {
        !phoneNumbers.isEmpty
    }

    /// Check if contact has email
    var hasEmail: Bool {
        email != nil && !email!.isEmpty
    }

    /// Check if contact can be invited (has phone number but no account)
    var canBeInvited: Bool {
        hasPhoneNumber && !hasAppAccount
    }

    // MARK: - Initialization

    init(
        id: String,
        name: String,
        phoneNumbers: [String],
        email: String? = nil,
        thumbnailImageData: Data? = nil,
        hasAppAccount: Bool = false,
        matchedUserId: UUID? = nil,
        matchedPhone: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumbers = phoneNumbers
        self.email = email
        self.thumbnailImageData = thumbnailImageData
        self.hasAppAccount = hasAppAccount
        self.matchedUserId = matchedUserId
        self.matchedPhone = matchedPhone
    }

    // MARK: - Equatable

    static func == (lhs: ContactEntry, rhs: ContactEntry) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sorting

extension ContactEntry {
    /// Sort contacts alphabetically by name
    nonisolated static func sortByName(_ contacts: [ContactEntry]) -> [ContactEntry] {
        contacts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Sort contacts with app accounts first, then alphabetically
    nonisolated static func sortByAccountStatus(_ contacts: [ContactEntry]) -> [ContactEntry] {
        contacts.sorted { lhs, rhs in
            if lhs.hasAppAccount != rhs.hasAppAccount {
                return lhs.hasAppAccount  // Accounts first
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

// MARK: - Filtering

extension Array where Element == ContactEntry {
    /// Filter to contacts with app accounts
    var onSwiff: [ContactEntry] {
        filter { $0.hasAppAccount }
    }

    /// Filter to contacts without app accounts
    var toInvite: [ContactEntry] {
        filter { !$0.hasAppAccount }
    }

    /// Filter contacts that can be invited (have phone but no account)
    var invitable: [ContactEntry] {
        filter { $0.canBeInvited }
    }

    /// Search contacts by name
    func search(_ query: String) -> [ContactEntry] {
        guard !query.isEmpty else { return self }
        let lowercased = query.lowercased()
        return filter { contact in
            contact.name.lowercased().contains(lowercased)
                || contact.email?.lowercased().contains(lowercased) == true
                || contact.phoneNumbers.contains { $0.contains(lowercased) }
        }
    }
}
