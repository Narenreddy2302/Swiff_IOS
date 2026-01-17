//
//  AddTransactionSheet.swift
//  Swiff IOS
//
//  Refined 3-step transaction creation flow with clean UI and keyboard handling
//

import SwiftUI

struct AddTransactionSheet: View {
    @Binding var showingAddTransactionSheet: Bool
    let onTransactionAdded: (Transaction) -> Void
    var preselectedParticipant: Person? = nil

    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = NewTransactionViewModel()

    // Saving state for feedback
    @State private var isSaving: Bool = false

    // Focus state for keyboard management
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool

    private let stepTitles = ["Details", "Split", "Breakdown"]

    var body: some View {
        VStack(spacing: 0) {
            // Simplified Header with navigation
            sheetHeader

            // Compact step progress dots
            stepProgressDots
                .padding(.vertical, Theme.Metrics.paddingMedium)

            // Step content
            TabView(selection: $viewModel.currentStep) {
                Step1BasicDetailsView(viewModel: viewModel)
                    .environmentObject(dataManager)
                    .tag(1)

                Step2SplitOptionsView(viewModel: viewModel)
                    .environmentObject(dataManager)
                    .tag(2)

                if viewModel.isSplit {
                    Step3SplitMethodView(viewModel: viewModel)
                        .environmentObject(dataManager)
                        .tag(3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: viewModel.currentStep)

            // Validation message for Step 3 (compact)
            if viewModel.currentStep == 3, let message = viewModel.validationMessage {
                validationBanner(message: message, isValid: viewModel.isSplitValid)
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.bottom, Theme.Metrics.paddingMedium)
            }
        }
        .background(Theme.Colors.sheetCardBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Metrics.cornerRadiusLarge)
        .disabled(isSaving)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAmountFocused = false
                    isNameFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .onAppear {
            setupPreselectedParticipant()
        }
    }

    // MARK: - Simplified Header with Navigation

    private var sheetHeader: some View {
        HStack(spacing: Theme.Metrics.headerContentSpacing) {
            // Cancel / Back button
            Button(action: {
                HapticManager.shared.light()
                if viewModel.currentStep > 1 {
                    withAnimation(.smooth) {
                        viewModel.goToPreviousStep()
                    }
                } else {
                    showingAddTransactionSheet = false
                    viewModel.reset()
                }
            }) {
                HStack(spacing: 4) {
                    if viewModel.currentStep > 1 {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(viewModel.currentStep > 1 ? "Back" : "Cancel")
                        .font(Theme.Fonts.bodyLarge)
                }
                .foregroundColor(Theme.Colors.textPrimary)
            }
            .frame(width: 80, alignment: .leading)
            .accessibilityLabel(viewModel.currentStep > 1 ? "Go back to previous step" : "Cancel transaction")
            .accessibilityHint(viewModel.currentStep > 1 ? "Double tap to go back" : "Double tap to cancel")

            Spacer()

            // Center title
            Text(currentStepTitle)
                .font(Theme.Fonts.headerMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            // Primary action button
            Button(action: {
                HapticManager.shared.light()
                handlePrimaryAction()
            }) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.brandPrimary))
                } else {
                    Text(primaryButtonTitle)
                        .font(Theme.Fonts.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(canProceed ? Theme.Colors.brandPrimary : Theme.Colors.textSecondary.opacity(0.5))
                }
            }
            .disabled(!canProceed || isSaving)
            .frame(width: 80, alignment: .trailing)
            .accessibilityLabel(primaryButtonTitle)
            .accessibilityHint(canProceed ? "Double tap to \(primaryButtonTitle.lowercased())" : "Complete required fields first")
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.top, Theme.Metrics.paddingMedium)
        .padding(.bottom, Theme.Metrics.paddingSmall)
    }

    // MARK: - Step Progress Dots

    private var stepProgressDots: some View {
        let totalSteps = viewModel.isSplit ? 3 : 2

        return HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= viewModel.currentStep ? Theme.Colors.brandPrimary : Theme.Colors.border)
                    .frame(
                        width: step == viewModel.currentStep ? 8 : 6,
                        height: step == viewModel.currentStep ? 8 : 6
                    )
                    .scaleEffect(step == viewModel.currentStep ? 1.0 : 0.85)
                    .animation(.snappy, value: viewModel.currentStep)
                    .accessibilityLabel("Step \(step) of \(totalSteps)")
                    .accessibilityValue(step < viewModel.currentStep ? "Completed" : (step == viewModel.currentStep ? "Current step" : "Not started"))
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Validation Banner

