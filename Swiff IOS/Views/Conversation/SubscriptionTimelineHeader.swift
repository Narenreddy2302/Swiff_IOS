//
//  SubscriptionTimelineHeader.swift
//  Swiff IOS
//
//  Timeline header for subscription detail view
//  Shows subscription icon, name, price, status, and shared members
//

import SwiftUI

// MARK: - Subscription Timeline Header

struct SubscriptionTimelineHeader: View {
    let subscription: Subscription
    let sharedPeople: [Person]

    private var subscriptionColor: Color {
        Color(hexString: subscription.color)
    }

    private var statusColor: Color {
        if subscription.cancellationDate != nil {
            return .wiseError
        } else if !subscription.isActive {
            return .orange
        } else {
            return .wiseBrightGreen
        }
    }

    private var statusText: String {
        if subscription.cancellationDate != nil {
            return "Cancelled"
        } else if !subscription.isActive {
            return "Paused"
        } else {
            return "Active"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Subscription icon
            subscriptionIcon

            // Name and price
            VStack(spacing: 6) {
                Text(subscription.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .multilineTextAlignment(.center)

                Text(String(format: "$%.2f/%@", subscription.price, subscription.billingCycle.displayShort))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)

                // Show shared indicator below price
                if subscription.isShared && !sharedPeople.isEmpty {
                    HStack(spacing: 4) {
                        Text("Shared")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wisePurple)

                        Text("•")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(String(format: "$%.2f/person", subscription.costPerPerson))
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseBrightGreen)
                    }
                    .padding(.top, 2)
                }
            }

            // Status badge
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.spotifyLabelMedium)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.1))
            .cornerRadius(20)

            // Shared members (if applicable)
            if subscription.isShared && !sharedPeople.isEmpty {
                sharedMembersSection
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    // MARK: - Subscription Icon

    private var subscriptionIcon: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        subscriptionColor.opacity(0.3),
                        subscriptionColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 64, height: 64)
            .overlay(
                Image(systemName: subscription.icon)
                    .font(.system(size: 32))
                    .foregroundColor(subscriptionColor)
            )
    }

    // MARK: - Shared Members Section

    private var sharedMembersSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)

                Text("Shared with \(sharedPeople.count) \(sharedPeople.count == 1 ? "person" : "people")")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            MemberAvatarStack(
                people: sharedPeople,
                maxVisible: 4,
                avatarSize: 32,
                overlap: 8
            )

            Text(String(format: "$%.2f per person", subscription.costPerPerson))
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseBrightGreen)
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview

#Preview("Subscription Timeline Header") {
    ScrollView {
        VStack(spacing: 32) {
            // Active subscription
            SubscriptionTimelineHeader(
                subscription: Subscription(
                    name: "Spotify Premium",
                    description: "Music streaming",
                    price: 10.99,
                    billingCycle: .monthly,
                    category: .music,
                    icon: "music.note",
                    color: "#1DB954"
                ),
                sharedPeople: []
            )

            Divider()

            // Shared subscription
            SubscriptionTimelineHeader(
                subscription: {
                    var sub = Subscription(
                        name: "Netflix",
                        description: "Streaming service",
                        price: 19.99,
                        billingCycle: .monthly,
                        category: .entertainment,
                        icon: "tv.fill",
                        color: "#E50914"
                    )
                    sub.isShared = true
                    sub.sharedWith = [UUID(), UUID(), UUID()]
                    return sub
                }(),
                sharedPeople: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2))
                ]
            )

            Divider()

            // Paused subscription
            SubscriptionTimelineHeader(
                subscription: {
                    var sub = Subscription(
                        name: "Adobe Creative Cloud",
                        description: "Design tools",
                        price: 54.99,
                        billingCycle: .monthly,
                        category: .design,
                        icon: "paintbrush.fill",
                        color: "#FF0000"
                    )
                    sub.isActive = false
                    return sub
                }(),
                sharedPeople: []
            )

            Divider()

            // Cancelled subscription
            SubscriptionTimelineHeader(
                subscription: {
                    var sub = Subscription(
                        name: "Gym Membership",
                        description: "Fitness center",
                        price: 49.99,
                        billingCycle: .monthly,
                        category: .fitness,
                        icon: "figure.run",
                        color: "#FF6B35"
                    )
                    sub.cancellationDate = Date()
                    return sub
                }(),
                sharedPeople: []
            )
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}
