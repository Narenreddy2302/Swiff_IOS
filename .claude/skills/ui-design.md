# UI/UX Design Patterns

## Purpose
Maintain consistent visual design and user experience across the app following the established design system and Apple Human Interface Guidelines.

## When to Use This Skill
- Creating new screens or components
- Styling UI elements
- Implementing state feedback
- Adding haptic feedback
- Ensuring design consistency

---

## Design System Overview

### Color Palette

```swift
// Wise-Inspired Color Palette
extension Color {
    // Primary Brand Colors
    static let wiseBrightGreen = Color(red: 159/255, green: 232/255, blue: 112/255) // #9FE870
    static let wiseForestGreen = Color(red: 22/255, green: 51/255, blue: 0/255)     // #163300
    static let wiseBlue = Color(red: 0/255, green: 185/255, blue: 255/255)          // #00B9FF

    // Background Colors
    static let wiseCardBackground = Color(.systemBackground).opacity(0.9)
    static let wiseSecondaryBackground = Color(.secondarySystemBackground)

    // Semantic Colors
    static let expenseRed = Color.red
    static let incomeGreen = Color.green
    static let warningOrange = Color.orange

    // Avatar Color Palette
    static let avatarColors: [Color] = [
        Color(red: 255/255, green: 107/255, blue: 107/255), // Coral
        Color(red: 78/255, green: 205/255, blue: 196/255),  // Teal
        Color(red: 255/255, green: 217/255, blue: 102/255), // Yellow
        Color(red: 147/255, green: 112/255, blue: 219/255), // Purple
        Color(red: 72/255, green: 201/255, blue: 176/255),  // Mint
        Color(red: 255/255, green: 159/255, blue: 67/255)   // Orange
    ]
}

// Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
```

### Typography (Spotify-Inspired)

```swift
extension Font {
    // Display Fonts
    static let spotifyDisplayLarge = Font.system(size: 32, weight: .bold)
    static let spotifyDisplayMedium = Font.system(size: 24, weight: .bold)
    static let spotifyDisplaySmall = Font.system(size: 20, weight: .bold)

    // Heading Fonts
    static let spotifyHeading = Font.system(size: 18, weight: .semibold)

    // Body Fonts
    static let spotifyBodyLarge = Font.system(size: 17, weight: .regular)
    static let spotifyBodyMedium = Font.system(size: 15, weight: .regular)
    static let spotifyBodySmall = Font.system(size: 13, weight: .regular)

    // Label Fonts
    static let spotifyLabel = Font.system(size: 12, weight: .medium)
    static let spotifyCaption = Font.system(size: 11, weight: .regular)

    // Number Fonts (Monospaced for alignment)
    static let spotifyNumberLarge = Font.system(size: 28, weight: .bold).monospacedDigit()
    static let spotifyNumberMedium = Font.system(size: 17, weight: .semibold).monospacedDigit()
    static let spotifyNumberSmall = Font.system(size: 13, weight: .medium).monospacedDigit()
}
```

---

## Core Components

### UnifiedListRow

```swift
struct UnifiedListRow<IconContent: View>: View {
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color
    @ViewBuilder let iconContent: () -> IconContent

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            iconContent()

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Value
            Text(value)
                .font(.spotifyNumberMedium)
                .foregroundColor(valueColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .subtleShadow()
    }
}
```

### UnifiedIconCircle

```swift
struct UnifiedIconCircle: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(icon: String, color: Color, size: CGFloat = 48) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(color)
            )
    }
}
```

### UnifiedCard

```swift
struct UnifiedCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
        )
        .subtleShadow()
    }
}
```

### AvatarView

