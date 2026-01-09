//
//  Group+Preview.swift
//  Swiff IOS
//
//  Preview extensions for Group and GroupExpense models
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension Group {

    // MARK: - By State

    /// Group with unsettled expenses
    static var previewUnsettled: Group {
        MockDataProvider.shared.groupBeachVacation
    }

    /// Fully settled group
    static var previewSettled: Group {
        MockDataProvider.shared.groupDinnerClub
    }

    /// Empty group (no expenses)
    static var previewEmpty: Group {
        MockDataProvider.shared.groupProjectTeam
    }

    /// Large group (7 members)
    static var previewLarge: Group {
        MockDataProvider.shared.groupOfficeParty
    }

    /// Group with mixed settled/unsettled expenses
    static var previewMixed: Group {
        MockDataProvider.shared.groupRoommates
    }

    // MARK: - By Size

    /// Small group (2-3 members)
    static var previewSmall: Group {
        MockDataProvider.shared.groupProjectTeam
    }

    /// Medium group (3-4 members)
    static var previewMedium: Group {
        MockDataProvider.shared.groupBeachVacation
    }

    /// Large group (5+ members)
    static var previewLargeSize: Group {
        MockDataProvider.shared.groupOfficeParty
    }

    // MARK: - By Expense Amount

    /// Group with high total ($700+)
    static var previewHighTotal: Group {
        MockDataProvider.shared.groupRoommates
    }

    /// Group with low total
    static var previewLowTotal: Group {
        MockDataProvider.shared.groupDinnerClub
    }

    // MARK: - Collections

    /// All groups (5)
    static var previewList: [Group] {
        MockDataProvider.shared.allGroups
    }

    /// Groups with unsettled expenses
    static var previewUnsettledList: [Group] {
        MockDataProvider.shared.allGroups.filter { $0.hasUnsettledExpenses }
    }

    /// Groups with no expenses
    static var previewEmptyList: [Group] {
        MockDataProvider.shared.allGroups.filter { $0.expenses.isEmpty }
    }

    /// Empty array for empty state
    static var previewNone: [Group] {
        []
    }

    // MARK: - Random

    /// Random group
    static var previewRandom: Group {
        MockDataProvider.shared.allGroups.randomElement() ?? previewUnsettled
    }
}

// MARK: - GroupExpense Preview Extensions

extension GroupExpense {

    // MARK: - By State

    /// Settled expense
    static var previewSettled: GroupExpense {
        MockDataProvider.shared.groupDinnerClub.expenses.first ?? previewUnsettled
    }

    /// Unsettled expense
    static var previewUnsettled: GroupExpense {
        MockDataProvider.shared.groupBeachVacation.expenses.first!
    }

    // MARK: - By Amount

    /// Large expense ($400+)
    static var previewLarge: GroupExpense {
        MockDataProvider.shared.groupBeachVacation.expenses.first! // Airbnb $450
    }

    /// Small expense (<$100)
    static var previewSmall: GroupExpense {
        MockDataProvider.shared.groupRoommates.expenses.first { $0.amount < 100 } ?? previewUnsettled
    }

    // MARK: - By Category

    /// Travel expense
    static var previewTravel: GroupExpense {
        MockDataProvider.shared.groupBeachVacation.expenses.first!
    }

    /// Dining expense
    static var previewDining: GroupExpense {
        MockDataProvider.shared.groupDinnerClub.expenses.first!
    }

    /// Utilities expense
    static var previewUtilities: GroupExpense {
        MockDataProvider.shared.groupRoommates.expenses.first { $0.category == .utilities } ?? previewUnsettled
    }

    // MARK: - Collections

    /// All expenses from all groups
    static var previewList: [GroupExpense] {
        MockDataProvider.shared.allGroups.flatMap { $0.expenses }
    }

    /// Settled expenses
    static var previewSettledList: [GroupExpense] {
        MockDataProvider.shared.allGroups.flatMap { $0.expenses }.filter { $0.isSettled }
    }

    /// Unsettled expenses
    static var previewUnsettledList: [GroupExpense] {
        MockDataProvider.shared.allGroups.flatMap { $0.expenses }.filter { !$0.isSettled }
    }

    /// Empty list
    static var previewEmpty: [GroupExpense] {
        []
    }
}
#endif
