//
//  SubscriptionCard.swift
//  Swiff IOS
//
//  Clean row-based subscription display with initials avatar
//  Updated to match new unified list design
//

import SwiftUI

// MARK: - Subscription Card

/// Clean row-based subscription display with initials-based avatar.
/// Shows colored circle with initials, name, billing cycle, price, and next billing date.
/// Design: 44x44 avatar, 14pt gap, clean row without status badges.
struct SubscriptionCard: View {
    let subscription: Subscription
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var initials: String {
        InitialsGenerator.generate(from: subscription.name)
    }

    private var avatarColor: Color {
        // Use subscription category's pastel color
        subscription.category.pastelAvatarColor
    }

    private var priceText: String {
        String(format: "$%.2f", subscription.price)
    }

    private var formattedPriceWithSign: String {
        "- " + priceText
    }

    private var amountColor: Color {
        AmountColors.negative
    }

    private var nextBillingText: String {
        if !subscription.isActive {
            return subscription.cancellationDate != nil ? "Cancelled" : "Paused"
        }
        return subscription.nextBillingDate.shortCardDate
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 14) {
                // Initials avatar (no status badge)
                initialsAvatar

                // Name and billing cycle
                VStack(alignment: .leading, spacing: 3) {
                    Text(subscription.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subscription.billingCycle.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                        .lineLimit(1)
                }

                Spacer()

                // Price and next billing
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formattedPriceWithSign)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(amountColor)

                    Text(nextBillingText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Initials Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - SubscriptionCategory Pastel Color Extension

extension SubscriptionCategory {
    /// Pastel avatar color for the new unified list design
    var pastelAvatarColor: Color {
        switch self {
        case .entertainment, .music, .gaming:
            return InitialsAvatarColors.purple
        case .productivity, .development, .design:
            return InitialsAvatarColors.gray
        case .fitness, .health:
            return InitialsAvatarColors.pink
        case .education:
            return InitialsAvatarColors.yellow
        case .news:
            return InitialsAvatarColors.gray
        case .cloud, .finance:
            return InitialsAvatarColors.green
        case .utilities:
            return InitialsAvatarColors.yellow
        case .other:
            return InitialsAvatarColors.gray
        }
    }
}

// MARK: - Preview

#Preview("SubscriptionCard - New Design") {
    VStack(spacing: 0) {
        // Adobe Creative Cloud
        SubscriptionCard(
            subscription: Subscription(
                name: "Adobe Creative Cloud",
                description: "Design software",
                price: 54.99,
                billingCycle: .monthly,
                category: .productivity,
                icon: "paintbrush.fill",
                color: "#FF6B6B"
            )
        )

        AlignedDivider()

        // Duolingo Plus
        SubscriptionCard(
            subscription: Subscription(
                name: "Duolingo Plus",
                description: "Language learning",
                price: 6.99,
                billingCycle: .monthly,
                category: .education,
                icon: "book.fill",
                color: "#58CC02"
            )
        )

        AlignedDivider()

        // Gym Membership
        SubscriptionCard(
            subscription: Subscription(
                name: "Gym Membership",
                description: "Fitness center",
                price: 49.99,
                billingCycle: .monthly,
                category: .fitness,
                icon: "figure.run",
                color: "#FF7F50"
            )
        )

        AlignedDivider()

        // HBO Max
        SubscriptionCard(
            subscription: Subscription(
                name: "HBO Max",
                description: "Streaming service",
                price: 15.99,
                billingCycle: .monthly,
                category: .entertainment,
                icon: "play.rectangle.fill",
                color: "#9B59B6"
            )
        )

        AlignedDivider()

        // LinkedIn Premium
        SubscriptionCard(
            subscription: Subscription(
                name: "LinkedIn Premium",
                description: "Professional network",
                price: 29.99,
                billingCycle: .monthly,
                category: .productivity,
                icon: "briefcase.fill",
                color: "#0077B5"
            )
        )

        AlignedDivider()

        // Netflix
        SubscriptionCard(
            subscription: Subscription(
                name: "Netflix",
                description: "Streaming service",
                price: 19.99,
                billingCycle: .monthly,
                category: .entertainment,
                icon: "tv.fill",
                color: "#E50914"
            )
        )
    }
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.wiseBackground)
}
