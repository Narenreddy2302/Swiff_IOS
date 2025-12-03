//
//  SubscriptionGridCardView.swift
//  Swiff IOS
//
//  Created for Page 4 Task Implementation
//

import SwiftUI

// MARK: - Subscription Grid Card View
struct SubscriptionGridCardView: View {
    let subscription: Subscription

    var statusColor: Color {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return .wiseError
            } else {
                return .wiseWarning
            }
        }
        return .wiseBrightGreen
    }

    var statusText: String {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return "Cancelled"
            } else {
                return "Paused"
            }
        }
        return "Active"
    }

    var daysUntilBilling: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: subscription.nextBillingDate)
        return max(components.day ?? 0, 0)
    }

    var countdownText: String {
        if subscription.billingCycle == .lifetime {
            return "Lifetime"
        }

        let days = daysUntilBilling
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "in \(days) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: subscription.nextBillingDate)
        }
    }

    var isExpiringSoon: Bool {
        return subscription.isActive && daysUntilBilling <= 7
    }

    var body: some View {
        VStack(spacing: 0) {
            // Card Content
            VStack(spacing: 12) {
                // Icon and Status Badge
                ZStack(alignment: .topLeading) {
                    // Large Icon with Gradient Background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hexString: subscription.color).opacity(0.3),
                                    Color(hexString: subscription.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: subscription.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(Color(hexString: subscription.color))
                        )

                    // AGENT 8: Trial Badge in top-left corner
                    if subscription.isFreeTrial {
                        TrialBadge(
                            daysRemaining: subscription.daysUntilTrialEnd,
                            isExpired: subscription.isTrialExpired
                        )
                        .offset(x: -8, y: -4)
                    } else {
                        // Status Badge (for non-trial)
                        HStack(spacing: 3) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(statusColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.15))
                        )
                        .offset(x: -8, y: -4)
                    }
                }
                .padding(.top, 12)

                // Subscription Name
                Text(subscription.name)
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wisePrimaryText)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                // Price and Billing Cycle
                VStack(spacing: 2) {
                    Text(String(format: "$%.2f", subscription.price))
                        .font(.spotifyNumberLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.wisePrimaryText)

                    Text("per \(subscription.billingCycle.shortName)")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                // AGENT 8: Trial Countdown (show instead of next billing for trials)
                if subscription.isFreeTrial {
                    TrialCountdown(
                        daysRemaining: subscription.daysUntilTrialEnd,
                        isExpired: subscription.isTrialExpired
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.wiseWarning.opacity(0.15))
                    )
                } else if subscription.isActive {
                    // Countdown Badge for regular subscriptions
                    HStack(spacing: 4) {
                        Image(systemName: isExpiringSoon ? "exclamationmark.circle.fill" : "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(isExpiringSoon ? .wiseError : .wiseSecondaryText)

                        Text(countdownText)
                            .font(.spotifyCaptionSmall)
                            .fontWeight(.medium)
                            .foregroundColor(isExpiringSoon ? .wiseError : .wiseSecondaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isExpiringSoon ? Color.wiseError.opacity(0.1) : Color.wiseBorder.opacity(0.5))
                    )
                }

                // Shared Indicator
                if subscription.isShared {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("Shared")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.wiseBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseBlue.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
        )
        .cardShadow()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    var subscription = Subscription(
        name: "Netflix",
        description: "Streaming Service",
        price: 15.99,
        billingCycle: .monthly,
        category: .entertainment,
        icon: "play.tv.fill",
        color: "#E50914"
    )
    subscription.nextBillingDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    subscription.isActive = true
    subscription.isShared = true
    subscription.totalSpent = 159.90

    return SubscriptionGridCardView(subscription: subscription)
        .frame(width: 180)
        .padding()
}
