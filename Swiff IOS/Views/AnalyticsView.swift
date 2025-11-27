//
//
//  AnalyticsView.swift
//  Swiff IOS
//
//  Completely redesigned with wallet-style interface matching screenshot
//  Features: Circular progress ring, category breakdown, savings/expenses tabs
//  Updated: 2025-11-26
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
    @State private var selectedViewType: ViewType = .incomes
    @State private var showingDatePicker = false
    @State private var animateProgress = false
    @State private var animateCategories = false
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
                    // Header with "Wallet" title and date range picker
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // Circular progress ring with amount
                    circularProgressSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Savings/Expenses tabs
                    categoryTabsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    
                    // Category breakdown list
                    categoryListSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .background(Color.wiseBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear {
            triggerAnimations()
        }
    }
    
    // MARK: - Header Section
    
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
    
    // MARK: - Circular Progress Section
    
    private var circularProgressSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        Color.wiseSeparator.opacity(0.3),
                        lineWidth: 16
                    )
                    .frame(width: 280, height: 280)
                
                // Animated category segments
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
                        .animation(
                            .spring(response: 1.0, dampingFraction: 0.7)
                                .delay(Double(index) * 0.1),
                            value: animateProgress
                        )
                }
                
                // Center content with amount
                VStack(spacing: 8) {
                    Text(currentMonthName())
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                    
                    // Large amount display
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
                    .opacity(animateProgress ? 1 : 0)
                    .scaleEffect(animateProgress ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateProgress)
                    
                    Text("total this period")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .opacity(animateProgress ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: animateProgress)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Category Tabs Section
    
    private var categoryTabsSection: some View {
        HStack(spacing: 0) {
            ForEach(ViewType.allCases, id: \.self) { viewType in
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.wiseBorder.opacity(0.5))
        )
    }
    
    // MARK: - Category List Section
    
    private var categoryListSection: some View {
        VStack(spacing: 0) {
            let categories = getCurrentCategories()
            
            if categories.isEmpty {
                emptyCategoryState
            } else {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    WalletCategoryRow(
                        category: category,
                        animate: animateCategories,
                        index: index
                    )
                    .opacity(animateCategories ? 1 : 0)
                    .offset(y: animateCategories ? 0 : 20)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.75)
                            .delay(Double(index) * 0.08),
                        value: animateCategories
                    )
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyCategoryState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
            
            Text("No data available")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
            
            Text("Add some transactions to see your \(selectedViewType == .incomes ? "incomes" : "expenses") breakdown")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper Methods
    
    private func triggerAnimations() {
        // Reset first
        animateProgress = false
        animateCategories = false
        
        // Trigger with delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                animateProgress = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animateCategories = true
            }
        }
    }
    
    private func resetAnimations() {
        animateProgress = false
        animateCategories = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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

// MARK: - Wallet Category Row Component

struct WalletCategoryRow: View {
    let category: AnalyticsCategoryData
    let animate: Bool
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(category.color)
            }
            
            // Category name
            Text(category.name)
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
            
            Spacer()
            
            // Percentage badge
            Text("\(Int(category.percentage))%")
                .font(.spotifyLabelLarge)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(category.color)
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Types
// Note: AnalyticsCategoryData is defined in AnalyticsComponents.swift

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
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(category.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Name and Percentage Badge
                HStack(spacing: 12) {
                    Text(category.name)
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    // Percentage Badge
                    Text("\(Int(category.percentage))%")
                        .font(.spotifyLabelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(category.color)
                        )
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background Track
                        Capsule()
                            .fill(Color.wiseSeparator.opacity(0.5))
                            .frame(height: 8)
                        
                        // Progress Fill
                        Capsule()
                            .fill(category.color)
                            .frame(
                                width: geometry.size.width * animatedWidth,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .onAppear {
            if animate {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                    animatedWidth = CGFloat(category.percentage / 100.0)
                }
            }
        }
        .onChange(of: animate) { oldValue, newValue in
            if newValue {
                animatedWidth = 0
                withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                    animatedWidth = CGFloat(category.percentage / 100.0)
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

// MARK: - Income Breakdown View (Full Page)

struct IncomeBreakdownView: View {
    let dateRange: DateRange
    let incomeData: [ChartDataItem]
    @EnvironmentObject var dataManager: DataManager

    @State private var selectedCategory: String?

    private var totalIncome: Double {
        incomeData.reduce(0) { $0 + $1.amount }
    }

    private var averageIncome: Double {
        guard !incomeData.isEmpty else { return 0 }
        return totalIncome / Double(incomeData.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Pie Chart and Contribution List
                if incomeData.isEmpty {
                    emptyIncomeState
                } else {
                    VStack(spacing: 16) {
                        CategoryPieChart(
                            data: incomeData,
                            total: totalIncome,
                            isIncome: true,
                            dateRange: dateRange.displayName
                        )
                        .padding(.horizontal, 16)

                        CategoryContributionList(
                            data: incomeData,
                            total: totalIncome,
                            isIncome: true,
                            selectedCategory: $selectedCategory
                        )
                        .padding(.horizontal, 16)
                    }
                }

            }
            .padding(.top, 16)
        }
        .refreshable {
            // Refresh data
            HapticManager.shared.pullToRefresh()
            dataManager.loadAllData()
            ToastManager.shared.showSuccess("Refreshed")
        }
    }

    // MARK: - Empty State
    
    private var emptyIncomeState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Income Data")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("No income transactions found for the selected period")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Income Flow Chart View

struct IncomeFlowChartView: View {
    let data: [ChartDataItem]
    
    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("Income Breakdown")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)
            
            // Total Amount
            Text(formatCurrency(totalAmount))
                .font(.spotifyNumberLarge)
                .foregroundColor(.wiseBrightGreen)
            
            // Flow Chart
            Chart(data) { item in
                BarMark(
                    x: .value("Amount", item.amount)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(8)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(formatCurrency(item.amount))
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    let index = value.index
                    if index < data.count {
                        AxisValueLabel {
                            HStack(spacing: 6) {
                                if let icon = data[index].icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(data[index].color)
                                }
                                Text(data[index].category)
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }
                    }
                }
            }
            .frame(height: max(CGFloat(data.count) * 45, 200))
            
            // Category Legend
            VStack(spacing: 8) {
                ForEach(data) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.system(size: 12))
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.category)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.amount))
                            .font(.spotifyCaptionMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Expenses Breakdown View (Full Page)

struct ExpensesBreakdownView: View {
    let dateRange: DateRange
    let expenseData: [ChartDataItem]
    let subscriptions: [Subscription]
    let savingsOpportunities: [SavingsSuggestion]
    let unusedSubscriptions: [Subscription]
    let annualSuggestions: [AnnualSuggestion]
    @EnvironmentObject var dataManager: DataManager

    @State private var selectedCategory: String?

    private var totalExpenses: Double {
        expenseData.reduce(0) { $0 + $1.amount }
    }

    private var averageExpense: Double {
        guard !expenseData.isEmpty else { return 0 }
        return totalExpenses / Double(expenseData.count)
    }

    private var totalSubscriptionCost: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Pie Chart and Contribution List
                if expenseData.isEmpty {
                    emptyExpenseState
                } else {
                    VStack(spacing: 16) {
                        CategoryPieChart(
                            data: expenseData,
                            total: totalExpenses,
                            isIncome: false,
                            dateRange: dateRange.displayName
                        )
                        .padding(.horizontal, 16)

                        CategoryContributionList(
                            data: expenseData,
                            total: totalExpenses,
                            isIncome: false,
                            selectedCategory: $selectedCategory
                        )
                        .padding(.horizontal, 16)
                    }
                }

                // Subscription Summary
                subscriptionSummarySection

                // Savings Opportunities
                savingsOpportunitiesSection

            }
            .padding(.top, 16)
        }
        .refreshable {
            // Refresh data
            HapticManager.shared.pullToRefresh()
            dataManager.loadAllData()
            ToastManager.shared.showSuccess("Refreshed")
        }
    }

    // MARK: - Subscription Summary Section
    
    private var subscriptionSummarySection: some View {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("SUBSCRIPTION OVERVIEW")
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 16)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatisticsCardComponent(
                    icon: "star.circle.fill",
                    title: "Active",
                    value: "\(activeSubscriptions.count)",
                    iconColor: .wiseBrightGreen
                )
                
                StatisticsCardComponent(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly",
                    value: formatCurrency(totalSubscriptionCost),
                    iconColor: .wiseBlue
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Savings Opportunities Section
    
    private var savingsOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Opportunities")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)
            
            if savingsOpportunities.isEmpty && unusedSubscriptions.isEmpty && annualSuggestions.isEmpty {
                emptyInsightsView
                    .padding(.horizontal, 16)
            } else {
                // Display opportunities
                ForEach(savingsOpportunities.prefix(5)) { suggestion in
                    SavingsSuggestionCard(suggestion: suggestion)
                        .padding(.horizontal, 16)
                }
                
                // Unused Subscriptions
                if !unusedSubscriptions.isEmpty {
                    unusedSubscriptionsCard(subscriptions: unusedSubscriptions)
                        .padding(.horizontal, 16)
                }
                
                // Annual Conversion Suggestions
                if !annualSuggestions.isEmpty {
                    annualConversionCard(suggestions: annualSuggestions)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyExpenseState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 64))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Expense Data")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("No expense transactions found for the selected period")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Insight Cards

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

            Text("\(subscriptions.count) subscription\(subscriptions.count == 1 ? "" : "s") haven't been used recently")
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
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

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
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Expense Flow Chart View

struct ExpenseFlowChartView: View {
    let data: [ChartDataItem]
    
    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("Expense Breakdown")
                .font(.spotifyHeadingLarge)
                .foregroundColor(.wisePrimaryText)
            
            // Total Amount
            Text(formatCurrency(totalAmount))
                .font(.spotifyNumberLarge)
                .foregroundColor(.wiseError)
            
            // Flow Chart
            Chart(data) { item in
                BarMark(
                    x: .value("Amount", item.amount)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(8)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(formatCurrency(item.amount))
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    let index = value.index
                    if index < data.count {
                        AxisValueLabel {
                            HStack(spacing: 6) {
                                if let icon = data[index].icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(data[index].color)
                                }
                                Text(data[index].category)
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }
                    }
                }
            }
            .frame(height: max(CGFloat(data.count) * 45, 200))
            
            // Category Legend
            VStack(spacing: 8) {
                ForEach(data) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.system(size: 12))
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.category)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.amount))
                            .font(.spotifyCaptionMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Savings Suggestion Card

struct SavingsSuggestionCard: View {
    let suggestion: SavingsSuggestion
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        HStack(spacing: 16) {
            // Icon with proper spacing (no overlap)
            Circle()
                .fill(colorForType(suggestion.type).opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: iconForType(suggestion.type))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colorForType(suggestion.type))
                )

            // Content with proper spacing
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.type.rawValue)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                Text(suggestion.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)

                if suggestion.potentialSavings > 0 {
                    Text("Save \(formatCurrency(suggestion.potentialSavings))")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseBrightGreen)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .cardShadow()
    }

    private func iconForType(_ type: SuggestionType) -> String {
        switch type {
        case .unused, .unusedSubscription: return "pause.circle.fill"
        case .annualConversion, .switchToAnnual: return "arrow.2.circlepath.circle.fill"
        case .priceIncrease: return "arrow.up.circle.fill"
        case .alternative: return "lightbulb.fill"
        case .trialEnding: return "hourglass"
        }
    }

    private func colorForType(_ type: SuggestionType) -> Color {
        switch type {
        case .unused, .unusedSubscription: return .wiseOrange
        case .annualConversion, .switchToAnnual: return .wiseBrightGreen
        case .priceIncrease: return .wiseError
        case .alternative: return .wiseBlue
        case .trialEnding: return .wisePurple
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
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
