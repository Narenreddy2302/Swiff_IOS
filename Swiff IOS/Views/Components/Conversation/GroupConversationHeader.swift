//
//  GroupConversationHeader.swift
//  Swiff IOS
//
//  Conversation-style header for group detail view
//  Shows group info with member avatars
//

import SwiftUI

// MARK: - Group Conversation Header

struct GroupConversationHeader: View {
    let group: Group
    let members: [Person]
    var backgroundColor: Color = .wiseBlue

    private var totalAmount: Double {
        group.expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Large emoji circle (80pt)
            UnifiedEmojiCircle(
                emoji: group.emoji,
                backgroundColor: backgroundColor,
                size: 80
            )

            // Group name
            Text(group.name)
                .font(.spotifyDisplayMedium)
                .foregroundColor(.wisePrimaryText)
                .multilineTextAlignment(.center)

            // Description (if present)
            if !group.description.isEmpty {
                Text(group.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Stats row (members + total)
            HStack(spacing: 24) {
                // Member count
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                        .font(.spotifyLabelMedium)
                }
                .foregroundColor(.wiseSecondaryText)

                // Separator dot
                Text("•")
                    .foregroundColor(.wiseBorder)

                // Total amount
                Text(String(format: "$%.2f total", totalAmount))
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            // Member avatar stack (centered)
            if !members.isEmpty {
                MemberAvatarStack(
                    people: members,
                    maxVisible: 5,
                    avatarSize: 36,
                    overlap: 8
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview("Group Conversation Header") {
    ScrollView {
        VStack(spacing: 32) {
            // Sample with multiple members
            GroupConversationHeader(
                group: Group(
                    name: "Weekend Trip",
                    description: "Beach house expenses",
                    emoji: "🏖️",
                    members: [UUID(), UUID(), UUID()]
                ),
                members: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2))
                ]
            )

            Divider()

            // Sample with many members
            GroupConversationHeader(
                group: Group(
                    name: "Office Lunch Group",
                    description: "Weekly team lunches and coffee runs",
                    emoji: "🍕",
                    members: [UUID(), UUID(), UUID(), UUID(), UUID(), UUID()]
                ),
                members: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2)),
                    Person(name: "Sarah Wilson", email: "sarah@example.com", phone: "", avatarType: .initials("SW", colorIndex: 3)),
                    Person(name: "Mike Brown", email: "mike@example.com", phone: "", avatarType: .initials("MB", colorIndex: 4)),
                    Person(name: "Chris Johnson", email: "chris@example.com", phone: "", avatarType: .initials("CJ", colorIndex: 0))
                ]
            )

            Divider()

            // Sample with no description
            GroupConversationHeader(
                group: Group(
                    name: "Roommates",
                    description: "",
                    emoji: "🏠",
                    members: [UUID(), UUID()]
                ),
                members: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1))
                ]
            )
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}
