import SwiftUI

// MARK: - Button Style Enums

enum SwiffButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return Theme.Metrics.buttonHeightSmall  // 36
        case .medium: return Theme.Metrics.buttonHeightMedium  // 44
        case .large: return Theme.Metrics.buttonHeightLarge  // 52
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Theme.Metrics.buttonHorizontalPaddingSmall  // 24
        case .medium: return Theme.Metrics.buttonHorizontalPaddingLarge  // 28
        case .large: return Theme.Metrics.buttonHorizontalPaddingLarge  // 28
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return Theme.Metrics.buttonPaddingSmall  // 12
        case .medium: return Theme.Metrics.buttonPaddingMedium  // 14
        case .large: return Theme.Metrics.buttonPaddingLarge  // 14
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
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

    func foregroundColor(colorScheme: ColorScheme) -> Color {
        switch self {
        case .primary:
            // Black text on cream (dark mode), white text on teal (light mode)
            return colorScheme == .dark ? Theme.Colors.pureBlack : Color.white
        case .secondary:
            // Cream text (dark mode), black text (light mode) - outlined button
            return colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.pureBlack
        case .tertiary:
            return Theme.Colors.textPrimary
        case .destructive:
            return Color.white
        }
    }

    func backgroundColor(colorScheme: ColorScheme, isPressed: Bool) -> Color {
        switch self {
        case .primary:
            // Cream (dark mode), Teal (light mode)
            let baseColor = colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.teal
            return isPressed ? baseColor.opacity(0.9) : baseColor
        case .secondary:
            // Transparent with border
            return isPressed ? Theme.Colors.hoverOverlay : Color.clear
        case .tertiary:
            return isPressed ? Theme.Colors.activeOverlay : Theme.Colors.hoverOverlay
        case .destructive:
            let baseColor = Theme.Colors.errorRed
            return isPressed ? baseColor.opacity(0.9) : baseColor
        }
    }

    func borderColor(colorScheme: ColorScheme) -> Color? {
        switch self {
        case .secondary:
            // Cream border (dark mode), black border (light mode)
            return colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.pureBlack
        default:
            return nil
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return Theme.Colors.teal
        case .secondary: return .clear
        case .tertiary: return .clear
        case .destructive: return Theme.Colors.errorRed
        }
    }
}

// MARK: - Primary Button Component

struct SwiffButton: View {
    @Environment(\.colorScheme) var colorScheme

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
                        .font(.system(size: size.iconSize, weight: .medium))
                }
                Text(title)
                    .font(.system(size: size.fontSize, weight: .medium))
            }
            .foregroundColor(variant.foregroundColor(colorScheme: colorScheme))
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(variant.backgroundColor(colorScheme: colorScheme, isPressed: isPressed))
            .cornerRadius(Theme.Metrics.cornerRadiusFull)  // Pill shape - 100px
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusFull)
                    .stroke(variant.borderColor(colorScheme: colorScheme) ?? Color.clear, lineWidth: variant == .secondary ? Theme.Border.widthMedium : 0)
            )
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

// MARK: - Icon Button Component (Circular)

struct SwiffIconButton: View {
    @Environment(\.colorScheme) var colorScheme

    let icon: String
    let size: CGFloat
    let color: Color?
    let backgroundColor: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        size: CGFloat = 24,
        color: Color? = nil,
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
                .foregroundColor(color ?? (colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.pureBlack))
                .frame(width: Theme.Metrics.iconButtonMedium, height: Theme.Metrics.iconButtonMedium)
                .background(
                    backgroundColor.map { bgColor in
                        Circle()
                            .fill(bgColor)
                    }
                )
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Send Button (Circular with Arrow) - Per Design System

struct SwiffSendButton: View {
    @Environment(\.colorScheme) var colorScheme

    let action: () -> Void
    let isEnabled: Bool

    init(isEnabled: Bool = true, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isEnabled ? Color.white : Theme.Colors.textTertiary)
                .frame(width: Theme.Metrics.sendButtonSize, height: Theme.Metrics.sendButtonSize)
                .background(
                    Circle()
                        .fill(isEnabled ? Theme.Colors.teal : Theme.Colors.buttonDisabled)
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Floating Action Button

struct SwiffFloatingActionButton: View {
    @Environment(\.colorScheme) var colorScheme

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
                .foregroundColor(colorScheme == .dark ? Theme.Colors.pureBlack : Color.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.teal)
                )
                .shadow(color: Theme.Colors.teal.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Filter Pill Button

struct SwiffFilterPillButton: View {
    @Environment(\.colorScheme) var colorScheme

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
                    .font(Theme.Fonts.bodySmall)
            }
            .foregroundColor(
                isSelected
                    ? (colorScheme == .dark ? Theme.Colors.pureBlack : Color.white)
                    : Theme.Colors.textPrimary
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? (colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.teal)
                    : Theme.Colors.hoverOverlay
            )
            .cornerRadius(20)
        }
        .animation(.easeInOut(duration: Theme.Animation.normal), value: isSelected)
    }
}

// MARK: - Segmented Control Button

struct SwiffSegmentedControlButton: View {
    @Environment(\.colorScheme) var colorScheme

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
                    .font(Theme.Fonts.bodySmall)
            }
            .foregroundColor(
                isSelected
                    ? (colorScheme == .dark ? Theme.Colors.pureBlack : Color.white)
                    : Theme.Colors.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? (colorScheme == .dark ? Theme.Colors.creamWhite : Theme.Colors.teal)
                    : Color.clear
            )
            .cornerRadius(20)
        }
        .animation(.easeInOut(duration: Theme.Animation.normal), value: isSelected)
    }
}

// MARK: - Header Action Button (Standardized)

struct HeaderActionButton: View {
    @Environment(\.colorScheme) var colorScheme

    let icon: String
    let color: Color?
    let action: () -> Void

    init(
        icon: String = "plus.circle.fill",
        color: Color? = nil,
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
                .foregroundColor(color ?? Theme.Colors.teal)
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

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: Theme.Animation.fast), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        SwiffButton("Primary Action") {}
        SwiffButton("Secondary", variant: .secondary) {}
        SwiffButton("Tertiary", variant: .tertiary) {}
        SwiffButton("Destructive", variant: .destructive) {}
        SwiffSendButton {}
        HeaderActionButton {}
    }
    .padding()
    .background(Color.wiseBackground)
}
