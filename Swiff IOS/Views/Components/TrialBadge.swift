//
//  TrialBadge.swift
//  Swiff IOS
//
//  Created by Agent 8 on 11/21/25.
//  AGENT 8: Prominent FREE TRIAL badge for subscription cards
//

import SwiftUI
import Combine

// AGENT 8: Trial badge component with color-coded urgency
struct TrialBadge: View {
    let daysRemaining: Int?
    let isExpired: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.system(size: 10, weight: .bold))
            Text("FREE TRIAL")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(badgeColor)
        )
        .shadow(color: badgeColor.opacity(0.3), radius: 2, x: 0, y: 1)
    }

    // AGENT 8: Color-coded based on expiration urgency (adaptive for dark mode)
    private var badgeColor: Color {
        if isExpired {
            return .wiseError
        }

        guard let days = daysRemaining else {
            return .wiseWarning
        }

        if days <= 1 {
            return .wiseError
        } else if days <= 3 {
            return .wiseWarning
        } else {
            return .wiseInfo // Blue for safe trials
        }
    }
}

// AGENT 8: Trial countdown display
struct TrialCountdown: View {
    let daysRemaining: Int?
    let isExpired: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isExpired ? "exclamationmark.circle.fill" : "clock.fill")
                .font(.system(size: 12))
                .foregroundColor(countdownColor)

            Text(countdownText)
                .font(.spotifyCaptionMedium)
                .foregroundColor(countdownColor)
        }
    }

    private var countdownText: String {
        if isExpired {
            return "Trial Expired"
        }

        guard let days = daysRemaining else {
            return "Active Trial"
        }

        if days == 0 {
            return "Ends today"
        } else if days == 1 {
            return "Ends tomorrow"
        } else {
            return "Ends in \(days) days"
        }
    }

    private var countdownColor: Color {
        if isExpired {
            return .wiseError
        }

        guard let days = daysRemaining else {
            return .wiseWarning
        }

        if days <= 1 {
            return .wiseError
        } else if days <= 3 {
            return .wiseWarning
        } else {
            return .wiseSecondaryText
        }
    }
}

// AGENT 8: Preview
#Preview("Trial Badge") {
    VStack(spacing: 16) {
        TrialBadge(daysRemaining: 14, isExpired: false)
        TrialBadge(daysRemaining: 3, isExpired: false)
        TrialBadge(daysRemaining: 1, isExpired: false)
        TrialBadge(daysRemaining: 0, isExpired: true)
    }
    .padding()
}

#Preview("Trial Countdown") {
    VStack(spacing: 16) {
        TrialCountdown(daysRemaining: 14, isExpired: false)
        TrialCountdown(daysRemaining: 3, isExpired: false)
        TrialCountdown(daysRemaining: 1, isExpired: false)
        TrialCountdown(daysRemaining: 0, isExpired: false)
        TrialCountdown(daysRemaining: nil, isExpired: true)
    }
    .padding()
}
