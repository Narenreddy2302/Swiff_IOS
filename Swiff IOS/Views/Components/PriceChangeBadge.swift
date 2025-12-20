//
//  PriceChangeBadge.swift
//  Swiff IOS
//
//  Created by Agent 9 for Price History Tracking
//  Displays price increase/decrease badges
//

import SwiftUI

// MARK: - Price Change Badge

struct PriceChangeBadge: View {
    let priceChange: PriceChange
    let showDismissButton: Bool
    let onDismiss: (() -> Void)?

    init(priceChange: PriceChange, showDismissButton: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.priceChange = priceChange
        self.showDismissButton = showDismissButton
        self.onDismiss = onDismiss
    }

    private var badgeColor: Color {
        priceChange.isIncrease ? Color.wiseError : Color.wiseBrightGreen
    }

    private var iconName: String {
        priceChange.isIncrease ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(badgeColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(priceChange.isIncrease ? "Price Increased" : "Price Decreased")
                    .font(.spotifyLabelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)

                Text(priceChange.formattedChangePercentage)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(badgeColor)
            }

            Spacer()

            if showDismissButton, let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)
                        .padding(4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(badgeColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(badgeColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compact Price Change Badge

struct CompactPriceChangeBadge: View {
    let priceChange: PriceChange

    private var badgeColor: Color {
        priceChange.isIncrease ? Color.wiseError : Color.wiseBrightGreen
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priceChange.isIncrease ? "arrow.up" : "arrow.down")
                .font(.system(size: 10))
            Text(priceChange.formattedChangePercentage)
                .font(.spotifyCaptionSmall)
                .fontWeight(.medium)
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.15))
        )
    }
}

// MARK: - Price Change Row

struct PriceChangeRow: View {
    let priceChange: PriceChange

    private var arrowColor: Color {
        priceChange.isIncrease ? Color.wiseError : Color.wiseBrightGreen
    }

    private var avatarColor: Color {
        priceChange.isIncrease ? InitialsAvatarColors.pink : InitialsAvatarColors.green
    }

    private var initials: String {
        priceChange.isIncrease ? "↑" : "↓"
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: priceChange.changeDate)
    }

    private var descriptionText: String {
        let oldPriceStr = String(format: "$%.2f", priceChange.oldPrice)
        let newPriceStr = String(format: "$%.2f", priceChange.newPrice)
        return "\(oldPriceStr) → \(newPriceStr)"
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: priceChange.changeDate, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 14) {
            // Initials avatar (44x44)
            initialsAvatar

            // Title and description
            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(descriptionText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer()

            // Amount and time
            VStack(alignment: .trailing, spacing: 3) {
                Text(priceChange.formattedChangeAmount)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(arrowColor)

                Text(relativeTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }
        }
        .padding(.vertical, 14)
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - Recent Price Increase Indicator

struct RecentPriceIncreaseIndicator: View {
    let daysAgo: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text("Price increased \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago")
                .font(.spotifyCaptionMedium)
                .fontWeight(.medium)
        }
        .foregroundColor(.wiseWarning)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.wiseWarning.opacity(0.15))
        )
    }
}

#Preview("Price Change Badge") {
    VStack(spacing: 20) {
        PriceChangeBadge(
            priceChange: PriceChange(
                subscriptionId: UUID(),
                oldPrice: 9.99,
                newPrice: 12.99,
                detectedAutomatically: true
            ),
            showDismissButton: true,
            onDismiss: {}
        )

        PriceChangeBadge(
            priceChange: PriceChange(
                subscriptionId: UUID(),
                oldPrice: 15.99,
                newPrice: 12.99,
                detectedAutomatically: false
            )
        )

        CompactPriceChangeBadge(
            priceChange: PriceChange(
                subscriptionId: UUID(),
                oldPrice: 9.99,
                newPrice: 14.99,
                detectedAutomatically: true
            )
        )

        PriceChangeRow(
            priceChange: PriceChange(
                subscriptionId: UUID(),
                oldPrice: 9.99,
                newPrice: 12.99,
                reason: "Annual price adjustment",
                detectedAutomatically: true
            )
        )

        RecentPriceIncreaseIndicator(daysAgo: 5)
    }
    .padding()
    .background(Color.wiseBackground)
}
