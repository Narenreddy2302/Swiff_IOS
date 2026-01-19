//
//  SubscriptionCard.swift
//  Swiff IOS
//
//  Row-based subscription display with initials avatar
//  Updated to match TransactionCard design pattern
//

import SwiftUI

// MARK: - Subscription Card

/// Row-based subscription display with initials-based avatar.
/// Shows colored circle with initials, name, billing cycle, price, and next billing date.
/// Design: 56x56 avatar, 16pt spacing, matching TransactionCard layout.
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
        subscription.price.asCurrency
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
            HStack(spacing: 16) {
                // Initials avatar (larger size matching TransactionCard)
                initialsAvatar

                // Name and billing cycle
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(subscription.billingCycle.displayName)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                        .lineLimit(1)
                }

                Spacer()

                // Price and next billing
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedPriceWithSign)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(amountColor)

                    Text(nextBillingText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Initials Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 56, height: 56)

            Text(initials)
                .font(.system(size: 18, weight: .semibold))
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

