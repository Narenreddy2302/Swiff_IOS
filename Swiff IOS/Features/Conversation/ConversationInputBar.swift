//
//  ConversationInputBar.swift
//  Swiff IOS
//
//  Professional input bar for conversation views
//  Updated with new UI Design System specifications
//  Features: Pill-shaped input, Dark Gray (#2C2C2E) background, Teal send button
//

import SwiftUI

// MARK: - Conversation Input Bar

/// Professional input bar with message field and action buttons
/// Per design system: Pill-shaped input with dark gray background
struct ConversationInputBar: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var messageText: String
    @FocusState.Binding var isMessageFieldFocused: Bool

    let onSendMessage: () -> Void
    let onAddTransaction: () -> Void
    let onScrollToBottom: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.Colors.borderSubtle)

            HStack(spacing: 12) {
                // Add transaction button
                Button(action: onAddTransaction) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.teal)
                }
                .accessibilityLabel("Add transaction")
                .accessibilityHint("Create a new payment or split")

                // Message input field - Pill shape with dark gray background
                HStack(spacing: 8) {
                    TextField("iMessage", text: $messageText)
                        .font(Theme.Fonts.inputText)
                        .foregroundColor(.wisePrimaryText)
                        .focused($isMessageFieldFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSendMessage()
                            }
                        }
                }
                .padding(.horizontal, Theme.Metrics.inputPaddingH)
                .padding(.vertical, Theme.Metrics.inputPaddingV)
                .background(
                    // Dark Gray (#2C2C2E) in dark mode
                    colorScheme == .dark ? Theme.Colors.darkGray : Theme.Colors.secondaryBackground
                )
                .cornerRadius(Theme.Metrics.inputCornerRadius)  // Pill shape

                // Send/Scroll to bottom button
                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: onSendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.teal)
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

// MARK: - Message Input View Modifier

/// Standalone input style modifier for text fields
struct MessageInputStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.inputText)
            .foregroundColor(.wisePrimaryText)
            .padding(.horizontal, Theme.Metrics.inputPaddingH)
            .padding(.vertical, Theme.Metrics.inputPaddingV)
            .background(
                colorScheme == .dark ? Theme.Colors.darkGray : Theme.Colors.secondaryBackground
            )
            .cornerRadius(Theme.Metrics.inputCornerRadius)
    }
}

extension View {
    func messageInputStyle() -> some View {
        modifier(MessageInputStyle())
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
