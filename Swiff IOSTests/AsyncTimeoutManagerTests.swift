//
//  AsyncTimeoutManagerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 2.1: Async Operation Timeouts
//

import XCTest
@testable import Swiff_IOS

final class AsyncTimeoutManagerTests: XCTestCase {

    var timeoutManager: AsyncTimeoutManager!

    override func setUp() async throws {
        try await super.setUp()
        timeoutManager = AsyncTimeoutManager()
    }

    override func tearDown() async throws {
        timeoutManager = nil
        try await super.tearDown()
    }

    // MARK: - Test 2.1.1: Basic Timeout Functionality

    func testBasicTimeout() async throws {
        print("🧪 Test 2.1.1: Testing basic timeout functionality")

        // Test operation that completes before timeout
        let result = try await timeoutManager.withTimeout(
            timeout: 5.0,
            operationType: .database
        ) {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return "Success"
        }

        XCTAssertEqual(result, "Success", "Operation should complete successfully")
        print("   ✓ Operation completed before timeout")

        // Test operation that times out
        do {
            _ = try await timeoutManager.withTimeout(
                timeout: 1.0,
                operationType: .database
            ) {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                return "Should not reach"
            }
            XCTFail("Operation should have timed out")
        } catch let error as TimeoutError {
            if case .operationTimedOut(let operation, let duration) = error {
                XCTAssertEqual(operation, "Database")
                XCTAssertEqual(duration, 1.0)
                print("   ✓ Operation timed out correctly after \(duration)s")
            }
        }

        print("✅ Test 2.1.1: Basic timeout verified")
        print("   Result: PASS - Timeouts working correctly")
    }

    // MARK: - Test 2.1.2: Different Operation Types

    func testOperationTypeDefaults() async throws {
        print("🧪 Test 2.1.2: Testing default timeouts for different operation types")

        let operationTypes: [(type: AsyncTimeoutManager.OperationType, expectedTimeout: TimeInterval)] = [
            (.network, 30.0),
            (.database, 10.0),
            (.fileSystem, 15.0),
            (.backup, 120.0),
            (.export, 60.0),
            (.custom(name: "TestOp"), 30.0)
        ]

        for (type, expectedTimeout) in operationTypes {
            XCTAssertEqual(type.defaultTimeout, expectedTimeout, "\(type.operationName) should have \(expectedTimeout)s timeout")
            print("   ✓ \(type.operationName): \(expectedTimeout)s timeout")
        }

        print("✅ Test 2.1.2: Operation type defaults verified")
        print("   Result: PASS - All operation types have correct default timeouts")
    }

    // MARK: - Test 2.1.3: Retry Logic with Timeout

    func testRetryLogicWithTimeout() async throws {
        print("🧪 Test 2.1.3: Testing retry logic with timeout")

        var attemptCount = 0

        do {
            _ = try await timeoutManager.withRetryAndTimeout(
                timeout: 1.0,
                operationType: .network,
                maxRetries: 3,
                retryDelay: 0.5
            ) {
                attemptCount += 1
                print("   Attempt #\(attemptCount)")

                if attemptCount < 3 {
                    throw NSError(domain: "TestError", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Simulated network error"
                    ])
                }

                return "Success on attempt 3"
            }

            XCTAssertEqual(attemptCount, 3, "Should succeed on third attempt")
            print("   ✓ Succeeded after 3 attempts")

        } catch {
            XCTFail("Operation should have succeeded on retry: \(error)")
        }

