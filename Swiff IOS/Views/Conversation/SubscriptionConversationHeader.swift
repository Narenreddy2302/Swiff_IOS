//
//  SubscriptionConversationHeader.swift
//  Swiff IOS
//
//  Compact header for subscription conversation view
//  Uses BaseConversationHeader for consistent styling
//

import SwiftUI

struct SubscriptionConversationHeader: View {
    let subscription: Subscription
    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        BaseConversationHeader(
            onBack: onBack,
            leading: {
                subscriptionIcon
            },
            title: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(Theme.Fonts.headerTitle)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    priceAndStatusView
                }
            },
            trailing: {
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Text("Edit")
                            .textActionButtonStyle()
                    }
                }
            }
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private var priceAndStatusView: some View {
        HStack(spacing: 6) {
            Text(priceText)
                .font(Theme.Fonts.headerSubtitle)
                .foregroundColor(.wiseSecondaryText)

            if !subscription.isActive {
                statusIndicator
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if subscription.cancellationDate != nil {
            SubscriptionStatusPill(status: .cancelled)
        } else {
            SubscriptionStatusPill(status: .paused)
        }
    }

    private var subscriptionIcon: some View {
        ZStack {
            Circle()
                .fill(subscription.category.pastelAvatarColor)
                .frame(width: Theme.Metrics.avatarStandard, height: Theme.Metrics.avatarStandard)

            Text(InitialsGenerator.generate(from: subscription.name))
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(.wisePrimaryText)
        }
    }

    // MARK: - Computed Properties

    private var priceText: String {
        "\(subscription.price.asCurrency)/\(subscription.billingCycle.displayShort)"
    }
}

// MARK: - Status Pill Component

/// Reusable subscription status pill
struct SubscriptionStatusPill: View {
    enum Status {
        case cancelled
        case paused

        var text: String {
            switch self {
            case .cancelled: return "Cancelled"
            case .paused: return "Paused"
            }
        }

        var color: Color {
            switch self {
            case .cancelled: return .wiseError
            case .paused: return .wiseWarning
            }
        }
    }

    let status: Status

    var body: some View {
        Text(status.text)
            .font(Theme.Fonts.badgeText)
            .foregroundColor(status.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.1))
            .cornerRadius(Theme.Metrics.cornerRadiusSmall / 2)
    }
}

