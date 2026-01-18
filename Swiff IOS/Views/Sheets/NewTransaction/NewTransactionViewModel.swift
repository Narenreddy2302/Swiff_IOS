//
//  NewTransactionViewModel.swift
//  Swiff IOS
//
//  ViewModel for the 3-step New Transaction flow
//  Handles all state management, validation, and split calculations
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

struct SplitDetail: Equatable {
    var amount: Double = 0
    var percentage: Double = 0
    var shares: Int = 1
    var adjustment: Double = 0

    static func == (lhs: SplitDetail, rhs: SplitDetail) -> Bool {
        return abs(lhs.amount - rhs.amount) < 0.001 &&
               abs(lhs.percentage - rhs.percentage) < 0.001 &&
               lhs.shares == rhs.shares &&
               abs(lhs.adjustment - rhs.adjustment) < 0.001
    }
}

// MARK: - New Transaction ViewModel

class NewTransactionViewModel: ObservableObject {

    // MARK: - Sheet State

    @Published var currentStep: Int = 1  // 1, 2, or 3
    @Published var isTransitioning: Bool = false  // Prevents double navigation

    // MARK: - Step 1: Basic Details

    @Published var transactionType: TransactionTypeOption = .expense
    @Published var amountString: String = ""
    @Published var selectedCurrency: Currency = Currency(rawValue: UserSettings.shared.selectedCurrency) ?? .USD
    @Published var transactionName: String = ""
    @Published var selectedCategory: TransactionCategory = .food
    @Published var transactionDate: Date = Date()
    @Published var showDatePicker: Bool = false

    /// Parsed amount with safety checks
    var amount: Double {
        let parsed = Double(amountString) ?? 0
        // Guard against NaN/Infinity for safe calculations
        return parsed.isFinite && parsed >= 0 ? parsed : 0
    }

