//
//  MessageBubbleView.swift
//  iMessageTransactionUI
//
//  Description:
//  Renders a single text message bubble with timestamp.
//  Styled according to iMessage design language.
//
//  Styling:
//  - Sent messages:
//    - Blue background (#007AFF)
//    - White text
//    - Rounded corners with smaller bottom-right radius
//    - Right-aligned
//
//  - Received messages:
//    - Gray background (#E9E9EB)
//    - Black text
//    - Rounded corners with smaller bottom-left radius
//    - Left-aligned
//
//  Layout:
//  - VStack containing:
//    1. Message bubble with text
//    2. Timestamp below the bubble
//
//  Properties:
//  - message: Message - The text message to display
//
//  Note:
//  This component is only for text messages.
//  For transactions, use TransactionBubbleView.
//

import SwiftUI

// MARK: - MessageBubbleView
/// Renders a text message bubble with iMessage styling
struct MessageBubbleView: View {
    
    // MARK: - Properties
    
    /// The message to display
    let message: Message
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: message.isSent ? .trailing : .leading, spacing: 4) {
            // Message bubble
            bubbleView
            
            // Timestamp
            timestampView
        }
    }
    
    // MARK: - Bubble View
    /// The main message bubble containing the text
    private var bubbleView: some View {
        Text(message.content)
            .font(.system(size: 17))
            .lineSpacing(2)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .foregroundColor(message.isSent ? .white : .textPrimary)
            .clipShape(MessageBubbleShape(isSent: message.isSent))
    }
    
    /// Background color based on message type
    private var bubbleBackground: Color {
        message.isSent ? .iMessageBlue : .iMessageGray
    }
    
    // MARK: - Timestamp View
    /// Displays the message timestamp
    private var timestampView: some View {
        Text(message.formattedTime)
            .font(.system(size: 11))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 4)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Sent message
        MessageBubbleView(message: Message(
            content: "Hello! This is a sent message with some longer text to demonstrate wrapping.",
            type: .sent
        ))
        
        // Received message
        MessageBubbleView(message: Message(
            content: "Hey! This is a received message.",
            type: .received
        ))
        
        // Short messages
        MessageBubbleView(message: Message(
            content: "Got it! 👍",
            type: .sent
        ))
        
        MessageBubbleView(message: Message(
            content: "Sure!",
            type: .received
        ))
    }
    .padding()
}
