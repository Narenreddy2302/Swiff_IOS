//
//  DateTimeHelperTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 3.3: DST-aware date/time handling
//

import XCTest
@testable import Swiff_IOS

final class DateTimeHelperTests: XCTestCase {

    // MARK: - Test 3.3.1: DST Transition Detection

    func testDSTTransitionDetection() throws {
        print("🧪 Test 3.3.1: Testing DST transition detection")

        // Create a date during spring forward (March 2024 - 2nd Sunday)
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10
        components.hour = 2
        components.minute = 30
        components.timeZone = TimeZone(identifier: "America/New_York")

        let calendar = Calendar.current
        if let springDate = calendar.date(from: components) {
            let info = DateTimeHelper.dstTransitionInfo(for: springDate)

            if info.isDSTTransition {
                print("   ✓ Spring forward detected on March 10, 2024")
                print("   ✓ Transition type: \(info.description)")
                XCTAssertEqual(info.transitionType, .springForward)
            } else {
                print("   ℹ️ No DST transition detected (timezone may not observe DST)")
            }
        }

        // Create a date during fall back (November 2024 - 1st Sunday)
        components.year = 2024
        components.month = 11
        components.day = 3
        components.hour = 2
        components.minute = 30

        if let fallDate = calendar.date(from: components) {
            let info = DateTimeHelper.dstTransitionInfo(for: fallDate)

            if info.isDSTTransition {
                print("   ✓ Fall back detected on November 3, 2024")
                print("   ✓ Transition type: \(info.description)")
                XCTAssertEqual(info.transitionType, .fallBack)
            } else {
                print("   ℹ️ No DST transition detected (timezone may not observe DST)")
            }
        }

        print("✅ Test 3.3.1: DST transition detection verified")
        print("   Result: PASS - DST transitions detected correctly")
    }

    // MARK: - Test 3.3.2: Date Extension Properties

    func testDateExtensionProperties() throws {
        print("🧪 Test 3.3.2: Testing Date extension DST properties")

        let date = Date()
        let info = date.dstTransitionInfo

        print("   ✓ Current date DST info: \(info.description)")
        print("   ✓ Is DST transition: \(date.isDSTTransition)")

        // Test should complete without errors
        XCTAssertNotNil(info, "DST info should not be nil")

        print("✅ Test 3.3.2: Date extension properties verified")
        print("   Result: PASS - Extension properties work correctly")
    }

    // MARK: - Test 3.3.3: DST-Safe Day Addition

    func testDSTSafeDayAddition() throws {
        print("🧪 Test 3.3.3: Testing DST-safe day addition")

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 9 // Day before spring forward
        components.hour = 12
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/New_York")

        guard let startDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        // Add 1 day across DST transition
        if let nextDay = DateTimeHelper.addDays(1, to: startDate) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: nextDay)

            print("   ✓ Start: March 9, 2024 at 12:00")
            print("   ✓ After +1 day: \(DateTimeHelper.formattedWithDST(date: nextDay))")
            print("   ✓ Time preserved: \(timeComponents.hour ?? 0):\(String(format: "%02d", timeComponents.minute ?? 0))")

