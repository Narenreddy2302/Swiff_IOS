//
//  DebouncedState.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Debounced auto-save utilities for text field editing
//

import Foundation
import Combine
import SwiftUI

// MARK: - Debounced Property Wrapper

/// Property wrapper that debounces value changes
/// Useful for auto-saving text field edits without triggering save on every keystroke
@propertyWrapper
class Debounced<Value: Equatable> {
    private var _value: Value
    private let delay: TimeInterval
    private let onSave: ((Value) -> Void)?
    private var cancellable: AnyCancellable?

    var wrappedValue: Value {
        get { _value }
        set {
            _value = newValue
            debounceAndSave(newValue)
        }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { self._value },
            set: { newValue in
                self._value = newValue
                self.debounceAndSave(newValue)
            }
        )
    }

    init(wrappedValue: Value, delay: TimeInterval = 0.5, onSave: ((Value) -> Void)? = nil) {
        self._value = wrappedValue
        self.delay = delay
        self.onSave = onSave
    }

    private func debounceAndSave(_ newValue: Value) {
        cancellable?.cancel()

        cancellable = Just(newValue)
            .delay(for: .seconds(delay), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.onSave?(value)
            }
    }
}

// MARK: - Debounced Save Publisher

/// Publisher-based debouncer for Combine-style operations
class DebouncedSavePublisher<T: Equatable>: ObservableObject {
    @Published var value: T
    private var cancellable: AnyCancellable?
    private let delay: TimeInterval
    private let onSave: (T) -> Void

    init(initialValue: T, delay: TimeInterval = 0.5, onSave: @escaping (T) -> Void) {
        self.value = initialValue
        self.delay = delay
        self.onSave = onSave

        setupDebouncing()
    }

    private func setupDebouncing() {
        cancellable = $value
            .dropFirst() // Ignore initial value
            .removeDuplicates()
            .debounce(for: .seconds(delay), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.onSave(newValue)
            }
    }
}

// MARK: - AsyncDebouncer Class

/// Simple debouncer for async operations with ObservableObject support
@MainActor
class AsyncDebouncer: ObservableObject {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?

    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }

    func debounce(operation: @escaping () async -> Void) {
        task?.cancel()
        
        task = Task {
            // Wait for delay
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Check if cancelled
            guard !Task.isCancelled else { return }
            
            // Execute operation
            await operation()
        }
    }

    func cancel() {
        task?.cancel()
    }
}

// MARK: - View Extension for Debounced Changes

extension View {
    /// Adds debounced onChange modifier
    func onDebouncedChange<V: Equatable>(
        of value: V,
        delay: TimeInterval = 0.5,
        perform action: @escaping (V) -> Void
    ) -> some View {
        self.modifier(DebouncedChangeModifier(value: value, delay: delay, action: action))
    }
}

private struct DebouncedChangeModifier<V: Equatable>: ViewModifier {
    let value: V
    let delay: TimeInterval
    let action: (V) -> Void

    @State private var workItem: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { oldValue, newValue in
                // Cancel previous work
                workItem?.cancel()

                // Schedule new work
                workItem = Task {
                    // Wait for delay
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    // Check if cancelled
                    guard !Task.isCancelled else { return }

                    // Execute action on main thread
                    await MainActor.run {
                        action(newValue)
                    }
                }
            }
    }
}

// MARK: - Debounced Text Field

/// Custom text field with built-in debouncing
struct DebouncedTextField: View {
    let title: String
    @Binding var text: String
    let delay: TimeInterval
    let onSave: (String) -> Void

    @State private var debouncedText: String
    @State private var debouncer: AsyncDebouncer
    @State private var isSaving = false

    init(
        _ title: String,
        text: Binding<String>,
        delay: TimeInterval = 0.5,
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self._text = text
        self.delay = delay
        self.onSave = onSave
        self._debouncedText = State(initialValue: text.wrappedValue)
        self._debouncer = State(initialValue: AsyncDebouncer(delay: delay))
    }

    var body: some View {
        HStack {
            TextField(title, text: $debouncedText)
                .onChange(of: debouncedText) { oldValue, newValue in
                    text = newValue
                    isSaving = true

                    debouncer.debounce {
                        onSave(newValue)
                        await MainActor.run {
                            isSaving = false
                        }
                    }
                }

            if isSaving {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }
}

// MARK: - Save Status Indicator

/// Visual indicator for save status
struct SaveStatusIndicator: View {
    enum Status {
        case idle
        case saving
        case saved
        case error(String)
    }

    let status: Status

    var body: some View {
        VStack {
            switch status {
            case .idle:
                EmptyView()

            case .saving:
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Saving...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            case .saved:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)

            case .error(let message):
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Error: \(message)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: statusIdentifier)
    }

    private var statusIdentifier: Int {
        switch status {
        case .idle: return 0
        case .saving: return 1
        case .saved: return 2
        case .error: return 3
        }
    }
}

// MARK: - Usage Examples

/*
 // Example 1: Using @Debounced property wrapper
 struct PersonEditView: View {
     @Debounced(delay: 0.5, onSave: { newName in
         // Save to database
         try? dataManager.updatePerson(updatedPerson)
     })
     var personName: String

     var body: some View {
         TextField("Name", text: $personName)
     }
 }

 // Example 2: Using AsyncDebouncer class
 struct EditView: View {
     @StateObject private var debouncer = AsyncDebouncer(delay: 0.5)
     @State private var name = ""

     var body: some View {
         TextField("Name", text: $name)
             .onChange(of: name) { oldValue, newValue in
                 debouncer.debounce {
                     await saveName(newValue)
                 }
             }
     }
 }

 // Example 3: Using DebouncedTextField
 struct FormView: View {
     @State private var name = ""

     var body: some View {
         DebouncedTextField("Name", text: $name, delay: 0.5) { newName in
             try? dataManager.updatePerson(newName)
         }
     }
 }

 // Example 4: Using view extension
 struct SimpleView: View {
     @State private var searchText = ""

     var body: some View {
         TextField("Search", text: $searchText)
             .onDebouncedChange(of: searchText, delay: 0.5) { newValue in
                 performSearch(newValue)
             }
     }
 }
 */
