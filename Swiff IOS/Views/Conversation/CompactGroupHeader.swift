//
//  CompactGroupHeader.swift
//  Swiff IOS
//
//  Compact header for group conversation view
//  Matches PersonConversationHeader style
//

import SwiftUI

struct CompactGroupHeader: View {
    let group: Group
    let members: [Person]
    var onBack: (() -> Void)?
    var onInfo: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            // Back button
            if let onBack = onBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
            }

            // Centered Title Info
            Spacer()

            VStack(spacing: 2) {
                // Emoji + Name
                HStack(spacing: 6) {
                    UnifiedEmojiCircle(
                        emoji: group.emoji,
                        backgroundColor: .clear,
                        size: 24
                    )

                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }

                // Member count (Subtitle)
                Text("\(members.count) members")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
            .offset(x: onBack != nil ? -16 : 0)  // Optical centering compensation

            Spacer()

            // Info Button
            if let onInfo = onInfo {
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Theme.Colors.border)
                .frame(height: 0.5), alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview("CompactGroupHeader") {
    ZStack {
        Color.wiseBackground.ignoresSafeArea()
        CompactGroupHeader(
            group: MockData.groupWithExpenses,
            members: [MockData.personOwedMoney, MockData.personOwingMoney],
            onBack: {},
            onInfo: {}
        )
    }
}
