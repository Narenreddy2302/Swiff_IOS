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
        SwiftUI.Group {
            switch item {
            case .transaction(let transaction, _):
                transactionBubble(transaction)
            case .payment(_, let amount, let direction, let description, let date):
                paymentBubble(amount: amount, direction: direction, description: description, date: date)
            case .paidBill(_, let personName, let date):
                paidBillBubble(personName: personName, date: date)
            case .settlement(_, let date):
                settlementBubble(date: date)
            case .reminder(_, let date):
                reminderBubble(date: date)
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
        ConversationBubbleView(type: transaction.isExpense ? .outgoing : .incoming) {
            VStack(alignment: transaction.isExpense ? .trailing : .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                
                if !transaction.subtitle.isEmpty {
                    Text(transaction.subtitle)
                        .font(.system(size: 14))
                        .opacity(0.8)
                }
                
                Text(transaction.formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                
                Text(relativeTime(transaction.date))
                    .font(.system(size: 11))
                    .opacity(0.6)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Payment Bubble

    @ViewBuilder
    private func paymentBubble(amount: Double, direction: PaymentDirection, description: String, date: Date) -> some View {
        ConversationBubbleView(type: direction == .outgoing ? .outgoing : .incoming) {
            VStack(alignment: direction == .outgoing ? .trailing : .leading, spacing: 4) {
                Text(description.isEmpty ? "Payment" : description)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .bold))
                
                Text(relativeTime(date))
                    .font(.system(size: 11))
                    .opacity(0.6)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Paid Bill Bubble

    @ViewBuilder
    private func paidBillBubble(personName: String, date: Date) -> some View {
        ConversationBubbleView(type: .incoming) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(personName) paid the bill")
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                
                Text(relativeTime(date))
                    .font(.system(size: 11))
                    .opacity(0.6)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Settlement Bubble

    private func settlementBubble(date: Date) -> some View {
        ConversationBubbleView(type: .systemEvent) {
            VStack(spacing: 2) {
                Text("Balance Settled")
                    .font(.system(size: 12, weight: .bold))
                Text(relativeTime(date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Reminder Bubble

    private func reminderBubble(date: Date) -> some View {
        ConversationBubbleView(type: .systemEvent) {
            VStack(spacing: 2) {
                Text("Reminder Sent")
                    .font(.system(size: 12, weight: .bold))
                Text(relativeTime(date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(text: String, isFromPerson: Bool, date: Date) -> some View {
        ConversationBubbleView(type: isFromPerson ? .incoming : .outgoing) {
            VStack(alignment: isFromPerson ? .leading : .trailing, spacing: 4) {
                Text(text)
                    .font(.system(size: 16))
                
                Text(relativeTime(date))
                    .font(.system(size: 11))
                    .opacity(0.6)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Split Request Bubble

    @ViewBuilder
    private func splitRequestBubble(title: String, message: String?, billTotal: Double, paidBy: String, youOwe: Double, date: Date) -> some View {
        // If 'youOwe' > 0, someone requested money FROM you -> Incoming bubble
        // If 'youOwe' == 0 (implied you requested), it would likely be outgoing.
        // Assuming split request here usually means "Someone requested a split".
        // Let's assume incoming if person name is involved, but here we don't know who initiated easily without logic.
        // Based on logic: "Person requested a split" -> Incoming.
        
        ConversationBubbleView(type: .incoming) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Split Request: \(title)")
                    .font(.system(size: 16, weight: .bold))
                
                if let message = message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16))
                }
                
                Divider().background(Color.primary.opacity(0.2))
                
                HStack {
                    Text("Total: \(formatCurrency(billTotal))")
                        .font(.system(size: 12))
                    Spacer()
                    Text("You owe: \(formatCurrency(youOwe))")
                        .font(.system(size: 12, weight: .bold))
                }
                
                Text(relativeTime(date))
                    .font(.system(size: 11))
                    .opacity(0.6)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Helper Functions

    private func relativeTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
