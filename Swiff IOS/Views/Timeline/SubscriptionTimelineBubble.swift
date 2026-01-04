//
//  SubscriptionTimelineBubble.swift
//  Swiff IOS
//
//  Timeline bubble component for SubscriptionDetailView
//  Renders different bubble types based on SubscriptionTimelineItem
//

import SwiftUI

// MARK: - Subscription Timeline Bubble

struct SubscriptionTimelineBubble: View {
    let item: SubscriptionTimelineItem
    let subscription: Subscription
    var onMarkUsed: (() -> Void)?

    var body: some View {
        switch item {
        case .billingCharged(_, let amount, let date):
            billingChargedBubble(amount: amount, date: date)
        case .billingUpcoming(_, let amount, let dueDate, let date):
            billingUpcomingBubble(amount: amount, dueDate: dueDate, date: date)
        case .priceChange(_, let oldPrice, let newPrice, let date):
            priceChangeBubble(oldPrice: oldPrice, newPrice: newPrice, date: date)
        case .trialStarted(_, let trialEndDate, let date):
            trialStartedBubble(trialEndDate: trialEndDate, date: date)
        case .trialEnding(_, let daysLeft, let priceAfterTrial, let date):
            trialEndingBubble(daysLeft: daysLeft, priceAfterTrial: priceAfterTrial, date: date)
        case .trialConverted(_, let newPrice, let date):
            trialConvertedBubble(newPrice: newPrice, date: date)
        case .subscriptionCreated(_, let subscriptionName, let date):
            subscriptionCreatedBubble(subscriptionName: subscriptionName, date: date)
        case .subscriptionPaused(_, let date):
            subscriptionPausedBubble(date: date)
        case .subscriptionResumed(_, let date):
            subscriptionResumedBubble(date: date)
        case .subscriptionCancelled(_, let date):
            subscriptionCancelledBubble(date: date)
        case .usageRecorded(_, let date):
            usageRecordedBubble(date: date)
        case .reminderSent(_, let date):
            reminderSentBubble(date: date)
        case .memberAdded(_, let personName, let date):
            memberAddedBubble(personName: personName, date: date)
        case .memberRemoved(_, let personName, let date):
            memberRemovedBubble(personName: personName, date: date)
        case .memberPaid(_, let personName, let amount, let date):
            memberPaidBubble(personName: personName, amount: amount, date: date)
        }
    }

    // MARK: - Billing Charged Bubble

