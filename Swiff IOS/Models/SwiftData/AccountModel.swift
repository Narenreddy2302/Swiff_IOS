//
//  AccountModel.swift
//  Swiff IOS
//
//  SwiftData entity for Account persistence
//

import Foundation
import SwiftData

@Model
final class AccountModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var number: String
    var typeRaw: String
    var isDefault: Bool
    var createdDate: Date

    // Supabase sync metadata
    var syncVersion: Int = 1
    var deletedAt: Date?
    var pendingSync: Bool = false
    var lastSyncedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        number: String = "",
        type: AccountType,
        isDefault: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.typeRaw = type.rawValue
        self.isDefault = isDefault
        self.createdDate = createdDate
    }

    /// Convert to domain model
    func toDomain() -> Account {
        let accountType = AccountType(rawValue: typeRaw) ?? .bank

        return Account(
            id: id,
            name: name,
            number: number,
            type: accountType,
            isDefault: isDefault,
            createdDate: createdDate
        )
    }

    /// Convenience initializer from domain model
    convenience init(from account: Account) {
        self.init(
            id: account.id,
            name: account.name,
            number: account.number,
            type: account.type,
            isDefault: account.isDefault,
            createdDate: account.createdDate
        )
    }

    /// Update from domain model
    func update(from account: Account) {
        self.name = account.name
        self.number = account.number
        self.typeRaw = account.type.rawValue
        self.isDefault = account.isDefault
    }
}
