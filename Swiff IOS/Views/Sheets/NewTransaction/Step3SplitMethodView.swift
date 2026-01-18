//
//  Step3SplitMethodView.swift
//  Swiff IOS
//
//  Step 3: Split Details - Method selection and per-person configuration
//  Redesigned to match reference UI exactly
//

import SwiftUI

struct Step3SplitMethodView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedParticipant: UUID?

    // Navigation callbacks
    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    // Split method tabs
    private let splitMethods: [(SplitType, String)] = [
        (.equally, "Equally"),
        (.exactAmounts, "Exact"),
        (.percentages, "Percentage"),
        (.shares, "Shares")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header with back and step indicator
            headerSection

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Progress dots
                    progressDots

                    // Split Details title and subtitle
                    titleSection

                    // Split method tab selector
                    splitMethodTabs

                    // Balanced status indicator
                    balancedStatusIndicator

                    // Participants list with split inputs
                    participantsList

                    // Bottom summary
                    bottomSummary

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .safeAreaInset(edge: .bottom) {
                // Create Transaction button
                createTransactionButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(
                        Color(UIColor.systemGroupedBackground)
                            .ignoresSafeArea()
                    )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Back button
            Button(action: {
                HapticManager.shared.light()
                onBack?()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Spacer()

            // Title
            Text("Add Transaction")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            // Step indicator
            Text("STEP 3/3")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.brandPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step == 3 ? Theme.Colors.brandPrimary : Color(UIColor.systemGray4))
                    .frame(width: step == 3 ? 24 : 8, height: 8)
                    .animation(.snappy, value: step)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Split Details")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: 4) {
                Text("Specify how the")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(viewModel.amount.asCurrency)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("should be divided.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Split Method Tabs

    private var splitMethodTabs: some View {
        HStack(spacing: 0) {
            ForEach(splitMethods, id: \.0) { method, label in
                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        viewModel.splitMethod = method
                        viewModel.onSplitMethodChanged()
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(label)
                            .font(.system(size: 15, weight: viewModel.splitMethod == method ? .semibold : .regular))
                            .foregroundColor(viewModel.splitMethod == method ? Theme.Colors.brandPrimary : Theme.Colors.textSecondary)

                        // Underline indicator
                        Rectangle()
                            .fill(viewModel.splitMethod == method ? Theme.Colors.brandPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Balanced Status Indicator

    private var balancedStatusIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isSplitValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.isSplitValid ? Theme.Colors.brandPrimary : Theme.Colors.warning)

                Text(viewModel.isSplitValid ? "Balanced (100%)" : "Not Balanced")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.isSplitValid ? Theme.Colors.brandPrimary : Theme.Colors.warning)
            }

            Spacer()

            Text("Total: \(viewModel.amount.asCurrency)")
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isSplitValid ? Theme.Colors.brandPrimary.opacity(0.1) : Theme.Colors.warning.opacity(0.1))
        )
    }

    // MARK: - Participants List

    private var participantsList: some View {
        let sortedParticipantIds = viewModel.participantIds.sorted()

        return VStack(spacing: 12) {
            ForEach(sortedParticipantIds, id: \.self) { participantId in
                if let person = dataManager.people.first(where: { $0.id == participantId }) {
                    ParticipantSplitCard(
                        person: person,
                        calculated: viewModel.calculatedSplits[participantId] ?? SplitDetail(),
                        splitMethod: viewModel.splitMethod,
                        isFocused: focusedParticipant == participantId,
                        onAmountChanged: { amount in
                            viewModel.updateSplitAmount(for: participantId, amount: amount)
                        },
                        onPercentageChanged: { percentage in
                            viewModel.updateSplitPercentage(for: participantId, percentage: percentage)
                        },
                        onSharesChanged: { shares in
                            viewModel.updateSplitShares(for: participantId, shares: shares)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Bottom Summary

    private var bottomSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("REMAINING")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(remainingAmount.asCurrency)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(remainingAmount == 0 ? Theme.Colors.brandPrimary : Theme.Colors.amountNegative)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("TOTAL")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(viewModel.amount.asCurrency)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Create Transaction Button

    private var createTransactionButton: some View {
        Button {
            HapticManager.shared.light()
            onSave?()
        } label: {
            HStack(spacing: 8) {
                Text("Create Transaction")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.brandPrimary)
                    .opacity(viewModel.canSubmit ? 1 : 0.5)
            )
        }
        .disabled(!viewModel.canSubmit)
    }

    // MARK: - Computed Properties

    private var remainingAmount: Double {
        let allocated = viewModel.calculatedSplits.values.reduce(0) { $0 + $1.amount }
        return max(0, viewModel.amount - allocated)
    }
}

// MARK: - Participant Split Card

struct ParticipantSplitCard: View {
    let person: Person
    let calculated: SplitDetail
    let splitMethod: SplitType
    let isFocused: Bool
    let onAmountChanged: (Double) -> Void
    let onPercentageChanged: (Double) -> Void
    let onSharesChanged: (Int) -> Void

    @State private var percentageText: String = ""

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: 52, height: 52)

            // Name and amount
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(calculated.amount.asCurrency)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            // Input control based on split method
            splitInputControl
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .onAppear {
            percentageText = String(format: "%.0f", calculated.percentage)
        }
    }

    @ViewBuilder
    private var splitInputControl: some View {
        switch splitMethod {
        case .equally:
            // Just show percentage
            Text("\(Int(calculated.percentage)) %")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)

        case .percentages:
            // Editable percentage input
            HStack(spacing: 4) {
                TextField("0", text: $percentageText)
                    .font(.system(size: 17, weight: .medium))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .onChange(of: percentageText) { _, newValue in
                        if let value = Double(newValue) {
                            onPercentageChanged(value)
                        }
                    }

                Text("%")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.brandPrimary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    )
            )

        case .exactAmounts:
            // Editable amount input
            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField("0.00", value: .constant(calculated.amount), format: .number)
                    .font(.system(size: 17, weight: .medium))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .onChange(of: calculated.amount) { _, newValue in
                        onAmountChanged(newValue)
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.brandPrimary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    )
            )

        case .shares:
            // Share stepper
            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.shared.light()
                    let current = calculated.shares
                    if current > 1 {
                        onSharesChanged(current - 1)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(UIColor.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)

                Text("\(calculated.shares)x")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(width: 32)

                Button(action: {
                    HapticManager.shared.light()
                    let current = calculated.shares
                    if current < 10 {
                        onSharesChanged(current + 1)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(UIColor.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
            }

        case .adjustments:
            // Adjustment input
            HStack(spacing: 4) {
                Text("+/-")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField("0", value: .constant(calculated.adjustment), format: .number)
                    .font(.system(size: 17, weight: .medium))
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.brandPrimary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview("Step 3 - Split Details") {
    Step3SplitMethodView(
        viewModel: {
            let vm = NewTransactionViewModel()
            vm.isSplit = true
            vm.amountString = "1240"
            return vm
        }()
    )
    .environmentObject(DataManager.shared)
    .background(Color(UIColor.systemGroupedBackground))
}
