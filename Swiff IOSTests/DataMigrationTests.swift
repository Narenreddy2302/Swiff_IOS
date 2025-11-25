//
//  DataMigrationTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for DataMigrationManager - Phase 4.3
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class DataMigrationTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var migrationManager: DataMigrationManager!

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
        migrationManager = DataMigrationManager(modelContext: modelContext)

        // Reset version to 0 for testing
        UserDefaults.standard.set(0, forKey: "SwiffDatabaseVersion")
    }

    override func tearDown() async throws {
        migrationManager = nil
        modelContext = nil
        modelContainer = nil

        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "SwiffDatabaseVersion")
        UserDefaults.standard.removeObject(forKey: "SwiffMigrationStatistics")

        try await super.tearDown()
    }

    // MARK: - Test 1: Version Detection

    func testGetCurrentVersion() {
        // Initially should be 0
        XCTAssertEqual(migrationManager.getCurrentVersion(), 0, "Initial version should be 0")

        // Set version to 1
        UserDefaults.standard.set(1, forKey: "SwiffDatabaseVersion")

        // Create new manager to reload version
        let newManager = DataMigrationManager(modelContext: modelContext)
        XCTAssertEqual(newManager.getCurrentVersion(), 1, "Version should be 1 after setting")
    }

    func testNeedsMigration() {
        // Set version to 0
        UserDefaults.standard.set(0, forKey: "SwiffDatabaseVersion")
        let manager = DataMigrationManager(modelContext: modelContext)

        XCTAssertTrue(manager.needsMigration(), "Should need migration from v0")

        // Set to current version
        UserDefaults.standard.set(DataMigrationManager.currentVersion, forKey: "SwiffDatabaseVersion")
        let upToDateManager = DataMigrationManager(modelContext: modelContext)

        XCTAssertFalse(upToDateManager.needsMigration(), "Should not need migration at current version")
    }

    func testGetMigrationPath() {
        let path = migrationManager.getMigrationPath(from: 0, to: 3)
        XCTAssertEqual(path, [1, 2, 3], "Migration path should be [1, 2, 3]")

        let emptyPath = migrationManager.getMigrationPath(from: 3, to: 3)
        XCTAssertEqual(emptyPath, [], "Same version should have empty path")

        let singleStep = migrationManager.getMigrationPath(from: 0, to: 1)
        XCTAssertEqual(singleStep, [1], "Single step path should be [1]")
    }

    // MARK: - Test 2: Migration Execution

    func testBasicMigration() async throws {
        // Verify starting at version 0
        XCTAssertEqual(migrationManager.getCurrentVersion(), 0, "Should start at version 0")

        // Perform migration
        let result = try await migrationManager.migrate(to: 1)

        XCTAssertTrue(result.success, "Migration should succeed")
        XCTAssertEqual(result.fromVersion, 0, "Should migrate from version 0")
        XCTAssertEqual(result.toVersion, 1, "Should migrate to version 1")
        XCTAssertEqual(migrationManager.getCurrentVersion(), 1, "Version should be updated to 1")
        XCTAssertTrue(result.errors.isEmpty, "Should have no errors")
    }

    func testMigrationToLatestVersion() async throws {
        let result = try await migrationManager.migrate()

        XCTAssertTrue(result.success, "Migration to latest should succeed")
        XCTAssertEqual(result.toVersion, DataMigrationManager.currentVersion, "Should migrate to current version")
        XCTAssertEqual(migrationManager.getCurrentVersion(), DataMigrationManager.currentVersion, "Version should match current")
    }

    func testNoMigrationNeeded() async throws {
        // Set to current version
        UserDefaults.standard.set(DataMigrationManager.currentVersion, forKey: "SwiffDatabaseVersion")
        let manager = DataMigrationManager(modelContext: modelContext)

        // Try to migrate
        do {
            _ = try await manager.migrate(to: DataMigrationManager.currentVersion)
            XCTFail("Should throw noMigrationNeeded error")
        } catch MigrationError.noMigrationNeeded {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Test 3: Custom Migration Steps

    func testRegisterCustomMigration() {
        var migrationExecuted = false

        let customStep = MigrationStep(
            from: 1,
            to: 2,
            description: "Test migration",
            migrate: { _ in
                migrationExecuted = true
            }
        )

        migrationManager.registerMigrationStep(customStep)

        let migrations = migrationManager.getAvailableMigrations()
        XCTAssertTrue(migrations.contains { $0.contains("Test migration") }, "Custom migration should be registered")
    }

    func testCustomMigrationExecution() async throws {
        var migrationExecuted = false

        let customStep = MigrationStep(
            from: 1,
            to: 2,
            description: "Custom migration step",
            migrate: { context in
                migrationExecuted = true

                // Add a test person
                let person = PersonModel(name: "Migrated User", email: "test@example.com")
                context.insert(person)
                try context.save()
            }
        )

        migrationManager.registerMigrationStep(customStep)

        // First migrate to v1
        _ = try await migrationManager.migrate(to: 1)

        // Then migrate to v2 (should execute custom step)
        let result = try await migrationManager.migrate(to: 2)

        XCTAssertTrue(result.success, "Custom migration should succeed")
        XCTAssertTrue(migrationExecuted, "Custom migration should be executed")

        // Verify the person was added
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person after migration")
        XCTAssertEqual(people.first?.name, "Migrated User", "Person should have correct name")
    }

    // MARK: - Test 4: Migration Validation

    func testMigrationValidation() async throws {
        // Migrate to v1
        let result = try await migrationManager.migrate(to: 1)

        XCTAssertTrue(result.success, "Migration should succeed")

        // Validate database
        let errors = try await migrationManager.validateDatabase()
        XCTAssertTrue(errors.isEmpty, "Database should be valid after migration")
    }

    func testValidationWithData() async throws {
        // Add some data before migration
        let person = PersonModel(name: "Test Person", email: "test@example.com")
        modelContext.insert(person)

        let subscription = SubscriptionModel(
            name: "Test Sub",
            amount: 9.99,
            cycle: "monthly",
            personId: person.id
        )
        modelContext.insert(subscription)

        try modelContext.save()

        // Perform migration
        _ = try await migrationManager.migrate(to: 1)

        // Validate
        let errors = try await migrationManager.validateDatabase()
        XCTAssertTrue(errors.isEmpty, "Database with existing data should be valid")

        // Verify data still exists
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should still have 1 person")
    }

    // MARK: - Test 5: Backup Creation

    func testBackupCreation() async throws {
        // Perform migration (which creates backup)
        let result = try await migrationManager.migrate(to: 1)

        XCTAssertTrue(result.success, "Migration should succeed")
        XCTAssertNotNil(result.backupPath, "Backup should be created")

        if let backupPath = result.backupPath {
            XCTAssertTrue(backupPath.contains("MigrationBackups"), "Backup should be in MigrationBackups folder")
            XCTAssertTrue(backupPath.contains("pre_migration_v0"), "Backup should have correct naming")
        }
    }

    // MARK: - Test 6: Migration Statistics

    func testStatisticsTracking() async throws {
        // Reset statistics
        migrationManager.resetStatistics()

        var stats = migrationManager.getStatistics()
        XCTAssertEqual(stats.totalMigrations, 0, "Should start with 0 migrations")

        // Perform migration
        _ = try await migrationManager.migrate(to: 1)

        stats = migrationManager.getStatistics()
        XCTAssertEqual(stats.totalMigrations, 1, "Should have 1 migration")
        XCTAssertEqual(stats.successfulMigrations, 1, "Should have 1 successful migration")
        XCTAssertEqual(stats.successRate, 1.0, "Success rate should be 100%")
        XCTAssertNotNil(stats.lastMigrationDate, "Last migration date should be set")
        XCTAssertEqual(stats.lastMigrationVersion, 1, "Last version should be 1")
    }

    func testStatisticsPersistence() async throws {
        // Perform migration
        _ = try await migrationManager.migrate(to: 1)

        // Create new manager (should load statistics)
        let newManager = DataMigrationManager(modelContext: modelContext)
        let stats = newManager.getStatistics()

        XCTAssertEqual(stats.totalMigrations, 1, "Statistics should persist")
        XCTAssertEqual(stats.successfulMigrations, 1, "Successful count should persist")
    }

    // MARK: - Test 7: Rollback Support

    func testRollbackNotNeeded() async throws {
        // At version 0, rollback to 0 should do nothing
        try await migrationManager.rollback(to: 0)

        XCTAssertEqual(migrationManager.getCurrentVersion(), 0, "Version should still be 0")
    }

    func testRollbackWithCustomStep() async throws {
        var rollbackExecuted = false

        let customStep = MigrationStep(
            from: 1,
            to: 2,
            description: "Reversible migration",
            migrate: { context in
                let person = PersonModel(name: "To Be Removed", email: "temp@example.com")
                context.insert(person)
                try context.save()
            },
            rollback: { context in
                rollbackExecuted = true

                // Remove the person
                let descriptor = FetchDescriptor<PersonModel>(
                    predicate: #Predicate { $0.name == "To Be Removed" }
                )
                let people = try context.fetch(descriptor)
                for person in people {
                    context.delete(person)
                }
                try context.save()
            }
        )

        migrationManager.registerMigrationStep(customStep)

        // Migrate to v2
        _ = try await migrationManager.migrate(to: 1)
        _ = try await migrationManager.migrate(to: 2)

        XCTAssertEqual(migrationManager.getCurrentVersion(), 2, "Should be at version 2")

        // Verify person exists
        var descriptor = FetchDescriptor<PersonModel>()
        var people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 1, "Should have 1 person")

        // Rollback to v1
        try await migrationManager.rollback(to: 1)

        XCTAssertTrue(rollbackExecuted, "Rollback should be executed")
        XCTAssertEqual(migrationManager.getCurrentVersion(), 1, "Should be back at version 1")

        // Verify person was removed
        descriptor = FetchDescriptor<PersonModel>()
        people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 0, "Person should be removed after rollback")
    }

    // MARK: - Test 8: Dry Run

    func testDryRunMigration() async throws {
        let steps = try await migrationManager.dryRunMigration(to: 1)

        XCTAssertEqual(steps.count, 1, "Should have 1 step")
        XCTAssertTrue(steps[0].contains("Initialize database schema"), "Should describe step")

        // Verify version not changed
        XCTAssertEqual(migrationManager.getCurrentVersion(), 0, "Version should still be 0 after dry run")
    }

    func testDryRunMultipleSteps() async throws {
        // Register additional steps
        migrationManager.registerMigrationStep(MigrationStep(
            from: 1,
            to: 2,
            description: "Add premium features",
            migrate: { _ in }
        ))

        let steps = try await migrationManager.dryRunMigration(to: 2)

        XCTAssertEqual(steps.count, 2, "Should have 2 steps")
        XCTAssertTrue(steps[1].contains("Add premium features"), "Should describe second step")
    }

    // MARK: - Test 9: Migration Info

    func testGetMigrationInfo() {
        let info = migrationManager.getMigrationInfo()

        XCTAssertTrue(info.contains("Migration needed"), "Should indicate migration needed")
        XCTAssertTrue(info.contains("v0"), "Should show current version")
        XCTAssertTrue(info.contains("v\(DataMigrationManager.currentVersion)"), "Should show target version")
    }

    func testGetAvailableMigrations() {
        let migrations = migrationManager.getAvailableMigrations()

        XCTAssertFalse(migrations.isEmpty, "Should have at least one migration")
        XCTAssertTrue(migrations[0].contains("v0 → v1"), "Should show version transition")
        XCTAssertTrue(migrations[0].contains("Initialize database schema"), "Should show description")
    }

    func testExportMigrationReport() {
        let report = migrationManager.exportMigrationReport()

        XCTAssertTrue(report.contains("Swiff Migration Report"), "Should have title")
        XCTAssertTrue(report.contains("Current Version"), "Should show current version")
        XCTAssertTrue(report.contains("Statistics"), "Should include statistics")
        XCTAssertTrue(report.contains("Available Migrations"), "Should list migrations")
    }

    // MARK: - Test 10: Error Handling

    func testMigrationAlreadyInProgress() async throws {
        // Start a long-running migration
        let slowStep = MigrationStep(
            from: 1,
            to: 2,
            description: "Slow migration",
            migrate: { _ in
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        )

        migrationManager.registerMigrationStep(slowStep)

        // Migrate to v1 first
        _ = try await migrationManager.migrate(to: 1)

        // Start migration to v2
        Task {
            _ = try? await migrationManager.migrate(to: 2)
        }

        // Small delay to ensure first migration starts
        try await Task.sleep(nanoseconds: 10_000_000)

        // Try to start another migration
        do {
            _ = try await migrationManager.migrate(to: 2)
            XCTFail("Should throw migrationAlreadyInProgress error")
        } catch MigrationError.migrationAlreadyInProgress {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testUnsupportedMigration() async throws {
        // Try to migrate to a version without a defined step
        do {
            _ = try await migrationManager.migrate(to: 5, from: 4)
            XCTFail("Should throw unsupportedMigration error")
        } catch MigrationError.unsupportedMigration(let from, let to) {
            XCTAssertEqual(from, 4, "Should report correct from version")
            XCTAssertEqual(to, 5, "Should report correct to version")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidVersion() {
        do {
            _ = try MigrationVersion(versionString: "invalid")
            XCTFail("Should throw invalidVersion error")
        } catch MigrationError.invalidVersion(let version) {
            XCTAssertEqual(version, "invalid", "Should report invalid version string")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Test 11: MigrationVersion Struct

    func testMigrationVersionCreation() throws {
        let v1 = MigrationVersion(major: 1, minor: 2, patch: 3)
        XCTAssertEqual(v1.versionString, "1.2.3", "Version string should be formatted correctly")
        XCTAssertEqual(v1.versionNumber, 1, "Version number should be major version")

        let v2 = try MigrationVersion(versionString: "2.0.1")
        XCTAssertEqual(v2.major, 2, "Major should be 2")
        XCTAssertEqual(v2.minor, 0, "Minor should be 0")
        XCTAssertEqual(v2.patch, 1, "Patch should be 1")
    }

    func testMigrationVersionComparison() {
        let v1 = MigrationVersion(major: 1, minor: 0, patch: 0)
        let v2 = MigrationVersion(major: 2, minor: 0, patch: 0)
        let v1_1 = MigrationVersion(major: 1, minor: 1, patch: 0)
        let v1_0_1 = MigrationVersion(major: 1, minor: 0, patch: 1)

        XCTAssertTrue(v1 < v2, "v1 should be less than v2")
        XCTAssertTrue(v1 < v1_1, "v1.0.0 should be less than v1.1.0")
        XCTAssertTrue(v1 < v1_0_1, "v1.0.0 should be less than v1.0.1")
        XCTAssertFalse(v2 < v1, "v2 should not be less than v1")
        XCTAssertTrue(v1 == v1, "Version should equal itself")
    }

    // MARK: - Test 12: Edge Cases

    func testMigrationWithEmptyDatabase() async throws {
        // Empty database should migrate successfully
        let result = try await migrationManager.migrate(to: 1)

        XCTAssertTrue(result.success, "Empty database should migrate")
        XCTAssertEqual(result.errors.count, 0, "Should have no errors")
    }

    func testMigrationWithLargeDataset() async throws {
        // Add many entities
        for i in 0..<100 {
            let person = PersonModel(name: "Person \(i)", email: "person\(i)@example.com")
            modelContext.insert(person)
        }
        try modelContext.save()

        // Migrate
        let result = try await migrationManager.migrate(to: 1)

        XCTAssertTrue(result.success, "Large dataset should migrate")

        // Verify all data still exists
        let descriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(descriptor)
        XCTAssertEqual(people.count, 100, "All people should still exist")
    }

    func testConcurrentMigrationPrevention() async throws {
        XCTAssertFalse(migrationManager.isInProgress, "Should not be in progress initially")

        // Migration state is tested in testMigrationAlreadyInProgress
        // This just verifies the property exists
    }
}
