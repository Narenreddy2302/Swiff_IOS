# Widget Development

## Purpose
Guide iOS widget development using WidgetKit, following Apple's best practices and project conventions.

## When to Use This Skill
- Creating new widgets
- Updating widget data
- Implementing widget interactions
- Deep linking from widgets
- Configuring widget refresh

---

## Project Widgets

```
SwiffWidgets/
├── UpcomingRenewalsWidget.swift    # Shows next renewals
├── MonthlySpendingWidget.swift     # Monthly spending overview
├── QuickActionsWidget.swift        # Quick action buttons
├── WidgetDataService.swift         # Shared data access
└── WidgetAppIntents.swift          # iOS 17+ interactions
```

---

## Widget Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Main App                                  │
│              (Writes to App Group)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   App Group Container                        │
│            (group.com.yourcompany.swiff)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Widget Extension                          │
│              (Reads from App Group)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## App Group Configuration

### Entitlements

```xml
<!-- Swiff IOS.entitlements -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourcompany.swiff</string>
</array>

<!-- SwiffWidgets.entitlements -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourcompany.swiff</string>
</array>
```

---

## Widget Data Service

```swift
// SwiffWidgets/WidgetDataService.swift
import Foundation
import WidgetKit

class WidgetDataService {
    static let shared = WidgetDataService()

    private let appGroupID = "group.com.yourcompany.swiff"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Data Models

    struct WidgetSubscription: Codable {
        let id: UUID
        let name: String
        let price: Double
        let nextBillingDate: Date
        let icon: String
        let color: String
    }

    struct WidgetSpending: Codable {
        let month: String
        let amount: Double
        let comparedToLastMonth: Double // Percentage change
    }

    // MARK: - Read Data

    func getUpcomingRenewals(limit: Int = 5) -> [WidgetSubscription] {
        guard let data = sharedDefaults?.data(forKey: "upcomingRenewals"),
              let subscriptions = try? JSONDecoder().decode([WidgetSubscription].self, from: data) else {
            return []
        }
        return Array(subscriptions.prefix(limit))
    }

    func getMonthlySpending() -> WidgetSpending? {
        guard let data = sharedDefaults?.data(forKey: "monthlySpending"),
              let spending = try? JSONDecoder().decode(WidgetSpending.self, from: data) else {
            return nil
        }
        return spending
    }

    func getTotalMonthlySubscriptionCost() -> Double {
        sharedDefaults?.double(forKey: "totalMonthlyCost") ?? 0
    }

    // MARK: - Write Data (Called from main app)

    func saveUpcomingRenewals(_ subscriptions: [WidgetSubscription]) {
        if let data = try? JSONEncoder().encode(subscriptions) {
            sharedDefaults?.set(data, forKey: "upcomingRenewals")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "UpcomingRenewalsWidget")
    }

    func saveMonthlySpending(_ spending: WidgetSpending) {
        if let data = try? JSONEncoder().encode(spending) {
            sharedDefaults?.set(data, forKey: "monthlySpending")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "MonthlySpendingWidget")
    }

    func saveTotalMonthlyCost(_ cost: Double) {
        sharedDefaults?.set(cost, forKey: "totalMonthlyCost")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Refresh Widgets

    func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

---

## Upcoming Renewals Widget

```swift
// SwiffWidgets/UpcomingRenewalsWidget.swift
import WidgetKit
import SwiftUI

struct UpcomingRenewalsEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetDataService.WidgetSubscription]
}

struct UpcomingRenewalsProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingRenewalsEntry {
        UpcomingRenewalsEntry(date: Date(), subscriptions: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingRenewalsEntry) -> Void) {
        let entry = UpcomingRenewalsEntry(
            date: Date(),
            subscriptions: WidgetDataService.shared.getUpcomingRenewals(limit: 3)
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingRenewalsEntry>) -> Void) {
        let subscriptions = WidgetDataService.shared.getUpcomingRenewals(limit: 3)
        let entry = UpcomingRenewalsEntry(date: Date(), subscriptions: subscriptions)

        // Refresh daily at midnight
        let nextUpdate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct UpcomingRenewalsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: UpcomingRenewalsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallRenewalsView(subscriptions: entry.subscriptions)
        case .systemMedium:
            MediumRenewalsView(subscriptions: entry.subscriptions)
        case .systemLarge:
            LargeRenewalsView(subscriptions: entry.subscriptions)
        default:
            SmallRenewalsView(subscriptions: entry.subscriptions)
        }
    }
}

struct SmallRenewalsView: View {
    let subscriptions: [WidgetDataService.WidgetSubscription]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming")
                .font(.caption)
                .foregroundColor(.secondary)

