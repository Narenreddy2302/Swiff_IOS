//
//  Step2SplitOptionsView.swift
//  Swiff IOS
//
//  Step 2: People Involved - Who paid and who is included
//  Production-ready with design system compliance and accessibility
//

import SwiftUI

// MARK: - Step2SplitOptionsView

struct Step2SplitOptionsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager

    @State private var payerSearchText: String = ""
    @State private var participantSearchText: String = ""

    // MARK: - Constants

    private let totalSteps = 3

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            stepHeader
            scrollContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 2: People involved in transaction")
    }

    // MARK: - Subviews

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {
                progressBar
                whoPaidSection
                whoIsIncludedSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
        .safeAreaInset(edge: .bottom) {
            nextButton
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.bottom, Theme.Metrics.paddingMedium)
                .background(
                    Theme.Colors.secondaryBackground
                        .ignoresSafeArea()
                )
        }
    }

    private var stepHeader: some View {
        VStack(spacing: Theme.Metrics.paddingSmall) {
            HStack {
                Text("STEP 2 OF 3")
                    .font(Theme.Fonts.labelMedium)
                    .foregroundColor(Theme.Colors.brandPrimary)

                Spacer()

                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.smooth) {
                        viewModel.goToPreviousStep()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .accessibilityLabel("Go back")
            }

            HStack {
                Text("People Involved")
                    .font(Theme.Fonts.displayMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()
            }
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.top, Theme.Metrics.paddingMedium)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= 2 ? Theme.Colors.brandPrimary : Theme.Colors.border)
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("Step 2 of \(totalSteps) completed")
    }

    private var whoPaidSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Who paid?")
                .font(Theme.Fonts.headerSmall)
                .foregroundColor(Theme.Colors.textPrimary)

            searchField(
                placeholder: "Search payer...",
                text: $payerSearchText
            )
            .accessibilityLabel("Search for payer")

            payerToggleButtons
        }
    }

    private var payerToggleButtons: some View {
        HStack(spacing: Theme.Metrics.paddingSmall) {
            // Me (Self) button
            Button(action: {
                HapticManager.shared.selection()
                selectSelfAsPayer()
            }) {
                HStack(spacing: Theme.Metrics.paddingSmall) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))

                    Text("Me (Self)")
                        .font(Theme.Fonts.labelLarge)

                    if isSelfPayer {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(isSelfPayer ? Theme.Colors.textOnPrimary : Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingSmall)
                .background(
                    Capsule()
                        .fill(isSelfPayer ? Theme.Colors.brandPrimary : Theme.Colors.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelfPayer ? Color.clear : Theme.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Me as payer")
            .accessibilityAddTraits(isSelfPayer ? .isSelected : [])

            // Someone else button
            Button(action: {
                HapticManager.shared.selection()
                viewModel.isPaidBySearchFocused = true
            }) {
                HStack(spacing: Theme.Metrics.paddingSmall) {
                    Text("Someone else")
                        .font(Theme.Fonts.labelLarge)

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingSmall)
                .background(
                    Capsule()
                        .fill(Theme.Colors.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select someone else as payer")

            Spacer()
        }
    }

    private var whoIsIncludedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Who is included?")
                .font(Theme.Fonts.headerSmall)
                .foregroundColor(Theme.Colors.textPrimary)

            searchField(
                placeholder: "Find people to split with...",
                text: $participantSearchText
            )
            .accessibilityLabel("Search for participants")

            selectedParticipantsRow
            peopleList
        }
    }

    private var selectedParticipantsRow: some View {
        let selectedPeople = dataManager.people.filter { viewModel.participantIds.contains($0.id) }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                ForEach(selectedPeople) { person in
                    SelectedPersonBubble(
                        person: person,
                        isSelf: isPersonSelf(person),
                        onRemove: {
                            HapticManager.shared.selection()
                            withAnimation(.smooth) {
                                viewModel.toggleParticipant(person.id)
                            }
                        }
                    )
                }

                addPersonPlaceholder
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selected participants: \(selectedPeople.count)")
    }

    private var addPersonPlaceholder: some View {
        Button(action: {
            HapticManager.shared.selection()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .strokeBorder(Theme.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add person")
    }

    private var peopleList: some View {
        let filteredPeople = participantSearchText.isEmpty
            ? dataManager.people
            : dataManager.people.filter { $0.name.localizedCaseInsensitiveContains(participantSearchText) }

        return VStack(spacing: 0) {
            ForEach(filteredPeople) { person in
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.smooth) {
                        viewModel.toggleParticipant(person.id)
                        if viewModel.paidByUserId == nil {
                            viewModel.selectPayer(person.id)
                        }
                    }
                }) {
                    PersonListRow(
                        person: person,
                        isSelected: viewModel.participantIds.contains(person.id)
                    )
                }
                .buttonStyle(.plain)

                if person.id != filteredPeople.last?.id {
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    private var nextButton: some View {
        let canProceed = viewModel.participantIds.count >= 2

        return Button {
            handleNextStep()
        } label: {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Text("Next: Split Details")
                    .font(Theme.Fonts.bodyLarge)
                    .fontWeight(.semibold)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Theme.Colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: SwiffButtonSize.large.height)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Theme.Colors.brandPrimary)
                    .opacity(canProceed ? 1 : 0.5)
            )
        }
        .disabled(!canProceed)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Next: Split details")
        .accessibilityHint(canProceed ? "Continue to split configuration" : "Select at least 2 participants first")
    }

    // MARK: - Helper Views

    private func searchField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Theme.Metrics.iconSizeSmall))
                .foregroundColor(Theme.Colors.textSecondary)

            TextField(placeholder, text: text)
                .font(Theme.Fonts.bodyLarge)
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingSmall)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Private Methods

    private func handleNextStep() {
        HapticManager.shared.selection()
        if viewModel.participantIds.count >= 2 {
            viewModel.isSplit = true
            viewModel.initializeSplitDefaults()
            withAnimation(.smooth) {
                viewModel.goToNextStep()
            }
        }
    }

    private var isSelfPayer: Bool {
        guard let payerId = viewModel.paidByUserId,
              let payer = dataManager.people.first(where: { $0.id == payerId }) else {
            return true
        }
        return payer.id == dataManager.people.first?.id
    }

    private func selectSelfAsPayer() {
        if let firstPerson = dataManager.people.first {
            viewModel.selectPayer(firstPerson.id)
        }
    }

    private func isPersonSelf(_ person: Person) -> Bool {
        return person.id == dataManager.people.first?.id
    }
}

