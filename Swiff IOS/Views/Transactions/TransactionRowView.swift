//
//  TransactionRowView.swift
//  Swiff IOS
//
//  Compact transaction row for feed page
//  Layout: Avatar | Name + Time | Amount + Type
//

import SwiftUI

// MARK: - Feed Transaction Row

/// Compact transaction row for dense feed display
/// Layout: 40x40 avatar | Name (14pt semibold) + Time (12pt) | Amount (14pt semibold) + Type (12pt)
struct FeedTransactionRow: View {
    let transaction: Transaction
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 40

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 10) {
                // Avatar - initials with colored background
                initialsAvatar

                // Left side - Name and Time
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                        .lineLimit(1)

                    Text(transaction.formattedTime)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }

                Spacer(minLength: 8)

                // Right side - Amount and Type
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedAmount)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(amountColor)

                    Text(transaction.derivedTransactionType.displayName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(displayName), \(formattedAmount), \(transaction.derivedTransactionType.displayName)")
    }

    // MARK: - Computed Properties

    private var displayName: String {
        transaction.displayName
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        let formatted = formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00"
        let prefix = transaction.isExpense ? "-" : "+"
        return "\(prefix)\(formatted)"
    }

    private var amountColor: Color {
        transaction.isExpense ? Theme.Colors.feedPrimaryText : Theme.Colors.feedPositiveAmount
    }

    // MARK: - Avatar

    private var initialsAvatar: some View {
        Circle()
            .fill(InitialsAvatarColors.color(for: displayName))
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: displayName))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(avatarTextColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }

    private var avatarTextColor: Color {
        // Use dark text on light backgrounds (green, yellow)
        let color = InitialsAvatarColors.color(for: displayName)
        if color == InitialsAvatarColors.green || color == InitialsAvatarColors.yellow {
            return Theme.Colors.feedPrimaryText
        }
        return .white
    }
}

// MARK: - Feed Row Divider

/// Indented divider for separating transaction rows
/// Aligned with text content (past the avatar)
struct FeedRowDivider: View {
    // Indent: 16pt (horizontal padding) + 40pt (avatar) + 10pt (spacing) = 66pt
    private let leadingIndent: CGFloat = 66

    var body: some View {
        Rectangle()
            .fill(Theme.Colors.feedDivider)
            .frame(height: 1)
            .padding(.leading, leadingIndent)
    }
}

// MARK: - Legacy Compatibility

/// Wrapper for backward compatibility with existing code
struct TransactionRowView: View {
    let transaction: Transaction
    var onTap: (() -> Void)? = nil

    var body: some View {
        FeedTransactionRow(transaction: transaction, onTap: onTap)
    }
}

// MARK: - Preview

#Preview("FeedTransactionRow - Various Types") {
    ScrollView {
        VStack(spacing: 0) {
            // Income - Receive
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Mikel Borle",
                    subtitle: "Payment received",
                    amount: 350.00,
                    category: .income,
                    date: Date(),
                    isRecurring: false,
                    tags: []
                )
            )
            .padding(.horizontal, 16)

            // Transfer - Uber
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Uber",
                    subtitle: "Trip to downtown",
                    amount: -10.00,
                    category: .transportation,
                    date: Date(),
                    isRecurring: false,
                    tags: [],
                    merchant: "Uber"
                )
            )
            .padding(.horizontal, 16)

            // Send - Person
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Ryan Scott",
                    subtitle: "Split dinner",
                    amount: -124.00,
                    category: .other,
                    date: Date(),
                    isRecurring: false,
                    tags: []
                )
            )
            .padding(.horizontal, 16)

            // Payment - Food Panda
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Food Panda",
                    subtitle: "Food delivery",
                    amount: -21.56,
                    category: .food,
                    date: Date(),
                    isRecurring: false,
                    tags: [],
                    merchant: "Food Panda"
                )
            )
            .padding(.horizontal, 16)
        }
    }
    .background(Color.white)
}

#Preview("FeedTransactionRow - Edge Cases") {
    VStack(spacing: 0) {
        // Large amount
        FeedTransactionRow(
            transaction: Transaction(
                title: "Salary Deposit",
                subtitle: "Monthly salary",
                amount: 5000.00,
                category: .income,
                date: Date(),
                isRecurring: true,
                tags: []
            )
        )
        .padding(.horizontal, 16)

        // Small amount
        FeedTransactionRow(
            transaction: Transaction(
                title: "Coffee",
                subtitle: "Starbucks",
                amount: -4.50,
                category: .food,
                date: Date(),
                isRecurring: false,
                tags: [],
                merchant: "Starbucks"
            )
        )
        .padding(.horizontal, 16)

        // Pending request
        FeedTransactionRow(
            transaction: Transaction(
                title: "John Smith",
                subtitle: "Dinner split request",
                amount: 50.00,
                category: .other,
                date: Date(),
                isRecurring: false,
                tags: [],
                paymentStatus: .pending
            )
        )
        .padding(.horizontal, 16)
    }
    .background(Color.white)
}
