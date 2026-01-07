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
    }
}
