//
//  TimelineInputArea.swift
//  Swiff IOS
//
//  Created by Claude Code on 12/20/25.
//  Bottom input bar with quick action button and optional text field
//

import SwiftUI

struct TimelineInputArea: View {
    let config: TimelineInputAreaConfig
    let onQuickAction: () -> Void
    var onSend: ((String) -> Void)?

    @State private var messageText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Plus Button (Left)
                Button(action: onQuickAction) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Circle())
                }

                // Text Field (Center)
                HStack {
                    TextField("iMessage", text: $messageText)
                        .font(.system(size: 17))
                        .focused($isFocused)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .background(
                    Capsule()
                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                )

                // Send Button (Right) - Only visible when typing
                if !messageText.isEmpty {
                    Button(action: {
                        onSend?(messageText)
                        messageText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .transition(.scale)
                } else {
                     // Placeholder for Mic or just empty space to keep alignment
                     // For now, let's keep it clean
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
        }
    }
}

#Preview {
    VStack {
        Spacer()
        TimelineInputArea(
            config: TimelineInputAreaConfig(
                quickActionTitle: "New split",
                quickActionIcon: "plus",
                placeholder: "iMessage",
                showMessageField: true
            ),
            onQuickAction: { print("Quick action") },
            onSend: { _ in }
        )
    }
}
