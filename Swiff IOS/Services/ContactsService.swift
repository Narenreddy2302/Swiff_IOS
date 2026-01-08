//
//  ContactsService.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Service for fetching and managing iOS contacts
//

import Combine
import Contacts
import Foundation

/// Service for interacting with iOS Contacts
@MainActor
class ContactsService: ObservableObject {

    // MARK: - Singleton

    static let shared = ContactsService()

    // MARK: - Properties

    private let store = CNContactStore()

    @Published var isLoading = false
    @Published var lastError: Error?

    // MARK: - Keys to Fetch

    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactNicknameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
    ]

    // MARK: - Initialization

    private init() {}

    // MARK: - Permission Check

    /// Check if contacts permission is granted
    var hasPermission: Bool {
        CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    /// Check current authorization status
    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    // MARK: - Fetch All Contacts

    /// Fetch all contacts from the device
    /// - Returns: Array of ContactEntry objects
    func fetchAllContacts() async throws -> [ContactEntry] {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Check permission first
        guard hasPermission else {
            let error = ContactsError.permissionDenied
            lastError = error
            throw error
        }

        return try await withCheckedThrowingContinuation { continuation in
            print("DEBUG: Starting contact fetch via CNContactStore")

            // Run on background thread
            Task.detached(priority: .userInitiated) { [keysToFetch, store] in
                var contacts: [ContactEntry] = []

                let request = CNContactFetchRequest(keysToFetch: keysToFetch)
                request.sortOrder = .userDefault

                do {
                    try store.enumerateContacts(with: request) { contact, _ in
                        // Get full name using formatter (respects user's display preferences)
                        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""

                        // Skip contacts without names (buildName not available in detached task easily, simplified)
                        // If we need buildName, we'd need to move it or duplicate logic.
                        // Let's rely on formatter for now, or reimplement simple fallback.
                        // Actually, capturing 'self' in detached task is tricky if we want to use methods.
                        // Let's just implement the name logic inline or use a static helper.

                        var finalName = name
                        if finalName.isEmpty {
                            var components: [String] = []
                            if !contact.namePrefix.isEmpty { components.append(contact.namePrefix) }
                            if !contact.givenName.isEmpty { components.append(contact.givenName) }
                            if !contact.middleName.isEmpty { components.append(contact.middleName) }
                            if !contact.familyName.isEmpty { components.append(contact.familyName) }
                            if !contact.nameSuffix.isEmpty { components.append(contact.nameSuffix) }

                            if components.isEmpty && !contact.nickname.isEmpty {
                                finalName = contact.nickname
                            } else {
                                finalName = components.joined(separator: " ")
                            }
                        }

                        guard !finalName.isEmpty else { return }

                        // Normalize phone numbers
                        let phoneNumbers = contact.phoneNumbers.map { phoneValue in
                            PhoneNumberNormalizer.normalize(phoneValue.value.stringValue)
                        }.filter { !$0.isEmpty }

                        // Get primary email
                        let email = contact.emailAddresses.first?.value as String?

                        // Create contact entry
                        let entry = ContactEntry(
                            id: contact.identifier,
                            name: finalName,
                            phoneNumbers: phoneNumbers,
                            email: email,
                            thumbnailImageData: contact.thumbnailImageData,
                            hasAppAccount: false,
                            matchedUserId: nil,
                            matchedPhone: nil
                        )

                        contacts.append(entry)
                    }

                    // Sort alphabetically by name
                    let sortedContacts = ContactEntry.sortByName(contacts)
                    print("DEBUG: Fetched \(sortedContacts.count) contacts from device")
                    continuation.resume(returning: sortedContacts)

                } catch {
                    print("DEBUG: Failed to fetch contacts: \(error)")
                    continuation.resume(throwing: ContactsError.fetchFailed(error))
                }
            }
        }
    }

    /// Fetch contacts with phone numbers only (for account matching)
    func fetchContactsWithPhoneNumbers() async throws -> [ContactEntry] {
        let allContacts = try await fetchAllContacts()
        return allContacts.filter { $0.hasPhoneNumber }
    }

    // MARK: - Single Contact Fetch

    /// Fetch a single contact by identifier
    func fetchContact(identifier: String) async throws -> ContactEntry? {
        guard hasPermission else {
            throw ContactsError.permissionDenied
        }

        do {
            let contact = try store.unifiedContact(
                withIdentifier: identifier, keysToFetch: keysToFetch)
            let name =
                CNContactFormatter.string(from: contact, style: .fullName)
                ?? buildName(from: contact)

            let phoneNumbers = contact.phoneNumbers.map { phoneValue in
                PhoneNumberNormalizer.normalize(phoneValue.value.stringValue)
            }.filter { !$0.isEmpty }

            let email = contact.emailAddresses.first?.value as String?

            return ContactEntry(
                id: contact.identifier,
                name: name,
                phoneNumbers: phoneNumbers,
                email: email,
                thumbnailImageData: contact.thumbnailImageData,
                hasAppAccount: false
            )
        } catch {
            throw ContactsError.fetchFailed(error)
        }
    }

    // MARK: - Helper Methods

    /// Build name from contact components if formatter fails
    private func buildName(from contact: CNContact) -> String {
        var components: [String] = []

        if !contact.namePrefix.isEmpty {
            components.append(contact.namePrefix)
        }
        if !contact.givenName.isEmpty {
            components.append(contact.givenName)
        }
        if !contact.middleName.isEmpty {
            components.append(contact.middleName)
        }
        if !contact.familyName.isEmpty {
            components.append(contact.familyName)
        }
        if !contact.nameSuffix.isEmpty {
            components.append(contact.nameSuffix)
        }

        // Fallback to nickname if no name parts
        if components.isEmpty && !contact.nickname.isEmpty {
            return contact.nickname
        }

        return components.joined(separator: " ")
    }

    // MARK: - Statistics

    /// Get contact statistics
    func getStatistics() async -> ContactStatistics {
        do {
            let contacts = try await fetchAllContacts()
            let withPhone = contacts.filter { $0.hasPhoneNumber }
            let withEmail = contacts.filter { $0.hasEmail }

            return ContactStatistics(
                totalContacts: contacts.count,
                withPhoneNumbers: withPhone.count,
                withEmails: withEmail.count
            )
        } catch {
            return ContactStatistics(totalContacts: 0, withPhoneNumbers: 0, withEmails: 0)
        }
    }
}

// MARK: - Contact Statistics

struct ContactStatistics {
    let totalContacts: Int
    let withPhoneNumbers: Int
    let withEmails: Int

    var summary: String {
        """
        Total Contacts: \(totalContacts)
        With Phone Numbers: \(withPhoneNumbers)
        With Emails: \(withEmails)
        """
    }
}

// MARK: - Contacts Error

enum ContactsError: LocalizedError {
    case permissionDenied
    case fetchFailed(Error)
    case contactNotFound

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Contacts access denied. Please enable in Settings."
        case .fetchFailed(let error):
            return "Failed to fetch contacts: \(error.localizedDescription)"
        case .contactNotFound:
            return "Contact not found."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy > Contacts and enable access for Swiff."
        case .fetchFailed:
            return "Please try again later."
        case .contactNotFound:
            return "The contact may have been deleted."
        }
    }
}
