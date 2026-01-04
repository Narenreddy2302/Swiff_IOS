//
//  TransactionModel.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  SwiftData entity for Transaction persistence
//

import Foundation
import SwiftData

@Model
final class TransactionModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    var amount: Double
    var categoryRaw: String
    var date: Date
    var isRecurring: Bool
    var tags: [String]
    var payerId: UUID?
    var payeeId: UUID?

    // Page 2 Enhancements - New fields for schema V2
    var merchant: String?
    var paymentStatusRaw: String
    var receiptData: Data?
    var linkedSubscriptionId: UUID?

    // Agent 13: Data Model Enhancements - Additional fields
    var merchantCategory: String?
    var isRecurringCharge: Bool
    var paymentMethodRaw: String?
    var location: String?
    var notes: String

    // Split Transaction Support
    var splitBillId: UUID?

    // Transaction Type for feed display
    var transactionTypeRaw: String?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var relatedPerson: PersonModel?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        amount: Double,
        category: TransactionCategory,
        date: Date = Date(),
        isRecurring: Bool = false,
        tags: [String] = [],
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
        self.categoryRaw = category.rawValue
        self.date = date
        self.isRecurring = isRecurring
        self.tags = tags
        self.merchant = merchant
        self.paymentStatusRaw = paymentStatus.rawValue
        self.receiptData = receiptData
        self.linkedSubscriptionId = linkedSubscriptionId
        self.merchantCategory = merchantCategory
        self.isRecurringCharge = isRecurringCharge
        self.paymentMethodRaw = paymentMethod?.rawValue
        self.location = location
        self.notes = notes
        self.splitBillId = splitBillId
        self.transactionTypeRaw = transactionType?.rawValue
        self.relatedPerson = nil
    }

    // Convert to domain model
    func toDomain() -> Transaction {
        let category = TransactionCategory(rawValue: categoryRaw) ?? .other
        let paymentStatus = PaymentStatus(rawValue: paymentStatusRaw) ?? .completed
        let paymentMethod = paymentMethodRaw != nil ? PaymentMethod(rawValue: paymentMethodRaw!) : nil
        let transactionType =
            transactionTypeRaw != nil ? TransactionType(rawValue: transactionTypeRaw!) : nil

        return Transaction(
            id: id,
            title: title,
            subtitle: subtitle,
            amount: amount,
            category: category,
            date: date,
            isRecurring: isRecurring,
            tags: tags,
            merchant: merchant,
            paymentStatus: paymentStatus,
            receiptData: receiptData,
            linkedSubscriptionId: linkedSubscriptionId,
            merchantCategory: merchantCategory,
            isRecurringCharge: isRecurringCharge,
            paymentMethod: paymentMethod,
            location: location,
            notes: notes,
            splitBillId: splitBillId,
            transactionType: transactionType
        )
    }

    /// Convenience initializer from domain model
    convenience init(from transaction: Transaction) {
        self.init(
            id: transaction.id,
            title: transaction.title,
            subtitle: transaction.subtitle,
            amount: transaction.amount,
            category: transaction.category,
            date: transaction.date,
            isRecurring: transaction.isRecurring,
            tags: transaction.tags,
            merchant: transaction.merchant,
            paymentStatus: transaction.paymentStatus,
            receiptData: transaction.receiptData,
            linkedSubscriptionId: transaction.linkedSubscriptionId,
            merchantCategory: transaction.merchantCategory,
            isRecurringCharge: transaction.isRecurringCharge,
            paymentMethod: transaction.paymentMethod,
            location: transaction.location,
            notes: transaction.notes,
            splitBillId: transaction.splitBillId,
            transactionType: transaction.transactionType
        )
    }
}
