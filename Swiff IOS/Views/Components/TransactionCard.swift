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
/// Shows colored circle with initials, title, status, amount, and relative time.
/// Design: 44x44 avatar, 14pt gap, clean row without status badges.
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

    private var formattedAmountWithSign: String {
        let sign = isIncoming ? "+ " : "- "
        return "\(sign)\(transaction.formattedAmount)"
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: transaction.date, relativeTo: Date())
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 14) {
                // Initials avatar (no status badge)
                initialsAvatar

                // Title and status
                VStack(alignment: .leading, spacing: 3) {
                    Text(transaction.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                        .lineLimit(1)
                }

                Spacer()

                // Amount and time
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formattedAmountWithSign)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(amountColor)

                    Text(relativeTime)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Preview

#Preview("TransactionCard - Income") {
    TransactionCard(
        transaction: MockData.incomeTransaction,
        context: .feed
    )
    .padding()
    .background(Color.wiseCardBackground)
}

#Preview("TransactionCard - Expenses") {
    VStack(spacing: 0) {
        TransactionCard(transaction: MockData.expenseTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.groceryTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.diningTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.transportTransaction, context: .feed)
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}

#Preview("TransactionCard - Status Variations") {
    VStack(spacing: 0) {
        TransactionCard(transaction: MockData.pendingTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.recurringTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.linkedTransaction, context: .feed)
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}

#Preview("TransactionCard - Edge Cases") {
    VStack(spacing: 0) {
        TransactionCard(transaction: MockData.largeTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.smallTransaction, context: .feed)
        AlignedDivider()
        TransactionCard(transaction: MockData.entertainmentTransaction, context: .feed)
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}
