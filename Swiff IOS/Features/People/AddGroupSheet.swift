import SwiftUI

// MARK: - Add Group Sheet (Redesigned with Live Preview)
struct AddGroupSheet: View {
    @Binding var showingAddGroupSheet: Bool
    @EnvironmentObject var dataManager: DataManager
    let editingGroup: Group?
    let people: [Person]
    let onGroupAdded: (Group) -> Void

    @State private var name = ""
    @State private var selectedEmoji = "👥"
    @State private var selectedMembers: Set<UUID> = []
    @State private var showingAddPersonSheet = false
    @State private var personCountBeforeAdd = 0
    @FocusState private var isNameFocused: Bool

    // Quick emoji options (6 most common)
    private let quickEmojis = ["👥", "🏠", "🎉", "✈️", "🍕", "💼"]
    private let allEmojis = [
        "👥", "🏖️", "🏠", "💼", "🎉", "🍕", "✈️", "🏃‍♂️", "📚", "🎵", "🎮", "⚽", "🍽️", "🏛️", "🎭", "🎪", "🎨", "📱",
    ]

    init(
        showingAddGroupSheet: Binding<Bool>, editingGroup: Group? = nil, people: [Person],
        onGroupAdded: @escaping (Group) -> Void
    ) {
        self._showingAddGroupSheet = showingAddGroupSheet
        self.editingGroup = editingGroup
        self.people = people
        self.onGroupAdded = onGroupAdded

        if let group = editingGroup {
            _name = State(initialValue: group.name)
            _selectedEmoji = State(initialValue: group.emoji)
            _selectedMembers = State(initialValue: Set(group.members))
        }
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedMembers.isEmpty
    }

    private var saveButtonText: String {
        editingGroup == nil ? "Create Group" : "Save Changes"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Live Preview Card
                previewCard

                // Group Details Section
                groupDetailsSection

                // Members Section
                membersSection

                // Create/Save Button
                createButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color.wiseBackground)
        .onAppear { isNameFocused = true }
        .sheet(isPresented: $showingAddPersonSheet) {
            AddPersonSheet(isPresented: $showingAddPersonSheet)
                .environmentObject(dataManager)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: showingAddPersonSheet) { oldValue, newValue in
            if newValue {
                personCountBeforeAdd = dataManager.people.count
            } else if !newValue && dataManager.people.count > personCountBeforeAdd {
                if let newestPerson = dataManager.people.last {
                    selectedMembers.insert(newestPerson.id)
                }
            }
        }
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        HStack(spacing: 16) {
            // Emoji in colored circle
            ZStack {
                Circle()
                    .fill(Color.wiseBlue)
                    .frame(width: 48, height: 48)

                Text(selectedEmoji)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "Group Name" : name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(name.isEmpty ? .wiseSecondaryText : .wisePrimaryText)

                Text("\(selectedMembers.count) member\(selectedMembers.count == 1 ? "" : "s")")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
    }

    // MARK: - Group Details Section
    private var groupDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Details")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Emoji + Name Row
            HStack(spacing: 12) {
                // Emoji button with edit indicator
                Menu {
                    ForEach(allEmojis, id: \.self) { emoji in
                        Button(action: {
                            HapticManager.shared.selection()
                            selectedEmoji = emoji
                        }) {
                            Text(emoji)
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.wiseBlue)
                            .frame(width: 52, height: 52)

                        Text(selectedEmoji)
                            .font(.system(size: 26))
                    }
                    .overlay(
                        Circle()
                            .fill(Color.wiseCardBackground)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.wiseSecondaryText)
                            )
                            .offset(x: 18, y: 18)
                    )
                }

                // Name TextField
                TextField("Group name", text: $name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                    .focused($isNameFocused)
            }

            // Quick Emoji Row
            HStack(spacing: 8) {
                ForEach(quickEmojis, id: \.self) { emoji in
                    Button(action: {
                        HapticManager.shared.selection()
                        selectedEmoji = emoji
                    }) {
                        Text(emoji)
                            .font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(
                                        selectedEmoji == emoji
                                            ? Color.wiseBlue.opacity(0.2)
                                            : Color.wiseBorder.opacity(0.3))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedEmoji == emoji ? Color.wiseBlue : Color.clear,
                                        lineWidth: 2)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
                }
            }
        }
    }

    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header with Count Badge
            HStack {
                Text("Members")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                if !selectedMembers.isEmpty {
                    Text("\(selectedMembers.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.wiseForestGreen))
                }
            }

            // Vertical Member List
            VStack(spacing: 0) {
                ForEach(dataManager.people) { person in
                    MemberSelectionRow(
                        person: person,
                        isSelected: selectedMembers.contains(person.id),
                        onToggle: {
                            HapticManager.shared.light()
                            if selectedMembers.contains(person.id) {
                                selectedMembers.remove(person.id)
                            } else {
                                selectedMembers.insert(person.id)
                            }
                        }
                    )

                    if person.id != dataManager.people.last?.id {
                        Divider()
                            .padding(.leading, 58)
                    }
                }

                // Add Person Row
                AddPersonRow(action: { showingAddPersonSheet = true })
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
            )
        }
    }

    // MARK: - Create Button
    private var createButton: some View {
        Button(action: saveGroup) {
            Text(saveButtonText)
                .font(.spotifyBodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.5))
                )
        }
        .disabled(!isFormValid)
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
    }

    // MARK: - Save Action
    private func saveGroup() {
        HapticManager.shared.impact(.medium)

        if let existing = editingGroup {
            var updatedGroup = existing
            updatedGroup.name = name.trimmingCharacters(in: .whitespaces)
            updatedGroup.emoji = selectedEmoji
            updatedGroup.members = Array(selectedMembers)
            onGroupAdded(updatedGroup)
        } else {
            let newGroup = Group(
                name: name.trimmingCharacters(in: .whitespaces),
                description: "",
                emoji: selectedEmoji,
                members: Array(selectedMembers)
            )
            onGroupAdded(newGroup)
        }

        HapticManager.shared.success()
        showingAddGroupSheet = false
    }
}

// MARK: - Member Selection Row (Vertical list with checkmarks)
struct MemberSelectionRow: View {
    let person: Person
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Avatar
                AvatarView(person: person, size: .large, style: .solid)
                    .frame(width: 44, height: 44)

                // Name
                Text(person.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .wiseForestGreen : .wiseBorder)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
