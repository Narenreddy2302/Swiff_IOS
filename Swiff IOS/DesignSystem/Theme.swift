//
//  Theme.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Root Namespace
//

import SwiftUI

/// Root namespace for the Swiff Design System
public struct Theme {
    // Shared constants
    // Shared constants
    public static let cornerRadius: CGFloat = 12.0
    public static let padding: CGFloat = 16.0

    public struct Metrics {
        // MARK: - Padding (8pt Grid)
        public static let paddingSmall: CGFloat = 8.0
        public static let paddingMedium: CGFloat = 16.0
        public static let paddingLarge: CGFloat = 24.0

        // MARK: - Corner Radius
        public static let cornerRadiusSmall: CGFloat = 8.0
        public static let cornerRadiusMedium: CGFloat = 12.0
        public static let cornerRadiusLarge: CGFloat = 16.0

        // MARK: - Icon Sizes
        public static let iconSizeSmall: CGFloat = 16.0
        public static let iconSizeMedium: CGFloat = 24.0
        public static let iconSizeLarge: CGFloat = 32.0

        // MARK: - Header Metrics
        public static let headerHeight: CGFloat = 60.0
        public static let headerPaddingH: CGFloat = 8.0
        public static let headerPaddingV: CGFloat = 8.0
        public static let headerContentSpacing: CGFloat = 12.0
        public static let headerAvatarSpacing: CGFloat = 10.0

        // MARK: - Avatar Sizes (Standardized)
        public static let avatarCompact: CGFloat = 32.0  // Compact headers
        public static let avatarStandard: CGFloat = 40.0  // List rows
        public static let avatarMedium: CGFloat = 48.0  // Subscription icons
        public static let avatarLarge: CGFloat = 64.0  // Detail headers
        public static let avatarHero: CGFloat = 80.0  // Profile/Group hero

        // MARK: - Transaction Flow Specific
        public static let spacingTiny: CGFloat = 4.0
        public static let categoryChipSize: CGFloat = 80.0
        public static let avatarBubbleSize: CGFloat = 52.0
        public static let progressBarHeight: CGFloat = 4.0
        public static let progressDotActive: CGFloat = 24.0
        public static let progressDotInactive: CGFloat = 8.0
        public static let tabUnderlineHeight: CGFloat = 2.0
        public static let splitInputWidth: CGFloat = 50.0
        public static let amountInputWidth: CGFloat = 70.0
        public static let stepperButtonSize: CGFloat = 28.0
        public static let selectionIndicatorSize: CGFloat = 26.0
        public static let currencyPickerWidth: CGFloat = 120.0
        public static let sharesDisplayWidth: CGFloat = 32.0

        // MARK: - Touch Targets (Apple HIG)
        public static let minTapTarget: CGFloat = 44.0
        public static let buttonIconSize: CGFloat = 22.0
        public static let backButtonIconSize: CGFloat = 18.0
    }

    public struct Border {
        public static let widthDefault: CGFloat = 1.0
        public static let widthFocused: CGFloat = 2.0
        public static let widthSelected: CGFloat = 2.0
    }

    public struct Opacity {
        public static let disabled: Double = 0.5
        public static let subtle: Double = 0.3
        public static let faint: Double = 0.15
        public static let border: Double = 0.5
    }
}
