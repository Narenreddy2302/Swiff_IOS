//
//  TimelineItemView.swift
//  Swiff IOS
//
//  Created for SWIFF iOS Timeline/Conversation UI Redesign
//  Wrapper for individual timeline items with icon and connector
//

import SwiftUI

struct TimelineItemView<Content: View>: View {
    let iconType: TimelineIconType
    let isLast: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: Icon with connecting line
            VStack(spacing: 0) {
                TimelineIconView(type: iconType)

                if !isLast {
                    TimelineConnector()
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 24)

            // Right: Content
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 0) {
        TimelineItemView(iconType: .payment, isLast: false) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment received")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                Text("$50.00 from John")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
        }

        TimelineItemView(iconType: .expense, isLast: false) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Split bill created")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                Text("Dinner at restaurant")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
        }

        TimelineItemView(iconType: .system, isLast: true) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance settled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
            }
        }
    }
    .background(Color.wiseBackground)
}
