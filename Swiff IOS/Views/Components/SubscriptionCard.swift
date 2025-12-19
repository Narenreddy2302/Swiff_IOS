//
//  SubscriptionCard.swift
//  Swiff IOS
//
//  Row-based subscription display with icon status indicator
//

import SwiftUI

// MARK: - Subscription Card

/// Row-based subscription display with icon status indicator.
/// Shows brand icon with status badge, name, billing cycle, price, and next billing.
struct SubscriptionCard: View {
    let subscription: Subscription
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var statusColor: Color {
        if !subscription.isActive {
            return subscription.cancellationDate != nil ? .wiseError : .wiseWarning
        }
        return .wiseSuccess
    }

    private var brandColor: Color {
        Color(hexString: subscription.color)
    }

    private var priceText: String {
        String(format: "$%.2f", subscription.price)
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
            HStack(spacing: 12) {
                // Icon with status indicator
                iconWithStatusIndicator

                // Name and billing cycle
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subscription.billingCycle.displayName)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                // Price and next billing
                VStack(alignment: .trailing, spacing: 4) {
                    Text(priceText)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text(nextBillingText)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Icon with Status Indicator

    private var iconWithStatusIndicator: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main icon circle (filled with brand color)
            Circle()
                .fill(brandColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: subscription.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(brandColor)
                )

            // Status indicator badge
            Circle()
                .fill(Color.wiseCardBackground)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .fill(statusColor)
                        .frame(width: 14, height: 14)
                )
                .offset(x: 2, y: 2)
        }
    }
}

// MARK: - Preview

#Preview("SubscriptionCard") {
    VStack(spacing: 0) {
        // Active subscription - Adobe Creative Cloud
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

        Divider()
            .padding(.leading, 76)

        // Active subscription - Duolingo Plus
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

        Divider()
            .padding(.leading, 76)

        // Active subscription - Gym Membership
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

        Divider()
            .padding(.leading, 76)

        // Active subscription - HBO Max
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

        Divider()
            .padding(.leading, 76)

        // Active subscription - LinkedIn Premium
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
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(16)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.wiseGroupedBackground)
}
