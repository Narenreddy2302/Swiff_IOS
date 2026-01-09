//
//  DueLinkingService.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Service for auto-linking existing dues when contacts join the app
//

import Foundation
import Combine

/// Service that automatically links existing dues to newly joined app users
/// When a contact who has pending dues with the user joins Swiff, their
/// Person record is updated to reflect their app user status
@MainActor
class DueLinkingService: ObservableObject {

    // MARK: - Singleton

    static let shared = DueLinkingService()

    // MARK: - Dependencies

    private let dataManager = DataManager.shared
    private let contactSyncManager = ContactSyncManager.shared

    // MARK: - Published Properties

    @Published var lastLinkDate: Date?
    @Published var linkedContactsCount: Int = 0

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Called after contact sync to check for newly joined users
    /// - Parameter matchedContacts: Contacts that have been matched with app accounts
    func linkNewAppUsers(matchedContacts: [ContactEntry]) async {
        var linkedCount = 0

        for contact in matchedContacts where contact.hasAppAccount {
            if await linkContactToAppUser(contact) {
                linkedCount += 1
            }
        }

        if linkedCount > 0 {
            linkedContactsCount = linkedCount
            lastLinkDate = Date()
            print("DueLinkingService: Linked \(linkedCount) contacts to app accounts")
        }
    }

    /// Check for contacts that have become app users since last sync
    /// This can be called periodically or on app launch
    func checkForNewAppUsers() async {
        // Get all people with personSource == .contact
        let contactBasedPeople = dataManager.people.filter {
            $0.personSource == .contact && $0.contactId != nil
        }

        guard !contactBasedPeople.isEmpty else {
            print("DueLinkingService: No contact-based people to check")
            return
        }

        var linkedCount = 0

        // For each person, check if their linked contact now has an app account
        for person in contactBasedPeople {
            guard let contactId = person.contactId else { continue }

            // Find the corresponding contact
            if let contact = contactSyncManager.contacts.first(where: { $0.id == contactId }),
               contact.hasAppAccount
            {
                if await linkPersonToAppUser(person: person, contact: contact) {
                    linkedCount += 1
                }
            }
        }

        if linkedCount > 0 {
            linkedContactsCount = linkedCount
            lastLinkDate = Date()
            print("DueLinkingService: Linked \(linkedCount) people to app accounts via checkForNewAppUsers")
        }
    }

    /// Check if a specific person should be linked to an app account
    /// - Parameter person: The person to check
    /// - Returns: True if the person was linked to an app account
    func checkAndLinkPerson(_ person: Person) async -> Bool {
        guard person.personSource == .contact,
              let contactId = person.contactId,
              let contact = contactSyncManager.contacts.first(where: { $0.id == contactId }),
              contact.hasAppAccount
        else {
            return false
        }

        return await linkPersonToAppUser(person: person, contact: contact)
    }

    // MARK: - Private Methods

    /// Link a specific contact to their app account
    /// - Parameter contact: The contact entry that has an app account
    /// - Returns: True if a person was linked
    private func linkContactToAppUser(_ contact: ContactEntry) async -> Bool {
        guard contact.hasAppAccount,
              contact.matchedUserId != nil
        else {
            return false
        }

        // Find existing Person by contact ID
        if let existingPerson = dataManager.people.first(where: { $0.contactId == contact.id }) {
            return await linkPersonToAppUser(person: existingPerson, contact: contact)
        }

        // Fallback: Find by phone number
        let normalizedPhone = PhoneNumberNormalizer.normalize(contact.primaryPhone ?? "")
        if let existingPerson = dataManager.people.first(where: { person in
            PhoneNumberNormalizer.normalize(person.phone) == normalizedPhone
        }) {
            return await linkPersonToAppUser(person: existingPerson, contact: contact)
        }

        return false
    }

    /// Update a person to reflect their app user status
    /// - Parameters:
    ///   - person: The person to update
    ///   - contact: The contact with app account info
    /// - Returns: True if the person was updated
    private func linkPersonToAppUser(person: Person, contact: ContactEntry) async -> Bool {
        // Check if person was contact-based (not already an app user)
        guard person.personSource == .contact else {
            return false
        }

        // Update person to app_user status
        var updatedPerson = person
        updatedPerson.personSource = .appUser

        // Link contact ID if not already set
        if updatedPerson.contactId == nil {
            updatedPerson.contactId = contact.id
        }

        do {
            try dataManager.updatePerson(updatedPerson)
            print("DueLinkingService: Linked \(person.name) to app account")

            // Notify the user
            await notifyUserOfLink(person: updatedPerson)

            return true
        } catch {
            print("DueLinkingService: Failed to link app user: \(error)")
            return false
        }
    }

    /// Notify user that a contact has joined
    /// - Parameter person: The person who joined
    private func notifyUserOfLink(person: Person) async {
        // Show toast notification
        ToastManager.shared.showSuccess("\(person.name) joined Swiff!")
    }

    // MARK: - Statistics

    /// Get all people who were linked from contacts (for debugging/stats)
    var linkedPeopleCount: Int {
        dataManager.people.filter { $0.personSource == .appUser && $0.contactId != nil }.count
    }

    /// Get all people who are still contact-only (not yet on the app)
    var pendingContactsCount: Int {
        dataManager.people.filter { $0.personSource == .contact }.count
    }
}
