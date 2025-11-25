//
//  FormValidator.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 3.4: Comprehensive form validation with real-time feedback
//

import Foundation
import Combine

// MARK: - Validation Error

enum FormValidatorError: LocalizedError {
    case invalidEmail(String)
    case invalidPhoneNumber(String)
    case invalidAmount(String)
    case requiredFieldEmpty(String)
    case valueTooSmall(field: String, minimum: Decimal)
    case valueTooLarge(field: String, maximum: Decimal)
    case invalidLength(field: String, min: Int?, max: Int?)
    case invalidFormat(field: String, expected: String)
    case customError(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail(let email):
            return "Invalid email address: '\(email)'"
        case .invalidPhoneNumber(let phone):
            return "Invalid phone number: '\(phone)'"
        case .invalidAmount(let amount):
            return "Invalid amount: '\(amount)'"
        case .requiredFieldEmpty(let field):
            return "\(field) is required"
        case .valueTooSmall(let field, let minimum):
            return "\(field) must be at least \(minimum)"
        case .valueTooLarge(let field, let maximum):
            return "\(field) must not exceed \(maximum)"
        case .invalidLength(let field, let min, let max):
            if let min = min, let max = max {
                return "\(field) must be between \(min) and \(max) characters"
            } else if let min = min {
                return "\(field) must be at least \(min) characters"
            } else if let max = max {
                return "\(field) must not exceed \(max) characters"
            }
            return "\(field) has invalid length"
        case .invalidFormat(let field, let expected):
            return "\(field) format is invalid. Expected: \(expected)"
        case .customError(let message):
            return message
        }
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case invalid(FormValidatorError)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    var error: FormValidatorError? {
        if case .invalid(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Field Validation Rules

struct FieldValidationRule {
    let fieldName: String
    let validators: [(String) -> ValidationResult]

    func validate(_ value: String) -> ValidationResult {
        for validator in validators {
            let result = validator(value)
            if !result.isValid {
                return result
            }
        }
        return ValidationResult.valid
    }
}

// MARK: - Form Validator

enum FormValidator {

    // MARK: - Email Validation

    /// Comprehensive email validation
    /// - Parameter email: Email address to validate
    /// - Returns: ValidationResult
    static func validateEmail(_ email: String) -> ValidationResult {
        // Check if empty
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ValidationResult.invalid(.requiredFieldEmpty("Email"))
        }

        // Check length
        guard trimmed.count <= 254 else {
            return ValidationResult.invalid(.invalidLength(field: "Email", min: nil, max: 254))
        }

        // RFC 5322 compliant email regex
        let emailRegex = #"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#

        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: trimmed) else {
            return ValidationResult.invalid(.invalidEmail(trimmed))
        }

        // Check for common typos
        let commonDomains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com"]
        let commonTypos = ["gmial.com", "yahooo.com", "outlok.com", "hotmial.com", "iclod.com"]

        let domain = trimmed.split(separator: "@").last?.lowercased() ?? ""
        if commonTypos.contains(String(domain)) {
            return ValidationResult.invalid(.customError("Did you mean one of these domains: \(commonDomains.joined(separator: ", "))?"))
        }

        // Check for multiple @ symbols
        if trimmed.filter({ $0 == "@" }).count != 1 {
            return ValidationResult.invalid(.invalidEmail(trimmed))
        }

        return ValidationResult.valid
    }

    // MARK: - Phone Number Validation

    /// Phone number validation (supports multiple formats)
    /// - Parameter phoneNumber: Phone number to validate
    /// - Returns: ValidationResult
    static func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty phone numbers (optional field)
        if trimmed.isEmpty {
            return ValidationResult.valid
        }

        // Remove common separators for validation
        let digitsOnly = trimmed.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)

        // Check minimum length (at least 10 digits for most countries)
        guard digitsOnly.count >= 10 else {
            return ValidationResult.invalid(.invalidPhoneNumber(phoneNumber))
        }

        // Check maximum length (max 15 digits per E.164)
        guard digitsOnly.count <= 15 else {
            return ValidationResult.invalid(.invalidPhoneNumber(phoneNumber))
        }

        // Common phone formats:
        // +1 (555) 123-4567
        // (555) 123-4567
        // 555-123-4567
        // 5551234567
        // +1-555-123-4567

        let phoneRegex = #"^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,4}[-\s\.]?[0-9]{1,9}$"#
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        guard phonePredicate.evaluate(with: trimmed) else {
            return ValidationResult.invalid(.invalidPhoneNumber(phoneNumber))
        }

