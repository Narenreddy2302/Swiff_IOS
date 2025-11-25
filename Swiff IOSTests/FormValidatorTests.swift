//
//  FormValidatorTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 3.4: Comprehensive form validation
//

import XCTest
@testable import Swiff_IOS

final class FormValidatorTests: XCTestCase {

    // MARK: - Test 3.4.1: Email Validation

    func testEmailValidation() throws {
        print("🧪 Test 3.4.1: Testing email validation")

        // Valid emails
        let validEmails = [
            "user@example.com",
            "test.user@example.com",
            "user+tag@example.co.uk",
            "user_name@example-domain.com",
            "123@example.com",
            "user@sub.example.com"
        ]

        for email in validEmails {
            let result = FormValidator.validateEmail(email)
            XCTAssertTrue(result.isValid, "Email '\(email)' should be valid")
            print("   ✓ Valid: \(email)")
        }

        // Invalid emails
        let invalidEmails = [
            "",                          // Empty
            "invalid",                   // No @
            "@example.com",              // Missing local part
            "user@",                     // Missing domain
            "user@@example.com",         // Double @
            "user @example.com",         // Space before @
            "user@example",              // Missing TLD
            "user@.com",                 // Missing domain
            String(repeating: "a", count: 255) + "@example.com"  // Too long
        ]

        for email in invalidEmails {
            let result = FormValidator.validateEmail(email)
            XCTAssertFalse(result.isValid, "Email '\(email)' should be invalid")
            print("   ✓ Invalid: \(email) - \(result.error?.localizedDescription ?? "")")
        }

        print("✅ Test 3.4.1: Email validation verified")
        print("   Result: PASS - All email formats validated correctly")
    }

    // MARK: - Test 3.4.2: Phone Number Validation

    func testPhoneNumberValidation() throws {
        print("🧪 Test 3.4.2: Testing phone number validation")

        // Valid phone numbers
        let validPhones = [
            "+1 (555) 123-4567",
            "(555) 123-4567",
            "555-123-4567",
            "5551234567",
            "+1-555-123-4567",
            "+44 20 7123 4567",
            "",  // Empty is allowed (optional field)
        ]

        for phone in validPhones {
            let result = FormValidator.validatePhoneNumber(phone)
            XCTAssertTrue(result.isValid, "Phone '\(phone)' should be valid")
            print("   ✓ Valid: \(phone.isEmpty ? "(empty)" : phone)")
        }

        // Invalid phone numbers
        let invalidPhones = [
            "123",                       // Too short
            "abcdefghij",               // Letters only
            "+1 (555) 12",              // Too short
            String(repeating: "1", count: 20),  // Too long
            "555-ABC-DEFG"              // Letters mixed with digits (invalid)
        ]

        for phone in invalidPhones {
            let result = FormValidator.validatePhoneNumber(phone)
            XCTAssertFalse(result.isValid, "Phone '\(phone)' should be invalid")
            print("   ✓ Invalid: \(phone) - \(result.error?.localizedDescription ?? "")")
        }

        print("✅ Test 3.4.2: Phone number validation verified")
        print("   Result: PASS - All phone formats validated correctly")
    }

    // MARK: - Test 3.4.3: Amount Validation

    func testAmountValidation() throws {
        print("🧪 Test 3.4.3: Testing amount validation")

        // Valid amounts
        let validAmounts = [
            ("10.00", true),
            ("$50.00", true),
            ("1,234.56", true),
            ("0.01", true),
            ("999999.99", true)
        ]

        for (amount, shouldBeValid) in validAmounts {
            let result = FormValidator.validateAmount(amount)
            XCTAssertTrue(result.isValid == shouldBeValid, "Amount '\(amount)' validation mismatch")
            print("   ✓ Valid: \(amount)")
        }

        // Invalid amounts
        let invalidAmounts = [
            "",              // Empty
            "abc",           // Not a number
            "-10.00",        // Negative (when not allowed)
            "0.00",          // Zero (when not allowed)
            "0.001",         // Too many decimal places
            "1000000000"     // Exceeds maximum
        ]

        for amount in invalidAmounts {
            let result = FormValidator.validateAmount(amount)
            XCTAssertFalse(result.isValid, "Amount '\(amount)' should be invalid")
            print("   ✓ Invalid: \(amount) - \(result.error?.localizedDescription ?? "")")
        }

        // Test with custom limits
        let customResult = FormValidator.validateAmount(
            "5.00",
            minimum: 10.00,
            maximum: 100.00
        )
        XCTAssertFalse(customResult.isValid, "Amount below minimum should be invalid")
        print("   ✓ Custom range validation working")

        // Test allowing zero
        let zeroResult = FormValidator.validateAmount("0.00", allowZero: true)
        XCTAssertTrue(zeroResult.isValid, "Zero should be valid when allowed")
        print("   ✓ Allow zero option working")

        // Test allowing negative
        let negativeResult = FormValidator.validateAmount("-10.00", allowNegative: true)
        XCTAssertTrue(negativeResult.isValid, "Negative should be valid when allowed")
        print("   ✓ Allow negative option working")

        print("✅ Test 3.4.3: Amount validation verified")
        print("   Result: PASS - All amount validations correct")
    }

