//
//  DataManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Centralized data manager for app state management
//  Updated by Agent to remove Cloud dependencies.
//

import Auth
import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - DataManager Errors

public enum DataManagerError: LocalizedError {
    case invalidAmount
    case personNotFound
    case contactImportFailed
    case persistenceError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .personNotFound:
            return "Person not found"
        case .contactImportFailed:
            return "Failed to import contact"
        case .persistenceError(let error):
            return "Persistence error: \(error.localizedDescription)"
        }
    }
}

@MainActor
public class DataManager: ObservableObject {

    // MARK: - Singleton
    public static let shared = DataManager()

    // MARK: - Published Properties

    @Published var people: [Person] = []
    @Published var groups: [Group] = []
    @Published var subscriptions: [Subscription] = []
    @Published var transactions: [Transaction] = []
    @Published var splitBills: [SplitBill] = []
    @Published var accounts: [Account] = []
    @Published var sharedSubscriptions: [SharedSubscription] = []

    /// Conversation messages keyed by entity ID (Person/Contact/Group/Subscription)
    @Published var conversationMessages: [UUID: [ConversationMessage]] = [:]

    @Published var isLoading = false
    @Published var error: Error?
    @Published var isFirstLaunch = false

    // Progress tracking for long-running operations
    @Published var operationProgress: Double? = nil
    @Published var operationMessage: String? = nil
    @Published var isPerformingOperation = false

    // MARK: - Real-Time Change Notifications

    /// Revision counter - increment to force view updates across the app
    @Published public var dataRevision: Int = 0

    /// Subject for granular change notifications
    public let dataChangeSubject = PassthroughSubject<DataChange, Never>()

    /// Enum describing what type of data change occurred
    public enum DataChange: Equatable {
        case personUpdated(UUID)
        case personAdded(UUID)
        case personDeleted(UUID)
        case groupUpdated(UUID)
        case groupAdded(UUID)
        case groupDeleted(UUID)
        case subscriptionUpdated(UUID)
        case subscriptionAdded(UUID)
        case subscriptionDeleted(UUID)
        case transactionUpdated(UUID)
        case transactionAdded(UUID)
        case transactionDeleted(UUID)
        case splitBillUpdated(UUID)
        case splitBillAdded(UUID)
        case splitBillDeleted(UUID)
        case accountUpdated(UUID)
        case accountAdded(UUID)
        case accountDeleted(UUID)
        case sharedSubscriptionUpdated(UUID)
        case sharedSubscriptionAdded(UUID)
        case sharedSubscriptionDeleted(UUID)
        case messageAdded(entityId: UUID)
        case messageDeleted(entityId: UUID)
        case allDataReloaded
    }

    // MARK: - Notification Batching (FIX 4.2)

    /// Pending notifications to be batched
    private var pendingNotifications: [DataChange] = []

    /// Task for debouncing notifications
    private var notificationBatchTask: Task<Void, Never>?

    /// Emit a change notification with batching to reduce cascading updates
    /// Changes are collected and emitted together within a single frame (~16ms)
    private func notifyChange(_ change: DataChange) {
        pendingNotifications.append(change)

        // Cancel any pending batch task
        notificationBatchTask?.cancel()

        // Batch notifications within approximately one frame (16ms)
        notificationBatchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 16_000_000)  // 16ms = ~1 frame at 60fps

            guard !Task.isCancelled else { return }

            // Send all pending notifications
            for notification in self.pendingNotifications {
                self.dataChangeSubject.send(notification)
            }

            // Single revision increment for all batched changes
            self.dataRevision += 1

