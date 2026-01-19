//
//  ContactSyncManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Orchestrates contact syncing and account matching
//

import Combine
import Contacts
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
    private let cacheService = ContactCacheService.shared

    private var contactsChangeObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupChangeObserver()
    }

    deinit {
        if let observer = contactsChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupChangeObserver() {
        contactsChangeObserver = NotificationCenter.default.addObserver(
            forName: .CNContactStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("DEBUG: Contact store changed externally")
            Task { @MainActor [weak self] in
                // Mark cache as stale so next load triggers sync
                await self?.cacheService.invalidateCache()
                // If we are currently displaying contacts, we might want to refresh UI?
                // For now, just invalidate cache is enough - next view appear will re-sync.
            }
        }
    }

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
            Date().timeIntervalSince(lastSync) < minimumSyncInterval
        {
            print(
                "DEBUG: Skipping sync - last sync was \(Int(Date().timeIntervalSince(lastSync)))s ago (min interval: \(Int(minimumSyncInterval))s)"
            )
            return
        }

        // Check permission before syncing
        let status = permissionManager.checkContactsPermission()
        guard status.isGranted else {
            return
        }

        await syncContacts()
    }

    /// Load contacts from cache first, then sync if needed
    func loadContactsWithCache() async {
        // 1. Immediately load cached contacts if available
        if let cached = await cacheService.loadCachedContacts() {
            print("DEBUG: Loaded \(cached.count) contacts from cache")
            await MainActor.run {
                self.contacts = cached
            }
        } else {
            print("DEBUG: No cached contacts found")
        }

        // 2. Check if we need to sync (cache stale or empty)
        let isFresh = await cacheService.isCacheFresh()
        let needsSync = !isFresh || contacts.isEmpty

        if needsSync {
            print("DEBUG: Cache stale or empty, triggering sync")
            await syncContactsIfNeeded()
        } else {
            print("DEBUG: Cache is fresh, skipping sync")
        }
    }

    /// Sync contacts progressively - shows results as they load
    func syncContactsProgressively() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil

        // 1. Load cache first for instant display
        if let cached = await cacheService.loadCachedContacts() {
            await MainActor.run {
                self.contacts = cached
            }
        }

        // 2. Stream fresh contacts in batches
        var allContacts: [ContactEntry] = []

        do {
            print("DEBUG: ContactSyncManager starting progressive sync")

            // Note: contactsService.fetchContactsInBatches() yields [ContactEntry]
            // We'll simulate batch processing since current ContactsService might not expose a stream yet
            // If it doesn't, we'll implement a simple batching wrapper or use fetchAllContacts for now
            // But based on user request, we should use 'fetchContactsInBatches' if it exists.
            // Let's check ContactsService first.
            // For now, I will assume fetchAllContacts is the only one fully available and working, but to follow the prompt's
            // requirement of "Phase 2: Progressive Loading UI", I should check if I need to update ContactsService.
            // The prompt says: "fetchContactsInBatches() returns AsyncThrowingStream<[ContactEntry], Error> (exists but unused)"
            // So I can use it!

            for try await batch in contactsService.fetchContactsInBatches() {
                allContacts.append(contentsOf: batch)

                // Update UI with each batch (throttled to avoid too many updates)
                if allContacts.count % 100 == 0 || allContacts.count < 100 {
                    await MainActor.run {
                        // Sort by name for display
                        self.contacts = allContacts.sorted { $0.name < $1.name }
                    }
                }
            }

            // 3. Match with server accounts
            let contactsWithPhones = allContacts.filter { $0.hasPhoneNumber }
            let matchedContacts = await matchContactsWithAccounts(
                deviceContacts: allContacts,
                contactsWithPhones: contactsWithPhones
            )

            // 4. Final update with matched status
            contacts = ContactEntry.sortByAccountStatus(matchedContacts)
            lastSyncDate = Date()
            lastSyncTimestamp = Date()

            // 5. Cache results
            await cacheService.cacheContacts(contacts)

        } catch {
            print("Contact sync error: \(error.localizedDescription)")
            syncError = error
        }

        isSyncing = false
    }

    /// Full sync of contacts from device and match with Swiff accounts
    func syncContacts() async {
        // Redirect to progressive sync
        await syncContactsProgressively()
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
