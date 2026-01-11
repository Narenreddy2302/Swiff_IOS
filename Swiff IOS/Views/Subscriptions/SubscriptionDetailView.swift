//
//  SubscriptionDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for subscription management
//

import Combine
import SwiftUI

// MARK: - Subscription Conversation Tab

enum SubscriptionConversationTab: String, ConversationTabProtocol, CaseIterable {
    case timeline = "Timeline"
    case details = "Details"
}

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let subscriptionId: UUID
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCancelAlert = false
    @State private var showingPauseAlert = false
    @State private var showingPriceHistoryChart = false

    // Tab selection
    @State private var selectedTab: SubscriptionConversationTab = .timeline

    // Timeline events
    @State private var events: [SubscriptionEvent] = []

    // AGENT 9: Price history tracking
    @State private var priceHistory: [PriceChange] = []
    @State private var showPriceIncreaseBadge = false

    // New sheets for Quick Actions

    @State private var showingUsageTrackingSheet = false
    @State private var showingReminderSheet = false
    @State private var showingShareSheet = false
    @State private var isCancellationExpanded = false

    var subscription: Subscription? {
        dataManager.subscriptions.first { $0.id == subscriptionId }
    }

    var sharedPeople: [Person] {
        guard let subscription = subscription, subscription.isShared else { return [] }
        return subscription.sharedWith.compactMap { personId in
            dataManager.people.first { $0.id == personId }
        }
    }

    // MARK: - Computed Properties for Timeline

    // Get subscription alert if any
    private var subscriptionAlert: SubscriptionAlertType? {
        guard let subscription = subscription else { return nil }

        // Check trial ending
        if subscription.isFreeTrial, let trialEnd = subscription.trialEndDate {
            let daysLeft =
                Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
            if daysLeft <= 7 && daysLeft >= 0 {
                return .trialEnding(daysLeft: daysLeft, priceAfter: subscription.price)
            }
        }

        // Check payment upcoming
        let nextBilling = subscription.nextBillingDate
        let daysUntil =
            Calendar.current.dateComponents([.day], from: Date(), to: nextBilling).day ?? 0
        if daysUntil <= 3 && daysUntil >= 0 {
            return .paymentUpcoming(daysUntil: daysUntil, amount: subscription.price)
        }

        // Check if paused
        if !subscription.isActive && subscription.cancellationDate == nil {
            return .subscriptionPaused
        }

        return nil
    }

    var statusColor: Color {
        guard let subscription = subscription else { return .wiseSecondaryText }
        if subscription.cancellationDate != nil {
            return .wiseError
        } else if !subscription.isActive {
            return .orange
        } else {
            return .wiseBrightGreen
        }
    }

    var statusText: String {
        guard let subscription = subscription else { return "Unknown" }
        if subscription.cancellationDate != nil {
            return "Cancelled"
        } else if !subscription.isActive {
            return "Paused"
        } else {
            return "Active"
        }
    }

    // Helper view to avoid type-checking timeout
    @ViewBuilder
    private func iconView(
        subscription: Subscription,
        subscriptionColor: Color,
        gradientColors: [Color]
    ) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: subscription.icon)
                    .font(.system(size: 48))
                    .foregroundColor(subscriptionColor)
            )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let subscription = subscription {
                // Conversation-style header
                SubscriptionConversationHeader(
                    subscription: subscription,
                    onBack: { dismiss() },
                    onEdit: { showingEditSheet = true }
                )

                // Tab selector with vertical spacing
                PillSegmentedControl(selectedTab: $selectedTab)
                    .padding(.vertical, 12)

                Divider()

                // Tab content
                TabView(selection: $selectedTab) {
                    timelineTab(subscription: subscription)
                        .tag(SubscriptionConversationTab.timeline)

                    detailsTab(subscription: subscription)
                        .tag(SubscriptionConversationTab.details)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                subscriptionNotFoundView
            }
        }
        .background(Color.wiseBackground)
        .navigationBarHidden(true)
        .hidesTabBar()
        .observeEntity(subscriptionId, type: .subscription, dataManager: dataManager)
        .sheet(isPresented: $showingEditSheet) {
            if let subscription = subscription {
                EditSubscriptionSheet(
                    subscription: subscription,
                    onSubscriptionUpdated: {
                        showingEditSheet = false
                    })
            }
        }
        .alert("Delete Subscription?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSubscription()
            }
        } message: {
            if let subscription = subscription {
                Text(
                    "This will permanently delete '\(subscription.name)'. This action cannot be undone."
                )
            }
        }
        .alert("Cancel Subscription?", isPresented: $showingCancelAlert) {
            Button("Keep", role: .cancel) {}
            Button("Cancel Subscription", role: .destructive) {
                cancelSubscription()
            }
        } message: {
            if let subscription = subscription {
                Text(
                    "This will mark '\(subscription.name)' as cancelled. You can still delete it later if needed."
                )
            }
        }
        .alert("Pause Subscription?", isPresented: $showingPauseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Pause") {
                pauseSubscription()
            }
        } message: {
            Text(
                "This subscription will be paused and won't be included in monthly cost calculations. You can resume it anytime."
            )
        }
        .sheet(isPresented: $showingPriceHistoryChart) {
            if let subscription = subscription {
                NavigationView {
                    PriceHistoryChartView(subscription: subscription)
                        .environmentObject(dataManager)
                }
            }
        }

        .sheet(isPresented: $showingUsageTrackingSheet) {
            if let subscription = subscription {
                UsageTrackingSheet(
                    subscription: subscription,
                    onUsageUpdated: {
                        // Data refreshes automatically via @EnvironmentObject
                    }
                )
                .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingReminderSheet) {
            if let subscription = subscription {
                ReminderSettingsSheet(
                    subscription: subscription,
                    onSettingsSaved: {
                        // Data refreshes automatically via @EnvironmentObject
                    }
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let subscription = subscription {
                ShareSubscriptionSheet(
                    subscription: subscription,
                    showingSheet: $showingShareSheet
                )
                .environmentObject(dataManager)
            }
        }
    }

    // MARK: - Tab Views

    @ViewBuilder
    private func timelineTab(subscription: Subscription) -> some View {
        ZStack(alignment: .bottom) {
            ChatTimelineView(
                groupedItems: SubscriptionEvent.groupByDate(events).map { ($0.date, $0.events) },
                emptyStateConfig: TimelineEmptyStateConfig(
                    icon: "clock.badge.questionmark",
                    title: "No timeline events yet",
                    subtitle: "Events will appear as you use this subscription"
                )
            ) { event in
                switch event.eventType {
                case .billingCharged:
                    ChatBubble(direction: .outgoing, timestamp: event.eventDate) {
                        TransactionBubbleContent(
                            title: event.title,
                            subtitle: event.subtitle,
                            amount: event.amount ?? 0,
                            isExpense: true
                        )
                    }
                case .billingUpcoming:
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(text: event.title, icon: event.eventType.icon)
                    }
                case .usageRecorded:
                    ChatBubble(direction: .outgoing, timestamp: event.eventDate) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(event.title)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                case .priceIncrease, .priceDecrease:
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(text: event.title, icon: event.eventType.icon)
                    }
                case .memberPaid:
                    ChatBubble(direction: .incoming, timestamp: event.eventDate) {
                        PaymentBubbleContent(amount: event.amount ?? 0, note: event.title)
                    }
                default:
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(text: event.title, icon: event.eventType.icon)
                    }
                }
            }
            .background(Color.wiseBackground)
            .onAppear {
                loadPriceHistory()
                loadTimelineEvents(subscription: subscription)
            }

            // Timeline input area
            TimelineInputArea(
                config: TimelineInputAreaConfig(
                    quickActionTitle: "Mark Used",
                    quickActionIcon: "checkmark.square",
                    placeholder: "",
                    showMessageField: false
                ),
                onQuickAction: {
                    markAsUsedToday(subscription: subscription)
                }
            )
        }
    }

    private var timelineEventsList: some View {
        EmptyView() // Deprecated by ChatTimelineView
    }

    private var emptyTimelineView: some View {
        EmptyView() // Deprecated by ChatTimelineView
    }

    @ViewBuilder
    private func detailsTab(subscription: Subscription) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trial Status Section (if trial)
                if subscription.isFreeTrial {
                    trialStatusSection(subscription: subscription)
                }

                // Price increase badge (if recent increase)
                if showPriceIncreaseBadge, let latestIncrease = priceHistory.first,
                    latestIncrease.isIncrease
                {
                    priceIncreaseBadgeSection(priceChange: latestIncrease)
                }

                // NEW: Billing Summary Card (Hero card - replaces Overview + Spending Stats)
                SubscriptionBillingSummaryCard(
                    subscription: subscription
                )

                // Shared cost card (if shared)
                if subscription.isShared && !sharedPeople.isEmpty {
                    SharedSubscriptionCostCard(
                        subscription: subscription,
                        sharedPeople: sharedPeople
                    )
                    .padding(.horizontal, 16)
                }

                // NEW: Quick Actions Section
                SubscriptionQuickActionsSection(
                    subscription: subscription,
                    onPauseResume: {
                        if subscription.isActive {
                            showingPauseAlert = true
                        } else {
                            resumeSubscription()
                        }
                    },
                    onRemind: {
                        showingReminderSheet = true
                    },
                    onUsage: {
                        showingUsageTrackingSheet = true
                    },
                    onWebsite: {
                        openWebsite(subscription: subscription)
                    },
                    onShare: {
                        showingShareSheet = true
                    }
                )

                // Price history section (kept inline)
                if !priceHistory.isEmpty {
                    priceHistorySection(subscription: subscription)
                }

                // Additional Info (simplified, no card wrapper)
                additionalInfoSection(subscription: subscription)

                // Shared With Section (simplified)
                sharedInfoSectionSimplified(subscription: subscription)

                // Cancellation Instructions (collapsible)
                cancellationInfoSection(subscription: subscription)

                // Actions Section (simplified)
                simplifiedActionsSection(subscription: subscription)
            }
            .padding(.top, 16)
        }
        .background(Color.wiseBackground)
        .onAppear {

            loadPriceHistory()
        }
    }

    // MARK: - Helper for opening website
    private func openWebsite(subscription: Subscription) {
        guard let website = subscription.website, !website.isEmpty else { return }
        let urlString = website.hasPrefix("http") ? website : "https://\(website)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - View Components

    // AGENT 8: Trial Status Section
    @ViewBuilder
    private func trialStatusSection(subscription: Subscription) -> some View {
        TrialStatusSection(
            subscription: subscription,
            onConvertNow: {
                convertTrialToPaidNow(subscription: subscription)
            },
            onCancelTrial: {
                showingCancelAlert = true
            }
        )
        .padding(.horizontal, 16)
    }

    // AGENT 9: Price increase badge section
    @ViewBuilder
    private func priceIncreaseBadgeSection(priceChange: PriceChange) -> some View {
        PriceChangeBadge(
            priceChange: priceChange,
            showDismissButton: true,
            onDismiss: {
                withAnimation {
                    showPriceIncreaseBadge = false
                }
            }
        )
        .padding(.horizontal, 16)
    }

    // AGENT 9: Price history section
    @ViewBuilder
    private func priceHistorySection(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)
                Text("Price History")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                Spacer()
            }

            // Recent price changes (max 3)
            VStack(spacing: 0) {
                ForEach(Array(priceHistory.prefix(3).enumerated()), id: \.element.id) {
                    index, change in
                    PriceChangeRow(priceChange: change)

                    if index < priceHistory.prefix(3).count - 1 {
                        AlignedDivider()
                    }
                }
            }

            // View all button
            Button(action: {
                showingPriceHistoryChart = true
            }) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 14))
                    Text("View Price Chart & Full History")
                        .font(.spotifyLabelMedium)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.wiseBlue)
                .cornerRadius(10)
            }

            if priceHistory.count > 3 {
                Text(
                    "\(priceHistory.count - 3) more price change\(priceHistory.count - 3 == 1 ? "" : "s")"
                )
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func overviewCard(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Price and billing
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(subscription.price.asCurrency)
                        .font(.spotifyNumberLarge)
                        .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Billing Cycle")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(subscription.billingCycle.displayName)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }
            }

            Divider()

            // Monthly equivalent
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Cost")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text("\(subscription.monthlyEquivalent.asCurrency)/mo")
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wiseForestGreen)
                }

                Spacer()

                if subscription.isActive {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next Billing")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(subscription.nextBillingDate, style: .date)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
            }

            Divider()

            // Category and payment
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    HStack(spacing: 6) {
                        Image(systemName: subscription.category.icon)
                            .font(.system(size: 14))
                        Text(subscription.category.rawValue)
                            .font(.spotifyBodyMedium)
                    }
                    .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Payment")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(subscription.paymentMethod.rawValue)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func usageTrackingCard(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseForestGreen)
                Text("Usage Tracking")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            // Last used display
            if let lastUsed = subscription.lastUsedDate {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Used")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                        Text(lastUsed, style: .relative)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Uses")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                        Text("\(subscription.usageCount)")
                            .font(.spotifyNumberMedium)
                            .foregroundColor(.wiseForestGreen)
                    }
                }
            }

            // Mark as used button
            Button(action: {
                markAsUsedToday(subscription: subscription)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Mark as Used Today")
                        .font(.spotifyLabelMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.wiseForestGreen)
                .cornerRadius(10)
            }

            // Usage stats if there's data
            if subscription.usageCount > 0, subscription.lastUsedDate != nil {
                Divider()

                let daysSinceCreation =
                    Calendar.current.dateComponents(
                        [.day], from: subscription.createdDate, to: Date()
                    ).day ?? 1
                let usageFrequency =
                    Double(subscription.usageCount) / Double(max(daysSinceCreation, 1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Insights")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.wiseSecondaryText)
                        Text(String(format: "Used %.1f times per day on average", usageFrequency))
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func spendingStatsCard(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Stats")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(subscription.totalSpent.asCurrency)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                if let lastBilling = subscription.lastBillingDate {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Last Billed")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(lastBilling, style: .date)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
            }

            if subscription.isActive {
                Divider()

                // Days until next billing
                let daysUntil =
                    Calendar.current.dateComponents(
                        [.day], from: Date(), to: subscription.nextBillingDate
                    ).day ?? 0
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16))
                        .foregroundColor(.wiseBlue)

                    Text("\(daysUntil) days until next billing")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func detailsSection(subscription: Subscription) -> some View {
        if (subscription.website != nil && !(subscription.website?.isEmpty ?? true))
            || !subscription.notes.isEmpty || subscription.cancellationDate != nil
        {
            VStack(alignment: .leading, spacing: 16) {
                Text("Details")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                if let website = subscription.website, !website.isEmpty {
                    Button(action: {
                        if let url = URL(
                            string: website.hasPrefix("http") ? website : "https://\(website)")
                        {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.wiseBlue)
                            Text(website)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseBlue)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.wiseBlue)
                        }
                    }
                }

                if !subscription.notes.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)

                        Text(subscription.notes)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                    }
                }

                Divider()

                HStack {
                    Text("Created")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text(subscription.createdDate, style: .date)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }

                if let cancelDate = subscription.cancellationDate {
                    Divider()

                    HStack {
                        Text("Cancelled On")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseError)
                        Spacer()
                        Text(cancelDate, style: .date)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseError)
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func sharedInfoSection(subscription: Subscription) -> some View {
        if subscription.isShared && !sharedPeople.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Shared With")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                VStack(spacing: 0) {
                    Text("Split between \(sharedPeople.count + 1) people")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.bottom, 12)

                    if sharedPeople.count > 0 {
                        VStack(spacing: 0) {
                            ForEach(Array(sharedPeople.enumerated()), id: \.element.id) {
                                index, person in
                                sharedPersonRow(person: person, subscription: subscription)

                                if index < sharedPeople.count - 1 {
                                    AlignedDivider()
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Task 5.12: Cancellation Instructions Section
    @ViewBuilder
    private func cancellationInstructionsSection(subscription: Subscription) -> some View {
        if let instructions = subscription.cancellationInstructions, !instructions.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.wiseWarning)
                    Text("How to Cancel")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                    Spacer()

                    // Cancellation difficulty badge
                    if let difficulty = subscription.cancellationDifficulty {
                        HStack(spacing: 4) {
                            Image(systemName: difficulty.icon)
                                .font(.system(size: 12))
                            Text(difficulty.rawValue)
                                .font(.spotifyLabelSmall)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(difficulty.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(difficulty.color.opacity(0.15))
                        .cornerRadius(12)
                    }
                }

                // Instructions text
                Text(instructions)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineSpacing(4)

                // Cancellation deadline if available
                if let deadline = subscription.cancellationDeadline {
                    Divider()

                    HStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseError)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cancellation Deadline")
                                .font(.spotifyLabelSmall)
                                .foregroundColor(.wiseSecondaryText)

                            Text(deadline, style: .date)
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.wiseError)
                        }

                        Spacer()

                        let daysUntilDeadline =
                            Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
                            ?? 0
                        if daysUntilDeadline >= 0 {
                            Text("\(daysUntilDeadline) days left")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseError)
                        }
                    }
                }

                // Website link if available
                if let website = subscription.website, !website.isEmpty {
                    Divider()

                    Button(action: {
                        if let url = URL(
                            string: website.hasPrefix("http") ? website : "https://\(website)")
                        {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "safari.fill")
                                .font(.system(size: 14))
                            Text("Open Website to Cancel")
                                .font(.spotifyLabelMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.wiseBlue)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Simplified Actions Section (NEW)
    @ViewBuilder
    private func simplifiedActionsSection(subscription: Subscription) -> some View {
        VStack(spacing: 12) {
            // Cancel Subscription button (outlined red) - only if active and not already cancelled
            if subscription.isActive && subscription.cancellationDate == nil {
                Button(action: { showingCancelAlert = true }) {
                    Text("Cancel Subscription")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.wiseError, lineWidth: 1)
                        )
                }
            }

            // Delete Subscription button (text only) - always visible
            Button(action: { showingDeleteAlert = true }) {
                Text("Delete Subscription")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Additional Info Section (NEW - simplified, no card wrapper)
    @ViewBuilder
    private func additionalInfoSection(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("Additional Info")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.bottom, 16)

            // Category row with icon
            HStack {
                Text("Category")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: subscription.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hexString: subscription.color))
                    Text(subscription.category.rawValue)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }
            }
            .padding(.vertical, 12)

            AlignedDivider()

            // Payment Method row
            HStack {
                Text("Payment Method")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
                Spacer()
                Text(subscription.paymentMethod.rawValue)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
            }
            .padding(.vertical, 12)

            AlignedDivider()

            // Created Date row
            HStack {
                Text("Created")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
                Spacer()
                Text(subscription.createdDate, style: .date)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
            }
            .padding(.vertical, 12)

            // Website row (if available)
            if let website = subscription.website, !website.isEmpty {
                AlignedDivider()

                Button(action: {
                    openWebsite(subscription: subscription)
                }) {
                    HStack {
                        Text("Website")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(website)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseBlue)
                                .lineLimit(1)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(.wiseBlue)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }

            // Notes row (if not empty)
            if !subscription.notes.isEmpty {
                AlignedDivider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                    Text(subscription.notes)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
            }

            // Cancelled Date row (if cancelled)
            if let cancelDate = subscription.cancellationDate {
                AlignedDivider()

                HStack {
                    Text("Cancelled On")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseError)
                    Spacer()
                    Text(cancelDate, style: .date)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseError)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Shared Info Section Simplified (NEW)
    @ViewBuilder
    private func sharedInfoSectionSimplified(subscription: Subscription) -> some View {
        if subscription.isShared && !sharedPeople.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Header with count badge
                HStack {
                    Text("Shared With")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    // People count badge
                    Text("\(sharedPeople.count + 1) people")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.wiseBorder.opacity(0.5))
                        .cornerRadius(12)
                }

                // Shared people list
                VStack(spacing: 0) {
                    // Owner row (You)
                    sharedPersonRowSelf(subscription: subscription)

                    AlignedDivider()

                    // Other shared people
                    ForEach(Array(sharedPeople.enumerated()), id: \.element.id) { index, person in
                        sharedPersonRow(person: person, subscription: subscription)

                        if index < sharedPeople.count - 1 {
                            AlignedDivider()
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    // Self row for subscription owner
    @ViewBuilder
    private func sharedPersonRowSelf(subscription: Subscription) -> some View {
        HStack(spacing: 14) {
            // "You" avatar
            ZStack {
                Circle()
                    .fill(Color.wiseForestGreen.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseForestGreen)
            }

            // Name
            VStack(alignment: .leading, spacing: 3) {
                Text("You")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Text("Owner")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
            }

            Spacer()

            // Share amount
            Text((subscription.monthlyEquivalent / Double(sharedPeople.count + 1)).asCurrency)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AmountColors.positive)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Cancellation Info Section (NEW - Collapsible)
    @ViewBuilder
    private func cancellationInfoSection(subscription: Subscription) -> some View {
        if let instructions = subscription.cancellationInstructions, !instructions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                DisclosureGroup(
                    isExpanded: $isCancellationExpanded,
                    content: {
                        VStack(alignment: .leading, spacing: 16) {
                            // Instructions text
                            Text(instructions)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .lineSpacing(4)
                                .padding(.top, 12)

                            // Cancellation deadline warning (if available)
                            if let deadline = subscription.cancellationDeadline {
                                cancellationDeadlineWarning(deadline: deadline)
                            }

                            // Open Website button (if available)
                            if let website = subscription.website, !website.isEmpty {
                                Button(action: {
                                    openWebsite(subscription: subscription)
                                }) {
                                    HStack {
                                        Image(systemName: "safari.fill")
                                            .font(.system(size: 14))
                                        Text("Open Website to Cancel")
                                            .font(.spotifyLabelMedium)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.wiseBlue)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    },
                    label: {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.wiseWarning)

                            Text("How to Cancel")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            // Difficulty badge
                            if let difficulty = subscription.cancellationDifficulty {
                                difficultyBadge(difficulty: difficulty)
                            }
                        }
                    }
                )
                .accentColor(.wiseSecondaryText)
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    // Difficulty badge helper
    @ViewBuilder
    private func difficultyBadge(difficulty: CancellationDifficulty) -> some View {
        HStack(spacing: 4) {
            Image(systemName: difficulty.icon)
                .font(.system(size: 12))
            Text(difficulty.rawValue)
                .font(.spotifyLabelSmall)
                .fontWeight(.medium)
        }
        .foregroundColor(difficulty.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(difficulty.color.opacity(0.15))
        .cornerRadius(12)
    }

    // Deadline warning helper
    @ViewBuilder
    private func cancellationDeadlineWarning(deadline: Date) -> some View {
        let daysUntilDeadline =
            Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0

        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 20))
                .foregroundColor(.wiseError)

            VStack(alignment: .leading, spacing: 4) {
                Text("Cancellation Deadline")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)

                Text(deadline, style: .date)
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.wiseError)
            }

            Spacer()

            if daysUntilDeadline >= 0 {
                Text("\(daysUntilDeadline) days left")
                    .font(.spotifyLabelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.wiseError)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.wiseError.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.wiseError.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseError.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - OLD Actions Section (kept for reference, replaced by simplifiedActionsSection)
    @ViewBuilder
    private func actionsSection(subscription: Subscription) -> some View {
        VStack(spacing: 12) {
            if subscription.isActive && subscription.cancellationDate == nil {
                Button(action: { showingPauseAlert = true }) {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 18))
                        Text("Pause Subscription")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseWarning)
                    .cornerRadius(12)
                }
            }

            if !subscription.isActive && subscription.cancellationDate == nil {
                Button(action: { resumeSubscription() }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("Resume Subscription")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseBrightGreen)
                    .cornerRadius(12)
                }
            }

            if subscription.isActive && subscription.cancellationDate == nil {
                Button(action: { showingCancelAlert = true }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Cancel Subscription")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseError)
                    .cornerRadius(12)
                }
            }

            Button(action: { showingDeleteAlert = true }) {
                Text("Delete Subscription")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    private var subscriptionNotFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.wiseError)

            Text("Subscription not found")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func sharedPersonRow(person: Person, subscription: Subscription) -> some View {
        HStack(spacing: 14) {
            // Initials avatar (44x44)
            initialsAvatarForPerson(person: person)

            // Name and email
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(person.email)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
                    .lineLimit(1)
            }

            Spacer()

            // Amount
            Text((subscription.monthlyEquivalent / Double(sharedPeople.count + 1)).asCurrency)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AmountColors.positive)
        }
        .padding(.vertical, 14)
    }

    private func initialsAvatarForPerson(person: Person) -> some View {
        let initials = InitialsGenerator.generate(from: person.name)
        let avatarColor = InitialsAvatarColors.color(for: person.name)

        return ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255))
        }
    }

    // MARK: - Helper Functions

    private func handleAlertAction(alert: SubscriptionAlertType) {
        switch alert {
        case .trialEnding:
            showingCancelAlert = true
        case .priceIncreased:
            showingPriceHistoryChart = true
        case .paymentUpcoming:
            break
        case .subscriptionPaused:
            resumeSubscription()
        }
    }

    private func loadTimelineEvents(subscription: Subscription) {
        events = SubscriptionEventService.shared.generateEvents(
            for: subscription,
            priceHistory: priceHistory,
            people: dataManager.people
        )
    }

    private func getPersonName(for personId: UUID?) -> String? {
        guard let personId = personId else { return nil }
        return dataManager.people.first { $0.id == personId }?.name
    }

    private func pauseSubscription() {
        guard var subscription = subscription else { return }
        subscription.isActive = false

        do {
            try dataManager.updateSubscription(subscription)
        } catch {
            dataManager.error = error
        }
    }

    private func resumeSubscription() {
        guard var subscription = subscription else { return }
        subscription.isActive = true

        do {
            try dataManager.updateSubscription(subscription)
        } catch {
            dataManager.error = error
        }
    }

    private func cancelSubscription() {
        guard var subscription = subscription else { return }
        subscription.isActive = false
        subscription.cancellationDate = Date()

        do {
            try dataManager.updateSubscription(subscription)
        } catch {
            dataManager.error = error
        }
    }

    private func deleteSubscription() {
        guard let subscription = subscription else { return }
        do {
            try dataManager.deleteSubscription(id: subscription.id)
            dismiss()
        } catch {
            dataManager.error = error
        }
    }

    // MARK: - Reminder & Usage Tracking Functions

    private func markAsUsedToday(subscription: Subscription) {
        guard var updatedSubscription = self.subscription else { return }
        updatedSubscription.lastUsedDate = Date()
        updatedSubscription.usageCount += 1

        do {
            try dataManager.updateSubscription(updatedSubscription)
            // Reload timeline events to show the new usage event
            loadTimelineEvents(subscription: updatedSubscription)
            // Provide haptic feedback
            HapticManager.shared.success()
        } catch {
            dataManager.error = error
        }
    }

    // AGENT 9: Load price history
    private func loadPriceHistory() {
        guard let subscription = subscription else { return }
        priceHistory = dataManager.getPriceHistory(for: subscription.id)

        // Check if there's a recent price increase (within 30 days)
        if let latestChange = priceHistory.first, latestChange.isIncrease {
            let daysSinceChange =
                Calendar.current.dateComponents([.day], from: latestChange.changeDate, to: Date())
                .day ?? 0
            showPriceIncreaseBadge = daysSinceChange <= 30
        }
    }

    // AGENT 8: Convert trial to paid subscription now
    private func convertTrialToPaidNow(subscription: Subscription) {
        Task {
            await SubscriptionRenewalService.shared.convertTrialToPaid(subscription: subscription)
        }
    }
}


// MARK: - Extensions
extension SubscriptionEvent: TimelineItemProtocol {
    var timestamp: Date { eventDate }
    var timelineIconType: TimelineIconType {
        switch eventType {
        case .billingCharged: return .expense
        case .memberPaid: return .payment
        case .priceIncrease, .priceDecrease: return .system
        default: return .system
        }
    }
}
