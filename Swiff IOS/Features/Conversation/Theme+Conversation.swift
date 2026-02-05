//
//  Theme+Conversation.swift
//  Swiff IOS
//
//  Theme extensions specific to conversation views
//  Updated with new UI Design System specifications
//  Provides consistent styling helpers
//

import SwiftUI

// NOTE: View modifier button styles (navigationButtonStyle, textActionButtonStyle, iconActionButtonStyle)
// are defined in Views/Components/ConversationButtonStyles.swift - do not duplicate here

// MARK: - Theme Extensions

extension Theme {

    /// Conversation-specific fonts - Updated with new UI Design System
    struct ConversationFonts {
        static let messageBubble = Font.system(size: 16)
        static let messageBubbleBold = Font.system(size: 16, weight: .semibold)
        static let transactionTitle = Font.system(size: 16, weight: .semibold)
        static let transactionAmount = Font.system(size: 17, weight: .semibold)
        static let transactionMetadata = Font.system(size: 14)
        static let transactionMetadataValue = Font.system(size: 14, weight: .medium)
        static let systemMessage = Font.system(size: 12, weight: .medium)
        static let dateHeader = Font.system(size: 11, weight: .semibold)
        static let inputField = Font.system(size: 16)
    }

    /// Conversation-specific metrics - Updated with new UI Design System
    struct ConversationMetrics {
        // Card metrics - Updated to match design system
        static let cardCornerRadius: CGFloat = Theme.Metrics.cardCornerRadius  // 20px
        static let cardBorderWidth: CGFloat = Theme.Border.widthDefault
        static let cardShadowRadius: CGFloat = 8.0
        static let cardShadowY: CGFloat = 4.0
        static let cardPadding: CGFloat = Theme.Metrics.cardPadding  // 24px
        static let cardIconSize: CGFloat = 40.0
        static let cardMaxWidth: CGFloat = 320.0

        // Message bubble metrics - Updated to design system specs
        static let bubbleMaxWidthRatio: CGFloat = Theme.Metrics.chatBubbleMaxWidthRatio  // 0.75
        static let bubbleCornerRadius: CGFloat = Theme.Metrics.chatBubbleCornerRadius  // 20px
        static let bubbleTailRadius: CGFloat = Theme.Metrics.chatBubbleTailRadius  // 4px
        static let bubblePaddingH: CGFloat = Theme.Metrics.chatBubblePaddingH  // 16px
        static let bubblePaddingV: CGFloat = Theme.Metrics.chatBubblePaddingV  // 12px

        // Timeline spacing
        static let timelineItemSpacingTight: CGFloat = 2.0
        static let timelineItemSpacingWide: CGFloat = 16.0
        static let timelineDateSpacing: CGFloat = 24.0

        // Input bar metrics - Updated to pill shape
        static let inputBarIconSize: CGFloat = 28.0
        static let inputBarCornerRadius: CGFloat = Theme.Metrics.inputCornerRadius  // Pill shape (100px)
        static let inputBarPadding: CGFloat = 12.0
        static let inputBarFieldPaddingH: CGFloat = Theme.Metrics.inputPaddingH  // 20px
        static let inputBarFieldPaddingV: CGFloat = Theme.Metrics.inputPaddingV  // 14px

        // Balance banner metrics
        static let balanceBannerPaddingH: CGFloat = Theme.Metrics.spaceMD  // 16px
        static let balanceBannerPaddingV: CGFloat = 10.0
        static let balanceBannerIconSize: CGFloat = 14.0
    }
}

// MARK: - Color Extensions

extension Color {
    // NOTE: iMessageBlue and iMessageGray are defined in Models/Domain/SupportingTypes.swift
    // Do not duplicate here to avoid "Invalid redeclaration" errors

    /// Transaction type colors - Using new Teal accent
    static var transactionPayment: Color { Theme.Colors.teal }  // Teal #4ECDC4
    static var transactionRequest: Color { Theme.Colors.orangeBadge }  // Orange #F5A623
    static var transactionSplit: Color { Theme.Colors.teal }  // Teal
    static var transactionExpense: Color { Theme.Colors.tealDark }  // Teal Dark #3BA99C

    /// Balance state colors - Using new palette
    static var balancePositive: Color { Theme.Colors.teal }  // Teal for positive
    static var balanceNegative: Color { Theme.Colors.errorRed }  // Error Red #E74C3C
    static var balanceSettled: Color { Theme.Colors.textSecondary }
}

// NOTE: iMessageBubbleShape and iMessageBubbleDirection are defined in
// Views/Components/Shapes/iMessageBubbleShape.swift - do not duplicate here

// NOTE: Theme.Fonts is defined in DesignSystem/Typography.swift - do not duplicate here

// NOTE: Theme.Colors is defined in DesignSystem/Colors.swift - do not duplicate here

// MARK: - Preview Helpers

#Preview("Theme Colors - New Design System") {
    VStack(spacing: 16) {
        Text("Transaction Colors")
            .font(.headline)
            .foregroundColor(.wisePrimaryText)

        HStack(spacing: 12) {
            Circle()
                .fill(Color.transactionPayment)
                .frame(width: 40, height: 40)
                .overlay(Text("Pay").font(.caption2).foregroundColor(.white))

            Circle()
                .fill(Color.transactionRequest)
                .frame(width: 40, height: 40)
                .overlay(Text("Req").font(.caption2).foregroundColor(.white))

            Circle()
                .fill(Color.transactionSplit)
                .frame(width: 40, height: 40)
                .overlay(Text("Split").font(.caption2).foregroundColor(.white))

            Circle()
                .fill(Color.transactionExpense)
                .frame(width: 40, height: 40)
                .overlay(Text("Exp").font(.caption2).foregroundColor(.white))
        }

        Text("Balance Colors")
            .font(.headline)
            .foregroundColor(.wisePrimaryText)
            .padding(.top)

        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.balancePositive)
                .frame(width: 60, height: 40)
                .cornerRadius(8)
                .overlay(Text("+").foregroundColor(.white))

            Rectangle()
                .fill(Color.balanceNegative)
                .frame(width: 60, height: 40)
                .cornerRadius(8)
                .overlay(Text("-").foregroundColor(.white))

            Rectangle()
                .fill(Color.balanceSettled)
                .frame(width: 60, height: 40)
                .cornerRadius(8)
                .overlay(Text("=").foregroundColor(.white))
        }

        Text("Chat Bubble Colors")
            .font(.headline)
            .foregroundColor(.wisePrimaryText)
            .padding(.top)

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Theme.Metrics.chatBubbleCornerRadius)
                .fill(Theme.Colors.oliveGray)
                .frame(width: 100, height: 40)
                .overlay(Text("Outgoing").font(.caption2).foregroundColor(Theme.Colors.creamWhite))

            RoundedRectangle(cornerRadius: Theme.Metrics.chatBubbleCornerRadius)
                .fill(Theme.Colors.mediumGray)
                .frame(width: 100, height: 40)
                .overlay(Text("Incoming").font(.caption2).foregroundColor(Theme.Colors.creamWhite))
        }

        Text("Primary Colors")
            .font(.headline)
            .foregroundColor(.wisePrimaryText)
            .padding(.top)

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.teal)
                .frame(width: 60, height: 40)
                .overlay(Text("Teal").font(.caption2).foregroundColor(.white))

            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.creamWhite)
                .frame(width: 60, height: 40)
                .overlay(Text("Cream").font(.caption2).foregroundColor(.black))

            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.orangeBadge)
                .frame(width: 60, height: 40)
                .overlay(Text("Orange").font(.caption2).foregroundColor(.white))
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
