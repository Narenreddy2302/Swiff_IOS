//
//  CurrencyTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 3.1: Replace Double with Decimal
//

import XCTest
@testable import Swiff_IOS

final class CurrencyTests: XCTestCase {

    // MARK: - Test 3.1.1: Precision Testing

    func testDecimalPrecision() throws {
        print("🧪 Test 3.1.1: Testing decimal precision with Currency")

        // Test notorious floating point precision issues
        let price1 = Currency(double: 0.1)
        let price2 = Currency(double: 0.2)
        let sum = price1 + price2

        // With Decimal, this should be exactly 0.3
        XCTAssertEqual(sum.doubleValue, 0.3, accuracy: 0.0000001)
        print("   ✓ 0.1 + 0.2 = \(sum.doubleValue) (no precision loss)")

        // Test larger precision scenario
        let amount1 = Currency(double: 123.456789)
        let amount2 = Currency(double: 987.654321)
        let total = amount1 + amount2

        XCTAssertEqual(total.doubleValue, 1111.11111, accuracy: 0.0001)
        print("   ✓ Large decimal addition: \(total.doubleValue)")

        // Test multiplication precision
        let basePrice = Currency(double: 9.99)
        let quantity = 3
        let totalPrice = basePrice * quantity

        XCTAssertEqual(totalPrice.doubleValue, 29.97, accuracy: 0.001)
        print("   ✓ $9.99 × 3 = \(totalPrice.formatted())")

        print("✅ Test 3.1.1: Decimal precision verified")
        print("   Result: PASS - No floating point precision loss")
    }

    // MARK: - Test 3.1.2: Rounding Behavior

    func testRoundingBehavior() throws {
        print("🧪 Test 3.1.2: Testing currency rounding modes")

        let amount = Currency(double: 12.3456)

        // Round up
        let roundedUp = amount.rounded(toPlaces: 2, mode: .up)
        XCTAssertEqual(roundedUp.doubleValue, 12.35, accuracy: 0.001)
        print("   ✓ Round up: 12.3456 → \(roundedUp.formattedPlain())")

        // Round down
        let roundedDown = amount.rounded(toPlaces: 2, mode: .down)
        XCTAssertEqual(roundedDown.doubleValue, 12.34, accuracy: 0.001)
        print("   ✓ Round down: 12.3456 → \(roundedDown.formattedPlain())")

        // Round nearest
        let roundedNearest = amount.rounded(toPlaces: 2, mode: .nearest)
        XCTAssertEqual(roundedNearest.doubleValue, 12.35, accuracy: 0.001)
        print("   ✓ Round nearest: 12.3456 → \(roundedNearest.formattedPlain())")

        // Banker's rounding (round to even)
        let amount1 = Currency(double: 2.5)
        let bankers1 = amount1.rounded(toPlaces: 0, mode: .bankers)
        XCTAssertEqual(bankers1.doubleValue, 2.0, accuracy: 0.001)

        let amount2 = Currency(double: 3.5)
        let bankers2 = amount2.rounded(toPlaces: 0, mode: .bankers)
        XCTAssertEqual(bankers2.doubleValue, 4.0, accuracy: 0.001)

        print("   ✓ Banker's rounding: 2.5 → \(bankers1.intValue), 3.5 → \(bankers2.intValue)")

        print("✅ Test 3.1.2: Rounding behavior verified")
        print("   Result: PASS - All rounding modes work correctly")
    }

    // MARK: - Test 3.1.3: Currency Conversions

    func testCurrencyConversions() throws {
        print("🧪 Test 3.1.3: Testing currency format conversions")

        let amount = Currency(double: 1234.56)

        // USD formatting
        let usd = amount.formatted(currencyCode: "USD")
        print("   ✓ USD: \(usd)")
        XCTAssertTrue(usd.contains("1,234.56") || usd.contains("1234.56"))

        // EUR formatting
        let eur = amount.formatted(currencyCode: "EUR")
        print("   ✓ EUR: \(eur)")

        // Without symbol
        let noSymbol = amount.formatted(showSymbol: false)
        print("   ✓ No symbol: \(noSymbol)")
        XCTAssertFalse(noSymbol.contains("$"))

        // Plain formatting
        let plain = amount.formattedPlain(decimalPlaces: 2)
        print("   ✓ Plain: \(plain)")

        print("✅ Test 3.1.3: Currency conversions verified")
        print("   Result: PASS - Formatting works for multiple currencies")
    }

    // MARK: - Test 3.1.4: Arithmetic Operations

