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
    static func row(for transaction: Transaction, onTap: (() -> Void)? = nil) -> some View {
        let iconConfig = avatarConfig(for: transaction)
        let timeString = transactionTime(for: transaction)
        let statusString = transactionStatus(for: transaction)
        // Screenshot shows all amounts in black, regardless of expense/income
        let valueColor = Color.wisePrimaryText
        let value = formatAmount(abs(transaction.amount), isExpense: transaction.isExpense)

        return UniversalListRow(
            title: transaction.title,
            subtitle: timeString,
            value: value,
            valueColor: valueColor,
            valueLabel: statusString,
            icon: iconConfig,
            showChevron: false,
            onTap: onTap
        )
    }

    /// Creates a card view for a Transaction (using UniversalListRow with card styling)
    static func card(
        for transaction: Transaction, context: CardContext = .feed,
        subscription: Subscription? = nil, onTap: (() -> Void)? = nil
    ) -> some View {
        let iconConfig = avatarConfig(for: transaction)
        let timeString = transactionTime(for: transaction)
        let statusString = transactionStatus(for: transaction)
        let valueColor =
            transaction.isExpense
            ? Color.wisePrimaryText : Color.wiseSuccess
        let value = formatAmount(abs(transaction.amount), isExpense: transaction.isExpense)

        return UniversalListRow(
            title: transaction.title,
            subtitle: timeString,
            value: value,
            valueColor: valueColor,
            valueLabel: statusString,
            icon: iconConfig,
            showChevron: false,
            onTap: onTap
        )
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    /// Creates a simple row view for a Transaction
    static func simpleRow(for transaction: Transaction, onTap: (() -> Void)? = nil)
        -> some View
    {
        row(for: transaction, onTap: onTap)
    }

    // MARK: - Person Row

    /// Creates a row view for a Person

    static func row(
        for person: Person, transactions: [Transaction] = [], onTap: (() -> Void)? = nil
    ) -> some View {
        let (iconConfig, valueColor, valueText, subtitle, statusLabel) = personConfig(
            person, transactions: transactions)

        return UniversalListRow(
            title: person.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: valueColor,
            valueLabel: statusLabel,
            icon: iconConfig,
            showChevron: true,
            onTap: onTap
        )
    }

    /// Creates a card view for a Person
    static func card(for person: Person, transactions: [Transaction] = []) -> some View {
        let (iconConfig, valueColor, valueText, subtitle, statusLabel) = personConfig(
            person, transactions: transactions)

        return UniversalListRow(
            title: person.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: valueColor,
            valueLabel: statusLabel,
            icon: iconConfig,
            showChevron: false
        )
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    // MARK: - Group Row

    /// Creates a row view for a Group

    static func row(for group: Group, onTap: (() -> Void)? = nil) -> some View {
        let (iconConfig, valueText, subtitle) = groupConfig(group)

        return UniversalListRow(
            title: group.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: .wisePrimaryText,
            valueLabel: nil,
            icon: iconConfig,
            showChevron: true,
            onTap: onTap
        )
    }

    /// Creates a card view for a Group
    static func card(for group: Group) -> some View {
        let (iconConfig, valueText, subtitle) = groupConfig(group)

        return UniversalListRow(
            title: group.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: .wisePrimaryText,
            valueLabel: nil,
            icon: iconConfig,
            showChevron: false
        )
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    // MARK: - Subscription Row

    /// Creates a row view for a Subscription

    static func row(for subscription: Subscription, onTap: (() -> Void)? = nil) -> some View
    {
        let (iconConfig, valueText, subtitle) = subscriptionConfig(subscription)

        return UniversalListRow(
            title: subscription.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: .wisePrimaryText,
            valueLabel: subscription.billingCycle.displayName,
            icon: iconConfig,
            showChevron: true,
            onTap: onTap
        )
    }

    /// Creates a card view for a Subscription
    static func card(for subscription: Subscription) -> some View {
        let (iconConfig, valueText, subtitle) = subscriptionConfig(subscription)

        return UniversalListRow(
            title: subscription.name,
            subtitle: subtitle,
            value: valueText,
            valueColor: .wisePrimaryText,
            valueLabel: subscription.billingCycle.displayName,
            icon: iconConfig,
            showChevron: false
        )
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    // MARK: - Helpers

    /// Generate avatar configuration for transaction based on title/merchant
    private static func avatarConfig(for transaction: Transaction) -> UniversalIconConfig {
        let displayName = transaction.merchant ?? transaction.title

        // Special handling for specific merchants matching the screenshot
        switch displayName.lowercased() {
        case let name where name.contains("uber"):
            // Uber uses black circle with white text logo
            return .initials(
                text: "Uber", backgroundColor: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
            )

        case let name where name.contains("food") && name.contains("panda"):
            // Food Panda uses pink circle with emoji
            return .emoji(
                text: "🐼", backgroundColor: Color(red: 233 / 255, green: 30 / 255, blue: 99 / 255))

        default:
            // For other transactions, use initials with color based on name hash
            let color = avatarColorForTransaction(displayName)
            return .initials(text: displayName, backgroundColor: color)
        }
    }

    /// Generate avatar color based on name hash
    private static func avatarColorForTransaction(_ name: String) -> Color {
        let hash = abs(name.hashValue)

        // Colors matching the screenshot design
        let colors: [Color] = [
            Color(red: 52 / 255, green: 120 / 255, blue: 120 / 255),  // Teal (Mikel Borle)
            Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255),  // Black (Uber alternative)
            Color(red: 233 / 255, green: 30 / 255, blue: 99 / 255),  // Pink (Food Panda alternative)
            Color(red: 76 / 255, green: 76 / 255, blue: 76 / 255),  // Gray
            Color(red: 88 / 255, green: 86 / 255, blue: 214 / 255),  // Purple (Ryan Scott)
            Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255),  // Orange
            Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255),  // Red
            Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255),  // Blue
        ]

        return colors[hash % colors.count]
    }

    private static func transactionTime(for transaction: Transaction) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"  // Format like "10:30 AM"
        return formatter.string(from: transaction.date)
    }

    private static func transactionStatus(for transaction: Transaction) -> String {
        // Match screenshot labels exactly:
        // - "Receive" for incoming money
        // - "Send" for outgoing money to people
        // - "Payment" for payments to merchants/services
        // - "Transfer" for transfers

        if !transaction.isExpense {
            return "Receive"
        }

        // Check if it's a transfer based on category or title
        if transaction.category == .transfer || transaction.title.lowercased().contains("transfer")
        {
            return "Transfer"
        }

        // Check if it's to a merchant/service (has merchant field or specific categories)
        if transaction.merchant != nil
            || [.food, .transportation, .utilities, .bills, .shopping, .entertainment].contains(
                transaction.category)
        {
            return "Payment"
        }

        // Default to "Send" for person-to-person transactions
        return "Send"
    }

    private static func personConfig(_ person: Person, transactions: [Transaction]) -> (
        UniversalIconConfig, Color, String, String, String
    ) {
        let iconConfig: UniversalIconConfig

        switch person.avatarType {
        case .initials(let initials, let colorIndex):
            iconConfig = .initials(
                text: initials.isEmpty ? person.name : initials,
                backgroundColor: AvatarColorPalette.color(for: colorIndex))
        case .emoji(let emoji):
            iconConfig = .emoji(
                text: emoji, backgroundColor: InitialsAvatarColors.color(for: person.name))
        case .photo(let data):
            if let uiImage = UIImage(data: data) {
                iconConfig = .image(uiImage)
            } else {
                // Fallback to initials if image data is corrupted
                iconConfig = .initials(
                    text: person.name, backgroundColor: InitialsAvatarColors.color(for: person.name))
            }
        }

        let (valueText, valueColor) = personBalanceFormatted(person)
        let (subtitle, statusLabel) = personSubtitleAndStatus(
            for: person, transactions: transactions)

        return (iconConfig, valueColor, valueText, subtitle, statusLabel)
    }

    private static func personSubtitleAndStatus(for person: Person, transactions: [Transaction])
        -> (String, String)
    {
        let balanceText =
            person.balance > 0 ? "Owes you" : (person.balance < 0 ? "You owe" : "Settled")

        // Get last transaction with this person
        let lastActivity =
            transactions
            .filter { $0.title.contains(person.name) || $0.subtitle.contains(person.name) }
            .sorted { $0.date > $1.date }
            .first

        var subtitle = "No recent activity"
        if let lastActivity = lastActivity {
            subtitle = relativeTime(from: lastActivity.date)
        }

        return (subtitle, balanceText)
    }

    private static func personBalanceFormatted(_ person: Person) -> (String, Color) {
        if person.balance > 0 {
            return (formatAmount(person.balance, isExpense: false), .wiseBrightGreen)
        } else if person.balance < 0 {
            return (formatAmount(abs(person.balance), isExpense: true), .wiseError)
        } else {
            return ("$0.00", .wiseSecondaryText)
        }
    }

    private static func groupConfig(_ group: Group) -> (UniversalIconConfig, String, String) {
        let iconConfig = UniversalIconConfig.emoji(
            text: group.emoji, backgroundColor: .wiseBlue.opacity(0.12))

        let totalAmount =
            group.totalAmount > 0
            ? group.totalAmount : group.expenses.reduce(0.0) { $0 + $1.amount }
        let valueText = formatCurrency(totalAmount)

        let memberCount = group.members.count
        let expenseCount = group.expenses.count
        let subtitle =
            "\(memberCount) member\(memberCount == 1 ? "" : "s") • \(expenseCount) expense\(expenseCount == 1 ? "" : "s")"

        return (iconConfig, valueText, subtitle)
    }

    private static func subscriptionConfig(_ subscription: Subscription) -> (
        UniversalIconConfig, String, String
    ) {
        // Use system icon for subscription
        let iconConfig = UniversalIconConfig.system(
            name: subscription.icon,
            color: Color(hexString: subscription.color)
        )

        let valueText = formatCurrency(subscription.price)
        let subtitle = subscriptionSubtitle(for: subscription)

        return (iconConfig, valueText, subtitle)
    }

    private static func subscriptionSubtitle(for subscription: Subscription) -> String {
        let statusIcon =
            subscription.isActive ? "✓" : (subscription.cancellationDate != nil ? "✕" : "⏸")
        let statusText =
            subscription.isActive
            ? "Active" : (subscription.cancellationDate != nil ? "Cancelled" : "Paused")
        let cycleText = subscription.billingCycle.rawValue

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let nextDateText = dateFormatter.string(from: subscription.nextBillingDate)

        return "\(statusIcon) \(statusText) • \(cycleText) • Next: \(nextDateText)"
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
        return isExpense ? "-\(formatted)" : "+\(formatted)"
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
