//
//  SubscriptionEvent.swift
//  Swiff IOS
//
//  Subscription timeline event model for conversation-style timeline view
//

import Foundation
import SwiftUI

// MARK: - Subscription Event Type

enum SubscriptionEventType: String, Codable {
    case billingCharged
    case billingUpcoming
    case priceIncrease
    case priceDecrease
    case trialStarted
    case trialEnding
    case trialConverted
    case subscriptionCreated
    case subscriptionPaused
    case subscriptionResumed
    case subscriptionCancelled
    case usageRecorded
    case reminderSent
    case memberAdded
    case memberRemoved
    case memberPaid

    var icon: String {
        switch self {
        case .billingCharged:
            return "creditcard.fill"
        case .billingUpcoming:
            return "calendar.badge.clock"
        case .priceIncrease:
            return "arrow.up.circle.fill"
        case .priceDecrease:
            return "arrow.down.circle.fill"
        case .trialStarted:
            return "gift.fill"
        case .trialEnding:
            return "clock.badge.exclamationmark"
        case .trialConverted:
            return "checkmark.circle.fill"
        case .subscriptionCreated:
            return "plus.circle.fill"
        case .subscriptionPaused:
            return "pause.circle.fill"
        case .subscriptionResumed:
            return "play.circle.fill"
        case .subscriptionCancelled:
            return "xmark.circle.fill"
        case .usageRecorded:
            return "checkmark.square.fill"
        case .reminderSent:
            return "bell.fill"
        case .memberAdded:
            return "person.badge.plus"
        case .memberRemoved:
            return "person.badge.minus"
        case .memberPaid:
            return "person.crop.circle.badge.checkmark"
        }
    }

    var color: Color {
        switch self {
        case .billingCharged:
            return AmountColors.negative
        case .billingUpcoming:
            return .wiseBlue
        case .priceIncrease:
            return .wiseWarning
        case .priceDecrease:
            return .wiseBrightGreen
        case .trialStarted:
            return .wisePurple
        case .trialEnding:
            return .wiseWarning
        case .trialConverted:
            return .wiseBrightGreen
        case .subscriptionCreated:
            return .wiseBrightGreen
        case .subscriptionPaused:
            return .wiseWarning
        case .subscriptionResumed:
            return .wiseBrightGreen
        case .subscriptionCancelled:
            return .wiseError
        case .usageRecorded:
            return .wiseBrightGreen
        case .reminderSent:
            return .wiseBlue
        case .memberAdded:
            return .wisePurple
        case .memberRemoved:
            return .wiseSecondaryText
        case .memberPaid:
            return .wiseBrightGreen
        }
    }

    var bubbleType: BubbleType {
        switch self {
        case .billingCharged:
            return .outgoing // Money going out (right-aligned)
        case .priceIncrease, .priceDecrease:
            return .incoming // Price changes (left-aligned)
        case .memberAdded, .memberRemoved, .memberPaid:
            return .incoming // Member activity (left-aligned)
        default:
            return .systemEvent // System events (centered)
        }
    }
}

// MARK: - Subscription Event

struct SubscriptionEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var subscriptionId: UUID
    var eventType: SubscriptionEventType
    var eventDate: Date
    var title: String
    var subtitle: String?
    var amount: Double?
    var metadata: [String: String]
    var isSystemMessage: Bool
    var relatedPersonId: UUID?

    init(
        id: UUID = UUID(),
        subscriptionId: UUID,
        eventType: SubscriptionEventType,
        eventDate: Date,
        title: String,
        subtitle: String? = nil,
        amount: Double? = nil,
        metadata: [String: String] = [:],
        isSystemMessage: Bool = false,
        relatedPersonId: UUID? = nil
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.eventType = eventType
        self.eventDate = eventDate
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.metadata = metadata
        self.isSystemMessage = isSystemMessage
        self.relatedPersonId = relatedPersonId
    }

    // MARK: - Computed Properties

    var formattedAmount: String? {
        guard let amount = amount else { return nil }
        let sign = eventType == .billingCharged ? "-" : (amount > 0 ? "+" : "")
        return String(format: "%@ $%.2f", sign, abs(amount))
    }

    var amountColor: Color {
        switch eventType {
        case .billingCharged:
            return AmountColors.negative
        case .priceDecrease, .memberPaid:
            return AmountColors.positive
        case .priceIncrease:
            return AmountColors.negative
        default:
            return .wisePrimaryText
        }
    }

    var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(eventDate) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: eventDate)
        } else if calendar.isDateInYesterday(eventDate) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: eventDate, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: eventDate)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: eventDate)
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eventDate)
    }

    /// Get the date section header (e.g., "Today", "Yesterday", "Dec 15")
    static func sectionDate(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    /// Group events by date
    static func groupByDate(_ events: [SubscriptionEvent]) -> [(date: Date, events: [SubscriptionEvent])] {
        let calendar = Calendar.current

        // Group by start of day
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.eventDate)
        }

        // Sort by date descending (newest first)
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, events: $0.value.sorted { $0.eventDate > $1.eventDate }) }
    }
}
