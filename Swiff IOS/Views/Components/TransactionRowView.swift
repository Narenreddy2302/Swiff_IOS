//
//  TransactionRowView.swift
//  Swiff IOS
//
//  Standalone transaction row component with icon status indicator
//

import SwiftUI

// MARK: - Transaction Row View

/// Standalone row-based transaction display with icon status indicator.
/// Simpler version without CardContext for use in lists and grouped views.
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

    private var iconName: String {
        transaction.category.icon
    }

    private var amountColor: Color {
        isIncoming ? .wiseSuccess : .wiseError
    }

    private var formattedAmountWithSign: String {
        let sign = isIncoming ? "+" : "-"
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
            HStack(spacing: 12) {
                // Icon with status indicator
                iconWithStatusIndicator

                // Title and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                // Amount and time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedAmountWithSign)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(amountColor)

                    Text(relativeTime)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Icon with Status Indicator

    private var iconWithStatusIndicator: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main icon circle
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.wisePrimaryText)
                )

            // Status indicator (plus/minus badge)
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .fill(isIncoming ? Color.wiseSuccess : Color.wiseError)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: isIncoming ? "plus" : "minus")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                )
                .offset(x: 2, y: 2)
        }
    }
}

// MARK: - Preview

#Preview("TransactionRowView") {
    VStack(spacing: 0) {
        TransactionRowView(
            transaction: Transaction(
                id: UUID(),
                title: "Transfer to Access Bank",
                subtitle: "Bank transfer",
                amount: -1000.00,
                category: .transfer,
                date: Date(),
                isRecurring: false,
                tags: []
            )
        )
        .padding(.horizontal, 16)

        Divider()
            .padding(.leading, 76)

        TransactionRowView(
            transaction: Transaction(
                id: UUID(),
                title: "Salary Deposit",
                subtitle: "Monthly income",
                amount: 5000.00,
                category: .income,
                date: Date().addingTimeInterval(-3600),
                isRecurring: false,
                tags: []
            )
        )
        .padding(.horizontal, 16)

        Divider()
            .padding(.leading, 76)

        TransactionRowView(
            transaction: Transaction(
                id: UUID(),
                title: "Online Purchase",
                subtitle: "Shopping",
                amount: -150.00,
                category: .shopping,
                date: Date().addingTimeInterval(-86400),
                isRecurring: false,
                tags: [],
                paymentStatus: .pending
            )
        )
        .padding(.horizontal, 16)
    }
    .background(Color(.systemBackground))
}
