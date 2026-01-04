//
//  InsightsComponents.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Insights Card
struct InsightsCard: View {
    @EnvironmentObject var dataManager: DataManager

    var totalSpending: Double {
        dataManager.calculateMonthlyExpenses() + dataManager.calculateTotalMonthlyCost()
    }

    var lastMonthSpending: Double {
        // Mock data - in production, calculate from last month's data
        totalSpending * 0.92  // Simulating 8% increase
    }

    var spendingChange: Double {
        ((totalSpending - lastMonthSpending) / lastMonthSpending) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(Theme.Fonts.headerLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            VStack(spacing: 12) {
                // Spending trend insight
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Theme.Colors.brandSecondary,
                    title: "Spending Trend",
                    description: spendingChange >= 0
                        ? "You're spending \(String(format: "%.1f%%", spendingChange)) more than last month"
                        : "You're spending \(String(format: "%.1f%%", abs(spendingChange))) less than last month",
                    isPositive: spendingChange < 0
                )

                // Subscription insight
                if dataManager.subscriptions.filter({ $0.isActive }).count > 0 {
                    InsightRow(
                        icon: "creditcard.circle",
                        iconColor: Theme.Colors.brandSecondary,
                        title: "Active Subscriptions",
                        description:
                            "\(dataManager.subscriptions.filter { $0.isActive }.count) subscriptions costing $\(String(format: "%.0f", dataManager.calculateTotalMonthlyCost()))/month",
                        isPositive: true
                    )
                }

                // Balance insight
                if dataManager.people.filter({ $0.balance > 0 }).count > 0 {
                    let totalOwed = dataManager.people.filter { $0.balance > 0 }.reduce(0) {
                        $0 + $1.balance
                    }
                    InsightRow(
                        icon: "person.2.circle",
                        iconColor: Theme.Colors.brandPrimary,
                        title: "Money Owed to You",
                        description:
                            "$\(String(format: "%.0f", totalOwed)) from \(dataManager.people.filter { $0.balance > 0 }.count) people",
                        isPositive: true
                    )
                }
            }
        }
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(description)
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.cardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Upcoming Renewals Section
struct UpcomingRenewalsSection: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager

    var upcomingRenewals: [Subscription] {
        let calendar = Calendar.current
        let today = Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!

        return dataManager.subscriptions
            .filter { subscription in
                subscription.isActive && subscription.nextBillingDate >= today
                    && subscription.nextBillingDate <= nextWeek
            }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Renewals")
                    .font(Theme.Fonts.headerLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button("View All") {
                    selectedTab = 3  // Switch to Subscriptions tab
                }
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.brandPrimary)
            }

