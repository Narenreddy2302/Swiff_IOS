//
//  NotificationManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Notification permissions and scheduling management
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Memory Leak Fix (Phase 2.2)
    // Store initialization task to prevent orphaned tasks
    private var initTask: Task<Void, Never>?

    private init() {
        initTask = Task { @MainActor in
            await checkPermissionStatus()
            await setupNotificationCategories()
            initTask = nil
        }
    }

    deinit {
        // Clean up any pending tasks
        initTask?.cancel()
        initTask = nil
    }

    // MARK: - AGENT 7: Notification Categories & Actions

    /// Setup notification categories with custom actions
    private func setupNotificationCategories() async {
        // Subscription renewal actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_SUBSCRIPTION",
            title: "View Details",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_REMINDER",
            title: "Remind Tomorrow",
            options: []
        )

        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_SUBSCRIPTION",
            title: "Cancel Subscription",
            options: [.destructive, .foreground]
        )

        let renewalCategory = UNNotificationCategory(
            identifier: "SUBSCRIPTION_RENEWAL",
            actions: [viewAction, snoozeAction, cancelAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Trial expiration actions
        let keepAction = UNNotificationAction(
            identifier: "KEEP_TRIAL",
            title: "Keep Subscription",
            options: [.foreground]
        )

        let cancelTrialAction = UNNotificationAction(
            identifier: "CANCEL_TRIAL",
            title: "Cancel Before Charge",
            options: [.destructive, .foreground]
        )

        let trialCategory = UNNotificationCategory(
            identifier: "TRIAL_EXPIRATION",
            actions: [viewAction, keepAction, cancelTrialAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Price change actions
        let reviewAction = UNNotificationAction(
            identifier: "REVIEW_PRICE",
            title: "Review Changes",
            options: [.foreground]
        )

        let priceCategory = UNNotificationCategory(
            identifier: "PRICE_CHANGE",
            actions: [reviewAction, viewAction, cancelAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Unused subscription actions
        let stillUsingAction = UNNotificationAction(
            identifier: "STILL_USING",
            title: "Still Using",
            options: []
        )

        let unusedCategory = UNNotificationCategory(
            identifier: "UNUSED_SUBSCRIPTION",
            actions: [stillUsingAction, viewAction, cancelAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Payment reminder actions
        let paymentCategory = UNNotificationCategory(
            identifier: "PAYMENT_REMINDER",
            actions: [viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Test notification category
        let testCategory = UNNotificationCategory(
            identifier: "TEST_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Register all categories
        let categories: Set<UNNotificationCategory> = [
            renewalCategory,
            trialCategory,
            priceCategory,
            unusedCategory,
            paymentCategory,
            testCategory
        ]

        center.setNotificationCategories(categories)
        print("✅ Notification categories registered")
    }

    // MARK: - Notification Action Handling

    /// Handle notification action responses
    /// Call this from SceneDelegate or AppDelegate
    func handleNotificationAction(
        _ response: UNNotificationResponse,
        completion: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        guard let subscriptionIdString = userInfo["subscriptionId"] as? String,
              let subscriptionId = UUID(uuidString: subscriptionIdString) else {
            completion()
            return
        }

        Task { @MainActor in
            // Get subscription
            let dataManager = DataManager.shared
            guard let subscription = dataManager.subscriptions.first(where: { $0.id == subscriptionId }) else {
                completion()
                return
            }

            switch actionIdentifier {
            case "VIEW_SUBSCRIPTION", "REVIEW_PRICE":
                // Navigate to subscription detail
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToSubscription"),
                    object: subscription.id
                )

            case "SNOOZE_REMINDER":
                // Snooze reminder for 1 day
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                await ReminderService.shared.snoozeReminder(for: subscription, until: tomorrow)
                ToastManager.shared.showSuccess("Reminder snoozed until tomorrow")

            case "CANCEL_SUBSCRIPTION", "CANCEL_TRIAL":
                // Show cancellation confirmation
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowCancelSubscription"),
                    object: subscription.id
                )

            case "KEEP_TRIAL":
                // Mark trial as kept
                var updatedSubscription = subscription
                updatedSubscription.willConvertToPaid = true
                try? dataManager.updateSubscription(updatedSubscription)
                ToastManager.shared.showSuccess("Trial will convert to paid subscription")

            case "STILL_USING":
                // Update last used date
                var updatedSubscription = subscription
                updatedSubscription.lastUsedDate = Date()
                updatedSubscription.usageCount += 1
                try? dataManager.updateSubscription(updatedSubscription)
                ToastManager.shared.showSuccess("Marked as still using")

            case UNNotificationDefaultActionIdentifier:
                // Default tap action - navigate to subscription
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToSubscription"),
                    object: subscription.id
                )

            case UNNotificationDismissActionIdentifier:
                // User dismissed notification
                print("User dismissed notification for \(subscription.name)")

            default:
                break
            }

            completion()
        }
    }

    // MARK: - Permission Management

    /// Check current notification permission status
    func checkPermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Request notification permissions
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await checkPermissionStatus()

            if granted {
                ToastManager.shared.showSuccess("Notifications enabled")
            } else {
                ToastManager.shared.showWarning("Notifications were not enabled")
            }

            return granted
        } catch {
            ToastManager.shared.showError("Failed to request notification permission")
            return false
        }
    }

    /// Open app settings to enable notifications
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Notification Scheduling

    /// Schedule a payment reminder notification
    func schedulePaymentReminder(for person: Person, amount: Double, date: Date) async {
        guard isAuthorized else {
            ToastManager.shared.showWarning("Enable notifications to receive reminders")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = person.balance > 0
            ? "\(person.name) owes you \(amount.asCurrency)"
            : "You owe \(person.name) \(abs(amount).asCurrency)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "PAYMENT_REMINDER"

        // Schedule for specific date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "payment_\(person.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            ToastManager.shared.showSuccess("Reminder scheduled")
        } catch {
            ToastManager.shared.showError("Failed to schedule reminder")
        }
    }

    /// Schedule a subscription renewal reminder
    func scheduleSubscriptionReminder(for subscription: Subscription, daysBefore: Int = 3) async {
        guard isAuthorized else {
            ToastManager.shared.showWarning("Enable notifications to receive reminders")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewal"
        content.body = "\(subscription.name) will renew in \(daysBefore) days (\(subscription.price.asCurrency))"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "SUBSCRIPTION_REMINDER"

        // Calculate reminder date (X days before renewal)
        guard let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: subscription.nextBillingDate
        ) else { return }

        // Only schedule if in the future
        guard reminderDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "subscription_\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule subscription reminder: \(error)")
        }
    }

    // MARK: - AGENT 7: Enhanced Notification Scheduling

    /// Schedule a renewal reminder with custom settings from subscription
    func scheduleRenewalReminder(for subscription: Subscription, daysBefore: Int? = nil) async {
        guard isAuthorized else {
            ToastManager.shared.showWarning("Enable notifications to receive reminders")
            return
        }

        // Check if reminders are enabled for this subscription
        guard subscription.enableRenewalReminder else { return }

        let daysBeforeRenewal = daysBefore ?? subscription.reminderDaysBefore

        let content = UNMutableNotificationContent()
        content.title = "\(subscription.name) Renews Soon"
        content.body = "$\(String(format: "%.2f", subscription.price)) will be charged on \(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))"
        content.subtitle = subscription.category.rawValue
        content.sound = UNNotificationSound(named: UNNotificationSoundName("subscription_reminder.mp3"))
        content.badge = NSNumber(value: await getPendingNotifications().count + 1)
        content.categoryIdentifier = "SUBSCRIPTION_RENEWAL"
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "subscriptionName": subscription.name,
            "type": "renewal"
        ]

        // Calculate reminder date
        var reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBeforeRenewal,
            to: subscription.nextBillingDate
        ) ?? subscription.nextBillingDate

        // Apply custom reminder time if set
        if let reminderTime = subscription.reminderTime {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)

            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour ?? 9
            combined.minute = timeComponents.minute ?? 0

            if let customDate = Calendar.current.date(from: combined) {
                reminderDate = customDate
            }
        } else {
            // Default to 9 AM
            var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
            components.hour = 9
            components.minute = 0
            if let defaultDate = Calendar.current.date(from: components) {
                reminderDate = defaultDate
            }
        }

        // Only schedule if in the future
        guard reminderDate > Date() else { return }

        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "renewal_\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ Scheduled renewal reminder for \(subscription.name) at \(reminderDate)")
        } catch {
            print("❌ Failed to schedule renewal reminder: \(error)")
        }
    }

    /// Schedule a price change alert (AGENT 9: Price History Tracking)
    func schedulePriceChangeAlert(for subscription: Subscription, oldPrice: Double, newPrice: Double) async {
        guard isAuthorized else {
            ToastManager.shared.showWarning("Enable notifications to receive price change alerts")
            return
        }

        let changePercentage = ((newPrice - oldPrice) / oldPrice) * 100
        let changeAmount = newPrice - oldPrice

        let content = UNMutableNotificationContent()
        content.title = "\(subscription.name) Price Increased"
        content.body = String(format: "$%.2f → $%.2f (+$%.2f, +%.1f%%)", oldPrice, newPrice, changeAmount, changePercentage)
        content.sound = .default
        content.badge = NSNumber(value: await getPendingNotifications().count + 1)
        content.categoryIdentifier = "PRICE_CHANGE"
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "subscriptionName": subscription.name,
            "type": "price_change",
            "oldPrice": oldPrice,
            "newPrice": newPrice
        ]

        // Send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "price_change_\(subscription.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ Price change alert scheduled for \(subscription.name)")
            ToastManager.shared.showWarning("Price increased: \(subscription.name)")
        } catch {
            print("❌ Failed to schedule price change alert: \(error)")
        }
    }

    /// Schedule trial expiration reminders (3 days, 1 day, same day)
    func scheduleTrialExpirationReminder(for subscription: Subscription) async {
        guard isAuthorized else { return }
        guard subscription.isFreeTrial, let trialEndDate = subscription.trialEndDate else { return }

        let reminders = [
            (days: 3, title: "Trial Ending Soon"),
            (days: 1, title: "Trial Ends Tomorrow"),
            (days: 0, title: "Trial Ends Today")
        ]

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = "\(subscription.name) trial ends on \(trialEndDate.formatted(date: .abbreviated, time: .omitted))"

            if subscription.willConvertToPaid {
                let priceAfter = subscription.priceAfterTrial ?? subscription.price
                content.subtitle = "Will convert to $\(String(format: "%.2f", priceAfter))/\(subscription.billingCycle.shortName)"
            } else {
                content.subtitle = "Remember to cancel if not continuing"
            }

            content.sound = .default
            content.categoryIdentifier = "TRIAL_EXPIRATION"
            content.userInfo = [
                "subscriptionId": subscription.id.uuidString,
                "type": "trial"
            ]

            // Calculate notification date
            guard let notificationDate = Calendar.current.date(
                byAdding: .day,
                value: -reminder.days,
                to: trialEndDate
            ) else { continue }

            // Only schedule if in the future
            guard notificationDate > Date() else { continue }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
            components.hour = 10
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "trial_\(subscription.id.uuidString)_\(reminder.days)d",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Scheduled trial reminder for \(subscription.name) - \(reminder.days) days before")
            } catch {
                print("❌ Failed to schedule trial reminder: \(error)")
            }
        }
    }

    /// Schedule unused subscription alert
    func scheduleUnusedSubscriptionAlert(for subscription: Subscription, daysUnused: Int) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Unused Subscription"
        content.body = "You haven't used \(subscription.name) in \(daysUnused) days. Consider cancelling?"
        content.subtitle = "Tap to review or mark as still using"
        content.sound = .default
        content.categoryIdentifier = "UNUSED_SUBSCRIPTION"
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "type": "unused",
            "daysUnused": daysUnused
        ]

        // Send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "unused_\(subscription.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ Scheduled unused subscription alert for \(subscription.name)")
        } catch {
            print("❌ Failed to schedule unused subscription alert: \(error)")
        }
    }

    /// Update all scheduled reminders for a subscription
    func updateScheduledReminders(for subscription: Subscription) async {
        // Cancel existing reminders
        cancelAllReminders(for: subscription)

        // Reschedule if enabled
        if subscription.enableRenewalReminder && subscription.isActive {
            await scheduleRenewalReminder(for: subscription)
        }

        // Schedule trial reminders if applicable
        if subscription.isFreeTrial && !subscription.isTrialExpired {
            await scheduleTrialExpirationReminder(for: subscription)
        }

        print("✅ Updated reminders for \(subscription.name)")
    }

    /// Cancel all reminders for a subscription
    func cancelAllReminders(for subscription: Subscription) {
        let identifiers = [
            "renewal_\(subscription.id.uuidString)",
            "subscription_\(subscription.id.uuidString)",
            "trial_\(subscription.id.uuidString)_3d",
            "trial_\(subscription.id.uuidString)_1d",
            "trial_\(subscription.id.uuidString)_0d"
        ]

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ Cancelled all reminders for \(subscription.name)")
    }

    /// Send a test notification
    func sendTestNotification() async {
        guard isAuthorized else {
            ToastManager.shared.showWarning("Enable notifications first")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test reminder from Swiff. Notifications are working!"
        content.subtitle = "Your reminders will look like this"
        content.sound = .default
        content.categoryIdentifier = "TEST_NOTIFICATION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            ToastManager.shared.showSuccess("Test notification sent!")
        } catch {
            ToastManager.shared.showError("Failed to send test notification")
        }
    }

    /// Schedule all subscription reminders
    func scheduleAllSubscriptionReminders(subscriptions: [Subscription]) async {
        guard isAuthorized else { return }

        for subscription in subscriptions where subscription.isActive {
            await scheduleSubscriptionReminder(for: subscription)
        }
    }

    /// Cancel a specific notification
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all payment reminders for a person
    func cancelPaymentReminders(for personId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["payment_\(personId.uuidString)"])
    }

    /// Cancel all subscription reminders for a subscription
    func cancelSubscriptionReminders(for subscriptionId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["subscription_\(subscriptionId.uuidString)"])
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        ToastManager.shared.showSuccess("All reminders cancelled")
    }

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    // MARK: - Badge Management

    /// Update app badge count
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    /// Clear app badge
    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - Notification Permission View

