//
//  Colors.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Semantic Colors
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
            self.init(
                uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) }
            )
        #else
            self = light
        #endif
    }
}

extension Theme {

    public struct Colors {
        // MARK: - Green Palette (5-tier system)
        public static let green1 = Color(red: 238 / 255, green: 242 / 255, blue: 227 / 255)  // #EEF2E3 - Light backgrounds, disabled states
        public static let green2 = Color(red: 200 / 255, green: 241 / 255, blue: 105 / 255)  // #C8F169 - Hover/focus states, highlights
        public static let green3 = Color(red: 120 / 255, green: 197 / 255, blue: 28 / 255)  // #78C51C - Success indicators, active states
        public static let green4 = Color(red: 42 / 255, green: 111 / 255, blue: 43 / 255)  // #2A6F2B - Secondary brand, positive amounts
        public static let green5 = Color(red: 4 / 255, green: 63 / 255, blue: 46 / 255)  // #043F2E - Primary brand, buttons, headers

        // MARK: - Brand Colors (Adaptive for Dark Mode)
        /// Primary brand color - dark green in light mode, bright lime in dark mode
        public static let brandPrimary = Color(light: green5, dark: green3)

        /// Secondary brand color - medium green in light mode, lime highlight in dark mode
        public static let brandSecondary = Color(light: green4, dark: green2)

        /// Accent color - orange for both modes, slightly brighter in dark mode
        public static let brandAccent = Color(
            light: Color(red: 1.0, green: 0.596, blue: 0.0),
            dark: Color(red: 1.0, green: 0.65, blue: 0.15)
        )

        /// Text color on primary buttons - white on dark green, dark on bright lime
        public static let textOnPrimary = Color(
            light: Color.white,
            dark: Color(red: 0.05, green: 0.15, blue: 0.1)
        )

        /// Border color - adapts for visibility in both modes
        public static let border = Color(
            light: Color.black.opacity(0.1),
            dark: Color.white.opacity(0.15)
        )

        // MARK: - Semantic Status Colors
        public static let success = green3  // #78C51C - Bright lime for success states
        public static let warning = Color(red: 1.0, green: 0.624, blue: 0.039)  // Orange warning
        public static let systemError = Color(red: 1.0, green: 0.271, blue: 0.227)  // Red error

        public static let info = Color(red: 0.039, green: 0.518, blue: 1.0)  // Blue info

        // Aliases for compatibility
        public static let statusError = systemError
        public static let statusWarning = warning
        public static let statusSuccess = success

        // MARK: - Backgrounds (Adaptive)
        public static let background = Color(
            light: Color.white,
            dark: Color.black
        )

        public static let cardBackground = Color(
            light: Color.white,
            dark: Color(red: 0.15, green: 0.15, blue: 0.15)
        )

        public static let secondaryBackground = Color(
            light: Color(red: 0.98, green: 0.98, blue: 0.98),
            dark: Color(red: 0.11, green: 0.11, blue: 0.118)
        )

        // MARK: - Text (Adaptive)
        public static let textPrimary = Color(
            light: Color(red: 0.102, green: 0.102, blue: 0.102),
            dark: Color.white
        )

        public static let textSecondary = Color(
            light: Color(red: 0.235, green: 0.235, blue: 0.235),
            dark: Color(red: 0.7, green: 0.7, blue: 0.7)
        )

        public static let textTertiary = Color(
            light: Color(red: 0.557, green: 0.557, blue: 0.576),
            dark: Color(red: 0.486, green: 0.486, blue: 0.502)
        )

        // MARK: - Finance Colors (Adaptive)
        /// Positive amount color - bright green that works on both light and dark
        public static let amountPositive = Color(
            light: green4,
            dark: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
        )

        /// Negative amount color - red that adapts for visibility
        public static let amountNegative = Color(
            light: Color(red: 0.851, green: 0.176, blue: 0.125),
            dark: Color(red: 1.0, green: 0.35, blue: 0.35)
        )

        // MARK: - Component Colors (Adaptive)
        /// Primary button background - matches brandPrimary for consistency
        public static let buttonPrimary = Color(light: green5, dark: green3)

        /// Primary button text - dark on bright lime, white on dark green
        public static let buttonPrimaryText = Color(
            light: Color.white,
            dark: Color(red: 0.05, green: 0.15, blue: 0.1)
        )

