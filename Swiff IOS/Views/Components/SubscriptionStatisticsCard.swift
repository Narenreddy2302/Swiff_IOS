//
//  SubscriptionStatisticsCard.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Display subscription statistics and insights
//

import SwiftUI

struct SubscriptionStatisticsCard: View {
    @EnvironmentObject var dataManager: DataManager

    var statistics: SubscriptionStatistics {
        dataManager.getSubscriptionStatistics()
    }

    var upcomingRenewals: [Subscription] {
        dataManager.getWeekRenewals()
    }

    var trialsEndingSoon: [Subscription] {
        dataManager.subscriptions.filter { subscription in
            subscription.isFreeTrial &&
            !subscription.isTrialExpired &&
            subscription.daysUntilTrialEnd ?? 100 <= 7
        }
    }

    var potentialSavings: Double {
        let pausedAndCancelled = dataManager.subscriptions.filter { !$0.isActive }
        return pausedAndCancelled.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private func formatCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription Overview")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("Your spending summary")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.wiseForestGreen)
            }

            Divider()

            // Statistics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Total Active
                StatisticItemView(
                    icon: "checkmark.circle.fill",
                    iconColor: .wiseBrightGreen,
                    title: "Active",
                    value: "\(statistics.totalActive)",
                    subtitle: "of \(statistics.totalActive + statistics.totalInactive)"
                )

                // Upcoming Renewals
                StatisticItemView(
                    icon: "calendar.badge.clock",
                    iconColor: .wiseAccentBlue,
                    title: "This Week",
                    value: "\(statistics.upcomingRenewals7Days)",
                    subtitle: "renewals"
                )

                // Free Trials Ending Soon (if any)
                if !trialsEndingSoon.isEmpty {
                    StatisticItemView(
                        icon: "gift.fill",
                        iconColor: .orange,
                        title: "Trials Ending",
                        value: "\(trialsEndingSoon.count)",
                        subtitle: "this week"
                    )
                }

                // Potential Savings (if there are paused/cancelled)
                if potentialSavings > 0 {
                    StatisticItemView(
                        icon: "arrow.down.circle.fill",
                        iconColor: .wiseForestGreen,
                        title: "Savings",
                        value: formatCurrency(potentialSavings),
                        subtitle: "potential"
                    )
                }

                // Monthly Cost
                StatisticItemView(
                    icon: "dollarsign.circle.fill",
                    iconColor: .wiseForestGreen,
                    title: "Monthly",
                    value: formatCurrency(statistics.totalMonthlyCost),
                    subtitle: "total cost"
                )

                // Annual Cost
                StatisticItemView(
                    icon: "calendar.circle.fill",
                    iconColor: .wiseAccentOrange,
                    title: "Annual",
                    value: formatCurrency(statistics.totalAnnualCost),
                    subtitle: "projected"
                )
            }

            // Upcoming Renewals Section
            if !upcomingRenewals.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseAccentOrange)

                        Text("Upcoming Renewals")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wisePrimaryText)
                    }

                    ForEach(upcomingRenewals.prefix(3)) { subscription in
                        UpcomingRenewalRow(subscription: subscription)
                    }

                    if upcomingRenewals.count > 3 {
                        Text("+\(upcomingRenewals.count - 3) more")
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.leading, 30)
                    }
                }
            }

            // Paused/Cancelled Summary
            let pausedCount = dataManager.subscriptions.filter { !$0.isActive && $0.cancellationDate == nil }.count
            let cancelledCount = dataManager.subscriptions.filter { $0.cancellationDate != nil }.count

            if pausedCount > 0 || cancelledCount > 0 {
                Divider()

                HStack(spacing: 20) {
                    if pausedCount > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(pausedCount)")
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.wisePrimaryText)

                                Text("Paused")
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                    }

                    if cancelledCount > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseError)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(cancelledCount)")
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.wisePrimaryText)

                                Text("Cancelled")
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

// MARK: - Statistic Item View

struct StatisticItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Text(value)
                .font(.spotifyHeadingMedium)
                .fontWeight(.bold)
                .foregroundColor(.wisePrimaryText)

            Text(subtitle)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.05))
        )
    }
}

// MARK: - Upcoming Renewal Row

struct UpcomingRenewalRow: View {
    let subscription: Subscription

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private func formatCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    var daysUntilRenewal: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
    }

    var renewalText: String {
        if daysUntilRenewal == 0 {
            return "Today"
        } else if daysUntilRenewal == 1 {
            return "Tomorrow"
        } else {
            return "in \(daysUntilRenewal) days"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: subscription.color).opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: subscription.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: subscription.color))
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(renewalText)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Amount
            Text(formatCurrency(subscription.price))
                .font(.spotifyBodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SubscriptionStatisticsCard()
        .environmentObject(DataManager.shared)
        .padding()
        .background(Color.wiseBackground)
}
