//
//  NewTransactionViewModel.swift
//  Swiff IOS
//
//  ViewModel for the 3-step New Transaction flow
//  Coordinator pattern with navigation direction tracking
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

// MARK: - Navigation Direction

enum StepNavigationDirection {
    case forward
    case backward
}

// MARK: - NewTransactionViewModel

@MainActor
class NewTransactionViewModel: ObservableObject {

    // MARK: - State Objects

    var basicDetails: BasicDetailsState
    var splitOptions: SplitOptionsState
    var splitMethod: SplitMethodState

    // MARK: - Navigation State

    @Published var currentStep: Int = 1
    @Published var navigationDirection: StepNavigationDirection = .forward
    @Published var isTransitioning: Bool = false
    @Published var isLoading: Bool = false
    @Published var showCancelConfirmation: Bool = false

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
        // Forward child state changes to trigger UI updates
        basicDetails.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        splitOptions.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        splitMethod.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    /// Whether the user has entered any data (for cancel confirmation)
    var hasUnsavedData: Bool {
        basicDetails.amountInCents > 0
            || !basicDetails.transactionName.trimmingCharacters(in: .whitespaces).isEmpty
            || basicDetails.selectedCategory != nil
            || !splitOptions.participantIds.isEmpty
    }

    /// Final validation check for transaction submission
    var canSubmit: Bool {
        if !splitOptions.isSplit {
            return basicDetails.canProceed
        }
        return basicDetails.canProceed
            && splitOptions.canProceed
            && splitMethod.isBalanced(
                amount: basicDetails.amount,
                participantIds: splitOptions.participantIds
            )
    }

    /// Calculated splits for all participants
    var calculatedSplits: [UUID: SplitDetail] {
        splitMethod.calculateSplits(
            amount: basicDetails.amount,
            participantIds: splitOptions.participantIds
        )
    }

    /// Remaining amount to allocate
    var remainingAmount: Double {
        let allocated = splitOptions.participantIds.reduce(0.0) { sum, id in
            sum + (calculatedSplits[id]?.amount ?? 0)
        }
        return max(0, basicDetails.amount - allocated)
    }

    // MARK: - Navigation

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
            // Initialize split method defaults when entering Step 3
            if splitOptions.isSplit {
                splitMethod.initializeDefaults(
                    for: splitOptions.participantIds,
                    totalAmount: basicDetails.amount
                )
            }

        default:
            break
        }

        isTransitioning = true
        navigationDirection = .forward
        HapticManager.shared.selection()

        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep < 3 {
                currentStep += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    func goToPreviousStep() {
        guard !isTransitioning else { return }
        guard currentStep > 1 else { return }

        isTransitioning = true
        navigationDirection = .backward
        HapticManager.shared.selection()

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    /// Handle cancel: show confirmation if data has been entered
    func handleCancel() -> Bool {
        if hasUnsavedData {
            showCancelConfirmation = true
            return false // Don't dismiss yet
        }
        return true // OK to dismiss
    }

    // MARK: - Reset

    func reset() {
        currentStep = 1
        navigationDirection = .forward
        isTransitioning = false
        isLoading = false
        showCancelConfirmation = false

        basicDetails.reset()
        splitOptions.reset()
        splitMethod.reset()
    }
}
