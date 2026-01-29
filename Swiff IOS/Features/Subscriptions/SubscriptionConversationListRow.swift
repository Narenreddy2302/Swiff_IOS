//
//  SubscriptionConversationListRow.swift
//  Swiff IOS
//
//  WhatsApp-style conversation row for the Subscriptions list
//  Shows icon avatar, name, last event/message, timestamp, and price badge
//

import SwiftUI

// MARK: - Subscription Conversation List Row

/// WhatsApp-style conversation row for a subscription
/// Layout: 52x52 icon avatar | Name + Last event | Timestamp + Price badge
struct SubscriptionConversationListRow: View {
    @EnvironmentObject var dataManager: DataManager
    let subscription: Subscription

    private let avatarSize: CGFloat = 52

    private var preview: ConversationPreview {
        dataManager.conversationPreview(for: subscription)
    }

    private var priceBadge: (text: String, color: Color) {
        let suffix: String
        switch subscription.billingCycle {
        case .monthly: suffix = "/mo"
        case .yearly, .annually: suffix = "/yr"
        case .weekly: suffix = "/wk"
        case .quarterly: suffix = "/qtr"
        case .daily: suffix = "/day"
        case .biweekly: suffix = "/2wk"
        case .semiAnnually: suffix = "/6mo"
        case .lifetime: suffix = ""
        }

        let price = subscription.isShared ? subscription.costPerPerson : subscription.price
        let color: Color = subscription.isActive
            ? Theme.Colors.feedPrimaryText
            : Theme.Colors.feedSecondaryText

        return ("\(price.asCurrency)\(suffix)", color)
    }

    private var statusIndicator: (text: String, color: Color)? {
        if subscription.cancellationDate != nil {
            return ("Cancelled", Theme.Colors.statusError)
        } else if !subscription.isActive {
            return ("Paused", .orange)
        } else if subscription.isFreeTrial, let days = subscription.daysUntilTrialEnd, days <= 7 {
            return ("Trial · \(days)d left", .orange)
        }
        return nil
    }

    var body: some View {
        ConversationListRow(
            avatarContent: AnyView(subscriptionAvatar),
            name: subscription.name,
            preview: preview,
            badgeText: preview.unreadCount == 0 ? priceBadge.text : nil,
            badgeColor: preview.unreadCount == 0 ? priceBadge.color : nil
        )
        .overlay(alignment: .bottomTrailing) {
            // Status overlay for inactive/cancelled/trial
            if let status = statusIndicator, preview.unreadCount == 0 {
                Text(status.text)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(status.color)
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Avatar

    private var iconColor: Color {
        Color(hexString: subscription.color)
    }

    private var subscriptionAvatar: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: avatarSize, height: avatarSize)

            Image(systemName: subscription.icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
        }
        .overlay(alignment: .bottomTrailing) {
            // Active status dot
            if subscription.isActive && subscription.cancellationDate == nil {
                Circle()
                    .fill(Color(red: 0.0, green: 0.75, blue: 0.40))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.wiseBackground, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Shared Subscription Conversation List Row

/// WhatsApp-style conversation row for a shared subscription
struct SharedSubscriptionConversationListRow: View {
    @EnvironmentObject var dataManager: DataManager
    let sharedSubscription: SharedSubscription
    let people: [Person]
    let subscription: Subscription?

    private let avatarSize: CGFloat = 52

    private var displayName: String {
        subscription?.name ?? (sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes)
    }

    private var preview: ConversationPreview {
        let totalPeople = sharedSubscription.sharedWith.count + 1
        let memberNames = sharedSubscription.sharedWith.prefix(2).compactMap { id in
            people.first { $0.id == id }?.name.components(separatedBy: " ").first
        }
        let memberText = memberNames.isEmpty ? "Shared" : memberNames.joined(separator: ", ")
        let suffix = totalPeople > 3 ? " +\(totalPeople - 3) more" : ""

        return ConversationPreview(
            lastMessageText: "Shared with \(memberText)\(suffix) · \(sharedSubscription.individualCost.asCurrency)/person",
            lastMessageDate: sharedSubscription.nextBillingDate,
            unreadCount: 0,
            isLastMessageSent: false,
            messageStatus: nil,
            isTyping: false
        )
    }

    private var balanceBadge: (text: String, color: Color)? {
        let balance = sharedSubscription.balance
        if balance > 0 {
            return ("+\(balance.asCurrency)", Color(red: 0.020, green: 0.588, blue: 0.412))
        } else if balance < 0 {
            return ("-\(abs(balance).asCurrency)", Theme.Colors.feedPrimaryText)
        }
        return nil
    }

    var body: some View {
        ConversationListRow(
            avatarContent: AnyView(sharedAvatar),
            name: displayName,
            preview: preview,
            badgeText: balanceBadge?.text,
            badgeColor: balanceBadge?.color
        )
    }

    // MARK: - Avatar

    private var sharedAvatar: some View {
        let avatarColor = FeedAvatarColor.forName(displayName)
        return ZStack {
            Circle()
                .fill(avatarColor.background)
                .frame(width: avatarSize, height: avatarSize)

            // Show member avatar stack if small count, else initials
            if sharedSubscription.members.count <= 3 {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(avatarColor.foreground)
            } else {
                Text(InitialsGenerator.generate(from: displayName))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
            }
        }
        .accessibilityHidden(true)
    }
}
