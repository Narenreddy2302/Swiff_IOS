//
//  ContentView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/11/25.
//  Updated on 11/18/25: Models moved to separate files
//

import SwiftUI
import SwiftData
import PhotosUI
import ContactsUI
import Combine

// MARK: - Imported Models
// All data models have been extracted to separate files:
// - Models/DataModels/Person.swift
// - Models/DataModels/Group.swift
// - Models/DataModels/Subscription.swift
// - Models/DataModels/Transaction.swift
// - Models/DataModels/SupportingTypes.swift
// - Models/SwiftDataModels/*.swift

// MARK: - Spotify Font System
extension Font {
    // Large Display Fonts - Bold and impactful
    static let spotifyDisplayLarge = Font.custom("Helvetica Neue", size: 32).weight(.black)
    static let spotifyDisplayMedium = Font.custom("Helvetica Neue", size: 24).weight(.bold)
    
    // Headings - Strong hierarchy
    static let spotifyHeadingLarge = Font.custom("Helvetica Neue", size: 20).weight(.bold)
    static let spotifyHeadingMedium = Font.custom("Helvetica Neue", size: 18).weight(.bold)
    static let spotifyHeadingSmall = Font.custom("Helvetica Neue", size: 16).weight(.bold)
    
    // Body Text - Clean and readable (SF Font)
    static let spotifyBodyLarge = Font.system(size: 16, weight: .medium)
    static let spotifyBodyMedium = Font.system(size: 14, weight: .medium)
    static let spotifyBodySmall = Font.system(size: 13, weight: .regular)
    
    // Labels - For cards and metadata (SF Font)
    static let spotifyLabelLarge = Font.system(size: 14, weight: .semibold)
    static let spotifyLabelMedium = Font.system(size: 12, weight: .semibold)
    static let spotifyLabelSmall = Font.system(size: 11, weight: .semibold)
    
    // Captions - Supporting information (SF Font)
    static let spotifyCaptionLarge = Font.system(size: 12, weight: .medium)
    static let spotifyCaptionMedium = Font.system(size: 11, weight: .regular)
    static let spotifyCaptionSmall = Font.system(size: 10, weight: .regular)
    
    // Numbers - For financial amounts
    static let spotifyNumberLarge = Font.custom("Helvetica Neue", size: 24).weight(.black)
    static let spotifyNumberMedium = Font.custom("Helvetica Neue", size: 16).weight(.bold)
    static let spotifyNumberSmall = Font.custom("Helvetica Neue", size: 14).weight(.bold)
}

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var spotlightNavigation = SpotlightNavigationHandler()
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedTab: Int = 0

    init() {
        // Configure tab bar appearance with adaptive colors for dark mode
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Set adaptive background color - solid colored background in dark mode
        let backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) : // Solid dark background in dark mode
                UIColor.systemBackground   // Standard background in light mode
        }
        appearance.backgroundColor = backgroundColor

        // Create adaptive colors for tab items - using brand colors
        let unselectedColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(white: 1.0, alpha: 0.5) : // Semi-transparent white in dark mode
                UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 0.5) // wiseCharcoal with 0.5 opacity in light mode
        }

        // Selected color uses wiseBrightGreen for brand consistency
        let selectedColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.624, green: 0.910, blue: 0.439, alpha: 1.0) : // wiseBrightGreen in dark mode
                UIColor(red: 0.086, green: 0.200, blue: 0.0, alpha: 1.0)     // wiseForestGreen in light mode
        }

        // Configure unselected tab item appearance - adaptive
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]

        // Configure selected tab item appearance - white icons in dark mode
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]

        // Add subtle separator line for definition
        appearance.shadowImage = nil
        appearance.shadowColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(white: 0.2, alpha: 0.3) : // Subtle separator in dark mode
                UIColor(white: 0.8, alpha: 0.3)   // Subtle separator in light mode
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Enable translucency to allow content to scroll underneath
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = backgroundColor

        // Set the tint color for selected items - adaptive
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label {
                        tabLabel("Home", tag: 0)
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(0)

            RecentActivityView()
                .tabItem {
                    Label {
                        tabLabel("Feed", tag: 1)
                    } icon: {
                        Image(systemName: "rectangle.stack.fill")
                    }
                }
                .tag(1)

            PeopleView()
                .tabItem {
                    Label {
                        tabLabel("People", tag: 2)
                    } icon: {
                        Image(systemName: "person.2.fill")
                    }
                }
                .tag(2)

            SubscriptionsView()
                .tabItem {
                    Label {
                        tabLabel("Subscriptions", tag: 3)
                    } icon: {
                        Image(systemName: "creditcard.fill")
                    }
                }
                .tag(3)

            AnalyticsView()
                .tabItem {
                    Label {
                        tabLabel("Analytics", tag: 4)
                    } icon: {
                        Image(systemName: "chart.pie.fill")
                    }
                }
                .tag(4)
        }
        .tint(.wiseBrightGreen) // Brand accent color for tab bar
        .preferredColorScheme(preferredColorSchemeValue)
        .dataManagerOverlays() // Add error handling and progress display
        .toast() // Add toast notification support
        .onChange(of: selectedTab) { oldValue, newValue in
            // TASK D-004: Haptic feedback on tab change
            HapticManager.shared.selection()
        }
        .onChange(of: spotlightNavigation.shouldNavigateToTab) { oldValue, newValue in
            // Handle Spotlight navigation to specific tab
            if let tab = newValue {
                selectedTab = tab
            }
        }
    }

    /// Returns the appropriate tab label based on tabBarStyle setting
    /// - "labels": Always show labels (default)
    /// - "iconsOnly": Never show labels
    /// - "selectedOnly": Only show label for selected tab
    @ViewBuilder
    private func tabLabel(_ title: String, tag: Int) -> some View {
        switch userSettings.tabBarStyle {
        case "iconsOnly":
            Text("")
        case "selectedOnly":
            if selectedTab == tag {
                Text(title)
            } else {
                Text("")
            }
        default: // "labels"
            Text(title)
        }
    }

    /// Computed property to determine the preferred color scheme based on user settings
    private var preferredColorSchemeValue: ColorScheme? {
        switch userSettings.themeMode.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        default: // "system"
            return nil
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var showingSearch = false
    @State private var showingQuickActions = false
    @State private var showingAddSplitBill = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background that extends to all edges
                Color.wiseBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top Header with Profile and Actions
                        TopHeaderSection(
                            showingSettings: $showingSettings,
                            showingProfile: $showingProfile,
                            showingSearch: $showingSearch,
                            showingQuickActions: $showingQuickActions
                        )

                        // Main Content Section
                        VStack(spacing: 20) {
                            // Today Section (moved down)
                            TodaySection()

                            // Four Card Grid
                            FinancialOverviewGrid(selectedTab: $selectedTab)

                            // Recent Group Activity Section
                            RecentGroupActivitySection()

                            // Recent Transactions Section
                            RecentActivitySection()

                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
        .sheet(isPresented: $showingQuickActions) {
            QuickActionSheet()
        }
    }
}

// MARK: - Top Header Section
struct TopHeaderSection: View {
    @Binding var showingSettings: Bool
    @Binding var showingProfile: Bool
    @Binding var showingSearch: Bool
    @Binding var showingQuickActions: Bool

    var body: some View {
        HStack {
            // Profile Icon (left corner)
            Button(action: {
                HapticManager.shared.impact(.medium)
                showingProfile = true
            }) {
                AvatarView(
                    avatarType: UserProfileManager.shared.profile.avatarType,
                    size: .large,
                    style: .solid
                )
                .frame(width: 32, height: 32)
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))

            Spacer()

            // Logo in center
            Text("Swiff.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.wiseForestGreen)

            Spacer()

            // Add Button (right corner)
            HeaderActionButton(icon: "plus.circle.fill", color: .wiseForestGreen) {
                HapticManager.shared.impact(.medium)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showingQuickActions = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

// MARK: - Today Section
struct TodaySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Today")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
            }
            
            HStack {
                Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wiseSecondaryText)

                Spacer()
            }
        }
    }
}

// MARK: - Financial Overview Grid
struct FinancialOverviewGrid: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager
    @State private var showingBalanceDetail = false
    @State private var animatedBalance: Double = 0
    @State private var animatedIncome: Double = 0
    @State private var animatedExpenses: Double = 0
    @State private var animatedSubscriptions: Double = 0

    var totalBalance: Double {
        // Calculate total balance from people balances
        let peopleBalance = dataManager.people.reduce(0.0) { total, person in
            total + person.balance
        }
        // Add net monthly income
        let netIncome = dataManager.getNetMonthlyIncome()
        return peopleBalance + netIncome
    }

    // Simple trend calculation (mock data - in production, you'd compare with last month)
    func calculateTrend(for type: String) -> (percentage: Double, isPositive: Bool) {
        // For demo purposes, using random trend between -15% and +15%
        // In production, you would calculate actual change from previous month
        switch type {
        case "balance":
            return (5.2, true)  // +5.2%
        case "subscriptions":
            return (-2.1, false) // -2.1%
        case "income":
            return (8.5, true)  // +8.5%
        case "expenses":
            return (3.4, true)  // +3.4%
        default:
            return (0, true)
        }
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            // Balance Card
            Button(action: {
                HapticManager.shared.light()
                showingBalanceDetail = true
            }) {
                EnhancedFinancialCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: .wiseBrightGreen,
                    title: "BALANCE",
                    amount: String(format: "$%.0f", animatedBalance),
                    trend: calculateTrend(for: "balance")
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Subscriptions Card (replaced Difference)
            Button(action: {
                HapticManager.shared.light()
                selectedTab = 3 // Switch to Subscriptions tab
            }) {
                EnhancedFinancialCard(
                    icon: "creditcard.circle.fill",
                    iconColor: .wiseBlue,
                    title: "SUBSCRIPTIONS",
                    amount: String(format: "$%.0f/mo", animatedSubscriptions),
                    trend: calculateTrend(for: "subscriptions")
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Income Card
            EnhancedFinancialCard(
                icon: "arrow.up.circle.fill",
                iconColor: .wiseBrightGreen,
                title: "INCOME",
                amount: String(format: "$%.0f", animatedIncome),
                trend: calculateTrend(for: "income")
            )

            // Expenses Card
            EnhancedFinancialCard(
                icon: "arrow.down.circle.fill",
                iconColor: .wiseError,
                title: "EXPENSES",
                amount: String(format: "$%.0f", animatedExpenses),
                trend: calculateTrend(for: "expenses")
            )
        }
        .onAppear {
            // Animate numbers on appear
            withAnimation(.easeOut(duration: 0.8)) {
                animatedBalance = totalBalance
                animatedSubscriptions = dataManager.calculateTotalMonthlyCost()
                animatedIncome = dataManager.calculateMonthlyIncome()
                animatedExpenses = dataManager.calculateMonthlyExpenses()
            }
        }
        .onChange(of: dataManager.people.count) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedBalance = totalBalance
            }
        }
        .onChange(of: dataManager.subscriptions.count) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedSubscriptions = dataManager.calculateTotalMonthlyCost()
            }
        }
        .onChange(of: dataManager.transactions.count) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedIncome = dataManager.calculateMonthlyIncome()
                animatedExpenses = dataManager.calculateMonthlyExpenses()
            }
        }
        .sheet(isPresented: $showingBalanceDetail) {
            BalanceDetailView()
        }
    }
}