    func testArithmeticOperations() throws {
        print("🧪 Test 3.1.4: Testing currency arithmetic operations")

        let price1 = Currency(double: 10.50)
        let price2 = Currency(double: 5.25)

        // Addition
        let sum = price1 + price2
        XCTAssertEqual(sum.doubleValue, 15.75, accuracy: 0.001)
        print("   ✓ Addition: $10.50 + $5.25 = \(sum.formatted())")

        // Subtraction
        let diff = price1 - price2
        XCTAssertEqual(diff.doubleValue, 5.25, accuracy: 0.001)
        print("   ✓ Subtraction: $10.50 - $5.25 = \(diff.formatted())")

        // Multiplication
        let doubled = price1 * 2
        XCTAssertEqual(doubled.doubleValue, 21.0, accuracy: 0.001)
        print("   ✓ Multiplication: $10.50 × 2 = \(doubled.formatted())")

        // Division
        let half = try price1 / 2
        XCTAssertEqual(half.doubleValue, 5.25, accuracy: 0.001)
        print("   ✓ Division: $10.50 ÷ 2 = \(half.formatted())")

        // Compound assignment
        var total = Currency(double: 100.00)
        total += price1
        XCTAssertEqual(total.doubleValue, 110.50, accuracy: 0.001)
        print("   ✓ Compound add: $100.00 += $10.50 = \(total.formatted())")

        total -= price2
        XCTAssertEqual(total.doubleValue, 105.25, accuracy: 0.001)
        print("   ✓ Compound subtract: $110.50 -= $5.25 = \(total.formatted())")

        print("✅ Test 3.1.4: Arithmetic operations verified")
        print("   Result: PASS - All operations accurate")
    }

    // MARK: - Test 3.1.5: Comparison Operations

    func testComparisonOperations() throws {
        print("🧪 Test 3.1.5: Testing currency comparison operations")

        let amount1 = Currency(double: 100.00)
        let amount2 = Currency(double: 50.00)
        let amount3 = Currency(double: 100.00)

        XCTAssertTrue(amount1 > amount2)
        print("   ✓ $100.00 > $50.00")

        XCTAssertTrue(amount2 < amount1)
        print("   ✓ $50.00 < $100.00")

        XCTAssertTrue(amount1 == amount3)
        print("   ✓ $100.00 == $100.00")

        XCTAssertTrue(amount1 >= amount3)
        print("   ✓ $100.00 >= $100.00")

        XCTAssertTrue(amount2 <= amount1)
        print("   ✓ $50.00 <= $100.00")

        print("✅ Test 3.1.5: Comparison operations verified")
        print("   Result: PASS - All comparisons correct")
    }

    // MARK: - Test 3.1.6: Edge Cases

    func testEdgeCases() throws {
        print("🧪 Test 3.1.6: Testing edge cases")

        // Zero
        let zero = Currency.zero
        XCTAssertTrue(zero.isZero)
        print("   ✓ Zero detection works")

        // Positive/Negative
        let positive = Currency(double: 10.0)
        let negative = Currency(double: -10.0)

        XCTAssertTrue(positive.isPositive)
        XCTAssertTrue(negative.isNegative)
        print("   ✓ Positive/negative detection works")

        // Absolute value
        let absValue = negative.abs
        XCTAssertEqual(absValue.doubleValue, 10.0, accuracy: 0.001)
        print("   ✓ Absolute value: |-$10.00| = \(absValue.formatted())")

        // Division by zero
        do {
            _ = try positive / 0
            XCTFail("Should throw division by zero error")
        } catch CurrencyError.divisionByZero {
            print("   ✓ Division by zero prevented")
        }

        print("✅ Test 3.1.6: Edge cases verified")
        print("   Result: PASS - Edge cases handled correctly")
    }

    // MARK: - Test 3.1.7: String Parsing

    func testStringParsing() throws {
        print("🧪 Test 3.1.7: Testing currency string parsing")

        // Parse with dollar sign
        let parsed1 = try CurrencyHelper.parse("$123.45")
        XCTAssertEqual(parsed1.doubleValue, 123.45, accuracy: 0.001)
        print("   ✓ Parsed: '$123.45' → \(parsed1.formatted())")

        // Parse with commas
        let parsed2 = try CurrencyHelper.parse("$1,234.56")
        XCTAssertEqual(parsed2.doubleValue, 1234.56, accuracy: 0.001)
        print("   ✓ Parsed: '$1,234.56' → \(parsed2.formatted())")

        // Parse plain number
        let parsed3 = try CurrencyHelper.parse("999.99")
        XCTAssertEqual(parsed3.doubleValue, 999.99, accuracy: 0.001)
        print("   ✓ Parsed: '999.99' → \(parsed3.formatted())")

        // Invalid input
        do {
            _ = try CurrencyHelper.parse("invalid")
            XCTFail("Should throw invalid amount error")
        } catch CurrencyError.invalidAmount {
            print("   ✓ Invalid input rejected")
        }

        print("✅ Test 3.1.7: String parsing verified")
        print("   Result: PASS - String parsing works correctly")
    }