// MARK: - SelectedPersonBubble

struct SelectedPersonBubble: View {

    // MARK: - Properties

    let person: Person
    let isSelf: Bool
    let onRemove: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                    .frame(width: 52, height: 52)

                removeButton
            }

            Text(displayName)
                .font(Theme.Fonts.labelSmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), selected")
        .accessibilityHint("Double tap to remove")
    }

    // MARK: - Subviews

    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.Colors.textOnPrimary)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Theme.Colors.textTertiary))
        }
        .offset(x: 4, y: -4)
        .accessibilityLabel("Remove \(displayName)")
    }

    // MARK: - Computed Properties

    private var displayName: String {
        isSelf ? "Me" : person.name.components(separatedBy: " ").first ?? person.name
    }
}

// MARK: - PersonListRow

struct PersonListRow: View {

    // MARK: - Properties

    let person: Person
    let isSelected: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: Theme.Metrics.avatarMedium, height: Theme.Metrics.avatarMedium)

            personInfo

            Spacer()

            selectionIndicator
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingMedium)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Subviews

    private var personInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(person.name)
                .font(Theme.Fonts.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textPrimary)

            if !person.email.isEmpty {
                Text(person.email)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
            } else if !person.phone.isEmpty {
                Text(person.phone)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? Theme.Colors.brandPrimary : Theme.Colors.border,
                    lineWidth: isSelected ? 0 : 2
                )
                .background(
                    Circle()
                        .fill(isSelected ? Theme.Colors.brandPrimary : Color.clear)
                )
                .frame(width: 26, height: 26)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.textOnPrimary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Step 2 - People Involved") {
    Step2SplitOptionsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Theme.Colors.secondaryBackground)
}
