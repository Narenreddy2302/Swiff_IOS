//
//  ActivityComponents.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Recent Group Activity Section
struct RecentGroupActivitySection: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAllActivity = false
    @State private var isInitialLoad = true

    // Activity item for sorting and display
    struct ActivityItem: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
        let activityType: String
        let amount: String
        let date: Date
        let avatarColor: Color
        let personId: UUID?  // Track if this is a person activity
        let groupId: UUID?   // Track if this is a group activity
    }

    var recentActivities: [ActivityItem] {
        dataManager.computeActivities(limit: 8)
    }

    /// Refresh activities with visual feedback
    private func refreshActivities() {
        HapticManager.shared.pullToRefresh()
        withAnimation(.easeOut(duration: 0.15)) {
            isInitialLoad = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                isInitialLoad = false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent activity")
                    .fontWeight(.bold)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Button(action: refreshActivities) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .accessibilityLabel("Refresh activities")

                Button("See all") {
                    showingAllActivity = true
                }
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.brandPrimary)
            }

            if isInitialLoad {
                // Skeleton loading state
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonFriendActivityCard()
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .onAppear {
                    // Simulate brief loading, then show actual content
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isInitialLoad = false
                        }
                    }
                }
            } else if recentActivities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .pulseAnimation(isPulsing: true, scale: 1.08)

                    Text("No recent activity")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("Add people and groups to see activity here")
                        .font(Theme.Fonts.captionMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(Array(recentActivities.enumerated()), id: \.element.id) { index, activity in
                            if let personId = activity.personId,
                                let person = dataManager.people.first(where: { $0.id == personId })
                            {
                                // Person activity - navigate to person detail
                                NavigationLink(destination: PersonDetailView(personId: person.id)) {
                                    FriendActivityCard(
                                        friendMemoji: activity.emoji,
                                        friendName: activity.name,
                                        activityType: activity.activityType,
                                        amount: activity.amount,
                                        timeAgo: activity.date.timeAgoCompact,
                                        avatarColor: activity.avatarColor
                                    )
                                }
                                .buttonStyle(.haptic)
                                .cardEntry(delay: Double(index) * 0.05)
                            } else if let groupId = activity.groupId {
                                // Group activity - navigate to group detail
                                NavigationLink(destination: GroupDetailView(groupId: groupId)) {
                                    FriendActivityCard(
                                        friendMemoji: activity.emoji,
                                        friendName: activity.name,
                                        activityType: activity.activityType,
                                        amount: activity.amount,
                                        timeAgo: activity.date.timeAgoCompact,
                                        avatarColor: activity.avatarColor
                                    )
                                }
                                .buttonStyle(.haptic)
                                .cardEntry(delay: Double(index) * 0.05)
                            } else {
                                // Unknown activity type - no navigation
                                FriendActivityCard(
                                    friendMemoji: activity.emoji,
                                    friendName: activity.name,
                                    activityType: activity.activityType,
                                    amount: activity.amount,
                                    timeAgo: activity.date.timeAgoCompact,
                                    avatarColor: activity.avatarColor
                                )
                                .cardEntry(delay: Double(index) * 0.05)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Recent activity, \(recentActivities.count) items")
                .accessibilityHint("Swipe left or right to browse activities")
            }
        }
        .sheet(isPresented: $showingAllActivity) {
            AllActivityView()
        }
    }
}

// MARK: - All Activity View
struct AllActivityView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    var allActivities: [RecentGroupActivitySection.ActivityItem] {
        dataManager.computeActivities()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if allActivities.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()

