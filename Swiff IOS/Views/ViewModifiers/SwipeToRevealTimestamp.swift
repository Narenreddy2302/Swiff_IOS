//
//  SwipeToRevealTimestamp.swift
//  Swiff IOS
//
//  iMessage-style swipe-to-reveal timestamp modifier
//  Timestamps are hidden by default and revealed when swiping left
//

import SwiftUI

// MARK: - Swipe To Reveal Timestamp Modifier

struct SwipeToRevealTimestamp: ViewModifier {
    let timestamp: Date
    let direction: iMessageBubbleDirection

    @State private var dragOffset: CGFloat = 0
    @State private var showTimestamp: Bool = false
    @State private var hideTimestampTask: Task<Void, Never>?

    // Configuration
    private let maxDragDistance: CGFloat = 70
    private let triggerThreshold: CGFloat = 30
    private let timestampWidth: CGFloat = 60
    private let autoHideDelay: Double = 2.0

    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            // Timestamp on left (for outgoing - appears when content slides left)
            if direction == iMessageBubbleDirection.outgoing {
                timestampView
                    .opacity(timestampOpacity)
                    .frame(width: showTimestamp ? timestampWidth : 0)
                    .clipped()
            }

            // Main content with drag gesture
            content
                .offset(x: dragOffset)
                .gesture(swipeGesture)

            // Timestamp on right (for incoming/center - appears when content slides left)
            if direction == iMessageBubbleDirection.incoming || direction == iMessageBubbleDirection.center {
                timestampView
                    .opacity(timestampOpacity)
                    .frame(width: showTimestamp ? timestampWidth : 0)
                    .clipped()
            }
        }
    }

    // MARK: - Timestamp View

    private var timestampView: some View {
        Text(formatTime(timestamp))
            .font(.system(size: 11))
            .foregroundColor(.wiseSecondaryText)
            .frame(width: timestampWidth)
    }

    // MARK: - Computed Properties

    private var timestampOpacity: Double {
        let progress = abs(dragOffset) / triggerThreshold
        return min(progress, 1.0)
    }


    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                // Only allow left swipe (negative translation)
                if value.translation.width < 0 {
                    // Cancel any pending hide task
                    hideTimestampTask?.cancel()

                    // Apply drag with resistance at max distance
                    let drag = value.translation.width
                    if abs(drag) < maxDragDistance {
                        dragOffset = drag
                    } else {
                        // Rubber band effect past max
                        let overflow = abs(drag) - maxDragDistance
                        let dampened = maxDragDistance + (overflow * 0.3)
                        dragOffset = -dampened
                    }

                    // Show timestamp when past threshold
                    if abs(dragOffset) > triggerThreshold {
                        showTimestamp = true
                    }
                }
            }
            .onEnded { _ in
                // Animate back to original position
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    dragOffset = 0
                }

                // Schedule auto-hide
                if showTimestamp {
                    scheduleAutoHide()
                }
            }
    }

    // MARK: - Helpers

    private func scheduleAutoHide() {
        hideTimestampTask?.cancel()
        hideTimestampTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoHideDelay * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showTimestamp = false
                    }
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - View Extension

extension View {
    /// Adds iMessage-style swipe-to-reveal timestamp
    func swipeToRevealTimestamp(_ date: Date, direction: iMessageBubbleDirection) -> some View {
        modifier(SwipeToRevealTimestamp(timestamp: date, direction: direction))
    }
}

// MARK: - Preview

#Preview("Swipe To Reveal Timestamp") {
    VStack(spacing: 16) {
        Text("Swipe left on bubbles to reveal timestamps")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 20)

        // Incoming message
        HStack {
            Text("Hey, how are you?")
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray5))
                .clipShape(iMessageBubbleShape(direction: iMessageBubbleDirection.incoming, showTail: true))
            Spacer()
        }
        .padding(.horizontal, 8)
        .swipeToRevealTimestamp(Date(), direction: iMessageBubbleDirection.incoming)
        .frame(height: 50)

        // Outgoing message
        HStack {
            Spacer()
            Text("I'm doing great, thanks!")
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .foregroundColor(.white)
                .background(Color.wiseBlue)
                .clipShape(iMessageBubbleShape(direction: iMessageBubbleDirection.outgoing, showTail: true))
        }
        .padding(.horizontal, 8)
        .swipeToRevealTimestamp(Date().addingTimeInterval(-300), direction: iMessageBubbleDirection.outgoing)
        .frame(height: 50)
    }
    .padding()
    .background(Color.wiseBackground)
}
