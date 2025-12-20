//
//  ConversationBubbleView.swift
//  Swiff IOS
//
//  Base chat-style bubble component for conversation views
//  Used across People, Groups, and Subscriptions pages
//

import SwiftUI

// MARK: - Bubble Type

enum BubbleType {
    case incoming    // Money coming to you (left-aligned, green-tinted)
    case outgoing    // Money going out (right-aligned, neutral)
    case systemEvent // System notifications (centered, subtle)
}

// MARK: - Bubble Alignment

enum BubbleAlignment {
    case left
    case right
    case center

    init(from type: BubbleType) {
        switch type {
        case .incoming: self = .left
        case .outgoing: self = .right
        case .systemEvent: self = .center
        }
    }
}

// MARK: - Conversation Bubble View

/// Base chat-style bubble component with variants for incoming, outgoing, and system events
struct ConversationBubbleView<Content: View>: View {
    let type: BubbleType
    let content: Content

    init(type: BubbleType, @ViewBuilder content: () -> Content) {
        self.type = type
        self.content = content()
    }

    private var alignment: BubbleAlignment {
        BubbleAlignment(from: type)
    }

    var body: some View {
        HStack {
            if alignment == .right || alignment == .center {
                Spacer()
            }

            content
                .padding(12)
                .background(bubbleBackground)
                .clipShape(BubbleShape(alignment: alignment))
                .overlay(
                    BubbleShape(alignment: alignment)
                        .stroke(bubbleBorderColor, lineWidth: 1)
                )

            if alignment == .left || alignment == .center {
                Spacer()
            }
        }
        .frame(maxWidth: alignment == .center ? 280 : .infinity)
    }

    private var bubbleBackground: Color {
        switch type {
        case .incoming:
            return Color.wiseBrightGreen.opacity(0.08)
        case .outgoing:
            return Color.wiseCardBackground
        case .systemEvent:
            return Color.wiseBorder.opacity(0.2)
        }
    }

    private var bubbleBorderColor: Color {
        switch type {
        case .incoming:
            return Color.wiseBrightGreen.opacity(0.2)
        case .outgoing:
            return Color.wiseBorder
        case .systemEvent:
            return Color.clear
        }
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let alignment: BubbleAlignment
    let cornerRadius: CGFloat = 16
    let tailRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch alignment {
        case .left:
            // Rounded on all corners except bottom-left
            path.move(to: CGPoint(x: rect.minX + tailRadius, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + tailRadius, y: rect.maxY - tailRadius))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + tailRadius, y: rect.maxY - tailRadius))
            path.addLine(to: CGPoint(x: rect.minX + tailRadius, y: rect.minY + cornerRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + tailRadius + cornerRadius, y: rect.minY),
                             control: CGPoint(x: rect.minX + tailRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                             control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                             control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()

        case .right:
            // Rounded on all corners except bottom-right
            path.move(to: CGPoint(x: rect.maxX - tailRadius, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - tailRadius, y: rect.maxY - tailRadius))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - tailRadius, y: rect.maxY - tailRadius))
            path.addLine(to: CGPoint(x: rect.maxX - tailRadius, y: rect.minY + cornerRadius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - tailRadius - cornerRadius, y: rect.minY),
                             control: CGPoint(x: rect.maxX - tailRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius),
                             control: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY),
                             control: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()

        case .center:
            // Fully rounded (pill shape)
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }

        return path
    }
}

// MARK: - Simple Rounded Bubble (Alternative)

/// A simpler bubble without the speech tail
struct RoundedBubbleView<Content: View>: View {
    let type: BubbleType
    let maxWidthRatio: CGFloat
    let content: Content

    init(
        type: BubbleType,
        maxWidthRatio: CGFloat = 0.85,
        @ViewBuilder content: () -> Content
    ) {
        self.type = type
        self.maxWidthRatio = maxWidthRatio
        self.content = content()
    }

    private var alignment: Alignment {
        switch type {
        case .incoming: return .leading
        case .outgoing: return .trailing
        case .systemEvent: return .center
        }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack {
                if type == .outgoing || type == .systemEvent {
                    Spacer()
                }

                content
                    .padding(12)
                    .background(bubbleBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(bubbleBorderColor, lineWidth: 1)
                    )
                    .frame(maxWidth: geometry.size.width * maxWidthRatio, alignment: alignment)

                if type == .incoming || type == .systemEvent {
                    Spacer()
                }
            }
        }
    }

    private var bubbleBackground: Color {
        switch type {
        case .incoming:
            return Color.wiseBrightGreen.opacity(0.08)
        case .outgoing:
            return Color.wiseCardBackground
        case .systemEvent:
            return Color.wiseBorder.opacity(0.2)
        }
    }

    private var bubbleBorderColor: Color {
        switch type {
        case .incoming:
            return Color.wiseBrightGreen.opacity(0.2)
        case .outgoing:
            return Color.wiseBorder
        case .systemEvent:
            return Color.clear
        }
    }
}

// MARK: - Preview

#Preview("Conversation Bubbles") {
    ScrollView {
        VStack(spacing: 14) {
            // Incoming bubble (money to you)
            ConversationBubbleView(type: .incoming) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment from Alex")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("+ $125.50")
                        .font(.spotifyNumberMedium)
                        .foregroundColor(AmountColors.positive)
                    Text("2:30 PM")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Outgoing bubble (money from you)
            ConversationBubbleView(type: .outgoing) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dinner split")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("- $45.00")
                        .font(.spotifyNumberMedium)
                        .foregroundColor(AmountColors.negative)
                    Text("Yesterday")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // System event
            ConversationBubbleView(type: .systemEvent) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseBrightGreen)
                    Text("Balance settled")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .padding(16)
    }
    .background(Color.wiseBackground)
}
