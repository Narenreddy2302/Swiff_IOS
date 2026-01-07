//
//  FeedSubscriptionRow.swift
//  Swiff IOS
//
//  Compact subscription row for feed-style display
//  Layout: 40x40 avatar | Name + Next Billing | Amount + Payer
//

import SwiftUI

// MARK: - Feed Subscription Row

/// Subscription row matching reference design
/// Layout: 48x48 avatar | Name (15pt semibold) + Cycle · Next: Date (13pt) | Amount (15pt semibold) + Payer (13pt)
struct FeedSubscriptionRow: View {
    let subscription: Subscription
    let people: [Person]
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 14) {
            // Avatar - initials with colored background
            initialsAvatar

            // Left side - Name and Cycle + Next Billing
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.feedPrimaryText)
                    .lineLimit(1)

                Text(cycleAndNextBillingText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            }

            Spacer(minLength: 8)

            // Right side - Amount and Payer
            VStack(alignment: .trailing, spacing: 4) {
                Text(displayAmount)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.feedPrimaryText)

                Text(payerLabel)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(subscription.name), \(displayAmount), \(payerLabel)")
    }

    // MARK: - Computed Properties

    private var cycleAndNextBillingText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: subscription.nextBillingDate)
        return "\(subscription.billingCycle.displayName) · Next: \(dateStr)"
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
        let avatarColor = FeedAvatarColor.forName(subscription.name)
        return Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: subscription.name))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Feed Shared Subscription Row

/// Shared subscription row matching reference design
/// Layout: 48x48 avatar | Name (15pt) + Cycle · Next: Date (13pt) | Balance (15pt, colored) + Member Avatars
struct FeedSharedSubscriptionRow: View {
    let sharedSubscription: SharedSubscription
    let people: [Person]
    let subscription: Subscription?  // Optional linked subscription for name/date
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 14) {
            // Avatar - initials with colored background
            initialsAvatar

            // Left side - Name and Cycle + Next Billing
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.feedPrimaryText)
                    .lineLimit(1)

                Text(cycleAndNextBillingText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            }

            Spacer(minLength: 8)

            // Right side - Balance and Member Avatars
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedBalance)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(balanceColor)

                SharedMembersAvatarStack(
                    members: sharedSubscription.members
                )
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(displayName), \(formattedBalance)")
    }

    // MARK: - Computed Properties

    private var displayName: String {
        // Use subscription name if available, otherwise use notes
        if let subscription = subscription {
            return subscription.name
        }
        return sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes
    }

    private var cycleAndNextBillingText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: sharedSubscription.nextBillingDate)
        return "\(sharedSubscription.billingCycle.displayName) · Next: \(dateStr)"
    }

    private var formattedBalance: String {
        let balance = sharedSubscription.balance
        if balance > 0 {
            return String(format: "+$%.2f", balance)
        } else if balance < 0 {
            return String(format: "-$%.2f", abs(balance))
        }
        return "$0.00"
    }

    private var balanceColor: Color {
        switch sharedSubscription.balanceStatus {
        case .owesYou:
            return Color(red: 0.020, green: 0.588, blue: 0.412)  // Green
        case .youOwe:
            return Theme.Colors.feedPrimaryText  // Primary text color
        case .settled:
            return Theme.Colors.feedSecondaryText  // Tertiary/secondary color
        }
    }

    // MARK: - Avatar

    private var initialsAvatar: some View {
        let avatarColor = FeedAvatarColor.forName(displayName)
        return Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: displayName))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Shared Members Avatar Stack

/// Stacked member avatars for shared subscription rows
/// Shows up to 3 members with overlapping avatars, and "+N" for extras
struct SharedMembersAvatarStack: View {
    let members: [SharedMember]
    let maxVisible: Int = 3

    private let avatarSize: CGFloat = 20

    var body: some View {
        HStack(spacing: -6) {
            ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.offset) { index, member in
                memberAvatar(for: member)
                    .zIndex(Double(maxVisible - index))  // Ensure proper overlapping order
            }

            if members.count > maxVisible {
                Text("+\(members.count - maxVisible)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
                    .padding(.leading, 8)
            }
        }
    }

    private func memberAvatar(for member: SharedMember) -> some View {
        let avatarColor = FeedAvatarColor.forName(member.name)
        return Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(member.initials)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
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
