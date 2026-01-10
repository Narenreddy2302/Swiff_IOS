//
//  SubscriptionBillingSummaryCard.swift
//  Swiff IOS
//
//  Hero card for subscription billing summary
//  Consolidates Overview, Spending Stats, and Reminder controls
//

import SwiftUI

// MARK: - Subscription Billing Summary Card

struct SubscriptionBillingSummaryCard: View {
    let subscription: Subscription

    // MARK: - Computed Properties

    private var daysUntilBilling: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day
            ?? 0
    }

    private var subscriptionStatus: SubscriptionStatusType {
        if subscription.cancellationDate != nil {
            return .cancelled
        } else if !subscription.isActive {
            return .paused
        } else if subscription.isFreeTrial {
            return .trial
        } else {
            return .active
        }
    }

    private var statusColor: Color {
        switch subscriptionStatus {
        case .active: return .wiseBrightGreen
        case .paused: return .wiseWarning
        case .cancelled: return .wiseError
        case .trial: return .wiseBlue
        }
    }

    private var countdownBadgeColor: Color {
        if daysUntilBilling <= 3 {
            return .wiseError
        } else if daysUntilBilling <= 7 {
            return .wiseWarning
        } else {
            return .wiseBlue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Status badge (for non-active states)
            if subscriptionStatus != .active {
                statusBadge
            }

            // 2x2 Metrics Grid
            metricsGrid

        }
        .padding(20)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.spotifyLabelMedium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(statusColor.opacity(0.1))
        .cornerRadius(20)
    }

    private var statusText: String {
        switch subscriptionStatus {
        case .active: return "Active"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        case .trial:
            if let days = subscription.daysUntilTrialEnd {
                return "Trial - \(days) days left"
            }
            return "Free Trial"
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12
        ) {
            // Top Left: Next Billing Date with countdown
            nextBillingMetric

            // Top Right: Monthly Cost
            monthlyCostMetric

            // Bottom Left: Total Spent
            totalSpentMetric

            // Bottom Right: Member Since
            memberSinceMetric
        }
    }

    // MARK: - Next Billing Metric (Most Prominent)

    private var nextBillingMetric: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Billing")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            if subscriptionStatus == .paused {
                Text("Paused")
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wiseWarning)
            } else if subscriptionStatus == .cancelled {
                Text("Cancelled")
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wiseError)
            } else if subscriptionStatus == .trial {
                if let trialEnd = subscription.trialEndDate {
                    Text(formatDate(trialEnd))
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)
                } else {
                    Text("Trial")
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wiseBlue)
                }
            } else {
                Text(formatDate(subscription.nextBillingDate))
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)
            }

            // Countdown badge (only for active/trial)
            if subscriptionStatus == .active || subscriptionStatus == .trial {
                countdownBadgeView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(countdownBadgeColor.opacity(0.08))
        )
    }

    private var countdownBadgeView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 10))

            Text(
                daysUntilBilling == 0
                    ? "Today" : daysUntilBilling == 1 ? "Tomorrow" : "\(daysUntilBilling) days"
            )
            .font(.spotifyLabelSmall)
            .fontWeight(.semibold)
        }
        .foregroundColor(countdownBadgeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(countdownBadgeColor.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - Monthly Cost Metric

    private var monthlyCostMetric: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Cost")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(subscription.monthlyEquivalent.asCurrency)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wiseForestGreen)

            Text("/month")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseBorder.opacity(0.3))
        )
    }

    // MARK: - Total Spent Metric

    private var totalSpentMetric: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Spent")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(subscription.totalSpent.asCurrency)
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)

            Text("all time")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseBorder.opacity(0.3))
        )
    }

    // MARK: - Member Since Metric

    private var memberSinceMetric: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Member Since")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(formatShortDate(subscription.createdDate))
                .font(.spotifyBodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.wisePrimaryText)

            Text(membershipDuration)
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseBorder.opacity(0.3))
        )
    }

    private var membershipDuration: String {
        let components = Calendar.current.dateComponents(
            [.month, .day], from: subscription.createdDate, to: Date())
        let months = components.month ?? 0

        if months == 0 {
            let days = components.day ?? 0
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if months < 12 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return "\(years) year\(years == 1 ? "" : "s")"
            }
            return "\(years)y \(remainingMonths)m"
        }
    }

    // MARK: - Helper Functions

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Subscription Status Enum

enum SubscriptionStatusType {
    case active
    case paused
    case cancelled
    case trial
}

// MARK: - Preview

#Preview("Active Subscription") {
    ScrollView {
        SubscriptionBillingSummaryCard(
            subscription: MockData.activeSubscription
        )
    }
    .background(Color.wiseBackground)
}
