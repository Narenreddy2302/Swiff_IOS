//
//  SearchView.swift
//  Swiff IOS
//
//  Enhanced by Agent 12 on 11/21/25.
//  Advanced search view with history, filters, suggestions, and autocomplete
//

import SwiftUI
import Combine

// MARK: - Enhanced Search View

struct SearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var searchHistory = SearchHistoryManager.shared

    // Search state
    @State private var searchQuery = ""
    @State private var selectedCategory: String?
    @State private var sortOption: SearchSortOption = .relevance
    @State private var searchFilters = SearchFilters()

    // UI state
    @State private var showFilterSheet = false
    @State private var showSortMenu = false
    @State private var isSearching = false

    // Search results
    @State private var searchResults: [SearchResult] = []
    @State private var groupedResults: [SearchResultType: [SearchResult]] = [:]

    // Debounce timer for search
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar with filters
                searchHeader

                // Search results or history
                if searchQuery.isEmpty {
                    searchHistoryView
                } else if isSearching {
                    loadingView
                } else if searchResults.isEmpty {
                    EmptySearchState(query: searchQuery) {
                        clearSearch()
                    }
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFilterSheet) {
                AdvancedSearchFilterSheet(filters: $searchFilters)
            }
        }
        .onChange(of: searchQuery) { oldValue, newValue in
            performSearch()
        }
        .onChange(of: searchFilters) { oldValue, newValue in
            if !searchQuery.isEmpty {
                performSearch()
            }
        }
        .onChange(of: sortOption) { oldValue, newValue in
            if !searchResults.isEmpty {
                sortResults()
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 12) {
            // Search field
            HStack(spacing: 12) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseSecondaryText)

                // Text field
                TextField("Search people, subscriptions, transactions...", text: $searchQuery)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()

                // Clear button
                if !searchQuery.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.wiseBorder.opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal, 16)

            // Filter and sort controls
            if !searchQuery.isEmpty {
                HStack(spacing: 12) {
                    // Category filter (if search has results)
                    if let category = selectedCategory {
                        Button(action: { selectedCategory = nil; performSearch() }) {
                            HStack(spacing: 6) {
                                Text("In: \(category)")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.wiseBrightGreen)
                            .cornerRadius(16)
                        }
                    }

                    // Advanced filters button
                    Button(action: { showFilterSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 14))
                            Text("Filters")
                                .font(.system(size: 13, weight: .medium))
                            if searchFilters.isActive {
                                Circle()
                                    .fill(Color.wiseError)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .foregroundColor(searchFilters.isActive ? .white : .wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(searchFilters.isActive ? Color.wiseBrightGreen : Color.wiseBorder.opacity(0.5))
                        .cornerRadius(16)
                    }

                    Spacer()

                    // Sort menu
                    Menu {
                        ForEach(SearchSortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: sortOption.icon)
                                .font(.system(size: 14))
                            Text(sortOption.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.wiseBorder.opacity(0.5))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Divider()
        }
        .background(Color.wiseCardBackground)
    }

    // MARK: - Search History View

    private var searchHistoryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !searchHistory.history.isEmpty {
                    // History header
                    HStack {
                        Text("Recent Searches")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Button("Clear History") {
                            searchHistory.clearHistory()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseError)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // History items
                    VStack(spacing: 0) {
                        ForEach(searchHistory.history) { item in
                            SearchHistoryRow(
                                item: item,
                                onTap: {
                                    searchQuery = item.query
                                },
                                onDelete: {
                                    searchHistory.removeSearch(item)
                                }
                            )

                            if item.id != searchHistory.history.last?.id {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.wiseMidGray.opacity(0.5))

                        Text("Search Swiff")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.wisePrimaryText)

                        Text("Find people, subscriptions, and transactions")
                            .font(.system(size: 15))
                            .foregroundColor(.wiseSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                }

                // Quick search suggestions
                if searchHistory.history.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Try searching for:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.horizontal, 16)

                        VStack(spacing: 8) {
                            QuickSearchButton(title: "Active subscriptions", icon: "repeat.circle.fill") {
                                searchQuery = "active"
                            }
                            QuickSearchButton(title: "This month's transactions", icon: "calendar") {
                                searchQuery = "this month"
                            }
                            QuickSearchButton(title: "Shared subscriptions", icon: "person.2.fill") {
                                searchQuery = "shared"
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
                }
            }
        }
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Show results grouped by type
                ForEach(SearchResultType.allCases, id: \.self) { type in
                    if let results = groupedResults[type], !results.isEmpty {
                        Section {
                            VStack(spacing: 0) {
                                ForEach(results) { result in
                                    SearchSuggestionRow(result: result) {
                                        handleResultTap(result)
                                    }

                                    if result.id != results.last?.id {
                                        Divider()
                                            .padding(.leading, 68)
                                    }
                                }
                            }

                            // Category filter suggestion
                            if results.count >= 3 && selectedCategory == nil {
                                Button {
                                    selectedCategory = type.rawValue
                                    filterByCategory(type)
                                } label: {
                                    HStack {
                                        Image(systemName: "line.3.horizontal.decrease")
                                            .font(.system(size: 12))
                                        Text("Show only \(type.rawValue)")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.wiseBrightGreen)
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 16)
                            }
                        } header: {
                            SearchCategoryHeader(type: type, count: results.count)
                        }
                    }
                }

                // Results summary
                Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Searching...")
                .font(.system(size: 15))
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Search Logic

    private func performSearch() {
        // Cancel previous search
        searchTask?.cancel()

        // Clear results if query is empty
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            groupedResults = [:]
            isSearching = false
            return
        }

        // Debounce search
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay

            guard !Task.isCancelled else { return }

            await performSearchTask()
        }
    }

    @MainActor
    private func performSearchTask() async {
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var results: [SearchResult] = []

        // Search people
        if searchFilters.resultTypes.contains(.person) {
            let peopleResults = searchPeople(query: query)
            results.append(contentsOf: peopleResults)
        }

        // Search subscriptions
        if searchFilters.resultTypes.contains(.subscription) {
            let subscriptionResults = searchSubscriptions(query: query)
            results.append(contentsOf: subscriptionResults)
        }

        // Search transactions
        if searchFilters.resultTypes.contains(.transaction) {
            let transactionResults = searchTransactions(query: query)
            results.append(contentsOf: transactionResults)
        }

        // Apply filters
        results = applyFilters(to: results)

        // Filter by selected category if any
        if let category = selectedCategory {
            results = results.filter { $0.type.rawValue == category }
        }

        // Update results
        searchResults = results
        groupResults()
        sortResults()

        // Add to history
        searchHistory.addSearch(searchQuery, resultCount: results.count)

        isSearching = false
    }

    private func searchPeople(query: String) -> [SearchResult] {
        return dataManager.people.compactMap { person in
            let nameMatch = person.name.lowercased().contains(query)
            let emailMatch = person.email.lowercased().contains(query)
            let phoneMatch = person.phone.contains(query)

            guard nameMatch || emailMatch || phoneMatch else { return nil }

            let score = calculateMatchScore(
                text: person.name + person.email + person.phone,
                query: query
            )

            return SearchResult(
                id: person.id,
                type: .person,
                title: person.name,
                subtitle: person.email,
                metadata: person.balance.asCurrency,
                icon: "person.circle.fill",
                color: "#007AFF",
                matchScore: score
            )
        }
    }

    private func searchSubscriptions(query: String) -> [SearchResult] {
        return dataManager.subscriptions.compactMap { subscription in
            let nameMatch = subscription.name.lowercased().contains(query)
            let categoryMatch = subscription.category.rawValue.lowercased().contains(query)
            let descriptionMatch = subscription.description.lowercased().contains(query)

            guard nameMatch || categoryMatch || descriptionMatch else { return nil }

            let score = calculateMatchScore(
                text: subscription.name + subscription.category.rawValue + subscription.description,
                query: query
            )

            return SearchResult(
                id: subscription.id,
                type: .subscription,
                title: subscription.name,
                subtitle: subscription.category.rawValue,
                metadata: "\(subscription.price.asCurrency)/\(subscription.billingCycle.shortName)",
                icon: subscription.icon,
                color: subscription.color,
                matchScore: score
            )
        }
    }

    private func searchTransactions(query: String) -> [SearchResult] {
        return dataManager.transactions.compactMap { transaction in
            let titleMatch = transaction.title.lowercased().contains(query)
            let subtitleMatch = transaction.subtitle.lowercased().contains(query)
            let categoryMatch = transaction.category.rawValue.lowercased().contains(query)
            let tagsMatch = transaction.tags.contains { $0.lowercased().contains(query) }

            guard titleMatch || subtitleMatch || categoryMatch || tagsMatch else { return nil }

            let score = calculateMatchScore(
                text: transaction.title + transaction.subtitle + transaction.category.rawValue,
                query: query
            )

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let dateStr = formatter.string(from: transaction.date)

            return SearchResult(
                id: transaction.id,
                type: .transaction,
                title: transaction.title,
                subtitle: transaction.subtitle,
                metadata: dateStr,
                icon: transaction.category.icon,
                color: "#FF9800",
                matchScore: score
            )
        }
    }

    private func applyFilters(to results: [SearchResult]) -> [SearchResult] {
        return results.filter { result in
            // Category filter
            if !searchFilters.selectedCategories.isEmpty {
                guard searchFilters.selectedCategories.contains(result.subtitle) else { return false }
            }

            // Date range filter (for transactions)
            if let startDate = searchFilters.startDate, let endDate = searchFilters.endDate {
                if result.type == .transaction {
                    if let transaction = dataManager.transactions.first(where: { $0.id == result.id }) {
                        guard transaction.date >= startDate && transaction.date <= endDate else { return false }
                    }
                }
            }

            // Amount range filter
            if let minAmount = searchFilters.minAmount {
                if result.type == .subscription {
                    if let subscription = dataManager.subscriptions.first(where: { $0.id == result.id }) {
                        guard subscription.price >= minAmount else { return false }
                    }
                } else if result.type == .transaction {
                    if let transaction = dataManager.transactions.first(where: { $0.id == result.id }) {
                        guard abs(transaction.amount) >= minAmount else { return false }
                    }
                }
            }

            if let maxAmount = searchFilters.maxAmount {
                if result.type == .subscription {
                    if let subscription = dataManager.subscriptions.first(where: { $0.id == result.id }) {
                        guard subscription.price <= maxAmount else { return false }
                    }
                } else if result.type == .transaction {
                    if let transaction = dataManager.transactions.first(where: { $0.id == result.id }) {
                        guard abs(transaction.amount) <= maxAmount else { return false }
                    }
                }
            }

            // Status filter (for subscriptions)
            if !searchFilters.statusFilters.isEmpty && result.type == .subscription {
                if let subscription = dataManager.subscriptions.first(where: { $0.id == result.id }) {
                    let status = subscription.isActive ? "active" : (subscription.cancellationDate != nil ? "cancelled" : "paused")
                    guard searchFilters.statusFilters.contains(status) else { return false }
                }
            }

            // Tags filter (for transactions)
            if !searchFilters.selectedTags.isEmpty && result.type == .transaction {
                if let transaction = dataManager.transactions.first(where: { $0.id == result.id }) {
                    guard !Set(transaction.tags).isDisjoint(with: searchFilters.selectedTags) else { return false }
                }
            }

            // Payment method filter
            if !searchFilters.paymentMethods.isEmpty && result.type == .subscription {
                if let subscription = dataManager.subscriptions.first(where: { $0.id == result.id }) {
                    guard searchFilters.paymentMethods.contains(subscription.paymentMethod.rawValue) else { return false }
                }
            }

            return true
        }
    }

    private func calculateMatchScore(text: String, query: String) -> Double {
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()

        // Exact match
        if lowerText == lowerQuery {
            return 1.0
        }

        // Starts with query
        if lowerText.hasPrefix(lowerQuery) {
            return 0.9
        }

        // Contains query at word boundary
        if lowerText.contains(" " + lowerQuery) {
            return 0.7
        }

        // Contains query anywhere
        if lowerText.contains(lowerQuery) {
            return 0.5
        }

        // Fuzzy match (contains all characters in order)
        var lastIndex = lowerText.startIndex
        var matchCount = 0
        for char in lowerQuery {
            if let index = lowerText[lastIndex...].firstIndex(of: char) {
                matchCount += 1
                lastIndex = lowerText.index(after: index)
            }
        }

        return Double(matchCount) / Double(lowerQuery.count) * 0.3
    }

    private func groupResults() {
        groupedResults = Dictionary(grouping: searchResults, by: { $0.type })
    }

    private func sortResults() {
        switch sortOption {
        case .relevance:
            searchResults.sort { $0.matchScore > $1.matchScore }
        case .date:
            searchResults.sort { result1, result2 in
                if result1.type == .transaction, let t1 = dataManager.transactions.first(where: { $0.id == result1.id }),
                   result2.type == .transaction, let t2 = dataManager.transactions.first(where: { $0.id == result2.id }) {
                    return t1.date > t2.date
                }
                return false
            }
        case .amount:
            searchResults.sort { result1, result2 in
                let amount1 = getAmount(for: result1)
                let amount2 = getAmount(for: result2)
                return amount1 > amount2
            }
        case .nameAZ:
            searchResults.sort { $0.title < $1.title }
        }

        groupResults()
    }

    private func getAmount(for result: SearchResult) -> Double {
        switch result.type {
        case .subscription:
            return dataManager.subscriptions.first(where: { $0.id == result.id })?.price ?? 0
        case .transaction:
            return abs(dataManager.transactions.first(where: { $0.id == result.id })?.amount ?? 0)
        case .person:
            return abs(dataManager.people.first(where: { $0.id == result.id })?.balance ?? 0)
        }
    }

    private func filterByCategory(_ type: SearchResultType) {
        selectedCategory = type.rawValue
        searchResults = searchResults.filter { $0.type == type }
        groupResults()
    }

    private func clearSearch() {
        searchQuery = ""
        selectedCategory = nil
        searchResults = []
        groupedResults = [:]
    }

    private func handleResultTap(_ result: SearchResult) {
        // TODO: Navigate to detail view based on result type
        // For now, just print the selection
        print("Tapped result: \(result.title) (\(result.type.rawValue))")
    }
}

// MARK: - Quick Search Button

struct QuickSearchButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.wiseBrightGreen)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wiseBorder.opacity(0.3))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Search - Default") {
    SearchView()
        .environmentObject(DataManager.shared)
}

#Preview("Search - Dark Mode") {
    SearchView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
