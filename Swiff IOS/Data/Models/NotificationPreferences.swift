//
//  NotificationPreferences.swift
//  Swiff IOS
//
//  Created by Agent on 1/19/26.
//  Moved from SupportingTypes.swift to resolve isolation issues
//

import Foundation

// MARK: - Person Notification Types

/// Contact method for notifications to a person
public enum ContactMethod: String, CaseIterable, Codable, Sendable {
    case inApp = "In-App"
    case email = "Email"
    case sms = "SMS"
    case whatsapp = "WhatsApp"

    var icon: String {
        switch self {
        case .inApp: return "app.badge"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .whatsapp: return "message.badge.filled.fill"
        }
    }
}

/// Notification preferences for a person
public struct NotificationPreferences: Codable, Equatable, Sendable {
    public var enableReminders: Bool
    public var reminderFrequency: Int  // days between reminders
    public var preferredContactMethod: ContactMethod

    public init(
        enableReminders: Bool = true,
        reminderFrequency: Int = 7,
        preferredContactMethod: ContactMethod = .inApp
    ) {
        self.enableReminders = enableReminders
        self.reminderFrequency = reminderFrequency
        self.preferredContactMethod = preferredContactMethod
    }
}