    @ViewBuilder
    private func billingChargedBubble(amount: Double, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 0) {
                Text("Payment processed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }

            // Nested card with amount
            NestedCardView(senderName: nil, senderInitials: nil) {
                HStack {
                    Text(subscription.name)
                        .font(.system(size: 13))
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AmountColors.negative)
                }
            }
        }
    }

    // MARK: - Billing Upcoming Bubble

    @ViewBuilder
    private func billingUpcomingBubble(amount: Double, dueDate: Date, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 0) {
                Text(daysUntilMessage(dueDate))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }

            // Nested card with amount
            NestedCardView(senderName: nil, senderInitials: nil) {
                HStack {
                    Text(subscription.name)
                        .font(.system(size: 13))
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.wiseWarning)
                }
            }
        }
    }

    // MARK: - Price Change Bubble

    @ViewBuilder
    private func priceChangeBubble(oldPrice: Double, newPrice: Double, date: Date) -> some View {
        let isIncrease = newPrice > oldPrice

        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 0) {
                Text(isIncrease ? "Price increased" : "Price decreased")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }

            // Price comparison
            HStack(spacing: 8) {
                Text(formatCurrency(oldPrice))
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
                    .strikethrough()

                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
                    .foregroundColor(.wiseSecondaryText)

                Text(formatCurrency(newPrice))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isIncrease ? .wiseWarning : .wiseBrightGreen)
            }
        }
    }

    // MARK: - Trial Started Bubble

    @ViewBuilder
    private func trialStartedBubble(trialEndDate: Date, date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 14))
                .foregroundColor(.wisePurple)

            Text("Free trial started")
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Trial Ending Bubble

    @ViewBuilder
    private func trialEndingBubble(daysLeft: Int, priceAfterTrial: Double, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Warning title row
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.wiseWarning)

                    Text(daysLeft == 1 ? "Trial ends tomorrow" : "Trial ends in \(daysLeft) days")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }

            // Price after trial
            HStack(spacing: 4) {
                Text("Price after trial:")
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)

                Text(formatCurrency(priceAfterTrial))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
            }
        }
    }

    // MARK: - Trial Converted Bubble

    @ViewBuilder
    private func trialConvertedBubble(newPrice: Double, date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseBrightGreen)

            Text("Trial converted to paid subscription")
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Subscription Created Bubble

    @ViewBuilder
    private func subscriptionCreatedBubble(subscriptionName: String, date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseBrightGreen)

            HStack(spacing: 0) {
                Text("Started tracking ")
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)

                Text(subscriptionName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Subscription Paused Bubble

    @ViewBuilder
    private func subscriptionPausedBubble(date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseWarning)

            Text("Subscription paused")
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Subscription Resumed Bubble

    @ViewBuilder
    private func subscriptionResumedBubble(date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseBrightGreen)

            Text("Subscription resumed")
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Subscription Cancelled Bubble

    @ViewBuilder
    private func subscriptionCancelledBubble(date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseError)

            Text("Subscription cancelled")
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Usage Recorded Bubble

    @ViewBuilder
    private func usageRecordedBubble(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 0) {
                Text("Marked as used")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }

            // Quick action button if callback provided
            if let onMarkUsed = onMarkUsed {
                QuickActionButton(
                    title: "Mark Used Again",
                    icon: "checkmark.square.fill",
                    style: .secondary,
                    isCompact: true,
                    action: onMarkUsed
                )
            }
        }
    }

    // MARK: - Reminder Sent Bubble

    @ViewBuilder
    private func reminderSentBubble(date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.fill")
                .font(.system(size: 14))
                .foregroundColor(.wiseBlue)

            Text("Reminder sent")
                .font(.system(size: 13))
                .foregroundColor(.wiseSecondaryText)

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Member Added Bubble

    @ViewBuilder
    private func memberAddedBubble(personName: String, date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 14))
                .foregroundColor(.wisePurple)

            HStack(spacing: 0) {
                Text(personName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)

                Text(" was added")
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Member Removed Bubble

    @ViewBuilder
    private func memberRemovedBubble(personName: String, date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "person.badge.minus")
                .font(.system(size: 14))
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 0) {
                Text(personName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)

                Text(" was removed")
                    .font(.system(size: 13))
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(relativeTime(date))
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }

    // MARK: - Member Paid Bubble

    @ViewBuilder
    private func memberPaidBubble(personName: String, amount: Double, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 0) {
                Text(personName)
                    .font(.system(size: 13, weight: .semibold))
                Text(" paid their share")
                    .font(.system(size: 13))

                Spacer()

                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.leading, 6)
            }
            .foregroundColor(.wisePrimaryText)

            // Nested card with amount
            NestedCardView(
                senderName: personName,
                senderInitials: InitialsGenerator.generate(from: personName)
            ) {
                HStack {
                    Text("Payment received")
                        .font(.system(size: 13))
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.wiseBrightGreen)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func daysUntilMessage(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        let days = components.day ?? 0

        if days == 0 {
            return "Payment due today"
        } else if days == 1 {
            return "Payment due tomorrow"
        } else {
            return "Payment due in \(days) days"
        }
    }
}

// MARK: - Preview

