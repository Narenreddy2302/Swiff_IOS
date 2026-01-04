//
//  StorageQuotaManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Manages disk space validation before file operations
//

import Foundation

// MARK: - Storage Error

enum StorageQuotaError: LocalizedError {
    case insufficientSpace(required: Int64, available: Int64)
    case quotaExceeded(limit: Int64)
    case fileSystemError(underlying: Error)
    case invalidPath

    var errorDescription: String? {
        switch self {
        case .insufficientSpace(let required, let available):
            let requiredMB = ByteCountFormatter.string(fromByteCount: required, countStyle: .file)
            let availableMB = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
            return "Insufficient disk space. Need \(requiredMB), but only \(availableMB) available."

        case .quotaExceeded(let limit):
            let limitMB = ByteCountFormatter.string(fromByteCount: limit, countStyle: .file)
            return "App storage quota exceeded. Maximum allowed: \(limitMB)"

        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"

        case .invalidPath:
            return "Invalid file path provided"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .insufficientSpace:
            return "Free up some space on your device by deleting unused apps or files."

        case .quotaExceeded:
            return "Delete old backups or export data to free up app storage."

        case .fileSystemError:
            return "Check file permissions or try again later."

        case .invalidPath:
            return "Verify the file path is correct."
        }
    }
}

// MARK: - Storage Info

struct StorageInfo {
    let totalSpace: Int64
    let availableSpace: Int64
    let usedSpace: Int64

    var availableSpaceMB: Double {
        Double(availableSpace) / 1_048_576 // Convert to MB
    }

    var usedSpaceMB: Double {
        Double(usedSpace) / 1_048_576
    }

    var totalSpaceMB: Double {
        Double(totalSpace) / 1_048_576
    }

    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return (Double(usedSpace) / Double(totalSpace)) * 100
    }

    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
}

// MARK: - Storage Quota Manager

class StorageQuotaManager {
    // MARK: - Singleton

    static let shared = StorageQuotaManager()

    private init() {}

    // MARK: - Constants

    /// Minimum free space to maintain (100 MB)
    private let minimumFreeSpace: Int64 = 100 * 1024 * 1024

    /// Maximum app storage quota (500 MB)
    private let appStorageQuota: Int64 = 500 * 1024 * 1024

    /// Safety buffer for file operations (10 MB)
    private let safetyBuffer: Int64 = 10 * 1024 * 1024

    // MARK: - Storage Information

    /// Get current storage information
    func getStorageInfo() throws -> StorageInfo {
        let fileManager = FileManager.default

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StorageQuotaError.invalidPath
        }

