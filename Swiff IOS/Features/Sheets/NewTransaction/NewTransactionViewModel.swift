//
//  NewTransactionViewModel.swift
//  Swiff IOS
//
//  ViewModel for the 3-step New Transaction flow
//  Refactored to use Coordinator pattern with separate State objects
//

import Combine
import Foundation
import SwiftUI

// MARK: - Transaction Type Option

enum TransactionTypeOption: String, CaseIterable {
    case expense = "Expense"
    case income = "Income"

    var icon: String {
        switch self {
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .expense: return Theme.Colors.statusError
        case .income: return Theme.Colors.amountPositive
        }
    }
}

// MARK: - NewTransactionViewModel

@MainActor
class NewTransactionViewModel: ObservableObject {

    // MARK: - State Objects

    var basicDetails: BasicDetailsState
    var splitOptions: SplitOptionsState
    var splitMethod: SplitMethodState

    // MARK: - Navigation State

    /// Current step in the 3-step flow (1, 2, or 3)
    @Published var currentStep: Int = 1

    /// Prevents double-tap navigation issues
    @Published var isTransitioning: Bool = false

    /// Loading state for network/async operations
    @Published var isLoading: Bool = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.basicDetails = BasicDetailsState()
        self.splitOptions = SplitOptionsState()
        self.splitMethod = SplitMethodState()

        setupObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Sync basic details amount changes to split method state if needed
        basicDetails.$amountString
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Sync split options changes to split method initialization
        splitOptions.$participantIds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Observe child state changes to trigger UI updates
        basicDetails.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(
            in: &cancellables)
        splitOptions.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(
            in: &cancellables)
        splitMethod.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(
            in: &cancellables)
    }

    // MARK: - Validation - Final Submission

    /// Final validation check for transaction submission
    var canSubmit: Bool {
        if !splitOptions.isSplit {
            return basicDetails.canProceed
        }
        return basicDetails.canProceed && splitOptions.canProceed
            && splitMethod.isBalanced(
                amount: basicDetails.amount, participantIds: splitOptions.participantIds)
    }

    // MARK: - Computed Properties for Views (Facade)

    var calculatedSplits: [UUID: SplitDetail] {
        splitMethod.calculateSplits(
            amount: basicDetails.amount, participantIds: splitOptions.participantIds)
    }

    var remainingAmount: Double {
        let allocated = splitOptions.participantIds.reduce(0.0) { sum, id in
            sum + (calculatedSplits[id]?.amount ?? 0)
        }
        return max(0, basicDetails.amount - allocated)
    }

    // MARK: - Navigation

    /// Advances to the next step with validation
    func goToNextStep() {
        guard !isTransitioning else { return }

        switch currentStep {
        case 1:
            guard basicDetails.canProceed else {
                HapticManager.shared.warning()
                return
            }

        case 2:
            guard splitOptions.canProceed else {
                HapticManager.shared.warning()
                return
            }
            // Initialize defaults when moving to Step 3
            if splitOptions.isSplit {
                splitMethod.initializeDefaults(
                    for: splitOptions.participantIds, totalAmount: basicDetails.amount)
            }

        default:
            break
        }

        isTransitioning = true
        HapticManager.shared.selection()

        withAnimation(.smooth(duration: 0.3)) {
            if currentStep < 3 {
                currentStep += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    /// Returns to the previous step
    func goToPreviousStep() {
        guard !isTransitioning else { return }
        guard currentStep > 1 else { return }

        isTransitioning = true
        HapticManager.shared.selection()

        withAnimation(.smooth(duration: 0.3)) {
            currentStep -= 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    // MARK: - Reset

    /// Resets all state to initial values
    func reset() {
        currentStep = 1
        isTransitioning = false
        isLoading = false

        basicDetails.reset()
        splitOptions.reset()
        splitMethod.reset()
    }
}
