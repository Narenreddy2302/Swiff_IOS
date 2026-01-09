//
//  SplitBill+Preview.swift
//  Swiff IOS
//
//  Preview extensions for SplitBill model
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension SplitBill {

    // MARK: - By Settlement State

    /// Fully settled (all paid)
    static var previewFullySettled: SplitBill {
        MockDataProvider.shared.splitBillFullySettled
    }

    /// Fully pending (none paid)
    static var previewFullyPending: SplitBill {
        MockDataProvider.shared.splitBillFullyPending
    }

    /// Partially settled (some paid)
    static var previewPartiallySettled: SplitBill {
        MockDataProvider.shared.splitBillPartiallySettled
    }

    /// Overdue (30+ days old, unpaid)
    static var previewOverdue: SplitBill {
        MockDataProvider.shared.splitBillOverdue
    }

    // MARK: - By Split Type

    /// Equal split
    static var previewEqual: SplitBill {
        MockDataProvider.shared.splitBillFullySettled
    }

    /// Percentage-based split
    static var previewPercentage: SplitBill {
        MockDataProvider.shared.splitBillPercentage
    }

    /// Shares-based split
    static var previewShares: SplitBill {
        MockDataProvider.shared.splitBillShares
    }

    // MARK: - By Amount

    /// Large split ($2,000+)
    static var previewLarge: SplitBill {
        MockDataProvider.shared.splitBillLarge
    }

    /// Small split (<$20)
    static var previewSmall: SplitBill {
        MockDataProvider.shared.splitBillSmall
    }

    /// Medium split ($100-$300)
    static var previewMedium: SplitBill {
        MockDataProvider.shared.splitBillPartiallySettled
    }

    // MARK: - Special Cases

    /// Split with notes
    static var previewWithNotes: SplitBill {
        MockDataProvider.shared.splitBillWithNotes
    }

    /// Split linked to group
    static var previewGroupLinked: SplitBill {
        MockDataProvider.shared.splitBillGroupLinked
    }

    // MARK: - Collections

    /// All split bills (10)
    static var previewList: [SplitBill] {
        MockDataProvider.shared.allSplitBills
    }

    /// Fully settled split bills
    static var previewSettledList: [SplitBill] {
        MockDataProvider.shared.allSplitBills.filter { $0.isFullySettled }
    }

    /// Pending split bills (not fully settled)
    static var previewPendingList: [SplitBill] {
        MockDataProvider.shared.allSplitBills.filter { !$0.isFullySettled }
    }

    /// Split bills linked to groups
    static var previewGroupLinkedList: [SplitBill] {
        MockDataProvider.shared.allSplitBills.filter { $0.groupId != nil }
    }

    /// Empty list
    static var previewEmpty: [SplitBill] {
        []
    }

    // MARK: - Random

    /// Random split bill
    static var previewRandom: SplitBill {
        MockDataProvider.shared.allSplitBills.randomElement() ?? previewFullySettled
    }
}

// MARK: - SplitParticipant Preview Extensions

extension SplitParticipant {

    // MARK: - By Payment State

    /// Paid participant
    static var previewPaid: SplitParticipant {
        SplitParticipant(
            personId: MockDataProvider.PersonUUIDs.emma,
            amount: 50.00,
            hasPaid: true
        )
    }

    /// Unpaid participant
    static var previewUnpaid: SplitParticipant {
        SplitParticipant(
            personId: MockDataProvider.PersonUUIDs.james,
            amount: 50.00,
            hasPaid: false
        )
    }

    /// Participant with percentage
    static var previewWithPercentage: SplitParticipant {
        SplitParticipant(
            personId: MockDataProvider.PersonUUIDs.david,
            amount: 75.00,
            hasPaid: false,
            percentage: 30
        )
    }

    /// Participant with shares
    static var previewWithShares: SplitParticipant {
        SplitParticipant(
            personId: MockDataProvider.PersonUUIDs.aisha,
            amount: 150.00,
            hasPaid: false,
            shares: 2
        )
    }

    // MARK: - Collections

    /// Mixed paid/unpaid participants
    static var previewMixedList: [SplitParticipant] {
        [previewPaid, previewUnpaid]
    }

    /// All paid participants
    static var previewAllPaidList: [SplitParticipant] {
        [
            SplitParticipant(personId: MockDataProvider.PersonUUIDs.emma, amount: 40.00, hasPaid: true),
            SplitParticipant(personId: MockDataProvider.PersonUUIDs.james, amount: 40.00, hasPaid: true),
            SplitParticipant(personId: MockDataProvider.PersonUUIDs.aisha, amount: 40.00, hasPaid: true)
        ]
    }

    /// All unpaid participants
    static var previewAllUnpaidList: [SplitParticipant] {
        [
            SplitParticipant(personId: MockDataProvider.PersonUUIDs.david, amount: 30.00, hasPaid: false),
            SplitParticipant(personId: MockDataProvider.PersonUUIDs.sofia, amount: 30.00, hasPaid: false),
            SplitParticipant(personId: MockDataProvider.PersonUUIDs.michael, amount: 30.00, hasPaid: false)
        ]
    }
}
#endif
