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
public struct UnifiedIconCircle: View {
    public let icon: String  // SF Symbol name
    public let color: Color  // Category/theme color
    public var size: CGFloat = 48  // Circle diameter
    public var iconSize: CGFloat = 20  // Icon size

    public init(icon: String, color: Color, size: CGFloat = 48, iconSize: CGFloat = 20) {
        self.icon = icon
        self.color = color
        self.size = size
        self.iconSize = iconSize
    }

    public var body: some View {
        Circle()
            .fill(color.opacity(0.2))
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
public struct UnifiedEmojiCircle: View {
    public let emoji: String
    public var backgroundColor: Color = .wiseBlue
    public var size: CGFloat = 48

    public init(emoji: String, backgroundColor: Color = .wiseBlue, size: CGFloat = 48) {
        self.emoji = emoji
        self.backgroundColor = backgroundColor
        self.size = size
    }

    public var body: some View {
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

// MARK: - Outlined Icon Circle

/// A variant of UnifiedIconCircle with outlined (stroke) style instead of filled.
/// Used for card-based layouts inspired by Wise/Revolut design.
public struct OutlinedIconCircle: View {
    public let icon: String  // SF Symbol name
    public let color: Color  // Stroke and icon color
    public var size: CGFloat = 48  // Circle diameter
    public var strokeWidth: CGFloat = 2  // Border width
    public var iconSize: CGFloat = 20  // Icon size

    public init(
        icon: String, color: Color, size: CGFloat = 48, strokeWidth: CGFloat = 2,
        iconSize: CGFloat = 20
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.strokeWidth = strokeWidth
        self.iconSize = iconSize
    }

    public var body: some View {
        Circle()
            .stroke(color, lineWidth: strokeWidth)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(color)
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

        Text("OutlinedIconCircle Examples")
            .font(.headline)
            .padding(.top)

        HStack(spacing: 16) {
            OutlinedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
            OutlinedIconCircle(icon: "cart.fill", color: .orange)
            OutlinedIconCircle(icon: "car.fill", color: .wiseBlue)
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
