//
//  BackupModels.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Data structures for backup/restore functionality
//

import Foundation
import Combine

// MARK: - Export Data Structure

/// Complete data export structure containing all app data
struct ExportData: Codable {
    let version: Int // Backup format version for future compatibility
    let createdDate: Date
    let appVersion: String
    let people: [Person]
    let groups: [Group]
    let subscriptions: [Subscription]
    let transactions: [Transaction]
    let metadata: BackupMetadata

    init(
        people: [Person],
        groups: [Group],
        subscriptions: [Subscription],
        transactions: [Transaction],
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    ) {
        self.version = 1
        self.createdDate = Date()
        self.appVersion = appVersion
        self.people = people
        self.groups = groups
        self.subscriptions = subscriptions
        self.transactions = transactions
        self.metadata = BackupMetadata(
            version: 1,
            createdDate: Date(),
            appVersion: appVersion,
            peopleCount: people.count,
            groupsCount: groups.count,
            subscriptionsCount: subscriptions.count,
            transactionsCount: transactions.count
        )
    }
}

// MARK: - Backup Metadata

/// Metadata about the backup
struct BackupMetadata: Codable {
    let version: Int
    let createdDate: Date
    let appVersion: String
    let peopleCount: Int
    let groupsCount: Int
    let subscriptionsCount: Int
    let transactionsCount: Int

    var totalRecords: Int {
        peopleCount + groupsCount + subscriptionsCount + transactionsCount
    }

    var description: String {
        """
        Total Records: \(totalRecords)
        - People: \(peopleCount)
        - Groups: \(groupsCount)
        - Subscriptions: \(subscriptionsCount)
        - Transactions: \(transactionsCount)
        """
    }
}

// MARK: - Backup File Info

/// Information about a backup file
struct BackupFileInfo: Identifiable {
    let id = UUID()
    let url: URL
    let createdDate: Date
    let fileSize: Int64
    let metadata: BackupMetadata?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var filename: String {
        url.lastPathComponent
    }
}

// MARK: - Backup Errors

enum BackupError: LocalizedError {
    case documentDirectoryNotFound
    case backupDirectoryCreationFailed
    case fileWriteFailed(underlying: Error)
    case fileReadFailed(underlying: Error)
    case invalidBackupFormat
    case incompatibleVersion(found: Int, expected: Int)
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case backupNotFound(filename: String)
    case deleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .documentDirectoryNotFound:
            return "Could not access documents directory"
        case .backupDirectoryCreationFailed:
            return "Failed to create backup directory"
        case .fileWriteFailed(let error):
            return "Failed to write backup file: \(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "Failed to read backup file: \(error.localizedDescription)"
        case .invalidBackupFormat:
            return "Backup file format is invalid"
        case .incompatibleVersion(let found, let expected):
            return "Incompatible backup version (found: \(found), expected: \(expected))"
        case .decodingFailed(let error):
            return "Failed to decode backup data: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode backup data: \(error.localizedDescription)"
        case .backupNotFound(let filename):
            return "Backup file not found: \(filename)"
        case .deleteFailed(let error):
            return "Failed to delete backup: \(error.localizedDescription)"
        }
    }
}

// MARK: - Backup Options

/// Options for creating backups
struct BackupOptions: Sendable {
    var includePeople: Bool = true
    var includeGroups: Bool = true
    var includeSubscriptions: Bool = true
    var includeTransactions: Bool = true
    var prettyPrintJSON: Bool = false

    init(
        includePeople: Bool = true,
        includeGroups: Bool = true,
        includeSubscriptions: Bool = true,
        includeTransactions: Bool = true,
        prettyPrintJSON: Bool = false
    ) {
        self.includePeople = includePeople
        self.includeGroups = includeGroups
        self.includeSubscriptions = includeSubscriptions
        self.includeTransactions = includeTransactions
        self.prettyPrintJSON = prettyPrintJSON
    }

    static let all = BackupOptions()
    static let minimal = BackupOptions(
        includePeople: true,
        includeGroups: false,
        includeSubscriptions: false,
        includeTransactions: false
    )
}

// MARK: - Restore Options

/// Options for restoring from backup
struct RestoreOptions: Sendable {
    enum ConflictResolution: Sendable {
        case keepExisting  // Keep existing data, skip duplicates
        case replaceWithBackup  // Replace existing with backup data
        case mergeByDate  // Keep newer version based on date
    }

    var conflictResolution: ConflictResolution = .replaceWithBackup
    var clearExistingData: Bool = true
    var validateBeforeRestore: Bool = true

    init() {
        // Default initializer
    }

    init(conflictResolution: ConflictResolution = .replaceWithBackup,
         clearExistingData: Bool = true,
         validateBeforeRestore: Bool = true) {
        self.conflictResolution = conflictResolution
        self.clearExistingData = clearExistingData
        self.validateBeforeRestore = validateBeforeRestore
    }

    static let `default` = RestoreOptions()
}

// MARK: - Backup Statistics

/// Statistics about a backup operation
struct BackupStatistics {
    let startTime: Date
    let endTime: Date
    let recordsExported: Int
    let fileSize: Int64
    let filePath: String

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        String(format: "%.2f seconds", duration)
    }

    var summary: String {
        """
        Backup Statistics:
        - Duration: \(formattedDuration)
        - Records Exported: \(recordsExported)
        - File Size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
        - Location: \(filePath)
        """
    }
}

// MARK: - Restore Statistics

/// Statistics about a restore operation
struct RestoreStatistics {
    let startTime: Date
    let endTime: Date
    let recordsImported: Int
    let recordsSkipped: Int
    let recordsReplaced: Int

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        String(format: "%.2f seconds", duration)
    }

    var summary: String {
        """
        Restore Statistics:
        - Duration: \(formattedDuration)
        - Records Imported: \(recordsImported)
        - Records Skipped: \(recordsSkipped)
        - Records Replaced: \(recordsReplaced)
        - Total Processed: \(recordsImported + recordsSkipped)
        """
    }
}
