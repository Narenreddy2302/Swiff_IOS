//
//  ThreadSafeDataManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 2.4: Add Concurrent Operation Safety
//

import Foundation
import SwiftUI

// MARK: - Thread-Safe Array Wrapper

/// Actor-based thread-safe wrapper for array mutations
actor ThreadSafeArray<Element> {
    private var elements: [Element] = []

    /// Append an element thread-safely
    func append(_ element: Element) {
        elements.append(element)
    }

    /// Append multiple elements thread-safely
    func append(contentsOf newElements: [Element]) {
        elements.append(contentsOf: newElements)
    }

    /// Get all elements
    func getAll() -> [Element] {
        return elements
    }

    /// Get count
    func count() -> Int {
        return elements.count
    }

    /// Clear all elements
    func removeAll() {
        elements.removeAll()
    }

    /// Remove element at index
    func remove(at index: Int) {
        guard index < elements.count else { return }
        elements.remove(at: index)
    }

    /// Insert element at index
    func insert(_ element: Element, at index: Int) {
        elements.insert(element, at: index)
    }

    /// Get element at index
    func element(at index: Int) -> Element? {
        guard index < elements.count else { return nil }
        return elements[index]
    }
}

// MARK: - Concurrent Import Manager

/// Actor for managing concurrent import operations safely
actor ConcurrentImportManager {

    // MARK: - Properties

    private var activeImportTasks: [UUID: Task<Void, Error>] = [:]
    private var importProgress: [UUID: Double] = [:]

    // MARK: - Concurrent Import

    /// Import items concurrently with thread-safe progress tracking
    /// - Parameters:
    ///   - items: Array of items to import
    ///   - maxConcurrency: Maximum number of concurrent operations (default: 5)
    ///   - importHandler: Async closure to import a single item
    ///   - progressHandler: Progress callback on main actor
    /// - Returns: Number of successfully imported items
    func importConcurrently<T>(
        items: [T],
        maxConcurrency: Int = 5,
        importHandler: @escaping @Sendable (T) async throws -> Void,
        progressHandler: (@MainActor @Sendable (Double, String) -> Void)? = nil
    ) async throws -> Int {

        guard !items.isEmpty else { return 0 }

        let importId = UUID()
        let total = items.count
        var successCount = 0
        var failureCount = 0

        // Update initial progress
        await progressHandler?(0.0, "Starting import of \(total) items...")

        // Use task group for concurrent execution with limit
        try await withThrowingTaskGroup(of: Void.self) { group in
            var iterator = items.enumerated().makeIterator()
            var activeCount = 0

            // Function to add next task
            func addNextTask() async throws {
                if let (index, item) = iterator.next() {
                    activeCount += 1

                    group.addTask {
                        do {
                            // Import the item
                            try await importHandler(item)

                            // Update progress safely
                            await self.updateProgress(
                                id: importId,
                                current: index + 1,
                                total: total,
                                progressHandler: progressHandler
                            )

                        } catch {
                            print("⚠️ Import failed for item \(index): \(error.localizedDescription)")
                            throw error
                        }
                    }
                }
            }

            // Start initial batch up to maxConcurrency
            for _ in 0..<min(maxConcurrency, total) {
                try await addNextTask()
            }

            // Process results and add new tasks
            while activeCount > 0 {
                do {
                    try await group.next()
                    successCount += 1
                } catch {
                    failureCount += 1
                    // Continue with other imports even if one fails
                }

                activeCount -= 1

                // Add next task if available
                try await addNextTask()
            }
        }

        // Final progress update
        await progressHandler?(1.0, "Import complete: \(successCount) succeeded, \(failureCount) failed")

        return successCount
    }

    /// Update progress safely
    private func updateProgress(
        id: UUID,
        current: Int,
        total: Int,
        progressHandler: (@MainActor @Sendable (Double, String) -> Void)?
    ) async {
        let progress = Double(current) / Double(total)
        importProgress[id] = progress

        await progressHandler?(progress, "Imported \(current) of \(total) items")
    }

    /// Cancel all active import operations
    func cancelAll() {
        for (_, task) in activeImportTasks {
            task.cancel()
        }
        activeImportTasks.removeAll()
    }

    /// Get active import count
    var activeImportCount: Int {
        activeImportTasks.count
    }
}