        return ValidationResult.valid
    }

    // MARK: - Amount Validation

    /// Amount validation with range checking
    /// - Parameters:
    ///   - amount: Amount string to validate
    ///   - minimum: Minimum allowed value (default: 0.01)
    ///   - maximum: Maximum allowed value (default: 1,000,000)
    ///   - allowZero: Whether zero is allowed (default: false)
    ///   - allowNegative: Whether negative values are allowed (default: false)
    /// - Returns: ValidationResult
    static func validateAmount(
        _ amount: String,
        minimum: Decimal = 0.01,
        maximum: Decimal = 1_000_000,
        allowZero: Bool = false,
        allowNegative: Bool = false
    ) -> ValidationResult {
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty
        guard !trimmed.isEmpty else {
            return ValidationResult.invalid(.requiredFieldEmpty("Amount"))
        }

        // Remove currency symbols and commas
        let cleaned = trimmed
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Try to parse as Decimal
        guard let decimalValue = Decimal(string: cleaned) else {
            return ValidationResult.invalid(.invalidAmount(amount))
        }

        // Check if negative (when not allowed)
        if !allowNegative && decimalValue < 0 {
            return ValidationResult.invalid(.customError("Amount cannot be negative"))
        }

        // Check if zero (when not allowed)
        if !allowZero && decimalValue == 0 {
            return ValidationResult.invalid(.customError("Amount must be greater than zero"))
        }

        // Check minimum
        if decimalValue < minimum {
            return ValidationResult.invalid(.valueTooSmall(field: "Amount", minimum: minimum))
        }

        // Check maximum
        if decimalValue > maximum {
            return ValidationResult.invalid(.valueTooLarge(field: "Amount", maximum: maximum))
        }

        // Check decimal places (max 2 for currency)
        let decimalPlaces = max(0, -decimalValue.exponent)
        if decimalPlaces > 2 {
            return ValidationResult.invalid(.invalidFormat(field: "Amount", expected: "Maximum 2 decimal places"))
        }

        return ValidationResult.valid
    }

    // MARK: - Required Field Validation

    /// Validate that a required field is not empty
    /// - Parameters:
    ///   - value: Field value
    ///   - fieldName: Name of the field for error message
    /// - Returns: ValidationResult
    static func validateRequired(_ value: String, fieldName: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ValidationResult.invalid(.requiredFieldEmpty(fieldName))
        }
        return ValidationResult.valid
    }

    // MARK: - Length Validation

    /// Validate string length
    /// - Parameters:
    ///   - value: String to validate
    ///   - fieldName: Field name for error message
    ///   - minLength: Minimum length (optional)
    ///   - maxLength: Maximum length (optional)
    /// - Returns: ValidationResult
    static func validateLength(
        _ value: String,
        fieldName: String,
        minLength: Int? = nil,
        maxLength: Int? = nil
    ) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let length = trimmed.count

        if let min = minLength, length < min {
            return ValidationResult.invalid(.invalidLength(field: fieldName, min: min, max: nil))
        }

        if let max = maxLength, length > max {
            return ValidationResult.invalid(.invalidLength(field: fieldName, min: nil, max: max))
        }

        return ValidationResult.valid
    }

    // MARK: - Name Validation

    /// Validate person/group name
    /// - Parameter name: Name to validate
    /// - Returns: ValidationResult
    static func validateName(_ name: String, fieldName: String = "Name") -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty
        guard !trimmed.isEmpty else {
            return ValidationResult.invalid(.requiredFieldEmpty(fieldName))
        }

        // Check length (1-100 characters)
        guard trimmed.count >= 1 && trimmed.count <= 100 else {
            return ValidationResult.invalid(.invalidLength(field: fieldName, min: 1, max: 100))
        }

        // Check for invalid characters (allow letters, spaces, hyphens, apostrophes)
        let nameRegex = #"^[a-zA-Z\s\-'\.]+$"#
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)

        guard namePredicate.evaluate(with: trimmed) else {
            return ValidationResult.invalid(.invalidFormat(field: fieldName, expected: "Letters, spaces, hyphens, and apostrophes only"))
        }

        return ValidationResult.valid
    }

    // MARK: - Date Validation

    /// Validate date is within acceptable range
    /// - Parameters:
    ///   - date: Date to validate
    ///   - minDate: Minimum allowed date (optional)
    ///   - maxDate: Maximum allowed date (optional)
    ///   - fieldName: Field name for error message
    /// - Returns: ValidationResult
    static func validateDate(
        _ date: Date,
        minDate: Date? = nil,
        maxDate: Date? = nil,
        fieldName: String = "Date"
    ) -> ValidationResult {
        if let min = minDate, date < min {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return ValidationResult.invalid(.customError("\(fieldName) cannot be before \(formatter.string(from: min))"))
        }

        if let max = maxDate, date > max {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return ValidationResult.invalid(.customError("\(fieldName) cannot be after \(formatter.string(from: max))"))
        }

        return ValidationResult.valid
    }

    // MARK: - Composite Validation

    /// Validate multiple fields at once
    /// - Parameter rules: Array of field validation rules
    /// - Returns: Dictionary of field names to validation results
    static func validateForm(_ rules: [FieldValidationRule], values: [String: String]) -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]

        for rule in rules {
            let value = values[rule.fieldName] ?? ""
            results[rule.fieldName] = rule.validate(value)
        }

        return results
    }

    /// Check if all validation results are valid
    /// - Parameter results: Dictionary of validation results
    /// - Returns: True if all valid, false otherwise
    static func isFormValid(_ results: [String: ValidationResult]) -> Bool {
        return results.values.allSatisfy { $0.isValid }
    }

    /// Get all error messages from validation results
    /// - Parameter results: Dictionary of validation results
    /// - Returns: Array of error messages
    static func getErrorMessages(_ results: [String: ValidationResult]) -> [String] {
        return results.values.compactMap { result -> String? in
            if case .invalid(let error) = result {
                return error.localizedDescription
            }
            return nil
        }
    }
}

