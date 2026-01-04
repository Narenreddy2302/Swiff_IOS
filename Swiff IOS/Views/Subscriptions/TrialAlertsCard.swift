//
//  TrialAlertsCard.swift
//  Swiff IOS
//
//  Created by Agent 8 on 11/21/25.
//  AGENT 8: Trial alerts card for HomeView dashboard
//

import SwiftUI

// AGENT 8: Trial Alerts Card Component
struct TrialAlertsCard: View {
    let trialsEndingSoon: [Subscription]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    // Icon with animation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.wiseWarning.opacity(0.2), Color.wiseWarning.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: "gift.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.wiseWarning)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trial Alerts")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.wisePrimaryText)

                        Text(alertSubtitle)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    if trialsEndingSoon.count > 0 {
                        // Count Badge
                        Text("\(trialsEndingSoon.count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 32, minHeight: 32)
                            .background(
                                Circle()
                                    .fill(urgencyGradient)
                            )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(16)

                // Next Trial Expiring
                if let nextTrial = trialsEndingSoon.first {
                    Divider()
                        .background(Color.wiseBorder)

                    HStack(spacing: 12) {
                        // Trial Icon
                        Circle()
                            .fill(Color(hexString: nextTrial.color).opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: nextTrial.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hexString: nextTrial.color))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(nextTrial.name)
                                .font(.spotifyBodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.wisePrimaryText)
                                .lineLimit(1)

                            TrialCountdown(
                                daysRemaining: nextTrial.daysUntilTrialEnd,
                                isExpired: nextTrial.isTrialExpired
                            )
                        }

                        Spacer()

                        // Countdown Timer Visual
                        if let days = nextTrial.daysUntilTrialEnd {
                            VStack(spacing: 2) {
                                Text("\(days)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(countdownColor(days: days))

                                Text(days == 1 ? "day" : "days")
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.wiseCardBackground)
                    .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // AGENT 8: Helper computed properties
    private var alertSubtitle: String {
        if trialsEndingSoon.isEmpty {
            return "No trials expiring soon"
        } else if trialsEndingSoon.count == 1 {
            return "1 trial expiring soon"
        } else {
            return "\(trialsEndingSoon.count) trials expiring soon"
        }
    }

    private var urgencyGradient: LinearGradient {
        if let firstTrial = trialsEndingSoon.first,
           let days = firstTrial.daysUntilTrialEnd {
            if days <= 1 {
                return LinearGradient(colors: [.wiseError, Color.wiseError.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else if days <= 3 {
                return LinearGradient(colors: [.wiseWarning, Color.wiseWarning.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        return LinearGradient(colors: [.wiseWarning, Color.wiseWarning.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var borderColor: Color {
        if trialsEndingSoon.isEmpty {
            return Color.wiseBorder.opacity(0.3)
        }

        if let firstTrial = trialsEndingSoon.first,
           let days = firstTrial.daysUntilTrialEnd {
            if days <= 1 { return Color.wiseError.opacity(0.3) }
            else if days <= 3 { return Color.wiseWarning.opacity(0.3) }
        }
        return Color.wiseWarning.opacity(0.2)
    }

    private var shadowColor: Color {
        if trialsEndingSoon.isEmpty {
            return Color.wiseShadowColor
        }

        if let firstTrial = trialsEndingSoon.first,
           let days = firstTrial.daysUntilTrialEnd {
            if days <= 1 { return Color.wiseError.opacity(0.1) }
            else if days <= 3 { return Color.wiseWarning.opacity(0.1) }
        }
        return Color.wiseWarning.opacity(0.05)
    }

    private func countdownColor(days: Int) -> Color {
        if days <= 1 { return .wiseError }
        else if days <= 3 { return .wiseWarning }
        else { return .wiseSecondaryText }
    }
}

// AGENT 8: Preview
#Preview("Trial Alerts Card") {
    VStack(spacing: 20) {
        // With trials
        TrialAlertsCard(
            trialsEndingSoon: [],
            onTap: {}
        )

        // Empty state
        TrialAlertsCard(
            trialsEndingSoon: [],
            onTap: {}
        )
    }
    .padding()
}
