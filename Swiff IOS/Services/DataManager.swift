//
//  DataManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Centralized data manager for app state management
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = DataManager()
    
    // MARK: - Published Properties

    @Published var people: [Person] = []
    @Published var groups: [Group] = []
    @Published var subscriptions: [Subscription] = []
    @Published var transactions: [Transaction] = []

    @Published var isLoading = false
    @Published var error: Error?
    @Published var isFirstLaunch = false

    // Progress tracking for long-running operations
    @Published var operationProgress: Double? = nil
    @Published var operationMessage: String? = nil
    @Published var isPerformingOperation = false

    // MARK: - Private Properties

    private let persistenceService = PersistenceService.shared
    private let renewalService = SubscriptionRenewalService.shared
    private let firstLaunchKey = "HasLaunchedBefore"

    // MARK: - Computed Properties

    var hasData: Bool {
        !people.isEmpty || !groups.isEmpty || !subscriptions.isEmpty || !transactions.isEmpty
    }

    var peopleCount: Int { people.count }
    var groupsCount: Int { groups.count }
    var subscriptionsCount: Int { subscriptions.count }
    var transactionsCount: Int { transactions.count }

    // MARK: - Initialization

    private init() {
        checkFirstLaunch()
    }

    // MARK: - Data Loading

    func loadAllData() {
        isLoading = true
        error = nil

        do {
            // Load all data from persistence
            people = try persistenceService.fetchAllPeople()
            groups = try persistenceService.fetchAllGroups()
            subscriptions = try persistenceService.fetchAllSubscriptions()
            transactions = try persistenceService.fetchAllTransactions()

            // If database is empty and it's first launch, populate sample data
            if !hasData && isFirstLaunch {
                try populateSampleData()
                // Reload data after populating
                people = try persistenceService.fetchAllPeople()
                groups = try persistenceService.fetchAllGroups()
                subscriptions = try persistenceService.fetchAllSubscriptions()
                transactions = try persistenceService.fetchAllTransactions()

                markFirstLaunchComplete()
            }

            isLoading = false
            print("✅ Data loaded successfully:")
            print("   - People: \(people.count)")
            print("   - Groups: \(groups.count)")
            print("   - Subscriptions: \(subscriptions.count)")
            print("   - Transactions: \(transactions.count)")

            // Process overdue subscription renewals
            Task {
                await renewalService.processOverdueRenewals()
            }

        } catch {
            self.error = error
            isLoading = false
            print("❌ Error loading data: \(error.localizedDescription)")
        }
    }

    func refreshAllData() {
        loadAllData()
    }

    // MARK: - Person CRUD Operations

    func addPerson(_ person: Person) throws {
        try persistenceService.savePerson(person)
        people.append(person)
        print("✅ Person added: \(person.name)")

        // Index in Spotlight
        indexPersonInSpotlight(person)
    }

    func updatePerson(_ person: Person) throws {
        try persistenceService.updatePerson(person)
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
            print("✅ Person updated: \(person.name)")

            // Update in Spotlight
            indexPersonInSpotlight(person)
        }
    }

    func deletePerson(id: UUID) throws {
        try persistenceService.deletePerson(id: id)
        people.removeAll { $0.id == id }
        print("✅ Person deleted")

        // Remove from Spotlight
        removePersonFromSpotlight(id)
    }

    func searchPeople(byName searchTerm: String) -> [Person] {
        if searchTerm.isEmpty {
            return people
        }
        return people.filter { $0.name.localizedStandardContains(searchTerm) }
    }

    // MARK: - Group CRUD Operations

    func addGroup(_ group: Group) throws {
        try persistenceService.saveGroup(group)
        groups.append(group)
        print("✅ Group added: \(group.name)")
    }

    func updateGroup(_ group: Group) throws {
        try persistenceService.updateGroup(group)
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            print("✅ Group updated: \(group.name)")
        }
    }

    func deleteGroup(id: UUID) throws {
        try persistenceService.deleteGroup(id: id)
        groups.removeAll { $0.id == id }
        print("✅ Group deleted")
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
        print("✅ Subscription added: \(subscription.name)")

        // AGENT 7: Schedule notifications for new subscription
        Task {
            await NotificationManager.shared.updateScheduledReminders(for: subscription)
        }

        // Index in Spotlight
        indexSubscriptionInSpotlight(subscription)
    }

    func updateSubscription(_ subscription: Subscription) throws {
        // AGENT 9: Detect price changes before updating
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

                    // Schedule notification if price increased
                    if subscription.price > oldSubscription.price {
                        Task {
                            await NotificationManager.shared.schedulePriceChangeAlert(
                                for: subscription,
                                oldPrice: oldSubscription.price,
                                newPrice: subscription.price
                            )
                        }
                    }
                } catch {
                    print("⚠️ Failed to create price change record: \(error.localizedDescription)")
                }
            }
        }

        try persistenceService.updateSubscription(subscription)
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            print("✅ Subscription updated: \(subscription.name)")

            // AGENT 7: Reschedule notifications with updated settings
            Task {
                await NotificationManager.shared.updateScheduledReminders(for: subscription)
            }

            // Update in Spotlight
            indexSubscriptionInSpotlight(subscription)
        }
    }

    func deleteSubscription(id: UUID) throws {
        // AGENT 7: Cancel all notifications for this subscription before deleting
        if let subscription = subscriptions.first(where: { $0.id == id }) {
            NotificationManager.shared.cancelAllReminders(for: subscription)
        }

        try persistenceService.deleteSubscription(id: id)
        subscriptions.removeAll { $0.id == id }
        print("✅ Subscription deleted")

        // Remove from Spotlight
        removeSubscriptionFromSpotlight(id)
    }

    func getActiveSubscriptions() -> [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    func getInactiveSubscriptions() -> [Subscription] {
        subscriptions.filter { !$0.isActive }
    }

    // MARK: - Price Change Operations (AGENT 9)

    func addPriceChange(_ priceChange: PriceChange) throws {
        try persistenceService.savePriceChange(priceChange)
        print("✅ Price change recorded: $\(priceChange.oldPrice) → $\(priceChange.newPrice)")
    }

    func getPriceHistory(for subscriptionId: UUID) -> [PriceChange] {
        do {
            return try persistenceService.fetchPriceChanges(forSubscription: subscriptionId)
        } catch {
            print("❌ Error fetching price history: \(error.localizedDescription)")
            return []
        }
    }

    func getAllPriceChanges() -> [PriceChange] {
        do {
            return try persistenceService.fetchAllPriceChanges()
        } catch {
            print("❌ Error fetching all price changes: \(error.localizedDescription)")
            return []
        }
    }

    func getRecentPriceIncreases(days: Int = 30) -> [PriceChange] {
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
    func processOverdueRenewals() async {
        await renewalService.processOverdueRenewals()
        loadAllData() // Reload data to reflect changes
    }

    /// Pause a subscription
    func pauseSubscription(_ subscription: Subscription) async {
        await renewalService.pauseSubscription(subscription)
        loadAllData() // Reload data to reflect changes
    }

    /// Resume a paused subscription
    func resumeSubscription(_ subscription: Subscription) async {
        await renewalService.resumeSubscription(subscription)
        loadAllData() // Reload data to reflect changes
    }

    /// Cancel a subscription permanently
    func cancelSubscription(_ subscription: Subscription) async {
        await renewalService.cancelSubscription(subscription)
        loadAllData() // Reload data to reflect changes
    }

    // MARK: - Transaction CRUD Operations

    func addTransaction(_ transaction: Transaction) throws {
        try persistenceService.saveTransaction(transaction)
        transactions.append(transaction)
        transactions.sort { $0.date > $1.date } // Keep sorted by date
        print("✅ Transaction added: \(transaction.title)")

        // Index in Spotlight
        indexTransactionInSpotlight(transaction)
    }

    func updateTransaction(_ transaction: Transaction) throws {
        try persistenceService.updateTransaction(transaction)
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date } // Re-sort
            print("✅ Transaction updated: \(transaction.title)")

            // Update in Spotlight
            indexTransactionInSpotlight(transaction)
        }
    }

    func deleteTransaction(id: UUID) throws {
        try persistenceService.deleteTransaction(id: id)
        transactions.removeAll { $0.id == id }
        print("✅ Transaction deleted")

        // Remove from Spotlight
        removeTransactionFromSpotlight(id)
    }

    func getCurrentMonthTransactions() -> [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
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
    func bulkDeleteTransactions(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }

        // Delete from persistence
        for id in ids {
            try persistenceService.deleteTransaction(id: id)
        }

        // Remove from local array
        transactions.removeAll { ids.contains($0.id) }

        print("✅ Bulk delete complete: \(ids.count) transaction(s) deleted")
    }

    /// Bulk update category for multiple transactions
    func bulkUpdateCategory(transactionIds: [UUID], category: TransactionCategory) throws {
        guard !transactionIds.isEmpty else { return }

        // Update each transaction
        for id in transactionIds {
            if let index = transactions.firstIndex(where: { $0.id == id }) {
                var updatedTransaction = transactions[index]
                updatedTransaction.category = category

                // Update in persistence
                try persistenceService.updateTransaction(updatedTransaction)

                // Update in local array
                transactions[index] = updatedTransaction
            }
        }

        print("✅ Bulk category update complete: \(transactionIds.count) transaction(s) updated to \(category.rawValue)")
    }

    /// Bulk add tags to multiple transactions
    func bulkAddTags(transactionIds: [UUID], tags: [String]) throws {
        guard !transactionIds.isEmpty, !tags.isEmpty else { return }

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
            }
        }

        print("✅ Bulk tag addition complete: \(tags.count) tag(s) added to \(transactionIds.count) transaction(s)")
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
        }
    }

    func settleExpense(id: UUID, inGroup groupID: UUID) throws {
        try persistenceService.settleExpense(id: id)

        // Update local group
        if let groupIndex = groups.firstIndex(where: { $0.id == groupID }) {
            var updatedGroup = groups[groupIndex]
            if let expenseIndex = updatedGroup.expenses.firstIndex(where: { $0.id == id }) {
                updatedGroup.expenses[expenseIndex].isSettled = true
                groups[groupIndex] = updatedGroup
                print("✅ Expense settled")
            }
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
                self.operationMessage = "Imported \(imported) of \(subscriptions.count) subscriptions"

                print("📥 Imported subscription \(imported)/\(subscriptions.count): \(subscription.name)")
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

                print("📥 Imported transaction \(imported)/\(transactions.count): \(transaction.title)")
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
    }

    private func updateSubscriptionInternal(_ subscription: Subscription) async throws {
        try persistenceService.updateSubscription(subscription)
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        }
    }

    private func updateTransactionInternal(_ transaction: Transaction) async throws {
        try persistenceService.updateTransaction(transaction)
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date }
        }
    }

    private func updateGroupInternal(_ group: Group) async throws {
        try persistenceService.updateGroup(group)
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
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

    // MARK: - Sample Data Population

    private func populateSampleData() throws {
        print("📝 Populating sample data...")

        // Sample People
        let samplePeople: [Person] = [
            Person(
                name: "Emma Wilson",
                email: "emma.wilson@email.com",
                phone: "+1 (555) 123-4567",
                avatarType: .emoji("👩‍💼")
            ),
            Person(
                name: "James Chen",
                email: "james.chen@email.com",
                phone: "+1 (555) 234-5678",
                avatarType: .emoji("👨‍💻")
            ),
            Person(
                name: "Sofia Rodriguez",
                email: "sofia.rodriguez@email.com",
                phone: "+1 (555) 345-6789",
                avatarType: .emoji("👩‍🎨")
            ),
            Person(
                name: "Michael Taylor",
                email: "michael.taylor@email.com",
                phone: "+1 (555) 456-7890",
                avatarType: .emoji("👨‍🍳")
            ),
            Person(
                name: "Aisha Patel",
                email: "aisha.patel@email.com",
                phone: "+1 (555) 567-8901",
                avatarType: .emoji("👩‍⚕️")
            )
        ]

        // Save people first (no dependencies)
        for person in samplePeople {
            try persistenceService.savePerson(person)
        }

        // Sample Subscriptions
        var netflixSub = Subscription(
            name: "Netflix",
            description: "Premium streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )
        netflixSub.isActive = true
        netflixSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()

        var spotifySub = Subscription(
            name: "Spotify",
            description: "Music streaming",
            price: 9.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "music.note",
            color: "#1DB954"
        )
        spotifySub.isActive = true
        spotifySub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date()

        var gymSub = Subscription(
            name: "Gym Membership",
            description: "Monthly gym access",
            price: 49.99,
            billingCycle: .monthly,
            category: .health,
            icon: "figure.run",
            color: "#FF6B35"
        )
        gymSub.isActive = true
        gymSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()

        let sampleSubscriptions = [netflixSub, spotifySub, gymSub]

        for subscription in sampleSubscriptions {
            try persistenceService.saveSubscription(subscription)
        }

        // Sample Transactions
        let sampleTransactions: [Transaction] = [
            Transaction(
                id: UUID(),
                title: "Salary",
                subtitle: "Monthly income",
                amount: 5000.00,
                category: .income,
                date: Date(),
                isRecurring: true,
                tags: ["work", "monthly"]
            ),
            Transaction(
                id: UUID(),
                title: "Rent",
                subtitle: "Monthly rent payment",
                amount: -1500.00,
                category: .utilities,
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                isRecurring: true,
                tags: ["housing", "monthly"]
            ),
            Transaction(
                id: UUID(),
                title: "Grocery Shopping",
                subtitle: "Whole Foods",
                amount: -125.50,
                category: .groceries,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                isRecurring: false,
                tags: ["food"]
            ),
            Transaction(
                id: UUID(),
                title: "Dinner at Restaurant",
                subtitle: "Italian Bistro",
                amount: -85.00,
                category: .dining,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                isRecurring: false,
                tags: ["food", "dining"]
            )
        ]

        for transaction in sampleTransactions {
            try persistenceService.saveTransaction(transaction)
        }

        // Sample Groups
        var weekendTrip = Group(
            name: "Weekend Trip",
            description: "Mountain hiking adventure",
            emoji: "🏔️",
            members: [samplePeople[0].id, samplePeople[1].id, samplePeople[2].id]
        )

        let hotelExpense = GroupExpense(
            title: "Hotel Booking",
            amount: 300.00,
            paidBy: samplePeople[0].id,
            splitBetween: [samplePeople[0].id, samplePeople[1].id, samplePeople[2].id],
            category: .travel,
            notes: "2 nights at Mountain Lodge",
            receipt: nil,
            isSettled: false
        )

        weekendTrip.expenses = [hotelExpense]
        weekendTrip.totalAmount = 300.00

        var dinnerGroup = Group(
            name: "Dinner Club",
            description: "Monthly dinner meetups",
            emoji: "🍽️",
            members: [samplePeople[1].id, samplePeople[3].id, samplePeople[4].id]
        )

        let dinnerExpense = GroupExpense(
            title: "Italian Dinner",
            amount: 150.00,
            paidBy: samplePeople[1].id,
            splitBetween: [samplePeople[1].id, samplePeople[3].id, samplePeople[4].id],
            category: .dining,
            notes: "Anniversary celebration",
            receipt: nil,
            isSettled: true
        )

        dinnerGroup.expenses = [dinnerExpense]
        dinnerGroup.totalAmount = 150.00

        let sampleGroups = [weekendTrip, dinnerGroup]

        for group in sampleGroups {
            try persistenceService.saveGroup(group)
        }

        print("✅ Sample data populated successfully!")
    }

    // MARK: - Utility Methods

    func clearAllData() throws {
        people.removeAll()
        groups.removeAll()
        subscriptions.removeAll()
        transactions.removeAll()

        // Note: This would require a clearAllData method in PersistenceService
        // For now, just clear the in-memory arrays
        print("⚠️ Data cleared from memory. Persistence clearing not yet implemented.")
    }

    func resetToSampleData() throws {
        try clearAllData()
        try populateSampleData()
        loadAllData()
    }

    // MARK: - Formatting Utilities

    func formatCurrency(_ amount: Double) -> String {
        let currency = Currency(double: amount)
        return currency.formatted(
            currencyCode: UserSettings.shared.selectedCurrency,
            showSymbol: true,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        )
    }
}
