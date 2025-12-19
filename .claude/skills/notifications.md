# Notification Handling

## Purpose
Guide local notification implementation, permission management, scheduling strategies, and notification actions following Apple's best practices.

## When to Use This Skill
- Implementing renewal reminders
- Scheduling notifications
- Handling notification permissions
- Creating notification actions
- Managing notification limits

---

## Notification Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   NotificationManager                        │
│           (UNUserNotificationCenterDelegate)                 │
└─────────────────────────────────────────────────────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Permission  │ │   Renewal    │ │    Trial     │ │    Price     │
│  Management  │ │  Reminders   │ │ Expiration   │ │   Alerts     │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

---

## NotificationManager

```swift
// Services/NotificationManager.swift
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    // MARK: - Singleton
    static let shared = NotificationManager()

    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotificationsCount: Int = 0

    // MARK: - Initialization
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task {
            await updateAuthorizationStatus()
            await updatePendingCount()
        }
    }

    // MARK: - Permission Management

    func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await updateAuthorizationStatus()
            return granted
        } catch {
            throw NotificationError.authorizationFailed(error)
        }
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    // MARK: - Notification Categories

    func setupNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // Subscription Renewal Category
        let viewAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_1_DAY",
            title: "Remind Tomorrow",
            options: []
        )
        let renewalCategory = UNNotificationCategory(
            identifier: "SUBSCRIPTION_RENEWAL",
            actions: [viewAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Trial Expiration Category
        let keepAction = UNNotificationAction(
            identifier: "KEEP_SUBSCRIPTION",
            title: "Keep Subscription",
            options: []
        )
        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_SUBSCRIPTION",
            title: "Cancel",
            options: .destructive
        )
        let trialCategory = UNNotificationCategory(
            identifier: "TRIAL_EXPIRATION",
            actions: [keepAction, cancelAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Price Change Category
        let priceCategory = UNNotificationCategory(
            identifier: "PRICE_CHANGE",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([renewalCategory, trialCategory, priceCategory])
    }

    // MARK: - Schedule Renewal Reminder

    func scheduleRenewalReminder(for subscription: Subscription) async {
        guard subscription.enableRenewalReminder else { return }
        guard isAuthorized else { return }

        // Cancel existing reminder first
        cancelAllReminders(for: subscription)

        // Calculate trigger date
        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -subscription.reminderDaysBefore,
            to: subscription.nextBillingDate
        )

        guard let triggerDate = reminderDate, triggerDate > Date() else {
            return // Don't schedule past reminders
        }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewal Coming Up"
        content.body = "\(subscription.name) renews in \(subscription.reminderDaysBefore) days for \(subscription.price.asCurrency)"
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION_RENEWAL"
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "type": "renewal"
        ]

        // Set custom reminder time or use default (9 AM)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        if let reminderTime = subscription.reminderTime {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
        } else {
            dateComponents.hour = 9
            dateComponents.minute = 0
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "renewal_\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            await updatePendingCount()
            print("Scheduled renewal reminder for \(subscription.name)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Schedule Trial Expiration

    func scheduleTrialExpirationReminder(for subscription: Subscription) async {
        guard subscription.isFreeTrial,
              let trialEndDate = subscription.trialEndDate,
              trialEndDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Free Trial Ending Soon"
        content.body = "\(subscription.name) trial ends tomorrow. Cancel now to avoid charges of \(subscription.price.asCurrency)/\(subscription.billingCycle.displayName)"
        content.sound = .default
        content.categoryIdentifier = "TRIAL_EXPIRATION"
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "type": "trial"
        ]

        // Remind 1 day before
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: trialEndDate)!
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "trial_\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
        await updatePendingCount()
    }

    // MARK: - Schedule Price Change Alert

    func schedulePriceChangeAlert(for subscription: Subscription, oldPrice: Double, newPrice: Double) async {
        let percentChange = ((newPrice - oldPrice) / oldPrice) * 100

        let content = UNMutableNotificationContent()
        content.title = "Price Increase Detected"
        content.body = "\(subscription.name) increased from \(oldPrice.asCurrency) to \(newPrice.asCurrency) (\(String(format: "%.1f", percentChange))% increase)"
        content.sound = .default
        content.categoryIdentifier = "PRICE_CHANGE"
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "type": "price_change"
        ]

        // Immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "price_\(subscription.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel Reminders

    func cancelAllReminders(for subscription: Subscription) {
        let identifiers = [
            "renewal_\(subscription.id.uuidString)",
            "trial_\(subscription.id.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Task {
            await updatePendingCount()
        }
    }

    // MARK: - Update Scheduled Reminders

    func updateScheduledReminders(for subscription: Subscription) async {
        // Cancel existing
        cancelAllReminders(for: subscription)

        // Schedule new if active
        if subscription.isActive {
            await scheduleRenewalReminder(for: subscription)

            if subscription.isFreeTrial {
                await scheduleTrialExpirationReminder(for: subscription)
            }
        }
    }

    // MARK: - Pending Count

    func updatePendingCount() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingNotificationsCount = requests.count
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "VIEW_DETAILS":
            if let idString = userInfo["subscriptionId"] as? String,
               let id = UUID(uuidString: idString) {
                NotificationCenter.default.post(
                    name: .navigateToSubscription,
                    object: nil,
                    userInfo: ["subscriptionId": id]
                )
            }

        case "SNOOZE_1_DAY":
            if let idString = userInfo["subscriptionId"] as? String,
               let id = UUID(uuidString: idString) {
                Task {
                    await snoozeReminder(subscriptionId: id, days: 1)
                }
            }

        case "KEEP_SUBSCRIPTION":
            // Just acknowledge
            break

        case "CANCEL_SUBSCRIPTION":
            if let idString = userInfo["subscriptionId"] as? String,
               let id = UUID(uuidString: idString) {
                NotificationCenter.default.post(
                    name: .cancelSubscriptionRequested,
                    object: nil,
                    userInfo: ["subscriptionId": id]
                )
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification body
            if let idString = userInfo["subscriptionId"] as? String,
               let id = UUID(uuidString: idString) {
                NotificationCenter.default.post(
                    name: .navigateToSubscription,
                    object: nil,
                    userInfo: ["subscriptionId": id]
                )
            }

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Helper Methods

    private func snoozeReminder(subscriptionId: UUID, days: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Reminder"
        content.body = "Don't forget to review your upcoming subscription renewal"
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION_RENEWAL"
        content.userInfo = ["subscriptionId": subscriptionId.uuidString, "type": "snoozed"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(days * 24 * 60 * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "snoozed_\(subscriptionId.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToSubscription = Notification.Name("navigateToSubscription")
    static let cancelSubscriptionRequested = Notification.Name("cancelSubscriptionRequested")
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case authorizationFailed(Error)
    case schedulingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let error):
            return "Failed to request notification permission: \(error.localizedDescription)"
        case .schedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        }
    }
}
```

