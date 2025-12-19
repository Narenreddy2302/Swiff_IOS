//
//  Step5ConfigureView.swift
//  Swiff IOS
//
//  Step 5: Configure split amounts based on selected type
//

import SwiftUI

struct Step5ConfigureView: View {
    let splitType: SplitType
    let totalAmount: Double
    let participantIds: [UUID]

    @Binding var participantAmounts: [UUID: Double]
    @Binding var participantPercentages: [UUID: Double]
    @Binding var participantShares: [UUID: Int]

    @EnvironmentObject var dataManager: DataManager
    @State private var validationError: String?

    var participants: [Person] {
        participantIds.compactMap { id in
            dataManager.people.first { $0.id == id }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Configure Split")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Text(splitType.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 20)

                // Dynamic content based on split type
                switch splitType {
                case .equally:
                    equalSplitView
                case .exactAmounts:
                    exactAmountsView
                case .percentages:
                    percentagesView
                case .shares:
                    sharesView
                case .adjustments:
                    adjustmentsView
                }

                // Validation error
                if let error = validationError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.wiseError)
                        Text(error)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseError)
                    }
                    .padding(12)
                    .background(Color.wiseError.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.wiseBackground)
        .onAppear {
            initializeDefaults()
        }
    }

    // MARK: - Equal Split View

    private var equalSplitView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(participants) { person in
                HStack {
                    AvatarView(
                        avatarType: person.avatarType,
                        size: .medium,
                        style: .solid
                    )
                    .frame(width: 40, height: 40)

                    Text(person.name)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    Text(String(format: "$%.2f", SplitCalculationService.equalAmountPerPerson(totalAmount: totalAmount, participantCount: participantIds.count)))
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseBrightGreen)
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }

            // Summary card
            summaryCard(
                label: "Per Person",
                value: String(format: "$%.2f", SplitCalculationService.equalAmountPerPerson(totalAmount: totalAmount, participantCount: participantIds.count)),
                isValid: true
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Exact Amounts View

    private var exactAmountsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(participants) { person in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AvatarView(
                            avatarType: person.avatarType,
                            size: .medium,
                            style: .solid
                        )
                        .frame(width: 40, height: 40)

                        Text(person.name)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }

                    amountInputField(for: person.id, binding: $participantAmounts)
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }

            // Total validation
            let total = SplitCalculationService.roundToCents(participantAmounts.values.reduce(0, +))
            let isValid = SplitCalculationService.amountsEqual(total, totalAmount)
            let remaining = SplitCalculationService.roundToCents(totalAmount - total)

            summaryCard(
                label: "Total",
                value: String(format: "$%.2f / $%.2f", total, totalAmount),
                isValid: isValid
            )

            if !isValid {
                remainingIndicator(amount: remaining)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Percentages View

    private var percentagesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(participants) { person in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AvatarView(
                            avatarType: person.avatarType,
                            size: .medium,
                            style: .solid
                        )
                        .frame(width: 40, height: 40)

                        Text(person.name)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        let percentage = participantPercentages[person.id] ?? 0
                        Text(String(format: "$%.2f", SplitCalculationService.roundToCents(totalAmount * (percentage / 100))))
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseBrightGreen)
                    }

                    percentageInputField(for: person.id)
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }

            // Total validation
            let total = participantPercentages.values.reduce(0, +)
            let isValid = abs(total - 100) < SplitCalculationService.toleranceCents

            summaryCard(
                label: "Total",
                value: String(format: "%.1f%% / 100%%", total),
                isValid: isValid
            )

            if !isValid {
                let remaining = 100.0 - total
                HStack(spacing: 6) {
                    Image(systemName: remaining > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 12))
                    Text(remaining > 0 ? "\(String(format: "%.1f", remaining))% remaining" : "\(String(format: "%.1f", abs(remaining)))% over")
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(remaining > 0 ? .wiseWarning : .wiseError)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Shares View

    private var sharesView: some View {
        let totalShares = participantShares.values.reduce(0, +)
        let amountPerShare = totalShares > 0 ? SplitCalculationService.amountPerShare(totalAmount: totalAmount, totalShares: totalShares) : 0

        return VStack(alignment: .leading, spacing: 12) {
            // Info card about shares
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseInfo)
                Text("Each share is worth \(String(format: "$%.2f", amountPerShare))")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(12)
            .background(Color.wiseInfo.opacity(0.1))
            .cornerRadius(8)

            ForEach(participants) { person in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AvatarView(
                            avatarType: person.avatarType,
                            size: .medium,
                            style: .solid
                        )
                        .frame(width: 40, height: 40)

                        Text(person.name)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        let shares = participantShares[person.id] ?? 1
                        let amount = totalShares > 0 ? SplitCalculationService.roundToCents(totalAmount * Double(shares) / Double(totalShares)) : 0
                        Text(String(format: "$%.2f", amount))
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseBrightGreen)
                    }

                    HStack {
                        Stepper(
                            value: Binding(
                                get: { participantShares[person.id] ?? 1 },
                                set: { newValue in
                                    participantShares[person.id] = max(1, newValue)
                                    HapticManager.shared.light()
                                }
                            ),
                            in: 1...10
                        ) {
                            let shares = participantShares[person.id] ?? 1
                            Text("\(shares) \(shares == 1 ? "share" : "shares")")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.wiseBorder.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }

            // Total shares summary
            summaryCard(
                label: "Total Shares",
                value: "\(totalShares) shares",
                isValid: totalShares > 0
            )

            // Ratio display
            if participants.count > 1 {
                let ratioString = participants.compactMap { person in
                    guard let shares = participantShares[person.id] else { return nil }
                    return "\(shares)"
                }.joined(separator: " : ")

                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 12))
                    Text("Split ratio: \(ratioString)")
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(.wiseSecondaryText)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Adjustments View

    private var adjustmentsView: some View {
        let equalAmount = SplitCalculationService.equalAmountPerPerson(totalAmount: totalAmount, participantCount: participantIds.count)

        return VStack(alignment: .leading, spacing: 12) {
            // Info card
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseInfo)
                Text("Equal split is \(String(format: "$%.2f", equalAmount)) per person. Adjust as needed.")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(12)
            .background(Color.wiseInfo.opacity(0.1))
            .cornerRadius(8)

            ForEach(participants) { person in
                let currentAmount = participantAmounts[person.id] ?? equalAmount
                let difference = currentAmount - equalAmount
                let hasAdjustment = abs(difference) > SplitCalculationService.toleranceCents

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AvatarView(
                            avatarType: person.avatarType,
                            size: .medium,
                            style: .solid
                        )
                        .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            if hasAdjustment {
                                Text(difference > 0 ? "+\(String(format: "$%.2f", difference))" : "\(String(format: "$%.2f", difference))")
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(difference > 0 ? .wiseError : .wiseSuccess)
                            }
                        }

                        Spacer()

                        // Reset button if adjusted
                        if hasAdjustment {
                            Button(action: {
                                HapticManager.shared.light()
                                participantAmounts[person.id] = equalAmount
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.wiseSecondaryText)
                                    .padding(6)
                                    .background(Color.wiseBorder.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }

                    amountInputField(for: person.id, binding: $participantAmounts)
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }

            // Total validation
            let total = SplitCalculationService.roundToCents(participantAmounts.values.reduce(0, +))
            let isValid = SplitCalculationService.amountsEqual(total, totalAmount)
            let remaining = SplitCalculationService.roundToCents(totalAmount - total)

            summaryCard(
                label: "Total",
                value: String(format: "$%.2f / $%.2f", total, totalAmount),
                isValid: isValid
            )

            if !isValid {
                remainingIndicator(amount: remaining)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Methods

    private func initializeDefaults() {
        let equalAmount = SplitCalculationService.equalAmountPerPerson(totalAmount: totalAmount, participantCount: participantIds.count)

        switch splitType {
        case .equally:
            // No configuration needed
            break

        case .exactAmounts, .adjustments:
            if participantAmounts.isEmpty || !participantAmounts.keys.contains(where: { participantIds.contains($0) }) {
                for id in participantIds {
                    participantAmounts[id] = equalAmount
                }
            }

        case .percentages:
            if participantPercentages.isEmpty || !participantPercentages.keys.contains(where: { participantIds.contains($0) }) {
                let equalPercentage = SplitCalculationService.roundToCents(100.0 / Double(participantIds.count))
                for id in participantIds {
                    participantPercentages[id] = equalPercentage
                }
            }

        case .shares:
            if participantShares.isEmpty || !participantShares.keys.contains(where: { participantIds.contains($0) }) {
                for id in participantIds {
                    participantShares[id] = 1
                }
            }
        }
    }

    // MARK: - Reusable Components

    /// Summary card showing totals with validation color
    private func summaryCard(label: String, value: String, isValid: Bool) -> some View {
        HStack {
            Text("\(label):")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
            Spacer()
            Text(value)
                .font(.spotifyBodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(isValid ? .wiseSuccess : .wiseWarning)
        }
        .padding(16)
        .background(isValid ? Color.wiseSuccess.opacity(0.1) : Color.wiseWarning.opacity(0.1))
        .cornerRadius(8)
    }

    /// Remaining amount indicator
    private func remainingIndicator(amount: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: amount > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 12))
            Text(amount > 0 ? "\(String(format: "$%.2f", amount)) remaining" : "\(String(format: "$%.2f", abs(amount))) over")
                .font(.spotifyCaptionMedium)
        }
        .foregroundColor(amount > 0 ? .wiseWarning : .wiseError)
        .padding(.top, 4)
    }

    /// Amount input field with consistent styling
    private func amountInputField(for personId: UUID, binding: Binding<[UUID: Double]>) -> some View {
        HStack {
            Text("$")
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)

            TextField("0.00", value: Binding(
                get: { binding.wrappedValue[personId] ?? 0 },
                set: { newValue in
                    binding.wrappedValue[personId] = SplitCalculationService.roundToCents(newValue)
                }
            ), format: .number.precision(.fractionLength(2)))
                .keyboardType(.decimalPad)
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.wiseBorder.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                )
        )
    }

    /// Percentage input field with consistent styling
    private func percentageInputField(for personId: UUID) -> some View {
        HStack {
            TextField("0", value: Binding(
                get: { participantPercentages[personId] ?? 0 },
                set: { newValue in
                    participantPercentages[personId] = min(100, max(0, newValue))
                }
            ), format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)

            Text("%")
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.wiseBorder.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Step 5 Configure") {
    let dataManager = DataManager.shared
    let person1 = Person(name: "Alice", email: "alice@example.com", phone: "+1234567890", avatar: "👩‍💼")
    let person2 = Person(name: "Bob", email: "bob@example.com", phone: "+1234567891", avatar: "👨‍💻")
    dataManager.people = [person1, person2]

    return Step5ConfigureView(
        splitType: .percentages,
        totalAmount: 100.0,
        participantIds: [person1.id, person2.id],
        participantAmounts: .constant([:]),
        participantPercentages: .constant([:]),
        participantShares: .constant([:])
    )
    .environmentObject(dataManager)
}