// MARK: - Thread-Safe Counter

/// Actor-based thread-safe counter
actor ThreadSafeCounter {
    private var value: Int = 0

    func increment() -> Int {
        value += 1
        return value
    }

    func decrement() -> Int {
        value -= 1
        return value
    }

    func getValue() -> Int {
        return value
    }

    func setValue(_ newValue: Int) {
        value = newValue
    }

    func reset() {
        value = 0
    }
}

// MARK: - Thread-Safe Dictionary

/// Actor-based thread-safe dictionary
actor ThreadSafeDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]

    func get(_ key: Key) -> Value? {
        return dictionary[key]
    }

    func set(_ key: Key, value: Value) {
        dictionary[key] = value
    }

    func remove(_ key: Key) {
        dictionary[key] = nil
    }

    func getAll() -> [Key: Value] {
        return dictionary
    }

    func removeAll() {
        dictionary.removeAll()
    }

    func count() -> Int {
        return dictionary.count
    }
}

// MARK: - Concurrent Operation Queue

/// Actor for managing concurrent operations with rate limiting
actor ConcurrentOperationQueue {

    // MARK: - Properties

    private var maxConcurrentOperations: Int
    private var activeOperations: Int = 0
    private var pendingOperations: [(priority: TaskPriority, operation: @Sendable () async throws -> Void)] = []

    // MARK: - Initialization

    init(maxConcurrentOperations: Int = 5) {
        self.maxConcurrentOperations = maxConcurrentOperations
    }

    // MARK: - Queue Management

    /// Add operation to queue
    func enqueue(
        priority: TaskPriority = .medium,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws {
        if activeOperations < maxConcurrentOperations {
            // Execute immediately
            activeOperations += 1

            do {
                try await operation()
            } catch {
                await self.operationCompleted()
                throw error
            }

            await self.operationCompleted()
        } else {
            // Add to pending queue
            pendingOperations.append((priority: priority, operation: operation))
            pendingOperations.sort { $0.priority.rawValue > $1.priority.rawValue }
        }
    }

    /// Called when operation completes
    private func operationCompleted() async {
        activeOperations -= 1

        // Start next pending operation
        if !pendingOperations.isEmpty {
            let next = pendingOperations.removeFirst()
            try? await self.enqueue(priority: next.priority, operation: next.operation)
        }
    }

    /// Get current queue status
    func getStatus() -> (active: Int, pending: Int) {
        return (activeOperations, pendingOperations.count)
    }

    /// Clear all pending operations
    func clearPending() {
        pendingOperations.removeAll()
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Thread-Safe Array:
 ```swift
 let threadSafeArray = ThreadSafeArray<Person>()

 // Concurrent appends are safe
 await withTaskGroup(of: Void.self) { group in
     for person in people {
         group.addTask {
             await threadSafeArray.append(person)
         }
     }
 }

 let allPeople = await threadSafeArray.getAll()
 ```

 2. Concurrent Import Manager:
 ```swift
 let importManager = ConcurrentImportManager()

 let successCount = try await importManager.importConcurrently(
     items: people,
     maxConcurrency: 5,
     importHandler: { person in
         try await persistenceService.savePerson(person)
     },
     progressHandler: { progress, message in
         self.operationProgress = progress
         self.operationMessage = message
     }
 )
 ```

 3. Concurrent Operation Queue:
 ```swift
 let queue = ConcurrentOperationQueue(maxConcurrentOperations: 3)

 try await queue.enqueue(priority: .high) {
     // High priority operation
     try await performCriticalTask()
 }

 try await queue.enqueue(priority: .low) {
     // Low priority operation
     try await performBackgroundTask()
 }
 ```

 4. Thread-Safe Counter:
 ```swift
 let counter = ThreadSafeCounter()

 await withTaskGroup(of: Void.self) { group in
     for _ in 0..<100 {
         group.addTask {
             _ = await counter.increment()
         }
     }
 }

 let total = await counter.getValue() // Will be exactly 100
 ```
 */
