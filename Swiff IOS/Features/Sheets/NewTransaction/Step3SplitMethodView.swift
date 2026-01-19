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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 3: Configure split details")
    }

    private func dismissKeyboard() {
        focusedParticipant = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
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
        .scrollDismissesKeyboard(.interactively)
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
        HStack(spacing: Theme.Metrics.spacingTiny) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step == 3 ? Theme.Colors.brandPrimary : Theme.Colors.border)
                    .frame(width: step == 3 ? Theme.Metrics.progressDotActive : Theme.Metrics.progressDotInactive, height: Theme.Metrics.progressDotInactive)
                    .animation(.snappy, value: step)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Step 3 of 3 active")
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny + 2) {
            Text("Split Details")
                .font(Theme.Fonts.displayMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Theme.Metrics.spacingTiny) {
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                ForEach(splitMethods, id: \.0) { method, label in
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.smooth) {
                            viewModel.splitMethod = method
                            viewModel.onSplitMethodChanged()
                        }
                    }) {
                        HStack(spacing: Theme.Metrics.spacingTiny) {
                            Image(systemName: splitMethodIcon(for: method))
                                .font(.system(size: Theme.Metrics.iconSizeSmall))

                            Text(label)
                                .font(Theme.Fonts.labelMedium)
                        }
                        .foregroundColor(viewModel.splitMethod == method ? Theme.Colors.textOnPrimary : Theme.Colors.textPrimary)
                        .padding(.horizontal, Theme.Metrics.paddingMedium)
                        .padding(.vertical, Theme.Metrics.paddingSmall)
                        .background(
                            Capsule()
                                .fill(viewModel.splitMethod == method ? Theme.Colors.brandPrimary : Theme.Colors.cardBackground)
                        )
                        .overlay(
                            Capsule()
                                .stroke(viewModel.splitMethod == method ? Color.clear : Theme.Colors.border, lineWidth: Theme.Border.widthDefault)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label) split method")
                    .accessibilityAddTraits(viewModel.splitMethod == method ? .isSelected : [])
                }
            }
            .padding(.horizontal, Theme.Metrics.spacingTiny)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Split method selection")
    }

    private func splitMethodIcon(for method: SplitType) -> String {
        switch method {
        case .equally: return "equal"
        case .exactAmounts: return "dollarsign"
        case .percentages: return "percent"
        case .shares: return "number"
        case .adjustments: return "plusminus"
        }
    }

    private var balancedStatusIndicator: some View {
        HStack {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: viewModel.isSplitValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: Theme.Metrics.iconSizeSmall))
                    .foregroundColor(viewModel.isSplitValid ? Theme.Colors.brandPrimary : Theme.Colors.warning)

                Text(viewModel.isSplitValid ? "Balanced (100%)" : "Not Balanced")
                    .font(Theme.Fonts.labelLarge)
                    .foregroundColor(viewModel.isSplitValid ? Theme.Colors.brandPrimary : Theme.Colors.statusError)
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
                .fill(viewModel.isSplitValid ? Theme.Colors.green1 : Theme.Colors.statusError.opacity(Theme.Opacity.faint))
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
                        },
                        onAdjustmentChanged: { adjustment in
                            viewModel.updateSplitAdjustment(for: participantId, adjustment: adjustment)
                        }
                    )
                }
            }
        }
    }

    private var bottomSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
                Text("REMAINING")
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(remainingAmount.asCurrency)
                    .font(Theme.Fonts.numberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(abs(remainingAmount) < 0.01 ? Theme.Colors.brandPrimary : Theme.Colors.amountNegative)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Theme.Metrics.spacingTiny) {
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
                    .opacity(viewModel.canSubmit ? 1 : Theme.Opacity.disabled)
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
    let onAdjustmentChanged: (Double) -> Void

    /// Text state for editable input fields
    @State private var percentageText: String = ""
    @State private var amountText: String = ""
    @State private var adjustmentText: String = ""

    // MARK: - Body

    var body: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            AvatarBubbleView(
                person: person,
                size: Theme.Metrics.avatarBubbleSize,
                isSelected: false,
                showRemoveButton: false
            )

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
                .stroke(Theme.Colors.border, lineWidth: Theme.Border.widthDefault)
        )
        .onAppear {
            percentageText = String(format: "%.0f", calculated.percentage)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(calculated.amount.asCurrency), \(Int(calculated.percentage)) percent")
    }

    // MARK: - Subviews

    private var personInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
            Text(person.name)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(calculated.amount.asCurrency)
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, Theme.Metrics.spacingTiny)
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
        HStack(spacing: Theme.Metrics.spacingTiny) {
            TextField("0", text: $percentageText)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: Theme.Metrics.splitInputWidth)
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
        .transactionInputFieldStyle()
        .accessibilityLabel("Percentage input")
    }

    private var exactAmountControl: some View {
        HStack(spacing: Theme.Metrics.spacingTiny) {
            Text("$")
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)

            TextField("0.00", text: $amountText)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: Theme.Metrics.amountInputWidth)
                .onChange(of: amountText) { _, newValue in
                    // Filter to valid decimal input
                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                    if filtered != newValue {
                        amountText = filtered
                    }
                    if let value = Double(filtered) {
                        onAmountChanged(value)
                    }
                }
                .onAppear {
                    amountText = String(format: "%.2f", calculated.amount)
                }
        }
        .transactionInputFieldStyle()
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
                    .frame(width: Theme.Metrics.stepperButtonSize, height: Theme.Metrics.stepperButtonSize)
                    .background(Circle().fill(Theme.Colors.secondaryBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease shares")

            Text("\(calculated.shares)x")
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(width: Theme.Metrics.sharesDisplayWidth)
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
                    .frame(width: Theme.Metrics.stepperButtonSize, height: Theme.Metrics.stepperButtonSize)
                    .background(Circle().fill(Theme.Colors.secondaryBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase shares")
        }
    }

    private var adjustmentControl: some View {
        HStack(spacing: Theme.Metrics.spacingTiny) {
            Text("+/-")
                .font(Theme.Fonts.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)

            TextField("0", text: $adjustmentText)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .frame(width: Theme.Metrics.splitInputWidth)
                .onChange(of: adjustmentText) { _, newValue in
                    // Filter to valid decimal input (allow negative)
                    let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "-" }
                    if filtered != newValue {
                        adjustmentText = filtered
                    }
                    if let value = Double(filtered) {
                        onAdjustmentChanged(value)
                    }
                }
                .onAppear {
                    adjustmentText = String(format: "%.2f", calculated.adjustment)
                }
                .accessibilityLabel("Adjustment amount")
        }
        .transactionInputFieldStyle()
        .accessibilityLabel("Adjustment input")
    }
}

// MARK: - Input Field Style Modifier



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
