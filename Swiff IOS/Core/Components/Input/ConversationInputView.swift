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

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: 8) {
            ForEach(additionalActions) { action in
                QuickActionPill(
                    title: action.title,
                    icon: action.icon,
                    color: action.color,
                    isFlexible: true,
                    accessibilityHintText: action.accessibilityHint,
                    action: action.action
                )
            }
        }
        .padding(.horizontal, 16)
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
            .accessibilityLabel("Message input")
            .accessibilityHint("Type a message to send")
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
        .accessibilityLabel(canSend ? "Send message" : "Send disabled")
        .accessibilityHint(canSend ? "Double tap to send your message" : "Enter text to enable sending")
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
enum ConversationInputAction: Identifiable {
    case addTransaction(() -> Void)
    case remind(() -> Void)
    case settleUp(() -> Void)
    case theyOweMe(() -> Void)
    case iOwe(() -> Void)
    case splitBill(() -> Void)
    case settle(() -> Void)

    var id: String {
        switch self {
        case .addTransaction: return "addTransaction"
        case .remind: return "remind"
        case .settleUp: return "settleUp"
        case .theyOweMe: return "theyOweMe"
        case .iOwe: return "iOwe"
        case .splitBill: return "splitBill"
        case .settle: return "settle"
        }
    }

    var title: String {
        switch self {
        case .addTransaction: return "Add"
        case .remind: return "Remind"
        case .settleUp: return "Settle"
        case .theyOweMe: return "They Owe Me"
        case .iOwe: return "I Owe"
        case .splitBill: return "Split Bill"
        case .settle: return "Settle"
        }
    }

    var icon: String {
        switch self {
        case .addTransaction: return "plus.circle.fill"
        case .remind: return "bell.fill"
        case .settleUp: return "checkmark"
        case .theyOweMe: return "arrow.down.circle.fill"
        case .iOwe: return "arrow.up.circle.fill"
        case .splitBill: return "rectangle.split.2x1"
        case .settle: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .addTransaction: return Theme.Colors.brandPrimary  // Green
        case .remind: return Color(UIColor.systemGray)  // Dark gray
        case .settleUp: return Color(UIColor.systemGray)  // Dark gray
        case .theyOweMe: return .wiseBrightGreen
        case .iOwe: return .wiseBlue
        case .splitBill: return .purple
        case .settle: return .wiseWarning
        }
    }

    var accessibilityHint: String {
        switch self {
        case .addTransaction: return "Create a new payment or split"
        case .remind: return "Send a payment reminder to this person"
        case .settleUp: return "Mark the outstanding balance as paid"
        case .theyOweMe: return "Record money owed to you"
        case .iOwe: return "Record money you owe"
        case .splitBill: return "Split a bill among multiple people"
        case .settle: return "Settle the outstanding balance"
        }
    }

    var action: () -> Void {
        switch self {
        case .addTransaction(let action): return action
        case .remind(let action): return action
        case .settleUp(let action): return action
        case .theyOweMe(let action): return action
        case .iOwe(let action): return action
        case .splitBill(let action): return action
        case .settle(let action): return action
        }
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
                .addTransaction { print("Add transaction") },
                .remind { print("Remind") },
                .settleUp { print("Settle up") },
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
