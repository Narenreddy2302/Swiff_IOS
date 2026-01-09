//
//  Transaction.swift
//  iMessageTransactionUI
//
//  Description:
//  Model representing a transaction/expense that is split among multiple people.
//  Contains all data needed to display transaction cards and calculate balances.
//
//  Properties:
//  - id: Unique identifier for the transaction
//  - name: Name/description of the transaction (e.g., "Dinner", "Movie Tickets")
//  - totalBill: Total amount of the transaction in dollars
//  - paidBy: Name of the person who paid (use "You" for the current user)
//  - splitMethod: How the bill is split (currently supports "Equally")
//  - people: Array of names of people involved in the split
//  - creatorName: Name of who created this transaction
//  - timestamp: When the transaction was created
//
//  Computed Properties:
//  - sharePerPerson: Equal share each person owes (totalBill / number of people)
//  - youOwe: Amount the current user owes (0 if user paid, sharePerPerson otherwise)
//  - owedToYou: Amount others owe the user (share * others count if user paid, 0 otherwise)
//  - isPaidByCurrentUser: Boolean indicating if the current user paid
//
//  Balance Calculation Logic:
//  - If "You" paid: You are owed (sharePerPerson × number of other people)
//  - If someone else paid: You owe sharePerPerson
//

import Foundation

// MARK: - Transaction Model
/// Represents a single transaction/expense to be split among group members
struct Transaction: Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the transaction
    let id: UUID
    
    /// Name/description of the transaction (e.g., "Dinner at Restaurant")
    let name: String
    
    /// Total amount of the transaction in dollars
    let totalBill: Double
    
    /// Name of the person who paid for this transaction
    /// Use "You" to indicate the current user paid
    let paidBy: String
    
    /// Method used to split the bill
    /// Options: "Equally", "By Percentage", "Custom Amount"
    let splitMethod: String
    
    /// Array of names of all people involved in splitting this transaction
    /// Should include the current user as "You" if they are part of the split
    let people: [String]
    
    /// Name of the person who created this transaction record
    let creatorName: String
    
    /// Timestamp when the transaction was created
    let timestamp: Date
    
    // MARK: - Initializer
    
    /// Creates a new Transaction instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Transaction name/description
    ///   - totalBill: Total amount in dollars
    ///   - paidBy: Name of payer ("You" for current user)
    ///   - splitMethod: How to split the bill (defaults to "Equally")
    ///   - people: Array of people involved
    ///   - creatorName: Who created this transaction
    ///   - timestamp: Creation time (defaults to now)
    init(
        id: UUID = UUID(),
        name: String,
        totalBill: Double,
        paidBy: String,
        splitMethod: String = "Equally",
        people: [String],
        creatorName: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.totalBill = totalBill
        self.paidBy = paidBy
        self.splitMethod = splitMethod
        self.people = people
        self.creatorName = creatorName
        self.timestamp = timestamp
    }
    
    // MARK: - Computed Properties
    
    /// Calculates the equal share each person owes
    /// Formula: totalBill / numberOfPeople
    /// - Returns: Amount each person should pay
    var sharePerPerson: Double {
        guard !people.isEmpty else { return 0 }
        return totalBill / Double(people.count)
    }
    
    /// Checks if the current user ("You") paid for this transaction
    /// - Returns: true if paidBy equals "You" (case-insensitive)
    var isPaidByCurrentUser: Bool {
        return paidBy.lowercased() == "you"
    }
    
    /// Calculates how much the current user owes for this transaction
    /// - Returns: 0 if user paid, sharePerPerson if someone else paid
    ///
    /// Logic:
    /// - If user paid: They don't owe anything (return 0)
    /// - If someone else paid: User owes their share (return sharePerPerson)
    var youOwe: Double {
        if isPaidByCurrentUser {
            // User paid, so they don't owe anything
            return 0
        } else {
            // Someone else paid, user owes their share
            return sharePerPerson
        }
    }
    
    /// Calculates how much others owe the current user for this transaction
    /// - Returns: Total amount others owe if user paid, 0 otherwise
    ///
    /// Logic:
    /// - If user paid: Others owe (sharePerPerson × number of other people)
    /// - If someone else paid: Nothing is owed to user (return 0)
    var owedToYou: Double {
        if isPaidByCurrentUser {
            // User paid, so others owe their shares
            // Count of others = total people minus the user
            let othersCount = people.filter { $0.lowercased() != "you" }.count
            return sharePerPerson * Double(othersCount)
        } else {
            // Someone else paid, nothing owed to user
            return 0
        }
    }
    
    /// Formatted string of share per person with currency symbol
    /// - Returns: String in format "$X.XX"
    var formattedSharePerPerson: String {
        return "$\(String(format: "%.2f", sharePerPerson))"
    }
    
    /// Formatted string of total bill with currency symbol
    /// - Returns: String in format "$X.XX"
    var formattedTotalBill: String {
        return "$\(String(format: "%.2f", totalBill))"
    }
    
    /// Comma-separated list of all people involved
    /// - Returns: String like "Person 1, Person 2, Person 3"
    var peopleList: String {
        return people.joined(separator: ", ")
    }
    
    /// Label to show on transaction card based on who paid
    /// - Returns: " / Each Owes" if user paid, " / You Owe" otherwise
    var oweLabel: String {
        return isPaidByCurrentUser ? " / Each Owes" : " / You Owe"
    }
}

// MARK: - Sample Data Extension
extension Transaction {
    
    /// Sample transactions for preview and testing purposes
    static let sampleTransactions: [Transaction] = [
        Transaction(
            name: "Transaction Name",
            totalBill: 99.99,
            paidBy: "Naren Reddy",
            splitMethod: "Equally",
            people: ["Person 1", "Person 2", "Person 3"],
            creatorName: "Naren Reddy"
        ),
        Transaction(
            name: "Movie Tickets",
            totalBill: 45.00,
            paidBy: "Naren Reddy",
            splitMethod: "Equally",
            people: ["Person 1", "Person 2", "Person 3"],
            creatorName: "Naren Reddy"
        ),
        Transaction(
            name: "Groceries",
            totalBill: 50.00,
            paidBy: "You",
            splitMethod: "Equally",
            people: ["Person 1", "Person 2", "Person 3", "You"],
            creatorName: "You"
        ),
        Transaction(
            name: "Uber Ride",
            totalBill: 35.00,
            paidBy: "Sarah",
            splitMethod: "Equally",
            people: ["Person 1", "Person 2", "Person 3", "Person 4"],
            creatorName: "Sarah"
        )
    ]
}
