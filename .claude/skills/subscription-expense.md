# Subscription & Expense Domain Patterns

## Purpose
Guide domain-specific implementation for subscription management, expense tracking, billing calculations, and financial business logic.

## When to Use This Skill
- Implementing subscription features
- Adding expense tracking functionality
- Calculating billing and renewals
- Managing group expenses
- Building financial analytics

---

## Domain Models

### Subscription Model

```swift
// Models/DataModels/Subscription.swift
struct Subscription: Identifiable, Codable, Hashable {
    var id: UUID = UUID()

    // Core Properties
    var name: String
    var description: String
    var price: Double
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var icon: String
    var color: String

    // Status
    var nextBillingDate: Date
    var isActive: Bool = true
    var isPaused: Bool = false
    var isCancelled: Bool = false

    // Sharing
    var isShared: Bool = false
    var sharedWith: [UUID] = []

    // Trial Tracking
    var isFreeTrial: Bool = false
    var trialStartDate: Date?
    var trialEndDate: Date?
    var willConvertToPaid: Bool = false

    // Reminders
    var enableRenewalReminder: Bool = true
    var reminderDaysBefore: Int = 3
    var reminderTime: Date?
    var lastReminderSent: Date?

    // Usage Tracking
    var lastUsedDate: Date?
    var usageCount: Int = 0

    // Cancellation Info
    var cancellationDeadline: Date?
    var cancellationDifficulty: CancellationDifficulty?
    var cancellationInstructions: String?
    var cancellationURL: String?

    // Metadata
    var notes: String = ""
    var website: String = ""
    var totalSpent: Double = 0
    var dateAdded: Date = Date()
}
```

### Supporting Enums

```swift
enum BillingCycle: String, Codable, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case semiAnnually
    case yearly
    case annually
    case lifetime

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnually: return "Semi-annually"
        case .yearly, .annually: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var monthsPerCycle: Double {
        switch self {
        case .daily: return 1.0 / 30.0
        case .weekly: return 1.0 / 4.33
        case .biweekly: return 1.0 / 2.17
        case .monthly: return 1.0
        case .quarterly: return 3.0
        case .semiAnnually: return 6.0
        case .yearly, .annually: return 12.0
        case .lifetime: return 0
        }
    }
}

enum SubscriptionCategory: String, Codable, CaseIterable {
    case entertainment
    case productivity
    case health
    case education
    case news
    case utilities
    case gaming
    case design
    case development
    case finance
    case other

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .entertainment: return "tv.fill"
        case .productivity: return "briefcase.fill"
        case .health: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .news: return "newspaper.fill"
        case .utilities: return "wrench.fill"
        case .gaming: return "gamecontroller.fill"
        case .design: return "paintbrush.fill"
        case .development: return "chevron.left.forwardslash.chevron.right"
        case .finance: return "dollarsign.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .entertainment: return "#E50914"
        case .productivity: return "#007AFF"
        case .health: return "#34C759"
        case .education: return "#FF9500"
        case .news: return "#000000"
        case .utilities: return "#8E8E93"
        case .gaming: return "#AF52DE"
        case .design: return "#FF2D55"
        case .development: return "#5856D6"
        case .finance: return "#30D158"
        case .other: return "#636366"
        }
    }
}

enum CancellationDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var displayName: String {
        rawValue.capitalized
    }
}
```

---

## Billing Calculations

### Monthly Cost Calculator

```swift
// Utilities/BillingCycleCalculator.swift
struct BillingCycleCalculator {

    /// Calculate monthly equivalent cost
    static func monthlyEquivalent(price: Double, cycle: BillingCycle) -> Double {
        switch cycle {
        case .daily:
            return price * 30
        case .weekly:
            return price * 4.33
        case .biweekly:
            return price * 2.17
        case .monthly:
            return price
        case .quarterly:
            return price / 3
        case .semiAnnually:
            return price / 6
        case .yearly, .annually:
            return price / 12
        case .lifetime:
            return 0
        }
    }

    /// Calculate yearly equivalent cost
    static func yearlyEquivalent(price: Double, cycle: BillingCycle) -> Double {
        return monthlyEquivalent(price: price, cycle: cycle) * 12
    }

    /// Calculate next billing date based on cycle
    static func nextBillingDate(from date: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current

        switch cycle {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .semiAnnually:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
        case .yearly, .annually:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .lifetime:
            return Date.distantFuture
        }
    }

    /// Calculate days until next billing
    static func daysUntilBilling(nextBillingDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextBillingDate)
        return components.day ?? 0
    }
}
```

### Total Cost Calculations

