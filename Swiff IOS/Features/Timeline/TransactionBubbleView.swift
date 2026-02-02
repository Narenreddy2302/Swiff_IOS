//
//  TransactionBubbleView.swift
//  Swiff IOS
//
//  Enhanced transaction card for conversation timeline bubbles
//  Based on iMessage-style reference design with detailed transaction info
//

import SwiftUI

// MARK: - Transaction Bubble View

/// An enhanced transaction card displayed within conversation bubbles
/// Shows transaction details including header, divider, and breakdown section
struct TransactionBubbleView: View {
    let transaction: any TransactionDisplayData
    let isSent: Bool
    let showTail: Bool
    let creatorName: String
    let maxWidthRatio: CGFloat

    // MARK: - Initialization

    init(
        transaction: any TransactionDisplayData,
        isSent: Bool,
        showTail: Bool = true,
        creatorName: String = "You",
        maxWidthRatio: CGFloat = 0.85
    ) {
        self.transaction = transaction
        self.isSent = isSent
        self.showTail = showTail
        self.creatorName = creatorName
        self.maxWidthRatio = maxWidthRatio
    }

    // MARK: - Computed Properties

    private var bubbleDirection: iMessageBubbleDirection {
        isSent ? .outgoing : .incoming
    }

    private var backgroundColor: Color {
        isSent ? .iMessageBlue : .iMessageGray
    }

    private var primaryTextColor: Color {
        isSent ? .white : .wisePrimaryText
    }

    private var secondaryTextColor: Color {
        isSent ? .white.opacity(0.8) : .wiseSecondaryText
    }

    private var dividerColor: Color {
        isSent ? .white.opacity(0.3) : .wiseBorder.opacity(0.5)
    }

    private var amountColor: Color {
        isSent ? .transactionYellow : .transactionOrange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: isSent ? .trailing : .leading, spacing: 6) {
            // Creator attribution (outside bubble)
            Text(creatorName == "You" ? "You created this" : "\(creatorName) created this")
                .font(.system(size: 12))
                .foregroundColor(.wiseSecondaryText)
                .lineLimit(1)

            // Transaction card (inside bubble)
            transactionCard
                .frame(maxWidth: UIScreen.main.bounds.width * maxWidthRatio)
        }
        .frame(maxWidth: .infinity, alignment: isSent ? .trailing : .leading)
        .padding(.horizontal, 12)
    }

    // MARK: - Transaction Card

    private var transactionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header section
            headerSection

            // Divider
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)

            // Details section
            detailsSection
        }
        .padding(14)
        .background(backgroundColor)
        .clipShape(iMessageBubbleShape(direction: bubbleDirection, showTail: showTail))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            // Transaction name (left side)
            Text(transaction.displayTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)

            Spacer()

            // Amount + label (right side) - both in amount color per spec
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatCurrency(transaction.displayYourShare))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(amountColor)

                Text("/ \(amountLabel)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(amountColor)
            }
        }
    }

    private var amountLabel: String {
        isSent ? "Each Owes" : "You Owe"
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: 8) {
            TransactionDetailRow(
                label: "Total Bill",
                value: formatCurrency(transaction.displayTotalAmount),
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor
            )

            TransactionDetailRow(
                label: "Paid by",
                value: transaction.displayPaidByName,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor
            )

            TransactionDetailRow(
                label: "Split Method",
                value: transaction.displaySplitMethod,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor
            )

            if !transaction.displayInvolvedNames.isEmpty {
                TransactionDetailRow(
                    label: "Who Involved",
                    value: transaction.displayInvolvedNames.joined(separator: ", "),
                    primaryColor: primaryTextColor,
                    secondaryColor: secondaryTextColor
                )
            }

            // Settlement status
            if !transaction.isFullySettled {
                settlementProgressView
            }
        }
    }

    // MARK: - Settlement Progress

    private var settlementProgressView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Settlement Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryTextColor)

                Spacer()

                Text("\(Int(transaction.settlementProgress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(primaryTextColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(dividerColor)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isSent ? .white : .wiseBrightGreen)
                        .frame(width: geometry.size.width * transaction.settlementProgress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let label: String
    let value: String
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(secondaryColor)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(primaryColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

// MARK: - Simple Transaction Bubble

/// A simpler version for basic transaction display
struct SimpleTransactionBubble: View {
    let title: String
    let amount: Double
    let paidBy: String
    let isSent: Bool
    let showTail: Bool

    init(
        title: String,
        amount: Double,
        paidBy: String,
        isSent: Bool,
        showTail: Bool = true
    ) {
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.isSent = isSent
        self.showTail = showTail
    }

    private var bubbleDirection: iMessageBubbleDirection {
        isSent ? .outgoing : .incoming
    }

    private var backgroundColor: Color {
        isSent ? .iMessageBlue : .iMessageGray
    }

    private var primaryTextColor: Color {
        isSent ? .white : .wisePrimaryText
    }

    private var secondaryTextColor: Color {
        isSent ? .white.opacity(0.8) : .wiseSecondaryText
    }

    private var amountColor: Color {
        isSent ? .transactionYellow : .transactionOrange
    }

    var body: some View {
        HStack {
            if isSent {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryTextColor)

                    Spacer()

                    Text(formatCurrency(amount))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(amountColor)
                }

                // Divider
                Rectangle()
                    .fill(isSent ? Color.white.opacity(0.2) : Color.wiseBorder.opacity(0.3))
                    .frame(height: 1)

                // Paid by
                HStack {
                    Text("Paid by")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryTextColor)

                    Spacer()

                    Text(paidBy)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryTextColor)
                }
            }
            .padding(12)
            .background(backgroundColor)
            .clipShape(iMessageBubbleShape(direction: bubbleDirection, showTail: showTail))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8)

            if !isSent {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - Color Extension

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Transaction Bubble View") {
    ScrollView {
        VStack(spacing: 16) {
            // Date header
            Text("Today")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
                .padding(.vertical, 16)

            // Incoming transaction (they created)
            SimpleTransactionBubble(
                title: "Dinner at Italian Restaurant",
                amount: 45.00,
                paidBy: "John",
                isSent: false,
                showTail: true
            )

            // Outgoing transaction (you created)
            SimpleTransactionBubble(
                title: "Movie Tickets",
                amount: 32.50,
                paidBy: "You",
                isSent: true,
                showTail: true
            )

            // Another incoming
            SimpleTransactionBubble(
                title: "Coffee Run",
                amount: 15.75,
                paidBy: "Sarah",
                isSent: false,
                showTail: false
            )
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}