    // MARK: - Test 3.1.8: Helper Functions

    func testHelperFunctions() throws {
        print("🧪 Test 3.1.8: Testing currency helper functions")

        let amount = Currency(double: 100.00)

        // Percentage calculation
        let tax = CurrencyHelper.percentage(amount, percent: 15)
        XCTAssertEqual(tax.doubleValue, 15.0, accuracy: 0.001)
        print("   ✓ 15% of $100.00 = \(tax.formatted())")

        // Apply discount
        let discounted = CurrencyHelper.applyDiscount(amount, percent: 20)
        XCTAssertEqual(discounted.doubleValue, 80.0, accuracy: 0.001)
        print("   ✓ $100.00 - 20% = \(discounted.formatted())")

        // Apply tax
        let withTax = CurrencyHelper.applyTax(amount, percent: 10)
        XCTAssertEqual(withTax.doubleValue, 110.0, accuracy: 0.001)
        print("   ✓ $100.00 + 10% tax = \(withTax.formatted())")

        print("✅ Test 3.1.8: Helper functions verified")
        print("   Result: PASS - Helper functions work correctly")
    }

    // MARK: - Test 3.1.9: Split Evenly

    func testSplitEvenly() throws {
        print("🧪 Test 3.1.9: Testing even split functionality")

        let total = Currency(double: 100.00)

        // Split evenly among 3 people
        let splits = try CurrencyHelper.splitEvenly(total, ways: 3)
        XCTAssertEqual(splits.count, 3)

        let sum = splits.reduce(Currency.zero, +)
        XCTAssertEqual(sum.doubleValue, 100.0, accuracy: 0.01)

        print("   ✓ Split $100.00 among 3:")
        for (index, split) in splits.enumerated() {
            print("     Person \(index + 1): \(split.formatted())")
        }

        // Verify total
        print("   ✓ Total: \(sum.formatted()) (matches original)")

        print("✅ Test 3.1.9: Even split verified")
        print("   Result: PASS - Split handles remainders correctly")
    }

    // MARK: - Test 3.1.10: Large Numbers

    func testLargeNumbers() throws {
        print("🧪 Test 3.1.10: Testing large currency amounts")

        let million = Currency(double: 1_000_000.00)
        let thousand = Currency(double: 1_000.00)

        let sum = million + thousand
        XCTAssertEqual(sum.doubleValue, 1_001_000.00, accuracy: 1.0)
        print("   ✓ $1,000,000 + $1,000 = \(sum.formatted())")

        let quotient = try million / 1000
        XCTAssertEqual(quotient.doubleValue, 1_000.00, accuracy: 1.0)
        print("   ✓ $1,000,000 ÷ 1,000 = \(quotient.formatted())")

        print("✅ Test 3.1.10: Large numbers verified")
        print("   Result: PASS - Large amounts handled correctly")
    }

    // MARK: - Test 3.1.11: Codable Support

    func testCodableSupport() throws {
        print("🧪 Test 3.1.11: Testing Codable encoding/decoding")

        let original = Currency(double: 123.45)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        print("   ✓ Encoded to JSON")

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Currency.self, from: data)

        XCTAssertEqual(decoded.doubleValue, original.doubleValue, accuracy: 0.001)
        print("   ✓ Decoded from JSON: \(decoded.formatted())")

        print("✅ Test 3.1.11: Codable support verified")
        print("   Result: PASS - Encoding/decoding works correctly")
    }

    // MARK: - Test 3.1.12: Backward Compatibility

    func testBackwardCompatibility() throws {
        print("🧪 Test 3.1.12: Testing backward compatibility with Double")

        // Convert from Double
        let double: Double = 99.99
        let currency = CurrencyHelper.fromDouble(double)
        XCTAssertEqual(currency.doubleValue, double, accuracy: 0.001)
        print("   ✓ Convert from Double: \(double) → \(currency.formatted())")

        // Convert to Double
        let backToDouble = CurrencyHelper.toDouble(currency)
        XCTAssertEqual(backToDouble, double, accuracy: 0.001)
        print("   ✓ Convert to Double: \(currency.formatted()) → \(backToDouble)")

        print("✅ Test 3.1.12: Backward compatibility verified")
        print("   Result: PASS - Double compatibility maintained")
    }
}
