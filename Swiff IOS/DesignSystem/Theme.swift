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
        public static let avatarCompact: CGFloat = 32.0    // Compact headers
        public static let avatarStandard: CGFloat = 40.0   // List rows
        public static let avatarMedium: CGFloat = 48.0     // Subscription icons
        public static let avatarLarge: CGFloat = 64.0      // Detail headers
        public static let avatarHero: CGFloat = 80.0       // Profile/Group hero

        // MARK: - Touch Targets (Apple HIG)
        public static let minTapTarget: CGFloat = 44.0
        public static let buttonIconSize: CGFloat = 22.0
        public static let backButtonIconSize: CGFloat = 18.0
    }
}
