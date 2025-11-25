//
//  CurrencyHelper.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 3.1: Decimal-based currency handling for precision
//

import Foundation

// MARK: - Currency Error

enum CurrencyError: LocalizedError {
    case invalidAmount(String)
    case precisionLoss
    case overflowError
    case divisionByZero

    var errorDescription: String? {
        switch self {
        case .invalidAmount(let value):
            return "Invalid currency amount: '\(value)'"
        case .precisionLoss:
            return "Operation would result in precision loss"
        case .overflowError:
            return "Currency amount exceeds maximum allowed value"
        case .divisionByZero:
            return "Cannot divide currency by zero"
        }
    }
}

// MARK: - Currency (Decimal-based)

/// Thread-safe, precision-preserving currency representation using Decimal
struct Currency: Codable, Equatable, Comparable, Hashable {

    // MARK: - Properties

    private let amount: Decimal

    // MARK: - Initialization

    /// Initialize with Decimal value
    init(_ amount: Decimal) {
        self.amount = amount
    }

    /// Initialize with Double (for backward compatibility)
    /// - Warning: May lose precision for certain values
    init(double value: Double) {
        self.amount = Decimal(value)
    }

    /// Initialize with string
    init?(string value: String) {
        guard let decimal = Decimal(string: value) else {
            return nil
        }
        self.amount = decimal
    }

    /// Initialize with integer
    init(int value: Int) {
        self.amount = Decimal(value)
    }

    // MARK: - Computed Properties

    /// Get Decimal value
    var decimalValue: Decimal {
        return amount
    }

    /// Get Double value (for compatibility with existing code)
    /// - Warning: May lose precision
    var doubleValue: Double {
        return NSDecimalNumber(decimal: amount).doubleValue
    }

    /// Get integer value (truncated)
    var intValue: Int {
        return NSDecimalNumber(decimal: amount).intValue
    }

    /// Check if amount is zero
    var isZero: Bool {
        return amount == 0
    }

    /// Check if amount is positive
    var isPositive: Bool {
        return amount > 0
    }

    /// Check if amount is negative
    var isNegative: Bool {
        return amount < 0
    }

    /// Absolute value
    var abs: Currency {
        return Currency(Swift.abs(amount))
    }

    // MARK: - Formatting

