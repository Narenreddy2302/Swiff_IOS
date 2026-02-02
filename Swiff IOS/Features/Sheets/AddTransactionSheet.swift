//
//  AddTransactionSheet.swift
//  Swiff IOS
//
//  Full-screen sheet for creating new transactions
//  3-step flow with slide navigation, step indicator, and cancel confirmation
//

import SwiftUI

// MARK: - AddTransactionSheet

struct AddTransactionSheet: View {

    // MARK: - Properties

    @Binding var showingAddTransactionSheet: Bool
    let onTransactionAdded: (Transaction) -> Void
    var preselectedParticipant: Person? = nil

    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = NewTransactionViewModel()

    /// Saving state
    @State private var isSaving: Bool = false
    @State private var showSuccessOverlay: Bool = false
    @State private var shakeOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                sheetHeader

                // Step Content with custom slide transitions
                stepContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Loading overlay
            if isSaving {
                savingOverlay
            }

            // Success flash
            if showSuccessOverlay {
                successOverlay
            }
        }
        .background(Theme.Colors.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Metrics.cornerRadiusLarge)
        .disabled(isSaving)
        .alert("Discard this transaction?", isPresented: $viewModel.showCancelConfirmation) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard", role: .destructive) {
                showingAddTransactionSheet = false
                viewModel.reset()
            }
        } message: {
            Text("You'll lose all the details you've entered.")
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedData)
        .onAppear {
            setupPreselectedParticipant()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("New Transaction Sheet")
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        VStack(spacing: 10) {
            HStack {
                // Left button: Cancel or Back
                Button {
                    HapticManager.shared.selection()
                    if viewModel.currentStep > 1 {
                        viewModel.goToPreviousStep()
                    } else {
                        handleCancel()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.currentStep > 1 {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Back")
                        } else {
                            Text("Cancel")
                        }
                    }
                    .font(.system(size: 17))
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                }
                .accessibilityLabel(viewModel.currentStep > 1 ? "Go back" : "Cancel")

                Spacer()

                // Center: Step indicator dots
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        Capsule()
                            .fill(
                                step <= viewModel.currentStep
                                    ? Theme.Colors.brandPrimary
                                    : Theme.Colors.textTertiary.opacity(0.3)
                            )
                            .frame(
                                width: step == viewModel.currentStep ? 20 : 8,
                                height: 8
                            )
                            .animation(
                                reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8),
                                value: viewModel.currentStep
                            )
                    }
                }
                .accessibilityLabel("Step \(viewModel.currentStep) of 3")

                Spacer()

                // Right button: Next (steps 1 & 2) or empty (step 3)
                if viewModel.currentStep < 3 {
                    Button {
                        HapticManager.shared.selection()
                        viewModel.splitOptions.isSplit = true
                        viewModel.goToNextStep()
                    } label: {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.Colors.brandPrimary)
                            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    }
                    .disabled(!currentStepCanProceed)
                    .opacity(currentStepCanProceed ? 1.0 : Theme.Opacity.disabled)
                    .accessibilityLabel("Next step")
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
        .padding(.top, Theme.Metrics.paddingSmall)
        .padding(.bottom, 4)
        .background(Theme.Colors.background)
    }

    // MARK: - Step Content

    private var stepContentView: some View {
        ZStack {
            // Step views with transitions based on navigation direction
            Group {
                if viewModel.currentStep == 1 {
                    Step1BasicDetailsView(viewModel: viewModel)
                        .environmentObject(dataManager)
                } else if viewModel.currentStep == 2 {
                    Step2SplitOptionsView(viewModel: viewModel)
                        .environmentObject(dataManager)
                } else if viewModel.currentStep == 3 {
                    Step3SplitMethodView(
                        viewModel: viewModel,
                        onBack: {
                            viewModel.goToPreviousStep()
                        },
                        onSave: {
                            saveTransaction()
                        }
                    )
                    .environmentObject(dataManager)
                }
            }
            .transition(stepTransition)
            .id(viewModel.currentStep)
        }
        .clipped()
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 0.3),
            value: viewModel.currentStep
        )
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return viewModel.navigationDirection == .forward
            ? .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
            : .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
    }

    // MARK: - Overlays

    private var savingOverlay: some View {
        Color.black.opacity(Theme.Opacity.subtle)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: Theme.Metrics.paddingMedium) {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary)
                        )
                        .scaleEffect(1.3)

                    Text("Creating\u{2026}")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.textOnPrimary)
                }
                .padding(Theme.Metrics.paddingLarge)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.brandPrimary)
                )
            )
            .transition(.opacity)
    }

    private var successOverlay: some View {
        Color.clear
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.success)

                    Text("Transaction Created!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(Theme.Metrics.paddingLarge)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.cardBackground)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
                )
            )
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Validation

    private var currentStepCanProceed: Bool {
        switch viewModel.currentStep {
        case 1: return viewModel.basicDetails.canProceed
        case 2: return viewModel.splitOptions.canProceed
        default: return false
        }
    }

    // MARK: - Actions

    private func handleCancel() {
        if viewModel.hasUnsavedData {
            viewModel.showCancelConfirmation = true
        } else {
            showingAddTransactionSheet = false
            viewModel.reset()
        }
    }

    private func setupPreselectedParticipant() {
        if let person = preselectedParticipant {
            viewModel.splitOptions.isSplit = true
            viewModel.splitOptions.addParticipant(person.id)
            let myId = UserProfileManager.shared.profile.id
            viewModel.splitOptions.addParticipant(myId)
            viewModel.splitMethod.initializeDefaults(
                for: viewModel.splitOptions.participantIds,
                totalAmount: 0
            )
        }
    }

    // MARK: - Save Transaction

    private func saveTransaction() {
        guard !isSaving else { return }
        isSaving = true
        viewModel.isLoading = true

        // Validate amount
        guard viewModel.basicDetails.amount > 0, viewModel.basicDetails.amount.isFinite else {
            HapticManager.shared.error()
            ToastManager.shared.showError("Invalid amount. Please enter a valid number.")
            isSaving = false
            viewModel.isLoading = false
            return
        }

        let finalAmount =
            viewModel.basicDetails.transactionType == .expense
            ? -abs(viewModel.basicDetails.amount)
            : abs(viewModel.basicDetails.amount)

        var splitBillId: UUID? = nil

        // Create split bill if splitting
        if viewModel.splitOptions.isSplit, let payerId = viewModel.splitOptions.paidByUserId {
            do {
                splitBillId = try createSplitBill(payerId: payerId)
            } catch {
                handleSaveError(error)
                return
            }
        }

        let subtitle =
            viewModel.splitOptions.isSplit
            ? "Split Transaction" : viewModel.basicDetails.transactionType.rawValue

        let newTransaction = Transaction(
            title: viewModel.basicDetails.transactionName.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle,
            amount: finalAmount,
            category: viewModel.basicDetails.selectedCategory ?? .other,
            date: viewModel.basicDetails.transactionDate,
            isRecurring: false,
            tags: [],
            notes: viewModel.basicDetails.notes,
            splitBillId: splitBillId
        )

        onTransactionAdded(newTransaction)

        // Success feedback
        HapticManager.shared.success()

        // Show success animation then dismiss
        withAnimation(.spring(response: 0.3)) {
            showSuccessOverlay = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            ToastManager.shared.showSuccess("Transaction created")
            showingAddTransactionSheet = false
            viewModel.reset()
            isSaving = false
            viewModel.isLoading = false
        }
    }

    private func createSplitBill(payerId: UUID) throws -> UUID {
        var balanceChanges: [(person: Person, change: Double)] = []

        let sortedParticipantIds = viewModel.splitOptions.participantIds.sorted()
        let calculatedSplits = viewModel.calculatedSplits

        let participants = sortedParticipantIds.map { personId -> SplitParticipant in
            let calculated = calculatedSplits[personId] ?? SplitDetail()
            return SplitParticipant(
                personId: personId,
                amount: calculated.amount,
                hasPaid: personId == payerId,
                percentage: calculated.percentage,
                shares: viewModel.splitMethod.splitMethod == .shares ? calculated.shares : nil
            )
        }

        // Pre-validate: Check all participants exist
        for participant in participants where participant.personId != payerId {
            guard let person = dataManager.people.first(where: { $0.id == participant.personId })
            else {
                throw TransactionSaveError.participantNotFound
            }
            balanceChanges.append((person: person, change: -participant.amount))
        }

        // Pre-validate payer exists
        guard let payerPerson = dataManager.people.first(where: { $0.id == payerId }) else {
            throw TransactionSaveError.payerNotFound
        }

        let totalOwed =
            participants
            .filter { $0.personId != payerId }
            .reduce(0) { $0 + $1.amount }
        balanceChanges.append((person: payerPerson, change: totalOwed))

        // Create split bill
        let splitBill = SplitBill(
            title: viewModel.basicDetails.transactionName.trimmingCharacters(in: .whitespaces),
            totalAmount: abs(viewModel.basicDetails.amount),
            paidById: payerId,
            createdById: UserProfileManager.shared.profile.id,
            splitType: viewModel.splitMethod.splitMethod,
            participants: participants,
            notes: viewModel.basicDetails.notes,
            category: viewModel.basicDetails.selectedCategory ?? .other,
            date: viewModel.basicDetails.transactionDate
        )

        try dataManager.addSplitBill(splitBill)

        // Apply balance changes
        for (person, change) in balanceChanges {
            var updatedPerson = person
            updatedPerson.balance += change
            try dataManager.updatePerson(updatedPerson)
        }

        return splitBill.id
    }

    private func handleSaveError(_ error: Error) {
        HapticManager.shared.error()

        if let saveError = error as? TransactionSaveError {
            ToastManager.shared.showError(saveError.userMessage)
        } else {
            ToastManager.shared.showError("Failed to create split: \(error.localizedDescription)")
        }

        isSaving = false
        viewModel.isLoading = false
    }
}

// MARK: - Transaction Save Error

private enum TransactionSaveError: Error {
    case participantNotFound
    case payerNotFound
    case saveFailed(Error)

    var userMessage: String {
        switch self {
        case .participantNotFound:
            return "Participant not found. Please refresh and try again."
        case .payerNotFound:
            return "Payer not found. Please refresh and try again."
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview("Add Transaction Sheet") {
    AddTransactionSheet(
        showingAddTransactionSheet: .constant(true),
        onTransactionAdded: { _ in }
    )
    .environmentObject(DataManager.shared)
}
