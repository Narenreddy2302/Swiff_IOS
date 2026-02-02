//
//  MessageBubbleView.swift
//  Swiff IOS
//
//  Dedicated text message bubble component with iMessage styling
//  Features: iMessageBubbleShape, direction-based colors, optional tail for grouping
//

import SwiftUI

// MARK: - Message Bubble View

/// A dedicated view for displaying text messages in iMessage style
/// Uses iMessageBubbleShape for authentic bubble appearance with tails
struct MessageBubbleView: View {
    let message: ConversationMessage
    let showTail: Bool
    let maxWidthRatio: CGFloat

    // MARK: - Initialization

    init(
        message: ConversationMessage,
        showTail: Bool = true,
        maxWidthRatio: CGFloat = 0.75
    ) {
        self.message = message
        self.showTail = showTail
        self.maxWidthRatio = maxWidthRatio
    }

    // MARK: - Computed Properties

    private var bubbleDirection: iMessageBubbleDirection {
        message.isSent ? .outgoing : .incoming
    }

    private var backgroundColor: Color {
        message.isSent ? .iMessageBlue : .iMessageGray
    }

    private var textColor: Color {
        message.isSent ? .white : .wisePrimaryText
    }

    private var alignment: HorizontalAlignment {
        message.isSent ? .trailing : .leading
    }

    // MARK: - Body

    var body: some View {
        HStack {
            if message.isSent {
                Spacer()
            }

            VStack(alignment: alignment, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(.system(size: 17))
                    .lineSpacing(2)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: UIScreen.main.bounds.width * maxWidthRatio, alignment: message.isSent ? .trailing : .leading)

                // Message status indicator (for sent messages)
                if message.isSent {
                    statusIndicator
                }
            }

            if !message.isSent {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        switch message.status {
        case .sending:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                Text("Sending...")
                    .font(.system(size: 10))
                    .foregroundColor(.wiseSecondaryText)
            }
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
        case .delivered:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.wiseSecondaryText)
        case .read:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.wiseBlue)
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.wiseError)
                Text("Failed")
                    .foregroundColor(.wiseError)
            }
            .font(.system(size: 10, weight: .medium))
        }
    }
}

// MARK: - Simple Message Bubble

/// A simpler version for basic text display without ConversationMessage model
struct SimpleMessageBubble: View {
    let text: String
    let isSent: Bool
    let showTail: Bool

    init(text: String, isSent: Bool, showTail: Bool = true) {
        self.text = text
        self.isSent = isSent
        self.showTail = showTail
    }

    private var bubbleDirection: iMessageBubbleDirection {
        isSent ? .outgoing : .incoming
    }

    private var backgroundColor: Color {
        isSent ? .iMessageBlue : .iMessageGray
    }

    private var textColor: Color {
        isSent ? .white : .wisePrimaryText
    }

    var body: some View {
        HStack {
            if isSent {
                Spacer()
            }

            Text(text)
                .font(.system(size: 17))
                .lineSpacing(2)
                .foregroundColor(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isSent ? .trailing : .leading)

            if !isSent {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview("Message Bubble View") {
    ScrollView {
        VStack(spacing: 8) {
            // Date header
            Text("Today")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
                .padding(.vertical, 16)

            // Incoming messages
            MessageBubbleView(
                message: ConversationMessage(
                    entityId: UUID(),
                    entityType: .contact,
                    content: "Hey, can you send me the money for dinner?",
                    isSent: false
                ),
                showTail: true
            )

            MessageBubbleView(
                message: ConversationMessage(
                    entityId: UUID(),
                    entityType: .contact,
                    content: "It was $45 total",
                    isSent: false
                ),
                showTail: false
            )

            // Outgoing messages
            MessageBubbleView(
                message: ConversationMessage(
                    entityId: UUID(),
                    entityType: .contact,
                    content: "Sure! Let me create a due now",
                    isSent: true,
                    status: .delivered
                ),
                showTail: true
            )

            MessageBubbleView(
                message: ConversationMessage(
                    entityId: UUID(),
                    entityType: .contact,
                    content: "Done!",
                    isSent: true,
                    status: .read
                ),
                showTail: false
            )

            // Failed message
            MessageBubbleView(
                message: ConversationMessage(
                    entityId: UUID(),
                    entityType: .contact,
                    content: "This message failed to send",
                    isSent: true,
                    status: .failed
                ),
                showTail: true
            )
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}

#Preview("Simple Message Bubble") {
    VStack(spacing: 8) {
        SimpleMessageBubble(text: "Incoming message", isSent: false, showTail: true)
        SimpleMessageBubble(text: "Grouped message", isSent: false, showTail: false)
        SimpleMessageBubble(text: "Outgoing message", isSent: true, showTail: true)
        SimpleMessageBubble(text: "Grouped outgoing", isSent: true, showTail: false)
    }
    .padding()
    .background(Color.wiseBackground)
}
