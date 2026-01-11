//
//  CompactGroupHeader.swift
//  Swiff IOS
//
//  Professional compact header for group/person conversation view
//  Uses BaseConversationHeader for consistent styling
//  Enhanced with balance information and better visual hierarchy
//

import SwiftUI

struct CompactGroupHeader: View {
    let group: Group
    let members: [Person]
    var balance: ConversationBalance?
    var onBack: (() -> Void)?
    var onInfo: (() -> Void)?
    
    @State private var showBalanceDetail: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            BaseConversationHeader(
                onBack: onBack,
                leading: {
                    UnifiedEmojiCircle(
                        emoji: group.emoji,
                        backgroundColor: .clear,
                        size: Theme.Metrics.avatarCompact
                    )
                },
                title: {
                    HeaderTitleView(
                        title: group.name,
                        subtitle: balanceSubtitle
                    )
                },
                trailing: {
                    if let onInfo = onInfo {
                        Button(action: onInfo) {
                            Image(systemName: "info.circle")
                                .iconActionButtonStyle(color: .wiseForestGreen)
                        }
                        .accessibilityLabel("Group info")
                    }
                }
            )
            
            // Balance banner (if available)
            if let balance = balance {
                ConversationBalanceBanner(balance: balance)
            }
        }
    }
    
    private var balanceSubtitle: String {
        if let balance = balance {
            return balance.formattedBalance
        } else {
            return "\(members.count) member\(members.count == 1 ? "" : "s")"
        }
    }
}

// MARK: - Conversation Balance

/// Balance information for conversation header
struct ConversationBalance {
    let amount: Double
    let type: BalanceType
    
    enum BalanceType {
        case youOwe     // You owe them
        case theyOwe    // They owe you
        case settled    // All settled
    }
    
    var formattedBalance: String {
        let formattedAmount = abs(amount).asCurrency

        switch type {
        case .youOwe:
            return "You owe \(formattedAmount)"
        case .theyOwe:
            return "You are owed \(formattedAmount)"
        case .settled:
            return "All settled up"
        }
    }
    
    var color: Color {
        switch type {
        case .youOwe: return .wiseError
        case .theyOwe: return .wiseBrightGreen
        case .settled: return .wiseSecondaryText
        }
    }
}

// MARK: - Balance Banner

/// Subtle balance banner below header
struct ConversationBalanceBanner: View {
    let balance: ConversationBalance
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: balance.type == .settled ? "checkmark.circle.fill" : "dollarsign.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(balance.color)
            
            Text(balance.formattedBalance)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(balance.color)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(balance.color.opacity(0.08))
    }
}

