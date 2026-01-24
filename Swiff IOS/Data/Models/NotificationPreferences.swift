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
public struct NotificationPreferences: Equatable, Sendable {
    public var enableReminders: Bool
    public var reminderFrequency: Int  // days between reminders
    public var preferredContactMethod: ContactMethod

    public nonisolated init(
        enableReminders: Bool = true,
        reminderFrequency: Int = 7,
        preferredContactMethod: ContactMethod = .inApp
    ) {
        self.enableReminders = enableReminders
        self.reminderFrequency = reminderFrequency
        self.preferredContactMethod = preferredContactMethod
    }
}

// MARK: - Codable Conformance

// MARK: - Codable Conformance (Explicit Nonisolated)

extension NotificationPreferences: Codable {
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.enableReminders = try container.decode(Bool.self, forKey: .enableReminders)
        self.reminderFrequency = try container.decode(Int.self, forKey: .reminderFrequency)
        self.preferredContactMethod = try container.decode(
            ContactMethod.self, forKey: .preferredContactMethod)
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enableReminders, forKey: .enableReminders)
        try container.encode(reminderFrequency, forKey: .reminderFrequency)
        try container.encode(preferredContactMethod, forKey: .preferredContactMethod)
    }

    enum CodingKeys: String, CodingKey {
        case enableReminders
        case reminderFrequency
        case preferredContactMethod
    }
}
