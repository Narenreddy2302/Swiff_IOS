//
//  ConversationListRow.swift
//  Swiff IOS
//
//  WhatsApp-style conversation list row component
//  Used across People, Groups, and Subscriptions pages
//  Layout: Avatar | Name + Last message preview | Timestamp + Badge
//

import SwiftUI

// MARK: - WhatsApp Timestamp Formatter

/// Formats dates in WhatsApp style:
/// - Today: "10:30 AM"
/// - Yesterday: "Yesterday"
/// - This week: "Monday", "Tuesday", etc.
/// - Older: "12/25/24"
struct WhatsAppTimestamp {
    static func format(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let weekAgo = calendar.date(byAdding: .day, value: -6, to: now),
                  date >= weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: date)
        }
    }

    /// Color for the timestamp text
    static func color(hasUnread: Bool) -> Color {
        hasUnread ? Color(red: 0.0, green: 0.75, blue: 0.40) : Theme.Colors.feedSecondaryText
    }
}

// MARK: - Conversation Preview Data

/// Data model for conversation list row preview
struct ConversationPreview {
    let lastMessageText: String
    let lastMessageDate: Date?
    let unreadCount: Int
    let isLastMessageSent: Bool     // true = outgoing (shows ticks)
    let messageStatus: MessageStatus?
    let isTyping: Bool

    static var empty: ConversationPreview {
        ConversationPreview(
            lastMessageText: "No messages yet",
            lastMessageDate: nil,
            unreadCount: 0,
            isLastMessageSent: false,
            messageStatus: nil,
            isTyping: false
        )
    }
}

// MARK: - Conversation List Row

/// WhatsApp-style conversation list row
/// Shows avatar, name, last message preview, timestamp, and unread badge
struct ConversationListRow: View {
    let avatarContent: AnyView
    let name: String
    let preview: ConversationPreview
    let badgeText: String?       // Optional secondary badge (e.g., balance)
    let badgeColor: Color?

    private let avatarSize: CGFloat = 52

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            avatarContent
                .frame(width: avatarSize, height: avatarSize)

            // Middle: Name + Last message
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.feedPrimaryText)
                    .lineLimit(1)

                // Last message preview
                HStack(spacing: 4) {
                    // Delivery status ticks for sent messages
                    if preview.isLastMessageSent, let status = preview.messageStatus {
                        MessageStatusTicks(status: status)
                    }

                    if preview.isTyping {
                        Text("typing...")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.0, green: 0.75, blue: 0.40))
                            .italic()
                    } else {
                        Text(preview.lastMessageText)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.feedSecondaryText)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            // Right: Timestamp + Badge
            VStack(alignment: .trailing, spacing: 6) {
                // Timestamp
                if let date = preview.lastMessageDate {
                    Text(WhatsAppTimestamp.format(date))
                        .font(.system(size: 12))
                        .foregroundColor(WhatsAppTimestamp.color(hasUnread: preview.unreadCount > 0))
                }

                // Unread badge OR secondary badge
                if preview.unreadCount > 0 {
                    UnreadBadge(count: preview.unreadCount)
                } else if let badgeText = badgeText, let badgeColor = badgeColor {
                    Text(badgeText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(badgeColor)
                }
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(preview.lastMessageText)")
    }
}

// MARK: - Message Status Ticks (WhatsApp-style)

/// Double-tick delivery status indicator like WhatsApp
struct MessageStatusTicks: View {
    let status: MessageStatus

    var body: some View {
        Group {
            switch status {
            case .sending:
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            case .delivered:
                // Double checkmark (gray)
                HStack(spacing: -4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Theme.Colors.feedSecondaryText)
            case .read:
                // Double checkmark (blue)
                HStack(spacing: -4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(red: 0.33, green: 0.69, blue: 0.94))
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Unread Badge (WhatsApp-style green circle)

/// Green circle with unread count, matching WhatsApp design
struct UnreadBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 6 : 0)
            .frame(minWidth: 22, minHeight: 22)
            .background(
                Capsule()
                    .fill(Color(red: 0.0, green: 0.75, blue: 0.40))
            )
    }
}

// MARK: - Muted Badge (WhatsApp-style muted indicator)

/// Shows a muted icon for silenced conversations
struct MutedIndicator: View {
    var body: some View {
        Image(systemName: "speaker.slash.fill")
            .font(.system(size: 12))
            .foregroundColor(Theme.Colors.feedSecondaryText)
    }
}

// MARK: - Conversation Row Divider

/// Indented divider matching WhatsApp conversation list style
/// Starts after the avatar area (52 + 14 spacing = 66pt indent)
struct ConversationRowDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: 80) // Avatar width + spacing + small padding
            Divider()
                .background(Theme.Colors.border.opacity(0.5))
        }
        .frame(height: 0.5)
        .padding(.horizontal, 16)
    }
}
