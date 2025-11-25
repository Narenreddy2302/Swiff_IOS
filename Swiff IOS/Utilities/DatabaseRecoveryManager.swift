//
//  DatabaseRecoveryManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Handles database failures gracefully with recovery strategies
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Database Recovery Error

enum DatabaseRecoveryError: LocalizedError {
    case containerCreationFailed(underlying: Error)
    case resetFailed(underlying: Error)
    case backupFailed(underlying: Error)
    case recoveryExhausted

    var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let error):
            return "Database initialization failed: \(error.localizedDescription)"
        case .resetFailed(let error):
            return "Failed to reset database: \(error.localizedDescription)"
        case .backupFailed(let error):
            return "Failed to backup corrupted data: \(error.localizedDescription)"
        case .recoveryExhausted:
            return "All database recovery attempts have failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .containerCreationFailed:
            return "Try resetting the database. This will delete all local data."
        case .resetFailed:
            return "Please reinstall the app or contact support."
        case .backupFailed:
            return "The database is corrupted. Data backup failed but we can create a fresh database."
        case .recoveryExhausted:
            return "Please reinstall the application."
        }
    }
}

// MARK: - Recovery Strategy

enum RecoveryStrategy {
    case retry(attempts: Int)
    case backupAndReset
    case freshStart
    case showError
}

// MARK: - Database Recovery Manager

@MainActor
class DatabaseRecoveryManager: ObservableObject {
    // MARK: - Published Properties

    @Published var isRecovering: Bool = false
    @Published var recoveryError: DatabaseRecoveryError?
    @Published var showRecoverySheet: Bool = false
    @Published var recoveryMessage: String = ""

    // MARK: - Singleton

    static let shared = DatabaseRecoveryManager()

    private init() {}

    // MARK: - Recovery Methods

    /// Attempt to create model container with retry logic
    func attemptContainerCreation(
        schema: Schema,
        migrationPlan: SchemaMigrationPlan.Type,
        configuration: ModelConfiguration,
        maxRetries: Int = 3
    ) async throws -> ModelContainer {
        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: migrationPlan,
                    configurations: [configuration]
                )

                // Verify container is working
                _ = container.mainContext

                print("✅ Database container created successfully on attempt \(attempt)")
                return container

            } catch {
                lastError = error
                print("⚠️ Container creation attempt \(attempt) failed: \(error.localizedDescription)")

                // Wait before retry (exponential backoff)
                if attempt < maxRetries {
                    let delaySeconds = pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }

        // All retries failed - show recovery options
        throw DatabaseRecoveryError.containerCreationFailed(underlying: lastError ?? NSError(domain: "DatabaseRecovery", code: -1))
    }

    /// Attempt to backup corrupted database before reset
    func backupCorruptedDatabase() async throws {
        let fileManager = FileManager.default

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DatabaseRecoveryError.backupFailed(underlying: NSError(domain: "FileManager", code: -1))
        }

        let backupDirectory = documentsPath.appendingPathComponent("CorruptedBackups", isDirectory: true)

        // Create backup directory if needed
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }

        // Find SwiftData store files
        let storeURL = documentsPath.appendingPathComponent("default.store")

        if fileManager.fileExists(atPath: storeURL.path) {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let backupURL = backupDirectory.appendingPathComponent("corrupted_\(timestamp).store")

            do {
                try fileManager.copyItem(at: storeURL, to: backupURL)
                print("✅ Backed up corrupted database to: \(backupURL.path)")
                recoveryMessage = "Corrupted data backed up successfully"
            } catch {
                print("⚠️ Failed to backup corrupted database: \(error)")
                throw DatabaseRecoveryError.backupFailed(underlying: error)
            }
        }
    }

    /// Reset database by deleting all SwiftData files
    func resetDatabase() async throws {
        let fileManager = FileManager.default

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DatabaseRecoveryError.resetFailed(underlying: NSError(domain: "FileManager", code: -1))
        }

        // List of SwiftData files to delete
        let filesToDelete = [
            "default.store",
            "default.store-shm",
            "default.store-wal"
        ]

        for filename in filesToDelete {
            let fileURL = documentsPath.appendingPathComponent(filename)

            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("✅ Deleted: \(filename)")
                } catch {
                    print("⚠️ Failed to delete \(filename): \(error)")
                    throw DatabaseRecoveryError.resetFailed(underlying: error)
                }
            }
        }

        recoveryMessage = "Database reset successfully"
        print("✅ Database files deleted successfully")
    }

    /// Full recovery flow with user interaction
    func performRecovery(error: Error) async -> RecoveryStrategy {
        await MainActor.run {
            isRecovering = true
            recoveryError = DatabaseRecoveryError.containerCreationFailed(underlying: error)
            showRecoverySheet = true
        }

        // Wait for user decision
        // This would be connected to a SwiftUI sheet
        return .backupAndReset
    }

    /// Execute recovery strategy
    func executeRecovery(strategy: RecoveryStrategy) async throws {
        await MainActor.run {
            isRecovering = true
        }

        switch strategy {
        case .retry(_):
            // Already handled in attemptContainerCreation
            break

        case .backupAndReset:
            // Backup first (don't fail if backup fails)
            do {
                try await backupCorruptedDatabase()
            } catch {
                print("⚠️ Backup failed but continuing with reset: \(error)")
            }

            // Reset database
            try await resetDatabase()

        case .freshStart:
            // Just reset without backup
            try await resetDatabase()

        case .showError:
            await MainActor.run {
                isRecovering = false
            }
            throw DatabaseRecoveryError.recoveryExhausted
        }

        await MainActor.run {
            isRecovering = false
        }
    }

    /// Check if error is recoverable
    func isRecoverable(error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()

        // Common recoverable error patterns
        let recoverablePatterns = [
            "corrupt",
            "database",
            "sqlite",
            "migration",
            "schema",
            "model"
        ]

        return recoverablePatterns.contains { errorString.contains($0) }
    }
}

// MARK: - Recovery Sheet View

struct DatabaseRecoverySheet: View {
    @ObservedObject var recoveryManager = DatabaseRecoveryManager.shared
    @Binding var isPresented: Bool

    let onReset: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Error Icon
                ZStack {
                    Circle()
                        .fill(Color.wiseError.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.wiseError)
                }

                // Error Message
                VStack(spacing: 16) {
                    Text("Database Error")
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    if let error = recoveryManager.recoveryError {
                        Text(error.localizedDescription)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 8)
                        }
                    }
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.warning()
                        Task {
                            do {
                                try await recoveryManager.executeRecovery(strategy: .backupAndReset)
                                onReset()
                                isPresented = false
                            } catch {
                                print("Recovery failed: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Reset Database")
                                .fontWeight(.semibold)
                        }
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.wiseError)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        HapticManager.shared.light()
                        onCancel()
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.wiseBorder.opacity(0.3))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.wiseBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true

        var body: some View {
            DatabaseRecoverySheet(
                isPresented: $isPresented,
                onReset: { print("Reset") },
                onCancel: { print("Cancel") }
            )
        }
    }

    return PreviewWrapper()
}
