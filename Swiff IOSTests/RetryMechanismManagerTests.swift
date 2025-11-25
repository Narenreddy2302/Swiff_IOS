//
//  RetryMechanismManagerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for RetryMechanismManager - Phase 6.3
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class RetryMechanismManagerTests: XCTestCase {

    var manager: RetryMechanismManager!

    override func setUp() async throws {
        try await super.setUp()
        manager = RetryMechanismManager.shared
    }

    override func tearDown() async throws {
        // Reset all circuit breakers
        for name in manager.getAllCircuitBreakers().keys {
            manager.resetCircuitBreaker(name: name)
        }
        manager = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Retry Policies

    func testExponentialBackoffPolicy() {
        let policy = RetryPolicy.exponential(baseDelay: 1.0, multiplier: 2.0, maxDelay: 10.0)

        let delay1 = policy.delay(forAttempt: 1)
        let delay2 = policy.delay(forAttempt: 2)
        let delay3 = policy.delay(forAttempt: 3)

        XCTAssertEqual(delay1, 1.0) // 1.0 * 2^0
        XCTAssertEqual(delay2, 2.0) // 1.0 * 2^1
        XCTAssertEqual(delay3, 4.0) // 1.0 * 2^2
    }

    func testExponentialBackoffMaxDelay() {
        let policy = RetryPolicy.exponential(baseDelay: 1.0, multiplier: 2.0, maxDelay: 5.0)

        let delay10 = policy.delay(forAttempt: 10)
        XCTAssertLessThanOrEqual(delay10, 5.0)
    }

    func testLinearPolicy() {
        let policy = RetryPolicy.linear(delay: 2.0)

        let delay1 = policy.delay(forAttempt: 1)
        let delay2 = policy.delay(forAttempt: 2)
        let delay3 = policy.delay(forAttempt: 3)

        XCTAssertEqual(delay1, 2.0)
        XCTAssertEqual(delay2, 2.0)
        XCTAssertEqual(delay3, 2.0)
    }

    func testFibonacciPolicy() {
        let policy = RetryPolicy.fibonacci(baseDelay: 1.0)

        let delay1 = policy.delay(forAttempt: 1)
        let delay2 = policy.delay(forAttempt: 2)
        let delay3 = policy.delay(forAttempt: 3)
        let delay4 = policy.delay(forAttempt: 4)

        XCTAssertEqual(delay1, 1.0) // 1 * 1
        XCTAssertEqual(delay2, 1.0) // 1 * 1
        XCTAssertEqual(delay3, 2.0) // 1 * 2
        XCTAssertEqual(delay4, 3.0) // 1 * 3
    }

    func testCustomPolicy() {
        let policy = RetryPolicy.custom { attempt in
            return Double(attempt * 2)
        }

        let delay1 = policy.delay(forAttempt: 1)
        let delay2 = policy.delay(forAttempt: 2)

        XCTAssertEqual(delay1, 2.0)
        XCTAssertEqual(delay2, 4.0)
    }

    // MARK: - Test 2: Retry Configurations

    func testDefaultConfiguration() {
        let config = RetryConfiguration.default

        XCTAssertEqual(config.maxAttempts, 3)
    }

    func testAggressiveConfiguration() {
        let config = RetryConfiguration.aggressive

        XCTAssertEqual(config.maxAttempts, 5)
    }

    func testConservativeConfiguration() {
        let config = RetryConfiguration.conservative

        XCTAssertEqual(config.maxAttempts, 2)
    }

    func testNetworkRetryConfiguration() {
        let config = RetryConfiguration.networkRetry

        XCTAssertEqual(config.maxAttempts, 3)
    }

    // MARK: - Test 3: Retry Success

    func testRetrySuccessOnFirstAttempt() async {
        var callCount = 0

        let result = await manager.retry {
            callCount += 1
            return "Success"
        }

        XCTAssertTrue(result.wasSuccessful)
        XCTAssertEqual(result.value, "Success")
        XCTAssertEqual(result.attempts, 1)
        XCTAssertEqual(callCount, 1)
    }

    func testRetrySuccessOnSecondAttempt() async {
        var callCount = 0

        let result = await manager.retry {
            callCount += 1
            if callCount < 2 {
                throw NSError(domain: "test", code: 1)
            }
            return "Success"
        }

        XCTAssertTrue(result.wasSuccessful)
        XCTAssertEqual(result.value, "Success")
        XCTAssertEqual(result.attempts, 2)
        XCTAssertEqual(callCount, 2)
    }

    // MARK: - Test 4: Retry Failure

    func testRetryFailureAfterMaxAttempts() async {
        var callCount = 0

        let config = RetryConfiguration(
            maxAttempts: 3,
            policy: .linear(delay: 0.1),
            shouldRetry: { _ in true },
            onRetry: nil
        )

        let result = await manager.retry(configuration: config) {
            callCount += 1
            throw NSError(domain: "test", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Test error"
            ])
        }

        XCTAssertFalse(result.wasSuccessful)
        XCTAssertNil(result.value)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.attempts, 3)
        XCTAssertEqual(callCount, 3)
    }

    func testRetryNotRetryableError() async {
        var callCount = 0

        let config = RetryConfiguration(
            maxAttempts: 3,
            policy: .linear(delay: 0.1),
            shouldRetry: { _ in false },
            onRetry: nil
        )

        let result = await manager.retry(configuration: config) {
            callCount += 1
            throw NSError(domain: "test", code: 1)
        }

        XCTAssertFalse(result.wasSuccessful)
        XCTAssertEqual(result.attempts, 1) // Only one attempt
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Test 5: Circuit Breaker States

    func testCircuitBreakerInitialState() {
        let breaker = manager.getCircuitBreaker(name: "test")

        XCTAssertEqual(breaker.state, .closed)
    }

    func testCircuitBreakerOpensAfterFailures() async {
        let config = CircuitBreakerConfiguration(
            failureThreshold: 2,
            successThreshold: 1,
            timeout: 1.0
        )

        let breaker = manager.getCircuitBreaker(name: "test-open", configuration: config)

        // Execute failures
        for _ in 1...2 {
            _ = try? await breaker.execute {
                throw NSError(domain: "test", code: 1)
            }
        }

        XCTAssertEqual(breaker.state, .open)
    }

    func testCircuitBreakerHalfOpenAfterTimeout() async throws {
        let config = CircuitBreakerConfiguration(
            failureThreshold: 1,
            successThreshold: 1,
            timeout: 0.5
        )

        let breaker = manager.getCircuitBreaker(name: "test-timeout", configuration: config)

        // Trigger failure
        _ = try? await breaker.execute {
            throw NSError(domain: "test", code: 1)
        }

        XCTAssertEqual(breaker.state, .open)

        // Wait for timeout
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        // Next request should transition to half-open
        _ = try? await breaker.execute {
            throw NSError(domain: "test", code: 1)
        }

        // After failure in half-open, it goes back to open
        XCTAssertEqual(breaker.state, .open)
    }

    func testCircuitBreakerClosesAfterSuccesses() async throws {
        let config = CircuitBreakerConfiguration(
            failureThreshold: 1,
            successThreshold: 2,
            timeout: 0.5
        )

        let breaker = manager.getCircuitBreaker(name: "test-close", configuration: config)

        // Trigger failure to open circuit
        _ = try? await breaker.execute {
            throw NSError(domain: "test", code: 1)
        }

        XCTAssertEqual(breaker.state, .open)

        // Wait for timeout
        try await Task.sleep(nanoseconds: 600_000_000)

        // Execute successes
        _ = try? await breaker.execute { return "success" }
        _ = try? await breaker.execute { return "success" }

        XCTAssertEqual(breaker.state, .closed)
    }

    // MARK: - Test 6: Circuit Breaker Error

    func testCircuitBreakerErrorWhenOpen() async {
        let config = CircuitBreakerConfiguration(
            failureThreshold: 1,
            successThreshold: 1,
            timeout: 10.0
        )

        let breaker = manager.getCircuitBreaker(name: "test-error", configuration: config)

        // Open circuit
        _ = try? await breaker.execute {
            throw NSError(domain: "test", code: 1)
        }

        // Try to execute while open
        do {
            _ = try await breaker.execute { return "value" }
            XCTFail("Should throw circuit open error")
        } catch {
            XCTAssertTrue(error is CircuitBreakerError)
        }
    }

    // MARK: - Test 7: Retry Result

    func testRetryResultSummary() async {
        let result = await manager.retry {
            return "Success"
        }

        let summary = result.summary
        XCTAssertTrue(summary.contains("Success"))
        XCTAssertTrue(summary.contains("attempt"))
    }

    func testRetryResultDuration() async {
        let config = RetryConfiguration(
            maxAttempts: 2,
            policy: .linear(delay: 0.1),
            shouldRetry: { _ in true },
            onRetry: nil
        )

        let result = await manager.retry(configuration: config) {
            throw NSError(domain: "test", code: 1)
        }

        XCTAssertGreaterThan(result.totalDuration, 0.1) // At least one retry delay
    }

    // MARK: - Test 8: Circuit Breaker Management

    func testGetCircuitBreaker() {
        let breaker1 = manager.getCircuitBreaker(name: "test1")
        let breaker2 = manager.getCircuitBreaker(name: "test1") // Same name

        // Should return same instance
        XCTAssertTrue(breaker1 === breaker2)
    }

    func testResetCircuitBreaker() async {
        let breaker = manager.getCircuitBreaker(name: "test-reset")

        // Open circuit
        _ = try? await breaker.execute {
            throw NSError(domain: "test", code: 1)
        }

        manager.resetCircuitBreaker(name: "test-reset")

        XCTAssertEqual(breaker.state, .closed)
    }

    func testRemoveCircuitBreaker() {
        _ = manager.getCircuitBreaker(name: "test-remove")
        manager.removeCircuitBreaker(name: "test-remove")

        let breakers = manager.getAllCircuitBreakers()
        XCTAssertNil(breakers["test-remove"])
    }

    func testGetAllCircuitBreakers() {
        _ = manager.getCircuitBreaker(name: "test1")
        _ = manager.getCircuitBreaker(name: "test2")

        let all = manager.getAllCircuitBreakers()
        XCTAssertGreaterThanOrEqual(all.count, 2)
    }

    // MARK: - Test 9: Statistics

    func testCircuitBreakerStatistics() {
        let breaker = manager.getCircuitBreaker(name: "test-stats")
        let stats = breaker.statistics

        XCTAssertTrue(stats.contains("Circuit Breaker"))
        XCTAssertTrue(stats.contains("State:"))
        XCTAssertTrue(stats.contains("Failures:"))
    }

    func testManagerStatistics() {
        _ = manager.getCircuitBreaker(name: "stats1")
        _ = manager.getCircuitBreaker(name: "stats2")

        let stats = manager.getStatistics()

        XCTAssertTrue(stats.contains("Retry Mechanism Statistics"))
        XCTAssertTrue(stats.contains("Active Circuit Breakers:"))
    }

    // MARK: - Test 10: Retry Callback

    func testRetryCallback() async {
        var callbackCount = 0

        let config = RetryConfiguration(
            maxAttempts: 3,
            policy: .linear(delay: 0.1),
            shouldRetry: { _ in true },
            onRetry: { attempt, error in
                callbackCount += 1
            }
        )

        _ = await manager.retry(configuration: config) {
            throw NSError(domain: "test", code: 1)
        }

        XCTAssertEqual(callbackCount, 2) // Called for attempts 1 and 2 (not the last failure)
    }

    // MARK: - Test 11: Edge Cases

    func testRetryWithZeroDelay() async {
        let config = RetryConfiguration(
            maxAttempts: 2,
            policy: .linear(delay: 0.0),
            shouldRetry: { _ in true },
            onRetry: nil
        )

        var callCount = 0

        let result = await manager.retry(configuration: config) {
            callCount += 1
            if callCount < 2 {
                throw NSError(domain: "test", code: 1)
            }
            return "Success"
        }

        XCTAssertTrue(result.wasSuccessful)
        XCTAssertEqual(callCount, 2)
    }

    func testCircuitBreakerConfigurationPresets() {
        let defaultConfig = CircuitBreakerConfiguration.default
        let strictConfig = CircuitBreakerConfiguration.strict
        let relaxedConfig = CircuitBreakerConfiguration.relaxed

        XCTAssertEqual(defaultConfig.failureThreshold, 5)
        XCTAssertEqual(strictConfig.failureThreshold, 3)
        XCTAssertEqual(relaxedConfig.failureThreshold, 10)
    }
}
