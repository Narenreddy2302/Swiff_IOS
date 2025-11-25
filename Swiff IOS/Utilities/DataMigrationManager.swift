//
//  DataMigrationManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 4.3: Data migration framework with version detection and rollback
//

import Foundation
import SwiftData

// MARK: - Migration Error

enum MigrationError: LocalizedError {
    case versionNotFound
    case invalidVersion(String)
    case migrationFailed(String)
    case rollbackFailed(String)
    case incompatibleVersion(current: Int, target: Int)
    case migrationAlreadyInProgress
    case noMigrationNeeded
    case backupFailed(String)
    case validationFailed([String])
    case unsupportedMigration(from: Int, to: Int)

    var errorDescription: String? {
        switch self {
        case .versionNotFound:
            return "Database version not found"
        case .invalidVersion(let version):
            return "Invalid version format: '\(version)'"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .rollbackFailed(let reason):
            return "Rollback failed: \(reason)"
        case .incompatibleVersion(let current, let target):
            return "Cannot migrate from version \(current) to \(target)"
        case .migrationAlreadyInProgress:
            return "Migration already in progress"
        case .noMigrationNeeded:
            return "Database is already at target version"
        case .backupFailed(let reason):
            return "Pre-migration backup failed: \(reason)"
        case .validationFailed(let errors):
            return "Migration validation failed: \(errors.joined(separator: ", "))"
        case .unsupportedMigration(let from, let to):
            return "Migration from version \(from) to \(to) is not supported"
        }
    }
}

// MARK: - Migration Version

