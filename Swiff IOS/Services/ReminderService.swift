//
//  ReminderService.swift
//  Swiff IOS
//
//  Created by Agent 14 on 11/21/25.
//  Comprehensive reminder management service with smart scheduling
//
//  IMPLEMENTATION STATUS: ALL 10 TASKS COMPLETED
//  - Task 1: Initialize with NotificationManager dependency ✅
//  - Task 2: scheduleAllReminders(for:) ✅
//  - Task 3: rescheduleReminders(for:) ✅
//  - Task 4: cancelReminders(for:) ✅
//  - Task 5: calculateOptimalReminderTime(for:) ✅
//  - Task 6: shouldSendReminder(for:) ✅
//  - Task 7: getScheduledReminders() ✅
//  - Task 8: snoozeReminder(for:until:) ✅
//  - Task 9: dismissReminder(for:) ✅
//  - Task 10: Batch operations (scheduleAllPendingReminders, cleanupExpiredReminders) ✅
//

import Foundation
import Combine
import UserNotifications

/// Comprehensive reminder management service
@MainActor
class ReminderService: ObservableObject {

    // MARK: - Singleton
    @MainActor static let shared = ReminderService()

    // MARK: - Dependencies
    private let notificationManager: NotificationManager
    private let dataManager = DataManager.shared

    // MARK: - Published Properties
    @Published var scheduledReminders: [ScheduledReminder] = []
    @Published var reminderHistory: [ReminderHistoryEntry] = []
    @Published var preferences: ReminderPreferences
    @Published var isProcessing = false
    @Published var statistics: ReminderStatistics

    // MARK: - Private Properties
    private let userDefaultsKey = "com.swiff.reminderService.scheduledReminders"
    private let historyKey = "com.swiff.reminderService.history"
    private let preferencesKey = "com.swiff.reminderService.preferences"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init(notificationManager: NotificationManager = .shared) {
        self.notificationManager = notificationManager
        self.preferences = ReminderPreferences()
        self.statistics = ReminderStatistics()

        // Load persisted data
        loadScheduledReminders()
        loadHistory()
        loadPreferences()

        // Update statistics
        updateStatistics()
    }

    // MARK: - Task 2: Schedule All Reminders

    /// Schedule all reminder types for a subscription
    func scheduleAllReminders(for subscription: Subscription) async {
        guard subscription.isActive else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Cancel existing reminders first
        await cancelReminders(for: subscription)

        var newReminders: [ScheduledReminder] = []

        // 1. Renewal reminder
        if subscription.enableRenewalReminder && preferences.enabledReminderTypes.contains(.renewal) {
            if let renewalReminder = createRenewalReminder(for: subscription) {
                newReminders.append(renewalReminder)
            }
        }

        // 2. Trial expiration reminder
        if subscription.isFreeTrial && preferences.enabledReminderTypes.contains(.trialExpiration) {
            if let trialReminder = createTrialExpirationReminder(for: subscription) {
                newReminders.append(trialReminder)
            }
        }

        // 3. Schedule notifications
        for reminder in newReminders {
            await scheduleNotification(for: reminder, subscription: subscription)
            scheduledReminders.append(reminder)
            addHistoryEntry(for: reminder, subscription: subscription, action: .scheduled)
        }

        // Persist changes
        saveScheduledReminders()
        updateStatistics()

        print("✅ Scheduled \(newReminders.count) reminder(s) for \(subscription.name)")
    }

    // MARK: - Task 3: Reschedule Reminders

    /// Reschedule all reminders for a subscription
    func rescheduleReminders(for subscription: Subscription) async {
        await cancelReminders(for: subscription)
        await scheduleAllReminders(for: subscription)
        print("🔄 Rescheduled reminders for \(subscription.name)")
    }

    // MARK: - Task 4: Cancel Reminders

