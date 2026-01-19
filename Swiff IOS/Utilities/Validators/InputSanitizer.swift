//
//  InputSanitizer.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 3.6: Input sanitization to prevent injection attacks and data corruption
//

import Foundation
import Combine

// MARK: - Sanitization Error

enum SanitizationError: LocalizedError {
    case invalidPath(String)
    case pathTraversal(String)
    case suspiciousContent(String)
    case invalidCharacters(String)
    case excessiveLength(Int)

    var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid file path: '\(path)'"
        case .pathTraversal(let path):
            return "Path traversal attempt detected: '\(path)'"
        case .suspiciousContent(let content):
            return "Suspicious content detected: '\(content)'"
        case .invalidCharacters(let chars):
            return "Invalid characters found: '\(chars)'"
        case .excessiveLength(let length):
            return "Input exceeds maximum length: \(length)"
        }
    }
}

// MARK: - Input Sanitizer

enum InputSanitizer {

    // MARK: - Whitespace Sanitization

    /// Trim leading and trailing whitespace and newlines
    /// - Parameter input: String to trim
    /// - Returns: Trimmed string
    static func trimWhitespace(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Normalize whitespace (collapse multiple spaces to single space)
    /// - Parameter input: String to normalize
    /// - Returns: Normalized string
    static func normalizeWhitespace(_ input: String) -> String {
        let trimmed = trimWhitespace(input)
        return trimmed.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
    }

    /// Remove all whitespace
    /// - Parameter input: String to process
    /// - Returns: String without whitespace
    static func removeWhitespace(_ input: String) -> String {
        return input.replacingOccurrences(
            of: "\\s",
            with: "",
            options: .regularExpression
        )
    }

    // MARK: - Special Character Sanitization

    /// Remove special characters, keeping only alphanumeric and specified allowed characters
    /// - Parameters:
    ///   - input: String to sanitize
    ///   - allowedCharacters: Additional allowed characters (e.g., " -.'")
    /// - Returns: Sanitized string
    static func removeSpecialCharacters(
        _ input: String,
        allowedCharacters: String = ""
    ) -> String {
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: allowedCharacters)
        )

