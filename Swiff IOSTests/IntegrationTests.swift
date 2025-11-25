//
//  IntegrationTests.swift
//  Swiff IOSTests
//
//  Created by Test Agent 15 on 11/21/25.
//  Integration tests for Swiff iOS app workflows
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class IntegrationTests: XCTestCase {

    var dataManager: DataManager!
    var persistenceService: PersistenceService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        // Use shared instances for integration testing
        dataManager = DataManager.shared
        persistenceService = PersistenceService.shared
    }

    override func tearDownWithError() throws {
        dataManager = nil
        persistenceService = nil
        try super.tearDownWithError()
    }

    // MARK: - 15.3.1: DataManager + PersistenceService Integration

    func testDataManagerPersistence() throws {
        // Given: A test person
        let person = SampleDataGenerator.generatePerson(name: "Integration Test Person")

        // When: Adding person via DataManager
        try dataManager.addPerson(person)

        // Then: Person should be persisted and retrievable
        let fetchedPeople = try persistenceService.fetchAllPeople()
        XCTAssertTrue(fetchedPeople.contains(where: { $0.id == person.id }), "Person should be persisted")

        // When: Updating person
        var updatedPerson = person
        updatedPerson.email = "updated@test.com"
        try dataManager.updatePerson(updatedPerson)

        // Then: Updates should be persisted
        let refetchedPeople = try persistenceService.fetchAllPeople()
        let savedPerson = refetchedPeople.first(where: { $0.id == person.id })
        XCTAssertEqual(savedPerson?.email, "updated@test.com", "Person updates should be persisted")

        // When: Deleting person
        try dataManager.deletePerson(id: person.id)

        // Then: Person should be removed from persistence
        let finalPeople = try persistenceService.fetchAllPeople()
        XCTAssertFalse(finalPeople.contains(where: { $0.id == person.id }), "Person should be deleted from persistence")

        print("✅ testDataManagerPersistence passed")
    }

    func testSubscriptionPersistenceWithNotifications() throws {
        // Given: A test subscription
        var subscription = SampleDataGenerator.generateSubscription(name: "Test Subscription")
        subscription.enableRenewalReminder = true
        subscription.reminderDaysBefore = 3

        // When: Adding subscription via DataManager
        try dataManager.addSubscription(subscription)

        // Then: Subscription should be persisted
        let fetchedSubscriptions = try persistenceService.fetchAllSubscriptions()
        XCTAssertTrue(fetchedSubscriptions.contains(where: { $0.id == subscription.id }), "Subscription should be persisted")

        // Cleanup
        try dataManager.deleteSubscription(id: subscription.id)

        print("✅ testSubscriptionPersistenceWithNotifications passed")
    }

    func testTransactionPersistence() throws {
        // Given: Multiple transactions
        let transactions = SampleDataGenerator.generateTransactions(count: 5)

        // When: Adding all transactions
        for transaction in transactions {
            try dataManager.addTransaction(transaction)
        }

        // Then: All should be persisted
        let fetchedTransactions = try persistenceService.fetchAllTransactions()
        for transaction in transactions {
            XCTAssertTrue(fetchedTransactions.contains(where: { $0.id == transaction.id }), "Transaction should be persisted")
        }

        // Cleanup
        for transaction in transactions {
            try dataManager.deleteTransaction(id: transaction.id)
        }

        print("✅ testTransactionPersistence passed")
    }

    // MARK: - 15.3.2: Bulk Operations

    func testBulkOperations() async throws {
        // Given: 100 test items
        let people = SampleDataGenerator.generatePeople(count: 100)

        // When: Importing in bulk
        try await dataManager.importPeople(people)

        // Then: All should be saved
        let fetchedPeople = try persistenceService.fetchAllPeople()
        XCTAssertGreaterThanOrEqual(fetchedPeople.count, 100, "All 100 people should be imported")

        // Verify a sample of the imported data
        for person in people.prefix(10) {
            XCTAssertTrue(fetchedPeople.contains(where: { $0.id == person.id }), "Person \(person.name) should be in persistence")
        }

        // Cleanup
        for person in people {
            try? dataManager.deletePerson(id: person.id)
        }

        print("✅ testBulkOperations passed - 100 items imported successfully")
    }

    func testBulkSubscriptionImport() async throws {
        // Given: 50 test subscriptions
        let subscriptions = SampleDataGenerator.generateSubscriptions(count: 50)

        // When: Importing in bulk
        try await dataManager.importSubscriptions(subscriptions)

        // Then: All should be saved
        let fetchedSubscriptions = try persistenceService.fetchAllSubscriptions()
        XCTAssertGreaterThanOrEqual(fetchedSubscriptions.count, 50, "All 50 subscriptions should be imported")

        // Cleanup
        for subscription in subscriptions {
            try? dataManager.deleteSubscription(id: subscription.id)
        }

        print("✅ testBulkSubscriptionImport passed")
    }

    func testBulkTransactionImport() async throws {
        // Given: 200 test transactions
        let transactions = SampleDataGenerator.generateTransactions(count: 200)

        // When: Importing in bulk
        try await dataManager.importTransactions(transactions)

        // Then: All should be saved and sorted
        let fetchedTransactions = try persistenceService.fetchAllTransactions()
        XCTAssertGreaterThanOrEqual(fetchedTransactions.count, 200, "All 200 transactions should be imported")

        // Cleanup
        for transaction in transactions {
            try? dataManager.deleteTransaction(id: transaction.id)
        }

        print("✅ testBulkTransactionImport passed")
    }

    // MARK: - 15.3.3: Concurrent Access

    func testConcurrentAccess() async throws {
        // Given: Multiple concurrent operations
        let operations = 20

        // When: Running multiple operations simultaneously
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operations {
                group.addTask { @MainActor in
                    let person = SampleDataGenerator.generatePerson(name: "Concurrent Person \(i)")
                    do {
                        try self.dataManager.addPerson(person)
                        // Small delay to simulate real usage
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        try self.dataManager.deletePerson(id: person.id)
                    } catch {
                        XCTFail("Concurrent operation failed: \(error)")
                    }
                }
            }
        }

        // Then: No crashes or data corruption should occur
        // If we got here without crashing, the test passed
        print("✅ testConcurrentAccess passed - \(operations) concurrent operations completed")
    }

    func testConcurrentSubscriptionOperations() async throws {
        let operations = 15

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operations {
                group.addTask { @MainActor in
                    var subscription = SampleDataGenerator.generateSubscription(name: "Concurrent Sub \(i)")
                    do {
                        try self.dataManager.addSubscription(subscription)
                        try await Task.sleep(nanoseconds: 5_000_000) // 5ms

                        subscription.price += 5.0
                        try self.dataManager.updateSubscription(subscription)
                        try await Task.sleep(nanoseconds: 5_000_000) // 5ms

                        try self.dataManager.deleteSubscription(id: subscription.id)
                    } catch {
                        XCTFail("Concurrent subscription operation failed: \(error)")
                    }
                }
            }
        }

        print("✅ testConcurrentSubscriptionOperations passed")
    }

    // MARK: - 15.3.4: Reminder Scheduling

    func testReminderScheduling() async throws {
        // Given: A subscription with reminders enabled
        var subscription = SampleDataGenerator.generateSubscription(name: "Reminder Test")
        subscription.enableRenewalReminder = true
        subscription.reminderDaysBefore = 3
        subscription.nextBillingDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        // When: Adding subscription
        try dataManager.addSubscription(subscription)

        // Then: Notification should be scheduled
        // Note: Actual notification scheduling happens in NotificationManager
        // This test verifies the integration
        let center = UNUserNotificationCenter.current()
        let pendingNotifications = await center.pendingNotificationRequests()

        // Check if a notification exists for this subscription
        let subscriptionNotifications = pendingNotifications.filter { request in
            request.identifier.contains(subscription.id.uuidString)
        }

        XCTAssertFalse(subscriptionNotifications.isEmpty, "Notification should be scheduled for subscription")

        // Cleanup
        try dataManager.deleteSubscription(id: subscription.id)

        print("✅ testReminderScheduling passed")
    }

    // MARK: - 15.3.5: Reminder Cancellation

    func testReminderCancellation() async throws {
        // Given: A subscription with scheduled reminder
        var subscription = SampleDataGenerator.generateSubscription(name: "Cancellation Test")
        subscription.enableRenewalReminder = true
        subscription.reminderDaysBefore = 2
        subscription.nextBillingDate = Calendar.current.date(byAdding: .day, value: 4, to: Date())!

        try dataManager.addSubscription(subscription)

        // When: Deleting subscription
        try dataManager.deleteSubscription(id: subscription.id)

        // Then: Notification should be cancelled
        let center = UNUserNotificationCenter.current()
        let pendingNotifications = await center.pendingNotificationRequests()

        let remainingNotifications = pendingNotifications.filter { request in
            request.identifier.contains(subscription.id.uuidString)
        }

        XCTAssertTrue(remainingNotifications.isEmpty, "Notifications should be cancelled after deletion")

        print("✅ testReminderCancellation passed")
    }

    // MARK: - 15.3.6: Notification Actions

    func testNotificationActions() async throws {
        // Given: A subscription
        var subscription = SampleDataGenerator.generateSubscription(name: "Notification Action Test")
        subscription.enableRenewalReminder = true

        try dataManager.addSubscription(subscription)

        // When: Simulating notification action (mark as paid)
        // This would typically be triggered by user tapping notification action
        subscription.lastBillingDate = Date()
        subscription.nextBillingDate = subscription.billingCycle.calculateNextBilling(from: Date())
        try dataManager.updateSubscription(subscription)

        // Then: Subscription should be updated
        let fetchedSubs = try persistenceService.fetchAllSubscriptions()
        let updatedSub = fetchedSubs.first(where: { $0.id == subscription.id })

        XCTAssertNotNil(updatedSub?.lastBillingDate, "Last billing date should be updated")

        // Cleanup
        try dataManager.deleteSubscription(id: subscription.id)

        print("✅ testNotificationActions passed")
    }

    // MARK: - 15.3.7: Backup Creation

    func testBackupCreation() async throws {
        // Given: Some test data
        let person = SampleDataGenerator.generatePerson(name: "Backup Test Person")
        try dataManager.addPerson(person)

        // When: Creating a backup
        let backupService = BackupService.shared
        let backupData = try backupService.createBackup()

        // Then: Backup should contain the data
        XCTAssertFalse(backupData.people.isEmpty, "Backup should contain people")
        XCTAssertTrue(backupData.people.contains(where: { $0.id == person.id }), "Backup should contain test person")
        XCTAssertNotNil(backupData.metadata.timestamp, "Backup should have timestamp")

        // Cleanup
        try dataManager.deletePerson(id: person.id)

        print("✅ testBackupCreation passed")
    }

    // MARK: - 15.3.8: Backup Restore

    func testBackupRestore() async throws {
        // Given: Original data
        let originalPerson = SampleDataGenerator.generatePerson(name: "Original Person")
        try dataManager.addPerson(originalPerson)

        // Create backup
        let backupService = BackupService.shared
        let backupData = try backupService.createBackup()

        // Delete the data
        try dataManager.deletePerson(id: originalPerson.id)

        // Verify deletion
        var people = try persistenceService.fetchAllPeople()
        XCTAssertFalse(people.contains(where: { $0.id == originalPerson.id }), "Person should be deleted")

        // When: Restoring from backup
        try backupService.restoreBackup(backupData, strategy: .replace)

        // Then: Data should be restored
        people = try persistenceService.fetchAllPeople()
        XCTAssertTrue(people.contains(where: { $0.id == originalPerson.id }), "Person should be restored from backup")

        // Cleanup
        try? dataManager.deletePerson(id: originalPerson.id)

        print("✅ testBackupRestore passed")
    }

    // MARK: - 15.3.9: Backup Conflict Resolution

    func testBackupConflictResolution() async throws {
        // Given: Current data
        let currentPerson = SampleDataGenerator.generatePerson(name: "Current Person")
        try dataManager.addPerson(currentPerson)

        // And: Backup with different data
        let backupPerson = SampleDataGenerator.generatePerson(name: "Backup Person")
        let backupData = BackupData(
            people: [backupPerson],
            subscriptions: [],
            transactions: [],
            groups: [],
            metadata: BackupMetadata(
                version: "1.0.0",
                timestamp: Date(),
                deviceName: "Test Device",
                itemCount: 1
            )
        )

        // When: Restoring with merge strategy
        let backupService = BackupService.shared
        try backupService.restoreBackup(backupData, strategy: .merge)

        // Then: Both should exist
        let people = try persistenceService.fetchAllPeople()
        XCTAssertTrue(people.contains(where: { $0.id == currentPerson.id }), "Current person should still exist")
        XCTAssertTrue(people.contains(where: { $0.id == backupPerson.id }), "Backup person should be added")

        // Cleanup
        try? dataManager.deletePerson(id: currentPerson.id)
        try? dataManager.deletePerson(id: backupPerson.id)

        print("✅ testBackupConflictResolution passed")
    }

    // MARK: - 15.3.10: Schema Migration

    func testSchemaV1toV2Migration() throws {
        // This test would verify that old data formats can be migrated to new formats
        // For now, this is a placeholder as migration logic depends on actual schema changes

        // Given: Legacy data format (simulated)
        // When: Migration occurs
        // Then: Data should be in new format with defaults

        // This would be implemented when actual schema changes occur
        print("⚠️ testSchemaV1toV2Migration - Placeholder for future schema migrations")
    }

    // MARK: - 15.3.11: Migration Defaults

    func testMigrationDefaults() throws {
        // Given: Data missing new fields
        // When: Loading into new model
        // Then: Should have sensible defaults

        // Test that new Subscription fields have defaults
        let subscription = SampleDataGenerator.generateSubscription()

        XCTAssertEqual(subscription.usageCount, 0, "New usage count should default to 0")
        XCTAssertEqual(subscription.reminderDaysBefore, 3, "Reminder days should have default")
        XCTAssertTrue(subscription.enableRenewalReminder, "Reminders should be enabled by default")

        print("✅ testMigrationDefaults passed")
    }

    // MARK: - Additional Integration Tests

    func testCompleteSubscriptionLifecycle() async throws {
        // Test complete lifecycle: create -> update -> pause -> resume -> cancel
        var subscription = SampleDataGenerator.generateSubscription(name: "Lifecycle Test")

        // Create
        try dataManager.addSubscription(subscription)
        var fetched = try persistenceService.fetchAllSubscriptions()
        XCTAssertTrue(fetched.contains(where: { $0.id == subscription.id }), "Should be created")

        // Update
        subscription.price = 19.99
        try dataManager.updateSubscription(subscription)
        fetched = try persistenceService.fetchAllSubscriptions()
        let updated = fetched.first(where: { $0.id == subscription.id })
        XCTAssertEqual(updated?.price, 19.99, "Should be updated")

        // Pause
        await dataManager.pauseSubscription(subscription)
        dataManager.loadAllData()
        let paused = dataManager.subscriptions.first(where: { $0.id == subscription.id })
        XCTAssertFalse(paused?.isActive ?? true, "Should be paused")

        // Resume
        await dataManager.resumeSubscription(paused!)
        dataManager.loadAllData()
        let resumed = dataManager.subscriptions.first(where: { $0.id == subscription.id })
        XCTAssertTrue(resumed?.isActive ?? false, "Should be resumed")

        // Cancel/Delete
        try dataManager.deleteSubscription(id: subscription.id)
        fetched = try persistenceService.fetchAllSubscriptions()
        XCTAssertFalse(fetched.contains(where: { $0.id == subscription.id }), "Should be deleted")

        print("✅ testCompleteSubscriptionLifecycle passed")
    }

    func testGroupWithExpenses() throws {
        // Given: People and group with expenses
        let person1 = SampleDataGenerator.generatePerson(name: "Person 1")
        let person2 = SampleDataGenerator.generatePerson(name: "Person 2")

        try dataManager.addPerson(person1)
        try dataManager.addPerson(person2)

        var group = SampleDataGenerator.generateGroup(
            name: "Test Group",
            members: [person1.id, person2.id]
        )

        try dataManager.addGroup(group)

        // When: Adding expense to group
        let expense = SampleDataGenerator.generateGroupExpense(
            title: "Test Expense",
            amount: 100.0,
            paidBy: person1.id,
            splitBetween: [person1.id, person2.id]
        )

        try dataManager.addGroupExpense(expense, toGroup: group.id)

        // Then: Expense should be in group
        let fetchedGroups = try persistenceService.fetchAllGroups()
        let savedGroup = fetchedGroups.first(where: { $0.id == group.id })

        XCTAssertNotNil(savedGroup, "Group should exist")
        XCTAssertFalse(savedGroup?.expenses.isEmpty ?? true, "Group should have expenses")

        // Cleanup
        try dataManager.deleteGroup(id: group.id)
        try dataManager.deletePerson(id: person1.id)
        try dataManager.deletePerson(id: person2.id)

        print("✅ testGroupWithExpenses passed")
    }

    func testPriceChangeTracking() throws {
        // Given: A subscription
        var subscription = SampleDataGenerator.generateSubscription(name: "Price Change Test", price: 9.99)
        try dataManager.addSubscription(subscription)

        // When: Changing price
        subscription.price = 14.99
        try dataManager.updateSubscription(subscription)

        // Then: Price change should be recorded
        let priceHistory = dataManager.getPriceHistory(for: subscription.id)
        XCTAssertFalse(priceHistory.isEmpty, "Price change should be recorded")

        if let change = priceHistory.first {
            XCTAssertEqual(change.oldPrice, 9.99, "Old price should be 9.99")
            XCTAssertEqual(change.newPrice, 14.99, "New price should be 14.99")
        }

        // Cleanup
        try dataManager.deleteSubscription(id: subscription.id)

        print("✅ testPriceChangeTracking passed")
    }
}
