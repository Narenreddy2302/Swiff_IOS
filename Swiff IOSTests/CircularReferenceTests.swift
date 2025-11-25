//
//  CircularReferenceTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for CircularReferenceDetector - Phase 4.5
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class CircularReferenceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var detector: CircularReferenceDetector!

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
        detector = CircularReferenceDetector(modelContext: modelContext)
    }

    override func tearDown() async throws {
        detector = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: No Circular References

    func testNoCircularReferences() throws {
        // Add simple data without cycles
        let person1 = PersonModel(name: "Alice", email: "alice@example.com")
        let person2 = PersonModel(name: "Bob", email: "bob@example.com")

        modelContext.insert(person1)
        modelContext.insert(person2)

        let transaction = TransactionModel(
            payerId: person1.id,
            payeeId: person2.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction)

        try modelContext.save()

        let result = try detector.detectAllCircularReferences()

        XCTAssertFalse(result.hasCircularReferences, "Should not detect circular references")
        XCTAssertEqual(result.circularPaths.count, 0, "Should have no circular paths")
    }

    // MARK: - Test 2: Self-Reference Detection

    func testSelfReferenceDetection() throws {
        let person = PersonModel(name: "Charlie", email: "charlie@example.com")
        modelContext.insert(person)

        // Create self-payment transaction
        let transaction = TransactionModel(
            payerId: person.id,
            payeeId: person.id, // Same person
            amount: 100.0,
            date: Date()
        )
        modelContext.insert(transaction)

        try modelContext.save()

        let selfReferences = try detector.detectSelfReferences()

        XCTAssertFalse(selfReferences.isEmpty, "Should detect self-reference")
        XCTAssertTrue(selfReferences[0].contains("paying themselves"), "Error message should mention self-payment")
    }

    func testNoSelfReferences() throws {
        let person1 = PersonModel(name: "David", email: "david@example.com")
        let person2 = PersonModel(name: "Eve", email: "eve@example.com")

        modelContext.insert(person1)
        modelContext.insert(person2)

        let transaction = TransactionModel(
            payerId: person1.id,
            payeeId: person2.id,
            amount: 75.0,
            date: Date()
        )
        modelContext.insert(transaction)

        try modelContext.save()

        let selfReferences = try detector.detectSelfReferences()

        XCTAssertTrue(selfReferences.isEmpty, "Should not detect self-references")
    }

    // MARK: - Test 3: Transaction Chain Detection

    func testCircularTransactionChain() throws {
        // Create A -> B -> C -> A cycle
        let personA = PersonModel(name: "Alice", email: "alice@example.com")
        let personB = PersonModel(name: "Bob", email: "bob@example.com")
        let personC = PersonModel(name: "Charlie", email: "charlie@example.com")

        modelContext.insert(personA)
        modelContext.insert(personB)
        modelContext.insert(personC)

        // A owes B
        let transaction1 = TransactionModel(
            payerId: personA.id,
            payeeId: personB.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction1)

        // B owes C
        let transaction2 = TransactionModel(
            payerId: personB.id,
            payeeId: personC.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction2)

        // C owes A (completes the cycle)
        let transaction3 = TransactionModel(
            payerId: personC.id,
            payeeId: personA.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction3)

        try modelContext.save()

        let result = try detector.detectCircularTransactionChains()

        XCTAssertTrue(result.hasCircularReferences, "Should detect circular transaction chain")
        XCTAssertFalse(result.circularPaths.isEmpty, "Should have at least one circular path")

        if let path = result.circularPaths.first {
            XCTAssertEqual(path.type, .transactionChain, "Should be transaction chain type")
            XCTAssertGreaterThanOrEqual(path.cycleLength, 3, "Cycle should include at least 3 people")
        }
    }

    func testNoCircularTransactionChain() throws {
        // Create linear chain: A -> B -> C (no cycle)
        let personA = PersonModel(name: "Alice", email: "alice@example.com")
        let personB = PersonModel(name: "Bob", email: "bob@example.com")
        let personC = PersonModel(name: "Charlie", email: "charlie@example.com")

        modelContext.insert(personA)
        modelContext.insert(personB)
        modelContext.insert(personC)

        let transaction1 = TransactionModel(
            payerId: personA.id,
            payeeId: personB.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction1)

        let transaction2 = TransactionModel(
            payerId: personB.id,
            payeeId: personC.id,
            amount: 30.0,
            date: Date()
        )
        modelContext.insert(transaction2)

        try modelContext.save()

        let result = try detector.detectCircularTransactionChains()

        XCTAssertFalse(result.hasCircularReferences, "Should not detect circular references in linear chain")
        XCTAssertEqual(result.circularPaths.count, 0, "Should have no circular paths")
    }

    // MARK: - Test 4: Group Membership Detection

    func testGroupMembershipDetection() throws {
        let person1 = PersonModel(name: "Frank", email: "frank@example.com")
        let person2 = PersonModel(name: "Grace", email: "grace@example.com")

        modelContext.insert(person1)
        modelContext.insert(person2)

        let group = GroupModel(name: "Test Group")
        group.memberIds = [person1.id, person2.id]
        modelContext.insert(group)

        try modelContext.save()

        let result = try detector.detectCircularGroupMemberships()

        // Should not detect cycles in simple group membership
        XCTAssertFalse(result.hasCircularReferences, "Simple group should not have circular references")
    }

    func testEmptyGroupWarning() throws {
        let group = GroupModel(name: "Empty Group")
        modelContext.insert(group)

        try modelContext.save()

        let result = try detector.detectCircularGroupMemberships()

        XCTAssertFalse(result.warnings.isEmpty, "Should have warning for empty group")
        XCTAssertTrue(result.warnings[0].contains("no members"), "Warning should mention empty group")
    }

    // MARK: - Test 5: Subscription Chain Detection

    func testSubscriptionChainDetection() throws {
        let person = PersonModel(name: "Henry", email: "henry@example.com")
        modelContext.insert(person)

        let subscription = SubscriptionModel(
            name: "Netflix",
            amount: 9.99,
            cycle: "monthly",
            personId: person.id
        )
        modelContext.insert(subscription)

        try modelContext.save()

        let result = try detector.detectCircularSubscriptionChains()

        XCTAssertFalse(result.hasCircularReferences, "Valid subscription should not have circular references")
        XCTAssertTrue(result.warnings.isEmpty, "Should have no warnings for valid subscription")
    }

    func testOrphanedSubscriptionWarning() throws {
        let subscription = SubscriptionModel(
            name: "Orphaned Sub",
            amount: 9.99,
            cycle: "monthly",
            personId: UUID() // Non-existent person
        )
        modelContext.insert(subscription)

        try modelContext.save()

        let result = try detector.detectCircularSubscriptionChains()

        XCTAssertFalse(result.warnings.isEmpty, "Should have warning for orphaned subscription")
        XCTAssertTrue(result.warnings[0].contains("non-existent person"), "Warning should mention non-existent person")
    }

    // MARK: - Test 6: Graph Validation

    func testGraphValidationNoCycles() {
        var nodes: [GraphNode<String>] = []

        var nodeA = GraphNode(id: "A")
        nodeA.neighbors = ["B"]
        nodes.append(nodeA)

        var nodeB = GraphNode(id: "B")
        nodeB.neighbors = ["C"]
        nodes.append(nodeB)

        var nodeC = GraphNode(id: "C")
        nodeC.neighbors = []
        nodes.append(nodeC)

        let components = detector.validateGraphStructure(nodes: nodes)

        XCTAssertTrue(components.isEmpty, "Linear graph should have no strongly connected components")
    }

    func testGraphValidationWithCycle() {
        var nodes: [GraphNode<String>] = []

        var nodeA = GraphNode(id: "A")
        nodeA.neighbors = ["B"]
        nodes.append(nodeA)

        var nodeB = GraphNode(id: "B")
        nodeB.neighbors = ["C"]
        nodes.append(nodeB)

        var nodeC = GraphNode(id: "C")
        nodeC.neighbors = ["A"] // Cycle back to A
        nodes.append(nodeC)

        let components = detector.validateGraphStructure(nodes: nodes)

        XCTAssertFalse(components.isEmpty, "Cyclic graph should have strongly connected components")
        XCTAssertEqual(components[0].count, 3, "Component should include all 3 nodes")
    }

    // MARK: - Test 7: Recursion Prevention

    func testSafeRecursiveOperation() throws {
        var callCount = 0

        let result = try detector.safeRecursiveOperation(maxDepth: 10) { depth in
            callCount += 1
            return depth
        }

        XCTAssertEqual(result, 0, "Should return initial depth")
        XCTAssertEqual(callCount, 1, "Should call operation once")
    }

    func testRecursionLimitEnforcement() {
        var depth = 0

        XCTAssertThrowsError(
            try detector.safeRecursiveOperation(maxDepth: 5) { currentDepth in
                depth = currentDepth
                if currentDepth < 10 {
                    return try detector.safeRecursiveOperation(maxDepth: 5) { currentDepth + 1 }
                }
                return currentDepth
            }
        ) { error in
            XCTAssertTrue(error is CircularReferenceError, "Should throw CircularReferenceError")
            if case CircularReferenceError.infiniteRecursionDetected(let detectedDepth) = error {
                XCTAssertGreaterThanOrEqual(detectedDepth, 5, "Should detect recursion at or beyond limit")
            }
        }
    }

    // MARK: - Test 8: Path Finding

    func testFindPath() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        let debtGraph: [UUID: Set<UUID>] = [
            id1: [id2],
            id2: [id3]
        ]

        let path = detector.findPath(from: id1, to: id3, via: debtGraph)

        XCTAssertNotNil(path, "Should find path")
        XCTAssertEqual(path?.count, 3, "Path should include all 3 nodes")
        XCTAssertEqual(path?.first, id1, "Path should start at source")
        XCTAssertEqual(path?.last, id3, "Path should end at target")
    }

    func testFindPathNotExists() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        let debtGraph: [UUID: Set<UUID>] = [
            id1: [id2]
            // No path from id1 to id3
        ]

        let path = detector.findPath(from: id1, to: id3, via: debtGraph)

        XCTAssertNil(path, "Should not find path when none exists")
    }

    // MARK: - Test 9: Relationship Validation

    func testValidateNewRelationshipNoCycle() throws {
        let id1 = UUID()
        let id2 = UUID()

        let debtGraph: [UUID: Set<UUID>] = [:]

        let isValid = try detector.validateNewRelationship(from: id1, to: id2, in: debtGraph)

        XCTAssertTrue(isValid, "New relationship should be valid when no cycle exists")
    }

    func testValidateNewRelationshipCreatesCycle() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        // Existing: id1 -> id2 -> id3
        let debtGraph: [UUID: Set<UUID>] = [
            id1: [id2],
            id2: [id3]
        ]

        // Try to add: id3 -> id1 (would create cycle)
        XCTAssertThrowsError(
            try detector.validateNewRelationship(from: id3, to: id1, in: debtGraph)
        ) { error in
            XCTAssertTrue(error is CircularReferenceError, "Should throw CircularReferenceError")
            if case CircularReferenceError.cyclicDependency = error {
                // Expected
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - Test 10: Comprehensive Detection

    func testDetectAllCircularReferences() throws {
        // Add various entities
        let person1 = PersonModel(name: "Iris", email: "iris@example.com")
        let person2 = PersonModel(name: "Jack", email: "jack@example.com")

        modelContext.insert(person1)
        modelContext.insert(person2)

        // Add self-payment (should trigger warning)
        let selfTransaction = TransactionModel(
            payerId: person1.id,
            payeeId: person1.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(selfTransaction)

        // Add orphaned subscription (should trigger warning)
        let orphanedSub = SubscriptionModel(
            name: "Orphaned",
            amount: 9.99,
            cycle: "monthly",
            personId: UUID()
        )
        modelContext.insert(orphanedSub)

        try modelContext.save()

        let result = try detector.detectAllCircularReferences()

        XCTAssertFalse(result.warnings.isEmpty, "Should have warnings")
        XCTAssertTrue(result.warnings.count >= 2, "Should have at least 2 warnings")
    }

    // MARK: - Test 11: Statistics and Reporting

    func testGetStatistics() throws {
        let person1 = PersonModel(name: "Kate", email: "kate@example.com")
        let person2 = PersonModel(name: "Leo", email: "leo@example.com")

        modelContext.insert(person1)
        modelContext.insert(person2)

        try modelContext.save()

        let stats = try detector.getStatistics()

        XCTAssertTrue(stats.contains("Circular Reference Statistics"), "Stats should have title")
        XCTAssertTrue(stats.contains("Total Circular Paths"), "Stats should show total paths")
        XCTAssertTrue(stats.contains("Status"), "Stats should show status")
    }

    func testExportReport() throws {
        let person = PersonModel(name: "Mike", email: "mike@example.com")
        modelContext.insert(person)

        try modelContext.save()

        let report = try detector.exportReport()

        XCTAssertTrue(report.contains("Circular Reference Detection Report"), "Report should have title")
        XCTAssertTrue(report.contains("Status"), "Report should show status")
    }

    // MARK: - Test 12: Quick Checks

    func testHasCircularReferencesTrue() throws {
        // Create circular transaction chain
        let personA = PersonModel(name: "Alice", email: "alice@example.com")
        let personB = PersonModel(name: "Bob", email: "bob@example.com")

        modelContext.insert(personA)
        modelContext.insert(personB)

        let transaction1 = TransactionModel(
            payerId: personA.id,
            payeeId: personB.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction1)

        let transaction2 = TransactionModel(
            payerId: personB.id,
            payeeId: personA.id,
            amount: 50.0,
            date: Date()
        )
        modelContext.insert(transaction2)

        try modelContext.save()

        let hasCircular = try detector.hasCircularReferences()

        XCTAssertTrue(hasCircular, "Should detect circular references")
    }

    func testHasCircularReferencesFalse() throws {
        let person1 = PersonModel(name: "Nina", email: "nina@example.com")
        let person2 = PersonModel(name: "Oscar", email: "oscar@example.com")

        modelContext.insert(person1)
        modelContext.insert(person2)

        try modelContext.save()

        let hasCircular = try detector.hasCircularReferences()

        XCTAssertFalse(hasCircular, "Should not detect circular references")
    }

    func testGetCircularReferenceCount() throws {
        let person = PersonModel(name: "Paul", email: "paul@example.com")
        modelContext.insert(person)

        try modelContext.save()

        let count = try detector.getCircularReferenceCount()

        XCTAssertEqual(count, 0, "Should have 0 circular references")
    }

    // MARK: - Test 13: Result Methods

    func testCircularReferenceResultSummary() {
        let result = CircularReferenceResult(
            hasCircularReferences: false,
            circularPaths: [],
            warnings: []
        )

        XCTAssertTrue(result.summary.contains("No circular references"), "Summary should indicate no issues")

        let resultWithIssues = CircularReferenceResult(
            hasCircularReferences: true,
            circularPaths: [
                CircularReferenceResult.CircularPath(
                    type: .transactionChain,
                    entityIds: [UUID(), UUID()],
                    entityNames: ["Alice", "Bob"]
                )
            ],
            warnings: []
        )

        XCTAssertTrue(resultWithIssues.summary.contains("Found 1"), "Summary should show count")
    }

    func testCircularPathDescription() {
        let path = CircularReferenceResult.CircularPath(
            type: .transactionChain,
            entityIds: [UUID(), UUID(), UUID()],
            entityNames: ["Alice", "Bob", "Charlie"]
        )

        XCTAssertEqual(path.pathDescription, "Alice → Bob → Charlie", "Path description should be formatted correctly")
        XCTAssertEqual(path.cycleLength, 3, "Cycle length should be 3")
    }

    // MARK: - Test 14: Edge Cases

    func testEmptyDatabase() throws {
        let result = try detector.detectAllCircularReferences()

        XCTAssertFalse(result.hasCircularReferences, "Empty database should have no circular references")
        XCTAssertEqual(result.circularPaths.count, 0, "Should have no paths")
    }

    func testSinglePerson() throws {
        let person = PersonModel(name: "Quinn", email: "quinn@example.com")
        modelContext.insert(person)

        try modelContext.save()

        let result = try detector.detectAllCircularReferences()

        XCTAssertFalse(result.hasCircularReferences, "Single person should not create cycles")
    }

    func testComplexGraph() throws {
        // Create more complex scenario
        let people = (0..<5).map { i in
            PersonModel(name: "Person\(i)", email: "person\(i)@example.com")
        }

        for person in people {
            modelContext.insert(person)
        }

        // Create various transactions
        for i in 0..<4 {
            let transaction = TransactionModel(
                payerId: people[i].id,
                payeeId: people[i + 1].id,
                amount: Double(i * 10),
                date: Date()
            )
            modelContext.insert(transaction)
        }

        try modelContext.save()

        let result = try detector.detectAllCircularReferences()

        // Linear chain should not have cycles
        XCTAssertFalse(result.hasCircularReferences, "Linear chain should not have circular references")
    }
}
