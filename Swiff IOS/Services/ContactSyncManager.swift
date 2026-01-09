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

    // MARK: - Sync Debouncing

    /// Timestamp of last successful sync (for debouncing)
    private var lastSyncTimestamp: Date?

    /// Minimum interval between syncs (5 minutes)
    private let minimumSyncInterval: TimeInterval = 300

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

    /// Sync contacts only if not synced recently (debounced)
    /// Use this for automatic syncs on view appear to prevent redundant syncs
    func syncContactsIfNeeded() async {
        // Skip if synced within the minimum interval
        if let lastSync = lastSyncTimestamp,
           Date().timeIntervalSince(lastSync) < minimumSyncInterval {
            print("DEBUG: Skipping sync - last sync was \(Int(Date().timeIntervalSince(lastSync)))s ago (min interval: \(Int(minimumSyncInterval))s)")
            return
        }

        // Check permission before syncing
        let status = permissionManager.checkContactsPermission()
        guard status.isGranted else {
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
            lastSyncTimestamp = Date()  // Record for debouncing

            // Step 5: Check for newly matched app users to link dues
            let newlyMatchedAppUsers = matchedContacts.filter { $0.hasAppAccount }
            if !newlyMatchedAppUsers.isEmpty {
                await DueLinkingService.shared.linkNewAppUsers(matchedContacts: newlyMatchedAppUsers)
            }

            print("DEBUG: ContactSyncManager sync complete - \(contacts.count) contacts")

        } catch {
            syncError = error
            print("Contact sync error: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    // MARK: - Account Matching

    /// Match contacts with Swiff accounts using phone number hashes
    /// Phone hashing is performed on a background thread to avoid blocking UI
    private func matchContactsWithAccounts(
        deviceContacts: [ContactEntry], contactsWithPhones: [ContactEntry]
    ) async -> [ContactEntry] {
        // FIX 2.1: Move CPU-intensive hashing to background thread
        let phoneHashMap = await Task.detached(priority: .userInitiated) {
            var hashMap: [String: (contactId: String, normalizedPhone: String)] = [:]

            for contact in contactsWithPhones {
                for phone in contact.phoneNumbers {
                    let hash = PhoneNumberNormalizer.hash(phone)
                    if !hash.isEmpty {
                        hashMap[hash] = (contactId: contact.id, normalizedPhone: phone)
                    }
                }
            }

            print("DEBUG: Hashed \(hashMap.count) phone numbers on background thread")
            return hashMap
        }.value

        // If no phones to match, return original contacts
        guard !phoneHashMap.isEmpty else {
            return deviceContacts
        }

        // Get matched user IDs from server (already async, uses parallel batching)
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

    /// Fetch matched phone hashes from Supabase using parallel batching
    /// FIX 2.3: Execute all batches in parallel for 3-5x speedup
    private func fetchMatchedPhoneHashes(_ hashes: [String]) async -> [PhoneMatchResult] {
        let batchSize = 100

        // Create batches
        var batches: [[String]] = []
        for batchStart in stride(from: 0, to: hashes.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, hashes.count)
            batches.append(Array(hashes[batchStart..<batchEnd]))
        }

        print("DEBUG: Fetching \(hashes.count) hashes in \(batches.count) parallel batches")

        // Execute all batches in parallel using TaskGroup
        return await withTaskGroup(of: [PhoneMatchResult].self) { group in
            for batch in batches {
                group.addTask {
                    do {
                        return try await self.callMatchPhoneNumbersRPC(phoneHashes: batch)
                    } catch {
                        print("Error matching phone batch: \(error.localizedDescription)")
                        return []
                    }
                }
            }

            // Collect all results
            var allResults: [PhoneMatchResult] = []
            for await results in group {
                allResults.append(contentsOf: results)
            }

            print("DEBUG: Received \(allResults.count) matches from server")
            return allResults
        }
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
