//
//  Group.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Foundation
import Combine

// MARK: - Group Model

struct Group: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var emoji: String
    var members: [UUID] // Person IDs
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
}

// MARK: - Group Expense Model

struct GroupExpense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var paidBy: UUID // Person ID
    var splitBetween: [UUID] // Person IDs
    var category: TransactionCategory
    var date: Date
    var notes: String
    var receipt: String? // Receipt image path
    var isSettled: Bool

    init(title: String, amount: Double, paidBy: UUID, splitBetween: [UUID], category: TransactionCategory, notes: String = "", receipt: String? = nil, isSettled: Bool = false) {
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
