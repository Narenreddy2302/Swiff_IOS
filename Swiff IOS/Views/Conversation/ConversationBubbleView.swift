//
//  ConversationBubbleView.swift
//  Swiff IOS
//
//  Base chat-style bubble component for conversation views
//  Used across People, Groups, and Subscriptions pages
//

import SwiftUI

// MARK: - Bubble Type

public enum BubbleType {
    case incoming  // Money coming to you (left-aligned, gray)
    case outgoing  // Money going out (right-aligned, blue)
    case systemEvent  // System notifications (centered, subtle)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(bubbleBackground)
                .clipShape(BubbleShape(alignment: alignment))
                .foregroundColor(foregroundColor)

            if alignment == .left || alignment == .center {
                Spacer()
            }
        }
        .padding(.horizontal, 4) // Tiny padding for the tail
        .frame(maxWidth: alignment == .center ? 280 : .infinity)
    }

    private var bubbleBackground: Color {
        switch type {
        case .incoming:
            return Color(UIColor.systemGray5) // iMessage Gray
        case .outgoing:
            return Color.blue // iMessage Blue
        case .systemEvent:
            return Color.wiseBorder.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch type {
        case .incoming:
            return .primary
        case .outgoing:
            return .white
        case .systemEvent:
            return .secondary
        }
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let alignment: BubbleAlignment
    let cornerRadius: CGFloat = 18
    let tailRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let path = Path { path in
            let width = rect.width
            let height = rect.height
            
            switch alignment {
            case .left:
                // Start at top left (after corner)
                path.move(to: CGPoint(x: 20, y: 0))
                
                // Top edge
                path.addLine(to: CGPoint(x: width - 20, y: 0))
                
                // Top right corner
                path.addCurve(to: CGPoint(x: width, y: 20),
                              control1: CGPoint(x: width - 8, y: 0),
                              control2: CGPoint(x: width, y: 8))
                
                // Right edge
                path.addLine(to: CGPoint(x: width, y: height - 20))
                
                // Bottom right corner
                path.addCurve(to: CGPoint(x: width - 20, y: height),
                              control1: CGPoint(x: width, y: height - 8),
                              control2: CGPoint(x: width - 8, y: height))
                
                // Bottom edge
                path.addLine(to: CGPoint(x: 21, y: height))
                
                // Bottom left tail
                path.addCurve(to: CGPoint(x: 4, y: height - 4),
                              control1: CGPoint(x: 12, y: height),
                              control2: CGPoint(x: 4, y: height))
                
                path.addCurve(to: CGPoint(x: 0, y: height),
                              control1: CGPoint(x: 4, y: height),
                              control2: CGPoint(x: 0, y: height))
                
                // Tail connection
                path.addCurve(to: CGPoint(x: 0, y: height - 20),
                              control1: CGPoint(x: 0, y: height - 8),
                              control2: CGPoint(x: 0, y: height - 12))
                
                // Left edge (up to top left corner)
                path.addLine(to: CGPoint(x: 0, y: 20))
                
                // Top left corner
                path.addCurve(to: CGPoint(x: 20, y: 0),
                              control1: CGPoint(x: 0, y: 8),
                              control2: CGPoint(x: 8, y: 0))
                
            case .right:
                // Start at top left (after corner)
                path.move(to: CGPoint(x: 20, y: 0))
                
                // Top edge
                path.addLine(to: CGPoint(x: width - 20, y: 0))
                
                // Top right corner
                path.addCurve(to: CGPoint(x: width, y: 20),
                              control1: CGPoint(x: width - 8, y: 0),
                              control2: CGPoint(x: width, y: 8))
                
                // Right edge (down to tail)
                path.addLine(to: CGPoint(x: width, y: height - 20))
                
                // Tail connection
                path.addCurve(to: CGPoint(x: width, y: height),
                              control1: CGPoint(x: width, y: height - 12),
                              control2: CGPoint(x: width, y: height - 8))
                
                path.addCurve(to: CGPoint(x: width - 4, y: height - 4),
                              control1: CGPoint(x: width, y: height),
                              control2: CGPoint(x: width - 4, y: height))
                
                path.addCurve(to: CGPoint(x: width - 21, y: height),
                              control1: CGPoint(x: width - 4, y: height),
                              control2: CGPoint(x: width - 12, y: height))
                
                // Bottom edge
                path.addLine(to: CGPoint(x: 20, y: height))
                
                // Bottom left corner
                path.addCurve(to: CGPoint(x: 0, y: height - 20),
                              control1: CGPoint(x: 8, y: height),
                              control2: CGPoint(x: 0, y: height - 8))
                
                // Left edge
                path.addLine(to: CGPoint(x: 0, y: 20))
                
                // Top left corner
                path.addCurve(to: CGPoint(x: 20, y: 0),
                              control1: CGPoint(x: 8, y: 0),
                              control2: CGPoint(x: 0, y: 8))
                
            case .center:
                // Fully rounded (pill shape)
                path.addRoundedRect(
                    in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }
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
                    .cornerRadius(18)
                    .frame(maxWidth: geometry.size.width * maxWidthRatio, alignment: alignment)
                    .foregroundColor(foregroundColor)

                if type == .incoming || type == .systemEvent {
                    Spacer()
                }
            }
        }
    }

    private var bubbleBackground: Color {
        switch type {
        case .incoming:
            return Color(UIColor.systemGray5)
        case .outgoing:
            return Color.blue
        case .systemEvent:
            return Color.wiseBorder.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch type {
        case .incoming:
            return .primary
        case .outgoing:
            return .white
        case .systemEvent:
            return .secondary
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
                        .font(.system(size: 16))
                    Text("+ $125.50")
                        .font(.system(size: 16, weight: .bold))
                }
            }

            // Outgoing bubble (money from you)
            ConversationBubbleView(type: .outgoing) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dinner split")
                        .font(.system(size: 16))
                    Text("- $45.00")
                        .font(.system(size: 16, weight: .bold))
                }
            }

            // System event
            ConversationBubbleView(type: .systemEvent) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("Balance settled")
                        .font(.system(size: 14))
                }
            }
        }
        .padding(16)
    }
}
