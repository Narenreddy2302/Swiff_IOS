//
//  Transaction+Preview.swift
//  Swiff IOS
//
//  Preview extensions for Transaction model
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension Transaction {

    // MARK: - By Transaction Type

    /// Receive/Income transaction
    static var previewReceive: Transaction {
        MockDataProvider.shared.receiveTransactions[0]
    }

    /// Send transaction
    static var previewSend: Transaction {
        MockDataProvider.shared.sendTransactions[0]
    }

    /// Payment transaction (merchant)
    static var previewPayment: Transaction {
        MockDataProvider.shared.paymentTransactions[0]
    }

    /// Transfer transaction
    static var previewTransfer: Transaction {
        MockDataProvider.shared.transferTransactions[0]
    }

    /// Request transaction (pending)
    static var previewRequest: Transaction {
        MockDataProvider.shared.requestTransactions[0]
    }

    // MARK: - By Payment Status

    /// Completed transaction
    static var previewCompleted: Transaction {
        MockDataProvider.shared.paymentTransactions[0]
    }

    /// Pending transaction
    static var previewPending: Transaction {
        MockDataProvider.shared.requestTransactions[0]
    }

    /// Failed transaction
    static var previewFailed: Transaction {
        MockDataProvider.shared.requestTransactions.first { $0.paymentStatus == .failed } ?? previewPending
    }

    /// Cancelled transaction
    static var previewCancelled: Transaction {
        MockDataProvider.shared.requestTransactions.first { $0.paymentStatus == .cancelled } ?? previewPending
    }

    // MARK: - Edge Cases

    /// Large amount transaction ($5,000+)
    static var previewLargeAmount: Transaction {
        MockDataProvider.shared.receiveTransactions[0] // Salary $5,250
    }

    /// Small amount transaction (<$10)
    static var previewSmallAmount: Transaction {
        MockDataProvider.shared.paymentTransactions[0] // Coffee $5.75
    }

    /// Transaction linked to subscription
    static var previewLinkedToSubscription: Transaction {
        MockDataProvider.shared.paymentTransactions.first { $0.linkedSubscriptionId != nil } ?? previewPayment
    }

    /// Recurring transaction
    static var previewRecurring: Transaction {
        MockDataProvider.shared.receiveTransactions[0] // Salary (recurring)
    }

    /// Transaction with location
    static var previewWithLocation: Transaction {
        MockDataProvider.shared.paymentTransactions[0] // Coffee shop with location
    }

    // MARK: - By Category

    /// Income category transaction
    static var previewIncome: Transaction {
        MockDataProvider.shared.receiveTransactions[0]
    }

    /// Food category transaction
    static var previewFood: Transaction {
        MockDataProvider.shared.paymentTransactions[0]
    }

    /// Transportation category transaction
    static var previewTransportation: Transaction {
        MockDataProvider.shared.paymentTransactions.first { $0.category == .transportation } ?? previewPayment
    }

    /// Entertainment category transaction
    static var previewEntertainment: Transaction {
        MockDataProvider.shared.sendTransactions.first { $0.category == .entertainment } ?? previewSend
    }

    // MARK: - Collections

    /// First page of transactions (10 items, mixed types)
    static var previewPage1: [Transaction] {
        Array(MockDataProvider.shared.allTransactions.prefix(10))
    }

    /// All transactions (50+ items)
    static var previewAllPages: [Transaction] {
        MockDataProvider.shared.allTransactions
    }

    /// Only receive/income transactions
    static var previewReceiveList: [Transaction] {
        MockDataProvider.shared.receiveTransactions
    }

    /// Only send transactions
    static var previewSendList: [Transaction] {
        MockDataProvider.shared.sendTransactions
    }

    /// Only payment transactions
    static var previewPaymentList: [Transaction] {
        MockDataProvider.shared.paymentTransactions
    }

    /// Only transfer transactions
    static var previewTransferList: [Transaction] {
        MockDataProvider.shared.transferTransactions
    }

    /// Only request transactions
    static var previewRequestList: [Transaction] {
        MockDataProvider.shared.requestTransactions
    }

    /// Today's transactions
    static var previewToday: [Transaction] {
        let calendar = Calendar.current
        return MockDataProvider.shared.allTransactions.filter {
            calendar.isDateInToday($0.date)
        }
    }

    /// Empty array for empty state
    static var previewEmpty: [Transaction] {
        []
    }

    // MARK: - Random

    /// Random transaction
    static var previewRandom: Transaction {
        MockDataProvider.shared.allTransactions.randomElement() ?? previewPayment
    }
}
#endif
