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
        (.shares, "Shares"),
        (.adjustments, "Adjustments"),
    ]

    // MARK: - Body

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // No header here as it's in the container
            scrollContent
        }
        .onTapGesture {
            dismissKeyboard()
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
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {

                // Summary Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Amount")
                        .font(Theme.Fonts.labelSmall)
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(viewModel.basicDetails.amount.asCurrency)
                        .font(Theme.Fonts.displayMedium)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.top, Theme.Metrics.paddingMedium)

                // Split Method Tabs
                splitMethodTabs

                // Balanced Indicator
                balancedStatusIndicator

                // Participants List
                participantsList

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Metrics.paddingSmall) {
                // Remaining amount summary above button
                remainingAmountSummary

                createTransactionButton
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.bottom, Theme.Metrics.paddingLarge)
            .background(
                Theme.Colors.secondaryBackground
                    .ignoresSafeArea()
            )
        }
    }

    private var splitMethodTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                ForEach(splitMethods, id: \.0) { method, label in
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.snappy) {
                            viewModel.splitMethod.splitMethod = method
                            viewModel.splitMethod.initializeDefaults(
                                for: viewModel.splitOptions.participantIds,
                                totalAmount: viewModel.basicDetails.amount)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: splitMethodIcon(for: method))
                                .font(.system(size: Theme.Metrics.iconSizeSmall))
                            Text(label)
                                .font(Theme.Fonts.labelSmall)
                        }
                        .padding(.horizontal, Theme.Metrics.paddingMedium)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.splitMethod.splitMethod == method
                                ? Theme.Colors.brandPrimary
                                : Theme.Colors.cardBackground
                        )
                        .foregroundColor(
                            viewModel.splitMethod.splitMethod == method
                                ? Theme.Colors.textOnPrimary
                                : Theme.Colors.textPrimary
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    Theme.Colors.border,
                                    lineWidth: viewModel.splitMethod.splitMethod == method ? 0 : 1)
                        )
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var balancedStatusIndicator: some View {
        let isBalanced = viewModel.splitMethod.isBalanced(
            amount: viewModel.basicDetails.amount,
            participantIds: viewModel.splitOptions.participantIds
        )

        return HStack {
            Image(
                systemName: isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .foregroundColor(isBalanced ? Theme.Colors.success : Theme.Colors.warning)

            Text(isBalanced ? "Split is balanced" : "Split is not balanced")
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            if !isBalanced {
                Text(viewModel.remainingAmount.asCurrency)
                    .font(Theme.Fonts.numberMedium)
                    .foregroundColor(Theme.Colors.statusError)
            }
        }
        .padding(Theme.Metrics.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(isBalanced ? Theme.Colors.green1 : Theme.Colors.warning.opacity(0.1))
        )
    }

    private var participantsList: some View {
        let sortedParticipantIds = viewModel.splitOptions.participantIds.sorted()
        let calculated = viewModel.calculatedSplits

        return VStack(spacing: Theme.Metrics.paddingSmall) {
            ForEach(sortedParticipantIds, id: \.self) { participantId in
                if let person = dataManager.people.first(where: { $0.id == participantId }) {
                    ParticipantSplitCard(
                        person: person,
                        calculated: calculated[participantId] ?? SplitDetail(),
                        splitMethod: viewModel.splitMethod.splitMethod,
                        isPayer: viewModel.splitOptions.paidByUserId == participantId,
                        onAmountChanged: { amount in
                            viewModel.splitMethod.updateSplitAmount(
                                for: participantId, amount: amount)
                        },
                        onPercentageChanged: { percentage in
                            viewModel.splitMethod.updateSplitPercentage(
                                for: participantId, percentage: percentage)
                        },
                        onSharesChanged: { shares in
                            viewModel.splitMethod.updateSplitShares(
                                for: participantId, shares: shares)
                        },
                        onAdjustmentChanged: { adjustment in
                            viewModel.splitMethod.updateSplitAdjustment(
                                for: participantId, adjustment: adjustment)
                        }
                    )
                }
            }
        }
    }

    private var remainingAmountSummary: some View {
        HStack {
            Text("Remaining")
                .font(Theme.Fonts.labelSmall)
                .foregroundColor(Theme.Colors.textSecondary)
            Spacer()
            Text(viewModel.remainingAmount.asCurrency)
                .font(Theme.Fonts.numberMedium)
                .fontWeight(.bold)
                .foregroundColor(
                    abs(viewModel.remainingAmount) < 0.01
                        ? Theme.Colors.success
                        : Theme.Colors.statusError
                )
        }
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
}

// MARK: - ParticipantSplitCard

struct ParticipantSplitCard: View {

    // MARK: - Properties

    let person: Person
    let calculated: SplitDetail
    let splitMethod: SplitType
    let isPayer: Bool
    let onAmountChanged: (Double) -> Void
    let onPercentageChanged: (Double) -> Void
    let onSharesChanged: (Int) -> Void
    let onAdjustmentChanged: (Double) -> Void

    // Local state for inputs
    @State private var percentageText: String = ""
    @State private var amountText: String = ""
    @State private var adjustmentText: String = ""

    // MARK: - Body

    var body: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            AvatarView(avatarType: person.avatarType, size: .small, style: .solid)
                .frame(width: Theme.Metrics.avatarStandard, height: Theme.Metrics.avatarStandard)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                if splitMethod != .exactAmounts {
                    Text(calculated.amount.asCurrency)
                        .font(Theme.Fonts.labelSmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            splitInputControl
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
        .onChange(of: calculated) { _, newCalculated in
            syncLocalState(from: newCalculated)
        }
        .onAppear {
            syncLocalState(from: calculated)
        }
    }

    private func syncLocalState(from detail: SplitDetail) {
        // Only update if the parsed value is significantly different to avoid fighting the user typing
        // For Amount
        if let current = Double(amountText), abs(current - detail.amount) > 0.01 {
            amountText = String(format: "%.2f", detail.amount)
        } else if amountText.isEmpty {
            amountText = String(format: "%.2f", detail.amount)
        }

        // For Percentage
        if let current = Double(percentageText), abs(current - detail.percentage) > 0.1 {
            percentageText = String(format: "%.1f", detail.percentage)
        } else if percentageText.isEmpty {
            percentageText = String(format: "%.1f", detail.percentage)
        }

        // For Adjustment
        if let current = Double(adjustmentText), abs(current - detail.adjustment) > 0.01 {
            adjustmentText = String(format: "%.2f", detail.adjustment)
        } else if adjustmentText.isEmpty && detail.adjustment != 0 {
            adjustmentText = String(format: "%.2f", detail.adjustment)
        }
    }

    // MARK: - Subviews

    private var personInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
            HStack(spacing: 4) {
                Text(person.name)
                    .font(Theme.Fonts.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)

                if isPayer {
                    Image(systemName: "creditcard.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

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
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: Theme.Metrics.splitInputWidth)
                .onChange(of: percentageText) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                    if filtered != newValue {
                        percentageText = filtered
                    }
                    if let value = Double(filtered) {
                        onPercentageChanged(value)
                    }
                }

            Text("%")
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(8)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(8)
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
                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                    if filtered != newValue {
                        amountText = filtered
                    }
                    if let value = Double(filtered) {
                        onAmountChanged(value)
                    }
                }
        }
        .padding(8)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(8)
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
                    .frame(
                        width: Theme.Metrics.stepperButtonSize,
                        height: Theme.Metrics.stepperButtonSize
                    )
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
                    .frame(
                        width: Theme.Metrics.stepperButtonSize,
                        height: Theme.Metrics.stepperButtonSize
                    )
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
                    let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "-" }
                    if filtered != newValue {
                        adjustmentText = filtered
                    }
                    if let value = Double(filtered) {
                        onAdjustmentChanged(value)
                    }
                }
        }
        .padding(8)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview("Step 3 - Split Details") {
    Step3SplitMethodView(
        viewModel: {
            let vm = NewTransactionViewModel()
            vm.splitOptions.isSplit = true
            vm.basicDetails.amountString = "1240"
            return vm
        }()
    )
    .environmentObject(DataManager.shared)
    .background(Theme.Colors.secondaryBackground)
}
