//
//  ChatBubble.swift
//  Swiff IOS
//
//  Chat bubble component with new UI Design System styling
//  Features: 20px corner radius, 4px tail, cream text on dark backgrounds
//

import SwiftUI

// MARK: - Chat Bubble Direction

enum ChatBubbleDirection {
    case incoming  // Left (Other person) - Medium Gray (#3A3A3C)
    case outgoing  // Right (Current user) - Olive Gray (#4A5148)
    case center  // System/Status messages
}

// MARK: - Chat Bubble View

struct ChatBubble<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    let direction: ChatBubbleDirection
    let showTail: Bool
    let timestamp: Date?
    let maxWidthRatio: CGFloat

    @ViewBuilder let content: () -> Content

    // MARK: - Initializer

    init(
        direction: ChatBubbleDirection,
        showTail: Bool = true,
        timestamp: Date? = nil,
        maxWidthRatio: CGFloat = Theme.Metrics.chatBubbleMaxWidthRatio,
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
        maxWidthRatio: CGFloat = Theme.Metrics.chatBubbleMaxWidthRatio,
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
                Spacer(minLength: 40)
            }

            bubbleContent
                .frame(maxWidth: direction == .center ? .infinity : nil)

            if direction == .incoming {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, Theme.Metrics.spaceMD)
        .padding(.vertical, 3)
    }

    // MARK: - Bubble Content

    private var bubbleContent: some View {
        content()
            .background(backgroundColor)
            .clipShape(BubbleShape(direction: direction, showTail: showTail))
            .foregroundColor(textColor)
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        switch direction {
        case .incoming:
            // Cream text in dark mode, dark text in light mode
            return colorScheme == .dark ? Theme.Colors.creamWhite : .wisePrimaryText
        case .outgoing:
            // Cream text in dark mode, white on teal in light mode
            return colorScheme == .dark ? Theme.Colors.creamWhite : .white
        case .center:
            return .wiseSecondaryText
        }
    }

    private var backgroundColor: Color {
        switch direction {
        case .incoming:
            // Medium Gray (#3A3A3C) in dark mode
            return colorScheme == .dark ? Theme.Colors.mediumGray : Color.iMessageGray
        case .outgoing:
            // Olive Gray (#4A5148) in dark mode, Teal in light mode
            return colorScheme == .dark ? Theme.Colors.oliveGray : Theme.Colors.teal
        case .center:
            return .clear
        }
    }
}

// MARK: - Bubble Shape with Tail

struct BubbleShape: Shape {
    let direction: ChatBubbleDirection
    let showTail: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = Theme.Metrics.chatBubbleCornerRadius  // 20px
        let tailRadius: CGFloat = Theme.Metrics.chatBubbleTailRadius  // 4px

        var path = Path()

        switch direction {
        case .incoming:
            // Incoming bubble - tail on bottom left
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: cornerRadius,
                    bottomLeading: showTail ? tailRadius : cornerRadius,
                    bottomTrailing: cornerRadius,
                    topTrailing: cornerRadius
                )
            )
        case .outgoing:
            // Outgoing bubble - tail on bottom right
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: cornerRadius,
                    bottomLeading: cornerRadius,
                    bottomTrailing: showTail ? tailRadius : cornerRadius,
                    topTrailing: cornerRadius
                )
            )
        case .center:
            // System message - uniform corners
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 12, height: 12))
        }

        return path
    }
}

// MARK: - Preview

#Preview("Chat Bubbles - New Design System") {
    ScrollView {
        VStack(spacing: 8) {
            // Date header
            Text("Today")
                .font(Theme.Fonts.chatTimestamp)
                .foregroundColor(.wiseSecondaryText)
                .padding(.vertical, 16)

            // Incoming messages - Medium Gray (#3A3A3C)
            ChatBubble(direction: .incoming, timestamp: Date()) {
                Text("Hey, did you pay for dinner?")
                    .font(Theme.Fonts.chatMessage)
                    .padding(.horizontal, Theme.Metrics.chatBubblePaddingH)
                    .padding(.vertical, Theme.Metrics.chatBubblePaddingV)
            }

            ChatBubble(direction: .incoming, showTail: false, timestamp: Date()) {
                Text("I can Venmo you later")
                    .font(Theme.Fonts.chatMessage)
                    .padding(.horizontal, Theme.Metrics.chatBubblePaddingH)
                    .padding(.vertical, Theme.Metrics.chatBubblePaddingV)
            }

            // Outgoing messages - Olive Gray (#4A5148) in dark mode
            ChatBubble(direction: .outgoing, timestamp: Date()) {
                Text("Yes!")
                    .font(Theme.Fonts.chatMessage)
                    .padding(.horizontal, Theme.Metrics.chatBubblePaddingH)
                    .padding(.vertical, Theme.Metrics.chatBubblePaddingV)
            }

            ChatBubble(direction: .outgoing, showTail: false, timestamp: Date()) {
                Text("It was $45 total")
                    .font(Theme.Fonts.chatMessage)
                    .padding(.horizontal, Theme.Metrics.chatBubblePaddingH)
                    .padding(.vertical, Theme.Metrics.chatBubblePaddingV)
            }

            ChatBubble(direction: .outgoing, timestamp: Date()) {
                Text("I'll create a split now")
                    .font(Theme.Fonts.chatMessage)
                    .padding(.horizontal, Theme.Metrics.chatBubblePaddingH)
                    .padding(.vertical, Theme.Metrics.chatBubblePaddingV)
            }

            // Center system message
            ChatBubble(direction: .center, timestamp: nil) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.teal)
                    Text("Bill split successfully")
                        .font(Theme.Fonts.chatSystemMessage)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.Colors.hoverOverlay)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
    .background(Color.wiseBackground)
}
