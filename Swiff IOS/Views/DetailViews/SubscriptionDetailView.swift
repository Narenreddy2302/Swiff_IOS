//
//  SubscriptionDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for subscription management
//

import SwiftUI
import Combine

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

    // Reminder settings
    @State private var enableRenewalReminder = false
    @State private var reminderDaysBefore = 3
    @State private var reminderTime = Date()

    // AGENT 9: Price history tracking
    @State private var priceHistory: [PriceChange] = []
    @State private var showPriceIncreaseBadge = false

    var subscription: Subscription? {
        dataManager.subscriptions.first { $0.id == subscriptionId }
    }

    var sharedPeople: [Person] {
        guard let subscription = subscription, subscription.isShared else { return [] }
        return subscription.sharedWith.compactMap { personId in
            dataManager.people.first { $0.id == personId }
        }
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
                // Header
                SubscriptionTimelineHeader(
                    subscription: subscription,
                    sharedPeople: sharedPeople
                )
                .background(Color.wiseBackground)

                // Tab selector
                PillSegmentedControl(selectedTab: $selectedTab)
                    .padding(.bottom, 16)

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
        .navigationTitle(subscription?.name ?? "Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .observeEntity(subscriptionId, type: .subscription, dataManager: dataManager)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Text("Edit")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let subscription = subscription {
                EditSubscriptionSheet(subscription: subscription, onSubscriptionUpdated: {
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
                Text("This will permanently delete '\(subscription.name)'. This action cannot be undone.")
            }
        }
        .alert("Cancel Subscription?", isPresented: $showingCancelAlert) {
            Button("Keep", role: .cancel) {}
            Button("Cancel Subscription", role: .destructive) {
                cancelSubscription()
            }
        } message: {
            if let subscription = subscription {
                Text("This will mark '\(subscription.name)' as cancelled. You can still delete it later if needed.")
            }
        }
        .alert("Pause Subscription?", isPresented: $showingPauseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Pause") {
                pauseSubscription()
            }
        } message: {
            Text("This subscription will be paused and won't be included in monthly cost calculations. You can resume it anytime.")
        }
        .sheet(isPresented: $showingPriceHistoryChart) {
            if let subscription = subscription {
                NavigationView {
                    PriceHistoryChartView(subscription: subscription)
                        .environmentObject(dataManager)
                }
            }
        }
    }

    // MARK: - Tab Views

    @ViewBuilder
    private func timelineTab(subscription: Subscription) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if events.isEmpty {
                    emptyTimelineView
                        .padding(.top, 60)
                } else {
                    timelineEventsList
                        .padding(.top, 16)
                }
            }
        }
        .background(Color.wiseBackground)
        .onAppear {
            loadPriceHistory()
            loadTimelineEvents(subscription: subscription)
        }
    }

    private var timelineEventsList: some View {
        LazyVStack(spacing: 0) {
            let groupedEvents = SubscriptionEvent.groupByDate(events)

            ForEach(Array(groupedEvents.enumerated()), id: \.offset) { index, group in
                VStack(spacing: 14) {
                    // Date section header
                    TimelineDateSectionHeader(date: group.date)

                    // Events for this date
                    ForEach(group.events) { event in
                        TimelineEventBubble(
                            event: event,
                            personName: getPersonName(for: event.relatedPersonId)
                        )
                    }
                }
                .padding(.bottom, index < groupedEvents.count - 1 ? 24 : 16)
            }
        }
    }

    private var emptyTimelineView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText)

            Text("No timeline events yet")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text("Events will appear as you use this subscription")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private func detailsTab(subscription: Subscription) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // AGENT 8: Trial Status Section (if trial)
                if subscription.isFreeTrial {
                    trialStatusSection(subscription: subscription)
                }

                // AGENT 9: Price increase badge
                if showPriceIncreaseBadge, let latestIncrease = priceHistory.first, latestIncrease.isIncrease {
                    priceIncreaseBadgeSection(priceChange: latestIncrease)
                }

                overviewCard(subscription: subscription)

                // AGENT 9: Price history section
                if !priceHistory.isEmpty {
                    priceHistorySection(subscription: subscription)
                }

                reminderSettingsCard(subscription: subscription)
                usageTrackingCard(subscription: subscription)
                spendingStatsCard(subscription: subscription)
                detailsSection(subscription: subscription)
                sharedInfoSection(subscription: subscription)
                cancellationInstructionsSection(subscription: subscription)
                actionsSection(subscription: subscription)
            }
            .padding(.top, 16)
        }
        .background(Color.wiseBackground)
        .onAppear {
            loadSubscriptionData(subscription: subscription)
            loadPriceHistory()
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
                ForEach(Array(priceHistory.prefix(3).enumerated()), id: \.element.id) { index, change in
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
                Text("\(priceHistory.count - 3) more price change\(priceHistory.count - 3 == 1 ? "" : "s")")
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

                    Text(String(format: "$%.2f", subscription.price))
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

                    Text(String(format: "$%.2f/mo", subscription.monthlyEquivalent))
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
    private func reminderSettingsCard(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)
                Text("Renewal Reminders")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
            }

            // Enable reminder toggle
            Toggle(isOn: $enableRenewalReminder) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Reminders")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Get notified before your subscription renews")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseBlue)
            .onChange(of: enableRenewalReminder) { _, newValue in
                saveReminderSettings(subscription: subscription)
            }

            if enableRenewalReminder {
                Divider()

                // Days before selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notify me")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Picker("Days Before", selection: $reminderDaysBefore) {
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                        Text("2 weeks before").tag(14)
                        Text("1 month before").tag(30)
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseBorder.opacity(0.5))
                    )
                    .onChange(of: reminderDaysBefore) { _, _ in
                        saveReminderSettings(subscription: subscription)
                    }
                }

                Divider()

                // Time selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reminder Time")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseBorder.opacity(0.5))
                        )
                        .onChange(of: reminderTime) { _, _ in
                            saveReminderSettings(subscription: subscription)
                        }
                }

                Divider()

                // Test notification button
                Button(action: {
                    testNotification(subscription: subscription)
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                        Text("Send Test Notification")
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

                let daysSinceCreation = Calendar.current.dateComponents([.day], from: subscription.createdDate, to: Date()).day ?? 1
                let usageFrequency = Double(subscription.usageCount) / Double(max(daysSinceCreation, 1))

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

                    Text(String(format: "$%.2f", subscription.totalSpent))
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
                let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
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
        if (subscription.website != nil && !(subscription.website?.isEmpty ?? true)) || !subscription.notes.isEmpty || subscription.cancellationDate != nil {
            VStack(alignment: .leading, spacing: 16) {
                Text("Details")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                if let website = subscription.website, !website.isEmpty {
                    Button(action: {
                        if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
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
                            ForEach(Array(sharedPeople.enumerated()), id: \.element.id) { index, person in
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

                        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
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
                        if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
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
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer()

            // Amount
            Text(String(format: "$%.2f", subscription.monthlyEquivalent / Double(sharedPeople.count + 1)))
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
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }

    // MARK: - Helper Functions

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

    private func loadSubscriptionData(subscription: Subscription) {
        enableRenewalReminder = subscription.enableRenewalReminder
        reminderDaysBefore = subscription.reminderDaysBefore
        if let savedTime = subscription.reminderTime {
            reminderTime = savedTime
        }
    }

    private func saveReminderSettings(subscription: Subscription) {
        guard var updatedSubscription = self.subscription else { return }
        updatedSubscription.enableRenewalReminder = enableRenewalReminder
        updatedSubscription.reminderDaysBefore = reminderDaysBefore
        updatedSubscription.reminderTime = reminderTime

        do {
            try dataManager.updateSubscription(updatedSubscription)
            // Schedule notification if enabled
            if enableRenewalReminder {
                scheduleRenewalReminder(subscription: updatedSubscription)
            }
        } catch {
            dataManager.error = error
        }
    }

    private func testNotification(subscription: Subscription) {
        // TODO: Implement test notification using NotificationManager
        // For now, we'll just trigger a haptic feedback
        HapticManager.shared.success()
    }

    private func scheduleRenewalReminder(subscription: Subscription) {
        // TODO: Implement notification scheduling using NotificationManager
        // This will be implemented when NotificationManager is enhanced
    }

    private func markAsUsedToday(subscription: Subscription) {
        guard var updatedSubscription = self.subscription else { return }
        updatedSubscription.lastUsedDate = Date()
        updatedSubscription.usageCount += 1

        do {
            try dataManager.updateSubscription(updatedSubscription)
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
            let daysSinceChange = Calendar.current.dateComponents([.day], from: latestChange.changeDate, to: Date()).day ?? 0
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

#Preview {
    NavigationView {
        SubscriptionDetailView(subscriptionId: UUID())
            .environmentObject(DataManager.shared)
    }
}
