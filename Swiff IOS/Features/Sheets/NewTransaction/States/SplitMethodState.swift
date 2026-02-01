//
//  SplitMethodState.swift
//  Swiff IOS
//
//  State management for Step 3: Split Method & Calculations
//  Supports 5 split types with proper rounding and penny distribution
//

import Combine
import SwiftUI

// MARK: - Split Detail Model

struct SplitDetail: Equatable {
    var amount: Double = 0
    var percentage: Double = 0
    var shares: Int = 1
    var adjustment: Double = 0

    static func == (lhs: SplitDetail, rhs: SplitDetail) -> Bool {
        abs(lhs.amount - rhs.amount) < 0.001
            && abs(lhs.percentage - rhs.percentage) < 0.001
            && lhs.shares == rhs.shares
            && abs(lhs.adjustment - rhs.adjustment) < 0.001
    }
}

// MARK: - SplitMethodState

@MainActor
class SplitMethodState: ObservableObject {

    // MARK: - Published Properties

    @Published var splitMethod: SplitType = .equally
    @Published var splitDetails: [UUID: SplitDetail] = [:]

    // MARK: - Constants

    private let epsilon: Double = 0.01

    // MARK: - Split Calculations

    /// Calculate splits for all participants based on current method
    func calculateSplits(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        let count = participantIds.count
        guard count > 0, amount > 0 else { return [:] }

        switch splitMethod {
        case .equally:
            return calculateEqualSplit(amount: amount, participantIds: participantIds)

        case .exactAmounts:
            return calculateExactAmounts(amount: amount, participantIds: participantIds)

        case .percentages:
            return calculatePercentages(amount: amount, participantIds: participantIds)

        case .shares:
            return calculateShares(amount: amount, participantIds: participantIds)

        case .adjustments:
            return calculateAdjustments(amount: amount, participantIds: participantIds)
        }
    }

    // MARK: - Equal Split (with penny distribution)

    private func calculateEqualSplit(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        let count = participantIds.count
        let countDouble = Double(count)

        // Calculate base amount per person (floor to 2 decimal places)
        let baseAmountCents = Int(amount * 100) / count
        let remainderCents = Int(amount * 100) - (baseAmountCents * count)

        let baseAmount = Double(baseAmountCents) / 100.0
        let percentage = 100.0 / countDouble

        // Sort participant IDs for deterministic penny distribution
        let sorted = participantIds.sorted()
        var result: [UUID: SplitDetail] = [:]

        for (index, id) in sorted.enumerated() {
            // Distribute remainder pennies to the first N people
            let extraCent = index < remainderCents ? 0.01 : 0.0
            let personAmount = baseAmount + extraCent

            result[id] = SplitDetail(
                amount: personAmount,
                percentage: percentage,
                shares: 1
            )
        }

        return result
    }

    // MARK: - Exact Amounts

    private func calculateExactAmounts(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        return participantIds.reduce(into: [:]) { result, id in
            let detail = splitDetails[id] ?? SplitDetail()
            result[id] = SplitDetail(
                amount: detail.amount,
                percentage: amount > 0 ? (detail.amount / amount) * 100 : 0,
                shares: 1
            )
        }
    }

    // MARK: - Percentages

    private func calculatePercentages(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        return participantIds.reduce(into: [:]) { result, id in
            let detail = splitDetails[id] ?? SplitDetail()
            let personAmount = (detail.percentage / 100.0) * amount
            // Round to 2 decimal places
            let rounded = (personAmount * 100).rounded() / 100.0
            result[id] = SplitDetail(
                amount: rounded,
                percentage: detail.percentage,
                shares: 1
            )
        }
    }

    // MARK: - Shares

