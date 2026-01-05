//
//  TransactionRowView.swift
//  Swiff IOS
//
//  Redesigned transaction row for feed page
//  Layout: 48x48 Avatar | Name + Time · Category | Amount + Entity Name
//

import SwiftUI

// MARK: - Feed Transaction Row

/// Modern transaction row for feed display
/// Layout: 48x48 avatar | Name (15pt semibold) + Time · Category (13pt) | Amount (15pt semibold) + Entity (13pt)
struct FeedTransactionRow: View {
    @EnvironmentObject var dataManager: DataManager

    let transaction: Transaction
    let isLastInGroup: Bool
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { onTap?() }) {
                HStack(spacing: 14) {
                    // Avatar - initials with colored background
                    initialsAvatar

                    // Left side - Name and Time · Category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.Colors.feedPrimaryText)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(transaction.formattedTime)
                                .foregroundColor(Theme.Colors.feedSecondaryText)

                            Text("·")
                                .foregroundColor(Theme.Colors.feedTertiaryText)

                            Text(transaction.category.rawValue)
                                .foregroundColor(Theme.Colors.feedTertiaryText)
                        }
                        .font(.system(size: 13))
                    }

                    Spacer(minLength: 8)

                    // Right side - Amount and Entity Name
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedAmount)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(amountColor)

                        Text(entityDisplayName)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.feedSecondaryText)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(displayName), \(formattedAmount), \(entityDisplayName)")

            // Divider (if not last in group)
            if !isLastInGroup {
                Rectangle()
                    .fill(Theme.Colors.feedDivider)
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Computed Properties

    private var displayName: String {
        transaction.displayName
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? String(format: "%.2f", abs(transaction.amount))
        let prefix = transaction.isExpense ? "-$" : "+$"
        return "\(prefix)\(formatted)"
    }

    private var amountColor: Color {
        transaction.isExpense ? Theme.Colors.amountNegative : Theme.Colors.feedPositiveAmount
    }

    /// Entity display name for the right side
    /// Priority: Subscription > Group > Person > Merchant > Title
    private var entityDisplayName: String {
        // 1. Check if linked to a subscription
        if let subscriptionId = transaction.linkedSubscriptionId,
           let subscription = dataManager.subscriptions.first(where: { $0.id == subscriptionId }) {
            return subscription.name
        }

        // 2. Check if linked to a split bill/group
        if let splitBillId = transaction.splitBillId,
           let splitBill = dataManager.splitBills.first(where: { $0.id == splitBillId }) {
            // Find the group this split bill belongs to
            if let group = dataManager.groups.first(where: { $0.expenses.contains(where: { $0.id == splitBillId }) }) {
                return group.name
            }
            return splitBill.title
        }

        // 3. Check for related person (by searching for a match in people)
        // Try to find a person whose name matches the transaction title
        if let person = dataManager.people.first(where: { $0.name.lowercased() == transaction.title.lowercased() }) {
            return person.name
        }

        // 4. Fallback to merchant or title
        return transaction.merchant ?? transaction.title
    }

    // MARK: - Avatar

    private var avatarColor: FeedAvatarColor {
        FeedAvatarColor.forName(displayName)
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(InitialsGenerator.generate(from: displayName))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(avatarColor.foreground)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Feed Row Divider

/// Full-width divider for separating transaction groups
struct FeedRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.feedDivider)
            .frame(height: 1)
    }
}

// MARK: - Legacy Compatibility

/// Wrapper for backward compatibility with existing code
struct TransactionRowView: View {
    @EnvironmentObject var dataManager: DataManager

    let transaction: Transaction
    var isLastInGroup: Bool = true
    var onTap: (() -> Void)? = nil

    var body: some View {
        FeedTransactionRow(
            transaction: transaction,
            isLastInGroup: isLastInGroup,
            onTap: onTap
        )
        .environmentObject(dataManager)
    }
}

// MARK: - Preview

#Preview("FeedTransactionRow - Various Types") {
    ScrollView {
        VStack(spacing: 0) {
            // Income - Receive
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Mikel Borle",
                    subtitle: "Payment received",
                    amount: 350.00,
                    category: .income,
                    date: Date(),
                    isRecurring: false,
                    tags: []
                ),
                isLastInGroup: false
            )
            .padding(.horizontal, 20)

            // Transfer - Uber
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Uber",
                    subtitle: "Trip to downtown",
                    amount: -10.00,
                    category: .transportation,
                    date: Date(),
                    isRecurring: false,
                    tags: [],
                    merchant: "Uber"
                ),
                isLastInGroup: false
            )
            .padding(.horizontal, 20)

            // Send - Person
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Ryan Scott",
                    subtitle: "Split dinner",
                    amount: -124.00,
                    category: .food,
                    date: Date(),
                    isRecurring: false,
                    tags: []
                ),
                isLastInGroup: false
            )
            .padding(.horizontal, 20)

            // Payment - Food Panda
            FeedTransactionRow(
                transaction: Transaction(
                    title: "Food Panda",
                    subtitle: "Food delivery",
                    amount: -21.56,
                    category: .food,
                    date: Date(),
                    isRecurring: false,
                    tags: [],
                    merchant: "Food Panda"
                ),
                isLastInGroup: true
            )
            .padding(.horizontal, 20)
        }
    }
    .background(Theme.Colors.background)
    .environmentObject(DataManager.shared)
}

#Preview("FeedTransactionRow - Edge Cases") {
    VStack(spacing: 0) {
        // Large amount
        FeedTransactionRow(
            transaction: Transaction(
                title: "Salary Deposit",
                subtitle: "Monthly salary",
                amount: 5000.00,
                category: .income,
                date: Date(),
                isRecurring: true,
                tags: []
            ),
            isLastInGroup: false
        )
        .padding(.horizontal, 20)

        // Small amount
        FeedTransactionRow(
            transaction: Transaction(
                title: "Coffee",
                subtitle: "Starbucks",
                amount: -4.50,
                category: .food,
                date: Date(),
                isRecurring: false,
                tags: [],
                merchant: "Starbucks"
            ),
            isLastInGroup: false
        )
        .padding(.horizontal, 20)

        // Pending request
        FeedTransactionRow(
            transaction: Transaction(
                title: "John Smith",
                subtitle: "Dinner split request",
                amount: 50.00,
                category: .food,
                date: Date(),
                isRecurring: false,
                tags: [],
                paymentStatus: .pending
            ),
            isLastInGroup: true
        )
        .padding(.horizontal, 20)
    }
    .background(Theme.Colors.background)
    .environmentObject(DataManager.shared)
}
