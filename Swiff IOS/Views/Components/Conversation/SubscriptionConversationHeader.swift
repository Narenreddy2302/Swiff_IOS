//
//  SubscriptionConversationHeader.swift
//  Swiff IOS
//
//  Compact header for subscription conversation view
//  70pt height with icon, name, price, status, and quick actions
//

import SwiftUI

struct SubscriptionConversationHeader: View {
    let subscription: Subscription
    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Back button (plain chevron - matches conversation-style reference)
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                }
            }

            // Subscription info (name + price/status)
            VStack(alignment: .leading, spacing: 1) {
                Text(subscription.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                // Price + billing cycle and status
                priceAndStatusView
            }

            Spacer()

            // Edit button (if provided)
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.wiseForestGreen)
                }
            }

            // Subscription icon on right (matching avatar position)
            subscriptionIcon
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 70)
        .background(Color.wiseCardBackground)
        .overlay(
            Rectangle()
                .fill(Color.wiseBorder)
                .frame(height: 1)
            , alignment: .bottom
        )
    }

    @ViewBuilder
    private var priceAndStatusView: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Price with billing cycle
            Text("$\(String(format: "%.2f", subscription.price))/\(subscription.billingCycle.displayShort)")
                .font(.system(size: 12))
                .foregroundColor(.wiseSecondaryText)

            // Status indicator
            statusIndicator
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if subscription.isActive {
            // Active status - green dot
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.wiseBrightGreen)
                    .frame(width: 6, height: 6)
                Text("Active")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
        } else if subscription.cancellationDate != nil {
            // Cancelled status - red dot
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.wiseError)
                    .frame(width: 6, height: 6)
                Text("Cancelled")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
        } else {
            // Paused status - orange dot
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.wiseWarning)
                    .frame(width: 6, height: 6)
                Text("Paused")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
        }
    }

    private var subscriptionIcon: some View {
        ZStack {
            Circle()
                .fill(subscription.category.pastelAvatarColor)
                .frame(width: 48, height: 48)

            Text(InitialsGenerator.generate(from: subscription.name))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - Preview

#Preview("SubscriptionConversationHeader - Active") {
    SubscriptionConversationHeader(
        subscription: Subscription(
            name: "Netflix",
            description: "Streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment
        )
    )
    .background(Color.wiseBackground)
}

#Preview("SubscriptionConversationHeader - Paused") {
    var pausedSubscription = Subscription(
        name: "Spotify Premium",
        description: "Music streaming",
        price: 9.99,
        billingCycle: .monthly,
        category: .music
    )
    pausedSubscription.isActive = false

    return SubscriptionConversationHeader(
        subscription: pausedSubscription
    )
    .background(Color.wiseBackground)
}

#Preview("SubscriptionConversationHeader - Cancelled") {
    var cancelledSubscription = Subscription(
        name: "Adobe Creative Cloud",
        description: "Creative suite",
        price: 54.99,
        billingCycle: .monthly,
        category: .design
    )
    cancelledSubscription.isActive = false
    cancelledSubscription.cancellationDate = Date()

    return SubscriptionConversationHeader(
        subscription: cancelledSubscription
    )
    .background(Color.wiseBackground)
}

#Preview("SubscriptionConversationHeader - With Edit") {
    SubscriptionConversationHeader(
        subscription: Subscription(
            name: "GitHub Copilot",
            description: "AI pair programmer",
            price: 10.00,
            billingCycle: .monthly,
            category: .development
        ),
        onEdit: {}
    )
    .background(Color.wiseBackground)
}

#Preview("SubscriptionConversationHeader - Long Name") {
    SubscriptionConversationHeader(
        subscription: Subscription(
            name: "Microsoft Office 365 Personal Subscription",
            description: "Productivity suite",
            price: 69.99,
            billingCycle: .yearly,
            category: .productivity
        )
    )
    .background(Color.wiseBackground)
}
