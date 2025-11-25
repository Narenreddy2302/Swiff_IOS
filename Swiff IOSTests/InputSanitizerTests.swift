//
//  InputSanitizerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for Phase 3.6: Input sanitization
//

import XCTest
@testable import Swiff_IOS

final class InputSanitizerTests: XCTestCase {

    // MARK: - Test 3.6.1: Whitespace Sanitization

    func testWhitespaceSanitization() throws {
        print("🧪 Test 3.6.1: Testing whitespace sanitization")

        // Trim whitespace
        let input1 = "  Hello World  "
        let trimmed = InputSanitizer.trimWhitespace(input1)
        XCTAssertEqual(trimmed, "Hello World", "Whitespace should be trimmed")
        print("   ✓ Trimmed: '\(input1)' → '\(trimmed)'")

        // Normalize whitespace
        let input2 = "Hello    World   Test"
        let normalized = InputSanitizer.normalizeWhitespace(input2)
        XCTAssertEqual(normalized, "Hello World Test", "Multiple spaces should collapse")
        print("   ✓ Normalized: '\(input2)' → '\(normalized)'")

        // Remove all whitespace
        let input3 = "Hello World Test"
        let removed = InputSanitizer.removeWhitespace(input3)
        XCTAssertEqual(removed, "HelloWorldTest", "All spaces should be removed")
        print("   ✓ Removed: '\(input3)' → '\(removed)'")

        // Extension method
        let input4 = "  Test  "
        XCTAssertEqual(input4.trimmed, "Test", "Extension method should work")
        print("   ✓ Extension method working")

        print("✅ Test 3.6.1: Whitespace sanitization verified")
        print("   Result: PASS - Whitespace handling correct")
    }

    // MARK: - Test 3.6.2: Special Character Removal

    func testSpecialCharacterRemoval() throws {
        print("🧪 Test 3.6.2: Testing special character removal")

        // Remove special characters (keep alphanumeric only)
        let input1 = "Hello@World!123"
        let sanitized1 = InputSanitizer.removeSpecialCharacters(input1)
        XCTAssertEqual(sanitized1, "HelloWorld123", "Special chars should be removed")
        print("   ✓ Basic removal: '\(input1)' → '\(sanitized1)'")

        // Allow specific characters
        let input2 = "John-Doe@example.com"
        let sanitized2 = InputSanitizer.removeSpecialCharacters(input2, allowedCharacters: "-@.")
        XCTAssertTrue(sanitized2.contains("-") && sanitized2.contains("@"), "Allowed chars should remain")
        print("   ✓ With allowed chars: '\(input2)' → '\(sanitized2)'")

        // Remove dangerous characters
        let input3 = "Hello\0World\u{001F}Test"
        let sanitized3 = InputSanitizer.removeDangerousCharacters(input3)
        XCTAssertFalse(sanitized3.contains("\0"), "Null bytes should be removed")
        print("   ✓ Dangerous chars removed: '\(input3.debugDescription)' → '\(sanitized3)'")

        print("✅ Test 3.6.2: Special character removal verified")
        print("   Result: PASS - Special characters handled correctly")
    }

    // MARK: - Test 3.6.3: HTML Sanitization

    func testHTMLSanitization() throws {
        print("🧪 Test 3.6.3: Testing HTML sanitization")

        // Escape HTML
        let input1 = "<script>alert('XSS')</script>"
        let escaped = InputSanitizer.escapeHTML(input1)
        XCTAssertFalse(escaped.contains("<"), "HTML should be escaped")
        XCTAssertTrue(escaped.contains("&lt;"), "Should use HTML entities")
        print("   ✓ HTML escaped: '\(input1)' → '\(escaped)'")

        // Strip HTML tags
        let input2 = "<p>Hello <b>World</b></p>"
        let stripped = InputSanitizer.stripHTMLTags(input2)
        XCTAssertEqual(stripped, "Hello World", "HTML tags should be removed")
        print("   ✓ HTML stripped: '\(input2)' → '\(stripped)'")

        // Extension method
        let html = "<div>Test</div>"
        XCTAssertTrue(html.htmlEscaped.contains("&lt;"), "Extension should work")
        print("   ✓ Extension method working")

        print("✅ Test 3.6.3: HTML sanitization verified")
        print("   Result: PASS - HTML handling correct")
    }

