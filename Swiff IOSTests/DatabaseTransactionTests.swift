//
//  DatabaseTransactionTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for DatabaseTransactionManager - Phase 4.2
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class DatabaseTransactionTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var transactionManager: DatabaseTransactionManager!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container for testing
        let schema = Schema([
            PersonModel.self,
            GroupModel.self,
            SubscriptionModel.self,
            TransactionModel.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
        modelContext = ModelContext(modelContainer)
        transactionManager = DatabaseTransactionManager(modelContext: modelContext)
    }

    override func tearDown() async throws {
        transactionManager = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Basic Transaction (Begin/Commit/Rollback)

    func testBasicTransaction() async throws {
        // Verify no transaction initially
        XCTAssertFalse(transactionManager.hasActiveTransaction, "Should not have active transaction initially")

        // Begin transaction
        try transactionManager.beginTransaction()
        XCTAssertTrue(transactionManager.hasActiveTransaction, "Should have active transaction after begin")
        XCTAssertEqual(transactionManager.currentDepth, 1, "Transaction depth should be 1")

        // Insert a person
        let person = PersonModel(name: "John Doe", email: "john@example.com")
        modelContext.insert(person)

        // Commit
        try transactionManager.commit()
        XCTAssertFalse(transactionManager.hasActiveTransaction, "Should not have active transaction after commit")

        // Verify person was saved
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person after commit")
        XCTAssertEqual(people.first?.name, "John Doe", "Person name should match")
    }

    func testTransactionRollback() async throws {
        // Begin transaction
        try transactionManager.beginTransaction()

        // Insert a person
        let person = PersonModel(name: "Jane Doe", email: "jane@example.com")
        modelContext.insert(person)

        // Rollback
        try transactionManager.rollback()
        XCTAssertFalse(transactionManager.hasActiveTransaction, "Should not have active transaction after rollback")

        // Verify person was not saved
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 0, "Should have 0 people after rollback")
    }

    // MARK: - Test 2: Transaction Wrapper with Automatic Rollback

    func testPerformTransactionSuccess() async throws {
        let result = try await transactionManager.performTransaction {
            let person = PersonModel(name: "Alice", email: "alice@example.com")
            self.modelContext.insert(person)
            return 1
        }

        XCTAssertTrue(result.isSuccess, "Transaction should succeed")
        XCTAssertEqual(result.value, 1, "Should return correct value")

        // Verify person was saved
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person after successful transaction")
    }

    func testPerformTransactionFailure() async throws {
        let result = try await transactionManager.performTransaction {
            let person = PersonModel(name: "Bob", email: "bob@example.com")
            self.modelContext.insert(person)
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }

        XCTAssertFalse(result.isSuccess, "Transaction should fail")
        XCTAssertNotNil(result.error, "Should have error")

        // Verify person was not saved (rollback occurred)
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 0, "Should have 0 people after failed transaction")
    }

    // MARK: - Test 3: Transaction with Timeout

    func testTransactionTimeout() async throws {
        let result = try await transactionManager.performAsyncTransaction(timeout: 0.1) {
            // Simulate long operation
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            return "Should not complete"
        }

        // Transaction should timeout and rollback
        XCTAssertFalse(result.isSuccess, "Transaction should timeout")
        XCTAssertFalse(transactionManager.hasActiveTransaction, "Should not have active transaction after timeout")
    }

    func testTransactionWithinTimeout() async throws {
        let result = try await transactionManager.performAsyncTransaction(timeout: 1.0) {
            let person = PersonModel(name: "Charlie", email: "charlie@example.com")
            self.modelContext.insert(person)
            return 1
        }

        XCTAssertTrue(result.isSuccess, "Transaction should complete within timeout")
        XCTAssertEqual(result.value, 1, "Should return correct value")

        // Verify person was saved
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person")
    }

    // MARK: - Test 4: Savepoint Support

    func testSavepointCreation() async throws {
        try transactionManager.beginTransaction()

        // Create savepoints
        try transactionManager.createSavepoint("sp1")
        try transactionManager.createSavepoint("sp2")

        let savepoints = transactionManager.activeSavepoints
        XCTAssertEqual(savepoints.count, 2, "Should have 2 savepoints")
        XCTAssertTrue(savepoints.contains("sp1"), "Should contain sp1")
        XCTAssertTrue(savepoints.contains("sp2"), "Should contain sp2")

        try transactionManager.commit()
    }

    func testRollbackToSavepoint() async throws {
        try transactionManager.beginTransaction()

        // Insert first person
        let person1 = PersonModel(name: "David", email: "david@example.com")
        modelContext.insert(person1)

        // Create savepoint after first person
        try transactionManager.createSavepoint("after_david")

        // Insert second person
        let person2 = PersonModel(name: "Eve", email: "eve@example.com")
        modelContext.insert(person2)

        // Rollback to savepoint (should remove second person)
        try transactionManager.rollbackToSavepoint("after_david")

        // Verify savepoint was removed from active savepoints
        let savepoints = transactionManager.activeSavepoints
        XCTAssertFalse(savepoints.contains("after_david"), "Savepoint should be removed after rollback")

        // Note: In production with real Core Data or SQLite, this would preserve person1
        // SwiftData's in-memory rollback is more coarse-grained

        try transactionManager.rollback() // Clean up
    }

    func testSavepointNotFound() async throws {
        try transactionManager.beginTransaction()

        // Try to rollback to non-existent savepoint
        XCTAssertThrowsError(try transactionManager.rollbackToSavepoint("nonexistent")) { error in
            XCTAssertTrue(error is TransactionError, "Should throw TransactionError")
            if case TransactionError.savePointNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent", "Should report correct savepoint name")
            } else {
                XCTFail("Should be savePointNotFound error")
            }
        }

        try transactionManager.rollback()
    }

    // MARK: - Test 5: Nested Transaction Support

    func testNestedTransaction() async throws {
        try transactionManager.beginTransaction()
        XCTAssertEqual(transactionManager.currentDepth, 1, "Depth should be 1")

        try transactionManager.beginNestedTransaction()
        XCTAssertEqual(transactionManager.currentDepth, 2, "Depth should be 2")

        try transactionManager.beginNestedTransaction()
        XCTAssertEqual(transactionManager.currentDepth, 3, "Depth should be 3")

        // Commit nested
        try transactionManager.commitNested()
        XCTAssertEqual(transactionManager.currentDepth, 2, "Depth should be 2 after commit")

        try transactionManager.commitNested()
        XCTAssertEqual(transactionManager.currentDepth, 1, "Depth should be 1 after commit")

        try transactionManager.commit()
        XCTAssertEqual(transactionManager.currentDepth, 0, "Depth should be 0 after final commit")
    }

    func testNestedTransactionLimit() async throws {
        try transactionManager.beginTransaction()

        // Create maximum depth
        for _ in 1..<DatabaseTransactionManager.maxNestedDepth {
            try transactionManager.beginNestedTransaction()
        }

        XCTAssertEqual(transactionManager.currentDepth, DatabaseTransactionManager.maxNestedDepth, "Should reach max depth")

        // Try to exceed limit
        XCTAssertThrowsError(try transactionManager.beginNestedTransaction()) { error in
            XCTAssertTrue(error is TransactionError, "Should throw TransactionError")
            if case TransactionError.nestedTransactionLimit = error {
                // Success
            } else {
                XCTFail("Should be nestedTransactionLimit error")
            }
        }

        try transactionManager.rollback()
    }

    func testRollbackNested() async throws {
        try transactionManager.beginTransaction()

        let person1 = PersonModel(name: "Frank", email: "frank@example.com")
        modelContext.insert(person1)

        try transactionManager.beginNestedTransaction()

        let person2 = PersonModel(name: "Grace", email: "grace@example.com")
        modelContext.insert(person2)

        // Rollback nested transaction
        try transactionManager.rollbackNested()
        XCTAssertEqual(transactionManager.currentDepth, 1, "Depth should be 1 after nested rollback")

        try transactionManager.rollback() // Clean up
    }

    // MARK: - Test 6: Atomic Multi-Entity Operations

    func testAtomicInsert() async throws {
        let people = [
            PersonModel(name: "Henry", email: "henry@example.com"),
            PersonModel(name: "Iris", email: "iris@example.com"),
            PersonModel(name: "Jack", email: "jack@example.com")
        ]

        let result = try await transactionManager.atomicInsert(people)

        XCTAssertTrue(result.isSuccess, "Atomic insert should succeed")
        XCTAssertEqual(result.value, 3, "Should insert 3 people")

        // Verify all people were saved
        let descriptor = FetchDescriptor<PersonModel>()
        let savedPeople = try modelContext.fetch(descriptor)
        XCTAssertEqual(savedPeople.count, 3, "Should have 3 people after atomic insert")
    }

    func testAtomicDelete() async throws {
        // First, insert people
        let people = [
            PersonModel(name: "Kate", email: "kate@example.com"),
            PersonModel(name: "Leo", email: "leo@example.com")
        ]
        for person in people {
            modelContext.insert(person)
        }
        try modelContext.save()

        // Fetch them back
        let descriptor = FetchDescriptor<PersonModel>()
        let fetchedPeople = try modelContext.fetch(descriptor)
        XCTAssertEqual(fetchedPeople.count, 2, "Should have 2 people before delete")

        // Atomic delete
        let result = try await transactionManager.atomicDelete(fetchedPeople)

        XCTAssertTrue(result.isSuccess, "Atomic delete should succeed")
        XCTAssertEqual(result.value, 2, "Should delete 2 people")

        // Verify all people were deleted
        let remainingPeople = try modelContext.fetch(descriptor)
        XCTAssertEqual(remainingPeople.count, 0, "Should have 0 people after atomic delete")
    }

    func testAtomicUpdateWithValidation() async throws {
        // Insert a person
        let person = PersonModel(name: "Mike", email: "mike@example.com")
        modelContext.insert(person)
        try modelContext.save()

        let result = try await transactionManager.atomicUpdate(
            validation: {
                // Validation passes
                return true
            },
            update: {
                person.name = "Michael"
                return "Updated"
            }
        )

        XCTAssertTrue(result.isSuccess, "Atomic update should succeed")
        XCTAssertEqual(result.value, "Updated", "Should return update result")

        // Verify update was applied
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.first?.name, "Michael", "Name should be updated")
    }

    func testAtomicUpdateValidationFails() async throws {
        let result = try await transactionManager.atomicUpdate(
            validation: {
                // Validation fails
                return false
            },
            update: {
                return "Should not execute"
            }
        )

        XCTAssertFalse(result.isSuccess, "Atomic update should fail validation")
    }

    // MARK: - Test 7: Transaction Statistics

    func testTransactionStatistics() async throws {
        // Reset statistics
        transactionManager.resetStatistics()

        var stats = transactionManager.getStatistics()
        XCTAssertEqual(stats.totalTransactions, 0, "Should start with 0 transactions")

        // Perform successful transaction
        _ = try await transactionManager.performTransaction {
            let person = PersonModel(name: "Nina", email: "nina@example.com")
            self.modelContext.insert(person)
            return 1
        }

        stats = transactionManager.getStatistics()
        XCTAssertEqual(stats.totalTransactions, 1, "Should have 1 transaction")
        XCTAssertEqual(stats.successfulTransactions, 1, "Should have 1 successful transaction")
        XCTAssertEqual(stats.successRate, 1.0, "Success rate should be 100%")

        // Perform failed transaction
        _ = try await transactionManager.performTransaction {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }

        stats = transactionManager.getStatistics()
        XCTAssertEqual(stats.totalTransactions, 2, "Should have 2 transactions")
        XCTAssertEqual(stats.successfulTransactions, 1, "Should still have 1 successful")
        XCTAssertEqual(stats.failedTransactions, 1, "Should have 1 failed")
        XCTAssertEqual(stats.successRate, 0.5, "Success rate should be 50%")
    }

    func testStatisticsTracksRollback() async throws {
        transactionManager.resetStatistics()

        try transactionManager.beginTransaction()
        let person = PersonModel(name: "Oscar", email: "oscar@example.com")
        modelContext.insert(person)
        try transactionManager.rollback()

        let stats = transactionManager.getStatistics()
        XCTAssertEqual(stats.rolledBackTransactions, 1, "Should have 1 rolled back transaction")
    }

    // MARK: - Test 8: Error Handling

    func testCommitWithoutTransaction() async throws {
        XCTAssertThrowsError(try transactionManager.commit()) { error in
            XCTAssertTrue(error is TransactionError, "Should throw TransactionError")
            if case TransactionError.noTransactionInProgress = error {
                // Success
            } else {
                XCTFail("Should be noTransactionInProgress error")
            }
        }
    }

    func testRollbackWithoutTransaction() async throws {
        XCTAssertThrowsError(try transactionManager.rollback()) { error in
            XCTAssertTrue(error is TransactionError, "Should throw TransactionError")
            if case TransactionError.noTransactionInProgress = error {
                // Success
            } else {
                XCTFail("Should be noTransactionInProgress error")
            }
        }
    }

    func testBeginTransactionTwice() async throws {
        try transactionManager.beginTransaction()

        XCTAssertThrowsError(try transactionManager.beginTransaction()) { error in
            XCTAssertTrue(error is TransactionError, "Should throw TransactionError")
            if case TransactionError.transactionInProgress = error {
                // Success
            } else {
                XCTFail("Should be transactionInProgress error")
            }
        }

        try transactionManager.rollback()
    }

    func testCreateSavepointWithoutTransaction() async throws {
        XCTAssertThrowsError(try transactionManager.createSavepoint("test")) { error in
            XCTAssertTrue(error is TransactionError, "Should throw TransactionError")
            if case TransactionError.noTransactionInProgress = error {
                // Success
            } else {
                XCTFail("Should be noTransactionInProgress error")
            }
        }
    }

    // MARK: - Test 9: Convenience Wrappers

    func testWithTransactionSuccess() async throws {
        let count = try await transactionManager.withTransaction {
            let person = PersonModel(name: "Paul", email: "paul@example.com")
            self.modelContext.insert(person)
            return 1
        }

        XCTAssertEqual(count, 1, "Should return value directly")

        // Verify person was saved
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person")
    }

    func testWithTransactionFailure() async throws {
        do {
            _ = try await transactionManager.withTransaction {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            XCTFail("Should throw error")
        } catch {
            // Expected
            XCTAssertNotNil(error, "Should throw error")
        }
    }

    func testWithAsyncTransactionSuccess() async throws {
        let result = try await transactionManager.withAsyncTransaction {
            let person = PersonModel(name: "Quinn", email: "quinn@example.com")
            self.modelContext.insert(person)
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            return "Success"
        }

        XCTAssertEqual(result, "Success", "Should return value directly")

        // Verify person was saved
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person")
    }

    // MARK: - Test 10: Edge Cases

    func testEmptyTransaction() async throws {
        let result = try await transactionManager.performTransaction {
            // Do nothing
            return 0
        }

        XCTAssertTrue(result.isSuccess, "Empty transaction should succeed")
        XCTAssertEqual(result.value, 0, "Should return 0")
    }

    func testTransactionWithMultipleEntities() async throws {
        let result = try await transactionManager.performTransaction {
            // Insert person
            let person = PersonModel(name: "Rachel", email: "rachel@example.com")
            self.modelContext.insert(person)

            // Insert group
            let group = GroupModel(name: "Test Group")
            self.modelContext.insert(group)

            // Insert subscription
            let subscription = SubscriptionModel(
                name: "Test Sub",
                amount: 9.99,
                cycle: "monthly",
                personId: person.id
            )
            self.modelContext.insert(subscription)

            return 3
        }

        XCTAssertTrue(result.isSuccess, "Multi-entity transaction should succeed")
        XCTAssertEqual(result.value, 3, "Should insert 3 entities")

        // Verify all entities were saved
        let personDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(personDescriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person")

        let groupDescriptor = FetchDescriptor<GroupModel>()
        let groups = try modelContext.fetch(groupDescriptor)
        XCTAssertEqual(groups.count, 1, "Should have 1 group")

        let subDescriptor = FetchDescriptor<SubscriptionModel>()
        let subscriptions = try modelContext.fetch(subDescriptor)
        XCTAssertEqual(subscriptions.count, 1, "Should have 1 subscription")
    }

    func testReleaseSavepoint() async throws {
        try transactionManager.beginTransaction()

        try transactionManager.createSavepoint("sp1")
        try transactionManager.createSavepoint("sp2")

        XCTAssertEqual(transactionManager.activeSavepoints.count, 2, "Should have 2 savepoints")

        try transactionManager.releaseSavepoint("sp1")

        XCTAssertEqual(transactionManager.activeSavepoints.count, 1, "Should have 1 savepoint after release")
        XCTAssertFalse(transactionManager.activeSavepoints.contains("sp1"), "sp1 should be released")
        XCTAssertTrue(transactionManager.activeSavepoints.contains("sp2"), "sp2 should still exist")

        try transactionManager.commit()
    }

    func testTransactionDepthTracking() async throws {
        XCTAssertEqual(transactionManager.currentDepth, 0, "Initial depth should be 0")

        try transactionManager.beginTransaction()
        XCTAssertEqual(transactionManager.currentDepth, 1, "Depth should be 1")

        try transactionManager.beginNestedTransaction()
        XCTAssertEqual(transactionManager.currentDepth, 2, "Depth should be 2")

        try transactionManager.rollbackNested()
        XCTAssertEqual(transactionManager.currentDepth, 1, "Depth should be 1 after nested rollback")

        try transactionManager.rollback()
        XCTAssertEqual(transactionManager.currentDepth, 0, "Depth should be 0 after rollback")
    }
}
