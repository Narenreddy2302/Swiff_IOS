//
//  UnifiedTimelineView.swift
//  Swiff IOS
//
//  Created by Claude Code on 12/20/25.
//  Main container for timeline content with date grouping and optional status banner
//

import SwiftUI

struct UnifiedTimelineView<Item: TimelineItemProtocol, ItemContent: View>: View {
    let groupedItems: [(Date, [Item])]
    let statusBanner: StatusBannerConfig?
    let emptyStateConfig: TimelineEmptyStateConfig
    @ViewBuilder let itemContent: (Item, Bool) -> ItemContent

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Status banner (if applicable)
                if let banner = statusBanner, !banner.isEmpty {
                    StatusBannerView(config: banner)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                // Timeline content
                if groupedItems.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    ForEach(Array(groupedItems.enumerated()), id: \.offset) { groupIndex, group in
                        VStack(spacing: 0) {
                            // Date header
                            TimelineDateHeader(date: group.0)
                                .padding(.vertical, 12)

                            // Items
                            let items = group.1
                            ForEach(Array(items.enumerated()), id: \.element.id) { itemIndex, item in
                                let isLastInGroup = itemIndex == items.count - 1
                                let isLastOverall = groupIndex == groupedItems.count - 1 && isLastInGroup

                                TimelineItemView(
                                    iconType: item.timelineIconType,
                                    isLast: isLastOverall
                                ) {
                                    itemContent(item, isLastInGroup)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100) // Space for input area
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateConfig.icon)
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText)

            Text(emptyStateConfig.title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)

            Text(emptyStateConfig.subtitle)
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseTertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    // Mock data for preview
    struct MockTimelineItem: TimelineItemProtocol {
        let id: UUID
        let timestamp: Date
        let timelineIconType: TimelineIconType
        let title: String
    }

    let mockItems: [(Date, [MockTimelineItem])] = [
        (Date(), [
            MockTimelineItem(
                id: UUID(),
                timestamp: Date(),
                timelineIconType: .expense,
                title: "Lunch at Chipotle"
            ),
            MockTimelineItem(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-3600),
                timelineIconType: .payment,
                title: "Payment received"
            )
        ]),
        (Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), [
            MockTimelineItem(
                id: UUID(),
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                timelineIconType: .request,
                title: "Split bill request"
            )
        ])
    ]

    return UnifiedTimelineView(
        groupedItems: mockItems,
        statusBanner: StatusBannerConfig(
            pendingCount: 2,
            totalAmount: 50.50,
            isUserOwing: true
        ),
        emptyStateConfig: TimelineEmptyStateConfig(
            icon: "tray.fill",
            title: "No transactions yet",
            subtitle: "Record a payment to get started"
        )
    ) { item, isLast in
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            Text("Sample transaction details")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }
    .background(Color.wiseBackground)
}

// MARK: - Empty State Preview

#Preview("Empty State") {
    struct MockTimelineItem: TimelineItemProtocol {
        let id: UUID
        let timestamp: Date
        let timelineIconType: TimelineIconType
    }

    return UnifiedTimelineView(
        groupedItems: [(Date, [MockTimelineItem])](),
        statusBanner: nil,
        emptyStateConfig: TimelineEmptyStateConfig(
            icon: "tray.fill",
            title: "No transactions yet",
            subtitle: "Record a payment to get started"
        )
    ) { item, isLast in
        EmptyView()
    }
    .background(Color.wiseBackground)
}
