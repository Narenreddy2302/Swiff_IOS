//
//  AnalyticsComponents.swift
//  Swiff IOS
//
//  All missing analytics components with proper design
//  Created: 2025-11-26
//

import SwiftUI
import Charts

// MARK: - Animated Counter Text Component

/// A view that animates number counting with an ease-out-quart curve for premium feel
struct AnimatedCounterText: View {
    let targetValue: Double
    let duration: Double
    let prefix: String
    let suffix: String
    let showDecimals: Bool

    @State private var displayValue: Double = 0
    @State private var hasAnimated = false
    @State private var scaleEffect: CGFloat = 1.0

    init(
        targetValue: Double,
        duration: Double = 1.2,
        prefix: String = "$",
        suffix: String = "",
        showDecimals: Bool = true
    ) {
        self.targetValue = targetValue
        self.duration = duration
        self.prefix = prefix
        self.suffix = suffix
        self.showDecimals = showDecimals
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(prefix)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.wisePrimaryText)

            let integerPart = Int(displayValue)
            let decimalPart = Int((displayValue - Double(integerPart)) * 100)

            Text("\(integerPart)")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.wisePrimaryText)
                .contentTransition(.numericText(value: displayValue))

            if showDecimals {
                Text(".\(String(format: "%02d", decimalPart))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.wiseSecondaryText)
            }

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .scaleEffect(scaleEffect)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)

            // Ease-out-quart: 1 - (1 - t)^4
            let easedProgress = 1 - pow(1 - progress, 4)

            withAnimation(.linear(duration: 0.016)) {
                displayValue = targetValue * easedProgress
            }

            if progress >= 1.0 {
                timer.invalidate()
                displayValue = targetValue

                // Subtle scale pop on completion
                withAnimation(.counterSettle) {
                    scaleEffect = 1.03
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.counterSettle) {
                        scaleEffect = 1.0
                    }
                }
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

// MARK: - Premium Card Entrance Modifier

/// ViewModifier for premium card entrance animation with scale, opacity, offset, and blur
struct PremiumCardEntrance: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.92)
            .opacity(isVisible ? 1.0 : 0)
            .offset(y: isVisible ? 0 : 25)
            .blur(radius: isVisible ? 0 : 2)
            .animation(
                .premiumCardAppear.delay(delay),
                value: isVisible
            )
    }
}

extension View {
    /// Applies premium card entrance animation
    func premiumCardEntrance(isVisible: Bool, delay: Double = 0) -> some View {
        self.modifier(PremiumCardEntrance(isVisible: isVisible, delay: delay))
    }
}

// MARK: - Shimmer Progress Bar

/// A progress bar with shimmer sweep effect after fill completion
struct ShimmerProgressBar: View {
    let progress: Double
    let color: Color
    let animate: Bool

    @State private var fillProgress: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -100
    @State private var showShimmer = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.wiseSeparator.opacity(0.3))
                    .frame(height: 4)

                // Progress fill with shimmer overlay
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * fillProgress, height: 4)
                    .overlay(alignment: .leading) {
                        if showShimmer {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    .white.opacity(0.5),
                                    .clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 50, height: 4)
                            .offset(x: shimmerOffset)
                        }
                    }
                    .clipShape(Capsule())
            }
        }
        .frame(height: 4)
        .onChange(of: animate) { _, newValue in
            if newValue {
                // Reset
                fillProgress = 0
                shimmerOffset = -100
                showShimmer = false

                // Fill animation
                withAnimation(.progressFill.delay(0.3)) {
                    fillProgress = CGFloat(min(max(progress, 0), 1))
                }

                // Shimmer sweep after fill completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showShimmer = true
                    withAnimation(.linear(duration: 0.6)) {
                        shimmerOffset = 300
                    }
                    // Hide shimmer after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        showShimmer = false
                    }
                }
            }
        }
        .onAppear {
            if animate {
                withAnimation(.progressFill.delay(0.3)) {
                    fillProgress = CGFloat(min(max(progress, 0), 1))
                }
            }
        }
    }
}

// MARK: - Analytics Data Types

struct AnalyticsCategoryData: Identifiable {
    let id: UUID
    let icon: String
    let name: String
    let color: Color
    let percentage: Double
    let amount: Double
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Spending Trend Chart

struct SpendingTrendChart: View {
    let dateRange: DateRange
    let transactions: [Transaction]
    let animate: Bool
    
    @State private var selectedDate: Date?
    @State private var animateChart = false
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current

        // Group transactions by day/week/month based on dateRange
        let groupedData: [Date: Double]
        