            if upcomingRenewals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))

                    Text("No renewals in the next 7 days")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 10) {
                    ForEach(upcomingRenewals) { subscription in
                        NavigationLink(
                            destination: SubscriptionDetailView(subscriptionId: subscription.id)
                        ) {
                            UpcomingRenewalRow(subscription: subscription)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming Renewal Row
struct UpcomingRenewalRow: View {
    let subscription: Subscription

    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let renewalDate = calendar.startOfDay(for: subscription.nextBillingDate)
        return calendar.dateComponents([.day], from: today, to: renewalDate).day ?? 0
    }

    var urgencyColor: Color {
        if daysUntilRenewal <= 2 {
            return Theme.Colors.statusError
        } else if daysUntilRenewal <= 4 {
            return Theme.Colors.statusWarning
        }
        return Theme.Colors.brandSecondary
    }

    var urgencyText: String {
        if daysUntilRenewal == 0 {
            return "Today"
        } else if daysUntilRenewal == 1 {
            return "Tomorrow"
        } else {
            return "In \(daysUntilRenewal) days"
        }
    }

    var subtitle: String {
        return "\(subscription.billingCycle.rawValue) • \(urgencyText)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon (48x48)
            UnifiedIconCircle(
                icon: subscription.icon,
                color: Color(hexString: subscription.color),
                size: 48,
                iconSize: 20
            )

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(urgencyColor)
                    .lineLimit(1)
            }

            Spacer()

            // Price
            Text(String(format: "$%.2f", subscription.price))
                .font(Theme.Fonts.numberMedium)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Savings Opportunities Card
struct SavingsOpportunitiesCard: View {
    @EnvironmentObject var dataManager: DataManager

    var unusedSubscriptions: [Subscription] {
        // Mock logic - detect subscriptions that might be unused
        // In production, you'd track usage and determine based on that
        dataManager.subscriptions.filter { subscription in
            subscription.isActive && subscription.monthlyEquivalent > 15.0
        }.prefix(3).map { $0 }
    }

    var potentialSavings: Double {
        unusedSubscriptions.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var body: some View {
        if !unusedSubscriptions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Savings Opportunities")
                        .font(Theme.Fonts.headerLarge)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Potential savings summary
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.brandPrimary.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Theme.Colors.brandPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Potential Monthly Savings")
                                .font(Theme.Fonts.bodyMedium)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(
                                "Save up to $\(String(format: "%.0f", potentialSavings))/month by reviewing these subscriptions"
                            )
                            .font(Theme.Fonts.captionMedium)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.brandPrimary.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.brandPrimary.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // List of subscriptions to review
                    Text("Review these subscriptions:")
                        .font(Theme.Fonts.labelMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.top, 4)

                    ForEach(unusedSubscriptions) { subscription in
                        HStack(spacing: 10) {
                            Image(systemName: subscription.category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(subscription.category.color)
                                .frame(width: 24, height: 24)

                            Text(subscription.name)
                                .font(Theme.Fonts.bodySmall)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            Text("$\(String(format: "%.2f", subscription.monthlyEquivalent))")
                                .font(Theme.Fonts.labelMedium)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.Colors.cardBackground)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Subscription Spending Section
struct SubscriptionSpendingSection: View {
    @EnvironmentObject var dataManager: DataManager

    var personalMonthlySpend: Double {
        dataManager.subscriptions.filter { $0.isActive }.reduce(0.0) { total, subscription in
            total + subscription.monthlyEquivalent
        }
    }

    var sharedMonthlySpend: Double {
        dataManager.subscriptions
            .filter { $0.isActive && $0.isShared }
            .reduce(0.0) { total, subscription in
                let monthlyEquivalent = subscription.monthlyEquivalent
                let costPerPerson = monthlyEquivalent / Double(subscription.sharedWith.count + 1)
                return total + costPerPerson
            }
    }

    var totalSubscriptionSpend: Double {
        personalMonthlySpend + sharedMonthlySpend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Subscription Spending")
                    .font(Theme.Fonts.headerLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    // Navigate to subscriptions tab - you can implement this
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(Theme.Fonts.labelMedium)
                        Image(systemName: "chevron.right")
                            .font(Theme.Fonts.captionMedium)
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.border)
                    .clipShape(Capsule())
                }
            }

            // Subscription spending cards
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8
            ) {
                // Personal Subscriptions Card
                SubscriptionSpendingCard(
                    icon: "person.fill",
                    iconColor: Theme.Colors.brandPrimary,
                    title: "PERSONAL",
                    amount: String(format: "$%.0f/mo", personalMonthlySpend),
                    subtitle: "\(dataManager.subscriptions.filter { $0.isActive }.count) active"
                )

                // Shared Subscriptions Card
                SubscriptionSpendingCard(
                    icon: "person.2.fill",
                    iconColor: Theme.Colors.brandSecondary,
                    title: "SHARED",
                    amount: String(format: "$%.0f/mo", sharedMonthlySpend),
                    subtitle: "0 accepted"
                )
            }

            // Total spending summary
            HStack {
                Text("Total monthly spending:")
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Text(String(format: "$%.0f", totalSubscriptionSpend))
                    .font(Theme.Fonts.numberMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
    }
}

// MARK: - Subscription Spending Card
struct SubscriptionSpendingCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Spacer()
            }

            Text(title)
                .font(Theme.Fonts.labelSmall)
                .foregroundColor(Theme.Colors.textSecondary)
                .textCase(.uppercase)

            Text(amount)
                .font(Theme.Fonts.numberLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(subtitle)
                .font(Theme.Fonts.captionMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.cardBackground)
                .cardShadow()
        )
    }
}
