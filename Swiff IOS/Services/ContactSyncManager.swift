//
//  ContactSyncManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Orchestrates contact syncing and account matching
//

import Combine
import Foundation
import Supabase

/// Manages syncing of device contacts and matching with Swiff accounts
@MainActor
class ContactSyncManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ContactSyncManager()

    // MARK: - Published Properties

    @Published var contacts: [ContactEntry] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    // MARK: - Computed Properties

    /// Contacts with Swiff accounts
    var contactsOnSwiff: [ContactEntry] {
        contacts.filter { $0.hasAppAccount }
    }

    /// Contacts without Swiff accounts (can be invited)
    var contactsToInvite: [ContactEntry] {
        contacts.filter { !$0.hasAppAccount && $0.hasPhoneNumber }
    }

    /// Total contacts count
    var totalContactsCount: Int {
        contacts.count
    }

    /// Contacts on Swiff count
    var onSwiffCount: Int {
        contactsOnSwiff.count
    }

    // MARK: - Services

    private let contactsService = ContactsService.shared
    private let supabaseService = SupabaseService.shared
    private let permissionManager = SystemPermissionManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Sync Methods

    /// Sync contacts if permission is granted
    func syncContactsIfPermitted() async {
        // Check permission status
        let status = permissionManager.checkContactsPermission()
        guard status.isGranted else {
            // Permission not granted, don't sync
            return
        }

        await syncContacts()
    }

    /// Full sync of contacts from device and match with Swiff accounts
    func syncContacts() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        do {
            print("DEBUG: ContactSyncManager starting sync")
            // Step 1: Fetch all contacts from device
            let deviceContacts = try await contactsService.fetchAllContacts()

            // Step 2: Get contacts with phone numbers for matching
            let contactsWithPhones = deviceContacts.filter { $0.hasPhoneNumber }

            // Step 3: Match phone numbers against Swiff accounts
            let matchedContacts = await matchContactsWithAccounts(
                deviceContacts: deviceContacts, contactsWithPhones: contactsWithPhones)

            // Step 4: Update published contacts
            contacts = ContactEntry.sortByAccountStatus(matchedContacts)
            lastSyncDate = Date()

        } catch {
            syncError = error
            print("Contact sync error: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    // MARK: - Account Matching

    /// Match contacts with Swiff accounts using phone number hashes
    private func matchContactsWithAccounts(
        deviceContacts: [ContactEntry], contactsWithPhones: [ContactEntry]
    ) async -> [ContactEntry] {
        // Collect all phone numbers and their hashes
        var phoneHashMap: [String: (contactId: String, normalizedPhone: String)] = [:]

        for contact in contactsWithPhones {
            for phone in contact.phoneNumbers {
                let hash = PhoneNumberNormalizer.hash(phone)
                if !hash.isEmpty {
                    phoneHashMap[hash] = (contactId: contact.id, normalizedPhone: phone)
                }
            }
        }

        // If no phones to match, return original contacts
        guard !phoneHashMap.isEmpty else {
            return deviceContacts
        }

        // Get matched user IDs from server
        let matchedPhoneHashes = await fetchMatchedPhoneHashes(Array(phoneHashMap.keys))

        // Build set of matched contact IDs with their user info
        var matchedContactInfo: [String: (userId: UUID, phone: String)] = [:]

        for match in matchedPhoneHashes {
            if let mapping = phoneHashMap[match.phoneHash] {
                matchedContactInfo[mapping.contactId] = (
                    userId: match.userId, phone: mapping.normalizedPhone
                )
            }
        }

        // Update contacts with match status
        let updatedContacts = deviceContacts.map { contact -> ContactEntry in
            var updated = contact
            if let matchInfo = matchedContactInfo[contact.id] {
                updated.hasAppAccount = true
                updated.matchedUserId = matchInfo.userId
                updated.matchedPhone = matchInfo.phone
            }
            return updated
        }

        print("DEBUG: Matched \(matchedContactInfo.count) contacts with Swiff accounts")
        return updatedContacts
    }

    /// Fetch matched phone hashes from Supabase
    private func fetchMatchedPhoneHashes(_ hashes: [String]) async -> [PhoneMatchResult] {
        // Batch hashes in groups of 100 for efficient queries
        let batchSize = 100
        var allResults: [PhoneMatchResult] = []

        for batchStart in stride(from: 0, to: hashes.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, hashes.count)
            let batch = Array(hashes[batchStart..<batchEnd])

            do {
                let results = try await callMatchPhoneNumbersRPC(phoneHashes: batch)
                allResults.append(contentsOf: results)
            } catch {
                print("Error matching phone batch: \(error.localizedDescription)")
                // Continue with next batch even if one fails
            }
        }

        return allResults
    }

    /// Call the Supabase RPC function to match phone numbers
    private func callMatchPhoneNumbersRPC(phoneHashes: [String]) async throws -> [PhoneMatchResult]
    {
        // RPC call to match_phone_numbers function
        do {
            let response = try await supabaseService.client
                .rpc("match_phone_numbers", params: ["phone_hashes": phoneHashes])
                .execute()

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let results = try decoder.decode([PhoneMatchResult].self, from: response.data)
            return results

        } catch {
            // If RPC doesn't exist or fails, return empty (no matches)
            // This allows the app to work even without the server function
            print("RPC match_phone_numbers failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Search

    /// Search contacts by name, email, or phone
    func searchContacts(_ query: String) -> [ContactEntry] {
        guard !query.isEmpty else { return contacts }
        return contacts.search(query)
    }

    // MARK: - Refresh

    /// Force refresh contacts
    func refreshContacts() async {
        await syncContacts()
    }

    // MARK: - Statistics

    /// Get sync statistics
    var syncStatistics: String {
        """
        Total Contacts: \(totalContactsCount)
        On Swiff: \(onSwiffCount)
        To Invite: \(contactsToInvite.count)
        Last Sync: \(lastSyncDate?.formatted() ?? "Never")
        """
    }
}

// MARK: - Phone Match Result

struct PhoneMatchResult: Codable {
    let phoneHash: String
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case phoneHash = "phone_hash"
        case userId = "user_id"
    }
}
