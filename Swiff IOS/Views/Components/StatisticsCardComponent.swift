//
//  StatisticsCardComponent.swift
//  Swiff IOS
//
//  Reusable statistics card component following design system standards
//

import SwiftUI

/// Trend direction for statistics
enum TrendDirection {
    case positive(Double)
    case negative(Double)
    case neutral

    var color: Color {
        switch self {
        case .positive: return .wiseBrightGreen
        case .negative: return .wiseError
        case .neutral: return .wiseMidGray
        }
    }

    var icon: String {
        switch self {
        case .positive: return "arrow.up"
        case .negative: return "arrow.down"
        case .neutral: return "minus"
        }
    }

    var value: Double? {
        switch self {
        case .positive(let value), .negative(let value):
            return value
        case .neutral:
            return nil
        }
    }
}

/// Standardized statistics card component
struct StatisticsCardComponent: View {
    let icon: String
    let title: String
    let value: String
    let trend: TrendDirection?
    let subtitle: String?
    let iconColor: Color
    let showIcon: Bool

    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    init(
        icon: String = "chart.bar.fill",
        title: String,
        value: String,
        trend: TrendDirection? = nil,
        subtitle: String? = nil,
        iconColor: Color = .wiseForestGreen,
        showIcon: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.trend = trend
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.showIcon = showIcon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon (optional)
            if showIcon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Label (uppercase)
            Text(title)
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
                .lineLimit(1)

            // Main Value
            Text(value)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Trend or Subtitle
            if let trend = trend, let trendValue = trend.value {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(String(format: "%.1f%%", abs(trendValue)))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(trend.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(trend.color.opacity(0.1))
                .cornerRadius(8)
            } else if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

/// Horizontal statistics card (for feed/analytics)
struct HorizontalStatisticsCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    let backgroundColor: Color?

    @Environment(\.colorScheme) var colorScheme

    init(
        icon: String,
        title: String,
        value: String,
        iconColor: Color = .wiseForestGreen,
        backgroundColor: Color? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyLabelSmall)
                    .textCase(.uppercase)
                    .foregroundColor(.wiseSecondaryText)

                Text(value)
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            Spacer()
        }
        .padding(16)
        .frame(width: 180)
        .background(backgroundColor ?? Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }
}

/// Compact statistics card for smaller displays
struct CompactStatisticsCard: View {
    let icon: String
    let title: String
    let value: String
    let iconBackgroundColor: Color

    @Environment(\.colorScheme) var colorScheme

    init(
        icon: String,
        title: String,
        value: String,
        iconBackgroundColor: Color = .wiseForestGreen
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.iconBackgroundColor = iconBackgroundColor
    }

    var body: some View {
        VStack(spacing: 12) {
            // Icon with colored background
            Circle()
                .fill(iconBackgroundColor.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconBackgroundColor)
                )

            VStack(spacing: 4) {
                Text(title)
                    .font(.spotifyLabelSmall)
                    .textCase(.uppercase)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(value)
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }
}

// MARK: - Preview
#Preview("Standard Card") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            StatisticsCardComponent(
                icon: "dollarsign.circle",
                title: "Balance",
                value: "$1,234.56",
                trend: .positive(5.2)
            )

            StatisticsCardComponent(
                icon: "chart.bar.fill",
                title: "Subscriptions",
                value: "$89.99",
                trend: .negative(2.1),
                iconColor: .wiseBlue
            )
        }

        HStack(spacing: 12) {
            StatisticsCardComponent(
                icon: "arrow.down.circle",
                title: "Income",
                value: "$3,500.00",
                trend: .positive(8.5),
                iconColor: .wiseBrightGreen
            )

            StatisticsCardComponent(
                icon: "arrow.up.circle",
                title: "Expenses",
                value: "$2,145.23",
                trend: .neutral,
                iconColor: .wiseOrange
            )
        }
    }
    .padding()
    .background(Color.wiseBackground)
}

#Preview("Horizontal Card") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            HorizontalStatisticsCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Net Amount",
                value: "$1,234.56",
                iconColor: .wiseBlue
            )

            HorizontalStatisticsCard(
                icon: "arrow.down.circle.fill",
                title: "Total Income",
                value: "$5,000.00",
                iconColor: .wiseBrightGreen
            )

            HorizontalStatisticsCard(
                icon: "arrow.up.circle.fill",
                title: "Total Expenses",
                value: "$3,765.44",
                iconColor: .wiseOrange
            )
        }
        .padding(.horizontal)
    }
}

#Preview("Compact Card") {
    HStack(spacing: 12) {
        CompactStatisticsCard(
            icon: "person.2.fill",
            title: "People",
            value: "12",
            iconBackgroundColor: .wiseBlue
        )

        CompactStatisticsCard(
            icon: "arrow.up.arrow.down",
            title: "Owed to You",
            value: "$250.00",
            iconBackgroundColor: .wiseBrightGreen
        )

        CompactStatisticsCard(
            icon: "arrow.down",
            title: "You Owe",
            value: "$75.00",
            iconBackgroundColor: .wiseError
        )
    }
    .padding()
}
