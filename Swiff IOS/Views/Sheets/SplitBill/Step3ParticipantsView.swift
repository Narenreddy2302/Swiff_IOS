//
//  Step3ParticipantsView.swift
//  Swiff IOS
//
//  Step 3: Select participants to split the bill with
//

import SwiftUI

struct Step3ParticipantsView: View {
    @Binding var selectedParticipants: Set<UUID>
    @Binding var selectedGroup: Group?
    @EnvironmentObject var dataManager: DataManager

    @State private var useGroup = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Who's splitting the bill?")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Toggle: Friends or Group
                HStack(spacing: 0) {
                    Button(action: {
                        useGroup = false
                        selectedGroup = nil
                        HapticManager.shared.light()
                    }) {
                        Text("Friends")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(useGroup ? .wiseSecondaryText : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(useGroup ? Color.clear : Color.wiseBrightGreen)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        useGroup = true
                        selectedParticipants.removeAll()
                        HapticManager.shared.light()
                    }) {
                        Text("Group")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(useGroup ? .white : .wiseSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(useGroup ? Color.wiseBrightGreen : Color.clear)
                            .cornerRadius(8)
                    }
                }
                .background(Color.wiseBorder.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal, 20)

                if !useGroup {
                    // Friends selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(selectedParticipants.count) selected")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(dataManager.people) { person in
                                Button(action: {
                                    HapticManager.shared.light()
                                    if selectedParticipants.contains(person.id) {
                                        selectedParticipants.remove(person.id)
                                    } else {
                                        selectedParticipants.insert(person.id)
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        // Avatar
                                        AvatarView(
                                            avatarType: person.avatarType,
                                            size: .large,
                                            style: .solid
                                        )
                                        .frame(width: 48, height: 48)

                                        // Name
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(person.name)
                                                .font(.spotifyBodyLarge)
                                                .foregroundColor(.wisePrimaryText)

                                            if !person.email.isEmpty {
                                                Text(person.email)
                                                    .font(.spotifyCaptionMedium)
                                                    .foregroundColor(.wiseSecondaryText)
                                            }
                                        }

                                        Spacer()

                                        // Checkbox
                                        Image(systemName: selectedParticipants.contains(person.id) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedParticipants.contains(person.id) ? .wiseBrightGreen : .wiseBorder.opacity(0.5))
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedParticipants.contains(person.id) ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseCardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedParticipants.contains(person.id) ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.3),
                                                lineWidth: selectedParticipants.contains(person.id) ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    // Group selection
                    VStack(spacing: 12) {
                        ForEach(dataManager.groups) { group in
                            Button(action: {
                                HapticManager.shared.light()
                                selectedGroup = group
                                // Auto-select all group members as participants
                                selectedParticipants = Set(group.members)
                            }) {
                                HStack(spacing: 16) {
                                    // Emoji circle
                                    Circle()
                                        .fill(Color.wiseBlue.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(group.emoji)
                                                .font(.system(size: 24))
                                        )

                                    // Name and member count
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(group.name)
                                            .font(.spotifyBodyLarge)
                                            .foregroundColor(.wisePrimaryText)

                                        Text("\(group.members.count) members")
                                            .font(.spotifyCaptionMedium)
                                            .foregroundColor(.wiseSecondaryText)
                                    }

                                    Spacer()

                                    // Selection indicator
                                    if selectedGroup?.id == group.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.wiseBrightGreen)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(.wiseBorder.opacity(0.5))
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedGroup?.id == group.id ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseCardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedGroup?.id == group.id ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.3),
                                            lineWidth: selectedGroup?.id == group.id ? 2 : 1
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)

                    if dataManager.groups.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.3.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.wiseSecondaryText)

                            Text("No groups found")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text("Create a group in the People tab first")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.wiseBackground)
    }
}

// MARK: - Preview

#Preview("Step 3 Participants") {
    let dataManager = DataManager.shared
    let person1 = Person(name: "Alice", email: "alice@example.com", phone: "+1234567890", avatar: "👩‍💼")
    let person2 = Person(name: "Bob", email: "bob@example.com", phone: "+1234567891", avatar: "👨‍💻")
    let person3 = Person(name: "Charlie", email: "charlie@example.com", phone: "+1234567892", avatar: "🧑‍🔧")
    dataManager.people = [person1, person2, person3]

    return Step3ParticipantsView(
        selectedParticipants: .constant([person1.id]),
        selectedGroup: .constant(nil)
    )
    .environmentObject(dataManager)
}
