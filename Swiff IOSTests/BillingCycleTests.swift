//
//  BillingCycleTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 3.2: Fix Billing Cycle Calculations
//

import XCTest
@testable import Swiff_IOS

final class BillingCycleTests: XCTestCase {

    // MARK: - Test 3.2.1: Weekly Calculation Accuracy

    func testWeeklyCalculationAccuracy() throws {
        print("🧪 Test 3.2.1: Testing weekly subscription calculation (should be 4.345, not 4.33)")

        let weeklyAmount = Currency(double: 10.00)

        // Calculate monthly equivalent
        let monthly = BillingCycleCalculator.monthlyCost(
            cycleAmount: weeklyAmount,
            cycle: .weekly
        )

        // Correct calculation: 10 × 52.1429 / 12 = 43.452417
        let expected = 43.452417
        XCTAssertEqual(monthly.doubleValue, expected, accuracy: 0.01)

        print("   ✓ Weekly $10.00 → Monthly \(monthly.formatted())")
        print("   Exact value: \(monthly.doubleValue)")
        print("   Expected: ~$43.45 (not $43.33)")

        // Verify it uses correct weeks/year ratio
        let weeksPerYear = BillingCycle.weeksPerYear
        XCTAssertEqual(weeksPerYear, 52.1429, accuracy: 0.0001)
        print("   ✓ Weeks per year: \(weeksPerYear) (accounts for 365.25 days)")

        print("✅ Test 3.2.1: Weekly calculation verified")
        print("   Result: PASS - Using precise 52.1429 weeks/year")
    }

    // MARK: - Test 3.2.2: All Billing Cycles

    func testAllBillingCycles() throws {
        print("🧪 Test 3.2.2: Testing all billing cycle calculations")

        let amount = Currency(double: 100.00)

        // Daily
        let dailyAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .daily)
        XCTAssertEqual(dailyAnnual.doubleValue, 36525.0, accuracy: 1.0)
        print("   ✓ Daily: $100/day → \(dailyAnnual.formatted())/year")

