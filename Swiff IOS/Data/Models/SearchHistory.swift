//
//  SearchHistory.swift
//  Swiff IOS
//
//  Created by Agent 12 on 11/21/25.
//  Search history model with UserDefaults persistence
//

import Foundation
import Combine

// MARK: - Search History Item

struct SearchHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let timestamp: Date
    let resultCount: Int

    init(query: String, resultCount: Int = 0) {
        self.id = UUID()
        self.query = query
        self.timestamp = Date()
        self.resultCount = resultCount
    }
}

// MARK: - Search History Manager

@MainActor
class SearchHistoryManager: ObservableObject {

    // MARK: - Constants

    private static let maxHistoryItems = 10
    private static let historyKey = "com.swiff.searchHistory"

    // MARK: - Published Properties

    @Published var history: [SearchHistoryItem] = []

    // MARK: - Singleton

    static let shared = SearchHistoryManager()

    // MARK: - Initialization

    private init() {
        loadHistory()
    }

    // MARK: - Public Methods

    /// Add a search query to history
    func addSearch(_ query: String, resultCount: Int = 0) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Remove duplicate if exists
        history.removeAll { $0.query.lowercased() == query.lowercased() }

        // Add new item at the beginning
        let item = SearchHistoryItem(query: query, resultCount: resultCount)
        history.insert(item, at: 0)

        // Keep only the most recent items
        if history.count > Self.maxHistoryItems {
            history = Array(history.prefix(Self.maxHistoryItems))
        }

        saveHistory()
    }

    /// Remove a specific search from history
    func removeSearch(_ item: SearchHistoryItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    /// Clear all search history
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    /// Get recent searches (for suggestions)
    func getRecentSearches(limit: Int = 5) -> [String] {
        return Array(history.prefix(limit)).map { $0.query }
    }

    // MARK: - Private Methods

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.historyKey) else {
            history = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([SearchHistoryItem].self, from: data)
            history = decoded
        } catch {
            print("Failed to load search history: \(error)")
            history = []
        }
    }

    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(history)
            UserDefaults.standard.set(encoded, forKey: Self.historyKey)
        } catch {
            print("Failed to save search history: \(error)")
        }
    }
}

// MARK: - Search Result Type

enum SearchResultType: String, CaseIterable {
    case person = "People"
    case subscription = "Subscriptions"
    case transaction = "Transactions"

    var icon: String {
        switch self {
        case .person: return "person.circle.fill"
        case .subscription: return "repeat.circle.fill"
        case .transaction: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Search Result

struct SearchResult: Identifiable {
    let id: UUID
    let type: SearchResultType
    let title: String
    let subtitle: String
    let metadata: String // Additional info (e.g., price, date, balance)
    let icon: String
    let color: String
    let matchScore: Double // For relevance sorting

    init(
        id: UUID,
        type: SearchResultType,
        title: String,
        subtitle: String,
        metadata: String = "",
        icon: String,
        color: String,
        matchScore: Double = 0.0
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata
        self.icon = icon
        self.color = color
        self.matchScore = matchScore
    }
}

// MARK: - Search Sort Option

enum SearchSortOption: String, CaseIterable {
    case relevance = "Relevance"
    case date = "Date (Newest)"
    case amount = "Amount (Highest)"
    case nameAZ = "Name (A-Z)"

    var icon: String {
        switch self {
        case .relevance: return "sparkles"
        case .date: return "calendar"
        case .amount: return "dollarsign.circle"
        case .nameAZ: return "textformat"
        }
    }
}

// MARK: - Advanced Search Filters

struct SearchFilters: Equatable {
    // Category filters
    var selectedCategories: Set<String> = []

    // Date range
    var startDate: Date?
    var endDate: Date?

    // Amount range
    var minAmount: Double?
    var maxAmount: Double?

    // Status filters
    var statusFilters: Set<String> = [] // "active", "paused", "cancelled"

    // Tags
    var selectedTags: Set<String> = []

    // Payment method
    var paymentMethods: Set<String> = []

    // Result type filter
    var resultTypes: Set<SearchResultType> = [.subscription, .transaction]

    var isActive: Bool {
        !selectedCategories.isEmpty ||
        startDate != nil ||
        endDate != nil ||
        minAmount != nil ||
        maxAmount != nil ||
        !statusFilters.isEmpty ||
        !selectedTags.isEmpty ||
        !paymentMethods.isEmpty ||
        resultTypes.count < 2 // subscription + transaction
    }

    mutating func reset() {
        selectedCategories.removeAll()
        startDate = nil
        endDate = nil
        minAmount = nil
        maxAmount = nil
        statusFilters.removeAll()
        selectedTags.removeAll()
        paymentMethods.removeAll()
        resultTypes = [.subscription, .transaction]
    }
}
