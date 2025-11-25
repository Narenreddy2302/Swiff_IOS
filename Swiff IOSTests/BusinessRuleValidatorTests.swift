//
//  BusinessRuleValidatorTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 3.5: Business rule validation
//

import XCTest
@testable import Swiff_IOS

final class BusinessRuleValidatorTests: XCTestCase {

    // MARK: - Test 3.5.1: Expense Split Validation

    func testExpenseSplitValidation() throws {
        print("🧪 Test 3.5.1: Testing expense split validation")

        // Valid split (exactly equal)
        let total1 = Currency(double: 100.00)
        let splits1 = [
            Currency(double: 33.33),
            Currency(double: 33.33),
            Currency(double: 33.34)
        ]

        var result = BusinessRuleValidator.validateExpenseSplit(
            totalAmount: total1,
            splitAmounts: splits1
        )
        XCTAssertTrue(result.isValid, "Valid split should pass")
        print("   ✓ Valid split: $100.00 split 3 ways")

        // Invalid split (mismatch)
        let total2 = Currency(double: 100.00)
        let splits2 = [
            Currency(double: 30.00),
            Currency(double: 30.00),
            Currency(double: 30.00)  // Total: $90.00, missing $10
        ]

        result = BusinessRuleValidator.validateExpenseSplit(
            totalAmount: total2,
            splitAmounts: splits2
        )
        XCTAssertFalse(result.isValid, "Invalid split should fail")
        print("   ✓ Invalid split detected: \(result.error?.localizedDescription ?? "")")

        // Empty splits
        result = BusinessRuleValidator.validateExpenseSplit(
            totalAmount: total1,
            splitAmounts: []
        )
        XCTAssertFalse(result.isValid, "Empty splits should fail")
        print("   ✓ Empty splits rejected")

        // Even distribution
        let distributed = try BusinessRuleValidator.distributeExpenseEvenly(
            totalAmount: Currency(double: 100.00),
            participantCount: 3
        )
        XCTAssertEqual(distributed.count, 3, "Should have 3 splits")
        let sum = distributed.reduce(Currency.zero, +)
        XCTAssertEqual(sum.doubleValue, 100.00, accuracy: 0.01, "Sum should equal total")
        print("   ✓ Even distribution: \(distributed.map { $0.formatted() }.joined(separator: ", "))")

        print("✅ Test 3.5.1: Expense split validation verified")
        print("   Result: PASS - Split validation working correctly")
    }

    // MARK: - Test 3.5.2: Payment Validation

    func testPaymentValidation() throws {
        print("🧪 Test 3.5.2: Testing payment validation")

        let balance = Currency(double: 100.00)

        // Valid payment (within balance)
        var result = BusinessRuleValidator.validatePayment(
            paymentAmount: Currency(double: 50.00),
            currentBalance: balance
        )
        XCTAssertTrue(result.isValid, "Valid payment should pass")
        print("   ✓ Valid payment: $50.00 against $100.00 balance")

        // Exact balance payment
        result = BusinessRuleValidator.validatePayment(
            paymentAmount: Currency(double: 100.00),
            currentBalance: balance
        )
        XCTAssertTrue(result.isValid, "Exact balance payment should pass")
        print("   ✓ Exact balance payment accepted")

        // Overpayment (not allowed)
        result = BusinessRuleValidator.validatePayment(
            paymentAmount: Currency(double: 150.00),
            currentBalance: balance,
            allowOverpayment: false
        )
        XCTAssertFalse(result.isValid, "Overpayment should fail when not allowed")
        print("   ✓ Overpayment rejected: \(result.error?.localizedDescription ?? "")")

        // Overpayment (allowed)
        result = BusinessRuleValidator.validatePayment(
            paymentAmount: Currency(double: 150.00),
            currentBalance: balance,
            allowOverpayment: true
        )
        XCTAssertTrue(result.isValid, "Overpayment should pass when allowed")
        print("   ✓ Overpayment allowed when specified")

        // Negative payment
        result = BusinessRuleValidator.validatePayment(
            paymentAmount: Currency(double: -50.00),
            currentBalance: balance
        )
        XCTAssertFalse(result.isValid, "Negative payment should fail")
        print("   ✓ Negative payment rejected")

        // Calculate new balance
        let newBalance = BusinessRuleValidator.calculateBalanceAfterPayment(
            currentBalance: balance,
            paymentAmount: Currency(double: 30.00)
        )
        XCTAssertEqual(newBalance.doubleValue, 70.00, accuracy: 0.01, "Balance calculation should be correct")
        print("   ✓ New balance after $30 payment: \(newBalance.formatted())")

        print("✅ Test 3.5.2: Payment validation verified")
        print("   Result: PASS - Payment validation working correctly")
    }

