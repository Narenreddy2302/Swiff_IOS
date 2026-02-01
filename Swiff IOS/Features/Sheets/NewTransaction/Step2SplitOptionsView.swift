//
//  Step2SplitOptionsView.swift
//  Swiff IOS
//
//  Step 2: People — Who paid (single select) and who's included (multi select)
//  Features search bars, avatar pills for selected members, and validation
//

import SwiftUI

// MARK: - Step2SplitOptionsView

struct Step2SplitOptionsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager

    @State private var payerSearchText: String = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {
                    // Who Paid Section
                    whoPaidSection

                    // Divider
                    Divider()
                        .padding(.horizontal, Theme.Metrics.paddingMedium)

                    // Split Between Section
                    splitBetweenSection

                    Spacer(minLength: 100)
                }
                .padding(.top, Theme.Metrics.paddingSmall)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.Colors.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step 2: Select people for this transaction")
    }

    // MARK: - Who Paid Section

    private var whoPaidSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("WHO PAID?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Metrics.paddingMedium)

            // Search bar
            searchBar(
                placeholder: "Search people\u{2026}",
                text: $payerSearchText
            )
            .padding(.horizontal, Theme.Metrics.paddingMedium)

            // Payer list
            VStack(spacing: 0) {
                // Current user always at top
                let profile = UserProfileManager.shared.profile
                if payerMatchesSearch(profile.name) {
                    PayerRow(
                        name: profile.name,
                        subtitle: "(You)",
                        avatarType: profile.avatarType,
                        isSelected: viewModel.splitOptions.paidByUserId == profile.id,
                        action: {
                            HapticManager.shared.selection()
                            viewModel.splitOptions.selectPayer(profile.id)
                            if !viewModel.splitOptions.participantIds.contains(profile.id) {
                                viewModel.splitOptions.addParticipant(profile.id)
                            }
                        }
                    )

                    if !filteredPayers.isEmpty {
                        Divider().padding(.leading, 68)
                    }
                }

                ForEach(filteredPayers) { person in
                    if person.id != UserProfileManager.shared.profile.id {
                        PayerRow(
                            name: person.name,
                            subtitle: person.phone.isEmpty ? nil : person.phone,
                            avatarType: person.avatarType,
                            isSelected: viewModel.splitOptions.paidByUserId == person.id,
                            action: {
                                HapticManager.shared.selection()
                                viewModel.splitOptions.selectPayer(person.id)
                                if !viewModel.splitOptions.participantIds.contains(person.id) {
                                    viewModel.splitOptions.addParticipant(person.id)
                                }
                            }
                        )

                        if person.id != filteredPayers.last?.id {
                            Divider().padding(.leading, 68)
                        }
                    }
                }

                if filteredPayers.isEmpty && !payerMatchesSearch(UserProfileManager.shared.profile.name) {
                    emptySearchState
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Metrics.cornerRadiusMedium)
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
    }

    // MARK: - Split Between Section

    private var splitBetweenSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            HStack {
                Text("SPLIT BETWEEN")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                if viewModel.splitOptions.participantCount > 0 {
                    Text("\(viewModel.splitOptions.participantCount) selected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)

            // Selected avatar pills
            if !viewModel.splitOptions.participantIds.isEmpty {
                selectedAvatarPills
            }

            // Validation message
            if let message = viewModel.splitOptions.validationMessage {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text(message)
                        .font(.system(size: 13))
                }
                .foregroundColor(Theme.Colors.warning)
                .padding(.horizontal, Theme.Metrics.paddingMedium)
            }

            // Search bar
            searchBar(
                placeholder: "Search people\u{2026}",
                text: $viewModel.splitOptions.splitWithSearchText
            )
            .padding(.horizontal, Theme.Metrics.paddingMedium)

            // People list
            VStack(spacing: 0) {
                // Current user at top
                let profile = UserProfileManager.shared.profile
                if matchesSplitSearch(profile.name) {
                    MemberRow(
                        name: profile.name,
                        subtitle: "(You)",
                        avatarType: profile.avatarType,
                        isSelected: viewModel.splitOptions.participantIds.contains(profile.id),
                        action: {
                            HapticManager.shared.selection()
                            viewModel.splitOptions.toggleParticipant(profile.id)
                        }
                    )

                    if !filteredSplitPeople.isEmpty {
                        Divider().padding(.leading, 68)
                    }
                }

                ForEach(filteredSplitPeople) { person in
                    if person.id != UserProfileManager.shared.profile.id {
                        MemberRow(
                            name: person.name,
                            subtitle: person.phone.isEmpty ? nil : person.phone,
                            avatarType: person.avatarType,
                            isSelected: viewModel.splitOptions.participantIds.contains(person.id),
                            action: {
                                HapticManager.shared.selection()
                                viewModel.splitOptions.toggleParticipant(person.id)
                            }
                        )

                        if person.id != filteredSplitPeople.last?.id {
                            Divider().padding(.leading, 68)
                        }
                    }
                }

                if filteredSplitPeople.isEmpty && !matchesSplitSearch(UserProfileManager.shared.profile.name) {
                    emptySearchState
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Metrics.cornerRadiusMedium)
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
    }

    // MARK: - Selected Avatar Pills

    private var selectedAvatarPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.splitOptions.orderedParticipantIds, id: \.self) { personId in
                    if let person = resolvePerson(personId) {
                        AvatarPill(
                            name: viewModel.splitOptions.isCurrentUser(personId)
                                ? "You" : person.name,
                            avatarType: person.avatarType,
                            onRemove: {
                                withAnimation(reduceMotion ? .none : .spring(response: 0.2)) {
                                    HapticManager.shared.selection()
                                    viewModel.splitOptions.removeParticipant(personId)
                                }
                            }
                        )
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale.combined(with: .opacity)
                        )
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
        .animation(reduceMotion ? .none : .spring(response: 0.3), value: viewModel.splitOptions.participantIds)
    }

    // MARK: - Shared Components

    private func searchBar(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: Theme.Metrics.paddingSmall) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary)

            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textPrimary)

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.Metrics.cornerRadiusMedium)
    }

    private var emptySearchState: some View {
        Text("No people found")
            .font(.system(size: 15))
            .foregroundColor(Theme.Colors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    // MARK: - Helper Methods

    private var filteredPayers: [Person] {
        if payerSearchText.isEmpty {
            return dataManager.people
        }
        return dataManager.people.filter {
            $0.name.localizedCaseInsensitiveContains(payerSearchText)
        }
    }

    private var filteredSplitPeople: [Person] {
        if viewModel.splitOptions.splitWithSearchText.isEmpty {
            return dataManager.people
        }
        return dataManager.people.filter {
            $0.name.localizedCaseInsensitiveContains(viewModel.splitOptions.splitWithSearchText)
        }
    }

    private func payerMatchesSearch(_ name: String) -> Bool {
        payerSearchText.isEmpty || name.localizedCaseInsensitiveContains(payerSearchText)
    }

    private func matchesSplitSearch(_ name: String) -> Bool {
        viewModel.splitOptions.splitWithSearchText.isEmpty
            || name.localizedCaseInsensitiveContains(viewModel.splitOptions.splitWithSearchText)
    }

    private func resolvePerson(_ id: UUID) -> Person? {
        if id == UserProfileManager.shared.profile.id {
            return UserProfileManager.shared.profile.asPerson
        }
        return dataManager.people.first { $0.id == id }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// MARK: - Payer Row (Single Select — Radio Style)

private struct PayerRow: View {
    let name: String
    let subtitle: String?
    let avatarType: AvatarType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AvatarView(avatarType: avatarType, size: .medium, style: .solid)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 17))
                        .foregroundColor(Theme.Colors.textPrimary)

                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Radio button
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Theme.Colors.brandPrimary : Theme.Colors.textTertiary,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.brandPrimary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Theme.Colors.brandPrimary.opacity(0.06)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name)\(isSelected ? ", selected as payer" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Member Row (Multi Select — Checkbox Style)

private struct MemberRow: View {
    let name: String
    let subtitle: String?
    let avatarType: AvatarType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AvatarView(avatarType: avatarType, size: .medium, style: .solid)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 17))
                        .foregroundColor(Theme.Colors.textPrimary)

                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Theme.Colors.brandPrimary : Theme.Colors.textTertiary,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.brandPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.Colors.textOnPrimary)
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.paddingMedium)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Theme.Colors.brandPrimary.opacity(0.06)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name)\(isSelected ? ", included in split" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Avatar Pill (Removable)

private struct AvatarPill: View {
    let name: String
    let avatarType: AvatarType
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            AvatarView(avatarType: avatarType, size: .small, style: .solid)
                .frame(width: 24, height: 24)

            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(width: 16, height: 16)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Theme.Colors.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - UserProfile Extension

extension Person {
    var asPerson: Person { self }
}

extension UserProfile {
    var asPerson: Person {
        Person(
            name: self.name,
            email: self.email,
            phone: self.phone,
            avatarType: self.avatarType
        )
    }
}

// MARK: - Preview

#Preview("Step 2 - People") {
    Step2SplitOptionsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
}
