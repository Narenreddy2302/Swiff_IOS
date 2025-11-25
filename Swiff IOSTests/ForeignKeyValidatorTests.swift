//
//  ForeignKeyValidatorTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 4.1: Foreign key validation
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class ForeignKeyValidatorTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var validator: ForeignKeyValidator!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([
            PersonModel.self,
            GroupModel.self,
            SubscriptionModel.self,
            TransactionModel.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
        modelContext = ModelContext(modelContainer)

        validator = ForeignKeyValidator(modelContext: modelContext)

        print("🧪 Test setup complete - In-memory database created")
    }

    override func tearDown() async throws {
        // Clean up
        modelContext = nil
        modelContainer = nil
        validator = nil

        try await super.tearDown()
    }

    // MARK: - Test 4.1.1: Person Existence Validation

    func testPersonExistenceValidation() async throws {
        print("🧪 Test 4.1.1: Testing person existence validation")

        // Create a person
        let person = PersonModel(
            name: "John Doe",
            email: "john@example.com",
            phone: "555-1234",
            avatarType: .initials("JD")
        )
        modelContext.insert(person)
        try modelContext.save()

        // Valid person ID
        do {
            try validator.validatePersonExists(person.id)
            print("   ✓ Valid person ID accepted")
        } catch {
            XCTFail("Valid person should exist: \(error)")
        }

        // Invalid person ID
        let invalidId = UUID()
        do {
            try validator.validatePersonExists(invalidId)
            XCTFail("Invalid person ID should throw error")
        } catch ForeignKeyError.personNotFound {
            print("   ✓ Invalid person ID rejected")
        }

        // Get person
        do {
            let fetchedPerson = try validator.getPerson(person.id)
            XCTAssertEqual(fetchedPerson.id, person.id, "Should fetch correct person")
            print("   ✓ Person fetched successfully")
        } catch {
            XCTFail("Should fetch person: \(error)")
        }

        print("✅ Test 4.1.1: Person existence validation verified")
        print("   Result: PASS - Person validation working correctly")
    }

    // MARK: - Test 4.1.2: Multiple Person Validation

    func testMultiplePersonValidation() async throws {
        print("🧪 Test 4.1.2: Testing multiple person validation")

        // Create multiple people
        let person1 = PersonModel(
            name: "Alice",
            email: "alice@example.com",
            phone: "555-0001",
            avatarType: .initials("A")
        )
        let person2 = PersonModel(
            name: "Bob",
            email: "bob@example.com",
            phone: "555-0002",
            avatarType: .initials("B")
        )

        modelContext.insert(person1)
        modelContext.insert(person2)
        try modelContext.save()

        // Validate all exist
        do {
            try validator.validatePersonsExist([person1.id, person2.id])
            print("   ✓ Multiple valid person IDs accepted")
        } catch {
            XCTFail("All people should exist: \(error)")
        }

        // One invalid ID
        let invalidId = UUID()
        do {
            try validator.validatePersonsExist([person1.id, invalidId])
            XCTFail("Should fail with one invalid ID")
        } catch ForeignKeyError.personNotFound {
            print("   ✓ Invalid ID in batch detected")
        }

        print("✅ Test 4.1.2: Multiple person validation verified")
        print("   Result: PASS - Batch validation working correctly")
    }

    // MARK: - Test 4.1.3: Reference Counting

    func testReferenceCounting() async throws {
        print("🧪 Test 4.1.3: Testing reference counting")

        // Create a person
        let person = PersonModel(
            name: "Charlie",
            email: "charlie@example.com",
            phone: "555-0003",
            avatarType: .initials("C")
        )
        modelContext.insert(person)

        // Initially no references
        var count = try validator.countReferences(forPerson: person.id)
        XCTAssertEqual(count, 0, "New person should have no references")
        print("   ✓ New person: 0 references")

        // Create a subscription
        let subscription = SubscriptionModel(
            personId: person.id,
            name: "Netflix",
            amount: 15.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )
        modelContext.insert(subscription)
        try modelContext.save()

        count = try validator.countReferences(forPerson: person.id)
        XCTAssertEqual(count, 1, "Should have 1 reference")
        print("   ✓ After adding subscription: 1 reference")

        // Create another person for transaction
        let person2 = PersonModel(
            name: "David",
            email: "david@example.com",
            phone: "555-0004",
            avatarType: .initials("D")
        )
        modelContext.insert(person2)

        // Create a transaction
        let transaction = TransactionModel(
            payerId: person.id,
            payeeId: person2.id,
            amount: 50.00,
            description: "Test payment",
            date: Date()
        )
        modelContext.insert(transaction)
        try modelContext.save()

        count = try validator.countReferences(forPerson: person.id)
        XCTAssertEqual(count, 2, "Should have 2 references")
        print("   ✓ After adding transaction: 2 references")

        print("✅ Test 4.1.3: Reference counting verified")
        print("   Result: PASS - Reference counting accurate")
    }

    // MARK: - Test 4.1.4: Orphan Detection

    func testOrphanDetection() async throws {
        print("🧪 Test 4.1.4: Testing orphan detection")

        // Create a person
        let person = PersonModel(
            name: "Eve",
            email: "eve@example.com",
            phone: "555-0005",
            avatarType: .initials("E")
        )
        modelContext.insert(person)

        // Create a subscription
        let subscription = SubscriptionModel(
            personId: person.id,
            name: "Spotify",
            amount: 9.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )
        modelContext.insert(subscription)
        try modelContext.save()

        // Initially no orphans
        var result = try validator.detectOrphanedSubscriptions()
        XCTAssertFalse(result.hasOrphans, "Should have no orphans initially")
        print("   ✓ Initially: 0 orphans")

        // Delete person directly (bypassing validator - simulating corruption)
        modelContext.delete(person)
        try modelContext.save()

        // Now should detect orphan
        result = try validator.detectOrphanedSubscriptions()
        XCTAssertTrue(result.hasOrphans, "Should detect orphan")
        XCTAssertEqual(result.totalOrphans, 1, "Should have 1 orphan")
        print("   ✓ After deleting person: 1 orphan detected")
        print("   ✓ \(result.summary)")

        print("✅ Test 4.1.4: Orphan detection verified")
        print("   Result: PASS - Orphan detection working correctly")
    }

    // MARK: - Test 4.1.5: Cascade Delete with Restrict Rule

    func testCascadeDeleteRestrict() async throws {
        print("🧪 Test 4.1.5: Testing cascade delete with restrict rule")

        // Create a person
        let person = PersonModel(
            name: "Frank",
            email: "frank@example.com",
            phone: "555-0006",
            avatarType: .initials("F")
        )
        modelContext.insert(person)

        // Create a subscription
        let subscription = SubscriptionModel(
            personId: person.id,
            name: "Apple Music",
            amount: 10.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )
        modelContext.insert(subscription)
        try modelContext.save()

        // Try to delete with restrict rule (should fail)
        do {
            try validator.deletePerson(person.id, cascadeRule: .restrict)
            XCTFail("Should not allow delete with references")
        } catch ForeignKeyError.multipleReferencesExist(let entityType, let count) {
            XCTAssertEqual(count, 1, "Should report 1 reference")
            print("   ✓ Delete prevented: \(count) \(entityType) reference(s) exist")
        }

        // Verify person still exists
        do {
            _ = try validator.getPerson(person.id)
            print("   ✓ Person still exists after failed delete")
        } catch {
            XCTFail("Person should still exist")
        }

        print("✅ Test 4.1.5: Cascade delete with restrict verified")
        print("   Result: PASS - Restrict rule prevents deletion correctly")
    }

    // MARK: - Test 4.1.6: Cascade Delete with Cascade Rule

    func testCascadeDeleteCascade() async throws {
        print("🧪 Test 4.1.6: Testing cascade delete with cascade rule")

        // Create a person
        let person = PersonModel(
            name: "Grace",
            email: "grace@example.com",
            phone: "555-0007",
            avatarType: .initials("G")
        )
        modelContext.insert(person)

        // Create subscriptions
        let subscription1 = SubscriptionModel(
            personId: person.id,
            name: "Netflix",
            amount: 15.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )
        let subscription2 = SubscriptionModel(
            personId: person.id,
            name: "Hulu",
            amount: 7.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )

        modelContext.insert(subscription1)
        modelContext.insert(subscription2)
        try modelContext.save()

        // Verify references exist
        var count = try validator.countReferences(forPerson: person.id)
        XCTAssertEqual(count, 2, "Should have 2 references before delete")
        print("   ✓ Before delete: 2 references")

        // Delete with cascade rule
        do {
            try validator.deletePerson(person.id, cascadeRule: .cascade)
            print("   ✓ Person and dependent records deleted")
        } catch {
            XCTFail("Cascade delete should succeed: \(error)")
        }

        // Verify person is deleted
        do {
            _ = try validator.getPerson(person.id)
            XCTFail("Person should be deleted")
        } catch ForeignKeyError.personNotFound {
            print("   ✓ Person successfully deleted")
        }

        // Verify subscriptions are deleted
        let subscriptionDescriptor = FetchDescriptor<SubscriptionModel>()
        let remainingSubscriptions = try modelContext.fetch(subscriptionDescriptor)
        XCTAssertEqual(remainingSubscriptions.count, 0, "All subscriptions should be deleted")
        print("   ✓ All dependent subscriptions deleted")

        print("✅ Test 4.1.6: Cascade delete with cascade rule verified")
        print("   Result: PASS - Cascade rule deletes dependents correctly")
    }

    // MARK: - Test 4.1.7: Orphan Cleanup

    func testOrphanCleanup() async throws {
        print("🧪 Test 4.1.7: Testing orphan cleanup")

        // Create person and subscription
        let person = PersonModel(
            name: "Henry",
            email: "henry@example.com",
            phone: "555-0008",
            avatarType: .initials("H")
        )
        modelContext.insert(person)

        let subscription = SubscriptionModel(
            personId: person.id,
            name: "Disney+",
            amount: 7.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )
        modelContext.insert(subscription)
        try modelContext.save()

        // Delete person directly (creating orphan)
        modelContext.delete(person)
        try modelContext.save()

        // Detect orphan
        var result = try validator.detectOrphanedSubscriptions()
        XCTAssertEqual(result.totalOrphans, 1, "Should have 1 orphan")
        print("   ✓ Orphan detected: \(result.summary)")

        // Clean up orphans
        let cleanedCount = try validator.cleanupOrphanedSubscriptions()
        XCTAssertEqual(cleanedCount, 1, "Should clean up 1 orphan")
        print("   ✓ Cleaned up \(cleanedCount) orphan(s)")

        // Verify no orphans remain
        result = try validator.detectOrphanedSubscriptions()
        XCTAssertFalse(result.hasOrphans, "Should have no orphans after cleanup")
        print("   ✓ No orphans remaining")

        print("✅ Test 4.1.7: Orphan cleanup verified")
        print("   Result: PASS - Orphan cleanup working correctly")
    }

    // MARK: - Test 4.1.8: Transaction Validation

    func testTransactionValidation() async throws {
        print("🧪 Test 4.1.8: Testing transaction foreign key validation")

        // Create two people
        let person1 = PersonModel(
            name: "Ivy",
            email: "ivy@example.com",
            phone: "555-0009",
            avatarType: .initials("I")
        )
        let person2 = PersonModel(
            name: "Jack",
            email: "jack@example.com",
            phone: "555-0010",
            avatarType: .initials("J")
        )

        modelContext.insert(person1)
        modelContext.insert(person2)
        try modelContext.save()

        // Validate valid transaction
        do {
            try validator.validateTransactionCreation(
                payerId: person1.id,
                payeeId: person2.id
            )
            print("   ✓ Valid transaction participants accepted")
        } catch {
            XCTFail("Valid transaction should pass: \(error)")
        }

        // Invalid payer
        let invalidId = UUID()
        do {
            try validator.validateTransactionCreation(
                payerId: invalidId,
                payeeId: person2.id
            )
            XCTFail("Should reject invalid payer")
        } catch ForeignKeyError.personNotFound {
            print("   ✓ Invalid payer rejected")
        }

        // Invalid payee
        do {
            try validator.validateTransactionCreation(
                payerId: person1.id,
                payeeId: invalidId
            )
            XCTFail("Should reject invalid payee")
        } catch ForeignKeyError.personNotFound {
            print("   ✓ Invalid payee rejected")
        }

        print("✅ Test 4.1.8: Transaction validation verified")
        print("   Result: PASS - Transaction validation working correctly")
    }

    // MARK: - Test 4.1.9: Comprehensive Validation

    func testComprehensiveValidation() async throws {
        print("🧪 Test 4.1.9: Testing comprehensive foreign key validation")

        // Create clean database
        let errors1 = try validator.validateAllForeignKeys()
        XCTAssertTrue(errors1.isEmpty, "Clean database should have no errors")
        print("   ✓ Clean database: \(errors1.isEmpty ? "No errors" : errors1.joined(separator: ", "))")

        // Create person and orphaned subscription
        let person = PersonModel(
            name: "Kate",
            email: "kate@example.com",
            phone: "555-0011",
            avatarType: .initials("K")
        )
        modelContext.insert(person)

        let subscription = SubscriptionModel(
            personId: person.id,
            name: "HBO Max",
            amount: 14.99,
            billingCycle: "Monthly",
            startDate: Date(),
            isActive: true
        )
        modelContext.insert(subscription)
        try modelContext.save()

        // Delete person (creating orphan)
        modelContext.delete(person)
        try modelContext.save()

        // Validate should detect error
        let errors2 = try validator.validateAllForeignKeys()
        XCTAssertFalse(errors2.isEmpty, "Should detect orphaned records")
        print("   ✓ Orphans detected: \(errors2.joined(separator: ", "))")

        // Clean up
        _ = try validator.cleanupAllOrphans()

        // Should be clean again
        let errors3 = try validator.validateAllForeignKeys()
        XCTAssertTrue(errors3.isEmpty, "Should be clean after cleanup")
        print("   ✓ After cleanup: No errors")

        print("✅ Test 4.1.9: Comprehensive validation verified")
        print("   Result: PASS - Comprehensive validation working correctly")
    }

    // MARK: - Test 4.1.10: Edge Cases

    func testEdgeCases() async throws {
        print("🧪 Test 4.1.10: Testing edge cases")

        // Delete non-existent person
        let invalidId = UUID()
        do {
            try validator.deletePerson(invalidId, cascadeRule: .cascade)
            XCTFail("Should fail to delete non-existent person")
        } catch ForeignKeyError.personNotFound {
            print("   ✓ Non-existent person delete rejected")
        }

        // Count references for non-existent person
        // Note: This doesn't throw, just returns 0
        let count = try validator.countReferences(forPerson: invalidId)
        XCTAssertEqual(count, 0, "Non-existent person should have 0 references")
        print("   ✓ Non-existent person: 0 references")

        // Cleanup when no orphans exist
        let cleanedCount = try validator.cleanupAllOrphans()
        XCTAssertEqual(cleanedCount, 0, "Should clean up 0 orphans")
        print("   ✓ Cleanup with no orphans: 0 cleaned")

        print("✅ Test 4.1.10: Edge cases verified")
        print("   Result: PASS - Edge cases handled appropriately")
    }
}
