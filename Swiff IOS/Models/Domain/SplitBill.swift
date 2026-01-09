//
//  SplitBill.swift
//  Swiff IOS
//
//  Split bill data models for sharing expenses with friends or groups
//

import Foundation

// MARK: - Split Type Enum

enum SplitType: String, CaseIterable, Codable, Sendable {
    case equally = "Split Equally"
    case exactAmounts = "Exact Amounts"
    case percentages = "Percentages"
    case shares = "Shares"
    case adjustments = "Adjustments"

    var icon: String {
        switch self {
        case .equally:
            return "equal.square.fill"
        case .exactAmounts:
            return "dollarsign.square.fill"
        case .percentages:
            return "percent"
        case .shares:
            return "chart.pie.fill"
        case .adjustments:
            return "slider.horizontal.3"
        }
    }

    var description: String {
        switch self {
        case .equally:
            return "Divide total equally among all participants"
        case .exactAmounts:
            return "Specify exact dollar amount for each person"
        case .percentages:
            return "Assign percentage of total to each person"
        case .shares:
            return "Use share ratios (e.g., 2:1:1)"
        case .adjustments:
            return "Start equal, then adjust individual amounts"
        }
    }
}

// MARK: - Split Participant Model

struct SplitParticipant: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var personId: UUID          // Reference to Person
    var amount: Double          // Their portion of the bill
    var hasPaid: Bool           // Whether they've settled their portion
    var paymentDate: Date?      // When they paid (if hasPaid = true)

    // For percentage/shares calculation
    var percentage: Double?     // For percentage split (0-100)
    var shares: Int?            // For shares split (1, 2, 3...)

    init(personId: UUID, amount: Double = 0.0, hasPaid: Bool = false, paymentDate: Date? = nil, percentage: Double? = nil, shares: Int? = nil) {
        self.personId = personId
        self.amount = amount
        self.hasPaid = hasPaid
        self.paymentDate = paymentDate
        self.percentage = percentage
        self.shares = shares
    }
}

// MARK: - Split Bill Model

struct SplitBill: Identifiable, Codable, Sendable {
    var id = UUID()
    var title: String                    // "Dinner at Italian Restaurant"
    var totalAmount: Double              // Total bill amount
    var paidById: UUID                   // Person who paid the bill
    var splitType: SplitType             // How the bill is split
    var participants: [SplitParticipant] // Who owes what
    var notes: String                    // Optional notes
    var category: TransactionCategory    // Dining, groceries, etc.
    var date: Date                       // When the expense occurred
    var createdDate: Date                // When the split was created

    // Optional group association
    var groupId: UUID?                   // If split with a group

    // MARK: - Computed Properties

    var isFullySettled: Bool {
        participants.allSatisfy { $0.hasPaid }
    }

    var totalSettled: Double {
        participants.filter { $0.hasPaid }.reduce(0) { $0 + $1.amount }
    }

    var totalPending: Double {
        totalAmount - totalSettled
    }

    var settledCount: Int {
        participants.filter { $0.hasPaid }.count
    }

    var pendingCount: Int {
        participants.count - settledCount
    }

    var settlementProgress: Double {
        guard totalAmount > 0 else { return 0 }
        return totalSettled / totalAmount
    }

    // MARK: - Initializer

    init(
        title: String,
        totalAmount: Double,
        paidById: UUID,
        splitType: SplitType,
        participants: [SplitParticipant] = [],
        notes: String = "",
        category: TransactionCategory = .dining,
        date: Date = Date(),
        groupId: UUID? = nil
    ) {
        self.title = title
        self.totalAmount = totalAmount
        self.paidById = paidById
        self.splitType = splitType
        self.participants = participants
        self.notes = notes
        self.category = category
        self.date = date
        self.createdDate = Date()
        self.groupId = groupId
    }
}
