//
//  FeedEmptyStates.swift
//  Swiff IOS
//
//  Empty state variants for the Feed page
//  Matches reference design with minimal styling
//

import SwiftUI

// MARK: - No Transactions State

/// Empty state when user has no transactions at all
struct FeedNoTransactionsState: View {
    let onAddTransaction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.feedSecondaryText.opacity(0.5))

            Text("No transactions yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.feedSecondaryText)

            Button(action: {
                HapticManager.shared.medium()
                onAddTransaction()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Transaction")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.Colors.brandPrimary)
                .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - No Results State (Filtered)

/// Empty state when filters return no results
struct FeedNoResultsState: View {
    let filterTab: FeedFilterTab
    var searchText: String = ""
    let onClearFilters: () -> Void

    private var iconName: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }

        switch filterTab {
        case .all: return "tray"
        case .income: return "arrow.down.left.circle"
        case .sent: return "arrow.up.right.circle"
        case .request: return "clock.arrow.circlepath"
        case .transfer: return "arrow.left.arrow.right.circle"
        }
    }

    private var title: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }

        switch filterTab {
        case .all: return "No transactions"
        case .income: return "No income transactions"
        case .sent: return "No sent transactions"
        case .request: return "No request transactions"
        case .transfer: return "No transfer transactions"
        }
    }

    private var subtitle: String? {
        if !searchText.isEmpty {
            return "No transactions match \"\(searchText)\""
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.feedSecondaryText.opacity(0.5))

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.feedSecondaryText)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Colors.feedSecondaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if filterTab != .all || !searchText.isEmpty {
                Button(action: {
                    HapticManager.shared.light()
                    onClearFilters()
                }) {
                    Text("View All Transactions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Previews
// Note: FeedLoadingState is defined in FeedLoadingState.swift

#Preview("No Transactions") {
    FeedNoTransactionsState(onAddTransaction: {})
        .background(Color.white)
}

#Preview("No Income Results") {
    FeedNoResultsState(filterTab: .income, onClearFilters: {})
        .background(Color.white)
}

#Preview("No Sent Results") {
    FeedNoResultsState(filterTab: .sent, onClearFilters: {})
        .background(Color.white)
}

#Preview("Search No Results") {
    FeedNoResultsState(
        filterTab: .all,
        searchText: "Netflix",
        onClearFilters: {}
    )
    .background(Color.white)
}

#Preview("Loading State") {
    FeedLoadingState()
        .background(Color.white)
}
