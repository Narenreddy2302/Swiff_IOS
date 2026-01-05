import SwiftUI

// MARK: - Enhanced Subscriptions Header Section
struct SubscriptionsHeaderSectionEnhanced: View {
    @Binding var selectedTab: SubscriptionsView.SubscriptionsTab
    @Binding var showingAddSubscriptionSheet: Bool
    @Binding var showingInsightsSheet: Bool
    @Binding var showingRenewalCalendarSheet: Bool
    @Binding var showSearchBar: Bool
    @Binding var searchText: String
    let totalMonthlySpend: Double
    let totalAnnualSpend: Double
    let nextBillingDate: Date?
    let upcomingBillsCount: Int

    @State private var isAddButtonPressed = false

    var body: some View {
        VStack(spacing: 16) {
            // Top Header (matching design system)
            HStack {
                Text("Subscriptions")
                    .font(Theme.Fonts.displayLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                // Search and Add Buttons (matching Home/Feed/People design)
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(showSearchBar ? Theme.Colors.brandPrimary : Theme.Colors.textPrimary)
                    }

                    HeaderActionButton(icon: "plus.circle.fill", color: Theme.Colors.brandPrimary) {
                        HapticManager.shared.impact(.medium)
                        showingAddSubscriptionSheet = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Segmented Control
            HStack(spacing: 0) {
                ForEach(SubscriptionsView.SubscriptionsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                            searchText = ""  // Clear search when switching tabs
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : Theme.Colors.textSecondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTab == tab ? Theme.Colors.brandPrimary : Color.clear)
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Theme.Colors.secondaryBackground)
            )
            .padding(.horizontal, 16)

            // Search Bar (matching Feed design)
            if showSearchBar {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.textSecondary)
                        .font(.system(size: 16))

                    TextField("Search subscriptions...", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.textPrimary)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.secondaryBackground)
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Subscription Quick Stats View
struct SubscriptionQuickStatsView: View {
    let subscriptions: [Subscription]
    let sharedSubscriptions: [SharedSubscription]

    var totalMonthlySpend: Double {
        subscriptions.filter { $0.isActive }.reduce(0.0) { $0 + $1.monthlyEquivalent }
    }

    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }

    var totalCount: Int {
        subscriptions.count
    }

    // Calculate trends (placeholder - in production, compare with previous period)
    // Returns: percentage change, isUp (direction), isGood (financially positive)
    private func calculateTrend(for type: String) -> (percentage: Double, isUp: Bool, isGood: Bool) {
        // Mock trend data - in production, this would compare with previous period
        switch type {
        case "subscriptions":
            // Subscriptions DOWN = good (saving money)
            return (2.1, false, true)
        case "monthly":
            // Monthly spend UP = bad (spending more)
            return (5.2, true, false)
        default:
            return (0, true, true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 2x2 Grid matching Home page style
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8
            ) {
                // Total Subscriptions Card
                SubscriptionMetricCard(
                    icon: "creditcard.fill",
                    iconColor: Theme.Colors.brandPrimary,
                    title: "SUBSCRIPTIONS",
                    value: "\(totalCount)",
                    trend: calculateTrend(for: "subscriptions"),
                    isCount: true
                )

                // Monthly Spend Card
                SubscriptionMetricCard(
                    icon: "calendar.circle.fill",
                    iconColor: Theme.Colors.info,
                    title: "MONTHLY SPEND",
                    value: formatCurrency(totalMonthlySpend),
                    trend: calculateTrend(for: "monthly"),
                    isCount: false,
                    suffix: "/mo"
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Shared Subscription Quick Stats View
struct SharedSubscriptionQuickStatsView: View {
    let sharedSubscriptions: [SharedSubscription]
    let people: [Person]

    var totalCount: Int {
        sharedSubscriptions.count
    }

    var totalMonthlySpend: Double {
        sharedSubscriptions.reduce(0.0) { total, sharedSub in
            let participantCount = sharedSub.sharedWith.count + 1  // +1 for owner
            return total + (sharedSub.individualCost * Double(participantCount))
        }
    }

    // Calculate trends (placeholder - in production, compare with previous period)
    // Returns: percentage change, isUp (direction), isGood (financially positive)
    private func calculateTrend(for type: String) -> (percentage: Double, isUp: Bool, isGood: Bool) {
        switch type {
        case "shared":
            // More shared subscriptions = neutral/good (splitting costs)
            return (1.5, true, true)
        case "monthly":
            // Monthly spend UP = bad (spending more)
            return (3.2, true, false)
        default:
            return (0, true, true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8
            ) {
                // Shared Subscriptions Card
                SubscriptionMetricCard(
                    icon: "person.2.fill",
                    iconColor: Theme.Colors.brandPrimary,
                    title: "SHARED",
                    value: "\(totalCount)",
                    trend: calculateTrend(for: "shared"),
                    isCount: true
                )

                // Shared Monthly Spend Card
                SubscriptionMetricCard(
                    icon: "calendar.circle.fill",
                    iconColor: Theme.Colors.info,
                    title: "MONTHLY SPEND",
                    value: formatCurrency(totalMonthlySpend),
                    trend: calculateTrend(for: "monthly"),
                    isCount: false,
                    suffix: "/mo"
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Subscription Metric Card (Matching Home Page EnhancedFinancialCard Style)
struct SubscriptionMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let trend: (percentage: Double, isUp: Bool, isGood: Bool)
    let isCount: Bool
    var suffix: String = ""

    /// Color based on whether the trend is financially good or bad
    private var trendColor: Color {
        trend.isGood ? Theme.Colors.brandPrimary : Theme.Colors.statusError
    }

    var body: some View {
        SwiffCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)

                    Spacer()

                    // Trend indicator - arrow shows direction, color shows financial impact
                    if trend.percentage != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: trend.isUp ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(trendColor)

                            Text(String(format: "%.1f%%", abs(trend.percentage)))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(trendColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(trendColor.opacity(0.15))
                        )
                    }
                }

                Text(title)
                    .font(Theme.Fonts.captionSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .textCase(.uppercase)

                // Value with optional suffix
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(Theme.Fonts.numberLarge)
                        .foregroundColor(Theme.Colors.textPrimary)
                    if !suffix.isEmpty {
                        Text(suffix)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Subscription Stat Card
struct SubscriptionStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let isAmount: Bool
    let isCount: Bool

    init(
        title: String, amount: Double, icon: String, color: Color, isAmount: Bool = false,
        isCount: Bool = false
    ) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.isAmount = isAmount
        self.isCount = isCount
    }

    var formattedAmount: String {
        if isCount {
            return String(Int(amount))
        } else if isAmount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.maximumFractionDigits = amount >= 1000 ? 0 : 2
            return formatter.string(from: NSNumber(value: amount)) ?? "$0"
        }
        return String(format: "%.2f", amount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)

                Spacer()
            }

            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
                .tracking(0.5)

            Text(formattedAmount)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Subscriptions Category Filter Section
struct SubscriptionsCategoryFilterSection: View {
    @Binding var selectedCategory: SubscriptionCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories Button (matching PeopleFilterPill)
                Button(action: {
                    HapticManager.shared.light()
                    selectedCategory = nil
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.spotifyLabelMedium)
                    }
                    .foregroundColor(selectedCategory == nil ? .white : .wisePrimaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                selectedCategory == nil ? Theme.Colors.brandPrimary : Color.wiseBorder.opacity(0.3))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Category Pills (matching PeopleFilterPill)
                ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                    Button(action: {
                        HapticManager.shared.light()
                        selectedCategory = selectedCategory == category ? nil : category
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(
                                    selectedCategory == category ? .white : category.color)
                            Text(category.rawValue)
                                .font(.spotifyLabelMedium)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .wisePrimaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedCategory == category ? category.color : Color.wiseBorder.opacity(0.3)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Enhanced Personal Subscriptions View
struct EnhancedPersonalSubscriptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    let subscriptions: [Subscription]
    @Binding var searchText: String
    @Binding var selectedFilter: SubscriptionsView.SubscriptionFilter
    @Binding var showingFilterSheet: Bool
    @State private var subscriptionToDelete: Subscription?
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Subscriptions List
            if dataManager.isLoading && subscriptions.isEmpty {
                // Loading State
                SkeletonListView(rowCount: 5, rowType: .subscription)
            } else if subscriptions.isEmpty {
                EmptySubscriptionsView()
            } else {
                ScrollView {
                    // List View - Edge-to-edge like Feed
                    VStack(spacing: 0) {
                        ForEach(Array(subscriptions.enumerated()), id: \.element.id) {
                            index, subscription in
                            NavigationLink(
                                destination: SubscriptionDetailView(
                                    subscriptionId: subscription.id)
                            ) {
                                FeedSubscriptionRow(
                                    subscription: subscription,
                                    people: dataManager.people
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)

                            // Add divider between items (not after the last one)
                            if index < subscriptions.count - 1 {
                                FeedRowDivider()
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.wiseBackground)
                .refreshable {
                    HapticManager.shared.pullToRefresh()
                    dataManager.loadAllData()
                    ToastManager.shared.showSuccess("Refreshed")
                }
            }
        }
        .alert(
            "Delete Subscription?", isPresented: $showingDeleteAlert,
            presenting: subscriptionToDelete
        ) { subscription in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deleteSubscription(id: subscription.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { subscription in
            Text(
                "This will permanently delete '\(subscription.name)'. This action cannot be undone."
            )
        }
    }
}

// MARK: - Enhanced Subscription Row View (Unified Design)
@available(*, deprecated, message: "Use UnifiedListRowV2 instead")
struct EnhancedSubscriptionRowView: View {
    let subscription: Subscription
    @State private var showingDetails = false

    // Icon color from subscription's custom color
    private var iconColor: Color {
        Color(hexString: subscription.color)
    }

    // Status icon based on subscription state
    private var statusIcon: String {
        if subscription.isFreeTrial && !subscription.isTrialExpired {
            if let days = subscription.daysUntilTrialEnd, days <= 3 {
                return "⚠"
            }
            return "✓"
        }

        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return "✗"
            }
            return "⏸"
        }

        return "✓"
    }

    // Status text based on subscription state
    private var statusText: String {
        if subscription.isFreeTrial && !subscription.isTrialExpired {
            if let days = subscription.daysUntilTrialEnd {
                if days == 0 {
                    return "Trial ending"
                } else if days <= 3 {
                    return "Trial ending"
                }
                return "Active Trial"
            }
            return "Active Trial"
        }

        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return "Cancelled"
            }
            return "Paused"
        }

        return "Active"
    }

    // Billing cycle suffix for price display
    private var billingSuffix: String {
        switch subscription.billingCycle {
        case .monthly: return "/mo"
        case .yearly, .annually: return "/yr"
        case .weekly: return "/wk"
        case .quarterly: return "/qtr"
        case .daily: return "/day"
        case .biweekly: return "/2wk"
        case .semiAnnually: return "/6mo"
        case .lifetime: return ""
        }
    }

    // Subtitle with status, billing cycle, and next billing date
    private var subtitle: String {
        var components: [String] = []

        // Status with icon
        components.append("\(statusIcon) \(statusText)")

        // For trial ending soon, show days left
        if subscription.isFreeTrial && !subscription.isTrialExpired {
            if let days = subscription.daysUntilTrialEnd {
                if days <= 3 {
                    components.append("\(days) \(days == 1 ? "day" : "days") left")
                } else {
                    components.append(subscription.billingCycle.rawValue)
                    components.append("Next: \(formatDate(subscription.nextBillingDate))")
                }
            }
        }
        // For cancelled subscriptions, show expiry date
        else if subscription.cancellationDate != nil {
            if let cancelDate = subscription.cancellationDate {
                components.append("Expired \(formatDate(cancelDate))")
            }
        }
        // For paused subscriptions
        else if !subscription.isActive {
            components.append(subscription.billingCycle.rawValue)
            if let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) {
                components.append("Resumes: \(formatDate(nextDate))")
            }
        }
        // For active subscriptions
        else {
            components.append(subscription.billingCycle.rawValue)
            components.append("Next: \(formatDate(subscription.nextBillingDate))")
        }

        return components.joined(separator: " • ")
    }

    // Format date to "Dec 15" format
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack(spacing: 12) {
                // Icon (48x48)
                UnifiedIconCircle(
                    icon: subscription.icon,
                    color: iconColor
                )
                .frame(width: 48, height: 48)

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Value - Right aligned with billing suffix
                Text("\(formatCurrency(subscription.price))\(billingSuffix)")
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wiseBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Subscription Row View (Unified Design - Legacy Wrapper)
/// Legacy subscription row view - wraps ListRowFactory for backward compatibility
struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        ListRowFactory.row(for: subscription)
    }
}

// MARK: - Empty Subscriptions View
struct EmptySubscriptionsView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon - Properly sized and centered with subtle background
                ZStack {
                    // Background circle for visual weight
                    Circle()
                        .fill(Theme.Colors.secondaryBackground)
                        .frame(width: 140, height: 140)

                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
                }

                // Text Content - Professional spacing and sizing
                VStack(spacing: 12) {
                    Text("No Subscriptions Yet")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Add your first subscription to start tracking\nyour monthly expenses")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Subscriptions in Category View
struct NoCategorySubscriptionsView: View {
    let category: SubscriptionCategory
    let onClearFilter: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Category icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 100, height: 100)

                Image(systemName: category.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
            }

            // Text content
            VStack(spacing: 8) {
                Text("No \(category.rawValue) Subscriptions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("You don't have any subscriptions\nin this category yet")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Clear filter button
            Button(action: {
                HapticManager.shared.light()
                onClearFilter()
            }) {
                Text("Clear Filter")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.brandPrimary, lineWidth: 1.5)
                    )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Enhanced Shared Subscriptions View
struct EnhancedSharedSubscriptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var sharedSubscriptions: [SharedSubscription]
    @Binding var searchText: String
    let people: [Person]
    @State private var sharedSubscriptionToDelete: SharedSubscription?
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Subscriptions List
            if sharedSubscriptions.isEmpty {
                EmptySharedSubscriptionsView()
            } else {
                // List View
                VStack(spacing: 0) {
                    ForEach(Array(sharedSubscriptions.enumerated()), id: \.element.id) { index, sharedSub in
                        // Look up the linked subscription for name/date
                        let linkedSubscription = dataManager.subscriptions.first {
                            $0.id == sharedSub.subscriptionId
                        }

                        FeedSharedSubscriptionRow(
                            sharedSubscription: sharedSub,
                            people: people,
                            subscription: linkedSubscription
                        )
                        .padding(.horizontal, 16)
                        .contextMenu {
                            Button(role: .destructive) {
                                HapticManager.shared.heavy()
                                sharedSubscriptionToDelete = sharedSub
                                showingDeleteAlert = true
                            } label: {
                                Label("Remove Share", systemImage: "person.badge.minus")
                            }
                        }

                        // Add divider between items (not after the last one)
                        if index < sharedSubscriptions.count - 1 {
                            FeedRowDivider()
                        }
                    }
                }
            }
        }
        .alert("Remove Shared Subscription?", isPresented: $showingDeleteAlert, presenting: sharedSubscriptionToDelete) { shared in
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                deleteSharedSubscription(shared)
            }
        } message: { shared in
            Text("This will remove the shared subscription '\(shared.notes)'. The base subscription will remain.")
        }
    }

    private func deleteSharedSubscription(_ sharedSub: SharedSubscription) {
        do {
            try dataManager.unshareSubscription(sharedSubscriptionId: sharedSub.id)
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Shared Subscription Row (Initials-based design matching SubscriptionCard)
struct SharedSubscriptionRow: View {
    let sharedSubscription: SharedSubscription
    let people: [Person]

    private var sharedByPerson: Person? {
        people.first { $0.id == sharedSubscription.sharedBy }
    }

    private var sharedWithPeople: [Person] {
        sharedSubscription.sharedWith.compactMap { id in
            people.first { $0.id == id }
        }
    }

    private var displayName: String {
        sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes
    }

    private var initials: String {
        InitialsGenerator.generate(from: displayName)
    }

    private var avatarColor: Color {
        InitialsAvatarColors.purple  // Purple for shared subscriptions
    }

    private var billingCycleText: String {
        let totalPeople = sharedWithPeople.count + 1
        if totalPeople > 2 {
            return "Shared with \(totalPeople) people"
        } else if let sharedBy = sharedByPerson {
            return "Shared with \(sharedBy.name)"
        } else {
            return "Shared"
        }
    }

    private var totalPrice: Double {
        let totalPeople = sharedWithPeople.count + 1
        return sharedSubscription.individualCost * Double(totalPeople)
    }

    private var formattedPriceWithSign: String {
        String(format: "- $%.2f", totalPrice)
    }

    private var costPerPersonText: String {
        String(format: "$%.2f/person", sharedSubscription.individualCost)
    }

    private var amountColor: Color {
        AmountColors.negative
    }

    var body: some View {
        HStack(spacing: 14) {
            // Initials avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)

                Text(initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255))
            }

            // Name and billing info
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(billingCycleText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
                    .lineLimit(1)
            }

            Spacer()

            // Price and cost per person
            VStack(alignment: .trailing, spacing: 3) {
                Text(formattedPriceWithSign)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(amountColor)

                Text(costPerPersonText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Enhanced Shared Subscription Row View
@available(*, deprecated, message: "Use UnifiedListRowV2 instead")
struct EnhancedSharedSubscriptionRowView: View {
    let sharedSubscription: SharedSubscription
    let people: [Person]

    var sharedByPerson: Person? {
        people.first { $0.id == sharedSubscription.sharedBy }
    }

    var sharedWithPeople: [Person] {
        sharedSubscription.sharedWith.compactMap { id in
            people.first { $0.id == id }
        }
    }

    var statusIcon: String {
        sharedSubscription.isAccepted ? "✓" : "⚠"
    }

    var statusText: String {
        sharedSubscription.isAccepted ? "Active" : "Pending"
    }

    // Subtitle format: {statusIcon} {status} • Shared with {count} • {costPerPerson}/person
    var subtitle: String {
        var components: [String] = []

        // Status with icon
        components.append("\(statusIcon) \(statusText)")

        // Shared with count (total people in the share including owner)
        let totalPeople = sharedWithPeople.count + 1  // +1 for the owner
        if totalPeople > 2 {
            components.append("Shared with \(totalPeople)")
        } else if let sharedBy = sharedByPerson {
            components.append("Shared with \(sharedBy.name)")
        } else {
            components.append("Shared")
        }

        // Cost per person
        components.append(String(format: "$%.2f/person", sharedSubscription.individualCost))

        return components.joined(separator: " • ")
    }

    // Calculate total subscription price (for display)
    var totalPrice: Double {
        let totalPeople = sharedWithPeople.count + 1  // +1 for the owner
        return sharedSubscription.individualCost * Double(totalPeople)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon (48x48) - Shared subscription icon
            UnifiedIconCircle(
                icon: "person.2.fill",
                color: .wiseBlue
            )
            .frame(width: 48, height: 48)

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    sharedSubscription.notes.isEmpty
                        ? "Shared Subscription" : sharedSubscription.notes
                )
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Total Price - Right aligned
            Text(String(format: "$%.2f", totalPrice))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.wiseBackground)
    }
}

// MARK: - Empty Shared Subscriptions View
struct EmptySharedSubscriptionsView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Icon - Properly sized and centered
                    ZStack {
                        // Background circle for visual weight
                        Circle()
                            .fill(Color.wiseSecondaryText.opacity(0.08))
                            .frame(width: 120, height: 120)

                        Image(systemName: "person.2.badge.plus")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }

                    // Text Content - Professional spacing and sizing
                    VStack(spacing: 12) {
                        Text("No Shared Subscriptions")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.wisePrimaryText)

                        Text("Share your subscriptions with friends\nand family to split costs")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.wiseSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 48)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Shared Subscription Row View (Unified Design)
struct SharedSubscriptionRowView: View {
    let sharedSubscription: SharedSubscription

    var body: some View {
        HStack(spacing: 12) {
            // Icon (48x48)
            UnifiedIconCircle(
                icon: "person.2.fill",
                color: .wiseBlue
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    sharedSubscription.notes.isEmpty
                        ? "Shared Subscription" : sharedSubscription.notes
                )
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)

                Text("✓ Active • Shared")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(String(format: "$%.2f", sharedSubscription.individualCost))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.wiseBackground)
    }
}