                            Image(systemName: "person.2.slash")
                                .font(.system(size: 64))
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))

                            Text("No activity yet")
                                .font(Theme.Fonts.headerMedium)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text("Add people and groups to see activity here")
                                .font(Theme.Fonts.bodyMedium)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(allActivities) { activity in
                            HStack(spacing: 16) {
                                // Avatar
                                Circle()
                                    .fill(activity.avatarColor.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(activity.emoji)
                                            .font(.system(size: 24))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(activity.name)
                                        .font(Theme.Fonts.bodyMedium)
                                        .foregroundColor(Theme.Colors.textPrimary)

                                    Text(activity.activityType)
                                        .font(Theme.Fonts.captionMedium)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    if activity.amount != "$0.00" {
                                        Text(activity.amount)
                                            .font(Theme.Fonts.numberMedium)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                    }

                                    Text(activity.date.timeAgoCompact)
                                        .font(Theme.Fonts.captionMedium)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
            }
            .background(Theme.Colors.background)
            .navigationTitle("All Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Friend Activity Card
struct FriendActivityCard: View {
    let friendMemoji: String
    let friendName: String
    let activityType: String
    let amount: String
    let timeAgo: String
    let avatarColor: Color

    // Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var minCardWidth: CGFloat = 80
    @ScaledMetric(relativeTo: .body) private var maxCardWidth: CGFloat = 100
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 48
    @ScaledMetric(relativeTo: .caption) private var indicatorSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var emojiSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 8) {
            // Friend/Group Avatar with Memoji and activity indicator
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [avatarColor.opacity(0.2), avatarColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Text(friendMemoji)
                            .font(.system(size: emojiSize))
                    )

                // Activity indicator (small dot)
                Circle()
                    .fill(getActivityColor())
                    .frame(width: indicatorSize, height: indicatorSize)
                    .offset(x: avatarSize * 0.375, y: -avatarSize * 0.375)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.cardBackground, lineWidth: 2)
                            .frame(width: indicatorSize, height: indicatorSize)
                            .offset(x: avatarSize * 0.375, y: -avatarSize * 0.375)
                    )
            }

            // Activity details
            VStack(spacing: 2) {
                if amount != "$0.00" {
                    Text(amount)
                        .font(Theme.Fonts.numberMedium)
                        .foregroundColor(Theme.Colors.textPrimary)
                }

                Text(activityType)
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Text(timeAgo)
                    .font(Theme.Fonts.captionMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .frame(minWidth: minCardWidth, maxWidth: maxCardWidth)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }

    // Accessibility description for VoiceOver
    private var accessibilityDescription: String {
        let amountPart = amount != "$0.00" ? "\(amount), " : ""
        return "\(friendName), \(amountPart)\(activityType), \(timeAgo)"
    }

    // Activity indicator color based on type
    private func getActivityColor() -> Color {
        switch activityType {
        case "owes you", "paid you", "settled up", "settled":
            return Theme.Colors.brandPrimary  // Green - positive for user
        case "you owe", "requested":
            return Theme.Colors.brandAccent   // Orange - user owes money
        case "added bill", "new expense", "split bill":
            return Theme.Colors.brandSecondary
        case "joined group":
            return Theme.Colors.brandSecondary
        default:
            return Theme.Colors.textSecondary
        }
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter: ActivityFilter = .all
    @State private var showingFilterSheet = false
    @State private var selectedTransaction: Transaction?

    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case expenses = "Expenses"
        case income = "Income"
        case recurring = "Recurring"
    }

    var recentTransactions: [Transaction] {
        var filtered = dataManager.transactions

        switch selectedFilter {
        case .all:
            break
        case .expenses:
            filtered = filtered.filter { $0.isExpense }
        case .income:
            filtered = filtered.filter { !$0.isExpense }
        case .recurring:
            filtered = filtered.filter { $0.isRecurring }
        }

        return Array(
            filtered
                .sorted(by: { $0.date > $1.date })
                .prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(Theme.Fonts.headerLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button(action: { showingFilterSheet = true }) {
                    HStack(spacing: 4) {
                        Text(selectedFilter.rawValue)
                            .font(Theme.Fonts.labelMedium)
                        Image(systemName: "chevron.down")
                            .font(Theme.Fonts.captionMedium)
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.border)
                    .clipShape(Capsule())
                }
            }

            // Recent transactions
            if recentTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))

                    Text("No transactions yet")
                        .font(Theme.Fonts.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, transaction in
                        FeedTransactionRow(
                            transaction: transaction,
                            isLastInGroup: index == recentTransactions.count - 1,
                            onTap: {
                                selectedTransaction = transaction
                                HapticManager.shared.light()
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            ActivityFilterSheet(selectedFilter: $selectedFilter, isPresented: $showingFilterSheet)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailSheet(transaction: transaction)
                .environmentObject(dataManager)
        }
    }
}

// MARK: - Activity Filter Sheet
struct ActivityFilterSheet: View {
    @Binding var selectedFilter: RecentActivitySection.ActivityFilter
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(RecentActivitySection.ActivityFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        isPresented = false
                    }) {
                        HStack {
                            Text(filter.rawValue)
                                .font(Theme.Fonts.bodyMedium)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.brandPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Transaction Item Row
@available(*, deprecated, message: "Use UnifiedListRowV2 instead")
struct TransactionItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let isExpense: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon (48x48)
            UnifiedIconCircle(
                icon: icon,
                color: iconColor,
                size: 48,
                iconSize: 20
            )

            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Amount - Green for income, default for expense
            Text(amount)
                .font(Theme.Fonts.numberMedium)
                .foregroundColor(isExpense ? Theme.Colors.textPrimary : Theme.Colors.brandPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#Preview("Activity Cards - Different States") {
    HStack(spacing: 12) {
        FriendActivityCard(
            friendMemoji: "😊",
            friendName: "John",
            activityType: "owes you",
            amount: "$25.00",
            timeAgo: "2d ago",
            avatarColor: Theme.Colors.brandPrimary
        )

        FriendActivityCard(
            friendMemoji: "🎉",
            friendName: "Sarah",
            activityType: "you owe",
            amount: "$42.50",
            timeAgo: "1w ago",
            avatarColor: Theme.Colors.brandAccent
        )

        FriendActivityCard(
            friendMemoji: "🏠",
            friendName: "Roommates",
            activityType: "split bill",
            amount: "$120.00",
            timeAgo: "3d ago",
            avatarColor: Theme.Colors.brandSecondary
        )
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Skeleton Loading Cards") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonFriendActivityCard()
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}

#Preview("Recent Activity Section") {
    RecentGroupActivitySection()
        .environmentObject(DataManager.shared)
        .padding()
        .background(Theme.Colors.background)
}
