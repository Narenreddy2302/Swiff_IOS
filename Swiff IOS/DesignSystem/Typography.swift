//
//  Typography.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Design System - Semantic Typography
//  Updated with new UI Design System specifications
//

import SwiftUI

extension Theme {

    public struct Fonts {
        // MARK: - Display (Large Headings)
        /// Display - 48pt, weight black, line height 1.1 - Hero headings
        public static let display = Font.system(size: 48, weight: .black)

        /// Heading 1 - 32pt, weight bold, line height 1.2 - Page titles
        public static let heading1 = Font.system(size: 32, weight: .bold)

        /// Heading 2 - 24pt, weight bold, line height 1.3 - Section headings
        public static let heading2 = Font.system(size: 24, weight: .bold)

        /// Heading 3 - 20pt, weight semibold, line height 1.4 - Card titles, feature headings
        public static let heading3 = Font.system(size: 20, weight: .semibold)

        // MARK: - Body Text
        /// Body Large - 18pt, weight regular, line height 1.5 - Lead paragraphs
        public static let bodyLarge = Font.system(size: 18, weight: .regular)

        /// Body - 16pt, weight regular, line height 1.5 - Default body text
        public static let body = Font.system(size: 16, weight: .regular)

        /// Body Small - 14pt, weight regular, line height 1.5 - Secondary text, captions
        public static let bodySmall = Font.system(size: 14, weight: .regular)

        /// Caption - 12pt, weight regular, line height 1.4 - Labels, metadata
        public static let caption = Font.system(size: 12, weight: .regular)

        // MARK: - Font Weight Variants
        /// Body Medium - 16pt, weight medium
        public static let bodyMedium = Font.system(size: 16, weight: .medium)

        /// Body Semibold - 16pt, weight semibold
        public static let bodySemibold = Font.system(size: 16, weight: .semibold)

        /// Body Bold - 16pt, weight bold
        public static let bodyBold = Font.system(size: 16, weight: .bold)

        /// Caption Medium - 12pt, weight medium
        public static let captionMedium = Font.system(size: 12, weight: .medium)

        /// Caption Semibold - 12pt, weight semibold
        public static let captionSemibold = Font.system(size: 12, weight: .semibold)

        // MARK: - Legacy Display (compatibility)
        /// Title, Black Weight - For Main Titles
        public static let displayLarge = Font.title.weight(.black)

        /// Title2, Bold Weight - For Section Headers
        public static let displayMedium = Font.title2.weight(.bold)

        // MARK: - Legacy Headers (compatibility)
        /// Title3, Bold
        public static let headerLarge = Font.title3.weight(.bold)
        /// Headline
        public static let headerMedium = Font.headline
        /// Body, Semibold
        public static let headerSmall = Font.body.weight(.semibold)

        // MARK: - Label / Utilities
        /// Footnote, Semibold - Buttons and Labels
        public static let labelLarge = Font.footnote.weight(.semibold)
        /// Caption2, Semibold - Small pills/tags
        public static let labelMedium = Font.caption2.weight(.semibold)
        /// Caption2, Semibold - Tiny metadata
        public static let labelSmall = Font.caption2.weight(.semibold)

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

        // MARK: - Feature Card Typography
        /// 18pt semibold - Feature card titles
        public static let featureCardTitle = Font.system(size: 18, weight: .semibold)
        /// 14pt regular - Feature card descriptions
        public static let featureCardDescription = Font.system(size: 14, weight: .regular)

        // MARK: - Chat Typography
        /// 16pt regular - Chat message text
        public static let chatMessage = Font.system(size: 16, weight: .regular)
        /// 11pt medium - Chat timestamps
        public static let chatTimestamp = Font.system(size: 11, weight: .medium)
        /// 12pt medium - System messages
        public static let chatSystemMessage = Font.system(size: 12, weight: .medium)

        // MARK: - Input Typography
        /// 16pt regular - Input field text
        public static let inputText = Font.system(size: 16, weight: .regular)
        /// 16pt regular - Placeholder text (same as input)
        public static let inputPlaceholder = Font.system(size: 16, weight: .regular)
    }
}
