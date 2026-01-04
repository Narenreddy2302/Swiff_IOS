//
//  Transaction.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Combine
import Foundation

// MARK: - Transaction Model

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let subtitle: String
    let amount: Double
    var category: TransactionCategory
    let date: Date
    let isRecurring: Bool
    var tags: [String]

    // Page 2 Enhancements - New fields
    var merchant: String?  // Merchant/vendor name
    var paymentStatus: PaymentStatus  // Transaction status
    var receiptData: Data?  // Attached receipt image
    var linkedSubscriptionId: UUID?  // Link to subscription

    // Agent 13: Data Model Enhancements - Additional fields
    var merchantCategory: String?  // MCC code or category (e.g., "Restaurants", "Gas Stations")
    var isRecurringCharge: Bool  // Whether this is a recurring charge
    var paymentMethod: PaymentMethod?  // Which payment method was used
    var location: String?  // Where transaction occurred (city, store, etc.)
    var notes: String  // User notes about the transaction

    // Split Transaction Support
    var splitBillId: UUID?  // Reference to SplitBill if this is a split transaction

    // Transaction Type for feed display
    var transactionType: TransactionType?  // Optional - can be derived if not set

    // Initialize with default values for backward compatibility
    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        amount: Double,
        category: TransactionCategory,
        date: Date,
        isRecurring: Bool,
        tags: [String],
        merchant: String? = nil,
        paymentStatus: PaymentStatus = .completed,
        receiptData: Data? = nil,
        linkedSubscriptionId: UUID? = nil,
        merchantCategory: String? = nil,
        isRecurringCharge: Bool = false,
        paymentMethod: PaymentMethod? = nil,
        location: String? = nil,
        notes: String = "",
        splitBillId: UUID? = nil,
        transactionType: TransactionType? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.category = category
        self.date = date
        self.isRecurring = isRecurring
        self.tags = tags
        self.merchant = merchant
        self.paymentStatus = paymentStatus
        self.receiptData = receiptData
        self.linkedSubscriptionId = linkedSubscriptionId
        self.merchantCategory = merchantCategory
        self.isRecurringCharge = isRecurringCharge
        self.paymentMethod = paymentMethod
        self.location = location
        self.notes = notes
        self.splitBillId = splitBillId
        self.transactionType = transactionType
    }

    var isExpense: Bool {
        return amount < 0
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }

    var amountWithSign: String {
        let sign = isExpense ? "-" : "+"
        return "\(sign)\(formattedAmount)"
    }

    // New computed properties for Page 2
    var hasReceipt: Bool {
        return receiptData != nil
    }

    var isLinkedToSubscription: Bool {
        return linkedSubscriptionId != nil
    }

    var displayMerchant: String {
        return merchant ?? category.rawValue
    }

    // Split transaction computed properties
    var isSplitTransaction: Bool {
        return splitBillId != nil
    }

    /// Derives transaction type from existing data if not explicitly set
    /// Priority: explicit type > pending status > transfer category > income > merchant payment > send
    var derivedTransactionType: TransactionType {
        // Use explicit type if set
        if let explicitType = transactionType {
            return explicitType
        }

        // Pending status means request
        if paymentStatus == .pending {
            return .request
        }

        // Transfer category
        if category == .transfer {
            return .transfer
        }

        // Positive amounts are income (receive)
        if !isExpense {
            return .receive
        }

        // Has merchant or merchant-like categories = payment
        if merchant != nil ||
            [.food, .transportation, .utilities, .bills, .shopping, .entertainment, .groceries, .healthcare]
            .contains(category)
        {
            return .payment
        }

        // Default to send for person-to-person
        return .send
    }

    /// Formatted time string for feed display (e.g., "10:30 AM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Display name for feed (merchant or title)
    var displayName: String {
        merchant ?? title
    }
}
