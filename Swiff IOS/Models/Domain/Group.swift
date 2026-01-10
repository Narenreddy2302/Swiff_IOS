//
//  Group.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Combine
import Foundation

// MARK: - Group Model

struct Group: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var emoji: String
    var members: [UUID]  // Person IDs
    var expenses: [GroupExpense]
    var createdDate: Date
    var totalAmount: Double

    init(name: String, description: String, emoji: String, members: [UUID] = []) {
        self.name = name
        self.description = description
        self.emoji = emoji
        self.members = members
        self.expenses = []
        self.createdDate = Date()
        self.totalAmount = 0.0
    }

    // Check if group has any unsettled expenses
    var hasUnsettledExpenses: Bool {
        expenses.contains { !$0.isSettled }
    }

    // Settlement status text for display
    var settlementStatus: String {
        if expenses.isEmpty {
            return "No expenses"
        }
        return hasUnsettledExpenses ? "Active" : "Settled"
    }

    // Last expense details for feed-style display
    // Returns: "Dinner • 2 days ago" or "No expenses"
    func lastExpenseDetails() -> String {
        guard let lastExpense = expenses.sorted(by: { $0.date > $1.date }).first else {
            return "No expenses"
        }

        let title = lastExpense.title
        let timeText = relativeTimeString(from: lastExpense.date)

        return "\(title) • \(timeText)"
    }

    // Helper to format relative time
    private func relativeTimeString(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) \(weeks == 1 ? "week" : "weeks") ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months) \(months == 1 ? "month" : "months") ago"
        } else {
            let years = days / 365
            return "\(years) \(years == 1 ? "year" : "years") ago"
        }
    }

    // MARK: - Supabase Conversion

    /// Converts this domain model to a Supabase-compatible model for API upload
    /// - Parameter userId: The authenticated user's ID from Supabase
    /// - Returns: SupabaseGroup ready for API insertion/update
    /// - Note: Group members and expenses are synced separately via their own tables
    func toSupabaseModel(userId: UUID) -> SupabaseGroup {
        return SupabaseGroup(
            id: self.id,
            userId: userId,
            name: self.name,
            description: self.description.isEmpty ? nil : self.description,
            emoji: self.emoji,
            totalAmount: Decimal(self.totalAmount),
            createdAt: self.createdDate,
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
    }

    /// Converts group members to Supabase-compatible group member records
    /// - Parameter groupId: The group's ID
    /// - Returns: Array of SupabaseGroupMember ready for API insertion
    func membersToSupabaseModels() -> [SupabaseGroupMember] {
        return members.map { personId in
            SupabaseGroupMember(
                id: UUID(),
                groupId: self.id,
                personId: personId,
                memberUserId: nil,
                isAdmin: false,
                joinedAt: self.createdDate,
                invitationStatus: "accepted",
                invitedAt: nil,
                respondedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil,
                syncVersion: 1
            )
        }
    }
}

// MARK: - Group Expense Model

struct GroupExpense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var paidBy: UUID  // Person ID
    var splitBetween: [UUID]  // Person IDs
    var category: TransactionCategory
    var date: Date
    var notes: String
    var receipt: String?  // Receipt image path
    var isSettled: Bool

    init(
        title: String, amount: Double, paidBy: UUID, splitBetween: [UUID],
        category: TransactionCategory, notes: String = "", receipt: String? = nil,
        isSettled: Bool = false
    ) {
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.splitBetween = splitBetween
        self.category = category
        self.date = Date()
        self.notes = notes
        self.receipt = receipt
        self.isSettled = isSettled
    }

    var amountPerPerson: Double {
        splitBetween.isEmpty ? 0 : amount / Double(splitBetween.count)
    }
}

// MARK: - Bill Split Model

struct BillSplit: Identifiable {
    let id = UUID()
    var title: String
    var totalAmount: Double
    var paidBy: Person
    var participants: [BillParticipant]
    var category: TransactionCategory
    var date: Date
    var notes: String
    var isSettled: Bool

    var amountPerPerson: Double {
        participants.isEmpty ? 0 : totalAmount / Double(participants.count)
    }
}

struct BillParticipant: Identifiable {
    let id = UUID()
    let person: Person
    var amountOwed: Double
    var hasPaid: Bool
}
