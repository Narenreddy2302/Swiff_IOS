//
//  Step3SplitMethodView.swift
//  Swiff IOS
//
//  Step 3: Split Details - Method selection and per-person configuration
//  Redesigned to match reference UI with proper theme consistency
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
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingMedium + 4) {
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
                .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
            }
            .safeAreaInset(edge: .bottom) {
                // Create Transaction button
                createTransactionButton
                    .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
                    .padding(.bottom, Theme.Metrics.paddingMedium + 4)
                    .background(
                        Color.wiseGroupedBackground
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
                    .foregroundColor(.wisePrimaryText)
            }

            Spacer()

            // Title
            Text("Add Transaction")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            // Step indicator
            Text("STEP 3/3")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseForestGreen)
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
        .padding(.vertical, Theme.Metrics.paddingSmall + 4)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: Theme.Metrics.paddingSmall) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step == 3 ? Color.wiseForestGreen : Color.wiseBorder)
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
                .font(.spotifyDisplayMedium)
                .foregroundColor(.wisePrimaryText)

            HStack(spacing: 4) {
                Text("Specify how the")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)

                Text(viewModel.amount.asCurrency)
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)

                Text("should be divided.")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
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
                    VStack(spacing: Theme.Metrics.paddingSmall) {
                        Text(label)
                            .font(viewModel.splitMethod == method ? .spotifyLabelLarge : .spotifyBodyMedium)
                            .foregroundColor(viewModel.splitMethod == method ? Color.wiseForestGreen : Color.wiseSecondaryText)

                        // Underline indicator
                        Rectangle()
                            .fill(viewModel.splitMethod == method ? Color.wiseForestGreen : Color.clear)
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
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: viewModel.isSplitValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.isSplitValid ? Color.wiseForestGreen : Color.wiseWarning)

                Text(viewModel.isSplitValid ? "Balanced (100%)" : "Not Balanced")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(viewModel.isSplitValid ? Color.wiseForestGreen : Color.wiseWarning)
            }

            Spacer()

            Text("Total: \(viewModel.amount.asCurrency)")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingMedium - 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(viewModel.isSplitValid ? Color.wiseGreen1 : Color.wiseOrange.opacity(0.15))
        )
    }

    // MARK: - Participants List

    private var participantsList: some View {
        let sortedParticipantIds = viewModel.participantIds.sorted()

        return VStack(spacing: Theme.Metrics.paddingSmall + 4) {
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
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)

                Text(remainingAmount.asCurrency)
                    .font(.spotifyNumberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(remainingAmount == 0 ? Color.wiseForestGreen : Color.amountNegative)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("TOTAL")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)

                Text(viewModel.amount.asCurrency)
                    .font(.spotifyNumberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.wisePrimaryText)
            }
        }
        .padding(.top, Theme.Metrics.paddingSmall)
    }

    // MARK: - Create Transaction Button

    private var createTransactionButton: some View {
        Button {
            HapticManager.shared.success()
            onSave?()
        } label: {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Text("Create Transaction")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .fill(Color.wiseForestGreen)
                    .opacity(viewModel.canSubmit ? 1 : 0.5)
            )
        }
        .disabled(!viewModel.canSubmit)
        .cardShadow()
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
        HStack(spacing: Theme.Metrics.paddingMedium - 2) {
            // Avatar
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: 52, height: 52)

            // Name and amount
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)

                Text(calculated.amount.asCurrency)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Input control based on split method
            splitInputControl
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingMedium - 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                .fill(Color.wiseCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
        .cardShadow()
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
                .font(.spotifyBodyLarge)
                .fontWeight(.medium)
                .foregroundColor(.wiseSecondaryText)

        case .percentages:
            // Editable percentage input
            HStack(spacing: 4) {
                TextField("0", text: $percentageText)
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .onChange(of: percentageText) { _, newValue in
                        if let value = Double(newValue) {
                            onPercentageChanged(value)
                        }
                    }

                Text("%")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium - 2)
            .padding(.vertical, Theme.Metrics.paddingSmall + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall + 2)
                    .stroke(Color.wiseForestGreen.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall + 2)
                            .fill(Color.wiseTertiaryBackground)
                    )
            )

        case .exactAmounts:
            // Editable amount input
            HStack(spacing: 4) {
                Text("$")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("0.00", value: .constant(calculated.amount), format: .number)
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .onChange(of: calculated.amount) { _, newValue in
                        onAmountChanged(newValue)
                    }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium - 2)
            .padding(.vertical, Theme.Metrics.paddingSmall + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall + 2)
                    .stroke(Color.wiseForestGreen.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall + 2)
                            .fill(Color.wiseTertiaryBackground)
                    )
            )

        case .shares:
            // Share stepper
            HStack(spacing: Theme.Metrics.paddingSmall + 4) {
                Button(action: {
                    HapticManager.shared.light()
                    let current = calculated.shares
                    if current > 1 {
                        onSharesChanged(current - 1)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.wisePrimaryText)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.wiseTertiaryBackground))
                }
                .buttonStyle(.plain)

                Text("\(calculated.shares)x")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)
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
                        .foregroundColor(.wisePrimaryText)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.wiseTertiaryBackground))
                }
                .buttonStyle(.plain)
            }

        case .adjustments:
            // Adjustment input
            HStack(spacing: 4) {
                Text("+/-")
                    .font(.spotifyBodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.wiseSecondaryText)

                TextField("0", value: .constant(calculated.adjustment), format: .number)
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium - 2)
            .padding(.vertical, Theme.Metrics.paddingSmall + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall + 2)
                    .stroke(Color.wiseForestGreen.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall + 2)
                            .fill(Color.wiseTertiaryBackground)
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
    .background(Color.wiseGroupedBackground)
}