            if let next = subscriptions.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(next.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(next.nextBillingDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(next.price, format: .currency(code: "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            } else {
                Text("No upcoming renewals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "swiff://subscriptions"))
    }
}

struct MediumRenewalsView: View {
    let subscriptions: [WidgetDataService.WidgetSubscription]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Renewals")
                .font(.headline)

            if subscriptions.isEmpty {
                Text("No upcoming renewals this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(subscriptions.prefix(3), id: \.id) { subscription in
                    Link(destination: URL(string: "swiff://subscription/\(subscription.id)")!) {
                        HStack {
                            Image(systemName: subscription.icon)
                                .foregroundColor(Color(hex: subscription.color))

                            Text(subscription.name)
                                .font(.subheadline)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(subscription.price, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(subscription.nextBillingDate, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

@main
struct UpcomingRenewalsWidget: Widget {
    let kind: String = "UpcomingRenewalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingRenewalsProvider()) { entry in
            UpcomingRenewalsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Renewals")
        .description("See your upcoming subscription renewals.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

---

## Monthly Spending Widget

```swift
// SwiffWidgets/MonthlySpendingWidget.swift
import WidgetKit
import SwiftUI

struct MonthlySpendingEntry: TimelineEntry {
    let date: Date
    let spending: WidgetDataService.WidgetSpending?
    let totalSubscriptionCost: Double
}

struct MonthlySpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlySpendingEntry {
        MonthlySpendingEntry(date: Date(), spending: nil, totalSubscriptionCost: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlySpendingEntry) -> Void) {
        let entry = MonthlySpendingEntry(
            date: Date(),
            spending: WidgetDataService.shared.getMonthlySpending(),
            totalSubscriptionCost: WidgetDataService.shared.getTotalMonthlySubscriptionCost()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlySpendingEntry>) -> Void) {
        let entry = MonthlySpendingEntry(
            date: Date(),
            spending: WidgetDataService.shared.getMonthlySpending(),
            totalSubscriptionCost: WidgetDataService.shared.getTotalMonthlySubscriptionCost()
        )

        // Refresh hourly
        let nextUpdate = Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct MonthlySpendingWidgetView: View {
    let entry: MonthlySpendingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Cost")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(entry.totalSubscriptionCost, format: .currency(code: "USD"))
                .font(.title)
                .fontWeight(.bold)

            if let spending = entry.spending {
                HStack(spacing: 4) {
                    Image(systemName: spending.comparedToLastMonth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(spending.comparedToLastMonth >= 0 ? .red : .green)

                    Text("\(abs(spending.comparedToLastMonth), specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(spending.comparedToLastMonth >= 0 ? .red : .green)

                    Text("vs last month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "swiff://analytics"))
    }
}

struct MonthlySpendingWidget: Widget {
    let kind: String = "MonthlySpendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlySpendingProvider()) { entry in
            MonthlySpendingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monthly Spending")
        .description("Track your monthly subscription costs.")
        .supportedFamilies([.systemSmall])
    }
}
```

---

## Deep Linking

### URL Scheme Setup

```swift
// Swiff_IOSApp.swift
@main
struct Swiff_IOSApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handle(url)
                }
        }
    }
}
```

### Deep Link Handler

```swift
// Utilities/DeepLinkHandler.swift
class DeepLinkHandler: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedSubscriptionID: UUID?
    @Published var selectedPersonID: UUID?

    func handle(_ url: URL) {
        guard url.scheme == "swiff" else { return }

        switch url.host {
        case "subscriptions":
            selectedTab = 3 // Subscriptions tab
        case "subscription":
            if let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                selectedSubscriptionID = id
                selectedTab = 3
            }
        case "analytics":
            selectedTab = 4 // Analytics tab
        case "people":
            selectedTab = 2 // People tab
        case "person":
            if let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                selectedPersonID = id
                selectedTab = 2
            }
        default:
            break
        }
    }
}
```

---

## Widget Bundle

```swift
// SwiffWidgets/SwiffWidgetsBundle.swift
import WidgetKit
import SwiftUI

@main
struct SwiffWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UpcomingRenewalsWidget()
        MonthlySpendingWidget()
        QuickActionsWidget()
    }
}
```

---

## Syncing Data to Widget

### In Main App DataManager

```swift
// Services/DataManager.swift
extension DataManager {
    func syncToWidgets() {
        // Upcoming renewals
        let upcoming = subscriptions
            .filter { $0.isActive }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .prefix(5)
            .map { sub in
                WidgetDataService.WidgetSubscription(
                    id: sub.id,
                    name: sub.name,
                    price: sub.price,
                    nextBillingDate: sub.nextBillingDate,
                    icon: sub.icon,
                    color: sub.color
                )
            }

        WidgetDataService.shared.saveUpcomingRenewals(Array(upcoming))

        // Monthly cost
        let totalCost = calculateTotalMonthlyCost()
        WidgetDataService.shared.saveTotalMonthlyCost(totalCost)
    }
}
```

### Trigger Sync After Data Changes

```swift
func addSubscription(_ subscription: Subscription) throws {
    try persistenceService.saveSubscription(subscription)
    subscriptions.append(subscription)

    // Sync to widgets
    syncToWidgets()
}

func updateSubscription(_ subscription: Subscription) throws {
    try persistenceService.updateSubscription(subscription)
    // ... update local array

    syncToWidgets()
}
```

---

## Timeline Refresh Policies

| Policy | Use Case |
|--------|----------|
| `.atEnd` | Refresh when timeline ends |
| `.after(date)` | Refresh at specific time |
| `.never` | Manual refresh only |

```swift
// Refresh at midnight
let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
let timeline = Timeline(entries: [entry], policy: .after(midnight))

// Refresh hourly
let hourly = Date().addingTimeInterval(3600)
let timeline = Timeline(entries: [entry], policy: .after(hourly))

// Manual refresh only
let timeline = Timeline(entries: [entry], policy: .never)
```

---

## Common Mistakes to Avoid

1. **Not using App Groups for shared data**
2. **Fetching network data in widget** (use cached data)
3. **Too frequent timeline refreshes** (battery drain)
4. **Not handling empty state**
5. **Missing widget URL for deep linking**

---

## Checklist

- [ ] App Group configured for main app and widget
- [ ] Widget data service for shared storage
- [ ] Timeline provider implemented
- [ ] All widget sizes supported
- [ ] Deep linking configured
- [ ] Data synced after changes
- [ ] Empty state handled
- [ ] Preview configured

---

## Industry Standards

- **Apple WidgetKit** documentation
- **WWDC 2023-2024** - Widget sessions
- **Human Interface Guidelines** - Widgets
- **Battery efficiency** - Minimize refreshes