    // MARK: - Test 3.5.3: Date Range Validation

    func testDateRangeValidation() throws {
        print("🧪 Test 3.5.3: Testing date range validation")

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        // Valid range (start before end)
        var result = BusinessRuleValidator.validateDateRange(
            startDate: yesterday,
            endDate: tomorrow
        )
        XCTAssertTrue(result.isValid, "Valid date range should pass")
        print("   ✓ Valid date range: yesterday to tomorrow")

        // Same day (allowed)
        result = BusinessRuleValidator.validateDateRange(
            startDate: now,
            endDate: now,
            allowSameDay: true
        )
        XCTAssertTrue(result.isValid, "Same day should pass when allowed")
        print("   ✓ Same day allowed")

        // Same day (not allowed)
        result = BusinessRuleValidator.validateDateRange(
            startDate: now,
            endDate: now,
            allowSameDay: false
        )
        XCTAssertFalse(result.isValid, "Same day should fail when not allowed")
        print("   ✓ Same day rejected when not allowed")

        // Invalid range (end before start)
        result = BusinessRuleValidator.validateDateRange(
            startDate: tomorrow,
            endDate: yesterday
        )
        XCTAssertFalse(result.isValid, "Invalid range should fail")
        print("   ✓ Invalid range rejected: \(result.error?.localizedDescription ?? "")")

        print("✅ Test 3.5.3: Date range validation verified")
        print("   Result: PASS - Date range validation working correctly")
    }

    // MARK: - Test 3.5.4: Transaction Date Validation

    func testTransactionDateValidation() throws {
        print("🧪 Test 3.5.4: Testing transaction date validation")

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        // Current date
        var result = BusinessRuleValidator.validateTransactionDate(now)
        XCTAssertTrue(result.isValid, "Current date should pass")
        print("   ✓ Current date accepted")

        // Past date
        result = BusinessRuleValidator.validateTransactionDate(yesterday)
        XCTAssertTrue(result.isValid, "Past date should pass")
        print("   ✓ Past date accepted")

        // Future date
        result = BusinessRuleValidator.validateTransactionDate(tomorrow)
        XCTAssertFalse(result.isValid, "Future date should fail")
        print("   ✓ Future date rejected: \(result.error?.localizedDescription ?? "")")

        // Using extension
        let extensionResult = yesterday.validateNotFuture()
        XCTAssertTrue(extensionResult.isValid, "Extension method should work")
        print("   ✓ Date extension method working")

        print("✅ Test 3.5.4: Transaction date validation verified")
        print("   Result: PASS - Transaction date validation working correctly")
    }

    // MARK: - Test 3.5.5: Subscription Validation

    func testSubscriptionValidation() throws {
        print("🧪 Test 3.5.5: Testing subscription validation")

        // Active subscription
        var result = BusinessRuleValidator.validateSubscriptionActive(isActive: true)
        XCTAssertTrue(result.isValid, "Active subscription should pass")
        print("   ✓ Active subscription accepted")

        // Inactive subscription
        result = BusinessRuleValidator.validateSubscriptionActive(isActive: false)
        XCTAssertFalse(result.isValid, "Inactive subscription should fail")
        print("   ✓ Inactive subscription rejected: \(result.error?.localizedDescription ?? "")")

        // Valid billing cycle
        result = BusinessRuleValidator.validateBillingCycle(.monthly)
        XCTAssertTrue(result.isValid, "Valid billing cycle should pass")
        print("   ✓ Billing cycle validation passed")

        // Subscription dates
        let now = Date()
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: now)!