#Preview("SubscriptionTimelineBubble - Billing Events") {
    let mockSubscription = Subscription(
        name: "Netflix",
        description: "Premium Plan",
        price: 15.99,
        billingCycle: .monthly,
        category: .entertainment
    )

    return VStack(spacing: 16) {
        // Billing charged
        SubscriptionTimelineBubble(
            item: .billingCharged(
                id: UUID(),
                amount: 15.99,
                date: Date().addingTimeInterval(-3600)
            ),
            subscription: mockSubscription
        )

        // Billing upcoming
        SubscriptionTimelineBubble(
            item: .billingUpcoming(
                id: UUID(),
                amount: 15.99,
                dueDate: Date().addingTimeInterval(86400 * 2),
                date: Date()
            ),
            subscription: mockSubscription
        )

        // Price increase
        SubscriptionTimelineBubble(
            item: .priceChange(
                id: UUID(),
                oldPrice: 13.99,
                newPrice: 15.99,
                date: Date().addingTimeInterval(-86400 * 3)
            ),
            subscription: mockSubscription
        )

        // Price decrease
        SubscriptionTimelineBubble(
            item: .priceChange(
                id: UUID(),
                oldPrice: 15.99,
                newPrice: 12.99,
                date: Date().addingTimeInterval(-86400 * 5)
            ),
            subscription: mockSubscription
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("SubscriptionTimelineBubble - Trial Events") {
    let mockSubscription = Subscription(
        name: "Spotify Premium",
        description: "Music Streaming",
        price: 10.99,
        billingCycle: .monthly,
        category: .entertainment
    )

    return VStack(spacing: 16) {
        // Trial started
        SubscriptionTimelineBubble(
            item: .trialStarted(
                id: UUID(),
                trialEndDate: Date().addingTimeInterval(86400 * 30),
                date: Date().addingTimeInterval(-86400 * 20)
            ),
            subscription: mockSubscription
        )

        // Trial ending
        SubscriptionTimelineBubble(
            item: .trialEnding(
                id: UUID(),
                daysLeft: 3,
                priceAfterTrial: 10.99,
                date: Date()
            ),
            subscription: mockSubscription
        )

        // Trial converted
        SubscriptionTimelineBubble(
            item: .trialConverted(
                id: UUID(),
                newPrice: 10.99,
                date: Date().addingTimeInterval(-86400 * 2)
            ),
            subscription: mockSubscription
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("SubscriptionTimelineBubble - Status Events") {
    let mockSubscription = Subscription(
        name: "Apple Music",
        description: "Music Streaming",
        price: 9.99,
        billingCycle: .monthly,
        category: .entertainment
    )

    return VStack(spacing: 16) {
        // Subscription created
        SubscriptionTimelineBubble(
            item: .subscriptionCreated(
                id: UUID(),
                subscriptionName: "Apple Music",
                date: Date().addingTimeInterval(-86400 * 30)
            ),
            subscription: mockSubscription
        )

        // Subscription paused
        SubscriptionTimelineBubble(
            item: .subscriptionPaused(
                id: UUID(),
                date: Date().addingTimeInterval(-86400 * 7)
            ),
            subscription: mockSubscription
        )

        // Subscription resumed
        SubscriptionTimelineBubble(
            item: .subscriptionResumed(
                id: UUID(),
                date: Date().addingTimeInterval(-86400 * 2)
            ),
            subscription: mockSubscription
        )

        // Subscription cancelled
        SubscriptionTimelineBubble(
            item: .subscriptionCancelled(
                id: UUID(),
                date: Date()
            ),
            subscription: mockSubscription
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("SubscriptionTimelineBubble - Activity Events") {
    let mockSubscription = Subscription(
        name: "Disney+",
        description: "Streaming Service",
        price: 7.99,
        billingCycle: .monthly,
        category: .entertainment
    )

    return VStack(spacing: 16) {
        // Usage recorded
        SubscriptionTimelineBubble(
            item: .usageRecorded(
                id: UUID(),
                date: Date().addingTimeInterval(-3600 * 2)
            ),
            subscription: mockSubscription,
            onMarkUsed: { print("Mark used tapped") }
        )

        // Reminder sent
        SubscriptionTimelineBubble(
            item: .reminderSent(
                id: UUID(),
                date: Date().addingTimeInterval(-86400)
            ),
            subscription: mockSubscription
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}

#Preview("SubscriptionTimelineBubble - Member Events") {
    let mockSubscription = Subscription(
        name: "YouTube Premium",
        description: "Family Plan",
        price: 22.99,
        billingCycle: .monthly,
        category: .entertainment
    )

    return VStack(spacing: 16) {
        // Member added
        SubscriptionTimelineBubble(
            item: .memberAdded(
                id: UUID(),
                personName: "Sarah Johnson",
                date: Date().addingTimeInterval(-86400 * 5)
            ),
            subscription: mockSubscription
        )

        // Member removed
        SubscriptionTimelineBubble(
            item: .memberRemoved(
                id: UUID(),
                personName: "Mike Davis",
                date: Date().addingTimeInterval(-86400 * 3)
            ),
            subscription: mockSubscription
        )

        // Member paid
        SubscriptionTimelineBubble(
            item: .memberPaid(
                id: UUID(),
                personName: "Emma Wilson",
                amount: 5.75,
                date: Date().addingTimeInterval(-86400)
            ),
            subscription: mockSubscription
        )
    }
    .padding(16)
    .background(Color.wiseBackground)
}
