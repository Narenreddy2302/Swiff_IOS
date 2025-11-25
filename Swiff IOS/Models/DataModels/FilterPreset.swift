//
//  FilterPreset.swift
//  Swiff IOS
//
//  Created for Page 2 Task 2.2
//  Advanced filtering system for transactions
//

import Foundation

// MARK: - Advanced Filter Configuration
struct AdvancedTransactionFilter: Codable, Equatable {
    // Date filtering
    var dateRange: DateRange?
    var useCustomDateRange: Bool = false
    var customStartDate: Date?
    var customEndDate: Date?

    // Amount filtering
    var minAmount: Double?
    var maxAmount: Double?

    // Category filtering
    var selectedCategories: Set<TransactionCategory> = []
    var filterAllCategories: Bool = true

    // Toggle filters
    var hasReceipt: Bool? = nil  // nil = don't filter, true/false = filter
    var isRecurring: Bool? = nil
    var isLinkedToSubscription: Bool? = nil

    // Payment status filtering
    var selectedStatuses: Set<PaymentStatus> = []
    var filterAllStatuses: Bool = true

    // Transaction type
    var transactionType: TransactionTypeFilter = .all

    enum TransactionTypeFilter: String, Codable {
        case all = "All"
        case expenses = "Expenses Only"
        case income = "Income Only"
    }

    enum DateRange: String, Codable, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom Range"

        func getDateRange() -> (start: Date, end: Date)? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                return (start, now)

            case .yesterday:
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                      let start = calendar.startOfDay(for: yesterday) as Date?,
                      let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                    return nil
                }
                return (start, end)

            case .last7Days:
                guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
                return (start, now)

            case .last30Days:
                guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return nil }
                return (start, now)

            case .last90Days:
                guard let start = calendar.date(byAdding: .day, value: -90, to: now) else { return nil }
                return (start, now)

            case .thisMonth:
                guard let start = calendar.dateInterval(of: .month, for: now)?.start else { return nil }
                return (start, now)

            case .lastMonth:
                guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now),
                      let interval = calendar.dateInterval(of: .month, for: lastMonthDate) else {
                    return nil
                }
                return (interval.start, interval.end)

            case .custom:
                return nil
            }
        }
    }

    // Check if any filters are active
    var hasActiveFilters: Bool {
        return dateRange != nil ||
               useCustomDateRange ||
               minAmount != nil ||
               maxAmount != nil ||
               !filterAllCategories ||
               hasReceipt != nil ||
               isRecurring != nil ||
               isLinkedToSubscription != nil ||
               !filterAllStatuses ||
               transactionType != .all
    }

    // Count active filters
    var activeFilterCount: Int {
        var count = 0
        if dateRange != nil || useCustomDateRange { count += 1 }
        if minAmount != nil || maxAmount != nil { count += 1 }
        if !filterAllCategories { count += 1 }
        if hasReceipt != nil { count += 1 }
        if isRecurring != nil { count += 1 }
        if isLinkedToSubscription != nil { count += 1 }
        if !filterAllStatuses { count += 1 }
        if transactionType != .all { count += 1 }
        return count
    }

    // Reset all filters
    mutating func reset() {
        dateRange = nil
        useCustomDateRange = false
        customStartDate = nil
        customEndDate = nil
        minAmount = nil
        maxAmount = nil
        selectedCategories = []
        filterAllCategories = true
        hasReceipt = nil
        isRecurring = nil
        isLinkedToSubscription = nil
        selectedStatuses = []
        filterAllStatuses = true
        transactionType = .all
    }
}

// MARK: - Filter Preset (Saved Filters)
struct FilterPreset: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var filter: AdvancedTransactionFilter
    var createdDate: Date = Date()
    var icon: String = "line.3.horizontal.decrease.circle"

    // Predefined presets
    static let recentExpenses = FilterPreset(
        name: "Recent Expenses",
        filter: AdvancedTransactionFilter(
            dateRange: .last30Days,
            transactionType: .expenses
        ),
        icon: "arrow.down.circle"
    )

    static let largeTransactions = FilterPreset(
        name: "Large Transactions",
        filter: AdvancedTransactionFilter(
            dateRange: .last30Days,
            minAmount: 100
        ),
        icon: "dollarsign.circle"
    )

    static let recurringOnly = FilterPreset(
        name: "Recurring",
        filter: AdvancedTransactionFilter(
            isRecurring: true
        ),
        icon: "repeat.circle"
    )

    static let withReceipts = FilterPreset(
        name: "With Receipts",
        filter: AdvancedTransactionFilter(
            hasReceipt: true
        ),
        icon: "camera.circle"
    )

    static let linkedSubscriptions = FilterPreset(
        name: "Linked to Subscriptions",
        filter: AdvancedTransactionFilter(
            isLinkedToSubscription: true
        ),
        icon: "link.circle"
    )

    static let defaults: [FilterPreset] = [
        recentExpenses,
        largeTransactions,
        recurringOnly,
        withReceipts,
        linkedSubscriptions
    ]
}

// MARK: - Transaction Filtering Extension
extension Array where Element == Transaction {
    func applyFilter(_ filter: AdvancedTransactionFilter) -> [Transaction] {
        var filtered = self

        // Date range filtering
        if let dateRange = filter.dateRange, !filter.useCustomDateRange {
            if let range = dateRange.getDateRange() {
                filtered = filtered.filter { $0.date >= range.start && $0.date <= range.end }
            }
        } else if filter.useCustomDateRange,
                  let start = filter.customStartDate,
                  let end = filter.customEndDate {
            filtered = filtered.filter { $0.date >= start && $0.date <= end }
        }

        // Amount filtering
        if let min = filter.minAmount {
            filtered = filtered.filter { abs($0.amount) >= min }
        }
        if let max = filter.maxAmount {
            filtered = filtered.filter { abs($0.amount) <= max }
        }

        // Category filtering
        if !filter.filterAllCategories && !filter.selectedCategories.isEmpty {
            filtered = filtered.filter { filter.selectedCategories.contains($0.category) }
        }

        // Toggle filters
        if let hasReceipt = filter.hasReceipt {
            filtered = filtered.filter { $0.hasReceipt == hasReceipt }
        }
        if let isRecurring = filter.isRecurring {
            filtered = filtered.filter { $0.isRecurring == isRecurring }
        }
        if let isLinked = filter.isLinkedToSubscription {
            filtered = filtered.filter { $0.isLinkedToSubscription == isLinked }
        }

        // Status filtering
        if !filter.filterAllStatuses && !filter.selectedStatuses.isEmpty {
            filtered = filtered.filter { filter.selectedStatuses.contains($0.paymentStatus) }
        }

        // Transaction type filtering
        switch filter.transactionType {
        case .expenses:
            filtered = filtered.filter { $0.isExpense }
        case .income:
            filtered = filtered.filter { !$0.isExpense }
        case .all:
            break
        }

        return filtered
    }
}
