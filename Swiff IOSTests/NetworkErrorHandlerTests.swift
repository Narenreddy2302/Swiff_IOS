//
//  NetworkErrorHandlerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for NetworkErrorHandler - Phase 5.4
//

import XCTest
import Network
@testable import Swiff_IOS

@MainActor
final class NetworkErrorHandlerTests: XCTestCase {

    var handler: NetworkErrorHandler!

    override func setUp() async throws {
        try await super.setUp()
        handler = NetworkErrorHandler.shared
    }

    override func tearDown() async throws {
        handler = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Network Status

    func testNetworkStatusEnum() {
        XCTAssertTrue(NetworkStatus.connected.isConnected)
        XCTAssertFalse(NetworkStatus.disconnected.isConnected)
        XCTAssertFalse(NetworkStatus.unknown.isConnected)
    }

    func testGetNetworkStatus() {
        let status = handler.getNetworkStatus()
        XCTAssertTrue([.connected, .disconnected, .unknown].contains(status))
    }

    // MARK: - Test 2: Connection Type

    func testConnectionTypeDisplayNames() {
        XCTAssertEqual(NetworkConnectionType.wifi.displayName, "WiFi")
        XCTAssertEqual(NetworkConnectionType.cellular.displayName, "Cellular")
        XCTAssertEqual(NetworkConnectionType.ethernet.displayName, "Ethernet")
        XCTAssertEqual(NetworkConnectionType.unknown.displayName, "Unknown")
    }

    // MARK: - Test 3: Retry Configuration

    func testDefaultRetryConfiguration() {
        let config = RetryConfiguration.default

        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertEqual(config.baseDelay, 1.0)
        XCTAssertEqual(config.maxDelay, 10.0)
        XCTAssertEqual(config.multiplier, 2.0)
    }

    func testAggressiveRetryConfiguration() {
        let config = RetryConfiguration.aggressive

        XCTAssertEqual(config.maxRetries, 5)
        XCTAssertEqual(config.baseDelay, 0.5)
        XCTAssertEqual(config.maxDelay, 5.0)
    }

    func testConservativeRetryConfiguration() {
        let config = RetryConfiguration.conservative

        XCTAssertEqual(config.maxRetries, 2)
        XCTAssertEqual(config.baseDelay, 2.0)
        XCTAssertEqual(config.maxDelay, 15.0)
    }

    func testRetryDelayCalculation() {
        let config = RetryConfiguration.default

        let delay1 = config.delay(forAttempt: 1)
        let delay2 = config.delay(forAttempt: 2)
        let delay3 = config.delay(forAttempt: 3)

        XCTAssertEqual(delay1, 1.0) // 1.0 * 2^0
        XCTAssertEqual(delay2, 2.0) // 1.0 * 2^1
        XCTAssertEqual(delay3, 4.0) // 1.0 * 2^2
    }

    func testRetryDelayMaxLimit() {
        let config = RetryConfiguration.default

        let largeDelay = config.delay(forAttempt: 10)
        XCTAssertLessThanOrEqual(largeDelay, config.maxDelay)
    }

    // MARK: - Test 4: Error Classification

    func testClassifyURLErrorNotConnected() {
        let urlError = URLError(.notConnectedToInternet)
        let networkError = handler.classifyError(urlError)

        if case .offline = networkError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .offline error")
        }
    }

