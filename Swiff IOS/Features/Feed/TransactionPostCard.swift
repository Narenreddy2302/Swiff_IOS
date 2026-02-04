//
//  TransactionPostCard.swift
//  Swiff IOS
//
//  Twitter-style transaction card with professional layout
//  Features: Avatar, content, amount, engagement bar
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - Transaction Post Card

/// A Twitter-like card for displaying transactions in the feed
/// Includes avatar, transaction details, amount, and engagement actions
struct TransactionPostCard: View {
    
    // MARK: - Properties
    
    let transaction: FeedTransaction
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Main Content Row
                HStack(alignment: .top, spacing: 12) {
                    // Avatar
                    avatarSection
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        // Header: Name, handle, time
                        headerSection
                        
                        // Transaction Description
                        descriptionSection
                        
                        // Amount Card
                        amountCard
                        
                        // Participants (if split)
                        if !transaction.participants.isEmpty {
                            participantsSection
                        }
                        
                        // Engagement Bar
                        engagementBar
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.Colors.background)
            .contentShape(Rectangle())
        }
        .buttonStyle(FeedCardButtonStyle())
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        ZStack {
            Circle()
                .fill(transaction.avatarColor.opacity(0.15))
                .frame(width: 48, height: 48)
            
            Text(transaction.initials)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(transaction.avatarColor)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 4) {
            // Name
            Text(transaction.personName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Verified badge (for trusted contacts)
            if transaction.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.brandPrimary)
            }
            
            // Handle / Category
            Text("· \(transaction.category)")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Spacer()
            
            // Timestamp
            Text(transaction.timeAgo)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textTertiary)
            
            // More Options
            Button(action: {
                HapticManager.shared.light()
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        Text(transaction.description)
            .font(.system(size: 15))
            .foregroundColor(Theme.Colors.textPrimary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Amount Card
    
    private var amountCard: some View {
        HStack(spacing: 12) {
            // Transaction Type Icon
            ZStack {
                Circle()
                    .fill(transaction.amountColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.typeIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(transaction.amountColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Amount
                Text(transaction.formattedAmount)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(transaction.amountColor)
                
                // Status
                Text(transaction.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Split Method Badge
            if let splitMethod = transaction.splitMethod {
                Text(splitMethod)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        HStack(spacing: 8) {
            // Participant avatars (stacked)
            HStack(spacing: -8) {
                ForEach(Array(transaction.participants.prefix(4).enumerated()), id: \.offset) { index, participant in
                    Circle()
                        .fill(participantColor(for: index))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(String(participant.prefix(1)))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.background, lineWidth: 2)
                        )
                        .zIndex(Double(10 - index))
                }
                
                if transaction.participants.count > 4 {
                    Circle()
                        .fill(Theme.Colors.textTertiary)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("+\(transaction.participants.count - 4)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.background, lineWidth: 2)
                        )
                }
            }
            
            Text("Split with \(transaction.participants.count) people")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Engagement Bar
    
    private var engagementBar: some View {
        HStack(spacing: 0) {
            // Comment
            EngagementButton(
                icon: "bubble.left",
                count: transaction.commentCount,
                color: Theme.Colors.textSecondary,
                action: onComment
            )
            
            Spacer()
            
            // Like / Heart
            EngagementButton(
                icon: transaction.isLiked ? "heart.fill" : "heart",
                count: transaction.likeCount,
                color: transaction.isLiked ? .red : Theme.Colors.textSecondary,
                isActive: transaction.isLiked,
                action: onLike
            )
            
            Spacer()
            
            // Share
            EngagementButton(
                icon: "square.and.arrow.up",
                count: nil,
                color: Theme.Colors.textSecondary,
                action: onShare
            )
            
            Spacer()
            
            // Bookmark
            EngagementButton(
                icon: "bookmark",
                count: nil,
                color: Theme.Colors.textSecondary,
                action: { HapticManager.shared.light() }
            )
        }
        .padding(.top, 4)
    }
    
    // MARK: - Helpers
    
    private func participantColor(for index: Int) -> Color {
        let colors: [Color] = [
            Theme.Colors.brandPrimary,
            Theme.Colors.success,
            Theme.Colors.info,
            Theme.Colors.warning
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Engagement Button

struct EngagementButton: View {
    let icon: String
    let count: Int?
    let color: Color
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13))
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
    }
}

// MARK: - Feed Card Button Style

struct FeedCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Theme.Colors.cardBackground.opacity(0.5)
                    : Color.clear
            )
    }
}

// MARK: - Feed Transaction Model

struct FeedTransaction: Identifiable {
    let id: UUID
    let personName: String
    let initials: String
    let avatarColor: Color
    let isVerified: Bool
    let category: String
    let description: String
    let amount: Double
    let balanceType: BalanceType
    let isSettled: Bool
    let splitMethod: String?
    let participants: [String]
    let timestamp: Date
    var isLiked: Bool
    var likeCount: Int
    var commentCount: Int
    
    enum BalanceType {
        case youOwe
        case theyOwe
        case neutral
    }
    
    // MARK: - Computed Properties
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
    
    var amountColor: Color {
        if isSettled {
            return Theme.Colors.textSecondary
        }
        switch balanceType {
        case .youOwe:
            return Theme.Colors.amountNegative
        case .theyOwe:
            return Theme.Colors.amountPositive
        case .neutral:
            return Theme.Colors.textSecondary
        }
    }
    
    var typeIcon: String {
        if isSettled {
            return "checkmark.circle.fill"
        }
        switch balanceType {
        case .youOwe: return "arrow.up.circle.fill"
        case .theyOwe: return "arrow.down.circle.fill"
        case .neutral: return "equal.circle.fill"
        }
    }
    
    var statusText: String {
        if isSettled {
            return "Settled"
        }
        switch balanceType {
        case .youOwe: return "You owe"
        case .theyOwe: return "Owes you"
        case .neutral: return "Even"
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // MARK: - Mock Data
    
    static var mockData: [FeedTransaction] {
        [
            FeedTransaction(
                id: UUID(),
                personName: "Sarah Chen",
                initials: "SC",
                avatarColor: Theme.Colors.brandPrimary,
                isVerified: true,
                category: "Dinner",
                description: "Sushi dinner at Nobu - amazing omakase! 🍣 Thanks for organizing",
                amount: 156.50,
                balanceType: .theyOwe,
                isSettled: false,
                splitMethod: "Equally",
                participants: ["You", "Sarah", "Mike", "Lisa"],
                timestamp: Date().addingTimeInterval(-3600),
                isLiked: false,
                likeCount: 3,
                commentCount: 2
            ),
            FeedTransaction(
                id: UUID(),
                personName: "Alex Kim",
                initials: "AK",
                avatarColor: Theme.Colors.info,
                isVerified: false,
                category: "Utilities",
                description: "Monthly electricity bill - January 2026",
                amount: 89.00,
                balanceType: .youOwe,
                isSettled: false,
                splitMethod: nil,
                participants: [],
                timestamp: Date().addingTimeInterval(-86400),
                isLiked: true,
                likeCount: 1,
                commentCount: 0
            ),
            FeedTransaction(
                id: UUID(),
                personName: "Jordan Lee",
                initials: "JL",
                avatarColor: Theme.Colors.success,
                isVerified: true,
                category: "Travel",
                description: "Airbnb for the ski trip weekend. Split 5 ways - what an amazing trip! ⛷️",
                amount: 320.00,
                balanceType: .theyOwe,
                isSettled: true,
                splitMethod: "Equally",
                participants: ["You", "Jordan", "Sam", "Chris", "Pat"],
                timestamp: Date().addingTimeInterval(-172800),
                isLiked: true,
                likeCount: 8,
                commentCount: 5
            ),
            FeedTransaction(
                id: UUID(),
                personName: "Mike Johnson",
                initials: "MJ",
                avatarColor: Theme.Colors.warning,
                isVerified: false,
                category: "Food",
                description: "Coffee run ☕",
                amount: 12.50,
                balanceType: .youOwe,
                isSettled: false,
                splitMethod: nil,
                participants: [],
                timestamp: Date().addingTimeInterval(-259200),
                isLiked: false,
                likeCount: 0,
                commentCount: 1
            )
        ]
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(FeedTransaction.mockData) { transaction in
                TransactionPostCard(
                    transaction: transaction,
                    onLike: {},
                    onComment: {},
                    onShare: {},
                    onTap: {}
                )
                Divider()
            }
        }
    }
    .background(Theme.Colors.background)
}
