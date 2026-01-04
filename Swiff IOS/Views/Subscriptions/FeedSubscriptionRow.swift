//
//  FeedSubscriptionRow.swift
//  Swiff IOS
//
//  Compact subscription row for feed-style display
//  Layout: 40x40 avatar | Name + Next Billing | Amount + Payer
//

import SwiftUI

// MARK: - Feed Subscription Row

/// Compact subscription row matching FeedTransactionRow style
/// Layout: 40x40 avatar | Name (14pt semibold) + Next Billing (12pt) | Amount (14pt semibold) + Payer (12pt)
struct FeedSubscriptionRow: View {
    let subscription: Subscription
    let people: [Person]
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 40

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 10) {
                // Avatar - initials with colored background
                initialsAvatar

                // Left side - Name and Next Billing
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                        .lineLimit(1)

                    Text(nextBillingText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }

                Spacer(minLength: 8)

                // Right side - Amount and Payer
                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayAmount)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)

                    Text(payerLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(subscription.name), \(displayAmount), \(payerLabel)")
    }

    // MARK: - Computed Properties

    private var nextBillingText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: subscription.nextBillingDate)
    }

    private var displayAmount: String {
        let amount = subscription.isShared ? subscription.costPerPerson : subscription.price
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    private var payerLabel: String {
        guard subscription.isShared, let firstPayerId = subscription.sharedWith.first else {
            return "You"
        }
        if let person = people.first(where: { $0.id == firstPayerId }) {
            return person.name
        }
        return "Shared"
    }

    // MARK: - Avatar

    private var initialsAvatar: some View {
        Circle()
            .fill(InitialsAvatarColors.color(for: subscription.name))
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: subscription.name))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(avatarTextColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }

    private var avatarTextColor: Color {
        // Use dark text on light backgrounds (green, yellow)
        let color = InitialsAvatarColors.color(for: subscription.name)
        if color == InitialsAvatarColors.green || color == InitialsAvatarColors.yellow {
            return Theme.Colors.feedPrimaryText
        }
        return .white
    }
}

// MARK: - Feed Shared Subscription Row

/// Compact shared subscription row matching FeedTransactionRow style
/// Layout: 40x40 avatar | Name (14pt semibold) + Next Billing (12pt) | Amount (14pt semibold) + Payer (12pt)
struct FeedSharedSubscriptionRow: View {
    let sharedSubscription: SharedSubscription
    let people: [Person]
    let subscription: Subscription?  // Optional linked subscription for name/date
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 40

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 10) {
                // Avatar - initials with colored background
                initialsAvatar

                // Left side - Name and Next Billing
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                        .lineLimit(1)

                    Text(nextBillingText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }

                Spacer(minLength: 8)

                // Right side - Amount and Payer
                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayAmount)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)

                    Text(payerLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(displayName), \(displayAmount), \(payerLabel)")
    }

    // MARK: - Computed Properties

    private var displayName: String {
        // Use subscription name if available, otherwise use notes
        if let subscription = subscription {
            return subscription.name
        }
        return sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes
    }

    private var nextBillingText: String {
        if let subscription = subscription {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: subscription.nextBillingDate)
        }
        return "Shared"
    }

    private var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: sharedSubscription.individualCost)) ?? "$0.00"
    }

    private var payerLabel: String {
        if let person = people.first(where: { $0.id == sharedSubscription.sharedBy }) {
            return person.name
        }
        return "Shared"
    }

    // MARK: - Avatar

    private var initialsAvatar: some View {
        Circle()
            .fill(InitialsAvatarColors.color(for: displayName))
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: displayName))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(avatarTextColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }

    private var avatarTextColor: Color {
        // Use dark text on light backgrounds (green, yellow)
        let color = InitialsAvatarColors.color(for: displayName)
        if color == InitialsAvatarColors.green || color == InitialsAvatarColors.yellow {
            return Theme.Colors.feedPrimaryText
        }
        return .white
    }
}

// MARK: - Preview

#Preview("FeedSubscriptionRow - Personal") {
    VStack(spacing: 0) {
        FeedSubscriptionRow(
            subscription: Subscription(
                name: "Netflix",
                description: "Streaming service",
                price: 15.99,
                billingCycle: .monthly,
                category: .entertainment
            ),
            people: []
        )
        .padding(.horizontal, 16)

        FeedRowDivider()

        FeedSubscriptionRow(
            subscription: Subscription(
                name: "Spotify",
                description: "Music streaming",
                price: 9.99,
                billingCycle: .monthly,
                category: .music
            ),
            people: []
        )
        .padding(.horizontal, 16)

        FeedRowDivider()

        FeedSubscriptionRow(
            subscription: Subscription(
                name: "iCloud+",
                description: "Cloud storage",
                price: 2.99,
                billingCycle: .monthly,
                category: .cloud
            ),
            people: []
        )
        .padding(.horizontal, 16)
    }
    .background(Color.white)
}

#Preview("FeedSubscriptionRow - Shared") {
    VStack(spacing: 0) {
        FeedSubscriptionRow(
            subscription: {
                var sub = Subscription(
                    name: "Disney+",
                    description: "Streaming",
                    price: 13.99,
                    billingCycle: .monthly,
                    category: .entertainment
                )
                sub.isShared = true
                sub.sharedWith = [UUID()]
                return sub
            }(),
            people: [Person(name: "John Smith", email: "john@example.com", phone: "", avatar: "👤")]
        )
        .padding(.horizontal, 16)
    }
    .background(Color.white)
}
