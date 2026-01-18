//
//  Step3SplitMethodView.swift
//  Swiff IOS
//
//  Step 3: Split Details - Method selection and per-person configuration
//  Production-ready with design system compliance and accessibility
//

import SwiftUI

// MARK: - Step3SplitMethodView

struct Step3SplitMethodView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedParticipant: UUID?

    /// Navigation callbacks
    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    // MARK: - Constants

    private let splitMethods: [(SplitType, String)] = [
        (.equally, "Equally"),
        (.exactAmounts, "Exact"),
        (.percentages, "Percentage"),
        (.shares, "Shares")
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            scrollContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 3: Configure split details")
    }

    // MARK: - Subviews

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingMedium) {
                progressDots
                titleSection
                splitMethodTabs
                balancedStatusIndicator
                participantsList
                bottomSummary
                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
        .safeAreaInset(edge: .bottom) {
            createTransactionButton
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.bottom, Theme.Metrics.paddingMedium)
                .background(
                    Theme.Colors.secondaryBackground
                        .ignoresSafeArea()
                )
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: {
                HapticManager.shared.selection()
                onBack?()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .accessibilityLabel("Go back")

            Spacer()

            Text("Add Transaction")
                .font(Theme.Fonts.headerMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Text("STEP 3/3")
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.brandPrimary)
                .accessibilityLabel("Step 3 of 3")
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingSmall)
    }

    private var progressDots: some View {
        HStack(spacing: Theme.Metrics.paddingSmall) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step == 3 ? Theme.Colors.brandPrimary : Theme.Colors.border)
                    .frame(width: step == 3 ? 24 : 8, height: 8)
                    .animation(.snappy, value: step)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Step 3 of 3 active")
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Split Details")
                .font(Theme.Fonts.displayMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 4) {
                Text("Specify how the")
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(viewModel.amount.asCurrency)
                    .font(Theme.Fonts.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("should be divided.")
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Split details. Specify how the \(viewModel.amount.asCurrency) should be divided")
    }

    private var splitMethodTabs: some View {
        HStack(spacing: 0) {
            ForEach(splitMethods, id: \.0) { method, label in
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.smooth) {
                        viewModel.splitMethod = method
                        viewModel.onSplitMethodChanged()
                    }
                }) {
                    VStack(spacing: Theme.Metrics.paddingSmall) {
                        Text(label)
                            .font(viewModel.splitMethod == method ? Theme.Fonts.labelLarge : Theme.Fonts.bodyMedium)
                            .foregroundColor(viewModel.splitMethod == method ? Theme.Colors.brandPrimary : Theme.Colors.textSecondary)

                        Rectangle()
                            .fill(viewModel.splitMethod == method ? Theme.Colors.brandPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("\(label) split method")
                .accessibilityAddTraits(viewModel.splitMethod == method ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Split method selection")
    }

    private var balancedStatusIndicator: some View {
        HStack {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: viewModel.isSplitValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: Theme.Metrics.iconSizeSmall))
                    .foregroundColor(viewModel.isSplitValid ? Theme.Colors.brandPrimary : Theme.Colors.warning)

                Text(viewModel.isSplitValid ? "Balanced (100%)" : "Not Balanced")
                    .font(Theme.Fonts.labelLarge)
                    .foregroundColor(viewModel.isSplitValid ? Theme.Colors.brandPrimary : Theme.Colors.warning)
            }

            Spacer()

            Text("Total: \(viewModel.amount.asCurrency)")
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(viewModel.isSplitValid ? Theme.Colors.green1 : Theme.Colors.brandAccent.opacity(0.15))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isSplitValid ? "Split is balanced at 100%" : "Split is not balanced")
    }

    private var participantsList: some View {
        let sortedParticipantIds = viewModel.participantIds.sorted()

        return VStack(spacing: Theme.Metrics.paddingSmall) {
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

    private var bottomSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("REMAINING")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(remainingAmount.asCurrency)
                    .font(Theme.Fonts.numberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(remainingAmount == 0 ? Theme.Colors.brandPrimary : Theme.Colors.amountNegative)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("TOTAL")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(viewModel.amount.asCurrency)
                    .font(Theme.Fonts.numberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
        .padding(.top, Theme.Metrics.paddingSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Remaining: \(remainingAmount.asCurrency). Total: \(viewModel.amount.asCurrency)")
    }

    private var createTransactionButton: some View {
        Button {
            HapticManager.shared.success()
            onSave?()
        } label: {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Text("Create Transaction")
                    .font(Theme.Fonts.bodyLarge)
                    .fontWeight(.semibold)

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Theme.Colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: SwiffButtonSize.large.height)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.brandPrimary)
                    .opacity(viewModel.canSubmit ? 1 : 0.5)
            )
        }
        .disabled(!viewModel.canSubmit)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Create transaction")
        .accessibilityHint(viewModel.canSubmit ? "Double tap to save transaction" : "Split must be balanced first")
    }

    // MARK: - Computed Properties

    private var remainingAmount: Double {
        let allocated = viewModel.calculatedSplits.values.reduce(0) { $0 + $1.amount }
        return max(0, viewModel.amount - allocated)
    }
}

// MARK: - ParticipantSplitCard

struct ParticipantSplitCard: View {

    // MARK: - Properties

    let person: Person
    let calculated: SplitDetail
    let splitMethod: SplitType
    let isFocused: Bool
    let onAmountChanged: (Double) -> Void
    let onPercentageChanged: (Double) -> Void
    let onSharesChanged: (Int) -> Void

    @State private var percentageText: String = ""

    // MARK: - Body

    var body: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: 52, height: 52)

            personInfo

            Spacer()

            splitInputControl
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .onAppear {
            percentageText = String(format: "%.0f", calculated.percentage)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(calculated.amount.asCurrency), \(Int(calculated.percentage)) percent")
    }

    // MARK: - Subviews

    private var personInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.name)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(calculated.amount.asCurrency)
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var splitInputControl: some View {
        switch splitMethod {
        case .equally:
            equallyControl

        case .percentages:
            percentageControl

        case .exactAmounts:
            exactAmountControl

        case .shares:
            sharesControl

        case .adjustments:
            adjustmentControl
        }
    }

    private var equallyControl: some View {
        Text("\(Int(calculated.percentage)) %")
            .font(Theme.Fonts.bodyLarge)
            .fontWeight(.medium)
            .foregroundColor(Theme.Colors.textSecondary)
            .accessibilityLabel("\(Int(calculated.percentage)) percent")
    }

    private var percentageControl: some View {
        HStack(spacing: 4) {
            TextField("0", text: $percentageText)
                .font(Theme.Fonts.bodyLarge)
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
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .inputFieldStyle()
        .accessibilityLabel("Percentage input")
    }

    private var exactAmountControl: some View {
        HStack(spacing: 4) {
            Text("$")
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)

            TextField("0.00", value: .constant(calculated.amount), format: .number)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .onChange(of: calculated.amount) { _, newValue in
                    onAmountChanged(newValue)
                }
        }
        .inputFieldStyle()
        .accessibilityLabel("Amount input")
    }

    private var sharesControl: some View {
        HStack(spacing: Theme.Metrics.paddingSmall) {
            Button(action: {
                HapticManager.shared.selection()
                let current = calculated.shares
                if current > 1 {
                    onSharesChanged(current - 1)
                }
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.Colors.secondaryBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease shares")

            Text("\(calculated.shares)x")
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(width: 32)
                .accessibilityLabel("\(calculated.shares) shares")

            Button(action: {
                HapticManager.shared.selection()
                let current = calculated.shares
                if current < 10 {
                    onSharesChanged(current + 1)
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.Colors.secondaryBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase shares")
        }
    }

    private var adjustmentControl: some View {
        HStack(spacing: 4) {
            Text("+/-")
                .font(Theme.Fonts.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)

            TextField("0", value: .constant(calculated.adjustment), format: .number)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
        }
        .inputFieldStyle()
        .accessibilityLabel("Adjustment input")
    }
}

// MARK: - Input Field Style Modifier

private extension View {
    func inputFieldStyle() -> some View {
        self
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, Theme.Metrics.paddingSmall)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall)
                    .stroke(Theme.Colors.brandPrimary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusSmall)
                            .fill(Theme.Colors.secondaryBackground)
                    )
            )
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
    .background(Theme.Colors.secondaryBackground)
}
