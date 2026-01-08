//
//  GroupModel.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  SwiftData entities for Group and GroupExpense persistence
//

import Foundation
import SwiftData
import Combine

@Model
final class GroupModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupDescription: String // Renamed from 'description' to avoid keyword conflict
    var emoji: String
    var createdDate: Date
    var totalAmount: Double
    var memberIds: [UUID]

    // Supabase sync metadata
    var syncVersion: Int = 1
    var deletedAt: Date?
    var pendingSync: Bool = false
    var lastSyncedAt: Date?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var members: [PersonModel] = []

    @Relationship(deleteRule: .cascade)
    var expenses: [GroupExpenseModel] = []

    init(id: UUID = UUID(), name: String, description: String, emoji: String, createdDate: Date = Date(), totalAmount: Double = 0.0) {
        self.id = id
        self.name = name
        self.groupDescription = description
        self.emoji = emoji
        self.createdDate = createdDate
        self.totalAmount = totalAmount
        self.memberIds = []
    }

    // Convert to domain model
    func toDomain() -> Group {
        let memberIDs = members.map { $0.id }
        let expensesList = expenses.map { $0.toDomain() }

        var group = Group(
            name: name,
            description: groupDescription,
            emoji: emoji,
            members: memberIDs
        )
        group.id = id
        group.expenses = expensesList
        group.createdDate = createdDate
        group.totalAmount = totalAmount

        return group
    }

    /// Convenience initializer from domain model
    /// - Note: Requires context to resolve member UUIDs to PersonModel references
    convenience init(from group: Group, context: ModelContext) {
        self.init(
            id: group.id,
            name: group.name,
            description: group.description,
            emoji: group.emoji,
            createdDate: group.createdDate,
            totalAmount: group.totalAmount
        )

        // Resolve member UUIDs to PersonModel references
        let fetchDescriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { person in
                group.members.contains(person.id)
            }
        )

        if let fetchedMembers = try? context.fetch(fetchDescriptor) {
            // Use append instead of direct assignment to avoid conflicts with SwiftData macros
            for member in fetchedMembers {
                self.members.append(member)
            }
        }

        // Note: Expenses will be created separately via DataManager to avoid SwiftData relationship conflicts
    }
}

@Model
final class GroupExpenseModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var paidByID: UUID
    var splitBetweenIDs: [UUID]
    var categoryRaw: String // Store TransactionCategory raw value
    var date: Date
    var notes: String
    var receiptPath: String?
    var isSettled: Bool

    // Relationships
    @Relationship(deleteRule: .nullify)
    var group: GroupModel?

    @Relationship(deleteRule: .nullify)
    var paidBy: PersonModel?

    @Relationship(deleteRule: .nullify)
    var splitBetween: [PersonModel] = []

    init(id: UUID = UUID(), title: String, amount: Double, paidByID: UUID, splitBetweenIDs: [UUID], category: TransactionCategory, date: Date = Date(), notes: String = "", receiptPath: String? = nil, isSettled: Bool = false) {
        self.id = id
        self.title = title
        self.amount = amount
        self.paidByID = paidByID
        self.splitBetweenIDs = splitBetweenIDs
        self.categoryRaw = category.rawValue
        self.date = date
        self.notes = notes
        self.receiptPath = receiptPath
        self.isSettled = isSettled
    }

    // Convert to domain model
    func toDomain() -> GroupExpense {
        let category = TransactionCategory(rawValue: categoryRaw) ?? .other

        var expense = GroupExpense(
            title: title,
            amount: amount,
            paidBy: paidByID,
            splitBetween: splitBetweenIDs,
            category: category,
            notes: notes,
            receipt: receiptPath,
            isSettled: isSettled
        )
        expense.id = id
        expense.date = date

        return expense
    }

    /// Convenience initializer from domain model
    /// - Note: Requires context to resolve person UUIDs to PersonModel references
    convenience init(from expense: GroupExpense, context: ModelContext) {
        self.init(
            id: expense.id,
            title: expense.title,
            amount: expense.amount,
            paidByID: expense.paidBy,
            splitBetweenIDs: expense.splitBetween,
            category: expense.category,
            date: expense.date,
            notes: expense.notes,
            receiptPath: expense.receipt,
            isSettled: expense.isSettled
        )

        // Resolve paidBy UUID
        let paidByDescriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { $0.id == expense.paidBy }
        )
        self.paidBy = try? context.fetch(paidByDescriptor).first

        // Resolve splitBetween UUIDs
        let splitDescriptor = FetchDescriptor<PersonModel>(
            predicate: #Predicate { person in
                expense.splitBetween.contains(person.id)
            }
        )
        if let fetchedSplitBetween = try? context.fetch(splitDescriptor) {
            for person in fetchedSplitBetween {
                self.splitBetween.append(person)
            }
        }
    }
}
