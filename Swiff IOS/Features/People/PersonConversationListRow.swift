//
//  PersonConversationListRow.swift
//  Swiff IOS
//
//  WhatsApp-style conversation row for the People list
//  Shows avatar, name, last message preview, timestamp, and unread/balance badge
//

import SwiftUI

// MARK: - Person Conversation List Row

/// WhatsApp-style conversation row for a person
/// Layout: 52x52 avatar | Name + Last message | Timestamp + Badge
struct PersonConversationListRow: View {
    @EnvironmentObject var dataManager: DataManager
    let person: Person

    private let avatarSize: CGFloat = 52

    private var preview: ConversationPreview {
        dataManager.conversationPreview(for: person)
    }

    private var balanceBadge: (text: String, color: Color)? {
        if person.balance > 0 {
            return ("+\(abs(person.balance).asCurrency)", Theme.Colors.feedPositiveAmount)
        } else if person.balance < 0 {
            return ("-\(abs(person.balance).asCurrency)", Theme.Colors.statusError)
        }
        return nil
    }

    var body: some View {
        ConversationListRow(
            avatarContent: AnyView(initialsAvatar),
            name: person.name,
            preview: preview,
            badgeText: preview.unreadCount == 0 ? balanceBadge?.text : nil,
            badgeColor: preview.unreadCount == 0 ? balanceBadge?.color : nil
        )
    }

    // MARK: - Avatar

    private var avatarColor: FeedAvatarColor {
        FeedAvatarColor.forName(person.name)
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: person.name))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Group Conversation List Row

/// WhatsApp-style conversation row for a group
/// Shows emoji avatar, group name, last expense/message, and total amount
struct GroupConversationListRow: View {
    @EnvironmentObject var dataManager: DataManager
    let group: Group

    private let avatarSize: CGFloat = 52

    private var preview: ConversationPreview {
        dataManager.conversationPreview(for: group)
    }

    private var totalBadge: (text: String, color: Color)? {
        if group.totalAmount > 0 {
            return (group.totalAmount.asCurrency, Theme.Colors.feedPrimaryText)
        }
        return nil
    }

    var body: some View {
        ConversationListRow(
            avatarContent: AnyView(emojiAvatar),
            name: group.name,
            preview: preview,
            badgeText: preview.unreadCount == 0 ? totalBadge?.text : nil,
            badgeColor: preview.unreadCount == 0 ? totalBadge?.color : nil
        )
    }

    // MARK: - Avatar

    private var avatarColor: FeedAvatarColor {
        FeedAvatarColor.forName(group.name)
    }

    private var emojiAvatar: some View {
        Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(group.emoji)
                    .font(.system(size: 22))
            )
            .accessibilityHidden(true)
    }
}
