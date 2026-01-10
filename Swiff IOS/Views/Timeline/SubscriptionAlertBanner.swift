//
//  SubscriptionAlertBanner.swift
//  Swiff IOS
//
//  Created by Claude Code on 12/20/25.
//  Alert banner component for subscription-specific alerts in timeline
//

import SwiftUI

struct SubscriptionAlertBanner: View {
    let alertType: SubscriptionAlertType
    let subscription: Subscription

    enum SubscriptionAlertType {
        case paymentDue(daysUntil: Int)
        case trialEnding(daysLeft: Int)
        case priceIncreased(oldPrice: Double, newPrice: Double)

        var icon: String {
            switch self {
            case .paymentDue:
                return "calendar"
            case .trialEnding:
                return "clock"
            case .priceIncreased:
                return "arrow.up"
            }
        }

        var backgroundColor: Color {
            switch self {
            case .paymentDue:
                return Color.blue.opacity(0.15)
            case .trialEnding:
                return Color.orange.opacity(0.15)
            case .priceIncreased:
                return Color.red.opacity(0.15)
            }
        }

        var iconColor: Color {
            switch self {
            case .paymentDue:
                return .blue
            case .trialEnding:
                return .orange
            case .priceIncreased:
                return .red
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(alertType.iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: alertType.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(alertType.iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Text(subtitleText)
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(alertType.iconColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var titleText: String {
        switch alertType {
        case .paymentDue(let daysUntil):
            if daysUntil == 0 {
                return "Payment due today"
            } else if daysUntil == 1 {
                return "Payment due tomorrow"
            } else {
                return "Payment due in \(daysUntil) days"
            }

        case .trialEnding:
            return "Free trial ending"

        case .priceIncreased:
            return "Price increased"
        }
    }

    private var subtitleText: String {
        switch alertType {
        case .paymentDue:
            return "Amount: \(formatCurrency(subscription.price))"

        case .trialEnding(let daysLeft):
            let afterPrice = subscription.priceAfterTrial ?? subscription.price
            let cycle = subscription.billingCycle.displayName.lowercased()

            if daysLeft == 0 {
                return "Ends today • \(formatCurrency(afterPrice))/\(cycle) after trial"
            } else if daysLeft == 1 {
                return "1 day left • \(formatCurrency(afterPrice))/\(cycle) after trial"
            } else {
                return "\(daysLeft) days left • \(formatCurrency(afterPrice))/\(cycle) after trial"
            }

        case .priceIncreased(let oldPrice, let newPrice):
            let percentIncrease = ((newPrice - oldPrice) / oldPrice) * 100
            return "\(formatCurrency(oldPrice)) → \(formatCurrency(newPrice)) (+\(String(format: "%.0f", percentIncrease))%)"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

#Preview {
    VStack(spacing: 16) {
        // Payment Due - Tomorrow
        SubscriptionAlertBanner(
            alertType: .paymentDue(daysUntil: 1),
            subscription: Subscription(
                name: "Netflix",
                description: "Premium plan",
                price: 54.99,
                billingCycle: .monthly,
                category: .entertainment
            )
        )

        // Payment Due - In 3 days
        SubscriptionAlertBanner(
            alertType: .paymentDue(daysUntil: 3),
            subscription: Subscription(
                name: "Spotify",
                description: "Family plan",
                price: 16.99,
                billingCycle: .monthly,
                category: .entertainment
            )
        )

        // Trial Ending - 7 days
        SubscriptionAlertBanner(
            alertType: .trialEnding(daysLeft: 7),
            subscription: {
                var sub = Subscription(
                    name: "Adobe Creative Cloud",
                    description: "All apps",
                    price: 59.99,
                    billingCycle: .monthly,
                    category: .productivity
                )
                sub.isFreeTrial = true
                sub.priceAfterTrial = 59.99
                return sub
            }()
        )

        // Trial Ending - 1 day
        SubscriptionAlertBanner(
            alertType: .trialEnding(daysLeft: 1),
            subscription: {
                var sub = Subscription(
                    name: "Notion",
                    description: "Plus plan",
                    price: 10.00,
                    billingCycle: .monthly,
                    category: .productivity
                )
                sub.isFreeTrial = true
                sub.priceAfterTrial = 10.00
                return sub
            }()
        )

        // Price Increase
        SubscriptionAlertBanner(
            alertType: .priceIncreased(oldPrice: 49.99, newPrice: 54.99),
            subscription: Subscription(
                name: "YouTube Premium",
                description: "Individual plan",
                price: 54.99,
                billingCycle: .monthly,
                category: .entertainment
            )
        )

        // Price Increase - Higher percentage
        SubscriptionAlertBanner(
            alertType: .priceIncreased(oldPrice: 9.99, newPrice: 12.99),
            subscription: Subscription(
                name: "Apple Music",
                description: "Individual plan",
                price: 12.99,
                billingCycle: .monthly,
                category: .entertainment
            )
        )
    }
    .padding()
    .background(Color.wiseBackground)
}
