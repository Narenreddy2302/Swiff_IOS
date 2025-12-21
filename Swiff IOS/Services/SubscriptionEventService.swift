//
//  SubscriptionEventService.swift
//  Swiff IOS
//
//  Service to generate timeline events from subscription data
//

import Foundation

// MARK: - Subscription Event Service

class SubscriptionEventService {
    static let shared = SubscriptionEventService()

    private init() {}

    // MARK: - Generate Timeline Items (New API)

    /// Generate all timeline items for a subscription (returns SubscriptionTimelineItem)
    func generateTimelineItems(
        for subscription: Subscription,
        priceHistory: [PriceChange],
        people: [Person]
    ) -> [SubscriptionTimelineItem] {
        var items: [SubscriptionTimelineItem] = []

        // 1. Subscription created event
        items.append(.subscriptionCreated(
            id: UUID(),
            subscriptionName: subscription.name,
            date: subscription.createdDate
        ))

        // 2. Trial events
        if subscription.isFreeTrial {
            items.append(contentsOf: generateTrialTimelineItems(subscription: subscription))
        }

        // 3. Billing events
        items.append(contentsOf: generateBillingTimelineItems(subscription: subscription))

        // 4. Price change events
        items.append(contentsOf: generatePriceChangeTimelineItems(
            subscription: subscription,
            priceHistory: priceHistory
        ))

        // 5. Usage events
        items.append(contentsOf: generateUsageTimelineItems(subscription: subscription))

        // 6. Status change events
        items.append(contentsOf: generateStatusChangeTimelineItems(subscription: subscription))

        // 7. Member events (for shared subscriptions)
        if subscription.isShared {
            items.append(contentsOf: generateMemberTimelineItems(
                subscription: subscription,
                people: people
            ))
        }

        // Sort by date descending (newest first)
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Generate Events (Legacy API - kept for backward compatibility)

    /// Generate all timeline events for a subscription
    func generateEvents(
        for subscription: Subscription,
        priceHistory: [PriceChange],
        people: [Person]
    ) -> [SubscriptionEvent] {
        var events: [SubscriptionEvent] = []

        // 1. Subscription created event
        events.append(createSubscriptionCreatedEvent(subscription: subscription))

        // 2. Trial events
        if subscription.isFreeTrial {
            events.append(contentsOf: generateTrialEvents(subscription: subscription))
        }

        // 3. Billing events
        events.append(contentsOf: generateBillingEvents(subscription: subscription))

        // 4. Price change events
        events.append(contentsOf: generatePriceChangeEvents(
            subscription: subscription,
            priceHistory: priceHistory
        ))

        // 5. Usage events
        events.append(contentsOf: generateUsageEvents(subscription: subscription))

        // 6. Status change events
        events.append(contentsOf: generateStatusChangeEvents(subscription: subscription))

        // 7. Member events (for shared subscriptions)
        if subscription.isShared {
            events.append(contentsOf: generateMemberEvents(
                subscription: subscription,
                people: people
            ))
        }

        // Sort by date descending (newest first)
        return events.sorted { $0.eventDate > $1.eventDate }
    }

    // MARK: - Timeline Item Generators

    private func generateTrialTimelineItems(subscription: Subscription) -> [SubscriptionTimelineItem] {
        var items: [SubscriptionTimelineItem] = []

        // Trial started
        if let trialStart = subscription.trialStartDate, let trialEnd = subscription.trialEndDate {
            items.append(.trialStarted(
                id: UUID(),
                trialEndDate: trialEnd,
                date: trialStart
            ))
        }

        // Trial ending warning (7 days before)
        if let trialEnd = subscription.trialEndDate,
           !subscription.isTrialExpired,
           let daysUntil = subscription.daysUntilTrialEnd,
           daysUntil <= 7 && daysUntil > 0 {
            items.append(.trialEnding(
                id: UUID(),
                daysLeft: daysUntil,
                priceAfterTrial: subscription.priceAfterTrial ?? subscription.price,
                date: Date()
            ))
        }

        // Trial converted (if trial has ended and still active)
        if subscription.isTrialExpired && subscription.isActive,
           let trialEnd = subscription.trialEndDate {
            items.append(.trialConverted(
                id: UUID(),
                newPrice: subscription.price,
                date: trialEnd
            ))
        }

        return items
    }

    private func generateBillingTimelineItems(subscription: Subscription) -> [SubscriptionTimelineItem] {
        var items: [SubscriptionTimelineItem] = []
        let calendar = Calendar.current

        // Last billing
        if let lastBilling = subscription.lastBillingDate {
            items.append(.billingCharged(
                id: UUID(),
                amount: subscription.price,
                date: lastBilling
            ))
        }

        // Upcoming billing (if within 7 days and active)
        if subscription.isActive {
            let daysUntilNext = calendar.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
            if daysUntilNext <= 7 && daysUntilNext >= 0 {
                items.append(.billingUpcoming(
                    id: UUID(),
                    amount: subscription.price,
                    dueDate: subscription.nextBillingDate,
                    date: Date()
                ))
            }
        }

        // Generate past billing events based on billing cycle
        // Going back up to 6 months or 10 events
        if let lastBilling = subscription.lastBillingDate {
            var currentDate = lastBilling
            var count = 0
            let maxEvents = 10
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()

            while count < maxEvents && currentDate > sixMonthsAgo && currentDate > subscription.createdDate {
                // Calculate previous billing date
                switch subscription.billingCycle {
                case .monthly:
                    if let prevDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                case .quarterly:
                    if let prevDate = calendar.date(byAdding: .month, value: -3, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                case .yearly, .annually:
                    if let prevDate = calendar.date(byAdding: .year, value: -1, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                case .weekly:
                    if let prevDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                default:
                    break
                }

                if currentDate > subscription.createdDate {
                    items.append(.billingCharged(
                        id: UUID(),
                        amount: subscription.price,
                        date: currentDate
                    ))
                    count += 1
                }
            }
        }

        return items
    }

    private func generatePriceChangeTimelineItems(
        subscription: Subscription,
        priceHistory: [PriceChange]
    ) -> [SubscriptionTimelineItem] {
        return priceHistory.map { change in
            .priceChange(
                id: UUID(),
                oldPrice: change.oldPrice,
                newPrice: change.newPrice,
                date: change.changeDate
            )
        }
    }

    private func generateUsageTimelineItems(subscription: Subscription) -> [SubscriptionTimelineItem] {
        var items: [SubscriptionTimelineItem] = []

        if let lastUsed = subscription.lastUsedDate, subscription.usageCount > 0 {
            items.append(.usageRecorded(
                id: UUID(),
                date: lastUsed
            ))
        }

        return items
    }

    private func generateStatusChangeTimelineItems(subscription: Subscription) -> [SubscriptionTimelineItem] {
        var items: [SubscriptionTimelineItem] = []

        // Paused event (estimate based on current status)
        if !subscription.isActive && subscription.cancellationDate == nil {
            // Use last billing date or created date as estimate
            let estimatedPauseDate = subscription.lastBillingDate ?? subscription.createdDate
            items.append(.subscriptionPaused(
                id: UUID(),
                date: estimatedPauseDate
            ))
        }

        // Cancelled event
        if let cancelDate = subscription.cancellationDate {
            items.append(.subscriptionCancelled(
                id: UUID(),
                date: cancelDate
            ))
        }

        return items
    }

    private func generateMemberTimelineItems(
        subscription: Subscription,
        people: [Person]
    ) -> [SubscriptionTimelineItem] {
        var items: [SubscriptionTimelineItem] = []

        // Generate member added events for shared members
        let sharedPeople = subscription.sharedWith.compactMap { personId in
            people.first { $0.id == personId }
        }

        for person in sharedPeople {
            // Use subscription created date as estimate for when they were added
            // In a real app, you'd track this separately
            items.append(.memberAdded(
                id: UUID(),
                personName: person.name,
                date: subscription.createdDate
            ))
        }

        return items
    }

    // MARK: - Event Generators

    private func createSubscriptionCreatedEvent(subscription: Subscription) -> SubscriptionEvent {
        return SubscriptionEvent(
            subscriptionId: subscription.id,
            eventType: .subscriptionCreated,
            eventDate: subscription.createdDate,
            title: "Subscription started",
            subtitle: "Started tracking \(subscription.name)",
            isSystemMessage: true
        )
    }

    private func generateTrialEvents(subscription: Subscription) -> [SubscriptionEvent] {
        var events: [SubscriptionEvent] = []

        // Trial started
        if let trialStart = subscription.trialStartDate {
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .trialStarted,
                eventDate: trialStart,
                title: "Free trial started",
                subtitle: subscription.trialDuration.map { "\($0)-day trial" },
                isSystemMessage: true
            ))
        }

        // Trial ending warning (7 days before)
        if let trialEnd = subscription.trialEndDate,
           !subscription.isTrialExpired,
           let daysUntil = subscription.daysUntilTrialEnd,
           daysUntil <= 7 && daysUntil > 0 {
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .trialEnding,
                eventDate: Date(),
                title: "Trial ending soon",
                subtitle: "Expires in \(daysUntil) day\(daysUntil == 1 ? "" : "s")",
                amount: subscription.priceAfterTrial ?? subscription.price,
                isSystemMessage: true
            ))
        }

