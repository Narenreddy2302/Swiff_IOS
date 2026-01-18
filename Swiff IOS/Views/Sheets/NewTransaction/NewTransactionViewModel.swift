//
//  NewTransactionViewModel.swift
//  Swiff IOS
//
//  ViewModel for the 3-step New Transaction flow
//  Handles all state management, validation, and split calculations
//  Production-ready with thread safety and comprehensive validation
//

import Combine
import Foundation
import SwiftUI

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
        case .expense: return Theme.Colors.statusError
        case .income: return Theme.Colors.amountPositive
        }
    }
}

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

// MARK: - NewTransactionViewModel

@MainActor
class NewTransactionViewModel: ObservableObject {

    // MARK: - Navigation State

    /// Current step in the 3-step flow (1, 2, or 3)
    @Published var currentStep: Int = 1

    /// Prevents double-tap navigation issues
    @Published var isTransitioning: Bool = false

    /// Loading state for network/async operations
    @Published var isLoading: Bool = false

    // MARK: - Step 1: Basic Details

    @Published var transactionType: TransactionTypeOption = .expense
    @Published var amountString: String = ""
    @Published var selectedCurrency: Currency =
        Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
    @Published var transactionName: String = ""
    @Published var selectedCategory: TransactionCategory = .food
    @Published var transactionDate: Date = Date()
    @Published var showDatePicker: Bool = false

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
    @Published var showCurrencyPicker: Bool = false
    @Published var showCategoryPicker: Bool = false
    @Published var paidBySearchText: String = ""
    @Published var isPaidBySearchFocused: Bool = false
    @Published var isSplitWithSearchFocused: Bool = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Parsed amount with safety checks for NaN and Infinity
    var amount: Double {
        let parsed = Double(amountString) ?? 0
        return parsed.isFinite && parsed >= 0 ? parsed : 0
    }

