//
//  ChatBubble.swift
//  Swiff IOS
//
//  Created for SWIFF iOS "iMessage Style" Redesign
//  Base bubble container for chat-style interface
//

import SwiftUI

enum ChatBubbleDirection {
    case incoming // Left (Other person)
    case outgoing // Right (Current user)
    case center   // System/Status messages
}

struct ChatBubble<Content: View>: View {
    let direction: ChatBubbleDirection
    let timestamp: Date?
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if direction == .outgoing {
                Spacer()
            }
            
            VStack(alignment: direction == .incoming ? .leading : (direction == .outgoing ? .trailing : .center), spacing: 2) {
                content()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .clipShape(bubbleShape)
                    .foregroundColor(textColor)
                
                if let date = timestamp, direction != .center {
                    Text(formatTime(date))
                        .font(.system(size: 11))
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.horizontal, 4)
                }
            }
            
            if direction == .incoming {
                Spacer()
            }
        }
        .padding(.horizontal, 8) // Match iMessage standard padding
        .padding(.vertical, 2)
    }
    
    private var bubbleBackground: Color {
        switch direction {
        case .incoming:
            return Color(UIColor.systemGray5) // Standard iOS incoming gray
        case .outgoing:
            return .wiseBlue // Use app's primary blue for outgoing
        case .center:
            return .clear
        }
    }
    
    private var textColor: Color {
        switch direction {
        case .incoming:
            return .primary
        case .outgoing:
            return .white
        case .center:
            return .wiseSecondaryText
        }
    }
    
    private var bubbleShape: some Shape {
        // Simple rounded rectangle for now, could be more complex "bubble" shape later
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        ChatBubble(direction: .incoming, timestamp: Date()) {
            Text("Hey, did you pay for dinner?")
        }
        
        ChatBubble(direction: .outgoing, timestamp: Date()) {
            Text("Yes, it was $45. I'll split it now.")
        }
        
        ChatBubble(direction: .center, timestamp: nil) {
            Text("You split a bill")
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.wiseSecondaryText.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
