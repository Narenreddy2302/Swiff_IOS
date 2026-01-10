//
//  SyncService.swift
//  Swiff IOS
//
//  Offline-first sync service for Supabase
//

import Foundation
import Combine
import Network
import SwiftData
import Supabase

/// Offline-first sync service that manages data synchronization between SwiftData and Supabase
@MainActor
final class SyncService: ObservableObject {

    // MARK: - Singleton

    static let shared = SyncService()

    // MARK: - Published Properties

    @Published private(set) var isSyncing = false
    @Published private(set) var isOnline = true
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var pendingChangesCount = 0
    @Published private(set) var syncError: SyncError?
    @Published private(set) var syncProgress: SyncProgress = .idle

    // MARK: - Properties

    private let supabase = SupabaseService.shared
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.swiff.network")

    private var pendingChanges: [PendingChange] = []
    private var cancellables = Set<AnyCancellable>()
    private var realtimeSubscriptions: [String: Task<Void, Never>] = [:]

    /// File URL for persisting pending changes
    private var pendingChangesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pending_changes.json")
    }

    /// File URL for last sync timestamp
    private var lastSyncURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("last_sync.json")
    }

    // MARK: - Initialization

    private init() {
        loadPendingChanges()
        loadLastSyncDate()
        setupNetworkMonitoring()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied

                // If we just came online and have pending changes, sync them
                if !wasOnline && path.status == .satisfied {
                    await self?.syncPendingChanges()
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }

    // MARK: - Pending Changes Management

    /// Queue a change for sync
    func queueChange(_ change: PendingChange) {
        pendingChanges.append(change)
        pendingChangesCount = pendingChanges.count
        savePendingChanges()

        // If online, try to sync immediately
        if isOnline {
            Task {
                await syncPendingChanges()
            }
        }
    }

    /// Queue an insert operation
    func queueInsert<T: Encodable>(table: String, record: T, id: UUID) {
        do {
            let data = try JSONEncoder().encode(record)
            let change = PendingChange(
                id: UUID(),
                recordId: id,
                table: table,
                operation: .insert,
                payload: data,
                timestamp: Date(),
                retryCount: 0
            )
            queueChange(change)
        } catch {
            print("Failed to encode record for queue: \(error)")
        }
    }

    /// Queue an update operation
    func queueUpdate<T: Encodable>(table: String, record: T, id: UUID) {
        do {
            let data = try JSONEncoder().encode(record)
            let change = PendingChange(
                id: UUID(),
                recordId: id,
                table: table,
                operation: .update,
                payload: data,
                timestamp: Date(),
                retryCount: 0
            )
            queueChange(change)
        } catch {
            print("Failed to encode record for queue: \(error)")
        }
    }

    /// Queue a delete operation
    func queueDelete(table: String, id: UUID) {
        let change = PendingChange(
            id: UUID(),
            recordId: id,
            table: table,
            operation: .delete,
            payload: nil,
            timestamp: Date(),
            retryCount: 0
        )
        queueChange(change)
    }

    // MARK: - Sync Operations

    /// Sync all pending changes to Supabase
    func syncPendingChanges() async {
        guard isOnline && !isSyncing && !pendingChanges.isEmpty else { return }
        guard supabase.currentUser != nil else { return }

        isSyncing = true
        syncProgress = .syncing(completed: 0, total: pendingChanges.count)
        syncError = nil

        var successfulChanges: [UUID] = []
        var failedChanges: [(PendingChange, Error)] = []

        for (index, change) in pendingChanges.enumerated() {
            do {
                try await processChange(change)
                successfulChanges.append(change.id)
                syncProgress = .syncing(completed: index + 1, total: pendingChanges.count)
            } catch {
                if change.retryCount < SupabaseConfig.Sync.maxRetries {
                    // Increment retry count
                    var updatedChange = change
                    updatedChange.retryCount += 1
                    failedChanges.append((updatedChange, error))
                } else {
                    // Max retries reached, mark as failed
                    failedChanges.append((change, error))
                    print("Change failed after max retries: \(change.id), error: \(error)")
                }
            }
        }

        // Remove successful changes
        pendingChanges.removeAll { change in
            successfulChanges.contains(change.id)
        }

        // Update failed changes with incremented retry count
        for (failedChange, _) in failedChanges {
            if failedChange.retryCount < SupabaseConfig.Sync.maxRetries {
                if let index = pendingChanges.firstIndex(where: { $0.id == failedChange.id }) {
                    pendingChanges[index] = failedChange
                }
            }
        }

        pendingChangesCount = pendingChanges.count
        savePendingChanges()

        isSyncing = false
        syncProgress = failedChanges.isEmpty ? .completed : .failed(failedChanges.count)

        if !failedChanges.isEmpty {
            syncError = .partialSyncFailure(failedCount: failedChanges.count)
        }
    }

    /// Process a single pending change
    private func processChange(_ change: PendingChange) async throws {
        switch change.operation {
        case .insert:
            guard let payload = change.payload else {
                throw SyncError.invalidPayload
            }
            // Decode and insert
            try await supabase.client.from(change.table)
                .insert(payload)
                .execute()

        case .update:
            guard let payload = change.payload else {
                throw SyncError.invalidPayload
            }
            try await supabase.client.from(change.table)
                .update(payload)
                .eq("id", value: change.recordId.uuidString)
                .execute()

        case .delete:
            // Soft delete
            try await supabase.softDelete(from: change.table, id: change.recordId)
        }
    }

    // MARK: - Full Sync

    /// Perform a full sync from Supabase to local
    func performFullSync(modelContext: ModelContext) async throws {
        guard isOnline else {
            throw SyncError.offline
        }
        guard supabase.currentUser != nil else {
            throw SyncError.notAuthenticated
        }

        isSyncing = true
        syncProgress = .syncing(completed: 0, total: 12) // Updated count

        do {
            // Sync each table
            try await syncPersons(modelContext: modelContext)
            syncProgress = .syncing(completed: 1, total: 12)

            try await syncAccounts(modelContext: modelContext)
            syncProgress = .syncing(completed: 2, total: 12)

            try await syncGroups(modelContext: modelContext)
            syncProgress = .syncing(completed: 3, total: 12)

            try await syncGroupMembers(modelContext: modelContext)
            syncProgress = .syncing(completed: 4, total: 12)

            try await syncGroupExpenses(modelContext: modelContext)
            syncProgress = .syncing(completed: 5, total: 12)

            try await syncSubscriptions(modelContext: modelContext)
            syncProgress = .syncing(completed: 6, total: 12)

            try await syncSharedSubscriptions(modelContext: modelContext)
            syncProgress = .syncing(completed: 7, total: 12)

            try await syncPriceChanges(modelContext: modelContext)
            syncProgress = .syncing(completed: 8, total: 12)

            try await syncTransactions(modelContext: modelContext)
            syncProgress = .syncing(completed: 9, total: 12)

            try await syncSplitBills(modelContext: modelContext)
            syncProgress = .syncing(completed: 10, total: 12)

            // Save context
            try modelContext.save()
            syncProgress = .syncing(completed: 11, total: 12)

            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()

            isSyncing = false
            syncProgress = .completed
        } catch {
            isSyncing = false
            syncProgress = .failed(1)
            syncError = .syncFailed(error.localizedDescription)
            throw error
        }
    }

    /// Incremental sync - only fetch changes since last sync
    func performIncrementalSync(modelContext: ModelContext) async throws {
        guard isOnline else {
            throw SyncError.offline
        }
        guard supabase.currentUser != nil else {
            throw SyncError.notAuthenticated
        }

        let since = lastSyncDate ?? Date.distantPast

        isSyncing = true
        syncError = nil

        do {
            // Fetch modified records from each table
            let persons: [SupabasePerson] = try await supabase.fetchModifiedSince(
                from: SupabaseConfig.Tables.persons,
                since: since
            )

            let subscriptions: [SupabaseSubscription] = try await supabase.fetchModifiedSince(
                from: SupabaseConfig.Tables.subscriptions,
                since: since
            )

            let transactions: [SupabaseTransaction] = try await supabase.fetchModifiedSince(
                from: SupabaseConfig.Tables.transactions,
                since: since
            )

            // Apply changes to local database
            for person in persons {
                await applyPersonChange(person, modelContext: modelContext)
            }

            for subscription in subscriptions {
                await applySubscriptionChange(subscription, modelContext: modelContext)
            }

            for transaction in transactions {
                await applyTransactionChange(transaction, modelContext: modelContext)
            }

            try modelContext.save()

            lastSyncDate = Date()
            saveLastSyncDate()

            isSyncing = false
            syncProgress = .completed
        } catch {
            isSyncing = false
            syncError = .syncFailed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Table-Specific Sync

    private func syncPersons(modelContext: ModelContext) async throws {
        let remotePersons: [SupabasePerson] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.persons
        )

        for remote in remotePersons {
            await applyPersonChange(remote, modelContext: modelContext)
        }
    }

    private func applyPersonChange(_ remote: SupabasePerson, modelContext: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == remote.id }
        )

        do {
            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                // Check sync version for conflict resolution
                if remote.syncVersion > existing.syncVersion {
                    // Remote is newer, update local
                    updatePersonModel(existing, from: remote)
                }
                // If local is newer or equal, skip (local changes will sync up)
            } else if remote.deletedAt == nil {
                // New record, insert
                let newPerson = PersonModel.from(remote: remote)
                modelContext.insert(newPerson)
            }
        } catch {
            print("Failed to apply person change: \(error)")
        }
    }

    private func updatePersonModel(_ model: PersonModel, from remote: SupabasePerson) {
        model.name = remote.name
        model.email = remote.email ?? ""
        model.phone = remote.phone ?? ""
        model.balance = NSDecimalNumber(decimal: remote.balance).doubleValue
        model.avatarTypeRaw = remote.avatarType ?? "initials"
        model.avatarEmoji = remote.avatarEmoji
        model.avatarInitials = remote.avatarInitials
        model.avatarColorIndex = remote.avatarColorIndex ?? 0
        model.contactId = remote.contactId
        model.relationshipType = remote.relationshipType
        model.personNotes = remote.notes
        model.personSourceRaw = remote.personSource ?? PersonSource.manual.rawValue
        model.syncVersion = remote.syncVersion
        model.lastModifiedDate = remote.updatedAt
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
    }

    private func syncAccounts(modelContext: ModelContext) async throws {
        let remoteAccounts: [SupabaseAccount] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.accounts
        )

        for remote in remoteAccounts {
            let fetchDescriptor = FetchDescriptor<AccountModel>(
                predicate: #Predicate { $0.id == remote.id }
            )

            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.name = remote.name
                    existing.number = remote.number ?? ""
                    existing.typeRaw = remote.type
                    existing.isDefault = remote.isDefault
                    existing.syncVersion = remote.syncVersion
                    existing.pendingSync = false
                }
            } else if remote.deletedAt == nil {
                let newAccount = AccountModel.from(remote: remote)
                modelContext.insert(newAccount)
            }
        }
    }

    private func syncGroups(modelContext: ModelContext) async throws {
        let remoteGroups: [SupabaseGroup] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.groups
        )

        for remote in remoteGroups {
            let fetchDescriptor = FetchDescriptor<GroupModel>(
                predicate: #Predicate { $0.id == remote.id }
            )

            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.name = remote.name
                    existing.groupDescription = remote.description ?? ""
                    existing.emoji = remote.emoji ?? "👥"
                    existing.totalAmount = NSDecimalNumber(decimal: remote.totalAmount).doubleValue
                    existing.syncVersion = remote.syncVersion
                    existing.pendingSync = false
                }
            } else if remote.deletedAt == nil {
                let newGroup = GroupModel.from(remote: remote)
                modelContext.insert(newGroup)
            }
        }
    }

    private func syncGroupMembers(modelContext: ModelContext) async throws {
        // Group members are synced as part of groups
        // This is a simplified version - in production you'd handle this more carefully
    }

    private func syncSubscriptions(modelContext: ModelContext) async throws {
        let remoteSubscriptions: [SupabaseSubscription] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.subscriptions
        )

        for remote in remoteSubscriptions {
            await applySubscriptionChange(remote, modelContext: modelContext)
        }
    }

    private func applySubscriptionChange(_ remote: SupabaseSubscription, modelContext: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == remote.id }
        )

        do {
            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    updateSubscriptionModel(existing, from: remote)
                }
            } else if remote.deletedAt == nil {
                let newSubscription = SubscriptionModel.from(remote: remote)
                modelContext.insert(newSubscription)
            }
        } catch {
            print("Failed to apply subscription change: \(error)")
        }
    }

    private func updateSubscriptionModel(_ model: SubscriptionModel, from remote: SupabaseSubscription) {
        model.name = remote.name
        model.subscriptionDescription = remote.description ?? ""
        model.price = NSDecimalNumber(decimal: remote.price).doubleValue
        model.billingCycleRaw = remote.billingCycle
        model.categoryRaw = remote.category
        model.icon = remote.icon ?? "app.fill"
        model.color = remote.color ?? "#007AFF"
        model.nextBillingDate = remote.nextBillingDate ?? model.nextBillingDate
        model.isActive = remote.isActive
        model.isShared = remote.isShared
        model.syncVersion = remote.syncVersion
        model.pendingSync = false
    }

    private func syncTransactions(modelContext: ModelContext) async throws {
        let remoteTransactions: [SupabaseTransaction] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.transactions
        )

        for remote in remoteTransactions {
            await applyTransactionChange(remote, modelContext: modelContext)
        }
    }

    private func applyTransactionChange(_ remote: SupabaseTransaction, modelContext: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == remote.id }
        )

        do {
            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    updateTransactionModel(existing, from: remote)
                }
            } else if remote.deletedAt == nil {
                let newTransaction = TransactionModel.from(remote: remote)
                modelContext.insert(newTransaction)
            }
        } catch {
            print("Failed to apply transaction change: \(error)")
        }
    }

    private func updateTransactionModel(_ model: TransactionModel, from remote: SupabaseTransaction) {
        model.title = remote.title
        model.subtitle = remote.subtitle ?? ""
        model.amount = NSDecimalNumber(decimal: remote.amount).doubleValue
        model.categoryRaw = remote.category
        model.date = remote.date
        model.syncVersion = remote.syncVersion
        model.pendingSync = false
    }

    private func syncSplitBills(modelContext: ModelContext) async throws {
        let remoteSplitBills: [SupabaseSplitBill] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.splitBills
        )

        for remote in remoteSplitBills {
            let fetchDescriptor = FetchDescriptor<SplitBillModel>(
                predicate: #Predicate { $0.id == remote.id }
            )

            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.title = remote.title
                    existing.totalAmount = NSDecimalNumber(decimal: remote.totalAmount).doubleValue
                    existing.splitTypeRaw = remote.splitType
                    existing.notes = remote.notes ?? ""
                    existing.categoryRaw = remote.category
                    existing.date = remote.date
                    existing.syncVersion = remote.syncVersion
                    existing.pendingSync = false
                }
            } else if remote.deletedAt == nil {
                let newSplitBill = SplitBillModel.from(remote: remote)
                modelContext.insert(newSplitBill)
            }
        }
    }

    private func syncPriceChanges(modelContext: ModelContext) async throws {
        let remotePriceChanges: [SupabasePriceChange] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.priceChanges
        )

        for remote in remotePriceChanges {
            let fetchDescriptor = FetchDescriptor<PriceChangeModel>(
                predicate: #Predicate { $0.id == remote.id }
            )

            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.oldPrice = NSDecimalNumber(decimal: remote.oldPrice).doubleValue
                    existing.newPrice = NSDecimalNumber(decimal: remote.newPrice).doubleValue
                    existing.changeDate = remote.changeDate
                    existing.reason = remote.reason
                    existing.detectedAutomatically = remote.detectedAutomatically
                    existing.syncVersion = remote.syncVersion
                    existing.pendingSync = false
                }
            } else if remote.deletedAt == nil {
                let newPriceChange = PriceChangeModel.from(remote: remote)
                modelContext.insert(newPriceChange)
            }
        }
    }

    private func syncSharedSubscriptions(modelContext: ModelContext) async throws {
        let remoteSharedSubs: [SupabaseSharedSubscription] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.sharedSubscriptions
        )

        for remote in remoteSharedSubs {
            let fetchDescriptor = FetchDescriptor<SharedSubscriptionModel>(
                predicate: #Predicate { $0.id == remote.id }
            )

            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.subscriptionID = remote.subscriptionId
                    existing.sharedByID = remote.sharedByUserId
                    if let individualCost = remote.individualCost {
                        existing.individualCost = NSDecimalNumber(decimal: individualCost).doubleValue
                    }
                    existing.isAccepted = remote.isAccepted
                    existing.costSplitRaw = remote.costSplitType
                    existing.notes = remote.notes ?? ""
                    existing.syncVersion = remote.syncVersion
                    existing.pendingSync = false
                }
            } else if remote.deletedAt == nil {
                let newSharedSub = SharedSubscriptionModel.from(remote: remote)
                modelContext.insert(newSharedSub)
            }
        }
    }

    private func syncGroupExpenses(modelContext: ModelContext) async throws {
        let remoteExpenses: [SupabaseGroupExpense] = try await supabase.fetchUserRecords(
            from: SupabaseConfig.Tables.groupExpenses
        )

        for remote in remoteExpenses {
            let fetchDescriptor = FetchDescriptor<GroupExpenseModel>(
                predicate: #Predicate { $0.id == remote.id }
            )

            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.title = remote.title
                    existing.amount = NSDecimalNumber(decimal: remote.amount).doubleValue
                    // Use paidByPersonId first, then paidByUserId
                    if let paidBy = remote.paidByPersonId ?? remote.paidByUserId {
                        existing.paidByID = paidBy
                    }
                    existing.splitBetweenIDs = remote.splitBetweenPersonIds
                    existing.categoryRaw = remote.category
                    existing.isSettled = remote.isSettled
                    existing.date = remote.date
                    existing.notes = remote.notes ?? ""
                    existing.receiptPath = remote.receiptPath
                    existing.syncVersion = remote.syncVersion
                    existing.pendingSync = false
                }
            } else if remote.deletedAt == nil {
                let newExpense = GroupExpenseModel.from(remote: remote)
                modelContext.insert(newExpense)
            }
        }
    }

    // MARK: - Realtime Subscriptions

    /// Start listening to realtime changes
    func startRealtimeSync(modelContext: ModelContext) async {
        guard supabase.currentUser != nil else { return }

        // Subscribe to key tables
        let tables = [
            SupabaseConfig.Tables.persons,
            SupabaseConfig.Tables.subscriptions,
            SupabaseConfig.Tables.transactions,
            SupabaseConfig.Tables.groups
        ]

        for table in tables {
            do {
                try await supabase.subscribeToTable(table) { [weak self] message in
                    Task { @MainActor in
                        await self?.handleRealtimeMessage(message, modelContext: modelContext)
                    }
                }
            } catch {
                print("Failed to subscribe to \(table): \(error)")
            }
        }
    }

    /// Stop realtime sync
    func stopRealtimeSync() async {
        await supabase.unsubscribeAll()
        for (_, task) in realtimeSubscriptions {
            task.cancel()
        }
        realtimeSubscriptions.removeAll()
    }

    private func handleRealtimeMessage(_ message: RealtimeMessage, modelContext: ModelContext) async {
        print("📡 Realtime update on \(message.table): \(message.eventType)")

        // Handle the realtime change based on table and event type
        do {
            switch message.table {
            case SupabaseConfig.Tables.transactions:
                try await handleTransactionChange(message, modelContext: modelContext)
            case SupabaseConfig.Tables.subscriptions:
                try await handleSubscriptionChange(message, modelContext: modelContext)
            case SupabaseConfig.Tables.persons:
                try await handlePersonChange(message, modelContext: modelContext)
            case SupabaseConfig.Tables.groups:
                try await handleGroupChange(message, modelContext: modelContext)
            default:
                print("⚠️ Unknown table in realtime message: \(message.table)")
            }

            // Notify DataManager to reload data after applying changes
            await MainActor.run {
                DataManager.shared.loadAllData()
            }
        } catch {
            print("❌ Failed to handle realtime message: \(error)")
        }
    }

    // MARK: - Realtime Change Handlers

    private func handleTransactionChange(_ message: RealtimeMessage, modelContext: ModelContext) async throws {
        guard let newRecord = message.newRecord else {
            if message.isDelete, let oldRecord = message.oldRecord,
               let idString = oldRecord["id"] as? String,
               let id = UUID(uuidString: idString) {
                // Handle delete
                let fetchDescriptor = FetchDescriptor<TransactionModel>(
                    predicate: #Predicate { $0.id == id }
                )
                if let existing = try modelContext.fetch(fetchDescriptor).first {
                    modelContext.delete(existing)
                    try modelContext.save()
                    print("🗑️ Transaction deleted via realtime: \(id)")
                }
            }
            return
        }

        // Convert dictionary to JSON data, then decode
        let jsonData = try JSONSerialization.data(withJSONObject: newRecord)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let remote = try decoder.decode(SupabaseTransaction.self, from: jsonData)

        // Apply the change
        await applyTransactionChange(remote, modelContext: modelContext)
        try modelContext.save()
        print("✅ Transaction synced via realtime: \(remote.title)")
    }

    private func handleSubscriptionChange(_ message: RealtimeMessage, modelContext: ModelContext) async throws {
        guard let newRecord = message.newRecord else {
            if message.isDelete, let oldRecord = message.oldRecord,
               let idString = oldRecord["id"] as? String,
               let id = UUID(uuidString: idString) {
                // Handle delete
                let fetchDescriptor = FetchDescriptor<SubscriptionModel>(
                    predicate: #Predicate { $0.id == id }
                )
                if let existing = try modelContext.fetch(fetchDescriptor).first {
                    modelContext.delete(existing)
                    try modelContext.save()
                    print("🗑️ Subscription deleted via realtime: \(id)")
                }
            }
            return
        }

        let jsonData = try JSONSerialization.data(withJSONObject: newRecord)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let remote = try decoder.decode(SupabaseSubscription.self, from: jsonData)

        await applySubscriptionChange(remote, modelContext: modelContext)
        try modelContext.save()
        print("✅ Subscription synced via realtime: \(remote.name)")
    }

    private func handlePersonChange(_ message: RealtimeMessage, modelContext: ModelContext) async throws {
        guard let newRecord = message.newRecord else {
            if message.isDelete, let oldRecord = message.oldRecord,
               let idString = oldRecord["id"] as? String,
               let id = UUID(uuidString: idString) {
                // Handle delete
                let fetchDescriptor = FetchDescriptor<PersonModel>(
                    predicate: #Predicate { $0.id == id }
                )
                if let existing = try modelContext.fetch(fetchDescriptor).first {
                    modelContext.delete(existing)
                    try modelContext.save()
                    print("🗑️ Person deleted via realtime: \(id)")
                }
            }
            return
        }

        let jsonData = try JSONSerialization.data(withJSONObject: newRecord)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let remote = try decoder.decode(SupabasePerson.self, from: jsonData)

        await applyPersonChange(remote, modelContext: modelContext)
        try modelContext.save()
        print("✅ Person synced via realtime: \(remote.name)")
    }

    private func handleGroupChange(_ message: RealtimeMessage, modelContext: ModelContext) async throws {
        guard let newRecord = message.newRecord else {
            if message.isDelete, let oldRecord = message.oldRecord,
               let idString = oldRecord["id"] as? String,
               let id = UUID(uuidString: idString) {
                // Handle delete
                let fetchDescriptor = FetchDescriptor<GroupModel>(
                    predicate: #Predicate { $0.id == id }
                )
                if let existing = try modelContext.fetch(fetchDescriptor).first {
                    modelContext.delete(existing)
                    try modelContext.save()
                    print("🗑️ Group deleted via realtime: \(id)")
                }
            }
            return
        }

        let jsonData = try JSONSerialization.data(withJSONObject: newRecord)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let remote = try decoder.decode(SupabaseGroup.self, from: jsonData)

        await applyGroupChange(remote, modelContext: modelContext)
        try modelContext.save()
        print("✅ Group synced via realtime: \(remote.name)")
    }

    // MARK: - Apply Change Helpers

    private func applySubscriptionChange(_ remote: SupabaseSubscription, modelContext: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == remote.id }
        )

        do {
            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                // Update existing if remote is newer
                if remote.syncVersion > existing.syncVersion {
                    existing.name = remote.name
                    existing.price = NSDecimalNumber(decimal: remote.price).doubleValue
                    existing.billingCycle = remote.billingCycle
                    existing.category = remote.category
                    existing.isActive = remote.isActive
                    existing.syncVersion = remote.syncVersion
                }
            } else if remote.deletedAt == nil {
                // Insert new
                let newSubscription = SubscriptionModel.from(remote: remote)
                modelContext.insert(newSubscription)
            }
        } catch {
            print("Failed to apply subscription change: \(error)")
        }
    }

    private func applyPersonChange(_ remote: SupabasePerson, modelContext: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == remote.id }
        )

        do {
            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.name = remote.name
                    existing.email = remote.email ?? ""
                    existing.phone = remote.phone ?? ""
                    existing.balance = NSDecimalNumber(decimal: remote.balance).doubleValue
                    existing.syncVersion = remote.syncVersion
                }
            } else if remote.deletedAt == nil {
                let newPerson = PersonModel.from(remote: remote)
                modelContext.insert(newPerson)
            }
        } catch {
            print("Failed to apply person change: \(error)")
        }
    }

    private func applyGroupChange(_ remote: SupabaseGroup, modelContext: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == remote.id }
        )

        do {
            let existing = try modelContext.fetch(fetchDescriptor).first

            if let existing = existing {
                if remote.syncVersion > existing.syncVersion {
                    existing.name = remote.name
                    existing.groupDescription = remote.description ?? ""
                    existing.emoji = remote.emoji ?? "👥"
                    existing.totalAmount = NSDecimalNumber(decimal: remote.totalAmount).doubleValue
                    existing.syncVersion = remote.syncVersion
                }
            } else if remote.deletedAt == nil {
                let newGroup = GroupModel.from(remote: remote)
                modelContext.insert(newGroup)
            }
        } catch {
            print("Failed to apply group change: \(error)")
        }
    }

    // MARK: - Persistence

    private func loadPendingChanges() {
        guard FileManager.default.fileExists(atPath: pendingChangesURL.path) else { return }

        do {
            let data = try Data(contentsOf: pendingChangesURL)
            pendingChanges = try JSONDecoder().decode([PendingChange].self, from: data)
            pendingChangesCount = pendingChanges.count
        } catch {
            print("Failed to load pending changes: \(error)")
        }
    }

    private func savePendingChanges() {
        do {
            let data = try JSONEncoder().encode(pendingChanges)
            try data.write(to: pendingChangesURL)
        } catch {
            print("Failed to save pending changes: \(error)")
        }
    }

    private func loadLastSyncDate() {
        guard FileManager.default.fileExists(atPath: lastSyncURL.path) else { return }

        do {
            let data = try Data(contentsOf: lastSyncURL)
            let wrapper = try JSONDecoder().decode(DateWrapper.self, from: data)
            lastSyncDate = wrapper.date
        } catch {
            print("Failed to load last sync date: \(error)")
        }
    }

    private func saveLastSyncDate() {
        guard let date = lastSyncDate else { return }

        do {
            let wrapper = DateWrapper(date: date)
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: lastSyncURL)
        } catch {
            print("Failed to save last sync date: \(error)")
        }
    }

    // MARK: - Cleanup

    func cleanup() async {
        await stopRealtimeSync()
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Types

/// Represents a pending change to be synced
struct PendingChange: Codable, Identifiable {
    let id: UUID
    let recordId: UUID
    let table: String
    let operation: SyncOperation
    let payload: Data?
    let timestamp: Date
    var retryCount: Int
}

/// Sync operation type
enum SyncOperation: String, Codable {
    case insert
    case update
    case delete
}

/// Sync progress state
enum SyncProgress: Equatable {
    case idle
    case syncing(completed: Int, total: Int)
    case completed
    case failed(Int)

    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }
}

