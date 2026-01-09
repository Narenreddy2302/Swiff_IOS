//
//  DueBubbleContent.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Bubble content for displaying due transactions in conversation view
//

import SwiftUI

struct DueBubbleContent: View {
    let description: String
    let amount: Double
    let category: TransactionCategory
    let isTheyOweMe: Bool  // true = they owe you (incoming), false = you owe them (outgoing)
    let isSettled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category icon and description
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .foregroundColor(categoryColor)

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Amount with direction indicator
            HStack(spacing: 4) {
                Image(systemName: isTheyOweMe ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))

                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .semibold))
                    .strikethrough(isSettled, color: .wiseSecondaryText)

                if isSettled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseBrightGreen)
                }
            }

            // Direction label
            Text(isTheyOweMe ? "owes you" : "you owe")
                .font(.system(size: 11))
                .opacity(0.7)
        }
    }

    private var categoryColor: Color {
        switch category {
        case .food: return .orange
        case .dining: return .orange
        case .groceries: return .green
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .utilities: return .yellow
        case .bills: return .brown
        case .healthcare: return .red
        case .travel: return .cyan
        case .income: return .green
        case .transfer: return .gray
        case .investment: return .indigo
        case .other: return .gray
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}

// MARK: - Due Bubble Content with SplitBill

extension DueBubbleContent {
    /// Initialize from a SplitBill
    init(splitBill: SplitBill, isTheyOweMe: Bool) {
        self.description = splitBill.title
        self.amount = splitBill.totalAmount
        self.category = splitBill.category
        self.isTheyOweMe = isTheyOweMe
        self.isSettled = splitBill.isFullySettled
    }
}

// MARK: - Preview

#Preview("Due Bubble - They Owe Me") {
    VStack(spacing: 20) {
        ChatBubble(direction: .incoming, timestamp: Date()) {
            DueBubbleContent(
                description: "Lunch at Italian restaurant",
                amount: 45.50,
                category: .food,
                isTheyOweMe: true,
                isSettled: false
            )
        }

        ChatBubble(direction: .outgoing, timestamp: Date()) {
            DueBubbleContent(
                description: "Movie tickets",
                amount: 25.00,
                category: .entertainment,
                isTheyOweMe: false,
                isSettled: false
            )
        }

        ChatBubble(direction: .incoming, timestamp: Date()) {
            DueBubbleContent(
                description: "Coffee",
                amount: 8.50,
                category: .food,
                isTheyOweMe: true,
                isSettled: true
            )
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
