//
//  TaskCancellationManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 2.5: Comprehensive Task Cancellation System
//

import Combine
import Foundation
import SwiftUI

// MARK: - Cancellable Task Protocol

/// Protocol for objects that support task cancellation
protocol CancellableTask {
    /// Cancel the task
    func cancel()

    /// Check if task is currently running
    var isRunning: Bool { get }

    /// Task identifier
    var taskId: UUID { get }

    /// Task description
    var taskDescription: String { get }
}

// MARK: - Managed Task Wrapper

/// Wrapper for a Task with metadata for cancellation management
class ManagedTask<Success, Failure: Error>: CancellableTask, @unchecked Sendable {
    let taskId: UUID
    let taskDescription: String
    private(set) var task: Task<Success, Failure>?
    private var startTime: Date

    init(
        description: String,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) where Failure == Error {
        self.taskId = UUID()
        self.taskDescription = description
        self.startTime = Date()

        self.task = Task(priority: priority) {
            try await operation()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        print("🚫 Cancelled task: \(taskDescription) (ID: \(taskId))")
    }

    var isRunning: Bool {
        guard let task = task else { return false }
        return !task.isCancelled
    }

    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    /// Get the task result (await)
    func value() async throws -> Success {
        guard let task = task else {
            throw CancellationError()
        }
        return try await task.value
    }
}

// MARK: - Task Cancellation Manager

/// Global manager for coordinating task cancellation across the app
@MainActor
class TaskCancellationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TaskCancellationManager()

    // MARK: - Published Properties

    @Published var activeTasks: [UUID: any CancellableTask] = [:]
    @Published var cancelledTaskCount: Int = 0
    @Published var totalTasksRun: Int = 0

    // MARK: - Private Properties

    private var taskHistory: [TaskHistoryEntry] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Task Registration

    /// Register a cancellable task for management
    func registerTask(_ task: any CancellableTask) {
        activeTasks[task.taskId] = task
        totalTasksRun += 1

        print("📝 Registered task: \(task.taskDescription) (ID: \(task.taskId))")
    }

    /// Unregister a task (called when task completes)
    func unregisterTask(id: UUID) {
        if let task = activeTasks[id] {
            activeTasks.removeValue(forKey: id)
            print("✅ Unregistered task: \(task.taskDescription)")

            // Add to history
            taskHistory.append(TaskHistoryEntry(
                taskId: id,
                description: task.taskDescription,
                completedAt: Date()
            ))

            // Keep only last 100 entries
            if taskHistory.count > 100 {
                taskHistory.removeFirst(taskHistory.count - 100)
            }
        }
    }

    // MARK: - Cancellation Methods

    /// Cancel a specific task by ID
    func cancelTask(id: UUID) {
        if let task = activeTasks[id] {
            task.cancel()
            cancelledTaskCount += 1
            unregisterTask(id: id)

            ToastManager.shared.showWarning("Cancelled: \(task.taskDescription)")
        }
    }

    /// Cancel all active tasks
    func cancelAllTasks() {
        let count = activeTasks.count
        print("🚫 Cancelling all \(count) active tasks...")

        for (_, task) in activeTasks {
            task.cancel()
            cancelledTaskCount += 1
        }

        activeTasks.removeAll()

        if count > 0 {
            ToastManager.shared.showWarning("Cancelled \(count) operation(s)")
        }
    }

    /// Cancel tasks matching a predicate
    func cancelTasks(matching predicate: (any CancellableTask) -> Bool) {
        let tasksToCancel = activeTasks.values.filter(predicate)

        for task in tasksToCancel {
            cancelTask(id: task.taskId)
        }
    }

    /// Cancel all tasks of a specific type
    func cancelTasks(withDescriptionContaining substring: String) {
        cancelTasks { task in
            task.taskDescription.localizedCaseInsensitiveContains(substring)
        }
    }

    // MARK: - Query Methods

    /// Get all active task descriptions
    var activeTaskDescriptions: [String] {
        activeTasks.values.map { $0.taskDescription }
    }

