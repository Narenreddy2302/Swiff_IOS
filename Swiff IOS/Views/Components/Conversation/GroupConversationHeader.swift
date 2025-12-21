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

#Preview("GroupConversationHeader - With Expenses") {
    GroupConversationHeader(
        group: MockData.groupWithExpenses,
        members: [MockData.personOwedMoney, MockData.personOwingMoney, MockData.personSettled]
    )
    .background(Color.wiseBackground)
}

#Preview("GroupConversationHeader - Large Group") {
    GroupConversationHeader(
        group: MockData.largeGroup,
        members: MockData.people
    )
    .background(Color.wiseBackground)
}

#Preview("GroupConversationHeader - Empty Group") {
    GroupConversationHeader(
        group: MockData.emptyGroup,
        members: [MockData.personOwedMoney, MockData.personOwingMoney]
    )
    .background(Color.wiseBackground)
}
