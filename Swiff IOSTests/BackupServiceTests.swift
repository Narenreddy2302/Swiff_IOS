//
//  BackupServiceTests.swift
//  Swiff IOSTests
//
//  Created by Naren Reddy on 11/18/25.
//  Tests for backup and restore functionality
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class BackupServiceTests: XCTestCase {
    var backupService: BackupService!
    var persistenceService: PersistenceService!
    var dataManager: DataManager!

    override func setUp() async throws {
        try await super.setUp()
        backupService = BackupService.shared
        persistenceService = PersistenceService.shared
        dataManager = DataManager()
    }

    override func tearDown() async throws {
        // Clean up any test backups
        if let backups = try? await backupService.listBackups() {
            for backup in backups {
                try? await backupService.deleteBackup(at: backup.url)
            }
        }
        dataManager = nil
        try await super.tearDown()
    }

    // MARK: - Backup Creation Tests

    func testCreateBackup() async throws {
        // Given: Some data exists
        let person = Person(
            name: "Backup Test Person",
            email: "backup@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // When: Creating a backup
        let statistics = try await backupService.createBackup()

        // Then: Backup should be created successfully
        XCTAssertGreaterThan(statistics.recordsExported, 0, "Should export at least one record")
        XCTAssertGreaterThan(statistics.fileSize, 0, "Backup file should have content")
        XCTAssertFalse(statistics.filePath.isEmpty, "Backup file path should be set")
        XCTAssertGreaterThan(statistics.duration, 0, "Duration should be tracked")

        print("✅ Backup created: \(statistics.description)")
    }

    func testBackupContainsAllDataTypes() async throws {
        // Given: Data of all types
        let person = Person(
            name: "Test Person",
            email: "test@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

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
        try dataManager.addSubscription(subscription)

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
        try dataManager.addTransaction(transaction)

        // When: Creating backup
        let statistics = try await backupService.createBackup()

        // Then: All data types should be included
        XCTAssertGreaterThanOrEqual(statistics.recordsExported, 3,
                                   "Should export all data types")
    }

    func testBackupWithOptions() async throws {
        // Given: Various data types
        let person = Person(
            name: "Test Person",
            email: "test@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // When: Creating backup with only people
        let options = BackupOptions(
            includePeople: true,
            includeGroups: false,
            includeSubscriptions: false,
            includeTransactions: false,
            prettyPrintJSON: true
        )

        let statistics = try await backupService.createBackup(options: options)

        // Then: Backup should succeed
        XCTAssertGreaterThan(statistics.fileSize, 0)
    }

    // MARK: - Automatic Backup Tests

    func testShouldCreateBackup() async throws {
        // Given: No previous backup (simulated by UserDefaults reset)
        UserDefaults.standard.removeObject(forKey: "LastBackupDate")

        // When: Checking if backup should be created
        let shouldCreate = await backupService.shouldCreateBackup()

        // Then: Should return true for first backup
        XCTAssertTrue(shouldCreate, "Should create backup if never backed up before")
    }

    func testShouldNotCreateBackupTooSoon() async throws {
        // Given: A recent backup
        UserDefaults.standard.set(Date(), forKey: "LastBackupDate")

        // When: Checking if backup should be created
        let shouldCreate = await backupService.shouldCreateBackup()

        // Then: Should return false
        XCTAssertFalse(shouldCreate, "Should not create backup too soon after last one")
    }

    func testAutomaticBackupCreation() async throws {
        // Given: No recent backup
        UserDefaults.standard.removeObject(forKey: "LastBackupDate")

        // Add some data
        let person = Person(
            name: "Auto Backup Person",
            email: "auto@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // When: Creating automatic backup
        await backupService.createAutomaticBackupIfNeeded()

        // Then: Backup should exist
        let backups = try await backupService.listBackups()
        XCTAssertGreaterThan(backups.count, 0, "Automatic backup should be created")
    }

    // MARK: - Restore Tests

    func testRestoreFromBackup() async throws {
        // Given: A backup file with known data
        let originalPerson = Person(
            name: "Original Person",
            email: "original@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(originalPerson)

        // Create backup
        let backupStats = try await backupService.createBackup()
        guard let backupURL = URL(string: "file://\(backupStats.filePath)") else {
            XCTFail("Invalid backup URL")
            return
        }

        // Clear data to simulate fresh restore
        dataManager.people.removeAll()

        // When: Restoring from backup
        let restoreOptions = RestoreOptions(
            conflictResolution: .replaceWithBackup,
            clearExistingData: false,
            validateBeforeRestore: true
        )

        let restoreStats = try await backupService.restoreFromBackup(
            url: backupURL,
            options: restoreOptions
        )

        // Then: Data should be restored
        XCTAssertGreaterThan(restoreStats.recordsImported, 0, "Should import records")
        print("✅ Restore completed: \(restoreStats.description)")

        // Reload data to verify
        dataManager.loadAllData()
        XCTAssertTrue(dataManager.people.contains { $0.id == originalPerson.id },
                     "Restored data should match original")
    }

    func testRestoreWithConflictResolution() async throws {
        // Given: Existing data and a backup
        let person1 = Person(
            name: "Person 1",
            email: "person1@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person1)

        // Create backup
        let backupStats = try await backupService.createBackup()
        guard let backupURL = URL(string: "file://\(backupStats.filePath)") else {
            XCTFail("Invalid backup URL")
            return
        }

        // When: Restoring with keepExisting strategy
        let restoreOptions = RestoreOptions(
            conflictResolution: .keepExisting,
            clearExistingData: false,
            validateBeforeRestore: true
        )

        let restoreStats = try await backupService.restoreFromBackup(
            url: backupURL,
            options: restoreOptions
        )

        // Then: Existing records should be kept (skipped)
        XCTAssertGreaterThan(restoreStats.recordsSkipped, 0,
                           "Should skip existing records with keepExisting strategy")
    }

    // MARK: - Backup Management Tests

    func testListBackups() async throws {
        // Given: Multiple backups
        try await backupService.createBackup()
        try await Task.sleep(nanoseconds: 100_000_000) // Small delay
        try await backupService.createBackup()

        // When: Listing backups
        let backups = try await backupService.listBackups()

        // Then: Should return all backups sorted by date
        XCTAssertGreaterThanOrEqual(backups.count, 2, "Should list all backups")

        // Verify sorting (newest first)
        for i in 0..<(backups.count - 1) {
            XCTAssertTrue(
                backups[i].createdDate >= backups[i + 1].createdDate,
                "Backups should be sorted newest first"
            )
        }
    }

    func testDeleteBackup() async throws {
        // Given: A backup file
        let statistics = try await backupService.createBackup()
        guard let backupURL = URL(string: "file://\(statistics.filePath)") else {
            XCTFail("Invalid backup URL")
            return
        }

        // When: Deleting the backup
        try await backupService.deleteBackup(at: backupURL)

        // Then: Backup should no longer exist
        let backups = try await backupService.listBackups()
        XCTAssertFalse(backups.contains { $0.url == backupURL },
                      "Deleted backup should not appear in list")
    }

    func testDeleteOldBackups() async throws {
        // Given: Multiple backups
        for _ in 1...7 {
            try await backupService.createBackup()
            try await Task.sleep(nanoseconds: 50_000_000) // Small delay between backups
        }

        let initialCount = try await backupService.listBackups().count
        XCTAssertGreaterThanOrEqual(initialCount, 7, "Should have at least 7 backups")

        // When: Deleting old backups, keeping only 3
        try await backupService.deleteOldBackups(keepCount: 3)

        // Then: Should have exactly 3 backups left
        let remainingBackups = try await backupService.listBackups()
        XCTAssertEqual(remainingBackups.count, 3, "Should keep only 3 most recent backups")
    }

    func testGetTotalBackupSize() async throws {
        // Given: Some backups
        try await backupService.createBackup()
        try await backupService.createBackup()

        // When: Getting total size
        let totalSize = try await backupService.getTotalBackupSize()

        // Then: Should return positive size
        XCTAssertGreaterThan(totalSize, 0, "Total backup size should be positive")
    }

    // MARK: - Validation Tests

    func testValidateBackup() async throws {
        // Given: A valid backup
        let person = Person(
            name: "Validation Test",
            email: "validation@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        let statistics = try await backupService.createBackup()
        guard let backupURL = URL(string: "file://\(statistics.filePath)") else {
            XCTFail("Invalid backup URL")
            return
        }

        // When: Validating the backup
        let isValid = try await backupService.validateBackup(at: backupURL)

        // Then: Should be valid
        XCTAssertTrue(isValid, "Backup should be valid")
    }

    // MARK: - Export for Sharing Tests

    func testExportForSharing() async throws {
        // Given: Some data
        let person = Person(
            name: "Share Test Person",
            email: "share@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👤")
        )
        try dataManager.addPerson(person)

        // When: Exporting for sharing
        let exportURL = try await backupService.exportForSharing()

        // Then: Should create a temporary file
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path),
                     "Export file should exist")
        XCTAssertTrue(exportURL.path.contains("tmp"),
                     "Export should be in temporary directory")

        // Clean up
        try? FileManager.default.removeItem(at: exportURL)
    }

    // MARK: - Stress Tests

    func testLargeBackupPerformance() async throws {
        // Given: Large dataset
        let people = (1...1000).map { i in
            Person(
                name: "Performance Test Person \(i)",
                email: "perf\(i)@example.com",
                phone: "+123456789\(i)",
                avatarType: .emoji("👤")
            )
        }

        // Add all people
        for person in people {
            try dataManager.addPerson(person)
        }

        // When: Creating backup (measure performance)
        let startTime = Date()
        let statistics = try await backupService.createBackup()
        let duration = Date().timeIntervalSince(startTime)

        // Then: Should complete in reasonable time (< 5 seconds for 1000 records)
        XCTAssertLessThan(duration, 5.0, "Large backup should complete in under 5 seconds")
        XCTAssertEqual(statistics.recordsExported, 1000, "Should export all 1000 records")

        print("✅ Large backup completed in \(String(format: "%.2f", duration)) seconds")
    }
}
