//
//  ComprehensiveErrorTypesTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for ComprehensiveErrorTypes - Phase 6.1
//

import XCTest
@testable import Swiff_IOS

final class ComprehensiveErrorTypesTests: XCTestCase {

    // MARK: - Test 1: Error Domains

    func testErrorDomains() {
        XCTAssertEqual(ErrorDomain.database.rawValue, "com.swiff.error.database")
        XCTAssertEqual(ErrorDomain.network.rawValue, "com.swiff.error.network")
        XCTAssertEqual(ErrorDomain.validation.rawValue, "com.swiff.error.validation")
        XCTAssertEqual(ErrorDomain.permission.rawValue, "com.swiff.error.permission")
        XCTAssertEqual(ErrorDomain.storage.rawValue, "com.swiff.error.storage")
    }

    // MARK: - Test 2: Error Severity

    func testErrorSeverityComparison() {
        XCTAssertLessThan(ErrorSeverity.info, ErrorSeverity.warning)
        XCTAssertLessThan(ErrorSeverity.warning, ErrorSeverity.error)
        XCTAssertLessThan(ErrorSeverity.error, ErrorSeverity.critical)
        XCTAssertLessThan(ErrorSeverity.critical, ErrorSeverity.fatal)
    }

    func testErrorSeverityDisplayNames() {
        XCTAssertEqual(ErrorSeverity.info.displayName, "Info")
        XCTAssertEqual(ErrorSeverity.warning.displayName, "Warning")
        XCTAssertEqual(ErrorSeverity.error.displayName, "Error")
        XCTAssertEqual(ErrorSeverity.critical.displayName, "Critical")
        XCTAssertEqual(ErrorSeverity.fatal.displayName, "Fatal")
    }

    func testErrorSeverityIcons() {
        XCTAssertEqual(ErrorSeverity.info.icon, "info.circle")
        XCTAssertEqual(ErrorSeverity.warning.icon, "exclamationmark.triangle")
        XCTAssertEqual(ErrorSeverity.error.icon, "xmark.circle")
        XCTAssertEqual(ErrorSeverity.critical.icon, "exclamationmark.octagon")
        XCTAssertEqual(ErrorSeverity.fatal.icon, "exclamationmark.shield")
    }

    // MARK: - Test 3: Error Context

    func testErrorContextCreation() {
        let context = ErrorContext(
            userID: "user123",
            sessionID: "session456",
            additionalInfo: ["action": "test"]
        )

        XCTAssertEqual(context.userID, "user123")
        XCTAssertEqual(context.sessionID, "session456")
        XCTAssertNotNil(context.timestamp)
        XCTAssertNotNil(context.deviceInfo)
        XCTAssertFalse(context.appVersion.isEmpty)
    }

    func testErrorContextSummary() {
        let context = ErrorContext()
        let summary = context.summary

        XCTAssertTrue(summary.contains("Error Context"))
        XCTAssertTrue(summary.contains("Timestamp:"))
        XCTAssertTrue(summary.contains("App Version:"))
        XCTAssertTrue(summary.contains("Device:"))
    }

    func testDeviceInfo() {
        let deviceInfo = ErrorContext.DeviceInfo.current

        XCTAssertFalse(deviceInfo.model.isEmpty)
        XCTAssertFalse(deviceInfo.systemVersion.isEmpty)
        XCTAssertFalse(deviceInfo.locale.isEmpty)
        XCTAssertFalse(deviceInfo.timezone.isEmpty)
    }

    // MARK: - Test 4: Database Errors

