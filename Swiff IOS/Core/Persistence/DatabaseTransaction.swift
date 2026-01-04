//
//  DatabaseTransaction.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 4.2: Transaction support with rollback and savepoints
//

import Foundation
import SwiftData

// MARK: - Transaction Error

enum TransactionError: LocalizedError {
    case transactionInProgress
    case noTransactionInProgress
    case savePointNotFound(String)
    case rollbackFailed(String)
    case commitFailed(String)
    case nestedTransactionLimit
    case deadlock
    case timeout

    var errorDescription: String? {
        switch self {
        case .transactionInProgress:
            return "Cannot start new transaction: transaction already in progress"
        case .noTransactionInProgress:
            return "Cannot commit/rollback: no transaction in progress"
        case .savePointNotFound(let name):
            return "Savepoint '\(name)' not found"
        case .rollbackFailed(let reason):
            return "Rollback failed: \(reason)"
        case .commitFailed(let reason):
            return "Commit failed: \(reason)"
        case .nestedTransactionLimit:
            return "Maximum nested transaction depth exceeded"
        case .deadlock:
            return "Transaction deadlock detected"
        case .timeout:
            return "Transaction timeout exceeded"
        }
    }
}

// MARK: - Transaction Result

enum TransactionResult<T> {
    case success(T)
    case failure(Error)
    case rolledBack

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Savepoint

struct Savepoint {
    let name: String
    let timestamp: Date
    let depth: Int

    init(name: String, depth: Int) {
        self.name = name
        self.timestamp = Date()
        self.depth = depth
    }
}

// MARK: - Transaction Statistics

struct TransactionStatistics {
    var totalTransactions: Int = 0
    var successfulTransactions: Int = 0
    var failedTransactions: Int = 0
    var rolledBackTransactions: Int = 0
    var averageDuration: TimeInterval = 0
    var longestDuration: TimeInterval = 0

    var successRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(successfulTransactions) / Double(totalTransactions)
    }

    mutating func recordTransaction(success: Bool, rolledBack: Bool, duration: TimeInterval) {
        totalTransactions += 1

        if success {
            successfulTransactions += 1
        } else if rolledBack {
            rolledBackTransactions += 1
        } else {
            failedTransactions += 1
        }

        // Update average duration
        averageDuration = ((averageDuration * Double(totalTransactions - 1)) + duration) / Double(totalTransactions)

        // Update longest duration
        if duration > longestDuration {
            longestDuration = duration
        }
    }
}

// MARK: - Database Transaction Manager

@MainActor
class DatabaseTransactionManager {

    private let modelContext: ModelContext
    private var isInTransaction: Bool = false
    private var transactionDepth: Int = 0
    private var savepoints: [Savepoint] = []
    private var statistics: TransactionStatistics = TransactionStatistics()
    private var transactionStartTime: Date?

    static let maxNestedDepth = 10

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Basic Transaction Operations

    /// Start a new transaction
    func beginTransaction() throws {
        guard !isInTransaction else {
            throw TransactionError.transactionInProgress
        }

        isInTransaction = true
        transactionDepth = 1
        transactionStartTime = Date()
        savepoints.removeAll()
    }

