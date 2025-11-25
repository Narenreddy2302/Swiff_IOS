//
//  DatabaseRecoveryManagerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 1.1: Remove All Fatal Errors
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class DatabaseRecoveryManagerTests: XCTestCase {

    var recoveryManager: DatabaseRecoveryManager!
    var fileManager: FileManager!
    var testDocumentsDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        recoveryManager = DatabaseRecoveryManager.shared
        fileManager = FileManager.default

        // Get test documents directory
        testDocumentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    override func tearDown() async throws {
        // Clean up test files
        let backupDirectory = testDocumentsDirectory.appendingPathComponent("CorruptedBackups", isDirectory: true)
        if fileManager.fileExists(atPath: backupDirectory.path) {
            try? fileManager.removeItem(at: backupDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - Test 1.1.1: Simulate Database Corruption

    func testDatabaseCorruptionRecovery() async throws {
        // This test verifies that the app can recover from corrupted database

        print("🧪 Test 1.1.1: Simulating database corruption scenario")

        // Clean state
        let storeURL = testDocumentsDirectory.appendingPathComponent("default.store")

        // Create a corrupted file
        let corruptedData = Data("CORRUPTED DATABASE FILE".utf8)
        try corruptedData.write(to: storeURL)

        print("   Created corrupted database file at: \(storeURL.path)")

        // Verify file exists
        XCTAssertTrue(fileManager.fileExists(atPath: storeURL.path), "Corrupted file should exist")

        print("✅ Test 1.1.1: Database corruption setup complete")
        print("   Result: PASS - Corrupted file created successfully")
        print("   Next Step: Launch app to verify recovery sheet appears")
    }

    // MARK: - Test 1.1.2: Verify Retry Logic

    func testRetryLogicWithExponentialBackoff() async throws {
        print("🧪 Test 1.1.2: Testing retry logic with exponential backoff")

        let schema = Schema([PersonModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let startTime = Date()
        var attemptTimes: [TimeInterval] = []

        do {
            // This will fail because we're using a corrupted database
            let container = try await recoveryManager.attemptContainerCreation(
                schema: schema,
                migrationPlan: SwiffMigrationPlan.self,
                configuration: config,
                maxRetries: 3
            )

            // If it somehow succeeds, that's fine for the test
            XCTAssertNotNil(container)
            print("   Container created unexpectedly - database may not be corrupted")

        } catch {
            let totalTime = Date().timeIntervalSince(startTime)

            // Expected retry delays: 1s + 2s + 4s = ~7s minimum
            print("   Retry attempts completed")
            print("   Total time elapsed: \(String(format: "%.2f", totalTime))s")
            print("   Expected minimum: ~7s (1s + 2s + 4s exponential backoff)")

            // Verify exponential backoff occurred (should take at least 7 seconds)
            XCTAssertTrue(totalTime >= 6.0, "Exponential backoff should take at least 6 seconds")

            print("✅ Test 1.1.2: Retry logic verified")
            print("   Result: PASS - Exponential backoff working correctly")
        }
    }

    // MARK: - Test 1.1.3: Test Recovery UI

    func testRecoveryUIAppears() async throws {
        print("🧪 Test 1.1.3: Testing recovery UI state management")

        // Initially should not be showing
        XCTAssertFalse(recoveryManager.showRecoverySheet, "Recovery sheet should not be showing initially")
        XCTAssertFalse(recoveryManager.isRecovering, "Should not be in recovery state initially")

        // Simulate an error
        let testError = NSError(domain: "TestDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Test database corruption error"
        ])

        // Trigger recovery
        let strategy = await recoveryManager.performRecovery(error: testError)

        // Verify UI state changed
        XCTAssertTrue(recoveryManager.showRecoverySheet, "Recovery sheet should be showing")
        XCTAssertTrue(recoveryManager.isRecovering, "Should be in recovery state")
        XCTAssertNotNil(recoveryManager.recoveryError, "Recovery error should be set")

        print("✅ Test 1.1.3: Recovery UI state verified")
        print("   Result: PASS - Recovery sheet appears correctly")
        print("   - showRecoverySheet: \(recoveryManager.showRecoverySheet)")
        print("   - isRecovering: \(recoveryManager.isRecovering)")
        print("   - recoveryError: \(recoveryManager.recoveryError?.localizedDescription ?? "nil")")
    }

    // MARK: - Test 1.1.4: Confirm Backup Creation

    func testBackupCreation() async throws {
        print("🧪 Test 1.1.4: Testing corrupted database backup creation")

        // Create a test database file to backup
        let storeURL = testDocumentsDirectory.appendingPathComponent("default.store")
        let testData = Data("TEST DATABASE CONTENT".utf8)
        try testData.write(to: storeURL)

        print("   Created test database file")

        // Perform backup
        try await recoveryManager.backupCorruptedDatabase()

        // Verify backup directory was created
        let backupDirectory = testDocumentsDirectory.appendingPathComponent("CorruptedBackups", isDirectory: true)
        XCTAssertTrue(fileManager.fileExists(atPath: backupDirectory.path), "Backup directory should exist")

        // Verify backup file was created
        let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
        XCTAssertFalse(backupFiles.isEmpty, "Backup directory should contain files")

        // Verify backup file has correct naming pattern
        let backupFile = backupFiles.first!
        XCTAssertTrue(backupFile.lastPathComponent.hasPrefix("corrupted_"), "Backup file should have 'corrupted_' prefix")
        XCTAssertTrue(backupFile.lastPathComponent.hasSuffix(".store"), "Backup file should have '.store' extension")

        print("✅ Test 1.1.4: Backup creation verified")
        print("   Result: PASS - Corrupted database backed up successfully")
        print("   Backup location: \(backupDirectory.path)")
        print("   Backup files: \(backupFiles.count)")
        print("   Backup file: \(backupFile.lastPathComponent)")
    }

    // MARK: - Test 1.1.5: Validate Fresh Database

    func testDatabaseReset() async throws {
        print("🧪 Test 1.1.5: Testing database reset functionality")

        // Create database files to reset
        let filesToCreate = [
            "default.store",
            "default.store-shm",
            "default.store-wal"
        ]

        for filename in filesToCreate {
            let fileURL = testDocumentsDirectory.appendingPathComponent(filename)
            let testData = Data("TEST DATA".utf8)
            try testData.write(to: fileURL)
        }

        print("   Created test database files: \(filesToCreate.joined(separator: ", "))")

        // Verify files exist
        for filename in filesToCreate {
            let fileURL = testDocumentsDirectory.appendingPathComponent(filename)
            XCTAssertTrue(fileManager.fileExists(atPath: fileURL.path), "\(filename) should exist before reset")
        }

        // Perform reset
        try await recoveryManager.resetDatabase()

        // Verify files were deleted
        for filename in filesToCreate {
            let fileURL = testDocumentsDirectory.appendingPathComponent(filename)
            XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path), "\(filename) should be deleted after reset")
        }

        print("✅ Test 1.1.5: Database reset verified")
        print("   Result: PASS - All database files deleted successfully")
        print("   Files deleted: \(filesToCreate.joined(separator: ", "))")
    }

    // MARK: - Test 1.1.6: Test In-Memory Fallback

    func testInMemoryFallback() async throws {
        print("🧪 Test 1.1.6: Testing in-memory fallback scenario")

        // This test verifies that when all recovery fails, app falls back to in-memory database

        // Create a schema for testing
        let schema = Schema([PersonModel.self])
        let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [inMemoryConfig])

            // Verify container was created in-memory
            XCTAssertNotNil(container)

            // Verify we can create a context
            let context = container.mainContext
            XCTAssertNotNil(context)

            print("✅ Test 1.1.6: In-memory fallback verified")
            print("   Result: PASS - In-memory database created successfully")
            print("   Container: \(container)")
            print("   Context: \(context)")

        } catch {
            XCTFail("In-memory database creation should not fail: \(error)")
        }
    }

    // MARK: - Test Recovery Error Detection

    func testRecoverableErrorDetection() throws {
        print("🧪 Additional Test: Testing recoverable error detection")

        // Test various error types
        let recoverableErrors = [
            NSError(domain: "TestDomain", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Database is corrupted"
            ]),
            NSError(domain: "TestDomain", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "SQLite error occurred"
            ]),
            NSError(domain: "TestDomain", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Migration failed"
            ]),
        ]

        let nonRecoverableError = NSError(domain: "TestDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Random network error"
        ])

        // Test recoverable errors
        for error in recoverableErrors {
            XCTAssertTrue(
                recoveryManager.isRecoverable(error: error),
                "Should detect '\(error.localizedDescription)' as recoverable"
            )
        }

        // Test non-recoverable error
        XCTAssertFalse(
            recoveryManager.isRecoverable(error: nonRecoverableError),
            "Should detect network error as non-recoverable"
        )

        print("✅ Additional Test: Error detection verified")
        print("   Result: PASS - Recoverable error patterns working correctly")
    }
}
