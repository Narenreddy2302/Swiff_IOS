//
//  Theme+Conversation.swift
//  Swiff IOS
//
//  Theme extensions specific to conversation views
//  Provides consistent styling helpers
//

import SwiftUI

// NOTE: View modifier button styles (navigationButtonStyle, textActionButtonStyle, iconActionButtonStyle)
// are defined in Views/Components/ConversationButtonStyles.swift - do not duplicate here

// MARK: - Theme Extensions

extension Theme {
    
    /// Conversation-specific fonts
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
    
    /// Conversation-specific metrics
    struct ConversationMetrics {
        // Card metrics
        static let cardCornerRadius: CGFloat = 12.0
        static let cardBorderWidth: CGFloat = 1.0
        static let cardShadowRadius: CGFloat = 2.0
        static let cardShadowY: CGFloat = 1.0
        static let cardPadding: CGFloat = 16.0
        static let cardIconSize: CGFloat = 40.0
        static let cardMaxWidth: CGFloat = 320.0
        
        // Message bubble metrics
        static let bubbleMaxWidthRatio: CGFloat = 0.75
        static let bubbleCornerRadius: CGFloat = 18.0
        static let bubblePaddingH: CGFloat = 14.0
        static let bubblePaddingV: CGFloat = 10.0
        
        // Timeline spacing
        static let timelineItemSpacingTight: CGFloat = 2.0
        static let timelineItemSpacingWide: CGFloat = 16.0
        static let timelineDateSpacing: CGFloat = 24.0
        
        // Input bar metrics
        static let inputBarIconSize: CGFloat = 28.0
        static let inputBarCornerRadius: CGFloat = 20.0
        static let inputBarPadding: CGFloat = 12.0
        static let inputBarFieldPaddingH: CGFloat = 12.0
        static let inputBarFieldPaddingV: CGFloat = 8.0
        
        // Balance banner metrics
        static let balanceBannerPaddingH: CGFloat = 16.0
        static let balanceBannerPaddingV: CGFloat = 10.0
        static let balanceBannerIconSize: CGFloat = 14.0
    }
}

// MARK: - Color Extensions

extension Color {
    // NOTE: iMessageBlue and iMessageGray are defined in Models/Domain/SupportingTypes.swift
    // Do not duplicate here to avoid "Invalid redeclaration" errors

    /// Transaction type colors (convenience accessors)
    static var transactionPayment: Color { .wiseBrightGreen }
    static var transactionRequest: Color { .wiseOrange }
    static var transactionSplit: Color { .wiseBlue }
    static var transactionExpense: Color { .wiseAccentBlue }
    
    /// Balance state colors
    static var balancePositive: Color { .wiseBrightGreen }
    static var balanceNegative: Color { .wiseError }
    static var balanceSettled: Color { .wiseSecondaryText }
}

// NOTE: iMessageBubbleShape and iMessageBubbleDirection are defined in
// Views/Components/Shapes/iMessageBubbleShape.swift - do not duplicate here

// NOTE: Theme.Fonts is defined in DesignSystem/Typography.swift - do not duplicate here

// NOTE: Theme.Colors is defined in DesignSystem/Colors.swift - do not duplicate here

// MARK: - Preview Helpers

#Preview("Theme Colors") {
    VStack(spacing: 16) {
        Text("Transaction Colors")
            .font(.headline)
        
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
        
        Text("iMessage Colors")
            .font(.headline)
            .padding(.top)
        
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.iMessageBlue)
                .frame(width: 100, height: 40)
                .overlay(Text("Sent").foregroundColor(.white))
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.iMessageGray)
                .frame(width: 100, height: 40)
                .overlay(Text("Received").foregroundColor(.black))
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
