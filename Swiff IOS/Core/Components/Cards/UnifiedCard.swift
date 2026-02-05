//
//  UnifiedCard.swift
//  Swiff IOS
//
//  Base card wrapper providing consistent styling for all card components
//  Updated with new UI Design System specifications
//

import SwiftUI

// MARK: - Unified Card

/// Base card wrapper providing consistent styling for all card components.
/// Provides card background, corner radius (20px), shadow, and optional tap interaction.
/// Per design system: Dark Charcoal (#1C1C1E) in dark mode, White in light mode
struct UnifiedCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    let content: Content
    var padding: CGFloat = Theme.Metrics.cardPadding  // 24pt
    var cornerRadius: CGFloat = Theme.Metrics.cardCornerRadius  // 20pt
    var showBorder: Bool = true
    var onTap: (() -> Void)? = nil

    init(
        padding: CGFloat = Theme.Metrics.cardPadding,
        cornerRadius: CGFloat = Theme.Metrics.cardCornerRadius,
        showBorder: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        showBorder ? Theme.Colors.borderSubtle : Color.clear,
                        lineWidth: Theme.Border.widthDefault
                    )
            )
            .cardShadow()
    }
}

// MARK: - Feature Card

/// Feature card with larger padding and corner radius (24px)
/// Per design system: 32px padding, 24px corner radius
struct FeatureCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    let content: Content
    var padding: CGFloat = Theme.Metrics.featureCardPadding  // 32pt
    var cornerRadius: CGFloat = Theme.Metrics.featureCardCornerRadius  // 24pt
    var showBorder: Bool = true
    var onTap: (() -> Void)? = nil

    init(
        padding: CGFloat = Theme.Metrics.featureCardPadding,
        cornerRadius: CGFloat = Theme.Metrics.featureCardCornerRadius,
        showBorder: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        showBorder ? Theme.Colors.borderDefault : Color.clear,
                        lineWidth: Theme.Border.widthDefault
                    )
            )
            .cardShadow()
    }
}

// MARK: - Preview

#Preview("UnifiedCard") {
    VStack(spacing: 16) {
        UnifiedCard {
            HStack {
                Text("Simple Card")
                    .foregroundColor(.wisePrimaryText)
                Spacer()
                Text("Value")
                    .foregroundColor(.wiseSecondaryText)
            }
        }

        UnifiedCard(onTap: { print("Tapped") }) {
            HStack {
                Text("Tappable Card")
                    .foregroundColor(.wisePrimaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.wiseSecondaryText)
            }
        }

        FeatureCard {
            VStack(alignment: .leading, spacing: Theme.Metrics.spaceMD) {
                Text("Feature Card")
                    .font(Theme.Fonts.featureCardTitle)
                    .foregroundColor(.wisePrimaryText)
                Text("With larger padding and corner radius")
                    .font(Theme.Fonts.featureCardDescription)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
