//
//  Currency.swift
//  Swiff IOS
//
//  Currency enum with popular world currencies
//

import Foundation

// MARK: - Currency Enum

enum Currency: String, CaseIterable, Codable {
    case USD = "USD"
    case EUR = "EUR"
    case GBP = "GBP"
    case INR = "INR"
    case JPY = "JPY"
    case CAD = "CAD"
    case AUD = "AUD"
    case CNY = "CNY"

    /// Currency symbol for display
    var symbol: String {
        switch self {
        case .USD: return "$"
        case .EUR: return "€"
        case .GBP: return "£"
        case .INR: return "₹"
        case .JPY: return "¥"
        case .CAD: return "C$"
        case .AUD: return "A$"
        case .CNY: return "¥"
        }
    }

    /// Full currency name
    var name: String {
        switch self {
        case .USD: return "US Dollar"
        case .EUR: return "Euro"
        case .GBP: return "British Pound"
        case .INR: return "Indian Rupee"
        case .JPY: return "Japanese Yen"
        case .CAD: return "Canadian Dollar"
        case .AUD: return "Australian Dollar"
        case .CNY: return "Chinese Yuan"
        }
    }

    /// Display text combining symbol and code
    var displayText: String {
        return "\(symbol) \(rawValue)"
    }

    /// Flag emoji for the currency's primary country
    var flag: String {
        switch self {
        case .USD: return "🇺🇸"
        case .EUR: return "🇪🇺"
        case .GBP: return "🇬🇧"
        case .INR: return "🇮🇳"
        case .JPY: return "🇯🇵"
        case .CAD: return "🇨🇦"
        case .AUD: return "🇦🇺"
        case .CNY: return "🇨🇳"
        }
    }

    /// Number of decimal places for this currency
    var decimalPlaces: Int {
        switch self {
        case .JPY: return 0  // Japanese Yen has no decimal places
        default: return 2
        }
    }

    /// Format an amount with the currency symbol
    func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces

        if let formattedNumber = formatter.string(from: NSNumber(value: amount)) {
            return "\(symbol)\(formattedNumber)"
        }
        return "\(symbol)\(amount)"
    }
}
