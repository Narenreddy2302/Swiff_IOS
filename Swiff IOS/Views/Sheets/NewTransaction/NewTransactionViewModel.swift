//
//  NewTransactionViewModel.swift
//  Swiff IOS
//
//  ViewModel for the 3-step New Transaction flow
//

import SwiftUI
import Foundation
import Combine

// MARK: - Transaction Type Option

enum TransactionTypeOption: String, CaseIterable {
    case expense = "Expense"
    case income = "Income"

    var icon: String {
        switch self {
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .expense: return .wiseError
        case .income: return .wiseBrightGreen
        }
    }
}

// MARK: - Split Detail Model

struct SplitDetail {
    var amount: Double = 0
    var percentage: Double = 0
    var shares: Int = 1
    var adjustment: Double = 0
}

// MARK: - New Transaction ViewModel

class NewTransactionViewModel: ObservableObject {

    // MARK: - Sheet State

    @Published var currentStep: Int = 1  // 1, 2, or 3

    // MARK: - Step 1: Basic Details

    @Published var transactionType: TransactionTypeOption = .expense
    @Published var amountString: String = ""
    @Published var selectedCurrency: Currency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
    @Published var transactionName: String = ""
    @Published var selectedCategory: TransactionCategory = .food

    var amount: Double {
        let parsed = Double(amountString) ?? 0
        // Guard against NaN/Infinity for safe calculations
        return parsed.isFinite ? parsed : 0
    }

    // MARK: - Step 2: Split Options

    @Published var isSplit: Bool = false
    @Published var paidByUserId: UUID?
    @Published var participantIds: Set<UUID> = []
    @Published var selectedGroup: Group?
    @Published var splitWithSearchText: String = ""

    // MARK: - Step 3: Split Method

    @Published var splitMethod: SplitType = .equally
    @Published var splitDetails: [UUID: SplitDetail] = [:]

    // MARK: - UI State

    @Published var notes: String = ""

    // MARK: - Step 1: Picker States

    @Published var showCurrencyPicker: Bool = false
    @Published var showCategoryPicker: Bool = false

    // MARK: - Step 2: Search States

    @Published var paidBySearchText: String = ""
    @Published var isPaidBySearchFocused: Bool = false
    @Published var isSplitWithSearchFocused: Bool = false

    // MARK: - Computed Properties - Validation

