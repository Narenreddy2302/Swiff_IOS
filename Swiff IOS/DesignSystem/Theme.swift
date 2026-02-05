//
//  Theme.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Root Namespace
//  Updated with new UI Design System specifications
//

import SwiftUI

/// Root namespace for the Swiff Design System
public struct Theme {
    // Shared constants (legacy)
    public static let cornerRadius: CGFloat = 12.0
    public static let padding: CGFloat = 16.0

    public struct Metrics {
        // MARK: - Spacing System (Base-8 Scale)
        public static let spaceXS: CGFloat = 4.0    // Tight spacing, icon padding
        public static let spaceSM: CGFloat = 8.0    // Compact elements, inline spacing
        public static let spaceMD: CGFloat = 16.0   // Default component padding
        public static let spaceLG: CGFloat = 24.0   // Section spacing, card padding
        public static let spaceXL: CGFloat = 32.0   // Large section gaps
        public static let space2XL: CGFloat = 48.0  // Major section separations
        public static let space3XL: CGFloat = 64.0  // Page-level spacing

        // MARK: - Legacy Padding (mapped to new system)
        public static let paddingSmall: CGFloat = spaceSM   // 8pt
        public static let paddingMedium: CGFloat = spaceMD  // 16pt
        public static let paddingLarge: CGFloat = spaceLG   // 24pt

        // MARK: - Corner Radius
        public static let cornerRadiusSmall: CGFloat = 6.0      // Badges
        public static let cornerRadiusMedium: CGFloat = 12.0    // Default
        public static let cornerRadiusLarge: CGFloat = 20.0     // Cards, chat bubbles
        public static let cornerRadiusXL: CGFloat = 24.0        // Feature cards
        public static let cornerRadiusFull: CGFloat = 100.0     // Pill buttons, inputs
        public static let cornerRadiusDeviceFrame: CGFloat = 40.0  // Device mockups

        // MARK: - Icon Sizes
        public static let iconSizeSmall: CGFloat = 16.0   // Inline with text
        public static let iconSizeMedium: CGFloat = 20.0  // Buttons, list items
        public static let iconSizeLarge: CGFloat = 24.0   // Navigation, primary actions
        public static let iconSizeXL: CGFloat = 32.0      // Feature icons, empty states

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
        public static let avatarLarge: CGFloat = 64.0  // Detail headers, conversation
        public static let avatarHero: CGFloat = 80.0  // Profile/Group hero

        // MARK: - Button Sizes
        public static let buttonHeightSmall: CGFloat = 36.0
        public static let buttonHeightMedium: CGFloat = 44.0
        public static let buttonHeightLarge: CGFloat = 52.0
        public static let buttonPaddingSmall: CGFloat = 12.0
        public static let buttonPaddingMedium: CGFloat = 14.0
        public static let buttonPaddingLarge: CGFloat = 14.0
        public static let buttonHorizontalPaddingSmall: CGFloat = 24.0
        public static let buttonHorizontalPaddingLarge: CGFloat = 28.0

        // MARK: - Icon Button Sizes
        public static let iconButtonSmall: CGFloat = 40.0
        public static let iconButtonMedium: CGFloat = 48.0
        public static let sendButtonSize: CGFloat = 40.0

        // MARK: - Card Metrics
        public static let cardPadding: CGFloat = spaceLG  // 24pt
        public static let cardCornerRadius: CGFloat = cornerRadiusLarge  // 20pt
        public static let featureCardPadding: CGFloat = space2XL  // 32pt
        public static let featureCardCornerRadius: CGFloat = cornerRadiusXL  // 24pt

        // MARK: - Chat Bubble Metrics
        public static let chatBubbleCornerRadius: CGFloat = 20.0
        public static let chatBubbleTailRadius: CGFloat = 4.0
        public static let chatBubblePaddingH: CGFloat = 16.0
        public static let chatBubblePaddingV: CGFloat = 12.0
        public static let chatBubbleMaxWidthRatio: CGFloat = 0.75

        // MARK: - Input Field Metrics
        public static let inputPaddingH: CGFloat = 20.0
        public static let inputPaddingV: CGFloat = 14.0
        public static let inputCornerRadius: CGFloat = cornerRadiusFull  // Pill shape

        // MARK: - Waveform Metrics
        public static let waveformBarWidth: CGFloat = 4.0
        public static let waveformBarSpacing: CGFloat = 4.0
        public static let waveformHeight: CGFloat = 48.0

        // MARK: - Device Frame Metrics
        public static let deviceFrameBorder: CGFloat = 3.0
        public static let deviceFrameCornerRadius: CGFloat = cornerRadiusDeviceFrame
        public static let deviceFramePadding: CGFloat = 12.0
        public static let deviceScreenCornerRadius: CGFloat = 28.0
        public static let deviceMaxWidth: CGFloat = 375.0

        // MARK: - Transaction Flow Specific
        public static let spacingTiny: CGFloat = spaceXS  // 4pt
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

        // MARK: - List Item Metrics
        public static let listItemPaddingH: CGFloat = spaceMD  // 16pt
        public static let listItemPaddingV: CGFloat = 12.0
        public static let listItemCornerRadius: CGFloat = 8.0
        public static let listItemSpacing: CGFloat = spaceSM  // 8pt

        // MARK: - Badge Metrics
        public static let badgePaddingH: CGFloat = 10.0
        public static let badgePaddingV: CGFloat = 4.0
        public static let badgeCornerRadius: CGFloat = cornerRadiusSmall  // 6pt
        public static let platformBadgePaddingH: CGFloat = 12.0
        public static let platformBadgePaddingV: CGFloat = 6.0
    }

    public struct Border {
        public static let widthDefault: CGFloat = 1.0
        public static let widthMedium: CGFloat = 1.5
        public static let widthFocused: CGFloat = 2.0
        public static let widthSelected: CGFloat = 2.0
        public static let widthDeviceFrame: CGFloat = 3.0
    }

    public struct Opacity {
        public static let disabled: Double = 0.5
        public static let subtle: Double = 0.3
        public static let faint: Double = 0.15
        public static let border: Double = 0.5
        public static let borderSubtle: Double = 0.1
        public static let borderDefault: Double = 0.15
        public static let borderStrong: Double = 0.25
        public static let hoverOverlay: Double = 0.08
        public static let activeOverlay: Double = 0.12
    }

    public struct Animation {
        public static let fast: Double = 0.15
        public static let normal: Double = 0.2
        public static let slow: Double = 0.3
    }
}
