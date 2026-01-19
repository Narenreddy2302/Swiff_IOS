//
//  SplitMethodState.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  State management for Step 3: Split Method & Calculations
//

import Combine
import SwiftUI

// MARK: - Split Detail Model

struct SplitDetail: Equatable {
    var amount: Double = 0
    var percentage: Double = 0
    var shares: Int = 1
    var adjustment: Double = 0

    /// Tolerance-based equality for floating point comparisons
    static func == (lhs: SplitDetail, rhs: SplitDetail) -> Bool {
        return abs(lhs.amount - rhs.amount) < 0.001 && abs(lhs.percentage - rhs.percentage) < 0.001
            && lhs.shares == rhs.shares && abs(lhs.adjustment - rhs.adjustment) < 0.001
    }
}

@MainActor
class SplitMethodState: ObservableObject {

    // MARK: - Published Properties

    @Published var splitMethod: SplitType = .equally
    @Published var splitDetails: [UUID: SplitDetail] = [:]

    // MARK: - Internal Helper

    private let epsilon: Double = 0.01

    // MARK: - Calculations

    func calculateSplits(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        let count = Double(participantIds.count)
        guard count > 0, amount > 0 else { return [:] }

        switch splitMethod {
        case .equally:
            let perPersonAmount = amount / count
            let perPersonPercentage = 100.0 / count
            return participantIds.reduce(into: [:]) { result, id in
                result[id] = SplitDetail(
                    amount: perPersonAmount,
                    percentage: perPersonPercentage,
                    shares: 1
                )
            }

        case .exactAmounts:
            return participantIds.reduce(into: [:]) { result, id in
                let detail = splitDetails[id] ?? SplitDetail()
                result[id] = SplitDetail(
                    amount: detail.amount,
                    percentage: amount > 0 ? (detail.amount / amount) * 100 : 0,
                    shares: 1
                )
            }

        case .percentages:
            return participantIds.reduce(into: [:]) { result, id in
                let detail = splitDetails[id] ?? SplitDetail()
                result[id] = SplitDetail(
                    amount: (detail.percentage / 100) * amount,
                    percentage: detail.percentage,
                    shares: 1
                )
            }

        case .shares:
            let totalShares = totalShares(participantIds: participantIds)
            let totalSharesDouble = Double(totalShares)
            guard totalSharesDouble > 0 else { return [:] }

            return participantIds.reduce(into: [:]) { result, id in
                let shares = splitDetails[id]?.shares ?? 1
                let shareDouble = Double(shares)
                result[id] = SplitDetail(
                    amount: (shareDouble / totalSharesDouble) * amount,
                    percentage: (shareDouble / totalSharesDouble) * 100,
                    shares: shares
                )
            }

        case .adjustments:
            let totalAdjustments = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.adjustment ?? 0)
            }
            let baseAmount = (amount - totalAdjustments) / count

            return participantIds.reduce(into: [:]) { result, id in
                let adjustment = splitDetails[id]?.adjustment ?? 0
                let personAmount = baseAmount + adjustment
                result[id] = SplitDetail(
                    amount: max(0, personAmount),
                    percentage: amount > 0 ? (max(0, personAmount) / amount) * 100 : 0,
                    shares: 1,
                    adjustment: adjustment
                )
            }
        }
    }

    func totalShares(participantIds: Set<UUID>) -> Int {
        participantIds.reduce(0) { sum, id in
            sum + (splitDetails[id]?.shares ?? 1)
        }
    }

    // MARK: - Validation

    func isBalanced(amount: Double, participantIds: Set<UUID>) -> Bool {
        guard participantIds.count >= 2, amount > 0 else { return false }

        switch splitMethod {
        case .equally:
            return true

        case .shares:
            return totalShares(participantIds: participantIds) > 0

        case .exactAmounts:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.amount ?? 0)
            }
            return abs(total - amount) < epsilon

        case .percentages:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.percentage ?? 0)
            }
            return abs(total - 100) < 0.1

        case .adjustments:
            return true
        }
    }

    func validationMessage(amount: Double, participantIds: Set<UUID>) -> String? {
        switch splitMethod {
        case .equally:
            let count = Double(participantIds.count)
            let perPerson = count > 0 ? amount / count : 0
            return "Split equally: \(perPerson.asCurrency) each"

        case .exactAmounts:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.amount ?? 0)
            }
            if abs(total - amount) < epsilon {
                return "Amounts match total"
            } else {
                let remaining = amount - total
                // Use epsilon comparison for remaining amount display
                return remaining > epsilon
                    ? "\(remaining.asCurrency) remaining"
                    : "\(abs(remaining).asCurrency) over"
            }

        case .percentages:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.percentage ?? 0)
            }
            if abs(total - 100) < 0.1 {
                return "Percentages add up to 100%"
            } else {
                return "Total: \(String(format: "%.0f", total))% / 100%"
            }

        case .shares:
            let total = totalShares(participantIds: participantIds)
            return "\(total) share\(total == 1 ? "" : "s") total"

        case .adjustments:
            let totalAdjustments = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.adjustment ?? 0)
            }
            let sign = totalAdjustments >= 0 ? "+" : ""
            return "Adjustments: \(sign)\(totalAdjustments.asCurrency)"
        }
    }

    // MARK: - Updates

    func updateSplitAmount(for personId: UUID, amount: Double) {
        var detail = splitDetails[personId] ?? SplitDetail()
        detail.amount = max(0, amount)
        splitDetails[personId] = detail
    }

    func updateSplitPercentage(for personId: UUID, percentage: Double) {
        var detail = splitDetails[personId] ?? SplitDetail()
        detail.percentage = max(0, min(100, percentage))
        splitDetails[personId] = detail
    }

    func updateSplitShares(for personId: UUID, shares: Int) {
        var detail = splitDetails[personId] ?? SplitDetail()
        detail.shares = max(1, min(10, shares))
        splitDetails[personId] = detail
    }

    func updateSplitAdjustment(for personId: UUID, adjustment: Double) {
        var detail = splitDetails[personId] ?? SplitDetail()
        detail.adjustment = adjustment
        splitDetails[personId] = detail
    }

    func initializeDefaults(for participantIds: Set<UUID>, totalAmount: Double) {
        let count = Double(participantIds.count)
        guard count > 0 else { return }

        for personId in participantIds where splitDetails[personId] == nil {
            switch splitMethod {
            case .equally: break
            case .exactAmounts:
                splitDetails[personId] = SplitDetail(amount: totalAmount / count)
            case .percentages:
                splitDetails[personId] = SplitDetail(percentage: 100.0 / count)
            case .shares:
                splitDetails[personId] = SplitDetail(shares: 1)
            case .adjustments:
                splitDetails[personId] = SplitDetail(adjustment: 0)
            }
        }
    }

    // MARK: - Reset

    func reset() {
        splitMethod = .equally
        splitDetails.removeAll()
    }
}