    var canProceedStep1: Bool {
        amount > 0 && !transactionName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedStep2: Bool {
        if !isSplit {
            return true  // Personal transaction, can proceed
        }
        // Split transaction requires payer and at least 2 participants
        return paidByUserId != nil && participantIds.count >= 2
    }

    var canSubmit: Bool {
        if !isSplit {
            return canProceedStep1
        }
        return canProceedStep1 && canProceedStep2 && isSplitValid
    }

    var isSplitValid: Bool {
        // Must have participants for any split to be valid
        guard participantIds.count > 0 else { return false }

        switch splitMethod {
        case .equally:
            return participantIds.count >= 2
        case .shares:
            // Validate that total shares is greater than 0
            let totalShares = splitDetails.values.reduce(0) { $0 + $1.shares }
            return totalShares > 0 && participantIds.count >= 2
        case .exactAmounts:
            let total = splitDetails.values.reduce(0) { $0 + $1.amount }
            return abs(total - amount) < 0.01
        case .percentages:
            let total = splitDetails.values.reduce(0) { $0 + $1.percentage }
            return abs(total - 100) < 0.1
        case .adjustments:
            return participantIds.count >= 2
        }
    }

    var validationMessage: String? {
        switch splitMethod {
        case .equally:
            let perPerson = participantIds.count > 0 ? amount / Double(participantIds.count) : 0
            return "Split equally: \(perPerson.asCurrency) each"
        case .exactAmounts:
            let total = splitDetails.values.reduce(0) { $0 + $1.amount }
            if abs(total - amount) < 0.01 {
                return "Amounts match total"
            } else {
                return "Total: \(total.asCurrency) / \(amount.asCurrency)"
            }
        case .percentages:
            let total = splitDetails.values.reduce(0) { $0 + $1.percentage }
            if abs(total - 100) < 0.1 {
                return "Percentages add up to 100%"
            } else {
                return "Total: \(String(format: "%.1f", total))% / 100%"
            }
        case .shares:
            let totalShares = splitDetails.values.reduce(0) { $0 + $1.shares }
            return "\(totalShares) shares total"
        case .adjustments:
            let totalAdjustments = splitDetails.values.reduce(0) { $0 + $1.adjustment }
            let sign = totalAdjustments >= 0 ? "+" : ""
            return "Adjustments: \(sign)\(totalAdjustments.asCurrency)"
        }
    }

    // MARK: - Calculated Splits

    var calculatedSplits: [UUID: SplitDetail] {
        let count = Double(participantIds.count)
        guard count > 0, amount > 0 else { return [:] }

        switch splitMethod {
        case .equally:
            let perPersonAmount = amount / count
            let perPersonPercentage = 100.0 / count
            return participantIds.reduce(into: [:]) { result, id in
                result[id] = SplitDetail(amount: perPersonAmount, percentage: perPersonPercentage)
            }

        case .exactAmounts:
            // Iterate over participantIds to include all participants, not just those with splitDetails
            return participantIds.reduce(into: [:]) { result, id in
                let detail = splitDetails[id] ?? SplitDetail()
                result[id] = SplitDetail(
                    amount: detail.amount,
                    percentage: amount > 0 ? (detail.amount / amount) * 100 : 0
                )
            }

        case .percentages:
            // Iterate over participantIds to include all participants
            return participantIds.reduce(into: [:]) { result, id in
                let detail = splitDetails[id] ?? SplitDetail()
                result[id] = SplitDetail(
                    amount: (detail.percentage / 100) * amount,
                    percentage: detail.percentage
                )
            }

        case .shares:
            let totalShares = Double(splitDetails.values.reduce(0) { $0 + $1.shares })
            guard totalShares > 0 else { return [:] }
            // Iterate over participantIds to include all participants
            return participantIds.reduce(into: [:]) { result, id in
                let detail = splitDetails[id] ?? SplitDetail(shares: 1)
                let share = Double(detail.shares)
                result[id] = SplitDetail(
                    amount: (share / totalShares) * amount,
                    percentage: (share / totalShares) * 100,
                    shares: detail.shares
                )
            }

        case .adjustments:
            // Guard against division by zero
            guard count > 0 else { return [:] }
            let totalAdjustments = splitDetails.values.reduce(0) { $0 + $1.adjustment }
            let baseAmount = (amount - totalAdjustments) / count
            // Iterate over participantIds to include all participants
            return participantIds.reduce(into: [:]) { result, id in
                let detail = splitDetails[id] ?? SplitDetail()
                let personAmount = baseAmount + detail.adjustment
                result[id] = SplitDetail(
                    amount: personAmount,
                    percentage: amount > 0 ? (personAmount / amount) * 100 : 0,
                    adjustment: detail.adjustment
                )
            }
        }
    }

    // MARK: - Safe Split Detail Setters

    func updateSplitAmount(for personId: UUID, amount: Double) {
        if splitDetails[personId] != nil {
            splitDetails[personId]?.amount = amount
        } else {
            splitDetails[personId] = SplitDetail(amount: amount)
        }
    }

    func updateSplitPercentage(for personId: UUID, percentage: Double) {
        if splitDetails[personId] != nil {
            splitDetails[personId]?.percentage = percentage
        } else {
            splitDetails[personId] = SplitDetail(percentage: percentage)
        }
    }

    func updateSplitShares(for personId: UUID, shares: Int) {
        if splitDetails[personId] != nil {
            splitDetails[personId]?.shares = shares
        } else {
            splitDetails[personId] = SplitDetail(shares: shares)
        }
    }

    func updateSplitAdjustment(for personId: UUID, adjustment: Double) {
        if splitDetails[personId] != nil {
            splitDetails[personId]?.adjustment = adjustment
        } else {
            splitDetails[personId] = SplitDetail(adjustment: adjustment)
        }
    }

    // MARK: - Actions

    func selectPayer(_ personId: UUID) {
        paidByUserId = personId
        participantIds.insert(personId)  // Auto-add to participants
        paidBySearchText = ""
        isPaidBySearchFocused = false
    }

    func selectGroup(_ group: Group) {
        selectedGroup = group
        for memberId in group.members {
            participantIds.insert(memberId)
        }
        splitWithSearchText = ""
        isSplitWithSearchFocused = false
        initializeSplitDefaults()
    }

    func clearGroup() {
        selectedGroup = nil
        // Keep members selected, just clear the group badge
    }

    /// Add a participant from search and clear search
    func addParticipantFromSearch(_ personId: UUID) {
        participantIds.insert(personId)
        splitWithSearchText = ""
        initializeSplitDefault(for: personId)
    }

    // MARK: - Filtered Search Results

    /// Filter contacts for "Paid By" search
    func filteredPaidByContacts(from people: [Person]) -> [Person] {
        guard !paidBySearchText.isEmpty else { return people }

        let search = paidBySearchText.lowercased()
        return people.filter { person in
            person.name.lowercased().contains(search) ||
            person.email.lowercased().contains(search)
        }
    }

    /// Filter contacts for "Split With" search
    func filteredSplitWithContacts(from people: [Person]) -> [Person] {
        guard !splitWithSearchText.isEmpty else { return people }

        let search = splitWithSearchText.lowercased()
        return people.filter { person in
            person.name.lowercased().contains(search) ||
            person.email.lowercased().contains(search)
        }
    }

    /// Filter groups for "Split With" search
    func filteredSplitWithGroups(from groups: [Group]) -> [Group] {
        guard !splitWithSearchText.isEmpty else { return groups }

        let search = splitWithSearchText.lowercased()
        return groups.filter { group in
            group.name.lowercased().contains(search)
        }
    }

    func toggleParticipant(_ personId: UUID) {
        if participantIds.contains(personId) {
            // Prevent removing if it would leave less than 2 participants
            if participantIds.count > 2 || !isSplit {
                participantIds.remove(personId)
                splitDetails.removeValue(forKey: personId)

                // Clear group badge if we're modifying membership
                if selectedGroup != nil {
                    selectedGroup = nil
                }
            }
        } else {
            participantIds.insert(personId)
            initializeSplitDefault(for: personId)
        }
    }

    func initializeSplitDefaults() {
        for personId in participantIds {
            initializeSplitDefault(for: personId)
        }
    }

    func initializeSplitDefault(for personId: UUID) {
        let count = Double(participantIds.count)
        guard count > 0 else { return }

        switch splitMethod {
        case .equally:
            break  // No manual input needed
        case .exactAmounts:
            splitDetails[personId] = SplitDetail(amount: amount / count)
        case .percentages:
            splitDetails[personId] = SplitDetail(percentage: 100.0 / count)
        case .shares:
            splitDetails[personId] = SplitDetail(shares: 1)
        case .adjustments:
            splitDetails[personId] = SplitDetail(adjustment: 0)
        }
    }

    func onSplitMethodChanged() {
        splitDetails.removeAll()
        initializeSplitDefaults()
    }

    func reset() {
        currentStep = 1
        transactionType = .expense
        amountString = ""
        selectedCurrency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
        transactionName = ""
        selectedCategory = .food
        showCurrencyPicker = false
        showCategoryPicker = false
        isSplit = false
        paidByUserId = nil
        participantIds.removeAll()
        selectedGroup = nil
        paidBySearchText = ""
        isPaidBySearchFocused = false
        splitWithSearchText = ""
        isSplitWithSearchFocused = false
        splitMethod = .equally
        splitDetails.removeAll()
        notes = ""
    }

    func goToNextStep() {
        if currentStep < 3 {
            currentStep += 1
        }
    }

    func goToPreviousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
}