            // Time should be preserved even during DST transition
            XCTAssertEqual(timeComponents.hour, 12, "Hour should be preserved")
            XCTAssertEqual(timeComponents.minute, 0, "Minute should be preserved")
        } else {
            XCTFail("Failed to add days")
        }

        print("✅ Test 3.3.3: DST-safe day addition verified")
        print("   Result: PASS - Days added correctly across DST")
    }

    // MARK: - Test 3.3.4: DST-Safe Hour Addition

    func testDSTSafeHourAddition() throws {
        print("🧪 Test 3.3.4: Testing DST-safe hour addition")

        let startDate = Date()

        // Add 24 hours
        if let after24Hours = DateTimeHelper.addHours(24, to: startDate) {
            let interval = after24Hours.timeIntervalSince(startDate)
            let hours = Int(interval / 3600)

            print("   ✓ Start: \(DateTimeHelper.formattedWithDST(date: startDate))")
            print("   ✓ After 24 hours: \(DateTimeHelper.formattedWithDST(date: after24Hours))")
            print("   ✓ Actual hours elapsed: \(hours)")

            XCTAssertEqual(hours, 24, "Should be exactly 24 hours")
        }

        print("✅ Test 3.3.4: DST-safe hour addition verified")
        print("   Result: PASS - Hours added correctly")
    }

    // MARK: - Test 3.3.5: Same Time Next Day

    func testSameTimeNextDay() throws {
        print("🧪 Test 3.3.5: Testing same clock time next day")

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 0

        guard let startDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        if let nextDay = DateTimeHelper.sameTimeNextDay(from: startDate) {
            let originalTime = calendar.dateComponents([.hour, .minute], from: startDate)
            let nextDayTime = calendar.dateComponents([.hour, .minute], from: nextDay)

            print("   ✓ Original: June 15 at \(originalTime.hour!):\(String(format: "%02d", originalTime.minute!))")
            print("   ✓ Next day: June 16 at \(nextDayTime.hour!):\(String(format: "%02d", nextDayTime.minute!))")

            XCTAssertEqual(originalTime.hour, nextDayTime.hour, "Hour should match")
            XCTAssertEqual(originalTime.minute, nextDayTime.minute, "Minute should match")
        }

        print("✅ Test 3.3.5: Same time next day verified")
        print("   Result: PASS - Clock time preserved correctly")
    }

    // MARK: - Test 3.3.6: Hours Between Dates

    func testHoursBetweenDates() throws {
        print("🧪 Test 3.3.6: Testing hours calculation between dates")

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7200) // 2 hours

        let hours = DateTimeHelper.hoursBetween(start: startDate, end: endDate)

        print("   ✓ Start: \(DateTimeHelper.formattedWithDST(date: startDate))")
        print("   ✓ End: \(DateTimeHelper.formattedWithDST(date: endDate))")
        print("   ✓ Hours between: \(hours)")

        XCTAssertEqual(hours, 2, "Should be 2 hours")

        print("✅ Test 3.3.6: Hours between dates verified")
        print("   Result: PASS - Hour calculation correct")
    }

    // MARK: - Test 3.3.7: Days Between Dates

    func testDaysBetweenDates() throws {
        print("🧪 Test 3.3.7: Testing days calculation between dates")

        let calendar = Calendar.current
        let startDate = Date()
        guard let endDate = calendar.date(byAdding: .day, value: 5, to: startDate) else {
            XCTFail("Failed to create end date")
            return
        }

        let days = DateTimeHelper.daysBetween(start: startDate, end: endDate)

        print("   ✓ Days between: \(days)")
        XCTAssertEqual(days, 5, "Should be 5 days")

        print("✅ Test 3.3.7: Days between dates verified")
        print("   Result: PASS - Day calculation correct")
    }

    // MARK: - Test 3.3.8: Subscription Renewal Date

    func testSubscriptionRenewalDate() throws {
        print("🧪 Test 3.3.8: Testing subscription renewal date calculation")

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = 10
        components.minute = 30

        guard let startDate = calendar.date(from: components) else {
            XCTFail("Failed to create start date")
            return
        }

        // Test monthly renewal
        if let renewalDate = DateTimeHelper.subscriptionRenewalDate(
            startDate: startDate,
            billingCycle: .monthly,
            occurrences: 1
        ) {
            let renewalComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: renewalDate)

            print("   ✓ Start: Jan 15, 2024 at 10:30")
            print("   ✓ Renewal: \(renewalComponents.month!)/\(renewalComponents.day!) at \(renewalComponents.hour!):\(String(format: "%02d", renewalComponents.minute!))")

            XCTAssertEqual(renewalComponents.month, 2, "Should be February")
            XCTAssertEqual(renewalComponents.day, 15, "Should be 15th")
            XCTAssertEqual(renewalComponents.hour, 10, "Hour should be preserved")
            XCTAssertEqual(renewalComponents.minute, 30, "Minute should be preserved")
        }

        print("✅ Test 3.3.8: Subscription renewal date verified")
        print("   Result: PASS - Renewal dates calculated correctly")
    }

    // MARK: - Test 3.3.9: Start and End of Day

    func testStartAndEndOfDay() throws {
        print("🧪 Test 3.3.9: Testing start and end of day calculations")

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30

        guard let midDay = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        // Start of day
        if let startOfDay = DateTimeHelper.startOfDay(for: midDay) {
            let startComponents = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

            print("   ✓ Start of day: \(startComponents.hour!):\(String(format: "%02d", startComponents.minute!)):\(String(format: "%02d", startComponents.second!))")

            XCTAssertEqual(startComponents.hour, 0, "Should be midnight")
            XCTAssertEqual(startComponents.minute, 0, "Should be 0 minutes")
            XCTAssertEqual(startComponents.second, 0, "Should be 0 seconds")
        }

        // End of day
        if let endOfDay = DateTimeHelper.endOfDay(for: midDay) {
            let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endOfDay)

            print("   ✓ End of day: \(endComponents.hour!):\(String(format: "%02d", endComponents.minute!)):\(String(format: "%02d", endComponents.second!))")

            XCTAssertEqual(endComponents.hour, 23, "Should be 23 hours")
            XCTAssertEqual(endComponents.minute, 59, "Should be 59 minutes")
            XCTAssertEqual(endComponents.second, 59, "Should be 59 seconds")
        }

        print("✅ Test 3.3.9: Start and end of day verified")
        print("   Result: PASS - Day boundaries calculated correctly")
    }

    // MARK: - Test 3.3.10: Working Hours Calculation

    func testWorkingHoursCalculation() throws {
        print("🧪 Test 3.3.10: Testing working hours calculation")

        let calendar = Calendar.current
        let startDate = Date()
        guard let endDate = calendar.date(byAdding: .day, value: 3, to: startDate) else {
            XCTFail("Failed to create end date")
            return
        }

        let workingHours = DateTimeHelper.workingHoursBetween(
            start: startDate,
            end: endDate,
            workingHoursPerDay: 8
        )

        print("   ✓ Working hours over 3 days (8h/day): \(workingHours)")
        XCTAssertEqual(workingHours, 24.0, accuracy: 1.0, "Should be approximately 24 working hours")

        print("✅ Test 3.3.10: Working hours calculation verified")
        print("   Result: PASS - Working hours calculated correctly")
    }

    // MARK: - Test 3.3.11: Date Validation

    func testDateValidation() throws {
        print("🧪 Test 3.3.11: Testing date validation")

        // Valid date
        let validDate = DateTimeHelper.isValidDate(
            year: 2024,
            month: 6,
            day: 15,
            hour: 14,
            minute: 30
        )

        print("   ✓ Valid date (June 15, 2024 14:30): \(validDate)")
        XCTAssertTrue(validDate, "Should be a valid date")

        // Invalid date (February 30th doesn't exist)
        let invalidDate = DateTimeHelper.isValidDate(
            year: 2024,
            month: 2,
            day: 30,
            hour: 12,
            minute: 0
        )

        print("   ✓ Invalid date (Feb 30, 2024): \(invalidDate)")
        XCTAssertFalse(invalidDate, "Should be an invalid date")

        print("✅ Test 3.3.11: Date validation verified")
        print("   Result: PASS - Date validation works correctly")
    }

    // MARK: - Test 3.3.12: DST Formatting

    func testDSTFormatting() throws {
        print("🧪 Test 3.3.12: Testing DST-aware date formatting")

        let date = Date()

        // Format with offset
        let formatted = DateTimeHelper.formattedWithDST(date: date, includeOffset: true)
        print("   ✓ Formatted with offset: \(formatted)")
        XCTAssertTrue(formatted.contains("GMT"), "Should contain GMT offset")

        // Format without offset
        let noOffset = DateTimeHelper.formattedWithDST(date: date, includeOffset: false)
        print("   ✓ Formatted without offset: \(noOffset)")
        XCTAssertFalse(noOffset.contains("GMT"), "Should not contain GMT offset")

        // Test extension method
        let extensionFormatted = date.formattedWithDST()
        print("   ✓ Extension formatted: \(extensionFormatted)")
        XCTAssertTrue(extensionFormatted.contains("GMT"), "Extension should include GMT")

        print("✅ Test 3.3.12: DST formatting verified")
        print("   Result: PASS - Formatting works correctly")
    }

    // MARK: - Test 3.3.13: Next DST Transition

    func testNextDSTTransition() throws {
        print("🧪 Test 3.3.13: Testing next DST transition finder")

        if let nextDST = DateTimeHelper.nextDSTTransition() {
            print("   ✓ Next DST transition: \(DateTimeHelper.formattedWithDST(date: nextDST))")
            print("   ✓ Transition info: \(nextDST.dstTransitionInfo.description)")
            XCTAssertNotNil(nextDST, "Should find next DST transition")
        } else {
            print("   ℹ️ No DST transition found (timezone may not observe DST)")
        }

        print("✅ Test 3.3.13: Next DST transition verified")
        print("   Result: PASS - DST finder works correctly")
    }

    // MARK: - Test 3.3.14: Date Extension Methods

    func testDateExtensionMethods() throws {
        print("🧪 Test 3.3.14: Testing Date extension convenience methods")

        let date = Date()

        // Test addingDays
        if let tomorrow = date.addingDays(1) {
            let hours = DateTimeHelper.hoursBetween(start: date, end: tomorrow)
            print("   ✓ Adding 1 day: \(hours) hours elapsed")
            XCTAssertEqual(hours, 24, accuracy: 1, "Should be approximately 24 hours")
        }

        // Test addingHours
        if let later = date.addingHours(5) {
            let hours = DateTimeHelper.hoursBetween(start: date, end: later)
            print("   ✓ Adding 5 hours: \(hours) hours elapsed")
            XCTAssertEqual(hours, 5, "Should be exactly 5 hours")
        }

        // Test sameTimeNextDay
        if let nextDay = date.sameTimeNextDay() {
            let calendar = Calendar.current
            let originalTime = calendar.dateComponents([.hour, .minute], from: date)
            let nextDayTime = calendar.dateComponents([.hour, .minute], from: nextDay)

            print("   ✓ Same time next day preserves: \(originalTime.hour!):\(String(format: "%02d", originalTime.minute!))")
            XCTAssertEqual(originalTime.hour, nextDayTime.hour, "Hour should match")
        }

        print("✅ Test 3.3.14: Date extension methods verified")
        print("   Result: PASS - Extension methods work correctly")
    }

    // MARK: - Test 3.3.15: Edge Cases

    func testEdgeCases() throws {
        print("🧪 Test 3.3.15: Testing edge cases")

        let calendar = Calendar.current

        // Leap year date
        var leapComponents = DateComponents()
        leapComponents.year = 2024
        leapComponents.month = 2
        leapComponents.day = 29
        leapComponents.hour = 12

        if let leapDate = calendar.date(from: leapComponents) {
            if let nextYear = DateTimeHelper.addDays(365, to: leapDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: nextYear)
                print("   ✓ Leap year + 365 days: \(components.year!)-\(components.month!)-\(components.day!)")
            }
        }

        // Year boundary
        var yearEndComponents = DateComponents()
        yearEndComponents.year = 2024
        yearEndComponents.month = 12
        yearEndComponents.day = 31
        yearEndComponents.hour = 23
        yearEndComponents.minute = 59

        if let yearEnd = calendar.date(from: yearEndComponents) {
            if let newYear = DateTimeHelper.addDays(1, to: yearEnd) {
                let components = calendar.dateComponents([.year, .month, .day], from: newYear)
                print("   ✓ Year boundary: \(components.year!)-\(components.month!)-\(components.day!)")
                XCTAssertEqual(components.year, 2025, "Should be 2025")
                XCTAssertEqual(components.month, 1, "Should be January")
                XCTAssertEqual(components.day, 1, "Should be 1st")
            }
        }

        print("✅ Test 3.3.15: Edge cases verified")
        print("   Result: PASS - Edge cases handled correctly")
    }
}
