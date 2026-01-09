//
//  BalanceType.swift
//  iMessageTransactionUI
//
//  Description:
//  Enum representing the three possible balance states in the transaction system.
//  Used to determine the display color and label in the header balance summary.
//
//  Cases:
//  - theyOwe(Double): Positive balance - others owe the user money (displayed in green)
//  - youOwe(Double): Negative balance - user owes others money (displayed in red)
//  - settled: Zero balance - all transactions are settled (displayed in gray)
//
//  Usage:
//  This enum is computed in ChatViewModel based on all transactions.
//  The BalanceSummaryView uses this to render the appropriate UI.
//

import Foundation

// MARK: - BalanceType Enum
/// Represents the net balance state between the user and the group
enum BalanceType {
    
    // MARK: Cases
    
    /// Others owe the user this amount (positive balance)
    /// - Parameter amount: The total amount others owe the user
    case theyOwe(Double)
    
    /// User owes others this amount (negative balance)
    /// - Parameter amount: The total amount the user owes others
    case youOwe(Double)
    
    /// All debts are settled (zero balance)
    case settled
    
    // MARK: - Computed Properties
    
    /// Returns the display amount as a formatted string
    /// - Format: "+$X.XX" for theyOwe, "-$X.XX" for youOwe, "$0.00" for settled
    var displayAmount: String {
        switch self {
        case .theyOwe(let amount):
            return "+$\(String(format: "%.2f", amount))"
        case .youOwe(let amount):
            return "-$\(String(format: "%.2f", amount))"
        case .settled:
            return "$0.00"
        }
    }
    
    /// Returns the descriptive label for the balance state
    /// - "They owe you" for positive balance
    /// - "You owe" for negative balance
    /// - "All settled up" for zero balance
    var displayLabel: String {
        switch self {
        case .theyOwe:
            return "They owe you"
        case .youOwe:
            return "You owe"
        case .settled:
            return "All settled up"
        }
    }
}
