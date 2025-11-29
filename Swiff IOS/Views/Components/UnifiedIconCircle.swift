//
//  UnifiedIconCircle.swift
//  Swiff IOS
//
//  Created for Unified List Design System
//  Provides consistent circular icon containers for all list items
//

import SwiftUI

// MARK: - Unified Icon Circle

/// A consistent circular icon container for all list items.
/// Displays an SF Symbol inside a colored circular background.
struct UnifiedIconCircle: View {
    let icon: String              // SF Symbol name
    let color: Color              // Category/theme color
    var size: CGFloat = 48        // Circle diameter
    var iconSize: CGFloat = 20    // Icon size

    var body: some View {
        Circle()
            .fill(color.opacity(0.1))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(color)
            )
    }
}

// MARK: - Unified Emoji Circle

/// A variant of UnifiedIconCircle that displays an emoji character.
/// Used primarily for Groups which use emoji as their icons.
struct UnifiedEmojiCircle: View {
    let emoji: String
    var backgroundColor: Color = .wiseBlue
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [backgroundColor.opacity(0.2), backgroundColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(emoji)
                    .font(.system(size: size * 0.5))
            )
    }
}

// MARK: - Preview

#Preview("Icon Circles") {
    VStack(spacing: 20) {
        Text("UnifiedIconCircle Examples")
            .font(.headline)

        HStack(spacing: 16) {
            UnifiedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
            UnifiedIconCircle(icon: "cart.fill", color: .orange)
            UnifiedIconCircle(icon: "car.fill", color: .wiseBlue)
        }

        Text("UnifiedEmojiCircle Examples")
            .font(.headline)
            .padding(.top)

        HStack(spacing: 16) {
            UnifiedEmojiCircle(emoji: "🏠", backgroundColor: .wiseBlue)
            UnifiedEmojiCircle(emoji: "🎉", backgroundColor: .wiseBrightGreen)
            UnifiedEmojiCircle(emoji: "✈️", backgroundColor: .wiseOrange)
        }

        Text("Size Variations")
            .font(.headline)
            .padding(.top)

        HStack(spacing: 16) {
            UnifiedIconCircle(icon: "star.fill", color: .wiseWarning, size: 32, iconSize: 14)
            UnifiedIconCircle(icon: "star.fill", color: .wiseWarning, size: 48, iconSize: 20)
            UnifiedIconCircle(icon: "star.fill", color: .wiseWarning, size: 64, iconSize: 28)
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
