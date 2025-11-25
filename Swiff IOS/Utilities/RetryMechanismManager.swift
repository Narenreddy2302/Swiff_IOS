//
//  RetryMechanismManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 6.3: Comprehensive retry mechanisms with circuit breaker
//

import Foundation
import Combine

// MARK: - Retry Policy

enum RetryPolicy {
    case exponential(baseDelay: TimeInterval, multiplier: Double, maxDelay: TimeInterval)
    case linear(delay: TimeInterval)
    case fibonacci(baseDelay: TimeInterval)
    case custom((Int) -> TimeInterval)

    func delay(forAttempt attempt: Int) -> TimeInterval {
        switch self {
        case .exponential(let base, let multiplier, let max):
            let delay = base * pow(multiplier, Double(attempt - 1))
            return min(delay, max)

        case .linear(let delay):
            return delay

        case .fibonacci(let base):
            return base * Double(fibonacci(attempt))

        case .custom(let calculator):
            return calculator(attempt)
        }
    }

    private func fibonacci(_ n: Int) -> Int {
        guard n > 1 else { return n }
        var a = 0, b = 1
        for _ in 2...n {
            let temp = a + b
            a = b
            b = temp
        }
        return b
    }
}

// MARK: - Retry Configuration

struct RetryConfiguration {
    let maxAttempts: Int
    let policy: RetryPolicy
    let shouldRetry: (Error) -> Bool
    let onRetry: ((Int, Error) -> Void)?

    nonisolated static let `default` = RetryConfiguration(
        maxAttempts: 3,
        policy: .exponential(baseDelay: 1.0, multiplier: 2.0, maxDelay: 10.0),
        shouldRetry: { error in
            if let appError = error as? ApplicationError {
                return appError.isRetryable
            }
            return true
        },
        onRetry: nil
    )

    static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        policy: .exponential(baseDelay: 0.5, multiplier: 1.5, maxDelay: 5.0),
        shouldRetry: { _ in true },
        onRetry: nil
    )

    static let conservative = RetryConfiguration(
        maxAttempts: 2,
        policy: .linear(delay: 2.0),
        shouldRetry: { error in
            if let appError = error as? ApplicationError {
                return appError.isRetryable
            }
            return false
        },
        onRetry: nil
    )

    static let networkRetry = RetryConfiguration(
        maxAttempts: 3,
        policy: .exponential(baseDelay: 1.0, multiplier: 2.0, maxDelay: 8.0),
        shouldRetry: { error in
            if let networkError = error as? NetworkError {
                return networkError.isRetryable
            }
            return false
        },
        onRetry: nil
    )
}

// MARK: - Retry Result

struct RetryResult<T> {
    let value: T?
    let error: Error?
    let attempts: Int
    let totalDuration: TimeInterval
    let wasSuccessful: Bool

    var summary: String {
        if wasSuccessful {
            return "✅ Success after \(attempts) attempt(s) in \(String(format: "%.2f", totalDuration))s"
        } else {
            return "❌ Failed after \(attempts) attempt(s) in \(String(format: "%.2f", totalDuration))s"
        }
    }
}

// MARK: - Circuit Breaker State

enum CircuitBreakerState {
    case closed
    case open
    case halfOpen

    var displayName: String {
        switch self {
        case .closed: return "Closed"
        case .open: return "Open"
        case .halfOpen: return "Half-Open"
        }
    }
}

// MARK: - Circuit Breaker Configuration

struct CircuitBreakerConfiguration {
    let failureThreshold: Int
    let successThreshold: Int
    let timeout: TimeInterval

    nonisolated static let `default` = CircuitBreakerConfiguration(
        failureThreshold: 5,
        successThreshold: 2,
        timeout: 60.0
    )

    static let strict = CircuitBreakerConfiguration(
        failureThreshold: 3,
        successThreshold: 1,
        timeout: 30.0
    )

    static let relaxed = CircuitBreakerConfiguration(
        failureThreshold: 10,
        successThreshold: 3,
        timeout: 120.0
    )
}

// MARK: - Circuit Breaker

@MainActor
class CircuitBreaker {

    private(set) var state: CircuitBreakerState = .closed
    private var failureCount = 0
    private var successCount = 0
    private var lastFailureTime: Date?

    private let configuration: CircuitBreakerConfiguration
    private let name: String

    init(name: String, configuration: CircuitBreakerConfiguration = .default) {
        self.name = name
        self.configuration = configuration
    }

    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        try checkState()

