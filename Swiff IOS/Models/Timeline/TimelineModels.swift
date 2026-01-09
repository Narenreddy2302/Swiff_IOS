//
//  TimelineModels.swift
//  Swiff IOS
//
//  Created for SWIFF iOS Timeline/Conversation UI Redesign
//  Data models and supporting types for unified timeline components
//

import SwiftUI

// MARK: - Timeline Icon Type

enum TimelineIconType {
    case message    // Gray - general messages, notes
    case payment    // Green - completed payments, settlements
    case request    // Orange - pending requests, action needed
    case expense    // Red - expenses, charges
    case system     // Blue - member events, system notifications
    case paidBillSystem  // Gray checkmark - paid bill confirmation

    var color: Color {
        switch self {
        case .message: return .wiseSecondaryText
        case .payment: return .wiseBrightGreen
        case .request: return .wiseWarning
        case .expense: return .wiseError
        case .system: return .wiseBlue
        case .paidBillSystem: return .wiseBorder
        }
    }

    var backgroundColor: Color {
        switch self {
        case .message: return .wiseBorder
        case .payment: return .wiseBrightGreen
        case .request: return .wiseWarning
        case .expense: return .wiseError
        case .system: return .wiseBlue
        case .paidBillSystem: return .wiseBorder
        }
    }

    var iconColor: Color {
        switch self {
        case .message, .paidBillSystem: return .wiseSecondaryText
        case .payment, .request, .expense, .system: return .white
        }
    }

    var icon: String {
        switch self {
        case .message: return "bubble.left.fill"
        case .payment: return "checkmark"
        case .request: return "exclamationmark.circle.fill"
        case .expense: return "creditcard.fill"
        case .system: return "info.circle.fill"
        case .paidBillSystem: return "checkmark"
        }
    }
}

// MARK: - Timeline Item Protocol

protocol TimelineItemProtocol: Identifiable {
    var id: UUID { get }
    var timestamp: Date { get }
    var timelineIconType: TimelineIconType { get }
}

// MARK: - Person Timeline Item

enum PersonTimelineItem: TimelineItemProtocol {
    case transaction(Transaction, Person)
    case payment(id: UUID, amount: Double, direction: PaymentDirection, description: String, date: Date)
    case paidBill(id: UUID, personName: String, date: Date)
    case settlement(id: UUID, date: Date)
    case reminder(id: UUID, date: Date)
    case message(id: UUID, text: String, isFromPerson: Bool, date: Date)
    case splitRequest(id: UUID, title: String, message: String?, billTotal: Double, paidBy: String, youOwe: Double, date: Date)

    var id: UUID {
        switch self {
        case .transaction(let t, _): return t.id
        case .payment(let id, _, _, _, _): return id
        case .paidBill(let id, _, _): return id
        case .settlement(let id, _): return id
        case .reminder(let id, _): return id
        case .message(let id, _, _, _): return id
        case .splitRequest(let id, _, _, _, _, _, _): return id
        }
    }

    var timestamp: Date {
        switch self {
        case .transaction(let t, _): return t.date
        case .payment(_, _, _, _, let date): return date
        case .paidBill(_, _, let date): return date
        case .settlement(_, let date): return date
        case .reminder(_, let date): return date
        case .message(_, _, _, let date): return date
        case .splitRequest(_, _, _, _, _, _, let date): return date
        }
    }

    var timelineIconType: TimelineIconType {
        switch self {
        case .transaction(let t, _):
            return t.isExpense ? .expense : .payment
        case .payment:
            return .payment
        case .paidBill:
            return .paidBillSystem
        case .settlement:
            return .system
        case .reminder:
            return .request
        case .message:
            return .message
        case .splitRequest:
            return .request
        }
    }
}

enum PaymentDirection {
    case incoming  // Money received
    case outgoing  // Money sent
}

// MARK: - Group Timeline Item

enum GroupTimelineItem: TimelineItemProtocol {
    case expense(GroupExpense, payer: Person?, splitMembers: [Person])
    case memberJoined(id: UUID, person: Person, date: Date)
    case memberLeft(id: UUID, person: Person, date: Date)
    case settlement(id: UUID, expense: GroupExpense, date: Date)
    case splitBillCreated(SplitBill)
    case textMessage(ConversationMessage, senderName: String?)  // Text message in group chat

    var id: UUID {
        switch self {
        case .expense(let e, _, _): return e.id
        case .memberJoined(let id, _, _): return id
        case .memberLeft(let id, _, _): return id
        case .settlement(let id, _, _): return id
        case .splitBillCreated(let sb): return sb.id
        case .textMessage(let message, _): return message.id
        }
    }

    var timestamp: Date {
        switch self {
        case .expense(let e, _, _): return e.date
        case .memberJoined(_, _, let date): return date
        case .memberLeft(_, _, let date): return date
        case .settlement(_, _, let date): return date
        case .splitBillCreated(let sb): return sb.date
        case .textMessage(let message, _): return message.timestamp
        }
    }

    var timelineIconType: TimelineIconType {
        switch self {
        case .expense: return .expense
        case .memberJoined: return .system
        case .memberLeft: return .system
        case .settlement: return .payment
        case .splitBillCreated: return .request
        case .textMessage: return .message
        }
    }
}

// MARK: - Contact Timeline Item

enum ContactTimelineItem: TimelineItemProtocol {
    case due(SplitBill, isTheyOweMe: Bool)  // Due transaction (they owe me = positive, I owe them = negative)
    case settlement(id: UUID, amount: Double, date: Date)  // Settlement/payment
    case textMessage(ConversationMessage)  // Text message in conversation

    var id: UUID {
        switch self {
        case .due(let splitBill, _): return splitBill.id
        case .settlement(let id, _, _): return id
        case .textMessage(let message): return message.id
        }
    }

