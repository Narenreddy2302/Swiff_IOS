//
//  Step2SplitOptionsView.swift
//  Swiff IOS
//
//  Step 2: People Involved - Who paid and who is included
//  Redesigned to match reference UI with proper theme consistency
//

import SwiftUI

struct Step2SplitOptionsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @State private var payerSearchText: String = ""
    @State private var participantSearchText: String = ""

    // Progress bar steps
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator and title section
            stepHeader

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {
                    // Progress bar
                    progressBar

                    // Who paid section
                    whoPaidSection

                    // Who is included section
                    whoIsIncludedSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
            }
            .safeAreaInset(edge: .bottom) {
                // Next button
                nextButton
                    .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
                    .padding(.bottom, Theme.Metrics.paddingMedium + 4)
                    .background(
                        Color.wiseGroupedBackground
                            .ignoresSafeArea()
                    )
            }
        }
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: Theme.Metrics.paddingSmall + 4) {
            HStack {
                Text("STEP 2 OF 3")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseForestGreen)

                Spacer()

                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        viewModel.goToPreviousStep()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            HStack {
                Text("People Involved")
                    .font(.spotifyDisplayMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
        .padding(.top, Theme.Metrics.paddingMedium)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= 2 ? Color.wiseForestGreen : Color.wiseBorder)
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Who Paid Section

    private var whoPaidSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall + 4) {
            Text("Who paid?")
                .font(.spotifyHeadingSmall)
                .foregroundColor(.wisePrimaryText)

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseSecondaryText)

                TextField("Search payer...", text: $payerSearchText)
                    .font(.spotifyBodyLarge)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium - 2)
            .padding(.vertical, Theme.Metrics.paddingSmall + 4)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Color.wiseCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )

            // Payer toggle buttons
            HStack(spacing: Theme.Metrics.paddingSmall + 4) {
                // Me (Self) button
                Button(action: {
                    HapticManager.shared.light()
                    selectSelfAsPayer()
                }) {
                    HStack(spacing: Theme.Metrics.paddingSmall) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))

                        Text("Me (Self)")
                            .font(.spotifyLabelLarge)

                        if isSelfPayer {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundColor(isSelfPayer ? .white : .wisePrimaryText)
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.vertical, Theme.Metrics.paddingSmall + 4)
                    .background(
                        Capsule()
                            .fill(isSelfPayer ? Color.wiseForestGreen : Color.wiseCardBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelfPayer ? Color.clear : Color.wiseBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Someone else button
                Button(action: {
                    HapticManager.shared.light()
                    viewModel.isPaidBySearchFocused = true
                }) {
                    HStack(spacing: Theme.Metrics.paddingSmall) {
                        Text("Someone else")
                            .font(.spotifyLabelLarge)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.vertical, Theme.Metrics.paddingSmall + 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Who Is Included Section

    private var whoIsIncludedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall + 4) {
            Text("Who is included?")
                .font(.spotifyHeadingSmall)
                .foregroundColor(.wisePrimaryText)

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseSecondaryText)

                TextField("Find people to split with...", text: $participantSearchText)
                    .font(.spotifyBodyLarge)
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium - 2)
            .padding(.vertical, Theme.Metrics.paddingSmall + 4)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .fill(Color.wiseCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )

            // Selected participants horizontal scroll
            selectedParticipantsRow

            // People list
            peopleList
        }
    }

    // MARK: - Selected Participants Row

    private var selectedParticipantsRow: some View {
        let selectedPeople = dataManager.people.filter { viewModel.participantIds.contains($0.id) }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Metrics.paddingSmall + 4) {
                ForEach(selectedPeople) { person in
                    SelectedPersonBubble(
                        person: person,
                        isSelf: isPersonSelf(person),
                        onRemove: {
                            HapticManager.shared.light()
                            withAnimation(.smooth) {
                                viewModel.toggleParticipant(person.id)
                            }
                        }
                    )
                }

                // Add person placeholder
                Button(action: {
                    HapticManager.shared.light()
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.wiseBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .frame(width: 52, height: 52)

                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - People List

    private var peopleList: some View {
        let filteredPeople = participantSearchText.isEmpty
            ? dataManager.people
            : dataManager.people.filter { $0.name.localizedCaseInsensitiveContains(participantSearchText) }

        return VStack(spacing: 0) {
            ForEach(filteredPeople) { person in
                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        viewModel.toggleParticipant(person.id)
                        // Also set as payer if first selection
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
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                .fill(Color.wiseCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
        .cardShadow()
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            HapticManager.shared.light()
            if viewModel.participantIds.count >= 2 {
                viewModel.isSplit = true
                viewModel.initializeSplitDefaults()
                withAnimation(.smooth) {
                    viewModel.goToNextStep()
                }
            }
        } label: {
            HStack(spacing: Theme.Metrics.paddingSmall) {
                Text("Next: Split Details")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .fill(Color.wiseForestGreen)
                    .opacity(viewModel.participantIds.count >= 2 ? 1 : 0.5)
            )
        }
        .disabled(viewModel.participantIds.count < 2)
        .cardShadow()
    }

    // MARK: - Helper Properties

    private var isSelfPayer: Bool {
        guard let payerId = viewModel.paidByUserId,
              let payer = dataManager.people.first(where: { $0.id == payerId }) else {
            return true // Default to self
        }
        // Check if payer is the first person (typically "self")
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

// MARK: - Selected Person Bubble

struct SelectedPersonBubble: View {
    let person: Person
    let isSelf: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                    .frame(width: 52, height: 52)

                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.wiseGray))
                }
                .offset(x: 4, y: -4)
            }

            Text(isSelf ? "Me" : person.name.components(separatedBy: " ").first ?? person.name)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)
        }
    }
}

// MARK: - Person List Row

struct PersonListRow: View {
    let person: Person
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.Metrics.paddingMedium - 2) {
            // Avatar
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: Theme.Metrics.avatarMedium, height: Theme.Metrics.avatarMedium)

            // Name and contact info
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.wisePrimaryText)

                if !person.email.isEmpty {
                    Text(person.email)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                } else if !person.phone.isEmpty {
                    Text(person.phone)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            Spacer()

            // Selection indicator
            ZStack {
                Circle()
                    .strokeBorder(
                        isSelected ? Color.wiseForestGreen : Color.wiseBorder,
                        lineWidth: isSelected ? 0 : 2
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color.wiseForestGreen : Color.clear)
                    )
                    .frame(width: 26, height: 26)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingMedium - 2)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Step 2 - People Involved") {
    Step2SplitOptionsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Color.wiseGroupedBackground)
}