    func testClassifyURLErrorTimeout() {
        let urlError = URLError(.timedOut)
        let networkError = handler.classifyError(urlError)

        if case .timeout = networkError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .timeout error")
        }
    }

    func testClassifyURLErrorConnectionLost() {
        let urlError = URLError(.networkConnectionLost)
        let networkError = handler.classifyError(urlError)

        if case .connectionLost = networkError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .connectionLost error")
        }
    }

    func testClassifyURLErrorDNS() {
        let urlError = URLError(.cannotFindHost)
        let networkError = handler.classifyError(urlError)

        if case .dnsLookupFailed = networkError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .dnsLookupFailed error")
        }
    }

    func testClassifyURLErrorSSL() {
        let urlError = URLError(.secureConnectionFailed)
        let networkError = handler.classifyError(urlError)

        if case .sslError = networkError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .sslError error")
        }
    }

    func testClassifyURLErrorCancelled() {
        let urlError = URLError(.cancelled)
        let networkError = handler.classifyError(urlError)

        if case .requestCancelled = networkError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .requestCancelled error")
        }
    }

    // MARK: - Test 5: Status Code Classification

    func testClassifyStatusCode200() {
        let error = handler.classifyStatusCode(200)
        XCTAssertNil(error) // Success
    }

    func testClassifyStatusCode400() {
        let error = handler.classifyStatusCode(400)

        if case .clientError(let code) = error {
            XCTAssertEqual(code, 400)
        } else {
            XCTFail("Expected .clientError")
        }
    }

    func testClassifyStatusCode429() {
        let error = handler.classifyStatusCode(429)

        if case .rateLimitExceeded = error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .rateLimitExceeded")
        }
    }

    func testClassifyStatusCode500() {
        let error = handler.classifyStatusCode(500)

        if case .serverError(let code) = error {
            XCTAssertEqual(code, 500)
        } else {
            XCTFail("Expected .serverError")
        }
    }

    func testClassifyStatusCode503() {
        let error = handler.classifyStatusCode(503)

        if case .maintenanceMode = error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .maintenanceMode")
        }
    }

    // MARK: - Test 6: Error Retryability

    func testOfflineIsRetryable() {
        XCTAssertTrue(NetworkError.offline.isRetryable)
    }

    func testTimeoutIsRetryable() {
        XCTAssertTrue(NetworkError.timeout.isRetryable)
    }

    func testServerErrorIsRetryable() {
        XCTAssertTrue(NetworkError.serverError(statusCode: 500).isRetryable)
    }

    func testClientErrorNotRetryable() {
        XCTAssertFalse(NetworkError.clientError(statusCode: 400).isRetryable)
    }

    func testInvalidURLNotRetryable() {
        XCTAssertFalse(NetworkError.invalidURL.isRetryable)
    }

    func testCancelledNotRetryable() {
        XCTAssertFalse(NetworkError.requestCancelled.isRetryable)
    }

    // MARK: - Test 7: Error Messages

    func testOfflineErrorMessage() {
        let error = NetworkError.offline

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("internet"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testTimeoutErrorMessage() {
        let error = NetworkError.timeout

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("timed out"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testServerErrorMessage() {
        let error = NetworkError.serverError(statusCode: 500)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("500"))
    }

    func testRateLimitErrorMessage() {
        let error = NetworkError.rateLimitExceeded

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Too many"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    // MARK: - Test 8: Network Request Result

    func testSuccessfulRequestResult() {
        let result = NetworkRequestResult<String>(
            data: "test",
            statusCode: 200,
            error: nil,
            retryCount: 0,
            totalDuration: 1.5
        )

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.data, "test")
        XCTAssertEqual(result.statusCode, 200)
        XCTAssertNil(result.error)
    }

    func testFailedRequestResult() {
        let result = NetworkRequestResult<String>(
            data: nil,
            statusCode: 500,
            error: .serverError(statusCode: 500),
            retryCount: 3,
            totalDuration: 5.0
        )

        XCTAssertFalse(result.isSuccess)
        XCTAssertNil(result.data)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.retryCount, 3)
    }

    func testRequestResultSummary() {
        let successResult = NetworkRequestResult<String>(
            data: "test",
            statusCode: 200,
            error: nil,
            retryCount: 1,
            totalDuration: 2.5
        )

        let summary = successResult.summary
        XCTAssertTrue(summary.contains("Success"))
        XCTAssertTrue(summary.contains("1"))
    }

    // MARK: - Test 9: User Feedback Methods

    func testGetUserFriendlyMessage() {
        let error = NetworkError.offline
        let message = handler.getUserFriendlyMessage(for: error)

        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("internet"))
    }

    func testGetRecoverySuggestion() {
        let error = NetworkError.timeout
        let suggestion = handler.getRecoverySuggestion(for: error)

        XCTAssertNotNil(suggestion)
        XCTAssertFalse(suggestion!.isEmpty)
    }

    func testShouldShowRetryForRetryableError() {
        let error = NetworkError.timeout
        XCTAssertTrue(handler.shouldShowRetry(for: error))
    }

    func testShouldNotShowRetryForNonRetryableError() {
        let error = NetworkError.invalidURL
        XCTAssertFalse(handler.shouldShowRetry(for: error))
    }

    // MARK: - Test 10: Retry with Success

    func testPerformWithRetrySuccess() async throws {
        var attemptCount = 0

        let result = try await handler.performWithRetry(
            retryConfig: RetryConfiguration(
                maxRetries: 3,
                baseDelay: 0.1,
                maxDelay: 1.0,
                multiplier: 2.0
            )
        ) {
            attemptCount += 1
            return "Success"
        }

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.data, "Success")
        XCTAssertEqual(attemptCount, 1)
    }

    // MARK: - Test 11: Retry with Failure

    func testPerformWithRetryFailure() async throws {
        var attemptCount = 0

        let result: NetworkRequestResult<String> = try await handler.performWithRetry(
            retryConfig: RetryConfiguration(
                maxRetries: 2,
                baseDelay: 0.1,
                maxDelay: 1.0,
                multiplier: 2.0
            )
        ) {
            attemptCount += 1
            throw URLError(.timedOut)
        }

        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(attemptCount, 3) // Initial + 2 retries
        XCTAssertNotNil(result.error)
    }

    // MARK: - Test 12: Statistics

    func testGetNetworkStatistics() {
        let stats = handler.getNetworkStatistics()

        XCTAssertTrue(stats.contains("Network Statistics"))
        XCTAssertTrue(stats.contains("Status:"))
        XCTAssertTrue(stats.contains("Connection Type:"))
    }

    // MARK: - Test 13: Timeout Handling

    func testWithTimeoutSuccess() async throws {
        let result = try await handler.withTimeout(seconds: 2) {
            return "Fast operation"
        }

        XCTAssertEqual(result, "Fast operation")
    }

    func testWithTimeoutFailure() async throws {
        do {
            _ = try await handler.withTimeout(seconds: 0.5) {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                return "Should timeout"
            }
            XCTFail("Should have thrown timeout error")
        } catch NetworkError.timeout {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected timeout error, got: \(error)")
        }
    }

    // MARK: - Test 14: Edge Cases

    func testEmptyRetryConfiguration() {
        let config = RetryConfiguration(
            maxRetries: 0,
            baseDelay: 1.0,
            maxDelay: 10.0,
            multiplier: 2.0
        )

        XCTAssertEqual(config.maxRetries, 0)
    }

    func testMultipleNetworkErrors() {
        let errors: [NetworkError] = [
            .offline,
            .timeout,
            .serverError(statusCode: 500),
            .clientError(statusCode: 400),
            .invalidResponse
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}
