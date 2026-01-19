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
        viewModel.isSplit ? 3 : 2
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
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary))
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

    /// Header with close button, title, and step indicator
    private var sheetHeader: some View {
        HStack {
            closeButton
            Spacer()
            titleView
            Spacer()
            stepIndicator
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.top, Theme.Metrics.paddingMedium)
        .padding(.bottom, Theme.Metrics.paddingSmall)
    }

    private var closeButton: some View {
        Button(action: {
            HapticManager.shared.selection()
            showingAddTransactionSheet = false
            viewModel.reset()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: Theme.Metrics.iconSizeSmall, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: Theme.Metrics.avatarCompact, height: Theme.Metrics.avatarCompact)
        }
        .accessibilityLabel("Close")
        .accessibilityHint("Dismisses the new transaction sheet")
    }

    private var titleView: some View {
        Text("New Transaction")
            .font(Theme.Fonts.headerMedium)
            .foregroundColor(Theme.Colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var stepIndicator: some View {
        Text("STEP \(viewModel.currentStep) OF \(totalSteps)")
            .font(Theme.Fonts.labelSmall)
            .foregroundColor(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Metrics.paddingSmall)
            .padding(.vertical, Theme.Metrics.spacingTiny + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall)
                    .fill(Theme.Colors.border.opacity(Theme.Opacity.border))
            )
            .accessibilityLabel("Step \(viewModel.currentStep) of \(totalSteps)")
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

            if viewModel.isSplit {
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
            viewModel.isSplit = true
            viewModel.participantIds.insert(person.id)
            viewModel.initializeSplitDefaults()
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
        guard viewModel.amount > 0, viewModel.amount.isFinite else {
            HapticManager.shared.error()
            ToastManager.shared.showError("Invalid amount. Please enter a valid number.")
            isSaving = false
            return
        }

        let finalAmount =
            viewModel.transactionType == .expense
            ? -abs(viewModel.amount)
            : abs(viewModel.amount)

        var splitBillId: UUID? = nil

        // Create split bill if splitting
        if viewModel.isSplit, let payerId = viewModel.paidByUserId {
            do {
                splitBillId = try createSplitBill(payerId: payerId)
            } catch {
                handleSaveError(error)
                return
            }
        }

        let subtitle = viewModel.isSplit ? "Split Transaction" : viewModel.transactionType.rawValue
        let newTransaction = Transaction(
            title: viewModel.transactionName.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle,
            amount: finalAmount,
            category: viewModel.selectedCategory,
            date: viewModel.transactionDate,
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

    private func createSplitBill(payerId: UUID) throws -> UUID {
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
            title: viewModel.transactionName.trimmingCharacters(in: .whitespaces),
            totalAmount: abs(viewModel.amount),
            paidById: payerId,
            splitType: viewModel.splitMethod,
            participants: participants,
            notes: viewModel.notes,
            category: viewModel.selectedCategory,
            date: viewModel.transactionDate
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
