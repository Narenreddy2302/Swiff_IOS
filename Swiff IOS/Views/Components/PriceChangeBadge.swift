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

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(arrowColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: priceChange.isIncrease ? "arrow.up" : "arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(arrowColor)
                )

            // Price change details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(String(format: "$%.2f", priceChange.oldPrice))
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .strikethrough()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)

                    Text(String(format: "$%.2f", priceChange.newPrice))
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)

                    CompactPriceChangeBadge(priceChange: priceChange)
                }

                HStack(spacing: 4) {
                    Text(priceChange.changeDate, style: .date)
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)

                    if let reason = priceChange.reason, !reason.isEmpty {
                        Text("•")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Text(reason)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .lineLimit(1)
                    }

                    if priceChange.detectedAutomatically {
                        Text("•")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Text("Auto-detected")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseBlue)
                    }
                }
            }

            Spacer()

            // Change amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(priceChange.formattedChangeAmount)
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(arrowColor)
            }
        }
        .padding(.vertical, 8)
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