    /// Formatted amount for display
    var formattedAmount: String {
        return amount.asCurrency
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

    // MARK: - Cancellables for Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    private func setupObservers() {
        // Auto-recalculate splits when amount changes
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

    // MARK: - Computed Properties - Validation

    /// Step 1: Validate basic details are filled
    var canProceedStep1: Bool {
        let hasValidAmount = amount > 0
        let hasValidName = !transactionName.trimmingCharacters(in: .whitespaces).isEmpty
        return hasValidAmount && hasValidName
    }

    /// Step 1: Detailed validation messages
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

    /// Step 2: Validate split configuration
    var canProceedStep2: Bool {
        if !isSplit {
            return true  // Personal transaction, can proceed
        }
        // Split transaction requires payer and at least 2 participants
        return paidByUserId != nil && participantIds.count >= 2
    }

    /// Step 2: Detailed validation messages
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

    /// Step 3: Final submission validation
    var canSubmit: Bool {
        if !isSplit {
            return canProceedStep1
        }
        return canProceedStep1 && canProceedStep2 && isSplitValid
    }

    /// Validate split totals match
    var isSplitValid: Bool {
        // Must have participants for any split to be valid
        guard participantIds.count >= 2 else { return false }
        guard amount > 0 else { return false }

        switch splitMethod {
        case .equally:
            return true  // Always valid with 2+ participants

        case .shares:
            // Validate that total shares is greater than 0
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
            return true  // Always valid, adjustments are optional
        }
    }

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

    /// User-friendly validation message
    var validationMessage: String? {
        switch splitMethod {
        case .equally:
            let perPerson = participantIds.count > 0 ? amount / Double(participantIds.count) : 0
            return "Split equally: \(perPerson.asCurrency) each"

        case .exactAmounts:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.amount ?? 0)
            }
            if abs(total - amount) < 0.01 {
                return "Amounts match total"
            } else {
                let remaining = amount - total
                return remaining > 0 ? "\(remaining.asCurrency) remaining" : "\(abs(remaining).asCurrency) over"
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

    /// Returns calculated split details for all participants
    var calculatedSplits: [UUID: SplitDetail] {
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
                    amount: max(0, personAmount),  // Prevent negative amounts
                    percentage: amount > 0 ? (max(0, personAmount) / amount) * 100 : 0,
                    shares: 1,
                    adjustment: adjustment
                )
            }
        }
    }

    // MARK: - Split Detail Setters

    func updateSplitAmount(for personId: UUID, amount newAmount: Double) {
        guard participantIds.contains(personId) else { return }
        let safeAmount = max(0, newAmount)  // Prevent negative amounts

        if var detail = splitDetails[personId] {
            detail.amount = safeAmount
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(amount: safeAmount)
        }
        objectWillChange.send()
    }

    func updateSplitPercentage(for personId: UUID, percentage: Double) {
        guard participantIds.contains(personId) else { return }
        let safePercentage = max(0, min(100, percentage))  // Clamp 0-100

        if var detail = splitDetails[personId] {
            detail.percentage = safePercentage
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(percentage: safePercentage)
        }
        objectWillChange.send()
    }

    func updateSplitShares(for personId: UUID, shares: Int) {
        guard participantIds.contains(personId) else { return }
        let safeShares = max(1, min(10, shares))  // Clamp 1-10

        if var detail = splitDetails[personId] {
            detail.shares = safeShares
            splitDetails[personId] = detail
        } else {
            splitDetails[personId] = SplitDetail(shares: safeShares)
        }
        objectWillChange.send()
    }

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

    // MARK: - Recalculation Helpers

    private func recalculateSplitsForAmountChange() {
        guard isSplit && splitMethod != .equally else { return }

        // For percentage mode, amounts are auto-calculated from percentages
        // For exact amounts mode, we don't auto-adjust (user controls amounts)
        // For shares mode, amounts are auto-calculated from shares
        objectWillChange.send()
    }

    private func recalculateSplitsForParticipantChange() {
        // Clean up split details for removed participants
        let validIds = participantIds
        splitDetails = splitDetails.filter { validIds.contains($0.key) }

        // Initialize defaults for new participants
        for personId in participantIds where splitDetails[personId] == nil {
            initializeSplitDefault(for: personId)
        }
    }

    // MARK: - Payer Actions

    func selectPayer(_ personId: UUID) {
        paidByUserId = personId
        participantIds.insert(personId)  // Auto-add to participants
        paidBySearchText = ""
        isPaidBySearchFocused = false
        HapticManager.shared.selection()
    }

    func clearPayer() {
        paidByUserId = nil
    }

    // MARK: - Group Actions

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

    func clearGroup() {
        selectedGroup = nil
        // Keep members selected, just clear the group badge
    }

    // MARK: - Participant Actions

    func addParticipantFromSearch(_ personId: UUID) {
        participantIds.insert(personId)
        splitWithSearchText = ""
        initializeSplitDefault(for: personId)
        HapticManager.shared.selection()
    }

    func toggleParticipant(_ personId: UUID) {
        if participantIds.contains(personId) {
            removeParticipant(personId)
        } else {
            addParticipant(personId)
        }
    }

    func addParticipant(_ personId: UUID) {
        participantIds.insert(personId)
        initializeSplitDefault(for: personId)

        // Auto-set as payer if none selected
        if paidByUserId == nil {
            paidByUserId = personId
        }

        HapticManager.shared.selection()
    }

    func removeParticipant(_ personId: UUID) {
        // Prevent removing if it would leave less than 2 participants in split mode
        if isSplit && participantIds.count <= 2 {
            HapticManager.shared.warning()
            return
        }

        participantIds.remove(personId)
        splitDetails.removeValue(forKey: personId)

        // Clear payer if we removed the payer
        if paidByUserId == personId {
            paidByUserId = participantIds.first
        }

        // Clear group badge if we're modifying membership
        if selectedGroup != nil {
            selectedGroup = nil
        }

        HapticManager.shared.selection()
    }

    // MARK: - Filtered Search Results

    func filteredPaidByContacts(from people: [Person]) -> [Person] {
        guard !paidBySearchText.isEmpty else { return people }

        let search = paidBySearchText.lowercased()
        return people.filter { person in
            person.name.lowercased().contains(search) ||
            person.email.lowercased().contains(search) ||
            person.phone.contains(search)
        }
    }

    func filteredSplitWithContacts(from people: [Person]) -> [Person] {
        guard !splitWithSearchText.isEmpty else { return people }

        let search = splitWithSearchText.lowercased()
        return people.filter { person in
            person.name.lowercased().contains(search) ||
            person.email.lowercased().contains(search) ||
            person.phone.contains(search)
        }
    }

    func filteredSplitWithGroups(from groups: [Group]) -> [Group] {
        guard !splitWithSearchText.isEmpty else { return groups }

        let search = splitWithSearchText.lowercased()
        return groups.filter { group in
            group.name.lowercased().contains(search)
        }
    }

    // MARK: - Split Initialization

    func initializeSplitDefaults() {
        for personId in participantIds {
            initializeSplitDefault(for: personId)
        }
    }

    func initializeSplitDefault(for personId: UUID) {
        guard splitDetails[personId] == nil else { return }  // Don't overwrite existing

        let count = Double(participantIds.count)
        guard count > 0 else { return }

        switch splitMethod {
        case .equally:
            // No manual input needed for equal split
            break

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
        // Clear existing details and reinitialize
        splitDetails.removeAll()
        initializeSplitDefaults()
        HapticManager.shared.selection()
    }

    // MARK: - Navigation

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
            // Initialize split defaults when moving to step 3
            if isSplit {
                initializeSplitDefaults()
            }

        default:
            break
        }

        isTransitioning = true
        HapticManager.shared.light()

        withAnimation(.smooth(duration: 0.3)) {
            if currentStep < 3 {
                currentStep += 1
            }
        }

        // Reset transition flag after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    func goToPreviousStep() {
        guard !isTransitioning else { return }
        guard currentStep > 1 else { return }

        isTransitioning = true
        HapticManager.shared.light()

        withAnimation(.smooth(duration: 0.3)) {
            currentStep -= 1
        }

        // Reset transition flag after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    func goToStep(_ step: Int) {
        guard step >= 1 && step <= 3 else { return }
        guard !isTransitioning else { return }

        // Validate that we can skip to this step
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
        HapticManager.shared.light()

        withAnimation(.smooth(duration: 0.3)) {
            currentStep = step
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    // MARK: - Reset

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
    }

    // MARK: - Utility Functions

    /// Get display name for a participant (handles "You" case)
    func displayName(for personId: UUID, in people: [Person], selfId: UUID?) -> String {
        guard let person = people.first(where: { $0.id == personId }) else {
            return "Unknown"
        }
        if personId == selfId {
            return "You"
        }
        return person.name
    }

    /// Check if a person is the payer
    func isPayer(_ personId: UUID) -> Bool {
        return personId == paidByUserId
    }

    /// Check if a person is selected as participant
    func isParticipant(_ personId: UUID) -> Bool {
        return participantIds.contains(personId)
    }

    /// Get participant count display
    var participantCountDisplay: String {
        let count = participantIds.count
        return "\(count) \(count == 1 ? "person" : "people")"
    }
}