    // MARK: - Test 3.6.4: SQL Injection Detection

    func testSQLInjectionDetection() throws {
        print("🧪 Test 3.6.4: Testing SQL injection detection")

        // Detect SQL injection attempts
        let maliciousInputs = [
            "' OR '1'='1",
            "'; DROP TABLE users; --",
            "admin'--",
            "1' UNION SELECT * FROM users--"
        ]

        for input in maliciousInputs {
            let detected = InputSanitizer.containsSQLInjection(input)
            XCTAssertTrue(detected, "SQL injection should be detected in: \(input)")
            print("   ✓ Detected SQL injection: '\(input)'")
        }

        // Safe inputs
        let safeInputs = [
            "John Doe",
            "user@example.com",
            "Safe input 123"
        ]

        for input in safeInputs {
            let detected = InputSanitizer.containsSQLInjection(input)
            XCTAssertFalse(detected, "Safe input should not be flagged: \(input)")
            print("   ✓ Safe input accepted: '\(input)'")
        }

        // SQL escaping
        let input = "O'Reilly"
        let escaped = InputSanitizer.escapeSQLString(input)
        XCTAssertEqual(escaped, "O''Reilly", "Single quotes should be escaped")
        print("   ✓ SQL escaped: '\(input)' → '\(escaped)'")

        // Extension method
        let malicious = "' OR 1=1--"
        XCTAssertTrue(malicious.hasSQLInjection, "Extension should detect SQL injection")
        print("   ✓ Extension method working")

        print("✅ Test 3.6.4: SQL injection detection verified")
        print("   Result: PASS - SQL injection detection working")
    }

    // MARK: - Test 3.6.5: Path Validation

