//
//  PriceChangeModel.swift
//  Swiff IOS
//
//  Created for Page 4 Task 4.7b - Price History Tracking
//  SwiftData entity for PriceChange persistence
//

import Foundation
import SwiftData

@Model
final class PriceChangeModel {
    @Attribute(.unique) var id: UUID
    var subscriptionId: UUID
    var oldPrice: Double
    var newPrice: Double
    var changeDate: Date
    var reason: String?
    var detectedAutomatically: Bool

    init(id: UUID = UUID(), subscriptionId: UUID, oldPrice: Double, newPrice: Double, changeDate: Date = Date(), reason: String? = nil, detectedAutomatically: Bool = false) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.oldPrice = oldPrice
        self.newPrice = newPrice
        self.changeDate = changeDate
        self.reason = reason
        self.detectedAutomatically = detectedAutomatically
    }

    // Convert to domain model
    func toDomain() -> PriceChange {
        return PriceChange(
            id: id,
            subscriptionId: subscriptionId,
            oldPrice: oldPrice,
            newPrice: newPrice,
            changeDate: changeDate,
            reason: reason,
            detectedAutomatically: detectedAutomatically
        )
    }

    /// Convenience initializer from domain model
    convenience init(from priceChange: PriceChange) {
        self.init(
            id: priceChange.id,
            subscriptionId: priceChange.subscriptionId,
            oldPrice: priceChange.oldPrice,
            newPrice: priceChange.newPrice,
            changeDate: priceChange.changeDate,
            reason: priceChange.reason,
            detectedAutomatically: priceChange.detectedAutomatically
        )
    }
}
