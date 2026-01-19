//
//  UsageTrackingSheet.swift
//  Swiff IOS
//
//  Sheet for tracking subscription usage
//  Opened from Quick Actions "Usage" button
//

import SwiftUI

struct UsageTrackingSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let subscription: Subscription
    let onUsageUpdated: () -> Void

    @State private var isMarkingUsed = false

    // Computed properties
    private var currentSubscription: Subscription? {
        dataManager.subscriptions.first { $0.id == subscription.id }
    }

    private var usageCount: Int {
        currentSubscription?.usageCount ?? subscription.usageCount
    }

    private var lastUsedDate: Date? {
        currentSubscription?.lastUsedDate ?? subscription.lastUsedDate
    }

    private var daysSinceLastUsed: Int? {
        guard let lastUsed = lastUsedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day
    }

    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: subscription.createdDate, to: Date()).day ?? 1
    }

    private var usageFrequency: Double {
        guard usageCount > 0 else { return 0 }
        return Double(usageCount) / Double(max(daysSinceCreation, 1))
    }

    private var costPerUse: Double? {
        guard usageCount > 0 else { return nil }
        let totalCost = subscription.monthlyEquivalent * Double(daysSinceCreation) / 30.44
        return totalCost / Double(usageCount)
    }

    private var usageRating: UsageRating {
        if usageCount == 0 {
            return .unused
        } else if let days = daysSinceLastUsed, days > 30 {
            return .inactive
        } else if usageFrequency >= 0.5 {
            return .excellent
        } else if usageFrequency >= 0.2 {
            return .good
        } else {
            return .low
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Usage Overview Card
                    usageOverviewCard

                    // Mark as Used Section
                    markAsUsedSection

                    // Usage Stats Card
                    if usageCount > 0 {
                        usageStatsCard
                    }

                    // Usage Insights
                    if usageCount > 0 {
                        usageInsightsCard
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Usage Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }

    // MARK: - View Components

    private var usageOverviewCard: some View {
        VStack(spacing: 16) {
            // Subscription Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hexString: subscription.color).opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: subscription.icon)
                            .font(.system(size: 22))
                            .foregroundColor(Color(hexString: subscription.color))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("\(subscription.price.asCurrency)/\(subscription.billingCycle.displayShort)")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                // Usage Rating Badge
                UsageRatingBadge(rating: usageRating)
            }

            Divider()

            // Usage Stats Grid
            HStack(spacing: 24) {
                UsageStatItem(
                    icon: "number.circle.fill",
                    value: "\(usageCount)",
                    label: "Total Uses"
                )

                Spacer()

                UsageStatItem(
                    icon: "clock.fill",
                    value: lastUsedText,
                    label: "Last Used"
                )
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var lastUsedText: String {
        if let days = daysSinceLastUsed {
            if days == 0 {
                return "Today"
            } else if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            } else {
                let months = days / 30
                return "\(months) month\(months == 1 ? "" : "s") ago"
            }
        }
        return "Never"
    }

    private var markAsUsedSection: some View {
        VStack(spacing: 16) {
            Button(action: markAsUsed) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))

                    Text("Mark as Used Today")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseForestGreen)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMarkingUsed)

            if let days = daysSinceLastUsed, days == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseBrightGreen)

                    Text("Already marked as used today")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var usageStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)

                Text("Usage Statistics")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            VStack(spacing: 12) {
                // Usage Frequency
                HStack {
                    Text("Average Usage")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Spacer()

                    Text(String(format: "%.1f times/day", usageFrequency))
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)
                }

                Divider()

                // Cost Per Use
                if let cost = costPerUse {
                    HStack {
                        Text("Cost Per Use")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Spacer()

                        Text(cost.asCurrency)
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(cost < 1.0 ? .wiseBrightGreen : .wisePrimaryText)
                    }

                    Divider()
                }

                // Days Since Creation
                HStack {
                    Text("Tracking Since")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Spacer()

                    Text("\(daysSinceCreation) days")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var usageInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseOrange)

                Text("Insights")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            // Dynamic insight based on usage
            VStack(alignment: .leading, spacing: 8) {
                Text(usageInsightTitle)
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)

                Text(usageInsightDescription)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineSpacing(4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(usageRating.color.opacity(0.1))
            )
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private var usageInsightTitle: String {
        switch usageRating {
        case .excellent:
            return "Great Value!"
        case .good:
            return "Decent Usage"
        case .low:
            return "Consider Your Usage"
        case .inactive:
            return "Time to Decide"
        case .unused:
            return "Start Tracking"
        }
    }

    private var usageInsightDescription: String {
        switch usageRating {
        case .excellent:
            return "You're using \(subscription.name) frequently. At \(costPerUse.map { $0.asCurrency } ?? "N/A") per use, this subscription is providing good value."
        case .good:
            return "You're using \(subscription.name) regularly. Consider if you could use it more to maximize value."
        case .low:
            return "Your usage is low. You might want to evaluate if this subscription is worth keeping."
        case .inactive:
            if let days = daysSinceLastUsed {
                return "You haven't used \(subscription.name) in \(days) days. Consider cancelling to save \(subscription.monthlyEquivalent.asCurrency)/month."
            }
            return "Consider whether you still need this subscription."
        case .unused:
            return "Mark when you use \(subscription.name) to track its value over time."
        }
    }

    // MARK: - Actions

    private func markAsUsed() {
        isMarkingUsed = true

        guard var updatedSubscription = currentSubscription ?? dataManager.subscriptions.first(where: { $0.id == subscription.id }) else {
            isMarkingUsed = false
            return
        }

        updatedSubscription.lastUsedDate = Date()
        updatedSubscription.usageCount += 1

        do {
            try dataManager.updateSubscription(updatedSubscription)
            HapticManager.shared.success()
            onUsageUpdated()
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }

        isMarkingUsed = false
    }
}

// MARK: - Usage Rating

enum UsageRating {
    case excellent
    case good
    case low
    case inactive
    case unused

    var color: Color {
        switch self {
        case .excellent: return .wiseBrightGreen
        case .good: return .wiseBlue
        case .low: return .wiseWarning
        case .inactive: return .wiseError
        case .unused: return .wiseSecondaryText
        }
    }

    var text: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .low: return "Low"
        case .inactive: return "Inactive"
        case .unused: return "Unused"
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .low: return "arrow.down.circle.fill"
        case .inactive: return "moon.zzz.fill"
        case .unused: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Usage Rating Badge

struct UsageRatingBadge: View {
    let rating: UsageRating

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rating.icon)
                .font(.system(size: 10))

            Text(rating.text)
                .font(.spotifyCaptionSmall)
                .fontWeight(.semibold)
        }
        .foregroundColor(rating.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(rating.color.opacity(0.15))
        )
    }
}

// MARK: - Usage Stat Item

struct UsageStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.wiseForestGreen)

            Text(value)
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)

            Text(label)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }
}

