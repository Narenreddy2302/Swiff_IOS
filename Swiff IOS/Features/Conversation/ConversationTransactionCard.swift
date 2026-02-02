//
//  ConversationTransactionCard.swift
//  Swiff IOS
//
//  Professional transaction card component for conversation views
//  Follows Apple HIG and industry standards
//  Updated to match reference design with proper layout and styling
//

import SwiftUI

// MARK: - Conversation Transaction Card

/// Professional transaction card matching reference design
/// Features:
/// - Header text outside card (e.g., "You Created the transaction")
/// - Title and amount in top section
/// - Detail rows with labels and values
/// - Clean rectangular design with subtle borders
struct ConversationTransactionCard: View {
    let headerText: String  // e.g., "You Created the transaction"
    let title: String  // e.g., "Payment to Li Wei"
    let amount: String  // e.g., "$250.00"
    let amountLabel: String  // e.g., "You Lent"
    let amountColor: Color  // Color for amount (green for lent, red for owe)
    let metadata: [ConversationTransactionMetadata]
    var onTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header text outside the card
            Text(headerText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
                .lineLimit(1)
                .padding(.leading, 16)

            // Main card
            VStack(spacing: 0) {
                // Top section: Title and Amount
                HStack(alignment: .top, spacing: 12) {
                    // Title
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    Spacer()

                    // Amount section (right-aligned)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(amount)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(amountColor)

                        Text(amountLabel)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(amountColor.opacity(0.75))
                    }
                }
                .padding(14)

                // Divider
                Rectangle()
                    .fill(Color.wiseSeparator.opacity(0.5))
                    .frame(height: 0.5)

                // Detail rows
                VStack(spacing: 0) {
                    ForEach(Array(metadata.enumerated()), id: \.offset) { index, item in
                        ConversationTransactionMetadataRow(metadata: item)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.wiseSeparator.opacity(0.5), lineWidth: 0.5)
            )
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Conversation Transaction Type

enum ConversationTransactionType {
    case payment  // Direct payment
    case request  // Money request
    case split  // Bill split
    case expense  // Group expense

    var icon: String {
        switch self {
        case .payment: return "arrow.up.circle.fill"
        case .request: return "arrow.down.circle.fill"
        case .split: return "square.split.2x2.fill"
        case .expense: return "receipt.fill"
        }
    }

    var color: Color {
        switch self {
        case .payment: return .wiseBrightGreen
        case .request: return .wiseOrange
        case .split: return .wiseBlue
        case .expense: return .wiseAccentBlue
        }
    }
}

// MARK: - Conversation Transaction Metadata

struct ConversationTransactionMetadata {
    let label: String
    let value: String
    let valueColor: Color?
    let icon: String?

    init(label: String, value: String, valueColor: Color? = nil, icon: String? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.icon = icon
    }
}

// MARK: - Conversation Transaction Metadata Row

struct ConversationTransactionMetadataRow: View {
    let metadata: ConversationTransactionMetadata

    var body: some View {
        HStack(alignment: .top) {
            // Label (left-aligned)
            Text(metadata.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            // Value (right-aligned)
            HStack(spacing: 6) {
                if let icon = metadata.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(metadata.valueColor ?? .wisePrimaryText)
                }

                Text(metadata.value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(metadata.valueColor ?? .wisePrimaryText)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 9)
    }
}

// MARK: - Conversation Transaction Card Builder

/// Helper to build transaction cards from data
struct ConversationTransactionCardBuilder {

    /// Create a payment card (You lent money to someone)
    static func payment(
        to personName: String,
        amount: String,
        totalBill: String,
        paidBy: String = "You",
        splitMethod: String = "Equally",
        participants: String,
        creatorName: String = "You",
        note: String? = nil,
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        let metadata: [ConversationTransactionMetadata] = [
            ConversationTransactionMetadata(label: "Total Bill", value: totalBill),
            ConversationTransactionMetadata(label: "Paid by", value: paidBy),
            ConversationTransactionMetadata(label: "Split Method", value: splitMethod),
            ConversationTransactionMetadata(label: "Who are all involved", value: participants),
        ]

        return ConversationTransactionCard(
            headerText: "\(creatorName) created this",
            title: "Payment to \(personName)",
            amount: amount,
            amountLabel: "You Lent",
            amountColor: .wiseBrightGreen,
            metadata: metadata,
            onTap: onTap
        )
    }

    /// Create a request card (You're requesting money from someone)
    static func request(
        from personName: String,
        amount: String,
        totalBill: String,
        paidBy: String = "You",
        splitMethod: String,
        participants: String,
        creatorName: String = "You",
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        let metadata: [ConversationTransactionMetadata] = [
            ConversationTransactionMetadata(label: "Total Bill", value: totalBill),
            ConversationTransactionMetadata(label: "Paid by", value: paidBy),
            ConversationTransactionMetadata(label: "Split Method", value: splitMethod),
            ConversationTransactionMetadata(label: "Who are all involved", value: participants),
        ]

        return ConversationTransactionCard(
            headerText: "\(creatorName) created this",
            title: "Request from \(personName)",
            amount: amount,
            amountLabel: "You Lent",
            amountColor: .wiseBrightGreen,
            metadata: metadata,
            onTap: onTap
        )
    }

    /// Create an owe card (You owe money to someone)
    static func owe(
        to personName: String,
        amount: String,
        totalBill: String,
        paidBy: String,
        splitMethod: String = "Equally",
        participants: String,
        creatorName: String,
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        let metadata: [ConversationTransactionMetadata] = [
            ConversationTransactionMetadata(label: "Total Bill", value: totalBill),
            ConversationTransactionMetadata(label: "Paid by", value: paidBy),
            ConversationTransactionMetadata(label: "Split Method", value: splitMethod),
            ConversationTransactionMetadata(label: "Who are all involved", value: participants),
        ]

        return ConversationTransactionCard(
            headerText: "\(creatorName) created this",
            title: "Payment from \(personName)",
            amount: amount,
            amountLabel: "You Owe",
            amountColor: .wiseOrange,
            metadata: metadata,
            onTap: onTap
        )
    }

    /// Create a split expense card
    static func split(
        description: String,
        amount: String,
        totalBill: String,
        paidBy: String,
        splitMethod: String,
        participants: String,
        creatorName: String,
        isUserPayer: Bool,
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        let metadata: [ConversationTransactionMetadata] = [
            ConversationTransactionMetadata(label: "Total Bill", value: totalBill),
            ConversationTransactionMetadata(label: "Paid by", value: paidBy),
            ConversationTransactionMetadata(label: "Split Method", value: splitMethod),
            ConversationTransactionMetadata(label: "Who are all involved", value: participants),
        ]

        let amountLabel = isUserPayer ? "You Lent" : "You Owe"
        let amountColor: Color = isUserPayer ? .wiseBrightGreen : .wiseOrange

        return ConversationTransactionCard(
            headerText: "\(creatorName) created this",
            title: description,
            amount: amount,
            amountLabel: amountLabel,
            amountColor: amountColor,
            metadata: metadata,
            onTap: onTap
        )
    }

    /// Create a group expense card
    static func groupExpense(
        description: String,
        amount: String,
        totalBill: String,
        paidBy: String,
        splitMethod: String = "Equally",
        participants: String,
        creatorName: String,
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        let metadata: [ConversationTransactionMetadata] = [
            ConversationTransactionMetadata(label: "Total Bill", value: totalBill),
            ConversationTransactionMetadata(label: "Paid by", value: paidBy),
            ConversationTransactionMetadata(label: "Split Method", value: splitMethod),
            ConversationTransactionMetadata(label: "Who are all involved", value: participants),
        ]

        return ConversationTransactionCard(
            headerText: "\(creatorName) created this",
            title: description,
            amount: amount,
            amountLabel: "Your Share",
            amountColor: .wiseOrange,
            metadata: metadata,
            onTap: onTap
        )
    }
}

// MARK: - Preview

#Preview("Conversation Transaction Cards") {
    ScrollView {
        VStack(spacing: 16) {
            // Payment Card - You Lent
            ConversationTransactionCardBuilder.payment(
                to: "Li Wei",
                amount: "$250.00",
                totalBill: "$250.00",
                paidBy: "You",
                splitMethod: "Equally",
                participants: "You, Li Wei",
                creatorName: "You",
                onTap: {}
            )
            .padding(.horizontal, 12)

            // Request Card - You Lent (Large Request)
            ConversationTransactionCardBuilder.request(
                from: "Li Wei",
                amount: "$500.00",
                totalBill: "$500.00",
                paidBy: "You",
                splitMethod: "Equally",
                participants: "You, Li Wei",
                creatorName: "You",
                onTap: {}
            )
            .padding(.horizontal, 12)

            // Owe Card - You Owe
            ConversationTransactionCardBuilder.owe(
                to: "Li Wei",
                amount: "$125.00",
                totalBill: "$250.00",
                paidBy: "Li Wei",
                splitMethod: "Equally",
                participants: "You, Li Wei",
                creatorName: "Li Wei",
                onTap: {}
            )
            .padding(.horizontal, 12)

            // Split Card - User is payer
            ConversationTransactionCardBuilder.split(
                description: "Dinner at Restaurant",
                amount: "$45.00",
                totalBill: "$90.00",
                paidBy: "You",
                splitMethod: "Equally",
                participants: "You, Li Wei, John",
                creatorName: "You",
                isUserPayer: true,
                onTap: {}
            )
            .padding(.horizontal, 12)

            // Split Card - User owes
            ConversationTransactionCardBuilder.split(
                description: "Movie Tickets",
                amount: "$30.00",
                totalBill: "$90.00",
                paidBy: "Li Wei",
                splitMethod: "Equally",
                participants: "You, Li Wei, John",
                creatorName: "Li Wei",
                isUserPayer: false,
                onTap: {}
            )
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}
