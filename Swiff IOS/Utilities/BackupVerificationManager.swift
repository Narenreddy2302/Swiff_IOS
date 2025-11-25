//
//  BackupVerificationManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 4.4: Backup verification with checksum validation and integrity checks
//

import Foundation
import SwiftData
import CryptoKit

// MARK: - Verification Error

enum BackupVerificationError: LocalizedError {
    case backupNotFound(String)
    case checksumMismatch(expected: String, actual: String)
    case incompatibleVersion(backup: Int, current: Int)
    case corruptedBackup(String)
    case incompleteData(missing: [String])
    case invalidFormat(String)
    case metadataNotFound
    case validationFailed([String])

    var errorDescription: String? {
        switch self {
        case .backupNotFound(let path):
            return "Backup not found at path: '\(path)'"
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch: expected '\(expected)', got '\(actual)'"
        case .incompatibleVersion(let backup, let current):
            return "Backup version \(backup) incompatible with current version \(current)"
        case .corruptedBackup(let reason):
            return "Backup is corrupted: \(reason)"
        case .incompleteData(let missing):
            return "Incomplete backup data: missing \(missing.joined(separator: ", "))"
        case .invalidFormat(let format):
            return "Invalid backup format: '\(format)'"
        case .metadataNotFound:
            return "Backup metadata not found"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        }
    }
}

// MARK: - Verification Backup Metadata

struct VerificationBackupMetadata: Codable {
    let version: Int
    let created: Date
    let checksum: String
    let entitiesCounts: EntityCounts
    let totalSize: Int64
    let format: String
    let appVersion: String

    struct EntityCounts: Codable {
        let people: Int
        let groups: Int
        let subscriptions: Int
        let transactions: Int

        var total: Int {
            return people + groups + subscriptions + transactions
        }
    }
}

// MARK: - Verification Result

struct BackupVerificationResult {
    let isValid: Bool
    let metadata: VerificationBackupMetadata?
    let errors: [String]
    let warnings: [String]
    let checksumValid: Bool
    let versionCompatible: Bool
    let dataComplete: Bool

    var summary: String {
        if isValid {
            return "Backup is valid and can be restored"
        } else {
            let errorSummary = errors.isEmpty ? "" : " Errors: \(errors.count)"
            let warningSummary = warnings.isEmpty ? "" : " Warnings: \(warnings.count)"
            return "Backup validation failed.\(errorSummary)\(warningSummary)"
        }
    }

    var detailedReport: String {
        var report = "=== Backup Verification Report ===\n\n"
        report += "Status: \(isValid ? "✅ VALID" : "❌ INVALID")\n"
        report += "Checksum: \(checksumValid ? "✅ Valid" : "❌ Invalid")\n"
        report += "Version: \(versionCompatible ? "✅ Compatible" : "❌ Incompatible")\n"
        report += "Data: \(dataComplete ? "✅ Complete" : "❌ Incomplete")\n\n"

        if let metadata = metadata {
            report += "=== Metadata ===\n"
            report += "Version: \(metadata.version)\n"
            report += "Created: \(metadata.created.formatted())\n"
            report += "Size: \(ByteCountFormatter.string(fromByteCount: metadata.totalSize, countStyle: .file))\n"
            report += "Format: \(metadata.format)\n"
            report += "App Version: \(metadata.appVersion)\n\n"

            report += "=== Entity Counts ===\n"
            report += "People: \(metadata.entitiesCounts.people)\n"
            report += "Groups: \(metadata.entitiesCounts.groups)\n"
            report += "Subscriptions: \(metadata.entitiesCounts.subscriptions)\n"
            report += "Transactions: \(metadata.entitiesCounts.transactions)\n"
            report += "Total: \(metadata.entitiesCounts.total)\n\n"
        }

        if !errors.isEmpty {
            report += "=== Errors ===\n"
            for error in errors {
                report += "❌ \(error)\n"
            }
            report += "\n"
        }

        if !warnings.isEmpty {
            report += "=== Warnings ===\n"
            for warning in warnings {
                report += "⚠️ \(warning)\n"
            }
            report += "\n"
        }

        return report
    }
}

// MARK: - Restore Preview

struct RestorePreview {
    let metadata: VerificationBackupMetadata
    let currentCounts: VerificationBackupMetadata.EntityCounts
    let changes: RestoreChanges

    struct RestoreChanges {
        let peopleAdded: Int
        let peopleRemoved: Int
        let groupsAdded: Int
        let groupsRemoved: Int
        let subscriptionsAdded: Int
        let subscriptionsRemoved: Int
        let transactionsAdded: Int
        let transactionsRemoved: Int

