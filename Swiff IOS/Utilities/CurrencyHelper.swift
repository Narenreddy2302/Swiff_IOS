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

// MARK: - MoneyAmount (Decimal-based)

/// Thread-safe, precision-preserving monetary amount representation using Decimal
struct MoneyAmount: Codable, Equatable, Comparable, Hashable {

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
    var abs: MoneyAmount {
        return MoneyAmount(Swift.abs(amount))
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

    /// Add two monetary amounts
    static func + (lhs: MoneyAmount, rhs: MoneyAmount) -> MoneyAmount {
        return MoneyAmount(lhs.amount + rhs.amount)
    }

    /// Subtract two monetary amounts
    static func - (lhs: MoneyAmount, rhs: MoneyAmount) -> MoneyAmount {
        return MoneyAmount(lhs.amount - rhs.amount)
    }

    /// Multiply monetary amount by Decimal
    static func * (lhs: MoneyAmount, rhs: Decimal) -> MoneyAmount {
        return MoneyAmount(lhs.amount * rhs)
    }

    /// Multiply monetary amount by Int
    static func * (lhs: MoneyAmount, rhs: Int) -> MoneyAmount {
        return MoneyAmount(lhs.amount * Decimal(rhs))
    }

    /// Divide monetary amount by Decimal
    static func / (lhs: MoneyAmount, rhs: Decimal) throws -> MoneyAmount {
        guard rhs != 0 else {
            throw CurrencyError.divisionByZero
        }
        return MoneyAmount(lhs.amount / rhs)
    }

    /// Divide monetary amount by Int
    static func / (lhs: MoneyAmount, rhs: Int) throws -> MoneyAmount {
        guard rhs != 0 else {
            throw CurrencyError.divisionByZero
        }
        return MoneyAmount(lhs.amount / Decimal(rhs))
    }

    // MARK: - Compound Assignment

    static func += (lhs: inout MoneyAmount, rhs: MoneyAmount) {
        lhs = MoneyAmount(lhs.amount + rhs.amount)
    }

    static func -= (lhs: inout MoneyAmount, rhs: MoneyAmount) {
        lhs = MoneyAmount(lhs.amount - rhs.amount)
    }

    // MARK: - Comparison

    static func < (lhs: MoneyAmount, rhs: MoneyAmount) -> Bool {
        return lhs.amount < rhs.amount
    }

    static func > (lhs: MoneyAmount, rhs: MoneyAmount) -> Bool {
        return lhs.amount > rhs.amount
    }

    static func <= (lhs: MoneyAmount, rhs: MoneyAmount) -> Bool {
        return lhs.amount <= rhs.amount
    }

    static func >= (lhs: MoneyAmount, rhs: MoneyAmount) -> Bool {
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
    ) -> MoneyAmount {
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

        return MoneyAmount(rounded.decimalValue)
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

    /// Convert Double to MoneyAmount safely
    static func fromDouble(_ value: Double) -> MoneyAmount {
        return MoneyAmount(double: value)
    }

    /// Convert MoneyAmount to Double (for backward compatibility)
    static func toDouble(_ amount: MoneyAmount) -> Double {
        return amount.doubleValue
    }

    /// Parse monetary amount from string
    static func parse(_ string: String) throws -> MoneyAmount {
        // Remove currency symbols and whitespace
        let cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let amount = MoneyAmount(string: cleaned) else {
            throw CurrencyError.invalidAmount(string)
        }

        return amount
    }

    /// Calculate percentage
    static func percentage(_ amount: MoneyAmount, percent: Decimal) -> MoneyAmount {
        return amount * (percent / 100)
    }

    /// Apply discount
    static func applyDiscount(_ amount: MoneyAmount, percent: Decimal) -> MoneyAmount {
        let discount = percentage(amount, percent: percent)
        return amount - discount
    }

    /// Apply tax
    static func applyTax(_ amount: MoneyAmount, percent: Decimal) -> MoneyAmount {
        let tax = percentage(amount, percent: percent)
        return amount + tax
    }

    /// Split amount evenly
    static func splitEvenly(_ amount: MoneyAmount, ways: Int) throws -> [MoneyAmount] {
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
            splits[index] += MoneyAmount(double: 0.01)
            remainder -= MoneyAmount(double: 0.01)
            index += 1
        }

        return splits
    }
}

// MARK: - Extensions

extension MoneyAmount: CustomStringConvertible {
    var description: String {
        return formatted()
    }
}

extension MoneyAmount: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.amount = Decimal(value)
    }
}

extension MoneyAmount: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.amount = Decimal(value)
    }
}

// MARK: - Common MoneyAmount Values

extension MoneyAmount {
    static let zero = MoneyAmount(0)
    static let one = MoneyAmount(1)
    static let hundred = MoneyAmount(100)
}
