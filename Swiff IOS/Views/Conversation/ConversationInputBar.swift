//
//  ConversationInputBar.swift
//  Swiff IOS
//
//  Professional input bar for conversation views
//  Follows Apple Messages app design patterns
//

import SwiftUI

// MARK: - Conversation Input Bar

/// Professional input bar with message field and action buttons
/// Follows Apple Messages design with clear visual hierarchy
struct ConversationInputBar: View {
    @Binding var messageText: String
    @FocusState.Binding var isMessageFieldFocused: Bool
    
    let onSendMessage: () -> Void
    let onAddTransaction: () -> Void
    let onScrollToBottom: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Add transaction button
                Button(action: onAddTransaction) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.wiseBrightGreen)
                }
                .accessibilityLabel("Add transaction")
                .accessibilityHint("Create a new payment or split")
                
                // Message input field
                HStack(spacing: 8) {
                    TextField("iMessage", text: $messageText)
                        .font(.system(size: 16))
                        .foregroundColor(.wisePrimaryText)
                        .focused($isMessageFieldFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSendMessage()
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.wiseSecondaryText.opacity(0.08))
                .cornerRadius(20)
                
                // Send/Scroll to bottom button
                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: onSendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.wiseBlue)
                    }
                    .accessibilityLabel("Send message")
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: onScrollToBottom) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .accessibilityLabel("Scroll to bottom")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Convenience Wrapper

/// Wrapper view that manages input bar state
struct ConversationInputBarWrapper: View {
    @State private var messageText: String = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    let onSendMessage: (String) -> Void
    let onAddTransaction: () -> Void
    let onScrollToBottom: () -> Void
    
    var body: some View {
        ConversationInputBar(
            messageText: $messageText,
            isMessageFieldFocused: $isMessageFieldFocused,
            onSendMessage: {
                let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    onSendMessage(trimmed)
                    messageText = ""
                    isMessageFieldFocused = false
                }
            },
            onAddTransaction: onAddTransaction,
            onScrollToBottom: onScrollToBottom
        )
    }
}

// MARK: - Preview

#Preview("Input Bar") {
    VStack {
        Spacer()
        
        // Empty state
        ConversationInputBarWrapper(
            onSendMessage: { text in
                print("Send: \(text)")
            },
            onAddTransaction: {
                print("Add transaction")
            },
            onScrollToBottom: {
                print("Scroll to bottom")
            }
        )
    }
    .background(Color.wiseBackground)
}

#Preview("Input Bar with Text") {
    VStack {
        Spacer()
        
        // With text
        ConversationInputBarPreviewHelper(initialText: "Hey! Want to grab lunch this week?")
    }
    .background(Color.wiseBackground)
}

// Helper for preview with initial text
private struct ConversationInputBarPreviewHelper: View {
    @State private var messageText: String
    @FocusState private var isMessageFieldFocused: Bool
    
    init(initialText: String) {
        _messageText = State(initialValue: initialText)
    }
    
    var body: some View {
        ConversationInputBar(
            messageText: $messageText,
            isMessageFieldFocused: $isMessageFieldFocused,
            onSendMessage: {
                print("Send: \(messageText)")
                messageText = ""
            },
            onAddTransaction: {
                print("Add transaction")
            },
            onScrollToBottom: {
                print("Scroll to bottom")
            }
        )
    }
}
