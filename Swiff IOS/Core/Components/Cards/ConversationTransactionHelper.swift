//
//  ConversationTransactionHelper.swift
//  Swiff IOS
//
//  Helper utilities for converting transaction data to conversation cards
//  Handles logic for determining transaction type, creator, and display labels
//

import SwiftUI

// MARK: - Conversation Transaction Helper

/// Helper to convert various transaction types to conversation cards
struct ConversationTransactionHelper {
    
    // MARK: - Currency Formatting

    /// Format amount as currency string
    static func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }

    /// Extract first name from a full name for compact display
    static func firstName(_ fullName: String) -> String {
        if fullName == "You" { return fullName }
        return fullName.components(separatedBy: " ").first ?? fullName
    }
    
    // MARK: - Person-to-Person Transaction
    
    /// Create card for a person-to-person transaction
    /// - Parameters:
    ///   - amount: Transaction amount (positive = you lent, negative = you owe)
    ///   - personName: Name of the other person
    ///   - title: Transaction title/description
    ///   - isCurrentUserCreator: Whether current user created the transaction
    ///   - isCurrentUserPayer: Whether current user paid
    ///   - splitMethod: How the bill was split
    ///   - participants: List of participant names
    ///   - onTap: Action when card is tapped
    static func createPersonTransactionCard(
        amount: Double,
        personName: String,
        title: String,
        isCurrentUserCreator: Bool,
        isCurrentUserPayer: Bool,
        splitMethod: String = "Equally",
        participants: [String],
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        
        let absAmount = abs(amount)
        let formattedAmount = formatCurrency(absAmount)
        let creatorName = isCurrentUserCreator ? "You" : firstName(personName)
        let paidByName = isCurrentUserPayer ? "You" : personName
        let participantNames = participants.joined(separator: ", ")
        
        // Determine if current user is lending or owing
        let youLent = isCurrentUserPayer && participants.count > 1
        
        if youLent {
            // You paid and others owe you
            return ConversationTransactionCardBuilder.payment(
                to: personName,
                amount: formattedAmount,
                totalBill: formattedAmount,
                paidBy: paidByName,
                splitMethod: splitMethod,
                participants: participantNames,
                creatorName: creatorName,
                onTap: onTap
            )
        } else if !isCurrentUserPayer {
            // Someone else paid and you owe them
            return ConversationTransactionCardBuilder.owe(
                to: personName,
                amount: formattedAmount,
                totalBill: formatCurrency(absAmount * Double(participants.count)),
                paidBy: paidByName,
                splitMethod: splitMethod,
                participants: participantNames,
                creatorName: creatorName,
                onTap: onTap
            )
        } else {
            // Default payment
            return ConversationTransactionCardBuilder.payment(
                to: personName,
                amount: formattedAmount,
                totalBill: formattedAmount,
                paidBy: paidByName,
                splitMethod: splitMethod,
                participants: participantNames,
                creatorName: creatorName,
                onTap: onTap
            )
        }
    }
    
    // MARK: - Split Bill
    
    /// Create card for a split bill
    /// - Parameters:
    ///   - splitBill: The split bill data
    ///   - currentUserId: Current user's ID
    ///   - payerName: Name of the person who paid
    ///   - participantNames: Names of all participants
    ///   - onTap: Action when card is tapped
    static func createSplitBillCard(
        splitBill: SplitBill,
        currentUserId: UUID,
        payerName: String,
        creatorName: String? = nil,
        participantNames: [String],
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {

        let isCurrentUserPayer = splitBill.paidById == currentUserId
        let yourShare = splitBill.totalAmount / Double(max(splitBill.participants.count, 1))

        // Use createdById to determine creator (falls back to current user for legacy data without createdById)
        let isCurrentUserCreator = splitBill.createdById == nil || splitBill.createdById == currentUserId
        let resolvedCreatorName = firstName(creatorName ?? (isCurrentUserCreator ? "You" : payerName))

        let splitMethodText: String
        switch splitBill.splitType {
        case .equally:
            splitMethodText = "Equally"
        case .exactAmounts:
            splitMethodText = "Exact Amounts"
        case .percentages:
            splitMethodText = "By Percentage"
        case .shares:
            splitMethodText = "By Shares"
        case .adjustments:
            splitMethodText = "With Adjustments"
        }

        return ConversationTransactionCardBuilder.split(
            description: splitBill.title,
            amount: formatCurrency(yourShare),
            totalBill: formatCurrency(splitBill.totalAmount),
            paidBy: payerName,
            splitMethod: splitMethodText,
            participants: participantNames.joined(separator: ", "),
            creatorName: resolvedCreatorName,
            isUserPayer: isCurrentUserPayer,
            onTap: onTap
        )
    }
    
    // MARK: - Group Expense
    
    /// Create card for a group expense
    /// - Parameters:
    ///   - expense: The group expense data
    ///   - payerName: Name of the person who paid
    ///   - participantNames: Names of all participants
    ///   - onTap: Action when card is tapped
    static func createGroupExpenseCard(
        expense: GroupExpense,
        payerName: String,
        creatorName: String = "You",
        participantNames: [String],
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {

        return ConversationTransactionCardBuilder.groupExpense(
            description: expense.title,
            amount: formatCurrency(expense.amountPerPerson),
            totalBill: formatCurrency(expense.amount),
            paidBy: payerName,
            splitMethod: "Equally",
            participants: participantNames.joined(separator: ", "),
            creatorName: firstName(creatorName),
            onTap: onTap
        )
    }

    // MARK: - Transaction Display Data
    
    /// Create card from TransactionDisplayData protocol
    /// - Parameters:
    ///   - transaction: Any object conforming to TransactionDisplayData
    ///   - currentUserId: Current user's ID for determining relationships
    ///   - onTap: Action when card is tapped
    static func createCardFromDisplayData(
        transaction: TransactionDisplayData,
        currentUserId: UUID,
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        
        let isCurrentUserPayer = transaction.isUserPayer
        let participantNames = transaction.displayInvolvedNames.joined(separator: ", ")
        
        return ConversationTransactionCardBuilder.split(
            description: transaction.displayTitle,
            amount: formatCurrency(transaction.displayYourShare),
            totalBill: formatCurrency(transaction.displayTotalAmount),
            paidBy: transaction.displayPaidByName,
            splitMethod: transaction.displaySplitMethod,
            participants: participantNames,
            creatorName: firstName(transaction.displayCreatorName),
            isUserPayer: isCurrentUserPayer,
            onTap: onTap
        )
    }
    
    // MARK: - Simple Transaction (Legacy)
    
    /// Create card from a simple Transaction model
    /// - Parameters:
    ///   - transaction: Transaction data
    ///   - personName: Name of the person involved
    ///   - onTap: Action when card is tapped
    static func createSimpleTransactionCard(
        transaction: Transaction,
        personName: String,
        creatorName: String = "You",
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {

        let isExpense = transaction.amount < 0
        let absAmount = abs(transaction.amount)
        let displayCreatorName = firstName(creatorName)

        if isExpense {
            // You owe them
            return ConversationTransactionCardBuilder.owe(
                to: personName,
                amount: formatCurrency(absAmount),
                totalBill: formatCurrency(absAmount),
                paidBy: personName,
                splitMethod: "Personal",
                participants: "You, \(personName)",
                creatorName: displayCreatorName,
                onTap: onTap
            )
        } else {
            // They owe you
            return ConversationTransactionCardBuilder.payment(
                to: personName,
                amount: formatCurrency(absAmount),
                totalBill: formatCurrency(absAmount),
                paidBy: "You",
                splitMethod: "Personal",
                participants: "You, \(personName)",
                creatorName: displayCreatorName,
                onTap: onTap
            )
        }
    }
}

// MARK: - Extensions for Domain Models

// Note: These extensions require the domain models to be defined elsewhere
// They provide convenience methods for creating conversation cards

extension SplitBill {
    /// Create a conversation card for this split bill
    func toConversationCard(
        currentUserId: UUID,
        payerName: String,
        participantNames: [String],
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        return ConversationTransactionHelper.createSplitBillCard(
            splitBill: self,
            currentUserId: currentUserId,
            payerName: payerName,
            participantNames: participantNames,
            onTap: onTap
        )
    }
}

extension GroupExpense {
    /// Create a conversation card for this group expense
    func toConversationCard(
        payerName: String,
        participantNames: [String],
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        return ConversationTransactionHelper.createGroupExpenseCard(
            expense: self,
            payerName: payerName,
            participantNames: participantNames,
            onTap: onTap
        )
    }
}

extension Transaction {
    /// Create a conversation card for this simple transaction
    func toConversationCard(
        personName: String,
        onTap: (() -> Void)? = nil
    ) -> ConversationTransactionCard {
        return ConversationTransactionHelper.createSimpleTransactionCard(
            transaction: self,
            personName: personName,
            onTap: onTap
        )
    }
}