    func testDatabaseErrorCorrupted() {
        let error = DatabaseError.corruptedData(reason: "Invalid schema")

        XCTAssertEqual(error.domain, .database)
        XCTAssertEqual(error.code, 1001)
        XCTAssertEqual(error.severity, .critical)
        XCTAssertNotNil(error.localizedDescription)
        XCTAssertTrue(error.localizedDescription.contains("corrupted"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testDatabaseErrorMigrationFailed() {
        let error = DatabaseError.migrationFailed(fromVersion: 1, toVersion: 2)

        XCTAssertEqual(error.code, 1002)
        XCTAssertEqual(error.severity, .critical)
        XCTAssertTrue(error.localizedDescription.contains("migration"))
        XCTAssertFalse(error.isRetryable)
    }

    func testDatabaseErrorQueryFailed() {
        let underlying = NSError(domain: "test", code: 1, userInfo: nil)
        let error = DatabaseError.queryFailed(query: "SELECT * FROM users", underlying: underlying)

        XCTAssertEqual(error.code, 1003)
        XCTAssertNotNil(error.underlyingError)
        XCTAssertTrue(error.isRetryable)
    }

    func testDatabaseErrorDiskFull() {
        let error = DatabaseError.diskFull

        XCTAssertEqual(error.code, 1007)
        XCTAssertEqual(error.severity, .error)
        XCTAssertTrue(error.localizedDescription.contains("Disk"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    // MARK: - Test 5: Validation Errors

    func testValidationErrorInvalidEmail() {
        let error = ValidationError.invalidEmail("invalid.email")

        XCTAssertEqual(error.domain, .validation)
        XCTAssertEqual(error.code, 2001)
        XCTAssertEqual(error.severity, .warning)
        XCTAssertTrue(error.localizedDescription.contains("email"))
        XCTAssertTrue(error.isRetryable)
    }

    func testValidationErrorRequiredFieldMissing() {
        let error = ValidationError.requiredFieldMissing(field: "name")

        XCTAssertEqual(error.code, 2005)
        XCTAssertTrue(error.localizedDescription.contains("Required"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testValidationErrorValueTooLarge() {
        let error = ValidationError.valueTooLarge(value: 1000, max: 100)

        XCTAssertEqual(error.code, 2006)
        XCTAssertTrue(error.localizedDescription.contains("exceeds"))
    }

    func testValidationErrorDuplicateEntry() {
        let error = ValidationError.duplicateEntry(field: "email", value: "test@example.com")

        XCTAssertEqual(error.code, 2009)
        XCTAssertTrue(error.localizedDescription.contains("Duplicate"))
    }

    // MARK: - Test 6: Storage Errors

    func testStorageErrorQuotaExceeded() {
        let error = StorageError.quotaExceeded(used: 15_000_000, limit: 10_000_000)

        XCTAssertEqual(error.domain, .storage)
        XCTAssertEqual(error.code, 3001)
        XCTAssertEqual(error.severity, .error)
        XCTAssertTrue(error.localizedDescription.contains("quota"))
    }

    func testStorageErrorFileNotFound() {
        let error = StorageError.fileNotFound(path: "/tmp/test.txt")

        XCTAssertEqual(error.code, 3002)
        XCTAssertEqual(error.severity, .warning)
        XCTAssertTrue(error.localizedDescription.contains("not found"))
        XCTAssertFalse(error.isRetryable)
    }

    func testStorageErrorPermissionDenied() {
        let error = StorageError.permissionDenied(path: "/restricted/file.txt")

        XCTAssertEqual(error.code, 3003)
        XCTAssertEqual(error.severity, .error)
        XCTAssertTrue(error.localizedDescription.contains("Permission denied"))
    }

    func testStorageErrorWriteFailure() {
        let underlying = NSError(domain: "test", code: 1, userInfo: nil)
        let error = StorageError.writeFailure(path: "/tmp/file.txt", underlying: underlying)

        XCTAssertEqual(error.code, 3004)
        XCTAssertNotNil(error.underlyingError)
        XCTAssertTrue(error.isRetryable)
    }

    // MARK: - Test 7: Export Errors

    func testExportErrorNoData() {
        let error = ExportError.noDataToExport

        XCTAssertEqual(error.domain, .export)
        XCTAssertEqual(error.code, 4001)
        XCTAssertEqual(error.severity, .warning)
        XCTAssertFalse(error.isRetryable)
    }

    func testExportErrorFormatNotSupported() {
        let error = ExportError.formatNotSupported(format: "XML")

        XCTAssertEqual(error.code, 4002)
        XCTAssertTrue(error.localizedDescription.contains("not supported"))
    }

    func testExportErrorExportFailed() {
        let underlying = NSError(domain: "test", code: 1, userInfo: nil)
        let error = ExportError.exportFailed(format: "PDF", underlying: underlying)

        XCTAssertEqual(error.code, 4003)
        XCTAssertNotNil(error.underlyingError)
        XCTAssertTrue(error.isRetryable)
    }

    // MARK: - Test 8: System Errors

    func testSystemErrorLowMemory() {
        let error = SystemError.lowMemory

        XCTAssertEqual(error.domain, .system)
        XCTAssertEqual(error.code, 9001)
        XCTAssertEqual(error.severity, .critical)
        XCTAssertTrue(error.localizedDescription.contains("memory"))
    }

    func testSystemErrorUnknown() {
        let underlying = NSError(domain: "test", code: 1, userInfo: nil)
        let error = SystemError.unknown(underlying: underlying)

        XCTAssertEqual(error.code, 9999)
        XCTAssertNotNil(error.underlyingError)
    }

    // MARK: - Test 9: NSError Conversion

    func testToNSError() {
        let error = DatabaseError.corruptedData(reason: "Test")
        let nsError = error.toNSError()

        XCTAssertEqual(nsError.domain, "com.swiff.error.database")
        XCTAssertEqual(nsError.code, 1001)
        XCTAssertNotNil(nsError.localizedDescription)
    }

    func testNSErrorWithUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: nil)
        let error = DatabaseError.queryFailed(query: "SELECT", underlying: underlying)
        let nsError = error.toNSError()

        XCTAssertNotNil(nsError.userInfo[NSUnderlyingErrorKey])
    }

    // MARK: - Test 10: Error Helper

    func testErrorHelperClassify() {
        let error = DatabaseError.diskFull
        let classified = ErrorHelper.classify(error)

        XCTAssertEqual(classified.domain, .database)
    }

    func testErrorHelperGetUserMessage() {
        let error = ValidationError.invalidEmail("test")
        let message = ErrorHelper.getUserMessage(for: error)

        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("email"))
    }

    func testErrorHelperGetRecoverySuggestion() {
        let error = StorageError.quotaExceeded(used: 100, limit: 50)
        let suggestion = ErrorHelper.getRecoverySuggestion(for: error)

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("Delete") || suggestion!.contains("storage"))
    }

    func testErrorHelperIsRetryable() {
        let retryable = DatabaseError.queryFailed(
            query: "SELECT",
            underlying: NSError(domain: "test", code: 1)
        )
        let notRetryable = DatabaseError.corruptedData(reason: "test")

        XCTAssertTrue(ErrorHelper.isRetryable(retryable))
        XCTAssertFalse(ErrorHelper.isRetryable(notRetryable))
    }

    // MARK: - Test 11: Error Descriptions

    func testAllErrorsHaveDescriptions() {
        let errors: [ApplicationError] = [
            DatabaseError.corruptedData(reason: "test"),
            ValidationError.invalidEmail("test"),
            StorageError.fileNotFound(path: "test"),
            ExportError.noDataToExport,
            SystemError.lowMemory
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testAllErrorsHaveRecoverySuggestions() {
        let errors: [ApplicationError] = [
            DatabaseError.diskFull,
            ValidationError.requiredFieldMissing(field: "test"),
            StorageError.quotaExceeded(used: 100, limit: 50),
            ExportError.formatNotSupported(format: "XML")
        ]

        for error in errors {
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }

    // MARK: - Test 12: Error Codes Uniqueness

    func testDatabaseErrorCodesUnique() {
        let codes = [
            DatabaseError.corruptedData(reason: "").code,
            DatabaseError.migrationFailed(fromVersion: 0, toVersion: 0).code,
            DatabaseError.queryFailed(query: "", underlying: NSError(domain: "", code: 0)).code,
            DatabaseError.diskFull.code
        ]

        let uniqueCodes = Set(codes)
        XCTAssertEqual(codes.count, uniqueCodes.count)
    }

    func testValidationErrorCodesUnique() {
        let codes = [
            ValidationError.invalidEmail("").code,
            ValidationError.invalidPhoneNumber("").code,
            ValidationError.requiredFieldMissing(field: "").code,
            ValidationError.duplicateEntry(field: "", value: "").code
        ]

        let uniqueCodes = Set(codes)
        XCTAssertEqual(codes.count, uniqueCodes.count)
    }
}