        do {
            let result = try await operation()
            recordSuccess()
            return result
        } catch {
            recordFailure()
            throw error
        }
    }

    private func checkState() throws {
        switch state {
        case .closed:
            // Normal operation
            break

        case .open:
            // Check if timeout has elapsed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= configuration.timeout {
                state = .halfOpen
                successCount = 0
            } else {
                throw CircuitBreakerError.circuitOpen(name: name)
            }

        case .halfOpen:
            // Allow request to test if service is back
            break
        }
    }

    private func recordSuccess() {
        switch state {
        case .closed:
            failureCount = 0

        case .halfOpen:
            successCount += 1
            if successCount >= configuration.successThreshold {
                state = .closed
                failureCount = 0
                successCount = 0
            }

        case .open:
            break
        }
    }

    private func recordFailure() {
        lastFailureTime = Date()

        switch state {
        case .closed:
            failureCount += 1
            if failureCount >= configuration.failureThreshold {
                state = .open
            }

        case .halfOpen:
            state = .open
            failureCount = 0
            successCount = 0

        case .open:
            break
        }
    }

    func reset() {
        state = .closed
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
    }

    var statistics: String {
        var stats = "=== Circuit Breaker: \(name) ===\n"
        stats += "State: \(state.displayName)\n"
        stats += "Failures: \(failureCount)/\(configuration.failureThreshold)\n"
        stats += "Successes: \(successCount)/\(configuration.successThreshold)\n"

        if let lastFailure = lastFailureTime {
            let elapsed = Date().timeIntervalSince(lastFailure)
            stats += "Time Since Last Failure: \(String(format: "%.1f", elapsed))s\n"
        }

        return stats
    }
}

// MARK: - Circuit Breaker Error

enum CircuitBreakerError: LocalizedError {
    case circuitOpen(name: String)

    var errorDescription: String? {
        switch self {
        case .circuitOpen(let name):
            return "Circuit breaker '\(name)' is open. Service is temporarily unavailable."
        }
    }

    var recoverySuggestion: String? {
        "Wait a moment and try again. The service should recover automatically."
    }
}

// MARK: - Retry Mechanism Manager

@MainActor
class RetryMechanismManager {

    static let shared = RetryMechanismManager()

    private var circuitBreakers: [String: CircuitBreaker] = [:]
    private let logger = ErrorLogger.shared

    // MARK: - Retry with Configuration

