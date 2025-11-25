//
//  SwiftDataExtensions.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Convenience extensions for SwiftData model fetching and querying
//

import SwiftData
import Foundation
import Combine

// MARK: - PersonModel Extensions

extension PersonModel {
    /// Fetch person by UUID
    static func fetch(id: UUID, from context: ModelContext) -> PersonModel? {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Fetch people by name (case-insensitive search)
    static func search(name searchTerm: String, in context: ModelContext) -> [PersonModel] {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { person in
                person.name.localizedStandardContains(searchTerm)
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch people with outstanding balances
    static func fetchWithBalances(from context: ModelContext) -> [PersonModel] {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.balance != 0 }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all people sorted by name
    static func fetchAllSorted(from context: ModelContext) -> [PersonModel] {
        var descriptor = FetchDescriptor<PersonModel>()
        descriptor.sortBy = [SortDescriptor(\.name, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - GroupModel Extensions

extension GroupModel {
    /// Fetch group by UUID
    static func fetch(id: UUID, from context: ModelContext) -> GroupModel? {
        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Fetch groups containing a specific person
    static func fetchGroups(containingPerson personID: UUID, from context: ModelContext) -> [GroupModel] {
        let descriptor = FetchDescriptor<GroupModel>()
        let groups = (try? context.fetch(descriptor)) ?? []

        // Filter groups that have this person as a member
        return groups.filter { group in
            group.members.contains { $0.id == personID }
        }
    }

    /// Fetch all groups sorted by name
    static func fetchAllSorted(from context: ModelContext) -> [GroupModel] {
        var descriptor = FetchDescriptor<GroupModel>()
        descriptor.sortBy = [SortDescriptor(\.name, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch groups with unsettled expenses
    static func fetchWithUnsettledExpenses(from context: ModelContext) -> [GroupModel] {
        let descriptor = FetchDescriptor<GroupModel>()
        let groups = (try? context.fetch(descriptor)) ?? []

        return groups.filter { group in
            group.expenses.contains { !$0.isSettled }
        }
    }
}

// MARK: - SubscriptionModel Extensions

extension SubscriptionModel {
    /// Fetch subscription by UUID
    static func fetch(id: UUID, from context: ModelContext) -> SubscriptionModel? {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Fetch active subscriptions
    static func fetchActive(from context: ModelContext) -> [SubscriptionModel] {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.isActive == true }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch inactive/cancelled subscriptions
    static func fetchInactive(from context: ModelContext) -> [SubscriptionModel] {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.isActive == false }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch subscriptions by category
    static func fetch(byCategory category: String, from context: ModelContext) -> [SubscriptionModel] {
        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.categoryRaw == category }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch subscriptions renewing within next N days
    static func fetchRenewingSoon(days: Int, from context: ModelContext) -> [SubscriptionModel] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now

        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { subscription in
                subscription.isActive &&
                subscription.nextBillingDate >= now &&
                subscription.nextBillingDate <= futureDate
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Calculate total monthly cost of all active subscriptions
    static func calculateTotalMonthlyCost(from context: ModelContext) -> Double {
        let activeSubscriptions = fetchActive(from: context)

        return activeSubscriptions.reduce(0.0) { total, subscription in
            let billingCycle = BillingCycle(rawValue: subscription.billingCycleRaw) ?? .monthly
            let monthlyEquivalent: Double

            switch billingCycle {
            case .daily: monthlyEquivalent = subscription.price * 30
            case .weekly: monthlyEquivalent = subscription.price * 4.33
            case .biweekly: monthlyEquivalent = subscription.price * 2.17
            case .monthly: monthlyEquivalent = subscription.price
            case .quarterly: monthlyEquivalent = subscription.price / 3
            case .semiAnnually: monthlyEquivalent = subscription.price / 6
            case .yearly, .annually: monthlyEquivalent = subscription.price / 12
            case .lifetime: monthlyEquivalent = 0
            }

            return total + monthlyEquivalent
        }
    }
}

// MARK: - TransactionModel Extensions

extension TransactionModel {
    /// Fetch transaction by UUID
    static func fetch(id: UUID, from context: ModelContext) -> TransactionModel? {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Fetch transactions within date range
    static func fetch(from startDate: Date, to endDate: Date, in context: ModelContext) -> [TransactionModel] {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch transactions for current month
    static func fetchCurrentMonth(from context: ModelContext) -> [TransactionModel] {
        let now = Date()
        let calendar = Calendar.current

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            print("⚠️ Failed to calculate month boundaries, returning empty array")
            return []
        }

        return fetch(from: startOfMonth, to: endOfMonth, in: context)
    }

    /// Fetch transactions by category
    static func fetch(byCategory category: String, from context: ModelContext) -> [TransactionModel] {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.categoryRaw == category }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch recurring transactions
    static func fetchRecurring(from context: ModelContext) -> [TransactionModel] {
        let descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.isRecurring == true }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Calculate total for transactions (positive for income, negative for expenses)
    static func calculateTotal(for transactions: [TransactionModel]) -> Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }

    /// Calculate total income for current month
    static func calculateMonthlyIncome(from context: ModelContext) -> Double {
        let currentMonthTransactions = fetchCurrentMonth(from: context)
        let income = currentMonthTransactions.filter { $0.amount > 0 }
        return calculateTotal(for: income)
    }

    /// Calculate total expenses for current month
    static func calculateMonthlyExpenses(from context: ModelContext) -> Double {
        let currentMonthTransactions = fetchCurrentMonth(from: context)
        let expenses = currentMonthTransactions.filter { $0.amount < 0 }
        return abs(calculateTotal(for: expenses))
    }
}

// MARK: - GroupExpenseModel Extensions

extension GroupExpenseModel {
    /// Fetch expense by UUID
    static func fetch(id: UUID, from context: ModelContext) -> GroupExpenseModel? {
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Fetch unsettled expenses
    static func fetchUnsettled(from context: ModelContext) -> [GroupExpenseModel] {
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate { $0.isSettled == false }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch expenses paid by a specific person
    static func fetchPaidBy(personID: UUID, from context: ModelContext) -> [GroupExpenseModel] {
        let descriptor = FetchDescriptor<GroupExpenseModel>(
            predicate: #Predicate { $0.paidByID == personID }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
