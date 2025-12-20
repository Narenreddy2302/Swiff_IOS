//
//  ListRowFactory.swift
//  Swiff IOS
//
//  Created for Unified List View Design System - Phase 5-7
//  Factory for creating appropriate list row views based on data type
//
//  Updated to work with new unified list design components:
//  - TransactionCard: Initials-based avatars with pastel colors
//  - PersonCard: Initials-based avatars with hash-based colors
//  - GroupCard: Emoji avatars in blue circles
//  - SubscriptionCard: Initials-based avatars with category colors
//
//  All card components use:
//  - InitialsGenerator.generate(from:) for generating initials
//  - InitialsAvatarColors.color(for:) for avatar colors
//  - AmountColors.positive and AmountColors.negative for amount colors
//  - AlignedDivider() for dividers (76pt left padding)
//

import SwiftUI

/// Factory for creating appropriate list row views based on data type
struct ListRowFactory {

    // MARK: - Transaction Row

    /// Creates a row view for a Transaction
    @ViewBuilder
    static func row(for transaction: Transaction, onTap: (() -> Void)? = nil) -> some View {
        let directionIcon = transaction.isExpense ? "→" : "←"
        let directionText = transaction.isExpense ? "Sent" : "Received"

        // Get payment method text
        let paymentMethodText = transaction.paymentMethod?.shortName ?? "Card"

        // Format subtitle: "← Received – Visa • 3366" or "→ Sent – Visa • 3366"
        let subtitle = "\(directionIcon) \(directionText) – \(paymentMethodText)"

        // Format amount with sign
        let isExpense = transaction.isExpense
        let amountText = formatAmount(abs(transaction.amount), isExpense: isExpense)
        let amountColor: Color = isExpense ? .wisePrimaryText : .wiseBrightGreen

        UnifiedListRowV2(
            iconName: transaction.category.icon,
            iconColor: transaction.category.color,
            title: transaction.title,
            subtitle: subtitle,
            value: amountText,
            valueColor: amountColor,
            showChevron: true,
            onTap: onTap
        )
    }

    /// Creates a card view for a Transaction (unified list design with initials avatar)
    /// Uses TransactionCard component with:
    /// - Initials-based colored avatar (category-based pastel colors)
    /// - Clean row layout without status badges
    /// - AmountColors for positive/negative amounts
    @ViewBuilder
    static func card(for transaction: Transaction, context: CardContext = .feed, subscription: Subscription? = nil, onTap: (() -> Void)? = nil) -> some View {
        TransactionCard(
            transaction: transaction,
            context: context,
            subscription: subscription,
            onTap: onTap
        )
    }

    /// Creates a simple row view for a Transaction (without card background)
    @ViewBuilder
    static func simpleRow(for transaction: Transaction, onTap: (() -> Void)? = nil) -> some View {
        TransactionRowView(
            transaction: transaction,
            onTap: onTap
        )
    }

    // MARK: - Person Row

    /// Creates a row view for a Person
    static func row(for person: Person, transactions: [Transaction] = [], onTap: (() -> Void)? = nil) -> some View {
        // Compute all values before returning the view
        let subtitle = personSubtitle(for: person, transactions: transactions)
        let (valueText, valueColor) = personBalanceFormatted(person)

        return UnifiedAvatarRow(
            avatarType: person.avatarType,
            title: person.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: valueColor,
            showChevron: true,
            onTap: onTap
        )
    }

    /// Creates a card view for a Person (unified list design with initials avatar)
    /// Uses PersonCard component with:
    /// - Initials-based colored avatar (hash-based pastel colors from InitialsAvatarColors)
    /// - Balance status indicator (Owes you / You owe / Settled)
    /// - AmountColors for positive/negative balances
    static func card(for person: Person, transactions: [Transaction] = [], onTap: (() -> Void)? = nil) -> some View {
        return PersonCard(person: person, transactions: transactions, onTap: onTap)
    }

    /// Helper to compute person subtitle
    private static func personSubtitle(for person: Person, transactions: [Transaction]) -> String {
        let balanceIcon = person.balance > 0 ? "←" : "→"
        let balanceText = person.balance > 0 ? "Owes you" : (person.balance < 0 ? "You owe" : "Settled")

        // Get last transaction with this person
        let lastActivity = transactions
            .filter { $0.title.contains(person.name) || $0.subtitle.contains(person.name) }
            .sorted { $0.date > $1.date }
            .first

        var subtitle = "\(balanceIcon) \(balanceText)"
        if let lastActivity = lastActivity {
            let timeAgo = relativeTime(from: lastActivity.date)
            subtitle += " • Last activity \(timeAgo)"
        }
        return subtitle
    }

