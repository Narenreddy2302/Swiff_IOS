import SwiftUI

// MARK: - Subscription Insights Sheet
struct SubscriptionInsightsSheet: View {
    let subscriptions: [Subscription]
    @Binding var showingInsightsSheet: Bool

    var totalMonthlySpend: Double {
        subscriptions.filter { $0.isActive }.reduce(0.0) { $0 + $1.monthlyEquivalent }
    }

    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }

    var averageSubscriptionCost: Double {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        guard !activeSubscriptions.isEmpty else { return 0 }
        return totalMonthlySpend / Double(activeSubscriptions.count)
    }

    var categoryBreakdown: [(category: SubscriptionCategory, amount: Double, count: Int)] {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        let grouped = Dictionary(grouping: activeSubscriptions) { $0.category }
        return grouped.map { (category, subs) in
            let totalAmount = subs.reduce(0.0) { $0 + $1.monthlyEquivalent }
            return (category: category, amount: totalAmount, count: subs.count)
        }.sorted { $0.amount > $1.amount }
    }

    var mostExpensiveSubscription: Subscription? {
        subscriptions.filter { $0.isActive }.max(by: { $0.monthlyEquivalent < $1.monthlyEquivalent }
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], spacing: 12
                        ) {
                            InsightStatCard(
                                title: "Monthly Spend",
                                value: String(format: "$%.2f", totalMonthlySpend),
                                icon: "calendar.circle.fill",
                                color: .wiseBrightGreen
                            )

                            InsightStatCard(
                                title: "Annual Spend",
                                value: String(format: "$%.0f", totalAnnualSpend),
                                icon: "calendar.badge.plus",
                                color: .wiseBlue
                            )

                            InsightStatCard(
                                title: "Active Subscriptions",
                                value: "\(subscriptions.filter { $0.isActive }.count)",
                                icon: "checkmark.circle.fill",
                                color: .wiseBrightGreen
                            )

                            InsightStatCard(
                                title: "Average Cost",
                                value: String(format: "$%.2f", averageSubscriptionCost),
                                icon: "chart.bar.fill",
                                color: .wiseError
                            )
                        }
                    }

                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending by Category")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)

                        VStack(spacing: 12) {
                            ForEach(categoryBreakdown, id: \.category) { item in
                                CategoryBreakdownRow(
                                    category: item.category,
                                    amount: item.amount,
                                    count: item.count,
                                    percentage: totalMonthlySpend > 0
                                        ? (item.amount / totalMonthlySpend) : 0
                                )
                            }
                        }
                    }

                    // Most Expensive
                    if let mostExpensive = mostExpensiveSubscription {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Highest Cost")
                                .font(.spotifyHeadingLarge)
                                .foregroundColor(.wisePrimaryText)

                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color(hexString: mostExpensive.color).opacity(0.1))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: mostExpensive.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(Color(hexString: mostExpensive.color))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mostExpensive.name)
                                        .font(.spotifyBodyLarge)
                                        .foregroundColor(.wisePrimaryText)

                                    Text("Your most expensive subscription")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text(String(format: "$%.2f", mostExpensive.monthlyEquivalent))
                                        .font(.spotifyNumberMedium)
                                        .foregroundColor(.wiseError)

                                    Text("per month")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseCardBackground)
                                    .cardShadow()
                            )
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Subscription Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingInsightsSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Insight Stat Card
struct InsightStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }

            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(value)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let category: SubscriptionCategory
    let amount: Double
    let count: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(category.color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text("\(count) subscription\(count == 1 ? "" : "s")")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", amount))
                    .font(.spotifyNumberSmall)
                    .foregroundColor(.wisePrimaryText)

                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(category.color)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Renewal Calendar Sheet
struct RenewalCalendarSheet: View {
    let subscriptions: [Subscription]
    @Binding var showingRenewalCalendarSheet: Bool

    var upcomingRenewals: [(date: Date, subscriptions: [Subscription])] {
        let activeSubscriptions = subscriptions.filter {
            $0.isActive && $0.billingCycle != BillingCycle.lifetime
        }
        let grouped = Dictionary(grouping: activeSubscriptions) { subscription in
            Calendar.current.startOfDay(for: subscription.nextBillingDate)
        }

        return
            grouped
            .map { (date: $0.key, subscriptions: $0.value) }
            .sorted { $0.date < $1.date }
            .prefix(30)
            .map { $0 }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if upcomingRenewals.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 64))
                                .foregroundColor(.wiseSecondaryText.opacity(0.5))

                            VStack(spacing: 8) {
                                Text("No Upcoming Renewals")
                                    .font(.spotifyHeadingMedium)
                                    .foregroundColor(.wisePrimaryText)

                                Text("All your subscriptions are up to date")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(upcomingRenewals, id: \.date) { renewalGroup in
                            RenewalDateSection(
                                date: renewalGroup.date,
                                subscriptions: renewalGroup.subscriptions
                            )
                        }

                        Spacer(minLength: 50)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Renewal Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingRenewalCalendarSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Renewal Date Section
struct RenewalDateSection: View {
    let date: Date
    let subscriptions: [Subscription]

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isWithinWeek: Bool {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return date <= nextWeek
    }

    private var totalAmount: Double {
        subscriptions.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date, style: .date)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(isToday ? .wiseError : .wisePrimaryText)

                    Text(date, style: .relative)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", totalAmount))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(isWithinWeek ? .wiseError : .wisePrimaryText)

                    Text("\(subscriptions.count) renewal\(subscriptions.count == 1 ? "" : "s")")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Subscriptions List
            VStack(spacing: 8) {
                ForEach(subscriptions) { subscription in
                    ListRowFactory.row(for: subscription)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .subtleShadow()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isWithinWeek ? Color.wiseError.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Renewal Subscription Row
struct RenewalSubscriptionRow: View {
    let subscription: Subscription

    private var subtitle: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let nextDate = dateFormatter.string(from: subscription.nextBillingDate)
        return "\(subscription.billingCycle.rawValue) • Next: \(nextDate)"
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

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(String(format: "$%.2f", subscription.price))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