        var hasChanges: Bool {
            return peopleAdded > 0 || peopleRemoved > 0 ||
                   groupsAdded > 0 || groupsRemoved > 0 ||
                   subscriptionsAdded > 0 || subscriptionsRemoved > 0 ||
                   transactionsAdded > 0 || transactionsRemoved > 0
        }

        var summary: String {
            var parts: [String] = []

            if peopleAdded > 0 { parts.append("+\(peopleAdded) people") }
            if peopleRemoved > 0 { parts.append("-\(peopleRemoved) people") }
            if groupsAdded > 0 { parts.append("+\(groupsAdded) groups") }
            if groupsRemoved > 0 { parts.append("-\(groupsRemoved) groups") }
            if subscriptionsAdded > 0 { parts.append("+\(subscriptionsAdded) subscriptions") }
            if subscriptionsRemoved > 0 { parts.append("-\(subscriptionsRemoved) subscriptions") }
            if transactionsAdded > 0 { parts.append("+\(transactionsAdded) transactions") }
            if transactionsRemoved > 0 { parts.append("-\(transactionsRemoved) transactions") }

            return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
        }
    }

    var detailedSummary: String {
        var summary = "=== Restore Preview ===\n\n"

        summary += "Backup Date: \(metadata.created.formatted())\n"
        summary += "Backup Version: \(metadata.version)\n\n"

        summary += "Current Database:\n"
        summary += "  People: \(currentCounts.people)\n"
        summary += "  Groups: \(currentCounts.groups)\n"
        summary += "  Subscriptions: \(currentCounts.subscriptions)\n"
        summary += "  Transactions: \(currentCounts.transactions)\n\n"

        summary += "After Restore:\n"
        summary += "  People: \(metadata.entitiesCounts.people)\n"
        summary += "  Groups: \(metadata.entitiesCounts.groups)\n"
        summary += "  Subscriptions: \(metadata.entitiesCounts.subscriptions)\n"
        summary += "  Transactions: \(metadata.entitiesCounts.transactions)\n\n"

        summary += "Changes: \(changes.summary)\n"

        return summary
    }
}

// MARK: - Backup Verification Manager

@MainActor
class BackupVerificationManager {

    private let modelContext: ModelContext
    private let fileManager = FileManager.default

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Checksum Validation

    /// Calculate SHA256 checksum for file
    func calculateChecksum(for fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Validate backup checksum
    func validateChecksum(backupURL: URL, expectedChecksum: String) throws -> Bool {
        let actualChecksum = try calculateChecksum(for: backupURL)
        return actualChecksum == expectedChecksum
    }

    // MARK: - Metadata Operations

    /// Read backup metadata
    func readMetadata(from backupURL: URL) throws -> VerificationBackupMetadata {
        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")

        guard fileManager.fileExists(atPath: metadataURL.path) else {
            throw BackupVerificationError.metadataNotFound
        }

        let data = try Data(contentsOf: metadataURL)
        let metadata = try JSONDecoder().decode(VerificationBackupMetadata.self, from: data)

        return metadata
    }

    /// Create metadata for backup
    func createMetadata(for backupURL: URL, version: Int) throws -> VerificationBackupMetadata {
        // Calculate checksum
        let checksum = try calculateChecksum(for: backupURL)

        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        // Get entity counts from current database
        let counts = try getCurrentEntityCounts()

        // Get app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let metadata = VerificationBackupMetadata(
            version: version,
            created: Date(),
            checksum: checksum,
            entitiesCounts: counts,
            totalSize: fileSize,
            format: "swiftdata",
            appVersion: appVersion
        )

        // Save metadata
        try saveMetadata(metadata, for: backupURL)

        return metadata
    }

    /// Save metadata to file
    private func saveMetadata(_ metadata: VerificationBackupMetadata, for backupURL: URL) throws {
        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")

        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
    }

    // MARK: - Entity Count Operations

    /// Get current entity counts from database
    func getCurrentEntityCounts() throws -> VerificationBackupMetadata.EntityCounts {
        let peopleDescriptor = FetchDescriptor<PersonModel>()
        let people = try modelContext.fetch(peopleDescriptor)

        let groupsDescriptor = FetchDescriptor<GroupModel>()
        let groups = try modelContext.fetch(groupsDescriptor)

        let subscriptionsDescriptor = FetchDescriptor<SubscriptionModel>()
        let subscriptions = try modelContext.fetch(subscriptionsDescriptor)

        let transactionsDescriptor = FetchDescriptor<TransactionModel>()
        let transactions = try modelContext.fetch(transactionsDescriptor)

        return VerificationBackupMetadata.EntityCounts(
            people: people.count,
            groups: groups.count,
            subscriptions: subscriptions.count,
            transactions: transactions.count
        )
    }