    /// Commit the current transaction
    func commit() throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        do {
            try modelContext.save()

            // Record success
            recordTransactionCompletion(success: true, rolledBack: false)

            // Clean up
            isInTransaction = false
            transactionDepth = 0
            savepoints.removeAll()
            transactionStartTime = nil

        } catch {
            // Record failure
            recordTransactionCompletion(success: false, rolledBack: false)

            throw TransactionError.commitFailed(error.localizedDescription)
        }
    }

    /// Rollback the current transaction
    func rollback() throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        modelContext.rollback()

        // Record rollback
        recordTransactionCompletion(success: false, rolledBack: true)

        // Clean up
        isInTransaction = false
        transactionDepth = 0
        savepoints.removeAll()
        transactionStartTime = nil
    }

    // MARK: - Transaction Wrapper

    /// Execute operation within a transaction
    func performTransaction<T>(
        timeout: TimeInterval? = nil,
        operation: () throws -> T
    ) async throws -> TransactionResult<T> {
        // Start transaction
        try beginTransaction()

        // Set up timeout if specified
        let timeoutTask: Task<Void, Never>?
        if let timeout = timeout {
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if self.isInTransaction {
                    try? self.rollback()
                }
            }
        } else {
            timeoutTask = nil
        }

        do {
            // Execute operation
            let result = try operation()

            // Cancel timeout
            timeoutTask?.cancel()

            // Commit
            try commit()

            return .success(result)

        } catch {
            // Cancel timeout
            timeoutTask?.cancel()

            // Rollback
            try? rollback()

            return .failure(error)
        }
    }

    /// Execute async operation within a transaction
    func performAsyncTransaction<T>(
        timeout: TimeInterval? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> TransactionResult<T> {
        // Start transaction
        try beginTransaction()

        // Set up timeout if specified
        let timeoutTask: Task<Void, Never>?
        if let timeout = timeout {
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if self.isInTransaction {
                    try? self.rollback()
                }
            }
        } else {
            timeoutTask = nil
        }

        do {
            // Execute operation
            let result = try await operation()

            // Cancel timeout
            timeoutTask?.cancel()

            // Commit
            try commit()

            return .success(result)

        } catch {
            // Cancel timeout
            timeoutTask?.cancel()

            // Rollback
            try? rollback()

            return .failure(error)
        }
    }

    // MARK: - Savepoint Support

    /// Create a savepoint
    func createSavepoint(_ name: String) throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        let savepoint = Savepoint(name: name, depth: transactionDepth)
        savepoints.append(savepoint)
    }

    /// Rollback to a savepoint
    func rollbackToSavepoint(_ name: String) throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        guard let savepoint = savepoints.first(where: { $0.name == name }) else {
            throw TransactionError.savePointNotFound(name)
        }

        // Remove all savepoints after this one
        savepoints.removeAll { $0.timestamp > savepoint.timestamp }

        // Rollback context (note: SwiftData doesn't have native savepoint support,
        // so this does a full rollback - in production, you'd need to implement
        // manual state tracking or use Core Data)
        modelContext.rollback()
    }

    /// Release a savepoint
    func releaseSavepoint(_ name: String) throws {
        guard let index = savepoints.firstIndex(where: { $0.name == name }) else {
            throw TransactionError.savePointNotFound(name)
        }

        savepoints.remove(at: index)
    }

    // MARK: - Nested Transaction Support

    /// Begin a nested transaction
    func beginNestedTransaction() throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        guard transactionDepth < Self.maxNestedDepth else {
            throw TransactionError.nestedTransactionLimit
        }

        transactionDepth += 1

        // Create automatic savepoint
        let savepointName = "nested_\(transactionDepth)_\(UUID().uuidString.prefix(8))"
        try createSavepoint(savepointName)
    }

    /// Commit nested transaction
    func commitNested() throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        guard transactionDepth > 1 else {
            // If at top level, do regular commit
            try commit()
            return
        }

        // Release the automatic savepoint
        if let lastSavepoint = savepoints.last {
            try releaseSavepoint(lastSavepoint.name)
        }

        transactionDepth -= 1
    }

    /// Rollback nested transaction
    func rollbackNested() throws {
        guard isInTransaction else {
            throw TransactionError.noTransactionInProgress
        }

        guard transactionDepth > 1 else {
            // If at top level, do regular rollback
            try rollback()
            return
        }

        // Rollback to the automatic savepoint
        if let lastSavepoint = savepoints.last {
            try rollbackToSavepoint(lastSavepoint.name)
            try releaseSavepoint(lastSavepoint.name)
        }

        transactionDepth -= 1
    }

    // MARK: - Atomic Multi-Entity Operations

    /// Perform atomic insert of multiple entities
    func atomicInsert<T: PersistentModel>(_ entities: [T]) async throws -> TransactionResult<Int> {
        return try await performAsyncTransaction {
            for entity in entities {
                self.modelContext.insert(entity)
            }

            return entities.count
        }
    }

    /// Perform atomic delete of multiple entities
    func atomicDelete<T: PersistentModel>(_ entities: [T]) async throws -> TransactionResult<Int> {
        return try await performAsyncTransaction {
            for entity in entities {
                self.modelContext.delete(entity)
            }

            return entities.count
        }
    }

    /// Perform atomic update with validation
    func atomicUpdate<T>(
        validation: @escaping () throws -> Bool,
        update: @escaping () throws -> T
    ) async throws -> TransactionResult<T> {
        return try await performAsyncTransaction {
            // Validate first
            guard try validation() else {
                throw TransactionError.commitFailed("Validation failed")
            }

            // Perform update
            return try update()
        }
    }

    // MARK: - Statistics

    /// Get transaction statistics
    func getStatistics() -> TransactionStatistics {
        return statistics
    }

    /// Reset statistics
    func resetStatistics() {
        statistics = TransactionStatistics()
    }

    // MARK: - Private Helpers

    private func recordTransactionCompletion(success: Bool, rolledBack: Bool) {
        guard let startTime = transactionStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)
        statistics.recordTransaction(
            success: success,
            rolledBack: rolledBack,
            duration: duration
        )
    }

    // MARK: - State Queries

    /// Check if transaction is in progress
    var hasActiveTransaction: Bool {
        return isInTransaction
    }

    /// Get current transaction depth
    var currentDepth: Int {
        return transactionDepth
    }

    /// Get active savepoints
    var activeSavepoints: [String] {
        return savepoints.map { $0.name }
    }
}

