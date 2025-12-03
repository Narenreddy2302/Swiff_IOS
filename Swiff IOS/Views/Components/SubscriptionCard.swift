//
//  SubscriptionCard.swift
//  Swiff IOS
//
//  Card-based subscription display (list variant)
//

import SwiftUI

// MARK: - Subscription Card

/// Card-based subscription display for list views.
/// Shows status: "Active • Monthly • Next: Dec 15"
struct SubscriptionCard: View {
    let subscription: Subscription
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var statusColor: Color {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return .wiseError
            } else {
                return .wiseWarning
            }
        }
        return .wiseBrightGreen
    }

    private var statusText: String {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return "Cancelled"
            } else {
                return "Paused"
            }
        }
        return "Active"
    }

    private var priceText: String {
        String(format: "$%.2f", subscription.price)
    }

    private var nextBillingText: String {
        subscription.nextBillingDate.shortCardDate
    }

    private var brandColor: Color {
        Color(hexString: subscription.color)
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Brand Icon Circle (outlined)
                OutlinedIconCircle(
                    icon: subscription.icon,
                    color: brandColor,
                    size: 48,
                    strokeWidth: 2,
                    iconSize: 20
                )

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    // Subscription Name
                    Text(subscription.name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    // Status Line
                    HStack(spacing: 4) {
                        Text(statusText)
                            .font(.spotifyBodySmall)
                            .foregroundColor(statusColor)

                        Text("•")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(subscription.billingCycle.displayName)
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)

                        if subscription.isActive {
                            Text("•")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)

                            Text("Next: \(nextBillingText)")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Price
                Text(priceText)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Preview

#Preview("SubscriptionCard") {
    VStack(spacing: 12) {
        SubscriptionCard(
            subscription: Subscription(
                name: "Netflix",
                description: "Streaming service",
                price: 15.99,
                billingCycle: .monthly,
                category: .entertainment,
                icon: "tv.fill",
                color: "#E50914"
            )
        )
    }
    .padding()
    .background(Color.wiseGroupedBackground)
}
