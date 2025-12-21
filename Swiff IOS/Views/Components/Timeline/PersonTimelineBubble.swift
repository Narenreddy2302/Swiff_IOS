//
//  PersonTimelineBubble.swift
//  Swiff IOS
//
//  Timeline bubble component for PersonDetailView
//  Simplified design - clean info display with long-press context menu
//

import SwiftUI

// MARK: - Person Timeline Bubble

struct PersonTimelineBubble: View {
    let item: PersonTimelineItem
    let person: Person
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch item {
            case .transaction(let transaction, _):
                transactionBubble(transaction)
            case .payment(_, let amount, let direction, let description, let date):
                paymentBubble(amount: amount, direction: direction, description: description, date: date)
            case .paidBill(_, let personName, let date):
                paidBillBubble(personName: personName, date: date)
            case .settlement:
                settlementBubble
            case .reminder:
                reminderBubble
            case .message(_, let text, let isFromPerson, let date):
                messageBubble(text: text, isFromPerson: isFromPerson, date: date)
            case .splitRequest(_, let title, let message, let billTotal, let paidBy, let youOwe, let date):
                splitRequestBubble(title: title, message: message, billTotal: billTotal, paidBy: paidBy, youOwe: youOwe, date: date)
            }
        }
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }

    // MARK: - Transaction Bubble

    @ViewBuilder
    private func transactionBubble(_ transaction: Transaction) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row - consistent 14px font
            HStack(spacing: 0) {
                Text(transaction.isExpense ? "You" : person.name)
                    .font(.system(size: 14, weight: .semibold))
                Text(transaction.isExpense ? " paid \(person.name)" : " paid you")
                    .font(.system(size: 14))

                Spacer()

                Text(relativeTime(transaction.date))
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }
            .foregroundColor(.wisePrimaryText)

            // Nested card - cleaner design
            NestedCardView(senderName: nil, senderInitials: nil) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(transaction.title)
                        .font(.system(size: 14))
                        .foregroundColor(.wisePrimaryText)

                    HStack {
                        Text(transaction.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        Text(transaction.formattedAmount)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(transaction.isExpense ? .amountNegative : .amountPositive)
                    }
                }
            }
        }
    }

    // MARK: - Payment Bubble

    @ViewBuilder
    private func paymentBubble(amount: Double, direction: PaymentDirection, description: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row - consistent 14px font
            HStack(spacing: 0) {
                Text(direction == .incoming ? person.name : "You")
                    .font(.system(size: 14, weight: .semibold))
                Text(" paid ")
                    .font(.system(size: 14))
                Text(direction == .incoming ? "you" : person.name)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }
            .foregroundColor(.wisePrimaryText)

            // Nested card - consistent font
            NestedCardView(senderName: nil, senderInitials: nil) {
                HStack {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.amountPositive)
                }
            }
        }
    }

    // MARK: - Paid Bill Bubble

    @ViewBuilder
    private func paidBillBubble(personName: String, date: Date) -> some View {
        HStack(spacing: 0) {
            Text(personName)
                .font(.system(size: 14, weight: .semibold))
            Text(" paid the bill")
                .font(.system(size: 14))

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)
        }
        .foregroundColor(.wisePrimaryText)
    }

    // MARK: - Settlement Bubble

    private var settlementBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.amountPositive)
            Text("Balance settled")
                .font(.system(size: 14))
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Reminder Bubble

    private var reminderBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseWarning)
            Text("Reminder sent")
                .font(.system(size: 14))
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(text: String, isFromPerson: Bool, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row - consistent 14px font
            HStack(spacing: 0) {
                Text(isFromPerson ? person.name : "You")
                    .font(.system(size: 14, weight: .semibold))
                Text(" sent a message")
                    .font(.system(size: 14))

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }
            .foregroundColor(.wisePrimaryText)

            // Message card - consistent font
            NestedCardView(senderName: nil, senderInitials: nil) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.wisePrimaryText)
            }
        }
    }

    // MARK: - Split Request Bubble

    @ViewBuilder
    private func splitRequestBubble(title: String, message: String?, billTotal: Double, paidBy: String, youOwe: Double, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row - consistent 14px font
            HStack(spacing: 0) {
                Text(person.name)
                    .font(.system(size: 14, weight: .semibold))
                Text(" requested a split")
                    .font(.system(size: 14))

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }
            .foregroundColor(.wisePrimaryText)

            // Split request card - simplified, no avatar
            NestedCardView(senderName: nil, senderInitials: nil) {
                VStack(alignment: .leading, spacing: 10) {
                    // Message if present
                    if let message = message, !message.isEmpty {
                        Text(message)
                            .font(.system(size: 14))
                            .foregroundColor(.wisePrimaryText)
                    }

                    // Transaction details - cleaner layout
                    VStack(spacing: 6) {
                        detailRow(label: "Bill total", value: formatCurrency(billTotal))
                        detailRow(label: "Paid by", value: paidBy)

                        // You owe - consistent font, red color
                        HStack {
                            Text("You owe")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                            Spacer()
                            Text(formatCurrency(youOwe))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.amountNegative)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Detail Row Helper

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.wiseSecondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wisePrimaryText)
        }
    }

    // MARK: - Helper Functions

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Preview

#Preview("PersonTimelineBubble - Transaction") {
    VStack(spacing: 16) {
        PersonTimelineBubble(
            item: .transaction(MockData.expenseTransaction, MockData.personOwingMoney),
            person: MockData.personOwingMoney,
            onEdit: { print("Edit tapped") }
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("PersonTimelineBubble - Payment") {
    VStack(spacing: 16) {
        PersonTimelineBubble(
            item: .payment(id: UUID(), amount: 8.50, direction: .outgoing, description: "Coffee last week", date: Date()),
            person: MockData.personOwingMoney
        )

        PersonTimelineBubble(
            item: .payment(id: UUID(), amount: 45.00, direction: .incoming, description: "Dinner split", date: Date()),
            person: MockData.personOwedMoney
        )

        PersonTimelineBubble(
            item: .paidBill(id: UUID(), personName: "Jordan", date: Date()),
            person: MockData.personOwedMoney
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("PersonTimelineBubble - Split Request") {
    VStack(spacing: 16) {
        PersonTimelineBubble(
            item: .splitRequest(
                id: UUID(),
                title: "Dinner",
                message: "Hey! I covered dinner last night. Can you send me your share?",
                billTotal: 97.50,
                paidBy: "Jordan",
                youOwe: 48.75,
                date: Date()
            ),
            person: MockData.personOwingMoney,
            onEdit: { print("Edit tapped") }
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("PersonTimelineBubble - System Events") {
    VStack(spacing: 16) {
        PersonTimelineBubble(
            item: .settlement(id: UUID(), date: Date()),
            person: MockData.personSettled
        )

        PersonTimelineBubble(
            item: .reminder(id: UUID(), date: Date()),
            person: MockData.personOwedMoney
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}