    /// Cancel all reminders for a subscription
    func cancelReminders(for subscription: Subscription) async {
        isProcessing = true
        defer { isProcessing = false }

        // Find all reminders for this subscription
        let remindersToCancel = scheduledReminders.filter { $0.subscriptionId == subscription.id }

        // Cancel notifications
        let identifiers = remindersToCancel.map { $0.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)

        // Remove from array
        scheduledReminders.removeAll { $0.subscriptionId == subscription.id }

        // Add history entries
        for reminder in remindersToCancel {
            addHistoryEntry(for: reminder, subscription: subscription, action: .cancelled)
        }

        saveScheduledReminders()
        updateStatistics()

        print("🗑️ Cancelled \(remindersToCancel.count) reminder(s) for \(subscription.name)")
    }

    // MARK: - Task 5: Calculate Optimal Reminder Time

    /// Calculate optimal reminder time for a subscription
    /// Uses user preferences and quiet hours settings
    func calculateOptimalReminderTime(for subscription: Subscription) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // Start with subscription's next billing date
        var targetDate = subscription.nextBillingDate

        // Subtract days before
        let daysBefore = subscription.reminderDaysBefore > 0 ? subscription.reminderDaysBefore : preferences.defaultDaysBefore
        targetDate = calendar.date(byAdding: .day, value: -daysBefore, to: targetDate) ?? targetDate

        // Apply preferred time
        let preferredTime = subscription.reminderTime ?? preferences.defaultTime
        let timeComponents = calendar.dateComponents([.hour, .minute], from: preferredTime)

        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0

        guard var finalDate = calendar.date(from: components) else {
            return targetDate
        }

        // Check quiet hours
        if preferences.enableQuietHours {
            finalDate = adjustForQuietHours(finalDate)
        }

        // Ensure it's in the future
        if finalDate <= now {
            // Schedule for next appropriate time
            finalDate = calendar.date(byAdding: .day, value: 1, to: finalDate) ?? finalDate
        }