```swift
struct AvatarView: View {
    let avatarType: AvatarType
    let size: CGFloat

    init(avatarType: AvatarType, size: CGFloat = 48) {
        self.avatarType = avatarType
        self.size = size
    }

    var body: some View {
        Group {
            switch avatarType {
            case .photo(let data):
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    initialsAvatar("?", colorIndex: 0)
                }

            case .emoji(let emoji):
                Text(emoji)
                    .font(.system(size: size * 0.5))
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color.gray.opacity(0.1)))

            case .initials(let initials, let colorIndex):
                initialsAvatar(initials, colorIndex: colorIndex)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func initialsAvatar(_ initials: String, colorIndex: Int) -> some View {
        let color = Color.avatarColors[colorIndex % Color.avatarColors.count]
        return Text(initials.prefix(2).uppercased())
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
    }
}
```

---

## State Views

### Loading State

```swift
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.spotifyBodyMedium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### Empty State

```swift
struct EnhancedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.spotifyDisplaySmall)

                Text(message)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### Error State

```swift
struct ErrorStateView: View {
    let error: Error
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.spotifyHeading)

                Text(error.localizedDescription)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retry = retryAction {
                Button("Try Again", action: retry)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

---

## View Modifiers

### Card Style

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
            )
            .subtleShadow()
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
```

### Subtle Shadow

```swift
struct SubtleShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func subtleShadow() -> some View {
        modifier(SubtleShadow())
    }
}
```

---

## Haptic Feedback

```swift
// Utilities/HapticManager.swift
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // Context-specific helpers
    static func buttonTap() {
        impact(.light)
    }

    static func success() {
        notification(.success)
    }

    static func error() {
        notification(.error)
    }

    static func warning() {
        notification(.warning)
    }

    static func toggle() {
        impact(.medium)
    }

    static func destructiveAction() {
        impact(.heavy)
    }
}

// SwiftUI Button Extension
struct HapticButtonStyle: ButtonStyle {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    init(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        self.style = style
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.impact(style)
                }
            }
    }
}
```

---

## Toast Notifications

```swift
// Utilities/ToastManager.swift
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: Toast?

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastType

        enum ToastType {
            case success, error, info

            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .error: return "xmark.circle.fill"
                case .info: return "info.circle.fill"
                }
            }

            var color: Color {
                switch self {
                case .success: return .green
                case .error: return .red
                case .info: return .blue
                }
            }
        }
    }

    func show(_ message: String, type: Toast.ToastType = .info) {
        currentToast = Toast(message: message, type: type)

        // Auto dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            dismiss()
        }
    }

    func dismiss() {
        currentToast = nil
    }
}

// Toast View
struct ToastView: View {
    let toast: ToastManager.Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundColor(toast.type.color)

            Text(toast.message)
                .font(.spotifyBodyMedium)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}
```

---

## Spacing & Layout

### Standard Spacing

| Name | Value | Use Case |
|------|-------|----------|
| xs | 4pt | Tight text spacing |
| sm | 8pt | Related elements |
| md | 12pt | Default spacing |
| lg | 16pt | Section padding |
| xl | 24pt | Major sections |
| xxl | 32pt | Screen padding |

### Corner Radius

| Element | Radius |
|---------|--------|
| Small buttons | 8pt |
| Cards | 12pt |
| Large cards | 16pt |
| Full-screen sheets | 20pt |

---

## Common Patterns

### Screen Layout

```swift
struct ExampleScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                SectionHeader(title: "Section Title")

                // Content
                ForEach(items) { item in
                    ItemRow(item: item)
                }
            }
            .padding()
        }
        .navigationTitle("Screen Title")
        .background(Color.wiseSecondaryBackground)
    }
}
```

### Section Header

```swift
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.spotifyHeading)
                .foregroundColor(.primary)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseBlue)
            }
        }
    }
}
```

---

## Checklist

- [ ] Colors from design system palette
- [ ] Typography uses spotifyFont extensions
- [ ] Consistent spacing (8pt grid)
- [ ] Cards use cardStyle() modifier
- [ ] Empty/loading/error states handled
- [ ] Haptic feedback on interactions
- [ ] Accessibility labels present
- [ ] Animations respect reduce motion

---

## Industry Standards

- **Apple Human Interface Guidelines**
- **iOS Design Resources**
- **SF Symbols** for icons
- **8-point grid system**
- **60fps animation target**
