//
//  BasicDetailsState.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  State management for Step 1: Basic Details
//

import Combine
import SwiftUI

@MainActor
class BasicDetailsState: ObservableObject {

    // MARK: - Published Properties

    @Published var transactionType: TransactionTypeOption = .expense
    @Published var amountString: String = ""
    @Published var selectedCurrency: Currency
    @Published var transactionName: String = ""
    @Published var selectedCategory: TransactionCategory = .food
    @Published var transactionDate: Date = Date()
    @Published var notes: String = ""

    // MARK: - UI State

    @Published var showCurrencyPicker: Bool = false
    @Published var showCategoryPicker: Bool = false
    @Published var showDatePicker: Bool = false

    // MARK: - Computed Properties

    /// Parsed amount with safety checks for NaN and Infinity
    var amount: Double {
        let parsed = Double(amountString) ?? 0
        return parsed.isFinite && parsed >= 0 ? parsed : 0
    }

    /// Formatted amount for display
    var formattedAmount: String {
        return amount.asCurrency
    }

    /// Validates that basic transaction details are complete
    var canProceed: Bool {
        let hasValidAmount = amount > 0
        let hasValidName = !transactionName.trimmingCharacters(in: .whitespaces).isEmpty
        return hasValidAmount && hasValidName
    }

    // MARK: - Initialization

    init() {
        self.selectedCurrency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
    }

    // MARK: - Reset

    func reset() {
        transactionType = .expense
        amountString = ""
        selectedCurrency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
        transactionName = ""
        selectedCategory = .food
        transactionDate = Date()
        notes = ""

        showCurrencyPicker = false
        showCategoryPicker = false
        showDatePicker = false
    }
}
