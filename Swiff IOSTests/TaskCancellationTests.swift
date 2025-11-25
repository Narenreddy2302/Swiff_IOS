//
//  TaskCancellationTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 2.5: Implement Task Cancellation
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class TaskCancellationTests: XCTestCase {

    var taskManager: TaskCancellationManager!

    override func setUp() async throws {
        try await super.setUp()
        taskManager = TaskCancellationManager.shared
        taskManager.resetStatistics()
        taskManager.cancelAllTasks()
    }

    override func tearDown() async throws {
        taskManager.cancelAllTasks()
        taskManager.resetStatistics()
        try await super.tearDown()
    }

    // MARK: - Test 2.5.1: Task Registration

    func testTaskRegistration() async throws {
        print("🧪 Test 2.5.1: Testing task registration and unregistration")

        let initialCount = taskManager.activeTaskCount

        let task = try await taskManager.runManagedTask(description: "Test Task") {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return "Completed"
        }

        XCTAssertEqual(task, "Completed", "Task should complete successfully")

        // Task should be unregistered after completion
        try await Task.sleep(nanoseconds: 100_000_000) // Wait a bit
        let finalCount = taskManager.activeTaskCount
        XCTAssertEqual(finalCount, initialCount, "Task should be unregistered after completion")

        print("   ✓ Task registered and unregistered correctly")

        print("✅ Test 2.5.1: Task registration verified")
        print("   Result: PASS - Task lifecycle managed correctly")
    }

    // MARK: - Test 2.5.2: Single Task Cancellation

    func testSingleTaskCancellation() async throws {
        print("🧪 Test 2.5.2: Testing single task cancellation")

        let managedTask = ManagedTask<String, Error>(description: "Long Task") {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            return "Should not complete"
        }

        taskManager.registerTask(managedTask)
        XCTAssertTrue(taskManager.hasActiveTasks, "Should have active task")

        // Wait a moment
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Cancel the task
        taskManager.cancelTask(id: managedTask.taskId)

        XCTAssertFalse(taskManager.hasActiveTasks, "Task should be cancelled")
        print("   ✓ Task cancelled successfully")

        print("✅ Test 2.5.2: Single task cancellation verified")
        print("   Result: PASS - Task cancelled correctly")
    }

    // MARK: - Test 2.5.3: Multiple Task Cancellation

    func testMultipleTaskCancellation() async throws {
        print("🧪 Test 2.5.3: Testing multiple task cancellation")

        // Create 5 tasks
        var tasks: [ManagedTask<String, Error>] = []
        for i in 1...5 {
            let task = ManagedTask<String, Error>(description: "Task \(i)") {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                return "Task \(i) complete"
            }
            taskManager.registerTask(task)
            tasks.append(task)
        }

        XCTAssertEqual(taskManager.activeTaskCount, 5, "Should have 5 active tasks")
        print("   ✓ Created 5 active tasks")

        // Cancel all tasks
        taskManager.cancelAllTasks()

        XCTAssertEqual(taskManager.activeTaskCount, 0, "All tasks should be cancelled")
        XCTAssertEqual(taskManager.cancelledTaskCount, 5, "Should have 5 cancelled tasks")

        print("   ✓ All 5 tasks cancelled")

        print("✅ Test 2.5.3: Multiple task cancellation verified")
        print("   Result: PASS - All tasks cancelled correctly")
    }

    // MARK: - Test 2.5.4: Selective Task Cancellation

    func testSelectiveTaskCancellation() async throws {
        print("🧪 Test 2.5.4: Testing selective task cancellation")

        // Create different types of tasks
        let backupTask = ManagedTask<String, Error>(description: "Backup Operation") {
            try await Task.sleep(nanoseconds: 10_000_000_000)
            return "Backup complete"
        }

        let syncTask = ManagedTask<String, Error>(description: "Sync Operation") {
            try await Task.sleep(nanoseconds: 10_000_000_000)
            return "Sync complete"
        }

        let exportTask = ManagedTask<String, Error>(description: "Export Operation") {
            try await Task.sleep(nanoseconds: 10_000_000_000)
            return "Export complete"
        }

        taskManager.registerTask(backupTask)
        taskManager.registerTask(syncTask)
        taskManager.registerTask(exportTask)

        XCTAssertEqual(taskManager.activeTaskCount, 3, "Should have 3 active tasks")
        print("   ✓ Created 3 different tasks")

        // Cancel only backup tasks
        taskManager.cancelTasks(withDescriptionContaining: "backup")

        XCTAssertEqual(taskManager.activeTaskCount, 2, "Should have 2 active tasks remaining")
        print("   ✓ Backup task cancelled, 2 tasks remaining")

        // Cleanup
        taskManager.cancelAllTasks()

        print("✅ Test 2.5.4: Selective task cancellation verified")
        print("   Result: PASS - Selective cancellation working")
    }

    // MARK: - Test 2.5.5: Task Statistics

    func testTaskStatistics() async throws {
        print("🧪 Test 2.5.5: Testing task statistics tracking")

        taskManager.resetStatistics()

        // Run some tasks to completion
        for i in 1...3 {
            _ = try await taskManager.runManagedTask(description: "Completed Task \(i)") {
                try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                return i
            }
        }

        // Start and cancel some tasks
        for i in 1...2 {
            let task = ManagedTask<Int, Error>(description: "Cancelled Task \(i)") {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                return i
            }
            taskManager.registerTask(task)
            task.cancel()
            taskManager.unregisterTask(id: task.taskId)
        }

        let stats = taskManager.getStatistics()

        XCTAssertEqual(stats.totalTasksRun, 5, "Should have run 5 tasks total")
        print("   ✓ Total tasks run: \(stats.totalTasksRun)")

        print("   ✓ Statistics: \(stats.description)")

        print("✅ Test 2.5.5: Task statistics verified")
        print("   Result: PASS - Statistics tracked correctly")
    }

    // MARK: - Test 2.5.6: Task History

    func testTaskHistory() async throws {
        print("🧪 Test 2.5.6: Testing task history tracking")

        taskManager.clearHistory()

        // Run several tasks
        for i in 1...5 {
            _ = try await taskManager.runManagedTask(description: "Historical Task \(i)") {
                try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                return i
            }
        }

        let history = taskManager.getTaskHistory()
        XCTAssertEqual(history.count, 5, "Should have 5 history entries")

        print("   ✓ Task history recorded: \(history.count) entries")

        for entry in history {
            print("     - \(entry.description)")
        }

        // Clear history
        taskManager.clearHistory()
        XCTAssertEqual(taskManager.getTaskHistory().count, 0, "History should be cleared")

        print("✅ Test 2.5.6: Task history verified")
        print("   Result: PASS - History tracking working")
    }

    // MARK: - Test 2.5.7: Managed Task with Progress

    func testManagedTaskWithProgress() async throws {
        print("🧪 Test 2.5.7: Testing managed task with progress reporting")

        var progressUpdates: [Double] = []

        let result = try await taskManager.runManagedTaskWithProgress(
            description: "Task with Progress",
            progressHandler: { @MainActor progress in
                progressUpdates.append(progress)
                print("   Progress: \(Int(progress * 100))%")
            }
        ) { updateProgress in
            updateProgress(0.0)
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

            updateProgress(0.5)
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

            updateProgress(1.0)

            return "Completed with progress"
        }

        XCTAssertEqual(result, "Completed with progress")
        XCTAssertEqual(progressUpdates.count, 3, "Should have 3 progress updates")
        XCTAssertTrue(progressUpdates.contains(0.0), "Should start at 0%")
        XCTAssertTrue(progressUpdates.contains(1.0), "Should end at 100%")

        print("   ✓ Progress updates received: \(progressUpdates)")

        print("✅ Test 2.5.7: Managed task with progress verified")
        print("   Result: PASS - Progress reporting working")
    }

    // MARK: - Test 2.5.8: Async Backup Service Integration

    func testAsyncBackupServiceCancellation() async throws {
        print("🧪 Test 2.5.8: Testing AsyncBackupService cancellation integration")

        let asyncBackup = AsyncBackupService.shared

        // Start a backup
        let backupTask = Task {
            try await asyncBackup.createBackup(
                options: .all,
                timeout: 60.0
            )
        }

        // Wait a moment
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Cancel the backup
        asyncBackup.cancelBackup()

        print("   ✓ Backup cancellation requested")

        // Verify backup is no longer running
        XCTAssertFalse(asyncBackup.isBackupInProgress, "Backup should be cancelled")

        // Try to get result
        do {
            _ = try await backupTask.value
            print("   ℹ️ Backup completed before cancellation")
        } catch {
            print("   ✓ Backup was cancelled or failed")
        }

        print("✅ Test 2.5.8: Backup service cancellation verified")
        print("   Result: PASS - AsyncBackupService cancellation working")
    }

    // MARK: - Test 2.5.9: Cancellation with Cleanup

    func testCancellationWithCleanup() async throws {
        print("🧪 Test 2.5.9: Testing cancellation with proper cleanup")

        var cleanupCalled = false

        let task = Task {
            defer {
                cleanupCalled = true
                print("   ✓ Cleanup performed")
            }

            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            return "Should not complete"
        }

        // Wait briefly
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Cancel task
        task.cancel()

        // Try to get result
        do {
            _ = try await task.value
        } catch {
            print("   ✓ Task was cancelled")
        }

        // Verify cleanup was called
        XCTAssertTrue(cleanupCalled, "Cleanup should be called even when cancelled")

        print("✅ Test 2.5.9: Cancellation with cleanup verified")
        print("   Result: PASS - Cleanup executes on cancellation")
    }

    // MARK: - Test 2.5.10: Concurrent Cancellations

    func testConcurrentCancellations() async throws {
        print("🧪 Test 2.5.10: Testing concurrent task cancellations")

        // Create 20 tasks
        for i in 1...20 {
            let task = ManagedTask<Int, Error>(description: "Concurrent Task \(i)") {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                return i
            }
            taskManager.registerTask(task)
        }

        XCTAssertEqual(taskManager.activeTaskCount, 20, "Should have 20 active tasks")
        print("   ✓ Created 20 concurrent tasks")

        // Cancel all concurrently
        let startTime = Date()
        taskManager.cancelAllTasks()
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(taskManager.activeTaskCount, 0, "All tasks should be cancelled")
        print("   ✓ All 20 tasks cancelled in \(String(format: "%.3f", elapsed))s")

        print("✅ Test 2.5.10: Concurrent cancellations verified")
        print("   Result: PASS - Multiple tasks cancelled efficiently")
    }
}
