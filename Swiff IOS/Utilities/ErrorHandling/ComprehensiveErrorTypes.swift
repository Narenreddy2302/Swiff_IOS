//
//  ComprehensiveErrorTypes.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 6.1: Comprehensive error type hierarchy with codes, messages, and recovery
//

import Foundation
import UIKit

// MARK: - Error Domain

enum ErrorDomain: String {
    case database = "com.swiff.error.database"
    case network = "com.swiff.error.network"
    case validation = "com.swiff.error.validation"
    case permission = "com.swiff.error.permission"
    case storage = "com.swiff.error.storage"
    case currency = "com.swiff.error.currency"
    case subscription = "com.swiff.error.subscription"
    case export = "com.swiff.error.export"
    case backup = "com.swiff.error.backup"
    case system = "com.swiff.error.system"
}

// MARK: - Error Severity

enum ErrorSeverity: Int, Comparable {
    case info = 0
    case warning = 1
    case error = 2
    case critical = 3
    case fatal = 4

    static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .critical: return "Critical"
        case .fatal: return "Fatal"
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        case .fatal: return "exclamationmark.shield"
        }
    }
}

// MARK: - Error Context

struct ErrorContext {
    let timestamp: Date
    let userID: String?
    let sessionID: String?
    let deviceInfo: DeviceInfo
    let appVersion: String
    let buildNumber: String
    let additionalInfo: [String: Any]

    struct DeviceInfo {
        let model: String
        let systemVersion: String
        let locale: String
        let timezone: String

        static var current: DeviceInfo {
            return DeviceInfo(
                model: UIDevice.current.model,
                systemVersion: UIDevice.current.systemVersion,
                locale: Locale.current.identifier,
                timezone: TimeZone.current.identifier
            )
        }
    }

    init(
        userID: String? = nil,
        sessionID: String? = nil,
        additionalInfo: [String: Any] = [:]
    ) {
        self.timestamp = Date()
        self.userID = userID
        self.sessionID = sessionID
        self.deviceInfo = .current
        self.appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.additionalInfo = additionalInfo
    }

    var summary: String {
        var text = "=== Error Context ===\n"
        text += "Timestamp: \(timestamp)\n"
        text += "App Version: \(appVersion) (\(buildNumber))\n"
        text += "Device: \(deviceInfo.model) - iOS \(deviceInfo.systemVersion)\n"
        text += "Locale: \(deviceInfo.locale)\n"
        text += "Timezone: \(deviceInfo.timezone)\n"

        if let userID = userID {
            text += "User ID: \(userID)\n"
        }

        if let sessionID = sessionID {
            text += "Session ID: \(sessionID)\n"
        }

        if !additionalInfo.isEmpty {
            text += "\nAdditional Info:\n"
            for (key, value) in additionalInfo {
                text += "  \(key): \(value)\n"
            }
        }

        return text
    }
}

// MARK: - Base Application Error

protocol ApplicationError: LocalizedError {
    var domain: ErrorDomain { get }
    var code: Int { get }
    var severity: ErrorSeverity { get }
    var context: ErrorContext { get }
    var underlyingError: Error? { get }
    nonisolated var recoverySuggestion: String? { get }
    var isRetryable: Bool { get }

    func toNSError() -> NSError
}

extension ApplicationError {
    var errorDescription: String? {
        return localizedDescription
    }

    func toNSError() -> NSError {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription,
            "severity": severity.displayName,
            "domain": domain.rawValue,
            "timestamp": context.timestamp,
        ]

        if let suggestion = recoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion
        }

        if let underlying = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlying
        }

        return NSError(
            domain: domain.rawValue,
            code: code,
            userInfo: userInfo
        )
    }
}

// MARK: - Database Errors

enum DatabaseError: ApplicationError {
    case corruptedData(reason: String)
    case migrationFailed(fromVersion: Int, toVersion: Int)
    case queryFailed(query: String, underlying: Error)
    case constraintViolation(constraint: String)
    case transactionFailed(underlying: Error)
    case connectionLost
    case diskFull
    case recoveryFailed(attempts: Int)

    var domain: ErrorDomain { .database }

    var code: Int {
        switch self {
        case .corruptedData: return 1001
        case .migrationFailed: return 1002
        case .queryFailed: return 1003
        case .constraintViolation: return 1004
        case .transactionFailed: return 1005
        case .connectionLost: return 1006
        case .diskFull: return 1007
        case .recoveryFailed: return 1008
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .corruptedData, .migrationFailed, .recoveryFailed: return .critical
        case .diskFull: return .error
        case .connectionLost, .transactionFailed: return .warning
        case .queryFailed, .constraintViolation: return .error
        }
    }

    var context: ErrorContext {
        ErrorContext(additionalInfo: ["errorType": "DatabaseError"])
    }

    var underlyingError: Error? {
        switch self {
        case .queryFailed(_, let error), .transactionFailed(let error):
            return error
        default:
            return nil
        }
    }