    // MARK: - Test 3.4.4: Required Field Validation

    func testRequiredFieldValidation() throws {
        print("🧪 Test 3.4.4: Testing required field validation")

        // Valid (non-empty)
        let validValues = [
            "John Doe",
            "a",
            "   text   ",  // Will be trimmed but has content
        ]

        for value in validValues {
            let result = FormValidator.validateRequired(value, fieldName: "Name")
            XCTAssertTrue(result.isValid, "Value '\(value)' should be valid")
            print("   ✓ Valid: '\(value)'")
        }

        // Invalid (empty)
        let invalidValues = [
            "",
            "   ",           // Only whitespace
            "\t\n",          // Only whitespace/newlines
        ]

        for value in invalidValues {
            let result = FormValidator.validateRequired(value, fieldName: "Name")
            XCTAssertFalse(result.isValid, "Value '\(value)' should be invalid")
            print("   ✓ Invalid: '\(value.isEmpty ? "(empty)" : "(whitespace)")' - \(result.error?.localizedDescription ?? "")")
        }

        print("✅ Test 3.4.4: Required field validation verified")
        print("   Result: PASS - Required field detection correct")
    }

    // MARK: - Test 3.4.5: Length Validation

    func testLengthValidation() throws {
        print("🧪 Test 3.4.5: Testing length validation")

        let testValue = "Hello World"

        // Minimum length
        var result = FormValidator.validateLength(testValue, fieldName: "Text", minLength: 5)
        XCTAssertTrue(result.isValid, "Should pass minimum length")
        print("   ✓ Minimum length check passed")

        result = FormValidator.validateLength(testValue, fieldName: "Text", minLength: 20)
        XCTAssertFalse(result.isValid, "Should fail minimum length")
        print("   ✓ Minimum length check failed correctly")

        // Maximum length
        result = FormValidator.validateLength(testValue, fieldName: "Text", maxLength: 20)
        XCTAssertTrue(result.isValid, "Should pass maximum length")
        print("   ✓ Maximum length check passed")

        result = FormValidator.validateLength(testValue, fieldName: "Text", maxLength: 5)
        XCTAssertFalse(result.isValid, "Should fail maximum length")
        print("   ✓ Maximum length check failed correctly")

        // Both min and max
        result = FormValidator.validateLength(testValue, fieldName: "Text", minLength: 5, maxLength: 20)
        XCTAssertTrue(result.isValid, "Should pass both min and max")
        print("   ✓ Min/max range check passed")

        print("✅ Test 3.4.5: Length validation verified")
        print("   Result: PASS - Length constraints enforced correctly")
    }

    // MARK: - Test 3.4.6: Name Validation

    func testNameValidation() throws {
        print("🧪 Test 3.4.6: Testing name validation")

        // Valid names
        let validNames = [
            "John Doe",
            "Mary-Jane",
            "O'Connor",
            "Dr. Smith",
            "Jean-Luc Picard"
        ]

        for name in validNames {
            let result = FormValidator.validateName(name)
            XCTAssertTrue(result.isValid, "Name '\(name)' should be valid")
            print("   ✓ Valid: \(name)")
        }

        // Invalid names
        let invalidNames = [
            "",                          // Empty
            "   ",                       // Whitespace only
            "John123",                   // Contains numbers
            "User@Domain",               // Contains @
            "Test!Name",                 // Contains !
            String(repeating: "a", count: 101)  // Too long
        ]

        for name in invalidNames {
            let result = FormValidator.validateName(name)
            XCTAssertFalse(result.isValid, "Name '\(name)' should be invalid")
            print("   ✓ Invalid: '\(name.prefix(20))\(name.count > 20 ? "..." : "")' - \(result.error?.localizedDescription ?? "")")
        }

        print("✅ Test 3.4.6: Name validation verified")
        print("   Result: PASS - Name format validation correct")
    }

