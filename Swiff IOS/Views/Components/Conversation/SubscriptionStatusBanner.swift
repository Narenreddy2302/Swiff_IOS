//
//  SubscriptionStatusBanner.swift
//  Swiff IOS
//
//  Alert banner for subscription-specific alerts
//  Shows trial endings, price increases, upcoming payments, and paused status
//

import SwiftUI

// MARK: - Subscription Alert Type

enum SubscriptionAlertType {
    case trialEnding(daysLeft: Int, priceAfter: Double)
    case priceIncreased(newPrice: Double, increasePercent: Double)
    case paymentUpcoming(daysUntil: Int, amount: Double)
    case subscriptionPaused

    var icon: String {
        switch self {
        case .trialEnding:
            return "clock.badge.exclamationmark"
        case .priceIncreased:
            return "arrow.up.circle.fill"
        case .paymentUpcoming:
            return "calendar.badge.clock"
        case .subscriptionPaused:
            return "pause.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .trialEnding:
            return .wiseWarning
        case .priceIncreased:
            return .wiseError
        case .paymentUpcoming:
            return .wiseBlue
        case .subscriptionPaused:
            return .wiseWarning
        }
    }

    var title: String {
        switch self {
        case .trialEnding(let daysLeft, _):
            if daysLeft == 0 {
                return "Trial ending today"
            } else if daysLeft == 1 {
                return "Trial ending tomorrow"
            } else {
                return "Trial ending in \(daysLeft) days"
            }
        case .priceIncreased(_, let percent):
            return String(format: "Price increased by %.0f%%", percent)
        case .paymentUpcoming(let daysUntil, _):
            if daysUntil == 0 {
                return "Payment due today"
            } else if daysUntil == 1 {
                return "Payment due tomorrow"
            } else {
                return "Payment due in \(daysUntil) days"
            }
        case .subscriptionPaused:
            return "Subscription paused"
        }
    }

    var subtitle: String {
        switch self {
        case .trialEnding(_, let priceAfter):
            return String(format: "You'll be charged $%.2f after trial ends", priceAfter)
        case .priceIncreased(let newPrice, _):
            return String(format: "New price: $%.2f", newPrice)
        case .paymentUpcoming(_, let amount):
            return String(format: "Amount: $%.2f", amount)
        case .subscriptionPaused:
            return "Resume to continue billing"
        }
    }

    var actionButtonTitle: String? {
        switch self {
        case .trialEnding:
            return "Cancel Trial"
        case .priceIncreased:
            return "Review"
        case .paymentUpcoming:
            return nil
        case .subscriptionPaused:
            return "Resume"
        }
    }
}

// MARK: - Subscription Status Banner

struct SubscriptionStatusBanner: View {
    let alert: SubscriptionAlertType
    var onAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Warning icon
                Circle()
                    .fill(alert.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: alert.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(alert.color)
                    )

                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)

                    Text(alert.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.wiseSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            // Optional action button
            if let buttonTitle = alert.actionButtonTitle, let action = onAction {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(buttonTitle)
                            .font(.spotifyLabelMedium)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(alert.color)
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(alert.color.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(alert.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Trial Ending") {
    ScrollView {
        VStack(spacing: 16) {
            SubscriptionStatusBanner(
                alert: .trialEnding(daysLeft: 3, priceAfter: 9.99),
                onAction: {
                    print("Cancel trial tapped")
                }
            )

            SubscriptionStatusBanner(
                alert: .trialEnding(daysLeft: 1, priceAfter: 14.99)
            )

            SubscriptionStatusBanner(
                alert: .trialEnding(daysLeft: 0, priceAfter: 19.99)
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("Price Increased") {
    ScrollView {
        VStack(spacing: 16) {
            SubscriptionStatusBanner(
                alert: .priceIncreased(newPrice: 12.99, increasePercent: 30),
                onAction: {
                    print("Review tapped")
                }
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("Payment Upcoming") {
    ScrollView {
        VStack(spacing: 16) {
            SubscriptionStatusBanner(
                alert: .paymentUpcoming(daysUntil: 3, amount: 9.99)
            )

            SubscriptionStatusBanner(
                alert: .paymentUpcoming(daysUntil: 1, amount: 14.99)
            )

            SubscriptionStatusBanner(
                alert: .paymentUpcoming(daysUntil: 0, amount: 19.99)
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("Subscription Paused") {
    ScrollView {
        VStack(spacing: 16) {
            SubscriptionStatusBanner(
                alert: .subscriptionPaused,
                onAction: {
                    print("Resume tapped")
                }
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
