//
//  BackupVerificationTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for BackupVerificationManager - Phase 4.4
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class BackupVerificationTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var verificationManager: BackupVerificationManager!
    var tempDirectory: URL!

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
        verificationManager = BackupVerificationManager(modelContext: modelContext)

        // Create temp directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupVerificationTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Clean up temp directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        verificationManager = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestBackupFile(name: String, content: String = "Test backup content") -> URL {
        let fileURL = tempDirectory.appendingPathComponent(name)
        try? content.data(using: .utf8)?.write(to: fileURL)
        return fileURL
    }

    private func createTestMetadata(for backupURL: URL, version: Int = 1, checksumOverride: String? = nil) throws {
        let checksum = checksumOverride ?? (try? verificationManager.calculateChecksum(for: backupURL)) ?? "test_checksum"

        let metadata = BackupMetadata(
            version: version,
            created: Date(),
            checksum: checksum,
            entitiesCounts: BackupMetadata.EntityCounts(
                people: 10,
                groups: 5,
                subscriptions: 15,
                transactions: 20
            ),
            totalSize: 1024,
            format: "swiftdata",
            appVersion: "1.0"
        )

        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")

        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
    }

    // MARK: - Test 1: Checksum Calculation

    func testCalculateChecksum() throws {
        let fileURL = createTestBackupFile(name: "test1.backup", content: "Hello World")

        let checksum = try verificationManager.calculateChecksum(for: fileURL)

        XCTAssertFalse(checksum.isEmpty, "Checksum should not be empty")
        XCTAssertEqual(checksum.count, 64, "SHA256 checksum should be 64 characters")

        // Calculate again to ensure consistency
        let checksum2 = try verificationManager.calculateChecksum(for: fileURL)
        XCTAssertEqual(checksum, checksum2, "Checksum should be consistent")
    }

    func testChecksumDifferentContent() throws {
        let file1URL = createTestBackupFile(name: "test1.backup", content: "Content 1")
        let file2URL = createTestBackupFile(name: "test2.backup", content: "Content 2")

        let checksum1 = try verificationManager.calculateChecksum(for: file1URL)
        let checksum2 = try verificationManager.calculateChecksum(for: file2URL)

        XCTAssertNotEqual(checksum1, checksum2, "Different content should produce different checksums")
    }

    // MARK: - Test 2: Metadata Operations

    func testReadMetadata() throws {
        let backupURL = createTestBackupFile(name: "test.backup")
        try createTestMetadata(for: backupURL, version: 1)

        let metadata = try verificationManager.readMetadata(from: backupURL)

        XCTAssertEqual(metadata.version, 1, "Version should match")
        XCTAssertEqual(metadata.entitiesCounts.people, 10, "People count should match")
        XCTAssertEqual(metadata.format, "swiftdata", "Format should match")
    }

    func testCreateMetadata() throws {
        // Add some data to database
        let person = PersonModel(name: "Test Person", email: "test@example.com")
        modelContext.insert(person)
        try modelContext.save()

        let backupURL = createTestBackupFile(name: "test.backup")

        let metadata = try verificationManager.createMetadata(for: backupURL, version: 1)

        XCTAssertEqual(metadata.version, 1, "Version should be 1")
        XCTAssertEqual(metadata.entitiesCounts.people, 1, "Should have 1 person")
        XCTAssertFalse(metadata.checksum.isEmpty, "Checksum should be generated")

        // Verify metadata file was created
        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: metadataURL.path), "Metadata file should exist")
    }

    // MARK: - Test 3: Entity Counts

    func testGetCurrentEntityCounts() throws {
        // Add test data
        let person = PersonModel(name: "Alice", email: "alice@example.com")
        modelContext.insert(person)

        let group = GroupModel(name: "Test Group")
        modelContext.insert(group)

        let subscription = SubscriptionModel(
            name: "Netflix",
            amount: 9.99,
            cycle: "monthly",
            personId: person.id
        )
        modelContext.insert(subscription)

        try modelContext.save()

        let counts = try verificationManager.getCurrentEntityCounts()

        XCTAssertEqual(counts.people, 1, "Should have 1 person")
        XCTAssertEqual(counts.groups, 1, "Should have 1 group")
        XCTAssertEqual(counts.subscriptions, 1, "Should have 1 subscription")
        XCTAssertEqual(counts.transactions, 0, "Should have 0 transactions")
        XCTAssertEqual(counts.total, 3, "Total should be 3")
    }

    // MARK: - Test 4: Backup Verification

    func testVerifyValidBackup() async throws {
        let backupURL = createTestBackupFile(name: "valid.backup")
        try createTestMetadata(for: backupURL, version: 1)

        let result = try await verificationManager.verifyBackup(at: backupURL)

        XCTAssertTrue(result.isValid, "Backup should be valid")
        XCTAssertTrue(result.checksumValid, "Checksum should be valid")
        XCTAssertTrue(result.versionCompatible, "Version should be compatible")
        XCTAssertTrue(result.dataComplete, "Data should be complete")
        XCTAssertTrue(result.errors.isEmpty, "Should have no errors")
    }

    func testVerifyBackupNotFound() async throws {
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.backup")

        let result = try await verificationManager.verifyBackup(at: nonExistentURL)

        XCTAssertFalse(result.isValid, "Backup should be invalid")
        XCTAssertFalse(result.errors.isEmpty, "Should have errors")
        XCTAssertTrue(result.errors[0].contains("not found"), "Error should mention file not found")
    }

    func testVerifyBackupChecksumMismatch() async throws {
        let backupURL = createTestBackupFile(name: "corrupt.backup", content: "Original content")
        try createTestMetadata(for: backupURL, version: 1, checksumOverride: "invalid_checksum")

        let result = try await verificationManager.verifyBackup(at: backupURL)

        XCTAssertFalse(result.isValid, "Backup should be invalid")
        XCTAssertFalse(result.checksumValid, "Checksum should be invalid")
        XCTAssertTrue(result.errors.contains { $0.contains("Checksum validation failed") }, "Should have checksum error")
    }

    func testVerifyBackupIncompatibleVersion() async throws {
        let backupURL = createTestBackupFile(name: "future.backup")
        try createTestMetadata(for: backupURL, version: 999)

        let result = try await verificationManager.verifyBackup(at: backupURL)

        XCTAssertFalse(result.isValid, "Backup should be invalid")
        XCTAssertFalse(result.versionCompatible, "Version should be incompatible")
        XCTAssertTrue(result.errors.contains { $0.contains("newer than current version") }, "Should have version error")
    }

    func testVerifyBackupEmptyFile() async throws {
        let backupURL = createTestBackupFile(name: "empty.backup", content: "")
        try createTestMetadata(for: backupURL, version: 1)

        let result = try await verificationManager.verifyBackup(at: backupURL)

        XCTAssertFalse(result.isValid, "Empty backup should be invalid")
        XCTAssertTrue(result.errors.contains { $0.contains("empty") }, "Should have empty file error")
    }

    // MARK: - Test 5: Restore Preview

    func testGenerateRestorePreview() async throws {
        // Add current data
        let person = PersonModel(name: "Current User", email: "current@example.com")
        modelContext.insert(person)
        try modelContext.save()

        // Create backup with different counts
        let backupURL = createTestBackupFile(name: "preview.backup")
        try createTestMetadata(for: backupURL, version: 1)

        let preview = try await verificationManager.generateRestorePreview(for: backupURL)

        XCTAssertEqual(preview.currentCounts.people, 1, "Current should have 1 person")
        XCTAssertEqual(preview.metadata.entitiesCounts.people, 10, "Backup should have 10 people")
        XCTAssertEqual(preview.changes.peopleAdded, 9, "Should add 9 people")
        XCTAssertTrue(preview.changes.hasChanges, "Should have changes")
    }

    func testRestorePreviewNoChanges() async throws {
        // Create backup with same counts as current
        let backupURL = createTestBackupFile(name: "nochange.backup")

        let currentCounts = try verificationManager.getCurrentEntityCounts()
        let metadata = BackupMetadata(
            version: 1,
            created: Date(),
            checksum: try verificationManager.calculateChecksum(for: backupURL),
            entitiesCounts: currentCounts,
            totalSize: 1024,
            format: "swiftdata",
            appVersion: "1.0"
        )

        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)

        let preview = try await verificationManager.generateRestorePreview(for: backupURL)

        XCTAssertFalse(preview.changes.hasChanges, "Should have no changes")
        XCTAssertEqual(preview.changes.peopleAdded, 0, "Should add 0 people")
        XCTAssertEqual(preview.changes.peopleRemoved, 0, "Should remove 0 people")
    }

    // MARK: - Test 6: Batch Verification

    func testVerifyAllBackups() async throws {
        // Create multiple backups
        let backup1URL = createTestBackupFile(name: "backup1.backup")
        try createTestMetadata(for: backup1URL, version: 1)

        let backup2URL = createTestBackupFile(name: "backup2.backup")
        try createTestMetadata(for: backup2URL, version: 1)

        let backup3URL = createTestBackupFile(name: "invalid.backup", content: "")
        try createTestMetadata(for: backup3URL, version: 1)

        let results = try await verificationManager.verifyAllBackups(in: tempDirectory)

        XCTAssertEqual(results.count, 3, "Should verify 3 backups")

        let validCount = results.values.filter { $0.isValid }.count
        XCTAssertEqual(validCount, 2, "Should have 2 valid backups")

        let invalidCount = results.values.filter { !$0.isValid }.count
        XCTAssertEqual(invalidCount, 1, "Should have 1 invalid backup")
    }

    // MARK: - Test 7: Integrity Reports

    func testGenerateIntegrityReport() async throws {
        let backupURL = createTestBackupFile(name: "report.backup")
        try createTestMetadata(for: backupURL, version: 1)

        let report = try await verificationManager.generateIntegrityReport(for: backupURL)

        XCTAssertTrue(report.contains("Backup Verification Report"), "Should have report title")
        XCTAssertTrue(report.contains("Metadata"), "Should include metadata section")
        XCTAssertTrue(report.contains("Entity Counts"), "Should include entity counts")
        XCTAssertTrue(report.contains("✅") || report.contains("❌"), "Should include status icons")
    }

    func testGenerateComprehensiveReport() async throws {
        // Create multiple backups
        let backup1URL = createTestBackupFile(name: "backup1.backup")
        try createTestMetadata(for: backup1URL, version: 1)

        let backup2URL = createTestBackupFile(name: "backup2.backup")
        try createTestMetadata(for: backup2URL, version: 1)

        let report = try await verificationManager.generateComprehensiveReport(in: tempDirectory)

        XCTAssertTrue(report.contains("Comprehensive Backup Report"), "Should have report title")
        XCTAssertTrue(report.contains("Total Backups: 2"), "Should show total count")
        XCTAssertTrue(report.contains("backup1.backup"), "Should list backup1")
        XCTAssertTrue(report.contains("backup2.backup"), "Should list backup2")
    }

    // MARK: - Test 8: Quick Checks

    func testQuickCheckValid() throws {
        let backupURL = createTestBackupFile(name: "quick.backup")
        try createTestMetadata(for: backupURL, version: 1)

        let isValid = try verificationManager.quickCheck(backupURL: backupURL)

        XCTAssertTrue(isValid, "Quick check should pass for valid backup")
    }

    func testQuickCheckNoMetadata() throws {
        let backupURL = createTestBackupFile(name: "nometadata.backup")

        let isValid = try verificationManager.quickCheck(backupURL: backupURL)

        XCTAssertFalse(isValid, "Quick check should fail without metadata")
    }

    func testQuickCheckEmptyFile() throws {
        let backupURL = createTestBackupFile(name: "empty.backup", content: "")
        try createTestMetadata(for: backupURL, version: 1)

        let isValid = try verificationManager.quickCheck(backupURL: backupURL)

        XCTAssertFalse(isValid, "Quick check should fail for empty file")
    }

    func testFindValidBackups() throws {
        // Create valid and invalid backups
        let valid1URL = createTestBackupFile(name: "valid1.backup")
        try createTestMetadata(for: valid1URL, version: 1)

        let valid2URL = createTestBackupFile(name: "valid2.backup")
        try createTestMetadata(for: valid2URL, version: 1)

        _ = createTestBackupFile(name: "invalid.backup") // No metadata

        let validBackups = try verificationManager.findValidBackups(in: tempDirectory)

        XCTAssertEqual(validBackups.count, 2, "Should find 2 valid backups")
    }

    // MARK: - Test 9: Verification Result Methods

    func testVerificationResultSummary() {
        let result = BackupVerificationResult(
            isValid: true,
            metadata: nil,
            errors: [],
            warnings: [],
            checksumValid: true,
            versionCompatible: true,
            dataComplete: true
        )

        XCTAssertTrue(result.summary.contains("valid"), "Summary should indicate valid")

        let invalidResult = BackupVerificationResult(
            isValid: false,
            metadata: nil,
            errors: ["Error 1", "Error 2"],
            warnings: ["Warning 1"],
            checksumValid: false,
            versionCompatible: false,
            dataComplete: false
        )

        XCTAssertTrue(invalidResult.summary.contains("failed"), "Summary should indicate failure")
        XCTAssertTrue(invalidResult.summary.contains("Errors: 2"), "Summary should show error count")
    }

    func testVerificationResultDetailedReport() {
        let metadata = BackupMetadata(
            version: 1,
            created: Date(),
            checksum: "abc123",
            entitiesCounts: BackupMetadata.EntityCounts(
                people: 10,
                groups: 5,
                subscriptions: 15,
                transactions: 20
            ),
            totalSize: 1024,
            format: "swiftdata",
            appVersion: "1.0"
        )

        let result = BackupVerificationResult(
            isValid: true,
            metadata: metadata,
            errors: [],
            warnings: ["Test warning"],
            checksumValid: true,
            versionCompatible: true,
            dataComplete: true
        )

        let report = result.detailedReport

        XCTAssertTrue(report.contains("Backup Verification Report"), "Should have title")
        XCTAssertTrue(report.contains("✅ VALID"), "Should show valid status")
        XCTAssertTrue(report.contains("Metadata"), "Should have metadata section")
        XCTAssertTrue(report.contains("Entity Counts"), "Should have entity counts")
        XCTAssertTrue(report.contains("Warnings"), "Should show warnings")
        XCTAssertTrue(report.contains("Test warning"), "Should include warning text")
    }

    // MARK: - Test 10: Restore Preview Methods

    func testRestorePreviewChangesSummary() {
        let changes = RestorePreview.RestoreChanges(
            peopleAdded: 5,
            peopleRemoved: 2,
            groupsAdded: 3,
            groupsRemoved: 0,
            subscriptionsAdded: 10,
            subscriptionsRemoved: 1,
            transactionsAdded: 0,
            transactionsRemoved: 0
        )

        let summary = changes.summary

        XCTAssertTrue(summary.contains("+5 people"), "Should show people added")
        XCTAssertTrue(summary.contains("-2 people"), "Should show people removed")
        XCTAssertTrue(summary.contains("+3 groups"), "Should show groups added")
        XCTAssertTrue(summary.contains("+10 subscriptions"), "Should show subscriptions added")
    }

    func testRestorePreviewNoChangesSummary() {
        let changes = RestorePreview.RestoreChanges(
            peopleAdded: 0,
            peopleRemoved: 0,
            groupsAdded: 0,
            groupsRemoved: 0,
            subscriptionsAdded: 0,
            subscriptionsRemoved: 0,
            transactionsAdded: 0,
            transactionsRemoved: 0
        )

        XCTAssertFalse(changes.hasChanges, "Should have no changes")
        XCTAssertEqual(changes.summary, "No changes", "Summary should say no changes")
    }

    // MARK: - Test 11: Edge Cases

    func testVerifyBackupWithWarnings() async throws {
        let backupURL = createTestBackupFile(name: "warnings.backup")

        // Create metadata with older version
        let metadata = BackupMetadata(
            version: 0,
            created: Date(),
            checksum: try verificationManager.calculateChecksum(for: backupURL),
            entitiesCounts: BackupMetadata.EntityCounts(
                people: 0,
                groups: 0,
                subscriptions: 0,
                transactions: 0
            ),
            totalSize: 1024,
            format: "swiftdata",
            appVersion: "0.9"
        )

        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)

        let result = try await verificationManager.verifyBackup(at: backupURL)

        XCTAssertFalse(result.warnings.isEmpty, "Should have warnings")
        XCTAssertTrue(result.warnings.contains { $0.contains("no data") }, "Should warn about empty backup")
    }

    func testMetadataEntityCountsTotal() {
        let counts = BackupMetadata.EntityCounts(
            people: 10,
            groups: 5,
            subscriptions: 15,
            transactions: 20
        )

        XCTAssertEqual(counts.total, 50, "Total should be sum of all entities")
    }
}