    /// Formatted amount for display
    var formattedAmount: String {
        return amount.asCurrency
    }

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Auto-recalculate splits when amount changes (debounced)
        $amountString
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.recalculateSplitsForAmountChange()
            }
            .store(in: &cancellables)

        // Auto-recalculate when participants change
        $participantIds
            .sink { [weak self] _ in
                self?.recalculateSplitsForParticipantChange()
            }
            .store(in: &cancellables)
    }

    // MARK: - Validation - Step 1

    /// Validates that basic transaction details are complete
    var canProceedStep1: Bool {
        let hasValidAmount = amount > 0
        let hasValidName = !transactionName.trimmingCharacters(in: .whitespaces).isEmpty
        return hasValidAmount && hasValidName
    }

    /// Detailed validation error messages for step 1
    var step1ValidationErrors: [String] {
        var errors: [String] = []
        if amount <= 0 {
            errors.append("Enter an amount greater than 0")
        }
        if transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Enter a transaction name")
        }
        return errors
    }

    // MARK: - Validation - Step 2

    /// Validates split configuration is complete
    var canProceedStep2: Bool {
        if !isSplit {
            return true
        }
        return paidByUserId != nil && participantIds.count >= 2
    }

    /// Detailed validation error messages for step 2
    var step2ValidationErrors: [String] {
        var errors: [String] = []
        if isSplit {
            if paidByUserId == nil {
                errors.append("Select who paid")
            }
            if participantIds.count < 2 {
                errors.append("Select at least 2 people to split with")
            }
        }
        return errors
    }

    // MARK: - Validation - Final Submission

    /// Final validation check for transaction submission
    var canSubmit: Bool {
        if !isSplit {
            return canProceedStep1
        }
        return canProceedStep1 && canProceedStep2 && isSplitValid
    }

    /// Validates that split amounts/percentages/shares sum correctly
    var isSplitValid: Bool {
        guard participantIds.count >= 2 else { return false }
        guard amount > 0 else { return false }

        switch splitMethod {
        case .equally:
            return true

        case .shares:
            let totalShares = participantIds.reduce(0) { sum, id in
                sum + (splitDetails[id]?.shares ?? 1)
            }
            return totalShares > 0

        case .exactAmounts:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.amount ?? 0)
            }
            return abs(total - amount) < 0.01

        case .percentages:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.percentage ?? 0)
            }
            return abs(total - 100) < 0.1

        case .adjustments:
            return true
        }
    }

    // MARK: - Computed Properties - Split Status

    /// Remaining amount to allocate (for exact amounts mode)
    var remainingAmount: Double {
        let allocated = participantIds.reduce(0.0) { sum, id in
            sum + (calculatedSplits[id]?.amount ?? 0)
        }
        return max(0, amount - allocated)
    }

    /// Remaining percentage to allocate
    var remainingPercentage: Double {
        let allocated = participantIds.reduce(0.0) { sum, id in
            sum + (splitDetails[id]?.percentage ?? 0)
        }
        return max(0, 100 - allocated)
    }

    /// Total shares allocated
    var totalShares: Int {
        return participantIds.reduce(0) { sum, id in
            sum + (splitDetails[id]?.shares ?? 1)
        }
    }

    /// User-friendly validation message for current split state
    var validationMessage: String? {
        switch splitMethod {
        case .equally:
            let count = Double(participantIds.count)
            let perPerson = count > 0 ? amount / count : 0
            return "Split equally: \(perPerson.asCurrency) each"

        case .exactAmounts:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.amount ?? 0)
            }
            if abs(total - amount) < 0.01 {
                return "Amounts match total"
            } else {
                let remaining = amount - total
                return remaining > 0
                    ? "\(remaining.asCurrency) remaining" : "\(abs(remaining).asCurrency) over"
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
            return "\(totalShares) share\(totalShares == 1 ? "" : "s") total"

        case .adjustments:
            let totalAdjustments = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.adjustment ?? 0)
            }
            let sign = totalAdjustments >= 0 ? "+" : ""
            return "Adjustments: \(sign)\(totalAdjustments.asCurrency)"
        }
    }

    // MARK: - Calculated Splits

    /// Returns calculated split details for all participants based on current method
    var calculatedSplits: [UUID: SplitDetail] {
        let count = Double(participantIds.count)
        guard count > 0, amount > 0 else { return [:] }

        switch splitMethod {
        case .equally:
            let perPersonAmount = count > 0 ? amount / count : 0
            let perPersonPercentage = count > 0 ? 100.0 / count : 0
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
            let baseAmount = count > 0 ? (amount - totalAdjustments) / count : 0

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

    // MARK: - Split Detail Updates

    /// Updates the exact amount for a participant
    func updateSplitAmount(for personId: UUID, amount newAmount: Double) {
        guard participantIds.contains(personId) else { return }
        let safeAmount = max(0, newAmount)

        if var detail = splitDetails[personId] {
            detail.amount = safeAmount
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(amount: safeAmount)
        }
        objectWillChange.send()
    }

    /// Updates the percentage for a participant
    func updateSplitPercentage(for personId: UUID, percentage: Double) {
        guard participantIds.contains(personId) else { return }
        let safePercentage = max(0, min(100, percentage))

        if var detail = splitDetails[personId] {
            detail.percentage = safePercentage
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(percentage: safePercentage)
        }
        objectWillChange.send()
    }

    /// Updates the share count for a participant
    func updateSplitShares(for personId: UUID, shares: Int) {
        guard participantIds.contains(personId) else { return }
        let safeShares = max(1, min(10, shares))

        if var detail = splitDetails[personId] {
            detail.shares = safeShares
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(shares: safeShares)
        }
        objectWillChange.send()
    }

    /// Updates the adjustment amount for a participant
    func updateSplitAdjustment(for personId: UUID, adjustment: Double) {
        guard participantIds.contains(personId) else { return }

        if var detail = splitDetails[personId] {
            detail.adjustment = adjustment
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(adjustment: adjustment)
        }
        objectWillChange.send()
    }

    // MARK: - Recalculation

    private func recalculateSplitsForAmountChange() {
        guard isSplit && splitMethod != .equally else { return }
        objectWillChange.send()
    }

    private func recalculateSplitsForParticipantChange() {
        let validIds = participantIds
        splitDetails = splitDetails.filter { validIds.contains($0.key) }

        for personId in participantIds where splitDetails[personId] == nil {
            initializeSplitDefault(for: personId)
        }
    }

    // MARK: - Payer Actions

    /// Selects a person as the payer and adds them to participants
    func selectPayer(_ personId: UUID) {
        paidByUserId = personId
        participantIds.insert(personId)
        paidBySearchText = ""
        isPaidBySearchFocused = false
        HapticManager.shared.selection()
    }

    /// Clears the current payer selection
    func clearPayer() {
        paidByUserId = nil
    }

    // MARK: - Group Actions

    /// Selects a group and adds all members as participants
    func selectGroup(_ group: Group) {
        selectedGroup = group
        for memberId in group.members {
            participantIds.insert(memberId)
        }
        splitWithSearchText = ""
        isSplitWithSearchFocused = false
        initializeSplitDefaults()
        HapticManager.shared.selection()
    }

    /// Clears the group selection (keeps members selected)
    func clearGroup() {
        selectedGroup = nil
    }

    // MARK: - Participant Actions

    /// Adds a participant from search results
    func addParticipantFromSearch(_ personId: UUID) {
        participantIds.insert(personId)
        splitWithSearchText = ""
        initializeSplitDefault(for: personId)
        HapticManager.shared.selection()
    }

    /// Toggles a participant's selection state
    func toggleParticipant(_ personId: UUID) {
        if participantIds.contains(personId) {
            removeParticipant(personId)
        } else {
            addParticipant(personId)
        }
    }

    /// Adds a person as a participant
    func addParticipant(_ personId: UUID) {
        participantIds.insert(personId)
        initializeSplitDefault(for: personId)

        if paidByUserId == nil {
            paidByUserId = personId
        }

        HapticManager.shared.selection()
    }

    /// Removes a participant (with minimum count validation for splits)
    func removeParticipant(_ personId: UUID) {
        if isSplit && participantIds.count <= 2 {
            HapticManager.shared.warning()
            return
        }

        participantIds.remove(personId)
        splitDetails.removeValue(forKey: personId)

        if paidByUserId == personId {
            paidByUserId = participantIds.first
        }

        if selectedGroup != nil {
            selectedGroup = nil
        }

        HapticManager.shared.selection()
    }

    // MARK: - Search Filtering

    /// Filters people list for payer search
    func filteredPaidByContacts(from people: [Person]) -> [Person] {
        guard !paidBySearchText.isEmpty else { return people }

        let search = paidBySearchText.lowercased()
        return people.filter { person in
            person.name.lowercased().contains(search) || person.email.lowercased().contains(search)
                || person.phone.contains(search)
        }
    }

    /// Filters people list for participant search
    func filteredSplitWithContacts(from people: [Person]) -> [Person] {
        guard !splitWithSearchText.isEmpty else { return people }

        let search = splitWithSearchText.lowercased()
        return people.filter { person in
            person.name.lowercased().contains(search) || person.email.lowercased().contains(search)
                || person.phone.contains(search)
        }
    }

    /// Filters groups for search
    func filteredSplitWithGroups(from groups: [Group]) -> [Group] {
        guard !splitWithSearchText.isEmpty else { return groups }

        let search = splitWithSearchText.lowercased()
        return groups.filter { group in
            group.name.lowercased().contains(search)
        }
    }

    // MARK: - Split Initialization

    /// Initializes default split values for all participants
    func initializeSplitDefaults() {
        for personId in participantIds {
            initializeSplitDefault(for: personId)
        }
    }

    /// Initializes default split value for a single participant
    func initializeSplitDefault(for personId: UUID) {
        guard splitDetails[personId] == nil else { return }

        let count = Double(participantIds.count)
        guard count > 0 else { return }

        switch splitMethod {
        case .equally:
            break

        case .exactAmounts:
            splitDetails[personId] = SplitDetail(amount: count > 0 ? amount / count : 0)

        case .percentages:
            splitDetails[personId] = SplitDetail(percentage: count > 0 ? 100.0 / count : 0)

        case .shares:
            splitDetails[personId] = SplitDetail(shares: 1)

        case .adjustments:
            splitDetails[personId] = SplitDetail(adjustment: 0)
        }
    }

    /// Called when split method changes - reinitializes all split details
    func onSplitMethodChanged() {
        splitDetails.removeAll()
        initializeSplitDefaults()
        HapticManager.shared.selection()
    }

    // MARK: - Navigation

    /// Advances to the next step with validation
    func goToNextStep() {
        guard !isTransitioning else { return }

        switch currentStep {
        case 1:
            guard canProceedStep1 else {
                HapticManager.shared.warning()
                return
            }

        case 2:
            guard canProceedStep2 else {
                HapticManager.shared.warning()
                return
            }
            if isSplit {
                initializeSplitDefaults()
            }

        default:
            break
        }

        isTransitioning = true
        HapticManager.shared.selection()

        withAnimation(.smooth(duration: 0.3)) {
            if currentStep < 3 {
                currentStep += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    /// Returns to the previous step
    func goToPreviousStep() {
        guard !isTransitioning else { return }
        guard currentStep > 1 else { return }

        isTransitioning = true
        HapticManager.shared.selection()

        withAnimation(.smooth(duration: 0.3)) {
            currentStep -= 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    /// Jumps to a specific step (with validation)
    func goToStep(_ step: Int) {
        guard step >= 1 && step <= 3 else { return }
        guard !isTransitioning else { return }

        if step > currentStep {
            if step >= 2 && !canProceedStep1 {
                HapticManager.shared.warning()
                return
            }
            if step >= 3 && !canProceedStep2 {
                HapticManager.shared.warning()
                return
            }
        }

        isTransitioning = true
        HapticManager.shared.selection()

        withAnimation(.smooth(duration: 0.3)) {
            currentStep = step
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    // MARK: - Reset

    /// Resets all state to initial values
    func reset() {
        // Navigation
        currentStep = 1
        isTransitioning = false

        // Step 1
        transactionType = .expense
        amountString = ""
        selectedCurrency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
        transactionName = ""
        selectedCategory = .food
        transactionDate = Date()
        showCurrencyPicker = false
        showCategoryPicker = false
        showDatePicker = false

        // Step 2
        isSplit = false
        paidByUserId = nil
        participantIds.removeAll()
        selectedGroup = nil
        paidBySearchText = ""
        isPaidBySearchFocused = false
        splitWithSearchText = ""
        isSplitWithSearchFocused = false

        // Step 3
        splitMethod = .equally
        splitDetails.removeAll()

        // Other
        notes = ""
        isLoading = false
    }

    // MARK: - Utility Functions

    /// Returns display name for a participant ("You" for self)
    func displayName(for personId: UUID, in people: [Person], selfId: UUID?) -> String {
        guard let person = people.first(where: { $0.id == personId }) else {
            return "Unknown"
        }
        if personId == selfId {
            return "You"
        }
        return person.name
    }

    /// Checks if a person is the current payer
    func isPayer(_ personId: UUID) -> Bool {
        return personId == paidByUserId
    }

    /// Checks if a person is a selected participant
    func isParticipant(_ personId: UUID) -> Bool {
        return participantIds.contains(personId)
    }

    /// Formatted participant count string
    var participantCountDisplay: String {
        let count = participantIds.count
        return "\(count) \(count == 1 ? "person" : "people")"
    }
}
