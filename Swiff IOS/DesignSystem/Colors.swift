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

        // MARK: - Brand Colors
        static let brandPrimary = green5  // #043F2E - Primary brand color
        static let brandSecondary = green4  // #2A6F2B - Secondary brand color
        static let brandAccent = Color(red: 1.0, green: 0.596, blue: 0.0)  // wiseOrange (#FF9800)

        static let textOnPrimary = Color.white
        static let border = Color.gray.opacity(0.2)

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

        // MARK: - Finance Colors
        static let amountPositive = green4  // #2A6F2B - Medium dark green for income/positive
        static let amountNegative = Color(red: 0.851, green: 0.176, blue: 0.125)  // Red for expenses

        // MARK: - Component Colors (Adaptive)
        static let buttonPrimary = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 4/255, green: 63/255, blue: 46/255, alpha: 1.0)  // GREEN 5 (#043F2E)
                    : UIColor(red: 4/255, green: 63/255, blue: 46/255, alpha: 1.0)  // GREEN 5 (#043F2E)
            })

        static let buttonPrimaryText = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)  // White text on dark green
                    : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)  // White text on dark green
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

        // MARK: - Feed Reference Colors
        /// Primary text color for feed (#1C1C1E)
        static let feedPrimaryText = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)

        /// Secondary text color for feed (#8E8E93)
        static let feedSecondaryText = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)

        /// Positive amount color (#34C759)
        static let feedPositiveAmount = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)

        /// Divider line color (#E5E5EA)
        static let feedDivider = Color(red: 229 / 255, green: 229 / 255, blue: 234 / 255)

        /// Active filter tab color - lime green (#D4E157)
        static let feedActiveTab = Color(red: 212 / 255, green: 225 / 255, blue: 87 / 255)
    }
}
