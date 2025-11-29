//
//  UnifiedSectionHeader.swift
//  Swiff IOS
//
//  Created for Unified List Design System
//  Provides consistent date-based section headers (primarily for Transactions)
//

import SwiftUI

// MARK: - Unified Section Header

/// A consistent section header for date-based grouping.
/// Primarily used for the Transactions view to group items by date.
/// Other views (People, Groups, Subscriptions) do NOT use section headers.
struct UnifiedSectionHeader: View {
    let title: String           // e.g., "TODAY, NOV 27"
    var count: Int? = nil       // Item count
    var countLabel: String = "items"

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.wisePrimaryText)
                .tracking(0.5)

            Spacer()

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
        .padding(.vertical, 10)
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

#Preview("Section Headers") {
    VStack(spacing: 0) {
        Text("UnifiedSectionHeader Examples")
            .font(.headline)
            .padding()

        UnifiedSectionHeader(
            title: "TODAY, NOV 27",
            count: 3,
            countLabel: "transactions"
        )

        // Sample rows placeholder
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.wiseCardBackground)
            .frame(height: 70)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.wiseCardBackground)
            .frame(height: 70)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

        UnifiedSectionHeader(
            title: "YESTERDAY, NOV 26",
            count: 5,
            countLabel: "transactions"
        )

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.wiseCardBackground)
            .frame(height: 70)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

        UnifiedSectionHeader(
            title: "MON, NOV 25",
            count: 2,
            countLabel: "items"
        )

        RoundedRectangle(cornerRadius: 12)
            .fill(Color.wiseCardBackground)
            .frame(height: 70)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

        Spacer()
    }
    .background(Color.wiseBackground)
}
