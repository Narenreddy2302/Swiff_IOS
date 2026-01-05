//
//  InitialsListRow.swift
//  Swiff IOS
//
//  Unified list row with initials-based colored avatars
//  Matches the clean design reference with pastel avatar colors
//

import SwiftUI
import UIKit

// MARK: - Initials List Row

/// Clean list row with initials-based colored avatar.
/// Used for transactions, contacts, groups, subscriptions, and analytics.
///
/// Design specs:
/// - Avatar: 44x44 colored circle with initials
/// - Title: 15pt semibold, primary color
/// - Description: 13pt medium, gray (#666666)
/// - Amount: 15pt semibold, green/red based on sign
/// - Time: 12pt medium, light gray (#999999)
/// - Padding: 14pt vertical, 20pt horizontal
struct InitialsListRow: View {
    // MARK: - Properties

    let title: String
    let description: String
    let initials: String
    let avatarColor: Color
    let amount: String
    let amountColor: Color
    let timeText: String
    var onTap: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 14) {
                // Avatar with initials
                initialsAvatar

                // Left column: Title + Description
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.wiseDescriptionText)
                        .lineLimit(1)
                }

                Spacer()

                // Right column: Amount + Time
                VStack(alignment: .trailing, spacing: 3) {
                    Text(amount)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(amountColor)

                    Text(timeText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.wiseTimeText)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wisePrimaryText)
        }
    }
}

// MARK: - Pastel Avatar Colors

/// Pastel color palette for initials avatars
struct InitialsAvatarColors {
    /// Green - for income, positive amounts
    static let green = Color(red: 159 / 255, green: 232 / 255, blue: 112 / 255)

    /// Gray - for neutral, services, subscriptions
    static let gray = Color(red: 212 / 255, green: 212 / 255, blue: 212 / 255)

    /// Pink - for personal, people
    static let pink = Color(red: 255 / 255, green: 177 / 255, blue: 200 / 255)

    /// Yellow - for shopping, retail
    static let yellow = Color(red: 255 / 255, green: 229 / 255, blue: 102 / 255)

    /// Purple - for entertainment
    static let purple = Color(red: 196 / 255, green: 177 / 255, blue: 255 / 255)

    /// All colors for cycling
    static let allColors: [Color] = [green, gray, pink, yellow, purple]

    /// Get color by index (wraps around)
    static func color(at index: Int) -> Color {
        allColors[abs(index) % allColors.count]
    }

    /// Get color based on string hash
    static func color(for string: String) -> Color {
        color(at: abs(string.hashValue) % allColors.count)
    }
}

// MARK: - Feed Avatar Color (8-Color System)

/// Modern avatar color palette for feed transactions
/// Each color has adaptive background/foreground for light and dark mode
enum FeedAvatarColor: String, CaseIterable, Codable {
    case gray, yellow, emerald, violet, rose, amber, sky, slate

    /// Background color - pastel in light mode, deeper/muted in dark mode
    var background: Color {
        Color(uiColor: UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            switch self {
            case .gray:
                return isDark
                    ? UIColor(red: 0.25, green: 0.27, blue: 0.30, alpha: 1.0)
                    : UIColor(red: 0.886, green: 0.910, blue: 0.925, alpha: 1.0)
            case .yellow:
                return isDark
                    ? UIColor(red: 0.45, green: 0.38, blue: 0.15, alpha: 1.0)
                    : UIColor(red: 0.996, green: 0.941, blue: 0.541, alpha: 1.0)
            case .emerald:
                return isDark
                    ? UIColor(red: 0.12, green: 0.35, blue: 0.25, alpha: 1.0)
                    : UIColor(red: 0.820, green: 0.980, blue: 0.902, alpha: 1.0)
            case .violet:
                return isDark
                    ? UIColor(red: 0.30, green: 0.22, blue: 0.45, alpha: 1.0)
                    : UIColor(red: 0.929, green: 0.914, blue: 0.992, alpha: 1.0)
            case .rose:
                return isDark
                    ? UIColor(red: 0.45, green: 0.18, blue: 0.22, alpha: 1.0)
                    : UIColor(red: 1.0, green: 0.894, blue: 0.902, alpha: 1.0)
            case .amber:
                return isDark
                    ? UIColor(red: 0.45, green: 0.32, blue: 0.12, alpha: 1.0)
                    : UIColor(red: 0.996, green: 0.953, blue: 0.780, alpha: 1.0)
            case .sky:
                return isDark
                    ? UIColor(red: 0.12, green: 0.28, blue: 0.40, alpha: 1.0)
                    : UIColor(red: 0.878, green: 0.949, blue: 0.992, alpha: 1.0)
            case .slate:
                return isDark
                    ? UIColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1.0)
                    : UIColor(red: 0.945, green: 0.957, blue: 0.965, alpha: 1.0)
            }
        })
    }

    /// Foreground/text color - darker in light mode, brighter in dark mode
    var foreground: Color {
        Color(uiColor: UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            switch self {
            case .gray:
                return isDark
                    ? UIColor(red: 0.75, green: 0.78, blue: 0.82, alpha: 1.0)
                    : UIColor(red: 0.392, green: 0.455, blue: 0.545, alpha: 1.0)
            case .yellow:
                return isDark
                    ? UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
                    : UIColor(red: 0.631, green: 0.384, blue: 0.027, alpha: 1.0)
            case .emerald:
                return isDark
                    ? UIColor(red: 0.45, green: 0.90, blue: 0.65, alpha: 1.0)
                    : UIColor(red: 0.016, green: 0.471, blue: 0.341, alpha: 1.0)
            case .violet:
                return isDark
                    ? UIColor(red: 0.75, green: 0.65, blue: 1.0, alpha: 1.0)
                    : UIColor(red: 0.427, green: 0.157, blue: 0.851, alpha: 1.0)
            case .rose:
                return isDark
                    ? UIColor(red: 1.0, green: 0.55, blue: 0.65, alpha: 1.0)
                    : UIColor(red: 0.882, green: 0.114, blue: 0.290, alpha: 1.0)
            case .amber:
                return isDark
                    ? UIColor(red: 1.0, green: 0.75, blue: 0.35, alpha: 1.0)
                    : UIColor(red: 0.851, green: 0.463, blue: 0.024, alpha: 1.0)
            case .sky:
                return isDark
                    ? UIColor(red: 0.45, green: 0.80, blue: 1.0, alpha: 1.0)
                    : UIColor(red: 0.008, green: 0.518, blue: 0.780, alpha: 1.0)
            case .slate:
                return isDark
                    ? UIColor(red: 0.70, green: 0.75, blue: 0.82, alpha: 1.0)
                    : UIColor(red: 0.278, green: 0.333, blue: 0.412, alpha: 1.0)
            }
        })
    }

    /// Get a random color
    static func random() -> FeedAvatarColor {
        allCases.randomElement() ?? .emerald
    }

    /// Get color based on string hash (deterministic)
    static func forName(_ name: String) -> FeedAvatarColor {
        let index = abs(name.hashValue) % allCases.count
        return allCases[index]
    }
}

