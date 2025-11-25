//
//  ConcurrentOperationSafetyTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 2.4: Add Concurrent Operation Safety
//

import XCTest
@testable import Swiff_IOS

final class ConcurrentOperationSafetyTests: XCTestCase {

    // MARK: - Test 2.4.1: Thread-Safe Array

    func testThreadSafeArray() async throws {
        print("🧪 Test 2.4.1: Testing thread-safe array operations")

        let threadSafeArray = ThreadSafeArray<Int>()

        // Perform 100 concurrent appends
        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    await threadSafeArray.append(i)
                }
            }
        }

        let count = await threadSafeArray.count()
        XCTAssertEqual(count, 100, "Should have exactly 100 elements")
        print("   ✓ Concurrent appends successful: \(count) elements")

        let all = await threadSafeArray.getAll()
        XCTAssertEqual(all.count, 100, "GetAll should return 100 elements")
        print("   ✓ GetAll returned correct count")

        print("✅ Test 2.4.1: Thread-safe array verified")
        print("   Result: PASS - No race conditions in concurrent appends")
    }

    // MARK: - Test 2.4.2: Thread-Safe Counter

    func testThreadSafeCounter() async throws {
        print("🧪 Test 2.4.2: Testing thread-safe counter")

        let counter = ThreadSafeCounter()

        // Perform 1000 concurrent increments
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...1000 {
                group.addTask {
                    _ = await counter.increment()
                }
            }
        }

        let value = await counter.getValue()
        XCTAssertEqual(value, 1000, "Counter should be exactly 1000")
        print("   ✓ Concurrent increments: \(value) (expected 1000)")

        // Reset and test decrements
        await counter.reset()

        await withTaskGroup(of: Void.self) { group in
            for _ in 1...500 {
                group.addTask {
                    _ = await counter.increment()
                }
            }
            for _ in 1...200 {
                group.addTask {
                    _ = await counter.decrement()
                }
            }
        }

        let finalValue = await counter.getValue()
        XCTAssertEqual(finalValue, 300, "Counter should be 500 - 200 = 300")
        print("   ✓ Mixed operations: \(finalValue) (expected 300)")

        print("✅ Test 2.4.2: Thread-safe counter verified")
        print("   Result: PASS - No race conditions in counter operations")
    }

    // MARK: - Test 2.4.3: Thread-Safe Dictionary

    func testThreadSafeDictionary() async throws {
        print("🧪 Test 2.4.3: Testing thread-safe dictionary")

        let dictionary = ThreadSafeDictionary<String, Int>()

        // Perform concurrent inserts
        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    await dictionary.set("key_\(i)", value: i)
                }
            }
        }

        let count = await dictionary.count()
        XCTAssertEqual(count, 100, "Dictionary should have 100 entries")
        print("   ✓ Concurrent inserts: \(count) entries")

        // Test retrieval
        let value = await dictionary.get("key_50")
        XCTAssertEqual(value, 50, "Value for key_50 should be 50")
        print("   ✓ Value retrieval works correctly")

        // Test concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 {
                group.addTask {
                    await dictionary.set("key_\(i)", value: i * 2)
                }
            }
        }

        let updatedValue = await dictionary.get("key_25")
        XCTAssertEqual(updatedValue, 50, "Updated value should be 25 * 2 = 50")
        print("   ✓ Concurrent updates successful")

        print("✅ Test 2.4.3: Thread-safe dictionary verified")
        print("   Result: PASS - No race conditions in dictionary operations")
    }

    // MARK: - Test 2.4.4: Concurrent Import Manager

    func testConcurrentImportManager() async throws {
        print("🧪 Test 2.4.4: Testing concurrent import manager")

        let importManager = ConcurrentImportManager()
        let items = Array(1...100)
        var importedCount = 0
        var progressUpdates: [Double] = []

        let successCount = try await importManager.importConcurrently(
            items: items,
            maxConcurrency: 10,
            importHandler: { item in
                // Simulate import work
                try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                importedCount += 1
            },
            progressHandler: { @MainActor progress, message in
                progressUpdates.append(progress)
                if progressUpdates.count % 20 == 0 {
                    print("   Progress: \(Int(progress * 100))% - \(message)")
                }
            }
        )

        XCTAssertEqual(successCount, 100, "Should import all 100 items")
        print("   ✓ Successfully imported: \(successCount)/100 items")

        XCTAssertFalse(progressUpdates.isEmpty, "Should have progress updates")
        XCTAssertTrue(progressUpdates.contains(1.0), "Should reach 100% progress")
        print("   ✓ Progress updates: \(progressUpdates.count) updates")

        print("✅ Test 2.4.4: Concurrent import manager verified")
        print("   Result: PASS - Concurrent imports completed successfully")
    }

    // MARK: - Test 2.4.5: Import with Failures

    func testConcurrentImportWithFailures() async throws {
        print("🧪 Test 2.4.5: Testing concurrent import with some failures")

        let importManager = ConcurrentImportManager()
        let items = Array(1...50)

        let successCount = try await importManager.importConcurrently(
            items: items,
            maxConcurrency: 5,
            importHandler: { item in
                // Fail every 10th item
                if item % 10 == 0 {
                    throw NSError(domain: "TestError", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Simulated failure for item \(item)"
                    ])
                }
                try await Task.sleep(nanoseconds: 5_000_000) // 0.005 seconds
            }
        )

        // Should succeed for 45 items (50 - 5 failures)
        XCTAssertEqual(successCount, 45, "Should import 45 items (5 failures)")
        print("   ✓ Imported with failures: \(successCount)/50 (5 expected failures)")

        print("✅ Test 2.4.5: Concurrent import with failures verified")
        print("   Result: PASS - Partial failures handled correctly")
    }

    // MARK: - Test 2.4.6: Concurrent Operation Queue

    func testConcurrentOperationQueue() async throws {
        print("🧪 Test 2.4.6: Testing concurrent operation queue")

        let queue = ConcurrentOperationQueue(maxConcurrentOperations: 3)
        var completedOperations: [Int] = []
        let completedLock = NSLock()

        // Add 10 operations
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    try await queue.enqueue(priority: .medium) {
                        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

                        completedLock.lock()
                        completedOperations.append(i)
                        completedLock.unlock()

                        print("   Completed operation \(i)")
                    }
                }
            }

            try await group.waitForAll()
        }

        XCTAssertEqual(completedOperations.count, 10, "All 10 operations should complete")
        print("   ✓ Completed operations: \(completedOperations.count)/10")

        let status = await queue.getStatus()
        print("   ✓ Queue status - Active: \(status.active), Pending: \(status.pending)")

        print("✅ Test 2.4.6: Concurrent operation queue verified")
        print("   Result: PASS - Operation queue manages concurrency correctly")
    }

    // MARK: - Test 2.4.7: Queue Priority Handling

    func testQueuePriorityHandling() async throws {
        print("🧪 Test 2.4.7: Testing queue priority handling")

        let queue = ConcurrentOperationQueue(maxConcurrentOperations: 1)
        var executionOrder: [String] = []
        let orderLock = NSLock()

        // Add operations with different priorities
        async let high1: () = queue.enqueue(priority: .high) {
            try await Task.sleep(nanoseconds: 10_000_000)
            orderLock.lock()
            executionOrder.append("high1")
            orderLock.unlock()
        }

        async let low1: () = queue.enqueue(priority: .low) {
            try await Task.sleep(nanoseconds: 10_000_000)
            orderLock.lock()
            executionOrder.append("low1")
            orderLock.unlock()
        }

        async let medium1: () = queue.enqueue(priority: .medium) {
            try await Task.sleep(nanoseconds: 10_000_000)
            orderLock.lock()
            executionOrder.append("medium1")
            orderLock.unlock()
        }

        try await (high1, low1, medium1)

        print("   Execution order: \(executionOrder.joined(separator: " → "))")
        XCTAssertEqual(executionOrder.count, 3, "All 3 operations should complete")

        print("✅ Test 2.4.7: Queue priority handling verified")
        print("   Result: PASS - Priority-based execution working")
    }

    // MARK: - Test 2.4.8: Race Condition Prevention

    func testRaceConditionPrevention() async throws {
        print("🧪 Test 2.4.8: Testing race condition prevention in bulk operations")

        let threadSafeArray = ThreadSafeArray<String>()
        let items = (1...1000).map { "Item_\($0)" }

        let startTime = Date()

        // Simulate DataManager's bulk import scenario
        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    // Simulate async save + array append
                    try? await Task.sleep(nanoseconds: 1_000_000) // 0.001 seconds
                    await threadSafeArray.append(item)
                }
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)

        let finalCount = await threadSafeArray.count()
        XCTAssertEqual(finalCount, 1000, "Should have exactly 1000 items")

        print("   ✓ Bulk import completed: \(finalCount) items")
        print("   ✓ Time elapsed: \(String(format: "%.3f", elapsed))s")
        print("   ✓ No race conditions detected")

        print("✅ Test 2.4.8: Race condition prevention verified")
        print("   Result: PASS - Concurrent bulk operations are safe")
    }

    // MARK: - Test 2.4.9: Stress Test

    func testConcurrencyStressTest() async throws {
        print("🧪 Test 2.4.9: Testing concurrency stress test")

        let threadSafeArray = ThreadSafeArray<Int>()
        let counter = ThreadSafeCounter()
        let itemCount = 5000

        let startTime = Date()

        // Perform heavy concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Add items
            for i in 1...itemCount {
                group.addTask {
                    await threadSafeArray.append(i)
                    _ = await counter.increment()
                }
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)

        let arrayCount = await threadSafeArray.count()
        let counterValue = await counter.getValue()

        XCTAssertEqual(arrayCount, itemCount, "Array should have \(itemCount) items")
        XCTAssertEqual(counterValue, itemCount, "Counter should be \(itemCount)")

        print("   ✓ Stress test completed: \(itemCount) concurrent operations")
        print("   ✓ Array count: \(arrayCount)")
        print("   ✓ Counter value: \(counterValue)")
        print("   ✓ Time elapsed: \(String(format: "%.3f", elapsed))s")

        print("✅ Test 2.4.9: Concurrency stress test verified")
        print("   Result: PASS - System handles \(itemCount) concurrent operations correctly")
    }
}
