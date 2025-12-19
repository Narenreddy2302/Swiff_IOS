# Accessibility Implementation

## Purpose
Ensure the app is accessible to all users, including those with visual, motor, hearing, and cognitive disabilities.

## When to Use This Skill
- Creating new UI components
- Adding VoiceOver support
- Implementing Dynamic Type
- Testing accessibility
- Reviewing for WCAG compliance

---

## Accessibility Standards

| Standard | Requirement |
|----------|-------------|
| Touch targets | Minimum 44x44 points |
| Color contrast | 4.5:1 for normal text |
| VoiceOver | All interactive elements labeled |
| Dynamic Type | Support all text sizes |
| Reduce Motion | Respect user preference |

---

## VoiceOver Labels

### Basic Labels

```swift
struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack {
            Image(systemName: subscription.icon)
            Text(subscription.name)
            Spacer()
            Text(subscription.price.asCurrency)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subscription.name), \(subscription.price.accessibleCurrency) per \(subscription.billingCycle.displayName)")
        .accessibilityHint("Double tap to view details")
    }
}
```

### Custom Accessibility Labels

```swift
extension Double {
    var accessibleCurrency: String {
        let dollars = Int(self)
        let cents = Int((self - Double(dollars)) * 100)

        if cents == 0 {
            return "\(dollars) dollars"
        } else {
            return "\(dollars) dollars and \(cents) cents"
        }
    }
}

extension Date {
    var accessibleDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: self)
    }

    var accessibleRelativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
```

### Button Accessibility

```swift
Button(action: addSubscription) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add subscription")
.accessibilityHint("Opens form to add a new subscription")

Button(action: deleteSubscription) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete subscription")
.accessibilityHint("Removes this subscription permanently")
```

---

## Accessibility Traits

```swift
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }
}

struct ToggleButton: View {
    @Binding var isOn: Bool
    let label: String

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(label)
        }
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
    }
}
```

---

## Dynamic Type

### Supporting All Text Sizes

```swift
struct SubscriptionCard: View {
    let subscription: Subscription
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subscription.name)
                .font(.headline)

            Text(subscription.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(subscription.price.asCurrency)
                .font(.title2)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}
```

### Scaled Metrics

```swift
struct IconButton: View {
    @ScaledMetric var iconSize: CGFloat = 24
    @ScaledMetric var padding: CGFloat = 12

    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: iconSize))
            .padding(padding)
    }
}
```

### Adaptive Layouts

```swift
struct AdaptiveRow: View {
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        if sizeCategory.isAccessibilityCategory {
            // Stack vertically for larger text
            VStack(alignment: .leading, spacing: 8) {
                leadingContent
                trailingContent
            }
        } else {
            // Horizontal layout for normal text
            HStack {
                leadingContent
                Spacer()
                trailingContent
            }
        }
    }
}
```

---

## Reduce Motion

### Respecting User Preference

```swift
struct AnimatedCard: View {
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        CardContent()
            .opacity(isVisible ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 20))
            .animation(
                reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}
```

### Animation Presets

```swift
// Utilities/AnimationPresets.swift
struct AnimationPresets {
    @Environment(\.accessibilityReduceMotion) static var reduceMotion

    static var standard: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.3)
    }

    static var spring: Animation? {
        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)
    }

    static var slow: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.5)
    }
}

// Usage
.animation(AnimationPresets.standard, value: isExpanded)
```

---

## Color Contrast

### High Contrast Support

```swift
struct AccessibleText: View {
    let text: String
    @Environment(\.accessibilityHighContrast) var highContrast

    var body: some View {
        Text(text)
            .foregroundColor(highContrast ? .primary : .secondary)
    }
}
```

### Don't Rely on Color Alone

```swift
struct StatusIndicator: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            // Include text for colorblind users
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isActive ? "Status: Active" : "Status: Inactive")
    }
}
```

---

## Accessibility Announcements