// MARK: - Amount Colors

/// Amount display colors for positive/negative values
struct AmountColors {
    /// Positive/Income - green
    static let positive = Color(red: 0 / 255, green: 135 / 255, blue: 90 / 255)

    /// Negative/Expense - red
    static let negative = Color(red: 217 / 255, green: 45 / 255, blue: 32 / 255)

    /// Neutral - primary text color
    static let neutral = Color.wisePrimaryText
}

// MARK: - Initials Generator

struct InitialsGenerator {
    /// Generate initials from a name (1-2 characters)
    static func generate(from name: String) -> String {
        let words = name.split(separator: " ")

        if words.count >= 2 {
            // First letter of first two words
            let first = String(words[0].prefix(1)).uppercased()
            let second = String(words[1].prefix(1)).uppercased()
            return first + second
        } else if let firstWord = words.first {
            // First two letters of single word
            return String(firstWord.prefix(2)).uppercased()
        }

        return "?"
    }
}

// MARK: - Unified Divider

/// Divider aligned with text content in transaction rows
/// Calculation: 16pt (card padding) + 56pt (avatar) + 16pt (spacing) = 88pt
struct AlignedDivider: View {
    var leftPadding: CGFloat = 88  // Updated for 56px avatars

    var body: some View {
        Rectangle()
            .fill(Color.wiseSeparator)
            .frame(height: 1)
            .padding(.leading, leftPadding)
    }
}

// MARK: - Preview

