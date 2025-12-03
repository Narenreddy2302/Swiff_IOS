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
                        .padding(.bottom, 16)

                    // Task 6.2 & 6.3: Circular progress ring with animated category segments and center display
                    circularProgressSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Task 6.4: Incomes/Expenses tab selector with icons
                    categoryTabsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Task 6.5 & 6.6: Animated category list rows with percentage badges and empty state
                    categoryListSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Show additional sections only for expenses
                    if selectedViewType == .expenses {
                        // Task 6.7: Spending forecast section with trend prediction
                        spendingForecastSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        // Task 6.8: Subscription summary cards (active count, monthly cost)
                        subscriptionOverviewSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        // Task 6.9, 6.10, 6.11: Savings opportunities, unused subscriptions, annual conversion suggestions
                        savingsOpportunitiesSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
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
                .padding(.horizontal, 16)
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
                // Background circle with subtle pulse
                Circle()
                    .stroke(
                        Color.wiseSeparator.opacity(0.3),
                        lineWidth: 16
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(animateProgress ? 1.0 : 0.95)
                    .opacity(animateProgress ? 1.0 : 0.5)
                    .animation(.easeOut(duration: 0.6), value: animateProgress)

                // Task 6.2: Animated category segments with premium smooth animation
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
                                lineWidth: 16,
                                lineCap: .round
                            )
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: category.color.opacity(0.3), radius: 4, x: 0, y: 2)
                        .animation(
                            .interpolatingSpring(stiffness: 100, damping: 15)
                                .delay(Double(index) * 0.08),
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

                    // Large amount display with smooth counter animation
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.wisePrimaryText)

                        let totalAmount = calculateTotalAmount()
                        let integerPart = Int(totalAmount)
                        let decimalPart = Int((totalAmount - Double(integerPart)) * 100)

                        Text("\(integerPart)")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.wisePrimaryText)

                        Text(".\(String(format: "%02d", decimalPart))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .opacity(animateAmount ? 1 : 0)
                    .scaleEffect(animateAmount ? 1 : 0.5)
                    .blur(radius: animateAmount ? 0 : 10)
                    .animation(
                        .interpolatingSpring(stiffness: 120, damping: 18)
                            .delay(0.4),
                        value: animateAmount
                    )

                    Text("total this period")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .opacity(animateAmount ? 1 : 0)
                        .offset(y: animateAmount ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: animateAmount)
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
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 20)) {
                        selectedViewType = viewType
                        resetAnimations()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewType.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(viewType.rawValue)
                            .font(.spotifyLabelLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(selectedViewType == viewType ? .white : .wiseBodyText)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedViewType == viewType ? Color.wiseForestGreen : Color.clear)
                            .shadow(
                                color: selectedViewType == viewType ? Color.wiseForestGreen.opacity(0.3) : .clear,
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
                    .scaleEffect(selectedViewType == viewType ? 1.0 : 0.98)
                }
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
                // Task 6.5: Animated category list rows with percentage badges
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    // Task 6.12: Category drill-down navigation to filtered transaction list
                    Button(action: {
                        HapticManager.shared.light()
                        selectedCategory = category
                    }) {
                        WalletCategoryRow(
                            category: category,
                            animate: animateCategories,
                            index: index
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(animateCategories ? 1 : 0)
                    .offset(y: animateCategories ? 0 : 30)
                    .blur(radius: animateCategories ? 0 : 5)
                    .animation(
                        .interpolatingSpring(stiffness: 150, damping: 20)
                            .delay(Double(index) * 0.06),
                        value: animateCategories
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
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

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: getTrendIcon())
                                .font(.system(size: 12, weight: .semibold))
                            Text(getTrendPercentage())
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(getTrendColor())
                    }

                    // Confidence indicator with smooth fill animation
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

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.wiseSeparator.opacity(0.3))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(Color.wiseBlue)
                                    .frame(width: animateCards ? geometry.size.width * nextMonth.confidence : 0, height: 4)
                                    .animation(.interpolatingSpring(stiffness: 100, damping: 18).delay(0.3), value: animateCards)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .cardShadow()
            .scaleEffect(animateCards ? 1.0 : 0.95)
            .opacity(animateCards ? 1.0 : 0)
            .animation(.interpolatingSpring(stiffness: 120, damping: 18).delay(0.8), value: animateCards)
        }
    }

    // MARK: - Task 6.8: Subscription Overview Section

    private var subscriptionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUBSCRIPTION OVERVIEW")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)

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

                StatisticsCardComponent(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly",
                    value: formatCurrency(totalSubscriptionCost),
                    iconColor: .wiseBlue
                )
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

            let suggestions = AnalyticsService.shared.generateSavingsOpportunities()
            let unusedSubs = AnalyticsService.shared.detectUnusedSubscriptions(threshold: 60)
            let annualSuggestions = AnalyticsService.shared.suggestAnnualConversions()

            if suggestions.isEmpty && unusedSubs.isEmpty && annualSuggestions.isEmpty {
                emptyInsightsView
            } else {
                // Task 6.9: Display savings opportunities
                ForEach(suggestions.prefix(3)) { suggestion in
                    SavingsSuggestionCard(suggestion: suggestion)
                }

                // Task 6.10: Unused subscriptions alert card
                if !unusedSubs.isEmpty {
                    unusedSubscriptionsCard(subscriptions: unusedSubs)
                }

                // Task 6.11: Annual conversion suggestions with potential savings
                if !annualSuggestions.isEmpty {
                    annualConversionCard(suggestions: annualSuggestions)
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

            Text("No transactions yet")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text("Add your first transaction to see \(selectedViewType == .incomes ? "income" : "expense") analytics")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.wiseBrightGreen)

            Text("You're doing great!")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Text("No savings opportunities detected at this time.")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
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

        // Choreographed animation sequence for premium feel
        // 1. Start with background circle (immediate)
        withAnimation(.easeOut(duration: 0.6)) {
            animateProgress = true
        }
        
        // 2. Amount display fades in as progress animates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                animateAmount = true
            }
        }

        // 3. Category list items appear after circular animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                animateCategories = true
            }
        }
        
        // 4. Cards and additional content animate last
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                animateCards = true
            }
        }
    }

    private func resetAnimations() {
        // Smooth reset with quick fade out
        withAnimation(.easeOut(duration: 0.2)) {
            animateProgress = false
            animateAmount = false
            animateCategories = false
            animateCards = false
        }

        // Trigger new animations after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
                                    .padding(.leading, 76)
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

    @EnvironmentObject var dataManager: DataManager
    @State private var hovered = false

    private var transactionCount: Int {
        // Count transactions in this category
        let filtered = dataManager.transactions.filter { transaction in
            transaction.category.rawValue == category.name
        }
        return filtered.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon - UnifiedIconCircle style (48x48) with pulse effect
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .scaleEffect(hovered ? 1.05 : 1.0)

                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(category.color)
                    .scaleEffect(hovered ? 1.1 : 1.0)
            }
            .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: hovered)

            // Category name and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                // Subtitle: "23 transactions • 34.5%"
                Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s") • \(String(format: "%.1f", category.percentage))%")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Amount with subtle scale on hover
            Text(formatCurrency(category.amount))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
                .scaleEffect(hovered ? 1.05 : 1.0)
                .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: hovered)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
                .shadow(
                    color: hovered ? category.color.opacity(0.15) : .clear,
                    radius: hovered ? 12 : 0,
                    x: 0,
                    y: hovered ? 6 : 0
                )
        )
        .scaleEffect(hovered ? 1.02 : 1.0)
        .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: hovered)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !hovered {
                        HapticManager.shared.light()
                        hovered = true
                    }
                }
                .onEnded { _ in
                    hovered = false
                }
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
            // Icon with background and subtle pulse
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .scaleEffect(animate ? 1.0 : 0.8)

                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(category.color)
                    .scaleEffect(animate ? 1.0 : 0.5)
            }
            .animation(.interpolatingSpring(stiffness: 150, damping: 18).delay(0.1), value: animate)

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
                                .scaleEffect(animate ? 1.0 : 0.8)
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
        .scaleEffect(animate ? 1.0 : 0.95)
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
        // Smooth progress bar fill
        withAnimation(.interpolatingSpring(stiffness: 100, damping: 18).delay(0.2)) {
            animatedWidth = CGFloat(category.percentage / 100.0)
        }
        
        // Animated percentage counter
        let targetPercentage = Int(category.percentage)
        let duration: Double = 0.8
        let steps = 30
        let increment = targetPercentage / steps
        
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

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: transaction.category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                Text(formatDate(transaction.date))
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Amount
            Text(transaction.isExpense ? "-\(formatCurrency(abs(transaction.amount)))" : "+\(formatCurrency(transaction.amount))")
                .font(.spotifyNumberMedium)
                .foregroundColor(transaction.isExpense ? .wiseError : .wiseBrightGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        return transaction.category.color
    }

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// Note: StatisticsCardComponent is defined in Components/StatisticsCardComponent.swift

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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Preview

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(DataManager.shared)
    }
}
