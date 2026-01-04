//
//  RecentActivityView.swift
//  Swiff IOS
//
//  Redesigned Feed Page - Minimal, clean layout matching reference
//
//  Architecture:
//  ├── FeedHeader: Title + Search + Add buttons
//  ├── FeedFilterBar: 5 capsule filter tabs (All, Income, Sent, Request, Transfer)
//  ├── TransactionList: LazyVStack with date-grouped sections
//  └── EmptyStates: Contextual empty states for each filter
//

import SwiftData
import SwiftUI

// MARK: - Recent Activity View

struct RecentActivityView: View {
    @EnvironmentObject var dataManager: DataManager

    // MARK: - State

    @State private var selectedTab: FeedFilterTab = .all
    @State private var searchText = ""
    @State private var showingSearchBar = false
    @State private var showingAddSheet = false
    @State private var transactionToDelete: Transaction?
    @State private var showingDeleteAlert = false
    @State private var isLoading = false

    // MARK: - Computed Properties

    /// Filtered transactions based on selected tab and search
    private var filteredTransactions: [Transaction] {
        var result = dataManager.transactions

        // Apply tab filter
        result = result.filtered(by: selectedTab)

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText)
                    || transaction.subtitle.localizedCaseInsensitiveContains(searchText)
                    || (transaction.merchant?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    /// Grouped sections for display
    private var groupedSections: [FeedDateSection] {
        filteredTransactions.groupedByFeedSections()
    }

    /// Check if there are any transactions at all
    private var hasTransactions: Bool {
        !dataManager.transactions.isEmpty
    }

    /// Check if filtered results are empty
    private var hasFilteredResults: Bool {
        !filteredTransactions.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with title and action buttons
                feedHeader

                // Search bar (expandable)
                if showingSearchBar {
                    searchBar
                }

                // Filter tabs
                FeedFilterBar(selectedTab: $selectedTab) { _ in
                    HapticManager.shared.light()
                }
                .padding(.top, 8)

                // Main content
                mainContent
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddSheet,
                onTransactionAdded: handleNewTransaction
            )
        }
        .alert(
            "Delete Transaction?",
            isPresented: $showingDeleteAlert,
            presenting: transactionToDelete
        ) { transaction in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTransaction(transaction)
            }
        } message: { transaction in
            Text("This will permanently delete this transaction.")
        }
    }

    // MARK: - Header

    private var feedHeader: some View {
        HStack {
            Text("Feed")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Theme.Colors.feedPrimaryText)

            Spacer()

            HStack(spacing: 16) {
                // Search button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSearchBar.toggle()
                        if !showingSearchBar {
                            searchText = ""
                        }
                    }
                    HapticManager.shared.light()
                }) {
                    Image(systemName: showingSearchBar ? "xmark" : "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                }

                // Add button
                Button(action: {
                    showingAddSheet = true
                    HapticManager.shared.medium()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.feedSecondaryText)

            TextField("Search transactions...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.feedPrimaryText)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            loadingView
        } else if !hasTransactions {
            noTransactionsView
        } else if !hasFilteredResults {
            noResultsView
        } else {
            transactionListView
        }
    }

    // MARK: - Transaction List

    private var transactionListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(groupedSections) { section in
                    Section {
                        ForEach(Array(section.transactions.enumerated()), id: \.element.id) { index, transaction in
                            VStack(spacing: 0) {
                                NavigationLink(
                                    destination: TransactionDetailView(transactionId: transaction.id)
                                ) {
                                    FeedTransactionRow(transaction: transaction)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 16)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // Divider between transactions (not after last)
                                if index < section.transactions.count - 1 {
                                    FeedRowDivider()
                                }
                            }
                        }
                    } header: {
                        FeedSectionHeader(title: section.title)
                    }
                }

                // Bottom padding for tab bar
                Color.clear.frame(height: 100)
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await refreshData()
        }
    }

    // MARK: - Empty States

    private var noTransactionsView: some View {
        FeedNoTransactionsState(onAddTransaction: {
            showingAddSheet = true
        })
    }

    private var noResultsView: some View {
        FeedNoResultsState(
            filterTab: selectedTab,
            searchText: searchText,
            onClearFilters: {
                withAnimation {
                    selectedTab = .all
                    searchText = ""
                    showingSearchBar = false
                }
                HapticManager.shared.light()
            }
        )
    }

    private var loadingView: some View {
        FeedLoadingState()
    }

    // MARK: - Actions

    private func handleNewTransaction(_ transaction: Transaction) {
        do {
            try dataManager.addTransaction(transaction)
            HapticManager.shared.success()
            ToastManager.shared.showSuccess("Transaction added")
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        do {
            try dataManager.deleteTransaction(id: transaction.id)
            HapticManager.shared.success()
            ToastManager.shared.showSuccess("Transaction deleted")
        } catch {
            dataManager.error = error
            HapticManager.shared.error()
        }
    }

    private func refreshData() async {
        HapticManager.shared.pullToRefresh()
        try? await Task.sleep(nanoseconds: 500_000_000)
        dataManager.loadAllData()
        ToastManager.shared.showSuccess("Updated")
    }
}

// MARK: - Preview

#Preview("RecentActivityView - With Transactions") {
    RecentActivityView()
        .environmentObject(DataManager.shared)
}

#Preview("RecentActivityView - Empty State") {
    RecentActivityView()
        .environmentObject(DataManager.shared)
}
