//
//  Step2SplitOptionsView.swift
//  Swiff IOS
//
//  Step 2: Personal/Split toggle, payer selection, participant selection
//  Redesigned to match reference UI exactly with group support
//

import SwiftUI

struct Step2SplitOptionsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            // MARK: Personal/Split Toggle
            splitModeToggle
                .id("splitToggle")

            // MARK: Split Configuration (only when splitting)
            if viewModel.isSplit {
                // Paid By Section
                paidBySection
                    .id("paidBySection")

                // Split With Section
                splitWithSection
                    .id("splitWithSection")
            }

            // MARK: Navigation Buttons
            navigationButtons

            // Bottom padding for keyboard
            Spacer(minLength: keyboardHeight > 0 ? keyboardHeight : 60)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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

    // MARK: - Split Mode Toggle

    private var splitModeToggle: some View {
        VStack(spacing: 0) {
            // Personal option
            SplitOptionRow(
                icon: "1",
                title: "Personal",
                subtitle: "Just for you",
                isSelected: !viewModel.isSplit
            ) {
                withAnimation(.smooth) {
                    viewModel.isSplit = false
                }
            }

            Divider()
                .padding(.leading, 72)

            // Split option
            SplitOptionRow(
                icon: "2",
                title: "Split",
                subtitle: "Share with friends or groups",
                isSelected: viewModel.isSplit
            ) {
                withAnimation(.smooth) {
                    viewModel.isSplit = true
                    // Auto-select first person as payer if none selected
                    if viewModel.paidByUserId == nil, let firstPerson = dataManager.people.first {
                        viewModel.selectPayer(firstPerson.id)
                    }
                }
            }
        }
        .background(Theme.Colors.sheetCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Paid By Section

    private var paidBySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            SectionHeaderView(title: "PAID BY")

            // Show payer card or search
            if viewModel.isPaidBySearchFocused {
                paidBySearchView
            } else {
                selectedPayerCard
            }
        }
    }

    private var selectedPayerCard: some View {
        HStack(spacing: 12) {
            // Avatar
            if let payer = dataManager.people.first(where: { $0.id == viewModel.paidByUserId }) {
                PersonAvatarView(person: payer, size: 48, isSelected: true)

                // Name
                Text(payer.name)
                    .font(.system(size: 17, weight: .medium))

                Spacer()

                // Change button
                Button {
                    HapticManager.shared.light()
                    viewModel.isPaidBySearchFocused = true
                } label: {
                    Text("Change")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.brandPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.brandPrimary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.Colors.sheetCardBackground)
        .cornerRadius(12)
    }

    private var paidBySearchView: some View {
        VStack(spacing: 12) {
            // Search bar
            TransactionSearchBar(
                placeholder: "Search contacts...",
                text: $viewModel.paidBySearchText
            )

            // Results list
            VStack(spacing: 0) {
                let filteredContacts = viewModel.filteredPaidByContacts(from: dataManager.people)

                ForEach(Array(filteredContacts.enumerated()), id: \.element.id) { index, person in
                    Button {
                        HapticManager.shared.light()
                        viewModel.selectPayer(person.id)
                    } label: {
                        ContactSearchRowView(
                            person: person,
                            isSelected: viewModel.paidByUserId == person.id
                        )
                    }
                    .buttonStyle(.plain)

                    if index < filteredContacts.count - 1 {
                        Divider()
                            .padding(.leading, 72)
                    }
                }

                // Empty state
                if filteredContacts.isEmpty {
                    Text("No contacts found")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                }
            }
            .background(Theme.Colors.sheetCardBackground)
            .cornerRadius(12)

            // Cancel button
            Button {
                HapticManager.shared.light()
                viewModel.isPaidBySearchFocused = false
                viewModel.paidBySearchText = ""
            } label: {
                Text("Cancel")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
    }

    // MARK: - Split With Section

    private var splitWithSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with count
            SectionHeaderView(title: "SPLIT WITH (\(viewModel.participantIds.count))")

            // Selected group badge (if any)
            if let group = viewModel.selectedGroup {
                SelectedGroupBadgeView(group: group) {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        viewModel.clearGroup()
                    }
                }
            }

            // Selected participants list (only show selected people)
            if !viewModel.participantIds.isEmpty {
                selectedParticipantsListView
            }

            // Add participants button or inline search
            if viewModel.isSplitWithSearchFocused {
                addParticipantsSearchView
            } else {
                addParticipantsButton
            }
        }
    }

    // MARK: - Selected Participants List (Only selected people)

    private var selectedParticipantsListView: some View {
        let selectedPeople = dataManager.people.filter { viewModel.participantIds.contains($0.id) }

        return VStack(spacing: 0) {
            ForEach(Array(selectedPeople.enumerated()), id: \.element.id) { index, person in
                let isFromGroup = viewModel.selectedGroup?.members.contains(person.id) ?? false
                let isPayer = viewModel.paidByUserId == person.id

                SelectedParticipantRow(
                    person: person,
                    isFromGroup: isFromGroup,
                    groupName: viewModel.selectedGroup?.name,
                    isPayer: isPayer,
                    onRemove: isPayer
                        ? nil
                        : {
                            HapticManager.shared.light()
                            withAnimation(.smooth) {
                                viewModel.toggleParticipant(person.id)
                            }
                        }
                )

                if index < selectedPeople.count - 1 {
                    Divider()
                        .padding(.leading, 68)
                }
            }
        }
        .background(Theme.Colors.sheetCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Add Participants Button

    private var addParticipantsButton: some View {
        Button {
            HapticManager.shared.light()
            withAnimation(.smooth) {
                viewModel.isSplitWithSearchFocused = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.brandPrimary)

                Text("Add Participants")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.Colors.brandPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.Colors.brandPrimary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Participants Search View

    private var addParticipantsSearchView: some View {
        VStack(spacing: 12) {
            // Search bar with cancel
            HStack(spacing: 12) {
                TransactionSearchBar(
                    placeholder: "Search contacts or groups...",
                    text: $viewModel.splitWithSearchText
                )

                Button {
                    HapticManager.shared.light()
                    withAnimation(.smooth) {
                        viewModel.isSplitWithSearchFocused = false
                        viewModel.splitWithSearchText = ""
                    }
                } label: {
                    Text("Done")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }

            // Search results
            splitWithSearchResults
        }
    }

    private var splitWithSearchResults: some View {
        VStack(spacing: 0) {
            let filteredGroups = viewModel.filteredSplitWithGroups(from: dataManager.groups)
            let filteredContacts = viewModel.filteredSplitWithContacts(from: dataManager.people)
                .filter { !viewModel.participantIds.contains($0.id) }  // Exclude already selected

            // Groups section
            if !filteredGroups.isEmpty {
                // Section header
                HStack {
                    Text("GROUPS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGroupedBackground))

                // Group rows
                ForEach(filteredGroups) { group in
                    Button {
                        HapticManager.shared.light()
                        viewModel.selectGroup(group)
                    } label: {
                        GroupSearchRowView(
                            group: group,
                            people: dataManager.people,
                            isSelected: viewModel.selectedGroup?.id == group.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Contacts section (only show contacts not already selected)
            if !filteredContacts.isEmpty {
                // Section header
                HStack {
                    Text("CONTACTS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGroupedBackground))

                // Contact rows
                ForEach(filteredContacts) { person in
                    Button {
                        HapticManager.shared.light()
                        viewModel.addParticipantFromSearch(person.id)
                    } label: {
                        ContactSearchRowView(
                            person: person,
                            isSelected: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Empty state
            if filteredGroups.isEmpty && filteredContacts.isEmpty {
                Text(viewModel.splitWithSearchText.isEmpty ? "Type to search" : "No results found")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Theme.Colors.sheetCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                HapticManager.shared.light()
                withAnimation(.smooth) {
                    viewModel.goToPreviousStep()
                }
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

            // Continue/Save button
            Button {
                HapticManager.shared.light()
                if !viewModel.isSplit {
                    // Personal transaction - submit directly
                    // Note: The parent view handles the actual save
                } else if viewModel.canProceedStep2 {
                    viewModel.initializeSplitDefaults()
                    withAnimation(.smooth) {
                        viewModel.goToNextStep()
                    }
                }
            } label: {
                Text(viewModel.isSplit ? "Continue" : "Save")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.brandPrimary)
                            .opacity(viewModel.canProceedStep2 ? 1 : 0.5)
                    )
            }
            .disabled(!viewModel.canProceedStep2)
        }
    }
}

// MARK: - Supporting Views

/// Section header styled like iOS Settings
struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

/// iOS-style search bar for transaction flow
struct TransactionSearchBar: View {
    let placeholder: String
    @Binding var text: String
    var onFocus: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            // Text field
            TextField(
                placeholder, text: $text,
                onEditingChanged: { isEditing in
                    if isEditing {
                        onFocus?()
                    }
                }
            )
            .font(.system(size: 17))

            // Clear button
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

/// Person avatar view
struct PersonAvatarView: View {
    let person: Person
    var size: CGFloat = 40
    var isSelected: Bool = false

    var body: some View {
        AvatarView(avatarType: person.avatarType, size: avatarSize, style: .solid)
            .frame(width: size, height: size)
    }

    private var avatarSize: AvatarSize {
        if size <= 32 { return .small }
        if size <= 40 { return .small }
        if size <= 48 { return .medium }
        return .large
    }
}

/// Contact row in search results
struct ContactSearchRowView: View {
    let person: Person
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            PersonAvatarView(person: person, size: 44, isSelected: isSelected)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                if !person.email.isEmpty {
                    Text(person.email)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Checkmark
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Group row in search results
struct GroupSearchRowView: View {
    let group: Group
    let people: [Person]
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Group icon
            Text(group.emoji)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Theme.Colors.brandPrimary.opacity(0.2))
                .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)

                // Member preview
                let memberNames = group.members.compactMap { memberId -> String? in
                    people.first { $0.id == memberId }?.name.components(separatedBy: " ").first
                }.prefix(3).joined(separator: ", ")

                Text(
                    "\(group.members.count) members \(memberNames.isEmpty ? "" : "- \(memberNames)")"
                )
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
            }

            Spacer()

            // Checkmark
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Selected group badge
struct SelectedGroupBadgeView: View {
    let group: Group
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(group.emoji)
                .font(.system(size: 18))

            Text(group.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.brandPrimary)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .frame(width: 20, height: 20)
                    .background(Theme.Colors.brandPrimary.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Colors.brandPrimary.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Participant row with checkbox (legacy - used for search results)
struct ParticipantRowView: View {
    let person: Person
    let isSelected: Bool
    let isFromGroup: Bool
    let groupName: String?
    let isPayer: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            PersonAvatarView(person: person, size: 40, isSelected: isSelected)

            // Name and group tag
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)

                    if isPayer {
                        Text("Paid")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                if isFromGroup, let groupName = groupName {
                    Text("from \(groupName)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }

            Spacer()

            // Checkbox
            Circle()
                .strokeBorder(
                    isSelected ? Theme.Colors.brandPrimary : Color(UIColor.systemGray3),
                    lineWidth: 2
                )
                .background(
                    Circle()
                        .fill(isSelected ? Theme.Colors.brandPrimary : Color.clear)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Selected participant row with remove button (new design)
struct SelectedParticipantRow: View {
    let person: Person
    let isFromGroup: Bool
    let groupName: String?
    let isPayer: Bool
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            PersonAvatarView(person: person, size: 40, isSelected: true)

            // Name and group tag
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)

                    if isPayer {
                        Text("Paid")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                if isFromGroup, let groupName = groupName {
                    Text("from \(groupName)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }

            Spacer()

            // Remove button (only if not payer)
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Step 2 - Split Options") {
    Step2SplitOptionsView(
        viewModel: {
            let vm = NewTransactionViewModel()
            vm.isSplit = true
            return vm
        }()
    )
    .environmentObject(DataManager.shared)
    .background(Color(UIColor.systemGroupedBackground))
}
