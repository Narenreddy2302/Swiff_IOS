import SwiftUI

// MARK: - Subscriptions View
struct SubscriptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSubscriptionSheet = false
    @State private var showingInsightsSheet = false
    @State private var showingRenewalCalendarSheet = false
    @State private var selectedTab: SubscriptionsTab = .personal
    @State private var searchText = ""
    @State private var showSearchBar = false

    // Filter State
    @State private var selectedFilter: SubscriptionFilter = .all
    @State private var showingFilterSheet = false
    @State private var selectedCategory: SubscriptionCategory?

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

    enum SubscriptionFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
        case freeTrial = "Free Trial"
    }

    var filteredPersonalSubscriptions: [Subscription] {
        var result = dataManager.subscriptions

        // 1. Search Filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // 2. Category Filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // 3. Status Filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.isActive }
        case .inactive:
            result = result.filter { !$0.isActive }
        case .freeTrial:
            result = result.filter { $0.isFreeTrial }
        }

        // 4. Sort by most recent billing activity (newest first)
        result.sort { sub1, sub2 in
            let date1 = sub1.lastBillingDate ?? sub1.createdDate
            let date2 = sub2.lastBillingDate ?? sub2.createdDate
            return date1 > date2
        }

        return result
    }

    var filteredSharedSubscriptions: [SharedSubscription] {
        var result = dataManager.sharedSubscriptions

        // 1. Search Filter
        if !searchText.isEmpty {
            result = result.filter { sharedSub in
                // Search by notes (subscription name) or by linked subscription name
                let notesMatch = sharedSub.notes.localizedCaseInsensitiveContains(searchText)
                let subscriptionMatch =
                    dataManager.subscriptions
                    .first { $0.id == sharedSub.subscriptionId }?
                    .name.localizedCaseInsensitiveContains(searchText) ?? false
                return notesMatch || subscriptionMatch
            }
        }

        // 2. Category Filter (via linked subscription)
        if let category = selectedCategory {
            result = result.filter { sharedSub in
                guard
                    let subscription = dataManager.subscriptions.first(where: {
                        $0.id == sharedSub.subscriptionId
                    })
                else {
                    return false
                }
                return subscription.category == category
            }
        }

        // 3. Sort by most recent activity (newest first)
        result.sort { $0.createdDate > $1.createdDate }

        return result
    }

    // Calculation properties for header
    var totalMonthlySpend: Double {
        dataManager.subscriptions.filter { $0.isActive }.reduce(0.0) { $0 + $1.monthlyEquivalent }
    }

    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }

    var activeSubscriptionsCount: Int {
        dataManager.subscriptions.filter { $0.isActive }.count
    }

    var nextBillingDate: Date? {
        dataManager.subscriptions
            .filter { $0.isActive }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .first?.nextBillingDate
    }

    var upcomingBillsCount: Int {
        let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return dataManager.subscriptions
            .filter {
                $0.isActive && $0.nextBillingDate <= oneWeekFromNow
                    && $0.nextBillingDate >= Date()
            }
            .count
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Use consistent background throughout app
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Enhanced Header Section
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
                        upcomingBillsCount: upcomingBillsCount
                    )
                    .background(Theme.Colors.background)
                    .zIndex(1)

                    if selectedTab == .personal {
                        if dataManager.subscriptions.isEmpty && !dataManager.isLoading {
                            // No subscriptions at all - still show stats
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Stats Cards (shows $0 when empty)
                                    SubscriptionQuickStatsView(
                                        subscriptions: dataManager.subscriptions,
                                        sharedSubscriptions: []
                                    )
                                    .padding(.top, 8)

                                    EmptySubscriptionsView()
                                }
                                .padding(.bottom, 100)
                            }
                        } else if filteredPersonalSubscriptions.isEmpty && selectedCategory != nil {
                            // Category filter has no matches - show stats, filter, and category empty state
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Stats Cards
                                    SubscriptionQuickStatsView(
                                        subscriptions: dataManager.subscriptions,
                                        sharedSubscriptions: []
                                    )
                                    .padding(.top, 8)

                                    // Category Filter
                                    SubscriptionsCategoryFilterSection(
                                        selectedCategory: $selectedCategory)

                                    // Category-specific empty state
                                    NoCategorySubscriptionsView(
                                        category: selectedCategory!,
                                        onClearFilter: { selectedCategory = nil }
                                    )
                                }
                                .padding(.bottom, 100)
                            }
                            .transition(.move(edge: .leading))
                        } else {
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Stats Cards
                                    SubscriptionQuickStatsView(
                                        subscriptions: dataManager.subscriptions,
                                        sharedSubscriptions: []
                                    )
                                    .padding(.top, 8)

                                    // Category Filter
                                    SubscriptionsCategoryFilterSection(
                                        selectedCategory: $selectedCategory)

                                    // Main Content
                                    EnhancedPersonalSubscriptionsView(
                                        subscriptions: filteredPersonalSubscriptions,
                                        searchText: $searchText,
                                        selectedFilter: $selectedFilter,
                                        showingFilterSheet: $showingFilterSheet
                                    )
                                }
                                .padding(.bottom, 100)
                            }
                            .transition(.move(edge: .leading))
                        }
                    } else {
                        // Shared tab
                        if dataManager.sharedSubscriptions.isEmpty && !dataManager.isLoading {
                            // No shared subscriptions at all - still show stats
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Stats Cards (shows $0 when empty)
                                    SharedSubscriptionQuickStatsView(
                                        sharedSubscriptions: [],
                                        people: dataManager.people
                                    )
                                    .padding(.top, 8)

                                    EmptySharedSubscriptionsView()
                                }
                                .padding(.bottom, 100)
                            }
                        } else if filteredSharedSubscriptions.isEmpty && selectedCategory != nil {
                            // Category filter has no matches
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Stats Cards for Shared
                                    SharedSubscriptionQuickStatsView(
                                        sharedSubscriptions: filteredSharedSubscriptions,
                                        people: dataManager.people
                                    )
                                    .padding(.top, 8)

                                    // Category Filter
                                    SubscriptionsCategoryFilterSection(
                                        selectedCategory: $selectedCategory
                                    )

                                    // Category-specific empty state
                                    NoCategorySubscriptionsView(
                                        category: selectedCategory!,
                                        onClearFilter: { selectedCategory = nil }
                                    )
                                }
                                .padding(.bottom, 100)
                            }
                            .transition(.move(edge: .trailing))
                        } else {
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Stats Cards for Shared
                                    SharedSubscriptionQuickStatsView(
                                        sharedSubscriptions: filteredSharedSubscriptions,
                                        people: dataManager.people
                                    )
                                    .padding(.top, 8)

                                    // Category Filter
                                    SubscriptionsCategoryFilterSection(
                                        selectedCategory: $selectedCategory
                                    )

                                    // Main Content
                                    EnhancedSharedSubscriptionsView(
                                        sharedSubscriptions: .constant(filteredSharedSubscriptions),
                                        searchText: $searchText,
                                        people: dataManager.people
                                    )
                                }
                                .padding(.bottom, 100)
                            }
                            .transition(.move(edge: .trailing))
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSubscriptionSheet) {
                AddSubscriptionSheet(
                    showingAddSubscriptionSheet: $showingAddSubscriptionSheet,
                    onSubscriptionAdded: { subscription in
                        try? dataManager.addSubscription(subscription)
                    }
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
}