        do {
            let values = try documentsPath.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])

            let totalSpace = values.volumeTotalCapacity.map { Int64($0) } ?? 0
            let availableSpace = values.volumeAvailableCapacity.map { Int64($0) } ?? 0
            let usedSpace = totalSpace - availableSpace

            return StorageInfo(
                totalSpace: totalSpace,
                availableSpace: availableSpace,
                usedSpace: usedSpace
            )
        } catch {
            throw StorageQuotaError.fileSystemError(underlying: error)
        }
    }

    /// Get app's current storage usage
    func getAppStorageUsage() throws -> Int64 {
        let fileManager = FileManager.default

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StorageQuotaError.invalidPath
        }

        return try calculateDirectorySize(at: documentsPath)
    }

    /// Calculate size of directory recursively
    private func calculateDirectorySize(at url: URL) throws -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))

                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
            } catch {
                print("⚠️ Error calculating size for \(fileURL.path): \(error)")
                continue
            }
        }

        return totalSize
    }

    // MARK: - Validation Methods

    /// Validate if there's enough space for file operation
    func validateSpace(requiredBytes: Int64) throws {
        let storageInfo = try getStorageInfo()

        // Check minimum free space
        let requiredWithBuffer = requiredBytes + safetyBuffer
        if storageInfo.availableSpace < requiredWithBuffer {
            throw StorageQuotaError.insufficientSpace(
                required: requiredWithBuffer,
                available: storageInfo.availableSpace
            )
        }

        // Check app quota
        let appUsage = try getAppStorageUsage()
        if appUsage + requiredBytes > appStorageQuota {
            throw StorageQuotaError.quotaExceeded(limit: appStorageQuota)
        }
    }

    /// Validate space before writing file
    func validateBeforeWrite(fileURL: URL, estimatedSize: Int64? = nil) throws {
        let fileManager = FileManager.default

        // If file exists, get its current size
        var currentSize: Int64 = 0
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                currentSize = attributes[.size] as? Int64 ?? 0
            } catch {
                // If we can't get attributes, assume 0
                currentSize = 0
            }
        }

        // Use estimated size if provided, otherwise use current size + buffer
        let requiredSpace = estimatedSize ?? (currentSize + safetyBuffer)

        try validateSpace(requiredBytes: requiredSpace)
    }

    /// Validate space before writing data
    func validateBeforeWrite(data: Data, to url: URL) throws {
        try validateBeforeWrite(fileURL: url, estimatedSize: Int64(data.count))
    }

    /// Check if low on storage
    func isLowOnStorage() -> Bool {
        guard let storageInfo = try? getStorageInfo() else {
            return true // Assume low if we can't check
        }

        return storageInfo.availableSpace < minimumFreeSpace
    }

    /// Check if app is near quota
    func isNearQuota() -> Bool {
        guard let appUsage = try? getAppStorageUsage() else {
            return false
        }

        // Consider "near quota" as 80% of limit
        return appUsage > (appStorageQuota * 8 / 10)
    }

    // MARK: - Cleanup Methods

    /// Get list of large files that can be cleaned up
    func getLargeFiles(minSize: Int64 = 1024 * 1024) throws -> [(url: URL, size: Int64)] {
        let fileManager = FileManager.default

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StorageQuotaError.invalidPath
        }

        var largeFiles: [(URL, Int64)] = []

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]

        guard let enumerator = fileManager.enumerator(
            at: documentsPath,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))

                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    let fileSize = Int64(resourceValues.fileSize ?? 0)
                    if fileSize >= minSize {
                        largeFiles.append((fileURL, fileSize))
                    }
                }
            } catch {
                continue
            }
        }

        // Sort by size (largest first)
        return largeFiles.sorted { $0.1 > $1.1 }
    }

    /// Get old backup files that can be deleted
    func getOldBackups(olderThanDays days: Int = 30) throws -> [URL] {
        let fileManager = FileManager.default

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StorageQuotaError.invalidPath
        }

        let backupDirectory = documentsPath.appendingPathComponent("Backups", isDirectory: true)

        guard fileManager.fileExists(atPath: backupDirectory.path) else {
            return []
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        var oldBackups: [URL] = []

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey]

        guard let enumerator = fileManager.enumerator(
            at: backupDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))

                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    if let modificationDate = resourceValues.contentModificationDate,
                       modificationDate < cutoffDate {
                        oldBackups.append(fileURL)
                    }
                }
            } catch {
                continue
            }
        }

        return oldBackups
    }

    // MARK: - Atomic File Operations

    /// Perform atomic write with space validation
    func atomicWrite(data: Data, to url: URL) throws {
        // Validate space first
        try validateBeforeWrite(data: data, to: url)

        // Create temporary file
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString)

        do {
            // Write to temp file
            try data.write(to: tempURL, options: .atomic)

            // Verify write succeeded
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                throw StorageQuotaError.fileSystemError(
                    underlying: NSError(domain: "StorageQuotaManager", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Temporary file write failed"
                    ])
                )
            }

            // Move to final location
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }

            try FileManager.default.moveItem(at: tempURL, to: url)

            print("✅ Atomic write successful: \(url.lastPathComponent)")

        } catch {
            // Clean up temp file if it exists
            try? FileManager.default.removeItem(at: tempURL)
            throw StorageQuotaError.fileSystemError(underlying: error)
        }
    }
}

// MARK: - Convenience Extensions

extension StorageQuotaManager {
    /// Format bytes to human-readable string
    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Get storage warning message
    func getStorageWarningMessage() -> String? {
        if isLowOnStorage() {
            return "Your device is running low on storage. Consider freeing up some space."
        }

        if isNearQuota() {
            return "App storage is almost full. Consider deleting old backups."
        }

        return nil
    }
}
