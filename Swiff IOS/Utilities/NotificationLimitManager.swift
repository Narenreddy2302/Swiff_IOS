//
//  NotificationLimitManager.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 5.3: Comprehensive notification limit management
//

import Combine
import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Limit Errors

enum NotificationLimitError: LocalizedError {
    case limitReached(scheduled: Int, limit: Int)
    case schedulingFailed(underlying: Error)
    case authorizationDenied
    case invalidIdentifier
    case notificationNotFound(identifier: String)
    case priorityQueueFull

    var errorDescription: String? {
        switch self {
        case .limitReached(let scheduled, let limit):
            return "Notification limit reached: \(scheduled)/\(limit) notifications scheduled."
        case .schedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        case .authorizationDenied:
            return "Notification permission denied. Please enable in Settings."
        case .invalidIdentifier:
            return "Invalid notification identifier provided."
        case .notificationNotFound(let identifier):
            return "Notification not found: \(identifier)"
        case .priorityQueueFull:
            return "Cannot schedule more high-priority notifications."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .limitReached:
            return "Remove old or low-priority notifications to make room for new ones."
        case .schedulingFailed:
            return "Check notification settings and try again."
        case .authorizationDenied:
            return "Go to Settings > Notifications > Swiff to enable notifications."
        case .invalidIdentifier:
            return "Use a valid notification identifier."
        case .notificationNotFound:
            return "The notification may have already been delivered or removed."
        case .priorityQueueFull:
            return "Remove some high-priority notifications first."
        }
    }
}

// MARK: - Notification Priority

enum NotificationPriority: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Managed Notification

struct ManagedNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let fireDate: Date
    let priority: NotificationPriority
    let category: String
    let createdAt: Date
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var daysUntilFire: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: fireDate).day ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, title, body, fireDate, priority, category, createdAt, expiresAt
    }

    init(id: String, title: String, body: String, fireDate: Date, priority: NotificationPriority, category: String, expiresAt: Date? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.fireDate = fireDate
        self.priority = priority
        self.category = category
        self.createdAt = Date()
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        fireDate = try container.decode(Date.self, forKey: .fireDate)
        let priorityRaw = try container.decode(Int.self, forKey: .priority)
        priority = NotificationPriority(rawValue: priorityRaw) ?? .medium
        category = try container.decode(String.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(fireDate, forKey: .fireDate)
        try container.encode(priority.rawValue, forKey: .priority)
        try container.encode(category, forKey: .category)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
    }
}

// MARK: - Notification Schedule Statistics

struct NotificationScheduleStatistics {
    let totalScheduled: Int
    let availableSlots: Int
    let byPriority: [NotificationPriority: Int]
    let byCategory: [String: Int]
    let oldestNotification: Date?
    let newestNotification: Date?
    let expiredCount: Int
    let warningThreshold: Int

    var isNearLimit: Bool {
        return totalScheduled >= warningThreshold
    }

    var utilizationPercentage: Double {
        return (Double(totalScheduled) / 64.0) * 100.0
    }

    var summary: String {
        var text = "=== Notification Statistics ===\n\n"
        text += "Total Scheduled: \(totalScheduled)/64\n"
        text += "Available Slots: \(availableSlots)\n"
        text += "Utilization: \(String(format: "%.1f", utilizationPercentage))%\n\n"

        text += "By Priority:\n"
        for priority in [NotificationPriority.critical, .high, .medium, .low] {
            let count = byPriority[priority] ?? 0
            text += "  \(priority.displayName): \(count)\n"
        }

        text += "\nBy Category:\n"
        for (category, count) in byCategory.sorted(by: { $0.key < $1.key }) {
            text += "  \(category): \(count)\n"
        }

        if expiredCount > 0 {
            text += "\n⚠️ Expired Notifications: \(expiredCount)\n"
        }

        if isNearLimit {
            text += "\n⚠️ WARNING: Near notification limit!\n"
        }

        return text
    }
}

// MARK: - Notification Limit Manager

@MainActor
class NotificationLimitManager: ObservableObject {

    // MARK: - Configuration

    static let shared = NotificationLimitManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let maxNotifications = 64 // iOS limit
    private let warningThreshold = 55 // Warn when 85% full
    private let cleanupThreshold = 60 // Auto-cleanup when 94% full

    @Published var currentCount: Int = 0
    @Published var isNearLimit: Bool = false

    // MARK: - Notification Tracking

    private var managedNotifications: [String: ManagedNotification] = [:]
    private let storageKey = "managed_notifications"

    init() {
        loadManagedNotifications()
        Task {
            await updateNotificationCount()
        }
    }

    // MARK: - Authorization

