//
//  NestedCardView.swift
//  Swiff IOS
//
//  Created for SWIFF iOS Timeline/Conversation UI Redesign
//  Card displayed within timeline bubbles for detailed information
//

import SwiftUI

struct NestedCardView<Content: View>: View {
    let senderName: String?
    let senderInitials: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Sender header (optional) - simplified without avatar
            if let name = senderName {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
            }

            // Card content
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wiseTertiaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        // Card with sender
        NestedCardView(senderName: "John Doe", senderInitials: "JD") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Dinner at Italian Restaurant")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)

                HStack {
                    Text("You owe")
                        .font(.system(size: 11))
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text("$25.50")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }

        // Card without sender
        NestedCardView(senderName: nil, senderInitials: nil) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Netflix Subscription")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)

                HStack {
                    Text("Monthly")
                        .font(.system(size: 11))
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text("$15.99")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
