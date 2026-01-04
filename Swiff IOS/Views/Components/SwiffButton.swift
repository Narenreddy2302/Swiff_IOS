import SwiftUI

// MARK: - Button Style Enums

enum SwiffButtonSize {
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

enum SwiffButtonVariant {
    case primary
    case secondary
    case tertiary
    case destructive

    var foregroundColor: Color {
        switch self {
        case .primary: return Theme.Colors.textOnPrimary
        case .secondary: return Theme.Colors.brandPrimary
        case .tertiary: return Theme.Colors.textPrimary
        case .destructive: return Theme.Colors.textOnPrimary
        }
    }

    func backgroundColor(isPressed: Bool) -> AnyView {
        switch self {
        case .primary:
            return AnyView(Theme.Colors.brandPrimary)
        case .secondary:
            return AnyView(Theme.Colors.brandSecondary)
        case .tertiary:
            return AnyView(Theme.Colors.border.opacity(isPressed ? 0.8 : 0.5))
        case .destructive:
            return AnyView(Theme.Colors.statusError)
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return Theme.Colors.brandPrimary
        case .secondary: return .clear
        case .tertiary: return .clear
        case .destructive: return Theme.Colors.statusError
        }
    }
}

// MARK: - Primary Button Component

struct SwiffButton: View {
    let title: String
    let icon: String?
    let variant: SwiffButtonVariant
    let size: SwiffButtonSize
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        variant: SwiffButtonVariant = .primary,
        size: SwiffButtonSize = .medium,
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

struct SwiffIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let backgroundColor: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        size: CGFloat = 24,
        color: Color = Theme.Colors.brandPrimary,
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

struct SwiffFloatingActionButton: View {
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
                        gradient: Gradient(colors: [
                            Theme.Colors.brandPrimary, Theme.Colors.brandSecondary,
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Theme.Colors.brandPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Filter Pill Button

struct SwiffFilterPillButton: View {
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
                    .font(Theme.Fonts.bodyMedium)
            }
            .foregroundColor(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.Colors.brandPrimary : Theme.Colors.border.opacity(0.5))
            .cornerRadius(20)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Segmented Control Button

struct SwiffSegmentedControlButton: View {
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
                    .font(Theme.Fonts.bodyMedium)
            }
            .foregroundColor(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.Colors.brandPrimary : Color.clear)
            .cornerRadius(20)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Header Action Button (Standardized)

struct HeaderActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    init(
        icon: String = "plus.circle.fill",
        color: Color = Theme.Colors.brandPrimary,
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

#Preview {
    VStack(spacing: 20) {
        SwiffButton("Primary Action") {}
        SwiffButton("Secondary", variant: .secondary) {}
        SwiffButton("Destructive", variant: .destructive) {}
        HeaderActionButton {}
    }
    .padding()
}
