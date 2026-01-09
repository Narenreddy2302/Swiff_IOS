//
//  TransactionDisplayData.swift
//  Swiff IOS
//
//  Protocol for unified transaction display across different transaction types
//  Allows SplitBill, GroupExpense, and Transaction to render with the same UI component
//

import SwiftUI

// MARK: - Transaction Display Data Protocol

/// Protocol defining the common interface for displaying transaction data
/// in conversation timeline bubbles. Allows for unified rendering across
/// SplitBill, GroupExpense, and Transaction types.
protocol TransactionDisplayData {
    /// Title of the transaction (e.g., "Dinner at Restaurant")
    var displayTitle: String { get }

    /// Total amount of the transaction
    var displayTotalAmount: Double { get }

    /// The amount the current user owes or is owed
    var displayYourShare: Double { get }

    /// Name of the person who paid
    var displayPaidByName: String { get }

    /// ID of the person who paid (for avatar lookup)
    var displayPaidById: UUID? { get }

    /// Split method description (e.g., "Equally", "Custom")
    var displaySplitMethod: String { get }

    /// Names of people involved in the split
    var displayInvolvedNames: [String] { get }

    /// Name of the person who created the transaction
    var displayCreatorName: String { get }

    /// Timestamp of the transaction
    var displayTimestamp: Date { get }

    /// Whether the current user is the payer
    var isUserPayer: Bool { get }

    /// Transaction category for icon/color
    var displayCategory: TransactionCategory { get }

    /// Whether the transaction is fully settled
    var isFullySettled: Bool { get }

    /// Settlement progress (0.0 to 1.0)
    var settlementProgress: Double { get }
}

// MARK: - SplitBill Conformance

extension SplitBill: TransactionDisplayData {
    var displayTitle: String {
        title
    }

    var displayTotalAmount: Double {
        totalAmount
    }

    var displayYourShare: Double {
        // Calculate share per person
        guard participants.count > 0 else { return totalAmount }
        return totalAmount / Double(participants.count)
    }

    var displayPaidByName: String {
        // This would need to be resolved via DataManager
        // For now, return a placeholder
        "Payer"
    }

    var displayPaidById: UUID? {
        paidById
    }

    var displaySplitMethod: String {
        switch splitType {
        case .equally: return "Equally"
        case .exactAmounts: return "Exact Amounts"
        case .percentages: return "By Percentage"
        case .shares: return "By Shares"
        case .adjustments: return "With Adjustments"
        }
    }

    var displayInvolvedNames: [String] {
        // Would need to be resolved via DataManager
        participants.map { _ in "Participant" }
    }

    var displayCreatorName: String {
        // Would need to be resolved via DataManager
        "Creator"
    }

    var displayTimestamp: Date {
        date
    }

    var isUserPayer: Bool {
        // Would need current user ID to determine
        false
    }

    var displayCategory: TransactionCategory {
        category
    }

    // Note: settlementProgress is already defined in SplitBill.swift
    // The protocol requirement is satisfied by the existing computed property
}

// MARK: - GroupExpense Conformance

extension GroupExpense: TransactionDisplayData {
    var displayTitle: String {
        title
    }

    var displayTotalAmount: Double {
        amount
    }

    var displayYourShare: Double {
        // Calculate share based on split - uses amountPerPerson
        return amountPerPerson
    }

    var displayPaidByName: String {
        // Would need to be resolved via DataManager
        "Payer"
    }

    var displayPaidById: UUID? {
        paidBy
    }

    var displaySplitMethod: String {
        "Equally"  // Default for group expenses
    }

    var displayInvolvedNames: [String] {
        // Would need to be resolved via DataManager
        []
    }

    var displayCreatorName: String {
        // Would need to be resolved via DataManager
        "Creator"
    }

    var displayTimestamp: Date {
        date
    }

    var isUserPayer: Bool {
        // Would need current user ID to determine
        false
    }

    var displayCategory: TransactionCategory {
        category
    }

    var isFullySettled: Bool {
        isSettled
    }

    var settlementProgress: Double {
        isSettled ? 1.0 : 0.0
    }
}

// MARK: - Transaction Conformance

extension Transaction: TransactionDisplayData {
    var displayTitle: String {
        title
    }

    var displayTotalAmount: Double {
        abs(amount)
    }

    var displayYourShare: Double {
        abs(amount)
    }

    var displayPaidByName: String {
        "You"  // Transactions are personal
    }

    var displayPaidById: UUID? {
        nil
    }

    var displaySplitMethod: String {
        "Personal"
    }

    var displayInvolvedNames: [String] {
        []  // Personal transaction, no split
    }

    var displayCreatorName: String {
        "You"
    }

    var displayTimestamp: Date {
        date
    }

    var isUserPayer: Bool {
        true
    }

    var displayCategory: TransactionCategory {
        category
    }

    var isFullySettled: Bool {
        paymentStatus == .completed
    }

    var settlementProgress: Double {
        paymentStatus == .completed ? 1.0 : 0.0
    }
}

// MARK: - Transaction Display Helper

/// Helper struct for resolved transaction display data
/// Used when entity names have been resolved from DataManager
struct ResolvedTransactionDisplay: TransactionDisplayData {
    let displayTitle: String
    let displayTotalAmount: Double
    let displayYourShare: Double
    let displayPaidByName: String
    let displayPaidById: UUID?
    let displaySplitMethod: String
    let displayInvolvedNames: [String]
    let displayCreatorName: String
    let displayTimestamp: Date
    let isUserPayer: Bool
    let displayCategory: TransactionCategory
    let isFullySettled: Bool
    let settlementProgress: Double

    /// Create from a SplitBill with resolved names
    static func from(
        splitBill: SplitBill,
        payerName: String,
        creatorName: String,
        participantNames: [String],
        isCurrentUserPayer: Bool
    ) -> ResolvedTransactionDisplay {
        return ResolvedTransactionDisplay(
            displayTitle: splitBill.title,
            displayTotalAmount: splitBill.totalAmount,
            displayYourShare: splitBill.totalAmount / Double(max(splitBill.participants.count, 1)),
            displayPaidByName: payerName,
            displayPaidById: splitBill.paidById,
            displaySplitMethod: splitBill.displaySplitMethod,
            displayInvolvedNames: participantNames,
            displayCreatorName: creatorName,
            displayTimestamp: splitBill.date,
            isUserPayer: isCurrentUserPayer,
            displayCategory: splitBill.category,
            isFullySettled: splitBill.isFullySettled,
            settlementProgress: splitBill.settlementProgress
        )
    }

    /// Create from a GroupExpense with resolved names
    static func from(
        expense: GroupExpense,
        payerName: String,
        participantNames: [String],
        isCurrentUserPayer: Bool
    ) -> ResolvedTransactionDisplay {
        return ResolvedTransactionDisplay(
            displayTitle: expense.title,
            displayTotalAmount: expense.amount,
            displayYourShare: expense.amount / Double(max(participantNames.count, 1)),
            displayPaidByName: payerName,
            displayPaidById: expense.paidBy,
            displaySplitMethod: "Equally",
            displayInvolvedNames: participantNames,
            displayCreatorName: payerName,
            displayTimestamp: expense.date,
            isUserPayer: isCurrentUserPayer,
            displayCategory: expense.category,
            isFullySettled: expense.isSettled,
            settlementProgress: expense.isSettled ? 1.0 : 0.0
        )
    }
}
