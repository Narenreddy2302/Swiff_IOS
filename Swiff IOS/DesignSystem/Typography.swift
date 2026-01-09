//
//  Typography.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Semantic Typography
//

import SwiftUI

extension Theme {

    public struct Fonts {
        // MARK: - Display (Headings)
        /// Title, Black Weight - For Main Titles
        public static let displayLarge = Font.title.weight(.black)

        /// Title2, Bold Weight - For Section Headers
        public static let displayMedium = Font.title2.weight(.bold)

        // MARK: - Headers
        /// Title3, Bold
        public static let headerLarge = Font.title3.weight(.bold)
        /// Headline
        public static let headerMedium = Font.headline
        /// Body, Semibold
        public static let headerSmall = Font.body.weight(.semibold)

        // MARK: - Body
        /// Subheadline, Medium - Default readable text
        public static let bodyLarge = Font.subheadline.weight(.medium)
        /// Footnote, Medium - Secondary text
        public static let bodyMedium = Font.footnote.weight(.medium)
        /// Caption - Dense text
        public static let bodySmall = Font.caption

        // MARK: - Label / Utilities
        /// Footnote, Semibold - Buttons and Labels
        public static let labelLarge = Font.footnote.weight(.semibold)
        /// Caption2, Semibold - Small pills/tags
        public static let labelMedium = Font.caption2.weight(.semibold)
        /// Caption2, Semibold - Tiny metadata
        public static let labelSmall = Font.caption2.weight(.semibold)

        // MARK: - Captions
        public static let captionMedium = Font.caption2
        public static let captionSmall = Font.caption2

        // MARK: - Numbers (Impactful)
        /// Title2, Black - Big Balances
        public static let numberLarge = Font.title2.weight(.black)
        /// Body, Semibold - Transaction Amounts
        public static let numberMedium = Font.body.weight(.semibold)

        // MARK: - Header Typography
        /// 16pt semibold - Header titles
        public static let headerTitle = Font.system(size: 16, weight: .semibold)
        /// Footnote - Header subtitles
        public static let headerSubtitle = Font.footnote

        // MARK: - Navigation
        /// 18pt semibold - Back button icon
        public static let navigationIcon = Font.system(size: 18, weight: .semibold)

        // MARK: - Badges
        /// Caption2, medium - Status badges
        public static let badgeText = Font.caption2.weight(.medium)
        /// 10pt medium - Compact badges
        public static let badgeCompact = Font.system(size: 10, weight: .medium)

        // MARK: - System Events
        /// Caption2, medium - Event messages
        public static let eventText = Font.caption2.weight(.medium)
        /// 10pt regular - Timestamps
        public static let eventTimestamp = Font.system(size: 10)
    }
}