// MARK: - Financial Card
struct FinancialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(amount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Enhanced Financial Card (with trends)
struct EnhancedFinancialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    let trend: (percentage: Double, isPositive: Bool)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Spacer()

                // Trend indicator
                HStack(spacing: 2) {
                    Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trend.isPositive ? .wiseBrightGreen : .wiseError)

                    Text(String(format: "%.1f%%", abs(trend.percentage)))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trend.isPositive ? .wiseBrightGreen : .wiseError)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill((trend.isPositive ? Color.wiseBrightGreen : Color.wiseError).opacity(0.1))
                )
            }

            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(amount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Subscriptions Card
struct SubscriptionsCard: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        Button(action: {
            selectedTab = 3 // Switch to Subscriptions tab
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.wiseBlue)

                    Spacer()
                }

                Text("SUBSCRIPTIONS")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
                    .textCase(.uppercase)

                Text(String(format: "$%.0f/mo", dataManager.calculateTotalMonthlyCost()))
                    .font(.spotifyNumberLarge)
                    .foregroundColor(.wisePrimaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
                    .cardShadow()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Group Activity Section
struct RecentGroupActivitySection: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAllActivity = false

    // Activity item for sorting and display
    struct ActivityItem: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
        let activityType: String
        let amount: String
        let date: Date
        let avatarColor: Color
        let personId: UUID? // Track if this is a person activity
    }

    var recentActivities: [ActivityItem] {
        var activities: [ActivityItem] = []

        // Collect all group expenses
        for group in dataManager.groups {
            for expense in group.expenses {
                // Get person who paid
                if dataManager.people.contains(where: { $0.id == expense.paidBy }) {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencySymbol = "$"
                    let amountStr = formatter.string(from: NSNumber(value: expense.amount)) ?? "$0.00"

                    activities.append(ActivityItem(
                        emoji: group.emoji,
                        name: group.name,
                        activityType: expense.isSettled ? "settled" : "split bill",
                        amount: amountStr,
                        date: expense.date,
                        avatarColor: .wiseForestGreen,
                        personId: nil // This is a group activity
                    ))
                }
            }
        }

        // Collect person balance updates (positive balances = they owe you, negative = you owe them)
        for person in dataManager.people where person.balance != 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            let amountStr = formatter.string(from: NSNumber(value: abs(person.balance))) ?? "$0.00"

            let emoji: String
            if case .emoji(let emojiStr) = person.avatarType {
                emoji = emojiStr
            } else {
                emoji = "👤"
            }

            let activityType = person.balance > 0 ? "owes you" : "you owe"

            activities.append(ActivityItem(
                emoji: emoji,
                name: person.name,
                activityType: activityType,
                amount: amountStr,
                date: person.createdDate,
                avatarColor: person.balance > 0 ? .wiseBrightGreen : Color(red: 1.0, green: 0.592, blue: 0.0),
                personId: person.id // This is a person activity
            ))
        }

        // Sort by date descending and take first 8
        return activities.sorted { $0.date > $1.date }.prefix(8).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent activity")
                    .fontWeight(.bold)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wiseSecondaryText)

                Spacer()

                Button("See all") {
                    showingAllActivity = true
                }
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseForestGreen)
            }

            if recentActivities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.wiseSecondaryText)

                    Text("No recent activity")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Text("Add people and groups to see activity here")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentActivities) { activity in
                            if let personId = activity.personId,
                               let person = dataManager.people.first(where: { $0.id == personId }) {
                                NavigationLink(destination: PersonDetailView(personId: person.id)) {
                                    FriendActivityCard(
                                        friendMemoji: activity.emoji,
                                        friendName: activity.name,
                                        activityType: activity.activityType,
                                        amount: activity.amount,
                                        timeAgo: timeAgo(from: activity.date),
                                        avatarColor: activity.avatarColor
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Group activity - no navigation for now
                                FriendActivityCard(
                                    friendMemoji: activity.emoji,
                                    friendName: activity.name,
                                    activityType: activity.activityType,
                                    amount: activity.amount,
                                    timeAgo: timeAgo(from: activity.date),
                                    avatarColor: activity.avatarColor
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .sheet(isPresented: $showingAllActivity) {
            AllActivityView()
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else if seconds < 604800 {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(seconds / 604800)
            return "\(weeks)w ago"
        }
    }
}

// MARK: - All Activity View
struct AllActivityView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    var allActivities: [RecentGroupActivitySection.ActivityItem] {
        var activities: [RecentGroupActivitySection.ActivityItem] = []

        // Collect all group expenses
        for group in dataManager.groups {
            for expense in group.expenses {
                if dataManager.people.contains(where: { $0.id == expense.paidBy }) {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencySymbol = "$"
                    let amountStr = formatter.string(from: NSNumber(value: expense.amount)) ?? "$0.00"

                    activities.append(RecentGroupActivitySection.ActivityItem(
                        emoji: group.emoji,
                        name: group.name,
                        activityType: expense.isSettled ? "settled" : "split bill",
                        amount: amountStr,
                        date: expense.date,
                        avatarColor: .wiseForestGreen,
                        personId: nil
                    ))
                }
            }
        }

        // Collect person balance updates
        for person in dataManager.people where person.balance != 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            let amountStr = formatter.string(from: NSNumber(value: abs(person.balance))) ?? "$0.00"

            let emoji: String
            if case .emoji(let emojiStr) = person.avatarType {
                emoji = emojiStr
            } else {
                emoji = "👤"
            }

            let activityType = person.balance > 0 ? "owes you" : "you owe"

            activities.append(RecentGroupActivitySection.ActivityItem(
                emoji: emoji,
                name: person.name,
                activityType: activityType,
                amount: amountStr,
                date: person.createdDate,
                avatarColor: person.balance > 0 ? .wiseBrightGreen : Color(red: 1.0, green: 0.592, blue: 0.0),
                personId: person.id
            ))
        }

        return activities.sorted { $0.date > $1.date }
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
                                .foregroundColor(.wiseSecondaryText.opacity(0.5))

                            Text("No activity yet")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text("Add people and groups to see activity here")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
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
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Text(activity.activityType)
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    if activity.amount != "$0.00" {
                                        Text(activity.amount)
                                            .font(.spotifyNumberMedium)
                                            .foregroundColor(.wisePrimaryText)
                                    }

                                    Text(timeAgo(from: activity.date))
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .padding(16)
                            .background(Color.wiseCardBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("All Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else if seconds < 604800 {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(seconds / 604800)
            return "\(weeks)w ago"
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
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(friendMemoji)
                            .font(.system(size: 24))
                    )
                
                // Activity indicator (small dot)
                Circle()
                    .fill(getActivityColor())
                    .frame(width: 12, height: 12)
                    .offset(x: 18, y: -18)
                    .overlay(
                        Circle()
                            .stroke(Color.wiseCardBackground, lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .offset(x: 18, y: -18)
                    )
            }

            // Activity details
            VStack(spacing: 2) {
                if amount != "$0.00" {
                    Text(amount)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                
                Text(activityType)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                
                Text(timeAgo)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .frame(width: 80)
    }
    
    // Activity indicator color based on type
    private func getActivityColor() -> Color {
        switch activityType {
        case "paid you", "settled up":
            return .wiseBrightGreen
        case "requested":
            return Color(red: 1.0, green: 0.592, blue: 0.0) // Orange
        case "added bill", "new expense", "split bill":
            return .wiseBlue
        case "joined group":
            return .wiseBlue
        default:
            return .wiseSecondaryText
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    @Binding var showingQuickActions: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showingQuickActions = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.wiseForestGreen, Color.wiseBrightGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .wiseBrightGreen.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Quick Action Sheet
struct QuickActionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var showingAddSubscription = false
    @State private var showingAddPerson = false
    @State private var showingAddGroup = false

    private var preferredColorSchemeValue: ColorScheme? {
        switch UserSettings.shared.themeMode.lowercased() {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button(action: {
                    HapticManager.shared.light()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.wiseSecondaryText.opacity(0.6))
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.96))
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()
                .background(Color.wiseSecondaryText.opacity(0.12))

            // Actions - NO container, edge-to-edge
            VStack(spacing: 0) {
                QuickActionRowV2(
                    icon: "plus.circle.fill",
                    title: "Add Transaction",
                    subtitle: "Record a new expense or income",
                    iconColor: .wiseBrightGreen,
                    showDivider: true
                ) {
                    showingAddTransaction = true
                }

                QuickActionRowV2(
                    icon: "creditcard.fill",
                    title: "Add Subscription",
                    subtitle: "Track a new subscription service",
                    iconColor: .wiseBlue,
                    showDivider: true
                ) {
                    showingAddSubscription = true
                }

                QuickActionRowV2(
                    icon: "person.fill",
                    title: "Add Person",
                    subtitle: "Add a friend to track balances",
                    iconColor: Color(red: 1.0, green: 0.592, blue: 0.0),
                    showDivider: true
                ) {
                    showingAddPerson = true
                }

                QuickActionRowV2(
                    icon: "person.2.fill",
                    title: "Add Group",
                    subtitle: "Create a new group for shared expenses",
                    iconColor: .wiseForestGreen,
                    showDivider: false
                ) {
                    showingAddGroup = true
                }
            }

            Spacer(minLength: 0)
        }
        .background(Color.wiseCardBackground)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .presentationBackgroundInteraction(.disabled)
        .preferredColorScheme(preferredColorSchemeValue)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddTransaction,
                onTransactionAdded: { transaction in
                    do {
                        try dataManager.addTransaction(transaction)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionSheet(
                showingAddSubscriptionSheet: $showingAddSubscription,
                onSubscriptionAdded: { newSubscription in
                    do {
                        try dataManager.addSubscription(newSubscription)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonSheet(isPresented: $showingAddPerson)
                .environmentObject(dataManager)
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupSheet(showingAddGroupSheet: $showingAddGroup, editingGroup: nil, people: dataManager.people, onGroupAdded: { group in
                do {
                    try dataManager.addGroup(group)
                } catch {
                    dataManager.error = error
                }
            })
            .environmentObject(dataManager)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}



// MARK: - Insights Card
struct InsightsCard: View {
    @EnvironmentObject var dataManager: DataManager

    var totalSpending: Double {
        dataManager.calculateMonthlyExpenses() + dataManager.calculateTotalMonthlyCost()
    }

    var lastMonthSpending: Double {
        // Mock data - in production, calculate from last month's data
        totalSpending * 0.92 // Simulating 8% increase
    }

    var spendingChange: Double {
        ((totalSpending - lastMonthSpending) / lastMonthSpending) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)

            VStack(spacing: 12) {
                // Spending trend insight
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .wiseBlue,
                    title: "Spending Trend",
                    description: spendingChange >= 0
                        ? "You're spending \(String(format: "%.1f%%", spendingChange)) more than last month"
                        : "You're spending \(String(format: "%.1f%%", abs(spendingChange))) less than last month",
                    isPositive: spendingChange < 0
                )

                // Subscription insight
                if dataManager.subscriptions.filter({ $0.isActive }).count > 0 {
                    InsightRow(
                        icon: "creditcard.circle",
                        iconColor: .wiseBlue,
                        title: "Active Subscriptions",
                        description: "\(dataManager.subscriptions.filter { $0.isActive }.count) subscriptions costing $\(String(format: "%.0f", dataManager.calculateTotalMonthlyCost()))/month",
                        isPositive: true
                    )
                }

                // Balance insight
                if dataManager.people.filter({ $0.balance > 0 }).count > 0 {
                    let totalOwed = dataManager.people.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
                    InsightRow(
                        icon: "person.2.circle",
                        iconColor: .wiseBrightGreen,
                        title: "Money Owed to You",
                        description: "$\(String(format: "%.0f", totalOwed)) from \(dataManager.people.filter { $0.balance > 0 }.count) people",
                        isPositive: true
                    )
                }
            }
        }
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(description)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Upcoming Renewals Section
struct UpcomingRenewalsSection: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var dataManager: DataManager

    var upcomingRenewals: [Subscription] {
        let calendar = Calendar.current
        let today = Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!

        return dataManager.subscriptions
            .filter { subscription in
                subscription.isActive &&
                subscription.nextBillingDate >= today &&
                subscription.nextBillingDate <= nextWeek
            }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Renewals")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button("View All") {
                    selectedTab = 3 // Switch to Subscriptions tab
                }
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseForestGreen)
            }

            if upcomingRenewals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))

                    Text("No renewals in the next 7 days")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 10) {
                    ForEach(upcomingRenewals) { subscription in
                        NavigationLink(destination: SubscriptionDetailView(subscriptionId: subscription.id)) {
                            UpcomingRenewalRow(subscription: subscription)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming Renewal Row
struct UpcomingRenewalRow: View {
    let subscription: Subscription
    
    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let renewalDate = calendar.startOfDay(for: subscription.nextBillingDate)
        return calendar.dateComponents([.day], from: today, to: renewalDate).day ?? 0
    }
    
    var urgencyColor: Color {
        if daysUntilRenewal <= 2 {
            return .wiseError
        } else if daysUntilRenewal <= 4 {
            return .wiseOrange
        }
        return .wiseBlue
    }

    var urgencyText: String {
        if daysUntilRenewal == 0 {
            return "Today"
        } else if daysUntilRenewal == 1 {
            return "Tomorrow"
        } else {
            return "In \(daysUntilRenewal) days"
        }
    }

    var subtitle: String {
        return "\(subscription.billingCycle.rawValue) • \(urgencyText)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon (48x48)
            UnifiedIconCircle(
                icon: subscription.icon,
                color: Color(hexString: subscription.color),
                size: 48,
                iconSize: 20
            )

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(urgencyColor)
                    .lineLimit(1)
            }

            Spacer()

            // Price
            Text(String(format: "$%.2f", subscription.price))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Savings Opportunities Card
struct SavingsOpportunitiesCard: View {
    @EnvironmentObject var dataManager: DataManager

    var unusedSubscriptions: [Subscription] {
        // Mock logic - detect subscriptions that might be unused
        // In production, you'd track usage and determine based on that
        dataManager.subscriptions.filter { subscription in
            subscription.isActive && subscription.monthlyEquivalent > 15.0
        }.prefix(3).map { $0 }
    }

    var potentialSavings: Double {
        unusedSubscriptions.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var body: some View {
        if !unusedSubscriptions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Savings Opportunities")
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Potential savings summary
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.wiseBrightGreen.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.wiseBrightGreen)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Potential Monthly Savings")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text("Save up to $\(String(format: "%.0f", potentialSavings))/month by reviewing these subscriptions")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBrightGreen.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.wiseBrightGreen.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // List of subscriptions to review
                    Text("Review these subscriptions:")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.top, 4)

                    ForEach(unusedSubscriptions) { subscription in
                        HStack(spacing: 10) {
                            Image(systemName: subscription.category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(subscription.category.color)
                                .frame(width: 24, height: 24)

                            Text(subscription.name)
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            Text("$\(String(format: "%.2f", subscription.monthlyEquivalent))")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.wiseCardBackground)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Subscription Spending Section
struct SubscriptionSpendingSection: View {
    @EnvironmentObject var dataManager: DataManager

    var personalMonthlySpend: Double {
        dataManager.subscriptions.filter { $0.isActive }.reduce(0.0) { total, subscription in
            total + subscription.monthlyEquivalent
        }
    }

    var sharedMonthlySpend: Double {
        dataManager.subscriptions
            .filter { $0.isActive && $0.isShared }
            .reduce(0.0) { total, subscription in
                let monthlyEquivalent = subscription.monthlyEquivalent
                let costPerPerson = monthlyEquivalent / Double(subscription.sharedWith.count + 1)
                return total + costPerPerson
            }
    }

    var totalSubscriptionSpend: Double {
        personalMonthlySpend + sharedMonthlySpend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Subscription Spending")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
                
                Button(action: {
                    // Navigate to subscriptions tab - you can implement this
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.spotifyLabelMedium)
                        Image(systemName: "chevron.right")
                            .font(.spotifyCaptionMedium)
                    }
                    .foregroundColor(.wiseBodyText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.wiseBorder)
                    .clipShape(Capsule())
                }
            }
            
            // Subscription spending cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                // Personal Subscriptions Card
                SubscriptionSpendingCard(
                    icon: "person.fill",
                    iconColor: .wiseForestGreen,
                    title: "PERSONAL",
                    amount: String(format: "$%.0f/mo", personalMonthlySpend),
                    subtitle: "\(dataManager.subscriptions.filter { $0.isActive }.count) active"
                )

                // Shared Subscriptions Card
                SubscriptionSpendingCard(
                    icon: "person.2.fill",
                    iconColor: .wiseBlue,
                    title: "SHARED",
                    amount: String(format: "$%.0f/mo", sharedMonthlySpend),
                    subtitle: "0 accepted"
                )
            }
            
            // Total spending summary
            HStack {
                Text("Total monthly spending:")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                
                Spacer()
                
                Text(String(format: "$%.0f", totalSubscriptionSpend))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
    }
}

// MARK: - Subscription Spending Card
struct SubscriptionSpendingCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(amount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
            
            Text(subtitle)
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter: ActivityFilter = .all
    @State private var showingFilterSheet = false

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

        return Array(filtered
            .sorted(by: { $0.date > $1.date })
            .prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button(action: { showingFilterSheet = true }) {
                    HStack(spacing: 4) {
                        Text(selectedFilter.rawValue)
                            .font(.spotifyLabelMedium)
                        Image(systemName: "chevron.down")
                            .font(.spotifyCaptionMedium)
                    }
                    .foregroundColor(.wiseBodyText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.wiseBorder)
                    .clipShape(Capsule())
                }
            }

            // Recent transactions
            if recentTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 32))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))

                    Text("No transactions yet")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTransactions) { transaction in
                        NavigationLink(destination: TransactionDetailView(transactionId: transaction.id)) {
                            ListRowFactory.card(for: transaction, context: .feed)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            ActivityFilterSheet(selectedFilter: $selectedFilter, isPresented: $showingFilterSheet)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        } else {
            return "Just now"
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
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.wiseForestGreen)
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
                    .foregroundColor(.wiseForestGreen)
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
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Amount - Green for income, default for expense
            Text(amount)
                .font(.spotifyNumberMedium)
                .foregroundColor(isExpense ? .wisePrimaryText : .wiseBrightGreen)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Placeholder Views for Other Tabs
// MARK: - Recent Activity View (Feed)
struct RecentActivityView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedCategory: TransactionCategory? = nil
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var transactionToDelete: Transaction?
    @State private var showingDeleteAlert = false

    // Page 2: Advanced Filtering
    @State private var showingAdvancedFilterSheet = false
    @State private var advancedFilter = AdvancedTransactionFilter()
    @State private var savedPresets: [FilterPreset] = FilterPreset.defaults


    var filteredTransactions: [Transaction] {
        var filtered = dataManager.transactions

        // Page 2: Apply advanced filter if active
        if advancedFilter.hasActiveFilters {
            filtered = filtered.applyFilter(advancedFilter)
        } else {
            // Apply basic category filter
            if let selectedCategory = selectedCategory {
                filtered = filtered.filter { $0.category == selectedCategory }
            }

            // Apply basic time and type filters
            switch selectedFilter {
            case .all:
                break
            case .today:
                filtered = filtered.filter { Calendar.current.isDateInToday($0.date) }
            case .week:
                let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
                filtered = filtered.filter { $0.date >= weekAgo }
            case .month:
                let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                filtered = filtered.filter { $0.date >= monthAgo }
            case .expenses:
                filtered = filtered.filter { $0.isExpense }
            case .income:
                filtered = filtered.filter { !$0.isExpense }
            case .custom:
                // Custom date range filtering would be handled by separate date picker UI
                break
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.subtitle.localizedCaseInsensitiveContains(searchText) ||
                transaction.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                (transaction.merchant?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return filtered.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background that extends to all edges
                Color.wiseBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Search and Filter
                    FeedHeaderSection(
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        showingFilterSheet: $showingFilterSheet,
                        showingAddTransactionSheet: $showingAddTransactionSheet,
                        showingAdvancedFilterSheet: $showingAdvancedFilterSheet,
                        activeFilterCount: advancedFilter.activeFilterCount
                    )

                    // Category Filter Pills
                    CategoryFilterSection(
                        selectedCategory: $selectedCategory
                    )

                    // Transaction List
                    if filteredTransactions.isEmpty {
                        // Page 2: Enhanced Empty State
                        EnhancedFeedEmptyState(
                            onAddTransaction: { showingAddTransactionSheet = true },
                            onAddSampleData: nil,
                            isFiltered: advancedFilter.hasActiveFilters || selectedCategory != nil || selectedFilter != .all,
                            filterSummary: advancedFilter.hasActiveFilters ? "\(advancedFilter.activeFilterCount) filter(s) applied" : nil
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Page 2: Group transactions by date
                                let groupedTransactions = filteredTransactions.groupedByDateSections()
                                ForEach(groupedTransactions, id: \.sectionDate) { section in
                                    VStack(spacing: 12) {
                                        // Page 2: Date Group Header
                                        TransactionGroupHeader(
                                            date: section.sectionDate,
                                            transactionCount: section.transactions.count
                                        )

                                        ForEach(section.transactions) { transaction in
                                            NavigationLink(destination: TransactionDetailView(transactionId: transaction.id)) {
                                                ListRowFactory.card(for: transaction, context: .feed)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    HapticManager.shared.heavy()
                                                    transactionToDelete = transaction
                                                    showingDeleteAlert = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        .refreshable {
                            HapticManager.shared.pullToRefresh()
                            dataManager.loadAllData()
                            ToastManager.shared.showSuccess("Refreshed")
                        }
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .alert("Delete Transaction?", isPresented: $showingDeleteAlert, presenting: transactionToDelete) { transaction in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deleteTransaction(id: transaction.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { transaction in
            Text("This will permanently delete this \(transaction.isExpense ? "expense" : "income") of \(transaction.formattedAmount).")
        }
        .sheet(isPresented: $showingFilterSheet) {
            FeedFilterSheet(selectedFilter: $selectedFilter, showingFilterSheet: $showingFilterSheet)
        }
        .sheet(isPresented: $showingAddTransactionSheet) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddTransactionSheet,
                onTransactionAdded: { newTransaction in
                    do {
                        try dataManager.addTransaction(newTransaction)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
        }
        // Page 2: Advanced Filter Sheet
        .sheet(isPresented: $showingAdvancedFilterSheet) {
            AdvancedFilterSheet(filter: $advancedFilter, savedPresets: $savedPresets)
        }
    }
}

// MARK: - Feed Header Section
struct FeedHeaderSection: View {
    @Binding var searchText: String
    @Binding var selectedFilter: TransactionFilter
    @Binding var showingFilterSheet: Bool
    @Binding var showingAddTransactionSheet: Bool
    @Binding var showingAdvancedFilterSheet: Bool
    let activeFilterCount: Int

    @State private var isAddButtonPressed = false

    var body: some View {
        VStack(spacing: 16) {
            // Top Header
            HStack {
                Text("Feed")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                // Search and Add Buttons (matching Home screen design)
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.light()
                        // Focus on search bar or toggle search visibility
                        withAnimation {
                            // The search bar is already visible in the UI, so this button could scroll to it
                            // or we could add a showingSearch state if needed
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.wisePrimaryText)
                    }

                    HeaderActionButton(icon: "plus.circle.fill", color: .wiseForestGreen) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        showingAddTransactionSheet = true
                    }
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wiseSecondaryText)
                    .font(.system(size: 16))
                
                TextField("Search transactions...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.wiseSecondaryText)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.3))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Category Filter Section
struct CategoryFilterSection: View {
    @Binding var selectedCategory: TransactionCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories Button
                Button(action: { selectedCategory = nil }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(selectedCategory == nil ? .white : .wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedCategory == nil ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.6))
                    )
                }

                // Category Pills
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = selectedCategory == category ? nil : category
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(selectedCategory == category ? .white : category.color)
                            Text(category.rawValue)
                                .font(.spotifyLabelSmall)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color : Color.wiseBorder.opacity(0.6))
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Feed Transaction Row (Unified Design)
@available(*, deprecated, message: "Use UnifiedListRowV2 instead")
struct FeedTransactionRow: View {
    let transaction: Transaction
    @State private var isPressed = false

    // Phase 2: Income is GREEN, Expenses use default text color
    private var amountColor: Color {
        transaction.isExpense ? .wisePrimaryText : .wiseBrightGreen
    }

    private var displayTitle: String {
        // Use merchant name if available, otherwise use title
        if let merchant = transaction.merchant, !merchant.isEmpty {
            return merchant
        }
        return transaction.title
    }

    // Phase 2: New subtitle format - {direction} {status} – {paymentMethod} • {last4}
    // Examples: "← Received – Visa • 3366", "→ Sent – Apple Pay • 4521"
    private var displaySubtitle: String {
        var parts: [String] = []

        // Direction symbol
        let direction: String
        if transaction.isRecurring {
            direction = "↻"
        } else if transaction.isExpense {
            direction = "→ Sent"
        } else {
            direction = "← Received"
        }
        parts.append(direction)

        // Payment status (only if not completed)
        if transaction.paymentStatus != .completed {
            parts.append(transaction.paymentStatus.rawValue)
        }

        // Payment method and last 4 digits
        if let paymentMethod = transaction.paymentMethod {
            let methodName: String
            switch paymentMethod {
            case .creditCard:
                methodName = "Visa"  // Simplified for now
            case .debitCard:
                methodName = "Visa"
            case .applePay:
                methodName = "Apple Pay"
            case .googlePay:
                methodName = "Google Pay"
            case .paypal:
                methodName = "PayPal"
            case .bankTransfer:
                methodName = "Bank Transfer"
            case .other:
                methodName = paymentMethod.rawValue
            }

            // Generate mock last 4 digits based on transaction ID
            let last4 = String(format: "%04d", abs(transaction.id.hashValue % 10000))
            parts.append("\(methodName) • \(last4)")
        }

        return parts.joined(separator: " – ")
    }

    // Phase 2: Format amount with proper prefix
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        let absAmount = formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00"

        if transaction.isExpense {
            return "– \(absAmount)"  // en-dash for expenses
        } else {
            return "+ \(absAmount)"  // plus for income
        }
    }

    var body: some View {
        // Phase 2: Flat design - no card background, no shadow
        HStack(spacing: 12) {
            // Unified Icon Circle (48x48)
            UnifiedIconCircle(
                icon: transaction.category.icon,
                color: transaction.category.color
            )

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(displaySubtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Amount (right-aligned)
            Text(formattedAmount)
                .font(.spotifyNumberMedium)
                .foregroundColor(amountColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Tap animations and haptic feedback
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }, perform: {})
    }
}

// MARK: - Feed Filter Sheet
struct FeedFilterSheet: View {
    @Binding var selectedFilter: TransactionFilter
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        showingFilterSheet = false
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.wiseForestGreen)
                                .frame(width: 24)
                            
                            Text(filter.rawValue)
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.wiseBrightGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Add Transaction Sheet
struct AddTransactionSheet: View {
    @Binding var showingAddTransactionSheet: Bool
    let onTransactionAdded: (Transaction) -> Void

    @EnvironmentObject var dataManager: DataManager

    // Basic transaction fields
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var transactionType: TransactionType = .expense
    @State private var notes = ""

    // Split transaction fields (always active in new design)
    @State private var selectedPayer: Person?
    @State private var selectedParticipants: Set<UUID> = []
    @State private var splitType: SplitType = .equally
    @State private var participantAmounts: [UUID: Double] = [:]
    @State private var participantPercentages: [UUID: Double] = [:]
    @State private var participantShares: [UUID: Int] = [:]

    // Validation
    @State private var validationMessage: String?
    @State private var validationType: ValidationBanner.BannerType = .info

    // UI state for people selection
    @State private var showingPaidByPicker = false
    @State private var showingParticipantPicker = false

    enum TransactionType: String, CaseIterable {
        case expense = "Expense"
        case income = "Income"

        var color: Color {
            switch self {
            case .expense: return .wiseError
            case .income: return .wiseBrightGreen
            }
        }

        var icon: String {
            switch self {
            case .expense: return "arrow.down.circle.fill"
            case .income: return "arrow.up.circle.fill"
            }
        }
    }

    private var isFormValid: Bool {
        // Basic validation
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !amount.trimmingCharacters(in: .whitespaces).isEmpty,
              Double(amount) != nil else {
            return false
        }

        // Split validation - require at least one participant
        guard !selectedParticipants.isEmpty else { return false }

        if let validation = validateSplitConfiguration() {
            guard validation.isValid else { return false }
        }

        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            sheetHeader

            ScrollView {
                VStack(spacing: 20) {
                    // Transaction Name
                    transactionNameSection

                    // Total Amount with Currency
                    amountSection

                    // Category Selection
                    categorySection

                    // Paid By
                    paidBySection

                    // Split With
                    splitWithSection

                    // Split Method
                    splitMethodSection

                    // Notes
                    notesSection

                    // Validation Banner
                    if let message = validationMessage {
                        ValidationBanner(type: validationType, message: message)
                    }

                    // Submit Button
                    submitButton

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .background(Color.wiseBackground)
        .onChange(of: selectedCategory) { _, newCategory in
            transactionType = (newCategory == .income) ? .income : .expense
        }
        .onChange(of: amount) { _, _ in
            updateValidationMessage()
        }
        .onChange(of: selectedParticipants) { _, _ in
            updateValidationMessage()
        }
        .onChange(of: splitType) { _, newType in
            resetSplitInputs()
            initializeSplitDefaults(for: newType)
            updateValidationMessage()
        }
    }

    // MARK: - View Sections

    private var sheetHeader: some View {
        HStack {
            Text("New Split")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            Button(action: { showingAddTransactionSheet = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wisePrimaryText)
                    .frame(width: 32, height: 32)
                    .background(Color.wiseBorder.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var transactionNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Transaction Name", isRequired: false)

            TextField("e.g., Dinner at Mario's", text: $title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Total Amount", isRequired: false)

            HStack(spacing: 12) {
                // Amount input
                HStack(spacing: 8) {
                    Text("$")
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wiseSecondaryText)

                    TextField("0.00", text: $amount)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .keyboardType(.decimalPad)
                }
                .padding(16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )

                // Currency selector (static for now)
                HStack(spacing: 4) {
                    Text("USD")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Category", isRequired: false)

            CategoryHorizontalSelector(selectedCategory: $selectedCategory)
        }
    }

    private var paidBySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Paid By", isRequired: false)

            HStack(spacing: 12) {
                // Input field styled button
                Menu {
                    ForEach(Array(dataManager.people), id: \.id) { (person: Person) in
                        Button(action: {
                            HapticManager.shared.light()
                            selectedPayer = person
                        }) {
                            HStack {
                                Text(person.avatarType.displayValue)
                                Text(person.name)
                                if selectedPayer?.id == person.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedPayer?.name ?? "Phone number or email")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(selectedPayer != nil ? .wisePrimaryText : .wiseSecondaryText)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }

                // Add button
                Menu {
                    ForEach(Array(dataManager.people), id: \.id) { (person: Person) in
                        Button(action: {
                            HapticManager.shared.light()
                            selectedPayer = person
                        }) {
                            HStack {
                                Text(person.avatarType.displayValue)
                                Text(person.name)
                            }
                        }
                    }
                } label: {
                    Text("Add")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.wisePrimaryText)
                        .cornerRadius(12)
                }
            }

            Text("Leave empty if you paid")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)

            // Show selected payer chip if exists
            if let payer = selectedPayer {
                PersonSelectionChip(person: payer, showRemove: true) {
                    selectedPayer = nil
                }
            }
        }
    }

    private var splitWithSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Split With", isRequired: false)

            HStack(spacing: 12) {
                // Input field styled button
                Menu {
                    ForEach(Array(dataManager.people), id: \.id) { (person: Person) in
                        Button(action: { toggleParticipant(person.id) }) {
                            HStack {
                                Text(person.avatarType.displayValue)
                                Text(person.name)
                                if selectedParticipants.contains(person.id) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Phone number or email")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }

                // Add button
                Menu {
                    ForEach(Array(dataManager.people), id: \.id) { (person: Person) in
                        Button(action: { toggleParticipant(person.id) }) {
                            HStack {
                                Text(person.avatarType.displayValue)
                                Text(person.name)
                                if selectedParticipants.contains(person.id) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text("Add")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.wisePrimaryText)
                        .cornerRadius(12)
                }
            }

            Text("Add at least one person to split with")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)

            // Selected participants with inline inputs
            ForEach(Array(selectedParticipants), id: \.self) { personId in
                if let person = dataManager.people.first(where: { $0.id == personId }) {
                    participantChipView(person: person)
                }
            }
        }
    }

    private func participantChipView(person: Person) -> some View {
        HStack(spacing: 12) {
            AvatarView(avatarType: person.avatarType, size: .small, style: .solid)
                .frame(width: 32, height: 32)

            Text(person.name)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            participantInputField(for: person)

            Button(action: { toggleParticipant(person.id) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func participantInputField(for person: Person) -> some View {
        switch splitType {
        case .equally:
            let amount = calculateEqualAmount()
            Text(String(format: "$%.2f", amount))
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

        case .percentages:
            HStack(spacing: 4) {
                TextField("0", value: Binding(
                    get: { participantPercentages[person.id] ?? 0 },
                    set: { participantPercentages[person.id] = $0 }
                ), format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 50)
                .multilineTextAlignment(.trailing)
                .font(.spotifyBodyMedium)

                Text("%")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
            }

        case .shares:
            HStack(spacing: 4) {
                Stepper(
                    value: Binding(
                        get: { participantShares[person.id] ?? 1 },
                        set: { participantShares[person.id] = max(1, $0) }
                    ),
                    in: 1...10
                ) {
                    Text("\(participantShares[person.id] ?? 1)×")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }
            }

        case .exactAmounts, .adjustments:
            HStack(spacing: 4) {
                Text("$")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                TextField("0.00", value: Binding(
                    get: { participantAmounts[person.id] ?? 0 },
                    set: { participantAmounts[person.id] = $0 }
                ), format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                .font(.spotifyBodyMedium)
            }
        }
    }

    private var splitMethodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Split Method", isRequired: false)

            SplitMethodSelector(selectedType: $splitType)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Notes (Optional)", isRequired: false)

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Add details...")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(16)
                }

                TextEditor(text: $notes)
                    .font(.spotifyBodyMedium)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )
        }
    }

    private var submitButton: some View {
        Button(action: addTransaction) {
            Text("Create Split")
                .font(.spotifyBodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isFormValid ? Color.wisePrimaryText : Color.wiseBorder.opacity(0.5))
                .cornerRadius(12)
        }
        .disabled(!isFormValid)
    }

    // MARK: - Helper Methods

    private func calculateEqualAmount() -> Double {
        guard !selectedParticipants.isEmpty,
              let amountValue = Double(amount) else { return 0 }
        return amountValue / Double(selectedParticipants.count)
    }

    private func calculateAmount(for personId: UUID) -> Double {
        guard let amountValue = Double(amount) else { return 0 }

        switch splitType {
        case .equally:
            return calculateEqualAmount()

        case .percentages:
            let percentage = participantPercentages[personId] ?? 0
            return amountValue * (percentage / 100)

        case .shares:
            let shares = participantShares[personId] ?? 1
            let totalShares = participantShares.values.reduce(0, +)
            return totalShares > 0 ? amountValue * Double(shares) / Double(totalShares) : 0

        case .exactAmounts, .adjustments:
            return participantAmounts[personId] ?? 0
        }
    }

    private func validateSplitConfiguration() -> (isValid: Bool, message: String)? {
        guard let amountValue = Double(amount) else { return nil }

        switch splitType {
        case .equally:
            return (true, "Split equally among \(selectedParticipants.count) people")

        case .percentages:
            let total = participantPercentages.values.reduce(0, +)
            if abs(total - 100) < 0.1 {
                return (true, "Percentages add up to 100%")
            } else {
                return (false, "Percentages must add up to 100% (currently \(String(format: "%.1f", total))%)")
            }

        case .exactAmounts, .adjustments:
            let total = participantAmounts.values.reduce(0, +)
            if abs(total - amountValue) < 0.01 {
                return (true, "Amounts match total")
            } else {
                return (false, "Amounts must add up to $\(amount) (currently $\(String(format: "%.2f", total)))")
            }

        case .shares:
            return (true, "Split by shares")
        }
    }

    private func initializeSplitDefaults(for splitType: SplitType) {
        let amountValue = Double(amount) ?? 0
        let count = Double(selectedParticipants.count)

        switch splitType {
        case .equally:
            break

        case .percentages:
            let equalPercentage = count > 0 ? 100.0 / count : 0
            for personId in selectedParticipants {
                participantPercentages[personId] = equalPercentage
            }

        case .shares:
            for personId in selectedParticipants {
                participantShares[personId] = 1
            }

        case .exactAmounts, .adjustments:
            let equalAmount = count > 0 ? amountValue / count : 0
            for personId in selectedParticipants {
                participantAmounts[personId] = equalAmount
            }
        }
    }

    private func resetSplitInputs() {
        participantAmounts.removeAll()
        participantPercentages.removeAll()
        participantShares.removeAll()
    }

    private func toggleParticipant(_ personId: UUID) {
        HapticManager.shared.light()
        if selectedParticipants.contains(personId) {
            selectedParticipants.remove(personId)
            participantAmounts.removeValue(forKey: personId)
            participantPercentages.removeValue(forKey: personId)
            participantShares.removeValue(forKey: personId)
        } else {
            selectedParticipants.insert(personId)
            initializeSplitDefaults(for: splitType)
        }
    }

    private func updateValidationMessage() {
        if let validation = validateSplitConfiguration() {
            validationMessage = validation.message
            validationType = validation.isValid ? .success : .warning
        } else {
            validationMessage = nil
        }
    }

    private func addTransaction() {
        guard let amountValue = Double(amount) else { return }
        guard let payer = selectedPayer else { return }
        let finalAmount = transactionType == .expense ? -abs(amountValue) : abs(amountValue)

        var splitBillId: UUID? = nil

        // Create split bill - this is always a split transaction now
        let payerId = payer.id
        let participants = selectedParticipants.map { personId -> SplitParticipant in
            let amount = calculateAmount(for: personId)
            return SplitParticipant(
                personId: personId,
                amount: amount,
                hasPaid: personId == payerId,
                percentage: participantPercentages[personId],
                shares: participantShares[personId]
            )
        }

        let splitBill = SplitBill(
            title: title.trimmingCharacters(in: .whitespaces),
            totalAmount: abs(amountValue),
            paidById: payerId,
            splitType: splitType,
            participants: participants,
            notes: notes,
            category: selectedCategory,
            date: Date()
        )

        do {
            try dataManager.addSplitBill(splitBill)
            splitBillId = splitBill.id

            // Update balances for payer
            for participant in participants where participant.personId != payer.id {
                if var person = dataManager.people.first(where: { $0.id == participant.personId }) {
                    person.balance -= participant.amount
                    try dataManager.updatePerson(person)
                }
            }

            if var payerPerson = dataManager.people.first(where: { $0.id == payer.id }) {
                let totalOwed = participants
                    .filter { $0.personId != payer.id }
                    .reduce(0) { $0 + $1.amount }
                payerPerson.balance += totalOwed
                try dataManager.updatePerson(payerPerson)
            }
        } catch {
            print("Error creating split bill: \(error)")
            return
        }

        let newTransaction = Transaction(
            title: title.trimmingCharacters(in: .whitespaces),
            subtitle: "Split Transaction",
            amount: finalAmount,
            category: selectedCategory,
            date: Date(),
            isRecurring: false,
            tags: [],
            notes: notes,
            splitBillId: splitBillId
        )

        onTransactionAdded(newTransaction)
        HapticManager.shared.success()
        showingAddTransactionSheet = false
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    @Binding var selectedCategory: TransactionCategory
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            isPresented = false
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(category.color.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(category.color)
                                    )
                                
                                Text(category.rawValue)
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wisePrimaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.wiseCardBackground)
                                    .stroke(selectedCategory == category ? category.color : Color.wiseBorder, lineWidth: selectedCategory == category ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - People View
struct PeopleView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: PeopleTab = .people
    @State private var showingAddPersonSheet = false
    @State private var showingAddGroupSheet = false
    @State private var showSearchBar = false
    @State private var searchText = ""

    enum PeopleTab: String, CaseIterable {
        case people = "People"
        case groups = "Groups"
        
        var icon: String {
            switch self {
            case .people: return "person.2.fill"
            case .groups: return "person.3.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color.wiseBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fixed Header Section
                    VStack(spacing: 0) {
                        // Header
                        PeopleHeaderSection(
                            selectedTab: $selectedTab,
                            showingAddPersonSheet: $showingAddPersonSheet,
                            showingAddGroupSheet: $showingAddGroupSheet,
                            showSearchBar: $showSearchBar,
                            searchText: $searchText
                        )
                        .padding(.top, 10) // Standard top padding after safe area

                        // Quick Stats Cards
                        PeopleQuickStatsView(people: dataManager.people)

                        // No category filter section for People (Groups don't need filters like subscription categories)
                    }
                    .background(Color.wiseBackground)
                    .zIndex(1) // Keep header on top

                    // Content based on selected tab
                    if selectedTab == .people {
                        PeopleListView(people: dataManager.people, searchText: $searchText)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        GroupsListView(groups: dataManager.groups, people: dataManager.people, searchText: $searchText)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddPersonSheet) {
            AddPersonSheet(isPresented: $showingAddPersonSheet)
                .environmentObject(dataManager)
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddGroupSheet) {
            AddGroupSheet(
                showingAddGroupSheet: $showingAddGroupSheet,
                editingGroup: nil as Group?,
                people: dataManager.people,
                onGroupAdded: { group in
                    do {
                        try dataManager.addGroup(group)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
            .environmentObject(dataManager)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - People Header Section
struct PeopleHeaderSection: View {
    @Binding var selectedTab: PeopleView.PeopleTab
    @Binding var showingAddPersonSheet: Bool
    @Binding var showingAddGroupSheet: Bool
    @Binding var showSearchBar: Bool
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 16) {
            // Top Header (matching design system)
            HStack {
                Text("People")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                // Search and Add Buttons
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
                            .foregroundColor(showSearchBar ? .wiseBrightGreen : .wisePrimaryText)
                    }

                    HeaderActionButton(icon: "plus.circle.fill", color: .wiseForestGreen) {
                        HapticManager.shared.light()
                        if selectedTab == .people {
                            showingAddPersonSheet = true
                        } else {
                            showingAddGroupSheet = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            // Segmented Control
            HStack(spacing: 0) {
                ForEach(PeopleView.PeopleTab.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                            searchText = "" // Clear search when switching tabs
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.spotifyLabelLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .wiseBodyText)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTab == tab ? Color.wiseForestGreen : Color.clear)
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)

            // Search Bar (matching Feed design)
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.wiseSecondaryText)
                        .font(.system(size: 16))

                    TextField(selectedTab == .people ? "Search people..." : "Search groups...",
                              text: $searchText)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.wiseSecondaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBorder.opacity(0.3))
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 8) // Match Subscriptions header bottom padding
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationView {
            Text("Groups View")
                .navigationTitle("Groups")
        }
    }
}

// MARK: - People Quick Stats View
struct PeopleQuickStatsView: View {
    let people: [Person]

    var totalOwedToYou: Double {
        people.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
    }

    var totalYouOwe: Double {
        let negativeBalances = people.filter { $0.balance < 0 }
        return abs(negativeBalances.reduce(0) { $0 + $1.balance })
    }

    var owesYouCount: Int {
        people.filter { $0.balance > 0 }.count
    }

    var youOweCount: Int {
        people.filter { $0.balance < 0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1x2 Grid with owed amounts
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Owed to You Card
                PeopleStatCard(
                    title: "Owed to You",
                    amount: totalOwedToYou,
                    icon: "arrow.down.circle.fill",
                    color: .wiseBrightGreen,
                    isAmount: true,
                    peopleCount: owesYouCount
                )

                // You Owe Card
                PeopleStatCard(
                    title: "You Owe",
                    amount: totalYouOwe,
                    icon: "arrow.up.circle.fill",
                    color: .wiseError,
                    isAmount: true,
                    peopleCount: youOweCount
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - People Stat Card
struct PeopleStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let isAmount: Bool
    let isCount: Bool
    let peopleCount: Int

    init(title: String, amount: Double, icon: String, color: Color, isAmount: Bool = false, isCount: Bool = false, peopleCount: Int = 0) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.isAmount = isAmount
        self.isCount = isCount
        self.peopleCount = peopleCount
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()

                // People count indicator
                if peopleCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text("\(peopleCount)")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
                }
            }

            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(formattedAmount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Subscriptions View
struct SubscriptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: SubscriptionsTab = .personal
    @State private var showingAddSubscriptionSheet = false
    @State private var selectedFilter: SubscriptionFilter = .all
    @State private var selectedCategory: SubscriptionCategory? = nil
    @State private var searchText = ""
    @State private var showSearchBar = false
    @State private var showingFilterSheet = false
    @State private var showingInsightsSheet = false
    @State private var showingRenewalCalendarSheet = false
    @State private var viewMode: ViewMode = .list
    @State private var sortOption: SortOption = .name
    @State private var showingSortMenu = false

    enum ViewMode {
        case list, grid
    }

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case priceHighToLow = "Price: High to Low"
        case priceLowToHigh = "Price: Low to High"
        case nextBilling = "Next Billing"
        case dateAdded = "Date Added"

        var icon: String {
            switch self {
            case .name: return "textformat.abc"
            case .priceHighToLow, .priceLowToHigh: return "dollarsign.circle"
            case .nextBilling: return "calendar"
            case .dateAdded: return "clock"
            }
        }
    }

    enum SubscriptionsTab: String, CaseIterable {
        case personal = "Personal"
        case shared = "Shared"

        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .shared: return "person.2.fill"
            }
        }
    }

    var filteredPersonalSubscriptions: [Subscription] {
        var filtered = dataManager.subscriptions

        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .paused:
            filtered = filtered.filter { !$0.isActive && $0.cancellationDate == nil }
        case .cancelled:
            filtered = filtered.filter { $0.cancellationDate != nil }
        case .freeTrials:
            filtered = filtered.filter { $0.isFreeTrial && !$0.isTrialExpired }
        case .shared:
            filtered = filtered.filter { $0.isShared }
        case .expiringSoon:
            let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            filtered = filtered.filter { $0.nextBillingDate <= nextWeek && $0.isActive }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sorting
        switch sortOption {
        case .name:
            return filtered.sorted { $0.name < $1.name }
        case .priceHighToLow:
            return filtered.sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
        case .priceLowToHigh:
            return filtered.sorted { $0.monthlyEquivalent < $1.monthlyEquivalent }
        case .nextBilling:
            return filtered.sorted { $0.nextBillingDate < $1.nextBillingDate }
        case .dateAdded:
            return filtered.sorted { $0.createdDate > $1.createdDate }
        }
    }
    
    var totalMonthlySpend: Double {
        dataManager.subscriptions.filter { $0.isActive }.reduce(0.0) { total, subscription in
            total + subscription.monthlyEquivalent
        }
    }

    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }

    var nextBillingDate: Date? {
        dataManager.subscriptions
            .filter { $0.isActive }
            .map { $0.nextBillingDate }
            .min()
    }

    var upcomingBills: [Subscription] {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return dataManager.subscriptions
            .filter { $0.isActive && $0.nextBillingDate <= nextWeek }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color.wiseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header Section
                    VStack(spacing: 0) {
                        // Header with enhanced stats
                        SubscriptionsHeaderSectionEnhanced(
                            selectedTab: $selectedTab,
                            showingAddSubscriptionSheet: $showingAddSubscriptionSheet,
                            showingInsightsSheet: $showingInsightsSheet,
                            showingRenewalCalendarSheet: $showingRenewalCalendarSheet,
                            showSearchBar: $showSearchBar,
                            searchText: $searchText,
                            totalMonthlySpend: totalMonthlySpend,
                            totalAnnualSpend: totalAnnualSpend,
                            nextBillingDate: nextBillingDate,
                            upcomingBillsCount: upcomingBills.count
                        )
                        .padding(.top, 10) // Standard top padding after safe area

                        // Quick Stats Cards
                        SubscriptionQuickStatsView(
                            subscriptions: dataManager.subscriptions,
                            sharedSubscriptions: []
                        )
                        
                        // Category Filter Pills
                        SubscriptionsCategoryFilterSection(
                            selectedCategory: $selectedCategory
                        )
                    }
                    .background(Color.wiseBackground)
                    .zIndex(1) // Keep header on top
                    
                    // Content based on selected tab (using conditional rendering for better header stability)
                    if selectedTab == .personal {
                        EnhancedPersonalSubscriptionsView(
                            subscriptions: filteredPersonalSubscriptions,
                            searchText: $searchText,
                            selectedFilter: $selectedFilter,
                            showingFilterSheet: $showingFilterSheet,
                            viewMode: $viewMode,
                            sortOption: $sortOption,
                            showingSortMenu: $showingSortMenu
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        EnhancedSharedSubscriptionsView(
                            sharedSubscriptions: .constant([]),
                            searchText: $searchText,
                            people: dataManager.people
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
        }
        .sheet(isPresented: $showingAddSubscriptionSheet) {
            AddSubscriptionSheet(
                showingAddSubscriptionSheet: $showingAddSubscriptionSheet,
                onSubscriptionAdded: { newSubscription in
                    do {
                        try dataManager.addSubscription(newSubscription)
                    } catch {
                        dataManager.error = error
                    }
                }
            )
        }
        .sheet(isPresented: $showingFilterSheet) {
            SubscriptionsFilterSheet(
                selectedFilter: $selectedFilter,
                showingFilterSheet: $showingFilterSheet
            )
        }
        .sheet(isPresented: $showingInsightsSheet) {
            SubscriptionInsightsSheet(
                subscriptions: dataManager.subscriptions,
                showingInsightsSheet: $showingInsightsSheet
            )
        }
        .sheet(isPresented: $showingRenewalCalendarSheet) {
            RenewalCalendarSheet(
                subscriptions: dataManager.subscriptions,
                showingRenewalCalendarSheet: $showingRenewalCalendarSheet
            )
        }
    }
}

struct InsightsView: View {
    var body: some View {
        NavigationView {
            Text("Insights View")
                .navigationTitle("Insights")
        }
    }
}

// MARK: - Balance Summary Card (Redesigned with 2x2 Grid - Matching Home Screen)
struct BalanceSummaryCard: View {
    let totalOwedToYou: Double
    let totalYouOwe: Double
    let netBalance: Double
    let numberOfPeople: Int

    // Calculate trends (placeholder - in production, compare with previous period)
    private func calculateTrend(for type: String) -> (percentage: Double, isPositive: Bool) {
        switch type {
        case "balance":
            return netBalance >= 0 ? (5.2, true) : (2.1, false)
        case "people":
            return (0.0, true) // Neutral for count
        case "owed":
            return (3.5, true)
        case "owing":
            return (1.8, false)
        default:
            return (0, true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1x2 Grid with only owed amounts
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                // Owed to You Card
                EnhancedFinancialCard(
                    icon: "arrow.down.circle.fill",
                    iconColor: .wiseBrightGreen,
                    title: "OWED TO YOU",
                    amount: formatCurrency(totalOwedToYou),
                    trend: calculateTrend(for: "owed")
                )

                // You Owe Card
                EnhancedFinancialCard(
                    icon: "arrow.up.circle.fill",
                    iconColor: .wiseError,
                    title: "YOU OWE",
                    amount: formatCurrency(totalYouOwe),
                    trend: calculateTrend(for: "owing")
                )
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        String(format: "$%.0f", amount)
    }
}

// MARK: - People Filter Type
enum PeopleFilter: String, CaseIterable {
    case all = "All People"
    case owesYou = "Owes You"
    case youOwe = "You Owe"
    case settled = "Settled"
    case active = "Active"
}

// MARK: - People Sort Type
enum PeopleSort: String, CaseIterable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case balanceHighToLow = "Balance (High to Low)"
    case balanceLowToHigh = "Balance (Low to High)"
    case recentActivity = "Recent Activity"
    case dateAddedNewest = "Date Added (Newest)"
    case dateAddedOldest = "Date Added (Oldest)"
}

// MARK: - People Filter Pill
struct PeopleFilterPill: View {
    let filter: PeopleFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    private var displayText: String {
        switch filter {
        case .all: return "All"
        case .owesYou: return "Owes You"
        case .youOwe: return "You Owe"
        case .settled: return "Settled"
        case .active: return "Active"
        }
    }

    private var pillColor: Color {
        switch filter {
        case .all: return .wisePrimaryText
        case .owesYou: return .wiseBrightGreen
        case .youOwe: return .wiseError
        case .settled: return .wiseSecondaryText
        case .active: return .wiseBlue
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(displayText)
                    .font(.spotifyLabelMedium)

                if count > 0 && filter != .all {
                    Text("\(count)")
                        .font(.spotifyLabelSmall)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.wiseBorder.opacity(0.5))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .wisePrimaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? pillColor : Color.wiseBorder.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - People List View
struct PeopleListView: View {
    @EnvironmentObject var dataManager: DataManager
    let people: [Person]
    @Binding var searchText: String
    @State private var editingPerson: Person?
    @State private var showingEditSheet = false
    @State private var personToDelete: Person?
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: PeopleFilter = .all
    @State private var selectedSort: PeopleSort = .nameAscending
    @State private var showingSortMenu = false
    @State private var personToSettle: Person?
    @State private var showingSettleSheet = false
    @State private var showingSettleAllSheet = false
    @State private var isSelectionMode = false
    @State private var selectedPeople: Set<UUID> = []
    @State private var showingBulkReminderSheet = false

    var filteredPeople: [Person] {
        var result = people

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { person in
                person.name.localizedCaseInsensitiveContains(searchText) ||
                person.email.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply balance filter
        switch selectedFilter {
        case .all:
            break
        case .owesYou:
            result = result.filter { $0.balance > 0 }
        case .youOwe:
            result = result.filter { $0.balance < 0 }
        case .settled:
            result = result.filter { $0.balance == 0 }
        case .active:
            result = result.filter { $0.balance != 0 }
        }

        // Apply sorting
        switch selectedSort {
        case .nameAscending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .balanceHighToLow:
            result.sort { $0.balance > $1.balance }
        case .balanceLowToHigh:
            result.sort { $0.balance < $1.balance }
        case .recentActivity:
            // Sort by most recent transaction date
            result.sort { person1, person2 in
                let trans1 = dataManager.transactions.filter { trans in
                    trans.title.contains(person1.name) || trans.subtitle.contains(person1.name)
                }
                let trans2 = dataManager.transactions.filter { trans in
                    trans.title.contains(person2.name) || trans.subtitle.contains(person2.name)
                }
                let sortedTrans1 = trans1.sorted { $0.date > $1.date }
                let sortedTrans2 = trans2.sorted { $0.date > $1.date }
                let date1 = sortedTrans1.first?.date ?? Date.distantPast
                let date2 = sortedTrans2.first?.date ?? Date.distantPast
                return date1 > date2
            }
        case .dateAddedNewest:
            result.sort { $0.createdDate > $1.createdDate }
        case .dateAddedOldest:
            result.sort { $0.createdDate < $1.createdDate }
        }

        return result
    }

    // Balance calculations
    var totalOwedToYou: Double {
        let positiveBalances = people.filter { $0.balance > 0 }
        return positiveBalances.reduce(0) { $0 + $1.balance }
    }

    var totalYouOwe: Double {
        let negativeBalances = people.filter { $0.balance < 0 }
        let total = negativeBalances.reduce(0) { $0 + $1.balance }
        return abs(total)
    }

    var netBalance: Double {
        let owedToYou = totalOwedToYou
        let youOwe = totalYouOwe
        return owedToYou - youOwe
    }

    var numberOfPeople: Int {
        people.count
    }

    // Filter count helper
    func filterCount(for filter: PeopleFilter) -> Int {
        switch filter {
        case .all:
            return people.count
        case .owesYou:
            return people.filter { $0.balance > 0 }.count
        case .youOwe:
            return people.filter { $0.balance < 0 }.count
        case .settled:
            return people.filter { $0.balance == 0 }.count
        case .active:
            return people.filter { $0.balance != 0 }.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Pills and Sort Controls
            VStack(spacing: 12) {
                // Filter Pills - Horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PeopleFilter.allCases, id: \.self) { filter in
                            PeopleFilterPill(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                count: filterCount(for: filter)
                            ) {
                                HapticManager.shared.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Sort Button Row
                HStack(spacing: 12) {
                    // Sort Menu Button
                    Button(action: { showingSortMenu = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14))
                            Text("Sort")
                                .font(.spotifyLabelSmall)
                        }
                        .foregroundColor(.wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.wiseBorder.opacity(0.5))
                        )
                    }
                    .confirmationDialog("Sort By", isPresented: $showingSortMenu, titleVisibility: .visible) {
                        ForEach(PeopleSort.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                selectedSort = option
                                HapticManager.shared.lightImpact()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                    Spacer()

                    // People count indicator
                    Text("\(filteredPeople.count) \(filteredPeople.count == 1 ? "person" : "people")")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
            
            // People List
            if dataManager.isLoading && people.isEmpty {
                // Loading State
                SkeletonListView(rowCount: 5, rowType: .person)
            } else if filteredPeople.isEmpty {
                // Empty State
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
                                
                                Image(systemName: "person.2")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundColor(.wiseSecondaryText.opacity(0.5))
                            }
                            
                            // Text Content - Professional spacing and sizing
                            VStack(spacing: 12) {
                                Text("No People Yet")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("Add your first person to start\ntracking expenses")
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
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPeople) { person in
                            if isSelectionMode {
                                // Selection mode: Tap to select/deselect
                                Button(action: {
                                    if selectedPeople.contains(person.id) {
                                        selectedPeople.remove(person.id)
                                    } else {
                                        selectedPeople.insert(person.id)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        // Selection indicator
                                        Image(systemName: selectedPeople.contains(person.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedPeople.contains(person.id) ? .wiseForestGreen : .wiseSecondaryText)
                                            .font(.system(size: 24))

                                        ListRowFactory.card(for: person, transactions: dataManager.transactions)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Normal mode: Navigation
                                NavigationLink(destination: PersonDetailView(personId: person.id)) {
                                    ListRowFactory.card(for: person, transactions: dataManager.transactions)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.heavy()
                                        personToDelete = person
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        HapticManager.shared.light()
                                        editingPerson = person
                                        showingEditSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)

                                    // Show Settle Balance only if there's a non-zero balance
                                    if person.balance != 0 {
                                        Button {
                                            HapticManager.shared.success()
                                            personToSettle = person
                                            showingSettleSheet = true
                                        } label: {
                                            Label("Settle", systemImage: "checkmark.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
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
        .sheet(isPresented: $showingEditSheet) {
            if let person = editingPerson {
                EditPersonSheet(
                    showingEditPersonSheet: $showingEditSheet,
                    editingPerson: person,
                    onPersonUpdated: { updatedPerson in
                        do {
                            try dataManager.updatePerson(updatedPerson)
                        } catch {
                            dataManager.error = error
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettleSheet) {
            if let person = personToSettle {
                SettleUpSheet(person: person, onSettled: {
                    var updatedPerson = person
                    updatedPerson.balance = 0.0
                    do {
                        try dataManager.updatePerson(updatedPerson)
                        ToastManager.shared.showSuccess("Balance settled with \(person.name)")
                    } catch {
                        dataManager.error = error
                    }
                })
                .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingSettleAllSheet) {
            SettleAllBalancesSheet(
                people: people.filter { $0.balance != 0 },
                onSettled: {
                    // Update all people with non-zero balances to zero
                    for person in people where person.balance != 0 {
                        var updatedPerson = person
                        updatedPerson.balance = 0.0
                        do {
                            try dataManager.updatePerson(updatedPerson)
                        } catch {
                            dataManager.error = error
                        }
                    }
                    let count = people.filter { $0.balance != 0 }.count
                    ToastManager.shared.showSuccess("Settled \(count) balance\(count == 1 ? "" : "s")")
                }
            )
        }
        .sheet(isPresented: $showingBulkReminderSheet) {
            BulkReminderSheet(
                people: people.filter { selectedPeople.contains($0.id) },
                onRemindersSent: {
                    let count = selectedPeople.count
                    isSelectionMode = false
                    selectedPeople.removeAll()
                    ToastManager.shared.showSuccess("Reminders sent to \(count) \(count == 1 ? "person" : "people")")
                }
            )
        }
        .toolbar {
            // Leading: Cancel button in selection mode
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelectionMode {
                    Button("Cancel") {
                        isSelectionMode = false
                        selectedPeople.removeAll()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }

            // Trailing: Action buttons
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if isSelectionMode {
                        // Show Send button in selection mode
                        Button(action: {
                            if !selectedPeople.isEmpty {
                                showingBulkReminderSheet = true
                            }
                        }) {
                            Text("Send (\(selectedPeople.count))")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(selectedPeople.isEmpty ? .wiseSecondaryText : .wiseForestGreen)
                        }
                        .disabled(selectedPeople.isEmpty)
                    } else {
                        // Normal mode buttons
                        if !people.isEmpty {
                            Button(action: {
                                isSelectionMode = true
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.wiseBlue)
                            }
                        }

                        if people.contains(where: { $0.balance != 0 }) {
                            Button(action: {
                                showingSettleAllSheet = true
                            }) {
                                Text("Settle All")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseForestGreen)
                            }
                        }
                    }
                }
            }
        }
        .alert("Delete \(personToDelete?.name ?? "Person")?", isPresented: $showingDeleteAlert, presenting: personToDelete) { person in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deletePerson(id: person.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { person in
            Text("This will permanently delete \(person.name) and all associated data.")
        }
    }
}

// MARK: - Person Row View (Unified Design)
@available(*, deprecated, message: "Use UnifiedAvatarRow instead")
struct PersonRowView: View {
    let person: Person
    let transactions: [Transaction]

    // IMPORTANT: Positive balance (owes you) = GREEN, Negative (you owe) = RED
    private var balanceColor: Color {
        if person.balance > 0 {
            return .wiseBrightGreen // They owe you - GREEN
        } else if person.balance < 0 {
            return .wiseError // You owe them - RED
        } else {
            return .wiseSecondaryText // Settled - gray
        }
    }

    private var directionSymbol: String {
        if person.balance > 0 {
            return "←" // They owe you
        } else if person.balance < 0 {
            return "→" // You owe them
        } else {
            return "✓" // Settled
        }
    }

    private var balanceStatus: String {
        if person.balance > 0 {
            return "Owes you"
        } else if person.balance < 0 {
            return "You owe"
        } else {
            return "Settled"
        }
    }

    private var formattedBalance: String {
        formatCurrency(abs(person.balance))
    }

    private var lastActivityTime: String {
        let personTransactions = transactions.filter { transaction in
            transaction.title.contains(person.name) || transaction.subtitle.contains(person.name)
        }

        guard let lastTransaction = personTransactions.sorted(by: { $0.date > $1.date }).first else {
            return "no activity"
        }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: lastTransaction.date, to: now)

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if let days = components.day, days > 0 {
            if days == 1 {
                return "yesterday"
            } else if days < 7 {
                return "\(days) days ago"
            } else {
                let weeks = days / 7
                return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
            }
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        } else {
            return "just now"
        }
    }

    private var displaySubtitle: String {
        // Format: {direction} {balanceStatus} • Last activity {relativeTime}
        return "\(directionSymbol) \(balanceStatus) • Last activity \(lastActivityTime)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar as the icon (48x48 for .large size)
            AvatarView(person: person, size: .large, style: .gradient)

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(displaySubtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Value Area - Single amount, right-aligned
            Text(formattedBalance)
                .font(.spotifyNumberMedium)
                .foregroundColor(balanceColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settle All Balances Sheet
struct SettleAllBalancesSheet: View {
    @Environment(\.dismiss) var dismiss

    let people: [Person]
    let onSettled: () -> Void

    var totalOwedToYou: Double {
        people.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
    }

    var totalYouOwe: Double {
        abs(people.filter { $0.balance < 0 }.reduce(0) { $0 + $1.balance })
    }

    var netBalance: Double {
        people.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.wiseForestGreen)

                        Text("Settle All Balances")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)

                        Text("You're about to settle \(people.count) balance\(people.count == 1 ? "" : "s")")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(.top, 20)

                    // Balance Summary
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Owed to You")
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                                Text(String(format: "$%.2f", totalOwedToYou))
                                    .font(.spotifyNumberMedium)
                                    .foregroundColor(.wiseBrightGreen)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total You Owe")
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                                Text(String(format: "$%.2f", totalYouOwe))
                                    .font(.spotifyNumberMedium)
                                    .foregroundColor(.wiseError)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Net Balance")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            Text(String(format: "$%.2f", abs(netBalance)))
                                .font(.spotifyNumberLarge)
                                .foregroundColor(netBalance >= 0 ? .wiseBrightGreen : .wiseError)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                            .cardShadow()
                    )

                    // People List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("People to Settle (\(people.count))")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        VStack(spacing: 8) {
                            ForEach(people) { person in
                                HStack(spacing: 12) {
                                    AvatarView(person: person, size: .medium, style: .solid)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(person.name)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)

                                        Text(person.balance > 0 ? "Owes you" : "You owe")
                                            .font(.spotifyCaptionSmall)
                                            .foregroundColor(.wiseSecondaryText)
                                    }

                                    Spacer()

                                    Text(String(format: "$%.2f", abs(person.balance)))
                                        .font(.spotifyNumberMedium)
                                        .foregroundColor(person.balance > 0 ? .wiseBrightGreen : .wiseError)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.wiseBorder.opacity(0.2))
                                )
                            }
                        }
                    }

                    // Warning Message
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.wiseWarning)

                        Text("This will mark all balances as settled. This action cannot be undone.")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseWarning.opacity(0.1))
                    )

                    // Settle Button
                    Button(action: {
                        onSettled()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Settle All Balances")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Settle All")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

// MARK: - Bulk Reminder Sheet
struct BulkReminderSheet: View {
    @Environment(\.dismiss) var dismiss

    let people: [Person]
    let onRemindersSent: () -> Void

    @State private var customMessage = ""
    @State private var reminderMethod: ReminderMethod = .message

    enum ReminderMethod: String, CaseIterable {
        case message = "Message"
        case email = "Email"
        case whatsapp = "WhatsApp"
        case copy = "Copy Message"

        var icon: String {
            switch self {
            case .message: return "message.fill"
            case .email: return "envelope.fill"
            case .whatsapp: return "phone.bubble.left.fill"
            case .copy: return "doc.on.doc.fill"
            }
        }

        var color: Color {
            switch self {
            case .message: return .wiseBlue
            case .email: return .wiseForestGreen
            case .whatsapp: return .green
            case .copy: return .wiseSecondaryText
            }
        }
    }

    var defaultMessage: String {
        "Hi! Just a friendly reminder about our outstanding balance. Please let me know when you'd like to settle up. Thanks!"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.wiseBlue)

                        Text("Send Reminders")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)

                        Text("Send payment reminders to \(people.count) people")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(.top, 20)

                    // People List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recipients (\(people.count))")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        VStack(spacing: 8) {
                            ForEach(people) { person in
                                HStack(spacing: 12) {
                                    AvatarView(person: person, size: .medium, style: .solid)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(person.name)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)

                                        if person.balance != 0 {
                                            Text(person.balance > 0 ? "Owes you \(String(format: "$%.2f", abs(person.balance)))" : "You owe \(String(format: "$%.2f", abs(person.balance)))")
                                                .font(.spotifyCaptionSmall)
                                                .foregroundColor(person.balance > 0 ? .wiseBrightGreen : .wiseError)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.wiseBorder.opacity(0.2))
                                )
                            }
                        }
                    }

                    // Reminder Method Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Send via")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        ForEach(ReminderMethod.allCases, id: \.self) { method in
                            Button(action: { reminderMethod = method }) {
                                HStack(spacing: 12) {
                                    Image(systemName: method.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(reminderMethod == method ? .white : method.color)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(reminderMethod == method ? method.color : method.color.opacity(0.1))
                                        )

                                    Text(method.rawValue)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()

                                    if reminderMethod == method {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.wiseForestGreen)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(reminderMethod == method ? Color.wiseBorder.opacity(0.3) : Color.clear)
                                )
                            }
                        }
                    }

                    // Message Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        TextEditor(text: $customMessage)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                            .frame(height: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.3))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )

                        Button(action: { customMessage = defaultMessage }) {
                            Text("Use Default Message")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseBlue)
                        }
                    }

                    // Send Button
                    Button(action: sendReminders) {
                        HStack {
                            Spacer()
                            Image(systemName: reminderMethod.icon)
                                .font(.system(size: 16))
                            Text("Send to \(people.count) People")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(Color.wiseBlue)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Send Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .onAppear {
            customMessage = defaultMessage
        }
    }

    private func sendReminders() {
        // In a real implementation, this would actually send the reminders
        // For now, we'll just show the share sheet or copy to clipboard
        switch reminderMethod {
        case .copy:
            UIPasteboard.general.string = customMessage
            onRemindersSent()
            dismiss()
        case .message, .email, .whatsapp:
            // In a real app, you would loop through each person and open their messaging app
            // For now, we'll just confirm the action
            onRemindersSent()
            dismiss()
        }
    }
}

// MARK: - Groups List View
struct GroupsListView: View {
    @EnvironmentObject var dataManager: DataManager
    let groups: [Group]
    let people: [Person]
    @Binding var searchText: String
    @State private var editingGroup: Group?
    @State private var showingEditSheet = false
    @State private var groupToDelete: Group?
    @State private var showingDeleteAlert = false
    @State private var selectedSort: GroupSort = .nameAscending
    @State private var showingSortMenu = false

    enum GroupSort: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case memberCount = "Members"
        case expenseCount = "Expenses"
        case totalAmount = "Total Amount"
    }

    var filteredGroups: [Group] {
        var result = groups

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sorting
        switch selectedSort {
        case .nameAscending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .memberCount:
            result.sort { $0.members.count > $1.members.count }
        case .expenseCount:
            result.sort { $0.expenses.count > $1.expenses.count }
        case .totalAmount:
            result.sort { $0.totalAmount > $1.totalAmount }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sort Controls Row
            HStack(spacing: 12) {
                // Sort Menu Button
                Button(action: { showingSortMenu = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                        Text("Sort")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseBorder.opacity(0.5))
                    )
                }
                .confirmationDialog("Sort By", isPresented: $showingSortMenu, titleVisibility: .visible) {
                    ForEach(GroupSort.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            selectedSort = option
                            HapticManager.shared.lightImpact()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                Spacer()

                // Groups count indicator
                Text("\(filteredGroups.count) \(filteredGroups.count == 1 ? "group" : "groups")")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Groups List
            if dataManager.isLoading && groups.isEmpty {
                // Loading State
                SkeletonListView(rowCount: 5, rowType: .group)
            } else if filteredGroups.isEmpty {
                // Empty State
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
                                
                                Image(systemName: "person.3")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundColor(.wiseSecondaryText.opacity(0.5))
                            }
                            
                            // Text Content - Professional spacing and sizing
                            VStack(spacing: 12) {
                                Text("No Groups Yet")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("Create your first group to track\nshared expenses")
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
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredGroups) { group in
                            NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                                ListRowFactory.card(for: group)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    HapticManager.shared.heavy()
                                    groupToDelete = group
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    HapticManager.shared.light()
                                    editingGroup = group
                                    showingEditSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
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
        .sheet(isPresented: $showingEditSheet) {
            if let group = editingGroup {
                AddGroupSheet(
                    showingAddGroupSheet: $showingEditSheet,
                    editingGroup: group,
                    people: people,
                    onGroupAdded: { updatedGroup in
                        do {
                            try dataManager.updateGroup(updatedGroup)
                        } catch {
                            dataManager.error = error
                        }
                    }
                )
                .environmentObject(dataManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .alert("Delete \(groupToDelete?.name ?? "Group")?", isPresented: $showingDeleteAlert, presenting: groupToDelete) { group in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deleteGroup(id: group.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { group in
            Text("This will delete the group and all \(group.expenses.count) expenses.")
        }
    }
}

// MARK: - Group Row View (Unified Design)
@available(*, deprecated, message: "Use UnifiedListRowV2 with emoji icon instead")
struct GroupRowView: View {
    let group: Group
    let people: [Person]

    private var memberCountText: String {
        return "\(group.members.count) member\(group.members.count == 1 ? "" : "s")"
    }

    private var expenseCountText: String {
        return "\(group.expenses.count) expense\(group.expenses.count == 1 ? "" : "s")"
    }

    private var displaySubtitle: String {
        // Format: {memberCount} members • {expenseCount} expenses
        return "\(memberCountText) • \(expenseCountText)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Unified Emoji Circle (48x48)
            UnifiedEmojiCircle(
                emoji: group.emoji,
                backgroundColor: .wiseBlue
            )

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(displaySubtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Value Area - Single amount, right-aligned
            Text(formatCurrency(group.totalAmount))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Avatar Picker Sheet

struct AvatarPickerSheet: View {
    @Binding var selectedAvatarType: AvatarType
    @Binding var isPresented: Bool
    let personName: String  // For generating initials

    @State private var selectedTab = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedEmoji = "👨🏻‍💼"
    @State private var selectedColorIndex = 0
    @State private var isProcessingImage = false

    // Expanded emoji list with diverse options
    private let availableEmojis = [
        "👨🏻‍💼", "👩🏻‍💼", "👨🏼‍💼", "👩🏼‍💼", "👨🏽‍💼", "👩🏽‍💼",
        "👨🏾‍💼", "👩🏾‍💼", "👨🏿‍💼", "👩🏿‍💼", "🧑🏻‍💻", "🧑🏼‍💻",
        "🧑🏽‍💻", "🧑🏾‍💻", "🧑🏿‍💻", "👨🏻‍🎓", "👩🏻‍🎓", "👨🏼‍🎓",
        "👩🏼‍🎓", "👨🏽‍🎓", "👩🏽‍🎓", "👨🏾‍🎓", "👩🏾‍🎓", "👨🏿‍🎓",
        "👩🏿‍🎓", "🧑🏻‍🎨", "🧑🏼‍🎨", "🧑🏽‍🎨", "🧑🏾‍🎨", "🧑🏿‍🎨",
        "👨🏻‍⚕️", "👩🏻‍⚕️", "👨🏼‍⚕️", "👩🏼‍⚕️", "👨🏽‍⚕️", "👩🏽‍⚕️",
        "😊", "😎", "🤓", "😇", "🥳", "🤗", "😍", "🤩", "😺", "🐶",
        "🦊", "🐼", "🦁", "🐯", "🐸", "🐙", "🦋", "🌸", "⭐️", "🔥"
    ]

    private var previewAvatarType: AvatarType {
        switch selectedTab {
        case 0: // Photo
            if case .photo(let data) = selectedAvatarType, selectedPhotoItem == nil {
                return .photo(data)
            }
            return .initials(AvatarGenerator.generateInitials(from: personName), colorIndex: 0)
        case 1: // Emoji
            return .emoji(selectedEmoji)
        case 2: // Initials
            return .initials(AvatarGenerator.generateInitials(from: personName), colorIndex: selectedColorIndex)
        default:
            return .emoji("👤")
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Preview Section
                VStack(spacing: 16) {
                    ZStack {
                        // Preview avatar
                        AvatarView(avatarType: previewAvatarType, size: .xlarge, style: .solid)

                        // Loading overlay
                        if isProcessingImage {
                            Circle()
                                .fill(Color.wiseOverlayColor)
                                .frame(width: 64, height: 64)

                            ProgressView()
                                .tint(.white)
                        }
                    }

                    Text("Choose Your Avatar")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .background(Color.wiseBorder.opacity(0.3))

                // Tab Selector
                Picker("Avatar Source", selection: $selectedTab) {
                    Label("Photo", systemImage: "photo").tag(0)
                    Label("Emoji", systemImage: "face.smiling").tag(1)
                    Label("Initials", systemImage: "textformat").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Photo Tab
                    photoPickerView.tag(0)

                    // Emoji Tab
                    emojiGridView.tag(1)

                    // Initials Tab
                    initialsBuilderView.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Select Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAvatar()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.wiseForestGreen)
                    )
                    .disabled(isProcessingImage)
                }
            }
        }
    }

    // MARK: - Photo Picker View
    private var photoPickerView: some View {
        VStack(spacing: 20) {
            Spacer()

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseForestGreen)

                    Text("Choose from Photos")
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)

                    Text("Select any photo or saved Memoji from your library")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.wiseBrightGreen.opacity(0.1))
                        .stroke(Color.wiseBrightGreen.opacity(0.3), lineWidth: 2)
                        .shadow(color: .wiseBrightGreen.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 16)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    await loadPhoto(from: newValue)
                }
            }

            Spacer()
        }
    }

    // MARK: - Emoji Grid View
    private var emojiGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    Button(action: { selectedEmoji = emoji }) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.3))
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedEmoji == emoji ? Color.wiseForestGreen : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Initials Builder View
    private var initialsBuilderView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Show generated initials
            VStack(spacing: 12) {
                Text("Your Initials")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)

                Text(AvatarGenerator.generateInitials(from: personName))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.wisePrimaryText)
            }

            // Color selection
            VStack(spacing: 12) {
                Text("Choose Color")
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: 16) {
                    ForEach(0..<AvatarColorPalette.colors.count, id: \.self) { index in
                        Button(action: { selectedColorIndex = index }) {
                            Circle()
                                .fill(AvatarColorPalette.color(for: index))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColorIndex == index ? Color.wisePrimaryText : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .shadow(
                                    color: selectedColorIndex == index ? Color.wiseShadowColor : Color.clear,
                                    radius: 4, x: 0, y: 2
                                )
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Methods
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isProcessingImage = true
        defer { isProcessingImage = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let processedData = AvatarGenerator.processImage(uiImage) {
                selectedAvatarType = .photo(processedData)
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    private func saveAvatar() {
        switch selectedTab {
        case 0: // Photo - already set in loadPhoto
            break
        case 1: // Emoji
            selectedAvatarType = .emoji(selectedEmoji)
        case 2: // Initials
            selectedAvatarType = .initials(
                AvatarGenerator.generateInitials(from: personName),
                colorIndex: selectedColorIndex
            )
        default:
            break
        }

        isPresented = false
    }
}

// MARK: - Smart Input Type Detection
enum PersonInputType {
    case email
    case phone
    case name

    static func detect(_ input: String) -> PersonInputType {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Email detection: contains @
        if trimmed.contains("@") {
            return .email
        }

        // Phone detection: starts with + or is mostly digits
        let digitsOnly = trimmed.filter { $0.isNumber }
        let formattingChars = trimmed.filter { $0.isNumber || $0 == " " || $0 == "-" || $0 == "(" || $0 == ")" || $0 == "+" }
        if trimmed.hasPrefix("+") || (digitsOnly.count >= 7 && formattingChars.count == trimmed.count) {
            return .phone
        }

        // Default to name
        return .name
    }
}

// MARK: - Add Person Sheet (Simplified Smart Input)
struct AddPersonSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dataManager: DataManager

    @State private var inputValue = ""
    @FocusState private var isFocused: Bool

    private var detectedType: PersonInputType {
        PersonInputType.detect(inputValue)
    }

    private var isFormValid: Bool {
        !inputValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Person")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            TextField("Name, Phone, or Email", text: $inputValue)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
                .focused($isFocused)

            Button(action: handleAdd) {
                Text("Add")
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isFormValid ? Color.wiseForestGreen : Color.wiseSecondaryText.opacity(0.2))
                    .cornerRadius(12)
            }
            .disabled(!isFormValid)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wiseGroupedBackground)
        .onAppear { isFocused = true }
    }

    private func handleAdd() {
        let trimmedInput = inputValue.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return }

        var name = ""
        var email = ""
        var phone = ""

        switch detectedType {
        case .email:
            email = trimmedInput
            // Extract name from email prefix
            name = trimmedInput.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").capitalized ?? trimmedInput
        case .phone:
            phone = trimmedInput
            name = trimmedInput
        case .name:
            name = trimmedInput
        }

        // Check for existing person by email or phone
        let existingPerson = dataManager.people.first { person in
            (!email.isEmpty && person.email.lowercased() == email.lowercased()) ||
            (!phone.isEmpty && person.phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") == phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: ""))
        }

        if existingPerson != nil {
            // Person already exists
            ToastManager.shared.showInfo("Person already exists")
        } else {
            // Create new person with auto-generated avatar
            let newPerson = Person(
                name: name,
                email: email,
                phone: phone,
                avatarType: .initials(
                    AvatarGenerator.generateInitials(from: name),
                    colorIndex: AvatarColorPalette.colorIndex(for: name)
                )
            )

            do {
                try dataManager.addPerson(newPerson)
                ToastManager.shared.showSuccess("Person added!")
            } catch {
                dataManager.error = error
            }
        }

        inputValue = ""
        isPresented = false
    }
}

// MARK: - Edit Person Sheet (Full Featured)
struct EditPersonSheet: View {
    @Binding var showingEditPersonSheet: Bool
    let editingPerson: Person
    let onPersonUpdated: (Person) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedAvatarType: AvatarType = .initials("", colorIndex: 0)
    @State private var showingAvatarPicker = false
    @State private var showingContactPicker = false

    // Initialize with existing person data
    init(showingEditPersonSheet: Binding<Bool>, editingPerson: Person, onPersonUpdated: @escaping (Person) -> Void) {
        self._showingEditPersonSheet = showingEditPersonSheet
        self.editingPerson = editingPerson
        self.onPersonUpdated = onPersonUpdated

        _name = State(initialValue: editingPerson.name)
        _email = State(initialValue: editingPerson.email)
        _phone = State(initialValue: editingPerson.phone)
        _selectedAvatarType = State(initialValue: editingPerson.avatarType)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Auto-update initials when name changes
    private var currentInitials: String {
        AvatarGenerator.generateInitials(from: name)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Avatar")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Button(action: { showingAvatarPicker = true }) {
                            HStack(spacing: 16) {
                                // Show current avatar or default initials
                                if case .initials = selectedAvatarType, !currentInitials.isEmpty {
                                    AvatarView(
                                        avatarType: .initials(currentInitials, colorIndex: AvatarColorPalette.colorIndex(for: name)),
                                        size: .large,
                                        style: .solid
                                    )
                                } else {
                                    AvatarView(avatarType: selectedAvatarType, size: .large, style: .solid)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choose Avatar")
                                        .font(.spotifyHeadingSmall)
                                        .foregroundColor(.wisePrimaryText)

                                    Text("Select photo, emoji, or use initials")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.3))
                            )
                        }
                    }

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., John Smith", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: name) { oldValue, newValue in
                                    // Auto-generate initials avatar as default
                                    if case .initials = selectedAvatarType, !newValue.isEmpty {
                                        selectedAvatarType = .initials(
                                            AvatarGenerator.generateInitials(from: newValue),
                                            colorIndex: AvatarColorPalette.colorIndex(for: newValue)
                                        )
                                    } else if case .initials = selectedAvatarType {
                                        selectedAvatarType = .initials("", colorIndex: 0)
                                    }
                                }
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., john@example.com", text: $email)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Phone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., +1 234 567 8900", text: $phone)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.phonePad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditPersonSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePerson()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerSheet(
                    selectedAvatarType: $selectedAvatarType,
                    isPresented: $showingAvatarPicker,
                    personName: name.isEmpty ? "User" : name
                )
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(
                    name: $name,
                    email: $email,
                    phone: $phone,
                    isPresented: $showingContactPicker
                )
            }
        }
        .onAppear {
            // Initialize with initials avatar if needed
            if case .initials = selectedAvatarType, !name.isEmpty {
                selectedAvatarType = .initials(
                    AvatarGenerator.generateInitials(from: name),
                    colorIndex: AvatarColorPalette.colorIndex(for: name)
                )
            }
        }
    }

    private func savePerson() {
        // Ensure we have the latest initials if still using initials avatar
        var finalAvatarType = selectedAvatarType
        if case .initials = selectedAvatarType {
            finalAvatarType = .initials(
                AvatarGenerator.generateInitials(from: name),
                colorIndex: AvatarColorPalette.colorIndex(for: name)
            )
        }

        var updatedPerson = editingPerson
        updatedPerson.name = name.trimmingCharacters(in: .whitespaces)
        updatedPerson.email = email.trimmingCharacters(in: .whitespaces)
        updatedPerson.phone = phone.trimmingCharacters(in: .whitespaces)
        updatedPerson.avatarType = finalAvatarType

        onPersonUpdated(updatedPerson)
        showingEditPersonSheet = false
    }
}

// MARK: - Add Group Sheet
struct AddGroupSheet: View {
    @Binding var showingAddGroupSheet: Bool
    @EnvironmentObject var dataManager: DataManager
    let editingGroup: Group? // nil = add mode, Group = edit mode
    let people: [Person]
    let onGroupAdded: (Group) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var selectedEmoji = "👥"
    @State private var selectedMembers: Set<UUID> = []
    @State private var showingAddPersonSheet = false
    @State private var showingEmojiPicker = false
    @State private var personCountBeforeAdd = 0
    @FocusState private var isNameFocused: Bool

    // Initialize with default values or existing group data
    init(showingAddGroupSheet: Binding<Bool>, editingGroup: Group? = nil, people: [Person], onGroupAdded: @escaping (Group) -> Void) {
        self._showingAddGroupSheet = showingAddGroupSheet
        self.editingGroup = editingGroup
        self.people = people
        self.onGroupAdded = onGroupAdded

        // Pre-populate fields if editing
        if let group = editingGroup {
            _name = State(initialValue: group.name)
            _description = State(initialValue: group.description)
            _selectedEmoji = State(initialValue: group.emoji)
            _selectedMembers = State(initialValue: Set(group.members))
        }
    }

    // Group emoji options
    let availableEmojis = ["👥", "🏖️", "🏠", "💼", "🎉", "🍕", "✈️", "🏃‍♂️", "📚", "🎵", "🎮", "⚽", "🍽️", "🏛️", "🎭", "🎪", "🎨", "📱"]

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedMembers.isEmpty
    }

    private var saveButtonText: String {
        editingGroup == nil ? "Create Group" : "Save Changes"
    }

    // Selected members as Person objects (use dataManager for live updates)
    private var selectedPeople: [Person] {
        dataManager.people.filter { selectedMembers.contains($0.id) }
    }

    // Available members (not yet selected) - use dataManager for live updates
    private var availablePeople: [Person] {
        dataManager.people.filter { !selectedMembers.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(editingGroup == nil ? "Add Group" : "Edit Group")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                // Group Name Row (Emoji + TextField)
                HStack(spacing: 12) {
                    // Emoji Button
                    Button(action: { showingEmojiPicker.toggle() }) {
                        Text(selectedEmoji)
                            .font(.system(size: 24))
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseCardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.wiseSeparator, lineWidth: 1)
                            )
                    }

                    // Name TextField
                    TextField("Group name", text: $name)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.wiseSeparator, lineWidth: 1)
                        )
                        .focused($isNameFocused)
                }

                // Emoji Picker (collapsible)
                if showingEmojiPicker {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(availableEmojis, id: \.self) { emoji in
                            Button(action: {
                                selectedEmoji = emoji
                                showingEmojiPicker = false
                            }) {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedEmoji == emoji ? Color.wisePrimaryButton.opacity(0.2) : Color.wiseCardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedEmoji == emoji ? Color.wisePrimaryButton : Color.wiseSeparator, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseSeparator, lineWidth: 1)
                    )
                }

                // Members Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Members")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    // Horizontal scrolling member avatars
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Selected members first
                            ForEach(selectedPeople) { person in
                                MemberAvatarButton(
                                    person: person,
                                    isSelected: true,
                                    action: { selectedMembers.remove(person.id) }
                                )
                            }

                            // Available members
                            ForEach(availablePeople) { person in
                                MemberAvatarButton(
                                    person: person,
                                    isSelected: false,
                                    action: { selectedMembers.insert(person.id) }
                                )
                            }

                            // Add new person button
                            Button(action: { showingAddPersonSheet = true }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.wiseCardBackground)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Circle()
                                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                                    .foregroundColor(.wiseSeparator)
                                            )

                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.wiseSecondaryText)
                                    }

                                    Text("Add")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                        }
                    }

                    // Selected count indicator
                    if !selectedMembers.isEmpty {
                        Text("\(selectedMembers.count) member\(selectedMembers.count == 1 ? "" : "s") selected")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }

                // Create/Save Button
                Button(action: saveGroup) {
                    Text(saveButtonText)
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(isFormValid ? .wisePrimaryButtonText : .wiseSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? Color.wisePrimaryButton : Color.wiseSecondaryButton)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wiseBackground)
        .onAppear { isNameFocused = true }
        .sheet(isPresented: $showingAddPersonSheet) {
            AddPersonSheet(isPresented: $showingAddPersonSheet)
                .environmentObject(dataManager)
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: showingAddPersonSheet) { oldValue, newValue in
            if newValue {
                // Store person count before showing add sheet
                personCountBeforeAdd = dataManager.people.count
            } else if !newValue && dataManager.people.count > personCountBeforeAdd {
                // Sheet closed and a new person was added - auto-select the newest person
                if let newestPerson = dataManager.people.last {
                    selectedMembers.insert(newestPerson.id)
                }
            }
        }
    }

    private func saveGroup() {
        if let existing = editingGroup {
            // Edit mode - update existing group
            var updatedGroup = existing
            updatedGroup.name = name.trimmingCharacters(in: .whitespaces)
            updatedGroup.description = description.trimmingCharacters(in: .whitespaces)
            updatedGroup.emoji = selectedEmoji
            updatedGroup.members = Array(selectedMembers)

            onGroupAdded(updatedGroup)
        } else {
            // Add mode - create new group
            let newGroup = Group(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                emoji: selectedEmoji,
                members: Array(selectedMembers)
            )

            onGroupAdded(newGroup)
        }

        showingAddGroupSheet = false
    }
}

// MARK: - Member Avatar Button (Compact selection)
struct MemberAvatarButton: View {
    let person: Person
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(person: person, size: .large, style: .solid)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.wiseForestGreen : Color.clear, lineWidth: 2)
                        )

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseForestGreen)
                            .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                            .offset(x: 2, y: 2)
                    }
                }

                Text(person.name.components(separatedBy: " ").first ?? person.name)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(isSelected ? .wisePrimaryText : .wiseSecondaryText)
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
    }
}

// MARK: - Subscriptions Filter Sheet  
struct SubscriptionsFilterSheet: View {
    @Binding var selectedFilter: SubscriptionFilter
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(SubscriptionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        showingFilterSheet = false
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.wiseForestGreen)
                                .frame(width: 24)
                            
                            Text(filter.rawValue)
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.wiseBrightGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Filter Subscriptions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Contact Picker View
struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(name: $name, email: $email, phone: $phone, isPresented: $isPresented)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        @Binding var name: String
        @Binding var email: String
        @Binding var phone: String
        @Binding var isPresented: Bool

        init(name: Binding<String>, email: Binding<String>, phone: Binding<String>, isPresented: Binding<Bool>) {
            _name = name
            _email = email
            _phone = phone
            _isPresented = isPresented
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Extract name
            let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            name = fullName

            // Extract email
            if let firstEmail = contact.emailAddresses.first {
                email = firstEmail.value as String
            }

            // Extract phone
            if let firstPhone = contact.phoneNumbers.first {
                phone = firstPhone.value.stringValue
            }

            isPresented = false
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            isPresented = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}

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
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)

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
                            .foregroundColor(showSearchBar ? .wiseBrightGreen : .wisePrimaryText)
                    }

                    HeaderActionButton(icon: "plus.circle.fill", color: .wiseForestGreen) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        showingAddSubscriptionSheet = true
                    }
                }
            }
            .padding(.horizontal, 16)

            // Segmented Control
            HStack(spacing: 0) {
                ForEach(SubscriptionsView.SubscriptionsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                            searchText = "" // Clear search when switching tabs
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.spotifyLabelLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .wiseBodyText)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTab == tab ? Color.wiseForestGreen : Color.clear)
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)

            // Search Bar (matching Feed design)
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.wiseSecondaryText)
                        .font(.system(size: 16))

                    TextField("Search subscriptions...", text: $searchText)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.wiseSecondaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBorder.opacity(0.3))
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 8)
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
    
    var activeCount: Int {
        subscriptions.filter { $0.isActive }.count
    }
    
    var averagePerSubscription: Double {
        activeCount > 0 ? totalMonthlySpend / Double(activeCount) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1x2 Grid with only monthly and active
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Monthly Spend
                SubscriptionStatCard(
                    title: "Monthly",
                    amount: totalMonthlySpend,
                    icon: "calendar",
                    color: .wiseBlue,
                    isAmount: true
                )
                
                // Active Subscriptions
                SubscriptionStatCard(
                    title: "Active",
                    amount: Double(activeCount),
                    icon: "star.circle",
                    color: .wiseBrightGreen,
                    isCount: true
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
    
    init(title: String, amount: Double, icon: String, color: Color, isAmount: Bool = false, isCount: Bool = false) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(formattedAmount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Subscriptions Category Filter Section
struct SubscriptionsCategoryFilterSection: View {
    @Binding var selectedCategory: SubscriptionCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories Button
                Button(action: { selectedCategory = nil }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(selectedCategory == nil ? .white : .wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedCategory == nil ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                }
                
                // Category Pills
                ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                    Button(action: { 
                        selectedCategory = selectedCategory == category ? nil : category 
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(selectedCategory == category ? .white : category.color)
                            Text(category.rawValue)
                                .font(.spotifyLabelSmall)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color : Color.wiseBorder)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Subscription Statistics Card
struct SubscriptionStatisticsCard: View {
    @EnvironmentObject var dataManager: DataManager
    
    var totalMonthlySpend: Double {
        dataManager.subscriptions
            .filter { $0.isActive }
            .reduce(0) { total, subscription in
                total + subscription.monthlyEquivalent
            }
    }
    
    var activeCount: Int {
        dataManager.subscriptions.filter { $0.isActive }.count
    }
    
    var yearlyProjection: Double {
        totalMonthlySpend * 12
    }
    
    var averagePerSubscription: Double {
        activeCount > 0 ? totalMonthlySpend / Double(activeCount) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("OVERVIEW")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
            
            // 2x2 Grid of statistics
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Monthly Spend
                SubscriptionStatCard(
                    title: "Monthly",
                    amount: totalMonthlySpend,
                    icon: "calendar",
                    color: .wiseBlue,
                    isAmount: true
                )
                
                // Active Subscriptions
                SubscriptionStatCard(
                    title: "Active",
                    amount: Double(activeCount),
                    icon: "star.circle",
                    color: .wiseBrightGreen,
                    isCount: true
                )
                
                // Yearly Projection
                SubscriptionStatCard(
                    title: "Yearly",
                    amount: yearlyProjection,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .wiseOrange,
                    isAmount: true
                )
                
                // Average per Subscription
                SubscriptionStatCard(
                    title: "Average",
                    amount: averagePerSubscription,
                    icon: "chart.bar",
                    color: .wisePurple,
                    isAmount: true
                )
            }
        }
    }
}



// MARK: - Enhanced Personal Subscriptions View
struct EnhancedPersonalSubscriptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    let subscriptions: [Subscription]
    @Binding var searchText: String
    @Binding var selectedFilter: SubscriptionFilter
    @Binding var showingFilterSheet: Bool
    @Binding var viewMode: SubscriptionsView.ViewMode
    @Binding var sortOption: SubscriptionsView.SortOption
    @Binding var showingSortMenu: Bool
    @State private var subscriptionToDelete: Subscription?
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // View Mode Toggle and Sort Menu
            HStack(spacing: 12) {
                // View Mode Toggle
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = .list
                        }
                        HapticManager.shared.medium()
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(viewMode == .list ? .white : .wiseSecondaryText)
                            .frame(width: 40, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewMode == .list ? Color.wiseForestGreen : Color.clear)
                            )
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = .grid
                        }
                        HapticManager.shared.impact(.medium)
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(viewMode == .grid ? .white : .wiseSecondaryText)
                            .frame(width: 40, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewMode == .grid ? Color.wiseForestGreen : Color.clear)
                            )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.wiseBorder.opacity(0.5))
                )

                Spacer()

                // Sort Menu Button
                Button(action: { showingSortMenu = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                        Text("Sort")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wiseBorder.opacity(0.5))
                    )
                }
                .confirmationDialog("Sort By", isPresented: $showingSortMenu, titleVisibility: .visible) {
                    ForEach(SubscriptionsView.SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            sortOption = option
                            HapticManager.shared.lightImpact()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Subscriptions List or Grid
            if dataManager.isLoading && subscriptions.isEmpty {
                // Loading State
                SkeletonListView(rowCount: 5, rowType: .subscription)
            } else if subscriptions.isEmpty {
                EmptySubscriptionsView()
            } else {
                ScrollView {
                    if viewMode == .list {
                        // List View - Flat design with card container
                        VStack(spacing: 0) {
                            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, subscription in
                                NavigationLink(destination: SubscriptionDetailView(subscriptionId: subscription.id)) {
                                    ListRowFactory.card(for: subscription)
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Add divider between items (not after the last one)
                                if index < subscriptions.count - 1 {
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        .background(Color.wiseCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    } else {
                        // Grid View
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(subscriptions) { subscription in
                                NavigationLink(destination: SubscriptionDetailView(subscriptionId: subscription.id)) {
                                    SubscriptionGridCardView(subscription: subscription)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        HapticManager.shared.heavy()
                                        subscriptionToDelete = subscription
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.wiseGroupedBackground)
                .refreshable {
                    HapticManager.shared.pullToRefresh()
                    dataManager.loadAllData()
                    ToastManager.shared.showSuccess("Refreshed")
                }
            }
        }
        .alert("Delete Subscription?", isPresented: $showingDeleteAlert, presenting: subscriptionToDelete) { subscription in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deleteSubscription(id: subscription.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { subscription in
            Text("This will permanently delete '\(subscription.name)'. This action cannot be undone.")
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

// MARK: - Color Extension for Hex Support

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
                        
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))
                    }
                    
                    // Text Content - Professional spacing and sizing
                    VStack(spacing: 12) {
                        Text("No Subscriptions Yet")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.wisePrimaryText)
                        
                        Text("Add your first subscription to start tracking\nyour monthly expenses")
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

// MARK: - Enhanced Shared Subscriptions View
struct EnhancedSharedSubscriptionsView: View {
    @Binding var sharedSubscriptions: [SharedSubscription]
    @Binding var searchText: String
    let people: [Person]

    var body: some View {
        VStack(spacing: 0) {
            // Shared Subscriptions List
            if sharedSubscriptions.isEmpty {
                EmptySharedSubscriptionsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sharedSubscriptions) { sharedSub in
                            SharedSubscriptionRow(
                                sharedSubscription: sharedSub,
                                people: people
                            )

                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Shared Subscription Row (Using UnifiedListRowV2)
private struct SharedSubscriptionRow: View {
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

    private var statusIcon: String {
        sharedSubscription.isAccepted ? "✓" : "⚠"
    }

    private var statusText: String {
        sharedSubscription.isAccepted ? "Active" : "Pending"
    }

    private var subtitle: String {
        var components: [String] = []
        components.append("\(statusIcon) \(statusText)")

        let totalPeople = sharedWithPeople.count + 1
        if totalPeople > 2 {
            components.append("Shared with \(totalPeople)")
        } else if let sharedBy = sharedByPerson {
            components.append("Shared with \(sharedBy.name)")
        } else {
            components.append("Shared")
        }

        components.append(String(format: "$%.2f/person", sharedSubscription.individualCost))
        return components.joined(separator: " • ")
    }

    private var totalPrice: Double {
        let totalPeople = sharedWithPeople.count + 1
        return sharedSubscription.individualCost * Double(totalPeople)
    }

    var body: some View {
        UnifiedListRowV2(
            iconName: "person.2.fill",
            iconColor: .wiseBlue,
            title: sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes,
            subtitle: subtitle,
            value: String(format: "$%.2f", totalPrice),
            valueColor: .wisePrimaryText,
            showChevron: false
        )
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
        let totalPeople = sharedWithPeople.count + 1 // +1 for the owner
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
        let totalPeople = sharedWithPeople.count + 1 // +1 for the owner
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
                Text(sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes)
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
                Text(sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes)
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

// MARK: - Subscription Insights Sheet
struct SubscriptionInsightsSheet: View {
    let subscriptions: [Subscription]
    @Binding var showingInsightsSheet: Bool
    
    var totalMonthlySpend: Double {
        subscriptions.filter { $0.isActive }.reduce(0.0) { $0 + $1.monthlyEquivalent }
    }
    
    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }
    
    var averageSubscriptionCost: Double {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        guard !activeSubscriptions.isEmpty else { return 0 }
        return totalMonthlySpend / Double(activeSubscriptions.count)
    }
    
    var categoryBreakdown: [(category: SubscriptionCategory, amount: Double, count: Int)] {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        let grouped = Dictionary(grouping: activeSubscriptions) { $0.category }
        return grouped.map { (category, subs) in
            let totalAmount = subs.reduce(0.0) { $0 + $1.monthlyEquivalent }
            return (category: category, amount: totalAmount, count: subs.count)
        }.sorted { $0.amount > $1.amount }
    }
    
    var mostExpensiveSubscription: Subscription? {
        subscriptions.filter { $0.isActive }.max(by: { $0.monthlyEquivalent < $1.monthlyEquivalent })
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            InsightStatCard(
                                title: "Monthly Spend",
                                value: String(format: "$%.2f", totalMonthlySpend),
                                icon: "calendar.circle.fill",
                                color: .wiseBrightGreen
                            )
                            
                            InsightStatCard(
                                title: "Annual Spend",
                                value: String(format: "$%.0f", totalAnnualSpend),
                                icon: "calendar.badge.plus",
                                color: .wiseBlue
                            )
                            
                            InsightStatCard(
                                title: "Active Subscriptions",
                                value: "\(subscriptions.filter { $0.isActive }.count)",
                                icon: "checkmark.circle.fill",
                                color: .wiseBrightGreen
                            )
                            
                            InsightStatCard(
                                title: "Average Cost",
                                value: String(format: "$%.2f", averageSubscriptionCost),
                                icon: "chart.bar.fill",
                                color: .wiseError
                            )
                        }
                    }
                    
                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending by Category")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)
                        
                        VStack(spacing: 12) {
                            ForEach(categoryBreakdown, id: \.category) { item in
                                CategoryBreakdownRow(
                                    category: item.category,
                                    amount: item.amount,
                                    count: item.count,
                                    percentage: totalMonthlySpend > 0 ? (item.amount / totalMonthlySpend) : 0
                                )
                            }
                        }
                    }
                    
                    // Most Expensive
                    if let mostExpensive = mostExpensiveSubscription {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Highest Cost")
                                .font(.spotifyHeadingLarge)
                                .foregroundColor(.wisePrimaryText)
                            
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color(hexString: mostExpensive.color).opacity(0.1))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: mostExpensive.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(Color(hexString: mostExpensive.color))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mostExpensive.name)
                                        .font(.spotifyBodyLarge)
                                        .foregroundColor(.wisePrimaryText)
                                    
                                    Text("Your most expensive subscription")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(String(format: "$%.2f", mostExpensive.monthlyEquivalent))
                                        .font(.spotifyNumberMedium)
                                        .foregroundColor(.wiseError)
                                    
                                    Text("per month")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseCardBackground)
                                    .cardShadow()
                            )
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Subscription Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingInsightsSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Insight Stat Card
struct InsightStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(value)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let category: SubscriptionCategory
    let amount: Double
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(category.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("\(count) subscription\(count == 1 ? "" : "s")")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", amount))
                    .font(.spotifyNumberSmall)
                    .foregroundColor(.wisePrimaryText)
                
                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(category.color)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Renewal Calendar Sheet
struct RenewalCalendarSheet: View {
    let subscriptions: [Subscription]
    @Binding var showingRenewalCalendarSheet: Bool
    
    var upcomingRenewals: [(date: Date, subscriptions: [Subscription])] {
        let activeSubscriptions = subscriptions.filter { $0.isActive && $0.billingCycle != BillingCycle.lifetime }
        let grouped = Dictionary(grouping: activeSubscriptions) { subscription in
            Calendar.current.startOfDay(for: subscription.nextBillingDate)
        }
        
        return grouped
            .map { (date: $0.key, subscriptions: $0.value) }
            .sorted { $0.date < $1.date }
            .prefix(30)
            .map { $0 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if upcomingRenewals.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 64))
                                .foregroundColor(.wiseSecondaryText.opacity(0.5))
                            
                            VStack(spacing: 8) {
                                Text("No Upcoming Renewals")
                                    .font(.spotifyHeadingMedium)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("All your subscriptions are up to date")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(upcomingRenewals, id: \.date) { renewalGroup in
                            RenewalDateSection(
                                date: renewalGroup.date,
                                subscriptions: renewalGroup.subscriptions
                            )
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Renewal Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingRenewalCalendarSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Renewal Date Section
struct RenewalDateSection: View {
    let date: Date
    let subscriptions: [Subscription]
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isWithinWeek: Bool {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return date <= nextWeek
    }
    
    private var totalAmount: Double {
        subscriptions.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date, style: .date)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(isToday ? .wiseError : .wisePrimaryText)
                    
                    Text(date, style: .relative)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", totalAmount))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(isWithinWeek ? .wiseError : .wisePrimaryText)
                    
                    Text("\(subscriptions.count) renewal\(subscriptions.count == 1 ? "" : "s")")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            
            // Subscriptions List
            VStack(spacing: 8) {
                ForEach(subscriptions) { subscription in
                    ListRowFactory.row(for: subscription)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .subtleShadow()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWithinWeek ? Color.wiseError.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Renewal Subscription Row
@available(*, deprecated, message: "Use UnifiedListRowV2 instead")
struct RenewalSubscriptionRow: View {
    let subscription: Subscription

    private var subtitle: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let nextDate = dateFormatter.string(from: subscription.nextBillingDate)
        return "\(subscription.billingCycle.rawValue) • Next: \(nextDate)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon (48x48)
            UnifiedIconCircle(
                icon: subscription.icon,
                color: Color(hexString: subscription.color),
                size: 48,
                iconSize: 20
            )

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

            Text(String(format: "$%.2f", subscription.price))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
