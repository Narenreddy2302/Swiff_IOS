//
//  DateFormatters.swift
//  Swiff IOS
//
//  Card date formatting extensions for Transaction Card component
//

import Foundation

// MARK: - Card Date Formatting

extension Date {
    /// Formats date as "12th July, 2024" for card displays
    var cardFormattedDate: String {
        let day = Calendar.current.component(.day, from: self)
        let ordinal = day.ordinalSuffix

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, yyyy"
        let monthYear = formatter.string(from: self)

        return "\(day)\(ordinal) \(monthYear)"
    }

    /// Formats date as "Jul 12" for compact displays
    var shortCardDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

// MARK: - Ordinal Suffix

extension Int {
    /// Returns ordinal suffix (st, nd, rd, th) for the integer
    var ordinalSuffix: String {
        let ones = self % 10
        let tens = (self / 10) % 10

        // Special case for 11, 12, 13
        if tens == 1 { return "th" }

        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}
