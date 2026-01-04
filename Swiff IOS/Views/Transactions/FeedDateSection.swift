//
//  FeedDateSection.swift
//  Swiff IOS
//
//  Date grouping utility for feed transactions
//  Groups transactions by actual calendar dates (e.g., "JAN 3, 2026")
//

import Foundation

// MARK: - Feed Date Section

/// Section model for date-grouped transactions in the feed
struct FeedDateSection: Identifiable, Equatable {
    let id: UUID
    let title: String
    let transactions: [Transaction]

    init(id: UUID = UUID(), title: String, transactions: [Transaction]) {
        self.id = id
        self.title = title
        self.transactions = transactions
    }

    var isEmpty: Bool { transactions.isEmpty }

    static func == (lhs: FeedDateSection, rhs: FeedDateSection) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

// MARK: - Feed Date Group

/// Date group categories matching reference design
enum FeedDateGroup: String, CaseIterable {
    case today = "TODAY"
    case yesterday = "YESTERDAY"
    case thisWeek = "THIS WEEK"
    case lastWeek = "LAST WEEK"
    case older = "OLDER"

    /// Determine which date group a date belongs to
    static func group(for date: Date, calendar: Calendar = .current, now: Date = Date()) -> FeedDateGroup {
        // Check Today
        if calendar.isDateInToday(date) {
            return .today
        }

        // Check Yesterday
        if calendar.isDateInYesterday(date) {
            return .yesterday
        }

        // Get start of today
        let startOfToday = calendar.startOfDay(for: now)

        // Get start of this week (Sunday or Monday depending on locale)
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return .older
        }

        // Get start of last week
        guard let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)
        else {
            return .older
        }

        // Check This Week (excluding today and yesterday)
        if date >= thisWeekStart && date < startOfToday {
            return .thisWeek
        }

        // Check Last Week
        if date >= lastWeekStart && date < thisWeekStart {
            return .lastWeek
        }

        return .older
    }

    /// Display order for sections
    var sortOrder: Int {
        switch self {
        case .today: return 0
        case .yesterday: return 1
        case .thisWeek: return 2
        case .lastWeek: return 3
        case .older: return 4
        }
    }
}

// MARK: - Transaction Array Extension

extension Array where Element == Transaction {

    /// Group transactions by date sections for feed display
    /// Returns sections grouped by actual calendar dates (e.g., "JAN 3, 2026")
    func groupedByFeedSections(
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [FeedDateSection] {
        // Sort by date descending (most recent first)
        let sorted = self.sorted { $0.date > $1.date }

        // Group by calendar date (day)
        var groups: [Date: [Transaction]] = [:]

        for transaction in sorted {
            let dayStart = calendar.startOfDay(for: transaction.date)
            if groups[dayStart] == nil {
                groups[dayStart] = []
            }
            groups[dayStart]?.append(transaction)
        }

        // Sort dates descending and create sections
        let sortedDates = groups.keys.sorted(by: >)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        return sortedDates.map { date in
            let title = formatter.string(from: date).uppercased()
            return FeedDateSection(
                title: title,
                transactions: groups[date] ?? []
            )
        }
    }

    /// Filter transactions by FeedFilterTab
    func filtered(by tab: FeedFilterTab) -> [Transaction] {
        switch tab {
        case .all:
            return self
        case .income:
            return filter { !$0.isExpense }
        case .sent:
            let sentTypes: [TransactionType] = [.send, .payment]
            return filter { $0.isExpense && sentTypes.contains($0.derivedTransactionType) }
        case .request:
            return filter { $0.paymentStatus == .pending }
        case .transfer:
            return filter { $0.category == .transfer }
        }
    }
}
