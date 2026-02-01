//
//  Step3SplitMethodView.swift
//  Swiff IOS
//
//  Step 3: Split Method — 5 split types with dynamic per-person controls
//  Includes transaction summary, split type tabs, and create button
//

import SwiftUI

// MARK: - Step3SplitMethodView

struct Step3SplitMethodView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedParticipant: UUID?

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Split Type Definitions

    private let splitTypes: [(SplitType, String, String)] = [
        (.equally, "Equally", "equal"),
        (.percentages, "By %", "percent"),
        (.adjustments, "Adjusted", "plusminus"),
        (.exactAmounts, "By Amount", "dollarsign"),
        (.shares, "By Shares", "chart.pie"),
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingMedium) {
                    // Transaction Summary Bar
                    transactionSummary
                        .padding(.horizontal, Theme.Metrics.paddingMedium)

                    // Split Type Selector
                    splitTypeSelector

                    // Balance Status
                    balanceStatusBar
                        .padding(.horizontal, Theme.Metrics.paddingMedium)

                    // Dynamic Split Content
                    splitContent
                        .padding(.horizontal, Theme.Metrics.paddingMedium)

                    // Footnote for equal split rounding
                    if viewModel.splitMethod.splitMethod == .equally && hasRoundingRemainder {
                        Text("Amounts rounded to the nearest cent")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textTertiary)
                            .padding(.horizontal, Theme.Metrics.paddingMedium)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.top, Theme.Metrics.paddingSmall)
            }
            .scrollDismissesKeyboard(.interactively)

            // Bottom CTA
            createTransactionBar
        }
        .background(Theme.Colors.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedParticipant = nil
                    dismissKeyboard()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 3: Configure how to split the transaction")
    }

    // MARK: - Transaction Summary Bar

    private var transactionSummary: some View {
        HStack(spacing: 12) {
            // Category icon
            if let category = viewModel.basicDetails.selectedCategory {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(category.color)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.basicDetails.transactionName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let category = viewModel.basicDetails.selectedCategory {
                        Text(category.rawValue)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    if let payerId = viewModel.splitOptions.paidByUserId,
                       let payer = resolvePerson(payerId)
                    {
                        Text("Paid by \(viewModel.splitOptions.isCurrentUser(payerId) ? "You" : payer.name)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }

            Spacer()

            Text("\(viewModel.basicDetails.currencySymbol)\(viewModel.basicDetails.formattedAmountRaw)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(Theme.Metrics.paddingMedium)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
    }

    // MARK: - Split Type Selector

    private var splitTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(splitTypes, id: \.0) { splitType, label, icon in
                    let isSelected = viewModel.splitMethod.splitMethod == splitType

                    Button {
                        HapticManager.shared.light()
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
                            viewModel.splitMethod.splitMethod = splitType
                            viewModel.splitMethod.initializeDefaults(
                                for: viewModel.splitOptions.participantIds,
                                totalAmount: viewModel.basicDetails.amount
                            )
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))

                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(width: 72, height: 56)
                        .background(
                            isSelected
                                ? Theme.Colors.brandPrimary
                                : Theme.Colors.secondaryBackground
                        )
                        .foregroundColor(
                            isSelected
                                ? Theme.Colors.textOnPrimary
                                : Theme.Colors.textPrimary
                        )
                        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                                .stroke(
                                    isSelected ? Color.clear : Theme.Colors.border,
                                    lineWidth: 1
                                )
                        )
                        .scaleEffect(isSelected ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label) split")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 2)
        }
    }

    // MARK: - Balance Status Bar

    private var balanceStatusBar: some View {
        let isBalanced = viewModel.splitMethod.isBalanced(
            amount: viewModel.basicDetails.amount,
            participantIds: viewModel.splitOptions.participantIds
        )

        return HStack(spacing: 8) {
            Image(systemName: isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(isBalanced ? Theme.Colors.success : Theme.Colors.warning)

            Text(balanceStatusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            if !isBalanced {
                Text(balanceRemainingText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.statusError)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(isBalanced ? Theme.Colors.success.opacity(0.08) : Theme.Colors.warning.opacity(0.08))
        )
    }

    private var balanceStatusText: String {
        let isBalanced = viewModel.splitMethod.isBalanced(
            amount: viewModel.basicDetails.amount,
            participantIds: viewModel.splitOptions.participantIds
        )
        return isBalanced ? "Split is balanced" : "Split is not balanced"
    }

    private var balanceRemainingText: String {
        switch viewModel.splitMethod.splitMethod {
        case .percentages:
            let total = viewModel.splitMethod.totalPercentage(
                participantIds: viewModel.splitOptions.participantIds
            )
            return String(format: "%.0f%% / 100%%", total)
        case .exactAmounts:
            let total = viewModel.splitMethod.totalAllocatedAmount(
                participantIds: viewModel.splitOptions.participantIds
            )
            let diff = viewModel.basicDetails.amount - total
            return diff > 0
                ? "\(diff.asCurrency) remaining"
                : "\(abs(diff).asCurrency) over"
        default:
            return ""
        }
    }

    // MARK: - Dynamic Split Content

    @ViewBuilder
    private var splitContent: some View {
        let participantIds = viewModel.splitOptions.orderedParticipantIds
        let calculated = viewModel.calculatedSplits

        switch viewModel.splitMethod.splitMethod {
        case .equally:
            equalSplitContent(participantIds: participantIds, calculated: calculated)

        case .percentages:
            percentageSplitContent(participantIds: participantIds, calculated: calculated)

        case .adjustments:
            adjustedSplitContent(participantIds: participantIds, calculated: calculated)

        case .exactAmounts:
            amountSplitContent(participantIds: participantIds, calculated: calculated)

        case .shares:
            sharesSplitContent(participantIds: participantIds, calculated: calculated)
        }
    }

    // MARK: - Equal Split

    private func equalSplitContent(participantIds: [UUID], calculated: [UUID: SplitDetail]) -> some View {
        VStack(spacing: 12) {
            // Per person amount highlight
            if let first = calculated.values.first {
                Text("\(viewModel.basicDetails.currencySymbol)\(String(format: "%.2f", first.amount)) per person")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            // Member list
            VStack(spacing: 0) {
                ForEach(participantIds, id: \.self) { personId in
                    if let person = resolvePerson(personId) {
                        let detail = calculated[personId] ?? SplitDetail()
                        HStack(spacing: 12) {
                            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                                .frame(width: 32, height: 32)

                            Text(viewModel.splitOptions.isCurrentUser(personId) ? "You" : person.name)
                                .font(.system(size: 17))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            Text(detail.amount.asCurrency)
                                .font(.system(size: 17))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, Theme.Metrics.paddingMedium)
                        .padding(.vertical, 12)

                        if personId != participantIds.last {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Metrics.cornerRadiusMedium)
        }
    }

    // MARK: - Percentage Split

    private func percentageSplitContent(participantIds: [UUID], calculated: [UUID: SplitDetail]) -> some View {
        VStack(spacing: 8) {
            ForEach(participantIds, id: \.self) { personId in
                if let person = resolvePerson(personId) {
                    let detail = calculated[personId] ?? SplitDetail()
                    SplitInputRow(
                        person: person,
                        isCurrentUser: viewModel.splitOptions.isCurrentUser(personId),
                        primaryValue: String(format: "%.1f", viewModel.splitMethod.splitDetails[personId]?.percentage ?? 0),
                        suffix: "%",
                        secondaryValue: "= \(detail.amount.asCurrency)",
                        onValueChanged: { newValue in
                            if let pct = Double(newValue) {
                                viewModel.splitMethod.updateSplitPercentage(for: personId, percentage: pct)
                            }
                        },
                        focusedId: $focusedParticipant,
                        personId: personId
                    )
                }
            }

            // Total bar
            totalBar(
                label: "Total",
                value: String(format: "%.0f%%", viewModel.splitMethod.totalPercentage(participantIds: viewModel.splitOptions.participantIds)),
                target: "100%",
                isBalanced: abs(viewModel.splitMethod.totalPercentage(participantIds: viewModel.splitOptions.participantIds) - 100) < 0.1
            )
        }
    }

    // MARK: - Adjusted Split

    private func adjustedSplitContent(participantIds: [UUID], calculated: [UUID: SplitDetail]) -> some View {
        VStack(spacing: 8) {
            ForEach(participantIds, id: \.self) { personId in
                if let person = resolvePerson(personId) {
                    let detail = calculated[personId] ?? SplitDetail()
                    HStack(spacing: 12) {
                        AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.splitOptions.isCurrentUser(personId) ? "You" : person.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(detail.amount.asCurrency)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .monospacedDigit()
                        }

                        Spacer()

                        // Stepper controls
                        HStack(spacing: 12) {
                            Button {
                                HapticManager.shared.light()
                                let current = viewModel.splitMethod.splitDetails[personId]?.adjustment ?? 0
                                viewModel.splitMethod.updateSplitAdjustment(for: personId, adjustment: current - 1.0)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Theme.Colors.brandPrimary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Decrease amount")

                            let adj = viewModel.splitMethod.splitDetails[personId]?.adjustment ?? 0
                            Text(adj == 0 ? "$0" : String(format: "%+.0f", adj))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(adj > 0 ? Theme.Colors.success : adj < 0 ? Theme.Colors.statusError : Theme.Colors.textSecondary)
                                .frame(width: 48)
                                .monospacedDigit()

                            Button {
                                HapticManager.shared.light()
                                let current = viewModel.splitMethod.splitDetails[personId]?.adjustment ?? 0
                                viewModel.splitMethod.updateSplitAdjustment(for: personId, adjustment: current + 1.0)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Theme.Colors.brandPrimary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase amount")
                        }
                    }
                    .padding(Theme.Metrics.paddingMedium)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Metrics.cornerRadiusMedium)
                }
            }
        }
    }

    // MARK: - Amount Split

    private func amountSplitContent(participantIds: [UUID], calculated: [UUID: SplitDetail]) -> some View {
        VStack(spacing: 8) {
            ForEach(participantIds, id: \.self) { personId in
                if let person = resolvePerson(personId) {
                    SplitInputRow(
                        person: person,
                        isCurrentUser: viewModel.splitOptions.isCurrentUser(personId),
                        primaryValue: String(format: "%.2f", viewModel.splitMethod.splitDetails[personId]?.amount ?? 0),
                        suffix: "",
                        secondaryValue: nil,
                        prefix: viewModel.basicDetails.currencySymbol,
                        onValueChanged: { newValue in
                            if let amt = Double(newValue) {
                                viewModel.splitMethod.updateSplitAmount(for: personId, amount: amt)
                            }
                        },
                        focusedId: $focusedParticipant,
                        personId: personId
                    )
                }
            }

            // Total bar
            let totalAllocated = viewModel.splitMethod.totalAllocatedAmount(
                participantIds: viewModel.splitOptions.participantIds
            )
            totalBar(
                label: "Total",
                value: totalAllocated.asCurrency,
                target: viewModel.basicDetails.amount.asCurrency,
                isBalanced: abs(totalAllocated - viewModel.basicDetails.amount) < 0.01
            )
        }
    }

    // MARK: - Shares Split

    private func sharesSplitContent(participantIds: [UUID], calculated: [UUID: SplitDetail]) -> some View {
        VStack(spacing: 8) {
            // Per share value
            let totalShareCount = viewModel.splitMethod.totalShares(
                participantIds: viewModel.splitOptions.participantIds
            )
            if totalShareCount > 0 {
                let perShare = viewModel.basicDetails.amount / Double(totalShareCount)
                Text("Each share = \(perShare.asCurrency)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 4)
            }

            ForEach(participantIds, id: \.self) { personId in
                if let person = resolvePerson(personId) {
                    let detail = calculated[personId] ?? SplitDetail()
                    let shares = viewModel.splitMethod.splitDetails[personId]?.shares ?? 1

                    HStack(spacing: 12) {
                        AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.splitOptions.isCurrentUser(personId) ? "You" : person.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(detail.amount.asCurrency)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .monospacedDigit()
                        }

                        Spacer()

                        // Share stepper
                        HStack(spacing: 10) {
                            Button {
                                HapticManager.shared.light()
                                if shares > 1 {
                                    viewModel.splitMethod.updateSplitShares(for: personId, shares: shares - 1)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(shares <= 1 ? Theme.Colors.textTertiary : Theme.Colors.brandPrimary)
                            }
                            .buttonStyle(.plain)
                            .disabled(shares <= 1)
                            .accessibilityLabel("Decrease shares")

                            Text("\(shares)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.textPrimary)
                                .frame(width: 32)

                            Button {
                                HapticManager.shared.light()
                                viewModel.splitMethod.updateSplitShares(for: personId, shares: shares + 1)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Theme.Colors.brandPrimary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase shares")
                        }
                    }
                    .padding(Theme.Metrics.paddingMedium)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Metrics.cornerRadiusMedium)
                }
            }

            // Total shares
            HStack {
                Text("Total shares")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
                Text("\(totalShareCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }

    // MARK: - Total Bar

    private func totalBar(label: String, value: String, target: String, isBalanced: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isBalanced ? Theme.Colors.success : Theme.Colors.statusError)

                Text("/ \(target)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textTertiary)

                if isBalanced {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.success)
                }
            }
            .monospacedDigit()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isBalanced ? Theme.Colors.success.opacity(0.06) : Theme.Colors.statusError.opacity(0.06))
        )
    }

    // MARK: - Create Transaction Bar

    private var createTransactionBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                HapticManager.shared.medium()
                onSave?()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary))
                            .scaleEffect(0.9)
                    } else {
                        Text("Create Transaction")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundColor(Theme.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Theme.Colors.brandPrimary)
                )
                .opacity(viewModel.canSubmit ? 1.0 : Theme.Opacity.disabled)
            }
            .disabled(!viewModel.canSubmit || viewModel.isLoading)
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 12)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Helpers

    private func resolvePerson(_ id: UUID) -> Person? {
        if id == UserProfileManager.shared.profile.id {
            return UserProfileManager.shared.profile.asPerson
        }
        return dataManager.people.first { $0.id == id }
    }

    private var hasRoundingRemainder: Bool {
        let cents = Int(viewModel.basicDetails.amount * 100)
        let count = viewModel.splitOptions.participantIds.count
        guard count > 0 else { return false }
        return cents % count != 0
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// MARK: - Split Input Row (Reusable for Percentage and Amount)

private struct SplitInputRow: View {
    let person: Person
    let isCurrentUser: Bool
    let primaryValue: String
    let suffix: String
    let secondaryValue: String?
    var prefix: String = ""
    let onValueChanged: (String) -> Void
    var focusedId: FocusState<UUID?>.Binding
    let personId: UUID

    @State private var localText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "You" : person.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                if let secondary = secondaryValue {
                    Text(secondary)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Input field
            HStack(spacing: 4) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                TextField("0", text: $localText)
                    .font(.system(size: 15, weight: .medium))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 64)
                    .focused(focusedId, equals: personId)
                    .onChange(of: localText) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                        if filtered != newValue {
                            localText = filtered
                        }
                        onValueChanged(filtered)
                    }

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(8)
        }
        .padding(Theme.Metrics.paddingMedium)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
        .onAppear {
            localText = primaryValue
        }
        .onChange(of: primaryValue) { _, newValue in
            // Only sync if not currently focused (avoid fighting user input)
            if focusedId.wrappedValue != personId {
                localText = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview("Step 3 - Split Method") {
    Step3SplitMethodView(
        viewModel: {
            let vm = NewTransactionViewModel()
            vm.basicDetails.amountInCents = 12500
            vm.basicDetails.transactionName = "Dinner"
            vm.basicDetails.selectedCategory = .food
            return vm
        }()
    )
    .environmentObject(DataManager.shared)
}
