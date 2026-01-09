//
//  Account+Preview.swift
//  Swiff IOS
//
//  Preview extensions for Account model
//  Provides convenient access to mock data for SwiftUI previews
//

import Foundation
import SwiftUI

#if DEBUG
extension Account {

    // MARK: - By Type

    /// Default bank account
    static var previewDefault: Account {
        MockDataProvider.shared.accountChase
    }

    /// Bank account (non-default)
    static var previewBank: Account {
        MockDataProvider.shared.accountWellsFargo
    }

    /// Credit card account
    static var previewCreditCard: Account {
        MockDataProvider.shared.accountAppleCard
    }

    /// Savings account
    static var previewSavings: Account {
        MockDataProvider.shared.accountAlly
    }

    /// Digital wallet (PayPal)
    static var previewWalletPayPal: Account {
        MockDataProvider.shared.accountPayPal
    }

    /// Digital wallet (Venmo)
    static var previewWalletVenmo: Account {
        MockDataProvider.shared.accountVenmo
    }

    // MARK: - By Properties

    /// Account with masked number
    static var previewWithNumber: Account {
        MockDataProvider.shared.accountChase // Has "••4521"
    }

    /// Account without number (wallet)
    static var previewWithoutNumber: Account {
        MockDataProvider.shared.accountPayPal // Empty number
    }

    // MARK: - Collections

    /// All accounts (6)
    static var previewList: [Account] {
        MockDataProvider.shared.allAccounts
    }

    /// Bank accounts only
    static var previewBankList: [Account] {
        MockDataProvider.shared.allAccounts.filter { $0.type == .bank }
    }

    /// Wallet accounts only
    static var previewWalletList: [Account] {
        MockDataProvider.shared.allAccounts.filter { $0.type == .wallet }
    }

    /// Card accounts only
    static var previewCardList: [Account] {
        MockDataProvider.shared.allAccounts.filter { $0.type == .creditCard || $0.type == .debitCard }
    }

    /// Empty list for empty state
    static var previewEmpty: [Account] {
        []
    }

    // MARK: - Random

    /// Random account
    static var previewRandom: Account {
        MockDataProvider.shared.allAccounts.randomElement() ?? previewDefault
    }
}
#endif
