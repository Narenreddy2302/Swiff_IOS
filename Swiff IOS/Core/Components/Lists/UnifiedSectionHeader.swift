//
//  UnifiedSectionHeader.swift
//  Swiff IOS
//
//  Created for Unified List Design System
//  Provides consistent date-based section headers (primarily for Transactions)
//

import SwiftUI

// MARK: - Section Header Style

/// Determines the format style for section headers
enum SectionHeaderStyle {
    case relative    // "Today", "Yesterday"
    case dayMonth    // "16 January"
    case monthYear   // "January 2018"
}

// MARK: - Unified Section Header

/// A consistent section header for date-based grouping.
/// Primarily used for the Transactions view to group items by date.
/// Other views (People, Groups, Subscriptions) do NOT use section headers.
///
/// **V2 Changes:**
/// - Clean, bold text (no uppercase, no tracking)
/// - NO count badge (cleaner, minimalist design)
/// - Date-based initialization with smart formatting
/// - "Today" / "Yesterday" / "16 January" / "January 2018" formats
struct UnifiedSectionHeader: View {
    private let title: String
    private var count: Int? = nil       // Item count (legacy support)
    private var countLabel: String = "items"

    // MARK: - Initializers

    /// Legacy initializer - text-based (backward compatibility)
    init(title: String, count: Int? = nil, countLabel: String = "items") {
        self.title = title
        self.count = count
        self.countLabel = countLabel
    }

    /// New date-based initializer with automatic formatting
    /// - Parameters:
    ///   - date: The date to display
    ///   - style: The formatting style (relative by default)
    init(date: Date, style: SectionHeaderStyle = .relative) {
        self.title = Self.formatDate(date, style: style)
        self.count = nil
        self.countLabel = "items"
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.spotifyHeadingLarge)  // 20pt, bold
                .foregroundColor(.wisePrimaryText)

            Spacer()

            // Legacy count badge support (not used in V2 design)
            if let count = count {
                Text("\(count) \(count == 1 ? String(countLabel.dropLast()) : countLabel)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Date Formatting

    /// Formats a date according to the specified style
    private static func formatDate(_ date: Date, style: SectionHeaderStyle) -> String {
        let calendar = Calendar.current

        switch style {
        case .relative:
            // Use "Today" or "Yesterday" if applicable, otherwise fall through to dayMonth
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                // For other dates in current year, use day + month format
                let currentYear = calendar.component(.year, from: Date())
                let dateYear = calendar.component(.year, from: date)

                if currentYear == dateYear {
                    // "16 January"
                    return date.formatted(.dateTime.day().month(.wide))
                } else {
                    // "January 2018"
                    return date.formatted(.dateTime.month(.wide).year())
                }
            }

        case .dayMonth:
            // "16 January"
            return date.formatted(.dateTime.day().month(.wide))

        case .monthYear:
            // "January 2018"
            return date.formatted(.dateTime.month(.wide).year())
        }
    }
}

// MARK: - Date Extension for Section Headers

extension Date {
    /// Converts a date to a section header title format.
    /// Examples: "TODAY, NOV 27", "YESTERDAY, NOV 26", "MON, NOV 25"
    func toSectionHeaderTitle() -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "TODAY, \(self.formatted(.dateTime.month(.abbreviated).day()).uppercased())"
        } else if calendar.isDateInYesterday(self) {
            return "YESTERDAY, \(self.formatted(.dateTime.month(.abbreviated).day()).uppercased())"
        } else {
            return self.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased()
        }
    }
}

// MARK: - Preview

#Preview("Section Headers V2 - Date-Based") {
    ScrollView {
        VStack(spacing: 0) {
            Text("UnifiedSectionHeader V2 Examples")
                .font(.headline)
                .padding()

            // Today's section
            UnifiedSectionHeader(date: Date(), style: .relative)

            // Sample transaction rows
            UnifiedListRowV2(
                iconName: "cup.and.saucer.fill",
                iconColor: .orange,
                title: "Starbucks",
                subtitle: "→ Sent – Apple Pay",
                value: "– $6.45",
                valueColor: .wisePrimaryText
            )

            Divider()
                .padding(.leading, 76)

            UnifiedListRowV2(
                iconName: "cart.fill",
                iconColor: .wiseBrightGreen,
                title: "Whole Foods",
                subtitle: "→ Sent – Visa • 3366",
                value: "– $89.20",
                valueColor: .wisePrimaryText
            )

            // Yesterday's section
            UnifiedSectionHeader(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                style: .relative
            )

            UnifiedListRowV2(
                iconName: "fuelpump.fill",
                iconColor: Color(red: 0.647, green: 0.165, blue: 0.165),
                title: "Shell Gas Station",
                subtitle: "→ Sent – Mastercard • 4421",
                value: "– $45.80",
                valueColor: .wisePrimaryText
            )

            Divider()
                .padding(.leading, 76)

            // Older date section (16 January format)
            UnifiedSectionHeader(
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                style: .relative
            )

            UnifiedListRowV2(
                iconName: "dollarsign.circle.fill",
                iconColor: .wiseBrightGreen,
                title: "Salary Payment",
                subtitle: "← Received – Direct Deposit",
                value: "+ $3,500.00",
                valueColor: .wiseBrightGreen
            )

            Divider()
                .padding(.leading, 76)

            // Previous year section (January 2018 format)
            UnifiedSectionHeader(
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                style: .relative
            )

            UnifiedListRowV2(
                iconName: "tv.fill",
                iconColor: .red,
                title: "Netflix",
                subtitle: "→ Sent – Visa • 3366",
                value: "– $15.99",
                valueColor: .wisePrimaryText
            )

            Spacer()
        }
    }
    .background(Color.wiseBackground)
}

#Preview("Section Headers - Legacy Style") {
    VStack(spacing: 0) {
        Text("Legacy Section Header (Backward Compatible)")
            .font(.headline)
            .padding()

        // Legacy text-based header
        UnifiedSectionHeader(
            title: "Custom Header Text",
            count: 3,
            countLabel: "transactions"
        )

        UnifiedListRowV2(
            iconName: "cart.fill",
            iconColor: .orange,
            title: "Amazon",
            subtitle: "→ Sent – Visa • 3366",
            value: "– $125.20",
            valueColor: .wisePrimaryText
        )

        Spacer()
    }
    .background(Color.wiseBackground)
}

#Preview("Section Headers - All Styles") {
    VStack(spacing: 20) {
        Text("Date Formatting Styles")
            .font(.headline)
            .padding()

        VStack(spacing: 8) {
            Text("Relative Style:")
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)

            UnifiedSectionHeader(date: Date(), style: .relative)
        }

        VStack(spacing: 8) {
            Text("Day + Month Style:")
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)

            UnifiedSectionHeader(date: Date(), style: .dayMonth)
        }

        VStack(spacing: 8) {
            Text("Month + Year Style:")
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)

            UnifiedSectionHeader(date: Date(), style: .monthYear)
        }

        Spacer()
    }
    .padding()
    .background(Color.wiseBackground)
}