// MARK: - Convenience Extensions

extension DatabaseTransactionManager {

    /// Execute operation with automatic rollback on error
    func withTransaction<T>(_ operation: () throws -> T) async throws -> T {
        let result = try await performTransaction(operation: operation)

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .rolledBack:
            throw TransactionError.rollbackFailed("Transaction was rolled back")
        }
    }

    /// Execute async operation with automatic rollback on error
    func withAsyncTransaction<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        let result = try await performAsyncTransaction(operation: operation)

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .rolledBack:
            throw TransactionError.rollbackFailed("Transaction was rolled back")
        }
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic transaction:
 ```swift
 let transactionManager = DatabaseTransactionManager(modelContext: context)

 let result = try await transactionManager.performTransaction {
     // Insert multiple entities
     context.insert(person1)
     context.insert(person2)

     return 2
 }

 if result.isSuccess {
     print("Inserted \(result.value!) people")
 }
 ```

 2. Transaction with timeout:
 ```swift
 let result = try await transactionManager.performAsyncTransaction(timeout: 5.0) {
     // Long-running operation
     try await someAsyncOperation()

     return "Success"
 }
 ```

 3. Using savepoints:
 ```swift
 try transactionManager.beginTransaction()

 context.insert(person1)

 try transactionManager.createSavepoint("after_person1")

 context.insert(person2)

 // Oops, person2 had an error, rollback to savepoint
 try transactionManager.rollbackToSavepoint("after_person1")

 try transactionManager.commit()
 ```

 4. Nested transactions:
 ```swift
 try transactionManager.beginTransaction()

 context.insert(person1)

 try transactionManager.beginNestedTransaction()

 context.insert(person2)

 try transactionManager.commitNested()

 try transactionManager.commit()
 ```

 5. Atomic multi-entity operations:
 ```swift
 let people = [person1, person2, person3]
 let result = try await transactionManager.atomicInsert(people)

 print("Inserted \(result.value!) people")
 ```

 6. Convenience wrapper:
 ```swift
 let count = try await transactionManager.withTransaction {
     context.insert(person1)
     context.insert(person2)
     return 2
 }
 ```
 */
