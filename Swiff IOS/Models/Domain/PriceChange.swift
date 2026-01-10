//
//  PriceChange.swift
//  Swiff IOS
//
//  Created for Page 4 Task 4.7b - Price History Tracking
//

import Foundation

// MARK: - Price Change Model

public struct PriceChange: Identifiable, Codable {
    public var id: UUID = UUID()
    public var subscriptionId: UUID
    public var oldPrice: Double
    public var newPrice: Double
    public var changeDate: Date = Date()
    public var reason: String?
    public var detectedAutomatically: Bool = false

    public init(
        id: UUID = UUID(), subscriptionId: UUID, oldPrice: Double, newPrice: Double,
        changeDate: Date = Date(), reason: String? = nil, detectedAutomatically: Bool = false
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.oldPrice = oldPrice
        self.newPrice = newPrice
        self.changeDate = changeDate
        self.reason = reason
        self.detectedAutomatically = detectedAutomatically
    }

    // Computed properties
    public var changeAmount: Double {
        return newPrice - oldPrice
    }

    public var changePercentage: Double {
        guard oldPrice > 0 else { return 0 }
        return ((newPrice - oldPrice) / oldPrice) * 100
    }

    public var isIncrease: Bool {
        return newPrice > oldPrice
    }

    public var formattedChangeAmount: String {
        let sign = isIncrease ? "+" : "-"
        return "\(sign)\(abs(changeAmount).asCurrency)"
    }

    public var formattedChangePercentage: String {
        let sign = isIncrease ? "+" : ""
        return String(format: "%@%.1f%%", sign, changePercentage)
    }

    // MARK: - Supabase Conversion

    func toSupabaseModel() -> SupabasePriceChange {
        SupabasePriceChange(
            id: id,
            subscriptionId: subscriptionId,
            oldPrice: Decimal(oldPrice),
            newPrice: Decimal(newPrice),
            changeDate: changeDate,
            reason: reason,
            detectedAutomatically: detectedAutomatically,
            createdAt: changeDate,
            updatedAt: Date(),
            deletedAt: nil,
            syncVersion: 1
        )
    }
}
