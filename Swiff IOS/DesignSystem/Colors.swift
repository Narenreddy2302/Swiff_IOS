//
//  Colors.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Semantic Colors
//  Updated with new UI Design System palette
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
        // MARK: - Primary Colors
        /// Pure Black - Dark mode backgrounds
        public static let pureBlack = Color(red: 0 / 255, green: 0 / 255, blue: 0 / 255)  // #000000

        /// Cream White - Primary text (dark mode), buttons, borders
        public static let creamWhite = Color(red: 245 / 255, green: 240 / 255, blue: 230 / 255)  // #F5F0E6

        /// Off-White - Light mode backgrounds
        public static let offWhite = Color(red: 250 / 255, green: 249 / 255, blue: 246 / 255)  // #FAF9F6

        // MARK: - Accent Colors
        /// Teal/Mint - Primary accent, links, active states, list items
        public static let teal = Color(red: 78 / 255, green: 205 / 255, blue: 196 / 255)  // #4ECDC4

        /// Teal Dark - Hover states, emphasis
        public static let tealDark = Color(red: 59 / 255, green: 169 / 255, blue: 156 / 255)  // #3BA99C

        // MARK: - Semantic Colors
        /// Orange Badge - Badges, notifications, highlights
        public static let orangeBadge = Color(red: 245 / 255, green: 166 / 255, blue: 35 / 255)  // #F5A623

        /// Amber Yellow - Warnings, attention states
        public static let amberYellow = Color(red: 255 / 255, green: 204 / 255, blue: 2 / 255)  // #FFCC02

        /// Success Green - Success states (using teal for consistency)
        public static let successGreen = teal  // #4ECDC4

        /// Error Red - Error states, destructive actions
        public static let errorRed = Color(red: 231 / 255, green: 76 / 255, blue: 60 / 255)  // #E74C3C

        // MARK: - Neutral Colors
        /// Dark Charcoal - Cards (dark mode), secondary backgrounds
        public static let darkCharcoal = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)  // #1C1C1E

        /// Dark Gray - Input fields, chat bubbles (outgoing)
        public static let darkGray = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)  // #2C2C2E

        /// Medium Gray - Chat bubbles (incoming), borders
        public static let mediumGray = Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)  // #3A3A3C

        /// Olive Gray - Secondary text, placeholders, chat bubble (outgoing variant)
        public static let oliveGray = Color(red: 74 / 255, green: 81 / 255, blue: 72 / 255)  // #4A5148

        /// Light Gray - Borders (light mode), dividers
        public static let lightGray = Color(red: 229 / 255, green: 229 / 255, blue: 229 / 255)  // #E5E5E5

        // MARK: - Legacy Green Palette (maintained for compatibility)
        public static let green1 = Color(red: 238 / 255, green: 242 / 255, blue: 227 / 255)  // #EEF2E3
        public static let green2 = Color(red: 200 / 255, green: 241 / 255, blue: 105 / 255)  // #C8F169
        public static let green3 = Color(red: 120 / 255, green: 197 / 255, blue: 28 / 255)  // #78C51C
        public static let green4 = Color(red: 42 / 255, green: 111 / 255, blue: 43 / 255)  // #2A6F2B
        public static let green5 = Color(red: 4 / 255, green: 63 / 255, blue: 46 / 255)  // #043F2E

        // MARK: - Brand Colors (Adaptive for Dark Mode)
        /// Primary brand color - cream in dark mode, teal in light mode
        public static let brandPrimary = Color(light: teal, dark: creamWhite)

        /// Secondary brand color - teal dark in light mode, teal in dark mode
        public static let brandSecondary = Color(light: tealDark, dark: teal)

        /// Accent color - teal for both modes
        public static let brandAccent = teal

        /// Text color on primary buttons - black on cream (dark mode), white on teal (light mode)
        public static let textOnPrimary = Color(
            light: Color.white,
            dark: pureBlack
        )

        /// Border color - adapts for visibility in both modes
        public static let border = Color(
            light: lightGray,
            dark: creamWhite.opacity(0.15)
        )

        // MARK: - Semantic Status Colors
        public static let success = successGreen
        public static let warning = amberYellow
        public static let systemError = errorRed
        public static let info = teal

        // Aliases for compatibility
        public static let statusError = systemError
        public static let statusWarning = warning
        public static let statusSuccess = success

        // MARK: - Backgrounds (Adaptive)
        public static let background = Color(
            light: offWhite,
            dark: pureBlack
        )

        public static let cardBackground = Color(
            light: Color.white,
            dark: darkCharcoal
        )

        public static let secondaryBackground = Color(
            light: Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255),  // #F5F5F5
            dark: darkGray
        )

        /// Elevated background level 2 - for nested elements
        public static let elevatedBackground = Color(
            light: Color.white,
            dark: darkGray
        )

        /// Elevated background level 3 - for hover/active states
        public static let elevatedBackground3 = Color(
            light: Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255),
            dark: mediumGray
        )

        // MARK: - Text (Adaptive)
        public static let textPrimary = Color(
            light: pureBlack,
            dark: creamWhite
        )

        public static let textSecondary = Color(
            light: Color(red: 74 / 255, green: 74 / 255, blue: 74 / 255),  // #4A4A4A
            dark: creamWhite.opacity(0.7)
        )

        public static let textTertiary = Color(
            light: Color(red: 154 / 255, green: 154 / 255, blue: 154 / 255),  // #9A9A9A
            dark: creamWhite.opacity(0.5)
        )

        public static let textDisabled = Color(
            light: Color(red: 154 / 255, green: 154 / 255, blue: 154 / 255),
            dark: creamWhite.opacity(0.3)
        )

        // MARK: - Finance Colors (Adaptive)
        /// Positive amount color - teal for both modes
        public static let amountPositive = teal

        /// Negative amount color - error red
        public static let amountNegative = errorRed

        // MARK: - Component Colors (Adaptive)
        /// Primary button background - cream in dark mode, teal in light mode
        public static let buttonPrimary = Color(light: teal, dark: creamWhite)

        /// Primary button text - white on teal (light), black on cream (dark)
        public static let buttonPrimaryText = Color(
            light: Color.white,
            dark: pureBlack
        )

        public static let buttonSecondary = Color(
            light: Color.clear,
            dark: Color.clear
        )

        public static let buttonSecondaryText = Color(
            light: pureBlack,
            dark: creamWhite
        )

        public static let buttonSecondaryBorder = Color(
            light: pureBlack,
            dark: creamWhite
        )

        public static let buttonDisabled = Color(
            light: lightGray,
            dark: mediumGray
        )

        // MARK: - Chat Bubble Colors (Adaptive)
        /// Incoming message bubble - medium gray (dark mode)
        public static let chatBubbleIncoming = Color(
            light: Color(red: 233 / 255, green: 233 / 255, blue: 235 / 255),  // #E9E9EB
            dark: mediumGray
        )

        /// Outgoing message bubble - olive gray variant
        public static let chatBubbleOutgoing = Color(
            light: teal,
            dark: oliveGray
        )

        /// Chat bubble text color
        public static let chatBubbleText = creamWhite

        // MARK: - Feed Reference Colors (Adaptive)
        /// Primary text color for feed
        public static let feedPrimaryText = Color(
            light: pureBlack,
            dark: creamWhite
        )

        /// Secondary text color for feed
        public static let feedSecondaryText = Color(
            light: Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255),
            dark: creamWhite.opacity(0.7)
        )

        /// Tertiary text color for feed
        public static let feedTertiaryText = Color(
            light: Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
            dark: creamWhite.opacity(0.5)
        )

        /// Positive amount color for feed - teal
        public static let feedPositiveAmount = teal

        /// Divider line color
        public static let feedDivider = Color(
            light: lightGray,
            dark: mediumGray
        )

        /// Active filter tab color - teal
        public static let feedActiveTab = teal

        // MARK: - Sheet Colors

        /// Card background for detail sheets
        public static let sheetCardBackground = Color(
            light: Color.white,
            dark: darkCharcoal
        )

        /// Border/divider color for sheets
        public static let sheetBorder = Color(
            light: lightGray,
            dark: mediumGray
        )

        /// Pill/button background
        public static let sheetPillBackground = Color(
            light: Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255),
            dark: darkGray
        )

        /// Primary teal for buttons
        public static let sheetGreenPrimary = teal

        // MARK: - Sheet Badge Colors

        /// Contact badge background (teal variant)
        public static let sheetContactBadgeBg = Color(
            light: teal.opacity(0.15),
            dark: teal.opacity(0.2)
        )
        /// Contact badge text
        public static let sheetContactBadgeText = Color(
            light: tealDark,
            dark: teal
        )

        /// Group badge background (purple)
        public static let sheetGroupBadgeBg = Color(
            light: Color(red: 0.953, green: 0.910, blue: 1.0),
            dark: Color(red: 0.3, green: 0.1, blue: 0.4)
        )
        /// Group badge text (purple)
        public static let sheetGroupBadgeText = Color(
            light: Color(red: 0.576, green: 0.200, blue: 0.918),
            dark: Color(red: 0.8, green: 0.5, blue: 1.0)
        )

        /// Subscription badge background (orange)
        public static let sheetSubscriptionBadgeBg = Color(
            light: orangeBadge.opacity(0.15),
            dark: orangeBadge.opacity(0.2)
        )
        /// Subscription badge text (orange)
        public static let sheetSubscriptionBadgeText = Color(
            light: Color(red: 0.702, green: 0.263, blue: 0.035),
            dark: orangeBadge
        )

        // MARK: - Border Colors (CSS Variables equivalent)
        /// Subtle border - 10% opacity
        public static let borderSubtle = Color(
            light: pureBlack.opacity(0.06),
            dark: creamWhite.opacity(0.1)
        )

        /// Default border - 15% opacity
        public static let borderDefault = Color(
            light: pureBlack.opacity(0.1),
            dark: creamWhite.opacity(0.15)
        )

        /// Strong border - 25% opacity
        public static let borderStrong = Color(
            light: pureBlack.opacity(0.2),
            dark: creamWhite.opacity(0.25)
        )

        // MARK: - Interaction States
        /// Hover overlay
        public static let hoverOverlay = Color(
            light: pureBlack.opacity(0.05),
            dark: creamWhite.opacity(0.08)
        )

        /// Active/pressed overlay
        public static let activeOverlay = Color(
            light: pureBlack.opacity(0.08),
            dark: creamWhite.opacity(0.12)
        )

        /// Focus ring color
        public static let focusRing = teal.opacity(0.4)
    }
}