        // Trial converted (if trial has ended and still active)
        if subscription.isTrialExpired && subscription.isActive,
           let trialEnd = subscription.trialEndDate {
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .trialConverted,
                eventDate: trialEnd,
                title: "Trial converted to paid",
                subtitle: "Now paying \(String(format: "$%.2f", subscription.price))",
                amount: subscription.price,
                isSystemMessage: true
            ))
        }

        return events
    }

    private func generateBillingEvents(subscription: Subscription) -> [SubscriptionEvent] {
        var events: [SubscriptionEvent] = []
        let calendar = Calendar.current

        // Last billing
        if let lastBilling = subscription.lastBillingDate {
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .billingCharged,
                eventDate: lastBilling,
                title: "Payment charged",
                subtitle: subscription.billingCycle.displayName,
                amount: subscription.price,
                isSystemMessage: false
            ))
        }

        // Upcoming billing (if within 7 days and active)
        if subscription.isActive {
            let daysUntilNext = calendar.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
            if daysUntilNext <= 7 && daysUntilNext >= 0 {
                events.append(SubscriptionEvent(
                    subscriptionId: subscription.id,
                    eventType: .billingUpcoming,
                    eventDate: Date(),
                    title: "Upcoming payment",
                    subtitle: daysUntilNext == 0 ? "Due today" : "Due in \(daysUntilNext) day\(daysUntilNext == 1 ? "" : "s")",
                    amount: subscription.price,
                    isSystemMessage: true
                ))
            }
        }

        // Generate past billing events based on billing cycle
        // Going back up to 6 months or 10 events
        if let lastBilling = subscription.lastBillingDate {
            var currentDate = lastBilling
            var count = 0
            let maxEvents = 10
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()

            while count < maxEvents && currentDate > sixMonthsAgo && currentDate > subscription.createdDate {
                // Calculate previous billing date
                switch subscription.billingCycle {
                case .monthly:
                    if let prevDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                case .quarterly:
                    if let prevDate = calendar.date(byAdding: .month, value: -3, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                case .yearly, .annually:
                    if let prevDate = calendar.date(byAdding: .year, value: -1, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                case .weekly:
                    if let prevDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) {
                        currentDate = prevDate
                    } else { break }
                default:
                    break
                }

                if currentDate > subscription.createdDate {
                    events.append(SubscriptionEvent(
                        subscriptionId: subscription.id,
                        eventType: .billingCharged,
                        eventDate: currentDate,
                        title: "Payment charged",
                        subtitle: subscription.billingCycle.displayName,
                        amount: subscription.price,
                        isSystemMessage: false
                    ))
                    count += 1
                }
            }
        }

        return events
    }

    private func generatePriceChangeEvents(
        subscription: Subscription,
        priceHistory: [PriceChange]
    ) -> [SubscriptionEvent] {
        return priceHistory.map { change in
            let eventType: SubscriptionEventType = change.isIncrease ? .priceIncrease : .priceDecrease
            let title = change.isIncrease ? "Price increased" : "Price decreased"
            let subtitle = String(format: "$%.2f → $%.2f (%@)", change.oldPrice, change.newPrice, change.formattedChangePercentage)

            return SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: eventType,
                eventDate: change.changeDate,
                title: title,
                subtitle: subtitle,
                amount: change.changeAmount,
                metadata: ["reason": change.reason ?? ""],
                isSystemMessage: false
            )
        }
    }

    private func generateUsageEvents(subscription: Subscription) -> [SubscriptionEvent] {
        var events: [SubscriptionEvent] = []

        if let lastUsed = subscription.lastUsedDate, subscription.usageCount > 0 {
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .usageRecorded,
                eventDate: lastUsed,
                title: "Marked as used",
                subtitle: "Total uses: \(subscription.usageCount)",
                isSystemMessage: false
            ))
        }

        return events
    }

    private func generateStatusChangeEvents(subscription: Subscription) -> [SubscriptionEvent] {
        var events: [SubscriptionEvent] = []

        // Paused event (estimate based on current status)
        if !subscription.isActive && subscription.cancellationDate == nil {
            // Use last billing date or created date as estimate
            let estimatedPauseDate = subscription.lastBillingDate ?? subscription.createdDate
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .subscriptionPaused,
                eventDate: estimatedPauseDate,
                title: "Subscription paused",
                subtitle: "Not included in monthly costs",
                isSystemMessage: true
            ))
        }

        // Cancelled event
        if let cancelDate = subscription.cancellationDate {
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .subscriptionCancelled,
                eventDate: cancelDate,
                title: "Subscription cancelled",
                subtitle: "No longer active",
                isSystemMessage: true
            ))
        }

        return events
    }

    private func generateMemberEvents(
        subscription: Subscription,
        people: [Person]
    ) -> [SubscriptionEvent] {
        var events: [SubscriptionEvent] = []

        // Generate member added events for shared members
        let sharedPeople = subscription.sharedWith.compactMap { personId in
            people.first { $0.id == personId }
        }

        for person in sharedPeople {
            // Use subscription created date as estimate for when they were added
            // In a real app, you'd track this separately
            events.append(SubscriptionEvent(
                subscriptionId: subscription.id,
                eventType: .memberAdded,
                eventDate: subscription.createdDate,
                title: "\(person.name) joined",
                subtitle: "Split with \(subscription.sharedWith.count + 1) people",
                amount: subscription.costPerPerson,
                isSystemMessage: false,
                relatedPersonId: person.id
            ))
        }

        return events
    }

    // MARK: - Helper Methods (Timeline Items)

    /// Group timeline items by date
    func groupTimelineItemsByDate(_ items: [SubscriptionTimelineItem]) -> [(date: Date, items: [SubscriptionTimelineItem])] {
        let calendar = Calendar.current

        // Group by start of day
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.timestamp)
        }

        // Sort by date descending (newest first)
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    /// Get timeline item count for a subscription
    func getTimelineItemCount(
        for subscription: Subscription,
        priceHistory: [PriceChange],
        people: [Person]
    ) -> Int {
        return generateTimelineItems(for: subscription, priceHistory: priceHistory, people: people).count
    }

    /// Get recent timeline items (last 30 days)
    func getRecentTimelineItems(
        for subscription: Subscription,
        priceHistory: [PriceChange],
        people: [Person],
        days: Int = 30
    ) -> [SubscriptionTimelineItem] {
        let allItems = generateTimelineItems(for: subscription, priceHistory: priceHistory, people: people)
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return allItems.filter { $0.timestamp >= cutoffDate }
    }

    // MARK: - Helper Methods (Legacy Events)

    /// Get event count for a subscription
    func getEventCount(
        for subscription: Subscription,
        priceHistory: [PriceChange],
        people: [Person]
    ) -> Int {
        return generateEvents(for: subscription, priceHistory: priceHistory, people: people).count
    }

    /// Get recent events (last 30 days)
    func getRecentEvents(
        for subscription: Subscription,
        priceHistory: [PriceChange],
        people: [Person],
        days: Int = 30
    ) -> [SubscriptionEvent] {
        let allEvents = generateEvents(for: subscription, priceHistory: priceHistory, people: people)
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return allEvents.filter { $0.eventDate >= cutoffDate }
    }
}
