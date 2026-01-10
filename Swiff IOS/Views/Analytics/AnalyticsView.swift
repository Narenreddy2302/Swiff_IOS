//
//
//  AnalyticsView.swift
//  Swiff IOS
//
//  Completely redesigned with wallet-style interface matching screenshot
//  Features: Circular progress ring, category breakdown, savings/expenses tabs
//  Enhanced with all 12 tasks for comprehensive analytics dashboard
//  Updated: 2025-11-29
//

import SwiftUI
import Charts
import Combine

/// Main analytics dashboard showing wallet overview with spending insights
struct AnalyticsView: View {

    // MARK: - Properties
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedDateRange: DateRange = .month
    @State private var selectedViewType: ViewType = .expenses
    @State private var showingDatePicker = false
    @State private var animateProgress = false
    @State private var animateCategories = false
    @State private var animateAmount = false
    @State private var animateCards = false
    @State private var selectedCategory: AnalyticsCategoryData?
    @State private var ringGlow: CGFloat = 0
    @State private var emptyStateAnimating = false
    @State private var amountKey = UUID()
    @Namespace private var animation

    enum ViewType: String, CaseIterable {
        case incomes = "Incomes"
        case expenses = "Expenses"

        var icon: String {
            switch self {
            case .incomes: return "arrow.down.circle.fill"
            case .expenses: return "arrow.up.circle.fill"
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Task 6.1: Header with "Analytics." title and date range picker button
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Task 6.2 & 6.3: Circular progress ring with animated category segments and center display
                    circularProgressSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    // Task 6.4: Incomes/Expenses tab selector with icons
                    categoryTabsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Task 6.5 & 6.6: Animated category list rows with percentage badges and empty state
                    categoryListSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)

                    // Show additional sections only for expenses
                    if selectedViewType == .expenses {
                        // Task 6.7: Spending forecast section with trend prediction
                        spendingForecastSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)

                        // Task 6.8: Subscription summary cards (active count, monthly cost)
                        subscriptionOverviewSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)