    var timestamp: Date {
        switch self {
        case .due(let splitBill, _): return splitBill.date
        case .settlement(_, _, let date): return date
        case .textMessage(let message): return message.timestamp
        }
    }

    var timelineIconType: TimelineIconType {
        switch self {
        case .due(_, let isTheyOweMe):
            return isTheyOweMe ? .payment : .expense
        case .settlement:
            return .payment
        case .textMessage:
            return .message
        }
    }

    /// Get the amount for display
    var amount: Double {
        switch self {
        case .due(let splitBill, _):
            return splitBill.totalAmount
        case .settlement(_, let amount, _):
            return amount
        case .textMessage:
            return 0  // Messages don't have amounts
        }
    }

    /// Get the description for display
    var displayDescription: String {
        switch self {
        case .due(let splitBill, _):
            return splitBill.title
        case .settlement:
            return "Payment received"
        case .textMessage(let message):
            return message.content
        }
    }

    /// Check if this represents money coming to the user (they owe me)
    var isIncoming: Bool {
        switch self {
        case .due(_, let isTheyOweMe):
            return isTheyOweMe
        case .settlement:
            return true  // Settlements are always incoming (money received)
        case .textMessage(let message):
            return !message.isSent  // Incoming if not sent by current user
        }
    }
}

// MARK: - Subscription Timeline Item

enum SubscriptionTimelineItem: TimelineItemProtocol {
    case billingCharged(id: UUID, amount: Double, date: Date)
    case billingUpcoming(id: UUID, amount: Double, dueDate: Date, date: Date)
    case priceChange(id: UUID, oldPrice: Double, newPrice: Double, date: Date)
    case trialStarted(id: UUID, trialEndDate: Date, date: Date)
    case trialEnding(id: UUID, daysLeft: Int, priceAfterTrial: Double, date: Date)
    case trialConverted(id: UUID, newPrice: Double, date: Date)
    case subscriptionCreated(id: UUID, subscriptionName: String, date: Date)
    case subscriptionPaused(id: UUID, date: Date)
    case subscriptionResumed(id: UUID, date: Date)
    case subscriptionCancelled(id: UUID, date: Date)
    case usageRecorded(id: UUID, date: Date)
    case reminderSent(id: UUID, date: Date)
    case memberAdded(id: UUID, personName: String, date: Date)
    case memberRemoved(id: UUID, personName: String, date: Date)
    case memberPaid(id: UUID, personName: String, amount: Double, date: Date)

    var id: UUID {
        switch self {
        case .billingCharged(let id, _, _): return id
        case .billingUpcoming(let id, _, _, _): return id
        case .priceChange(let id, _, _, _): return id
        case .trialStarted(let id, _, _): return id
        case .trialEnding(let id, _, _, _): return id
        case .trialConverted(let id, _, _): return id
        case .subscriptionCreated(let id, _, _): return id
        case .subscriptionPaused(let id, _): return id
        case .subscriptionResumed(let id, _): return id
        case .subscriptionCancelled(let id, _): return id
        case .usageRecorded(let id, _): return id
        case .reminderSent(let id, _): return id
        case .memberAdded(let id, _, _): return id
        case .memberRemoved(let id, _, _): return id
        case .memberPaid(let id, _, _, _): return id
        }
    }

    var timestamp: Date {
        switch self {
        case .billingCharged(_, _, let date): return date
        case .billingUpcoming(_, _, _, let date): return date
        case .priceChange(_, _, _, let date): return date
        case .trialStarted(_, _, let date): return date
        case .trialEnding(_, _, _, let date): return date
        case .trialConverted(_, _, let date): return date
        case .subscriptionCreated(_, _, let date): return date
        case .subscriptionPaused(_, let date): return date
        case .subscriptionResumed(_, let date): return date
        case .subscriptionCancelled(_, let date): return date
        case .usageRecorded(_, let date): return date
        case .reminderSent(_, let date): return date
        case .memberAdded(_, _, let date): return date
        case .memberRemoved(_, _, let date): return date
        case .memberPaid(_, _, _, let date): return date
        }
    }

    var timelineIconType: TimelineIconType {
        switch self {
        case .billingCharged: return .expense
        case .billingUpcoming: return .request
        case .priceChange(_, let oldPrice, let newPrice, _):
            return newPrice > oldPrice ? .request : .payment
        case .trialStarted: return .system
        case .trialEnding: return .system
        case .trialConverted: return .system
        case .subscriptionCreated: return .system
        case .subscriptionPaused: return .system
        case .subscriptionResumed: return .system
        case .subscriptionCancelled: return .system
        case .usageRecorded: return .payment
        case .reminderSent: return .request
        case .memberAdded: return .system
        case .memberRemoved: return .system
        case .memberPaid: return .system
        }
    }
}

// MARK: - Empty State Configuration

struct TimelineEmptyStateConfig {
    let icon: String
    let title: String
    let subtitle: String
}

// MARK: - Status Banner Configuration

struct StatusBannerConfig {
    let pendingCount: Int
    let totalAmount: Double
    let isUserOwing: Bool  // true = you owe, false = owed to you
    let personName: String?  // Optional name for personalized message

    init(pendingCount: Int, totalAmount: Double, isUserOwing: Bool, personName: String? = nil) {
        self.pendingCount = pendingCount
        self.totalAmount = totalAmount
        self.isUserOwing = isUserOwing
        self.personName = personName
    }

    var isEmpty: Bool {
        pendingCount == 0 && totalAmount == 0
    }
}

// MARK: - Input Area Configuration

struct TimelineInputAreaConfig {
    let quickActionTitle: String
    let quickActionIcon: String
    let placeholder: String
    let showMessageField: Bool
}