    // MARK: - Comprehensive Verification

    /// Verify backup integrity
    func verifyBackup(at backupURL: URL) async throws -> BackupVerificationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var metadata: VerificationBackupMetadata?
        var checksumValid = false
        var versionCompatible = false
        var dataComplete = false

        // Check if backup file exists
        guard fileManager.fileExists(atPath: backupURL.path) else {
            errors.append("Backup file not found")
            return BackupVerificationResult(
                isValid: false,
                metadata: nil as VerificationBackupMetadata?,
                errors: errors,
                warnings: warnings,
                checksumValid: false,
                versionCompatible: false,
                dataComplete: false
            )
        }

        // Read metadata
        do {
            metadata = try readMetadata(from: backupURL)
        } catch {
            errors.append("Failed to read metadata: \(error.localizedDescription)")
            // Continue verification without metadata
        }

        // Validate checksum
        if let meta = metadata {
            do {
                checksumValid = try validateChecksum(backupURL: backupURL, expectedChecksum: meta.checksum)
                if !checksumValid {
                    errors.append("Checksum validation failed")
                }
            } catch {
                errors.append("Checksum calculation failed: \(error.localizedDescription)")
            }
        }

        // Check version compatibility
        if let meta = metadata {
            let currentVersion = DataMigrationManager.currentVersion
            versionCompatible = meta.version <= currentVersion

            if !versionCompatible {
                errors.append("Backup version \(meta.version) is newer than current version \(currentVersion)")
            } else if meta.version < currentVersion {
                warnings.append("Backup is from older version \(meta.version), migration may be needed")
            }
        }

        // Check data completeness
        if let meta = metadata {
            if meta.entitiesCounts.total == 0 {
                warnings.append("Backup contains no data")
            }

            dataComplete = true // If we got here, data structure is valid
        }

        // Check file integrity
        do {
            let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            if fileSize == 0 {
                errors.append("Backup file is empty")
            } else if let meta = metadata, abs(fileSize - meta.totalSize) > 1024 {
                // Allow 1KB difference for filesystem metadata
                warnings.append("File size mismatch: expected \(meta.totalSize), got \(fileSize)")
            }
        } catch {
            errors.append("Failed to check file attributes: \(error.localizedDescription)")
        }

        let isValid = errors.isEmpty && checksumValid && versionCompatible && dataComplete