                        // Task 6.9, 6.10, 6.11: Savings opportunities, unused subscriptions, annual conversion suggestions
                        savingsOpportunitiesSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                }
            }
            .background(Color.wiseBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            triggerAnimations()
        }
    }

    // MARK: - Task 6.1: Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Analytics.")
                .font(.spotifyDisplayLarge)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            // Date range picker button
            Button(action: {
                HapticManager.shared.light()
                showingDatePicker.toggle()
            }) {
                HStack(spacing: 8) {
                    Text(selectedDateRange.displayName)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.wiseCardBackground)
                .cornerRadius(12)
            }
            .actionSheet(isPresented: $showingDatePicker) {
                ActionSheet(
                    title: Text("Select Time Period"),
                    buttons: [
                        .default(Text(DateRange.week.displayName)) {
                            selectedDateRange = .week
                            resetAnimations()
                        },
                        .default(Text(DateRange.month.displayName)) {
                            selectedDateRange = .month
                            resetAnimations()
                        },
                        .default(Text(DateRange.quarter.displayName)) {
                            selectedDateRange = .quarter
                            resetAnimations()
                        },
                        .default(Text(DateRange.year.displayName)) {
                            selectedDateRange = .year
                            resetAnimations()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }

    // MARK: - Task 6.2 & 6.3: Circular Progress Section

    private var circularProgressSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background circle with subtle breathing pulse when complete
                Circle()
                    .stroke(
                        Color.wiseSeparator.opacity(0.3),
                        lineWidth: 14
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(animateProgress ? (1.0 + ringGlow * 0.01) : 0.95)
                    .opacity(animateProgress ? 1.0 : 0.4)
                    .animation(.easeOut(duration: 0.6), value: animateProgress)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: ringGlow
                    )

                // Task 6.2: Animated category segments with premium ring animation
                let categories = getCurrentCategories()
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Circle()
                        .trim(
                            from: animateProgress ? startAngle(for: index, in: categories) : 0,
                            to: animateProgress ? endAngle(for: index, in: categories) : 0
                        )
                        .stroke(
                            category.color,
                            style: StrokeStyle(
                                lineWidth: 14,
                                lineCap: .round
                            )
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: category.color.opacity(animateProgress ? 0.4 : 0),
                            radius: animateProgress ? 6 : 0,
                            x: 0,
                            y: animateProgress ? 3 : 0
                        )
                        .scaleEffect(animateProgress ? 1.0 : 0.96)
                        .animation(
                            .ringSegment.delay(Double(index) * 0.08),
                            value: animateProgress
                        )
                }

                // Task 6.3: Center display with current month, total amount, and period label
                VStack(spacing: 8) {
                    Text(currentMonthName())
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .opacity(animateAmount ? 1 : 0)
                        .offset(y: animateAmount ? 0 : -10)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: animateAmount)

                    // Animated counter text component
                    if animateAmount {
                        AnimatedCounterText(
                            targetValue: calculateTotalAmount(),
                            duration: 1.2,
                            prefix: "$",
                            suffix: "",
                            showDecimals: true
                        )
                        .id(amountKey)
                    } else {
                        // Placeholder to maintain layout
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.wisePrimaryText)
                            Text("0")
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(.wisePrimaryText)
                            Text(".00")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .opacity(0)
                    }

                    Text("total this period")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .opacity(animateAmount ? 1 : 0)
                        .offset(y: animateAmount ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animateAmount)
                }
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - Task 6.4: Category Tabs Section

    private var categoryTabsSection: some View {
        HStack(spacing: 0) {
            ForEach(ViewType.allCases, id: \.self) { viewType in
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.tabIndicator) {
                        selectedViewType = viewType
                    }
                    resetAnimations()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .rotationEffect(.degrees(selectedViewType == viewType ? 0 : -10))
                            .scaleEffect(selectedViewType == viewType ? 1.0 : 0.9)
                        Text(viewType.rawValue)
                            .font(.spotifyLabelLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(selectedViewType == viewType ? .white : .wiseBodyText)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selectedViewType == viewType {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.wiseForestGreen)
                                .matchedGeometryEffect(id: "tab_indicator", in: animation)
                                .shadow(
                                    color: Color.wiseForestGreen.opacity(0.3),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        }
                    }
                }
                .animation(.tabIndicator, value: selectedViewType)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.wiseBorder.opacity(0.5))
        )
    }

    // MARK: - Task 6.5 & 6.6: Category List Section

    private var categoryListSection: some View {
        VStack(spacing: 0) {
            let categories = getCurrentCategories()

            if categories.isEmpty {
                // Task 6.6: Empty state for no data scenarios
                emptyCategoryState
            } else {
                // Task 6.5: Animated category list rows with feed page style (grouped container)
                VStack(spacing: 0) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        // Task 6.12: Category drill-down navigation to filtered transaction list
                        Button(action: {
                            HapticManager.shared.light()
                            selectedCategory = category
                        }) {
                            WalletCategoryRow(
                                category: category,
                                animate: animateCategories,
                                index: index,
                                isExpense: selectedViewType == .expenses
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(animateCategories ? 1 : 0)
                        .offset(y: animateCategories ? 0 : 10)
                        .animation(
                            .categoryEntrance.delay(0.05 * Double(index)),
                            value: animateCategories
                        )

                        // Divider between rows (aligned with text, like feed page)
                        if index < categories.count - 1 {
                            AlignedDivider()
                        }
                    }
                }
                .opacity(animateCategories ? 1 : 0)
                .animation(.categoryEntrance, value: animateCategories)
            }
        }
        .animation(.categoryEntrance, value: selectedViewType)
        .sheet(item: $selectedCategory) { category in
            NavigationView {
                FilteredTransactionListView(
                    category: category,
                    dateRange: selectedDateRange,
                    isExpense: selectedViewType == .expenses
                )
                .environmentObject(dataManager)
            }
        }
    }

    // MARK: - Task 6.7: Spending Forecast Section

    private var spendingForecastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SPENDING FORECAST")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 10)
                .animation(.categoryEntrance.delay(0.1), value: animateCards)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.wiseBlue.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.wiseBlue)
                                .font(.system(size: 20))
                        )
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .animation(.premiumCardAppear.delay(0.2), value: animateCards)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Month Prediction")
                            .font(.spotifyHeadingSmall)
                            .foregroundColor(.wisePrimaryText)

                        Text("Based on current spending trends")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()
                }

                let forecast = AnalyticsService.shared.forecastSpending(months: 1)
                if let nextMonth = forecast.first {
                    HStack(alignment: .firstTextBaseline) {
                        Text(formatCurrency(nextMonth.predictedAmount))
                            .font(.spotifyNumberLarge)
                            .foregroundColor(.wiseBlue)
                            .opacity(animateCards ? 1 : 0)
                            .scaleEffect(animateCards ? 1.0 : 0.9)
                            .animation(.premiumCardAppear.delay(0.3), value: animateCards)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: getTrendIcon())
                                .font(.system(size: 12, weight: .semibold))
                            Text(getTrendPercentage())
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(getTrendColor())
                        .opacity(animateCards ? 1 : 0)
                        .animation(.categoryEntrance.delay(0.35), value: animateCards)
                    }

                    // Confidence indicator with shimmer effect
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Confidence")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)

                            Spacer()

                            Text("\(Int(nextMonth.confidence * 100))%")
                                .font(.spotifyCaptionSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(.wisePrimaryText)
                        }

                        ShimmerProgressBar(
                            progress: nextMonth.confidence,
                            color: .wiseBlue,
                            animate: animateCards
                        )
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .cardShadow()
            .premiumCardEntrance(isVisible: animateCards, delay: 0.0)
        }
    }

    // MARK: - Task 6.8: Subscription Overview Section

    private var subscriptionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUBSCRIPTION OVERVIEW")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 10)
                .animation(.categoryEntrance.delay(0.15), value: animateCards)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatisticsCardComponent(
                    icon: "star.circle.fill",
                    title: "Active",
                    value: "\(activeSubscriptionsCount)",
                    iconColor: .wiseBrightGreen
                )
                .premiumCardEntrance(isVisible: animateCards, delay: 0.1)

                StatisticsCardComponent(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly",
                    value: formatCurrency(totalSubscriptionCost),
                    iconColor: .wiseBlue
                )
                .premiumCardEntrance(isVisible: animateCards, delay: 0.15)
            }
        }
    }

    // MARK: - Task 6.9, 6.10, 6.11: Savings Opportunities Section

    private var savingsOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SAVINGS OPPORTUNITIES")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 10)
                .animation(.categoryEntrance.delay(0.2), value: animateCards)

            let suggestions = AnalyticsService.shared.generateSavingsOpportunities()
            let unusedSubs = AnalyticsService.shared.detectUnusedSubscriptions(threshold: 60)
            let annualSuggestions = AnalyticsService.shared.suggestAnnualConversions()

            if suggestions.isEmpty && unusedSubs.isEmpty && annualSuggestions.isEmpty {
                emptyInsightsView
            } else {
                // Task 6.9: Display savings opportunities with staggered entrance
                ForEach(Array(suggestions.prefix(3).enumerated()), id: \.element.id) { index, suggestion in
                    SavingsSuggestionCard(suggestion: suggestion)
                        .premiumCardEntrance(isVisible: animateCards, delay: 0.2 + Double(index) * 0.08)
                }

                // Task 6.10: Unused subscriptions alert card
                if !unusedSubs.isEmpty {
                    unusedSubscriptionsCard(subscriptions: unusedSubs)
                        .premiumCardEntrance(isVisible: animateCards, delay: 0.35)
                }

                // Task 6.11: Annual conversion suggestions with potential savings
                if !annualSuggestions.isEmpty {
                    annualConversionCard(suggestions: annualSuggestions)
                        .premiumCardEntrance(isVisible: animateCards, delay: 0.4)
                }
            }
        }
    }

    // MARK: - Task 6.6: Empty States

    private var emptyCategoryState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
                .scaleEffect(emptyStateAnimating ? 1.05 : 0.95)
                .rotationEffect(.degrees(emptyStateAnimating ? 3 : -3))
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: emptyStateAnimating
                )

            Text("No transactions yet")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .opacity(emptyStateAnimating ? 1 : 0)
                .offset(y: emptyStateAnimating ? 0 : 10)
                .animation(.gentle.delay(0.2), value: emptyStateAnimating)

            Text("Add your first transaction to see \(selectedViewType == .incomes ? "income" : "expense") analytics")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
                .opacity(emptyStateAnimating ? 1 : 0)
                .offset(y: emptyStateAnimating ? 0 : 10)
                .animation(.gentle.delay(0.3), value: emptyStateAnimating)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .onAppear {
            withAnimation(.gentle.delay(0.5)) {
                emptyStateAnimating = true
            }
        }
    }

    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            // Animated checkmark with draw effect
            ZStack {
                Circle()
                    .stroke(Color.wiseBrightGreen.opacity(0.3), lineWidth: 3)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: animateCards ? 1 : 0)
                    .stroke(Color.wiseBrightGreen, lineWidth: 3)
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCards)

                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.wiseBrightGreen)
                    .scaleEffect(animateCards ? 1.0 : 0.5)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.bouncy.delay(0.6), value: animateCards)
            }

            Text("You're doing great!")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .opacity(animateCards ? 1 : 0)
                .animation(.gentle.delay(0.7), value: animateCards)

            Text("No savings opportunities detected at this time.")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
                .opacity(animateCards ? 1 : 0)
                .animation(.gentle.delay(0.8), value: animateCards)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .premiumCardEntrance(isVisible: animateCards, delay: 0.2)
    }

    // MARK: - Task 6.10: Unused Subscriptions Card

    private func unusedSubscriptionsCard(subscriptions: [Subscription]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.wiseOrange.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.wiseOrange)
                            .font(.system(size: 20))
                    )

                Text("Unused Subscriptions")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }

            Text("\(subscriptions.count) subscription\(subscriptions.count == 1 ? "" : "s") haven't been used in 60+ days")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)

            ForEach(subscriptions.prefix(3)) { subscription in
                HStack {
                    Text(subscription.name)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text(formatCurrency(subscription.monthlyEquivalent) + "/mo")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseError)
                }
                .padding(.vertical, 4)
            }

            if subscriptions.count > 3 {
                Text("+ \(subscriptions.count - 3) more")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    // MARK: - Task 6.11: Annual Conversion Card

    private func annualConversionCard(suggestions: [AnnualSuggestion]) -> some View {
        let totalSavings = suggestions.reduce(0.0) { $0 + $1.annualSavings }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.wiseBrightGreen.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "arrow.2.circlepath.circle.fill")
                            .foregroundColor(.wiseBrightGreen)
                            .font(.system(size: 20))
                    )

                Text("Switch to Annual Plans")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()
            }

            Text("Save \(formatCurrency(totalSavings)) per year")
                .font(.spotifyNumberLarge)
                .foregroundColor(.wiseBrightGreen)

            Text("\(suggestions.count) subscription\(suggestions.count == 1 ? "" : "s") could save money with annual billing")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)

            ForEach(suggestions.prefix(3)) { suggestion in
                HStack {
                    Text(suggestion.subscription.name)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text("Save \(formatCurrency(suggestion.annualSavings))/yr")
                        .font(.spotifyBodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseBrightGreen)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    // MARK: - Helper Methods

    private func triggerAnimations() {
        // Reset all animation states first
        animateProgress = false
        animateAmount = false
        animateCategories = false
        animateCards = false
        ringGlow = 0
        emptyStateAnimating = false
        amountKey = UUID() // Reset counter animation

        // Premium orchestrated animation sequence
        // Phase 1: Ring background and segments (immediate)
        withAnimation(.easeOut(duration: 0.6)) {
            animateProgress = true
        }

        // Phase 2: Start ring breathing pulse after ring draws
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            ringGlow = 1
        }

        // Phase 3: Amount counter starts after ring animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.gentle) {
                animateAmount = true
            }
        }

        // Phase 4: Category list items with staggered entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.categoryEntrance) {
                animateCategories = true
            }
        }

        // Phase 5: Cards and additional content appear last
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.premiumCardAppear) {
                animateCards = true
            }
        }
    }

    private func resetAnimations() {
        // Coordinated fade-out sequence for smooth transition

        // Phase 1: Ring and amount fade first (0.2s)
        withAnimation(.easeIn(duration: 0.2)) {
            animateProgress = false
            animateAmount = false
            ringGlow = 0
        }

        // Phase 2: Category rows slide out (0.15s, slight delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeIn(duration: 0.15)) {
                animateCategories = false
            }
        }

        // Phase 3: Cards fade (0.15s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.15)) {
                animateCards = false
                emptyStateAnimating = false
            }
        }

        // Phase 4: Re-trigger animations after brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            triggerAnimations()
        }
    }

    private func getCurrentCategories() -> [AnalyticsCategoryData] {
        switch selectedViewType {
        case .incomes:
            return prepareIncomesCategories()
        case .expenses:
            return prepareExpenseCategories()
        }
    }

    private func calculateTotalAmount() -> Double {
        switch selectedViewType {
        case .incomes:
            return calculateTotalIncomes()
        case .expenses:
            return calculateTotalExpenses()
        }
    }

    private func startAngle(for index: Int, in categories: [AnalyticsCategoryData]) -> CGFloat {
        guard !categories.isEmpty, index >= 0, index < categories.count else { return 0 }
        let previousSegments = categories.prefix(index)
        let totalPrevious = previousSegments.reduce(0.0) { $0 + $1.percentage }
        return CGFloat(min(max(totalPrevious / 100.0, 0), 1))
    }

    private func endAngle(for index: Int, in categories: [AnalyticsCategoryData]) -> CGFloat {
        guard !categories.isEmpty, index >= 0, index < categories.count else { return 0 }
        let segmentsUpToIndex = categories.prefix(index + 1)
        let total = segmentsUpToIndex.reduce(0.0) { $0 + $1.percentage }
        return CGFloat(min(max(total / 100.0, 0), 1))
    }

    private func currentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private func calculateTotalIncomes() -> Double {
        let transactions = getFilteredTransactions()
        return transactions.filter { !$0.isExpense }.reduce(0.0) { $0 + $1.amount }
    }

    private func calculateTotalExpenses() -> Double {
        let transactions = getFilteredTransactions()
        return transactions.filter { $0.isExpense }.reduce(0.0) { $0 + abs($1.amount) }
    }

    private func getFilteredTransactions() -> [Transaction] {
        let startDate = selectedDateRange.startDate
        let endDate = selectedDateRange.endDate

        return dataManager.transactions
            .filter { $0.date >= startDate && $0.date <= endDate }
    }

    private var activeSubscriptionsCount: Int {
        dataManager.subscriptions.filter { $0.isActive }.count
    }

    private var totalSubscriptionCost: Double {
        dataManager.subscriptions
            .filter { $0.isActive }
            .reduce(0.0) { $0 + $1.monthlyEquivalent }
    }

    private func getTrendIcon() -> String {
        let analysis = AnalyticsService.shared.getTrendAnalysis(for: selectedDateRange)
        return analysis.isIncreasing ? "arrow.up.right" : "arrow.down.right"
    }

    private func getTrendColor() -> Color {
        let analysis = AnalyticsService.shared.getTrendAnalysis(for: selectedDateRange)
        return analysis.isIncreasing ? .wiseError : .wiseBrightGreen
    }

    private func getTrendPercentage() -> String {
        let analysis = AnalyticsService.shared.getTrendAnalysis(for: selectedDateRange)
        let percentage = abs(analysis.percentageChange)
        return String(format: "%.1f%%", percentage)
    }

    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }

    // MARK: - Category Data Preparation

    private func prepareIncomesCategories() -> [AnalyticsCategoryData] {
        let transactions = getFilteredTransactions()
        let incomeTransactions = transactions.filter { !$0.isExpense }

        guard !incomeTransactions.isEmpty else { return [] }

        // Group by category
        let grouped = Dictionary(grouping: incomeTransactions) { $0.category }
        let totalIncome = incomeTransactions.reduce(0.0) { $0 + $1.amount }

        // Create category data
        let categories = grouped.map { (category, transactions) -> AnalyticsCategoryData in
            let amount = transactions.reduce(0.0) { $0 + $1.amount }
            let percentage = (amount / totalIncome) * 100

            return AnalyticsCategoryData(
                id: UUID(),
                icon: category.icon,
                name: category.rawValue,
                color: category.color,
                percentage: percentage,
                amount: amount
            )
        }
        .sorted { $0.percentage > $1.percentage }
        .prefix(5)

        return Array(categories)
    }

    private func prepareExpenseCategories() -> [AnalyticsCategoryData] {
        let transactions = getFilteredTransactions()
        let expenseTransactions = transactions.filter { $0.isExpense }

        guard !expenseTransactions.isEmpty else { return [] }

        // Group by category
        let grouped = Dictionary(grouping: expenseTransactions) { $0.category }
        let totalExpenses = expenseTransactions.reduce(0.0) { $0 + abs($1.amount) }

        // Create category data
        let categories = grouped.map { (category, transactions) -> AnalyticsCategoryData in
            let amount = transactions.reduce(0.0) { $0 + abs($1.amount) }
            let percentage = (amount / totalExpenses) * 100

            return AnalyticsCategoryData(
                id: UUID(),
                icon: category.icon,
                name: category.rawValue,
                color: category.color,
                percentage: percentage,
                amount: amount
            )
        }
        .sorted { $0.percentage > $1.percentage }
        .prefix(5)

        return Array(categories)
    }
}

