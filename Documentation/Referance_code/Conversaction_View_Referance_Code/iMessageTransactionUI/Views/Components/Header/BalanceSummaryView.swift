//
//  BalanceSummaryView.swift
//  iMessageTransactionUI
//
//  Description:
//  Displays the net balance summary in the header.
//  Shows a single consolidated amount with appropriate color and label.
//
//  Display States:
//  1. Positive balance (theyOwe):
//     - Amount: "+$X.XX" in green
//     - Label: "They owe you"
//
//  2. Negative balance (youOwe):
//     - Amount: "-$X.XX" in red
//     - Label: "You owe"
//
//  3. Zero balance (settled):
//     - Amount: "$0.00" in gray
//     - Label: "All settled up"
//
//  Layout:
//  - VStack with amount on top and label below
//  - Right-aligned in parent container
//
//  Properties:
//  - balance: BalanceType - The balance state to display
//

import SwiftUI

// MARK: - BalanceSummaryView
/// Displays the net balance with appropriate styling based on balance state
struct BalanceSummaryView: View {
    
    // MARK: - Properties
    
    /// The balance state to display
    let balance: BalanceType
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Amount display
            Text(balance.displayAmount)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(amountColor)
            
            // Label display
            Text(balance.displayLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the appropriate color based on balance state
    /// - theyOwe: Green (positive for user)
    /// - youOwe: Red (negative for user)
    /// - settled: Gray (neutral)
    private var amountColor: Color {
        switch balance {
        case .theyOwe:
            return .owedGreen
        case .youOwe:
            return .oweRed
        case .settled:
            return .textSecondary
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Positive balance preview
        BalanceSummaryView(balance: .theyOwe(37.50))
            .padding()
            .background(Color.headerBackground)
        
        // Negative balance preview
        BalanceSummaryView(balance: .youOwe(25.00))
            .padding()
            .background(Color.headerBackground)
        
        // Settled preview
        BalanceSummaryView(balance: .settled)
            .padding()
            .background(Color.headerBackground)
    }
}
