//
//  AsyncTimeoutManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 2.1: Async Operation Timeouts
//

import Foundation

// MARK: - Timeout Error

enum TimeoutError: LocalizedError {
    case operationTimedOut(operation: String, duration: TimeInterval)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .operationTimedOut(let operation, let duration):
            return "Operation '\(operation)' timed out after \(duration) seconds"
        case .cancelled:
            return "Operation was cancelled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .operationTimedOut:
            return "Please check your network connection and try again"
        case .cancelled:
            return "Operation was cancelled by user or system"
        }
    }
}

// MARK: - Async Timeout Manager

actor AsyncTimeoutManager {

    // MARK: - Timeout Configuration

    enum OperationType {
        case network
        case database
        case fileSystem
        case backup
        case export
        case custom(name: String)

        var defaultTimeout: TimeInterval {
            switch self {
            case .network:
                return 30.0  // 30 seconds for network operations
            case .database:
                return 10.0  // 10 seconds for database operations
            case .fileSystem:
                return 15.0  // 15 seconds for file operations
            case .backup:
                return 120.0 // 2 minutes for backup operations
            case .export:
                return 60.0  // 1 minute for export operations
            case .custom:
                return 30.0  // 30 seconds default for custom operations
            }
        }

        var operationName: String {
            switch self {
            case .network:
                return "Network"
            case .database:
                return "Database"
            case .fileSystem:
                return "File System"
            case .backup:
                return "Backup"
            case .export:
                return "Export"
            case .custom(let name):
                return name
            }
        }
    }

    // MARK: - Execute with Timeout

    /// Execute an async operation with a timeout
    /// - Parameters:
    ///   - timeout: Timeout duration in seconds (defaults to operation type's default)
    ///   - operationType: Type of operation being performed
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: TimeoutError if operation exceeds timeout, or operation's error
    func withTimeout<T>(
        timeout: TimeInterval? = nil,
        operationType: OperationType,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let timeoutDuration = timeout ?? operationType.defaultTimeout
        let operationName = operationType.operationName

        return try await withThrowingTaskGroup(of: T.self) { group in

            // Add the actual operation
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
                throw TimeoutError.operationTimedOut(operation: operationName, duration: timeoutDuration)
            }

            // Wait for first task to complete
            guard let result = try await group.next() else {
                throw TimeoutError.cancelled
            }

            // Cancel remaining tasks
            group.cancelAll()

            return result
        }
    }

    // MARK: - Execute with Retry and Timeout

    /// Execute an async operation with retry logic and timeout
    /// - Parameters:
    ///   - timeout: Timeout duration in seconds
    ///   - operationType: Type of operation
    ///   - maxRetries: Maximum number of retry attempts
    ///   - retryDelay: Delay between retries in seconds
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: Last error encountered after all retries
    func withRetryAndTimeout<T>(
        timeout: TimeInterval? = nil,
        operationType: OperationType,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attempt = 0

        while attempt <= maxRetries {
            do {
                let result = try await withTimeout(
                    timeout: timeout,
                    operationType: operationType,
                    operation: operation
                )
                return result

            } catch {
                lastError = error
                attempt += 1

                if attempt <= maxRetries {
                    print("⚠️ \(operationType.operationName) attempt \(attempt) failed: \(error.localizedDescription)")
                    print("   Retrying in \(retryDelay)s...")

                    // Wait before retry
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }

        // All retries exhausted
        throw lastError ?? TimeoutError.cancelled
    }

    // MARK: - Execute with Progress

    /// Execute an async operation with timeout and progress reporting
    /// - Parameters:
    ///   - timeout: Timeout duration in seconds
    ///   - operationType: Type of operation
    ///   - progressHandler: Closure called with progress updates (0.0 to 1.0)
    ///   - operation: The async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: TimeoutError or operation's error
    func withTimeoutAndProgress<T>(
        timeout: TimeInterval? = nil,
        operationType: OperationType,
        progressHandler: @escaping @Sendable (Double) -> Void,
        operation: @escaping @Sendable (_ updateProgress: @escaping @Sendable (Double) -> Void) async throws -> T
    ) async throws -> T {
        let timeoutDuration = timeout ?? operationType.defaultTimeout

        return try await withThrowingTaskGroup(of: T.self) { group in

            // Add the actual operation with progress
            group.addTask {
                try await operation { progress in
                    progressHandler(progress)
                }
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
                throw TimeoutError.operationTimedOut(
                    operation: operationType.operationName,
                    duration: timeoutDuration
                )
            }

            // Wait for first task to complete
            guard let result = try await group.next() else {
                throw TimeoutError.cancelled
            }

            // Cancel remaining tasks
            group.cancelAll()

            return result
        }
    }

    // MARK: - Check if Operation Timed Out

    /// Check if an error is a timeout error
    static func isTimeoutError(_ error: Error) -> Bool {
        if error is TimeoutError {
            return true
        }
        return false
    }
}

// MARK: - Convenience Extensions

extension AsyncTimeoutManager {

    /// Execute a network request with timeout
    static func networkRequest<T>(
        timeout: TimeInterval = 30.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let manager = AsyncTimeoutManager()
        return try await manager.withTimeout(
            timeout: timeout,
            operationType: .network,
            operation: operation
        )
    }

    /// Execute a database operation with timeout
    static func databaseOperation<T>(
        timeout: TimeInterval = 10.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let manager = AsyncTimeoutManager()
        return try await manager.withTimeout(
            timeout: timeout,
            operationType: .database,
            operation: operation
        )
    }

    /// Execute a backup operation with timeout
    static func backupOperation<T>(
        timeout: TimeInterval = 120.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let manager = AsyncTimeoutManager()
        return try await manager.withTimeout(
            timeout: timeout,
            operationType: .backup,
            operation: operation
        )
    }

    /// Execute an export operation with timeout
    static func exportOperation<T>(
        timeout: TimeInterval = 60.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let manager = AsyncTimeoutManager()
        return try await manager.withTimeout(
            timeout: timeout,
            operationType: .export,
            operation: operation
        )
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic timeout:
 ```swift
 let manager = AsyncTimeoutManager()
 let result = try await manager.withTimeout(
     timeout: 10.0,
     operationType: .database
 ) {
     // Your async operation
     return await fetchData()
 }
 ```

 2. With retry:
 ```swift
 let manager = AsyncTimeoutManager()
 let result = try await manager.withRetryAndTimeout(
     timeout: 30.0,
     operationType: .network,
     maxRetries: 3,
     retryDelay: 2.0
 ) {
     // Your async network request
     return await API.fetchData()
 }
 ```

 3. Convenience method:
 ```swift
 let data = try await AsyncTimeoutManager.networkRequest(timeout: 20.0) {
     return await API.fetchData()
 }
 ```

 4. With progress:
 ```swift
 let manager = AsyncTimeoutManager()
 let result = try await manager.withTimeoutAndProgress(
     timeout: 120.0,
     operationType: .backup,
     progressHandler: { progress in
         print("Progress: \(progress * 100)%")
     }
 ) { updateProgress in
     // Your operation with progress updates
     updateProgress(0.5)
     return await performBackup()
 }
 ```
 */
