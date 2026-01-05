//
//  Colors.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Semantic Colors
//

import SwiftUI
import UIKit

extension Theme {

    struct Colors {
        // MARK: - Green Palette (5-tier system)
        static let green1 = Color(red: 238/255, green: 242/255, blue: 227/255)  // #EEF2E3 - Light backgrounds, disabled states
        static let green2 = Color(red: 200/255, green: 241/255, blue: 105/255)  // #C8F169 - Hover/focus states, highlights
        static let green3 = Color(red: 120/255, green: 197/255, blue: 28/255)   // #78C51C - Success indicators, active states
        static let green4 = Color(red: 42/255, green: 111/255, blue: 43/255)    // #2A6F2B - Secondary brand, positive amounts
        static let green5 = Color(red: 4/255, green: 63/255, blue: 46/255)      // #043F2E - Primary brand, buttons, headers

        // MARK: - Brand Colors (Adaptive for Dark Mode)
        /// Primary brand color - dark green in light mode, bright lime in dark mode
        static let brandPrimary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 120/255, green: 197/255, blue: 28/255, alpha: 1.0)  // green3 (#78C51C)
                    : UIColor(red: 4/255, green: 63/255, blue: 46/255, alpha: 1.0)     // green5 (#043F2E)
            })

        /// Secondary brand color - medium green in light mode, lime highlight in dark mode
        static let brandSecondary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 200/255, green: 241/255, blue: 105/255, alpha: 1.0)  // green2 (#C8F169)
                    : UIColor(red: 42/255, green: 111/255, blue: 43/255, alpha: 1.0)    // green4 (#2A6F2B)
            })

        /// Accent color - orange for both modes, slightly brighter in dark mode
        static let brandAccent = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1.0)  // Brighter orange
                    : UIColor(red: 1.0, green: 0.596, blue: 0.0, alpha: 1.0)  // #FF9800
            })

        /// Text color on primary buttons - white on dark green, dark on bright lime
        static let textOnPrimary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.05, green: 0.15, blue: 0.1, alpha: 1.0)  // Dark green text
                    : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)    // White
            })

        /// Border color - adapts for visibility in both modes
        static let border = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 1.0, alpha: 0.15)  // Light border on dark
                    : UIColor(white: 0.0, alpha: 0.1)   // Dark border on light
            })

        // MARK: - Semantic Status Colors
        static let success = green3  // #78C51C - Bright lime for success states
        static let warning = Color(red: 1.0, green: 0.624, blue: 0.039)  // Orange warning
        static let systemError = Color(red: 1.0, green: 0.271, blue: 0.227)  // Red error

        static let info = Color(red: 0.039, green: 0.518, blue: 1.0)  // Blue info

        // Aliases for compatibility
        static let statusError = systemError
        static let statusWarning = warning
        static let statusSuccess = success

        // MARK: - Backgrounds (Adaptive)
        static let background = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                    : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            })

        static let cardBackground = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
                    : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            })

        static let secondaryBackground = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1.0)
                    : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
            })

        // MARK: - Text (Adaptive)
        static let textPrimary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    : UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0)
            })

        static let textSecondary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
                    : UIColor(red: 0.235, green: 0.235, blue: 0.235, alpha: 1.0)
            })

        static let textTertiary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.486, green: 0.486, blue: 0.502, alpha: 1.0)
                    : UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)
            })

        // MARK: - Finance Colors (Adaptive)
        /// Positive amount color - bright green that works on both light and dark
        static let amountPositive = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)   // System green
                    : UIColor(red: 42/255, green: 111/255, blue: 43/255, alpha: 1.0)   // green4 (#2A6F2B)
            })

        /// Negative amount color - red that adapts for visibility
        static let amountNegative = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)            // Brighter red
                    : UIColor(red: 0.851, green: 0.176, blue: 0.125, alpha: 1.0)        // #D92D20
            })

        // MARK: - Component Colors (Adaptive)
        /// Primary button background - matches brandPrimary for consistency
        static let buttonPrimary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 120/255, green: 197/255, blue: 28/255, alpha: 1.0)  // green3 (#78C51C)
                    : UIColor(red: 4/255, green: 63/255, blue: 46/255, alpha: 1.0)     // green5 (#043F2E)
            })

        /// Primary button text - dark on bright lime, white on dark green
        static let buttonPrimaryText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.05, green: 0.15, blue: 0.1, alpha: 1.0)  // Dark green text
                    : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)    // White text
            })

        static let buttonSecondary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.227, green: 0.227, blue: 0.235, alpha: 1.0)
                    : UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1.0)
            })

        static let buttonSecondaryText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    : UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0)
            })

        static let buttonDisabled = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.282, green: 0.282, blue: 0.29, alpha: 1.0)
                    : UIColor(red: 0.776, green: 0.776, blue: 0.784, alpha: 1.0)
            })

        // MARK: - Feed Reference Colors (Adaptive)
        /// Primary text color for feed - white in dark mode, dark gray in light mode
        static let feedPrimaryText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor.white
                    : UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)
            })

        /// Secondary text color for feed - adapts for readability
        static let feedSecondaryText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.65, alpha: 1.0)
                    : UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
            })

        /// Tertiary text color for feed - lighter shade for category
        static let feedTertiaryText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.5, alpha: 1.0)
                    : UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0)
            })

        /// Positive amount color - bright green in both modes
        static let feedPositiveAmount = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
                    : UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
            })

        /// Divider line color - subtle in both modes
        static let feedDivider = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 1.0, alpha: 0.12)
                    : UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0)
            })

        /// Active filter tab color - lime green, slightly brighter in dark mode
        static let feedActiveTab = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 220/255, green: 235/255, blue: 100/255, alpha: 1.0)
                    : UIColor(red: 212/255, green: 225/255, blue: 87/255, alpha: 1.0)
            })

        // MARK: - Sheet Colors

        /// Card background for detail sheets - adaptive
        static let sheetCardBackground = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1.0)  // Dark gray
                    : UIColor(red: 0.973, green: 0.980, blue: 0.988, alpha: 1.0) // #F8F9FA
            })

        /// Border/divider color for sheets - adaptive
        static let sheetBorder = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.25, alpha: 1.0)
                    : UIColor(red: 0.886, green: 0.906, blue: 0.925, alpha: 1.0) // #E2E7EC
            })

        /// Pill/button background - adaptive
        static let sheetPillBackground = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.2, alpha: 1.0)
                    : UIColor(red: 0.945, green: 0.957, blue: 0.965, alpha: 1.0) // #F1F3F5
            })

        /// Primary green for buttons - adaptive
        static let sheetGreenPrimary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 1.0)      // Brighter green
                    : UIColor(red: 0.020, green: 0.588, blue: 0.412, alpha: 1.0) // #059669
            })

        // MARK: - Sheet Badge Colors

        /// Contact badge background (blue) - adaptive
        static let sheetContactBadgeBg = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0)       // Darker blue bg
                    : UIColor(red: 0.859, green: 0.914, blue: 1.0, alpha: 1.0)
            })
        /// Contact badge text (blue) - adaptive
        static let sheetContactBadgeText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)       // Lighter blue text
                    : UIColor(red: 0.114, green: 0.306, blue: 0.851, alpha: 1.0)
            })

        /// Group badge background (purple) - adaptive
        static let sheetGroupBadgeBg = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 1.0)       // Darker purple bg
                    : UIColor(red: 0.953, green: 0.910, blue: 1.0, alpha: 1.0)
            })
        /// Group badge text (purple) - adaptive
        static let sheetGroupBadgeText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)       // Lighter purple text
                    : UIColor(red: 0.576, green: 0.200, blue: 0.918, alpha: 1.0)
            })

        /// Subscription badge background (amber) - adaptive
        static let sheetSubscriptionBadgeBg = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.4, green: 0.3, blue: 0.1, alpha: 1.0)       // Darker amber bg
                    : UIColor(red: 0.996, green: 0.953, blue: 0.780, alpha: 1.0)
            })
        /// Subscription badge text (amber) - adaptive
        static let sheetSubscriptionBadgeText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)       // Lighter amber text
                    : UIColor(red: 0.702, green: 0.263, blue: 0.035, alpha: 1.0)
            })
    }
}
