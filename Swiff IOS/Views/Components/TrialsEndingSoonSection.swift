//
//  TrialsEndingSoonSection.swift
//  Swiff IOS
//
//  Created by Agent 8 on 11/21/25.
//  AGENT 8: Section showing trials expiring within 7 days
//

import SwiftUI

// AGENT 8: Trials Ending Soon Section
struct TrialsEndingSoonSection: View {
    let trials: [Subscription]
    let onKeep: (Subscription) -> Void
    let onCancel: (Subscription) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.wiseWarning)

                    Text("Trials Ending Soon")
                        .font(.spotifyHeadingLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                if trials.count > 3 {
                    Button(action: onViewAll) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.spotifyBodyMedium)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.wiseBlue)
                    }
                }
            }

            // Trial Cards
            if trials.isEmpty {
                // Empty State
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.wiseForestGreen)

                        Text("No trials expiring soon")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseForestGreen.opacity(0.05))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(trials.prefix(3)) { trial in
                        TrialExpiringCard(
                            subscription: trial,
                            onKeep: { onKeep(trial) },
                            onCancel: { onCancel(trial) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseBackground)
        )
        .cardShadow()
    }
}

// AGENT 8: Trial Expiring Card Component
struct TrialExpiringCard: View {
    let subscription: Subscription
    let onKeep: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: subscription.color).opacity(0.3),
                                Color(hex: subscription.color).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: subscription.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: subscription.color))
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)

                    HStack(spacing: 8) {
                        TrialCountdown(
                            daysRemaining: subscription.daysUntilTrialEnd,
                            isExpired: subscription.isTrialExpired
                        )

                        if subscription.willConvertToPaid {
                            Text("•")
                                .foregroundColor(.wiseSecondaryText)

                            Text("Auto-converts")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }

                Spacer()

                // Urgency Indicator
                if let days = subscription.daysUntilTrialEnd {
                    VStack(spacing: 2) {
                        Text("\(days)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(urgencyColor(days: days))

                        Text(days == 1 ? "day" : "days")
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Cancel Button
                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                        Text("Cancel")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.wiseError)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.wiseError.opacity(0.1))
                            .stroke(Color.wiseError, lineWidth: 1)
                    )
                }

                // Keep Button
                Button(action: onKeep) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                        Text("Keep")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.wiseForestGreen, .wiseBrightGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(urgencyBackgroundColor)
                .stroke(urgencyBorderColor, lineWidth: 1.5)
        )
    }

    // AGENT 8: Color coding based on urgency
    private func urgencyColor(days: Int) -> Color {
        if days <= 1 { return .wiseError }
        else if days <= 3 { return .wiseWarning }
        else { return .wiseSecondaryText }
    }

    private var urgencyBackgroundColor: Color {
        guard let days = subscription.daysUntilTrialEnd else { return .clear }
        if days <= 1 { return Color.wiseError.opacity(0.05) }
        else if days <= 3 { return Color.wiseWarning.opacity(0.05) }
        else { return .clear }
    }

    private var urgencyBorderColor: Color {
        guard let days = subscription.daysUntilTrialEnd else { return Color.wiseBorder }
        if days <= 1 { return Color.wiseError.opacity(0.3) }
        else if days <= 3 { return Color.wiseWarning.opacity(0.3) }
        else { return Color.wiseBorder }
    }
}

// AGENT 8: Preview
#Preview("Trials Ending Soon") {
    ScrollView {
        TrialsEndingSoonSection(
            trials: [
                // Sample trial data will be added
            ],
            onKeep: { _ in },
            onCancel: { _ in },
            onViewAll: {}
        )
        .padding()
    }
}
