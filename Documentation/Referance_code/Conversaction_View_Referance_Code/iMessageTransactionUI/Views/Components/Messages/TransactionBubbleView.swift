//
//  TransactionBubbleView.swift
//  iMessageTransactionUI
//
//  Description:
//  Renders a transaction card within a message bubble.
//  Displays all transaction details in a structured format.
//
//  Layout:
//  - VStack containing:
//    1. Creator text (above the bubble, in gray)
//    2. Transaction bubble with:
//       - Header: Transaction name + Amount/You Owe
//       - Divider line
//       - Details: Total Bill, Paid by, Split Method, Who are all involved
//    3. Timestamp below the bubble
//
//  Styling:
//  - Sent transactions:
//    - Blue background
//    - White text for labels
//    - Yellow text for amount (#FFD60A)
//    - White divider at 20% opacity
//
//  - Received transactions:
//    - Gray background
//    - Black text for labels
//    - Orange text for amount (#FF6B35)
//    - Black divider at 8% opacity
//
//  Properties:
//  - transaction: Transaction - The transaction data to display
//  - messageType: MessageType - Whether this is sent or received
//

import SwiftUI

// MARK: - TransactionBubbleView
/// Renders a transaction card within a message bubble
struct TransactionBubbleView: View {
    
    // MARK: - Properties
    
    /// The transaction data to display
    let transaction: Transaction
    
    /// Whether this message is sent or received
    let messageType: MessageType
    
    /// Convenience property for checking if message is sent
    private var isSent: Bool {
        messageType == .sent
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: isSent ? .trailing : .leading, spacing: 6) {
            // Creator text (above the bubble)
            creatorText
            
            // Transaction bubble
            transactionBubble
            
            // Timestamp
            timestampView
        }
    }
    
    // MARK: - Creator Text
    /// Shows who created the transaction (above the bubble)
    private var creatorText: some View {
        Text("\(transaction.creatorName) created the transaction")
            .font(.system(size: 12))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 6)
    }
    
    // MARK: - Transaction Bubble
    /// Main transaction card bubble
    private var transactionBubble: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Name and Amount
            transactionHeader
            
            // Divider
            dividerLine
            
            // Details
            transactionDetails
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(bubbleBackground)
        .clipShape(MessageBubbleShape(isSent: isSent))
    }
    
    /// Background color based on message type
    private var bubbleBackground: Color {
        isSent ? .iMessageBlue : .iMessageGray
    }
    
    // MARK: - Transaction Header
    /// Header row with transaction name and amount
    private var transactionHeader: some View {
        HStack(alignment: .top) {
            // Transaction name
            Text(transaction.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isSent ? .white : .textPrimary)
            
            Spacer()
            
            // Amount and label
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Text(transaction.formattedSharePerPerson)
                        .font(.system(size: 17, weight: .semibold))
                    Text(transaction.oweLabel)
                        .font(.system(size: 13))
                }
                .foregroundColor(amountColor)
            }
        }
    }
    
    /// Color for the amount text
    private var amountColor: Color {
        isSent ? .transactionYellow : .transactionOrange
    }
    
    // MARK: - Divider Line
    /// Horizontal divider between header and details
    private var dividerLine: some View {
        Rectangle()
            .fill(isSent ? Color.transactionDividerSent : Color.transactionDivider)
            .frame(height: 1)
    }
    
    // MARK: - Transaction Details
    /// Detail rows showing transaction information
    private var transactionDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Total Bill
            TransactionDetailRow(
                label: "Total Bill",
                value: transaction.formattedTotalBill,
                isSent: isSent
            )
            
            // Paid by
            TransactionDetailRow(
                label: "Paid by",
                value: transaction.paidBy,
                isSent: isSent
            )
            
            // Split Method
            TransactionDetailRow(
                label: "Split Method",
                value: transaction.splitMethod,
                isSent: isSent
            )
            
            // Who are all involved
            TransactionDetailRow(
                label: "Who are all involved",
                value: transaction.peopleList,
                isSent: isSent
            )
        }
    }
    
    // MARK: - Timestamp View
    /// Displays the transaction timestamp
    private var timestampView: some View {
        Text(transaction.timestamp.formattedTime)
            .font(.system(size: 11))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 4)
    }
}

// MARK: - TransactionDetailRow
/// A single row in the transaction details section
struct TransactionDetailRow: View {
    
    /// Label text (left side)
    let label: String
    
    /// Value text (right side)
    let value: String
    
    /// Whether this is in a sent message
    let isSent: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            // Label
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSent ? .white.opacity(0.9) : .textPrimary)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(isSent ? .white : .textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(nil)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Received transaction
        TransactionBubbleView(
            transaction: Transaction.sampleTransactions[0],
            messageType: .received
        )
        
        // Sent transaction
        TransactionBubbleView(
            transaction: Transaction.sampleTransactions[2],
            messageType: .sent
        )
    }
    .padding()
}