// MARK: - Task 6.12: Filtered Transaction List View

struct FilteredTransactionListView: View {
    let category: AnalyticsCategoryData
    let dateRange: DateRange
    let isExpense: Bool

    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    private var filteredTransactions: [Transaction] {
        let startDate = dateRange.startDate
        let endDate = dateRange.endDate

        return dataManager.transactions
            .filter { transaction in
                transaction.date >= startDate &&
                transaction.date <= endDate &&
                transaction.category.rawValue == category.name &&
                transaction.isExpense == isExpense
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                        .frame(width: 32, height: 32)
                        .background(Color.wiseCardBackground)
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                        Text(category.name)
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                    }

                    Text("\(filteredTransactions.count) transactions")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()
                .background(Color.wiseSeparator)

            // Transaction list
            if filteredTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))

                    Text("No transactions found")
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTransactions) { transaction in
                            TransactionHistoryRow(transaction: transaction)
                                .padding(.horizontal, 20)

                            if transaction.id != filteredTransactions.last?.id {
                                Divider()
                                    .padding(.leading, 80)
                                    .background(Color.wiseSeparator)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.wiseBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Wallet Category Row Component

struct WalletCategoryRow: View {
    let category: AnalyticsCategoryData
    let animate: Bool
    let index: Int
    let isExpense: Bool

    @EnvironmentObject var dataManager: DataManager
    @State private var iconAnimated = false

    // MARK: - Computed Properties

    private var transactionCount: Int {
        // Count transactions in this category
        let filtered = dataManager.transactions.filter { transaction in
            transaction.category.rawValue == category.name
        }
        return filtered.count
    }

    /// Generate initials from category name (1-2 characters)
    private var categoryInitials: String {
        InitialsGenerator.generate(from: category.name)
    }

    /// Get avatar color based on category name
    private var avatarColor: Color {
        InitialsAvatarColors.color(for: category.name)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            // Initials-based avatar (44x44 circle)
            initialsAvatar

            // Left column: Title + Description
            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                // Description: "X transactions • Y%"
                Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s") • \(String(format: "%.1f", category.percentage))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer()

            // Amount
            Text(formatCurrency(category.amount))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isExpense ? AmountColors.negative : AmountColors.positive)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .onChange(of: animate) { _, newValue in
            if newValue {
                iconAnimated = false
                withAnimation(.categoryEntrance.delay(Double(index) * 0.05)) {
                    iconAnimated = true
                }
            } else {
                iconAnimated = false
            }
        }
        .onAppear {
            if animate {
                withAnimation(.categoryEntrance.delay(Double(index) * 0.05 + 0.15)) {
                    iconAnimated = true
                }
            }
        }
    }

    // MARK: - Initials Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(categoryInitials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
        .scaleEffect(iconAnimated ? 1.0 : 0.8)
        .animation(.categoryEntrance.delay(Double(index) * 0.05 + 0.1), value: iconAnimated)
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// MARK: - Supporting Types

struct CategorySegment {
    let color: Color
    let percentage: Double
}

// MARK: - Category Progress Row

struct CategoryProgressRow: View {
    let category: AnalyticsCategoryData
    let isExpense: Bool
    let colorScheme: ColorScheme
    let animate: Bool

    @State private var animatedWidth: CGFloat = 0
    @State private var animatedPercentage: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            // Icon with background and subtle entrance
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .scaleEffect(animate ? 1.0 : 0.9)

                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(category.color)
                    .scaleEffect(animate ? 1.0 : 0.8)
            }
            .animation(.gentle.delay(0.1), value: animate)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Name and Percentage Badge
                HStack(spacing: 12) {
                    Text(category.name)
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    // Percentage Badge with animated counter
                    Text("\(animatedPercentage)%")
                        .font(.spotifyLabelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(category.color)
                                .scaleEffect(animate ? 1.0 : 0.9)
                        )
                }

                // Progress Bar with smooth fill animation
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background Track
                        Capsule()
                            .fill(Color.wiseSeparator.opacity(0.5))
                            .frame(height: 8)

                        // Progress Fill with gradient shimmer effect
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [category.color, category.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * animatedWidth,
                                height: 8
                            )
                            .shadow(color: category.color.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .scaleEffect(animate ? 1.0 : 0.97)
        .opacity(animate ? 1.0 : 0)
        .onAppear {
            if animate {
                animateProgressBar()
            }
        }
        .onChange(of: animate) { oldValue, newValue in
            if newValue {
                animatedWidth = 0
                animatedPercentage = 0
                animateProgressBar()
            }
        }
    }

    private func animateProgressBar() {
        // Smooth progress bar fill with gentle animation
        withAnimation(.gentle.delay(0.2)) {
            animatedWidth = CGFloat(category.percentage / 100.0)
        }

        // Animated percentage counter - slower and smoother
        let targetPercentage = Int(category.percentage)
        let duration: Double = 1.2
        let steps = 20
        let increment = targetPercentage / max(steps, 1)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(i)) {
                animatedPercentage = min(increment * i, targetPercentage)
                if i == steps {
                    animatedPercentage = targetPercentage
                }
            }
        }
    }
}