        result = BusinessRuleValidator.validateSubscriptionDates(
            startDate: now,
            endDate: nextMonth
        )
        XCTAssertTrue(result.isValid, "Valid subscription dates should pass")
        print("   ✓ Subscription date range accepted")

        // Invalid subscription dates
        result = BusinessRuleValidator.validateSubscriptionDates(
            startDate: nextMonth,
            endDate: now
        )
        XCTAssertFalse(result.isValid, "Invalid subscription dates should fail")
        print("   ✓ Invalid subscription dates rejected")

        print("✅ Test 3.5.5: Subscription validation verified")
        print("   Result: PASS - Subscription validation working correctly")
    }

    // MARK: - Test 3.5.6: Group Validation

    func testGroupValidation() throws {
        print("🧪 Test 3.5.6: Testing group validation")

        // Group with members
        var result = BusinessRuleValidator.validateGroupHasMembers(
            memberCount: 3,
            groupName: "Test Group"
        )
        XCTAssertTrue(result.isValid, "Group with members should pass")
        print("   ✓ Group with 3 members accepted")

        // Empty group
        result = BusinessRuleValidator.validateGroupHasMembers(
            memberCount: 0,
            groupName: "Empty Group"
        )
        XCTAssertFalse(result.isValid, "Empty group should fail")
        print("   ✓ Empty group rejected: \(result.error?.localizedDescription ?? "")")

        // Unique member
        let memberID = UUID()
        let existingIDs = [UUID(), UUID(), UUID()]

        result = BusinessRuleValidator.validateUniqueMember(
            memberID: memberID,
            existingMemberIDs: existingIDs,
            memberName: "New Member"
        )
        XCTAssertTrue(result.isValid, "Unique member should pass")
        print("   ✓ Unique member accepted")

        // Duplicate member
        result = BusinessRuleValidator.validateUniqueMember(
            memberID: existingIDs[0],
            existingMemberIDs: existingIDs,
            memberName: "Duplicate Member"
        )
        XCTAssertFalse(result.isValid, "Duplicate member should fail")
        print("   ✓ Duplicate member rejected: \(result.error?.localizedDescription ?? "")")

        print("✅ Test 3.5.6: Group validation verified")
        print("   Result: PASS - Group validation working correctly")
    }

    // MARK: - Test 3.5.7: Balance Validation

    func testBalanceValidation() throws {
        print("🧪 Test 3.5.7: Testing balance validation")

        // Positive balance
        var result = BusinessRuleValidator.validateNonNegativeBalance(
            Currency(double: 100.00)
        )
        XCTAssertTrue(result.isValid, "Positive balance should pass")
        print("   ✓ Positive balance accepted")

        // Zero balance
        result = BusinessRuleValidator.validateNonNegativeBalance(Currency.zero)
        XCTAssertTrue(result.isValid, "Zero balance should pass")
        print("   ✓ Zero balance accepted")

        // Negative balance
        result = BusinessRuleValidator.validateNonNegativeBalance(
            Currency(double: -50.00)
        )
        XCTAssertFalse(result.isValid, "Negative balance should fail")
        print("   ✓ Negative balance rejected: \(result.error?.localizedDescription ?? "")")

        // Sufficient balance
        result = BusinessRuleValidator.validateSufficientBalance(
            requiredAmount: Currency(double: 50.00),
            availableBalance: Currency(double: 100.00)
        )
        XCTAssertTrue(result.isValid, "Sufficient balance should pass")
        print("   ✓ Sufficient balance verified")

        // Insufficient balance
        result = BusinessRuleValidator.validateSufficientBalance(
            requiredAmount: Currency(double: 150.00),
            availableBalance: Currency(double: 100.00)
        )
        XCTAssertFalse(result.isValid, "Insufficient balance should fail")
        print("   ✓ Insufficient balance rejected: \(result.error?.localizedDescription ?? "")")

        // Using extension
        let amount = Currency(double: 100.00)
        let extensionResult = amount.validateNonNegative()
        XCTAssertTrue(extensionResult.isValid, "Extension method should work")
        print("   ✓ Currency extension method working")

        print("✅ Test 3.5.7: Balance validation verified")
        print("   Result: PASS - Balance validation working correctly")
    }

    // MARK: - Test 3.5.8: Self-Payment Validation

    func testSelfPaymentValidation() throws {
        print("🧪 Test 3.5.8: Testing self-payment validation")

        let personID1 = UUID()
        let personID2 = UUID()

        // Valid payment (different people)
        var result = BusinessRuleValidator.validateNotSelfPayment(
            payerID: personID1,
            payeeID: personID2,
            payerName: "Alice"
        )
        XCTAssertTrue(result.isValid, "Payment between different people should pass")
        print("   ✓ Payment between different people accepted")

        // Self-payment
        result = BusinessRuleValidator.validateNotSelfPayment(
            payerID: personID1,
            payeeID: personID1,
            payerName: "Bob"
        )
        XCTAssertFalse(result.isValid, "Self-payment should fail")
        print("   ✓ Self-payment rejected: \(result.error?.localizedDescription ?? "")")

        print("✅ Test 3.5.8: Self-payment validation verified")
        print("   Result: PASS - Self-payment validation working correctly")
    }

    // MARK: - Test 3.5.9: Composite Expense Validation

    func testCompositeExpenseValidation() throws {
        print("🧪 Test 3.5.9: Testing composite expense validation")

        let total = Currency(double: 100.00)
        let splits = [
            Currency(double: 33.33),
            Currency(double: 33.33),
            Currency(double: 33.34)
        ]
        let participantIDs = [UUID(), UUID(), UUID()]
        let date = Date()

        // Valid expense
        var results = BusinessRuleValidator.validateExpenseCreation(
            totalAmount: total,
            splitAmounts: splits,
            date: date,
            participantIDs: participantIDs
        )

        XCTAssertTrue(BusinessRuleValidator.areAllValid(results), "Valid expense should pass all checks")
        print("   ✓ Valid expense passed all checks")

        // Invalid expense (future date)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        results = BusinessRuleValidator.validateExpenseCreation(
            totalAmount: total,
            splitAmounts: splits,
            date: tomorrow,
            participantIDs: participantIDs
        )

        XCTAssertFalse(BusinessRuleValidator.areAllValid(results), "Future expense should fail")
        let errors = BusinessRuleValidator.getErrorMessages(results)
        print("   ✓ Future expense rejected: \(errors.joined(separator: ", "))")

        // Invalid expense (participant mismatch)
        results = BusinessRuleValidator.validateExpenseCreation(
            totalAmount: total,
            splitAmounts: splits,
            date: date,
            participantIDs: [UUID(), UUID()]  // Only 2 participants but 3 splits
        )

        XCTAssertFalse(BusinessRuleValidator.areAllValid(results), "Mismatched participants should fail")
        print("   ✓ Participant mismatch detected")

        print("✅ Test 3.5.9: Composite expense validation verified")
        print("   Result: PASS - Composite validation working correctly")
    }

    // MARK: - Test 3.5.10: Composite Payment Validation

    func testCompositePaymentValidation() throws {
        print("🧪 Test 3.5.10: Testing composite payment validation")

        let payerID = UUID()
        let payeeID = UUID()
        let amount = Currency(double: 50.00)
        let balance = Currency(double: 100.00)
        let date = Date()

        // Valid payment
        var results = BusinessRuleValidator.validatePaymentCreation(
            amount: amount,
            payerID: payerID,
            payeeID: payeeID,
            currentBalance: balance,
            date: date,
            payerName: "Alice"
        )

        XCTAssertTrue(BusinessRuleValidator.areAllValid(results), "Valid payment should pass all checks")
        print("   ✓ Valid payment passed all checks")

        // Invalid payment (self-payment)
        results = BusinessRuleValidator.validatePaymentCreation(
            amount: amount,
            payerID: payerID,
            payeeID: payerID,  // Same person
            currentBalance: balance,
            date: date,
            payerName: "Bob"
        )

        XCTAssertFalse(BusinessRuleValidator.areAllValid(results), "Self-payment should fail")
        let errors = BusinessRuleValidator.getErrorMessages(results)
        print("   ✓ Self-payment rejected: \(errors.joined(separator: ", "))")

        // Invalid payment (overpayment)
        results = BusinessRuleValidator.validatePaymentCreation(
            amount: Currency(double: 150.00),
            payerID: payerID,
            payeeID: payeeID,
            currentBalance: balance,
            date: date,
            payerName: "Charlie"
        )

        XCTAssertFalse(BusinessRuleValidator.areAllValid(results), "Overpayment should fail")
        print("   ✓ Overpayment rejected")

        print("✅ Test 3.5.10: Composite payment validation verified")
        print("   Result: PASS - Composite payment validation working correctly")
    }

    // MARK: - Test 3.5.11: Extension Methods

    func testExtensionMethods() throws {
        print("🧪 Test 3.5.11: Testing extension methods")

        // Currency extension
        let amount = Currency(double: 50.00)
        let balance = Currency(double: 100.00)

        let paymentResult = amount.validateAsPayment(against: balance)
        XCTAssertTrue(paymentResult.isValid, "Currency payment validation should work")
        print("   ✓ Currency.validateAsPayment() working")

        let nonNegativeResult = amount.validateNonNegative()
        XCTAssertTrue(nonNegativeResult.isValid, "Currency non-negative validation should work")
        print("   ✓ Currency.validateNonNegative() working")

        // Date extension
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let futureResult = yesterday.validateNotFuture()
        XCTAssertTrue(futureResult.isValid, "Date future validation should work")
        print("   ✓ Date.validateNotFuture() working")

        let rangeResult = yesterday.validateRange(to: tomorrow)
        XCTAssertTrue(rangeResult.isValid, "Date range validation should work")
        print("   ✓ Date.validateRange() working")

        print("✅ Test 3.5.11: Extension methods verified")
        print("   Result: PASS - All extension methods working correctly")
    }

    // MARK: - Test 3.5.12: Edge Cases

    func testEdgeCases() throws {
        print("🧪 Test 3.5.12: Testing edge cases")

        // Very small amounts (rounding)
        let tinyAmount = Currency(double: 0.01)
        let splits = [
            Currency(double: 0.003),
            Currency(double: 0.003),
            Currency(double: 0.004)
        ]

        let splitResult = BusinessRuleValidator.validateExpenseSplit(
            totalAmount: tinyAmount,
            splitAmounts: splits
        )
        print("   ✓ Tiny amount split: \(splitResult.isValid ? "valid" : "invalid")")

        // Large participant count
        let largeExpense = try BusinessRuleValidator.distributeExpenseEvenly(
            totalAmount: Currency(double: 1000.00),
            participantCount: 100
        )
        XCTAssertEqual(largeExpense.count, 100, "Should split among 100 participants")
        print("   ✓ Large participant count (100) handled")

        // Exact balance payment
        let exactPayment = BusinessRuleValidator.validatePayment(
            paymentAmount: Currency(double: 100.00),
            currentBalance: Currency(double: 100.00)
        )
        XCTAssertTrue(exactPayment.isValid, "Exact balance payment should be valid")
        print("   ✓ Exact balance payment accepted")

        // Millisecond-level date differences
        let now = Date()
        let almostNow = now.addingTimeInterval(0.001)  // 1 millisecond later

        let rangeResult = BusinessRuleValidator.validateDateRange(
            startDate: now,
            endDate: almostNow
        )
        XCTAssertTrue(rangeResult.isValid, "Millisecond difference should be valid")
        print("   ✓ Millisecond-level date difference handled")

        print("✅ Test 3.5.12: Edge cases verified")
        print("   Result: PASS - Edge cases handled appropriately")
    }
}