struct NotificationPermissionCard: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: notificationManager.isAuthorized ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 32))
                    .foregroundColor(notificationManager.isAuthorized ? .wiseForestGreen : .wiseSecondaryText)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(notificationManager.isAuthorized ? Color.wiseForestGreen.opacity(0.1) : Color.wiseBorder.opacity(0.3))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(notificationManager.isAuthorized ? "Notifications Enabled" : "Enable Notifications")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text(notificationManager.isAuthorized
                        ? "You'll receive payment and subscription reminders"
                        : "Get reminders for payments and renewals")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(2)
                }

                Spacer()
            }

            if !notificationManager.isAuthorized {
                Button(action: {
                    Task {
                        isRequesting = true
                        if notificationManager.permissionStatus == .denied {
                            notificationManager.openSettings()
                        } else {
                            _ = await notificationManager.requestPermission()
                        }
                        isRequesting = false
                    }
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(notificationManager.permissionStatus == .denied ? "Open Settings" : "Enable Notifications")
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .background(Color.wiseForestGreen)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
                .shadow(color: Color.wiseShadowColor, radius: 10, x: 0, y: 2)
        )
        .onAppear {
            Task {
                await notificationManager.checkPermissionStatus()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NotificationPermissionCard()
            .padding()

        Text("Preview of notification permission card")
            .font(.caption)
    }
    .background(Color.wiseBackground)
}
