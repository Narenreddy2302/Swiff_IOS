//
//  MessageRowView.swift
//  iMessageTransactionUI
//
//  Description:
//  Container view that renders a single message row.
//  Determines whether to display a text bubble or transaction bubble.
//
//  Responsibilities:
//  - Aligns message based on type (sent = trailing, received = leading)
//  - Delegates to appropriate bubble component
//  - Handles spacing and layout
//
//  Layout:
//  - HStack with flexible spacers for alignment
//  - Maximum width of 75% for text messages, 90% for transactions
//  - Sent messages align to trailing edge (right)
//  - Received messages align to leading edge (left)
//
//  Child Components:
//  - MessageBubbleView: For regular text messages
//  - TransactionBubbleView: For transaction messages
//
//  Properties:
//  - message: Message - The message to display
//

import SwiftUI

// MARK: - MessageRowView
/// Container view that renders a message row with proper alignment
struct MessageRowView: View {
    
    // MARK: - Properties
    
    /// The message to display
    let message: Message
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Add leading spacer for sent messages (right-align)
            if message.isSent {
                Spacer(minLength: 40)
            }
            
            // Message content
            messageContent
                .frame(
                    maxWidth: message.isTransaction ? UIScreen.main.bounds.width * 0.9 : UIScreen.main.bounds.width * 0.75,
                    alignment: message.isSent ? .trailing : .leading
                )
            
            // Add trailing spacer for received messages (left-align)
            if message.isReceived {
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Message Content
    /// Determines which bubble type to render based on message content
    @ViewBuilder
    private var messageContent: some View {
        if message.isTransaction, let transaction = message.transaction {
            // Render transaction bubble
            TransactionBubbleView(
                transaction: transaction,
                messageType: message.type
            )
        } else {
            // Render regular text bubble
            MessageBubbleView(message: message)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 10) {
        // Sent text message
        MessageRowView(message: Message(
            content: "Hello, this is a sent message!",
            type: .sent
        ))
        
        // Received text message
        MessageRowView(message: Message(
            content: "This is a received message.",
            type: .received
        ))
        
        // Transaction message
        MessageRowView(message: Message(
            content: "",
            type: .received,
            transaction: Transaction.sampleTransactions[0]
        ))
    }
    .padding()
}