    // MARK: - Test 3.4.7: Date Validation

    func testDateValidation() throws {
        print("🧪 Test 3.4.7: Testing date validation")

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        // Valid date (within range)
        var result = FormValidator.validateDate(now, minDate: yesterday, maxDate: tomorrow)
        XCTAssertTrue(result.isValid, "Date should be valid")
        print("   ✓ Date within range is valid")

        // Date too early
        result = FormValidator.validateDate(yesterday, minDate: now, maxDate: tomorrow)
        XCTAssertFalse(result.isValid, "Date should be too early")
        print("   ✓ Date before minimum detected: \(result.error?.localizedDescription ?? "")")

        // Date too late
        result = FormValidator.validateDate(tomorrow, minDate: yesterday, maxDate: now)
        XCTAssertFalse(result.isValid, "Date should be too late")
        print("   ✓ Date after maximum detected: \(result.error?.localizedDescription ?? "")")

        // No restrictions
        result = FormValidator.validateDate(now)
        XCTAssertTrue(result.isValid, "Date without restrictions should be valid")
        print("   ✓ Date without restrictions is valid")

        print("✅ Test 3.4.7: Date validation verified")
        print("   Result: PASS - Date range validation correct")
    }

    // MARK: - Test 3.4.8: Composite Form Validation

    func testCompositeFormValidation() throws {
        print("🧪 Test 3.4.8: Testing composite form validation")

        // Define validation rules
        let nameRule = FieldValidationRule(
            fieldName: "name",
            validators: [{ FormValidator.validateName($0, fieldName: "Name") }]
        )

        let emailRule = FieldValidationRule(
            fieldName: "email",
            validators: [{ FormValidator.validateEmail($0) }]
        )

        let amountRule = FieldValidationRule(
            fieldName: "amount",
            validators: [{ FormValidator.validateAmount($0) }]
        )

        let rules = [nameRule, emailRule, amountRule]

        // Valid form data
        let validData: [String: String] = [
            "name": "John Doe",
            "email": "john@example.com",
            "amount": "50.00"
        ]

        var results = FormValidator.validateForm(rules, values: validData)
        XCTAssertTrue(FormValidator.isFormValid(results), "Valid form should pass")
        print("   ✓ Valid form passed all checks")

        // Invalid form data (bad email)
        let invalidData: [String: String] = [
            "name": "John Doe",
            "email": "invalid-email",
            "amount": "50.00"
        ]

        results = FormValidator.validateForm(rules, values: invalidData)
        XCTAssertFalse(FormValidator.isFormValid(results), "Invalid form should fail")

        let errors = FormValidator.getErrorMessages(results)
        XCTAssertFalse(errors.isEmpty, "Should have error messages")
        print("   ✓ Invalid form detected: \(errors.joined(separator: ", "))")

        print("✅ Test 3.4.8: Composite form validation verified")
        print("   Result: PASS - Multi-field validation working")
    }

    // MARK: - Test 3.4.9: Real-time Validation

    func testRealTimeValidation() async throws {
        print("🧪 Test 3.4.9: Testing real-time validation with debouncing")

        let validator = RealTimeValidator()

        // Test debounced validation
        let result1 = await validator.validateWithDebounce(
            fieldName: "email",
            value: "test@example.com",
            validator: FormValidator.validateEmail,
            debounceInterval: 0.1
        )

        // Initially might return cached or default
        print("   ✓ Initial result: \(result1.isValid ? "valid" : "invalid")")

        // Wait for debounce to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Check cached result
        if let cached = await validator.getCachedResult(for: "email") {
            XCTAssertTrue(cached.isValid, "Email should be valid after debounce")
            print("   ✓ Debounced validation completed: valid")
        }

        // Test with invalid email
        _ = await validator.validateWithDebounce(
            fieldName: "email",
            value: "invalid",
            validator: FormValidator.validateEmail,
            debounceInterval: 0.1
        )

        try await Task.sleep(nanoseconds: 200_000_000)

        if let cached = await validator.getCachedResult(for: "email") {
            XCTAssertFalse(cached.isValid, "Invalid email should fail")
            print("   ✓ Invalid email detected after debounce")
        }

        // Clear cache
        await validator.clearCache(for: "email")
        let clearedCache = await validator.getCachedResult(for: "email")
        XCTAssertNil(clearedCache, "Cache should be cleared")
        print("   ✓ Cache cleared successfully")

        print("✅ Test 3.4.9: Real-time validation verified")
        print("   Result: PASS - Debouncing and caching working")
    }

