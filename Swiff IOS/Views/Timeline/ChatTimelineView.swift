//
//  ChatTimelineView.swift
//  Swiff IOS
//
//  Created for SWIFF iOS "iMessage Style" Redesign
//  Timeline view that mimics a chat interface
//

import SwiftUI

struct ChatTimelineView<Item: TimelineItemProtocol, ItemContent: View>: View {
    let groupedItems: [(Date, [Item])]
    let emptyStateConfig: TimelineEmptyStateConfig?
    @ViewBuilder let itemContent: (Item) -> ItemContent

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if groupedItems.isEmpty, let emptyConfig = emptyStateConfig {
                        emptyStateView(config: emptyConfig)
                            .padding(.top, 60)
                    } else {
                        ForEach(Array(groupedItems.enumerated()), id: \.offset) { groupIndex, group in
                            VStack(spacing: 0) {
                                // Date header (Sticky-like appearance)
                                ChatDateHeader(date: group.0)
                                    .padding(.vertical, 16)
                                
                                // Items
                                ForEach(Array(group.1.enumerated()), id: \.element.id) { itemIndex, item in
                                    itemContent(item)
                                        .id(item.id)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .onAppear {
                // Scroll to bottom on load if items exist
                if let lastGroup = groupedItems.last, let lastItem = lastGroup.1.last {
                    proxy.scrollTo(lastItem.id, anchor: .bottom)
                }
            }
            .onChange(of: groupedItems.count) { _ in
                 if let lastGroup = groupedItems.last, let lastItem = lastGroup.1.last {
                     withAnimation {
                         proxy.scrollTo(lastItem.id, anchor: .bottom)
                     }
                 }
            }
        }
    }
    
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
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChatDateHeader: View {
    let date: Date
    
    var body: some View {
        Text(formatDate(date))
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.wiseSecondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d" // e.g. January 7
            // Optional: Add year if not current year
            if calendar.component(.year, from: date) != calendar.component(.year, from: Date()) {
                formatter.dateFormat = "MMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
}
