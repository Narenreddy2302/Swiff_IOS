//
//  QuickActionsWidget.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Widget providing quick action buttons with deep linking
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct QuickActionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionsEntry {
        QuickActionsEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionsEntry) -> Void) {
        let entry = QuickActionsEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsEntry>) -> Void) {
        let entry = QuickActionsEntry(date: Date())

        // Quick actions don't need frequent updates
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date())!

        let timeline = Timeline(entries: [entry], policy: .after(nextWeek))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct QuickActionsEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View

struct QuickActionsWidgetEntryView: View {
    var entry: QuickActionsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumQuickActionsView()
        default:
            MediumQuickActionsView()
        }
    }
}

// MARK: - Medium Widget (4x2) - Grid of Actions

struct MediumQuickActionsView: View {
    let actions = [
        QuickAction(
            title: "Add Transaction",
            icon: "plus.circle.fill",
            color: "#007AFF",
            deepLink: "swiff://action/add-transaction"
        ),
        QuickAction(
            title: "Add Subscription",
            icon: "calendar.badge.plus",
            color: "#34C759",
            deepLink: "swiff://action/add-subscription"
        ),
        QuickAction(
            title: "Subscriptions",
            icon: "creditcard.fill",
            color: "#FF9500",
            deepLink: "swiff://action/view-subscriptions"
        ),
        QuickAction(
            title: "Analytics",
            icon: "chart.bar.fill",
            color: "#AF52DE",
            deepLink: "swiff://action/view-analytics"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                QuickActionButton(action: actions[0])
                Divider()
                QuickActionButton(action: actions[1])
            }

            Divider()

            HStack(spacing: 0) {
                QuickActionButton(action: actions[2])
                Divider()
                QuickActionButton(action: actions[3])
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let action: QuickAction

    var body: some View {
        Link(destination: URL(string: action.deepLink)!) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: action.color))

                Text(action.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Quick Action Model

struct QuickAction {
    let title: String
    let icon: String
    let color: String
    let deepLink: String
}

// MARK: - Widget Configuration

struct QuickActionsWidget: Widget {
    let kind: String = WidgetConfiguration.quickActionsWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsProvider()) { entry in
            QuickActionsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quickly access common actions like adding transactions or viewing analytics.")
        .supportedFamilies([.systemMedium])
    }
}