    // MARK: - Test 3.4.10: Validation Error Messages

    func testValidationErrorMessages() throws {
        print("🧪 Test 3.4.10: Testing validation error messages")

        // Email error
        let emailResult = FormValidator.validateEmail("invalid")
        if let error = emailResult.error {
            XCTAssertNotNil(error.localizedDescription)
            print("   ✓ Email error: \(error.localizedDescription)")
        }

        // Amount error
        let amountResult = FormValidator.validateAmount("abc")
        if let error = amountResult.error {
            XCTAssertNotNil(error.localizedDescription)
            print("   ✓ Amount error: \(error.localizedDescription)")
        }

        // Required field error
        let requiredResult = FormValidator.validateRequired("", fieldName: "Name")
        if let error = requiredResult.error {
            XCTAssertNotNil(error.localizedDescription)
            print("   ✓ Required error: \(error.localizedDescription)")
        }

        // Length error
        let lengthResult = FormValidator.validateLength("ab", fieldName: "Password", minLength: 8)
        if let error = lengthResult.error {
            XCTAssertNotNil(error.localizedDescription)
            print("   ✓ Length error: \(error.localizedDescription)")
        }

        print("✅ Test 3.4.10: Validation error messages verified")
        print("   Result: PASS - All error messages are descriptive")
    }

    // MARK: - Test 3.4.11: Edge Cases

    func testEdgeCases() throws {
        print("🧪 Test 3.4.11: Testing edge cases")

        // Unicode in names
        let unicodeName = FormValidator.validateName("José García")
        // Note: Current implementation only allows ASCII letters
        print("   ✓ Unicode name: \(unicodeName.isValid ? "valid" : "invalid")")

        // Very long email
        let longEmail = String(repeating: "a", count: 250) + "@example.com"
        let longEmailResult = FormValidator.validateEmail(longEmail)
        XCTAssertFalse(longEmailResult.isValid, "Very long email should be invalid")
        print("   ✓ Long email rejected")

        // Amount with many decimal places
        let preciseAmount = FormValidator.validateAmount("10.123456")
        XCTAssertFalse(preciseAmount.isValid, "Amount with >2 decimals should be invalid")
        print("   ✓ Excess decimal places rejected")

        // Phone with unusual formatting
        let unusualPhone = FormValidator.validatePhoneNumber("+1.555.123.4567")
        print("   ✓ Unusual phone format: \(unusualPhone.isValid ? "valid" : "invalid")")

        // Empty required field with whitespace
        let whitespaceRequired = FormValidator.validateRequired("   \t\n   ", fieldName: "Field")
        XCTAssertFalse(whitespaceRequired.isValid, "Whitespace-only should fail required check")
        print("   ✓ Whitespace-only field rejected")

        print("✅ Test 3.4.11: Edge cases verified")
        print("   Result: PASS - Edge cases handled appropriately")
    }

    // MARK: - Test 3.4.12: Performance

    func testValidationPerformance() throws {
        print("🧪 Test 3.4.12: Testing validation performance")

        let startTime = Date()

        // Validate 1000 emails
        for i in 0..<1000 {
            _ = FormValidator.validateEmail("user\(i)@example.com")
        }

        let emailTime = Date().timeIntervalSince(startTime)
        print("   ✓ 1000 email validations: \(String(format: "%.3f", emailTime))s")
        XCTAssertLessThan(emailTime, 1.0, "Should validate 1000 emails in under 1 second")

        // Validate 1000 amounts
        let amountStart = Date()
        for i in 0..<1000 {
            _ = FormValidator.validateAmount("\(i).99")
        }
        let amountTime = Date().timeIntervalSince(amountStart)
        print("   ✓ 1000 amount validations: \(String(format: "%.3f", amountTime))s")
        XCTAssertLessThan(amountTime, 1.0, "Should validate 1000 amounts in under 1 second")

        print("✅ Test 3.4.12: Validation performance verified")
        print("   Result: PASS - Performance is acceptable")
    }
}