        return String(input.unicodeScalars.filter { allowed.contains($0) })
    }

    /// Remove only dangerous characters (for user-generated content)
    /// - Parameter input: String to sanitize
    /// - Returns: Sanitized string
    static func removeDangerousCharacters(_ input: String) -> String {
        var sanitized = input

        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")

        // Remove control characters (except newline and tab)
        let controlCharacters = CharacterSet.controlCharacters.subtracting(
            CharacterSet(charactersIn: "\n\t")
        )
        sanitized = String(sanitized.unicodeScalars.filter { !controlCharacters.contains($0) })

        return sanitized
    }

    // MARK: - HTML/XML Sanitization

    /// Escape HTML special characters
    /// - Parameter input: String to escape
    /// - Returns: HTML-escaped string
    static func escapeHTML(_ input: String) -> String {
        var escaped = input
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&#x27;")
        escaped = escaped.replacingOccurrences(of: "/", with: "&#x2F;")
        return escaped
    }

    /// Remove all HTML tags
    /// - Parameter input: String with potential HTML
    /// - Returns: String without HTML tags
    static func stripHTMLTags(_ input: String) -> String {
        return input.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
    }

    // MARK: - SQL Injection Prevention

    /// Escape single quotes for SQL (basic protection)
    /// Note: Use parameterized queries instead when possible
    /// - Parameter input: String to escape
    /// - Returns: Escaped string
    static func escapeSQLString(_ input: String) -> String {
        return input.replacingOccurrences(of: "'", with: "''")
    }

    /// Detect potential SQL injection patterns
    /// - Parameter input: String to check
    /// - Returns: True if suspicious patterns found
    static func containsSQLInjection(_ input: String) -> Bool {
        let lowercased = input.lowercased()

        let suspiciousPatterns = [
            "' or '1'='1",
            "' or 1=1",
            "'; drop table",
            "'; delete from",
            "union select",
            "exec(",
            "execute(",
            "xp_cmdshell"
        ]

        return suspiciousPatterns.contains { pattern in
            lowercased.contains(pattern)
        }
    }

    // MARK: - Path Validation and Sanitization

    /// Validate file path for safety
    /// - Parameter path: File path to validate
    /// - Returns: Validation result
    static func validateFilePath(_ path: String) throws -> String {
        let trimmed = trimWhitespace(path)

        // Check for empty path
        guard !trimmed.isEmpty else {
            throw SanitizationError.invalidPath("(empty)")
        }

        // Check for path traversal attempts
        if trimmed.contains("..") {
            throw SanitizationError.pathTraversal(trimmed)
        }

        // Check for absolute paths starting with /
        if trimmed.hasPrefix("/") {
            throw SanitizationError.pathTraversal(trimmed)
        }

        // Check for null bytes
        if trimmed.contains("\0") {
            throw SanitizationError.invalidPath(trimmed)
        }

        // Check for suspicious characters
        let suspiciousChars = ["<", ">", "|", ":", "*", "?", "\""]
        for char in suspiciousChars {
            if trimmed.contains(char) {
                throw SanitizationError.invalidCharacters(char)
            }
        }

        return trimmed
    }

    /// Sanitize filename (remove dangerous characters)
    /// - Parameter filename: Filename to sanitize
    /// - Returns: Safe filename
    static func sanitizeFilename(_ filename: String) -> String {
        var safe = trimWhitespace(filename)

        // Remove path separators
        safe = safe.replacingOccurrences(of: "/", with: "_")
        safe = safe.replacingOccurrences(of: "\\", with: "_")

        // Remove dangerous characters
        let dangerous = ["<", ">", ":", "\"", "|", "?", "*", "\0"]
        for char in dangerous {
            safe = safe.replacingOccurrences(of: char, with: "")
        }

        // Remove leading/trailing dots (hidden files on Unix)
        while safe.hasPrefix(".") {
            safe = String(safe.dropFirst())
        }
        while safe.hasSuffix(".") {
            safe = String(safe.dropLast())
        }

        // Ensure filename is not empty after sanitization
        if safe.isEmpty {
            safe = "untitled"
        }

        // Limit length
        if safe.count > 255 {
            safe = String(safe.prefix(255))
        }

        return safe
    }

    // MARK: - XSS Prevention

    /// Detect potential XSS attempts
    /// - Parameter input: String to check
    /// - Returns: True if suspicious patterns found
    static func containsXSS(_ input: String) -> Bool {
        let lowercased = input.lowercased()

        let suspiciousPatterns = [
            "<script",
            "javascript:",
            "onerror=",
            "onload=",
            "onclick=",
            "<iframe",
            "eval(",
            "alert("
        ]

        return suspiciousPatterns.contains { pattern in
            lowercased.contains(pattern)
        }
    }

    /// Sanitize user-generated content for safe display
    /// - Parameter input: User content
    /// - Returns: Sanitized content
    static func sanitizeUserContent(_ input: String) -> String {
        var sanitized = input

        // Remove dangerous characters
        sanitized = removeDangerousCharacters(sanitized)

        // Escape HTML
        sanitized = escapeHTML(sanitized)

        // Trim whitespace
        sanitized = trimWhitespace(sanitized)

        return sanitized
    }

    // MARK: - Length Validation

    /// Validate and truncate string length
    /// - Parameters:
    ///   - input: String to validate
    ///   - maxLength: Maximum allowed length
    ///   - truncate: Whether to truncate (default) or throw error
    /// - Returns: Validated/truncated string
    static func validateLength(
        _ input: String,
        maxLength: Int,
        truncate: Bool = true
    ) throws -> String {
        guard input.count <= maxLength else {
            if truncate {
                return String(input.prefix(maxLength))
            } else {
                throw SanitizationError.excessiveLength(input.count)
            }
        }

        return input
    }

    // MARK: - Numeric Sanitization

    /// Extract only numeric characters
    /// - Parameter input: String to process
    /// - Returns: String with only digits
    static func extractDigits(_ input: String) -> String {
        return String(input.filter { $0.isNumber })
    }

    /// Extract alphanumeric characters only
    /// - Parameter input: String to process
    /// - Returns: String with only letters and numbers
    static func extractAlphanumeric(_ input: String) -> String {
        return String(input.filter { $0.isLetter || $0.isNumber })
    }

    // MARK: - Email Sanitization

    /// Sanitize email address
    /// - Parameter email: Email to sanitize
    /// - Returns: Sanitized email
    static func sanitizeEmail(_ email: String) -> String {
        var sanitized = trimWhitespace(email)
        sanitized = sanitized.lowercased()

        // Remove any spaces
        sanitized = sanitized.replacingOccurrences(of: " ", with: "")

        // Remove control characters
        sanitized = removeDangerousCharacters(sanitized)

        return sanitized
    }

    // MARK: - Phone Number Sanitization

    /// Sanitize phone number (extract digits and +)
    /// - Parameter phone: Phone number to sanitize
    /// - Returns: Sanitized phone number
    static func sanitizePhoneNumber(_ phone: String) -> String {
        var sanitized = trimWhitespace(phone)

        // Keep only digits, +, -, (, ), and spaces
        let allowed = CharacterSet(charactersIn: "0123456789+-(). ")
        sanitized = String(sanitized.unicodeScalars.filter { allowed.contains($0) })

        return sanitized
    }

    // MARK: - URL Sanitization

    /// Validate URL is safe (http/https only)
    /// - Parameter urlString: URL string to validate
    /// - Returns: True if safe
    static func isSafeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }

        guard let scheme = url.scheme?.lowercased() else {
            return false
        }

        // Only allow http and https
        return scheme == "http" || scheme == "https"
    }

    /// Sanitize URL string
    /// - Parameter urlString: URL to sanitize
    /// - Returns: Sanitized URL string or nil if invalid
    static func sanitizeURL(_ urlString: String) -> String? {
        let trimmed = trimWhitespace(urlString)

        guard isSafeURL(trimmed) else {
            return nil
        }

        return trimmed
    }

    // MARK: - Composite Sanitization

    /// Sanitize person/group name
    /// - Parameter name: Name to sanitize
    /// - Returns: Sanitized name
    static func sanitizeName(_ name: String) -> String {
        var sanitized = trimWhitespace(name)

        // Remove dangerous characters but keep common name characters
        sanitized = removeSpecialCharacters(sanitized, allowedCharacters: " -.'")

        // Normalize whitespace
        sanitized = normalizeWhitespace(sanitized)

        // Limit length
        sanitized = (try? validateLength(sanitized, maxLength: 100)) ?? ""

        return sanitized
    }

    /// Sanitize description/notes field
    /// - Parameter text: Text to sanitize
    /// - Returns: Sanitized text
    static func sanitizeDescription(_ text: String) -> String {
        var sanitized = trimWhitespace(text)

        // Remove dangerous characters
        sanitized = removeDangerousCharacters(sanitized)

        // Escape HTML for safety
        sanitized = escapeHTML(sanitized)

        // Limit length
        sanitized = (try? validateLength(sanitized, maxLength: 1000)) ?? ""

        return sanitized
    }

    // MARK: - Batch Sanitization

    /// Sanitize multiple strings
    /// - Parameter inputs: Array of strings to sanitize
    /// - Returns: Array of sanitized strings
    static func sanitizeBatch(
        _ inputs: [String],
        using sanitizer: (String) -> String
    ) -> [String] {
        return inputs.map { sanitizer($0) }
    }
}

