//
//  Person+Preview.swift
//  Swiff IOS
//
//  Preview extensions for Person model
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension Person {

    // MARK: - Single Instance Previews

    /// Person who owes you money (positive balance)
    static var previewOwedMoney: Person {
        MockDataProvider.shared.personEmma
    }

    /// Person you owe money to (negative balance)
    static var previewOwingMoney: Person {
        MockDataProvider.shared.personJames
    }

    /// Person with zero balance (settled)
    static var previewSettled: Person {
        MockDataProvider.shared.personAisha
    }

    /// Person with large positive balance
    static var previewLargePositive: Person {
        MockDataProvider.shared.personDavid
    }

    /// Person with large negative balance
    static var previewLargeNegative: Person {
        MockDataProvider.shared.personLiWei
    }

    /// Person categorized as family
    static var previewFamily: Person {
        MockDataProvider.shared.personSofia
    }

    /// Person categorized as coworker
    static var previewCoworker: Person {
        MockDataProvider.shared.personMichael
    }

    /// Person with very long name (edge case)
    static var previewLongName: Person {
        MockDataProvider.shared.personAlexandra
    }

    /// Person with small balance
    static var previewSmallBalance: Person {
        MockDataProvider.shared.personPriya
    }

    /// Person with "Other" relationship type
    static var previewOther: Person {
        MockDataProvider.shared.personCarlos
    }

    // MARK: - Collection Previews

    /// Array of all sample people for list previews (10 people)
    static var previewList: [Person] {
        MockDataProvider.shared.allPeople
    }

    /// Array of people with positive balances (they owe you)
    static var previewOwedList: [Person] {
        MockDataProvider.shared.allPeople.filter { $0.balance > 0 }
    }

    /// Array of people with negative balances (you owe them)
    static var previewOwingList: [Person] {
        MockDataProvider.shared.allPeople.filter { $0.balance < 0 }
    }

    /// Array of people with zero balance (settled)
    static var previewSettledList: [Person] {
        MockDataProvider.shared.allPeople.filter { $0.balance == 0 }
    }

    /// Empty array for empty state preview
    static var previewEmpty: [Person] {
        []
    }

    // MARK: - Random for Variety

    /// Random person from mock data
    static var previewRandom: Person {
        MockDataProvider.shared.allPeople.randomElement() ?? previewOwedMoney
    }

    // MARK: - By Avatar Type

    /// Person with emoji avatar
    static var previewEmojiAvatar: Person {
        MockDataProvider.shared.personEmma
    }

    /// Person with initials avatar
    static var previewInitialsAvatar: Person {
        MockDataProvider.shared.personJames
    }
}
#endif
