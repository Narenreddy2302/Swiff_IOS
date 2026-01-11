//
//  TransactionCard.swift
//  Swiff IOS
//
//  Row-based transaction display with initials avatar
//  Updated to match new unified list design
//

import SwiftUI

// MARK: - Transaction Card

/// Row-based transaction display with initials-based avatar.
/// Shows colored circle with initials, title, status, amount, and activity status.
/// Design: 56x56 avatar, larger typography, spacious layout matching reference design.
struct TransactionCard: View {
    let transaction: Transaction
    let context: CardContext
    var subscription: Subscription? = nil
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var isIncoming: Bool {
        !transaction.isExpense
    }

    private var statusText: String {
        transaction.paymentStatus.displayText
    }

    private var initials: String {
        InitialsGenerator.generate(from: transaction.title)
    }

    private var avatarColor: Color {
        // Map category to pastel avatar colors
        transaction.category.pastelAvatarColor
    }

    private var amountColor: Color {
        isIncoming ? AmountColors.positive : AmountColors.negative
    }

    private var formattedAmount: String {
        transaction.formattedAmount
    }

    private var activityText: String {
        "No activity"
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Initials avatar (larger size)
                initialsAvatar

                // Title and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                        .lineLimit(1)
                }

                Spacer()

                // Amount and activity status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedAmount)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(amountColor)

                    Text(activityText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Initials Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 56, height: 56)

            Text(initials)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - TransactionCategory Pastel Color Extension

extension TransactionCategory {
    /// Pastel avatar color for the new unified list design
    var pastelAvatarColor: Color {
        switch self {
        case .food, .dining:
            return InitialsAvatarColors.yellow
        case .groceries:
            return InitialsAvatarColors.green
        case .transportation, .travel:
            return InitialsAvatarColors.gray
        case .shopping:
            return InitialsAvatarColors.pink
        case .entertainment:
            return InitialsAvatarColors.purple
        case .bills, .utilities:
            return InitialsAvatarColors.yellow
        case .healthcare:
            return InitialsAvatarColors.pink
        case .income:
            return InitialsAvatarColors.green
        case .transfer:
            return InitialsAvatarColors.gray
        case .investment:
            return InitialsAvatarColors.green
        case .other:
            return InitialsAvatarColors.gray
        }
    }
}

