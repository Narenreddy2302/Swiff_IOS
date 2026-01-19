//
//  SplitOptionRow.swift
//  Swiff IOS
//
//  Radio-button style option row for Personal/Split selection
//  Matches reference design with emoji icon and radio button
//

import SwiftUI

/// Row component for Personal/Split selection with radio button style
/// Matches the reference design exactly
struct SplitOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack(spacing: 14) {
                // Emoji icon
                Text(icon)
                    .font(.system(size: 32))

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Radio button
                Circle()
                    .strokeBorder(isSelected ? Color.blue : Color(UIColor.systemGray3), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Split Option Row") {
    struct PreviewWrapper: View {
        @State private var isSplit: Bool = false

        var body: some View {
            VStack(spacing: 0) {
                SplitOptionRow(
                    icon: "1",
                    title: "Personal",
                    subtitle: "Just for you",
                    isSelected: !isSplit
                ) {
                    isSplit = false
                }

                Divider()
                    .padding(.leading, 72)

                SplitOptionRow(
                    icon: "2",
                    title: "Split",
                    subtitle: "Share with friends or groups",
                    isSelected: isSplit
                ) {
                    isSplit = true
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(20)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
