//
//  BasicDetailsState.swift
//  Swiff IOS
//
//  State management for Step 1: Transaction Details
//  Cents-based right-to-left currency input for precision
//

import Combine
import SwiftUI

@MainActor
class BasicDetailsState: ObservableObject {

    // MARK: - Published Properties

    /// Amount stored as integer cents for right-to-left currency input precision
    /// Typing 1 → $0.01, typing 2 → $0.12, typing 5 → $1.25
    @Published var amountInCents: Int = 0

    /// Selected currency
    @Published var selectedCurrency: Currency

    /// Transaction name/description
    @Published var transactionName: String = ""

    /// Selected category (nil until user picks one)
    @Published var selectedCategory: TransactionCategory? = nil

    /// Transaction type (expense/income) — defaults to expense
    @Published var transactionType: TransactionTypeOption = .expense

    /// Transaction date — defaults to now
    @Published var transactionDate: Date = Date()

    /// Optional notes
    @Published var notes: String = ""

    /// Whether the custom numeric keypad is active vs system keyboard for name
    @Published var isKeypadActive: Bool = true

    // MARK: - Constants

    /// Maximum: $999,999.99 = 99_999_999 cents
    static let maxCents: Int = 99_999_999

    /// Minimum valid amount: $0.01 = 1 cent
    static let minCents: Int = 1

    /// Character limit for transaction name
    static let nameCharacterLimit: Int = 50

    // MARK: - Computed Properties

    /// Amount as Double for compatibility with existing models
    var amount: Double {
        Double(amountInCents) / 100.0
    }

    /// Backward-compatible amount string
    var amountString: String {
        get { formattedAmountRaw }
        set { /* No-op: amount is driven by keypad */ }
    }

    /// Formatted amount for hero display (e.g., "0.00", "1,250.00")
    var formattedAmountRaw: String {
        let value = Double(amountInCents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }

    /// Currency symbol for display
    var currencySymbol: String {
        selectedCurrency.symbol
    }

    /// Whether the amount is zero (placeholder state)
    var isAmountZero: Bool {
        amountInCents == 0
    }

    /// Validates that all required Step 1 fields are complete
    var canProceed: Bool {
        amountInCents >= Self.minCents
            && !transactionName.trimmingCharacters(in: .whitespaces).isEmpty
            && selectedCategory != nil
    }

    /// Whether name is within 10 characters of the limit
    var isNearCharacterLimit: Bool {
        transactionName.count >= (Self.nameCharacterLimit - 10)
    }

    /// Remaining characters for name input
    var remainingCharacters: Int {
        max(0, Self.nameCharacterLimit - transactionName.count)
    }

    // MARK: - Initialization

    init() {
        self.selectedCurrency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
    }

    // MARK: - Keypad Input Actions

    /// Append a digit (right-to-left: shifts existing digits left, adds new digit on right)
    func appendDigit(_ digit: Int) {
        guard digit >= 0 && digit <= 9 else { return }
        let newCents = amountInCents * 10 + digit
        guard newCents <= Self.maxCents else {
            // At max — provide warning haptic and ignore
            HapticManager.shared.warning()
            return
        }
        amountInCents = newCents
    }

    /// Delete the last digit (rightmost) — shifts digits right
    func deleteLastDigit() {
        amountInCents /= 10
    }

    /// Clear the entire amount
    func clearAmount() {
        amountInCents = 0
    }

    // MARK: - Name Validation

    /// Trim and enforce character limit
    func enforceNameLimit() {
        if transactionName.count > Self.nameCharacterLimit {
            transactionName = String(transactionName.prefix(Self.nameCharacterLimit))
        }
    }

    // MARK: - Reset

    func reset() {
        amountInCents = 0
        selectedCurrency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
        transactionName = ""
        selectedCategory = nil
        transactionType = .expense
        transactionDate = Date()
        notes = ""
        isKeypadActive = true
    }
}
