//
//  SystemEventRow.swift
//  Swiff IOS
//
//  System event notification component for conversation views
//  Displays join/leave, settlement, and status change events
//

import SwiftUI

// MARK: - System Event Type

enum SystemEventType {
    // Person events
    case paymentReceived(amount: Double)
    case paymentSent(amount: Double)
    case balanceSettled
    case reminderSent

    // Group events
    case memberJoined(name: String)
    case memberLeft(name: String)
    case expenseSettled(amount: Double)
    case groupCreated
    case expenseAdded(title: String)

    // Subscription events
    case billingCharged(amount: Double)
    case priceChanged(oldPrice: Double, newPrice: Double)
    case trialStarted(days: Int)
    case trialEnding(days: Int)
    case subscriptionPaused
    case subscriptionResumed
    case subscriptionCancelled
    case memberAddedToSubscription(name: String)
    case memberRemovedFromSubscription(name: String)

    var icon: String {
        switch self {
        case .paymentReceived: return "arrow.down.circle.fill"
        case .paymentSent: return "arrow.up.circle.fill"
        case .balanceSettled: return "checkmark.circle.fill"
        case .reminderSent: return "bell.fill"
        case .memberJoined: return "person.badge.plus"
        case .memberLeft: return "person.badge.minus"
        case .expenseSettled: return "checkmark.circle.fill"
        case .groupCreated: return "person.3.fill"
        case .expenseAdded: return "plus.circle.fill"
        case .billingCharged: return "creditcard.fill"
        case .priceChanged: return "arrow.up.arrow.down.circle.fill"
        case .trialStarted: return "gift.fill"
        case .trialEnding: return "clock.fill"
        case .subscriptionPaused: return "pause.circle.fill"
        case .subscriptionResumed: return "play.circle.fill"
        case .subscriptionCancelled: return "xmark.circle.fill"
        case .memberAddedToSubscription: return "person.badge.plus"
        case .memberRemovedFromSubscription: return "person.badge.minus"
        }
    }

    var iconColor: Color {
        switch self {
        case .paymentReceived, .balanceSettled, .expenseSettled, .subscriptionResumed:
            return .wiseBrightGreen
        case .paymentSent:
            return AmountColors.negative
        case .reminderSent, .trialEnding:
            return .wiseWarning
        case .memberJoined, .groupCreated, .trialStarted, .memberAddedToSubscription:
            return .wiseBlue
        case .memberLeft, .subscriptionCancelled, .memberRemovedFromSubscription:
            return .wiseError
        case .expenseAdded:
            return .wisePurple
        case .billingCharged:
            return .wiseSecondaryText
        case .priceChanged:
            return .wiseWarning
        case .subscriptionPaused:
            return .wiseSecondaryText
        }
    }

    var text: String {
        switch self {
        case .paymentReceived(let amount):
            return "Received \(formatCurrency(amount))"
        case .paymentSent(let amount):
            return "Sent \(formatCurrency(amount))"
        case .balanceSettled:
            return "Balance settled"
        case .reminderSent:
            return "Reminder sent"
        case .memberJoined(let name):
            return "\(name) joined the group"
        case .memberLeft(let name):
            return "\(name) left the group"
        case .expenseSettled(let amount):
            return "Expense settled: \(formatCurrency(amount))"
        case .groupCreated:
            return "Group created"
        case .expenseAdded(let title):
            return "Expense added: \(title)"
        case .billingCharged(let amount):
            return "Charged \(formatCurrency(amount))"
        case .priceChanged(let oldPrice, let newPrice):
            let change = newPrice > oldPrice ? "increased" : "decreased"
            return "Price \(change) to \(formatCurrency(newPrice))"
        case .trialStarted(let days):
            return "Free trial started (\(days) days)"
        case .trialEnding(let days):
            return "Trial ending in \(days) day\(days == 1 ? "" : "s")"
        case .subscriptionPaused:
            return "Subscription paused"
        case .subscriptionResumed:
            return "Subscription resumed"
        case .subscriptionCancelled:
            return "Subscription cancelled"
        case .memberAddedToSubscription(let name):
            return "\(name) added to subscription"
        case .memberRemovedFromSubscription(let name):
            return "\(name) removed from subscription"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - System Event Row

struct SystemEventRow: View {
    let eventType: SystemEventType
    let timestamp: Date
    var showTimestamp: Bool = true

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    // Only show icon for important events to reduce noise
                    if shouldShowIcon {
                        Image(systemName: eventType.icon)
                            .font(Theme.Fonts.eventText)
                            .foregroundColor(eventType.iconColor)
                    }

                    Text(eventType.text)
                        .font(Theme.Fonts.eventText)
                        .foregroundColor(.wiseSecondaryText)
                }

                if showTimestamp {
                    Text(relativeTime)
                        .font(Theme.Fonts.eventTimestamp)
                        .foregroundColor(.wiseTertiaryText)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(eventType.text), \(relativeTime)")

            Spacer()
        }
    }

    private var shouldShowIcon: Bool {
        // Only show icons for things that need visual distinction
        switch eventType {
        case .paymentReceived, .paymentSent, .memberJoined:
            return true
        default:
            return false
        }
    }
}

// MARK: - Compact System Event (Inline)

struct CompactSystemEvent: View {
    let eventType: SystemEventType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: eventType.icon)
                .font(Theme.Fonts.badgeText)
                .foregroundColor(eventType.iconColor)

            Text(eventType.text)
                .font(Theme.Fonts.captionSmall)
                .foregroundColor(.wiseSecondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(eventType.text)
    }
}

// MARK: - Preview

#Preview("System Events") {
    ScrollView {
        VStack(spacing: 14) {
            Text("Person Events")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            SystemEventRow(
                eventType: .paymentReceived(amount: 125.50),
                timestamp: Date().addingTimeInterval(-3600)
            )

            SystemEventRow(
                eventType: .balanceSettled,
                timestamp: Date().addingTimeInterval(-86400)
            )

            SystemEventRow(
                eventType: .reminderSent,
                timestamp: Date().addingTimeInterval(-172800)
            )

            Divider()
                .padding(.vertical, 8)

            Text("Group Events")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            SystemEventRow(
                eventType: .memberJoined(name: "Sarah"),
                timestamp: Date().addingTimeInterval(-7200)
            )

            SystemEventRow(
                eventType: .memberLeft(name: "John"),
                timestamp: Date().addingTimeInterval(-86400)
            )

            SystemEventRow(
                eventType: .expenseSettled(amount: 45.00),
                timestamp: Date().addingTimeInterval(-259200)
            )

            Divider()
                .padding(.vertical, 8)

            Text("Subscription Events")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            SystemEventRow(
                eventType: .billingCharged(amount: 19.99),
                timestamp: Date().addingTimeInterval(-86400)
            )

            SystemEventRow(
                eventType: .priceChanged(oldPrice: 15.99, newPrice: 19.99),
                timestamp: Date().addingTimeInterval(-604800)
            )

            SystemEventRow(
                eventType: .trialEnding(days: 3),
                timestamp: Date()
            )
        }
        .padding(.vertical, 16)
    }
    .background(Color.wiseBackground)
}