    func retry<T>(
        configuration: RetryConfiguration = .default,
        operation: @escaping () async throws -> T
    ) async -> RetryResult<T> {
        let startTime = Date()
        var lastError: Error?
        var attempts = 0

        for attempt in 1...configuration.maxAttempts {
            attempts = attempt

            do {
                let result = try await operation()
                let duration = Date().timeIntervalSince(startTime)

                logger.info(
                    "Operation succeeded on attempt \(attempt)",
                    category: "Retry",
                    metadata: [
                        "attempts": String(attempt),
                        "duration": String(format: "%.2f", duration)
                    ]
                )

                return RetryResult(
                    value: result,
                    error: nil,
                    attempts: attempt,
                    totalDuration: duration,
                    wasSuccessful: true
                )

            } catch {
                lastError = error

                // Check if we should retry
                guard configuration.shouldRetry(error) else {
                    logger.warning(
                        "Error not retryable",
                        category: "Retry",
                        metadata: ["error": error.localizedDescription]
                    )
                    break
                }

                // Check if we have more attempts
                guard attempt < configuration.maxAttempts else {
                    logger.error(
                        "Max retry attempts reached",
                        category: "Retry",
                        metadata: ["maxAttempts": String(configuration.maxAttempts)]
                    )
                    break
                }

                // Call retry callback
                configuration.onRetry?(attempt, error)

                // Wait before retrying
                let delay = configuration.policy.delay(forAttempt: attempt)

                logger.debug(
                    "Retrying after delay",
                    category: "Retry",
                    metadata: [
                        "attempt": String(attempt),
                        "delay": String(format: "%.2f", delay),
                        "error": error.localizedDescription
                    ]
                )

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        return RetryResult(
            value: nil,
            error: lastError,
            attempts: attempts,
            totalDuration: duration,
            wasSuccessful: false
        )
    }

    // MARK: - Retry with Circuit Breaker

    func retryWithCircuitBreaker<T>(
        name: String,
        configuration: RetryConfiguration = .default,
        circuitBreakerConfig: CircuitBreakerConfiguration = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Get or create circuit breaker
        let breaker = getCircuitBreaker(name: name, configuration: circuitBreakerConfig)

        // Execute with circuit breaker
        return try await breaker.execute {
            let result = await self.retry(configuration: configuration, operation: operation)

            if let value = result.value {
                return value
            } else if let error = result.error {
                throw error
            } else {
                throw RetryError.maxAttemptsExceeded(attempts: result.attempts)
            }
        }
    }

    // MARK: - Circuit Breaker Management

    func getCircuitBreaker(
        name: String,
        configuration: CircuitBreakerConfiguration = .default
    ) -> CircuitBreaker {
        if let existing = circuitBreakers[name] {
            return existing
        }

        let breaker = CircuitBreaker(name: name, configuration: configuration)
        circuitBreakers[name] = breaker
        return breaker
    }

    func resetCircuitBreaker(name: String) {
        circuitBreakers[name]?.reset()
    }

    func removeCircuitBreaker(name: String) {
        circuitBreakers.removeValue(forKey: name)
    }

    func getAllCircuitBreakers() -> [String: CircuitBreaker] {
        return circuitBreakers
    }

    // MARK: - Statistics

    func getStatistics() -> String {
        var stats = "=== Retry Mechanism Statistics ===\n\n"
        stats += "Active Circuit Breakers: \(circuitBreakers.count)\n\n"

        if !circuitBreakers.isEmpty {
            for (_, breaker) in circuitBreakers.sorted(by: { $0.key < $1.key }) {
                stats += breaker.statistics + "\n"
            }
        }

        return stats
    }
}

// MARK: - Retry Error

enum RetryError: LocalizedError {
    case maxAttemptsExceeded(attempts: Int)
    case notRetryable(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .maxAttemptsExceeded(let attempts):
            return "Operation failed after \(attempts) retry attempts"
        case .notRetryable(let error):
            return "Operation not retryable: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .maxAttemptsExceeded:
            return "The operation failed multiple times. Please try again later."
        case .notRetryable:
            return "This error cannot be automatically retried. Please fix the issue and try again."
        }
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic retry with default configuration:
 ```swift
 let manager = RetryMechanismManager.shared

 let result = await manager.retry {
     return try await performNetworkRequest()
 }

 if let data = result.value {
     print("Success: \(data)")
 } else {
     print("Failed: \(result.error?.localizedDescription ?? "Unknown error")")
 }
 ```

 2. Custom retry configuration:
 ```swift
 let config = RetryConfiguration(
     maxAttempts: 5,
     policy: .exponential(baseDelay: 1.0, multiplier: 2.0, maxDelay: 10.0),
     shouldRetry: { error in
         // Only retry network errors
         return error is NetworkError
     },
     onRetry: { attempt, error in
         print("Retry attempt \(attempt): \(error)")
     }
 )

 let result = await manager.retry(configuration: config) {
     return try await fetchData()
 }
 ```

 3. Retry with circuit breaker:
 ```swift
 do {
     let data = try await manager.retryWithCircuitBreaker(
         name: "API",
         configuration: .networkRetry,
         circuitBreakerConfig: .default
     ) {
         return try await callAPI()
     }
     print("Success: \(data)")
 } catch CircuitBreakerError.circuitOpen {
     print("Service temporarily unavailable")
 } catch {
     print("Request failed: \(error)")
 }
 ```

 4. Different retry policies:
 ```swift
 // Exponential backoff
 let exponential = RetryConfiguration(
     maxAttempts: 3,
     policy: .exponential(baseDelay: 1.0, multiplier: 2.0, maxDelay: 10.0),
     shouldRetry: { _ in true },
     onRetry: nil
 )

 // Linear delay
 let linear = RetryConfiguration(
     maxAttempts: 3,
     policy: .linear(delay: 2.0),
     shouldRetry: { _ in true },
     onRetry: nil
 )

 // Fibonacci backoff
 let fibonacci = RetryConfiguration(
     maxAttempts: 5,
     policy: .fibonacci(baseDelay: 1.0),
     shouldRetry: { _ in true },
     onRetry: nil
 )

 // Custom policy
 let custom = RetryConfiguration(
     maxAttempts: 3,
     policy: .custom { attempt in
         return Double(attempt * attempt) // Quadratic backoff
     },
     shouldRetry: { _ in true },
     onRetry: nil
 )
 ```

 5. Circuit breaker management:
 ```swift
 // Get circuit breaker
 let breaker = manager.getCircuitBreaker(name: "Database")

 // Check state
 print("State: \(breaker.state)")

 // Reset circuit breaker
 manager.resetCircuitBreaker(name: "Database")

 // Get statistics
 print(breaker.statistics)
 ```

 6. Get all statistics:
 ```swift
 let stats = manager.getStatistics()
 print(stats)
 ```
 */
