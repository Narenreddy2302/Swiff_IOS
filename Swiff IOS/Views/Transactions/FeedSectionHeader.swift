//
//  FeedSectionHeader.swift
//  Swiff IOS
//
//  Minimal section header matching reference design
//  Format: "TODAY" + horizontal line
//

import SwiftUI

// MARK: - Feed Section Header

struct FeedSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.feedSecondaryText)
                .textCase(.uppercase)
                .tracking(0.3)

            Rectangle()
                .fill(Theme.Colors.feedDivider)
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 2)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Preview

#Preview("FeedSectionHeader - Today") {
    VStack(spacing: 20) {
        FeedSectionHeader(title: "TODAY")
        FeedSectionHeader(title: "YESTERDAY")
        FeedSectionHeader(title: "THIS WEEK")
        FeedSectionHeader(title: "LAST WEEK")
        FeedSectionHeader(title: "OLDER")
        Spacer()
    }
    .background(Color.white)
}