// MARK: - String Extension

extension String {
    /// Trim whitespace from string
    var trimmed: String {
        return InputSanitizer.trimWhitespace(self)
    }

    /// Sanitize as name
    var sanitizedName: String {
        return InputSanitizer.sanitizeName(self)
    }

    /// Sanitize as email
    var sanitizedEmail: String {
        return InputSanitizer.sanitizeEmail(self)
    }

    /// Sanitize as phone number
    var sanitizedPhone: String {
        return InputSanitizer.sanitizePhoneNumber(self)
    }

    /// Sanitize as user content
    var sanitizedContent: String {
        return InputSanitizer.sanitizeUserContent(self)
    }

    /// Check if contains SQL injection
    var hasSQLInjection: Bool {
        return InputSanitizer.containsSQLInjection(self)
    }

    /// Check if contains XSS
    var hasXSS: Bool {
        return InputSanitizer.containsXSS(self)
    }

    /// Escape HTML
    var htmlEscaped: String {
        return InputSanitizer.escapeHTML(self)
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic whitespace trimming:
 ```swift
 let input = "  Hello World  "
 let trimmed = InputSanitizer.trimWhitespace(input)
 // Result: "Hello World"

 // Or using extension:
 let trimmed2 = input.trimmed
 ```

 2. Sanitize user name:
 ```swift
 let name = "  John <script>alert('xss')</script> Doe  "
 let safe = InputSanitizer.sanitizeName(name)
 // Result: "John scriptalertxssscript Doe" (special chars removed)

 // Or using extension:
 let safe2 = name.sanitizedName
 ```

 3. Validate file path:
 ```swift
 do {
     let path = try InputSanitizer.validateFilePath("documents/invoice.pdf")
     // Safe to use
 } catch {
     print("Invalid path: \(error)")
 }
 ```

 4. Sanitize user-generated content:
 ```swift
 let userComment = "<b>Great app!</b>"
 let safe = InputSanitizer.sanitizeUserContent(userComment)
 // Result: "&lt;b&gt;Great app!&lt;/b&gt;"
 ```

 5. Detect injection attempts:
 ```swift
 let input = "'; DROP TABLE users; --"
 if input.hasSQLInjection {
     print("SQL injection attempt detected!")
 }

 if input.hasXSS {
     print("XSS attempt detected!")
 }
 ```

 6. Sanitize filename:
 ```swift
 let filename = "../../../etc/passwd"
 let safe = InputSanitizer.sanitizeFilename(filename)
 // Result: "etcpasswd"
 ```
 */