// MARK: - Real-time Validation Helper

actor RealTimeValidator {
    private var validationCache: [String: ValidationResult] = [:]
    private var debounceTimers: [String: Task<Void, Never>] = [:]

    /// Validate field with debouncing
    /// - Parameters:
    ///   - fieldName: Name of the field
    ///   - value: Current field value
    ///   - validator: Validation function
    ///   - debounceInterval: Debounce interval in seconds (default: 0.5)
    /// - Returns: Cached validation result (may be stale during debounce)
    func validateWithDebounce(
        fieldName: String,
        value: String,
        validator: @escaping (String) -> ValidationResult,
        debounceInterval: TimeInterval = 0.5
    ) async -> ValidationResult {
        // Cancel existing timer for this field
        debounceTimers[fieldName]?.cancel()

        // Create new debounce timer
        let task = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))

            // Perform validation
            let result = validator(value)
            validationCache[fieldName] = result
        }

        debounceTimers[fieldName] = task

        // Return cached result or valid by default
        return validationCache[fieldName] ?? ValidationResult.valid
    }

    /// Get cached validation result
    func getCachedResult(for fieldName: String) -> ValidationResult? {
        return validationCache[fieldName]
    }

    /// Clear cache for a specific field
    func clearCache(for fieldName: String) {
        validationCache.removeValue(forKey: fieldName)
        debounceTimers[fieldName]?.cancel()
        debounceTimers.removeValue(forKey: fieldName)
    }

    /// Clear all cached results
    func clearAllCache() {
        validationCache.removeAll()
        debounceTimers.values.forEach { $0.cancel() }
        debounceTimers.removeAll()
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Email validation:
 ```swift
 let result = FormValidator.validateEmail("user@example.com")
 if result.isValid {
     print("Email is valid")
 } else {
     print("Error: \(result.error?.localizedDescription ?? "")")
 }
 ```

 2. Amount validation:
 ```swift
 let result = FormValidator.validateAmount(
     "$123.45",
     minimum: 1.00,
     maximum: 10000.00
 )
 ```

 3. Phone number validation:
 ```swift
 let result = FormValidator.validatePhoneNumber("+1 (555) 123-4567")
 ```

 4. Composite form validation:
 ```swift
 let nameRule = FieldValidationRule(fieldName: "name", validators: [
     { FormValidator.validateName($0).isValid ? .valid : FormValidator.validateName($0) }
 ])

 let emailRule = FieldValidationRule(fieldName: "email", validators: [
     { FormValidator.validateEmail($0) }
 ])

 let values = ["name": "John Doe", "email": "john@example.com"]
 let results = FormValidator.validateForm([nameRule, emailRule], values: values)

 if FormValidator.isFormValid(results) {
     print("Form is valid!")
 } else {
     print("Errors: \(FormValidator.getErrorMessages(results))")
 }
 ```

 5. Real-time validation with debouncing:
 ```swift
 let validator = RealTimeValidator()

 // In your view's onChange handler:
 Task {
     let result = await validator.validateWithDebounce(
         fieldName: "email",
         value: emailText,
         validator: FormValidator.validateEmail
     )
 }
 ```
 */
