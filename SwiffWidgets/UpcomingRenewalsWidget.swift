//
//  UpcomingRenewalsWidget.swift
//  SwiffWidgets
//
//  Created by Agent 10 on 11/21/25.
//  Widget showing upcoming subscription renewals
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct UpcomingRenewalsProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingRenewalsEntry {
        let subscriptions = WidgetDataService.shared.loadUpcomingRenewals()
        return UpcomingRenewalsEntry(date: Date(), subscriptions: Array(subscriptions.prefix(7)))
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingRenewalsEntry) -> Void) {
        let subscriptions = WidgetDataService.shared.loadUpcomingRenewals()
        let entry = UpcomingRenewalsEntry(date: Date(), subscriptions: Array(subscriptions.prefix(7)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingRenewalsEntry>) -> Void) {
        let subscriptions = WidgetDataService.shared.loadUpcomingRenewals()
        let entry = UpcomingRenewalsEntry(date: Date(), subscriptions: Array(subscriptions.prefix(7)))

        // Calculate next update time (midnight tomorrow)
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)

        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct UpcomingRenewalsEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSubscription]
}

// MARK: - Widget Views

struct UpcomingRenewalsWidgetEntryView: View {
    var entry: UpcomingRenewalsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallUpcomingRenewalsView(subscriptions: entry.subscriptions)
        case .systemMedium:
            MediumUpcomingRenewalsView(subscriptions: entry.subscriptions)
        case .systemLarge:
            LargeUpcomingRenewalsView(subscriptions: entry.subscriptions)
        default:
            SmallUpcomingRenewalsView(subscriptions: entry.subscriptions)
        }
    }
}

// MARK: - Small Widget (2x2)

struct SmallUpcomingRenewalsView: View {
    let subscriptions: [WidgetSubscription]

    var nextSubscription: WidgetSubscription? {
        subscriptions.first
    }

    var body: some View {
        if let subscription = nextSubscription {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: subscription.color).opacity(0.1),
                        Color(hex: subscription.color).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: subscription.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: subscription.color))

                        Spacer()

                        Text(subscription.renewalCountdown)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(subscription.name)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)

                    Text(subscription.formattedPrice)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: subscription.color))

                    Text(subscription.category)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(16)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))

                Text("All Set!")
                    .font(.system(size: 14, weight: .semibold))

                Text("No renewals soon")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Medium Widget (4x2)

struct MediumUpcomingRenewalsView: View {
    let subscriptions: [WidgetSubscription]

    var upcomingSubscriptions: [WidgetSubscription] {
        Array(subscriptions.prefix(3))
    }

    var totalAmount: Double {
        upcomingSubscriptions.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Next Renewals")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(totalAmount.asCurrencyString)
                    .font(.system(size: 28, weight: .bold))

                Text("\(upcomingSubscriptions.count) upcoming")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(spacing: 0) {
                ForEach(upcomingSubscriptions) { subscription in
                    HStack(spacing: 8) {
                        Image(systemName: subscription.icon)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: subscription.color))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(subscription.name)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)

                            Text(subscription.renewalCountdown)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(subscription.formattedPrice)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: subscription.color))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)

                    if subscription.id != upcomingSubscriptions.last?.id {
                        Divider()
                            .padding(.leading, 40)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Large Widget (4x4)

struct LargeUpcomingRenewalsView: View {
    let subscriptions: [WidgetSubscription]

    var upcomingSubscriptions: [WidgetSubscription] {
        Array(subscriptions.prefix(7))
    }

    var totalMonthly: Double {
        upcomingSubscriptions.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upcoming Renewals")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Total: \(totalMonthly.asCurrencyString)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.0, green: 0.725, blue: 1.0))
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(upcomingSubscriptions) { subscription in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: subscription.color).opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: subscription.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: subscription.color))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(subscription.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    Text(subscription.renewalCountdown)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Text("•")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 9))

                                    Text(subscription.category)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Text(subscription.formattedPrice)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: subscription.color))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if subscription.id != upcomingSubscriptions.last?.id {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
            }

            if upcomingSubscriptions.count < subscriptions.count {
                Divider()

                Link(destination: WidgetConfiguration.deepLinkURL(for: WidgetConfiguration.viewSubscriptionsAction)!) {
                    HStack {
                        Text("View All Subscriptions")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.0, green: 0.725, blue: 1.0))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.0, green: 0.725, blue: 1.0))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct UpcomingRenewalsWidget: Widget {
    let kind: String = WidgetConfiguration.upcomingRenewalsWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingRenewalsProvider()) { entry in
            UpcomingRenewalsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Renewals")
        .description("See your next subscription renewals and upcoming bills.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
