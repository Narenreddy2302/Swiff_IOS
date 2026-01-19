//
//  CurrencyFormatter.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Centralized currency formatting using user's selected currency
//

import Foundation

class CurrencyFormatter {
    static let shared = CurrencyFormatter()

    private init() {}

    /// Format a currency value using the user's selected currency
    func format(_ value: Double, currency: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        // Use provided currency or user's selected currency
        let selectedCurrency = currency ?? UserSettings.shared.selectedCurrency

        // Set currency code based on selection
        switch selectedCurrency {
        case "USD":
            formatter.currencySymbol = "$"
            formatter.currencyCode = "USD"
        case "EUR":
            formatter.currencySymbol = "€"
            formatter.currencyCode = "EUR"
        case "GBP":
            formatter.currencySymbol = "£"
            formatter.currencyCode = "GBP"
        case "JPY":
            formatter.currencySymbol = "¥"
            formatter.currencyCode = "JPY"
            formatter.maximumFractionDigits = 0 // JPY doesn't use decimal places
            formatter.minimumFractionDigits = 0
        case "CAD":
            formatter.currencySymbol = "CA$"
            formatter.currencyCode = "CAD"
        case "AUD":
            formatter.currencySymbol = "A$"
            formatter.currencyCode = "AUD"
        case "INR":
            formatter.currencySymbol = "₹"
            formatter.currencyCode = "INR"
        default:
            formatter.currencySymbol = "$"
            formatter.currencyCode = "USD"
        }

        return formatter.string(from: NSNumber(value: value)) ?? "\(formatter.currencySymbol ?? "$")0.00"
    }

    /// Format a currency value with sign (+ or -)
    func formatWithSign(_ value: Double, currency: String? = nil) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(format(value, currency: currency))"
    }

    /// Format absolute value (always positive)
    func formatAbsolute(_ value: Double, currency: String? = nil) -> String {
        return format(abs(value), currency: currency)
    }

    /// Get currency symbol for selected currency
    func getCurrencySymbol(for currency: String? = nil) -> String {
        let selectedCurrency = currency ?? UserSettings.shared.selectedCurrency

        switch selectedCurrency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        case "INR": return "₹"
        default: return "$"
        }
    }
}

// Extension for Double to make formatting easier
extension Double {
    var asCurrency: String {
        CurrencyFormatter.shared.format(self)
    }

    var asCurrencyWithSign: String {
        CurrencyFormatter.shared.formatWithSign(self)
    }

    var asAbsoluteCurrency: String {
        CurrencyFormatter.shared.formatAbsolute(self)
    }
}
