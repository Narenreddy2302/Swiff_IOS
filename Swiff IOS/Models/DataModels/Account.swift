//
//  Account.swift
//  Swiff IOS
//
//  Account model for tracking payment sources
//

import SwiftUI

// MARK: - Account Model

struct Account: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String              // "Chase Checking", "HDFC Savings"
    var number: String            // "••4521" (masked)
    var type: AccountType
    var isDefault: Bool
    var createdDate: Date

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
        self.type = type
        self.isDefault = isDefault
        self.createdDate = createdDate
    }

    /// Display string combining name and masked number
    var displayName: String {
        if number.isEmpty {
            return name
        }
        return "\(name) \(number)"
    }
}

// MARK: - Account Type Enum

enum AccountType: String, CaseIterable, Codable {
    case bank = "Bank Account"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case wallet = "Digital Wallet"
    case upi = "UPI"

    /// SF Symbol icon for the account type
    var icon: String {
        switch self {
        case .bank: return "building.columns.fill"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard.fill"
        case .wallet: return "wallet.pass.fill"
        case .upi: return "indianrupeesign.circle.fill"
        }
    }

    /// Color for the account type icon
    var color: Color {
        switch self {
        case .bank: return .wiseForestGreen
        case .creditCard: return .wiseBlue
        case .debitCard: return .wiseOrange
        case .wallet: return Color(red: 0.647, green: 0.400, blue: 0.835)  // Purple
        case .upi: return Color(red: 0.086, green: 0.400, blue: 0.200)     // Dark green
        }
    }

    /// Short display name
    var shortName: String {
        switch self {
        case .bank: return "Bank"
        case .creditCard: return "Credit"
        case .debitCard: return "Debit"
        case .wallet: return "Wallet"
        case .upi: return "UPI"
        }
    }
}

// MARK: - Sample Accounts (for testing/preview)

extension Account {
    static let sampleAccounts: [Account] = [
        Account(name: "Chase Checking", number: "••4521", type: .bank, isDefault: true),
        Account(name: "Visa Credit", number: "••8834", type: .creditCard),
        Account(name: "Apple Pay", number: "", type: .wallet),
        Account(name: "Bank of America", number: "••7712", type: .bank),
        Account(name: "HDFC Savings", number: "••3456", type: .bank),
        Account(name: "Google Pay", number: "", type: .upi)
    ]
}
