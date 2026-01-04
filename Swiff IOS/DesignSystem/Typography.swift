//
//  Typography.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Semantic Typography
//

import SwiftUI

extension Theme {

    struct Fonts {
        // MARK: - Display (Headings)
        /// Title, Black Weight - For Main Titles
        static let displayLarge = Font.title.weight(.black)

        /// Title2, Bold Weight - For Section Headers
        static let displayMedium = Font.title2.weight(.bold)

        // MARK: - Headers
        /// Title3, Bold
        static let headerLarge = Font.title3.weight(.bold)
        /// Headline
        static let headerMedium = Font.headline
        /// Body, Semibold
        static let headerSmall = Font.body.weight(.semibold)

        // MARK: - Body
        /// Subheadline, Medium - Default readable text
        static let bodyLarge = Font.subheadline.weight(.medium)
        /// Footnote, Medium - Secondary text
        static let bodyMedium = Font.footnote.weight(.medium)
        /// Caption - Dense text
        static let bodySmall = Font.caption

        // MARK: - Label / Utilities
        /// Footnote, Semibold - Buttons and Labels
        static let labelLarge = Font.footnote.weight(.semibold)
        /// Caption2, Semibold - Small pills/tags
        static let labelMedium = Font.caption2.weight(.semibold)
        /// Caption2, Semibold - Tiny metadata
        static let labelSmall = Font.caption2.weight(.semibold)

        // MARK: - Captions
        static let captionMedium = Font.caption2
        static let captionSmall = Font.caption2

        // MARK: - Numbers (Impactful)
        /// Title2, Black - Big Balances
        static let numberLarge = Font.title2.weight(.black)
        /// Body, Semibold - Transaction Amounts
        static let numberMedium = Font.body.weight(.semibold)
    }
}
