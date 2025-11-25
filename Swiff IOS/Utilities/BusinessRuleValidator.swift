//
//  BusinessRuleValidator.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 3.5: Business rule validation for subscriptions, expenses, and groups
//

import Foundation

// MARK: - Business Rule Error

enum BusinessRuleError: LocalizedError {
    case expenseSplitMismatch(expected: Currency, actual: Currency)
    case paymentOverpayment(amount: Currency, balance: Currency)
    case paymentExceedsBalance(payment: Currency, balance: Currency)
    case invalidDateRange(start: Date, end: Date)
    case subscriptionNotActive(status: String)
    case emptyGroup(groupName: String)
    case duplicateMember(memberName: String)
    case negativeBalance(amount: Currency)
    case insufficientBalance(required: Currency, available: Currency)
    case invalidBillingCycle(cycle: String)
    case futureTransaction(date: Date)
    case expenseWithoutParticipants
    case selfPayment(personName: String)
    case circularReference(entity: String)
    case customRule(String)

    var errorDescription: String? {
        switch self {
        case .expenseSplitMismatch(let expected, let actual):
            return "Expense split amounts (\(actual.formatted())) must equal total (\(expected.formatted()))"
        case .paymentOverpayment(let amount, let balance):
            return "Payment amount (\(amount.formatted())) exceeds owed balance (\(balance.formatted()))"
        case .paymentExceedsBalance(let payment, let balance):
            return "Payment (\(payment.formatted())) cannot exceed balance (\(balance.formatted()))"
        case .invalidDateRange(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "End date (\(formatter.string(from: end))) must be after start date (\(formatter.string(from: start)))"
        case .subscriptionNotActive(let status):
            return "Cannot modify inactive subscription (status: \(status))"
        case .emptyGroup(let groupName):
            return "Group '\(groupName)' must have at least one member"
        case .duplicateMember(let memberName):
            return "'\(memberName)' is already a member of this group"
        case .negativeBalance(let amount):
            return "Balance cannot be negative: \(amount.formatted())"
        case .insufficientBalance(let required, let available):
            return "Insufficient balance. Required: \(required.formatted()), Available: \(available.formatted())"
        case .invalidBillingCycle(let cycle):
            return "Invalid billing cycle: '\(cycle)'"
        case .futureTransaction(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Transaction date cannot be in the future: \(formatter.string(from: date))"
        case .expenseWithoutParticipants:
            return "Expense must have at least one participant"
        case .selfPayment(let personName):
            return "'\(personName)' cannot pay themselves"
        case .circularReference(let entity):
            return "Circular reference detected in \(entity)"
        case .customRule(let message):
            return message
        }
    }
}

// MARK: - Business Rule Validation Result

enum BusinessRuleResult {
    case valid
    case invalid(BusinessRuleError)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    var error: BusinessRuleError? {
        if case .invalid(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Business Rule Validator

enum BusinessRuleValidator {

    // MARK: - Expense Split Validation

    /// Validate that expense split amounts equal the total
    /// - Parameters:
    ///   - totalAmount: Total expense amount
    ///   - splitAmounts: Array of split amounts
    ///   - tolerance: Acceptable difference due to rounding (default: 0.01)
    /// - Returns: BusinessRuleResult
    static func validateExpenseSplit(
        totalAmount: Currency,
        splitAmounts: [Currency],
        tolerance: Currency = Currency(double: 0.01)
    ) -> BusinessRuleResult {
        // Check if there are any participants
        guard !splitAmounts.isEmpty else {
            return .invalid(.expenseWithoutParticipants)
        }

        // Calculate sum of splits
        let splitSum = splitAmounts.reduce(Currency.zero) { result, amount in
            result + amount
        }

        // Check if sum equals total (within tolerance)
        let difference = (totalAmount - splitSum).abs

        if difference > tolerance {
            return .invalid(.expenseSplitMismatch(expected: totalAmount, actual: splitSum))
        }

        return .valid
    }

    /// Distribute expense evenly and validate
    /// - Parameters:
    ///   - totalAmount: Total expense amount
    ///   - participantCount: Number of participants
    /// - Returns: Array of split amounts if valid
    static func distributeExpenseEvenly(
        totalAmount: Currency,
        participantCount: Int
    ) throws -> [Currency] {
        guard participantCount > 0 else {
            throw BusinessRuleError.expenseWithoutParticipants
        }

        return try CurrencyHelper.splitEvenly(totalAmount, ways: participantCount)
    }

    // MARK: - Payment Validation

    /// Validate payment amount against balance
    /// - Parameters:
    ///   - paymentAmount: Payment amount
    ///   - currentBalance: Current balance owed
    ///   - allowOverpayment: Whether overpayment is allowed (default: false)
    /// - Returns: BusinessRuleResult
    static func validatePayment(
        paymentAmount: Currency,
        currentBalance: Currency,
        allowOverpayment: Bool = false
    ) -> BusinessRuleResult {
        // Payment must be positive
        guard paymentAmount.isPositive else {
            return .invalid(.customRule("Payment amount must be positive"))
        }

        // Check for overpayment
        if !allowOverpayment && paymentAmount > currentBalance {
            return .invalid(.paymentOverpayment(amount: paymentAmount, balance: currentBalance))
        }

        return .valid
    }

    /// Calculate new balance after payment
    /// - Parameters:
    ///   - currentBalance: Current balance
    ///   - paymentAmount: Payment amount
    /// - Returns: New balance
    static func calculateBalanceAfterPayment(
        currentBalance: Currency,
        paymentAmount: Currency
    ) -> Currency {
        return currentBalance - paymentAmount
    }

    // MARK: - Date Range Validation

    /// Validate date range (start before end)
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    ///   - allowSameDay: Whether start and end can be the same day (default: true)
    /// - Returns: BusinessRuleResult
    static func validateDateRange(
        startDate: Date,
        endDate: Date,
        allowSameDay: Bool = true
    ) -> BusinessRuleResult {
        if allowSameDay {
            guard endDate >= startDate else {
                return .invalid(.invalidDateRange(start: startDate, end: endDate))
            }
        } else {
            guard endDate > startDate else {
                return .invalid(.invalidDateRange(start: startDate, end: endDate))
            }
        }

        return .valid
    }

    /// Validate transaction date is not in the future
    /// - Parameter date: Transaction date
    /// - Returns: BusinessRuleResult
    static func validateTransactionDate(_ date: Date) -> BusinessRuleResult {
        let now = Date()
        guard date <= now else {
            return .invalid(.futureTransaction(date: date))
        }

        return .valid
    }

    // MARK: - Subscription Validation

    /// Validate subscription status
    /// - Parameters:
    ///   - isActive: Whether subscription is active
    ///   - operationDescription: Description of operation being attempted
    /// - Returns: BusinessRuleResult
    static func validateSubscriptionActive(
        isActive: Bool,
        operationDescription: String = "operation"
    ) -> BusinessRuleResult {
        guard isActive else {
            return .invalid(.subscriptionNotActive(status: "inactive"))
        }

        return .valid
    }

    /// Validate subscription billing cycle
    /// - Parameter cycle: Billing cycle to validate
    /// - Returns: BusinessRuleResult
    static func validateBillingCycle(_ cycle: BillingCycle) -> BusinessRuleResult {
        // All enum cases are valid, this is for future extensibility
        return .valid
    }

    /// Validate subscription dates
    /// - Parameters:
    ///   - startDate: Subscription start date
    ///   - endDate: Subscription end date (optional)
    /// - Returns: BusinessRuleResult
    static func validateSubscriptionDates(
        startDate: Date,
        endDate: Date?
    ) -> BusinessRuleResult {
        // If end date exists, validate range
        if let end = endDate {
            return validateDateRange(startDate: startDate, endDate: end, allowSameDay: false)
        }

        return .valid
    }

    // MARK: - Group Validation

    /// Validate group has members
    /// - Parameters:
    ///   - memberCount: Number of members
    ///   - groupName: Name of the group
    /// - Returns: BusinessRuleResult
    static func validateGroupHasMembers(
        memberCount: Int,
        groupName: String
    ) -> BusinessRuleResult {
        guard memberCount > 0 else {
            return .invalid(.emptyGroup(groupName: groupName))
        }

        return .valid
    }

    /// Validate member is not already in group
    /// - Parameters:
    ///   - memberID: ID of member to add
    ///   - existingMemberIDs: Array of existing member IDs
    ///   - memberName: Name of member for error message
    /// - Returns: BusinessRuleResult
    static func validateUniqueMember(
        memberID: UUID,
        existingMemberIDs: [UUID],
        memberName: String
    ) -> BusinessRuleResult {
        guard !existingMemberIDs.contains(memberID) else {
            return .invalid(.duplicateMember(memberName: memberName))
        }

        return .valid
    }

    // MARK: - Balance Validation

    /// Validate balance is non-negative
    /// - Parameter balance: Balance to validate
    /// - Returns: BusinessRuleResult
    static func validateNonNegativeBalance(_ balance: Currency) -> BusinessRuleResult {
        guard !balance.isNegative else {
            return .invalid(.negativeBalance(amount: balance))
        }

        return .valid
    }

    /// Validate sufficient balance for operation
    /// - Parameters:
    ///   - requiredAmount: Amount required
    ///   - availableBalance: Available balance
    /// - Returns: BusinessRuleResult
    static func validateSufficientBalance(
        requiredAmount: Currency,
        availableBalance: Currency
    ) -> BusinessRuleResult {
        guard availableBalance >= requiredAmount else {
            return .invalid(.insufficientBalance(required: requiredAmount, available: availableBalance))
        }

        return .valid
    }

    // MARK: - Transaction Validation

    /// Validate person is not paying themselves
    /// - Parameters:
    ///   - payerID: ID of person making payment
    ///   - payeeID: ID of person receiving payment
    ///   - payerName: Name of payer for error message
    /// - Returns: BusinessRuleResult
    static func validateNotSelfPayment(
        payerID: UUID,
        payeeID: UUID,
        payerName: String
    ) -> BusinessRuleResult {
        guard payerID != payeeID else {
            return .invalid(.selfPayment(personName: payerName))
        }

        return .valid
    }

    // MARK: - Composite Business Rules

    /// Validate complete expense creation
    /// - Parameters:
    ///   - totalAmount: Total expense amount
    ///   - splitAmounts: Split amounts
    ///   - date: Expense date
    ///   - participantIDs: Participant IDs
    /// - Returns: Array of validation results
    static func validateExpenseCreation(
        totalAmount: Currency,
        splitAmounts: [Currency],
        date: Date,
        participantIDs: [UUID]
    ) -> [BusinessRuleResult] {
        var results: [BusinessRuleResult] = []

        // Validate split
        results.append(validateExpenseSplit(totalAmount: totalAmount, splitAmounts: splitAmounts))

        // Validate date
        results.append(validateTransactionDate(date))

        // Validate participants
        if participantIDs.isEmpty {
            results.append(.invalid(.expenseWithoutParticipants))
        }

        // Validate participant count matches split count
        if participantIDs.count != splitAmounts.count {
            results.append(.invalid(.customRule("Participant count must match split count")))
        }

        return results
    }

    /// Validate complete payment creation
    /// - Parameters:
    ///   - amount: Payment amount
    ///   - payerID: Payer ID
    ///   - payeeID: Payee ID
    ///   - currentBalance: Current balance
    ///   - date: Payment date
    ///   - payerName: Payer name
    /// - Returns: Array of validation results
    static func validatePaymentCreation(
        amount: Currency,
        payerID: UUID,
        payeeID: UUID,
        currentBalance: Currency,
        date: Date,
        payerName: String
    ) -> [BusinessRuleResult] {
        var results: [BusinessRuleResult] = []

        // Validate payment amount
        results.append(validatePayment(paymentAmount: amount, currentBalance: currentBalance))

        // Validate not self-payment
        results.append(validateNotSelfPayment(payerID: payerID, payeeID: payeeID, payerName: payerName))

        // Validate date
        results.append(validateTransactionDate(date))

        return results
    }

    /// Check if all validation results are valid
    /// - Parameter results: Array of validation results
    /// - Returns: True if all valid
    static func areAllValid(_ results: [BusinessRuleResult]) -> Bool {
        return results.allSatisfy { $0.isValid }
    }

    /// Get all error messages from validation results
    /// - Parameter results: Array of validation results
    /// - Returns: Array of error messages
    static func getErrorMessages(_ results: [BusinessRuleResult]) -> [String] {
        return results.compactMap { result in
            if case .invalid(let error) = result {
                return error.localizedDescription
            }
            return nil
        }
    }
}

// MARK: - Business Rule Extensions

extension Currency {
    /// Validate this amount is suitable for a payment
    func validateAsPayment(against balance: Currency) -> BusinessRuleResult {
        return BusinessRuleValidator.validatePayment(
            paymentAmount: self,
            currentBalance: balance
        )
    }

    /// Validate this amount is non-negative
    func validateNonNegative() -> BusinessRuleResult {
        return BusinessRuleValidator.validateNonNegativeBalance(self)
    }
}

extension Date {
    /// Validate this date is not in the future
    func validateNotFuture() -> BusinessRuleResult {
        return BusinessRuleValidator.validateTransactionDate(self)
    }

    /// Validate this date range
    func validateRange(to endDate: Date) -> BusinessRuleResult {
        return BusinessRuleValidator.validateDateRange(startDate: self, endDate: endDate)
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Validate expense split:
 ```swift
 let total = Currency(double: 100.00)
 let splits = [
     Currency(double: 33.33),
     Currency(double: 33.33),
     Currency(double: 33.34)
 ]

 let result = BusinessRuleValidator.validateExpenseSplit(
     totalAmount: total,
     splitAmounts: splits
 )

 if result.isValid {
     print("Expense split is valid")
 } else {
     print("Error: \(result.error?.localizedDescription ?? "")")
 }
 ```

 2. Validate payment:
 ```swift
 let payment = Currency(double: 50.00)
 let balance = Currency(double: 100.00)

 let result = BusinessRuleValidator.validatePayment(
     paymentAmount: payment,
     currentBalance: balance
 )
 ```

 3. Validate complete expense:
 ```swift
 let results = BusinessRuleValidator.validateExpenseCreation(
     totalAmount: Currency(double: 100.00),
     splitAmounts: splits,
     date: Date(),
     participantIDs: [id1, id2, id3]
 )

 if BusinessRuleValidator.areAllValid(results) {
     // Create expense
 } else {
     let errors = BusinessRuleValidator.getErrorMessages(results)
     print("Errors: \(errors.joined(separator: ", "))")
 }
 ```

 4. Using extensions:
 ```swift
 let amount = Currency(double: 50.00)
 let result = amount.validateAsPayment(against: balance)

 let date = Date()
 let dateResult = date.validateNotFuture()
 ```
 */