    /// Helper to compute person balance text and color
    private static func personBalanceFormatted(_ person: Person) -> (String, Color) {
        if person.balance > 0 {
            return (formatAmount(person.balance, isExpense: false), .wiseBrightGreen)
        } else if person.balance < 0 {
            return (formatAmount(abs(person.balance), isExpense: true), .wiseError)
        } else {
            return ("$0.00", .wiseSecondaryText)
        }
    }

    // MARK: - Group Row

    /// Creates a row view for a Group
    @ViewBuilder
    static func row(for group: Group, onTap: (() -> Void)? = nil) -> some View {
        // Format subtitle: "4 members • 12 expenses"
        let memberCount = group.members.count
        let expenseCount = group.expenses.count
        let subtitle = "\(memberCount) member\(memberCount == 1 ? "" : "s") • \(expenseCount) expense\(expenseCount == 1 ? "" : "s")"

        // Format total amount
        let totalAmount = group.totalAmount > 0 ? group.totalAmount : group.expenses.reduce(0.0) { $0 + $1.amount }
        let valueText = formatCurrency(totalAmount)

        // Use UnifiedListRowV2 with emoji circle
        HStack(spacing: 12) {
            // Filled Emoji Circle
            Circle()
                .fill(Color.wiseBlue)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(group.emoji)
                        .font(.system(size: 24))
                )

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Value
            Text(valueText)
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    /// Creates a card view for a Group (unified list design with emoji avatar)
    /// Uses GroupCard component with:
    /// - Emoji in blue circle (44x44)
    /// - Member and expense count summary
    /// - Total amount display
    static func card(for group: Group, onTap: (() -> Void)? = nil) -> some View {
        return GroupCard(group: group, onTap: onTap)
    }

    // MARK: - Subscription Row

    /// Creates a row view for a Subscription
    static func row(for subscription: Subscription, onTap: (() -> Void)? = nil) -> some View {
        let subtitle = subscriptionSubtitle(for: subscription)
        let valueText = formatCurrency(subscription.price)

        return UnifiedListRowV2(
            iconName: subscription.icon,
            iconColor: Color(hexString: subscription.color),
            title: subscription.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: .wisePrimaryText,
            showChevron: true,
            onTap: onTap
        )
    }

    /// Creates a card view for a Subscription (unified list design with initials avatar)
    /// Uses SubscriptionCard component with:
    /// - Initials-based colored avatar (category-based pastel colors)
    /// - Billing cycle and next billing date
    /// - Price display (neutral color)
    static func card(for subscription: Subscription, onTap: (() -> Void)? = nil) -> some View {
        return SubscriptionCard(subscription: subscription, onTap: onTap)
    }

    /// Helper to compute subscription subtitle
    private static func subscriptionSubtitle(for subscription: Subscription) -> String {
        let statusIcon = subscription.isActive ? "✓" : (subscription.cancellationDate != nil ? "✕" : "⏸")
        let statusText = subscription.isActive ? "Active" : (subscription.cancellationDate != nil ? "Cancelled" : "Paused")
        let cycleText = subscription.billingCycle.rawValue

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let nextDateText = dateFormatter.string(from: subscription.nextBillingDate)

        return "\(statusIcon) \(statusText) • \(cycleText) • Next: \(nextDateText)"
    }

    // MARK: - Notification Row

    /// Creates a row view for a NotificationHistoryEntry
    @ViewBuilder
    static func row(for notification: NotificationHistoryEntry, onTap: (() -> Void)? = nil) -> some View {
        // Format subtitle: "Renewal reminder • 2h ago"
        let timeAgo = relativeTime(from: notification.sentDate)
        let subtitle = "\(notification.type.rawValue) • \(timeAgo)"

        // Value shows "Opened" for read notifications
        let valueText = notification.wasOpened ? "Opened" : ""

        UnifiedListRowV2(
            iconName: notification.type.icon,
            iconColor: Color(hexString: notification.type.color),
            title: notification.title,
            subtitle: subtitle,
            value: valueText,
            valueColor: .wiseSecondaryText,
            showChevron: false,
            onTap: onTap
        )
    }
}

// MARK: - Helper Extensions

extension ListRowFactory {
    /// Format relative time string
    static func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format currency amount
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    /// Format amount with sign (for transactions and balances)
    static func formatAmount(_ amount: Double, isExpense: Bool) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
        return isExpense ? "– \(formatted)" : "+ \(formatted)"
    }
}

// MARK: - Supporting Extensions

extension PaymentMethod {
    var shortName: String {
        switch self {
        case .creditCard:
            return "Visa"
        case .debitCard:
            return "Debit"
        case .bankTransfer:
            return "Bank Transfer"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .paypal:
            return "PayPal"
        case .other:
            return "Card"
        }
    }
}
