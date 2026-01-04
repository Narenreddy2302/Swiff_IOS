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
        /// Size 32, Black Weight - For Main Titles
        static let displayLarge = Font.custom("Helvetica Neue", size: 32).weight(.black)

        /// Size 24, Bold Weight - For Section Headers
        static let displayMedium = Font.custom("Helvetica Neue", size: 24).weight(.bold)

        // MARK: - Headers
        /// Size 20, Bold
        static let headerLarge = Font.custom("Helvetica Neue", size: 20).weight(.bold)
        /// Size 18, Bold
        static let headerMedium = Font.custom("Helvetica Neue", size: 18).weight(.bold)
        /// Size 16, Bold
        static let headerSmall = Font.custom("Helvetica Neue", size: 16).weight(.bold)

        // MARK: - Body (SF Pro)
        /// Size 16, Medium - Default readable text
        static let bodyLarge = Font.system(size: 16, weight: .medium)
        /// Size 14, Medium - Secondary text
        static let bodyMedium = Font.system(size: 14, weight: .medium)
        /// Size 13, Regular - Dense text
        static let bodySmall = Font.system(size: 13, weight: .regular)

        // MARK: - Label / Utilities
        /// Size 14, Semibold - Buttons and Labels
        static let labelLarge = Font.system(size: 14, weight: .semibold)
        /// Size 12, Semibold - Small pills/tags
        static let labelMedium = Font.system(size: 12, weight: .semibold)
        /// Size 11, Semibold - Tiny metadata
        static let labelSmall = Font.system(size: 11, weight: .semibold)

        // MARK: - Captions
        static let captionMedium = Font.system(size: 12, weight: .regular)
        static let captionSmall = Font.system(size: 11, weight: .regular)

        // MARK: - Numbers (Monospaced/Impactful)
        /// Size 24, Black - Big Balances
        static let numberLarge = Font.custom("Helvetica Neue", size: 24).weight(.black)
        /// Size 16, Bold - Transaction Amounts
        static let numberMedium = Font.custom("Helvetica Neue", size: 16).weight(.bold)
    }
}