    /// Request notification authorization
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            if !granted {
                throw NotificationLimitError.authorizationDenied
            }
            return granted
        } catch {
            throw NotificationLimitError.authorizationDenied
        }
    }

    /// Check if notifications are authorized
    func checkAuthorization() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Notification Scheduling

    /// Schedule notification with priority management
    func scheduleNotification(
        _ notification: ManagedNotification,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger
    ) async throws {
        // Check authorization
        guard await checkAuthorization() else {
            throw NotificationLimitError.authorizationDenied
        }

        // Update count
        await updateNotificationCount()

        // Check if we're at limit
        if currentCount >= maxNotifications {
            // Try cleanup first
            let removed = try await cleanupOldNotifications()

            if removed == 0 {
                // Still at limit, try removing low priority
                let lowPriorityRemoved = try await removeLowPriorityNotifications(toMakeRoom: 1)

                if lowPriorityRemoved == 0 {
                    throw NotificationLimitError.limitReached(
                        scheduled: currentCount,
                        limit: maxNotifications
                    )
                }
            }
        }

        // Check for auto-cleanup threshold
        if currentCount >= cleanupThreshold {
            _ = try await cleanupOldNotifications()
        }

        // Schedule the notification
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)

            // Track the notification
            managedNotifications[notification.id] = notification
            saveManagedNotifications()

            // Update count
            await updateNotificationCount()

        } catch {
            throw NotificationLimitError.schedulingFailed(underlying: error)
        }
    }

    // MARK: - Notification Removal

    /// Remove specific notification
    func removeNotification(identifier: String) async throws {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        managedNotifications.removeValue(forKey: identifier)
        saveManagedNotifications()

        await updateNotificationCount()
    }

    /// Remove notifications by category
    func removeNotifications(category: String) async throws -> Int {
        let toRemove = managedNotifications.values.filter { $0.category == category }
        let identifiers = toRemove.map { $0.id }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        for id in identifiers {
            managedNotifications.removeValue(forKey: id)
        }
        saveManagedNotifications()

        await updateNotificationCount()

        return identifiers.count
    }

    /// Remove notifications by priority
    func removeNotifications(priority: NotificationPriority) async throws -> Int {
        let toRemove = managedNotifications.values.filter { $0.priority == priority }
        let identifiers = toRemove.map { $0.id }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        for id in identifiers {
            managedNotifications.removeValue(forKey: id)
        }
        saveManagedNotifications()

        await updateNotificationCount()

        return identifiers.count
    }

    // MARK: - Cleanup

    /// Cleanup expired and old notifications
    func cleanupOldNotifications() async throws -> Int {
        var removedCount = 0

        // Get all pending notifications
        let pending = await notificationCenter.pendingNotificationRequests()
        let pendingIds = Set(pending.map { $0.identifier })

        // Remove notifications that are no longer pending
        let orphaned = managedNotifications.keys.filter { !pendingIds.contains($0) }
        for id in orphaned {
            managedNotifications.removeValue(forKey: id)
            removedCount += 1
        }

        // Remove expired notifications
        let expired = managedNotifications.values.filter { $0.isExpired }
        for notification in expired {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notification.id])
            managedNotifications.removeValue(forKey: notification.id)
            removedCount += 1
        }

        // Remove old low-priority notifications (older than 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let oldLowPriority = managedNotifications.values.filter {
            $0.priority == .low && $0.createdAt < thirtyDaysAgo
        }

        for notification in oldLowPriority {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notification.id])
            managedNotifications.removeValue(forKey: notification.id)
            removedCount += 1
        }

        if removedCount > 0 {
            saveManagedNotifications()
            await updateNotificationCount()
        }

        return removedCount
    }

    /// Remove low-priority notifications to make room
    private func removeLowPriorityNotifications(toMakeRoom needed: Int) async throws -> Int {
        let lowPriority = managedNotifications.values
            .filter { $0.priority == .low }
            .sorted { $0.createdAt < $1.createdAt } // Oldest first

        let toRemove = Array(lowPriority.prefix(needed))
        let identifiers = toRemove.map { $0.id }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        for id in identifiers {
            managedNotifications.removeValue(forKey: id)
        }

        if !identifiers.isEmpty {
            saveManagedNotifications()
            await updateNotificationCount()
        }

        return identifiers.count
    }

    // MARK: - Count Management

    /// Update current notification count
    func updateNotificationCount() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        currentCount = pending.count
        isNearLimit = currentCount >= warningThreshold

        // Sync managed notifications with actual pending
        let pendingIds = Set(pending.map { $0.identifier })
        let managedIds = Set(managedNotifications.keys)

        // Remove orphaned entries
        for id in managedIds where !pendingIds.contains(id) {
            managedNotifications.removeValue(forKey: id)
        }

        saveManagedNotifications()
    }

    /// Get available notification slots
    func getAvailableSlots() -> Int {
        return max(0, maxNotifications - currentCount)
    }

    // MARK: - Statistics

    /// Get notification statistics
    func getStatistics() async -> NotificationScheduleStatistics {
        await updateNotificationCount()

        var byPriority: [NotificationPriority: Int] = [:]
        var byCategory: [String: Int] = [:]
        var oldestDate: Date?
        var newestDate: Date?
        var expiredCount = 0

        for notification in managedNotifications.values {
            // Count by priority
            byPriority[notification.priority, default: 0] += 1

            // Count by category
            byCategory[notification.category, default: 0] += 1

            // Track dates
            if oldestDate == nil || notification.createdAt < oldestDate! {
                oldestDate = notification.createdAt
            }
            if newestDate == nil || notification.createdAt > newestDate! {
                newestDate = notification.createdAt
            }

            // Count expired
            if notification.isExpired {
                expiredCount += 1
            }
        }

        return NotificationScheduleStatistics(
            totalScheduled: currentCount,
            availableSlots: getAvailableSlots(),
            byPriority: byPriority,
            byCategory: byCategory,
            oldestNotification: oldestDate,
            newestNotification: newestDate,
            expiredCount: expiredCount,
            warningThreshold: warningThreshold
        )
    }

    /// Get managed notifications list
    func getManagedNotifications() -> [ManagedNotification] {
        return Array(managedNotifications.values).sorted { $0.fireDate < $1.fireDate }
    }

    /// Get notifications by priority
    func getNotifications(priority: NotificationPriority) -> [ManagedNotification] {
        return managedNotifications.values.filter { $0.priority == priority }
            .sorted { $0.fireDate < $1.fireDate }
    }

    /// Get notifications by category
    func getNotifications(category: String) -> [ManagedNotification] {
        return managedNotifications.values.filter { $0.category == category }
            .sorted { $0.fireDate < $1.fireDate }
    }

    // MARK: - Persistence

    private func saveManagedNotifications() {
        let notifications = Array(managedNotifications.values)

        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadManagedNotifications() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let notifications = try? JSONDecoder().decode([ManagedNotification].self, from: data) else {
            return
        }

        managedNotifications = Dictionary(uniqueKeysWithValues: notifications.map { ($0.id, $0) })
    }

    // MARK: - Cleanup All

    /// Remove all notifications
    func removeAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        managedNotifications.removeAll()
        saveManagedNotifications()
        await updateNotificationCount()
    }
}

