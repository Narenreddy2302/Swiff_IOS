//
//  UnifiedCard.swift
//  Swiff IOS
//
//  Base card wrapper providing consistent styling for all card components
//

import SwiftUI

// MARK: - Unified Card

/// Base card wrapper providing consistent styling for all card components.
/// Provides card background, corner radius, shadow, and optional tap interaction.
struct UnifiedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    var onTap: (() -> Void)? = nil

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.onTap = onTap
    }

    @ViewBuilder
    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(CardButtonStyle())
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        content
            .padding(padding)
            .background(Color.wiseCardBackground)
            .cornerRadius(cornerRadius)
            .cardShadow()
    }
}

// MARK: - Preview

#Preview("UnifiedCard") {
    VStack(spacing: 16) {
        UnifiedCard {
            HStack {
                Text("Simple Card")
                Spacer()
                Text("Value")
            }
        }

        UnifiedCard(onTap: { print("Tapped") }) {
            HStack {
                Text("Tappable Card")
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
    }
    .padding()
    .background(Color.wiseGroupedBackground)
}
