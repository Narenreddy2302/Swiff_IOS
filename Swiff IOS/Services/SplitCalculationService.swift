//
//  SplitCalculationService.swift
//  Swiff IOS
//
//  Service for calculating split bill amounts using different methods
//

import Foundation

class SplitCalculationService {

    // MARK: - Constants

    /// Tolerance for floating-point comparisons ($0.01)
    static let toleranceCents: Double = 0.01

    // MARK: - Equal Split

    static func calculateEqualSplit(totalAmount: Double, participantIds: [UUID]) -> [SplitParticipant] {
        guard !participantIds.isEmpty, totalAmount > 0 else { return [] }

        let count = Double(participantIds.count)
        let baseAmount = roundToCents(totalAmount / count)

        // Calculate remainder after rounding to distribute fairly
        let distributedTotal = baseAmount * count
        let remainder = roundToCents(totalAmount - distributedTotal)

        return participantIds.enumerated().map { index, personId in
            // Give the remainder (positive or negative) to the last participant
            let amount = index == participantIds.count - 1 ? baseAmount + remainder : baseAmount
            return SplitParticipant(personId: personId, amount: roundToCents(amount))
        }
    }

    // MARK: - Exact Amounts

    static func calculateExactAmounts(amounts: [UUID: Double]) -> [SplitParticipant] {
        return amounts.map { SplitParticipant(personId: $0.key, amount: roundToCents($0.value)) }
    }

    // MARK: - Percentages

    static func calculatePercentages(totalAmount: Double, percentages: [UUID: Double]) -> [SplitParticipant] {
        guard totalAmount > 0 else { return [] }

        return percentages.map { personId, percentage in
            let amount = roundToCents(totalAmount * (percentage / 100.0))
            return SplitParticipant(personId: personId, amount: amount, percentage: percentage)
        }
    }

    // MARK: - Shares

    static func calculateShares(totalAmount: Double, shares: [UUID: Int]) -> [SplitParticipant] {
        let totalShares = shares.values.reduce(0, +)
        guard totalShares > 0, totalAmount > 0 else { return [] }

        let amountPerShare = totalAmount / Double(totalShares)

        // Calculate amounts with rounding
        var participants = shares.map { personId, shareCount in
            let amount = roundToCents(amountPerShare * Double(shareCount))
            return SplitParticipant(personId: personId, amount: amount, shares: shareCount)
        }

        // Distribute rounding difference to first participant
        let calculatedTotal = participants.reduce(0) { $0 + $1.amount }
        let difference = roundToCents(totalAmount - calculatedTotal)
        if !participants.isEmpty && abs(difference) > 0 {
            participants[0].amount = roundToCents(participants[0].amount + difference)
        }

        return participants
    }

    // MARK: - Adjustments (starts equal, then adjust)

    static func calculateAdjustments(
        totalAmount: Double,
        participantIds: [UUID],
        adjustments: [UUID: Double] = [:]
    ) -> [SplitParticipant] {
        guard totalAmount > 0 else { return [] }

        // Start with equal split
        var participants = calculateEqualSplit(totalAmount: totalAmount, participantIds: participantIds)

        // Apply adjustments if provided (round each adjustment)
        for (index, participant) in participants.enumerated() {
            if let adjustment = adjustments[participant.personId] {
                participants[index].amount = roundToCents(adjustment)
            }
        }

        return participants
    }

    // MARK: - Validation

    static func validateSplit(
        totalAmount: Double,
        participants: [SplitParticipant],
        splitType: SplitType
    ) -> (isValid: Bool, error: String?) {
        // Check if there are participants
        guard !participants.isEmpty else {
            return (false, "At least one participant is required")
        }

        // Check if total amount is positive
        guard totalAmount > 0 else {
            return (false, "Total amount must be greater than 0")
        }

        // Check if all participant amounts are positive
        guard participants.allSatisfy({ $0.amount > 0 }) else {
            return (false, "All participant amounts must be greater than 0")
        }

        // Validate total amounts match
        let calculatedTotal = participants.reduce(0) { $0 + $1.amount }

        guard abs(calculatedTotal - totalAmount) < toleranceCents else {
            return (
                false,
                "Amounts don't add up to total. Expected $\(String(format: "%.2f", totalAmount)), got $\(String(format: "%.2f", calculatedTotal))"
            )
        }

        // Type-specific validations
        switch splitType {
        case .percentages:
            let totalPercentage = participants.compactMap { $0.percentage }.reduce(0, +)
            guard abs(totalPercentage - 100.0) < toleranceCents else {
                return (false, "Percentages must add up to 100%. Currently: \(String(format: "%.1f", totalPercentage))%")
            }

        case .shares:
            guard participants.allSatisfy({ $0.shares != nil && $0.shares! > 0 }) else {
                return (false, "All participants must have valid shares (greater than 0)")
            }

        case .exactAmounts, .adjustments:
            // Already validated that amounts are positive and sum to total
            break

        case .equally:
            // Equal split is automatically valid if amounts sum to total
            break
        }

        return (true, nil)
    }

    // MARK: - Helper Methods

    /// Calculate the amount per person for equal split (rounded to cents)
    static func equalAmountPerPerson(totalAmount: Double, participantCount: Int) -> Double {
        guard participantCount > 0, totalAmount > 0 else { return 0 }
        return roundToCents(totalAmount / Double(participantCount))
    }

    /// Calculate remaining amount based on already assigned amounts
    static func calculateRemaining(totalAmount: Double, assignedAmounts: [Double]) -> Double {
        let assigned = assignedAmounts.reduce(0, +)
        return roundToCents(max(0, totalAmount - assigned))
    }

    /// Validate that a percentage is valid (0-100)
    static func isValidPercentage(_ percentage: Double) -> Bool {
        return percentage >= 0 && percentage <= 100
    }

    /// Round amount to 2 decimal places (cents)
    static func roundToCents(_ amount: Double) -> Double {
        return round(amount * 100) / 100
    }

    /// Calculate amount per share (rounded to cents)
    static func amountPerShare(totalAmount: Double, totalShares: Int) -> Double {
        guard totalShares > 0, totalAmount > 0 else { return 0 }
        return roundToCents(totalAmount / Double(totalShares))
    }

    /// Check if two amounts are equal within tolerance
    static func amountsEqual(_ a: Double, _ b: Double) -> Bool {
        return abs(a - b) < toleranceCents
    }
}
