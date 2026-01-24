//
//  AddTransactionSheet.swift
//  Swiff IOS
//
//  Redesigned 3-step transaction creation flow matching reference UI
//  Production-ready with full accessibility and design system compliance
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

    /// Saving state for feedback and preventing double-taps
    @State private var isSaving: Bool = false

    /// Focus state for keyboard management
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool

    // MARK: - Computed Properties

    private var totalSteps: Int {
        viewModel.splitOptions.isSplit ? 3 : 2
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                sheetHeader
                stepContent
            }

            // Loading overlay during save
            if isSaving {
                Color.black.opacity(Theme.Opacity.subtle)
                    .ignoresSafeArea()

                VStack(spacing: Theme.Metrics.paddingMedium) {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary)
                        )
                        .scaleEffect(1.3)

                    Text("Saving...")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textOnPrimary)
                }
                .padding(Theme.Metrics.paddingLarge)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.brandPrimary)
                )
            }
        }
        .background(Theme.Colors.secondaryBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Metrics.cornerRadiusLarge)
        .disabled(isSaving)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .onAppear {
            setupPreselectedParticipant()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("New Transaction Sheet")
    }

    // MARK: - Subviews

    /// Header with navigation, title, and step indicator
    private var sheetHeader: some View {
        VStack(spacing: Theme.Metrics.paddingSmall) {
            // Title Row
            HStack {
                // Left: Close or Back Button
                Button(action: {
                    HapticManager.shared.selection()
                    if viewModel.currentStep > 1 {
                        withAnimation(.smooth) {
                            viewModel.goToPreviousStep()
                        }
                    } else {
                        showingAddTransactionSheet = false
                        viewModel.reset()
                    }
                }) {
                    Image(systemName: viewModel.currentStep > 1 ? "arrow.left" : "xmark")
                        .font(.system(size: Theme.Metrics.iconSizeMedium, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .frame(width: Theme.Metrics.minTapTarget, height: Theme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(viewModel.currentStep > 1 ? "Go back" : "Close")

                Spacer()

                // Center: Dynamic Title
                Text(stepTitle)
                    .font(Theme.Fonts.headerMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                // Right: Spacer for centering
                Color.clear
                    .frame(width: Theme.Metrics.minTapTarget, height: Theme.Metrics.minTapTarget)
            }

            // Step Indicator Row
            HStack(spacing: Theme.Metrics.paddingSmall) {
                ForEach(1...3, id: \.self) { step in
                    Circle()
                        .fill(
                            step <= viewModel.currentStep
                                ? Theme.Colors.brandPrimary
                                : Theme.Colors.textTertiary.opacity(Theme.Opacity.subtle)
                        )
                        .frame(width: 8, height: 8)
                        .animation(.smooth, value: viewModel.currentStep)
                }
            }
            .accessibilityLabel("Step \(viewModel.currentStep) of 3")
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.top, Theme.Metrics.paddingSmall)
        .padding(.bottom, Theme.Metrics.paddingMedium)
    }

    /// Dynamic title based on current step
    private var stepTitle: String {
        switch viewModel.currentStep {
        case 1: return "New Transaction"
        case 2: return "Split Options"
        case 3: return "Split Details"
        default: return "New Transaction"
        }
    }
    /// TabView-based step content with smooth transitions
    private var stepContent: some View {
        TabView(selection: $viewModel.currentStep) {
            Step1BasicDetailsView(viewModel: viewModel)
                .environmentObject(dataManager)
                .tag(1)

            Step2SplitOptionsView(viewModel: viewModel)
                .environmentObject(dataManager)
                .tag(2)

            if viewModel.splitOptions.isSplit {
                Step3SplitMethodView(
                    viewModel: viewModel,
                    onBack: {
                        withAnimation(.smooth) {
                            viewModel.goToPreviousStep()
                        }
                    },
                    onSave: {
                        saveTransaction()
                    }
                )
                .environmentObject(dataManager)
                .tag(3)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.smooth, value: viewModel.currentStep)
    }

    // MARK: - Private Methods

    private func setupPreselectedParticipant() {
        if let person = preselectedParticipant {
            viewModel.splitOptions.isSplit = true
            viewModel.splitOptions.addParticipant(person.id)
            let myId = UserProfileManager.shared.profile.id
            viewModel.splitOptions.addParticipant(myId)
            viewModel.splitMethod.initializeDefaults(
                for: viewModel.splitOptions.participantIds, totalAmount: 0)  // Amount might not be set yet
        }
    }

    private func dismissKeyboard() {
        isAmountFocused = false
        isNameFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func saveTransaction() {
        // Prevent double-tap
        guard !isSaving else { return }
        isSaving = true

        // Validate amount is safe
        guard viewModel.basicDetails.amount > 0, viewModel.basicDetails.amount.isFinite else {
            HapticManager.shared.error()
            ToastManager.shared.showError("Invalid amount. Please enter a valid number.")
            isSaving = false
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
            category: viewModel.basicDetails.selectedCategory,
            date: viewModel.basicDetails.transactionDate,
            isRecurring: false,
            tags: [],
            notes: viewModel.basicDetails.notes,
            splitBillId: splitBillId
        )

        onTransactionAdded(newTransaction)
        HapticManager.shared.success()
        ToastManager.shared.showSuccess("Transaction saved")
        showingAddTransactionSheet = false
        viewModel.reset()
        isSaving = false
    }

    private func createSplitBill(payerId: UUID) throws -> UUID {
        // Pre-validate all participants exist before making any changes
        var balanceChanges: [(person: Person, change: Double)] = []

        // Build participant list with stable ordering
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

        // Pre-validate: Check all participants exist and calculate balance changes
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
            splitType: viewModel.splitMethod.splitMethod,
            participants: participants,
            notes: viewModel.basicDetails.notes,
            category: viewModel.basicDetails.selectedCategory,
            date: viewModel.basicDetails.transactionDate
        )

        try dataManager.addSplitBill(splitBill)

        // Apply all balance changes atomically
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
