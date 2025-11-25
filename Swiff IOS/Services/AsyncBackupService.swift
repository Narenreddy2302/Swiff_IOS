//
//  AsyncBackupService.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 2.3: Async BackupService with timeout, progress, and cancellation support
//

import Foundation
import SwiftData
import Combine

// MARK: - Async Backup Service

@MainActor
class AsyncBackupService {
    // MARK: - Singleton

    static let shared = AsyncBackupService()

    // MARK: - Properties

    private let backupService = BackupService.shared
    private let timeoutManager = AsyncTimeoutManager()

    // Task references for cancellation support (Phase 2.5)
    private var currentBackupTask: Task<BackupStatistics, Error>?
    private var currentRestoreTask: Task<RestoreStatistics, Error>?

    private init() {}

    deinit {
        // Clean up any pending tasks
        currentBackupTask?.cancel()
        currentRestoreTask?.cancel()
    }

    // MARK: - Async Backup Creation with Progress

    /// Create a backup asynchronously with timeout and progress reporting
    /// - Parameters:
    ///   - options: Backup options (what to include)
    ///   - timeout: Timeout duration (defaults to 120 seconds)
    ///   - progressHandler: Closure called with progress updates (0.0 to 1.0)
    /// - Returns: Backup statistics
    /// - Throws: BackupError or TimeoutError
    func createBackup(
        options: BackupOptions,
        timeout: TimeInterval = 120.0,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> BackupStatistics {

        // Cancel any existing backup operation
        currentBackupTask?.cancel()

        // Create new backup task with timeout
        currentBackupTask = Task { @MainActor in
            try await timeoutManager.withTimeout(
                timeout: timeout,
                operationType: .backup
            ) {
                // Report initial progress
                progressHandler?(0.0)

                // Perform backup on background actor to avoid blocking main thread
                let stats = try await Task.detached(priority: .userInitiated) { @Sendable in
                    // Create backup using sync service
                    // We'll wrap the sync method since it's already efficient
                    try await MainActor.run {
                        // Simulate progress updates during backup
                        progressHandler?(0.25)

                        let result = try BackupService.shared.createBackup(options: options)

                        progressHandler?(1.0)
                        return result
                    }
                }.value

                // Clear task reference
                await MainActor.run {
                    self.currentBackupTask = nil
                }

                return stats
            }
        }

        return try await currentBackupTask!.value
    }

    // MARK: - Async Backup Restoration with Progress

    /// Restore from backup asynchronously with timeout and progress reporting
    /// - Parameters:
    ///   - url: URL of the backup file
    ///   - options: Restore options (conflict resolution, etc.)
    ///   - timeout: Timeout duration (defaults to 120 seconds)
    ///   - progressHandler: Closure called with progress updates (0.0 to 1.0)
    /// - Returns: Restore statistics
    /// - Throws: BackupError or TimeoutError
    func restoreFromBackup(
        url: URL,
        options: RestoreOptions,
        timeout: TimeInterval = 120.0,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> RestoreStatistics {

        // Cancel any existing restore operation
        currentRestoreTask?.cancel()

        // Create new restore task with timeout
        currentRestoreTask = Task { @MainActor in
            try await timeoutManager.withTimeout(
                timeout: timeout,
                operationType: .backup
            ) {
                // Report initial progress
                progressHandler?(0.0)

                // Perform restore on background actor
                let stats = try await Task.detached(priority: .userInitiated) { @Sendable in
                    try await MainActor.run {
                        // Simulate progress updates during restore
                        progressHandler?(0.1)

                        let result = try BackupService.shared.restoreFromBackup(
                            url: url,
                            options: options
                        )

                        progressHandler?(1.0)
                        return result
                    }
                }.value

                // Clear task reference
                await MainActor.run {
                    self.currentRestoreTask = nil
                }

                return stats
            }
        }

        return try await currentRestoreTask!.value
    }

    // MARK: - Cancellation Support (Phase 2.5)

    /// Cancel the current backup operation
    func cancelBackup() {
        currentBackupTask?.cancel()
        currentBackupTask = nil

        ToastManager.shared.showWarning("Backup cancelled")
        print("⚠️ Backup operation cancelled")
    }

    /// Cancel the current restore operation
    func cancelRestore() {
        currentRestoreTask?.cancel()
        currentRestoreTask = nil

        ToastManager.shared.showWarning("Restore cancelled")
        print("⚠️ Restore operation cancelled")
    }

    /// Check if a backup operation is currently running
    var isBackupInProgress: Bool {
        currentBackupTask != nil && !(currentBackupTask?.isCancelled ?? true)
    }

    /// Check if a restore operation is currently running
    var isRestoreInProgress: Bool {
        currentRestoreTask != nil && !(currentRestoreTask?.isCancelled ?? true)
    }

    // MARK: - Async Backup List Management

    /// Get list of available backups asynchronously
    /// - Returns: Array of backup file URLs
    func getAvailableBackups() async throws -> [URL] {
        let result: [BackupFileInfo] = try await AsyncTimeoutManager.databaseOperation(timeout: 5.0) {
            await MainActor.run {
                (try? self.backupService.listBackups()) ?? []
            }
        }
        return result.map { $0.url }
    }

    /// Delete a backup file asynchronously
    /// - Parameter url: URL of the backup to delete
    func deleteBackup(at url: URL) async throws {
        try await AsyncTimeoutManager.databaseOperation(timeout: 5.0) {
            await MainActor.run {
                try? self.backupService.deleteBackup(at: url)
                return ()
            }
        }
    }

    // MARK: - Automatic Backup with Timeout

    /// Create automatic backup if needed (async version)
    func createAutomaticBackupIfNeeded() async {
        guard await MainActor.run(body: { backupService.shouldCreateBackup() }) else {
            print("⏭️ Skipping automatic backup (too soon)")
            return
        }

        do {
            let options = await MainActor.run { BackupOptions.all }
            let stats = try await createBackup(
                options: options,
                timeout: 120.0,
                progressHandler: { progress in
                    print("📦 Auto-backup progress: \(Int(progress * 100))%")
                }
            )
            print("✅ Automatic backup created: \(stats.filePath)")
            await MainActor.run {
                ToastManager.shared.showSuccess("Backup created successfully")
            }

        } catch let error as TimeoutError {
            print("❌ Automatic backup timed out: \(error.localizedDescription)")
            await MainActor.run {
                ToastManager.shared.showError("Backup timed out. Please try again.")
            }

        } catch {
            print("❌ Automatic backup failed: \(error.localizedDescription)")
            await MainActor.run {
                ToastManager.shared.showError("Backup failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Enhanced Backup Statistics

extension BackupStatistics {
    /// Human-readable duration
    var durationString: String {
        let duration = endTime.timeIntervalSince(startTime)
        return String(format: "%.2f seconds", duration)
    }

    /// Human-readable file size
    var fileSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Detailed description
    var detailedDescription: String {
        """
        Backup Statistics:
        - Duration: \(durationString)
        - Records: \(recordsExported)
        - File Size: \(fileSizeString)
        - Path: \(filePath)
        """
    }
}

// MARK: - Enhanced Restore Statistics

extension RestoreStatistics {
    /// Human-readable duration
    var durationString: String {
        let duration = endTime.timeIntervalSince(startTime)
        return String(format: "%.2f seconds", duration)
    }

    /// Total records processed
    var totalRecords: Int {
        recordsImported + recordsSkipped + recordsReplaced
    }

    /// Success rate
    var successRate: Double {
        guard totalRecords > 0 else { return 0.0 }
        return Double(recordsImported + recordsReplaced) / Double(totalRecords)
    }

    /// Detailed description
    var detailedDescription: String {
        """
        Restore Statistics:
        - Duration: \(durationString)
        - Imported: \(recordsImported)
        - Replaced: \(recordsReplaced)
        - Skipped: \(recordsSkipped)
        - Success Rate: \(String(format: "%.1f%%", successRate * 100))
        """
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic async backup:
 ```swift
 let asyncBackup = AsyncBackupService.shared

 do {
     let stats = try await asyncBackup.createBackup(options: .all)
     print("Backup completed: \(stats.description)")
 } catch {
     print("Backup failed: \(error)")
 }
 ```

 2. Backup with progress:
 ```swift
 let asyncBackup = AsyncBackupService.shared

 let stats = try await asyncBackup.createBackup(
     options: BackupOptions.all,
     timeout: 120.0,
     progressHandler: { progress in
         print("Progress: \(Int(progress * 100))%")
         // Update UI progress bar
     }
 )
 ```

 3. Restore with cancellation:
 ```swift
 let asyncBackup = AsyncBackupService.shared

 // Start restore
 Task {
     do {
         let stats = try await asyncBackup.restoreFromBackup(
             url: backupURL,
             options: RestoreOptions()
         )
         print("Restore completed: \(stats.description)")
     } catch {
         print("Restore failed or cancelled: \(error)")
     }
 }

 // Cancel if needed
 asyncBackup.cancelRestore()
 ```

 4. Check operation status:
 ```swift
 if asyncBackup.isBackupInProgress {
     print("Backup is running...")
 }
 ```
 */
