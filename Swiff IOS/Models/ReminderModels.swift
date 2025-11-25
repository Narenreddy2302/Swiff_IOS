//
//  ReminderModels.swift
//  Swiff IOS
//
//  Created by Agent 14 on 11/21/25.
//  Reminder data models and supporting types for ReminderService
//

import Foundation
import SwiftUI
import Combine

// MARK: - Reminder Types

/// Type of reminder
enum ReminderType: String, CaseIterable, Codable {
    case renewal = "Renewal"
    case trialExpiration = "Trial Expiration"
    case priceChange = "Price Change"
    case unused = "Unused Subscription"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .renewal: return "arrow.clockwise.circle.fill"
        case .trialExpiration: return "gift.circle.fill"
        case .priceChange: return "dollarsign.circle.fill"
        case .unused: return "exclamationmark.circle.fill"
        case .custom: return "bell.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .renewal: return .wiseBlue
        case .trialExpiration: return .wiseAccentOrange
        case .priceChange: return .wiseError
        case .unused: return Color(red: 1.0, green: 0.800, blue: 0.0) // Yellow
        case .custom: return .wiseForestGreen
        }
    }

    var priority: ReminderPriority {
        switch self {
        case .renewal: return .medium
        case .trialExpiration: return .high
        case .priceChange: return .high
        case .unused: return .low
        case .custom: return .medium
        }
    }
}

/// Reminder status
enum ReminderStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case sent = "Sent"
    case snoozed = "Snoozed"
    case dismissed = "Dismissed"
    case failed = "Failed"

    var icon: String {
        switch self {
        case .scheduled: return "clock.circle.fill"
        case .sent: return "checkmark.circle.fill"
        case .snoozed: return "moon.circle.fill"
        case .dismissed: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .scheduled: return .wiseBlue
        case .sent: return .wiseBrightGreen
        case .snoozed: return .wiseSecondaryText
        case .dismissed: return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        case .failed: return .wiseError
        }
    }
}

/// Reminder priority
enum ReminderPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var badgeColor: Color {
        switch self {
        case .low: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .medium: return .wiseBlue
        case .high: return .wiseAccentOrange
        case .urgent: return .wiseError
        }
    }
}

// MARK: - Reminder Models

/// Scheduled reminder
struct ScheduledReminder: Identifiable, Codable {
    let id: String // Notification identifier
    let subscriptionId: UUID
    let type: ReminderType
    let scheduledDate: Date
    var status: ReminderStatus
    var priority: ReminderPriority
    var message: String
    var snoozedUntil: Date?
    let createdDate: Date

    init(
        id: String,
        subscriptionId: UUID,
        type: ReminderType,
        scheduledDate: Date,
        status: ReminderStatus = .scheduled,
        priority: ReminderPriority? = nil,
        message: String
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.type = type
        self.scheduledDate = scheduledDate
        self.status = status
        self.priority = priority ?? type.priority
        self.message = message
        self.snoozedUntil = nil
        self.createdDate = Date()
    }

    var isSnoozed: Bool {
        status == .snoozed
    }

    var isPending: Bool {
        status == .scheduled && scheduledDate > Date()
    }

    var isOverdue: Bool {
        status == .scheduled && scheduledDate <= Date()
    }
}

/// Reminder preferences
struct ReminderPreferences: Codable {
    var enabledReminderTypes: Set<ReminderType>
    var defaultDaysBefore: Int
    var defaultTime: Date // Time of day for reminders
    var enableQuietHours: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date
    var enableBatchNotifications: Bool
    var maxDailyReminders: Int

