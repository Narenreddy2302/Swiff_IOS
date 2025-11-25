//
//  TrialStatusSection.swift
//  Swiff IOS
//
//  Created by Agent 8 on 11/21/25.
//  AGENT 8: Trial status display for subscription detail view
//

import SwiftUI

// AGENT 8: Trial Status Section Component
struct TrialStatusSection: View {
    let subscription: Subscription
    let onConvertNow: () -> Void
    let onCancelTrial: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "gift.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)

                Text("Free Trial Status")
                    .font(.spotifyHeadingLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                TrialBadge(
                    daysRemaining: subscription.daysUntilTrialEnd,
                    isExpired: subscription.isTrialExpired
                )
            }

            // Trial Timeline
            TrialTimelineView(subscription: subscription)

            // Trial Information Cards
            VStack(spacing: 12) {
                // Days Remaining Card
                TrialInfoCard(
                    icon: "clock.fill",
                    title: "Days Remaining",
                    value: subscription.daysUntilTrialEnd != nil ? "\(subscription.daysUntilTrialEnd!)" : "Expired",
                    color: trialUrgencyColor
                )

                // End Date Card
                if let endDate = subscription.trialEndDate {
                    TrialInfoCard(
                        icon: "calendar",
                        title: "Trial Ends",
                        value: formatDate(endDate),
                        color: .wiseSecondaryText
                    )
                }

                // Will Convert Card
                if subscription.willConvertToPaid {
                    if let priceAfterTrial = subscription.priceAfterTrial {
                        TrialInfoCard(
                            icon: "arrow.right.circle.fill",
                            title: "Converts To",
                            value: String(format: "$%.2f/%@", priceAfterTrial, subscription.billingCycle.shortName),
                            color: .wiseForestGreen
                        )
                    } else {
                        TrialInfoCard(
                            icon: "arrow.right.circle.fill",
                            title: "Converts To",
                            value: String(format: "$%.2f/%@", subscription.price, subscription.billingCycle.shortName),
                            color: .wiseForestGreen
                        )
                    }
                } else {
                    TrialInfoCard(
                        icon: "xmark.circle.fill",
                        title: "Status",
                        value: "Will be cancelled",
                        color: .orange
                    )
                }
            }

            // Action Buttons
            if !subscription.isTrialExpired {
                VStack(spacing: 12) {
                    // Convert Now Button (if will convert to paid)
                    if subscription.willConvertToPaid {
                        Button(action: onConvertNow) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                Text("Convert to Paid Now")
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.wiseForestGreen, .wiseForestGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }

                    // Cancel Before Trial Ends Button
                    Button(action: onCancelTrial) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Cancel Before Trial Ends")
                                .font(.spotifyBodyMedium)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.wiseError)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseError.opacity(0.1))
                                .stroke(Color.wiseError, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(trialBackgroundColor)
                .stroke(trialBorderColor, lineWidth: 2)
        )
        .shadow(color: trialShadowColor, radius: 8, x: 0, y: 4)
    }

    // AGENT 8: Helper computed properties
    private var trialUrgencyColor: Color {
        guard let days = subscription.daysUntilTrialEnd else { return .red }
        if days <= 1 { return .red }
        else if days <= 3 { return .orange }
        else { return .wiseForestGreen }
    }

    private var trialBackgroundColor: Color {
        guard let days = subscription.daysUntilTrialEnd else { return Color.red.opacity(0.05) }
        if days <= 1 { return Color.red.opacity(0.05) }
        else if days <= 3 { return Color.orange.opacity(0.05) }
        else { return Color.orange.opacity(0.02) }
    }

    private var trialBorderColor: Color {
        guard let days = subscription.daysUntilTrialEnd else { return .red }
        if days <= 1 { return .red.opacity(0.3) }
        else if days <= 3 { return .orange.opacity(0.3) }
        else { return Color.orange.opacity(0.2) }
    }

    private var trialShadowColor: Color {
        guard let days = subscription.daysUntilTrialEnd else { return Color.red.opacity(0.1) }
        if days <= 1 { return Color.red.opacity(0.1) }
        else if days <= 3 { return Color.orange.opacity(0.1) }
        else { return Color.orange.opacity(0.05) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// AGENT 8: Trial Info Card Component
struct TrialInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)

                Text(value)
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.wiseCardBackground)
        )
    }
}

// AGENT 8: Trial Timeline View with Progress Bar
struct TrialTimelineView: View {
    let subscription: Subscription

    var body: some View {
        VStack(spacing: 12) {
            // Timeline Labels
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)

                    if let startDate = subscription.trialStartDate {
                        Text(formatShortDate(startDate))
                            .font(.spotifyCaptionMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.wisePrimaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ends")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)

                    if let endDate = subscription.trialEndDate {
                        Text(formatShortDate(endDate))
                            .font(.spotifyCaptionMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.wiseBorder.opacity(0.3))
                        .frame(height: 16)

                    // Progress Fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: progressGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 16)
                        .animation(.easeInOut(duration: 0.5), value: progressPercentage)

                    // Progress Indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: max(0, min(geometry.size.width - 24, geometry.size.width * CGFloat(progressPercentage) - 12)))
                        .overlay(
                            Circle()
                                .stroke(progressColor, lineWidth: 3)
                                .frame(width: 24, height: 24)
                                .offset(x: max(0, min(geometry.size.width - 24, geometry.size.width * CGFloat(progressPercentage) - 12)))
                        )
                }
            }
            .frame(height: 24)

            // Duration Text
            HStack {
                Spacer()
                if let duration = subscription.trialDuration {
                    Text("\(duration) day trial")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }

    // AGENT 8: Calculate progress percentage
    private var progressPercentage: Double {
        guard let startDate = subscription.trialStartDate,
              let endDate = subscription.trialEndDate else {
            return 0.0
        }

        let now = Date()
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = now.timeIntervalSince(startDate)

        let percentage = min(max(elapsed / totalDuration, 0.0), 1.0)
        return percentage
    }

    private var progressColor: Color {
        if progressPercentage >= 0.9 { return .red }
        else if progressPercentage >= 0.7 { return .orange }
        else { return .wiseForestGreen }
    }

    private var progressGradientColors: [Color] {
        if progressPercentage >= 0.9 {
            return [.red, .red.opacity(0.7)]
        } else if progressPercentage >= 0.7 {
            return [.orange, .orange.opacity(0.7)]
        } else {
            return [.wiseForestGreen, .wiseBrightGreen]
        }
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// AGENT 8: Preview
#Preview("Trial Status Section") {
    VStack {
        TrialStatusSection(
            subscription: Subscription(
                name: "Netflix",
                description: "Premium Plan",
                price: 0.0,
                billingCycle: .monthly,
                category: .entertainment,
                icon: "tv.fill",
                color: "#E50914"
            ),
            onConvertNow: {},
            onCancelTrial: {}
        )
    }
    .padding()
}
