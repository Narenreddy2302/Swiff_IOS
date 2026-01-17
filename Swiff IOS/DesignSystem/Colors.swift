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
            dark: Color(red: 1.0, green: 0.65, blue: 0.0)
        )

        /// Text color on primary buttons - white on dark green, dark on bright lime
        public static let textOnPrimary = Color(
            light: Color.white,
            dark: green5
        )

        /// Border color - adapts for visibility in both modes
        public static let border = Color(
            light: Color.black.opacity(0.1),
            dark: Color.white.opacity(0.15)
        )

        // MARK: - Semantic Status Colors
        public static let success = Color(light: green3, dark: green3)
        public static let warning = Color(light: Color(red: 1.0, green: 0.624, blue: 0.039), dark: Color(red: 1.0, green: 0.700, blue: 0.100))
        public static let systemError = Color(light: Color(red: 1.0, green: 0.271, blue: 0.227), dark: Color(red: 1.0, green: 0.400, blue: 0.400))

        public static let info = Color(light: Color(red: 0.039, green: 0.518, blue: 1.0), dark: Color(red: 0.400, green: 0.700, blue: 1.0))

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
            dark: Color(red: 28/255, green: 28/255, blue: 30/255) // #1C1C1E
        )

        public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)

        // MARK: - Text (Adaptive)
        public static let textPrimary = Color(
            light: Color(red: 0.102, green: 0.102, blue: 0.102),
            dark: Color.white
        )

        public static let textSecondary = Color(
            light: Color(red: 0.235, green: 0.235, blue: 0.235),
            dark: Color(red: 0.92, green: 0.92, blue: 0.96) // System Gray
        )

        public static let textTertiary = Color(
            light: Color(red: 0.557, green: 0.557, blue: 0.576),
            dark: Color(red: 0.557, green: 0.557, blue: 0.576) // Keep gray
        )

        // MARK: - Finance Colors (Adaptive)
        /// Positive amount color - bright green that works on both light and dark
        public static let amountPositive = Color(
            light: green4,
            dark: green3
        )

        /// Negative amount color - red that adapts for visibility
        public static let amountNegative = Color(
            light: Color(red: 0.851, green: 0.176, blue: 0.125),
            dark: Color(red: 1.0, green: 0.271, blue: 0.227)
        )

        // MARK: - Component Colors (Adaptive)
        /// Primary button background - matches brandPrimary for consistency
        public static let buttonPrimary = Color(light: green5, dark: green3)

        /// Primary button text - dark on bright lime, white on dark green
        public static let buttonPrimaryText = Color(
            light: Color.white,
            dark: green5
        )

        public static let buttonSecondary = Color(
            light: Color(red: 0.949, green: 0.949, blue: 0.969),
            dark: Color(red: 44/255, green: 44/255, blue: 46/255) // #2C2C2E
        )

        public static let buttonSecondaryText = Color(
            light: Color(red: 0.102, green: 0.102, blue: 0.102),
            dark: Color.white
        )

        public static let buttonDisabled = Color(
            light: Color(red: 0.776, green: 0.776, blue: 0.784),
            dark: Color(red: 58/255, green: 58/255, blue: 60/255) // #3A3A3C
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
            dark: Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
        )

        /// Tertiary text color for feed - lighter shade for category
        public static let feedTertiaryText = Color(
            light: Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
            dark: Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
        )

        /// Positive amount color - bright green in both modes
        public static let feedPositiveAmount = Color(
            light: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
            dark: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
        )

        /// Divider line color - subtle in both modes
        public static let feedDivider = Color(
            light: Color(red: 229 / 255, green: 229 / 255, blue: 234 / 255),
            dark: Color(red: 58/255, green: 58/255, blue: 60/255) // #3A3A3C
        )

        /// Active filter tab color - lime green, slightly brighter in dark mode
        public static let feedActiveTab = Color(
            light: Color(red: 212 / 255, green: 225 / 255, blue: 87 / 255),
            dark: green2
        )

        // MARK: - Sheet Colors

        /// Card background for detail sheets - adaptive
        public static let sheetCardBackground = Color(
            light: Color(red: 0.973, green: 0.980, blue: 0.988),
            dark: Color(red: 28/255, green: 28/255, blue: 30/255) // #1C1C1E
        )

        /// Border/divider color for sheets - adaptive
        public static let sheetBorder = Color(
            light: Color(red: 0.886, green: 0.906, blue: 0.925),
            dark: Color(red: 56/255, green: 56/255, blue: 58/255) // #38383A
        )

        /// Pill/button background - adaptive
        public static let sheetPillBackground = Color(
            light: Color(red: 0.945, green: 0.957, blue: 0.965),
            dark: Color(red: 44/255, green: 44/255, blue: 46/255) // #2C2C2E
        )

        /// Primary green for buttons - adaptive
        public static let sheetGreenPrimary = Color(
            light: Color(red: 0.020, green: 0.588, blue: 0.412),
            dark: green3
        )

        // MARK: - Sheet Badge Colors

        /// Contact badge background (blue) - adaptive
        public static let sheetContactBadgeBg = Color(
            light: Color(red: 0.859, green: 0.914, blue: 1.0),
            dark: Color(red: 0.1, green: 0.2, blue: 0.4) // Dark Blue
        )
        /// Contact badge text (blue) - adaptive
        public static let sheetContactBadgeText = Color(
            light: Color(red: 0.114, green: 0.306, blue: 0.851),
            dark: Color(red: 0.4, green: 0.7, blue: 1.0) // Light Blue
        )

        /// Group badge background (purple) - adaptive
        public static let sheetGroupBadgeBg = Color(
            light: Color(red: 0.953, green: 0.910, blue: 1.0),
            dark: Color(red: 0.3, green: 0.1, blue: 0.4) // Dark Purple
        )
        /// Group badge text (purple) - adaptive
        public static let sheetGroupBadgeText = Color(
            light: Color(red: 0.576, green: 0.200, blue: 0.918),
            dark: Color(red: 0.8, green: 0.5, blue: 1.0) // Light Purple
        )

        /// Subscription badge background (amber) - adaptive
        public static let sheetSubscriptionBadgeBg = Color(
            light: Color(red: 0.996, green: 0.953, blue: 0.780),
            dark: Color(red: 0.4, green: 0.3, blue: 0.1) // Dark Amber
        )
        /// Subscription badge text (amber) - adaptive
        public static let sheetSubscriptionBadgeText = Color(
            light: Color(red: 0.702, green: 0.263, blue: 0.035),
            dark: Color(red: 1.0, green: 0.7, blue: 0.4) // Light Amber
        )
    }
}