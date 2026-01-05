//
//  FeedHeader.swift
//  Swiff IOS
//
//  Feed page header with title, spending summary, and action buttons
//

import SwiftUI

struct FeedHeader: View {
    @Binding var searchText: String
    @Binding var showingSearchBar: Bool
    @Binding var showingAddSheet: Bool
    @Binding var showingAdvancedFilterSheet: Bool
    let monthlySpending: Double
    let activeFilterCount: Int

    var body: some View {
        VStack(spacing: 16) {
            // Main header row (matching People and Subscriptions design)
            HStack {
                Text("Feed")
                    .font(Theme.Fonts.displayLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                // Action buttons (matching other pages)
                HStack(spacing: 16) {
                    // Search button
                    Button(action: {
                        HapticManager.shared.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSearchBar.toggle()
                            if !showingSearchBar {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(showingSearchBar ? .wiseBrightGreen : .wisePrimaryText)
                    }

                    // Filter button with badge
                    Button(action: {
                        HapticManager.shared.light()
                        showingAdvancedFilterSheet = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 20))
                                .foregroundColor(
                                    activeFilterCount > 0 ? .wiseBrightGreen : .wisePrimaryText
                                )

                            if activeFilterCount > 0 {
                                Circle()
                                    .fill(Color.wiseBrightGreen)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }

                    // Add button using HeaderActionButton component
                    HeaderActionButton(icon: "plus.circle.fill", color: .wiseForestGreen) {
                        HapticManager.shared.light()
                        showingAddSheet = true
                    }
                }
            }
            .padding(.horizontal, 16)

            // Expandable search bar
            if showingSearchBar {
                SearchBarView(searchText: $searchText)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 10)
    }

    private var spendingSummary: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: monthlySpending)) ?? "$0.00"
        return "\(formatted) spent this month"
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.wiseSecondaryText)
                .font(.system(size: 16))

            TextField("Search transactions...", text: $searchText)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    HapticManager.shared.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.wiseSecondaryText)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("FeedHeader") {
    VStack {
        FeedHeader(
            searchText: .constant(""),
            showingSearchBar: .constant(false),
            showingAddSheet: .constant(false),
            showingAdvancedFilterSheet: .constant(false),
            monthlySpending: 2450.32,
            activeFilterCount: 0
        )

        Spacer()
    }
    .background(Color.wiseBackground)
}

#Preview("FeedHeader with Search") {
    VStack {
        FeedHeader(
            searchText: .constant("Coffee"),
            showingSearchBar: .constant(true),
            showingAddSheet: .constant(false),
            showingAdvancedFilterSheet: .constant(false),
            monthlySpending: 1250.00,
            activeFilterCount: 2
        )

        Spacer()
    }
    .background(Color.wiseBackground)
}
