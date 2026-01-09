//
//  ConversationButtonStyles.swift
//  Swiff IOS
//
//  Button style modifiers for conversation views
//  Following Apple HIG with 44pt minimum tap targets
//

import SwiftUI

// MARK: - Navigation Button Style

/// Style for navigation buttons (back, info, etc.)
/// Ensures 44x44pt minimum tap target per Apple HIG
struct NavigationButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.navigationIcon)
            .foregroundColor(.wisePrimaryText)
            .frame(width: Theme.Metrics.minTapTarget, height: Theme.Metrics.minTapTarget)
            .contentShape(Rectangle())
    }
}

// MARK: - Text Action Button Style

/// Style for text-based action buttons (Edit, Save, etc.)
struct TextActionButtonStyle: ViewModifier {
    var color: Color = .wiseForestGreen

    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.headerTitle)
            .foregroundColor(color)
    }
}

// MARK: - Icon Action Button Style

/// Style for icon-based action buttons in headers
struct IconActionButtonStyle: ViewModifier {
    var size: CGFloat = Theme.Metrics.buttonIconSize
    var color: Color = .wisePrimaryText

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
            .foregroundColor(color)
            .frame(width: Theme.Metrics.minTapTarget, height: Theme.Metrics.minTapTarget)
            .contentShape(Rectangle())
    }
}

// MARK: - View Extensions

extension View {
    /// Apply navigation button styling (44x44pt tap target)
    func navigationButtonStyle() -> some View {
        modifier(NavigationButtonStyle())
    }

    /// Apply text action button styling
    func textActionButtonStyle(color: Color = .wiseForestGreen) -> some View {
        modifier(TextActionButtonStyle(color: color))
    }

    /// Apply icon action button styling
    func iconActionButtonStyle(size: CGFloat = Theme.Metrics.buttonIconSize, color: Color = .wisePrimaryText) -> some View {
        modifier(IconActionButtonStyle(size: size, color: color))
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 24) {
        // Navigation button
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .navigationButtonStyle()
        }
        .background(Color(UIColor.systemGray).opacity(0.1))

        // Text action button
        Button(action: {}) {
            Text("Edit")
                .textActionButtonStyle()
        }

        // Icon action button
        Button(action: {}) {
            Image(systemName: "info.circle")
                .iconActionButtonStyle(color: .wiseForestGreen)
        }
        .background(Color(UIColor.systemGray).opacity(0.1))
    }
    .padding()
}