---

## Notification Limit Manager

```swift
// Utilities/NotificationLimitManager.swift
class NotificationLimitManager {
    static let shared = NotificationLimitManager()

    // iOS limits to 64 scheduled local notifications
    private let maxNotifications = 64
    private let reservedSlots = 10 // Keep some for urgent notifications

    var availableSlots: Int {
        maxNotifications - reservedSlots
    }

    func canScheduleMore() async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.count < availableSlots
    }

    func prioritizeNotifications(_ subscriptions: [Subscription]) -> [Subscription] {
        // Prioritize by:
        // 1. Trials expiring soon
        // 2. Higher price subscriptions
        // 3. Sooner billing dates

        return subscriptions
            .filter { $0.isActive && $0.enableRenewalReminder }
            .sorted { sub1, sub2 in
                // Trials first
                if sub1.isFreeTrial && !sub2.isFreeTrial { return true }
                if !sub1.isFreeTrial && sub2.isFreeTrial { return false }

                // Then by price (higher first)
                if sub1.price != sub2.price {
                    return sub1.price > sub2.price
                }

                // Then by date (sooner first)
                return sub1.nextBillingDate < sub2.nextBillingDate
            }
            .prefix(availableSlots)
            .map { $0 }
    }
}
```

---

## Permission Request UI

```swift
struct NotificationPermissionView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Stay Informed")
                .font(.title2)
                .fontWeight(.bold)

            Text("Get reminders before your subscriptions renew so you're never surprised by charges.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button(action: requestPermission) {
                if isRequesting {
                    ProgressView()
                } else {
                    Text("Enable Notifications")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)

            Button("Maybe Later") {
                // Dismiss
            }
            .foregroundColor(.secondary)
        }
        .padding(40)
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            _ = try? await notificationManager.requestAuthorization()
            isRequesting = false
        }
    }
}
```

---

## Notification Settings UI

```swift
struct NotificationSettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @AppStorage("defaultReminderDays") private var defaultReminderDays = 3

    var body: some View {
        Form {
            Section {
                if notificationManager.isAuthorized {
                    Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Enable Notifications") {
                        Task {
                            _ = try? await notificationManager.requestAuthorization()
                        }
                    }
                }
            }

            Section("Default Reminder") {
                Picker("Days before renewal", selection: $defaultReminderDays) {
                    Text("1 day").tag(1)
                    Text("3 days").tag(3)
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                }
            }

            Section {
                HStack {
                    Text("Scheduled Notifications")
                    Spacer()
                    Text("\(notificationManager.pendingNotificationsCount)")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("Cancel All Notifications", role: .destructive) {
                    notificationManager.cancelAllNotifications()
                }
            }
        }
        .navigationTitle("Notifications")
    }
}
```

---

## Integration with Subscriptions

```swift
// In DataManager after subscription changes
func addSubscription(_ subscription: Subscription) throws {
    try persistenceService.saveSubscription(subscription)
    subscriptions.append(subscription)

    // Schedule notification
    Task {
        await NotificationManager.shared.updateScheduledReminders(for: subscription)
    }
}

func deleteSubscription(id: UUID) throws {
    // Cancel notifications first
    if let subscription = subscriptions.first(where: { $0.id == id }) {
        NotificationManager.shared.cancelAllReminders(for: subscription)
    }

    try persistenceService.deleteSubscription(id: id)
    subscriptions.removeAll { $0.id == id }
}
```

---

## Common Mistakes to Avoid

1. **Not checking authorization before scheduling**
2. **Exceeding 64 notification limit**
3. **Scheduling past dates**
4. **Not cancelling when subscription deleted**
5. **Not handling foreground notifications**

---

## Checklist

- [ ] Permission requested at appropriate time
- [ ] Categories and actions configured
- [ ] Renewal reminders scheduled
- [ ] Trial expiration alerts scheduled
- [ ] Notifications cancelled on delete
- [ ] Foreground presentation handled
- [ ] Action handlers implemented
- [ ] 64 notification limit respected

---

## Industry Standards

- **Apple Local Notifications** documentation
- **Human Interface Guidelines** - Notifications
- **User permission best practices**
- **Notification action patterns**
