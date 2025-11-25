//
//  PriceChange.swift
//  Swiff IOS
//
//  Created for Page 4 Task 4.7b - Price History Tracking
//

import Foundation

// MARK: - Price Change Model

struct PriceChange: Identifiable, Codable {
    var id: UUID = UUID()
    var subscriptionId: UUID
    var oldPrice: Double
    var newPrice: Double
    var changeDate: Date = Date()
    var reason: String?
    var detectedAutomatically: Bool = false

    // Computed properties
    var changeAmount: Double {
        return newPrice - oldPrice
    }

    var changePercentage: Double {
        guard oldPrice > 0 else { return 0 }
        return ((newPrice - oldPrice) / oldPrice) * 100
    }

    var isIncrease: Bool {
        return newPrice > oldPrice
    }

    var formattedChangeAmount: String {
        let sign = isIncrease ? "+" : ""
        return String(format: "%@$%.2f", sign, abs(changeAmount))
    }

    var formattedChangePercentage: String {
        let sign = isIncrease ? "+" : ""
        return String(format: "%@%.1f%%", sign, changePercentage)
    }
}