```swift
extension DataManager {

    /// Calculate total monthly subscription cost
    func calculateTotalMonthlyCost() -> Double {
        getActiveSubscriptions().reduce(0.0) { total, subscription in
            total + BillingCycleCalculator.monthlyEquivalent(
                price: subscription.price,
                cycle: subscription.billingCycle
            )
        }
    }

    /// Calculate total yearly subscription cost
    func calculateTotalYearlyCost() -> Double {
        calculateTotalMonthlyCost() * 12
    }

    /// Calculate cost by category
    func calculateCostByCategory() -> [SubscriptionCategory: Double] {
        var result: [SubscriptionCategory: Double] = [:]

        for subscription in getActiveSubscriptions() {
            let monthlyAmount = BillingCycleCalculator.monthlyEquivalent(
                price: subscription.price,
                cycle: subscription.billingCycle
            )
            result[subscription.category, default: 0] += monthlyAmount
        }

        return result
    }
}
```

---

## Transaction Model

```swift
// Models/DataModels/Transaction.swift
struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()

    // Core Properties
    var title: String
    var subtitle: String
    var amount: Double  // Negative for expenses, positive for income
    var category: TransactionCategory
    var date: Date

    // Additional Info
    var isRecurring: Bool = false
    var tags: [String] = []
    var merchant: String = ""
    var location: String = ""
    var notes: String = ""

    // Status
    var paymentStatus: PaymentStatus = .completed
    var paymentMethod: PaymentMethod?

    // Receipt
    var receiptData: Data?

    // Subscription Link
    var linkedSubscriptionId: UUID?

    // Computed Properties
    var isExpense: Bool {
        amount < 0
    }

    var isIncome: Bool {
        amount > 0
    }

    var absoluteAmount: Double {
        abs(amount)
    }
}

enum TransactionCategory: String, Codable, CaseIterable {
    case dining
    case groceries
    case transportation
    case travel
    case shopping
    case entertainment
    case utilities
    case healthcare
    case income
    case transfer
    case investment
    case subscriptions
    case other

    var displayName: String {
        switch self {
        case .dining: return "Food & Dining"
        case .groceries: return "Groceries"
        case .transportation: return "Transportation"
        case .travel: return "Travel"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .utilities: return "Bills & Utilities"
        case .healthcare: return "Healthcare"
        case .income: return "Income"
        case .transfer: return "Transfer"
        case .investment: return "Investment"
        case .subscriptions: return "Subscriptions"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .dining: return "fork.knife"
        case .groceries: return "cart.fill"
        case .transportation: return "car.fill"
        case .travel: return "airplane"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .utilities: return "house.fill"
        case .healthcare: return "cross.fill"
        case .income: return "dollarsign.circle.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .subscriptions: return "repeat"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum PaymentStatus: String, Codable, CaseIterable {
    case pending
    case completed
    case failed
    case disputed
    case refunded
}

enum PaymentMethod: String, Codable, CaseIterable {
    case creditCard
    case debitCard
    case paypal
    case applePay
    case googlePay
    case bankTransfer
    case cash
    case other

    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .paypal: return "PayPal"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .bankTransfer: return "Bank Transfer"
        case .cash: return "Cash"
        case .other: return "Other"
        }
    }
}
```

---

## Group Expense Model

```swift
// Models/DataModels/Group.swift
struct Group: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var emoji: String
    var members: [UUID]  // Person IDs
    var expenses: [GroupExpense] = []
    var createdDate: Date = Date()
    var totalAmount: Double = 0

    /// Calculate balance for a specific member
    func balance(for memberId: UUID) -> Double {
        var balance: Double = 0

        for expense in expenses where !expense.isSettled {
            if expense.paidBy == memberId {
                // They paid, others owe them
                let sharePerPerson = expense.amount / Double(expense.splitBetween.count)
                let othersShare = sharePerPerson * Double(expense.splitBetween.count - 1)
                balance += othersShare
            } else if expense.splitBetween.contains(memberId) {
                // They owe money
                let sharePerPerson = expense.amount / Double(expense.splitBetween.count)
                balance -= sharePerPerson
            }
        }

        return balance
    }
}

struct GroupExpense: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var paidBy: UUID  // Person ID
    var splitBetween: [UUID]  // Person IDs
    var category: TransactionCategory
    var date: Date = Date()
    var notes: String = ""
    var receipt: String?  // Image path
    var isSettled: Bool = false

    /// Calculate each person's share
    var sharePerPerson: Double {
        guard !splitBetween.isEmpty else { return 0 }
        return amount / Double(splitBetween.count)
    }
}
```

---

## Price Change Tracking

```swift
// Models/DataModels/PriceChange.swift
struct PriceChange: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var subscriptionId: UUID
    var oldPrice: Double
    var newPrice: Double
    var changeDate: Date = Date()
    var reason: String?
    var detectedAutomatically: Bool = true

    var percentageChange: Double {
        guard oldPrice > 0 else { return 0 }
        return ((newPrice - oldPrice) / oldPrice) * 100
    }

    var isIncrease: Bool {
        newPrice > oldPrice
    }

    var isDecrease: Bool {
        newPrice < oldPrice
    }

    var absoluteChange: Double {
        newPrice - oldPrice
    }
}
```

---

