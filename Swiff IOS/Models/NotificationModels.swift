//
//  NotificationModels.swift
//  Swiff IOS
//
//  Created by Agent 7 on 11/21/25.
//  Models for notification tracking and history
//

import Foundation
import Combine

// MARK: - AGENT 7: Notification Models

/// Types of notifications supported
enum NotificationType: String, Codable, CaseIterable {
    case renewal = "Renewal Reminder"
    case trial = "Trial Expiration"
    case priceChange = "Price Change"
    case unused = "Unused Subscription"
    case payment = "Payment Reminder"
    case test = "Test Notification"

    var icon: String {
        switch self {
        case .renewal: return "arrow.clockwise.circle.fill"
        case .trial: return "gift.fill"
        case .priceChange: return "dollarsign.circle.fill"
        case .unused: return "exclamationmark.triangle.fill"
        case .payment: return "creditcard.fill"
        case .test: return "bell.fill"
        }
    }

    var color: String {
        switch self {
        case .renewal: return "#007AFF"
        case .trial: return "#FF9500"
        case .priceChange: return "#FF3B30"
        case .unused: return "#FFCC00"
        case .payment: return "#34C759"
        case .test: return "#8E8E93"
        }
    }
}

/// Action taken on a notification
enum NotificationAction: String, Codable {
    case viewed = "Viewed"
    case snoozed = "Snoozed"
    case dismissed = "Dismissed"
    case cancelledSubscription = "Cancelled Subscription"
    case markedAsUsing = "Marked as Using"
    case none = "No Action"
}

/// Scheduled reminder record
// Note: ScheduledReminder is defined in ReminderModels.swift

/// Filter options for notification history
enum NotificationHistoryFilter: String, CaseIterable {
    case all = "All"
    case renewal = "Renewals"
    case trial = "Trials"
    case priceChange = "Price Changes"
    case unused = "Unused"
    case payment = "Payment"
    
    var icon: String {
        switch self {
        case .all: return "bell.fill"
        case .renewal: return "arrow.clockwise.circle.fill"
        case .trial: return "gift.fill"
        case .priceChange: return "dollarsign.circle.fill"
        case .unused: return "exclamationmark.triangle.fill"
        case .payment: return "creditcard.fill"
        }
    }
    
    func matches(_ type: NotificationType) -> Bool {
        switch self {
        case .all:
            return true
        case .renewal:
            return type == .renewal
        case .trial:
            return type == .trial
        case .priceChange:
            return type == .priceChange
        case .unused:
            return type == .unused
        case .payment:
            return type == .payment
        }
    }
}

/// Notification history entry
struct NotificationHistoryEntry: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let title: String
    let body: String
    let sentDate: Date
    var wasOpened: Bool
    var openedDate: Date?
    var action: NotificationAction
    var actionDate: Date?
    let subscriptionId: UUID?
    let subscriptionName: String?
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        body: String,
        sentDate: Date = Date(),
        wasOpened: Bool = false,
        openedDate: Date? = nil,
        action: NotificationAction = .none,
        actionDate: Date? = nil,
        subscriptionId: UUID? = nil,
        subscriptionName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.sentDate = sentDate
        self.wasOpened = wasOpened
        self.openedDate = openedDate
        self.action = action
        self.actionDate = actionDate
        self.subscriptionId = subscriptionId
        self.subscriptionName = subscriptionName
    }
    
    mutating func markAsOpened() {
        wasOpened = true
        openedDate = Date()
    }
    
    mutating func recordAction(_ newAction: NotificationAction) {
        action = newAction
        actionDate = Date()
    }
}

/// Statistics for notification tracking
struct NotificationStatistics {
    var totalSent: Int = 0
    var totalOpened: Int = 0
    var renewalsSent: Int = 0
    var trialsSent: Int = 0
    var priceChangesSent: Int = 0
    var unusedAlertsSent: Int = 0
    var paymentsSent: Int = 0
    
    var openRate: Double {
        guard totalSent > 0 else { return 0 }
        return Double(totalOpened) / Double(totalSent) * 100
    }
}