    var localizedDescription: String {
        switch self {
        case .corruptedData(let reason):
            return "Database corrupted: \(reason)"
        case .migrationFailed(let from, let to):
            return "Database migration failed from version \(from) to \(to)"
        case .queryFailed(let query, _):
            return "Database query failed: \(query)"
        case .constraintViolation(let constraint):
            return "Database constraint violated: \(constraint)"
        case .transactionFailed:
            return "Database transaction failed"
        case .connectionLost:
            return "Database connection lost"
        case .diskFull:
            return "Disk is full, cannot write to database"
        case .recoveryFailed(let attempts):
            return "Database recovery failed after \(attempts) attempts"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .corruptedData:
            return "Try resetting the database or restoring from backup."
        case .migrationFailed:
            return "Contact support to recover your data."
        case .queryFailed:
            return "Try again or contact support if the issue persists."
        case .constraintViolation:
            return "Check your data for conflicts and try again."
        case .transactionFailed:
            return "Retry the operation."
        case .connectionLost:
            return "Restart the app to reconnect to the database."
        case .diskFull:
            return "Free up storage space on your device."
        case .recoveryFailed:
            return "Reset the database or restore from a backup."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .queryFailed, .transactionFailed, .connectionLost:
            return true
        default:
            return false
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: ApplicationError {
    case invalidEmail(String)
    case invalidPhoneNumber(String)
    case invalidAmount(Decimal)
    case invalidDate(Date)
    case requiredFieldMissing(field: String)
    case valueTooLarge(value: Any, max: Any)
    case valueTooSmall(value: Any, min: Any)
    case invalidFormat(field: String, expectedFormat: String)
    case duplicateEntry(field: String, value: String)

    var domain: ErrorDomain { .validation }

    var code: Int {
        switch self {
        case .invalidEmail: return 2001
        case .invalidPhoneNumber: return 2002
        case .invalidAmount: return 2003
        case .invalidDate: return 2004
        case .requiredFieldMissing: return 2005
        case .valueTooLarge: return 2006
        case .valueTooSmall: return 2007
        case .invalidFormat: return 2008
        case .duplicateEntry: return 2009
        }
    }

    var severity: ErrorSeverity { .warning }

    var context: ErrorContext {
        ErrorContext(additionalInfo: ["errorType": "ValidationError"])
    }

    var underlyingError: Error? { nil }

    var localizedDescription: String {
        switch self {
        case .invalidEmail(let email):
            return "Invalid email address: \(email)"
        case .invalidPhoneNumber(let phone):
            return "Invalid phone number: \(phone)"
        case .invalidAmount(let amount):
            return "Invalid amount: \(amount)"
        case .invalidDate(let date):
            return "Invalid date: \(date)"
        case .requiredFieldMissing(let field):
            return "Required field missing: \(field)"
        case .valueTooLarge(let value, let max):
            return "Value \(value) exceeds maximum \(max)"
        case .valueTooSmall(let value, let min):
            return "Value \(value) is below minimum \(min)"
        case .invalidFormat(let field, let format):
            return "Invalid format for \(field), expected: \(format)"
        case .duplicateEntry(let field, let value):
            return "Duplicate entry for \(field): \(value)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address (e.g., user@example.com)"
        case .invalidPhoneNumber:
            return "Enter a valid phone number with country code"
        case .invalidAmount:
            return "Enter a valid positive number"
        case .invalidDate:
            return "Select a valid date"
        case .requiredFieldMissing:
            return "Fill in all required fields"
        case .valueTooLarge:
            return "Enter a smaller value"
        case .valueTooSmall:
            return "Enter a larger value"
        case .invalidFormat:
            return "Check the format and try again"
        case .duplicateEntry:
            return "Use a different value or update the existing entry"
        }
    }

    var isRetryable: Bool { true }
}

// MARK: - Storage Errors (renamed to avoid conflict with SDK StorageError)

enum AppStorageError: ApplicationError {
    case quotaExceeded(used: Int64, limit: Int64)
    case fileNotFound(path: String)
    case permissionDenied(path: String)
    case writeFailure(path: String, underlying: Error)
    case readFailure(path: String, underlying: Error)
    case corruptedFile(path: String)
    case invalidPath(path: String)

    var domain: ErrorDomain { .storage }

    var code: Int {
        switch self {
        case .quotaExceeded: return 3001
        case .fileNotFound: return 3002
        case .permissionDenied: return 3003
        case .writeFailure: return 3004
        case .readFailure: return 3005
        case .corruptedFile: return 3006
        case .invalidPath: return 3007
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .quotaExceeded, .corruptedFile: return .error
        case .fileNotFound, .invalidPath: return .warning
        case .permissionDenied: return .error
        case .writeFailure, .readFailure: return .error
        }
    }

    var context: ErrorContext {
        ErrorContext(additionalInfo: ["errorType": "StorageError"])
    }

    var underlyingError: Error? {
        switch self {
        case .writeFailure(_, let error), .readFailure(_, let error):
            return error
        default:
            return nil
        }
    }

    var localizedDescription: String {
        switch self {
        case .quotaExceeded(let used, let limit):
            let usedMB = Double(used) / 1_048_576
            let limitMB = Double(limit) / 1_048_576
            return
                "Storage quota exceeded: \(String(format: "%.1f", usedMB))MB of \(String(format: "%.1f", limitMB))MB used"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .permissionDenied(let path):
            return "Permission denied for: \(path)"
        case .writeFailure(let path, _):
            return "Failed to write file: \(path)"
        case .readFailure(let path, _):
            return "Failed to read file: \(path)"
        case .corruptedFile(let path):
            return "Corrupted file: \(path)"
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .quotaExceeded:
            return "Delete old files or increase storage limit"
        case .fileNotFound:
            return "Check that the file exists"
        case .permissionDenied:
            return "Grant necessary permissions in Settings"
        case .writeFailure, .readFailure:
            return "Check available storage and try again"
        case .corruptedFile:
            return "Delete the corrupted file and recreate it"
        case .invalidPath:
            return "Use a valid file path"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .writeFailure, .readFailure: return true
        default: return false
        }
    }
}

// MARK: - Export Errors

enum ExportError: ApplicationError {
    case noDataToExport
    case formatNotSupported(format: String)
    case exportFailed(format: String, underlying: Error)
    case encodingFailed(underlying: Error)
    case saveFailed(destination: String, underlying: Error)

    var domain: ErrorDomain { .export }

    var code: Int {
        switch self {
        case .noDataToExport: return 4001
        case .formatNotSupported: return 4002
        case .exportFailed: return 4003
        case .encodingFailed: return 4004
        case .saveFailed: return 4005
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .noDataToExport: return .warning
        case .formatNotSupported: return .error
        case .exportFailed, .encodingFailed, .saveFailed: return .error
        }
    }

    var context: ErrorContext {
        ErrorContext(additionalInfo: ["errorType": "ExportError"])
    }

    var underlyingError: Error? {
        switch self {
        case .exportFailed(_, let error), .encodingFailed(let error), .saveFailed(_, let error):
            return error
        default:
            return nil
        }
    }

    var localizedDescription: String {
        switch self {
        case .noDataToExport:
            return "No data available to export"
        case .formatNotSupported(let format):
            return "Export format not supported: \(format)"
        case .exportFailed(let format, _):
            return "Failed to export as \(format)"
        case .encodingFailed:
            return "Failed to encode data for export"
        case .saveFailed(let destination, _):
            return "Failed to save export to: \(destination)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noDataToExport:
            return "Add some data before exporting"
        case .formatNotSupported:
            return "Choose a supported export format (CSV, PDF, JSON)"
        case .exportFailed, .encodingFailed:
            return "Try a different export format"
        case .saveFailed:
            return "Check storage space and permissions"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .exportFailed, .encodingFailed, .saveFailed: return true
        default: return false
        }
    }
}

// MARK: - Error Helper

class ErrorHelper {

    /// Convert any error to ApplicationError
    static func classify(_ error: Error) -> ApplicationError {
        if let appError = error as? ApplicationError {
            return appError
        }

        // Try to classify common errors
        if let urlError = error as? URLError {
            return NetworkError.unknown(underlying: urlError) as! ApplicationError
        }

        // Default to system error
        return SystemError.unknown(underlying: error)
    }

    /// Get user-friendly message
    static func getUserMessage(for error: Error) -> String {
        if let appError = error as? ApplicationError {
            return appError.localizedDescription
        }
        return error.localizedDescription
    }

    /// Get recovery suggestion
    static func getRecoverySuggestion(for error: Error) -> String? {
        if let appError = error as? ApplicationError {
            return appError.recoverySuggestion
        }
        return nil
    }

    /// Check if error is retryable
    static func isRetryable(_ error: Error) -> Bool {
        if let appError = error as? ApplicationError {
            return appError.isRetryable
        }
        return false
    }
}

// MARK: - System Errors

enum SystemError: ApplicationError {
    case lowMemory
    case backgroundTaskExpired
    case appTerminated
    case unknown(underlying: Error)

    var domain: ErrorDomain { .system }

    var code: Int {
        switch self {
        case .lowMemory: return 9001
        case .backgroundTaskExpired: return 9002
        case .appTerminated: return 9003
        case .unknown: return 9999
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .lowMemory, .appTerminated: return .critical
        case .backgroundTaskExpired: return .warning
        case .unknown: return .error
        }
    }

    var context: ErrorContext {
        ErrorContext(additionalInfo: ["errorType": "SystemError"])
    }

    var underlyingError: Error? {
        switch self {
        case .unknown(let error): return error
        default: return nil
        }
    }

    var localizedDescription: String {
        switch self {
        case .lowMemory:
            return "Low memory warning"
        case .backgroundTaskExpired:
            return "Background task expired"
        case .appTerminated:
            return "App was terminated"
        case .unknown(let error):
            return "System error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .lowMemory:
            return "Close other apps to free up memory"
        case .backgroundTaskExpired:
            return "Operation will resume when app is reopened"
        case .appTerminated:
            return "Restart the app"
        case .unknown:
            return "Try restarting the app"
        }
    }

    var isRetryable: Bool { false }
}
