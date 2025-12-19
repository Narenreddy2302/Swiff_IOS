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

#Preview("Subscription Grid Cards") {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            // Active subscription - Spotify
            SubscriptionGridCardView(
                subscription: {
                    var sub = Subscription(
                        name: "Spotify",
                        description: "Music Streaming",
                        price: 5.99,
                        billingCycle: .monthly,
                        category: .music,
                        icon: "waveform",
                        color: "#1DB954"
                    )
                    sub.isActive = true
                    return sub
                }()
            )

            // Active subscription - YouTube
            SubscriptionGridCardView(
                subscription: {
                    var sub = Subscription(
                        name: "YouTube Premium",
                        description: "Video Streaming",
                        price: 18.99,
                        billingCycle: .monthly,
                        category: .entertainment,
                        icon: "play.fill",
                        color: "#FF0000"
                    )
                    sub.isActive = true
                    return sub
                }()
            )

            // Active subscription - Netflix
            SubscriptionGridCardView(
                subscription: {
                    var sub = Subscription(
                        name: "Netflix",
                        description: "Streaming Service",
                        price: 15.99,
                        billingCycle: .monthly,
                        category: .entertainment,
                        icon: "play.rectangle.fill",
                        color: "#E50914"
                    )
                    sub.isActive = true
                    return sub
                }()
            )

            // Active subscription - iCloud
            SubscriptionGridCardView(
                subscription: {
                    var sub = Subscription(
                        name: "iCloud",
                        description: "Cloud Storage",
                        price: 2.99,
                        billingCycle: .monthly,
                        category: .cloud,
                        icon: "icloud.fill",
                        color: "#3395FF"
                    )
                    sub.isActive = true
                    return sub
                }()
            )

            // Paused subscription
            SubscriptionGridCardView(
                subscription: {
                    var sub = Subscription(
                        name: "Apple Music",
                        description: "Music Streaming",
                        price: 10.99,
                        billingCycle: .monthly,
                        category: .music,
                        icon: "music.note",
                        color: "#FC3C44"
                    )
                    sub.isActive = false
                    return sub
                }()
            )

            // Cancelled subscription
            SubscriptionGridCardView(
                subscription: {
                    var sub = Subscription(
                        name: "Disney+",
                        description: "Streaming Service",
                        price: 7.99,
                        billingCycle: .monthly,
                        category: .entertainment,
                        icon: "sparkles.tv",
                        color: "#113CCF"
                    )
                    sub.isActive = false
                    sub.cancellationDate = Date()
                    return sub
                }()
            )
        }
        .padding(20)
    }
    .background(Color.wiseGroupedBackground)
}
