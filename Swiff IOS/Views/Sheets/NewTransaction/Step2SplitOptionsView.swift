//
//  Step2SplitOptionsView.swift
//  Swiff IOS
//
//  Step 2: People Involved - Who paid and who is included
//  Redesigned to match reference UI exactly
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
                VStack(alignment: .leading, spacing: 24) {
                    // Progress bar
                    progressBar

                    // Who paid section
                    whoPaidSection

                    // Who is included section
                    whoIsIncludedSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .safeAreaInset(edge: .bottom) {
                // Next button
                nextButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(
                        Color(UIColor.systemGroupedBackground)
                            .ignoresSafeArea()
                    )
            }
        }
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("STEP 2 OF 3")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandPrimary)

                Spacer()

                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        viewModel.goToPreviousStep()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            HStack {
                Text("People Involved")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= 2 ? Theme.Colors.brandPrimary : Color(UIColor.systemGray4))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Who Paid Section

    private var whoPaidSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who paid?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField("Search payer...", text: $payerSearchText)
                    .font(.system(size: 17))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            // Payer toggle buttons
            HStack(spacing: 12) {
                // Me (Self) button
                Button(action: {
                    HapticManager.shared.light()
                    selectSelfAsPayer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))

                        Text("Me (Self)")
                            .font(.system(size: 15, weight: .medium))

                        if isSelfPayer {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundColor(isSelfPayer ? .white : Theme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelfPayer ? Theme.Colors.brandPrimary : Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)

                // Someone else button
                Button(action: {
                    HapticManager.shared.light()
                    viewModel.isPaidBySearchFocused = true
                }) {
                    HStack(spacing: 8) {
                        Text("Someone else")
                            .font(.system(size: 15, weight: .medium))

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Who Is Included Section

    private var whoIsIncludedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who is included?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)

                TextField("Find people to split with...", text: $participantSearchText)
                    .font(.system(size: 17))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
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
            HStack(spacing: 12) {
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
                                .strokeBorder(Color(UIColor.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .frame(width: 52, height: 52)

                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(Theme.Colors.textSecondary)
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
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
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
            HStack(spacing: 8) {
                Text("Next: Split Details")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.brandPrimary)
                    .opacity(viewModel.participantIds.count >= 2 ? 1 : 0.5)
            )
        }
        .disabled(viewModel.participantIds.count < 2)
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
                        .background(Circle().fill(Color(UIColor.systemGray)))
                }
                .offset(x: 4, y: -4)
            }

            Text(isSelf ? "Me" : person.name.components(separatedBy: " ").first ?? person.name)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(1)
        }
    }
}

// MARK: - Person List Row

struct PersonListRow: View {
    let person: Person
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(avatarType: person.avatarType, size: .medium, style: .solid)
                .frame(width: 48, height: 48)

            // Name and contact info
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                if !person.email.isEmpty {
                    Text(person.email)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                } else if !person.phone.isEmpty {
                    Text(person.phone)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            // Selection indicator
            ZStack {
                Circle()
                    .strokeBorder(
                        isSelected ? Theme.Colors.brandPrimary : Color(UIColor.systemGray4),
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
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Step 2 - People Involved") {
    Step2SplitOptionsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Color(UIColor.systemGroupedBackground))
}
