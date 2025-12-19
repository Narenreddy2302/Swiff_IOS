//
//  AddSplitBillSheet.swift
//  Swiff IOS
//
//  Multi-step wizard for creating split bills
//

import SwiftUI

struct AddSplitBillSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    // Step navigation
    @State private var currentStep = 0
    private let totalSteps = 6
    private let stepTitles = ["Details", "Payer", "Participants", "Split Type", "Configure", "Review"]

    // Step 1: Details
    @State private var title = ""
    @State private var totalAmount = ""
    @State private var date = Date()
    @State private var category: TransactionCategory = .dining
    @State private var notes = ""

    // Step 2: Payer
    @State private var selectedPayer: Person?

    // Step 3: Participants
    @State private var selectedParticipants: Set<UUID> = []
    @State private var selectedGroup: Group?

    // Step 4: Split Type
    @State private var selectedSplitType: SplitType = .equally
    @State private var previousSplitType: SplitType = .equally

    // Step 5: Configure
    @State private var participantAmounts: [UUID: Double] = [:]
    @State private var participantPercentages: [UUID: Double] = [:]
    @State private var participantShares: [UUID: Int] = [:]

    // Error handling
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var configValidationError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                StepProgressView(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    stepTitles: stepTitles
                )
                .padding(.top, 8)

                Divider()
                    .background(Color.wiseBorder.opacity(0.3))

                // Step content
                TabView(selection: $currentStep) {
                    Step1DetailsView(
                        title: $title,
                        totalAmount: $totalAmount,
                        date: $date,
                        category: $category,
                        notes: $notes
                    )
                    .tag(0)

                    Step2PayerView(selectedPayer: $selectedPayer)
                        .tag(1)

                    Step3ParticipantsView(
                        selectedParticipants: $selectedParticipants,
                        selectedGroup: $selectedGroup
                    )
                    .tag(2)

                    Step4SplitTypeView(selectedSplitType: $selectedSplitType)
                        .tag(3)

                    Step5ConfigureView(
                        splitType: selectedSplitType,
                        totalAmount: Double(totalAmount) ?? 0,
                        participantIds: Array(selectedParticipants),
                        participantAmounts: $participantAmounts,
                        participantPercentages: $participantPercentages,
                        participantShares: $participantShares
                    )
                    .tag(4)

                    if let payer = selectedPayer {
                        Step6ReviewView(
                            title: title,
                            totalAmount: Double(totalAmount) ?? 0,
                            payer: payer,
                            participants: calculateParticipants(),
                            category: category,
                            date: date,
                            notes: notes
                        )
                        .tag(5)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                Divider()
                    .background(Color.wiseBorder.opacity(0.3))

                VStack(spacing: 12) {
                    // Validation error banner
                    if !canProceed, let errorMessage = currentValidationMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                            Text(errorMessage)
                                .font(.spotifyCaptionMedium)
                        }
                        .foregroundColor(.wiseError)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.wiseError.opacity(0.1))
                        .cornerRadius(8)
                    }

                    HStack(spacing: 12) {
                        // Back button
                        if currentStep > 0 {
                            Button(action: {
                                HapticManager.shared.light()
                                withAnimation(.smooth) {
                                    currentStep -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.wisePrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.wiseSecondaryButton)
                                .cornerRadius(12)
                            }
                        }

                        // Next/Create button
                        Button(action: {
                            HapticManager.shared.light()
                            handleNextAction()
                        }) {
                            Text(currentStep == totalSteps - 1 ? "Create Split Bill" : "Next")
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(canProceed ? .wiseForestGreen : .wiseSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(canProceed ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .disabled(!canProceed)
                    }
                }
                .padding(16)
                .background(Color.wiseBackground)
            }
            .navigationTitle("Split Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .foregroundColor(.wisePrimaryText)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Validation

    private var canProceed: Bool {
        switch currentStep {
        case 0: // Details
            let amount = Double(totalAmount) ?? 0
            return !title.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
        case 1: // Payer
            return selectedPayer != nil
        case 2: // Participants
            // Handle both group mode and individual selection
            if selectedGroup != nil {
                return true // Group is selected, participants will be auto-populated
            }
            return !selectedParticipants.isEmpty
        case 3: // Split Type
            return true // Always valid
        case 4: // Configure
            return validateConfiguration()
        case 5: // Review
            return true
        default:
            return false
        }
    }

    private func validateConfiguration() -> Bool {
        let amount = Double(totalAmount) ?? 0
        let participants = calculateParticipants()

        // Check for empty participants
        guard !participants.isEmpty else {
            configValidationError = "No participants selected"
            return false
        }

        let validation = SplitCalculationService.validateSplit(
            totalAmount: amount,
            participants: participants,
            splitType: selectedSplitType
        )

        configValidationError = validation.error
        return validation.isValid
    }

    /// Get validation error message for current step
    private var currentValidationMessage: String? {
        switch currentStep {
        case 0:
            if title.trimmingCharacters(in: .whitespaces).isEmpty {
                return "Please enter a title"
            }
            if (Double(totalAmount) ?? 0) <= 0 {
                return "Please enter a valid amount"
            }
            return nil
        case 1:
            return selectedPayer == nil ? "Please select who paid" : nil
        case 2:
            if selectedGroup == nil && selectedParticipants.isEmpty {
                return "Please select participants or a group"
            }
            return nil
        case 4:
            return configValidationError
        default:
            return nil
        }
    }

    // MARK: - Actions

    private func handleNextAction() {
        if currentStep < totalSteps - 1 {
            // Check if split type changed when leaving step 3
            if currentStep == 3 && selectedSplitType != previousSplitType {
                resetConfigurationForSplitType()
                previousSplitType = selectedSplitType
            }

            withAnimation(.smooth) {
                currentStep += 1
            }
        } else {
            createSplitBill()
        }
    }

    /// Reset configuration data when split type changes
    private func resetConfigurationForSplitType() {
        let amount = Double(totalAmount) ?? 0
        let equalAmount = SplitCalculationService.equalAmountPerPerson(totalAmount: amount, participantCount: selectedParticipants.count)

        switch selectedSplitType {
        case .equally:
            // No configuration needed
            break

        case .exactAmounts, .adjustments:
            participantAmounts.removeAll()
            for id in selectedParticipants {
                participantAmounts[id] = equalAmount
            }

        case .percentages:
            participantPercentages.removeAll()
            let equalPercentage = SplitCalculationService.roundToCents(100.0 / Double(max(1, selectedParticipants.count)))
            for id in selectedParticipants {
                participantPercentages[id] = equalPercentage
            }

        case .shares:
            participantShares.removeAll()
            for id in selectedParticipants {
                participantShares[id] = 1
            }
        }

        // Clear validation error
        configValidationError = nil
    }

    private func createSplitBill() {
        guard let payer = selectedPayer else { return }
        guard let amount = Double(totalAmount) else { return }

        let participants = calculateParticipants()

        let splitBill = SplitBill(
            title: title,
            totalAmount: amount,
            paidById: payer.id,
            splitType: selectedSplitType,
            participants: participants,
            notes: notes,
            category: category,
            date: date,
            groupId: selectedGroup?.id
        )

        do {
            try dataManager.addSplitBill(splitBill)
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func calculateParticipants() -> [SplitParticipant] {
        let amount = Double(totalAmount) ?? 0
        let participantIds = Array(selectedParticipants)

        switch selectedSplitType {
        case .equally:
            return SplitCalculationService.calculateEqualSplit(
                totalAmount: amount,
                participantIds: participantIds
            )
        case .exactAmounts:
            return SplitCalculationService.calculateExactAmounts(amounts: participantAmounts)
        case .percentages:
            return SplitCalculationService.calculatePercentages(
                totalAmount: amount,
                percentages: participantPercentages
            )
        case .shares:
            return SplitCalculationService.calculateShares(
                totalAmount: amount,
                shares: participantShares
            )
        case .adjustments:
            return SplitCalculationService.calculateAdjustments(
                totalAmount: amount,
                participantIds: participantIds,
                adjustments: participantAmounts
            )
        }
    }
}

// MARK: - Preview

#Preview("Add Split Bill Sheet") {
    let dataManager = DataManager.shared
    let person1 = Person(name: "Alice", email: "alice@example.com", phone: "+1234567890", avatar: "👩‍💼")
    let person2 = Person(name: "Bob", email: "bob@example.com", phone: "+1234567891", avatar: "👨‍💻")
    dataManager.people = [person1, person2]

    return AddSplitBillSheet()
        .environmentObject(dataManager)
}