    func testPathValidation() throws {
        print("🧪 Test 3.6.5: Testing path validation")

        // Valid path
        let validPath = "documents/invoice.pdf"
        do {
            let validated = try InputSanitizer.validateFilePath(validPath)
            XCTAssertEqual(validated, validPath, "Valid path should pass")
            print("   ✓ Valid path accepted: '\(validPath)'")
        } catch {
            XCTFail("Valid path should not throw: \(error)")
        }

        // Path traversal attempts
        let traversalAttempts = [
            "../../../etc/passwd",
            "docs/../../../etc/passwd",
            "..\\..\\windows\\system32"
        ]

        for attempt in traversalAttempts {
            do {
                _ = try InputSanitizer.validateFilePath(attempt)
                XCTFail("Path traversal should be detected: \(attempt)")
            } catch SanitizationError.pathTraversal {
                print("   ✓ Path traversal blocked: '\(attempt)'")
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Absolute path (not allowed)
        do {
            _ = try InputSanitizer.validateFilePath("/etc/passwd")
            XCTFail("Absolute path should be rejected")
        } catch SanitizationError.pathTraversal {
            print("   ✓ Absolute path rejected")
        }

        print("✅ Test 3.6.5: Path validation verified")
        print("   Result: PASS - Path traversal prevented")
    }

    // MARK: - Test 3.6.6: Filename Sanitization

    func testFilenameSanitization() throws {
        print("🧪 Test 3.6.6: Testing filename sanitization")

        // Dangerous filename
        let input1 = "../../etc/passwd"
        let safe1 = InputSanitizer.sanitizeFilename(input1)
        XCTAssertFalse(safe1.contains("/"), "Path separators should be removed")
        XCTAssertFalse(safe1.contains(".."), "Parent directory refs should be removed")
        print("   ✓ Dangerous filename sanitized: '\(input1)' → '\(safe1)'")

        // Special characters
        let input2 = "file<name>.txt"
        let safe2 = InputSanitizer.sanitizeFilename(input2)
        XCTAssertFalse(safe2.contains("<"), "Special chars should be removed")
        print("   ✓ Special chars removed: '\(input2)' → '\(safe2)'")

        // Hidden file
        let input3 = "...hidden"
        let safe3 = InputSanitizer.sanitizeFilename(input3)
        XCTAssertFalse(safe3.hasPrefix("."), "Leading dots should be removed")
        print("   ✓ Hidden file sanitized: '\(input3)' → '\(safe3)'")

        // Empty filename
        let input4 = "../../../"
        let safe4 = InputSanitizer.sanitizeFilename(input4)
        XCTAssertEqual(safe4, "untitled", "Empty filename should get default")
        print("   ✓ Empty filename handled: '\(input4)' → '\(safe4)'")

        // Very long filename
        let longName = String(repeating: "a", count: 300)
        let safe5 = InputSanitizer.sanitizeFilename(longName)
        XCTAssertLessThanOrEqual(safe5.count, 255, "Filename should be truncated")
        print("   ✓ Long filename truncated: \(longName.count) → \(safe5.count)")

        print("✅ Test 3.6.6: Filename sanitization verified")
        print("   Result: PASS - Filenames sanitized correctly")
    }

    // MARK: - Test 3.6.7: XSS Detection

    func testXSSDetection() throws {
        print("🧪 Test 3.6.7: Testing XSS detection")

        // XSS attempts
        let xssAttempts = [
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "javascript:alert('XSS')",
            "<iframe src='javascript:alert(1)'>",
            "<body onload=alert('XSS')>"
        ]

        for attempt in xssAttempts {
            let detected = InputSanitizer.containsXSS(attempt)
            XCTAssertTrue(detected, "XSS should be detected in: \(attempt)")
            print("   ✓ XSS detected: '\(attempt)'")
        }

        // Safe content
        let safeContent = [
            "Hello World",
            "user@example.com",
            "Price: $99.99"
        ]

        for content in safeContent {
            let detected = InputSanitizer.containsXSS(content)
            XCTAssertFalse(detected, "Safe content should not be flagged: \(content)")
            print("   ✓ Safe content accepted: '\(content)'")
        }

        // Extension method
        let xss = "<script>alert(1)</script>"
        XCTAssertTrue(xss.hasXSS, "Extension should detect XSS")
        print("   ✓ Extension method working")

        print("✅ Test 3.6.7: XSS detection verified")
        print("   Result: PASS - XSS detection working")
    }

    // MARK: - Test 3.6.8: User Content Sanitization

    func testUserContentSanitization() throws {
        print("🧪 Test 3.6.8: Testing user content sanitization")

        // Malicious content
        let input1 = "<script>alert('XSS')</script>User comment"
        let safe1 = InputSanitizer.sanitizeUserContent(input1)
        XCTAssertFalse(safe1.contains("<script>"), "Script tags should be escaped")
        print("   ✓ Malicious content sanitized: '\(input1)' → '\(safe1)'")

        // Control characters
        let input2 = "Hello\0World\u{001F}Test"
        let safe2 = InputSanitizer.sanitizeUserContent(input2)
        XCTAssertFalse(safe2.contains("\0"), "Control chars should be removed")
        print("   ✓ Control chars removed")

        // Extension method
        let content = "<b>Test</b>"
        XCTAssertTrue(content.sanitizedContent.contains("&lt;"), "Extension should work")
        print("   ✓ Extension method working")

        print("✅ Test 3.6.8: User content sanitization verified")
        print("   Result: PASS - User content sanitized correctly")
    }

    // MARK: - Test 3.6.9: Length Validation

    func testLengthValidation() throws {
        print("🧪 Test 3.6.9: Testing length validation")

        // Within limit
        let input1 = "Hello"
        let result1 = try InputSanitizer.validateLength(input1, maxLength: 10)
        XCTAssertEqual(result1, input1, "Should pass when within limit")
        print("   ✓ Within limit: '\(input1)' (length: \(input1.count))")

        // Exactly at limit
        let input2 = "HelloWorld"
        let result2 = try InputSanitizer.validateLength(input2, maxLength: 10)
        XCTAssertEqual(result2, input2, "Should pass when at limit")
        print("   ✓ At limit: '\(input2)' (length: \(input2.count))")

        // Over limit (truncate)
        let input3 = "HelloWorldTest"
        let result3 = try InputSanitizer.validateLength(input3, maxLength: 10, truncate: true)
        XCTAssertEqual(result3.count, 10, "Should truncate to max length")
        print("   ✓ Truncated: '\(input3)' → '\(result3)' (from \(input3.count) to \(result3.count))")

        // Over limit (throw error)
        do {
            _ = try InputSanitizer.validateLength(input3, maxLength: 10, truncate: false)
            XCTFail("Should throw error when over limit")
        } catch SanitizationError.excessiveLength(let length) {
            XCTAssertEqual(length, input3.count, "Error should report correct length")
            print("   ✓ Error thrown for excessive length: \(length)")
        }

        print("✅ Test 3.6.9: Length validation verified")
        print("   Result: PASS - Length validation working correctly")
    }

    // MARK: - Test 3.6.10: Numeric Extraction

    func testNumericExtraction() throws {
        print("🧪 Test 3.6.10: Testing numeric extraction")

        // Extract digits
        let input1 = "Phone: (555) 123-4567"
        let digits = InputSanitizer.extractDigits(input1)
        XCTAssertEqual(digits, "5551234567", "Only digits should remain")
        print("   ✓ Digits extracted: '\(input1)' → '\(digits)'")

        // Extract alphanumeric
        let input2 = "User-ID: ABC123!@#"
        let alphanum = InputSanitizer.extractAlphanumeric(input2)
        XCTAssertEqual(alphanum, "UserIDABC123", "Only alphanumeric should remain")
        print("   ✓ Alphanumeric extracted: '\(input2)' → '\(alphanum)'")

        print("✅ Test 3.6.10: Numeric extraction verified")
        print("   Result: PASS - Extraction working correctly")
    }

    // MARK: - Test 3.6.11: Email and Phone Sanitization

    func testEmailAndPhoneSanitization() throws {
        print("🧪 Test 3.6.11: Testing email and phone sanitization")

        // Email sanitization
        let email1 = "  USER@EXAMPLE.COM  "
        let sanitizedEmail = InputSanitizer.sanitizeEmail(email1)
        XCTAssertEqual(sanitizedEmail, "user@example.com", "Email should be lowercased and trimmed")
        print("   ✓ Email sanitized: '\(email1)' → '\(sanitizedEmail)'")

        // Phone sanitization
        let phone1 = "  +1 (555) 123-4567  "
        let sanitizedPhone = InputSanitizer.sanitizePhoneNumber(phone1)
        XCTAssertFalse(sanitizedPhone.hasPrefix(" "), "Phone should be trimmed")
        print("   ✓ Phone sanitized: '\(phone1)' → '\(sanitizedPhone)'")

        // Extension methods
        let email2 = " Test@Example.Com "
        XCTAssertEqual(email2.sanitizedEmail, "test@example.com", "Extension should work")
        print("   ✓ Email extension working")

        let phone2 = " 555-123-4567 "
        XCTAssertEqual(phone2.sanitizedPhone, "555-123-4567", "Extension should work")
        print("   ✓ Phone extension working")

        print("✅ Test 3.6.11: Email and phone sanitization verified")
        print("   Result: PASS - Email/phone sanitization correct")
    }

    // MARK: - Test 3.6.12: URL Validation

    func testURLValidation() throws {
        print("🧪 Test 3.6.12: Testing URL validation")

        // Safe URLs
        let safeURLs = [
            "https://example.com",
            "http://example.com/path",
            "https://sub.example.com/path?query=value"
        ]

        for url in safeURLs {
            XCTAssertTrue(InputSanitizer.isSafeURL(url), "Safe URL should pass: \(url)")
            print("   ✓ Safe URL: '\(url)'")
        }

        // Unsafe URLs
        let unsafeURLs = [
            "javascript:alert(1)",
            "file:///etc/passwd",
            "data:text/html,<script>alert(1)</script>",
            "ftp://example.com"
        ]

        for url in unsafeURLs {
            XCTAssertFalse(InputSanitizer.isSafeURL(url), "Unsafe URL should fail: \(url)")
            print("   ✓ Unsafe URL rejected: '\(url)'")
        }

        // Sanitize URL
        let validURL = " https://example.com "
        let sanitized = InputSanitizer.sanitizeURL(validURL)
        XCTAssertNotNil(sanitized, "Valid URL should be sanitized")
        print("   ✓ URL sanitized: '\(validURL)' → '\(sanitized ?? "nil")'")

        let invalidURL = "javascript:alert(1)"
        let sanitizedInvalid = InputSanitizer.sanitizeURL(invalidURL)
        XCTAssertNil(sanitizedInvalid, "Invalid URL should return nil")
        print("   ✓ Invalid URL rejected")

        print("✅ Test 3.6.12: URL validation verified")
        print("   Result: PASS - URL validation working correctly")
    }

    // MARK: - Test 3.6.13: Composite Sanitization

    func testCompositeSanitization() throws {
        print("🧪 Test 3.6.13: Testing composite sanitization")

        // Sanitize name
        let name1 = "  <script>John</script> O'Reilly  "
        let safeName = InputSanitizer.sanitizeName(name1)
        XCTAssertFalse(safeName.contains("<"), "Special chars should be removed")
        XCTAssertTrue(safeName.contains("O"), "Valid chars should remain")
        print("   ✓ Name sanitized: '\(name1)' → '\(safeName)'")

        // Sanitize description
        let desc1 = "  Great app! <script>alert(1)</script>  "
        let safeDesc = InputSanitizer.sanitizeDescription(desc1)
        XCTAssertTrue(safeDesc.contains("&lt;"), "HTML should be escaped")
        print("   ✓ Description sanitized: '\(desc1)' → '\(safeDesc)'")

        // Extension method
        let testName = " John Doe "
        XCTAssertEqual(testName.sanitizedName, "John Doe", "Extension should work")
        print("   ✓ Name extension working")

        print("✅ Test 3.6.13: Composite sanitization verified")
        print("   Result: PASS - Composite sanitization correct")
    }

    // MARK: - Test 3.6.14: Batch Sanitization

    func testBatchSanitization() throws {
        print("🧪 Test 3.6.14: Testing batch sanitization")

        let inputs = [
            "  Name 1  ",
            "  Name 2  ",
            "  Name 3  "
        ]

        let sanitized = InputSanitizer.sanitizeBatch(inputs, using: InputSanitizer.trimWhitespace)

        XCTAssertEqual(sanitized.count, inputs.count, "Should sanitize all inputs")
        for (index, result) in sanitized.enumerated() {
            XCTAssertEqual(result, inputs[index].trimmingCharacters(in: .whitespacesAndNewlines))
            print("   ✓ Batch \(index + 1): '\(inputs[index])' → '\(result)'")
        }

        print("✅ Test 3.6.14: Batch sanitization verified")
        print("   Result: PASS - Batch processing working correctly")
    }

    // MARK: - Test 3.6.15: Edge Cases

    func testEdgeCases() throws {
        print("🧪 Test 3.6.15: Testing edge cases")

        // Empty string
        let empty = ""
        XCTAssertEqual(InputSanitizer.trimWhitespace(empty), "", "Empty should remain empty")
        print("   ✓ Empty string handled")

        // Only whitespace
        let whitespace = "   \t\n   "
        XCTAssertEqual(InputSanitizer.trimWhitespace(whitespace), "", "Whitespace-only should trim to empty")
        print("   ✓ Whitespace-only handled")

        // Unicode characters
        let unicode = "Héllo Wörld 你好"
        let sanitized = InputSanitizer.sanitizeName(unicode)
        print("   ✓ Unicode: '\(unicode)' → '\(sanitized)'")

        // Very long input
        let longInput = String(repeating: "a", count: 10000)
        let truncated = try InputSanitizer.validateLength(longInput, maxLength: 1000)
        XCTAssertEqual(truncated.count, 1000, "Should truncate very long input")
        print("   ✓ Very long input truncated: \(longInput.count) → \(truncated.count)")

        // Mixed line endings
        let mixed = "Line1\r\nLine2\rLine3\n"
        let sanitizedMixed = InputSanitizer.removeDangerousCharacters(mixed)
        print("   ✓ Mixed line endings handled")

        print("✅ Test 3.6.15: Edge cases verified")
        print("   Result: PASS - Edge cases handled appropriately")
    }
}