/// Sync error types
enum SyncError: LocalizedError, Identifiable {
    case offline
    case notAuthenticated
    case invalidPayload
    case syncFailed(String)
    case partialSyncFailure(failedCount: Int)
    case conflictResolutionFailed

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .offline:
            return "You are offline. Changes will sync when connected."
        case .notAuthenticated:
            return "Please sign in to sync your data."
        case .invalidPayload:
            return "Invalid data format."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .partialSyncFailure(let count):
            return "\(count) changes failed to sync. Will retry automatically."
        case .conflictResolutionFailed:
            return "Failed to resolve data conflict."
        }
    }
}

/// Wrapper for encoding dates
private struct DateWrapper: Codable {
    let date: Date
}

// MARK: - SwiftData Model Extensions for Supabase

extension PersonModel {
    /// Create from Supabase remote model
    static func from(remote: SupabasePerson) -> PersonModel {
        // Determine avatar type
        let avatarType: AvatarType
        switch remote.avatarType {
        case "photo":
            avatarType = .photo(Data())
        case "emoji":
            avatarType = .emoji(remote.avatarEmoji ?? "👤")
        case "initials":
            avatarType = .initials(remote.avatarInitials ?? remote.name, colorIndex: remote.avatarColorIndex ?? 0)
        default:
            avatarType = .initials(remote.name, colorIndex: remote.avatarColorIndex ?? 0)
        }

        // Decode notification preferences
        let notifPrefs: NotificationPreferences
        if let prefsData = remote.notificationPreferences {
            notifPrefs = NotificationPreferences(
                enableReminders: prefsData.enableReminders,
                reminderFrequency: prefsData.reminderFrequency,
                preferredContactMethod: ContactMethod(rawValue: prefsData.preferredContactMethod) ?? .inApp
            )
        } else {
            notifPrefs = NotificationPreferences()
        }

        // Decode person source
        let personSource = remote.personSource.flatMap { PersonSource(rawValue: $0) } ?? .manual

        let model = PersonModel(
            id: remote.id,
            name: remote.name,
            email: remote.email ?? "",
            phone: remote.phone ?? "",
            avatarType: avatarType,
            balance: NSDecimalNumber(decimal: remote.balance).doubleValue,
            createdDate: remote.createdAt,
            lastModifiedDate: remote.updatedAt,
            contactId: remote.contactId,
            preferredPaymentMethod: remote.preferredPaymentMethod.flatMap { PaymentMethod(rawValue: $0) },
            notificationPreferences: notifPrefs,
            relationshipType: remote.relationshipType,
            notes: remote.notes,
            personSource: personSource
        )
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension AccountModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseAccount) -> AccountModel {
        let accountType = AccountType(rawValue: remote.type) ?? .bank
        let model = AccountModel(
            id: remote.id,
            name: remote.name,
            number: remote.number ?? "",
            type: accountType,
            isDefault: remote.isDefault,
            createdDate: remote.createdAt
        )
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension GroupModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseGroup) -> GroupModel {
        let model = GroupModel(
            id: remote.id,
            name: remote.name,
            description: remote.description ?? "",
            emoji: remote.emoji ?? "👥",
            createdDate: remote.createdAt,
            totalAmount: NSDecimalNumber(decimal: remote.totalAmount).doubleValue
        )
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension SubscriptionModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseSubscription) -> SubscriptionModel {
        let billingCycle = BillingCycle(rawValue: remote.billingCycle) ?? .monthly
        let category = SubscriptionCategory(rawValue: remote.category) ?? .other

        let model = SubscriptionModel(
            id: remote.id,
            name: remote.name,
            description: remote.description ?? "",
            price: NSDecimalNumber(decimal: remote.price).doubleValue,
            billingCycle: billingCycle,
            category: category,
            icon: remote.icon ?? "app.fill",
            color: remote.color ?? "#007AFF"
        )
        model.nextBillingDate = remote.nextBillingDate ?? billingCycle.calculateNextBilling(from: Date())
        model.isActive = remote.isActive
        model.isShared = remote.isShared
        model.paymentMethodRaw = remote.paymentMethod ?? PaymentMethod.creditCard.rawValue
        model.createdDate = remote.createdAt
        model.lastBillingDate = remote.lastBillingDate
        model.totalSpent = NSDecimalNumber(decimal: remote.totalSpent).doubleValue
        model.notes = remote.notes ?? ""
        model.website = remote.website
        model.isFreeTrial = remote.isFreeTrial
        model.trialStartDate = remote.trialStartDate
        model.trialEndDate = remote.trialEndDate
        model.enableRenewalReminder = remote.enableRenewalReminder
        model.reminderDaysBefore = remote.reminderDaysBefore ?? 3
        model.autoRenew = remote.autoRenew
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension TransactionModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseTransaction) -> TransactionModel {
        let category = TransactionCategory(rawValue: remote.category) ?? .other
        let paymentStatus = PaymentStatus(rawValue: remote.paymentStatus) ?? .completed
        let paymentMethod = remote.paymentMethod.flatMap { PaymentMethod(rawValue: $0) }
        let transactionType = remote.transactionType.flatMap { TransactionType(rawValue: $0) }

        let model = TransactionModel(
            id: remote.id,
            title: remote.title,
            subtitle: remote.subtitle ?? "",
            amount: NSDecimalNumber(decimal: remote.amount).doubleValue,
            category: category,
            date: remote.date,
            isRecurring: remote.isRecurring,
            tags: remote.tags,
            merchant: remote.merchant,
            paymentStatus: paymentStatus,
            receiptData: nil,
            linkedSubscriptionId: remote.linkedSubscriptionId,
            merchantCategory: remote.merchantCategory,
            isRecurringCharge: remote.isRecurringCharge,
            paymentMethod: paymentMethod,
            location: remote.location,
            notes: remote.notes ?? "",
            splitBillId: remote.splitBillId,
            transactionType: transactionType
        )
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension SplitBillModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseSplitBill) -> SplitBillModel {
        let splitType = SplitType(rawValue: remote.splitType) ?? .equally
        let category = TransactionCategory(rawValue: remote.category) ?? .dining

        // Determine paidById - use personId first, then userId, fallback to empty UUID
        let paidById = remote.paidByPersonId ?? remote.paidByUserId ?? UUID()

        // Create a domain SplitBill first
        var splitBill = SplitBill(
            title: remote.title,
            totalAmount: NSDecimalNumber(decimal: remote.totalAmount).doubleValue,
            paidById: paidById,
            splitType: splitType,
            participants: [], // Participants loaded separately
            notes: remote.notes ?? "",
            category: category,
            date: remote.date,
            groupId: remote.groupId
        )
        splitBill.id = remote.id
        splitBill.createdDate = remote.createdAt

        let model = SplitBillModel(from: splitBill)
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension PriceChangeModel {
    /// Create from Supabase remote model
    static func from(remote: SupabasePriceChange) -> PriceChangeModel {
        let model = PriceChangeModel(
            id: remote.id,
            subscriptionId: remote.subscriptionId,
            oldPrice: NSDecimalNumber(decimal: remote.oldPrice).doubleValue,
            newPrice: NSDecimalNumber(decimal: remote.newPrice).doubleValue,
            changeDate: remote.changeDate,
            reason: remote.reason,
            detectedAutomatically: remote.detectedAutomatically
        )
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension SharedSubscriptionModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseSharedSubscription) -> SharedSubscriptionModel {
        // Parse cost split type
        let costSplit = CostSplitType(rawValue: remote.costSplitType) ?? .equal

        // Build sharedWithIDs from remote
        var sharedWithIDs: [UUID] = []
        if let personId = remote.sharedWithPersonId {
            sharedWithIDs.append(personId)
        }
        if let userId = remote.sharedWithUserId {
            sharedWithIDs.append(userId)
        }

        let model = SharedSubscriptionModel(
            id: remote.id,
            subscriptionID: remote.subscriptionId,
            sharedByID: remote.sharedByUserId,
            sharedWithIDs: sharedWithIDs,
            costSplit: costSplit
        )
        if let individualCost = remote.individualCost {
            model.individualCost = NSDecimalNumber(decimal: individualCost).doubleValue
        }
        model.isAccepted = remote.isAccepted
        model.notes = remote.notes ?? ""
        model.createdDate = remote.createdAt
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}

extension GroupExpenseModel {
    /// Create from Supabase remote model
    static func from(remote: SupabaseGroupExpense) -> GroupExpenseModel {
        let category = TransactionCategory(rawValue: remote.category) ?? .other

        // Use paidByPersonId first, then paidByUserId
        let paidByID = remote.paidByPersonId ?? remote.paidByUserId ?? UUID()

        let model = GroupExpenseModel(
            id: remote.id,
            title: remote.title,
            amount: NSDecimalNumber(decimal: remote.amount).doubleValue,
            paidByID: paidByID,
            splitBetweenIDs: remote.splitBetweenPersonIds,
            category: category,
            date: remote.date,
            notes: remote.notes ?? "",
            receiptPath: remote.receiptPath,
            isSettled: remote.isSettled
        )
        model.syncVersion = remote.syncVersion
        model.deletedAt = remote.deletedAt
        model.pendingSync = false
        return model
    }
}