            // Clear pending notifications
            self.pendingNotifications.removeAll()
        }
    }

    /// Emit change immediately (for critical updates that shouldn't be batched)
    private func notifyChangeImmediately(_ change: DataChange) {
        dataChangeSubject.send(change)
        dataRevision += 1
    }

    // MARK: - Preview Mode Detection

    // nonisolated so it can be accessed from deinit
    private nonisolated static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    // MARK: - Private Properties

    private let persistenceService = PersistenceService.shared
    private let renewalService = SubscriptionRenewalService.shared
    private let firstLaunchKey = "HasLaunchedBefore"

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var hasData: Bool {
        !people.isEmpty || !groups.isEmpty || !subscriptions.isEmpty || !transactions.isEmpty
            || !splitBills.isEmpty || !accounts.isEmpty
    }

    var accountsCount: Int { accounts.count }
    var peopleCount: Int { people.count }
    var groupsCount: Int { groups.count }
    var subscriptionsCount: Int { subscriptions.count }
    var transactionsCount: Int { transactions.count }
    var splitBillsCount: Int { splitBills.count }
    var sharedSubscriptionsCount: Int { sharedSubscriptions.count }

    // MARK: - Contacts (Delegated to ContactSyncManager)

    /// Device contacts (fetched from CNContactStore)
    var contacts: [ContactEntry] {
        ContactSyncManager.shared.contacts
    }

    /// Contacts with Swiff accounts
    var contactsOnSwiff: [ContactEntry] {
        ContactSyncManager.shared.contactsOnSwiff
    }

    /// Contacts available to invite
    var contactsToInvite: [ContactEntry] {
        ContactSyncManager.shared.contactsToInvite
    }

    var contactsCount: Int { contacts.count }
    var contactsOnSwiffCount: Int { contactsOnSwiff.count }

    /// Sync device contacts and match with Swiff accounts
    func syncContacts() async {
        await ContactSyncManager.shared.syncContactsIfPermitted()
    }

    // MARK: - Initialization

    private init() {
        checkFirstLaunch()
    }

    // MARK: - Data Loading

    /// FIX 2.2: Public entry point - dispatches to async version to avoid blocking UI
    public func loadAllData() {
        isLoading = true
        error = nil

        Task { @MainActor in
            await loadAllDataAsync()
        }
    }

    /// FIX 2.2: Async version that loads all data types in parallel
    private func loadAllDataAsync() async {
        do {
            // Load all data types in parallel using async let
            // This prevents sequential blocking and significantly speeds up startup
            async let peopleResult = Task { @MainActor in
                try self.persistenceService.fetchAllPeople()
            }.value

            async let groupsResult = Task { @MainActor in
                try self.persistenceService.fetchAllGroups()
            }.value

            async let subscriptionsResult = Task { @MainActor in
                try self.persistenceService.fetchAllSubscriptions()
            }.value

            async let transactionsResult = Task { @MainActor in
                try self.persistenceService.fetchAllTransactions()
            }.value

            async let splitBillsResult = Task { @MainActor in
                try self.persistenceService.fetchAllSplitBills()
            }.value

            async let accountsResult = Task { @MainActor in
                try self.persistenceService.fetchAllAccounts()
            }.value

            async let sharedSubsResult = Task { @MainActor in
                (try? self.persistenceService.fetchAllSharedSubscriptions()) ?? []
            }.value

            // Await all in parallel - UI remains responsive during this time
            let (
                loadedPeople,
                loadedGroups,
                loadedSubscriptions,
                loadedTransactions,
                loadedSplitBills,
                loadedAccounts,
                loadedSharedSubs
            ) = try await (
                peopleResult,
                groupsResult,
                subscriptionsResult,
                transactionsResult,
                splitBillsResult,
                accountsResult,
                sharedSubsResult
            )

            // Update published properties on main actor
            people = loadedPeople
            groups = loadedGroups
            subscriptions = loadedSubscriptions
            transactions = loadedTransactions
            splitBills = loadedSplitBills
            accounts = loadedAccounts
            sharedSubscriptions = loadedSharedSubs

            isLoading = false

            print("✅ Data loaded successfully (async):")
            print("   - People: \(people.count)")
            print("   - Groups: \(groups.count)")
            print("   - Subscriptions: \(subscriptions.count)")
            print("   - Transactions: \(transactions.count)")
            print("   - Split Bills: \(splitBills.count)")
            print("   - Accounts: \(accounts.count)")
            print("   - Shared Subscriptions: \(sharedSubscriptions.count)")

            // Process overdue subscription renewals
            await renewalService.processOverdueRenewals()

            // Notify all views that data has been reloaded
            notifyChange(.allDataReloaded)

        } catch {
            self.error = error
            isLoading = false
            print("❌ Error loading data: \(error.localizedDescription)")
        }
    }

    public func refreshAllData() {
        loadAllData()
    }

    // MARK: - Person CRUD Operations

    public func addPerson(_ person: Person) throws {
        // Save locally first
        try persistenceService.savePerson(person)
        people.append(person)
        print("Person added: \(person.name)")

        // Index in Spotlight
        indexPersonInSpotlight(person)

        // Notify views of the change
        notifyChange(.personAdded(person.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = person.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.persons,
                record: supabaseModel,
                id: person.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    public func updatePerson(_ person: Person) throws {
        try persistenceService.updatePerson(person)
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
            print("Person updated: \(person.name)")

            // Update in Spotlight
            indexPersonInSpotlight(person)

            // Notify views of the change
            notifyChange(.personUpdated(person.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = person.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.persons,
                    record: supabaseModel,
                    id: person.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    public func deletePerson(id: UUID) throws {
        try persistenceService.deletePerson(id: id)
        people.removeAll { $0.id == id }
        print("Person deleted")

        // Remove from Spotlight
        removePersonFromSpotlight(id)

        // Notify views of the change
        notifyChange(.personDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.persons,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    public func searchPeople(byName searchTerm: String) -> [Person] {
        if searchTerm.isEmpty {
            return people
        }
        return people.filter { $0.name.localizedStandardContains(searchTerm) }
    }

    func importContact(_ contact: ContactEntry) throws -> Person {
        // Check if person already exists by contact ID
        if let existing = people.first(where: { $0.contactId == contact.id }) {
            return existing
        }

        // Check if person exists by phone number (cleaning it first)
        let contactPhones = contact.phoneNumbers.map { PhoneNumberNormalizer.normalize($0) }
        if let existing = people.first(where: { person in
            let personPhone = PhoneNumberNormalizer.normalize(person.phone)
            return contactPhones.contains(personPhone)
        }) {
            // Update contact ID for future reference
            var updated = existing
            updated.contactId = contact.id
            try updatePerson(updated)
            return updated
        }

        // Create new person with appropriate source
        let personSource: PersonSource = contact.hasAppAccount ? .appUser : .contact

        let newPerson = Person(
            name: contact.name,
            email: contact.email ?? "",
            phone: contact.primaryPhone ?? "",
            avatarType: .initials(
                contact.initials,
                colorIndex: AvatarColorPalette.colorIndex(for: contact.name)
            ),
            contactId: contact.id,
            personSource: personSource
        )

        try addPerson(newPerson)
        return newPerson
    }

    // MARK: - Group CRUD Operations

    func addGroup(_ group: Group) throws {
        try persistenceService.saveGroup(group)
        groups.append(group)
        print("Group added: \(group.name)")

        // Notify views of the change
        notifyChange(.groupAdded(group.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = group.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.groups,
                record: supabaseModel,
                id: group.id
            )
            // Also sync group members
            for memberModel in group.membersToSupabaseModels() {
                SyncService.shared.queueInsert(
                    table: SupabaseConfig.Tables.groupMembers,
                    record: memberModel,
                    id: memberModel.id
                )
            }
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func updateGroup(_ group: Group) throws {
        try persistenceService.updateGroup(group)
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            print("Group updated: \(group.name)")

            // Notify views of the change
            notifyChange(.groupUpdated(group.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = group.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.groups,
                    record: supabaseModel,
                    id: group.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    public func deleteGroup(id: UUID) throws {
        try persistenceService.deleteGroup(id: id)
        groups.removeAll { $0.id == id }
        print("Group deleted")

        // Notify views of the change
        notifyChange(.groupDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.groups,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func fetchGroupsWithUnsettledExpenses() -> [Group] {
        groups.filter { group in
            group.expenses.contains { !$0.isSettled }
        }
    }

    // MARK: - Subscription CRUD Operations

    func addSubscription(_ subscription: Subscription) throws {
        try persistenceService.saveSubscription(subscription)
        subscriptions.append(subscription)
        print("Subscription added: \(subscription.name)")

        // Index in Spotlight
        indexSubscriptionInSpotlight(subscription)

        // Notify views of the change
        notifyChange(.subscriptionAdded(subscription.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = subscription.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.subscriptions,
                record: supabaseModel,
                id: subscription.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func updateSubscription(_ subscription: Subscription) throws {
        // Detect price changes before updating
        if let oldSubscription = subscriptions.first(where: { $0.id == subscription.id }) {
            if oldSubscription.price != subscription.price {
                // Price has changed - create price change record
                let priceChange = PriceChange(
                    subscriptionId: subscription.id,
                    oldPrice: oldSubscription.price,
                    newPrice: subscription.price,
                    detectedAutomatically: true
                )

                do {
                    try addPriceChange(priceChange)

                } catch {
                    print("Failed to create price change record: \(error.localizedDescription)")
                }
            }
        }

        try persistenceService.updateSubscription(subscription)
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            print("Subscription updated: \(subscription.name)")

            // Update in Spotlight
            indexSubscriptionInSpotlight(subscription)

            // Notify views of the change
            notifyChange(.subscriptionUpdated(subscription.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = subscription.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.subscriptions,
                    record: supabaseModel,
                    id: subscription.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    public func deleteSubscription(id: UUID) throws {

        try persistenceService.deleteSubscription(id: id)
        subscriptions.removeAll { $0.id == id }
        print("Subscription deleted")

        // Remove from Spotlight
        removeSubscriptionFromSpotlight(id)

        // Notify views of the change
        notifyChange(.subscriptionDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.subscriptions,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func getActiveSubscriptions() -> [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    func getInactiveSubscriptions() -> [Subscription] {
        subscriptions.filter { !$0.isActive }
    }

    // MARK: - Shared Subscription CRUD Operations

    /// Add a new shared subscription
    func addSharedSubscription(_ sharedSubscription: SharedSubscription) throws {
        try persistenceService.saveSharedSubscription(sharedSubscription)
        sharedSubscriptions.append(sharedSubscription)
        print("Shared subscription added: \(sharedSubscription.notes)")

        notifyChange(.sharedSubscriptionAdded(sharedSubscription.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = sharedSubscription.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.sharedSubscriptions,
                record: supabaseModel,
                id: sharedSubscription.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    /// Update an existing shared subscription
    func updateSharedSubscription(_ sharedSubscription: SharedSubscription) throws {
        try persistenceService.updateSharedSubscription(sharedSubscription)
        if let index = sharedSubscriptions.firstIndex(where: { $0.id == sharedSubscription.id }) {
            sharedSubscriptions[index] = sharedSubscription
            print("Shared subscription updated: \(sharedSubscription.notes)")

            notifyChange(.sharedSubscriptionUpdated(sharedSubscription.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = sharedSubscription.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.sharedSubscriptions,
                    record: supabaseModel,
                    id: sharedSubscription.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    /// Delete a shared subscription
    public func deleteSharedSubscription(id: UUID) throws {
        try persistenceService.deleteSharedSubscription(id: id)
        sharedSubscriptions.removeAll { $0.id == id }
        print("Shared subscription deleted")

        notifyChange(.sharedSubscriptionDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.sharedSubscriptions,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    /// Get shared subscriptions for a specific person (where they are sharedBy or in sharedWith)
    func getSharedSubscriptionsForPerson(personId: UUID) -> [SharedSubscription] {
        return sharedSubscriptions.filter { shared in
            shared.sharedBy == personId || shared.sharedWith.contains(personId)
        }
    }

    /// Create a shared subscription from an existing personal subscription
    func shareSubscription(
        _ subscription: Subscription,
        with people: [UUID],
        splitType: CostSplitType,
        ownerId: UUID? = nil
    ) throws {
        // Calculate individual cost based on split type
        let totalPeople = people.count + 1  // +1 for owner
        let individualCost = subscription.monthlyEquivalent / Double(totalPeople)

        // Create shared subscription record
        var sharedSub = SharedSubscription(
            subscriptionId: subscription.id,
            sharedBy: ownerId ?? UUID(),  // In production, use current user ID
            sharedWith: people,
            costSplit: splitType
        )
        sharedSub.individualCost = individualCost
        sharedSub.isAccepted = true  // Auto-accept for now
        sharedSub.notes = subscription.name

        // Save shared subscription
        try addSharedSubscription(sharedSub)

        // Update the base subscription's isShared flag
        var updatedSubscription = subscription
        updatedSubscription.isShared = true
        updatedSubscription.sharedWith = people
        try updateSubscription(updatedSubscription)
    }

    /// Unshare a subscription (remove shared subscription record)
    public func unshareSubscription(sharedSubscriptionId: UUID) throws {
        guard let sharedSub = sharedSubscriptions.first(where: { $0.id == sharedSubscriptionId })
        else {
            return
        }

        // Find and update the base subscription
        if var baseSubscription = subscriptions.first(where: { $0.id == sharedSub.subscriptionId })
        {
            baseSubscription.isShared = false
            baseSubscription.sharedWith = []
            try updateSubscription(baseSubscription)
        }

        // Delete the shared subscription record
        try deleteSharedSubscription(id: sharedSubscriptionId)
    }

    // MARK: - Account Operations

    /// Add a new account
    public func addAccount(_ account: Account) throws {
        try persistenceService.saveAccount(account)
        accounts.append(account)
        print("Account added: \(account.name)")

        // Notify views of the change
        notifyChange(.accountAdded(account.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = account.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.accounts,
                record: supabaseModel,
                id: account.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    /// Update an existing account
    public func updateAccount(_ account: Account) throws {
        try persistenceService.updateAccount(account)
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            print("Account updated: \(account.name)")

            // Notify views of the change
            notifyChange(.accountUpdated(account.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = account.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.accounts,
                    record: supabaseModel,
                    id: account.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    /// Delete an account
    public func deleteAccount(id: UUID) throws {
        try persistenceService.deleteAccount(id: id)
        accounts.removeAll { $0.id == id }
        print("Account deleted")

        // Notify views of the change
        notifyChange(.accountDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.accounts,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    /// Get the default account
    public func getDefaultAccount() -> Account? {
        accounts.first { $0.isDefault } ?? accounts.first
    }

    /// Set an account as default
    public func setDefaultAccount(_ account: Account) throws {
        var updatedAccount = account
        updatedAccount.isDefault = true
        try updateAccount(updatedAccount)

        // Update local state to reflect the change
        for i in accounts.indices {
            accounts[i].isDefault = (accounts[i].id == account.id)
        }
    }

    // MARK: - Price Change Operations (AGENT 9)

    public func addPriceChange(_ priceChange: PriceChange) throws {
        try persistenceService.savePriceChange(priceChange)
        print("✅ Price change recorded: \(priceChange.oldPrice.asCurrency) → \(priceChange.newPrice.asCurrency)")

        // Notify views that the subscription has been updated (price changed)
        notifyChange(.subscriptionUpdated(priceChange.subscriptionId))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            let supabaseModel = priceChange.toSupabaseModel()
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.priceChanges,
                record: supabaseModel,
                id: priceChange.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    public func getPriceHistory(for subscriptionId: UUID) -> [PriceChange] {
        do {
            return try persistenceService.fetchPriceChanges(forSubscription: subscriptionId)
        } catch {
            print("❌ Error fetching price history: \(error.localizedDescription)")
            return []
        }
    }

    public func getAllPriceChanges() -> [PriceChange] {
        do {
            return try persistenceService.fetchAllPriceChanges()
        } catch {
            print("❌ Error fetching all price changes: \(error.localizedDescription)")
            return []
        }
    }

    public func getRecentPriceIncreases(days: Int = 30) -> [PriceChange] {
        do {
            return try persistenceService.fetchRecentPriceIncreases(days: days)
        } catch {
            print("❌ Error fetching recent price increases: \(error.localizedDescription)")
            return []
        }
    }

    func getSubscriptionsWithRecentPriceIncreases(days: Int = 30) -> [Subscription] {
        let recentIncreases = getRecentPriceIncreases(days: days)
        let subscriptionIds = Set(recentIncreases.map { $0.subscriptionId })

        return subscriptions.filter { subscriptionIds.contains($0.id) }
    }

    // MARK: - Subscription Renewal Methods

    /// Get subscription renewal statistics
    func getSubscriptionStatistics() -> SubscriptionStatistics {
        return renewalService.getStatistics()
    }

    /// Get subscriptions renewing within specified days
    func getUpcomingRenewals(within days: Int) -> [Subscription] {
        return renewalService.getUpcomingRenewals(within: days)
    }

    /// Get subscriptions renewing today
    func getTodayRenewals() -> [Subscription] {
        return renewalService.getTodayRenewals()
    }

    /// Get subscriptions renewing this week
    func getWeekRenewals() -> [Subscription] {
        return renewalService.getWeekRenewals()
    }

    /// Process overdue subscription renewals manually
    public func processOverdueRenewals() async {
        await renewalService.processOverdueRenewals()
        loadAllData()  // Reload data to reflect changes
    }

    /// Pause a subscription
    func pauseSubscription(_ subscription: Subscription) async {
        await renewalService.pauseSubscription(subscription)
        loadAllData()  // Reload data to reflect changes
    }

    /// Resume a paused subscription
    func resumeSubscription(_ subscription: Subscription) async {
        await renewalService.resumeSubscription(subscription)
        loadAllData()  // Reload data to reflect changes
    }

    /// Cancel a subscription permanently
    func cancelSubscription(_ subscription: Subscription) async {
        await renewalService.cancelSubscription(subscription)
        loadAllData()  // Reload data to reflect changes
    }

    // MARK: - Transaction CRUD Operations

    func addTransaction(_ transaction: Transaction) throws {
        try persistenceService.saveTransaction(transaction)
        transactions.append(transaction)
        transactions.sort { $0.date > $1.date }  // Keep sorted by date
        print("Transaction added: \(transaction.title)")

        // Index in Spotlight
        indexTransactionInSpotlight(transaction)

        // Notify views of the change
        notifyChange(.transactionAdded(transaction.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = transaction.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.transactions,
                record: supabaseModel,
                id: transaction.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func updateTransaction(_ transaction: Transaction) throws {
        try persistenceService.updateTransaction(transaction)
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date }  // Re-sort
            print("Transaction updated: \(transaction.title)")

            // Update in Spotlight
            indexTransactionInSpotlight(transaction)

            // Notify views of the change
            notifyChange(.transactionUpdated(transaction.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = transaction.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.transactions,
                    record: supabaseModel,
                    id: transaction.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    public func deleteTransaction(id: UUID) throws {
        try persistenceService.deleteTransaction(id: id)
        transactions.removeAll { $0.id == id }
        print("Transaction deleted")

        // Remove from Spotlight
        removeTransactionFromSpotlight(id)

        // Notify views of the change
        notifyChange(.transactionDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.transactions,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func getCurrentMonthTransactions() -> [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)),
            let endOfMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else {
            print("⚠️ Failed to calculate month boundaries, returning all transactions")
            return transactions
        }

        return transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
    }

    func getRecurringTransactions() -> [Transaction] {
        transactions.filter { $0.isRecurring }
    }

    // MARK: - Bulk Transaction Operations

    /// Bulk delete multiple transactions
    public func bulkDeleteTransactions(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }

        // Delete from persistence and queue for Supabase sync
        for id in ids {
            try persistenceService.deleteTransaction(id: id)

            // Queue for Supabase sync
            if SupabaseService.shared.currentUser != nil {
                SyncService.shared.queueDelete(
                    table: SupabaseConfig.Tables.transactions,
                    id: id
                )
            }

            // Notify views
            notifyChange(.transactionDeleted(id))
        }

        // Remove from local array
        transactions.removeAll { ids.contains($0.id) }

        // Sync pending changes
        if SupabaseService.shared.currentUser != nil {
            Task { await SyncService.shared.syncPendingChanges() }
        }

        print("✅ Bulk delete complete: \(ids.count) transaction(s) deleted")
    }

    /// Bulk update category for multiple transactions
    func bulkUpdateCategory(transactionIds: [UUID], category: TransactionCategory) throws {
        guard !transactionIds.isEmpty else { return }

        let userId = SupabaseService.shared.currentUser?.id

        // Update each transaction
        for id in transactionIds {
            if let index = transactions.firstIndex(where: { $0.id == id }) {
                var updatedTransaction = transactions[index]
                updatedTransaction.category = category

                // Update in persistence
                try persistenceService.updateTransaction(updatedTransaction)

                // Update in local array
                transactions[index] = updatedTransaction

                // Notify views
                notifyChange(.transactionUpdated(id))

                // Queue for Supabase sync
                if let userId = userId {
                    let supabaseModel = updatedTransaction.toSupabaseModel(userId: userId)
                    SyncService.shared.queueUpdate(
                        table: SupabaseConfig.Tables.transactions,
                        record: supabaseModel,
                        id: id
                    )
                }
            }
        }

        // Sync pending changes
        if userId != nil {
            Task { await SyncService.shared.syncPendingChanges() }
        }

        print(
            "✅ Bulk category update complete: \(transactionIds.count) transaction(s) updated to \(category.rawValue)"
        )
    }

    /// Bulk add tags to multiple transactions
    public func bulkAddTags(transactionIds: [UUID], tags: [String]) throws {
        guard !transactionIds.isEmpty, !tags.isEmpty else { return }

        let userId = SupabaseService.shared.currentUser?.id

        // Update each transaction
        for id in transactionIds {
            if let index = transactions.firstIndex(where: { $0.id == id }) {
                var updatedTransaction = transactions[index]

                // Add new tags, avoiding duplicates
                for tag in tags {
                    if !updatedTransaction.tags.contains(tag) {
                        updatedTransaction.tags.append(tag)
                    }
                }

                // Update in persistence
                try persistenceService.updateTransaction(updatedTransaction)

                // Update in local array
                transactions[index] = updatedTransaction

                // Notify views
                notifyChange(.transactionUpdated(id))

                // Queue for Supabase sync
                if let userId = userId {
                    let supabaseModel = updatedTransaction.toSupabaseModel(userId: userId)
                    SyncService.shared.queueUpdate(
                        table: SupabaseConfig.Tables.transactions,
                        record: supabaseModel,
                        id: id
                    )
                }
            }
        }

        // Sync pending changes
        if userId != nil {
            Task { await SyncService.shared.syncPendingChanges() }
        }

        print(
            "✅ Bulk tag addition complete: \(tags.count) tag(s) added to \(transactionIds.count) transaction(s)"
        )
    }

    // MARK: - Group Expense Operations

    func addGroupExpense(_ expense: GroupExpense, toGroup groupID: UUID) throws {
        try persistenceService.saveGroupExpense(expense, forGroup: groupID)

        // Update local group
        if let index = groups.firstIndex(where: { $0.id == groupID }) {
            var updatedGroup = groups[index]
            updatedGroup.expenses.append(expense)
            updatedGroup.totalAmount += expense.amount
            groups[index] = updatedGroup
            print("✅ Expense added to group: \(expense.title)")

            // Notify views of the change
            notifyChange(.groupUpdated(groupID))

            // Queue for Supabase sync
            if SupabaseService.shared.currentUser != nil {
                let supabaseModel = expense.toSupabaseModel(groupId: groupID)
                SyncService.shared.queueInsert(
                    table: SupabaseConfig.Tables.groupExpenses,
                    record: supabaseModel,
                    id: expense.id
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    public func settleExpense(id: UUID, inGroup groupID: UUID) throws {
        try persistenceService.settleExpense(id: id)

        // Update local group
        if let groupIndex = groups.firstIndex(where: { $0.id == groupID }) {
            var updatedGroup = groups[groupIndex]
            if let expenseIndex = updatedGroup.expenses.firstIndex(where: { $0.id == id }) {
                updatedGroup.expenses[expenseIndex].isSettled = true
                groups[groupIndex] = updatedGroup

                // Notify views of the change
                notifyChange(.groupUpdated(groupID))
                print("✅ Expense settled")

                // Queue for Supabase sync
                if SupabaseService.shared.currentUser != nil {
                    let settledExpense = updatedGroup.expenses[expenseIndex]
                    let supabaseModel = settledExpense.toSupabaseModel(groupId: groupID)
                    SyncService.shared.queueUpdate(
                        table: SupabaseConfig.Tables.groupExpenses,
                        record: supabaseModel,
                        id: id
                    )
                    Task { await SyncService.shared.syncPendingChanges() }
                }
            }
        }
    }

    func updateGroupExpense(_ expense: GroupExpense, inGroup groupID: UUID) throws {
        // saveGroupExpense handles both create and update
        try persistenceService.saveGroupExpense(expense, forGroup: groupID)

        // Update local group
        if let groupIndex = groups.firstIndex(where: { $0.id == groupID }) {
            var updatedGroup = groups[groupIndex]
            if let expenseIndex = updatedGroup.expenses.firstIndex(where: { $0.id == expense.id }) {
                updatedGroup.expenses[expenseIndex] = expense
                groups[groupIndex] = updatedGroup

                // Notify views of the change
                notifyChange(.groupUpdated(groupID))
                print("✅ Group expense updated: \(expense.title)")

                // Queue for Supabase sync
                if SupabaseService.shared.currentUser != nil {
                    let supabaseModel = expense.toSupabaseModel(groupId: groupID)
                    SyncService.shared.queueUpdate(
                        table: SupabaseConfig.Tables.groupExpenses,
                        record: supabaseModel,
                        id: expense.id
                    )
                    Task { await SyncService.shared.syncPendingChanges() }
                }
            }
        }
    }

    // MARK: - Split Bill CRUD Operations

    func addSplitBill(_ splitBill: SplitBill) throws {
        try persistenceService.saveSplitBill(splitBill)
        splitBills.append(splitBill)

        // Update Person balances
        try updateBalancesForSplitBill(splitBill)

        print("Split bill added: \(splitBill.title)")

        // Notify views of the change
        notifyChange(.splitBillAdded(splitBill.id))

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = splitBill.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.splitBills,
                record: supabaseModel,
                id: splitBill.id
            )
            // Also sync participants
            for participantModel in splitBill.participantsToSupabaseModels() {
                SyncService.shared.queueInsert(
                    table: SupabaseConfig.Tables.splitParticipants,
                    record: participantModel,
                    id: participantModel.id
                )
            }
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    func updateSplitBill(_ splitBill: SplitBill) throws {
        try persistenceService.updateSplitBill(splitBill)
        if let index = splitBills.firstIndex(where: { $0.id == splitBill.id }) {
            splitBills[index] = splitBill
            print("Split bill updated: \(splitBill.title)")

            // Notify views of the change
            notifyChange(.splitBillUpdated(splitBill.id))

            // Queue for Supabase sync
            if let userId = SupabaseService.shared.currentUser?.id {
                let supabaseModel = splitBill.toSupabaseModel(userId: userId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.splitBills,
                    record: supabaseModel,
                    id: splitBill.id
                )
                // Also update participants
                for participantModel in splitBill.participantsToSupabaseModels() {
                    SyncService.shared.queueUpdate(
                        table: SupabaseConfig.Tables.splitParticipants,
                        record: participantModel,
                        id: participantModel.id
                    )
                }
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    public func deleteSplitBill(id: UUID) throws {
        try persistenceService.deleteSplitBill(id: id)
        splitBills.removeAll { $0.id == id }
        print("Split bill deleted")

        // Notify views of the change
        notifyChange(.splitBillDeleted(id))

        // Queue for Supabase sync
        if SupabaseService.shared.currentUser != nil {
            SyncService.shared.queueDelete(
                table: SupabaseConfig.Tables.splitBills,
                id: id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }
    }

    public func markParticipantAsPaid(splitBillId: UUID, participantId: UUID) throws {
        guard let index = splitBills.firstIndex(where: { $0.id == splitBillId }) else { return }

        var updatedSplitBill = splitBills[index]
        if let participantIndex = updatedSplitBill.participants.firstIndex(where: {
            $0.id == participantId
        }) {
            updatedSplitBill.participants[participantIndex].hasPaid = true
            updatedSplitBill.participants[participantIndex].paymentDate = Date()

            // Update local persistence
            try persistenceService.updateSplitBill(updatedSplitBill)
            splitBills[index] = updatedSplitBill

            // Notify views of the change
            notifyChange(.splitBillUpdated(splitBillId))
            print("✅ Participant marked as paid")

            // Queue for Supabase sync
            if SupabaseService.shared.currentUser != nil {
                let participant = updatedSplitBill.participants[participantIndex]
                let participantModel = participant.toSupabaseModel(splitBillId: splitBillId)
                SyncService.shared.queueUpdate(
                    table: SupabaseConfig.Tables.splitParticipants,
                    record: participantModel,
                    id: participantId
                )
                Task { await SyncService.shared.syncPendingChanges() }
            }
        }
    }

    /// Update balances for all people involved in a split bill
    private func updateBalancesForSplitBill(_ splitBill: SplitBill) throws {
        // Find the person who paid
        guard let payerIndex = people.firstIndex(where: { $0.id == splitBill.paidById }) else {
            print("⚠️ Payer not found for split bill")
            return
        }

        // For each participant (except payer), update balances
        for participant in splitBill.participants {
            // Skip if participant is the payer
            guard participant.personId != splitBill.paidById else { continue }

            guard let personIndex = people.firstIndex(where: { $0.id == participant.personId })
            else {
                print("⚠️ Participant not found: \(participant.personId)")
                continue
            }

            // Participant owes the payer their portion
            // Payer's balance increases (positive = they owe you)
            people[payerIndex].balance += participant.amount

            // Update both people in persistence
            try persistenceService.updatePerson(people[payerIndex])
            try persistenceService.updatePerson(people[personIndex])

            print("📊 Balance updated: Payer balance +$\(participant.amount)")
        }
    }

    /// Get all split bills involving a specific person (as payer or participant)
    func getSplitBillsForPerson(personId: UUID) -> [SplitBill] {
        return splitBills.filter { splitBill in
            splitBill.paidById == personId
                || splitBill.participants.contains { $0.personId == personId }
        }
    }

    /// Get all split bills for a specific group
    func getSplitBillsForGroup(groupId: UUID) -> [SplitBill] {
        return splitBills.filter { $0.groupId == groupId }
    }

    /// Get unsettled split bills (where not all participants have paid)
    func getUnsettledSplitBills() -> [SplitBill] {
        return splitBills.filter { !$0.isFullySettled }
    }

    // MARK: - Contact Due Operations

    /// Create a simple due (IOU) with a contact
    /// - Parameters:
    ///   - contact: The contact entry from iOS contacts
    ///   - amount: The amount of the due
    ///   - theyOweMe: If true, the contact owes the current user; if false, current user owes them
    ///   - description: Description of what the due is for
    ///   - category: Transaction category
    ///   - date: The date of the due (defaults to now)
    ///   - notes: Optional notes
    /// - Returns: The created SplitBill representing the due
    @discardableResult
    func createSimpleDue(
        contact: ContactEntry,
        amount: Double,
        theyOweMe: Bool,
        description: String,
        category: TransactionCategory,
        date: Date = Date(),
        notes: String? = nil
    ) throws -> SplitBill {
        // Validate amount
        guard amount > 0 else {
            throw DataManagerError.invalidAmount
        }

        // 1. Import contact as Person if not exists
        var person = try importContact(contact)

        // 2. Ensure person source is set correctly
        if person.personSource == .manual {
            person.personSource = contact.hasAppAccount ? .appUser : .contact
        }

        // 3. Update person's balance directly
        // Balance convention: positive = they owe you, negative = you owe them
        if theyOweMe {
            // They owe me: increase their balance (they owe more)
            person.balance += amount
        } else {
            // I owe them: decrease their balance (I owe them, shown as negative from my perspective)
            person.balance -= amount
        }

        // 4. Save the updated person
        try updatePerson(person)

        // 5. Get current user ID for record keeping
        let currentUserId = getCurrentUserId()

        // 6. Determine payer for the split bill record
        let paidById = theyOweMe ? currentUserId : person.id

        // 7. Create participant record
        let participant = SplitParticipant(
            personId: theyOweMe ? person.id : currentUserId,
            amount: amount,
            hasPaid: false
        )

        // 8. Create SplitBill for record keeping (not for balance calculation)
        let splitBill = SplitBill(
            title: description,
            totalAmount: amount,
            paidById: paidById,
            splitType: .exactAmounts,
            participants: [participant],
            notes: notes ?? "",
            category: category,
            date: date
        )

        // 9. Save the split bill WITHOUT calling updateBalancesForSplitBill
        // (balance was already updated above)
        try persistenceService.saveSplitBill(splitBill)
        splitBills.append(splitBill)
        notifyChange(.splitBillAdded(splitBill.id))

        // 10. Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = splitBill.toSupabaseModel(userId: userId)
            SyncService.shared.queueInsert(
                table: SupabaseConfig.Tables.splitBills,
                record: supabaseModel,
                id: splitBill.id
            )
            Task { await SyncService.shared.syncPendingChanges() }
        }

        print("✅ Due created: \(description) - \(amount.asCurrency) (\(theyOweMe ? "they owe me" : "I owe them"))")

        return splitBill
    }

    /// Get the balance for a contact (if they have a linked Person record)
    /// - Parameter contact: The contact entry
    /// - Returns: The balance (positive = they owe you, negative = you owe them), or nil if no linked person
    func getBalanceForContact(_ contact: ContactEntry) -> Double? {
        // First try to find by contactId
        if let person = people.first(where: { $0.contactId == contact.id }) {
            return person.balance != 0 ? person.balance : nil
        }

        // Fallback: try to find by phone number
        let contactPhones = contact.phoneNumbers.map { PhoneNumberNormalizer.normalize($0) }
        if let person = people.first(where: { person in
            let personPhone = PhoneNumberNormalizer.normalize(person.phone)
            return contactPhones.contains(personPhone)
        }) {
            return person.balance != 0 ? person.balance : nil
        }

        return nil
    }

    /// Get all contacts that have pending dues (non-zero balance)
    /// - Returns: Array of tuples containing contact and their balance
    func getContactsWithDues() -> [(contact: ContactEntry, balance: Double)] {
        var results: [(ContactEntry, Double)] = []

        for contact in contacts {
            if let balance = getBalanceForContact(contact), balance != 0 {
                results.append((contact, balance))
            }
        }

        // Sort by absolute balance (highest first)
        return results.sorted { abs($0.1) > abs($1.1) }
    }

    /// Get count of contacts with pending dues
    var contactsWithDuesCount: Int {
        contacts.filter { getBalanceForContact($0) != nil }.count
    }

    /// Get all dues (split bills) for a specific contact
    /// - Parameter contact: The contact entry to get dues for
    /// - Returns: Array of SplitBill objects sorted by date (newest first)
    func getDuesForContact(_ contact: ContactEntry) -> [SplitBill] {
        // Find person by contactId
        guard let person = people.first(where: { $0.contactId == contact.id }) else {
            return []
        }
        return getSplitBillsForPerson(personId: person.id)
            .sorted { $0.date > $1.date }
    }

    /// Get the current user's ID from UserProfileManager
    private func getCurrentUserId() -> UUID {
        return UserProfileManager.shared.profile.id
    }

    // MARK: - Conversation Message Operations

    /// Send a message to an entity (person, contact, group, or subscription)
    /// - Parameters:
    ///   - entityId: The UUID of the entity to send the message to
    ///   - entityType: The type of entity (.person, .contact, .group, .subscription)
    ///   - content: The message content
    /// - Returns: The created ConversationMessage
    @discardableResult
    func sendMessage(
        to entityId: UUID,
        entityType: MessageEntityType,
        content: String
    ) throws -> ConversationMessage {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DataManagerError.invalidAmount  // Reuse existing error type
        }

        let message = ConversationMessage(
            entityId: entityId,
            entityType: entityType,
            content: content,
            isSent: true,
            status: .sent
        )

        // Add to in-memory storage
        var messages = conversationMessages[entityId] ?? []
        messages.append(message)
        conversationMessages[entityId] = messages

        // Notify views of the change
        notifyChange(.messageAdded(entityId: entityId))

        print("📨 Message sent to \(entityType): \(content.prefix(30))...")
        return message
    }

    /// Get all messages for a specific entity
    /// - Parameter entityId: The UUID of the entity
    /// - Returns: Array of ConversationMessage sorted by timestamp (oldest first)
    func getMessages(for entityId: UUID) -> [ConversationMessage] {
        return conversationMessages[entityId]?.sorted { $0.timestamp < $1.timestamp } ?? []
    }

    /// Get messages for a contact (by contact ID string)
    /// - Parameter contactId: The string ID of the contact
    /// - Returns: Array of ConversationMessage sorted by timestamp
    func getMessagesForContact(_ contactId: String) -> [ConversationMessage] {
        // Find the person linked to this contact
        guard let person = people.first(where: { $0.contactId == contactId }) else {
            return []
        }
        return getMessages(for: person.id)
    }

    /// Delete a message
    /// - Parameters:
    ///   - messageId: The UUID of the message to delete
    ///   - entityId: The UUID of the entity the message belongs to
    func deleteMessage(messageId: UUID, from entityId: UUID) {
        guard var messages = conversationMessages[entityId] else { return }

        messages.removeAll { $0.id == messageId }
        conversationMessages[entityId] = messages

        notifyChange(.messageDeleted(entityId: entityId))
        print("🗑️ Message deleted")
    }

    /// Clear all messages for an entity
    /// - Parameter entityId: The UUID of the entity
    func clearMessages(for entityId: UUID) {
        conversationMessages[entityId] = nil
        notifyChange(.messageDeleted(entityId: entityId))
        print("🗑️ All messages cleared for entity")
    }

    /// Get the count of messages for an entity
    /// - Parameter entityId: The UUID of the entity
    /// - Returns: The number of messages
    func messageCount(for entityId: UUID) -> Int {
        return conversationMessages[entityId]?.count ?? 0
    }

    /// Add an incoming message (received from another user)
    /// - Parameters:
    ///   - entityId: The UUID of the entity
    ///   - entityType: The type of entity
    ///   - content: The message content
    ///   - timestamp: The message timestamp (defaults to now)
    /// - Returns: The created ConversationMessage
    @discardableResult
    func receiveMessage(
        from entityId: UUID,
        entityType: MessageEntityType,
        content: String,
        timestamp: Date = Date()
    ) -> ConversationMessage {
        let message = ConversationMessage(
            entityId: entityId,
            entityType: entityType,
            content: content,
            isSent: false,
            timestamp: timestamp,
            status: .delivered
        )

        var messages = conversationMessages[entityId] ?? []
        messages.append(message)
        conversationMessages[entityId] = messages

        notifyChange(.messageAdded(entityId: entityId))
        print("📬 Message received from \(entityType): \(content.prefix(30))...")
        return message
    }

    // MARK: - Conversation Helpers (WhatsApp-style)

    /// Get the last message for a specific entity (person/group/subscription)
    /// Returns the most recent message by timestamp
    func lastMessage(for entityId: UUID) -> ConversationMessage? {
        return conversationMessages[entityId]?
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    /// Get the unread message count for a specific entity
    /// Counts incoming messages that haven't been read
    func unreadMessageCount(for entityId: UUID) -> Int {
        return conversationMessages[entityId]?
            .filter { !$0.isSent && $0.status != .read }
            .count ?? 0
    }

    /// Build a ConversationPreview for a person, combining messages and transactions
    func conversationPreview(for person: Person) -> ConversationPreview {
        let lastMsg = lastMessage(for: person.id)
        let unread = unreadMessageCount(for: person.id)

        // Also check the latest transaction involving this person
        let lastTransaction = transactions
            .filter { $0.title.contains(person.name) || $0.subtitle.contains(person.name) }
            .sorted { $0.date > $1.date }
            .first

        // Determine which is more recent: message or transaction
        let msgDate = lastMsg?.timestamp
        let txnDate = lastTransaction?.date

        if let msgDate = msgDate, let txnDate = txnDate {
            if msgDate > txnDate {
                return ConversationPreview(
                    lastMessageText: lastMsg?.content ?? "No messages yet",
                    lastMessageDate: msgDate,
                    unreadCount: unread,
                    isLastMessageSent: lastMsg?.isSent ?? false,
                    messageStatus: lastMsg?.status,
                    isTyping: false
                )
            } else {
                let txnPreview = transactionPreviewText(lastTransaction!)
                return ConversationPreview(
                    lastMessageText: txnPreview,
                    lastMessageDate: txnDate,
                    unreadCount: unread,
                    isLastMessageSent: true,
                    messageStatus: .delivered,
                    isTyping: false
                )
            }
        } else if let msgDate = msgDate {
            return ConversationPreview(
                lastMessageText: lastMsg?.content ?? "No messages yet",
                lastMessageDate: msgDate,
                unreadCount: unread,
                isLastMessageSent: lastMsg?.isSent ?? false,
                messageStatus: lastMsg?.status,
                isTyping: false
            )
        } else if let txnDate = txnDate {
            let txnPreview = transactionPreviewText(lastTransaction!)
            return ConversationPreview(
                lastMessageText: txnPreview,
                lastMessageDate: txnDate,
                unreadCount: unread,
                isLastMessageSent: true,
                messageStatus: .delivered,
                isTyping: false
            )
        }

        // No messages or transactions - show balance info or default
        if person.balance != 0 {
            return ConversationPreview(
                lastMessageText: person.balance > 0 ? "Owes you \(abs(person.balance).asCurrency)" : "You owe \(abs(person.balance).asCurrency)",
                lastMessageDate: person.lastModifiedDate,
                unreadCount: 0,
                isLastMessageSent: false,
                messageStatus: nil,
                isTyping: false
            )
        }

        return ConversationPreview(
            lastMessageText: "Tap to start a conversation",
            lastMessageDate: person.createdDate,
            unreadCount: 0,
            isLastMessageSent: false,
            messageStatus: nil,
            isTyping: false
        )
    }

    /// Build a ConversationPreview for a subscription
    func conversationPreview(for subscription: Subscription) -> ConversationPreview {
        let lastMsg = lastMessage(for: subscription.id)
        let unread = unreadMessageCount(for: subscription.id)

        // Generate latest event text
        let events = SubscriptionEventService.shared.generateEvents(
            for: subscription,
            priceHistory: getPriceHistory(for: subscription.id),
            people: people
        )
        let latestEvent = events.sorted { $0.eventDate > $1.eventDate }.first

        // Check if message is more recent than event
        let msgDate = lastMsg?.timestamp
        let eventDate = latestEvent?.eventDate

        if let msgDate = msgDate, let eventDate = eventDate {
            if msgDate > eventDate {
                return ConversationPreview(
                    lastMessageText: lastMsg?.content ?? "",
                    lastMessageDate: msgDate,
                    unreadCount: unread,
                    isLastMessageSent: lastMsg?.isSent ?? false,
                    messageStatus: lastMsg?.status,
                    isTyping: false
                )
            }
        } else if let msgDate = msgDate {
            return ConversationPreview(
                lastMessageText: lastMsg?.content ?? "",
                lastMessageDate: msgDate,
                unreadCount: unread,
                isLastMessageSent: lastMsg?.isSent ?? false,
                messageStatus: lastMsg?.status,
                isTyping: false
            )
        }

        // Use event as preview
        if let event = latestEvent {
            return ConversationPreview(
                lastMessageText: event.title,
                lastMessageDate: event.eventDate,
                unreadCount: unread,
                isLastMessageSent: false,
                messageStatus: nil,
                isTyping: false
            )
        }

        // Fallback: billing info
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let nextDate = formatter.string(from: subscription.nextBillingDate)
        return ConversationPreview(
            lastMessageText: "\(subscription.billingCycle.displayName) · Next: \(nextDate)",
            lastMessageDate: subscription.createdDate,
            unreadCount: 0,
            isLastMessageSent: false,
            messageStatus: nil,
            isTyping: false
        )
    }

    /// Build a ConversationPreview for a group
    func conversationPreview(for group: Group) -> ConversationPreview {
        let lastMsg = lastMessage(for: group.id)
        let unread = unreadMessageCount(for: group.id)

        // Latest group expense
        let latestExpense = group.expenses.sorted { $0.date > $1.date }.first

        let msgDate = lastMsg?.timestamp
        let expenseDate = latestExpense?.date

        if let msgDate = msgDate, let expenseDate = expenseDate {
            if msgDate > expenseDate {
                return ConversationPreview(
                    lastMessageText: lastMsg?.content ?? "",
                    lastMessageDate: msgDate,
                    unreadCount: unread,
                    isLastMessageSent: lastMsg?.isSent ?? false,
                    messageStatus: lastMsg?.status,
                    isTyping: false
                )
            } else {
                return ConversationPreview(
                    lastMessageText: "\(latestExpense!.title) · \(latestExpense!.amount.asCurrency)",
                    lastMessageDate: expenseDate,
                    unreadCount: unread,
                    isLastMessageSent: false,
                    messageStatus: nil,
                    isTyping: false
                )
            }
        } else if let msgDate = msgDate {
            return ConversationPreview(
                lastMessageText: lastMsg?.content ?? "",
                lastMessageDate: msgDate,
                unreadCount: unread,
                isLastMessageSent: lastMsg?.isSent ?? false,
                messageStatus: lastMsg?.status,
                isTyping: false
            )
        } else if let expense = latestExpense {
            return ConversationPreview(
                lastMessageText: "\(expense.title) · \(expense.amount.asCurrency)",
                lastMessageDate: expense.date,
                unreadCount: unread,
                isLastMessageSent: false,
                messageStatus: nil,
                isTyping: false
            )
        }

        return ConversationPreview(
            lastMessageText: "\(group.members.count) members · Tap to start",
            lastMessageDate: group.createdDate,
            unreadCount: 0,
            isLastMessageSent: false,
            messageStatus: nil,
            isTyping: false
        )
    }

    /// Generate a preview text from a transaction
    private func transactionPreviewText(_ transaction: Transaction) -> String {
        let amount = transaction.amount.asCurrency
        if transaction.title.lowercased().contains("settlement") {
            return "Settlement · \(amount)"
        } else if transaction.title.lowercased().contains("payment") {
            return "Payment · \(amount)"
        } else {
            return "\(transaction.title) · \(amount)"
        }
    }

    // MARK: - Statistics & Analytics

    func calculateTotalMonthlyCost() -> Double {
        let activeSubscriptions = getActiveSubscriptions()

        return activeSubscriptions.reduce(0.0) { total, subscription in
            let monthlyEquivalent: Double

            switch subscription.billingCycle {
            case .daily: monthlyEquivalent = subscription.price * 30
            case .weekly: monthlyEquivalent = subscription.price * 4.33
            case .biweekly: monthlyEquivalent = subscription.price * 2.17
            case .monthly: monthlyEquivalent = subscription.price
            case .quarterly: monthlyEquivalent = subscription.price / 3
            case .semiAnnually: monthlyEquivalent = subscription.price / 6
            case .yearly, .annually: monthlyEquivalent = subscription.price / 12
            case .lifetime: monthlyEquivalent = 0
            }

            return total + monthlyEquivalent
        }
    }

    func calculateMonthlyIncome() -> Double {
        let currentMonthTransactions = getCurrentMonthTransactions()
        let income = currentMonthTransactions.filter { $0.amount > 0 }
        return income.reduce(0.0) { $0 + $1.amount }
    }

    func calculateMonthlyExpenses() -> Double {
        let currentMonthTransactions = getCurrentMonthTransactions()
        let expenses = currentMonthTransactions.filter { $0.amount < 0 }
        return abs(expenses.reduce(0.0) { $0 + $1.amount })
    }

    func getNetMonthlyIncome() -> Double {
        calculateMonthlyIncome() - calculateMonthlyExpenses()
    }

    // MARK: - Bulk Import Operations

    /// Import multiple people with progress tracking
    func importPeople(_ people: [Person]) async throws {
        guard !people.isEmpty else { return }

        await MainActor.run {
            isPerformingOperation = true
            operationProgress = 0
            operationMessage = "Importing \(people.count) people..."
        }

        let total = Double(people.count)
        var imported = 0

        // Use background context for bulk operation
        for (index, person) in people.enumerated() {
            try await Task { @MainActor in
                try persistenceService.savePerson(person)
                self.people.append(person)
                imported += 1

                // Update progress
                self.operationProgress = Double(index + 1) / total
                self.operationMessage = "Imported \(imported) of \(people.count) people"

                print("📥 Imported person \(imported)/\(people.count): \(person.name)")
            }.value
        }

        await MainActor.run {
            operationProgress = nil
            operationMessage = nil
            isPerformingOperation = false
            print("✅ Bulk import complete: \(imported) people imported")
        }
    }

    /// Import multiple subscriptions with progress tracking
    func importSubscriptions(_ subscriptions: [Subscription]) async throws {
        guard !subscriptions.isEmpty else { return }

        await MainActor.run {
            isPerformingOperation = true
            operationProgress = 0
            operationMessage = "Importing \(subscriptions.count) subscriptions..."
        }

        let total = Double(subscriptions.count)
        var imported = 0

        for (index, subscription) in subscriptions.enumerated() {
            try await Task { @MainActor in
                try persistenceService.saveSubscription(subscription)
                self.subscriptions.append(subscription)
                imported += 1

                self.operationProgress = Double(index + 1) / total
                self.operationMessage =
                    "Imported \(imported) of \(subscriptions.count) subscriptions"

                print(
                    "📥 Imported subscription \(imported)/\(subscriptions.count): \(subscription.name)"
                )
            }.value
        }

        await MainActor.run {
            operationProgress = nil
            operationMessage = nil
            isPerformingOperation = false
            print("✅ Bulk import complete: \(imported) subscriptions imported")
        }
    }

    /// Import multiple transactions with progress tracking
    func importTransactions(_ transactions: [Transaction]) async throws {
        guard !transactions.isEmpty else { return }

        await MainActor.run {
            isPerformingOperation = true
            operationProgress = 0
            operationMessage = "Importing \(transactions.count) transactions..."
        }

        let total = Double(transactions.count)
        var imported = 0

        for (index, transaction) in transactions.enumerated() {
            try await Task { @MainActor in
                try persistenceService.saveTransaction(transaction)
                self.transactions.append(transaction)
                imported += 1

                self.operationProgress = Double(index + 1) / total
                self.operationMessage = "Imported \(imported) of \(transactions.count) transactions"

                print(
                    "📥 Imported transaction \(imported)/\(transactions.count): \(transaction.title)"
                )
            }.value
        }

        await MainActor.run {
            self.transactions.sort { $0.date > $1.date }
            operationProgress = nil
            operationMessage = nil
            isPerformingOperation = false
            print("✅ Bulk import complete: \(imported) transactions imported")
        }
    }

    /// Import multiple groups with progress tracking
    func importGroups(_ groups: [Group]) async throws {
        guard !groups.isEmpty else { return }

        await MainActor.run {
            isPerformingOperation = true
            operationProgress = 0
            operationMessage = "Importing \(groups.count) groups..."
        }

        let total = Double(groups.count)
        var imported = 0

        for (index, group) in groups.enumerated() {
            try await Task { @MainActor in
                try persistenceService.saveGroup(group)
                self.groups.append(group)
                imported += 1

                self.operationProgress = Double(index + 1) / total
                self.operationMessage = "Imported \(imported) of \(groups.count) groups"

                print("📥 Imported group \(imported)/\(groups.count): \(group.name)")
            }.value
        }

        await MainActor.run {
            operationProgress = nil
            operationMessage = nil
            isPerformingOperation = false
            print("✅ Bulk import complete: \(imported) groups imported")
        }
    }

    // MARK: - Debounced Auto-Save

    private var personSaveDebouncer: [UUID: Debouncer] = [:]
    private var subscriptionSaveDebouncer: [UUID: Debouncer] = [:]
    private var transactionSaveDebouncer: [UUID: Debouncer] = [:]
    private var groupSaveDebouncer: [UUID: Debouncer] = [:]

    /// Schedule debounced save for a person (useful for text field editing)
    func scheduleSave(for person: Person, delay: TimeInterval = 0.5) {
        // Get or create debouncer for this person
        if personSaveDebouncer[person.id] == nil {
            personSaveDebouncer[person.id] = Debouncer(delay: delay)
        }

        // Debounce the save operation
        personSaveDebouncer[person.id]?.debounce {
            do {
                try await self.updatePersonInternal(person)
                print("💾 Auto-saved person: \(person.name)")
            } catch {
                print("❌ Auto-save failed for person: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    /// Schedule debounced save for a subscription
    func scheduleSave(for subscription: Subscription, delay: TimeInterval = 0.5) {
        if subscriptionSaveDebouncer[subscription.id] == nil {
            subscriptionSaveDebouncer[subscription.id] = Debouncer(delay: delay)
        }

        subscriptionSaveDebouncer[subscription.id]?.debounce {
            do {
                try await self.updateSubscriptionInternal(subscription)
                print("💾 Auto-saved subscription: \(subscription.name)")
            } catch {
                print("❌ Auto-save failed for subscription: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    /// Schedule debounced save for a transaction
    func scheduleSave(for transaction: Transaction, delay: TimeInterval = 0.5) {
        if transactionSaveDebouncer[transaction.id] == nil {
            transactionSaveDebouncer[transaction.id] = Debouncer(delay: delay)
        }

        transactionSaveDebouncer[transaction.id]?.debounce {
            do {
                try await self.updateTransactionInternal(transaction)
                print("💾 Auto-saved transaction: \(transaction.title)")
            } catch {
                print("❌ Auto-save failed for transaction: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    /// Schedule debounced save for a group
    func scheduleSave(for group: Group, delay: TimeInterval = 0.5) {
        if groupSaveDebouncer[group.id] == nil {
            groupSaveDebouncer[group.id] = Debouncer(delay: delay)
        }

        groupSaveDebouncer[group.id]?.debounce {
            do {
                try await self.updateGroupInternal(group)
                print("💾 Auto-saved group: \(group.name)")
            } catch {
                print("❌ Auto-save failed for group: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    // MARK: - Internal Update Methods (for debounced saves)

    private func updatePersonInternal(_ person: Person) async throws {
        try persistenceService.updatePerson(person)
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
        }

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = person.toSupabaseModel(userId: userId)
            SyncService.shared.queueUpdate(
                table: SupabaseConfig.Tables.persons,
                record: supabaseModel,
                id: person.id
            )
            await SyncService.shared.syncPendingChanges()
        }
    }

    private func updateSubscriptionInternal(_ subscription: Subscription) async throws {
        try persistenceService.updateSubscription(subscription)
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        }

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = subscription.toSupabaseModel(userId: userId)
            SyncService.shared.queueUpdate(
                table: SupabaseConfig.Tables.subscriptions,
                record: supabaseModel,
                id: subscription.id
            )
            await SyncService.shared.syncPendingChanges()
        }
    }

    private func updateTransactionInternal(_ transaction: Transaction) async throws {
        try persistenceService.updateTransaction(transaction)
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date }
        }

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = transaction.toSupabaseModel(userId: userId)
            SyncService.shared.queueUpdate(
                table: SupabaseConfig.Tables.transactions,
                record: supabaseModel,
                id: transaction.id
            )
            await SyncService.shared.syncPendingChanges()
        }
    }

    private func updateGroupInternal(_ group: Group) async throws {
        try persistenceService.updateGroup(group)
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        }

        // Queue for Supabase sync
        if let userId = SupabaseService.shared.currentUser?.id {
            let supabaseModel = group.toSupabaseModel(userId: userId)
            SyncService.shared.queueUpdate(
                table: SupabaseConfig.Tables.groups,
                record: supabaseModel,
                id: group.id
            )
            await SyncService.shared.syncPendingChanges()
        }
    }

    // MARK: - First Launch Detection

    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
    }

    private func markFirstLaunchComplete() {
        UserDefaults.standard.set(true, forKey: firstLaunchKey)
        isFirstLaunch = false
        print("✅ First launch complete")
    }

    // MARK: - Utility Methods

    func clearAllData() throws {
        people.removeAll()
        groups.removeAll()
        subscriptions.removeAll()
        transactions.removeAll()
        splitBills.removeAll()
        accounts.removeAll()
        sharedSubscriptions.removeAll()

        // Note: This would require a clearAllData method in PersistenceService
        // For now, just clear the in-memory arrays
        print("⚠️ Data cleared from memory. Persistence clearing not yet implemented.")
    }

    // MARK: - Formatting Utilities

    func formatCurrency(_ amount: Double) -> String {
        let money = MoneyAmount(double: amount)
        return money.formatted(
            currencyCode: UserSettings.shared.selectedCurrency,
            showSymbol: true,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        )
    }
}