    private func validationBanner(message: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 14))
            Text(message)
                .font(Theme.Fonts.captionMedium)
        }
        .foregroundColor(isValid ? Theme.Colors.success : Theme.Colors.systemError)
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingSmall)
        .frame(maxWidth: .infinity)
        .background((isValid ? Theme.Colors.success : Theme.Colors.systemError).opacity(0.1))
        .cornerRadius(Theme.Metrics.cornerRadiusSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isValid ? "Validation passed: \(message)" : "Validation warning: \(message)")
    }

    // MARK: - Computed Properties

    private var currentStepTitle: String {
        let totalSteps = viewModel.isSplit ? 3 : 2
        guard viewModel.currentStep >= 1 && viewModel.currentStep <= totalSteps else {
            return "New Transaction"
        }
        return stepTitles[viewModel.currentStep - 1]
    }

    private var primaryButtonTitle: String {
        switch viewModel.currentStep {
        case 1:
            return "Next"
        case 2:
            return viewModel.isSplit ? "Next" : "Save"
        case 3:
            return "Save"
        default:
            return "Next"
        }
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case 1:
            return viewModel.canProceedStep1
        case 2:
            if viewModel.isSplit {
                return viewModel.canProceedStep2
            } else {
                return viewModel.canProceedStep1
            }
        case 3:
            return viewModel.canSubmit
        default:
            return false
        }
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        switch viewModel.currentStep {
        case 1:
            withAnimation(.smooth) {
                viewModel.goToNextStep()
            }
        case 2:
            if viewModel.isSplit {
                viewModel.initializeSplitDefaults()
                withAnimation(.smooth) {
                    viewModel.goToNextStep()
                }
            } else {
                saveTransaction()
            }
        case 3:
            saveTransaction()
        default:
            break
        }
    }

    private func setupPreselectedParticipant() {
        if let person = preselectedParticipant {
            viewModel.isSplit = true
            viewModel.participantIds.insert(person.id)
            viewModel.initializeSplitDefaults()
        }
    }

    private func saveTransaction() {
        // Prevent double-tap
        guard !isSaving else { return }
        isSaving = true

        // Validate amount is safe
        guard viewModel.amount > 0, viewModel.amount.isFinite else {
            HapticManager.shared.error()
            ToastManager.shared.showError("Invalid amount. Please enter a valid number.")
            isSaving = false
            return
        }

        let finalAmount = viewModel.transactionType == .expense ? -abs(viewModel.amount) : abs(viewModel.amount)

        var splitBillId: UUID? = nil

        // Create split bill if splitting
        if viewModel.isSplit, let payerId = viewModel.paidByUserId {
            // Pre-validate all participants exist before making any changes
            var balanceChanges: [(person: Person, change: Double)] = []

            // Build participant list with stable ordering
            let sortedParticipantIds = viewModel.participantIds.sorted()
            let participants = sortedParticipantIds.map { personId -> SplitParticipant in
                let calculated = viewModel.calculatedSplits[personId] ?? SplitDetail()
                return SplitParticipant(
                    personId: personId,
                    amount: calculated.amount,
                    hasPaid: personId == payerId,
                    percentage: calculated.percentage,
                    shares: viewModel.splitMethod == .shares ? calculated.shares : nil
                )
            }

            // Pre-validate: Check all participants exist and calculate balance changes
            for participant in participants where participant.personId != payerId {
                guard let person = dataManager.people.first(where: { $0.id == participant.personId }) else {
                    HapticManager.shared.error()
                    ToastManager.shared.showError("Participant not found. Please refresh and try again.")
                    isSaving = false
                    return
                }
                balanceChanges.append((person: person, change: -participant.amount))
            }

            // Pre-validate payer exists
            guard let payerPerson = dataManager.people.first(where: { $0.id == payerId }) else {
                HapticManager.shared.error()
                ToastManager.shared.showError("Payer not found. Please refresh and try again.")
                isSaving = false
                return
            }

            let totalOwed = participants
                .filter { $0.personId != payerId }
                .reduce(0) { $0 + $1.amount }
            balanceChanges.append((person: payerPerson, change: totalOwed))

            // Create split bill
            let splitBill = SplitBill(
                title: viewModel.transactionName.trimmingCharacters(in: .whitespaces),
                totalAmount: abs(viewModel.amount),
                paidById: payerId,
                splitType: viewModel.splitMethod,
                participants: participants,
                notes: viewModel.notes,
                category: viewModel.selectedCategory,
                date: Date()
            )

            do {
                try dataManager.addSplitBill(splitBill)
                splitBillId = splitBill.id

                // Apply all balance changes atomically
                for (person, change) in balanceChanges {
                    var updatedPerson = person
                    updatedPerson.balance += change
                    try dataManager.updatePerson(updatedPerson)
                }
            } catch {
                HapticManager.shared.error()
                ToastManager.shared.showError("Failed to create split: \(error.localizedDescription)")
                isSaving = false
                return
            }
        }

        let subtitle = viewModel.isSplit ? "Split Transaction" : viewModel.transactionType.rawValue
        let newTransaction = Transaction(
            title: viewModel.transactionName.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle,
            amount: finalAmount,
            category: viewModel.selectedCategory,
            date: Date(),
            isRecurring: false,
            tags: [],
            notes: viewModel.notes,
            splitBillId: splitBillId
        )

        onTransactionAdded(newTransaction)
        HapticManager.shared.success()
        ToastManager.shared.showSuccess("Transaction saved")
        showingAddTransactionSheet = false
        viewModel.reset()
        isSaving = false
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