    private func calculateShares(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        let totalShareCount = totalShares(participantIds: participantIds)
        guard totalShareCount > 0 else { return [:] }
        let totalSharesDouble = Double(totalShareCount)

        // Use penny distribution for shares too
        let totalCents = Int(amount * 100)
        let sorted = participantIds.sorted()
        var result: [UUID: SplitDetail] = [:]
        var distributedCents = 0

        for (index, id) in sorted.enumerated() {
            let shares = splitDetails[id]?.shares ?? 1
            let shareDouble = Double(shares)
            let percentage = (shareDouble / totalSharesDouble) * 100

            let personCents: Int
            if index == sorted.count - 1 {
                // Last person gets the remainder to avoid rounding errors
                personCents = totalCents - distributedCents
            } else {
                personCents = Int((shareDouble / totalSharesDouble) * Double(totalCents))
            }

            distributedCents += personCents
            let personAmount = Double(personCents) / 100.0

            result[id] = SplitDetail(
                amount: personAmount,
                percentage: percentage,
                shares: shares
            )
        }

        return result
    }

    // MARK: - Adjustments

    private func calculateAdjustments(amount: Double, participantIds: Set<UUID>) -> [UUID: SplitDetail] {
        let count = Double(participantIds.count)
        let totalAdjustments = participantIds.reduce(0.0) { sum, id in
            sum + (splitDetails[id]?.adjustment ?? 0)
        }
        let baseAmount = (amount - totalAdjustments) / count

        return participantIds.reduce(into: [:]) { result, id in
            let adjustment = splitDetails[id]?.adjustment ?? 0
            let personAmount = max(0, baseAmount + adjustment)
            let rounded = (personAmount * 100).rounded() / 100.0
            result[id] = SplitDetail(
                amount: rounded,
                percentage: amount > 0 ? (rounded / amount) * 100 : 0,
                shares: 1,
                adjustment: adjustment
            )
        }
    }

    // MARK: - Totals

    func totalShares(participantIds: Set<UUID>) -> Int {
        participantIds.reduce(0) { sum, id in
            sum + (splitDetails[id]?.shares ?? 1)
        }
    }

    func totalPercentage(participantIds: Set<UUID>) -> Double {
        participantIds.reduce(0.0) { sum, id in
            sum + (splitDetails[id]?.percentage ?? 0)
        }
    }

    func totalAllocatedAmount(participantIds: Set<UUID>) -> Double {
        participantIds.reduce(0.0) { sum, id in
            sum + (splitDetails[id]?.amount ?? 0)
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
            let total = totalAllocatedAmount(participantIds: participantIds)
            return abs(total - amount) < epsilon

        case .percentages:
            let total = totalPercentage(participantIds: participantIds)
            return abs(total - 100.0) < 0.1

        case .adjustments:
            return true
        }
    }

    func remainingAmount(amount: Double, participantIds: Set<UUID>) -> Double {
        switch splitMethod {
        case .equally, .shares, .adjustments:
            return 0
        case .exactAmounts:
            let total = totalAllocatedAmount(participantIds: participantIds)
            return max(0, amount - total)
        case .percentages:
            let total = totalPercentage(participantIds: participantIds)
            return max(0, 100.0 - total)
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
        detail.shares = max(1, min(99, shares))
        splitDetails[personId] = detail
    }

    func updateSplitAdjustment(for personId: UUID, adjustment: Double) {
        var detail = splitDetails[personId] ?? SplitDetail()
        detail.adjustment = adjustment
        splitDetails[personId] = detail
    }

    // MARK: - Initialize Defaults

    func initializeDefaults(for participantIds: Set<UUID>, totalAmount: Double) {
        let count = Double(participantIds.count)
        guard count > 0 else { return }

        // Reset all details for the current method
        var newDetails: [UUID: SplitDetail] = [:]

        for personId in participantIds {
            switch splitMethod {
            case .equally:
                break // No per-person details needed
            case .exactAmounts:
                let equalAmount = (totalAmount * 100).rounded() / 100.0 / count
                newDetails[personId] = SplitDetail(amount: (equalAmount * 100).rounded() / 100.0)
            case .percentages:
                let equalPct = (100.0 / count * 10).rounded() / 10.0
                newDetails[personId] = SplitDetail(percentage: equalPct)
            case .shares:
                newDetails[personId] = SplitDetail(shares: 1)
            case .adjustments:
                newDetails[personId] = SplitDetail(adjustment: 0)
            }
        }

        splitDetails = newDetails
    }

    // MARK: - Reset

    func reset() {
        splitMethod = .equally
        splitDetails.removeAll()
    }
}
