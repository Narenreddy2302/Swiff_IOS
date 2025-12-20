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

#Preview("Group Activity Bubbles") {
    ScrollView {
        VStack(spacing: 14) {
            // Pending expense with settle button
            GroupActivityBubble(
                expense: GroupExpense(
                    title: "Dinner at Italian Place",
                    amount: 120.00,
                    paidBy: UUID(),
                    splitBetween: [UUID(), UUID(), UUID(), UUID()],
                    category: .dining,
                    notes: "Amazing pasta and wine!",
                    isSettled: false
                ),
                payer: Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                splitMembers: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2)),
                    Person(name: "Sarah Wilson", email: "sarah@example.com", phone: "", avatarType: .initials("SW", colorIndex: 3))
                ],
                currentUserId: UUID(),
                onSettle: { print("Settle tapped") }
            )

            // Settled expense
            GroupActivityBubble(
                expense: GroupExpense(
                    title: "Weekend Groceries",
                    amount: 85.50,
                    paidBy: UUID(),
                    splitBetween: [UUID(), UUID(), UUID()],
                    category: .groceries,
                    notes: "",
                    isSettled: true
                ),
                payer: Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                splitMembers: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2))
                ],
                currentUserId: nil,
                onSettle: nil
            )

            // Expense with many split members
            GroupActivityBubble(
                expense: GroupExpense(
                    title: "Office Pizza Party",
                    amount: 180.00,
                    paidBy: UUID(),
                    splitBetween: [UUID(), UUID(), UUID(), UUID(), UUID(), UUID()],
                    category: .food,
                    notes: "Team celebration for successful launch",
                    isSettled: false
                ),
                payer: Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2)),
                splitMembers: [
                    Person(name: "Alex Thompson", email: "alex@example.com", phone: "", avatarType: .initials("AT", colorIndex: 0)),
                    Person(name: "Maria Santos", email: "maria@example.com", phone: "", avatarType: .initials("MS", colorIndex: 1)),
                    Person(name: "John Davis", email: "john@example.com", phone: "", avatarType: .initials("JD", colorIndex: 2)),
                    Person(name: "Sarah Wilson", email: "sarah@example.com", phone: "", avatarType: .initials("SW", colorIndex: 3)),
                    Person(name: "Mike Brown", email: "mike@example.com", phone: "", avatarType: .initials("MB", colorIndex: 4)),
                    Person(name: "Chris Johnson", email: "chris@example.com", phone: "", avatarType: .initials("CJ", colorIndex: 0))
                ],
                currentUserId: nil,
                onSettle: nil
            )

            // Small expense
            GroupActivityBubble(
                expense: GroupExpense(
                    title: "Coffee Run",
                    amount: 18.50,
                    paidBy: UUID(),
                    splitBetween: [UUID(), UUID()],
                    category: .food,
                    notes: "",
                    isSettled: false
                ),
                payer: Person(name: "Sarah Wilson", email: "sarah@example.com", phone: "", avatarType: .initials("SW", colorIndex: 3)),
                splitMembers: [
                    Person(name: "Sarah Wilson", email: "sarah@example.com", phone: "", avatarType: .initials("SW", colorIndex: 3)),
                    Person(name: "Mike Brown", email: "mike@example.com", phone: "", avatarType: .initials("MB", colorIndex: 4))
                ],
                currentUserId: UUID(),
                onSettle: { print("Settle coffee") }
            )
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
