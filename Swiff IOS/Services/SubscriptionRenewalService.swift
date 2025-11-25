//
//  SubscriptionRenewalService.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Service for managing subscription renewals and auto-renewal logic
//

import Foundation
import Combine

@MainActor
class SubscriptionRenewalService {
    static let shared = SubscriptionRenewalService()

    private let persistenceService = PersistenceService.shared
    private let notificationManager = NotificationManager.shared

    private init() {}

    // MARK: - Auto-Renewal Logic

    /// Check and process all overdue subscription renewals
    func processOverdueRenewals() async {
        do {
            let subscriptions = try persistenceService.fetchAllSubscriptions()
            let overdueSubscriptions = subscriptions.filter { isOverdue($0) }

            for subscription in overdueSubscriptions {
                await processRenewal(for: subscription)
            }

            if !overdueSubscriptions.isEmpty {
                print("✅ Processed \(overdueSubscriptions.count) overdue subscription renewal(s)")
            }
        } catch {
            print("❌ Failed to process overdue renewals: \(error)")
        }
    }

    /// Check if a subscription is overdue for renewal
    func isOverdue(_ subscription: Subscription) -> Bool {
        guard subscription.isActive else { return false }
        guard subscription.billingCycle != .lifetime else { return false }

        return subscription.nextBillingDate < Date()
    }

    /// Process renewal for a specific subscription
    func processRenewal(for subscription: Subscription) async {
        var updatedSubscription = subscription

        // Calculate next billing date based on billing cycle
        if let nextDate = calculateNextBillingDate(from: subscription.nextBillingDate, cycle: subscription.billingCycle) {
            updatedSubscription.nextBillingDate = nextDate

            do {
                try persistenceService.updateSubscription(updatedSubscription)
                print("✅ Renewed subscription: \(subscription.name), next billing: \(nextDate)")

                // AGENT 7: Reschedule reminders for new billing cycle
                await notificationManager.updateScheduledReminders(for: updatedSubscription)

                // Announce to user if needed
                if AccessibilitySettings.isVoiceOverRunning {
                    AccessibilityAnnouncer.shared.announce("\(subscription.name) has been renewed")
                }
            } catch {
                print("❌ Failed to update subscription renewal: \(error)")
            }
        }
    }

