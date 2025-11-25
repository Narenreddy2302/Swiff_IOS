//
//  SearchSuggestionRow.swift
//  Swiff IOS
//
//  Created by Agent 12 on 11/21/25.
//  Search suggestion and autocomplete row component
//

import SwiftUI

// MARK: - Search Suggestion Row

struct SearchSuggestionRow: View {
    let result: SearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(Color(hex: result.color).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: result.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: result.color))
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        if !result.metadata.isEmpty {
                            Text(result.metadata)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(result.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Type badge
                Text(result.type.rawValue.dropLast()) // Remove 's' from plural
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search History Row

struct SearchHistoryRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // History icon
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                // Query text
                Text(item.query)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Spacer()

                // Result count
                if item.resultCount > 0 {
                    Text("\(item.resultCount)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Category Header

struct SearchCategoryHeader: View {
    let type: SearchResultType
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Text(type.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Text("(\(count))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Empty Search State

struct EmptySearchState: View {
    let query: String
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(.gray.opacity(0.5))
            }

            // Message
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("We couldn't find anything matching '\(query)'")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Search Tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Search Tips:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    SearchTipRow(text: "Check your spelling")
                    SearchTipRow(text: "Try different keywords")
                    SearchTipRow(text: "Use broader search terms")
                    SearchTipRow(text: "Try searching by amount or date")
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 32)

            // Clear button
            Button(action: onClear) {
                Text("Clear Search")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.wiseBrightGreen)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

struct SearchTipRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.wiseBrightGreen)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Color Extension for Hex Support
// Note: Color hex init is defined in SupportingTypes.swift or ColorExtensions.swift
