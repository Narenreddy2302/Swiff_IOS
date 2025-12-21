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

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if config.showMessageField {
                    // Text field with "Send a message..." placeholder
                    TextField(config.placeholder, text: $messageText)
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                }

                // Quick action button - "+ New split" format
                Button(action: onQuickAction) {
                    HStack(spacing: 5) {
                        Image(systemName: config.quickActionIcon)
                            .font(.system(size: 12, weight: .medium))
                        Text(config.quickActionTitle)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }

                // Send button - BLACK background with white text (always visible when message field enabled)
                if config.showMessageField {
                    Button(action: {
                        onSend?(messageText)
                        messageText = ""
                    }) {
                        Text("Send")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Color.wisePrimaryText)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wiseCardBackground)
            .overlay(
                Rectangle()
                    .fill(Color.wiseBorder)
                    .frame(height: 1),
                alignment: .top
            )
        }
    }
}

#Preview {
    VStack {
        Spacer()

        Text("Without message field")
            .font(.caption)
            .foregroundColor(.secondary)
        TimelineInputArea(
            config: TimelineInputAreaConfig(
                quickActionTitle: "Record Payment",
                quickActionIcon: "plus",
                placeholder: "",
                showMessageField: false
            ),
            onQuickAction: {
                print("Quick action tapped")
            }
        )

        Spacer()

        Text("With message field")
            .font(.caption)
            .foregroundColor(.secondary)
        TimelineInputArea(
            config: TimelineInputAreaConfig(
                quickActionTitle: "New split",
                quickActionIcon: "plus",
                placeholder: "Send a message...",
                showMessageField: true
            ),
            onQuickAction: {
                print("Quick action tapped")
            },
            onSend: { message in
                print("Sent message: \(message)")
            }
        )
    }
    .background(Color.wiseBackground)
}
