//
//  AdaptiveShadow.swift
//  Swiff IOS
//
//  Created for Dark Mode Implementation
//  Updated with new UI Design System shadow specifications
//  Provides adaptive shadow that adjusts opacity based on color scheme
//

import SwiftUI

// MARK: - Adaptive Shadow View Modifier

/// A ViewModifier that applies shadows that adapt to light and dark mode.
/// In light mode, shadows are subtle. In dark mode, shadows are more prominent
/// to maintain visual depth against dark backgrounds.
struct AdaptiveShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let lightOpacity: Double
    let darkOpacity: Double

    init(radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 2, lightOpacity: Double = 0.08, darkOpacity: Double = 0.25) {
        self.radius = radius
        self.x = x
        self.y = y
        self.lightOpacity = lightOpacity
        self.darkOpacity = darkOpacity
    }

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? darkOpacity : lightOpacity),
                radius: radius,
                x: x,
                y: y
            )
    }
}

// MARK: - Adaptive Card Shadow

/// A specialized shadow modifier for card-like UI elements.
/// Provides slightly elevated appearance with appropriate depth for each color scheme.
/// Per design system: Light mode 0.08 opacity, Dark mode 0.25 opacity
struct AdaptiveCardShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Adaptive Elevated Shadow

/// A shadow modifier for elevated UI elements like floating buttons or popovers.
/// More pronounced than card shadows for stronger visual hierarchy.
/// Per design system: Light mode 0.15 opacity, Dark mode 0.4 opacity
struct AdaptiveElevatedShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
                radius: 16,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Adaptive Subtle Shadow

/// A very subtle shadow for minimal depth indication.
/// Useful for list items or subtle separations between elements.
/// Per design system: Light mode 0.05 opacity, Dark mode 0.15 opacity
struct AdaptiveSubtleShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05),
                radius: 4,
                x: 0,
                y: 1
            )
    }
}

// MARK: - View Extension

extension View {
    /// Applies an adaptive shadow that adjusts opacity based on color scheme.
    /// - Parameters:
    ///   - radius: The blur radius of the shadow. Default is 8.
    ///   - x: The horizontal offset of the shadow. Default is 0.
    ///   - y: The vertical offset of the shadow. Default is 2.
    ///   - lightOpacity: Shadow opacity in light mode. Default is 0.08.
    ///   - darkOpacity: Shadow opacity in dark mode. Default is 0.25.
    /// - Returns: A view with an adaptive shadow applied.
    func adaptiveShadow(
        radius: CGFloat = 8,
        x: CGFloat = 0,
        y: CGFloat = 2,
        lightOpacity: Double = 0.08,
        darkOpacity: Double = 0.25
    ) -> some View {
        self.modifier(AdaptiveShadow(
            radius: radius,
            x: x,
            y: y,
            lightOpacity: lightOpacity,
            darkOpacity: darkOpacity
        ))
    }

    /// Applies a standard card shadow that adapts to color scheme.
    /// Use this for card-like UI components.
    func cardShadow() -> some View {
        self.modifier(AdaptiveCardShadow())
    }

    /// Applies an elevated shadow that adapts to color scheme.
    /// Use this for floating buttons, popovers, or modal elements.
    func elevatedShadow() -> some View {
        self.modifier(AdaptiveElevatedShadow())
    }

    /// Applies a subtle shadow that adapts to color scheme.
    /// Use this for list items or minimal depth indication.
    func subtleShadow() -> some View {
        self.modifier(AdaptiveSubtleShadow())
    }
}

// MARK: - Adaptive Overlay

/// A ViewModifier that applies a dimming overlay that adapts to color scheme.
struct AdaptiveOverlay: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let lightOpacity: Double
    let darkOpacity: Double

    init(lightOpacity: Double = 0.4, darkOpacity: Double = 0.6) {
        self.lightOpacity = lightOpacity
        self.darkOpacity = darkOpacity
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Color.black.opacity(colorScheme == .dark ? darkOpacity : lightOpacity)
            )
    }
}

extension View {
    /// Applies a dimming overlay that adapts to color scheme.
    /// - Parameters:
    ///   - lightOpacity: Overlay opacity in light mode. Default is 0.4.
    ///   - darkOpacity: Overlay opacity in dark mode. Default is 0.6.
    /// - Returns: A view with an adaptive overlay applied.
    func adaptiveOverlay(lightOpacity: Double = 0.4, darkOpacity: Double = 0.6) -> some View {
        self.modifier(AdaptiveOverlay(lightOpacity: lightOpacity, darkOpacity: darkOpacity))
    }
}

// MARK: - Preview

#Preview("Adaptive Shadows") {
    VStack(spacing: 24) {
        Text("Adaptive Shadow Examples")
            .font(.headline)

        // Card Shadow
        RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius)
            .fill(Color.wiseCardBackground)
            .frame(width: 200, height: 100)
            .cardShadow()
            .overlay(Text("Card Shadow"))

        // Elevated Shadow
        RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius)
            .fill(Color.wiseCardBackground)
            .frame(width: 200, height: 100)
            .elevatedShadow()
            .overlay(Text("Elevated Shadow"))

        // Subtle Shadow
        RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius)
            .fill(Color.wiseCardBackground)
            .frame(width: 200, height: 100)
            .subtleShadow()
            .overlay(Text("Subtle Shadow"))

        // Custom Shadow
        RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius)
            .fill(Color.wiseCardBackground)
            .frame(width: 200, height: 100)
            .adaptiveShadow(radius: 12, x: 4, y: 4)
            .overlay(Text("Custom Shadow"))
    }
    .padding()
    .background(Color.wiseBackground)
}
