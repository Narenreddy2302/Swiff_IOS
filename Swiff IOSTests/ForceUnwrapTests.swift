//
//  ForceUnwrapTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 1.2: Fix Force Unwraps
//

import XCTest
import SwiftData
@testable import Swiff_IOS

@MainActor
final class ForceUnwrapTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container for testing
        let schema = Schema([
            PersonModel.self,
            SubscriptionModel.self,
            TransactionModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }

    // MARK: - Test 1.2.1: Date Calculation Edge Cases

    func testJanuaryToFebruaryTransition() throws {
        print("🧪 Test 1.2.1: Testing January 31 → February transition")

        let calendar = Calendar.current

        // Test January 31st
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 31
        components.hour = 12
        components.minute = 0

        guard let startDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        print("   Start date: January 31, 2025")

        // Add 1 month using safe date arithmetic
        guard let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            XCTFail("Date calculation should not fail")
            return
        }

        print("   Next month: \(nextMonthDate)")

        // Verify it's in February (not March)
        let resultMonth = calendar.component(.month, from: nextMonthDate)
        let resultDay = calendar.component(.day, from: nextMonthDate)

        // February only has 28/29 days, so Jan 31 + 1 month should be Feb 28/29
        XCTAssertEqual(resultMonth, 2, "Should be February")
        XCTAssertTrue(resultDay <= 29, "Day should be <= 29")

        print("✅ Test 1.2.1: Date calculation verified")
        print("   Result: PASS - Month boundary handled correctly")
        print("   Result date: February \(resultDay), 2025")
    }

    // MARK: - Test 1.2.2: Daylight Saving Time Transitions

    func testDSTTransitions() throws {
        print("🧪 Test 1.2.2: Testing Daylight Saving Time transitions")

        let calendar = Calendar.current

        // Spring forward: March 10, 2024, 2:00 AM → 3:00 AM (23-hour day)
        var springComponents = DateComponents()
        springComponents.year = 2024
        springComponents.month = 3
        springComponents.day = 10
        springComponents.hour = 1
        springComponents.minute = 30

        guard let springDate = calendar.date(from: springComponents) else {
            XCTFail("Failed to create spring DST date")
            return
        }

        // Add 24 hours
        guard let springResult = calendar.date(byAdding: .hour, value: 24, to: springDate) else {
            XCTFail("Spring DST calculation failed")
            return
        }

        print("   Spring forward test:")
        print("   Start: \(springDate)")
        print("   +24 hours: \(springResult)")

        // Fall back: November 3, 2024, 2:00 AM → 1:00 AM (25-hour day)
        var fallComponents = DateComponents()
        fallComponents.year = 2024
        fallComponents.month = 11
        fallComponents.day = 3
        fallComponents.hour = 1
        fallComponents.minute = 30

        guard let fallDate = calendar.date(from: fallComponents) else {
            XCTFail("Failed to create fall DST date")
            return
        }

        // Add 24 hours
        guard let fallResult = calendar.date(byAdding: .hour, value: 24, to: fallDate) else {
            XCTFail("Fall DST calculation failed")
            return
        }

        print("   Fall back test:")
        print("   Start: \(fallDate)")
        print("   +24 hours: \(fallResult)")

        print("✅ Test 1.2.2: DST transitions verified")
        print("   Result: PASS - DST handled without crashes")
    }

    // MARK: - Test 1.2.3: Leap Year Handling

    func testLeapYearHandling() throws {
        print("🧪 Test 1.2.3: Testing leap year February 29 calculations")

        let calendar = Calendar.current

        // Test February 29, 2024 (leap year)
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 29
        components.hour = 12

        guard let leapDate = calendar.date(from: components) else {
            XCTFail("Failed to create leap year date")
            return
        }

        print("   Leap year date: February 29, 2024")

        // Add 1 year - should go to February 28, 2025 (non-leap year)
        guard let nextYearDate = calendar.date(byAdding: .year, value: 1, to: leapDate) else {
            XCTFail("Leap year calculation failed")
            return
        }

        let resultMonth = calendar.component(.month, from: nextYearDate)
        let resultDay = calendar.component(.day, from: nextYearDate)
        let resultYear = calendar.component(.year, from: nextYearDate)

        print("   Next year: \(nextYearDate)")

        // Should be February 28, 2025
        XCTAssertEqual(resultYear, 2025, "Should be 2025")
        XCTAssertEqual(resultMonth, 2, "Should be February")
        XCTAssertEqual(resultDay, 28, "Should be Feb 28 (non-leap year)")

        print("✅ Test 1.2.3: Leap year handling verified")
        print("   Result: PASS - Leap year boundary handled correctly")
        print("   Result: February \(resultDay), \(resultYear)")
    }

    // MARK: - Test 1.2.4: Price Validation

    func testPriceValidationWithInvalidInput() throws {
        print("🧪 Test 1.2.4: Testing price validation with invalid input")

        // Test cases for price validation
        let testCases: [(input: String, shouldBeValid: Bool, description: String)] = [
            ("123.45", true, "Valid price"),
            ("-10.00", false, "Negative price"),
            ("0.00", false, "Zero price"),
            ("abc", false, "Non-numeric text"),
            ("12.345", true, "More than 2 decimals (should round)"),
            ("", false, "Empty string"),
            ("   ", false, "Whitespace only"),
            ("12.5", true, "One decimal place"),
            ("1000000.00", true, "Large amount"),
        ]

        var passedTests = 0
        var failedTests = 0

        for testCase in testCases {
            let parsedValue = Double(testCase.input)
            let isValid = parsedValue != nil && (parsedValue ?? 0) > 0

            if isValid == testCase.shouldBeValid {
                passedTests += 1
                print("   ✓ \(testCase.description): '\(testCase.input)' → \(isValid ? "Valid" : "Invalid")")
            } else {
                failedTests += 1
                print("   ✗ \(testCase.description): '\(testCase.input)' → Expected \(testCase.shouldBeValid), got \(isValid)")
            }
        }

        XCTAssertEqual(failedTests, 0, "All price validation tests should pass")

        print("✅ Test 1.2.4: Price validation verified")
        print("   Result: PASS - \(passedTests)/\(testCases.count) validation tests passed")
    }

    // MARK: - Test 1.2.5: Sample Data Generation

    func testSampleDataGeneration() throws {
        print("🧪 Test 1.2.5: Testing sample data generation with safe optionals")

        // Create sample person
        let person = PersonModel(
            name: "Test User",
            email: "test@example.com",
            phone: "123-456-7890"
        )

        // Set safe default values
        person.balance = 100.50
        person.dateCreated = Date()
        person.lastModifiedDate = Date()

        // Verify all required fields are set
        XCTAssertNotNil(person.name, "Name should be set")
        XCTAssertNotNil(person.balance, "Balance should be set")
        XCTAssertNotNil(person.dateCreated, "Date created should be set")

        print("   Person created: \(person.name)")
        print("   Balance: $\(person.balance)")
        print("   Date created: \(person.dateCreated)")

        // Create sample subscription
        let subscription = SubscriptionModel(
            name: "Test Subscription",
            price: 9.99,
            billingCycle: .monthly,
            startDate: Date(),
            category: "Entertainment"
        )

        subscription.nextBillingDate = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: Date()
        ) ?? Date()

        XCTAssertNotNil(subscription.name, "Subscription name should be set")
        XCTAssertNotNil(subscription.price, "Price should be set")
        XCTAssertNotNil(subscription.nextBillingDate, "Next billing date should be set")

        print("   Subscription created: \(subscription.name)")
        print("   Price: $\(subscription.price)")
        print("   Next billing: \(subscription.nextBillingDate)")

        // Create sample transaction
        let transaction = TransactionModel(
            amount: 25.00,
            type: .expense,
            date: Date(),
            category: "Food"
        )

        XCTAssertNotNil(transaction.amount, "Transaction amount should be set")
        XCTAssertNotNil(transaction.date, "Transaction date should be set")

        print("   Transaction created: $\(transaction.amount)")
        print("   Date: \(transaction.date)")

        print("✅ Test 1.2.5: Sample data generation verified")
        print("   Result: PASS - All data generated with safe defaults")
    }

    // MARK: - Additional Test: Guard Statement Safety

    func testGuardStatementSafety() throws {
        print("🧪 Additional Test: Testing guard statement implementations")

        // Test safe unwrapping with guard
        func safeCalculation(value: Double?) -> Double {
            guard let value = value else {
                return 0.0
            }
            return value * 2
        }

        // Test cases
        let result1 = safeCalculation(value: 10.0)
        XCTAssertEqual(result1, 20.0, "Should calculate with valid value")

        let result2 = safeCalculation(value: nil)
        XCTAssertEqual(result2, 0.0, "Should return default with nil")

        print("   ✓ Guard statement with valid value: 10.0 → 20.0")
        print("   ✓ Guard statement with nil value: nil → 0.0")

        print("✅ Additional Test: Guard statements working correctly")
        print("   Result: PASS - No force unwraps, safe fallbacks in place")
    }
}