## Renewal Service

```swift
// Services/SubscriptionRenewalService.swift
@MainActor
class SubscriptionRenewalService: ObservableObject {
    static let shared = SubscriptionRenewalService()

    private let persistenceService = PersistenceService.shared

    /// Process overdue subscription renewals
    func processOverdueRenewals() async {
        do {
            let subscriptions = try persistenceService.fetchActiveSubscriptions()
            let now = Date()

            for subscription in subscriptions {
                if subscription.nextBillingDate < now && subscription.billingCycle != .lifetime {
                    await processRenewal(subscription)
                }
            }
        } catch {
            print("Error processing renewals: \(error)")
        }
    }

    private func processRenewal(_ subscription: Subscription) async {
        var updated = subscription

        // Update to next billing date
        updated.nextBillingDate = BillingCycleCalculator.nextBillingDate(
            from: subscription.nextBillingDate,
            cycle: subscription.billingCycle
        )

        // Update total spent
        updated.totalSpent += subscription.price

        // Handle trial conversion
        if subscription.isFreeTrial && subscription.willConvertToPaid {
            if let trialEnd = subscription.trialEndDate, trialEnd <= Date() {
                updated.isFreeTrial = false
            }
        }

        do {
            try persistenceService.updateSubscription(updated)
        } catch {
            print("Failed to update subscription: \(error)")
        }
    }

    /// Get subscriptions renewing within specified days
    func getUpcomingRenewals(within days: Int) -> [Subscription] {
        do {
            return try persistenceService.fetchSubscriptionsRenewingSoon(days: days)
        } catch {
            return []
        }
    }

    /// Pause a subscription
    func pauseSubscription(_ subscription: Subscription) async {
        var updated = subscription
        updated.isPaused = true
        updated.isActive = false

        do {
            try persistenceService.updateSubscription(updated)
        } catch {
            print("Failed to pause subscription: \(error)")
        }
    }

    /// Resume a paused subscription
    func resumeSubscription(_ subscription: Subscription) async {
        var updated = subscription
        updated.isPaused = false
        updated.isActive = true

        // Recalculate next billing date from today
        updated.nextBillingDate = BillingCycleCalculator.nextBillingDate(
            from: Date(),
            cycle: subscription.billingCycle
        )

        do {
            try persistenceService.updateSubscription(updated)
        } catch {
            print("Failed to resume subscription: \(error)")
        }
    }

    /// Cancel a subscription
    func cancelSubscription(_ subscription: Subscription) async {
        var updated = subscription
        updated.isCancelled = true
        updated.isActive = false

        do {
            try persistenceService.updateSubscription(updated)
            NotificationManager.shared.cancelAllReminders(for: updated)
        } catch {
            print("Failed to cancel subscription: \(error)")
        }
    }
}
```

---

## Analytics Calculations

```swift
extension AnalyticsService {

    /// Calculate spending trends over months
    func calculateSpendingTrends(months: Int = 6) -> [MonthlySpending] {
        let calendar = Calendar.current
        var results: [MonthlySpending] = []

        for monthOffset in 0..<months {
            guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else {
                continue
            }

            let monthTransactions = getTransactionsForMonth(date)
            let totalExpenses = monthTransactions
                .filter { $0.amount < 0 }
                .reduce(0) { $0 + abs($1.amount) }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"

            results.append(MonthlySpending(
                month: formatter.string(from: date),
                date: date,
                amount: totalExpenses
            ))
        }

        return results.reversed()
    }

    /// Calculate category breakdown
    func calculateCategoryBreakdown() -> [CategorySpending] {
        let transactions = getCurrentMonthTransactions()
        var breakdown: [TransactionCategory: Double] = [:]

        for transaction in transactions where transaction.amount < 0 {
            breakdown[transaction.category, default: 0] += abs(transaction.amount)
        }

        return breakdown.map { category, amount in
            CategorySpending(category: category, amount: amount)
        }.sorted { $0.amount > $1.amount }
    }

    /// Forecast future spending based on trends
    func forecastSpending(months: Int = 3) -> Double {
        let trends = calculateSpendingTrends(months: 6)
        guard trends.count >= 3 else {
            return 0
        }

        let recentAverage = trends.suffix(3).reduce(0) { $0 + $1.amount } / 3
        return recentAverage * Double(months)
    }
}

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: String
    let date: Date
    let amount: Double
}

struct CategorySpending: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let amount: Double
}
```

---

## Checklist

- [ ] Billing cycle calculations correct
- [ ] Price change detection working
- [ ] Renewal dates advance properly
- [ ] Trial tracking accurate
- [ ] Group expense balances correct
- [ ] Analytics calculations verified
- [ ] Currency formatting consistent

---

## Industry Standards

- **Financial calculation precision** - Use Double for money
- **Date handling** - Use Calendar for date math
- **Billing best practices** - Handle all edge cases
- **GAAP** - Generally Accepted Accounting Principles