    /// Format as currency string
    func formatted(
        currencyCode: String = "USD",
        locale: Locale = .current,
        showSymbol: Bool = true,
        minimumFractionDigits: Int = 2,
        maximumFractionDigits: Int = 2
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits

        if !showSymbol {
            formatter.currencySymbol = ""
        }

        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    /// Format as plain number string
    func formattedPlain(decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces

        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0.00"
    }

    // MARK: - Arithmetic Operations

    /// Add two currency values
    static func + (lhs: Currency, rhs: Currency) -> Currency {
        return Currency(lhs.amount + rhs.amount)
    }

    /// Subtract two currency values
    static func - (lhs: Currency, rhs: Currency) -> Currency {
        return Currency(lhs.amount - rhs.amount)
    }

    /// Multiply currency by Decimal
    static func * (lhs: Currency, rhs: Decimal) -> Currency {
        return Currency(lhs.amount * rhs)
    }

    /// Multiply currency by Int
    static func * (lhs: Currency, rhs: Int) -> Currency {
        return Currency(lhs.amount * Decimal(rhs))
    }

    /// Divide currency by Decimal
    static func / (lhs: Currency, rhs: Decimal) throws -> Currency {
        guard rhs != 0 else {
            throw CurrencyError.divisionByZero
        }
        return Currency(lhs.amount / rhs)
    }

    /// Divide currency by Int
    static func / (lhs: Currency, rhs: Int) throws -> Currency {
        guard rhs != 0 else {
            throw CurrencyError.divisionByZero
        }
        return Currency(lhs.amount / Decimal(rhs))
    }

    // MARK: - Compound Assignment

    static func += (lhs: inout Currency, rhs: Currency) {
        lhs = Currency(lhs.amount + rhs.amount)
    }

    static func -= (lhs: inout Currency, rhs: Currency) {
        lhs = Currency(lhs.amount - rhs.amount)
    }

    // MARK: - Comparison

    static func < (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.amount < rhs.amount
    }

    static func > (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.amount > rhs.amount
    }

    static func <= (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.amount <= rhs.amount
    }

    static func >= (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.amount >= rhs.amount
    }

    // MARK: - Rounding

    enum RoundingMode {
        case up
        case down
        case nearest
        case bankers
    }

    /// Round to specified decimal places
    func rounded(
        toPlaces places: Int = 2,
        mode: RoundingMode = .nearest
    ) -> Currency {
        let roundingMode: NSDecimalNumber.RoundingMode

        switch mode {
        case .up:
            roundingMode = .up
        case .down:
            roundingMode = .down
        case .nearest:
            roundingMode = .plain
        case .bankers:
            roundingMode = .bankers
        }

        let handler = NSDecimalNumberHandler(
            roundingMode: roundingMode,
            scale: Int16(places),
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )

        let decimal = NSDecimalNumber(decimal: amount)
        let rounded = decimal.rounding(accordingToBehavior: handler)

        return Currency(rounded.decimalValue)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case amount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode as Decimal first
        if let decimal = try? container.decode(Decimal.self, forKey: .amount) {
            self.amount = decimal
        }
        // Fallback to Double for backward compatibility
        else if let double = try? container.decode(Double.self, forKey: .amount) {
            self.amount = Decimal(double)
        }
        // Fallback to String
        else if let string = try? container.decode(String.self, forKey: .amount),
                let decimal = Decimal(string: string) {
            self.amount = decimal
        } else {
            throw CurrencyError.invalidAmount("Unable to decode currency amount")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
    }
}

// MARK: - CurrencyHelper Utilities

enum CurrencyHelper {

    /// Convert Double to Currency safely
    static func fromDouble(_ value: Double) -> Currency {
        return Currency(double: value)
    }

    /// Convert Currency to Double (for backward compatibility)
    static func toDouble(_ currency: Currency) -> Double {
        return currency.doubleValue
    }

    /// Parse currency from string
    static func parse(_ string: String) throws -> Currency {
        // Remove currency symbols and whitespace
        let cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let currency = Currency(string: cleaned) else {
            throw CurrencyError.invalidAmount(string)
        }

        return currency
    }

    /// Calculate percentage
    static func percentage(_ amount: Currency, percent: Decimal) -> Currency {
        return amount * (percent / 100)
    }

    /// Apply discount
    static func applyDiscount(_ amount: Currency, percent: Decimal) -> Currency {
        let discount = percentage(amount, percent: percent)
        return amount - discount
    }

    /// Apply tax
    static func applyTax(_ amount: Currency, percent: Decimal) -> Currency {
        let tax = percentage(amount, percent: percent)
        return amount + tax
    }

    /// Split amount evenly
    static func splitEvenly(_ amount: Currency, ways: Int) throws -> [Currency] {
        guard ways > 0 else {
            throw CurrencyError.divisionByZero
        }

        let perPerson = try amount / ways
        let rounded = perPerson.rounded(toPlaces: 2)

        // Calculate remainder to distribute
        let total = rounded * ways
        var remainder = amount - total

        var splits = Array(repeating: rounded, count: ways)

        // Distribute remainder (usually a few cents)
        var index = 0
        while !remainder.isZero && index < ways {
            splits[index] += Currency(double: 0.01)
            remainder -= Currency(double: 0.01)
            index += 1
        }

        return splits
    }
}

// MARK: - Extensions

extension Currency: CustomStringConvertible {
    var description: String {
        return formatted()
    }
}

extension Currency: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.amount = Decimal(value)
    }
}

extension Currency: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.amount = Decimal(value)
    }
}

// MARK: - Common Currency Values

extension Currency {
    static let zero = Currency(0)
    static let one = Currency(1)
    static let hundred = Currency(100)
}