#Preview("InitialsListRow - Transactions") {
    ScrollView {
        VStack(spacing: 0) {
            Text("Transactions")
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                .padding(.bottom, 24)
                .padding(.horizontal, 20)

            // Income
            InitialsListRow(
                title: "Alex Thompson",
                description: "Payment received",
                initials: "AT",
                avatarColor: InitialsAvatarColors.green,
                amount: "+ $850.00",
                amountColor: AmountColors.positive,
                timeText: "4:32 PM"
            )

            AlignedDivider()

            // Expense - Spotify
            InitialsListRow(
                title: "Spotify",
                description: "Premium - Monthly",
                initials: "S",
                avatarColor: InitialsAvatarColors.gray,
                amount: "- $10.99",
                amountColor: AmountColors.negative,
                timeText: "12:00 PM"
            )

            AlignedDivider()

            // Expense - Apple
            InitialsListRow(
                title: "Apple",
                description: "iCloud+ Storage",
                initials: "A",
                avatarColor: InitialsAvatarColors.gray,
                amount: "- $2.99",
                amountColor: AmountColors.negative,
                timeText: "9:00 AM"
            )

            AlignedDivider()

            // Income from friend
            InitialsListRow(
                title: "Maria Santos",
                description: "Dinner split",
                initials: "MS",
                avatarColor: InitialsAvatarColors.pink,
                amount: "+ $45.00",
                amountColor: AmountColors.positive,
                timeText: "9:15 PM"
            )

            AlignedDivider()

            // Uber expense
            InitialsListRow(
                title: "Uber",
                description: "Trip to Downtown",
                initials: "U",
                avatarColor: InitialsAvatarColors.gray,
                amount: "- $18.50",
                amountColor: AmountColors.negative,
                timeText: "7:45 PM"
            )

            AlignedDivider()

            // Netflix
            InitialsListRow(
                title: "Netflix",
                description: "Standard Plan",
                initials: "N",
                avatarColor: InitialsAvatarColors.pink,
                amount: "- $15.49",
                amountColor: AmountColors.negative,
                timeText: "6:00 AM"
            )

            AlignedDivider()

            // Payroll
            InitialsListRow(
                title: "Direct Deposit",
                description: "Payroll - December",
                initials: "DD",
                avatarColor: InitialsAvatarColors.green,
                amount: "+ $3,200.00",
                amountColor: AmountColors.positive,
                timeText: "9:00 AM"
            )

            AlignedDivider()

            // Groceries
            InitialsListRow(
                title: "Whole Foods",
                description: "Groceries",
                initials: "WF",
                avatarColor: InitialsAvatarColors.yellow,
                amount: "- $127.83",
                amountColor: AmountColors.negative,
                timeText: "2:30 PM"
            )

            AlignedDivider()

            // Friend payment
            InitialsListRow(
                title: "Jordan Lee",
                description: "Concert tickets",
                initials: "JL",
                avatarColor: InitialsAvatarColors.purple,
                amount: "+ $150.00",
                amountColor: AmountColors.positive,
                timeText: "11:20 AM"
            )

            AlignedDivider()

            // Amazon
            InitialsListRow(
                title: "Amazon",
                description: "Order #8847-2931",
                initials: "A",
                avatarColor: InitialsAvatarColors.yellow,
                amount: "- $67.99",
                amountColor: AmountColors.negative,
                timeText: "3:45 PM"
            )
        }
    }
    .background(Color.wiseCardBackground)
}

#Preview("InitialsListRow - People") {
    VStack(spacing: 0) {
        InitialsListRow(
            title: MockData.personOwedMoney.name,
            description: "Owes you",
            initials: InitialsGenerator.generate(from: MockData.personOwedMoney.name),
            avatarColor: InitialsAvatarColors.color(for: MockData.personOwedMoney.name),
            amount: String(format: "$%.2f", MockData.personOwedMoney.balance),
            amountColor: AmountColors.positive,
            timeText: "No activity"
        )

        AlignedDivider()

        InitialsListRow(
            title: MockData.personOwingMoney.name,
            description: "You owe",
            initials: InitialsGenerator.generate(from: MockData.personOwingMoney.name),
            avatarColor: InitialsAvatarColors.color(for: MockData.personOwingMoney.name),
            amount: String(format: "$%.2f", abs(MockData.personOwingMoney.balance)),
            amountColor: AmountColors.negative,
            timeText: "No activity"
        )

        AlignedDivider()

        InitialsListRow(
            title: MockData.personSettled.name,
            description: "Settled",
            initials: InitialsGenerator.generate(from: MockData.personSettled.name),
            avatarColor: InitialsAvatarColors.color(for: MockData.personSettled.name),
            amount: String(format: "$%.2f", MockData.personSettled.balance),
            amountColor: .wisePrimaryText,
            timeText: "No activity"
        )
    }
    .background(Color.wiseCardBackground)
}

#Preview("InitialsListRow - Subscriptions") {
    VStack(spacing: 0) {
        InitialsListRow(
            title: MockData.activeSubscription.name,
            description: MockData.activeSubscription.billingCycle.displayName,
            initials: InitialsGenerator.generate(from: MockData.activeSubscription.name),
            avatarColor: MockData.activeSubscription.category.pastelAvatarColor,
            amount: String(format: "$%.2f", MockData.activeSubscription.price),
            amountColor: .wisePrimaryText,
            timeText: MockData.activeSubscription.nextBillingDate.shortCardDate
        )

        AlignedDivider()

        InitialsListRow(
            title: MockData.subscriptionDueToday.name,
            description: MockData.subscriptionDueToday.billingCycle.displayName,
            initials: InitialsGenerator.generate(from: MockData.subscriptionDueToday.name),
            avatarColor: MockData.subscriptionDueToday.category.pastelAvatarColor,
            amount: String(format: "$%.2f", MockData.subscriptionDueToday.price),
            amountColor: .wisePrimaryText,
            timeText: MockData.subscriptionDueToday.nextBillingDate.shortCardDate
        )

        AlignedDivider()

        InitialsListRow(
            title: MockData.yearlySubscription.name,
            description: MockData.yearlySubscription.billingCycle.displayName,
            initials: InitialsGenerator.generate(from: MockData.yearlySubscription.name),
            avatarColor: MockData.yearlySubscription.category.pastelAvatarColor,
            amount: String(format: "$%.2f", MockData.yearlySubscription.price),
            amountColor: .wisePrimaryText,
            timeText: MockData.yearlySubscription.nextBillingDate.shortCardDate
        )
    }
    .background(Color.wiseCardBackground)
}
