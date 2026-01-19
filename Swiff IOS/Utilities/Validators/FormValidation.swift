//
//  FormValidation.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Form validation utilities and helpers
//

import Combine
import Foundation

// MARK: - Validation Errors

enum FormValidationError: LocalizedError {
    case emptyField(String)
    case invalidEmail(String)
    case invalidPhone(String)
    case invalidAmount(String)
    case valueTooLow(String, minimum: Double)
    case valueTooHigh(String, maximum: Double)
    case invalidFormat(String, expected: String)

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidEmail(let email):
            return "'\(email)' is not a valid email address"
        case .invalidPhone(let phone):
            return "'\(phone)' is not a valid phone number"
        case .invalidAmount(let reason):
            return "Invalid amount: \(reason)"
        case .valueTooLow(let field, let minimum):
            return "\(field) must be at least \(minimum)"
        case .valueTooHigh(let field, let maximum):
            return "\(field) must be no more than \(maximum)"
        case .invalidFormat(let field, let expected):
            return "\(field) has invalid format. Expected: \(expected)"
        }
    }
}

// MARK: - Validators

struct Validator {

    // MARK: - String Validation

    static func validateNotEmpty(_ value: String, fieldName: String) -> Result<String, FormValidationError> {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .failure(.emptyField(fieldName))
        }
        return .success(trimmed)
    }

    static func validateMinLength(_ value: String, minLength: Int, fieldName: String) -> Result<String, FormValidationError> {
        if value.count < minLength {
            return .failure(.invalidFormat(fieldName, expected: "at least \(minLength) characters"))
        }
        return .success(value)
    }

    static func validateMaxLength(_ value: String, maxLength: Int, fieldName: String) -> Result<String, FormValidationError> {
        if value.count > maxLength {
            return .failure(.invalidFormat(fieldName, expected: "no more than \(maxLength) characters"))
        }
        return .success(value)
    }

    // MARK: - Email Validation

    static func validateEmail(_ email: String) -> Result<String, FormValidationError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty email (it's optional in many forms)
        if trimmed.isEmpty {
            return .success(trimmed)
        }

        // Email regex pattern
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)

        if predicate.evaluate(with: trimmed) {
            return .success(trimmed)
        } else {
            return .failure(.invalidEmail(trimmed))
        }
    }

    // MARK: - Phone Validation

    static func validatePhone(_ phone: String) -> Result<String, FormValidationError> {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty phone (it's optional in many forms)
        if trimmed.isEmpty {
            return .success(trimmed)
        }

        // Remove common phone number characters for validation
        let digitsOnly = trimmed.replacingOccurrences(of: #"[^\d]"#, with: "", options: .regularExpression)

        // Check if it has a reasonable number of digits (7-15)
        if digitsOnly.count >= 7 && digitsOnly.count <= 15 {
            return .success(trimmed)
        } else {
            return .failure(.invalidPhone(trimmed))
        }
    }

    // MARK: - Amount Validation

    static func validateAmount(_ value: Double, fieldName: String = "Amount", allowNegative: Bool = false, allowZero: Bool = true) -> Result<Double, FormValidationError> {
        if !allowNegative && value < 0 {
            return .failure(.invalidAmount("\(fieldName) cannot be negative"))
        }

        if !allowZero && value == 0 {
            return .failure(.invalidAmount("\(fieldName) cannot be zero"))
        }

        return .success(value)
    }

    static func validateAmountRange(_ value: Double, min: Double, max: Double, fieldName: String = "Amount") -> Result<Double, FormValidationError> {
        if value < min {
            return .failure(.valueTooLow(fieldName, minimum: min))
        }

        if value > max {
            return .failure(.valueTooHigh(fieldName, maximum: max))
        }

        return .success(value)
    }

    // MARK: - Date Validation

    static func validateFutureDate(_ date: Date, fieldName: String = "Date") -> Result<Date, FormValidationError> {
        if date < Date() {
            return .failure(.invalidFormat(fieldName, expected: "a future date"))
        }
        return .success(date)
    }

    static func validatePastDate(_ date: Date, fieldName: String = "Date") -> Result<Date, FormValidationError> {
        if date > Date() {
            return .failure(.invalidFormat(fieldName, expected: "a past date"))
        }
        return .success(date)
    }
}

// MARK: - Form State

class FormState: ObservableObject {
    @Published var errors: [String: String] = [:]
    @Published var isValid: Bool = true

    func setError(for field: String, message: String) {
        errors[field] = message
        isValid = false
    }

    func clearError(for field: String) {
        errors[field] = nil
        updateValidState()
    }

    func clearAllErrors() {
        errors.removeAll()
        isValid = true
    }

    private func updateValidState() {
        isValid = errors.isEmpty
    }

    func getError(for field: String) -> String? {
        return errors[field]
    }

    func hasError(for field: String) -> Bool {
        return errors[field] != nil
    }
}

// MARK: - Validation Extensions

extension String {
    var isValidEmail: Bool {
        if case .success = Validator.validateEmail(self) {
            return true
        }
        return false
    }

    var isValidPhone: Bool {
        if case .success = Validator.validatePhone(self) {
            return true
        }
        return false
    }
}
