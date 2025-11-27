//
//  HapticViewModifiers.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  View modifiers for adding haptic feedback to interactions
//

import SwiftUI

// MARK: - Haptic Tap Gesture Modifier

struct HapticTapGesture: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.impact(style)
                }
                action()
            }
    }
}

extension View {
    func hapticTap(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(HapticTapGesture(style: style, action: action))
    }
}

// MARK: - Swipe Action Haptic Modifier

struct SwipeActionHaptic: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Prepare haptic engine for swipe actions
                UIImpactFeedbackGenerator(style: .soft).prepare()
            }
    }
}

extension View {
    func swipeActionHaptic() -> some View {
        self.modifier(SwipeActionHaptic())
    }
}

// MARK: - Success Haptic Modifier

struct SuccessHaptic: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, isSuccess in
                if isSuccess && !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.success()
                }
            }
    }
}

extension View {
    func successHaptic(trigger: Bool) -> some View {
        self.modifier(SuccessHaptic(trigger: trigger))
    }
}

// MARK: - Error Haptic Modifier

struct ErrorHaptic: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, hasError in
                if hasError && !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.error()
                }
            }
    }
}

extension View {
    func errorHaptic(trigger: Bool) -> some View {
        self.modifier(ErrorHaptic(trigger: trigger))
    }
}

// MARK: - Selection Change Haptic

struct SelectionChangeHaptic<T: Equatable>: ViewModifier {
    let value: T

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, _ in
                if !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.selection()
                }
            }
    }
}

extension View {
    func selectionHaptic<T: Equatable>(value: T) -> some View {
        self.modifier(SelectionChangeHaptic(value: value))
    }
}

// MARK: - Long Press Haptic

struct LongPressHaptic: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onLongPressGesture {
                if !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.medium()
                }
                action()
            }
    }
}

extension View {
    func hapticLongPress(action: @escaping () -> Void) -> some View {
        self.modifier(LongPressHaptic(action: action))
    }
}

// MARK: - Toggle Haptic

struct ToggleHaptic: ViewModifier {
    @Binding var isOn: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: isOn) { _, _ in
                if !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.selection()
                }
            }
    }
}

extension View {
    func toggleHaptic(isOn: Binding<Bool>) -> some View {
        self.modifier(ToggleHaptic(isOn: isOn))
    }
}

// MARK: - Deletion Haptic

struct DeletionHaptic: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, didDelete in
                if didDelete && !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.heavy()
                }
            }
    }
}

extension View {
    func deletionHaptic(trigger: Bool) -> some View {
        self.modifier(DeletionHaptic(trigger: trigger))
    }
}

// MARK: - Pull to Refresh Haptic

struct PullToRefreshHaptic: ViewModifier {
    func body(content: Content) -> some View {
        content
            .refreshable {
                if !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.medium()
                }
            }
    }
}

// MARK: - Contextual Haptic Button Style

struct ContextualHapticButton: ButtonStyle {
    let context: HapticContext

    enum HapticContext {
        case primary
        case secondary
        case destructive
        case success

        var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .primary: return .medium
            case .secondary: return .light
            case .destructive: return .heavy
            case .success: return .medium
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(
                AccessibilitySettings.isReduceMotionEnabled ? .none : .quickEase,
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && !AccessibilitySettings.isReduceMotionEnabled {
                    HapticManager.shared.impact(context.hapticStyle)
                }
            }
    }
}

extension ButtonStyle where Self == ContextualHapticButton {
    static var primaryHaptic: ContextualHapticButton {
        ContextualHapticButton(context: .primary)
    }

    static var secondaryHaptic: ContextualHapticButton {
        ContextualHapticButton(context: .secondary)
    }

    static var destructiveHaptic: ContextualHapticButton {
        ContextualHapticButton(context: .destructive)
    }

    static var successHaptic: ContextualHapticButton {
        ContextualHapticButton(context: .success)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Haptic Feedback Examples")
            .font(.headline)

        Button("Primary Action") {}
            .buttonStyle(.primaryHaptic)
            .padding()
            .background(Color.wiseForestGreen)
            .foregroundColor(.white)
            .cornerRadius(12)

        Button("Secondary Action") {}
            .buttonStyle(.secondaryHaptic)
            .padding()
            .background(Color.wiseBorder.opacity(0.3))
            .cornerRadius(12)

        Button("Destructive Action") {}
            .buttonStyle(.destructiveHaptic)
            .padding()
            .background(Color.wiseError)
            .foregroundColor(.white)
            .cornerRadius(12)

        Button("Success Action") {}
            .buttonStyle(.successHaptic)
            .padding()
            .background(Color.wiseSuccess)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
    .padding()
}
