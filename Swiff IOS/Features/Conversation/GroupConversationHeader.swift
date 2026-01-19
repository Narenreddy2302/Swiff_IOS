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
        VStack(spacing: 0) {
            VStack(spacing: Theme.Metrics.paddingMedium) {
                // Large emoji circle (hero size)
                UnifiedEmojiCircle(
                    emoji: group.emoji,
                    backgroundColor: backgroundColor,
                    size: Theme.Metrics.avatarHero
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

                VStack(spacing: 4) {
                    // Group name
                    Text(group.name)
                        .font(Theme.Fonts.displayMedium)
                        .foregroundColor(.wisePrimaryText)
                        .multilineTextAlignment(.center)

                    // Description (if present)
                    if !group.description.isEmpty {
                        Text(group.description)
                            .font(Theme.Fonts.bodyLarge)
                            .foregroundColor(.wiseSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                // Stats row (members + total)
                HStack(spacing: Theme.Metrics.paddingMedium) {
                    // Member count
                    Label("\(members.count) member\(members.count == 1 ? "" : "s")", systemImage: "person.2.fill")
                        .font(Theme.Fonts.labelLarge)
                        .foregroundColor(.wiseSecondaryText)

                    // Separator dot
                    Circle()
                        .fill(Color.wiseBorder)
                        .frame(width: 4, height: 4)

                    // Total amount
                    Text("\(totalAmount.asCurrency) total")
                        .font(Theme.Fonts.labelLarge)
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.wiseBorder.opacity(0.2))
                .clipShape(Capsule())

                // Member avatar stack (centered)
                if !members.isEmpty {
                    MemberAvatarStack(
                        people: members,
                        maxVisible: 5,
                        avatarSize: Theme.Metrics.avatarStandard,
                        overlap: 10
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Theme.Metrics.paddingSmall)
                }
            }
            .padding(.top, Theme.Metrics.paddingLarge)
            .padding(.bottom, Theme.Metrics.paddingLarge)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