    /// Check if any tasks are running
    var hasActiveTasks: Bool {
        !activeTasks.isEmpty
    }

    /// Get count of active tasks
    var activeTaskCount: Int {
        activeTasks.count
    }

    /// Get task history
    func getTaskHistory() -> [TaskHistoryEntry] {
        return taskHistory
    }

    /// Get statistics
    func getStatistics() -> TaskStatistics {
        TaskStatistics(
            totalTasksRun: totalTasksRun,
            cancelledTasks: cancelledTaskCount,
            activeTasks: activeTaskCount,
            completionRate: totalTasksRun > 0 ?
                Double(totalTasksRun - cancelledTaskCount) / Double(totalTasksRun) : 0.0
        )
    }

    // MARK: - Cleanup

    /// Clear completed task history
    func clearHistory() {
        taskHistory.removeAll()
    }

    /// Reset statistics
    func resetStatistics() {
        cancelledTaskCount = 0
        totalTasksRun = 0
        taskHistory.removeAll()
    }
}

// MARK: - Task History Entry

struct TaskHistoryEntry: Identifiable {
    let id = UUID()
    let taskId: UUID
    let description: String
    let completedAt: Date
}

// MARK: - Task Statistics

struct TaskStatistics {
    let totalTasksRun: Int
    let cancelledTasks: Int
    let activeTasks: Int
    let completionRate: Double

    var completionRatePercentage: String {
        String(format: "%.1f%%", completionRate * 100)
    }

    var description: String {
        """
        Task Statistics:
        - Total Tasks Run: \(totalTasksRun)
        - Cancelled: \(cancelledTasks)
        - Currently Active: \(activeTasks)
        - Completion Rate: \(completionRatePercentage)
        """
    }
}

// MARK: - Convenience Extensions

extension TaskCancellationManager {

    /// Run a managed task with automatic registration and cleanup
    func runManagedTask<T>(
        description: String,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let managedTask = ManagedTask(description: description, priority: priority, operation: operation)

        registerTask(managedTask)

        defer {
            unregisterTask(id: managedTask.taskId)
        }

        return try await managedTask.value()
    }

    /// Run a managed task with progress reporting
    func runManagedTaskWithProgress<T: Sendable>(
        description: String,
        progressHandler: @escaping @MainActor (Double) -> Void,
        operation: @escaping @Sendable (_ updateProgress: @escaping @Sendable (Double) -> Void) async throws -> T
    ) async throws -> T {
        try await runManagedTask(description: description) {
            try await operation { progress in
                Task { @MainActor in
                    progressHandler(progress)
                }
            }
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Show active task indicator
    func withTaskActivityIndicator() -> some View {
        ZStack {
            self

            VStack {
                HStack {
                    Spacer()

                    if TaskCancellationManager.shared.hasActiveTasks {
                        TaskActivityIndicator()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Task Activity Indicator View

struct TaskActivityIndicator: View {
    @ObservedObject private var taskManager = TaskCancellationManager.shared

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)

            Text("\(taskManager.activeTaskCount) task(s)")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Run a managed task:
 ```swift
 let result = try await TaskCancellationManager.shared.runManagedTask(
     description: "Fetching user data"
 ) {
     try await API.fetchUserData()
 }
 ```

 2. Cancel all active tasks:
 ```swift
 TaskCancellationManager.shared.cancelAllTasks()
 ```

 3. Cancel specific tasks:
 ```swift
 TaskCancellationManager.shared.cancelTasks(withDescriptionContaining: "backup")
 ```

 4. Show task activity in UI:
 ```swift
 ContentView()
     .withTaskActivityIndicator()
 ```

 5. Get task statistics:
 ```swift
 let stats = TaskCancellationManager.shared.getStatistics()
 print(stats.description)
 ```

 6. Manual task management:
 ```swift
 let task = ManagedTask(description: "Long operation") {
     try await performLongOperation()
 }

 TaskCancellationManager.shared.registerTask(task)

 // Later, cancel if needed
 task.cancel()
 ```
 */
