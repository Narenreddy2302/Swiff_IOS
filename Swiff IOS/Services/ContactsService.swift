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

    /// FIX 3.2: Remove CNContactThumbnailImageDataKey from initial fetch
    /// Thumbnails will be loaded lazily via ContactThumbnailCache to save memory
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
        // REMOVED: CNContactThumbnailImageDataKey - loaded lazily now
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
    ]

    /// Keys for thumbnail fetch only (used by lazy loading cache)
    static let thumbnailKeys: [CNKeyDescriptor] = [
        CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]

    // MARK: - Pagination Configuration

    /// Configuration for paginated contact fetching
    struct FetchConfig: Sendable {
        var batchSize: Int = 100
        var maxContacts: Int = 10000

        nonisolated init() {}

        static let `default` = FetchConfig()
    }

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

                        // FIX 3.2: Create contact entry WITHOUT thumbnail data
                        // Thumbnails will be loaded lazily via ContactThumbnailCache
                        let entry = ContactEntry(
                            id: contact.identifier,
                            name: finalName,
                            phoneNumbers: phoneNumbers,
                            email: email,
                            thumbnailImageData: nil,  // Lazy loaded via ContactThumbnailCache
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

    // MARK: - Paginated Batch Fetching

    /// FIX 3.1: Fetch contacts in batches using AsyncThrowingStream
    /// This prevents memory spikes for devices with large contact lists
    func fetchContactsInBatches(config: FetchConfig = .default) -> AsyncThrowingStream<
        [ContactEntry], Error
    > {
        AsyncThrowingStream { continuation in
            Task.detached(priority: .userInitiated) { [keysToFetch, store] in
                guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
                    continuation.finish(throwing: ContactsError.permissionDenied)
                    return
                }

                let request = CNContactFetchRequest(keysToFetch: keysToFetch)
                request.sortOrder = .userDefault

                var currentBatch: [ContactEntry] = []
                var totalFetched = 0

                do {
                    try store.enumerateContacts(with: request) { contact, stopPointer in
                        // Respect max contacts limit
                        guard totalFetched < config.maxContacts else {
                            stopPointer.pointee = true
                            return
                        }

                        // Build name using formatter with fallback
                        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""

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

                        let phoneNumbers = contact.phoneNumbers.map { phoneValue in
                            PhoneNumberNormalizer.normalize(phoneValue.value.stringValue)
                        }.filter { !$0.isEmpty }

                        let email = contact.emailAddresses.first?.value as String?

                        let entry = ContactEntry(
                            id: contact.identifier,
                            name: finalName,
                            phoneNumbers: phoneNumbers,
                            email: email,
                            thumbnailImageData: nil,  // Lazy loaded
                            hasAppAccount: false
                        )

                        currentBatch.append(entry)
                        totalFetched += 1

                        // Yield batch when full
                        if currentBatch.count >= config.batchSize {
                            continuation.yield(currentBatch)
                            print(
                                "DEBUG: Yielded batch of \(currentBatch.count) contacts, total: \(totalFetched)"
                            )
                            currentBatch = []
                        }
                    }

                    // Yield remaining contacts
                    if !currentBatch.isEmpty {
                        continuation.yield(currentBatch)
                        print(
                            "DEBUG: Yielded final batch of \(currentBatch.count) contacts, total: \(totalFetched)"
                        )
                    }

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: ContactsError.fetchFailed(error))
                }
            }
        }
    }

    /// FIX 3.2: Fetch thumbnail for a single contact (for lazy loading cache)
    func fetchThumbnail(for contactId: String) async -> Data? {
        guard hasPermission else { return nil }

        return await Task.detached {
            do {
                let contact = try self.store.unifiedContact(
                    withIdentifier: contactId,
                    keysToFetch: ContactsService.thumbnailKeys
                )
                return contact.thumbnailImageData
            } catch {
                return nil
            }
        }.value
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

            // FIX 3.2: Don't include thumbnail - loaded lazily
            return ContactEntry(
                id: contact.identifier,
                name: name,
                phoneNumbers: phoneNumbers,
                email: email,
                thumbnailImageData: nil,  // Lazy loaded via ContactThumbnailCache
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
