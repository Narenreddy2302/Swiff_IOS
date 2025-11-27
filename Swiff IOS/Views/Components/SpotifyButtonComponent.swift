//
//  SpotifyButtonComponent.swift
//  Swiff IOS
//
//  Spotify-inspired button components following design system standards
//

import SwiftUI

// MARK: - Button Style Enums

enum ButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 13
        case .medium: return 14
        case .large: return 16
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 18
        case .large: return 20
        }
    }
}

enum ButtonVariant {
    case primary
    case secondary
    case tertiary
    case destructive

    var foregroundColor: Color {
        switch self {
        case .primary: return .wisePrimaryButtonText
        case .secondary: return .wisePrimaryButton
        case .tertiary: return .wisePrimaryText
        case .destructive: return .white
        }
    }

    func backgroundColor(isPressed: Bool) -> AnyView {
        switch self {
        case .primary:
            return AnyView(Color.wisePrimaryButton)
        case .secondary:
            return AnyView(Color.wiseSecondaryButton)
        case .tertiary:
            return AnyView(Color.wiseBorder.opacity(isPressed ? 0.8 : 0.5))
        case .destructive:
            return AnyView(Color.wiseDestructiveButton)
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return .wisePrimaryButton
        case .secondary: return .clear
        case .tertiary: return .clear
        case .destructive: return .wiseDestructiveButton
        }
    }
}

// MARK: - Primary Button Component

struct SpotifyButton: View {
    let title: String
    let icon: String?
    let variant: ButtonVariant
    let size: ButtonSize
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundColor(variant.foregroundColor)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(variant.backgroundColor(isPressed: isPressed))
            .cornerRadius(size.height / 2)
            .shadow(
                color: variant.shadowColor.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Icon Button Component

struct SpotifyIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let backgroundColor: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        size: CGFloat = 24,
        color: Color = .wiseForestGreen,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size + 20, height: size + 20)
                .background(
                    backgroundColor.map { color in
                        Circle()
                            .fill(color)
                    }
                )
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String = "plus",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.wiseForestGreen, .wiseBrightGreen]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.wiseBrightGreen.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Filter Pill Button

struct FilterPillButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(.spotifyBodyMedium)
            }
            .foregroundColor(isSelected ? .white : .wisePrimaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.5))
            .cornerRadius(20)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Segmented Control Button

struct SegmentedControlButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(.spotifyBodyMedium)
            }
            .foregroundColor(isSelected ? .white : .wiseBodyText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.wiseForestGreen : Color.clear)
            .cornerRadius(20)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Header Action Button (for next to search)

struct HeaderActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String = "plus.circle.fill",
        color: Color = .wiseForestGreen,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Custom Button Style

struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Primary Buttons") {
    VStack(spacing: 16) {
        SpotifyButton("Add Transaction", icon: "plus.circle.fill", variant: .primary, size: .large) {}
        SpotifyButton("Add Subscription", icon: "plus", variant: .primary, size: .medium) {}
        SpotifyButton("Add", icon: "plus", variant: .primary, size: .small) {}
    }
    .padding()
}

#Preview("Button Variants") {
    VStack(spacing: 16) {
        SpotifyButton("Primary Button", variant: .primary) {}
        SpotifyButton("Secondary Button", variant: .secondary) {}
        SpotifyButton("Tertiary Button", variant: .tertiary) {}
        SpotifyButton("Delete", icon: "trash", variant: .destructive) {}
    }
    .padding()
}

#Preview("Icon Buttons") {
    HStack(spacing: 20) {
        SpotifyIconButton(icon: "magnifyingglass", size: 20) {}
        SpotifyIconButton(icon: "plus.circle.fill", size: 24, color: .wiseForestGreen) {}
        SpotifyIconButton(
            icon: "bell.fill",
            size: 18,
            color: .white,
            backgroundColor: .wiseOrange
        ) {}
    }
    .padding()
}

#Preview("Floating Action Button") {
    ZStack {
        Color.wiseBackground.ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {}
                    .padding(.trailing, 24)
                    .padding(.bottom, 90)
            }
        }
    }
}

#Preview("Filter Pills") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            FilterPillButton("All", isSelected: true) {}
            FilterPillButton("Income", icon: "arrow.down.circle", isSelected: false) {}
            FilterPillButton("Expenses", icon: "arrow.up.circle", isSelected: false) {}
            FilterPillButton("Subscriptions", isSelected: false) {}
        }
        .padding(.horizontal)
    }
}

#Preview("Segmented Control") {
    HStack(spacing: 0) {
        SegmentedControlButton("Personal", icon: "person.fill", isSelected: true) {}
        SegmentedControlButton("Shared", icon: "person.2.fill", isSelected: false) {}
    }
    .padding(4)
    .background(Color.wiseBorder.opacity(0.5))
    .cornerRadius(25)
    .padding()
}

#Preview("Header Buttons") {
    HStack(spacing: 16) {
        HeaderActionButton(icon: "magnifyingglass") {}
        HeaderActionButton(icon: "plus.circle.fill") {}
        HeaderActionButton(icon: "ellipsis.circle", color: .wiseBlue) {}
    }
    .padding()
}