    /// Calculate next billing date based on billing cycle
    func calculateNextBillingDate(from currentDate: Date, cycle: BillingCycle) -> Date? {
        let calendar = Calendar.current

        switch cycle {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: currentDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: currentDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: currentDate)
        case .semiAnnually:
            return calendar.date(byAdding: .month, value: 6, to: currentDate)
        case .yearly, .annually:
            return calendar.date(byAdding: .year, value: 1, to: currentDate)
        case .lifetime:
            return nil // Lifetime subscriptions don't renew
        }
    }

    // MARK: - Upcoming Renewals

    /// Get subscriptions that will renew within the specified number of days
    func getUpcomingRenewals(within days: Int) -> [Subscription] {
        guard let subscriptions = try? persistenceService.fetchAllSubscriptions() else {
            return []
        }

        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        return subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.billingCycle != .lifetime &&
            subscription.nextBillingDate >= Date() &&
            subscription.nextBillingDate <= endDate
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    /// Get subscriptions renewing today
    func getTodayRenewals() -> [Subscription] {
        guard let subscriptions = try? persistenceService.fetchAllSubscriptions() else {
            return []
        }

        return subscriptions.filter { subscription in
            subscription.isActive &&
            Calendar.current.isDateInToday(subscription.nextBillingDate)
        }
    }

    /// Get subscriptions renewing this week
    func getWeekRenewals() -> [Subscription] {
        return getUpcomingRenewals(within: 7)
    }

    // MARK: - Renewal Reminders

    /// Schedule reminders for all upcoming renewals
    func scheduleAllRenewalReminders() async {
        do {
            let subscriptions = try persistenceService.fetchAllSubscriptions()
            let activeSubscriptions = subscriptions.filter { $0.isActive && $0.billingCycle != .lifetime }

            await notificationManager.scheduleAllSubscriptionReminders(subscriptions: activeSubscriptions)

            print("✅ Scheduled renewal reminders for \(activeSubscriptions.count) subscription(s)")
        } catch {
            print("❌ Failed to schedule renewal reminders: \(error)")
        }
    }

    /// Cancel renewal for a subscription (pause)
    func pauseSubscription(_ subscription: Subscription) async {
        var updatedSubscription = subscription
        updatedSubscription.isActive = false

        do {
            try persistenceService.updateSubscription(updatedSubscription)

            // Cancel pending reminders
            notificationManager.cancelSubscriptionReminders(for: subscription.id)

            ToastManager.shared.showSuccess("\(subscription.name) paused")
            print("✅ Paused subscription: \(subscription.name)")
        } catch {
            ToastManager.shared.showError("Failed to pause subscription")
            print("❌ Failed to pause subscription: \(error)")
        }
    }

    /// Resume a paused subscription
    func resumeSubscription(_ subscription: Subscription) async {
        var updatedSubscription = subscription
        updatedSubscription.isActive = true

        // Recalculate next billing date if it's in the past
        if updatedSubscription.nextBillingDate < Date() {
            if let nextDate = calculateNextBillingDate(from: Date(), cycle: subscription.billingCycle) {
                updatedSubscription.nextBillingDate = nextDate
            }
        }

        do {
            try persistenceService.updateSubscription(updatedSubscription)

            // Schedule new reminder
            await notificationManager.scheduleSubscriptionReminder(for: updatedSubscription)

            ToastManager.shared.showSuccess("\(subscription.name) resumed")
            print("✅ Resumed subscription: \(subscription.name)")
        } catch {
            ToastManager.shared.showError("Failed to resume subscription")
            print("❌ Failed to resume subscription: \(error)")
        }
    }

    /// Cancel a subscription permanently
    func cancelSubscription(_ subscription: Subscription) async {
        var updatedSubscription = subscription
        updatedSubscription.isActive = false
        updatedSubscription.cancellationDate = Date()

        do {
            try persistenceService.updateSubscription(updatedSubscription)

            // Cancel pending reminders
            notificationManager.cancelSubscriptionReminders(for: subscription.id)

            ToastManager.shared.showSuccess("\(subscription.name) cancelled")
            print("✅ Cancelled subscription: \(subscription.name)")
        } catch {
            ToastManager.shared.showError("Failed to cancel subscription")
            print("❌ Failed to cancel subscription: \(error)")
        }
    }

    // MARK: - AGENT 8: Trial Processing

    /// Process all expired trials today
    func processTrialExpirations() async {
        do {
            let subscriptions = try persistenceService.fetchAllSubscriptions()
            let expiredTrials = subscriptions.filter { $0.isFreeTrial && $0.isTrialExpired }

            for trial in expiredTrials {
                if trial.willConvertToPaid {
                    // Convert to paid subscription
                    await convertTrialToPaid(subscription: trial)
                } else {
                    // Cancel subscription
                    await cancelSubscription(trial)
                }
            }

            if !expiredTrials.isEmpty {
                print("✅ Processed \(expiredTrials.count) expired trial(s)")
            }
        } catch {
            print("❌ Failed to process trial expirations: \(error)")
        }
    }

    /// Convert trial subscription to paid subscription
    func convertTrialToPaid(subscription: Subscription) async {
        var updatedSubscription = subscription

        // Update trial fields
        updatedSubscription.isFreeTrial = false
        updatedSubscription.trialStartDate = nil
        updatedSubscription.trialEndDate = nil
        updatedSubscription.trialDuration = nil

        // Update price if trial had different pricing
        if let priceAfterTrial = subscription.priceAfterTrial {
            updatedSubscription.price = priceAfterTrial
            updatedSubscription.priceAfterTrial = nil
        }

        // Calculate next billing date
        if let nextDate = calculateNextBillingDate(from: Date(), cycle: subscription.billingCycle) {
            updatedSubscription.nextBillingDate = nextDate
        }

        // Ensure subscription is active
        updatedSubscription.isActive = true

        do {
            try persistenceService.updateSubscription(updatedSubscription)

            // Schedule renewal reminder
            await notificationManager.scheduleSubscriptionReminder(for: updatedSubscription)

            ToastManager.shared.showSuccess("\(subscription.name) trial converted to paid")
            print("✅ Converted trial to paid: \(subscription.name)")
        } catch {
            ToastManager.shared.showError("Failed to convert trial")
            print("❌ Failed to convert trial to paid: \(error)")
        }
    }

    /// Get trials ending soon (within specified days)
    func getTrialsEndingSoon(within days: Int = 7) -> [Subscription] {
        guard let subscriptions = try? persistenceService.fetchAllSubscriptions() else {
            return []
        }

        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        return subscriptions.filter { subscription in
            guard subscription.isFreeTrial,
                  !subscription.isTrialExpired,
                  let trialEndDate = subscription.trialEndDate else {
                return false
            }

            return trialEndDate >= Date() && trialEndDate <= endDate
        }.sorted { ($0.trialEndDate ?? Date()) < ($1.trialEndDate ?? Date()) }
    }

    /// Get active trials count
    func getActiveTrialsCount() -> Int {
        guard let subscriptions = try? persistenceService.fetchAllSubscriptions() else {
            return 0
        }

        return subscriptions.filter { $0.isFreeTrial && !$0.isTrialExpired }.count
    }

    // MARK: - Statistics

    /// Calculate total monthly cost of all active subscriptions
    func calculateMonthlyTotal() -> Double {
        guard let subscriptions = try? persistenceService.fetchAllSubscriptions() else {
            return 0
        }

        return subscriptions
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.monthlyEquivalent }
    }

    /// Calculate total annual cost of all active subscriptions
    func calculateAnnualTotal() -> Double {
        return calculateMonthlyTotal() * 12
    }

    /// Get subscription statistics
    func getStatistics() -> SubscriptionStatistics {
        guard let subscriptions = try? persistenceService.fetchAllSubscriptions() else {
            return SubscriptionStatistics(
                totalActive: 0,
                totalInactive: 0,
                totalMonthlyCost: 0,
                totalAnnualCost: 0,
                mostExpensiveCategory: "None",
                averageCostPerSubscription: 0,
                upcomingRenewals7Days: 0,
                upcomingRenewals30Days: 0,
                freeTrials: 0,
                trialsEndingSoon: 0
            )
        }

        let activeSubscriptions = subscriptions.filter { $0.isActive }
        let inactiveSubscriptions = subscriptions.filter { !$0.isActive }

        let freeTrials = subscriptions.filter { $0.isFreeTrial && $0.isActive }.count
        let trialsEnding = subscriptions.filter {
            $0.isFreeTrial && !$0.isTrialExpired && ($0.daysUntilTrialEnd ?? 100) <= 7
        }.count

        let renewals7 = getUpcomingRenewals(within: 7).count
        let renewals30 = getUpcomingRenewals(within: 30).count

        // Calculate most expensive category
        let categoryTotals = Dictionary(grouping: activeSubscriptions, by: { $0.category })
            .mapValues { subs in subs.reduce(0.0) { $0 + $1.monthlyEquivalent } }
        let mostExpensiveCategory = categoryTotals.max(by: { $0.value < $1.value })?.key.rawValue ?? "None"

        let totalMonthly = calculateMonthlyTotal()
        let avgCost = activeSubscriptions.isEmpty ? 0 : totalMonthly / Double(activeSubscriptions.count)

        return SubscriptionStatistics(
            totalActive: activeSubscriptions.count,
            totalInactive: inactiveSubscriptions.count,
            totalMonthlyCost: totalMonthly,
            totalAnnualCost: calculateAnnualTotal(),
            mostExpensiveCategory: mostExpensiveCategory,
            averageCostPerSubscription: avgCost,
            upcomingRenewals7Days: renewals7,
            upcomingRenewals30Days: renewals30,
            freeTrials: freeTrials,
            trialsEndingSoon: trialsEnding
        )
    }
}

// MARK: - Subscription Statistics

// Note: SubscriptionStatistics is defined in AnalyticsModels.swift

// MARK: - Subscription Extensions

extension Subscription {
    /// Calculate annual cost
    var annualCost: Double {
        return monthlyEquivalent * 12
    }

    /// Check if renewal is due soon (within 3 days)
    var isDueSoon: Bool {
        guard isActive else { return false }
        guard billingCycle != .lifetime else { return false }

        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return nextBillingDate <= threeDaysFromNow && nextBillingDate >= Date()
    }

    /// Check if overdue for renewal
    var isOverdue: Bool {
        guard isActive else { return false }
        guard billingCycle != .lifetime else { return false }

        return nextBillingDate < Date()
    }
}