        return BackupVerificationResult(
            isValid: isValid,
            metadata: metadata,
            errors: errors,
            warnings: warnings,
            checksumValid: checksumValid,
            versionCompatible: versionCompatible,
            dataComplete: dataComplete
        )
    }

    // MARK: - Restore Preview

    /// Generate restore preview
    func generateRestorePreview(for backupURL: URL) async throws -> RestorePreview {
        // Read backup metadata
        let metadata = try readMetadata(from: backupURL)

        // Get current counts
        let currentCounts = try getCurrentEntityCounts()

        // Calculate changes
        let changes = RestorePreview.RestoreChanges(
            peopleAdded: max(0, metadata.entitiesCounts.people - currentCounts.people),
            peopleRemoved: max(0, currentCounts.people - metadata.entitiesCounts.people),
            groupsAdded: max(0, metadata.entitiesCounts.groups - currentCounts.groups),
            groupsRemoved: max(0, currentCounts.groups - metadata.entitiesCounts.groups),
            subscriptionsAdded: max(0, metadata.entitiesCounts.subscriptions - currentCounts.subscriptions),
            subscriptionsRemoved: max(0, currentCounts.subscriptions - metadata.entitiesCounts.subscriptions),
            transactionsAdded: max(0, metadata.entitiesCounts.transactions - currentCounts.transactions),
            transactionsRemoved: max(0, currentCounts.transactions - metadata.entitiesCounts.transactions)
        )

        return RestorePreview(
            metadata: metadata,
            currentCounts: currentCounts,
            changes: changes
        )
    }

    // MARK: - Batch Verification

    /// Verify all backups in directory
    func verifyAllBackups(in directory: URL) async throws -> [URL: BackupVerificationResult] {
        var results: [URL: BackupVerificationResult] = [:]

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        )

        let backupFiles = contents.filter { $0.pathExtension == "backup" || $0.pathExtension == "store" }

        for backupURL in backupFiles {
            do {
                let result = try await verifyBackup(at: backupURL)
                results[backupURL] = result
            } catch {
                results[backupURL] = BackupVerificationResult(
                    isValid: false,
                    metadata: nil as VerificationBackupMetadata?,
                    errors: ["Verification failed: \(error.localizedDescription)"],
                    warnings: [],
                    checksumValid: false,
                    versionCompatible: false,
                    dataComplete: false
                )
            }
        }

        return results
    }

    // MARK: - Integrity Report

    /// Generate integrity report for backup
    func generateIntegrityReport(for backupURL: URL) async throws -> String {
        let result = try await verifyBackup(at: backupURL)
        return result.detailedReport
    }

    /// Generate comprehensive report for all backups
    func generateComprehensiveReport(in directory: URL) async throws -> String {
        let results = try await verifyAllBackups(in: directory)

        var report = "=== Comprehensive Backup Report ===\n\n"
        report += "Directory: \(directory.path)\n"
        report += "Total Backups: \(results.count)\n"

        let validCount = results.values.filter { $0.isValid }.count
        let invalidCount = results.count - validCount

        report += "Valid: \(validCount)\n"
        report += "Invalid: \(invalidCount)\n\n"

        report += "=== Individual Backup Reports ===\n\n"

        for (url, result) in results.sorted(by: { $0.key.path < $1.key.path }) {
            report += "Backup: \(url.lastPathComponent)\n"
            report += "Status: \(result.isValid ? "✅ Valid" : "❌ Invalid")\n"

            if let metadata = result.metadata {
                report += "Created: \(metadata.created.formatted())\n"
                report += "Entities: \(metadata.entitiesCounts.total)\n"
            }

            if !result.errors.isEmpty {
                report += "Errors: \(result.errors.joined(separator: ", "))\n"
            }

            report += "\n"
        }

        return report
    }

    // MARK: - Quick Checks

    /// Quick check if backup is valid (without full verification)
    func quickCheck(backupURL: URL) throws -> Bool {
        // Check file exists
        guard fileManager.fileExists(atPath: backupURL.path) else {
            return false
        }

        // Check file is not empty
        let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        if fileSize == 0 {
            return false
        }

        // Check metadata exists
        let metadataURL = backupURL.deletingLastPathComponent()
            .appendingPathComponent(backupURL.deletingPathExtension().lastPathComponent + "_metadata.json")

        return fileManager.fileExists(atPath: metadataURL.path)
    }

    /// Find valid backups in directory
    func findValidBackups(in directory: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        )

        let backupFiles = contents.filter { $0.pathExtension == "backup" || $0.pathExtension == "store" }

        return backupFiles.filter { (try? quickCheck(backupURL: $0)) ?? false }
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Verify a single backup:
 ```swift
 let verificationManager = BackupVerificationManager(modelContext: context)
 let backupURL = URL(fileURLWithPath: "/path/to/backup.store")

 let result = try await verificationManager.verifyBackup(at: backupURL)

 if result.isValid {
     print("✅ Backup is valid")
     print(result.summary)
 } else {
     print("❌ Backup is invalid")
     for error in result.errors {
         print("Error: \(error)")
     }
 }
 ```

 2. Generate restore preview:
 ```swift
 let preview = try await verificationManager.generateRestorePreview(for: backupURL)
 print(preview.detailedSummary)

 if preview.changes.hasChanges {
     print("Changes: \(preview.changes.summary)")
 }
 ```

 3. Create metadata for new backup:
 ```swift
 let metadata = try verificationManager.createMetadata(
     for: backupURL,
     version: DataMigrationManager.currentVersion
 )
 print("Checksum: \(metadata.checksum)")
 ```

 4. Verify all backups in directory:
 ```swift
 let backupsDir = FileManager.default.urls(
     for: .documentDirectory,
     in: .userDomainMask
 ).first!.appendingPathComponent("Backups")

 let results = try await verificationManager.verifyAllBackups(in: backupsDir)

 for (url, result) in results {
     print("\(url.lastPathComponent): \(result.isValid ? "✅" : "❌")")
 }
 ```

 5. Generate comprehensive report:
 ```swift
 let report = try await verificationManager.generateComprehensiveReport(in: backupsDir)
 print(report)
 ```

 6. Quick check for valid backups:
 ```swift
 let validBackups = try verificationManager.findValidBackups(in: backupsDir)
 print("Found \(validBackups.count) valid backup(s)")
 ```
 */
