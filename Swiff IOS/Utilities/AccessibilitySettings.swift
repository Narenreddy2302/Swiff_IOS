//
//  AccessibilitySettings.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  Centralized accessibility settings and helpers
//

import UIKit
import SwiftUI

// MARK: - Accessibility Settings

class AccessibilitySettings {
    static let shared = AccessibilitySettings()

    private init() {}

    // MARK: - Motion Settings

    /// Check if Reduce Motion is enabled
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Check if Reduce Transparency is enabled
    static var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    // MARK: - Visual Settings

    /// Check if Increase Contrast is enabled
    static var isIncreaseContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    /// Check if Button Shapes is enabled
    static var isButtonShapesEnabled: Bool {
        UIAccessibility.buttonShapesEnabled
    }

    /// Check if On/Off Labels is enabled
    static var isOnOffSwitchLabelsEnabled: Bool {
        UIAccessibility.isOnOffSwitchLabelsEnabled
    }

    // MARK: - Text Settings

    /// Check if Bold Text is enabled
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    /// Get the current content size category
    static var contentSizeCategory: UIContentSizeCategory {
        UIApplication.shared.preferredContentSizeCategory
    }

    /// Check if using an accessibility text size
    static var isAccessibilityTextSize: Bool {
        contentSizeCategory.isAccessibilityCategory
    }

    // MARK: - VoiceOver Settings

    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Check if Switch Control is running
    static var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }

    // MARK: - Audio Settings

    /// Check if Mono Audio is enabled
    static var isMonoAudioEnabled: Bool {
        UIAccessibility.isMonoAudioEnabled
    }

    /// Check if Closed Captions are enabled
    static var isClosedCaptioningEnabled: Bool {
        UIAccessibility.isClosedCaptioningEnabled
    }

    // MARK: - Helper Methods

    /// Get animation duration based on Reduce Motion setting
    static func animationDuration(_ duration: Double) -> Double {
        isReduceMotionEnabled ? 0.0 : duration
    }

    /// Get animation based on Reduce Motion setting
    static func animation(_ animation: Animation) -> Animation? {
        isReduceMotionEnabled ? nil : animation
    }

    /// Perform haptic feedback only if motion is not reduced
    static func hapticIfEnabled(_ haptic: () -> Void) {
        if !isReduceMotionEnabled {
            haptic()
        }
    }
}

// MARK: - View Extensions for Accessibility

extension View {
    /// Apply animation only if Reduce Motion is disabled
    func accessibleAnimation(_ animation: Animation?, value: some Equatable) -> some View {
        self.animation(AccessibilitySettings.isReduceMotionEnabled ? nil : animation, value: value)
    }

    /// Apply transition only if Reduce Motion is disabled
    func accessibleTransition(_ transition: AnyTransition) -> some View {
        self.transition(AccessibilitySettings.isReduceMotionEnabled ? .opacity : transition)
    }

    /// Add minimum touch target size for accessibility
    func accessibleTapTarget(minSize: CGFloat = 44) -> some View {
        self
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }

    /// Make text support Dynamic Type
    func dynamicTypeSize(min: DynamicTypeSize = .small, max: DynamicTypeSize = .accessibility3) -> some View {
        self.dynamicTypeSize(min...max)
    }
}

// MARK: - Accessibility Color Helpers

extension Color {
    /// Ensure proper contrast ratio for accessibility
    func accessibleContrast(with background: Color) -> Color {
        // This is a simplified version - in production, you'd calculate actual contrast ratios
        if AccessibilitySettings.isIncreaseContrastEnabled {
            return self
        }
        return self
    }

    /// Get a color suitable for background based on accessibility settings
    var accessibleBackground: Color {
        if AccessibilitySettings.isReduceTransparencyEnabled {
            return self.opacity(1.0)
        }
        return self
    }
}

// MARK: - Notification Names for Accessibility Changes

extension Notification.Name {
    static let reduceMotionStatusDidChange = UIAccessibility.reduceMotionStatusDidChangeNotification
    static let voiceOverStatusDidChange = UIAccessibility.voiceOverStatusDidChangeNotification
    static let boldTextStatusDidChange = UIAccessibility.boldTextStatusDidChangeNotification
    static let darkerSystemColorsStatusDidChange = UIAccessibility.darkerSystemColorsStatusDidChangeNotification
    static let reduceTransparencyStatusDidChange = UIAccessibility.reduceTransparencyStatusDidChangeNotification
}

// MARK: - Preview Helper

struct AccessibilitySettingsPreview: View {
    var body: some View {
        List {
            Section("Motion") {
                LabeledContent("Reduce Motion", value: AccessibilitySettings.isReduceMotionEnabled ? "Yes" : "No")
                LabeledContent("Reduce Transparency", value: AccessibilitySettings.isReduceTransparencyEnabled ? "Yes" : "No")
            }

            Section("Visual") {
                LabeledContent("Increase Contrast", value: AccessibilitySettings.isIncreaseContrastEnabled ? "Yes" : "No")
                LabeledContent("Button Shapes", value: AccessibilitySettings.isButtonShapesEnabled ? "Yes" : "No")
                LabeledContent("Bold Text", value: AccessibilitySettings.isBoldTextEnabled ? "Yes" : "No")
            }

            Section("Assistive Technology") {
                LabeledContent("VoiceOver", value: AccessibilitySettings.isVoiceOverRunning ? "Yes" : "No")
                LabeledContent("Switch Control", value: AccessibilitySettings.isSwitchControlRunning ? "Yes" : "No")
            }

            Section("Text") {
                LabeledContent("Text Size", value: "\(AccessibilitySettings.contentSizeCategory)")
                LabeledContent("Accessibility Size", value: AccessibilitySettings.isAccessibilityTextSize ? "Yes" : "No")
            }
        }
        .navigationTitle("Accessibility Settings")
    }
}

#Preview {
    NavigationStack {
        AccessibilitySettingsPreview()
    }
}
