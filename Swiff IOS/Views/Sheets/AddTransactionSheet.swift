//
//  AddTransactionSheet.swift
//  Swiff IOS
//
//  Redesigned 3-step transaction creation flow matching reference UI
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

    private var totalSteps: Int {
        viewModel.isSplit ? 3 : 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // New header design with step badge
            sheetHeader

            // Step content
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
        .background(Color.wiseGroupedBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Metrics.cornerRadiusLarge)
        .disabled(isSaving)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAmountFocused = false
                    isNameFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.spotifyBodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.wiseForestGreen)
            }
        }
        .onAppear {
            setupPreselectedParticipant()
        }
    }

    // MARK: - New Header Design

    private var sheetHeader: some View {
        HStack {
            // Close button
            Button(action: {
                HapticManager.shared.light()
                showingAddTransactionSheet = false
                viewModel.reset()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.wiseSecondaryText)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Close")

            Spacer()

            // Title
            Text("New Transaction")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            // Step indicator badge
            Text("STEP \(viewModel.currentStep) OF \(totalSteps)")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.wiseBorder.opacity(0.5))
                )
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.top, Theme.Metrics.paddingMedium)
        .padding(.bottom, Theme.Metrics.paddingSmall)
    }

    // MARK: - Actions

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
                date: viewModel.transactionDate
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
}

// MARK: - Preview

#Preview("Add Transaction Sheet") {
    AddTransactionSheet(
        showingAddTransactionSheet: .constant(true),
        onTransactionAdded: { _ in }
    )
    .environmentObject(DataManager.shared)
}
