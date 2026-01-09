//
//  ConversationInputView.swift
//  Swiff IOS
//
//  Unified input area for conversation views
//  Features: Text input, add transaction button, send button, action buttons
//

import SwiftUI

// MARK: - Conversation Input View

/// A unified input area for all conversation types
/// Supports text messaging with transaction/action buttons
struct ConversationInputView: View {
    @Binding var messageText: String
    let placeholder: String
    let onSend: (String) -> Void
    let onAddTransaction: () -> Void
    let additionalActions: [ConversationInputAction]

    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Initialization

    init(
        messageText: Binding<String>,
        placeholder: String = "Message",
        onSend: @escaping (String) -> Void,
        onAddTransaction: @escaping () -> Void,
        additionalActions: [ConversationInputAction] = []
    ) {
        self._messageText = messageText
        self.placeholder = placeholder
        self.onSend = onSend
        self.onAddTransaction = onAddTransaction
        self.additionalActions = additionalActions
    }

    // MARK: - Computed Properties

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top divider
            Rectangle()
                .fill(Color.wiseBorder.opacity(0.5))
                .frame(height: 0.5)

            // Input area
            VStack(spacing: 10) {
                // Additional action buttons (if any)
                if !additionalActions.isEmpty {
                    actionButtonsRow
                }

                // Main input row
                mainInputRow
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(additionalActions) { action in
                    QuickActionPill(
                        title: action.title,
                        icon: action.icon,
                        color: action.color,
                        action: action.action
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Main Input Row

    private var mainInputRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Text input field (leftmost)
            textInputField

            // Add Transaction button (right side, before send)
            AddTransactionButton(action: onAddTransaction, isCompact: true)

            // Send button (rightmost)
            sendButton
        }
    }

    // MARK: - Text Input Field

    private var textInputField: some View {
        TextField(placeholder, text: $messageText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
            )
            .lineLimit(1...5)
            .focused($isTextFieldFocused)
            .submitLabel(.send)
            .onSubmit {
                if canSend {
                    sendMessage()
                }
            }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(canSend ? Color.wiseBlue : Color.wiseSecondaryText.opacity(0.3))
                .clipShape(Circle())
        }
        .disabled(!canSend)
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Actions

    private func sendMessage() {
        guard canSend else { return }
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticManager.shared.impact(.light)
        onSend(trimmedMessage)
        messageText = ""
    }
}

// MARK: - Conversation Input Action

/// Represents an additional action button in the input area
struct ConversationInputAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    static func theyOweMe(action: @escaping () -> Void) -> ConversationInputAction {
        ConversationInputAction(
            title: "They Owe Me",
            icon: "arrow.down.circle.fill",
            color: .wiseBrightGreen,
            action: action
        )
    }

    static func iOwe(action: @escaping () -> Void) -> ConversationInputAction {
        ConversationInputAction(
            title: "I Owe",
            icon: "arrow.up.circle.fill",
            color: .wiseBlue,
            action: action
        )
    }

    static func splitBill(action: @escaping () -> Void) -> ConversationInputAction {
        ConversationInputAction(
            title: "Split Bill",
            icon: "rectangle.split.2x1",
            color: .wisePurple,
            action: action
        )
    }

    static func settle(action: @escaping () -> Void) -> ConversationInputAction {
        ConversationInputAction(
            title: "Settle Up",
            icon: "checkmark.circle",
            color: .wiseWarning,
            action: action
        )
    }
}

// MARK: - Simple Conversation Input

/// A simpler version without additional action buttons
struct SimpleConversationInput: View {
    @Binding var messageText: String
    let placeholder: String
    let onSend: (String) -> Void
    let primaryAction: ConversationInputAction?

    @FocusState private var isTextFieldFocused: Bool

    init(
        messageText: Binding<String>,
        placeholder: String = "Message",
        onSend: @escaping (String) -> Void,
        primaryAction: ConversationInputAction? = nil
    ) {
        self._messageText = messageText
        self.placeholder = placeholder
        self.onSend = onSend
        self.primaryAction = primaryAction
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.wiseBorder.opacity(0.5))
                .frame(height: 0.5)

            HStack(alignment: .bottom, spacing: 10) {
                // Primary action button (if provided)
                if let action = primaryAction {
                    Button(action: action.action) {
                        Image(systemName: action.icon)
                            .font(.system(size: 24))
                            .foregroundColor(action.color)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // Text input
                TextField(placeholder, text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.wiseBorder.opacity(0.3), lineWidth: 1)
                    )
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend {
                            sendMessage()
                        }
                    }

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(canSend ? Color.wiseBlue : Color.wiseSecondaryText.opacity(0.3))
                        .clipShape(Circle())
                }
                .disabled(!canSend)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private func sendMessage() {
        guard canSend else { return }
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticManager.shared.impact(.light)
        onSend(trimmedMessage)
        messageText = ""
    }
}

// MARK: - Preview

#Preview("Conversation Input View") {
    VStack {
        Spacer()

        ConversationInputView(
            messageText: .constant(""),
            placeholder: "iMessage",
            onSend: { message in print("Send: \(message)") },
            onAddTransaction: { print("Add transaction") },
            additionalActions: [
                .theyOweMe { print("They owe me") },
                .iOwe { print("I owe") },
                .splitBill { print("Split bill") }
            ]
        )
    }
    .background(Color.wiseBackground)
}

#Preview("Simple Conversation Input") {
    VStack {
        Spacer()

        SimpleConversationInput(
            messageText: .constant(""),
            placeholder: "Message",
            onSend: { message in print("Send: \(message)") },
            primaryAction: .theyOweMe { print("Action") }
        )
    }
    .background(Color.wiseBackground)
}

#Preview("Input with Text") {
    VStack {
        Spacer()

        ConversationInputView(
            messageText: .constant("Hey, can you split the dinner bill?"),
            placeholder: "iMessage",
            onSend: { _ in },
            onAddTransaction: {},
            additionalActions: []
        )
    }
    .background(Color.wiseBackground)
}
