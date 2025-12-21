//
//  TransactionRowView.swift
//  Swiff IOS
//
//  Standalone transaction row component with initials avatar
//  Updated to match new unified list design
//

import SwiftUI

// MARK: - Transaction Row View

/// Standalone row-based transaction display with initials-based avatar.
/// Simpler version without CardContext for use in lists and grouped views.
/// Design: 44x44 avatar, 14pt gap, clean row without status badges.
struct TransactionRowView: View {
    let transaction: Transaction
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

// MARK: - Preview

#Preview("TransactionRowView - Income & Expense") {
    VStack(spacing: 0) {
        TransactionRowView(transaction: MockData.incomeTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.expenseTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.groceryTransaction)
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}

#Preview("TransactionRowView - Various Categories") {
    VStack(spacing: 0) {
        TransactionRowView(transaction: MockData.diningTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.transportTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.entertainmentTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.recurringTransaction)
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}

#Preview("TransactionRowView - Edge Cases") {
    VStack(spacing: 0) {
        TransactionRowView(transaction: MockData.largeTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.smallTransaction)
        AlignedDivider()
        TransactionRowView(transaction: MockData.pendingTransaction)
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.wiseBackground)
}
