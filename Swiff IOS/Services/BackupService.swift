//
//  BackupService.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Service for creating, managing, and restoring data backups
//

import Combine
import Foundation

@MainActor
class BackupService {
    // MARK: - Singleton

    static let shared = BackupService()

    // MARK: - Constants

    private let backupInterval: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    private let lastBackupKey = "LastBackupDate"
    private let backupDirectoryName = "Backups"
    private let backupFilePrefix = "swiff_backup_"
    private let backupFileExtension = "json"

    // MARK: - Properties

    private let persistenceService = PersistenceService.shared
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Backup Directory Management

    /// Get the URL for the backups directory
    private func getBackupDirectoryURL() throws -> URL {
        guard
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            throw BackupError.documentDirectoryNotFound
        }

        let backupURL = documentsURL.appendingPathComponent(backupDirectoryName)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: backupURL.path) {
            do {
                try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
            } catch {
                throw BackupError.backupDirectoryCreationFailed
            }
        }

        return backupURL
    }

    // MARK: - Backup Creation

    /// Check if a backup should be created based on time interval
    func shouldCreateBackup() -> Bool {
        guard let lastBackup = UserDefaults.standard.object(forKey: lastBackupKey) as? Date else {
            return true  // Never backed up before
        }
        return Date().timeIntervalSince(lastBackup) > backupInterval
    }

    /// Create a backup of all app data
    @discardableResult
    @MainActor
    func createBackup(options: BackupOptions = .all) throws -> BackupStatistics {
        let startTime = Date()

        // Create backup directory
        let backupDirectory = try getBackupDirectoryURL()

        // Generate filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "\(backupFilePrefix)\(dateString).\(backupFileExtension)"
        let backupFileURL = backupDirectory.appendingPathComponent(filename)

        // Fetch all data
        let people = options.includePeople ? (try? persistenceService.fetchAllPeople()) ?? [] : []
        let groups = options.includeGroups ? (try? persistenceService.fetchAllGroups()) ?? [] : []
        let subscriptions =
            options.includeSubscriptions
            ? (try? persistenceService.fetchAllSubscriptions()) ?? [] : []
        let transactions =
            options.includeTransactions
            ? (try? persistenceService.fetchAllTransactions()) ?? [] : []

        // Create export data
        let exportData = ExportData(
            people: people,
            groups: groups,
            subscriptions: subscriptions,
            transactions: transactions
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if options.prettyPrintJSON {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        let jsonData: Data
        do {
            jsonData = try encoder.encode(exportData)
        } catch {
            throw BackupError.encodingFailed(underlying: error)
        }

        // Validate storage space and write atomically
        do {
            try StorageQuotaManager.shared.atomicWrite(data: jsonData, to: backupFileURL)
        } catch let error as AppStorageError {
            throw BackupError.fileWriteFailed(underlying: error)
        } catch {
            throw BackupError.fileWriteFailed(underlying: error)
        }

        // Update last backup date
        UserDefaults.standard.set(Date(), forKey: lastBackupKey)

        // Calculate statistics
        let endTime = Date()
        let fileSize =
            (try? fileManager.attributesOfItem(atPath: backupFileURL.path)[.size] as? Int64) ?? 0

        let statistics = BackupStatistics(
            startTime: startTime,
            endTime: endTime,
            recordsExported: exportData.metadata.totalRecords,
            fileSize: fileSize,
            filePath: backupFileURL.path
        )

        print("✅ Backup created successfully:")
        print(statistics.summary)

        return statistics
    }

    /// Create automatic backup if needed
    func createAutomaticBackupIfNeeded() {
        guard shouldCreateBackup() else {
            print("⏭️ Skipping automatic backup (too soon)")
            return
        }

        do {
            let stats = try createBackup()
            print("📦 Automatic backup created: \(stats.filePath)")
        } catch {
            print("❌ Automatic backup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Backup Restoration

    /// Restore data from a backup file
    @discardableResult
    @MainActor
    func restoreFromBackup(
        url: URL,
        options: RestoreOptions = .default
    ) throws -> RestoreStatistics {
        let startTime = Date()

        // Read backup file
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch {
            throw BackupError.fileReadFailed(underlying: error)
        }

        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData: ExportData
        do {
            exportData = try decoder.decode(ExportData.self, from: jsonData)
        } catch {
            throw BackupError.decodingFailed(underlying: error)
        }

        // Validate version compatibility
        if options.validateBeforeRestore && exportData.version != 1 {
            throw BackupError.incompatibleVersion(found: exportData.version, expected: 1)
        }

        var recordsImported = 0
        var recordsSkipped = 0
        var recordsReplaced = 0

        // Clear existing data if requested
        if options.clearExistingData {
            // This would require implementing clearAllData in PersistenceService
            print("⚠️ Clear existing data not yet implemented")
        }

        // Import people
        for person in exportData.people {
            do {
                // Check if person already exists
                if let existing = try? persistenceService.fetchPerson(byID: person.id) {
                    switch options.conflictResolution {
                    case .keepExisting:
                        recordsSkipped += 1
                        continue
                    case .replaceWithBackup:
                        try persistenceService.updatePerson(person)
                        recordsReplaced += 1
                    case .mergeByDate:
                        if person.createdDate > existing.createdDate {
                            try persistenceService.updatePerson(person)
                            recordsReplaced += 1
                        } else {
                            recordsSkipped += 1
                        }
                    }
                } else {
                    try persistenceService.savePerson(person)
                    recordsImported += 1
                }
            } catch {
                print("⚠️ Failed to import person: \(error.localizedDescription)")
                recordsSkipped += 1
            }
        }

        // Import subscriptions
        for subscription in exportData.subscriptions {
            do {
                if (try? persistenceService.fetchSubscription(byID: subscription.id)) != nil {
                    switch options.conflictResolution {
                    case .keepExisting:
                        recordsSkipped += 1
                        continue
                    case .replaceWithBackup:
                        try persistenceService.updateSubscription(subscription)
                        recordsReplaced += 1
                    case .mergeByDate:
                        try persistenceService.updateSubscription(subscription)
                        recordsReplaced += 1
                    }
                } else {
                    try persistenceService.saveSubscription(subscription)
                    recordsImported += 1
                }
            } catch {
                print("⚠️ Failed to import subscription: \(error.localizedDescription)")
                recordsSkipped += 1
            }
        }

        // Import transactions
        for transaction in exportData.transactions {
            do {
                if (try? persistenceService.fetchTransaction(byID: transaction.id)) != nil {
                    switch options.conflictResolution {
                    case .keepExisting:
                        recordsSkipped += 1
                        continue
                    case .replaceWithBackup:
                        try persistenceService.updateTransaction(transaction)
                        recordsReplaced += 1
                    case .mergeByDate:
                        try persistenceService.updateTransaction(transaction)
                        recordsReplaced += 1
                    }
                } else {
                    try persistenceService.saveTransaction(transaction)
                    recordsImported += 1
                }
            } catch {
                print("⚠️ Failed to import transaction: \(error.localizedDescription)")
                recordsSkipped += 1
            }
        }

        // Import groups (after people are imported)
        for group in exportData.groups {
            do {
                if (try? persistenceService.fetchGroup(byID: group.id)) != nil {
                    switch options.conflictResolution {
                    case .keepExisting:
                        recordsSkipped += 1
                        continue
                    case .replaceWithBackup:
                        try persistenceService.updateGroup(group)
                        recordsReplaced += 1
                    case .mergeByDate:
                        try persistenceService.updateGroup(group)
                        recordsReplaced += 1
                    }
                } else {
                    try persistenceService.saveGroup(group)
                    recordsImported += 1
                }
            } catch {
                print("⚠️ Failed to import group: \(error.localizedDescription)")
                recordsSkipped += 1
            }
        }

        let endTime = Date()
        let statistics = RestoreStatistics(
            startTime: startTime,
            endTime: endTime,
            recordsImported: recordsImported,
            recordsSkipped: recordsSkipped,
            recordsReplaced: recordsReplaced
        )

        print("✅ Restore completed:")
        print(statistics.summary)

        return statistics
    }

    // MARK: - Backup File Management

    /// List all available backups
    func listBackups() throws -> [BackupFileInfo] {
        let backupDirectory = try getBackupDirectoryURL()

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            let backupFiles =
                fileURLs
                .filter { $0.pathExtension == backupFileExtension }
                .compactMap { url -> BackupFileInfo? in
                    guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                        let creationDate = attributes[.creationDate] as? Date,
                        let fileSize = attributes[.size] as? Int64
                    else {
                        return nil
                    }

                    // Try to read metadata from file
                    let metadata = try? readBackupMetadata(from: url)

                    return BackupFileInfo(
                        url: url,
                        createdDate: creationDate,
                        fileSize: fileSize,
                        metadata: metadata
                    )
                }
                .sorted { $0.createdDate > $1.createdDate }  // Most recent first

            return backupFiles
        } catch {
            throw BackupError.fileReadFailed(underlying: error)
        }
    }

    /// Read metadata from a backup file without loading all data
    private func readBackupMetadata(from url: URL) throws -> BackupMetadata {
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportData.self, from: jsonData)
        return exportData.metadata
    }

    /// Delete a backup file
    func deleteBackup(at url: URL) throws {
        do {
            try fileManager.removeItem(at: url)
            print("✅ Backup deleted: \(url.lastPathComponent)")
        } catch {
            throw BackupError.deleteFailed(underlying: error)
        }
    }

    /// Delete old backups, keeping only the most recent N backups
    func deleteOldBackups(keepCount: Int = 5) throws {
        let backups = try listBackups()

        guard backups.count > keepCount else {
            print("ℹ️ No old backups to delete (total: \(backups.count), keeping: \(keepCount))")
            return
        }

        let backupsToDelete = backups.suffix(from: keepCount)

        for backup in backupsToDelete {
            try deleteBackup(at: backup.url)
        }

        print("✅ Deleted \(backupsToDelete.count) old backup(s)")
    }

    /// Get the total size of all backups
    func getTotalBackupSize() throws -> Int64 {
        let backups = try listBackups()
        return backups.reduce(0) { $0 + $1.fileSize }
    }

    // MARK: - Backup Validation

    /// Validate a backup file without importing it
    func validateBackup(at url: URL) throws -> Bool {
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let exportData = try decoder.decode(ExportData.self, from: jsonData)

            // Check version compatibility
            guard exportData.version == 1 else {
                throw BackupError.incompatibleVersion(found: exportData.version, expected: 1)
            }

            // Validate that metadata matches actual counts
            let actualPeopleCount = exportData.people.count
            let actualGroupsCount = exportData.groups.count
            let actualSubscriptionsCount = exportData.subscriptions.count
            let actualTransactionsCount = exportData.transactions.count

            guard exportData.metadata.peopleCount == actualPeopleCount,
                exportData.metadata.groupsCount == actualGroupsCount,
                exportData.metadata.subscriptionsCount == actualSubscriptionsCount,
                exportData.metadata.transactionsCount == actualTransactionsCount
            else {
                throw BackupError.invalidBackupFormat
            }

            print("✅ Backup file is valid")
            return true

        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.decodingFailed(underlying: error)
        }
    }

    // MARK: - Export to Share

    /// Export data to a temporary file for sharing
    @MainActor
    func exportForSharing(options: BackupOptions = .all) throws -> URL {
        let tempDirectory = fileManager.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "\(backupFilePrefix)\(dateString).\(backupFileExtension)"
        let tempFileURL = tempDirectory.appendingPathComponent(filename)

        // Fetch and encode data
        let people = options.includePeople ? (try? persistenceService.fetchAllPeople()) ?? [] : []
        let groups = options.includeGroups ? (try? persistenceService.fetchAllGroups()) ?? [] : []
        let subscriptions =
            options.includeSubscriptions
            ? (try? persistenceService.fetchAllSubscriptions()) ?? [] : []
        let transactions =
            options.includeTransactions
            ? (try? persistenceService.fetchAllTransactions()) ?? [] : []

        let exportData = ExportData(
            people: people,
            groups: groups,
            subscriptions: subscriptions,
            transactions: transactions
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: tempFileURL)

        return tempFileURL
    }
}

// All backup-related types (ExportData, BackupMetadata, BackupFileInfo, BackupError,
// BackupOptions, RestoreOptions, BackupStatistics, RestoreStatistics) are defined
// in BackupModels.swift

// StorageError is defined in ComprehensiveErrorTypes.swift