        // Weekly
        let weeklyAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .weekly)
        XCTAssertEqual(weeklyAnnual.doubleValue, 5214.29, accuracy: 1.0)
        print("   ✓ Weekly: $100/week → \(weeklyAnnual.formatted())/year")

        // Biweekly
        let biweeklyAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .biweekly)
        XCTAssertEqual(biweeklyAnnual.doubleValue, 2607.14, accuracy: 1.0)
        print("   ✓ Biweekly: $100/2weeks → \(biweeklyAnnual.formatted())/year")

        // Monthly
        let monthlyAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .monthly)
        XCTAssertEqual(monthlyAnnual.doubleValue, 1200.0, accuracy: 0.1)
        print("   ✓ Monthly: $100/month → \(monthlyAnnual.formatted())/year")

        // Quarterly
        let quarterlyAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .quarterly)
        XCTAssertEqual(quarterlyAnnual.doubleValue, 400.0, accuracy: 0.1)
        print("   ✓ Quarterly: $100/quarter → \(quarterlyAnnual.formatted())/year")

        // Semiannually
        let semiAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .semiannually)
        XCTAssertEqual(semiAnnual.doubleValue, 200.0, accuracy: 0.1)
        print("   ✓ Semiannually: $100/6mo → \(semiAnnual.formatted())/year")

        // Annually
        let annual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .annually)
        XCTAssertEqual(annual.doubleValue, 100.0, accuracy: 0.1)
        print("   ✓ Annually: $100/year → \(annual.formatted())/year")

        print("✅ Test 3.2.2: All billing cycles verified")
        print("   Result: PASS - All 7 cycles calculate correctly")
    }

    // MARK: - Test 3.2.3: Monthly Equivalents

    func testMonthlyEquivalents() throws {
        print("🧪 Test 3.2.3: Testing monthly equivalent calculations")

        let testCases: [(cycle: BillingCycle, amount: Double, expectedMonthly: Double)] = [
            (.weekly, 10.00, 43.45),
            (.biweekly, 50.00, 108.63),
            (.monthly, 100.00, 100.00),
            (.quarterly, 300.00, 100.00),
            (.annually, 1200.00, 100.00)
        ]

        for testCase in testCases {
            let amount = Currency(double: testCase.amount)
            let monthly = BillingCycleCalculator.monthlyCost(
                cycleAmount: amount,
                cycle: testCase.cycle
            )

            XCTAssertEqual(monthly.doubleValue, testCase.expectedMonthly, accuracy: 0.5)
            print("   ✓ \(testCase.cycle.rawValue) \(amount.formatted()) → \(monthly.formatted())/month")
        }

        print("✅ Test 3.2.3: Monthly equivalents verified")
        print("   Result: PASS - All monthly conversions accurate")
    }

    // MARK: - Test 3.2.4: Next Billing Date

    func testNextBillingDate() throws {
        print("🧪 Test 3.2.4: Testing next billing date calculations")

        let calendar = Calendar.current
        let startDate = Date()

        // Test weekly
        if let weekly = BillingCycleCalculator.nextBillingDate(from: startDate, cycle: .weekly) {
            let days = calendar.dateComponents([.day], from: startDate, to: weekly).day ?? 0
            XCTAssertEqual(days, 7, "Weekly should be 7 days")
            print("   ✓ Weekly: +7 days")
        }

        // Test monthly
        if let monthly = BillingCycleCalculator.nextBillingDate(from: startDate, cycle: .monthly) {
            let months = calendar.dateComponents([.month], from: startDate, to: monthly).month ?? 0
            XCTAssertEqual(months, 1, "Monthly should be 1 month")
            print("   ✓ Monthly: +1 month")
        }

        // Test annually
        if let annual = BillingCycleCalculator.nextBillingDate(from: startDate, cycle: .annually) {
            let years = calendar.dateComponents([.year], from: startDate, to: annual).year ?? 0
            XCTAssertEqual(years, 1, "Annually should be 1 year")
            print("   ✓ Annually: +1 year")
        }

        print("✅ Test 3.2.4: Next billing date verified")
        print("   Result: PASS - Date calculations correct")
    }

    // MARK: - Test 3.2.5: Leap Year Handling

    func testLeapYearHandling() throws {
        print("🧪 Test 3.2.5: Testing leap year impact on calculations")

        let amount = Currency(double: 1.00)

        // Daily subscription over a year should account for leap year
        let dailyAnnual = BillingCycleCalculator.annualCost(cycleAmount: amount, cycle: .daily)

        // Should use 365.25 average days per year
        XCTAssertEqual(dailyAnnual.doubleValue, 365.25, accuracy: 0.01)
        print("   ✓ Daily: $1/day × 365.25 days = \(dailyAnnual.formatted())/year")

        // Weekly calculation also uses 365.25 / 7
        let weeklyOccurrences = BillingCycle.weekly.occurrencesPerYear
        XCTAssertEqual(weeklyOccurrences, 52.1429, accuracy: 0.0001)
        print("   ✓ Weekly occurrences: \(weeklyOccurrences) (accounts for leap year)")

        print("✅ Test 3.2.5: Leap year handling verified")
        print("   Result: PASS - Leap years properly accounted for")
    }

    // MARK: - Test 3.2.6: Billing Periods in Range

    func testBillingPeriodsInRange() throws {
        print("🧪 Test 3.2.6: Testing billing period counting")

        let calendar = Calendar.current
        let startDate = Date()

        // 3 months later
        guard let endDate = calendar.date(byAdding: .month, value: 3, to: startDate) else {
            XCTFail("Failed to create end date")
            return
        }

        // Monthly billing
        let monthlyPeriods = BillingCycleCalculator.billingPeriods(
            from: startDate,
            to: endDate,
            cycle: .monthly
        )
        XCTAssertEqual(monthlyPeriods, 3, "Should have 3 monthly periods")
        print("   ✓ Monthly periods in 3 months: \(monthlyPeriods)")

        // Weekly billing
        let weeklyPeriods = BillingCycleCalculator.billingPeriods(
            from: startDate,
            to: endDate,
            cycle: .weekly
        )
        XCTAssertTrue(weeklyPeriods >= 12 && weeklyPeriods <= 13, "Should have ~12-13 weekly periods")
        print("   ✓ Weekly periods in 3 months: \(weeklyPeriods)")

        print("✅ Test 3.2.6: Billing period counting verified")
        print("   Result: PASS - Period calculations correct")
    }

    // MARK: - Test 3.2.7: Total Cost in Range

    func testTotalCostInRange() throws {
        print("🧪 Test 3.2.7: Testing total cost calculation for date range")

        let calendar = Calendar.current
        let startDate = Date()

        guard let endDate = calendar.date(byAdding: .month, value: 6, to: startDate) else {
            XCTFail("Failed to create end date")
            return
        }

        let monthlyAmount = Currency(double: 9.99)

        let totalCost = BillingCycleCalculator.totalCost(
            cycleAmount: monthlyAmount,
            cycle: .monthly,
            from: startDate,
            to: endDate
        )

        // 6 months × $9.99 = $59.94
        XCTAssertEqual(totalCost.doubleValue, 59.94, accuracy: 0.01)
        print("   ✓ 6 months × \(monthlyAmount.formatted()) = \(totalCost.formatted())")

        print("✅ Test 3.2.7: Total cost calculation verified")
        print("   Result: PASS - Range cost accurate")
    }

    // MARK: - Test 3.2.8: Proration

    func testProration() throws {
        print("🧪 Test 3.2.8: Testing prorated billing calculations")

        let monthlyAmount = Currency(double: 30.00)

        // Use 15 days of a monthly subscription
        let prorated = BillingCycleCalculator.prorated(
            cycleAmount: monthlyAmount,
            cycle: .monthly,
            daysUsed: 15
        )

        // Average month is 365.25/12 = 30.4375 days
        // 15 days ≈ half month = ~$14.78
        let expected = 14.78
        XCTAssertEqual(prorated.doubleValue, expected, accuracy: 0.5)
        print("   ✓ 15 days of \(monthlyAmount.formatted())/month = \(prorated.formatted())")

        // Use 7 days of a weekly subscription
        let weeklyAmount = Currency(double: 7.00)
        let weeklyProrated = BillingCycleCalculator.prorated(
            cycleAmount: weeklyAmount,
            cycle: .weekly,
            daysUsed: 7
        )

        // Full week
        XCTAssertEqual(weeklyProrated.doubleValue, 7.00, accuracy: 0.01)
        print("   ✓ 7 days of \(weeklyAmount.formatted())/week = \(weeklyProrated.formatted())")

        print("✅ Test 3.2.8: Proration verified")
        print("   Result: PASS - Prorated amounts accurate")
    }

    // MARK: - Test 3.2.9: Billing Summary

    func testBillingSummary() throws {
        print("🧪 Test 3.2.9: Testing billing summary generation")

        let weeklyAmount = Currency(double: 10.00)
        let summary = BillingSummary(cycleAmount: weeklyAmount, cycle: .weekly)

        XCTAssertEqual(summary.cycleAmount.doubleValue, 10.00, accuracy: 0.01)
        XCTAssertEqual(summary.monthlyEquivalent.doubleValue, 43.45, accuracy: 0.5)
        XCTAssertEqual(summary.annualTotal.doubleValue, 521.43, accuracy: 1.0)

        print("   \(summary.description)")

        print("✅ Test 3.2.9: Billing summary verified")
        print("   Result: PASS - Summary calculates correctly")
    }

    // MARK: - Test 3.2.10: Backward Compatibility

    func testBackwardCompatibility() throws {
        print("🧪 Test 3.2.10: Testing backward compatibility with Double")

        let weeklyPrice: Double = 10.00

        // Use Double-based method
        let annual = BillingCycleCalculator.annualCost(
            cycleAmount: weeklyPrice,
            cycle: .weekly
        )

        XCTAssertEqual(annual, 521.429, accuracy: 1.0)
        print("   ✓ Double input: $\(weeklyPrice)/week → $\(String(format: "%.2f", annual))/year")

        let monthly = BillingCycleCalculator.monthlyCost(
            cycleAmount: weeklyPrice,
            cycle: .weekly
        )

        XCTAssertEqual(monthly, 43.45, accuracy: 0.5)
        print("   ✓ Monthly equivalent: $\(String(format: "%.2f", monthly))/month")

        print("✅ Test 3.2.10: Backward compatibility verified")
        print("   Result: PASS - Double-based methods work correctly")
    }
}
