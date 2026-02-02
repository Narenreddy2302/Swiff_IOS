//
//  ChatTimelineView.swift
//  Swiff IOS
//
//  iMessage-style timeline view with message grouping
//  Features: Date headers, variable spacing, grouped messages support
//

import SwiftUI

// MARK: - Message Grouping Info

/// Information about an item's position in a message group
struct MessageGroupInfo {
    let isFirstInGroup: Bool
    let isLastInGroup: Bool
    // showTail removed as part of professional redesign

    static let standalone = MessageGroupInfo(
        isFirstInGroup: true, isLastInGroup: true)
}

// MARK: - Chat Timeline View

struct ChatTimelineView<Item: TimelineItemProtocol, ItemContent: View>: View {
    let groupedItems: [(Date, [Item])]
    let emptyStateConfig: TimelineEmptyStateConfig?
    let getItemDirection: (Item) -> ChatBubbleDirection  // Closure to determine item direction
    @ViewBuilder let itemContent: (Item, MessageGroupInfo) -> ItemContent

    // Spacing configuration
    private let spacingBetweenGroups: CGFloat = 16  // More breathing room between different senders
    private let spacingWithinGroup: CGFloat = 2  // Tighter for same sender

    // MARK: - Initializer (with direction closure)

    init(
        groupedItems: [(Date, [Item])],
        emptyStateConfig: TimelineEmptyStateConfig?,
        getItemDirection: @escaping (Item) -> ChatBubbleDirection,
        @ViewBuilder itemContent: @escaping (Item, MessageGroupInfo) -> ItemContent
    ) {
        self.groupedItems = groupedItems
        self.emptyStateConfig = emptyStateConfig
        self.getItemDirection = getItemDirection
        self.itemContent = itemContent
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if groupedItems.isEmpty, let emptyConfig = emptyStateConfig {
                        emptyStateView(config: emptyConfig)
                            .padding(.top, 60)
                    } else {
                        ForEach(Array(groupedItems.enumerated()), id: \.offset) {
                            groupIndex, group in
                            VStack(spacing: 0) {
                                // Date header
                                ChatDateHeader(date: group.0)
                                    .padding(.vertical, 24)

                                // Items with grouping logic
                                ForEach(Array(group.1.enumerated()), id: \.element.id) {
                                    itemIndex, item in
                                    let groupInfo = messageGroupInfo(
                                        for: item,
                                        at: itemIndex,
                                        in: group.1
                                    )

                                    itemContent(item, groupInfo)
                                        .id(item.id)
                                        .padding(.top, topSpacing(for: itemIndex, in: group.1))
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: groupedItems.count) {
                withAnimation {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    // MARK: - Grouping Logic

    /// Determine message group information for an item
    private func messageGroupInfo(for item: Item, at index: Int, in items: [Item])
        -> MessageGroupInfo
    {
        let currentDirection = getItemDirection(item)
        let isFirst = isFirstInGroup(at: index, in: items, direction: currentDirection)
        let isLast = isLastInGroup(at: index, in: items, direction: currentDirection)

        return MessageGroupInfo(
            isFirstInGroup: isFirst,
            isLastInGroup: isLast
        )
    }

    /// Check if item is first in its consecutive sender group
    private func isFirstInGroup(at index: Int, in items: [Item], direction: ChatBubbleDirection)
        -> Bool
    {
        guard index > 0 else { return true }
        let prevDirection = getItemDirection(items[index - 1])
        return prevDirection != direction
    }

    /// Check if item is last in its consecutive sender group
    private func isLastInGroup(at index: Int, in items: [Item], direction: ChatBubbleDirection)
        -> Bool
    {
        guard index < items.count - 1 else { return true }
        let nextDirection = getItemDirection(items[index + 1])
        return nextDirection != direction
    }

    /// Calculate top spacing based on grouping
    private func topSpacing(for index: Int, in items: [Item]) -> CGFloat {
        guard index > 0 else { return 0 }

        let prevDirection = getItemDirection(items[index - 1])
        let currentDirection = getItemDirection(items[index])

        // Tighter spacing for same sender, wider for different senders
        return prevDirection == currentDirection ? spacingWithinGroup : spacingBetweenGroups
    }

    // MARK: - Scroll Behavior

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastGroup = groupedItems.last, let lastItem = lastGroup.1.last {
            proxy.scrollTo(lastItem.id, anchor: .bottom)
        }
    }

    // MARK: - Empty State

    private func emptyStateView(config: TimelineEmptyStateConfig) -> some View {
        VStack(spacing: 16) {
            Image(systemName: config.icon)
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText)

            Text(config.title)
                .font(.headline)
                .foregroundColor(.wisePrimaryText)

            Text(config.subtitle)
                .font(.subheadline)
                .foregroundColor(.wiseSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Convenience Initializer (without direction closure - for backwards compatibility)

extension ChatTimelineView {
    /// Convenience initializer for simple use cases without grouping
    init(
        groupedItems: [(Date, [Item])],
        emptyStateConfig: TimelineEmptyStateConfig?,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent
    ) where Item: TimelineItemProtocol {
        self.groupedItems = groupedItems
        self.emptyStateConfig = emptyStateConfig
        self.getItemDirection = { _ in .incoming }  // Default direction
        self.itemContent = { item, _ in itemContent(item) }
    }
}

// MARK: - Chat Date Header

struct ChatDateHeader: View {
    let date: Date

    var body: some View {
        Text(formatDate(date))
            .font(.system(size: 11, weight: .semibold))  // 11pt Semibold for clear legibility at small size
            .foregroundColor(.wiseSecondaryText)  // Theme-aware secondary text color
            .padding(.horizontal, 12)
            .padding(.vertical, 6)  // Slightly more breathing room
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"  // e.g. January 7
            // Add year if not current year
            if calendar.component(.year, from: date) != calendar.component(.year, from: Date()) {
                formatter.dateFormat = "MMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
}