```swift
// Utilities/AccessibilityAnnouncer.swift
struct AccessibilityAnnouncer {
    static func announce(_ message: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: message
        )
    }

    static func announceScreenChange(_ message: String) {
        UIAccessibility.post(
            notification: .screenChanged,
            argument: message
        )
    }

    static func announceLayoutChange(_ message: String) {
        UIAccessibility.post(
            notification: .layoutChanged,
            argument: message
        )
    }
}

// Usage
Button("Delete") {
    deleteItem()
    AccessibilityAnnouncer.announce("Item deleted")
}

Button("Save") {
    saveItem()
    AccessibilityAnnouncer.announce("Subscription saved successfully")
}
```

---

## Focus Management

```swift
struct SearchView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @AccessibilityFocusState private var accessibilityFocus: Bool

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .focused($isSearchFocused)
                .accessibilityFocused($accessibilityFocus)

            Button("Clear") {
                searchText = ""
                // Move focus back to search field
                isSearchFocused = true
                accessibilityFocus = true
            }
        }
    }
}
```

---

## Accessibility Settings

```swift
// Utilities/AccessibilitySettings.swift
struct AccessibilitySettings {
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    static var isGrayscaleEnabled: Bool {
        UIAccessibility.isGrayscaleEnabled
    }

    static var isDarkerSystemColorsEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    static var prefersCrossFadeTransitions: Bool {
        UIAccessibility.prefersCrossFadeTransitions
    }
}
```

---

## View Modifiers

```swift
// Utilities/AccessibilityViewModifiers.swift
extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    func accessibleHeader(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    func accessibleImage(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }

    func accessibleLink(label: String, url: String) -> some View {
        self
            .accessibilityLabel("\(label), link")
            .accessibilityHint("Opens \(url)")
            .accessibilityAddTraits(.isLink)
    }

    func accessibleContainer(label: String) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
    }
}

// Usage
Image(systemName: "star.fill")
    .accessibleImage(label: "Favorite")

Text("Settings")
    .accessibleHeader(label: "Settings section")

Button("Add") { }
    .accessibleButton(label: "Add subscription", hint: "Opens form")
```

---

## Minimum Touch Targets

```swift
struct AccessibleButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    var body: some View {
        Button(action: action, label: label)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

// For icons/small buttons
struct TapTarget: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

extension View {
    func minimumTapTarget() -> some View {
        modifier(TapTarget())
    }
}

// Usage
Image(systemName: "xmark")
    .minimumTapTarget()
```

---

## Testing Accessibility

### Manual Testing Checklist

1. **VoiceOver Testing**
   - Enable VoiceOver in Settings
   - Navigate through all screens
   - Verify all elements are announced
   - Check reading order is logical

2. **Dynamic Type Testing**
   - Test at all text sizes (Settings > Accessibility > Display & Text Size)
   - Verify layout doesn't break at largest sizes
   - Check text isn't truncated

3. **Reduce Motion Testing**
   - Enable Reduce Motion
   - Verify animations are disabled/reduced
   - Check transitions are simple

4. **Color Contrast Testing**
   - Use Color Contrast Analyzer
   - Verify 4.5:1 ratio for text
   - Test with Grayscale mode

### Accessibility Inspector

```swift
// Add to development builds
#if DEBUG
extension View {
    func accessibilityDebug() -> some View {
        self.overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        print("Accessibility frame: \(geometry.frame(in: .global))")
                    }
            }
        )
    }
}
#endif
```

---

## Common Mistakes to Avoid

1. **Using only color to convey information**
2. **Small touch targets (< 44pt)**
3. **Missing VoiceOver labels**
4. **Not testing with actual VoiceOver**
5. **Ignoring Reduce Motion preference**
6. **Hard-coded font sizes instead of Dynamic Type**

---

## Checklist

- [ ] All interactive elements have accessibility labels
- [ ] Touch targets are at least 44x44 points
- [ ] Dynamic Type supported (all text sizes)
- [ ] Reduce Motion respected
- [ ] Color contrast meets 4.5:1 ratio
- [ ] Information not conveyed by color alone
- [ ] VoiceOver announces in logical order
- [ ] Headers marked with `.isHeader` trait
- [ ] Buttons marked with `.isButton` trait
- [ ] Images have descriptive labels

---

## Industry Standards

- **WCAG 2.1** - Web Content Accessibility Guidelines
- **Apple Accessibility Guidelines**
- **Section 508** - US accessibility requirements
- **iOS VoiceOver** documentation
- **Dynamic Type** best practices