        print("✅ Test 2.1.3: Retry logic verified")
        print("   Result: PASS - Retry mechanism working correctly")
    }

    // MARK: - Test 2.1.4: Retry Exhaustion

    func testRetryExhaustion() async throws {
        print("🧪 Test 2.1.4: Testing retry exhaustion after max attempts")

        var attemptCount = 0
        let startTime = Date()

        do {
            _ = try await timeoutManager.withRetryAndTimeout(
                timeout: 0.5,
                operationType: .network,
                maxRetries: 3,
                retryDelay: 0.2
            ) {
                attemptCount += 1
                print("   Attempt #\(attemptCount)")

                // Always fail
                throw NSError(domain: "TestError", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Persistent error"
                ])
            }

            XCTFail("Should have failed after max retries")

        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            print("   ✓ Failed after \(attemptCount) attempts")
            print("   Total time: \(String(format: "%.2f", elapsed))s")

            // Should have tried 4 times (initial + 3 retries)
            XCTAssertEqual(attemptCount, 4, "Should attempt initial + 3 retries")
        }

        print("✅ Test 2.1.4: Retry exhaustion verified")
        print("   Result: PASS - Max retries enforced correctly")
    }

    // MARK: - Test 2.1.5: Convenience Methods

    func testConvenienceMethods() async throws {
        print("🧪 Test 2.1.5: Testing convenience methods")

        // Test network request convenience
        let networkResult = try await AsyncTimeoutManager.networkRequest(timeout: 5.0) {
            try await Task.sleep(nanoseconds: 100_000_000)
            return "Network data"
        }
        XCTAssertEqual(networkResult, "Network data")
        print("   ✓ Network request convenience method works")

        // Test database operation convenience
        let dbResult = try await AsyncTimeoutManager.databaseOperation(timeout: 5.0) {
            try await Task.sleep(nanoseconds: 100_000_000)
            return 42
        }
        XCTAssertEqual(dbResult, 42)
        print("   ✓ Database operation convenience method works")

        // Test backup operation convenience
        let backupResult = try await AsyncTimeoutManager.backupOperation(timeout: 10.0) {
            try await Task.sleep(nanoseconds: 100_000_000)
            return true
        }
        XCTAssertTrue(backupResult)
        print("   ✓ Backup operation convenience method works")

        // Test export operation convenience
        let exportResult = try await AsyncTimeoutManager.exportOperation(timeout: 10.0) {
            try await Task.sleep(nanoseconds: 100_000_000)
            return ["export": "data"]
        }
        XCTAssertEqual(exportResult["export"], "data")
        print("   ✓ Export operation convenience method works")

        print("✅ Test 2.1.5: Convenience methods verified")
        print("   Result: PASS - All convenience methods working correctly")
    }

    // MARK: - Test 2.1.6: Progress Reporting

    func testProgressReporting() async throws {
        print("🧪 Test 2.1.6: Testing progress reporting with timeout")

        var progressUpdates: [Double] = []

        let result = try await timeoutManager.withTimeoutAndProgress(
            timeout: 5.0,
            operationType: .backup,
            progressHandler: { progress in
                progressUpdates.append(progress)
                print("   Progress: \(Int(progress * 100))%")
            }
        ) { updateProgress in
            updateProgress(0.0)
            try await Task.sleep(nanoseconds: 100_000_000)

            updateProgress(0.25)
            try await Task.sleep(nanoseconds: 100_000_000)

            updateProgress(0.50)
            try await Task.sleep(nanoseconds: 100_000_000)

            updateProgress(0.75)
            try await Task.sleep(nanoseconds: 100_000_000)

            updateProgress(1.0)

            return "Completed with progress"
        }

        XCTAssertEqual(result, "Completed with progress")
        XCTAssertEqual(progressUpdates.count, 5, "Should have 5 progress updates")
        XCTAssertEqual(progressUpdates, [0.0, 0.25, 0.50, 0.75, 1.0], "Progress should be sequential")

        print("   ✓ Received \(progressUpdates.count) progress updates")

        print("✅ Test 2.1.6: Progress reporting verified")
        print("   Result: PASS - Progress updates working correctly")
    }

    // MARK: - Test 2.1.7: Error Type Detection

    func testTimeoutErrorDetection() async throws {
        print("🧪 Test 2.1.7: Testing timeout error type detection")

        // Test with timeout error
        let timeoutError = TimeoutError.operationTimedOut(operation: "Test", duration: 10.0)
        XCTAssertTrue(AsyncTimeoutManager.isTimeoutError(timeoutError), "Should detect TimeoutError")
        print("   ✓ Timeout error detected correctly")

        // Test with non-timeout error
        let genericError = NSError(domain: "TestDomain", code: -1, userInfo: nil)
        XCTAssertFalse(AsyncTimeoutManager.isTimeoutError(genericError), "Should not detect generic error as timeout")
        print("   ✓ Generic error not detected as timeout")

        // Test error descriptions
        let error1 = TimeoutError.operationTimedOut(operation: "Database", duration: 10.0)
        XCTAssertNotNil(error1.errorDescription)
        XCTAssertNotNil(error1.recoverySuggestion)
        print("   ✓ Error has description: \(error1.errorDescription ?? "nil")")
        print("   ✓ Error has recovery suggestion: \(error1.recoverySuggestion ?? "nil")")

        print("✅ Test 2.1.7: Error type detection verified")
        print("   Result: PASS - Timeout errors properly classified")
    }

    // MARK: - Test 2.1.8: Concurrent Operations

    func testConcurrentOperations() async throws {
        print("🧪 Test 2.1.8: Testing multiple concurrent timeout operations")

        let startTime = Date()

        // Run 5 operations concurrently, each taking different times
        try await withThrowingTaskGroup(of: String.self) { group in
            for i in 1...5 {
                group.addTask {
                    try await self.timeoutManager.withTimeout(
                        timeout: 10.0,
                        operationType: .custom(name: "Operation \(i)")
                    ) {
                        let sleepTime = Double(i) * 100_000_000 // 0.1s to 0.5s
                        try await Task.sleep(nanoseconds: UInt64(sleepTime))
                        return "Operation \(i) completed"
                    }
                }
            }

            var results: [String] = []
            for try await result in group {
                results.append(result)
                print("   ✓ \(result)")
            }

            XCTAssertEqual(results.count, 5, "All 5 operations should complete")
        }

        let elapsed = Date().timeIntervalSince(startTime)
        print("   All operations completed in \(String(format: "%.2f", elapsed))s")

        print("✅ Test 2.1.8: Concurrent operations verified")
        print("   Result: PASS - Multiple timeouts can run concurrently")
    }
}
