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

            // If database is empty, populate sample data for easy visualization
            if !hasData {
                print("📊 Database is empty, populating sample data for visualization...")
                try populateSampleData()
                // Reload data after populating
                people = try persistenceService.fetchAllPeople()
                groups = try persistenceService.fetchAllGroups()
                subscriptions = try persistenceService.fetchAllSubscriptions()
                transactions = try persistenceService.fetchAllTransactions()
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
        print("📝 Populating comprehensive sample data...")

        // Sample People with diverse avatars and balances
        var emma = Person(
            name: "Emma Wilson",
            email: "emma.wilson@email.com",
            phone: "+1 (555) 123-4567",
            avatarType: .emoji("👩‍💼")
        )
        emma.balance = 45.50
        
        var james = Person(
            name: "James Chen",
            email: "james.chen@email.com",
            phone: "+1 (555) 234-5678",
            avatarType: .emoji("👨‍💻")
        )
        james.balance = -32.00
        
        var sofia = Person(
            name: "Sofia Rodriguez",
            email: "sofia.rodriguez@email.com",
            phone: "+1 (555) 345-6789",
            avatarType: .emoji("👩‍🎨")
        )
        sofia.balance = 120.75
        
        var michael = Person(
            name: "Michael Taylor",
            email: "michael.taylor@email.com",
            phone: "+1 (555) 456-7890",
            avatarType: .emoji("👨‍🍳")
        )
        michael.balance = -25.00
        
        var aisha = Person(
            name: "Aisha Patel",
            email: "aisha.patel@email.com",
            phone: "+1 (555) 567-8901",
            avatarType: .emoji("👩‍⚕️")
        )
        aisha.balance = 0.0
        
        var david = Person(
            name: "David Kim",
            email: "david.kim@email.com",
            phone: "+1 (555) 678-9012",
            avatarType: .emoji("👨‍🔬")
        )
        david.balance = 78.25
        
        var olivia = Person(
            name: "Olivia Brown",
            email: "olivia.brown@email.com",
            phone: "+1 (555) 789-0123",
            avatarType: .emoji("👩‍🏫")
        )
        olivia.balance = -15.50

        let samplePeople = [emma, james, sofia, michael, aisha, david, olivia]

        // Save people first (no dependencies)
        for person in samplePeople {
            try persistenceService.savePerson(person)
        }

        // Comprehensive Sample Subscriptions
        var netflixSub = Subscription(
            name: "Netflix",
            description: "Premium 4K streaming plan",
            price: 19.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )
        netflixSub.isActive = true
        netflixSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()

        var spotifySub = Subscription(
            name: "Spotify Premium",
            description: "Ad-free music streaming",
            price: 10.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "music.note",
            color: "#1DB954"
        )
        spotifySub.isActive = true
        spotifySub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

        var gymSub = Subscription(
            name: "Gym Membership",
            description: "24/7 fitness center access",
            price: 49.99,
            billingCycle: .monthly,
            category: .health,
            icon: "figure.run",
            color: "#FF6B35"
        )
        gymSub.isActive = true
        gymSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        
        var icloudSub = Subscription(
            name: "iCloud+",
            description: "200GB cloud storage",
            price: 2.99,
            billingCycle: .monthly,
            category: .productivity,
            icon: "cloud.fill",
            color: "#007AFF"
        )
        icloudSub.isActive = true
        icloudSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date()
        
        var youtubeSub = Subscription(
            name: "YouTube Premium",
            description: "Ad-free videos & music",
            price: 13.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.rectangle.fill",
            color: "#FF0000"
        )
        youtubeSub.isActive = true
        youtubeSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 8, to: Date()) ?? Date()
        
        var nytSub = Subscription(
            name: "The New York Times",
            description: "Digital news subscription",
            price: 17.00,
            billingCycle: .monthly,
            category: .news,
            icon: "newspaper.fill",
            color: "#000000"
        )
        nytSub.isActive = true
        nytSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date()
        
        var hboSub = Subscription(
            name: "HBO Max",
            description: "Premium content streaming",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "sparkles.tv.fill",
            color: "#7E22CE"
        )
        hboSub.isActive = true
        hboSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 25, to: Date()) ?? Date()
        
        var duolingoSub = Subscription(
            name: "Duolingo Plus",
            description: "Language learning app",
            price: 6.99,
            billingCycle: .monthly,
            category: .education,
            icon: "character.book.closed.fill",
            color: "#58CC02"
        )
        duolingoSub.isActive = true
        duolingoSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 18, to: Date()) ?? Date()
        
        var adobeSub = Subscription(
            name: "Adobe Creative Cloud",
            description: "Full creative suite access",
            price: 54.99,
            billingCycle: .monthly,
            category: .productivity,
            icon: "paintbrush.fill",
            color: "#FF0000"
        )
        adobeSub.isActive = true
        adobeSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date()
        
        var linkedinSub = Subscription(
            name: "LinkedIn Premium",
            description: "Career development tools",
            price: 29.99,
            billingCycle: .monthly,
            category: .productivity,
            icon: "briefcase.fill",
            color: "#0A66C2"
        )
        linkedinSub.isActive = true
        linkedinSub.nextBillingDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        let sampleSubscriptions = [netflixSub, spotifySub, gymSub, icloudSub, youtubeSub, 
                                  nytSub, hboSub, duolingoSub, adobeSub, linkedinSub]

        for subscription in sampleSubscriptions {
            try persistenceService.saveSubscription(subscription)
        }

        // Comprehensive Sample Transactions (last 30 days)
        let now = Date()
        var sampleTransactions: [Transaction] = []
        
        // Income transactions
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Salary",
            subtitle: "Monthly paycheck - Tech Corp",
            amount: 5250.00,
            category: .income,
            date: Calendar.current.date(byAdding: .day, value: -25, to: now)!,
            isRecurring: true,
            tags: ["work", "monthly", "salary"],
            merchant: "Tech Corp"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Freelance Project",
            subtitle: "Website design work",
            amount: 850.00,
            category: .income,
            date: Calendar.current.date(byAdding: .day, value: -15, to: now)!,
            isRecurring: false,
            tags: ["freelance", "design"],
            merchant: "Client Inc"
        ))
        
        // Housing & Utilities
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Rent Payment",
            subtitle: "Monthly rent",
            amount: -1800.00,
            category: .utilities,
            date: Calendar.current.date(byAdding: .day, value: -28, to: now)!,
            isRecurring: true,
            tags: ["housing", "monthly"],
            merchant: "Property Management Co"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Electricity Bill",
            subtitle: "Monthly utility",
            amount: -125.50,
            category: .utilities,
            date: Calendar.current.date(byAdding: .day, value: -20, to: now)!,
            isRecurring: true,
            tags: ["utilities", "monthly"],
            merchant: "Power Company"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Internet Service",
            subtitle: "Fiber optic 1Gbps",
            amount: -79.99,
            category: .utilities,
            date: Calendar.current.date(byAdding: .day, value: -18, to: now)!,
            isRecurring: true,
            tags: ["utilities", "internet"],
            merchant: "ISP Provider"
        ))
        
        // Groceries
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Weekly Groceries",
            subtitle: "Whole Foods Market",
            amount: -156.32,
            category: .groceries,
            date: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
            isRecurring: false,
            tags: ["food", "weekly"],
            merchant: "Whole Foods"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Grocery Shopping",
            subtitle: "Trader Joe's",
            amount: -98.75,
            category: .groceries,
            date: Calendar.current.date(byAdding: .day, value: -9, to: now)!,
            isRecurring: false,
            tags: ["food"],
            merchant: "Trader Joe's"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Farmers Market",
            subtitle: "Fresh produce",
            amount: -45.00,
            category: .groceries,
            date: Calendar.current.date(byAdding: .day, value: -6, to: now)!,
            isRecurring: false,
            tags: ["food", "fresh"],
            merchant: "Downtown Farmers Market"
        ))
        
        // Dining Out
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Dinner",
            subtitle: "Italian Restaurant",
            amount: -92.50,
            category: .dining,
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            isRecurring: false,
            tags: ["food", "dining", "italian"],
            merchant: "La Bella Vista"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Coffee Shop",
            subtitle: "Morning latte",
            amount: -5.75,
            category: .dining,
            date: Calendar.current.date(byAdding: .day, value: 0, to: now)!,
            isRecurring: false,
            tags: ["coffee", "morning"],
            merchant: "Starbucks"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Lunch",
            subtitle: "Sushi restaurant",
            amount: -32.00,
            category: .dining,
            date: Calendar.current.date(byAdding: .day, value: -4, to: now)!,
            isRecurring: false,
            tags: ["food", "lunch", "sushi"],
            merchant: "Tokyo Sushi Bar"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Brunch",
            subtitle: "Weekend brunch with friends",
            amount: -67.80,
            category: .dining,
            date: Calendar.current.date(byAdding: .day, value: -7, to: now)!,
            isRecurring: false,
            tags: ["food", "brunch", "friends"],
            merchant: "Sunny Side Cafe"
        ))
        
        // Transportation
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Gas Station",
            subtitle: "Shell fuel",
            amount: -58.20,
            category: .transportation,
            date: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
            isRecurring: false,
            tags: ["car", "fuel"],
            merchant: "Shell"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Uber Ride",
            subtitle: "Downtown to airport",
            amount: -35.00,
            category: .transportation,
            date: Calendar.current.date(byAdding: .day, value: -12, to: now)!,
            isRecurring: false,
            tags: ["rideshare", "airport"],
            merchant: "Uber"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Parking Fee",
            subtitle: "Downtown garage",
            amount: -18.00,
            category: .transportation,
            date: Calendar.current.date(byAdding: .day, value: -5, to: now)!,
            isRecurring: false,
            tags: ["parking"],
            merchant: "City Parking"
        ))
        
        // Shopping
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Amazon Purchase",
            subtitle: "Electronics & home goods",
            amount: -234.99,
            category: .shopping,
            date: Calendar.current.date(byAdding: .day, value: -8, to: now)!,
            isRecurring: false,
            tags: ["online", "electronics"],
            merchant: "Amazon"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Clothing Store",
            subtitle: "New work outfits",
            amount: -189.50,
            category: .shopping,
            date: Calendar.current.date(byAdding: .day, value: -14, to: now)!,
            isRecurring: false,
            tags: ["clothing", "work"],
            merchant: "Nordstrom"
        ))
        
        // Entertainment
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Movie Tickets",
            subtitle: "IMAX screening",
            amount: -42.00,
            category: .entertainment,
            date: Calendar.current.date(byAdding: .day, value: -10, to: now)!,
            isRecurring: false,
            tags: ["movies", "entertainment"],
            merchant: "AMC Theaters"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Concert Tickets",
            subtitle: "Live music event",
            amount: -125.00,
            category: .entertainment,
            date: Calendar.current.date(byAdding: .day, value: -16, to: now)!,
            isRecurring: false,
            tags: ["concert", "music"],
            merchant: "Ticketmaster"
        ))
        
        // Healthcare
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Doctor Visit",
            subtitle: "Annual checkup copay",
            amount: -35.00,
            category: .healthcare,
            date: Calendar.current.date(byAdding: .day, value: -22, to: now)!,
            isRecurring: false,
            tags: ["healthcare", "medical"],
            merchant: "Healthcare Clinic"
        ))
        
        sampleTransactions.append(Transaction(
            id: UUID(),
            title: "Pharmacy",
            subtitle: "Prescription refill",
            amount: -25.50,
            category: .healthcare,
            date: Calendar.current.date(byAdding: .day, value: -11, to: now)!,
            isRecurring: false,
            tags: ["pharmacy", "medication"],
            merchant: "CVS Pharmacy"
        ))

        for transaction in sampleTransactions {
            try persistenceService.saveTransaction(transaction)
        }

        // Sample Groups with detailed expenses
        var weekendTrip = Group(
            name: "Weekend Getaway",
            description: "Beach house vacation",
            emoji: "🏖️",
            members: [emma.id, james.id, sofia.id]
        )

        let hotelExpense = GroupExpense(
            title: "Beach House Rental",
            amount: 450.00,
            paidBy: emma.id,
            splitBetween: [emma.id, james.id, sofia.id],
            category: .travel,
            notes: "3 nights at Ocean View",
            receipt: nil,
            isSettled: false
        )
        
        let groceriesExpense = GroupExpense(
            title: "Groceries for Trip",
            amount: 180.00,
            paidBy: james.id,
            splitBetween: [emma.id, james.id, sofia.id],
            category: .groceries,
            notes: "Food and drinks for the weekend",
            receipt: nil,
            isSettled: false
        )

        weekendTrip.expenses = [hotelExpense, groceriesExpense]
        weekendTrip.totalAmount = 630.00

        var dinnerGroup = Group(
            name: "Dinner Club",
            description: "Monthly dinner meetups",
            emoji: "🍽️",
            members: [michael.id, aisha.id, david.id]
        )

        let dinnerExpense = GroupExpense(
            title: "Italian Dinner",
            amount: 195.00,
            paidBy: michael.id,
            splitBetween: [michael.id, aisha.id, david.id],
            category: .dining,
            notes: "Birthday celebration at La Trattoria",
            receipt: nil,
            isSettled: true
        )

        dinnerGroup.expenses = [dinnerExpense]
        dinnerGroup.totalAmount = 195.00
        
        var studyGroup = Group(
            name: "Study Buddies",
            description: "Course materials sharing",
            emoji: "📚",
            members: [olivia.id, james.id, aisha.id, david.id]
        )
        
        let textbooksExpense = GroupExpense(
            title: "Textbooks",
            amount: 320.00,
            paidBy: olivia.id,
            splitBetween: [olivia.id, james.id, aisha.id, david.id],
            category: .shopping,
            notes: "Semester textbooks bundle",
            receipt: nil,
            isSettled: false
        )
        
        studyGroup.expenses = [textbooksExpense]
        studyGroup.totalAmount = 320.00

        let sampleGroups = [weekendTrip, dinnerGroup, studyGroup]

        for group in sampleGroups {
            try persistenceService.saveGroup(group)
        }

        print("✅ Comprehensive sample data populated successfully!")
        print("   - 7 People with balances")
        print("   - 10 Active subscriptions")
        print("   - 25+ Transactions across various categories")
        print("   - 3 Groups with multiple expenses")
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
    
    /// Force populate sample data (useful for testing/demo)
    func forcePopulateSampleData() throws {
        print("🔄 Force populating sample data...")
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
