//
//  TwitterFeedView.swift
//  Swiff IOS
//
//  Twitter-style transaction feed with professional card layout
//  Features: Pull-to-refresh, infinite scroll, engagement actions
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - Twitter Feed View

/// Main feed view displaying transactions in a Twitter-like card format
/// Replaces traditional iMessage-style conversation for a more social feel
struct TwitterFeedView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var feedService = FeedDataService.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isRefreshing = false
    @State private var showingCompose = false
    @State private var selectedTransaction: FeedTransaction?
    @State private var animateCards = false
    
    // Filter state
    @State private var selectedFilter: FeedFilter = .all
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Content
            VStack(spacing: 0) {
                // Feed Header
                feedHeader
                
                // Filter Tabs
                filterTabs
                
                // Transaction Feed
                feedContent
            }
            .background(Theme.Colors.background)
            
            // Floating Compose Button
            composeButton
        }
        .onAppear {
            loadTransactions()
            animateEntrance()
        }
        .sheet(isPresented: $showingCompose) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingCompose,
                onTransactionAdded: { _ in
                    loadTransactions()
                }
            )
            .environmentObject(dataManager)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailSheet(transaction: transaction)
        }
    }
    
    // MARK: - Feed Header
    
    private var feedHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            // Profile Avatar
            ProfileAvatarButton()
            
            Spacer()
            
            // Logo
            Text("Swiff.")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(Theme.Colors.brandPrimary)
            
            Spacer()
            
            // Notifications
            Button(action: { HapticManager.shared.light() }) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                            HapticManager.shared.selection()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Theme.Colors.background)
        .overlay(
            Divider()
                .background(Theme.Colors.border),
            alignment: .bottom
        )
    }
    
    // MARK: - Feed Content
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Pull to refresh indicator
                if isRefreshing {
                    ProgressView()
                        .padding(.vertical, 20)
                }
                
                // Transaction Posts
                ForEach(Array(filteredTransactions.enumerated()), id: \.element.id) { index, transaction in
                    TransactionPostCard(
                        transaction: transaction,
                        onLike: { handleLike(transaction) },
                        onComment: { handleComment(transaction) },
                        onShare: { handleShare(transaction) },
                        onTap: { selectedTransaction = transaction }
                    )
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * 0.05),
                        value: animateCards
                    )
                    
                    // Divider between posts
                    Divider()
                        .background(Theme.Colors.border)
                }
                
                // Load more indicator
                if !feedService.feedTransactions.isEmpty {
                    loadMoreIndicator
                }
            }
        }
        .refreshable {
            await refreshFeed()
        }
    }
    
    // MARK: - Compose Button
    
    private var composeButton: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            showingCompose = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Colors.textOnPrimary)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.brandPrimary)
                .clipShape(Circle())
                .shadow(color: Theme.Colors.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Load More
    
    private var loadMoreIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 20)
            Spacer()
        }
        .onAppear {
            loadMoreTransactions()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTransactions: [FeedTransaction] {
        switch selectedFilter {
        case .all:
            return feedService.feedTransactions
        case .youOwe:
            return feedService.feedTransactions.filter { $0.balanceType == .youOwe }
        case .theyOwe:
            return feedService.feedTransactions.filter { $0.balanceType == .theyOwe }
        case .settled:
            return feedService.feedTransactions.filter { $0.isSettled }
        }
    }
    
    // MARK: - Actions
    
    private func loadTransactions() {
        // Load from FeedDataService (which pulls from DataManager)
        feedService.loadTransactions()
    }
    
    private func animateEntrance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                animateCards = true
            }
        }
    }
    
    private func refreshFeed() async {
        isRefreshing = true
        await feedService.refresh()
        isRefreshing = false
    }
    
    private func loadMoreTransactions() {
        // Implement pagination
    }
    
    private func handleLike(_ transaction: FeedTransaction) {
        HapticManager.shared.impact(.light)
        // Toggle like state
        if let index = feedService.feedTransactions.firstIndex(where: { $0.id == transaction.id }) {
            feedService.feedTransactions[index].isLiked.toggle()
            feedService.feedTransactions[index].likeCount += feedService.feedTransactions[index].isLiked ? 1 : -1
        }
    }
    
    private func handleComment(_ transaction: FeedTransaction) {
        HapticManager.shared.light()
        selectedTransaction = transaction
    }
    
    private func handleShare(_ transaction: FeedTransaction) {
        HapticManager.shared.light()
        // Show share sheet
    }
}

// MARK: - Feed Filter

enum FeedFilter: CaseIterable {
    case all
    case youOwe
    case theyOwe
    case settled
    
    var title: String {
        switch self {
        case .all: return "All"
        case .youOwe: return "You Owe"
        case .theyOwe: return "They Owe"
        case .settled: return "Settled"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .youOwe: return "arrow.up.circle"
        case .theyOwe: return "arrow.down.circle"
        case .settled: return "checkmark.circle"
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Theme.Colors.brandPrimary
                    : Theme.Colors.cardBackground
            )
            .foregroundColor(
                isSelected
                    ? Theme.Colors.textOnPrimary
                    : Theme.Colors.textSecondary
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Theme.Colors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
    }
}

// MARK: - Profile Avatar Button

struct ProfileAvatarButton: View {
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            // Navigate to profile
        }) {
            AvatarView(
                avatarType: profileManager.profile.avatarType,
                size: .small,
                style: .solid
            )
        }
    }
}

// MARK: - Preview

#Preview {
    TwitterFeedView()
        .environmentObject(DataManager.shared)
}
