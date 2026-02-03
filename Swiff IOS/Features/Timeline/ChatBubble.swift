//
//  ChatBubble.swift
//  Swiff IOS
//
//  Simple rectangular chat bubble component
//  Features: Clean rectangular design, minimal styling, functional approach
//
//

import SwiftUI

// MARK: - Chat Bubble Direction

enum ChatBubbleDirection {
    case incoming  // Left (Other person) - gray
    case outgoing  // Right (Current user) - blue
    case center  // System/Status messages
}

// MARK: - Chat Bubble View

struct ChatBubble<Content: View>: View {
    let direction: ChatBubbleDirection
    let showTail: Bool  // Kept for API compatibility but not used
    let timestamp: Date?
    let maxWidthRatio: CGFloat

    @ViewBuilder let content: () -> Content

    // MARK: - Initializer

    init(
        direction: ChatBubbleDirection,
        showTail: Bool = true,
        timestamp: Date? = nil,
        maxWidthRatio: CGFloat = 0.75,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.direction = direction
        self.showTail = showTail
        self.timestamp = timestamp
        self.maxWidthRatio = maxWidthRatio
        self.content = content
    }

    /// Convenience initializer without showTail (defaults to true)
    init(
        direction: ChatBubbleDirection,
        timestamp: Date?,
        maxWidthRatio: CGFloat = 0.75,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.direction = direction
        self.showTail = true
        self.timestamp = timestamp
        self.maxWidthRatio = maxWidthRatio
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if direction == .outgoing {
                Spacer(minLength: 40)  // More space on left for outgoing
            }

            bubbleContent
                .frame(maxWidth: direction == .center ? .infinity : nil)

            if direction == .incoming {
                Spacer(minLength: 40)  // More space on right for incoming
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }

    // MARK: - Bubble Content

    private var bubbleContent: some View {
        content()
            .background(backgroundColor)
            .cornerRadius(16)  // Simple rounded corners
            .foregroundColor(textColor)
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        switch direction {
        case .incoming:
            return .wisePrimaryText
        case .outgoing:
            return .white
        case .center:
            return .wiseSecondaryText
        }
    }

    private var backgroundColor: Color {
        switch direction {
        case .incoming:
            return .iMessageGray  // Adaptive: #E9E9EB light, #2C2C2E dark
        case .outgoing:
            return .iMessageBlue  // #007AFF - Keep the blue for outgoing
        case .center:
            return .clear
        }
    }
}

// MARK: - Preview

#Preview("Chat Bubbles - Rectangular Style") {
    ScrollView {
        VStack(spacing: 8) {
            // Date header
            Text("Today")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
                .padding(.vertical, 16)

            // Incoming messages
            ChatBubble(direction: .incoming, timestamp: Date()) {
                Text("Hey, did you pay for dinner?")
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }

            ChatBubble(direction: .incoming, timestamp: Date()) {
                Text("I can Venmo you later")
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }

            // Outgoing messages
            ChatBubble(direction: .outgoing, timestamp: Date()) {
                Text("Yes!")
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }

            ChatBubble(direction: .outgoing, timestamp: Date()) {
                Text("It was $45 total")
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }

            ChatBubble(direction: .outgoing, timestamp: Date()) {
                Text("I'll create a split now")
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }

            // Center system message
            ChatBubble(direction: .center, timestamp: nil) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseBrightGreen)
                    Text("Bill split successfully")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.wiseSecondaryText.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}
