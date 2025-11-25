//
//  EnhancedEmptyState.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Beautiful empty state components with illustrations
//

import SwiftUI

// MARK: - Enhanced Empty State

struct EnhancedEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    let illustrationColor: Color

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        illustrationColor: Color = .wiseForestGreen
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
        self.illustrationColor = illustrationColor
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                // Background circles for depth
                Circle()
                    .fill(illustrationColor.opacity(0.05))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(illustrationColor.opacity(0.1))
                    .frame(width: 150, height: 150)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [illustrationColor.opacity(0.8), illustrationColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 32)

            // Text Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.spotifyHeadingLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.light()
                    action()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))

                        Text(actionTitle)
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(illustrationColor)
                    .cornerRadius(12)
                    .shadow(color: illustrationColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleOnTap()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State Variants

struct EmptyPeopleState: View {
    let onAddPerson: () -> Void

    var body: some View {
        EnhancedEmptyState(
            icon: "person.2.fill",
            title: "No People Yet",
            subtitle: "Add friends, family, or colleagues to start tracking shared expenses and balances",
            actionTitle: "Add Person",
            action: onAddPerson,
            illustrationColor: .wiseForestGreen
        )
    }
}

struct EmptyGroupsState: View {
    let onAddGroup: () -> Void

    var body: some View {
        EnhancedEmptyState(
            icon: "person.3.fill",
            title: "No Groups Yet",
            subtitle: "Create groups for trips, events, or shared living to split expenses easily",
            actionTitle: "Create Group",
            action: onAddGroup,
            illustrationColor: .wiseAccentBlue
        )
    }
}

struct EmptySubscriptionsState: View {
    let onAddSubscription: () -> Void

    var body: some View {
        EnhancedEmptyState(
            icon: "rectangle.stack.badge.plus",
            title: "No Subscriptions",
            subtitle: "Track your monthly subscriptions and never miss a renewal. Add your first one to get started!",
            actionTitle: "Add Subscription",
            action: onAddSubscription,
            illustrationColor: .wiseAccentOrange
        )
    }
}

struct EmptySharedSubscriptionsState: View {
    var body: some View {
        EnhancedEmptyState(
            icon: "person.2.crop.square.stack",
            title: "No Shared Subscriptions",
            subtitle: "Share subscriptions with friends and family to split costs and save money together",
            illustrationColor: .wiseAccentBlue
        )
    }
}

struct EmptyTransactionsState: View {
    var body: some View {
        EnhancedEmptyState(
            icon: "list.bullet.rectangle",
            title: "No Transactions",
            subtitle: "Your transaction history will appear here once you start adding expenses",
            illustrationColor: .wiseSecondaryText
        )
    }
}

// Page 2: Enhanced Feed Empty State with Quick Actions
struct EnhancedFeedEmptyState: View {
    let onAddTransaction: () -> Void
    let onAddSampleData: (() -> Void)?
    let isFiltered: Bool
    let filterSummary: String?

    init(
        onAddTransaction: @escaping () -> Void,
        onAddSampleData: (() -> Void)? = nil,
        isFiltered: Bool = false,
        filterSummary: String? = nil
    ) {
        self.onAddTransaction = onAddTransaction
        self.onAddSampleData = onAddSampleData
        self.isFiltered = isFiltered
        self.filterSummary = filterSummary
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.wiseForestGreen.opacity(0.05))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color.wiseForestGreen.opacity(0.1))
                    .frame(width: 150, height: 150)

                Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle" : "list.bullet.rectangle.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.wiseForestGreen.opacity(0.8), Color.wiseForestGreen.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 32)

            // Text Content
            VStack(spacing: 12) {
                Text(isFiltered ? "No Matching Transactions" : "Start Tracking Expenses")
                    .font(.spotifyHeadingLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryText)
                    .multilineTextAlignment(.center)

                if isFiltered, let summary = filterSummary {
                    Text(summary)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Text("Add your first transaction to start managing your finances and tracking your spending")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)

            // Quick Action Buttons
            if !isFiltered {
                VStack(spacing: 12) {
                    // Primary Action: Add Transaction
                    Button(action: {
                        HapticManager.shared.medium()
                        onAddTransaction()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))

                            Text("Add First Transaction")
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                        .shadow(color: Color.wiseForestGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    // Secondary Actions
                    HStack(spacing: 12) {
                        // Add Sample Data (if provided)
                        if let onAddSampleData = onAddSampleData {
                            Button(action: {
                                HapticManager.shared.light()
                                onAddSampleData()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 14))

                                    Text("Sample Data")
                                        .font(.spotifyLabelMedium)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.wiseBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.wiseBlue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyExpensesState: View {
    var body: some View {
        EnhancedEmptyState(
            icon: "doc.text.magnifyingglass",
            title: "No Expenses",
            subtitle: "This group doesn't have any expenses yet. Add one to start tracking!",
            illustrationColor: .wiseSecondaryText
        )
    }
}

struct EmptyGroupMembersState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))

            Text("No members in this group")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(40)
    }
}

struct EmptyBalancesState: View {
    var body: some View {
        EnhancedEmptyState(
            icon: "chart.bar.doc.horizontal",
            title: "All Settled Up!",
            subtitle: "You don't owe anyone, and no one owes you. Great job keeping your finances balanced!",
            illustrationColor: .wiseBrightGreen
        )
    }
}

struct EmptyNotificationsState: View {
    var body: some View {
        EnhancedEmptyState(
            icon: "bell.slash",
            title: "No Notifications",
            subtitle: "You're all caught up! Notifications for reminders and renewals will appear here",
            illustrationColor: .wiseAccentBlue
        )
    }
}

// MARK: - Previews

#Preview("Empty People") {
    EmptyPeopleState(onAddPerson: {})
        .background(Color.wiseBackground)
}

#Preview("Empty Groups") {
    EmptyGroupsState(onAddGroup: {})
        .background(Color.wiseBackground)
}

#Preview("Empty Subscriptions") {
    EmptySubscriptionsState(onAddSubscription: {})
        .background(Color.wiseBackground)
}

#Preview("Empty Expenses") {
    EmptyExpensesState()
        .background(Color.wiseBackground)
}

#Preview("Empty Balances") {
    EmptyBalancesState()
        .background(Color.wiseBackground)
}
