//
//  TimelineEventBubble.swift
//  Swiff IOS
//
//  Timeline event bubble for subscription conversation view
//  Displays billing events, price changes, trial events, and member activity
//

import SwiftUI

// MARK: - Timeline Event Bubble

struct TimelineEventBubble: View {
    let event: SubscriptionEvent
    let personName: String?

    init(event: SubscriptionEvent, personName: String? = nil) {
        self.event = event
        self.personName = personName
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Leading icon for incoming bubbles
            if event.eventType.bubbleType == .incoming {
                eventIcon
            }

            // Bubble content
            ConversationBubbleView(type: event.eventType.bubbleType) {
                bubbleContent
            }

            // Trailing spacer for incoming/system events
            if event.eventType.bubbleType != .outgoing {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Bubble Content

    @ViewBuilder
    private var bubbleContent: some View {
        switch event.eventType.bubbleType {
        case .outgoing:
            outgoingBubbleContent
        case .incoming:
            incomingBubbleContent
        case .systemEvent:
            systemEventContent
        }
    }

    // MARK: - Outgoing Bubble (Billing Charges)

    private var outgoingBubbleContent: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(event.title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            if let formattedAmount = event.formattedAmount {
                Text(formattedAmount)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(event.amountColor)
            }

            Text(event.formattedTime)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Incoming Bubble (Price Changes, Member Events)

    private var incomingBubbleContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // For member events, show person name
            if let name = personName, event.eventType == .memberAdded || event.eventType == .memberRemoved || event.eventType == .memberPaid {
                Text(name)
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Text(event.title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            if let formattedAmount = event.formattedAmount {
                Text(formattedAmount)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(event.amountColor)
            }

            Text(event.formattedTime)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - System Event Content

    private var systemEventContent: some View {
        HStack(spacing: 8) {
            Image(systemName: event.eventType.icon)
                .font(.system(size: 14))
                .foregroundColor(event.eventType.color)

            VStack(spacing: 2) {
                Text(event.title)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wisePrimaryText)

                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }

    // MARK: - Event Icon

    private var eventIcon: some View {
        Circle()
            .fill(event.eventType.color.opacity(0.15))
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(event.eventType.color)
            )
    }
}

// MARK: - Date Section Header

struct TimelineDateSectionHeader: View {
    let date: Date

    var body: some View {
        HStack {
            Spacer()

            Text(SubscriptionEvent.sectionDate(for: date))
                .font(.spotifyLabelSmall)
                .fontWeight(.semibold)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.wiseBorder.opacity(0.3))
                .cornerRadius(12)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Timeline Event Bubbles") {
    ScrollView {
        VStack(spacing: 14) {
            TimelineDateSectionHeader(date: Date())

            // Billing event (outgoing)
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .billingCharged,
                    eventDate: Date(),
                    title: "Payment charged",
                    subtitle: "Monthly",
                    amount: 10.99
                )
            )

            // Price increase (incoming)
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .priceIncrease,
                    eventDate: Date().addingTimeInterval(-3600),
                    title: "Price increased",
                    subtitle: "$9.99 → $10.99 (+10.0%)",
                    amount: 1.00
                )
            )

            // System event
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .subscriptionCreated,
                    eventDate: Date().addingTimeInterval(-7200),
                    title: "Subscription started",
                    subtitle: "Started tracking Spotify",
                    isSystemMessage: true
                )
            )

            TimelineDateSectionHeader(date: Date().addingTimeInterval(-86400))

            // Trial event
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .trialStarted,
                    eventDate: Date().addingTimeInterval(-86400),
                    title: "Free trial started",
                    subtitle: "30-day trial",
                    isSystemMessage: true
                )
            )

            // Member added (incoming)
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .memberAdded,
                    eventDate: Date().addingTimeInterval(-172800),
                    title: "Alex Thompson joined",
                    subtitle: "Split with 3 people",
                    amount: 5.00,
                    relatedPersonId: UUID()
                ),
                personName: "Alex Thompson"
            )

            // Usage event (system)
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .usageRecorded,
                    eventDate: Date().addingTimeInterval(-259200),
                    title: "Marked as used",
                    subtitle: "Total uses: 15",
                    isSystemMessage: false
                )
            )

            // Price decrease (incoming)
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .priceDecrease,
                    eventDate: Date().addingTimeInterval(-345600),
                    title: "Price decreased",
                    subtitle: "$12.99 → $9.99 (-23.1%)",
                    amount: -3.00
                )
            )

            // Paused event
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .subscriptionPaused,
                    eventDate: Date().addingTimeInterval(-432000),
                    title: "Subscription paused",
                    subtitle: "Not included in monthly costs",
                    isSystemMessage: true
                )
            )

            // Upcoming billing
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .billingUpcoming,
                    eventDate: Date(),
                    title: "Upcoming payment",
                    subtitle: "Due in 3 days",
                    amount: 10.99,
                    isSystemMessage: true
                )
            )

            // Trial ending
            TimelineEventBubble(
                event: SubscriptionEvent(
                    subscriptionId: UUID(),
                    eventType: .trialEnding,
                    eventDate: Date(),
                    title: "Trial ending soon",
                    subtitle: "Expires in 5 days",
                    amount: 9.99,
                    isSystemMessage: true
                )
            )
        }
        .padding(.vertical, 16)
    }
    .background(Color.wiseBackground)
}
