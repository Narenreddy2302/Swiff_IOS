//
//  SplitBillModel.swift
//  Swiff IOS
//
//  SwiftData persistence model for SplitBill
//

import Foundation
import SwiftData

@Model
final class SplitBillModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var totalAmount: Double
    var paidById: UUID
    var splitTypeRaw: String
    var participantsData: Data  // Encoded [SplitParticipant]
    var notes: String
    var categoryRaw: String
    var date: Date
    var createdDate: Date
    var groupId: UUID?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var paidBy: PersonModel?

    @Relationship(deleteRule: .nullify)
    var group: GroupModel?

    init(from splitBill: SplitBill) {
        self.id = splitBill.id
        self.title = splitBill.title
        self.totalAmount = splitBill.totalAmount
        self.paidById = splitBill.paidById
        self.splitTypeRaw = splitBill.splitType.rawValue
        self.participantsData = (try? JSONEncoder().encode(splitBill.participants)) ?? Data()
        self.notes = splitBill.notes
        self.categoryRaw = splitBill.category.rawValue
        self.date = splitBill.date
        self.createdDate = splitBill.createdDate
        self.groupId = splitBill.groupId
    }

    func toDomain() -> SplitBill {
        let splitType = SplitType(rawValue: splitTypeRaw) ?? .equally
        let category = TransactionCategory(rawValue: categoryRaw) ?? .dining
        let participants = (try? JSONDecoder().decode([SplitParticipant].self, from: participantsData)) ?? []

        var splitBill = SplitBill(
            title: title,
            totalAmount: totalAmount,
            paidById: paidById,
            splitType: splitType,
            participants: participants,
            notes: notes,
            category: category,
            date: date,
            groupId: groupId
        )
        splitBill.id = id
        splitBill.createdDate = createdDate
        return splitBill
    }
}
