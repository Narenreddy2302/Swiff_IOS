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
        VStack(alignment: .trailing, spacing: 6) {
            Text(event.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.wisePrimaryText)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }

            if let formattedAmount = event.formattedAmount {
                Text(formattedAmount)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(event.amountColor)
            }

            Text(event.formattedTime)
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Incoming Bubble (Price Changes, Member Events)

    private var incomingBubbleContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // For member events, show person name
            if let name = personName,
                event.eventType == .memberAdded || event.eventType == .memberRemoved
                    || event.eventType == .memberPaid
            {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.wisePrimaryText)
            }

            Text(event.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.wisePrimaryText)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }

            if let formattedAmount = event.formattedAmount {
                Text(formattedAmount)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(event.amountColor)
            }

            Text(event.formattedTime)
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - System Event Content

    private var systemEventContent: some View {
        HStack(spacing: 6) {
            Image(systemName: event.eventType.icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(event.eventType.color)

            VStack(spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.wisePrimaryText)

                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }

    // MARK: - Event Icon

    private var eventIcon: some View {
        Circle()
            .fill(event.eventType.color.opacity(0.15))
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 9, weight: .bold))
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
                .background(Color.wiseSecondaryButton)
                .cornerRadius(12)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("TimelineEventBubble - Billing Events") {
    ScrollView {
        VStack(spacing: 14) {
            TimelineDateSectionHeader(date: Date())

            TimelineEventBubble(event: MockData.billingEvent)

            TimelineEventBubble(event: MockData.trialEndingEvent)
        }
        .padding(.vertical, 16)
    }
    .background(Color.wiseBackground)
}

#Preview("TimelineEventBubble - Price Changes") {
    ScrollView {
        VStack(spacing: 14) {
            TimelineDateSectionHeader(date: Date())

            TimelineEventBubble(event: MockData.priceChangeEvent)
        }
        .padding(.vertical, 16)
    }
    .background(Color.wiseBackground)
}

#Preview("TimelineEventBubble - Member Events") {
    ScrollView {
        VStack(spacing: 14) {
            TimelineDateSectionHeader(date: Date())

            TimelineEventBubble(
                event: MockData.memberAddedEvent,
                personName: MockData.personOwedMoney.name
            )
        }
        .padding(.vertical, 16)
    }
    .background(Color.wiseBackground)
}
