//
//  SettlementStatusBadge.swift
//  Swiff IOS
//
//  Status badge for expense settlement state
//  Shows settled (green) or pending (orange) with icon
//

import SwiftUI

// MARK: - Settlement Status

enum SettlementStatus {
    case settled
    case pending

    var icon: String {
        switch self {
        case .settled: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }

    var text: String {
        switch self {
        case .settled: return "Settled"
        case .pending: return "Pending"
        }
    }

    var color: Color {
        switch self {
        case .settled: return .wiseBrightGreen
        case .pending: return .wiseWarning
        }
    }

    var backgroundColor: Color {
        switch self {
        case .settled: return Color.wiseBrightGreen.opacity(0.15)
        case .pending: return Color.wiseWarning.opacity(0.15)
        }
    }
}

// MARK: - Settlement Status Badge

struct SettlementStatusBadge: View {
    let status: SettlementStatus
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(isCompact ? Theme.Fonts.badgeCompact : Theme.Fonts.badgeText)

            Text(status.text)
                .font(isCompact ? Theme.Fonts.badgeText : Theme.Fonts.labelMedium)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, isCompact ? Theme.Metrics.paddingSmall : 10)
        .padding(.vertical, isCompact ? 4 : 6)
        .background(status.backgroundColor)
        .clipShape(Capsule())
        .accessibilityLabel("Settlement status: \(status.text)")
    }
}

// MARK: - Preview

#Preview("Settlement Status Badges") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standard Size")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 12) {
                SettlementStatusBadge(status: .settled)
                SettlementStatusBadge(status: .pending)
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Compact Size")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 12) {
                SettlementStatusBadge(status: .settled, isCompact: true)
                SettlementStatusBadge(status: .pending, isCompact: true)
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("In Context")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            VStack(spacing: 12) {
                // Sample expense row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dinner at Italian Place")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)

                        Text("$120.00 • Split 4 ways")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    SettlementStatusBadge(status: .pending)
                }
                .padding(12)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)

                // Settled expense
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekend Groceries")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)

                        Text("$85.50 • Split 3 ways")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    SettlementStatusBadge(status: .settled)
                }
                .padding(12)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }
        }

        Spacer()
    }
    .padding(16)
    .background(Color.wiseBackground)
}
