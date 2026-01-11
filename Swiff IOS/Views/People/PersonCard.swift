//
//  PersonCard.swift
//  Swiff IOS
//
//  Clean row-based person display with initials avatar
//  Updated to match new unified list design
//

import SwiftUI

// MARK: - Person Card

/// Clean row-based person display with initials-based avatar.
/// Shows colored circle with initials, name, balance status, balance amount, and last activity.
/// Design: 44x44 avatar, 14pt gap, clean row without status badges.
struct PersonCard: View {
    let person: Person
    var transactions: [Transaction] = []

    // MARK: - Computed Properties

    private var initials: String {
        InitialsGenerator.generate(from: person.name)
    }

    private var avatarColor: Color {
        // Use pastel color based on name hash
        InitialsAvatarColors.color(for: person.name)
    }

    private var balanceText: String {
        abs(person.balance).asCurrency
    }

    private var balanceColor: Color {
        if person.balance > 0 {
            return AmountColors.positive // They owe you
        } else if person.balance < 0 {
            return AmountColors.negative // You owe them
        } else {
            return .wisePrimaryText
        }
    }

    private var balanceStatus: String {
        if person.balance > 0 {
            return "Owes you"
        } else if person.balance < 0 {
            return "You owe"
        } else {
            return "Settled"
        }
    }

    private var lastActivityText: String {
        person.lastActivityText(transactions: transactions)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            // Initials avatar (no status badge)
            initialsAvatar

            // Name and status
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(balanceStatus)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Balance and last activity
            VStack(alignment: .trailing, spacing: 3) {
                Text(balanceText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(balanceColor)

                if !lastActivityText.isEmpty {
                    Text(lastActivityText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Initials Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - Feed Person Row

/// Person row for People list with 8-color avatar system
/// Layout: 48x48 avatar | Name (15pt) + Last transaction (13pt) | Balance (15pt) + Status (13pt)
struct FeedPersonRow: View {
    let person: Person
    var transactions: [Transaction] = []
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 14) {
            // Avatar - initials with colored background
            initialsAvatar

            // Left side - Name and last transaction
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.feedPrimaryText)
                    .lineLimit(1)

                Text(person.lastTransactionDetails(transactions: transactions))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Right side - Balance and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedBalance)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(balanceColor)

                Text(balanceStatus)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(formattedBalance), \(balanceStatus)")
    }

    // MARK: - Computed Properties

    private var formattedBalance: String {
        let absBalance = abs(person.balance)
        let currencySymbol = CurrencyFormatter.shared.getCurrencySymbol()
        let formatted = absBalance.asCurrency.replacingOccurrences(of: currencySymbol, with: "").trimmingCharacters(in: .whitespaces)

        if person.balance > 0 {
            return "+\(currencySymbol)\(formatted)"
        } else if person.balance < 0 {
            return "-\(currencySymbol)\(formatted)"
        } else {
            return "\(currencySymbol)\(formatted)"
        }
    }

    private var balanceColor: Color {
        if person.balance > 0 {
            return Theme.Colors.feedPositiveAmount  // They owe you - green
        } else if person.balance < 0 {
            return Theme.Colors.feedPrimaryText  // You owe them - default
        } else {
            return Theme.Colors.feedSecondaryText  // Settled - gray
        }
    }

    private var balanceStatus: String {
        if person.balance > 0 {
            return "Owes you"
        } else if person.balance < 0 {
            return "You owe"
        } else {
            return "Settled"
        }
    }

    // MARK: - Avatar

    private var avatarColor: FeedAvatarColor {
        FeedAvatarColor.forName(person.name)
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: person.name))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }
}