        switch dateRange {
        case .week:
            // Daily grouping for week
            groupedData = Dictionary(grouping: transactions) { transaction in
                calendar.startOfDay(for: transaction.date)
            }.mapValues { txns in
                txns.filter { $0.isExpense }.reduce(0.0) { $0 + abs($1.amount) }
            }

        case .month, .custom:
            // Daily grouping for month and custom ranges
            groupedData = Dictionary(grouping: transactions) { transaction in
                calendar.startOfDay(for: transaction.date)
            }.mapValues { txns in
                txns.filter { $0.isExpense }.reduce(0.0) { $0 + abs($1.amount) }
            }

        case .quarter, .year:
            // Weekly grouping for quarter/year
            groupedData = Dictionary(grouping: transactions) { transaction in
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: transaction.date)
                return calendar.date(from: components) ?? transaction.date
            }.mapValues { txns in
                txns.filter { $0.isExpense }.reduce(0.0) { $0 + abs($1.amount) }
            }
        }
        
        return groupedData.map { ChartDataPoint(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private var averageSpending: Double {
        guard !chartData.isEmpty else { return 0 }
        let total = chartData.reduce(0.0) { $0 + $1.amount }
        return total / Double(chartData.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart
            if chartData.isEmpty {
                emptyChartState
            } else {
                chartView
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .onAppear {
            if animate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                        animateChart = true
                    }
                }
            }
        }
        .onChange(of: animate) { oldValue, newValue in
            if newValue {
                animateChart = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                        animateChart = true
                    }
                }
            }
        }
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selected point info or average
            if let selectedDate = selectedDate,
               let selectedPoint = chartData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                selectedPointInfo(selectedPoint)
            } else {
                averageInfo
            }
            
            // Chart
            Chart(chartData) { dataPoint in
                // Area Mark
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", animateChart ? dataPoint.amount : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.wiseBlue.opacity(0.3),
                            Color.wiseBlue.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Line Mark
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", animateChart ? dataPoint.amount : 0)
                )
                .foregroundStyle(Color.wiseBlue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                // Point Mark for selected date
                if let selectedDate = selectedDate,
                   Calendar.current.isDate(dataPoint.date, inSameDayAs: selectedDate) {
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(Color.wiseBlue)
                    .symbolSize(100)
                }
                
                // Average line
                RuleMark(y: .value("Average", averageSpending))
                    .foregroundStyle(Color.wiseSecondaryText.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: dateRangeStride)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.wiseSeparator.opacity(0.3))
                    
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatAxisDate(date))
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.wiseSeparator.opacity(0.3))
                    
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatAxisAmount(amount))
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }
    
    private var emptyChartState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
            
            Text("No spending data")
                .font(.spotifyHeadingSmall)
                .foregroundColor(.wisePrimaryText)
            
            Text("Start tracking expenses to see trends")
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private func selectedPointInfo(_ point: ChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatCurrency(point.amount))
                .font(.spotifyNumberLarge)
                .foregroundColor(.wiseBlue)
            
            Text(formatDate(point.date))
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }
    
    private var averageInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Average Spending")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
            
            Text(formatCurrency(averageSpending))
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
    }
    
    private var dateRangeStride: Calendar.Component {
        switch dateRange {
        case .week: return .day
        case .month, .custom: return .day  // Swift Charts doesn't support .weekOfMonth
        case .quarter: return .day         // Swift Charts doesn't support .weekOfYear
        case .year: return .month
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch dateRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month, .custom:
            formatter.dateFormat = "d"
        case .quarter, .year:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
    
    private func formatAxisAmount(_ amount: Double) -> String {
        let symbol = UserSettings.shared.selectedCurrency.symbol
        if amount >= 1000 {
            return String(format: "%@%.0fk", symbol, amount / 1000)
        } else {
            return amount.asCurrency
        }
    }
}

// MARK: - Financial Metric Card

struct FinancialMetricCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let animate: Bool
    
    @State private var animateValue = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Title
            Text(title)
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)
            
            // Amount
            Text(formatCurrency(amount))
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
                .opacity(animateValue ? 1 : 0)
                .scaleEffect(animateValue ? 1 : 0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .onAppear {
            if animate {
                withAnimation(.gentle.delay(0.2)) {
                    animateValue = true
                }
            }
        }
        .onChange(of: animate) { oldValue, newValue in
            if newValue {
                animateValue = false
                withAnimation(.gentle.delay(0.2)) {
                    animateValue = true
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// MARK: - Team Metric Card

struct TeamMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animate: Bool

    @State private var animateValue = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            // Title
            Text(title)
                .font(.spotifyLabelSmall)
                .textCase(.uppercase)
                .foregroundColor(.wiseSecondaryText)

            // Value
            Text(value)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
                .opacity(animateValue ? 1 : 0)
                .scaleEffect(animateValue ? 1 : 0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .onAppear {
            if animate {
                withAnimation(.gentle.delay(0.2)) {
                    animateValue = true
                }
            }
        }
        .onChange(of: animate) { oldValue, newValue in
            if newValue {
                animateValue = false
                withAnimation(.gentle.delay(0.2)) {
                    animateValue = true
                }
            }
        }
    }
}

// MARK: - Improved Category Row

struct ImprovedCategoryRow: View {
    let category: AnalyticsCategoryData
    let colorScheme: ColorScheme
    let animate: Bool
    let index: Int
    
    @State private var animatedWidth: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
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
                HStack {
                    Text(category.name)
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(category.amount))
                            .font(.spotifyNumberMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        Text("\(Int(category.percentage))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.wiseSeparator.opacity(0.5))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(category.color)
                            .frame(
                                width: geometry.size.width * animatedWidth,
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 15)
        .animation(
            .cardAppear.delay(Double(index) * 0.12),
            value: animate
        )
        .onAppear {
            if animate {
                withAnimation(.gentle.delay(Double(index) * 0.12 + 0.15)) {
                    animatedWidth = CGFloat(category.percentage / 100.0)
                }
            }
        }
        .onChange(of: animate) { oldValue, newValue in
            if newValue {
                animatedWidth = 0
                withAnimation(.gentle.delay(Double(index) * 0.12 + 0.15)) {
                    animatedWidth = CGFloat(category.percentage / 100.0)
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// MARK: - Team Member Analytics Row

struct TeamMemberAnalyticsRow: View {
    let person: Person
    let transactions: [Transaction]

    private var personTransactions: [Transaction] {
        // Filter transactions that mention this person's name
        transactions.filter { transaction in
            transaction.title.contains(person.name) || transaction.subtitle.contains(person.name)
        }
    }

    private var avatarColor: Color {
        AvatarColorPalette.color(for: person.avatarColorIndex)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(person.initials)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(avatarColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                Text("\(personTransactions.count) transactions")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Balance - use the person's actual balance
            VStack(alignment: .trailing, spacing: 4) {
                if person.balance > 0 {
                    Text("+\(formatCurrency(person.balance))")
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wiseBrightGreen)
                } else if person.balance < 0 {
                    Text("-\(formatCurrency(abs(person.balance)))")
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wiseError)
                } else {
                    Text("Settled")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// MARK: - Group Analytics Row

struct GroupAnalyticsRow: View {
    let group: Group
    let people: [Person]
    let transactions: [Transaction]

    private var totalAmount: Double {
        // Use group's totalAmount or calculate from expenses
        group.totalAmount > 0 ? group.totalAmount : group.expenses.reduce(0.0) { $0 + $1.amount }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon - use group emoji
            ZStack {
                Circle()
                    .fill(Color.wisePurple.opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(group.emoji)
                    .font(.system(size: 24))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                Text("\(group.members.count) members • \(group.expenses.count) expenses")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Total
            Text(formatCurrency(totalAmount))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }

    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: QuickInsight
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: insight.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(insight.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)
                
                Text(insight.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }
}

struct QuickInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Subscription Insights Card

struct SubscriptionInsightsCard: View {
    let subscriptions: [Subscription]
    let dateRange: DateRange
    
    private var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }
    
    private var totalMonthlyCost: Double {
        activeSubscriptions.reduce(0.0) { $0 + $1.monthlyEquivalent }
    }
    
    private var mostExpensive: Subscription? {
        activeSubscriptions.max(by: { $0.monthlyEquivalent < $1.monthlyEquivalent })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Cost")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                    
                    Text(formatCurrency(totalMonthlyCost))
                        .font(.spotifyNumberLarge)
                        .foregroundColor(.wisePrimaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                    
                    Text("\(activeSubscriptions.count)")
                        .font(.spotifyNumberLarge)
                        .foregroundColor(.wisePrimaryText)
                }
            }
            
            if let mostExpensive = mostExpensive {
                Divider()
                    .background(Color.wiseSeparator)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Expensive")
                        .font(.spotifyLabelSmall)
                        .textCase(.uppercase)
                        .foregroundColor(.wiseSecondaryText)
                    
                    HStack {
                        Text(mostExpensive.name)
                            .font(.spotifyHeadingSmall)
                            .foregroundColor(.wisePrimaryText)
                        
                        Spacer()
                        
                        Text(formatCurrency(mostExpensive.monthlyEquivalent) + "/mo")
                            .font(.spotifyNumberMedium)
                            .foregroundColor(.wiseError)
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
        return amount.asCurrency
    }
}

// MARK: - Savings Opportunity Card

struct SavingsOpportunityCard: View {
    let opportunity: SavingsOpportunity
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.wiseBrightGreen.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: opportunity.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.wiseBrightGreen)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(opportunity.title)
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)
                
                Text(opportunity.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(2)
                
                if opportunity.potentialSavings > 0 {
                    Text("Save \(formatCurrency(opportunity.potentialSavings))")
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wiseBrightGreen)
                }
            }
            
            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return amount.asCurrency
    }
}

struct SavingsOpportunity: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let potentialSavings: Double
}
