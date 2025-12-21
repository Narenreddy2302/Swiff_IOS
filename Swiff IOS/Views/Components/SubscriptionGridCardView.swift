//
//  SubscriptionGridCardView.swift
//  Swiff IOS
//
//  Modern grid card for subscription display
//

import SwiftUI

// MARK: - Subscription Grid Card View

/// Modern grid card view for displaying subscriptions in a 2-column grid layout.
/// Features rounded rectangle icon, service name, price, and status badge.
struct SubscriptionGridCardView: View {
    let subscription: Subscription

    // MARK: - Computed Properties

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

    private var iconBackgroundColor: Color {
        Color(hexString: subscription.color)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App Icon - Rounded Rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(iconBackgroundColor)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: subscription.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                )

            Spacer()

            // Service Name
            Text(subscription.name)
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)

            // Price with billing cycle
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "$%.2f", subscription.price))
                    .font(.spotifyNumberLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.wisePrimaryText)

                Text("per \(subscription.billingCycle.shortName)")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            // Status/Trial Badge (compact)
            if subscription.isFreeTrial {
                trialBadge
            } else {
                statusBadge
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .background(Color.wiseCardBackground)
        .cornerRadius(20)
        .cardShadow()
    }

    // MARK: - Badges

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.spotifyCaptionSmall)
                .foregroundColor(statusColor)
        }
    }

    private var trialBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 10))
            Text(subscription.trialStatus)
                .font(.spotifyCaptionSmall)
        }
        .foregroundColor(.wiseWarning)
    }
}

// MARK: - Preview

#Preview("Subscription Grid Cards - Active") {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            SubscriptionGridCardView(subscription: MockData.activeSubscription)
            SubscriptionGridCardView(subscription: MockData.sharedSubscription)
            SubscriptionGridCardView(subscription: MockData.cheapSubscription)
            SubscriptionGridCardView(subscription: MockData.yearlySubscription)
        }
        .padding(20)
    }
    .background(Color.wiseGroupedBackground)
}

#Preview("Subscription Grid Cards - Trial") {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            SubscriptionGridCardView(subscription: MockData.trialSubscription)
            SubscriptionGridCardView(subscription: MockData.expiredTrialSubscription)
        }
        .padding(20)
    }
    .background(Color.wiseGroupedBackground)
}

#Preview("Subscription Grid Cards - Inactive") {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            SubscriptionGridCardView(subscription: MockData.inactiveSubscription)
            SubscriptionGridCardView(subscription: MockData.subscriptionDueToday)
        }
        .padding(20)
    }
    .background(Color.wiseGroupedBackground)
}

#Preview("Subscription Grid Cards - Edge Cases") {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            SubscriptionGridCardView(subscription: MockData.expensiveSubscription)
            SubscriptionGridCardView(subscription: MockData.longNameSubscription)
        }
        .padding(20)
    }
    .background(Color.wiseGroupedBackground)
}