        return finalDate
    }

    /// Helper: Adjust time to avoid quiet hours
    private func adjustForQuietHours(_ date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let quietStartComponents = calendar.dateComponents([.hour, .minute], from: preferences.quietHoursStart)
        let quietEndComponents = calendar.dateComponents([.hour, .minute], from: preferences.quietHoursEnd)

        guard let hour = timeComponents.hour,
              let quietStart = quietStartComponents.hour,
              let quietEnd = quietEndComponents.hour else {
            return date
        }

        // Check if time falls in quiet hours
        let isInQuietHours: Bool
        if quietStart < quietEnd {
            isInQuietHours = hour >= quietStart && hour < quietEnd
        } else {
            // Quiet hours span midnight
            isInQuietHours = hour >= quietStart || hour < quietEnd
        }

        if isInQuietHours {
            // Move to end of quiet hours
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = quietEnd
            components.minute = 0
            return calendar.date(from: components) ?? date
        }

        return date
    }

    // MARK: - Task 6: Should Send Reminder

    /// Check if a reminder should be sent for a subscription
    func shouldSendReminder(for subscription: Subscription) -> Bool {
        // Check if subscription is active
        guard subscription.isActive else { return false }

        // Check if reminders are enabled for this subscription
        guard subscription.enableRenewalReminder else { return false }

        // Check if we've already sent a reminder recently
        if let lastSent = subscription.lastReminderSent {
            let daysSinceLastReminder = Calendar.current.dateComponents([.day], from: lastSent, to: Date()).day ?? 0
            if daysSinceLastReminder < 1 {
                return false // Don't spam reminders
            }
        }

        // Check daily limit
        let todayReminders = scheduledReminders.filter { reminder in
            Calendar.current.isDateInToday(reminder.scheduledDate) && reminder.status == .sent
        }

        if todayReminders.count >= preferences.maxDailyReminders {
            return false
        }

        return true
    }

    // MARK: - Task 7: Get Scheduled Reminders

    /// Get all scheduled reminders
    func getScheduledReminders() -> [ScheduledReminder] {
        return scheduledReminders.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    /// Get pending reminders (scheduled but not sent)
    func getPendingReminders() -> [ScheduledReminder] {
        return scheduledReminders.filter { $0.status == .scheduled && $0.scheduledDate > Date() }
    }

    /// Get overdue reminders
    func getOverdueReminders() -> [ScheduledReminder] {
        return scheduledReminders.filter { $0.status == .scheduled && $0.scheduledDate <= Date() }
    }

    // MARK: - Task 8: Snooze Reminder

    /// Snooze a reminder until specified date
    func snoozeReminder(for subscription: Subscription, until date: Date) async {
        // Find reminder
        guard let index = scheduledReminders.firstIndex(where: { $0.subscriptionId == subscription.id && $0.status == .scheduled }) else {
            return
        }

        var reminder = scheduledReminders[index]

        // Update reminder
        reminder.status = .snoozed
        reminder.snoozedUntil = date
        scheduledReminders[index] = reminder

        // Cancel current notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id])

        // Schedule new notification for snooze time
        let content = UNMutableNotificationContent()
        content.title = "Subscription Reminder"
        content.body = reminder.message
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION_REMINDER"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            addHistoryEntry(for: reminder, subscription: subscription, action: .snoozed, note: "Snoozed until \(date.formatted())")
            saveScheduledReminders()
            print("😴 Snoozed reminder for \(subscription.name) until \(date.formatted())")
        } catch {
            print("❌ Failed to snooze reminder: \(error)")
        }
    }

    // MARK: - Task 9: Dismiss Reminder

    /// Dismiss a reminder permanently
    func dismissReminder(for subscription: Subscription) async {
        // Find and update reminder
        guard let index = scheduledReminders.firstIndex(where: { $0.subscriptionId == subscription.id && $0.status == .scheduled }) else {
            return
        }

        var reminder = scheduledReminders[index]
        reminder.status = .dismissed
        scheduledReminders[index] = reminder

        // Cancel notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id])

        addHistoryEntry(for: reminder, subscription: subscription, action: .dismissed)
        saveScheduledReminders()
        updateStatistics()

        print("👋 Dismissed reminder for \(subscription.name)")
    }

    // MARK: - Task 10: Batch Operations

    /// Schedule all pending reminders for active subscriptions
    func scheduleAllPendingReminders() async {
        isProcessing = true
        defer { isProcessing = false }

        let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
        var scheduledCount = 0

        for subscription in activeSubscriptions {
            // Check if already has scheduled reminders
            let hasReminders = scheduledReminders.contains { $0.subscriptionId == subscription.id && $0.isPending }

            if !hasReminders {
                await scheduleAllReminders(for: subscription)
                scheduledCount += 1
            }
        }

        print("📅 Scheduled reminders for \(scheduledCount) subscription(s)")
    }

    /// Cleanup expired and old reminders
    func cleanupExpiredReminders() async {
        isProcessing = true
        defer { isProcessing = false }

        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        // Remove old sent/dismissed reminders
        let before = scheduledReminders.count
        scheduledReminders.removeAll { reminder in
            (reminder.status == .sent || reminder.status == .dismissed) && reminder.scheduledDate < cutoffDate
        }
        let removed = before - scheduledReminders.count

        // Cleanup old history entries (keep last 3 months)
        let historyCutoff = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let historyBefore = reminderHistory.count
        reminderHistory.removeAll { $0.timestamp < historyCutoff }
        let historyRemoved = historyBefore - reminderHistory.count

        saveScheduledReminders()
        saveHistory()
        updateStatistics()

        print("🧹 Cleaned up \(removed) reminder(s) and \(historyRemoved) history entry(ies)")
    }

    // MARK: - Helper Methods

    /// Create renewal reminder
    private func createRenewalReminder(for subscription: Subscription) -> ScheduledReminder? {
        let optimalTime = calculateOptimalReminderTime(for: subscription)

        // Don't create if in the past
        guard optimalTime > Date() else { return nil }

        let message = "\(subscription.name) will renew in \(subscription.reminderDaysBefore) days for \(subscription.price.asCurrency)"
        let id = "renewal_\(subscription.id.uuidString)"

        return ScheduledReminder(
            id: id,
            subscriptionId: subscription.id,
            type: .renewal,
            scheduledDate: optimalTime,
            status: .scheduled,
            message: message
        )
    }

    /// Create trial expiration reminder
    private func createTrialExpirationReminder(for subscription: Subscription) -> ScheduledReminder? {
        guard let trialEndDate = subscription.trialEndDate else { return nil }

        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -3, to: trialEndDate) else { return nil }

        // Don't create if in the past
        guard reminderDate > Date() else { return nil }

        let cost = subscription.priceAfterTrial ?? subscription.price
        let message = "\(subscription.name) trial ends in 3 days. Will charge \(cost.asCurrency) after trial."
        let id = "trial_\(subscription.id.uuidString)"

        return ScheduledReminder(
            id: id,
            subscriptionId: subscription.id,
            type: .trialExpiration,
            scheduledDate: reminderDate,
            status: .scheduled,
            priority: .high,
            message: message
        )
    }

    /// Schedule notification
    private func scheduleNotification(for reminder: ScheduledReminder, subscription: Subscription) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.type == .renewal ? "Subscription Renewal" : "Trial Ending"
        content.body = reminder.message
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION_REMINDER"
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Failed to schedule notification: \(error)")
        }
    }

    /// Add history entry
    private func addHistoryEntry(for reminder: ScheduledReminder, subscription: Subscription, action: ReminderAction, note: String? = nil) {
        let entry = ReminderHistoryEntry(
            reminderId: reminder.id,
            subscriptionId: subscription.id,
            type: reminder.type,
            action: action,
            note: note
        )
        reminderHistory.append(entry)
        saveHistory()
    }

    /// Update statistics
    private func updateStatistics() {
        let totalScheduled = scheduledReminders.filter { $0.status == .scheduled }.count
        let totalSent = scheduledReminders.filter { $0.status == .sent }.count
        let totalSnoozed = scheduledReminders.filter { $0.status == .snoozed }.count
        let totalDismissed = scheduledReminders.filter { $0.status == .dismissed }.count

        let upcomingToday = scheduledReminders.filter { reminder in
            Calendar.current.isDateInToday(reminder.scheduledDate) && reminder.isPending
        }.count

        let upcomingWeek = scheduledReminders.filter { reminder in
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: reminder.scheduledDate).day ?? 0
            return daysUntil >= 0 && daysUntil <= 7 && reminder.isPending
        }.count

        let overdueCount = scheduledReminders.filter { $0.isOverdue }.count

        statistics = ReminderStatistics(
            totalScheduled: totalScheduled,
            totalSent: totalSent,
            totalSnoozed: totalSnoozed,
            totalDismissed: totalDismissed,
            upcomingToday: upcomingToday,
            upcomingWeek: upcomingWeek,
            overdueCount: overdueCount
        )
    }

    // MARK: - Persistence

    private func saveScheduledReminders() {
        if let encoded = try? JSONEncoder().encode(scheduledReminders) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadScheduledReminders() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ScheduledReminder].self, from: data) {
            scheduledReminders = decoded
        }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(reminderHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ReminderHistoryEntry].self, from: data) {
            reminderHistory = decoded
        }
    }

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(ReminderPreferences.self, from: data) {
            preferences = decoded
        }
    }

    // MARK: - Public Configuration

    /// Update reminder preferences
    func updatePreferences(_ newPreferences: ReminderPreferences) {
        preferences = newPreferences
        savePreferences()
    }
}