        public static let buttonSecondary = Color(
            light: Color(red: 0.949, green: 0.949, blue: 0.969),
            dark: Color(red: 0.227, green: 0.227, blue: 0.235)
        )

        public static let buttonSecondaryText = Color(
            light: Color(red: 0.102, green: 0.102, blue: 0.102),
            dark: Color.white
        )

        public static let buttonDisabled = Color(
            light: Color(red: 0.776, green: 0.776, blue: 0.784),
            dark: Color(red: 0.282, green: 0.282, blue: 0.29)
        )

        // MARK: - Feed Reference Colors (Adaptive)
        /// Primary text color for feed - white in dark mode, dark gray in light mode
        public static let feedPrimaryText = Color(
            light: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255),
            dark: Color.white
        )

        /// Secondary text color for feed - adapts for readability
        public static let feedSecondaryText = Color(
            light: Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255),
            dark: Color.white.opacity(0.65)
        )

        /// Tertiary text color for feed - lighter shade for category
        public static let feedTertiaryText = Color(
            light: Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
            dark: Color.white.opacity(0.5)
        )

        /// Positive amount color - bright green in both modes
        public static let feedPositiveAmount = Color(
            light: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
            dark: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
        )

        /// Divider line color - subtle in both modes
        public static let feedDivider = Color(
            light: Color(red: 229 / 255, green: 229 / 255, blue: 234 / 255),
            dark: Color.white.opacity(0.12)
        )

        /// Active filter tab color - lime green, slightly brighter in dark mode
        public static let feedActiveTab = Color(
            light: Color(red: 212 / 255, green: 225 / 255, blue: 87 / 255),
            dark: Color(red: 220 / 255, green: 235 / 255, blue: 100 / 255)
        )

        // MARK: - Sheet Colors

        /// Card background for detail sheets - adaptive
        public static let sheetCardBackground = Color(
            light: Color(red: 0.973, green: 0.980, blue: 0.988),
            dark: Color(red: 0.11, green: 0.11, blue: 0.118)
        )

        /// Border/divider color for sheets - adaptive
        public static let sheetBorder = Color(
            light: Color(red: 0.886, green: 0.906, blue: 0.925),
            dark: Color.white.opacity(0.25)
        )

        /// Pill/button background - adaptive
        public static let sheetPillBackground = Color(
            light: Color(red: 0.945, green: 0.957, blue: 0.965),
            dark: Color.white.opacity(0.2)
        )

        /// Primary green for buttons - adaptive
        public static let sheetGreenPrimary = Color(
            light: Color(red: 0.020, green: 0.588, blue: 0.412),
            dark: Color(red: 0.2, green: 0.8, blue: 0.6)
        )

        // MARK: - Sheet Badge Colors

        /// Contact badge background (blue) - adaptive
        public static let sheetContactBadgeBg = Color(
            light: Color(red: 0.859, green: 0.914, blue: 1.0),
            dark: Color(red: 0.1, green: 0.2, blue: 0.4)
        )
        /// Contact badge text (blue) - adaptive
        public static let sheetContactBadgeText = Color(
            light: Color(red: 0.114, green: 0.306, blue: 0.851),
            dark: Color(red: 0.6, green: 0.8, blue: 1.0)
        )

        /// Group badge background (purple) - adaptive
        public static let sheetGroupBadgeBg = Color(
            light: Color(red: 0.953, green: 0.910, blue: 1.0),
            dark: Color(red: 0.3, green: 0.1, blue: 0.4)
        )
        /// Group badge text (purple) - adaptive
        public static let sheetGroupBadgeText = Color(
            light: Color(red: 0.576, green: 0.200, blue: 0.918),
            dark: Color(red: 0.8, green: 0.6, blue: 1.0)
        )

        /// Subscription badge background (amber) - adaptive
        public static let sheetSubscriptionBadgeBg = Color(
            light: Color(red: 0.996, green: 0.953, blue: 0.780),
            dark: Color(red: 0.4, green: 0.3, blue: 0.1)
        )
        /// Subscription badge text (amber) - adaptive
        public static let sheetSubscriptionBadgeText = Color(
            light: Color(red: 0.702, green: 0.263, blue: 0.035),
            dark: Color(red: 1.0, green: 0.8, blue: 0.4)
        )
    }
}
