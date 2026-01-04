//
//  GroupActivityBubble.swift
//  Swiff IOS
//
//  Expense activity bubble for group conversation view
//  Shows payer, expense details, split members, and settlement status
//

import SwiftUI

// MARK: - Group Activity Bubble

struct GroupActivityBubble: View {
    let expense: GroupExpense
    let payer: Person?
    let splitMembers: [Person]
    let currentUserId: UUID?
    var onSettle: (() -> Void)?

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: expense.date, relativeTo: Date())
    }

    private var splitMemberInitials: [String] {
        splitMembers.map { InitialsGenerator.generate(from: $0.name) }
    }

    private var splitMemberColors: [Color] {
        splitMembers.map { InitialsAvatarColors.color(for: $0.name) }
    }

    private var settlementStatus: SettlementStatus {
        expense.isSettled ? .settled : .pending
    }

    private var userOwesAmount: Double? {
        guard let currentUserId = currentUserId,
              expense.splitBetween.contains(currentUserId),
              expense.paidBy != currentUserId,
              !expense.isSettled else {
            return nil
        }
        return expense.amountPerPerson
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Payer info + time
            headerSection

            Divider()
                .padding(.vertical, 12)

            // Main content: Title + Amount
            mainContentSection

            Divider()
                .padding(.vertical, 12)

            // Footer: Split members + Status
            footerSection

            // Quick settle button (if user owes)
            if let owedAmount = userOwesAmount, let onSettle = onSettle {
                settleButton(amount: owedAmount, action: onSettle)
            }
        }
        .padding(14)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 10) {
            // Payer avatar (32pt)
            if let payer = payer {
                AvatarView(person: payer, size: .medium, style: .solid)
                    .frame(width: 32, height: 32)
            } else {
                Circle()
                    .fill(InitialsAvatarColors.gray)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(payer?.name ?? "Unknown")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)

                    Text("paid")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                Text("for \(expense.category.rawValue.lowercased())")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Time
            Text(relativeTime)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Main Content Section

    @ViewBuilder
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(expense.title)
                .font(.spotifyBodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.wisePrimaryText)

            Text(String(format: "$%.2f", expense.amount))
                .font(.spotifyNumberMedium)
                .fontWeight(.bold)
                .foregroundColor(.wisePrimaryText)

            if !expense.notes.isEmpty {
                Text(expense.notes)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Footer Section

    @ViewBuilder
    private var footerSection: some View {
        HStack(spacing: 12) {
            // Split members avatar stack
            HStack(spacing: 4) {
                Text("Split:")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)

                SmallAvatarStack(
                    initials: splitMemberInitials,
                    colors: splitMemberColors,
                    maxVisible: 4,
                    avatarSize: 24,
                    overlap: 6
                )
            }

            Spacer()

            // Settlement status badge
            SettlementStatusBadge(status: settlementStatus, isCompact: true)
        }
    }

    // MARK: - Settle Button

    @ViewBuilder
    private func settleButton(amount: Double, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, 12)

            QuickActionButton(
                title: String(format: "Settle My Share: $%.2f", amount),
                icon: "checkmark.circle.fill",
                style: .primary,
                action: action
            )
        }
    }
}

// MARK: - Preview

#Preview("GroupActivityBubble - Pending") {
    ScrollView {
        VStack(spacing: 14) {
            GroupActivityBubble(
                expense: MockData.groupWithExpenses.expenses[0],
                payer: MockData.personOwedMoney,
                splitMembers: [MockData.personOwedMoney, MockData.personOwingMoney, MockData.personSettled],
                currentUserId: MockData.personOwingMoney.id,
                onSettle: { print("Settle tapped") }
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("GroupActivityBubble - Settled") {
    ScrollView {
        VStack(spacing: 14) {
            GroupActivityBubble(
                expense: MockData.settledGroup.expenses[0],
                payer: MockData.personFriend,
                splitMembers: [MockData.personOwedMoney, MockData.personFriend, MockData.personFamily],
                currentUserId: nil,
                onSettle: nil
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}

#Preview("GroupActivityBubble - Large Group") {
    ScrollView {
        VStack(spacing: 14) {
            GroupActivityBubble(
                expense: MockData.largeGroup.expenses[0],
                payer: MockData.personOwedMoney,
                splitMembers: MockData.people,
                currentUserId: nil,
                onSettle: nil
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