// MARK: - Transaction History Row

struct TransactionHistoryRow: View {
    let transaction: Transaction

    // MARK: - Computed Properties

    private var isIncoming: Bool {
        !transaction.isExpense
    }

    private var statusText: String {
        transaction.paymentStatus.displayText
    }

    private var amountColor: Color {
        isIncoming ? .wiseSuccess : .wiseError
    }

    private var formattedAmountWithSign: String {
        let sign = isIncoming ? "+" : "-"
        return "\(sign)\(transaction.formattedAmount)"
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: transaction.date, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon with status indicator
            iconWithStatusIndicator

            // Title and status
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(statusText)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Amount and time
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmountWithSign)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(amountColor)

                Text(relativeTime)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Icon with Status Indicator

    private var iconWithStatusIndicator: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main icon circle
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.wisePrimaryText)
                )

            // Status indicator (plus/minus badge)
            Circle()
                .fill(Color.wiseCardBackground)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .fill(isIncoming ? Color.wiseSuccess : Color.wiseError)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: isIncoming ? "plus" : "minus")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                )
                .offset(x: 2, y: 2)
        }
    }
}

// Note: StatisticsCardComponent is defined in Components/StatisticsCardComponent.swift

// MARK: - Category Row Button Style

/// Custom button style for category rows with enhanced press state
struct CategoryRowButtonStyle: ButtonStyle {
    let categoryColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .shadow(
                color: configuration.isPressed ? categoryColor.opacity(0.15) : .clear,
                radius: configuration.isPressed ? 8 : 0,
                x: 0,
                y: configuration.isPressed ? 4 : 0
            )
            .animation(.snappy, value: configuration.isPressed)
    }
}

// MARK: - Savings Suggestion Card

struct SavingsSuggestionCard: View {
    let suggestion: SavingsSuggestion

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.wiseBrightGreen.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: iconForType(suggestion.type))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.wiseBrightGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(suggestion.description)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Save")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)

                Text(formatSavings(suggestion.potentialSavings))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wiseBrightGreen)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    private func iconForType(_ type: SuggestionType) -> String {
        switch type {
        case .unused:
            return "xmark.circle"
        case .priceIncrease:
            return "arrow.up.right.circle"
        case .annualConversion:
            return "calendar.circle"
        case .alternative:
            return "doc.on.doc"
        case .trialEnding:
            return "clock"
        }
    }

    private func formatSavings(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// MARK: - Preview

#Preview("Analytics - Default") {
    AnalyticsView()
        .environmentObject(DataManager.shared)
}

#Preview("Analytics - Dark Mode") {
    AnalyticsView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