// MARK: - Helper Extensions

extension NotificationLimitManager {

    /// Create a simple notification content
    static func createContent(
        title: String,
        body: String,
        sound: UNNotificationSound = .default,
        badge: NSNumber? = nil
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound

        if let badge = badge {
            content.badge = badge
        }

        return content
    }

    /// Create a date trigger
    static func createDateTrigger(fireDate: Date, repeats: Bool = false) -> UNCalendarNotificationTrigger {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    }

    /// Create an interval trigger
    static func createIntervalTrigger(interval: TimeInterval, repeats: Bool = false) -> UNTimeIntervalNotificationTrigger {
        return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Schedule a notification with priority:
 ```swift
 let manager = NotificationLimitManager.shared

 // Create managed notification
 let notification = ManagedNotification(
     id: UUID().uuidString,
     title: "Subscription Due",
     body: "Netflix payment due tomorrow",
     fireDate: Date().addingTimeInterval(86400),
     priority: .high,
     category: "subscription"
 )

 // Create content and trigger
 let content = NotificationLimitManager.createContent(
     title: notification.title,
     body: notification.body
 )

 let trigger = NotificationLimitManager.createDateTrigger(
     fireDate: notification.fireDate
 )

 // Schedule
 do {
     try await manager.scheduleNotification(notification, content: content, trigger: trigger)
 } catch NotificationLimitError.limitReached(let count, let limit) {
     print("Limit reached: \(count)/\(limit)")
 } catch {
     print("Error: \(error.localizedDescription)")
 }
 ```

 2. Check notification count and cleanup:
 ```swift
 await manager.updateNotificationCount()

 if manager.isNearLimit {
     print("⚠️ Near notification limit!")

     // Cleanup old notifications
     let removed = try await manager.cleanupOldNotifications()
     print("Removed \(removed) old notifications")
 }
 ```

 3. Get statistics:
 ```swift
 let stats = await manager.getStatistics()
 print(stats.summary)
 ```

 4. Remove notifications by category:
 ```swift
 let removed = try await manager.removeNotifications(category: "subscription")
 print("Removed \(removed) subscription notifications")
 ```

 5. Monitor notification count in SwiftUI:
 ```swift
 struct NotificationView: View {
     @StateObject private var manager = NotificationLimitManager.shared

     var body: some View {
         VStack {
             Text("Notifications: \(manager.currentCount)/64")

             if manager.isNearLimit {
                 Text("⚠️ Near Limit")
                     .foregroundColor(.red)
             }
         }
     }
 }
 ```
 */
