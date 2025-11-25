//
//  Debouncer.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Debouncer utility for batching rapid changes
//

import Foundation
import Combine

/// Debouncer class for delaying execution of code until a specified time has passed without new calls
@MainActor
class Debouncer {
    private var workItem: Task<Void, Never>?
    private let delay: TimeInterval

    /// Initialize a debouncer with a specific delay
    /// - Parameter delay: The time interval to wait before executing the debounced work
    init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Debounce the execution of the provided work
    /// - Parameter work: An async closure to execute after the debounce delay
    func debounce(_ work: @escaping @MainActor () async -> Void) {
        // Cancel any pending work
        workItem?.cancel()

        // Create new work item
        workItem = Task { @MainActor in
            // Wait for the delay period
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // Check if we weren't cancelled
            guard !Task.isCancelled else { return }

            // Execute the work
            await work()
        }
    }

    /// Cancel any pending debounced work
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }

    deinit {
        // Use nonisolated cancellation for deinit
        workItem?.cancel()
        workItem = nil
    }
}
