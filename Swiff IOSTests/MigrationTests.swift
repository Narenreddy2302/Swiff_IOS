//
//  MigrationTests.swift
//  Swiff IOSTests
//
//  Created by Naren Reddy on 11/18/25.
//  Comprehensive test suite for SwiftData schema migrations
//

import XCTest
import SwiftData
@testable import Swiff_IOS

/// Test suite for validating SwiftData schema migrations
///
/// These tests ensure that:
/// 1. Migrations complete successfully
/// 2. Data integrity is preserved
/// 3. Relationships remain intact
/// 4. Performance is acceptable
/// 5. Error cases are handled gracefully
final class MigrationTests: XCTestCase {

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        // Clean up any existing test databases
        clearTestDatabases()
    }

    override func tearDown() {
        // Clean up after tests
        clearTestDatabases()
        super.tearDown()
    }

    // MARK: - Schema Version Tests

    /// Test that current schema version is correctly defined
    func testCurrentSchemaVersion() {
        let version = SwiffSchemaV1.versionIdentifier
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 0)
        XCTAssertEqual(version.patch, 0)
    }

    /// Test that migration plan includes all schema versions
    func testMigrationPlanContainsAllSchemas() {
        let schemas = SwiffMigrationPlan.schemas
        XCTAssertFalse(schemas.isEmpty, "Migration plan must include at least V1")
        XCTAssertTrue(schemas.contains { $0 == SwiffSchemaV1.self })
    }

    /// Test that schema includes all required models
    func testSchemaV1ContainsAllModels() {
        let models = SwiffSchemaV1.models
        let modelNames = models.map { String(describing: $0) }

        XCTAssertTrue(modelNames.contains("PersonModel"), "Schema must include PersonModel")
        XCTAssertTrue(modelNames.contains("GroupModel"), "Schema must include GroupModel")
        XCTAssertTrue(modelNames.contains("GroupExpenseModel"), "Schema must include GroupExpenseModel")
        XCTAssertTrue(modelNames.contains("SubscriptionModel"), "Schema must include SubscriptionModel")
        XCTAssertTrue(modelNames.contains("SharedSubscriptionModel"), "Schema must include SharedSubscriptionModel")
        XCTAssertTrue(modelNames.contains("TransactionModel"), "Schema must include TransactionModel")
    }

    // MARK: - Container Creation Tests

    /// Test that model container can be created with V1 schema
    func testModelContainerCreationV1() throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        XCTAssertNoThrow(
            try ModelContainer(
                for: schema,
                migrationPlan: SwiffMigrationPlan.self,
                configurations: [configuration]
            ),
            "Creating ModelContainer with V1 schema should not throw"
        )
    }

    /// Test that PersistenceService can be initialized with migration plan
    func testPersistenceServiceInitialization() throws {
        // Create in-memory container for testing
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        // Initialize service with test container
        let service = PersistenceService(modelContainer: container)

        XCTAssertNotNil(service, "PersistenceService should initialize successfully")
    }

    // MARK: - Data Persistence Tests

    /// Test that data can be saved and retrieved with V1 schema
    func testDataPersistenceV1() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Create test data
        let person = PersonModel(
            id: UUID(),
            name: "Test User",
            email: "test@example.com",
            phone: "+1234567890",
            balance: 100.0,
            avatarType: .initials("TU", colorIndex: 0)
        )

        context.insert(person)
        try context.save()

        // Verify data was saved
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.email == "test@example.com" }
        )

        let fetchedPeople = try context.fetch(descriptor)
        XCTAssertEqual(fetchedPeople.count, 1)
        XCTAssertEqual(fetchedPeople.first?.name, "Test User")
        XCTAssertEqual(fetchedPeople.first?.balance, 100.0)
    }

    /// Test that relationships are preserved
    func testRelationshipPersistence() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Create person
        let person = PersonModel(
            id: UUID(),
            name: "John Doe",
            email: "john@example.com",
            phone: "+1234567890",
            balance: 0.0,
            avatarType: .emoji("👤")
        )

        // Create transaction
        let transaction = TransactionModel(
            id: UUID(),
            title: "Test Transaction",
            subtitle: "Test",
            amount: 50.0,
            categoryRaw: "income",
            date: Date(),
            isRecurring: false,
            tags: ["test"]
        )

        transaction.relatedPerson = person

        context.insert(person)
        context.insert(transaction)
        try context.save()

        // Verify relationship
        let descriptor = FetchDescriptor<TransactionModel>()
        let fetchedTransactions = try context.fetch(descriptor)

        XCTAssertEqual(fetchedTransactions.count, 1)
        XCTAssertNotNil(fetchedTransactions.first?.relatedPerson)
        XCTAssertEqual(fetchedTransactions.first?.relatedPerson?.name, "John Doe")
    }

    // MARK: - Migration Simulation Tests

    /// Test simulated migration from V1 to V1 (no-op, baseline test)
    func testNoOpMigration() async throws {
        // Create V1 database
        let v1Schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let v1Config = ModelConfiguration(
            schema: v1Schema,
            isStoredInMemoryOnly: true
        )

        let v1Container = try ModelContainer(
            for: v1Schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [v1Config]
        )

        let v1Context = v1Container.mainContext

        // Insert test data
        let person = PersonModel(
            id: UUID(),
            name: "Migration Test",
            email: "migrate@test.com",
            phone: "+1111111111",
            balance: 250.0,
            avatarType: .photo(Data())
        )

        v1Context.insert(person)
        try v1Context.save()

        let personID = person.id

        // "Migrate" by creating another V1 container (simulates app restart)
        let v1Container2 = try ModelContainer(
            for: v1Schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [v1Config]
        )

        let v1Context2 = v1Container2.mainContext

        // Verify data still exists (no migration needed)
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == personID }
        )

        let fetchedPeople = try v1Context2.fetch(descriptor)
        XCTAssertEqual(fetchedPeople.count, 1)
        XCTAssertEqual(fetchedPeople.first?.name, "Migration Test")
    }

    // MARK: - Data Integrity Tests

    /// Test that all data types are preserved during save/load
    func testAllDataTypesPersistence() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Test all data types in SubscriptionModel
        let subscription = SubscriptionModel(
            id: UUID(),
            name: "Netflix",
            subscriptionDescription: "Streaming service",
            price: 15.99,
            billingCycleRaw: "monthly",
            categoryRaw: "entertainment",
            icon: "tv",
            color: "red",
            nextBillingDate: Date(),
            isActive: true,
            isShared: false,
            sharedWithIDs: [UUID()],
            paymentMethodRaw: "credit_card",
            createdDate: Date(),
            lastBillingDate: Date(),
            totalSpent: 159.90,
            notes: "Family plan",
            website: "https://netflix.com",
            cancellationDate: nil
        )

        context.insert(subscription)
        try context.save()

        // Verify all fields
        let descriptor = FetchDescriptor<SubscriptionModel>()
        let fetched = try context.fetch(descriptor).first

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Netflix")
        XCTAssertEqual(fetched?.price, 15.99)
        XCTAssertEqual(fetched?.isActive, true)
        XCTAssertEqual(fetched?.sharedWithIDs.count, 1)
        XCTAssertEqual(fetched?.website, "https://netflix.com")
        XCTAssertNil(fetched?.cancellationDate)
    }

    /// Test that UUID uniqueness is preserved
    func testUUIDUniqueness() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Create multiple people
        let person1 = PersonModel(
            id: UUID(),
            name: "Person 1",
            email: "person1@test.com",
            phone: "+1111111111",
            balance: 0.0,
            avatarType: .initials("P1", colorIndex: 0)
        )

        let person2 = PersonModel(
            id: UUID(),
            name: "Person 2",
            email: "person2@test.com",
            phone: "+2222222222",
            balance: 0.0,
            avatarType: .initials("P2", colorIndex: 1)
        )

        context.insert(person1)
        context.insert(person2)
        try context.save()

        // Verify UUIDs are unique
        XCTAssertNotEqual(person1.id, person2.id)

        let descriptor = FetchDescriptor<PersonModel>()
        let allPeople = try context.fetch(descriptor)
        let uniqueIDs = Set(allPeople.map(\.id))

        XCTAssertEqual(allPeople.count, uniqueIDs.count, "All IDs should be unique")
    }

    // MARK: - Performance Tests

    /// Test migration performance with moderate dataset
    func testMigrationPerformanceWithModerateDataset() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Insert 100 records
        let startTime = Date()

        for i in 0..<100 {
            let person = PersonModel(
                id: UUID(),
                name: "Person \(i)",
                email: "person\(i)@test.com",
                phone: "+100000000\(i)",
                balance: Double(i * 10),
                avatarType: .initials("P\(i)", colorIndex: i % 10)
            )
            context.insert(person)
        }

        try context.save()
        let endTime = Date()

        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 5.0, "Saving 100 records should take less than 5 seconds")

        // Verify count
        let descriptor = FetchDescriptor<PersonModel>()
        let count = try context.fetch(descriptor).count
        XCTAssertEqual(count, 100)
    }

    /// Test fetch performance
    func testFetchPerformance() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Insert test data
        for i in 0..<50 {
            let transaction = TransactionModel(
                id: UUID(),
                title: "Transaction \(i)",
                subtitle: "Test",
                amount: Double(i),
                categoryRaw: i % 2 == 0 ? "income" : "expense",
                date: Date(),
                isRecurring: false,
                tags: ["test"]
            )
            context.insert(transaction)
        }
        try context.save()

        // Test fetch performance
        measure {
            let descriptor = FetchDescriptor<TransactionModel>()
            _ = try? context.fetch(descriptor)
        }
    }

    // MARK: - Error Handling Tests

    /// Test handling of invalid data during migration
    func testInvalidDataHandling() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let service = PersistenceService(modelContainer: container)

        // Test validation catches invalid email
        let invalidPerson = Person(
            id: UUID(),
            name: "Test",
            email: "invalid-email",  // Invalid format
            phone: "+1234567890",
            balance: 0.0,
            avatarType: .initials("T", colorIndex: 0)
        )

        XCTAssertThrowsError(try service.savePerson(invalidPerson)) { error in
            if case PersistenceError.validationFailed(let reason) = error {
                XCTAssertTrue(reason.contains("email"), "Should mention email in error")
            } else {
                XCTFail("Expected validation error, got \(error)")
            }
        }
    }

    // MARK: - Complex Relationship Tests

    /// Test group with multiple members and expenses
    func testComplexGroupRelationships() async throws {
        let schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [configuration]
        )

        let context = container.mainContext

        // Create people
        let person1 = PersonModel(
            id: UUID(),
            name: "Alice",
            email: "alice@test.com",
            phone: "+1111111111",
            balance: 0.0,
            avatarType: .emoji("👩")
        )

        let person2 = PersonModel(
            id: UUID(),
            name: "Bob",
            email: "bob@test.com",
            phone: "+2222222222",
            balance: 0.0,
            avatarType: .emoji("👨")
        )

        context.insert(person1)
        context.insert(person2)

        // Create group
        let group = GroupModel(
            id: UUID(),
            name: "Trip to Paris",
            groupDescription: "Summer vacation",
            emoji: "🗼",
            members: [person1, person2],
            totalAmount: 500.0
        )

        context.insert(group)

        // Create expense
        let expense = GroupExpenseModel(
            id: UUID(),
            title: "Hotel",
            amount: 500.0,
            paidByID: person1.id,
            splitBetweenIDs: [person1.id, person2.id],
            categoryRaw: "accommodation",
            date: Date(),
            notes: "3 nights",
            receiptPath: nil,
            isSettled: false
        )

        expense.group = group
        expense.paidBy = person1
        expense.splitBetween = [person1, person2]

        context.insert(expense)
        try context.save()

        // Verify relationships
        let groupDescriptor = FetchDescriptor<GroupModel>()
        let fetchedGroups = try context.fetch(groupDescriptor)

        XCTAssertEqual(fetchedGroups.count, 1)
        let fetchedGroup = fetchedGroups.first!
        XCTAssertEqual(fetchedGroup.members?.count, 2)
        XCTAssertEqual(fetchedGroup.expenses?.count, 1)

        let fetchedExpense = fetchedGroup.expenses?.first!
        XCTAssertEqual(fetchedExpense?.paidBy?.name, "Alice")
        XCTAssertEqual(fetchedExpense?.splitBetween?.count, 2)
    }

    // MARK: - Helper Methods

    private func clearTestDatabases() {
        // Clean up any test database files
        // In-memory databases are automatically cleaned up
    }

    // MARK: - Future Migration Tests (Template)

    /*
    /// Test migration from V1 to V2 (when V2 is implemented)
    func testMigrationV1toV2() async throws {
        // 1. Create V1 database
        let v1Schema = Schema(versionedSchema: SwiffSchemaV1.self)
        let v1Config = ModelConfiguration(
            schema: v1Schema,
            isStoredInMemoryOnly: true
        )

        let v1Container = try ModelContainer(
            for: v1Schema,
            configurations: [v1Config]
        )

        // 2. Insert V1 data
        let v1Context = v1Container.mainContext
        // ... insert test data

        // 3. Close V1 container

        // 4. Create V2 database (triggers migration)
        let v2Schema = Schema(versionedSchema: SwiffSchemaV2.self)
        let v2Config = ModelConfiguration(
            schema: v2Schema,
            isStoredInMemoryOnly: true
        )

        let v2Container = try ModelContainer(
            for: v2Schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [v2Config]
        )

        // 5. Verify migration
        let v2Context = v2Container.mainContext
        // ... verify data integrity
    }
    */
}
