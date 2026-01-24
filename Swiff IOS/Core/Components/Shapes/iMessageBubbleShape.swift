//
//  iMessageBubbleShape.swift
//  Swiff IOS
//
//  iMessage-style bubble shape with curved tail
//  Used for chat-style conversation views
//

import SwiftUI

// MARK: - iMessage Bubble Shape

struct iMessageBubbleShape: Shape {
    let direction: iMessageBubbleDirection
    let showTail: Bool

    // iMessage-style dimensions
    private let cornerRadius: CGFloat = 18  // Updated to 18 for smoother look
    private let tailWidth: CGFloat = 6  // Slightly narrower tail (10 -> 6)
    private let tailHeight: CGFloat = 6
    private let tailCurveOffset: CGFloat = 4

    init(direction: iMessageBubbleDirection, showTail: Bool = true) {
        self.direction = direction
        self.showTail = showTail
    }

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        // For center alignment or no tail, use simple rounded rectangle
        if direction == .center || !showTail {
            return Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
        }

        return Path { path in
            switch direction {
            case .incoming:
                drawIncomingBubble(path: &path, width: width, height: height)
            case .outgoing:
                drawOutgoingBubble(path: &path, width: width, height: height)
            case .center:
                // Handled above
                break
            }
        }
    }

    // MARK: - Incoming Bubble (Left-aligned with tail on bottom-left)

    private func drawIncomingBubble(path: inout Path, width: CGFloat, height: CGFloat) {
        let cr = cornerRadius

        // Start at top-left corner (after curve)
        path.move(to: CGPoint(x: cr, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: width - cr, y: 0))

        // Top-right corner
        path.addCurve(
            to: CGPoint(x: width, y: cr),
            control1: CGPoint(x: width - cr * 0.45, y: 0),
            control2: CGPoint(x: width, y: cr * 0.45)
        )

        // Right edge
        path.addLine(to: CGPoint(x: width, y: height - cr))

        // Bottom-right corner
        path.addCurve(
            to: CGPoint(x: width - cr, y: height),
            control1: CGPoint(x: width, y: height - cr * 0.45),
            control2: CGPoint(x: width - cr * 0.45, y: height)
        )

        // Bottom edge (to tail)
        path.addLine(to: CGPoint(x: tailWidth + tailCurveOffset, y: height))

        // Tail curve - outer curve down
        path.addCurve(
            to: CGPoint(x: tailCurveOffset, y: height + tailHeight),
            control1: CGPoint(x: tailWidth, y: height),
            control2: CGPoint(x: tailCurveOffset + 2, y: height + tailHeight - 2)
        )

        // Tail tip curve back up
        path.addCurve(
            to: CGPoint(x: 0, y: height - cr),
            control1: CGPoint(x: tailCurveOffset - 2, y: height + tailHeight),
            control2: CGPoint(x: 0, y: height - cr * 0.3)
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cr))

        // Top-left corner
        path.addCurve(
            to: CGPoint(x: cr, y: 0),
            control1: CGPoint(x: 0, y: cr * 0.45),
            control2: CGPoint(x: cr * 0.45, y: 0)
        )

        path.closeSubpath()
    }

    // MARK: - Outgoing Bubble (Right-aligned with tail on bottom-right)

    private func drawOutgoingBubble(path: inout Path, width: CGFloat, height: CGFloat) {
        let cr = cornerRadius

        // Start at top-left corner (after curve)
        path.move(to: CGPoint(x: cr, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: width - cr, y: 0))

        // Top-right corner
        path.addCurve(
            to: CGPoint(x: width, y: cr),
            control1: CGPoint(x: width - cr * 0.45, y: 0),
            control2: CGPoint(x: width, y: cr * 0.45)
        )

        // Right edge (to tail start)
        path.addLine(to: CGPoint(x: width, y: height - cr))

        // Tail tip curve down
        path.addCurve(
            to: CGPoint(x: width - tailCurveOffset, y: height + tailHeight),
            control1: CGPoint(x: width, y: height - cr * 0.3),
            control2: CGPoint(x: width - tailCurveOffset + 2, y: height + tailHeight)
        )

        // Tail curve back to bottom edge
        path.addCurve(
            to: CGPoint(x: width - tailWidth - tailCurveOffset, y: height),
            control1: CGPoint(x: width - tailCurveOffset - 2, y: height + tailHeight - 2),
            control2: CGPoint(x: width - tailWidth, y: height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cr, y: height))

        // Bottom-left corner
        path.addCurve(
            to: CGPoint(x: 0, y: height - cr),
            control1: CGPoint(x: cr * 0.45, y: height),
            control2: CGPoint(x: 0, y: height - cr * 0.45)
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cr))

        // Top-left corner
        path.addCurve(
            to: CGPoint(x: cr, y: 0),
            control1: CGPoint(x: 0, y: cr * 0.45),
            control2: CGPoint(x: cr * 0.45, y: 0)
        )

        path.closeSubpath()
    }
}

// MARK: - Preview

#Preview("iMessage Bubble Shapes") {
    VStack(spacing: 20) {
        // Incoming with tail
        Text("Hey, did you pay for dinner?")
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemGray5))
            .clipShape(
                iMessageBubbleShape(direction: iMessageBubbleDirection.incoming, showTail: true)
            )
            .frame(maxWidth: .infinity, alignment: .leading)

        // Incoming without tail (grouped)
        Text("I can pay you back tomorrow")
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemGray5))
            .clipShape(
                iMessageBubbleShape(direction: iMessageBubbleDirection.incoming, showTail: false)
            )
            .frame(maxWidth: .infinity, alignment: .leading)

        // Outgoing with tail
        Text("Yes! It was $45 total")
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(Color.wiseBlue)
            .clipShape(
                iMessageBubbleShape(direction: iMessageBubbleDirection.outgoing, showTail: true)
            )
            .frame(maxWidth: .infinity, alignment: .trailing)

        // Outgoing without tail (grouped)
        Text("No rush!")
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(Color.wiseBlue)
            .clipShape(
                iMessageBubbleShape(direction: iMessageBubbleDirection.outgoing, showTail: false)
            )
            .frame(maxWidth: .infinity, alignment: .trailing)

        // Center (system message)
        Text("Payment received")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.wiseSecondaryText.opacity(0.1))
            .clipShape(
                iMessageBubbleShape(direction: iMessageBubbleDirection.center, showTail: false))
    }
    .padding()
    .background(Color.wiseBackground)
}
