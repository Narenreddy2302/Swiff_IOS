//
//  SubscriptionGridCardView.swift
//  Swiff IOS
//
//  Grid card for subscription display
//  Updated to match TransactionCard design pattern with initials avatar
//

import SwiftUI

// MARK: - Subscription Grid Card View

/// Grid card view for displaying subscriptions in a 2-column grid layout.
/// Features circular initials avatar (matching TransactionCard), service name, price, and status badge.
struct SubscriptionGridCardView: View {
    let subscription: Subscription

    // MARK: - Computed Properties

    private var initials: String {
        InitialsGenerator.generate(from: subscription.name)
    }

    private var avatarColor: Color {
        subscription.category.pastelAvatarColor
    }

    private var statusColor: Color {
        if !subscription.isActive {
            return subscription.cancellationDate != nil ? .wiseError : .wiseWarning
        }
        return .wiseSuccess
    }

    private var statusText: String {
        if !subscription.isActive {
            return subscription.cancellationDate != nil ? "Cancelled" : "Paused"
        }
        return "Active"
    }

    // MARK: - Body

    var body: some View {
        SwiffCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Initials Avatar - matching TransactionCard style
                initialsAvatar

                Spacer()

                // Service Name
                Text(subscription.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                // Price with billing cycle
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.price.asCurrency)
                        .font(.spotifyNumberLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.wisePrimaryText)

                    Text("per \(subscription.billingCycle.shortName)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.wiseSecondaryText)
                }

                // Status/Trial Badge (compact)
                if subscription.isFreeTrial {
                    trialBadge
                } else {
                    statusBadge
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
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

    // MARK: - Badges

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(statusColor)
        }
    }

    private var trialBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
            Text(subscription.trialStatus)
                .font(.system(size: 15, weight: .regular))
        }
        .foregroundColor(.wiseWarning)
    }
}

