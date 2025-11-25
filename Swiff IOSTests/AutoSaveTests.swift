//
//  AutoSaveTests.swift
//  Swiff IOSTests
//
//  Created by Naren Reddy on 11/18/25.
//  Tests for auto-save functionality including debouncing, bulk operations, and crash recovery
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class AutoSaveTests: XCTestCase {
    var dataManager: DataManager!
    var persistenceService: PersistenceService!

    override func setUp() async throws {
        try await super.setUp()
        persistenceService = PersistenceService.shared
        dataManager = DataManager()
    }

    override func tearDown() async throws {
        dataManager = nil
        try await super.tearDown()
    }

    // MARK: - Immediate Save Tests

    func testImmediateSaveForPerson() async throws {
        // Given: A new person
        let person = Person(
            name: "Test Person",
            email: "test@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )

        // When: Adding the person
        try dataManager.addPerson(person)

        // Then: Person should be saved immediately
        let fetchedPerson = try persistenceService.fetchPerson(byID: person.id)
        XCTAssertNotNil(fetchedPerson, "Person should be saved immediately")
        XCTAssertEqual(fetchedPerson?.name, "Test Person")
    }

    func testImmediateSaveForSubscription() async throws {
        // Given: A new subscription
        var subscription = Subscription(
            name: "Test Subscription",
            description: "Test",
            price: 9.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#FF0000"
        )
        subscription.isActive = true

        // When: Adding the subscription
        try dataManager.addSubscription(subscription)

        // Then: Subscription should be saved immediately
        let fetchedSubscription = try persistenceService.fetchSubscription(byID: subscription.id)
        XCTAssertNotNil(fetchedSubscription, "Subscription should be saved immediately")
        XCTAssertEqual(fetchedSubscription?.name, "Test Subscription")
    }

    func testImmediateSaveForTransaction() async throws {
        // Given: A new transaction
        let transaction = Transaction(
            id: UUID(),
            title: "Test Transaction",
            subtitle: "Test",
            amount: -50.00,
            category: .dining,
            date: Date(),
            isRecurring: false,
            tags: ["test"]
        )

        // When: Adding the transaction
        try dataManager.addTransaction(transaction)

        // Then: Transaction should be saved immediately
        let fetchedTransaction = try persistenceService.fetchTransaction(byID: transaction.id)
        XCTAssertNotNil(fetchedTransaction, "Transaction should be saved immediately")
        XCTAssertEqual(fetchedTransaction?.title, "Test Transaction")
    }

    // MARK: - Debounced Save Tests

    func testDebouncedSaveForPersonUpdates() async throws {
        // Given: A person that's already saved
        let person = Person(
            name: "Original Name",
            email: "test@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // When: Rapidly updating the person (simulating text field editing)
        var updatedPerson = person
        updatedPerson.name = "Name 1"
        dataManager.scheduleSave(for: updatedPerson, delay: 0.1)

        updatedPerson.name = "Name 2"
        dataManager.scheduleSave(for: updatedPerson, delay: 0.1)

        updatedPerson.name = "Final Name"
        dataManager.scheduleSave(for: updatedPerson, delay: 0.1)

        // Then: Wait for debounce delay plus a bit more
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Verify only the final update was saved
        let fetchedPerson = try persistenceService.fetchPerson(byID: person.id)
        XCTAssertEqual(fetchedPerson?.name, "Final Name", "Should save only the final debounced value")
    }

    func testDebouncedSaveHandlesErrors() async throws {
        // Given: A person with invalid data that will fail validation
        let person = Person(
            name: "",  // Empty name should fail validation
            email: "invalid",
            phone: "",
            avatarType: .emoji("👤")
        )

        // When: Scheduling save
        dataManager.scheduleSave(for: person, delay: 0.1)

        // Wait for debounce
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Error should be set in dataManager
        XCTAssertNotNil(dataManager.error, "Error should be captured when save fails")
    }

    // MARK: - Bulk Import Tests

    func testBulkImportPeopleWithProgress() async throws {
        // Given: Multiple people to import
        let people = (1...10).map { i in
            Person(
                name: "Person \(i)",
                email: "person\(i)@example.com",
                phone: "+123456789\(i)",
                avatarType: .emoji("👤")
            )
        }

        // When: Importing in bulk
        let importTask = Task {
            try await dataManager.importPeople(people)
        }

        // Then: Progress should be tracked
        try await Task.sleep(nanoseconds: 50_000_000) // Wait a bit for progress to update
        XCTAssertTrue(dataManager.isPerformingOperation, "Should be performing operation")
        XCTAssertNotNil(dataManager.operationProgress, "Progress should be tracked")

        // Wait for completion
        try await importTask.value

        // Verify all people were imported
        XCTAssertEqual(dataManager.people.count, 10, "All people should be imported")
        XCTAssertFalse(dataManager.isPerformingOperation, "Operation should be complete")
        XCTAssertNil(dataManager.operationProgress, "Progress should be cleared")
    }

    func testBulkImportSubscriptions() async throws {
        // Given: Multiple subscriptions
        let subscriptions = (1...5).map { i in
            var sub = Subscription(
                name: "Subscription \(i)",
                description: "Test",
                price: Double(i) * 9.99,
                billingCycle: .monthly,
                category: .entertainment,
                icon: "tv.fill",
                color: "#FF0000"
            )
            sub.isActive = true
            return sub
        }

        // When: Importing in bulk
        try await dataManager.importSubscriptions(subscriptions)

        // Then: All subscriptions should be saved
        XCTAssertEqual(dataManager.subscriptions.count, 5)

        // Verify they're persisted
        for subscription in subscriptions {
            let fetched = try persistenceService.fetchSubscription(byID: subscription.id)
            XCTAssertNotNil(fetched)
        }
    }

    func testBulkImportTransactions() async throws {
        // Given: Multiple transactions
        let transactions = (1...20).map { i in
            Transaction(
                id: UUID(),
                title: "Transaction \(i)",
                subtitle: "Test",
                amount: Double(i) * -10.0,
                category: .dining,
                date: Date(),
                isRecurring: false,
                tags: ["test"]
            )
        }

        // When: Importing in bulk
        try await dataManager.importTransactions(transactions)

        // Then: All transactions should be saved and sorted
        XCTAssertEqual(dataManager.transactions.count, 20)

        // Verify sorting (newest first)
        for i in 0..<(dataManager.transactions.count - 1) {
            XCTAssertTrue(
                dataManager.transactions[i].date >= dataManager.transactions[i + 1].date,
                "Transactions should be sorted by date descending"
            )
        }
    }

    // MARK: - Crash Recovery Tests

    func testDataPersistsAfterAppRestart() async throws {
        // Given: Some data is saved
        let person = Person(
            name: "Persistent Person",
            email: "persist@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // When: Simulating app restart by creating a new DataManager
        let newDataManager = DataManager()
        newDataManager.loadAllData()

        // Then: Data should be loaded
        XCTAssertTrue(newDataManager.people.contains { $0.id == person.id },
                     "Data should persist across app restarts")
    }

    func testConcurrentSavesDoNotCorruptData() async throws {
        // Given: Multiple concurrent save operations
        let people = (1...5).map { i in
            Person(
                name: "Concurrent Person \(i)",
                email: "concurrent\(i)@example.com",
                phone: "+123456789\(i)",
                avatarType: .emoji("👤")
            )
        }

        // When: Saving concurrently
        await withTaskGroup(of: Void.self) { group in
            for person in people {
                group.addTask {
                    try? self.dataManager.addPerson(person)
                }
            }
        }

        // Then: All people should be saved without corruption
        XCTAssertEqual(dataManager.people.count, 5, "All concurrent saves should succeed")

        // Verify each person is correctly saved
        for person in people {
            let fetched = try persistenceService.fetchPerson(byID: person.id)
            XCTAssertNotNil(fetched)
            XCTAssertEqual(fetched?.name, person.name)
        }
    }

    // MARK: - Error Handling Tests

    func testErrorIsPublishedOnSaveFailure() async throws {
        // Given: DataManager with no errors
        XCTAssertNil(dataManager.error)

        // When: An invalid person fails to save (using debounced save)
        let invalidPerson = Person(
            name: "", // Empty name should fail
            email: "invalid",
            phone: "",
            avatarType: .emoji("👤")
        )

        dataManager.scheduleSave(for: invalidPerson, delay: 0.1)

        // Wait for debounce
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Error should be published
        XCTAssertNotNil(dataManager.error, "Error should be published when save fails")
    }

    // MARK: - Progress Tracking Tests

    func testProgressTrackingForLargeImport() async throws {
        // Given: A large dataset
        let largeDataset = (1...100).map { i in
            Person(
                name: "Person \(i)",
                email: "person\(i)@example.com",
                phone: "+123456789\(i)",
                avatarType: .emoji("👤")
            )
        }

        // When: Importing
        var progressValues: [Double] = []
        let importTask = Task {
            try await dataManager.importPeople(largeDataset)
        }

        // Track progress during import
        for _ in 0..<10 {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            if let progress = dataManager.operationProgress {
                progressValues.append(progress)
            }
        }

        try await importTask.value

        // Then: Progress should increase monotonically
        XCTAssertTrue(progressValues.count > 0, "Progress should be tracked")
        for i in 0..<(progressValues.count - 1) {
            XCTAssertTrue(progressValues[i] <= progressValues[i + 1],
                         "Progress should increase monotonically")
        }
    }

    // MARK: - Integration Tests

    func testFullWorkflow() async throws {
        // This test simulates a complete user workflow

        // 1. Add a person
        let person = Person(
            name: "Workflow Person",
            email: "workflow@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // 2. Add a subscription
        var subscription = Subscription(
            name: "Workflow Subscription",
            description: "Test",
            price: 9.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#FF0000"
        )
        subscription.isActive = true
        try dataManager.addSubscription(subscription)

        // 3. Add a transaction
        let transaction = Transaction(
            id: UUID(),
            title: "Workflow Transaction",
            subtitle: "Test",
            amount: -50.00,
            category: .dining,
            date: Date(),
            isRecurring: false,
            tags: ["test"]
        )
        try dataManager.addTransaction(transaction)

        // 4. Update person with debounced save
        var updatedPerson = person
        updatedPerson.name = "Updated Workflow Person"
        dataManager.scheduleSave(for: updatedPerson, delay: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)

        // 5. Verify everything persisted
        let newDataManager = DataManager()
        newDataManager.loadAllData()

        XCTAssertTrue(newDataManager.people.contains { $0.id == person.id })
        XCTAssertTrue(newDataManager.subscriptions.contains { $0.id == subscription.id })
        XCTAssertTrue(newDataManager.transactions.contains { $0.id == transaction.id })

        // Verify the update persisted
        let fetchedPerson = newDataManager.people.first { $0.id == person.id }
        XCTAssertEqual(fetchedPerson?.name, "Updated Workflow Person")
    }
}
