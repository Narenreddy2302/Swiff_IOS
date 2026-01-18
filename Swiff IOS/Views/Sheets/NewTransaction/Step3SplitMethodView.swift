//
//  Step3SplitMethodView.swift
//  Swiff IOS
//
//  Step 3: Split method selection and per-person configuration (compact layout)
//

import SwiftUI

struct Step3SplitMethodView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedParticipant: UUID?
    @State private var keyboardHeight: CGFloat = 0

    // Navigation callbacks
    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    // MARK: - Layout Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
        static let topPadding: CGFloat = 12
        static let cardCornerRadius: CGFloat = 12
        static let rowHorizontalPadding: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 10
        static let avatarSize: CGFloat = 36
        static let inputFieldWidth: CGFloat = 55
        static let percentageFieldWidth: CGFloat = 45
        static let adjustmentFieldWidth: CGFloat = 50
        static let shareButtonSize: CGFloat = 24
        static let shareDisplayWidth: CGFloat = 30
        static let minShareValue: Int = 1
        static let maxShareValue: Int = 10
        static let dividerLeadingPadding: CGFloat = 52
        static let keyboardBottomPadding: CGFloat = 60
        static let totalFontSize: CGFloat = 28
        static let payerBadgeFontSize: CGFloat = 9
        static let badgeHorizontalPadding: CGFloat = 5
        static let badgeVerticalPadding: CGFloat = 2
        static let badgeCornerRadius: CGFloat = 4
        static let inputPadding: CGFloat = 6
        static let inputVerticalPadding: CGFloat = 5
        static let inputCornerRadius: CGFloat = 6
        static let buttonIconSize: CGFloat = 10
        static let arrowIconSize: CGFloat = 10
        static let bannerVerticalPadding: CGFloat = 8
    }

    var body: some View {
        VStack(spacing: Theme.Metrics.paddingLarge) {
            // Summary Header (compact)
            summaryHeader
                .id("summaryHeader")

            // Split Method Selector
            SplitMethodSelector(
                selectedType: $viewModel.splitMethod,
                onSelect: {
                    viewModel.onSplitMethodChanged()
                }
            )

            // Participants Configuration
            participantsConfiguration
                .id("participantsConfig")

            // Owes Summary
            owesSummary

            // Navigation Buttons
            navigationButtons

            // Bottom padding for keyboard
            Spacer(minLength: keyboardHeight > 0 ? keyboardHeight : 60)
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.top, Theme.Metrics.paddingMedium)
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { notification in
            if let keyboardFrame = notification.userInfo?[
                UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            {
                withAnimation(.smooth) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            withAnimation(.smooth) {
                keyboardHeight = 0
            }
        }
    }

    // MARK: - Summary Header (Compact)

    private var summaryHeader: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(viewModel.amount.asCurrency)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Spacer()

            Text(methodDescription)
                .font(Theme.Fonts.captionMedium)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(Theme.Metrics.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.sheetPillBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Total amount \(viewModel.amount.asCurrency), \(methodDescription.replacingOccurrences(of: "\n", with: " "))"
        )
    }

    private var methodDescription: String {
        let count = viewModel.participantIds.count
        switch viewModel.splitMethod {
        case .equally:
            return "Split equally\namong \(count) people"
        case .exactAmounts:
            return "Exact amounts\nper person"
        case .percentages:
            return "Percentage\nallocation"
        case .shares:
            return "Share-based\ndistribution"
        case .adjustments:
            return "Equal base\nwith adjustments"
        }
    }

    // MARK: - Participants Configuration

    /// Sorted participant IDs for stable view ordering
    private var sortedParticipantIds: [UUID] {
        viewModel.participantIds.sorted()
    }

    private var participantsConfiguration: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Split breakdown")
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.textSecondary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Use sorted array for stable ForEach ordering
                ForEach(sortedParticipantIds, id: \.self) { participantId in
                    if let person = dataManager.people.first(where: { $0.id == participantId }) {
                        participantSplitRow(person: person)
                            .id(participantId)

                        if participantId != sortedParticipantIds.last {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.sheetCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Participant Split Row (Compact)

    private func participantSplitRow(person: Person) -> some View {
        let calculated = viewModel.calculatedSplits[person.id] ?? SplitDetail()
        let isPayer = viewModel.paidByUserId == person.id

        return HStack(spacing: Theme.Metrics.paddingSmall) {
            // Avatar
            AvatarView(avatarType: person.avatarType, size: .small, style: .solid)
                .frame(width: 36, height: 36)

            // Name and info
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(person.name)
                        .font(Theme.Fonts.bodyLarge)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    if isPayer {
                        Text("Paid")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.Colors.sheetGreenPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.sheetGreenPrimary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Text(String(format: "%.1f%%", calculated.percentage))
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            // Amount / Input
            VStack(alignment: .trailing, spacing: 2) {
                Text(calculated.amount.asCurrency)
                    .font(Theme.Fonts.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)

                inputControl(for: person)
            }
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(person.name)\(isPayer ? ", paid the bill" : ""), owes \(calculated.amount.asCurrency), \(String(format: "%.1f", calculated.percentage)) percent"
        )
        .accessibilityHint(
            viewModel.splitMethod == .equally ? "Split equally" : "Double tap to adjust amount")
    }

    @ViewBuilder
    private func inputControl(for person: Person) -> some View {
        switch viewModel.splitMethod {
        case .equally:
            EmptyView()

        case .exactAmounts:
            HStack(spacing: 4) {
                Text(viewModel.selectedCurrency.symbol)
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField(
                    "0.00",
                    value: Binding(
                        get: { viewModel.splitDetails[person.id]?.amount ?? 0 },
                        set: { viewModel.updateSplitAmount(for: person.id, amount: $0) }
                    ), format: .number
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.Fonts.captionMedium)
                .frame(width: 55)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(Theme.Colors.border.opacity(0.5))
                .cornerRadius(6)
                .focused($focusedParticipant, equals: person.id)
                .accessibilityLabel("Exact amount for \(person.name)")
                .accessibilityValue("\(viewModel.splitDetails[person.id]?.amount ?? 0)")
            }

        case .percentages:
            HStack(spacing: 4) {
                TextField(
                    "0",
                    value: Binding(
                        get: { viewModel.splitDetails[person.id]?.percentage ?? 0 },
                        set: { viewModel.updateSplitPercentage(for: person.id, percentage: $0) }
                    ), format: .number
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.Fonts.captionMedium)
                .frame(width: 45)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(Theme.Colors.border.opacity(0.5))
                .cornerRadius(6)
                .focused($focusedParticipant, equals: person.id)
                .accessibilityLabel("Percentage for \(person.name)")
                .accessibilityValue("\(viewModel.splitDetails[person.id]?.percentage ?? 0) percent")

                Text("%")
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

        case .shares:
            HStack(spacing: 6) {
                Button(action: {
                    HapticManager.shared.light()
                    let current = viewModel.splitDetails[person.id]?.shares ?? 1
                    if current > 1 {
                        viewModel.updateSplitShares(for: person.id, shares: current - 1)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(Theme.Colors.border.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Decrease shares for \(person.name)")

                Text("\(viewModel.splitDetails[person.id]?.shares ?? 1)x")
                    .font(Theme.Fonts.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(width: 30)
                    .accessibilityLabel("\(viewModel.splitDetails[person.id]?.shares ?? 1) shares")

                Button(action: {
                    HapticManager.shared.light()
                    let current = viewModel.splitDetails[person.id]?.shares ?? 1
                    if current < 10 {
                        viewModel.updateSplitShares(for: person.id, shares: current + 1)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(Theme.Colors.border.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Increase shares for \(person.name)")
            }

        case .adjustments:
            HStack(spacing: 4) {
                Text("+/-")
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField(
                    "0",
                    value: Binding(
                        get: { viewModel.splitDetails[person.id]?.adjustment ?? 0 },
                        set: { viewModel.updateSplitAdjustment(for: person.id, adjustment: $0) }
                    ), format: .number
                )
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .font(Theme.Fonts.captionMedium)
                .frame(width: 50)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(Theme.Colors.border.opacity(0.5))
                .cornerRadius(6)
                .focused($focusedParticipant, equals: person.id)
                .accessibilityLabel("Adjustment for \(person.name)")
                .accessibilityValue("\(viewModel.splitDetails[person.id]?.adjustment ?? 0)")
            }
        }
    }

    // MARK: - Owes Summary (Reference Style with Blue Background)

    /// Sorted non-payer participants for stable view ordering
    private var sortedNonPayerParticipants: [UUID] {
        sortedParticipantIds.filter { $0 != viewModel.paidByUserId }
    }

    private var owesSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !sortedNonPayerParticipants.isEmpty {
                VStack(spacing: 0) {
                    // Use sorted array for stable ForEach ordering
                    ForEach(sortedNonPayerParticipants, id: \.self) { participantId in
                        if let person = dataManager.people.first(where: { $0.id == participantId }),
                            let payerId = viewModel.paidByUserId,
                            let payer = dataManager.people.first(where: { $0.id == payerId })
                        {
                            let calculated =
                                viewModel.calculatedSplits[participantId] ?? SplitDetail()

                            // Get first name for compact display
                            let personFirstName =
                                person.name.components(separatedBy: " ").first ?? person.name
                            let payerFirstName =
                                payer.name.components(separatedBy: " ").first ?? payer.name

                            HStack {
                                Text("\(personFirstName) owes \(payerFirstName)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(calculated.amount.asCurrency)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Theme.Colors.brandPrimary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                "\(person.name) owes \(payer.name) \(calculated.amount.asCurrency)")
                        }
                    }
                }
                .background(Theme.Colors.brandPrimary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                HapticManager.shared.light()
                onBack?()
            } label: {
                Text("Back")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.buttonSecondary)
                    )
            }

            // Save button
            Button {
                HapticManager.shared.light()
                onSave?()
            } label: {
                Text("Save")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.brandPrimary)
                            .opacity(viewModel.canSubmit ? 1 : 0.5)
                    )
            }
            .disabled(!viewModel.canSubmit)
        }
    }

}

// MARK: - Preview

#Preview("Step 3 - Split Method") {
    Step3SplitMethodView(
        viewModel: {
            let vm = NewTransactionViewModel()
            vm.isSplit = true
            vm.amountString = "120"
            return vm
        }()
    )
    .environmentObject(DataManager.shared)
    .background(Theme.Colors.sheetCardBackground)
}
