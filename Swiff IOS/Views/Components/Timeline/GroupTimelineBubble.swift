//
//  GroupTimelineBubble.swift
//  Swiff IOS
//
//  Timeline bubble component for GroupDetailView
//  Renders different bubble types based on GroupTimelineItem
//

import SwiftUI

// MARK: - Group Timeline Bubble

struct GroupTimelineBubble: View {
    let item: GroupTimelineItem
    var onSettle: (() -> Void)?

    var body: some View {
        switch item {
        case .expense(let expense, let payer, let splitMembers):
            expenseBubble(expense: expense, payer: payer, splitMembers: splitMembers)
        case .memberJoined(_, let person, _):
            memberEventBubble(person: person, joined: true)
        case .memberLeft(_, let person, _):
            memberEventBubble(person: person, joined: false)
        case .settlement(_, let expense, _):
            settlementBubble(expense: expense)
        case .splitBillCreated(let splitBill):
            splitBillBubble(splitBill: splitBill)
        }
    }

    // MARK: - Expense Bubble

    @ViewBuilder
    private func expenseBubble(expense: GroupExpense, payer: Person?, splitMembers: [Person]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 0) {
                Text(payer?.name ?? "Someone")
                    .font(.spotifyCaptionMedium)
                    .fontWeight(.semibold)
                Text(" requested a split")
                    .font(.spotifyCaptionMedium)

                Text(relativeTime(expense.date))
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }
            .foregroundColor(.wisePrimaryText)

            // Nested card with details
            NestedCardView(
                senderName: payer?.name,
                senderInitials: payer.map { InitialsGenerator.generate(from: $0.name) }
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    // Message/title
                    if !expense.title.isEmpty {
                        Text(expense.title)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    // Transaction details
                    TransactionDetailsCard(
                        billTotal: expense.amount,
                        paidBy: payer?.name ?? "Unknown",
                        youOwe: expense.amountPerPerson
                    )
                }
            }

            // Quick actions
            if !expense.isSettled {
                if let onSettle = onSettle {
                    QuickActionButton.settle(amount: expense.amountPerPerson, action: onSettle)
                }
            }
        }
    }

    // MARK: - Member Event Bubble

    @ViewBuilder
    private func memberEventBubble(person: Person, joined: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: joined ? "person.badge.plus" : "person.badge.minus")
                .font(.system(size: 14))
                .foregroundColor(joined ? .wiseBlue : .wiseSecondaryText)
            Text("\(person.name) \(joined ? "joined" : "left") the group")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Settlement Bubble

    @ViewBuilder
    private func settlementBubble(expense: GroupExpense) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseBrightGreen)
            Text("'\(expense.title)' settled")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Split Bill Bubble

    @ViewBuilder
    private func splitBillBubble(splitBill: SplitBill) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Text("New split bill created")
                    .font(.spotifyCaptionMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)
            }

            NestedCardView(senderName: nil, senderInitials: nil) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(splitBill.title)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text("\(splitBill.participants.count) participants")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("GroupTimelineBubble - Expense") {
    VStack(spacing: 16) {
        GroupTimelineBubble(
            item: .expense(
                MockData.groupWithExpenses.expenses[0],
                payer: MockData.personOwedMoney,
                splitMembers: [MockData.personOwedMoney, MockData.personOwingMoney, MockData.personSettled]
            ),
            onSettle: { print("Settle tapped") }
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("GroupTimelineBubble - Member Events") {
    VStack(spacing: 16) {
        GroupTimelineBubble(
            item: .memberJoined(
                id: UUID(),
                person: MockData.personFriend,
                date: Date()
            )
        )

        GroupTimelineBubble(
            item: .memberLeft(
                id: UUID(),
                person: MockData.personCoworker,
                date: Date()
            )
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("GroupTimelineBubble - Settlement") {
    VStack(spacing: 16) {
        GroupTimelineBubble(
            item: .settlement(
                id: UUID(),
                expense: MockData.settledGroup.expenses[0],
                date: Date()
            )
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("GroupTimelineBubble - Split Bill") {
    VStack(spacing: 16) {
        GroupTimelineBubble(
            item: .splitBillCreated(MockData.pendingSplitBill)
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}