struct MigrationVersion: Codable, Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    var versionNumber: Int {
        return major
    }

    var versionString: String {
        return "\(major).\(minor).\(patch)"
    }

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(versionString: String) throws {
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 1 else {
            throw MigrationError.invalidVersion(versionString)
        }

        self.major = components[0]
        self.minor = components.count > 1 ? components[1] : 0
        self.patch = components.count > 2 ? components[2] : 0
    }

    static func < (lhs: MigrationVersion, rhs: MigrationVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

// MARK: - Migration Step

struct MigrationStep {
    let fromVersion: Int
    let toVersion: Int
    let description: String
    let migrate: (ModelContext) async throws -> Void
    let rollback: ((ModelContext) async throws -> Void)?

    init(
        from: Int,
        to: Int,
        description: String,
        migrate: @escaping (ModelContext) async throws -> Void,
        rollback: ((ModelContext) async throws -> Void)? = nil
    ) {
        self.fromVersion = from
        self.toVersion = to
        self.description = description
        self.migrate = migrate
        self.rollback = rollback
    }
}

// MARK: - Migration Result

struct MigrationResult {
    let success: Bool
    let fromVersion: Int
    let toVersion: Int
    let duration: TimeInterval
    let errors: [String]
    let backupPath: String?

    var summary: String {
        if success {
            return "Successfully migrated from v\(fromVersion) to v\(toVersion) in \(String(format: "%.2f", duration))s"
        } else {
            return "Migration from v\(fromVersion) to v\(toVersion) failed: \(errors.joined(separator: ", "))"
        }
    }
}

// MARK: - Migration Statistics

struct MigrationStatistics: Codable {
    var totalMigrations: Int = 0
    var successfulMigrations: Int = 0
    var failedMigrations: Int = 0
    var lastMigrationDate: Date?
    var lastMigrationVersion: Int?
    var totalMigrationTime: TimeInterval = 0

    var successRate: Double {
        guard totalMigrations > 0 else { return 0 }
        return Double(successfulMigrations) / Double(totalMigrations)
    }

    var averageMigrationTime: TimeInterval {
        guard totalMigrations > 0 else { return 0 }
        return totalMigrationTime / Double(totalMigrations)
    }

    mutating func recordMigration(success: Bool, duration: TimeInterval, toVersion: Int) {
        totalMigrations += 1

        if success {
            successfulMigrations += 1
            lastMigrationDate = Date()
            lastMigrationVersion = toVersion
        } else {
            failedMigrations += 1
        }

        totalMigrationTime += duration
    }
}

// MARK: - Data Migration Manager

@MainActor
class DataMigrationManager {

    // Current schema version
    static let currentVersion = 1

    private let modelContext: ModelContext
    private var isMigrating: Bool = false
    private var migrationSteps: [MigrationStep] = []
    private var statistics: MigrationStatistics

    // UserDefaults keys
    private let versionKey = "SwiffDatabaseVersion"
    private let statisticsKey = "SwiffMigrationStatistics"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Load statistics
        if let data = UserDefaults.standard.data(forKey: statisticsKey),
           let stats = try? JSONDecoder().decode(MigrationStatistics.self, from: data) {
            self.statistics = stats
        } else {
            self.statistics = MigrationStatistics()
        }

        // Register migration steps
        registerMigrationSteps()
    }

    // MARK: - Version Management

    /// Get current database version
    func getCurrentVersion() -> Int {
        return UserDefaults.standard.integer(forKey: versionKey)
    }

    /// Set database version
    private func setVersion(_ version: Int) {
        UserDefaults.standard.set(version, forKey: versionKey)
    }

    /// Check if migration is needed
    func needsMigration() -> Bool {
        let current = getCurrentVersion()
        return current < Self.currentVersion
    }

    /// Get migration path (list of versions to migrate through)
    func getMigrationPath(from: Int, to: Int) -> [Int] {
        guard from < to else { return [] }
        return Array((from + 1)...to)
    }

    // MARK: - Migration Registration

    /// Register all migration steps
    private func registerMigrationSteps() {
        // Migration from v0 (no database) to v1 (initial schema)
        migrationSteps.append(MigrationStep(
            from: 0,
            to: 1,
            description: "Initialize database schema",
            migrate: { context in
                // Initial schema is automatically created by SwiftData
                // No data transformation needed
            },
            rollback: { context in
                // Cannot rollback initial schema creation
            }
        ))

        // Example: Migration from v1 to v2 (future migration)
        // Uncomment and modify when v2 is needed
        /*
        migrationSteps.append(MigrationStep(
            from: 1,
            to: 2,
            description: "Add new fields to Person model",
            migrate: { context in
                // Add migration logic here
                let descriptor = FetchDescriptor<PersonModel>()
                let people = try context.fetch(descriptor)

                for person in people {
                    // Transform data
                    // person.newField = defaultValue
                }

                try context.save()
            },
            rollback: { context in
                // Rollback logic
                let descriptor = FetchDescriptor<PersonModel>()
                let people = try context.fetch(descriptor)

                for person in people {
                    // Revert changes
                    // person.newField = nil
                }

                try context.save()
            }
        ))
        */
    }

    /// Register custom migration step
    func registerMigrationStep(_ step: MigrationStep) {
        migrationSteps.append(step)
        migrationSteps.sort { $0.fromVersion < $1.fromVersion }
    }

    // MARK: - Migration Execution

    /// Perform migration to latest version
    func migrate() async throws -> MigrationResult {
        let currentVersion = getCurrentVersion()
        return try await migrate(to: Self.currentVersion, from: currentVersion)
    }

    /// Perform migration to specific version
    func migrate(to targetVersion: Int, from sourceVersion: Int? = nil) async throws -> MigrationResult {
        guard !isMigrating else {
            throw MigrationError.migrationAlreadyInProgress
        }

        let fromVersion = sourceVersion ?? getCurrentVersion()

        guard fromVersion < targetVersion else {
            throw MigrationError.noMigrationNeeded
        }

        isMigrating = true
        let startTime = Date()
        var errors: [String] = []
        var backupPath: String?

        defer {
            isMigrating = false
        }

        do {
            // Create backup before migration
            backupPath = try await createPreMigrationBackup(version: fromVersion)

            // Get migration path
            let path = getMigrationPath(from: fromVersion, to: targetVersion)

            // Execute each migration step
            for version in path {
                let step = migrationSteps.first { $0.toVersion == version }

                guard let step = step else {
                    throw MigrationError.unsupportedMigration(from: version - 1, to: version)
                }

                // Execute migration
                try await step.migrate(modelContext)

                // Update version after successful step
                setVersion(version)
            }

            // Validate migration
            let validationErrors = try await validateMigration(toVersion: targetVersion)

            if !validationErrors.isEmpty {
                throw MigrationError.validationFailed(validationErrors)
            }

            // Calculate duration
            let duration = Date().timeIntervalSince(startTime)

            // Record success
            statistics.recordMigration(success: true, duration: duration, toVersion: targetVersion)
            saveStatistics()

            return MigrationResult(
                success: true,
                fromVersion: fromVersion,
                toVersion: targetVersion,
                duration: duration,
                errors: [],
                backupPath: backupPath
            )

        } catch {
            errors.append(error.localizedDescription)

            // Attempt rollback
            do {
                try await rollback(to: fromVersion)
            } catch {
                errors.append("Rollback failed: \(error.localizedDescription)")
            }

            let duration = Date().timeIntervalSince(startTime)

            // Record failure
            statistics.recordMigration(success: false, duration: duration, toVersion: targetVersion)
            saveStatistics()

            return MigrationResult(
                success: false,
                fromVersion: fromVersion,
                toVersion: targetVersion,
                duration: duration,
                errors: errors,
                backupPath: backupPath
            )
        }
    }

    // MARK: - Rollback

    /// Rollback to specific version
    func rollback(to targetVersion: Int) async throws {
        let currentVersion = getCurrentVersion()

        guard currentVersion > targetVersion else {
            return // Already at or below target version
        }

        // Get reverse migration path
        let path = Array((targetVersion + 1)...currentVersion).reversed()

        // Execute rollback steps
        for version in path {
            let step = migrationSteps.first { $0.toVersion == version }

            guard let step = step, let rollback = step.rollback else {
                throw MigrationError.rollbackFailed("No rollback available for version \(version)")
            }

            try await rollback(modelContext)

            // Update version after successful rollback
            setVersion(version - 1)
        }
    }

    // MARK: - Backup

    /// Create pre-migration backup
    private func createPreMigrationBackup(version: Int) async throws -> String {
        let fileManager = FileManager.default

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw MigrationError.backupFailed("Cannot access documents directory")
        }

        // Create migration backups directory
        let backupsURL = documentsURL.appendingPathComponent("MigrationBackups")

        if !fileManager.fileExists(atPath: backupsURL.path) {
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        }

        // Create backup with timestamp
        let timestamp = Date().timeIntervalSince1970
        let backupFilename = "pre_migration_v\(version)_\(Int(timestamp)).backup"
        let backupURL = backupsURL.appendingPathComponent(backupFilename)

        // Get database files
        let storeURL = documentsURL.appendingPathComponent("default.store")

        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.copyItem(at: storeURL, to: backupURL)
        }

        return backupURL.path
    }

    // MARK: - Validation

    /// Validate migration completed successfully
    private func validateMigration(toVersion: Int) async throws -> [String] {
        var errors: [String] = []

        // Check version was updated
        let currentVersion = getCurrentVersion()
        if currentVersion != toVersion {
            errors.append("Version mismatch: expected \(toVersion), got \(currentVersion)")
        }

        // Validate data integrity
        do {
            // Check all entities can be fetched
            let personDescriptor = FetchDescriptor<PersonModel>()
            _ = try modelContext.fetch(personDescriptor)

            let groupDescriptor = FetchDescriptor<GroupModel>()
            _ = try modelContext.fetch(groupDescriptor)

            let subscriptionDescriptor = FetchDescriptor<SubscriptionModel>()
            _ = try modelContext.fetch(subscriptionDescriptor)

            let transactionDescriptor = FetchDescriptor<TransactionModel>()
            _ = try modelContext.fetch(transactionDescriptor)

        } catch {
            errors.append("Data integrity check failed: \(error.localizedDescription)")
        }

        return errors
    }

    /// Comprehensive database validation
    func validateDatabase() async throws -> [String] {
        var errors: [String] = []

        // Check foreign key integrity
        let validator = ForeignKeyValidator(modelContext: modelContext)
        let fkErrors = try validator.validateAllForeignKeys()
        errors.append(contentsOf: fkErrors)

        // Check for orphaned records
        let orphanResult = try validator.detectAllOrphans()
        if orphanResult.hasOrphans {
            errors.append(orphanResult.summary)
        }

        // Validate business rules
        do {
            let subscriptionDescriptor = FetchDescriptor<SubscriptionModel>()
            let subscriptions = try modelContext.fetch(subscriptionDescriptor)

            for subscription in subscriptions {
                // Validate subscription has valid person
                if let personId = subscription.personId {
                    do {
                        try validator.validatePersonExists(personId)
                    } catch {
                        errors.append("Invalid subscription: \(subscription.name) references non-existent person")
                    }
                }
            }
        } catch {
            errors.append("Subscription validation failed: \(error.localizedDescription)")
        }

        return errors
    }

    // MARK: - Statistics

    /// Get migration statistics
    func getStatistics() -> MigrationStatistics {
        return statistics
    }

    /// Reset statistics
    func resetStatistics() {
        statistics = MigrationStatistics()
        saveStatistics()
    }

    /// Save statistics to UserDefaults
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: statisticsKey)
        }
    }

    // MARK: - Migration Info

    /// Get migration info
    func getMigrationInfo() -> String {
        let current = getCurrentVersion()
        let target = Self.currentVersion

        if current == target {
            return "Database is up to date (v\(current))"
        } else {
            let path = getMigrationPath(from: current, to: target)
            return "Migration needed: v\(current) → v\(target) (through \(path.count) step(s))"
        }
    }

    /// Get available migrations
    func getAvailableMigrations() -> [String] {
        return migrationSteps.map { step in
            "v\(step.fromVersion) → v\(step.toVersion): \(step.description)"
        }
    }

    // MARK: - State Queries

    /// Check if migration is in progress
    var isInProgress: Bool {
        return isMigrating
    }
}