    init() {
        self.enabledReminderTypes = Set(ReminderType.allCases)
        self.defaultDaysBefore = 3
        // Set default time to 9:00 AM
        var components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        components.hour = 9
        components.minute = 0
        self.defaultTime = Calendar.current.date(from: components) ?? Date()
        self.enableQuietHours = false
        // Quiet hours: 10 PM to 8 AM
        var startComponents = DateComponents()
        startComponents.hour = 22
        startComponents.minute = 0
        self.quietHoursStart = Calendar.current.date(from: startComponents) ?? Date()
        var endComponents = DateComponents()
        endComponents.hour = 8
        endComponents.minute = 0
        self.quietHoursEnd = Calendar.current.date(from: endComponents) ?? Date()
        self.enableBatchNotifications = true
        self.maxDailyReminders = 10
    }
}

/// Reminder history entry
struct ReminderHistoryEntry: Identifiable, Codable {
    let id: UUID
    let reminderId: String
    let subscriptionId: UUID
    let type: ReminderType
    let action: ReminderAction
    let timestamp: Date
    let note: String?

    init(reminderId: String, subscriptionId: UUID, type: ReminderType, action: ReminderAction, note: String? = nil) {
        self.id = UUID()
        self.reminderId = reminderId
        self.subscriptionId = subscriptionId
        self.type = type
        self.action = action
        self.timestamp = Date()
        self.note = note
    }
}

/// Reminder action
enum ReminderAction: String, Codable {
    case created = "Created"
    case scheduled = "Scheduled"
    case sent = "Sent"
    case snoozed = "Snoozed"
    case dismissed = "Dismissed"
    case cancelled = "Cancelled"
    case failed = "Failed"
}

/// Snooze option
enum SnoozeOption: String, CaseIterable {
    case fifteenMinutes = "15 minutes"
    case oneHour = "1 hour"
    case threeHours = "3 hours"
    case tomorrow = "Tomorrow"
    case nextWeek = "Next week"
    case custom = "Custom"

    var duration: TimeInterval {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .oneHour: return 60 * 60
        case .threeHours: return 3 * 60 * 60
        case .tomorrow: return 24 * 60 * 60
        case .nextWeek: return 7 * 24 * 60 * 60
        case .custom: return 0
        }
    }

    func calculateSnoozeDate(from date: Date = Date()) -> Date {
        switch self {
        case .custom:
            return date
        case .tomorrow:
            // Tomorrow at 9 AM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.day! += 1
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? date.addingTimeInterval(duration)
        case .nextWeek:
            // Next week same day at 9 AM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.day! += 7
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? date.addingTimeInterval(duration)
        default:
            return date.addingTimeInterval(duration)
        }
    }
}

/// Reminder batch
struct ReminderBatch: Identifiable, Codable {
    let id: UUID
    let date: Date
    let reminders: [ScheduledReminder]
    let totalCount: Int
    var isDismissed: Bool

    init(date: Date, reminders: [ScheduledReminder]) {
        self.id = UUID()
        self.date = date
        self.reminders = reminders
        self.totalCount = reminders.count
        self.isDismissed = false
    }

    var highPriorityCount: Int {
        reminders.filter { $0.priority == .high || $0.priority == .urgent }.count
    }
}

// MARK: - Reminder Statistics

/// Reminder statistics
struct ReminderStatistics: Codable {
    let totalScheduled: Int
    let totalSent: Int
    let totalSnoozed: Int
    let totalDismissed: Int
    let upcomingToday: Int
    let upcomingWeek: Int
    let overdueCount: Int
    let successRate: Double // Percentage of reminders successfully sent

    init(
        totalScheduled: Int = 0,
        totalSent: Int = 0,
        totalSnoozed: Int = 0,
        totalDismissed: Int = 0,
        upcomingToday: Int = 0,
        upcomingWeek: Int = 0,
        overdueCount: Int = 0
    ) {
        self.totalScheduled = totalScheduled
        self.totalSent = totalSent
        self.totalSnoozed = totalSnoozed
        self.totalDismissed = totalDismissed
        self.upcomingToday = upcomingToday
        self.upcomingWeek = upcomingWeek
        self.overdueCount = overdueCount

        // Calculate success rate
        let total = totalScheduled + totalSent
        self.successRate = total > 0 ? (Double(totalSent) / Double(total)) * 100 : 0
    }
}