// MARK: - Migration Extensions

extension DataMigrationManager {

    /// Perform dry run migration (no actual changes)
    func dryRunMigration(to targetVersion: Int) async throws -> [String] {
        var steps: [String] = []

        let fromVersion = getCurrentVersion()
        let path = getMigrationPath(from: fromVersion, to: targetVersion)

        for version in path {
            if let step = migrationSteps.first(where: { $0.toVersion == version }) {
                steps.append("Step \(version): \(step.description)")
            } else {
                steps.append("Step \(version): [No migration defined]")
            }
        }

        return steps
    }

    /// Export migration report
    func exportMigrationReport() -> String {
        var report = "=== Swiff Migration Report ===\n\n"

        report += "Current Version: \(getCurrentVersion())\n"
        report += "Target Version: \(Self.currentVersion)\n"
        report += "Migration Needed: \(needsMigration() ? "Yes" : "No")\n\n"

        report += "=== Statistics ===\n"
        report += "Total Migrations: \(statistics.totalMigrations)\n"
        report += "Successful: \(statistics.successfulMigrations)\n"
        report += "Failed: \(statistics.failedMigrations)\n"
        report += "Success Rate: \(String(format: "%.1f%%", statistics.successRate * 100))\n"
        report += "Average Duration: \(String(format: "%.2f", statistics.averageMigrationTime))s\n"

        if let lastDate = statistics.lastMigrationDate {
            report += "Last Migration: \(lastDate.formatted())\n"
        }

        if let lastVersion = statistics.lastMigrationVersion {
            report += "Last Version: v\(lastVersion)\n"
        }

        report += "\n=== Available Migrations ===\n"
        for migration in getAvailableMigrations() {
            report += "- \(migration)\n"
        }

        return report
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Check if migration is needed:
 ```swift
 let migrationManager = DataMigrationManager(modelContext: context)

 if migrationManager.needsMigration() {
     print(migrationManager.getMigrationInfo())
 }
 ```

 2. Perform migration:
 ```swift
 do {
     let result = try await migrationManager.migrate()

     if result.success {
         print(result.summary)
         print("Backup: \(result.backupPath ?? "N/A")")
     } else {
         print("Migration failed:")
         for error in result.errors {
             print("- \(error)")
         }
     }
 } catch {
     print("Migration error: \(error)")
 }
 ```

 3. Dry run to preview migration:
 ```swift
 let steps = try await migrationManager.dryRunMigration(to: 3)
 print("Migration steps:")
 for step in steps {
     print(step)
 }
 ```

 4. Validate database after migration:
 ```swift
 let errors = try await migrationManager.validateDatabase()

 if errors.isEmpty {
     print("Database is valid")
 } else {
     print("Validation errors:")
     for error in errors {
         print("- \(error)")
     }
 }
 ```

 5. Register custom migration:
 ```swift
 let customMigration = MigrationStep(
     from: 2,
     to: 3,
     description: "Add premium features",
     migrate: { context in
         // Migration logic
     },
     rollback: { context in
         // Rollback logic
     }
 )

 migrationManager.registerMigrationStep(customMigration)
 ```

 6. Get migration statistics:
 ```swift
 let stats = migrationManager.getStatistics()
 print("Success rate: \(stats.successRate * 100)%")
 print("Average time: \(stats.averageMigrationTime)s")
 ```

 7. Export migration report:
 ```swift
 let report = migrationManager.exportMigrationReport()
 print(report)
 ```
 */
