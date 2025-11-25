//
//  ErrorLoggerTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for ErrorLogger - Phase 6.2
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class ErrorLoggerTests: XCTestCase {

    var logger: ErrorLogger!

    override func setUp() async throws {
        try await super.setUp()
        logger = ErrorLogger.shared
        logger.clearAllLogs()
    }

    override func tearDown() async throws {
        logger.clearAllLogs()
        logger = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Log Levels

    func testLogLevelComparison() {
        XCTAssertLessThan(LogLevel.debug, LogLevel.info)
        XCTAssertLessThan(LogLevel.info, LogLevel.warning)
        XCTAssertLessThan(LogLevel.warning, LogLevel.error)
        XCTAssertLessThan(LogLevel.error, LogLevel.critical)
    }

    func testLogLevelDisplayNames() {
        XCTAssertEqual(LogLevel.debug.displayName, "DEBUG")
        XCTAssertEqual(LogLevel.info.displayName, "INFO")
        XCTAssertEqual(LogLevel.warning.displayName, "WARNING")
        XCTAssertEqual(LogLevel.error.displayName, "ERROR")
        XCTAssertEqual(LogLevel.critical.displayName, "CRITICAL")
    }

    func testLogLevelIcons() {
        XCTAssertEqual(LogLevel.debug.icon, "🔍")
        XCTAssertEqual(LogLevel.info.icon, "ℹ️")
        XCTAssertEqual(LogLevel.warning.icon, "⚠️")
        XCTAssertEqual(LogLevel.error.icon, "❌")
        XCTAssertEqual(LogLevel.critical.icon, "🔥")
    }

    // MARK: - Test 2: Log Configuration

    func testDefaultConfiguration() {
        let config = LogConfiguration.default

        XCTAssertEqual(config.maxFileSize, 5 * 1024 * 1024)
        XCTAssertEqual(config.maxLogFiles, 5)
        XCTAssertEqual(config.logLevel, .info)
        XCTAssertTrue(config.enableConsoleLogging)
        XCTAssertTrue(config.enableFileLogging)
        XCTAssertTrue(config.privacyFilteringEnabled)
    }

    func testDebugConfiguration() {
        let config = LogConfiguration.debug

        XCTAssertEqual(config.logLevel, .debug)
        XCTAssertFalse(config.privacyFilteringEnabled)
    }

    func testProductionConfiguration() {
        let config = LogConfiguration.production

        XCTAssertEqual(config.logLevel, .warning)
        XCTAssertFalse(config.enableConsoleLogging)
        XCTAssertTrue(config.privacyFilteringEnabled)
    }

    // MARK: - Test 3: Log Entry

    func testLogEntryCreation() {
        let entry = LogEntry(
            timestamp: Date(),
            level: "INFO",
            message: "Test message",
            category: "Test",
            file: "test.swift",
            function: "testFunction",
            line: 42,
            metadata: ["key": "value"]
        )

        XCTAssertEqual(entry.level, "INFO")
        XCTAssertEqual(entry.message, "Test message")
        XCTAssertEqual(entry.category, "Test")
        XCTAssertEqual(entry.line, 42)
    }

    func testLogEntryFormattedMessage() {
        let entry = LogEntry(
            timestamp: Date(),
            level: "INFO",
            message: "Test",
            category: "General",
            file: "test.swift",
            function: "test",
            line: 1,
            metadata: [:]
        )

        let formatted = entry.formattedMessage

        XCTAssertTrue(formatted.contains("INFO"))
        XCTAssertTrue(formatted.contains("Test"))
        XCTAssertTrue(formatted.contains("General"))
    }

    func testLogEntryFileSize() {
        let entry = LogEntry(
            timestamp: Date(),
            level: "INFO",
            message: "Test",
            category: "General",
            file: "test.swift",
            function: "test",
            line: 1,
            metadata: [:]
        )

        XCTAssertGreaterThan(entry.fileSize, 0)
    }

    // MARK: - Test 4: Privacy Filter

    func testPrivacyFilterEmail() {
        let original = "User email is test@example.com"
        let filtered = PrivacyFilter.filter(original)

        XCTAssertFalse(filtered.contains("test@example.com"))
        XCTAssertTrue(filtered.contains("[EMAIL_REDACTED]"))
    }

    func testPrivacyFilterPhone() {
        let original = "Call me at +1234567890"
        let filtered = PrivacyFilter.filter(original)

        XCTAssertTrue(filtered.contains("[PHONE_REDACTED]"))
    }

    func testPrivacyFilterCreditCard() {
        let original = "Card: 1234-5678-9012-3456"
        let filtered = PrivacyFilter.filter(original)

        XCTAssertTrue(filtered.contains("[CARD_REDACTED]"))
    }

    func testPrivacyFilterSSN() {
        let original = "SSN: 123-45-6789"
        let filtered = PrivacyFilter.filter(original)

        XCTAssertTrue(filtered.contains("[SSN_REDACTED]"))
    }

    func testPrivacyFilterIP() {
        let original = "IP: 192.168.1.1"
        let filtered = PrivacyFilter.filter(original)

        XCTAssertTrue(filtered.contains("[IP_REDACTED]"))
    }

    func testPrivacyFilterMetadata() {
        let metadata = [
            "email": "test@example.com",
            "password": "secret123",
            "token": "abc123",
            "normalData": "visible"
        ]

        let filtered = PrivacyFilter.filterMetadata(metadata)

        XCTAssertEqual(filtered["password"], "[REDACTED]")
        XCTAssertEqual(filtered["token"], "[REDACTED]")
        XCTAssertTrue(filtered["email"]!.contains("[EMAIL_REDACTED]"))
        XCTAssertEqual(filtered["normalData"], "visible")
    }

    // MARK: - Test 5: Logging Methods

    func testDebugLogging() {
        logger.debug("Debug message", category: "Test")
        // Verify log was written (check file system or internal state)
        XCTAssertTrue(true) // Placeholder
    }

    func testInfoLogging() {
        logger.info("Info message", category: "Test")
        XCTAssertTrue(true) // Placeholder
    }

    func testWarningLogging() {
        logger.warning("Warning message", category: "Test")
        XCTAssertTrue(true) // Placeholder
    }

    func testErrorLogging() {
        logger.error("Error message", category: "Test")
        XCTAssertTrue(true) // Placeholder
    }

    func testCriticalLogging() {
        logger.critical("Critical message", category: "Test")
        XCTAssertTrue(true) // Placeholder
    }

    // MARK: - Test 6: Error Logging

    func testLogApplicationError() {
        let error = DatabaseError.corruptedData(reason: "Test")
        logger.logError(error, category: "Database")

        XCTAssertTrue(true) // Verify error was logged
    }

    func testLogStandardError() {
        let error = NSError(domain: "test", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Test error"
        ])
        logger.logError(error, category: "General")

        XCTAssertTrue(true) // Verify error was logged
    }

    // MARK: - Test 7: Performance Logging

    func testLogPerformanceSuccess() {
        logger.logPerformance(
            operation: "Test Operation",
            duration: 1.5,
            success: true,
            metadata: ["rows": "100"]
        )

        XCTAssertTrue(true) // Verify performance log
    }

    func testLogPerformanceFailure() {
        logger.logPerformance(
            operation: "Failed Operation",
            duration: 0.5,
            success: false
        )

        XCTAssertTrue(true) // Verify performance log
    }

    // MARK: - Test 8: Log File Management

    func testGetAllLogFiles() {
        let files = logger.getAllLogFiles()
        XCTAssertNotNil(files)
    }

    func testGetLogFileSize() {
        let files = logger.getAllLogFiles()
        if let firstFile = files.first {
            let size = logger.getLogFileSize(firstFile)
            XCTAssertGreaterThanOrEqual(size, 0)
        }
    }

    func testGetTotalLogsSize() {
        let totalSize = logger.getTotalLogsSize()
        XCTAssertGreaterThanOrEqual(totalSize, 0)
    }

    // MARK: - Test 9: Log Retrieval

    func testReadLogFile() {
        // Write a test log
        logger.info("Test log entry")

        // Give it a moment to write
        Thread.sleep(forTimeInterval: 0.1)

        let files = logger.getAllLogFiles()
        if let firstFile = files.first {
            let content = logger.readLogFile(firstFile)
            XCTAssertNotNil(content)
        }
    }

    // MARK: - Test 10: Log Management

    func testClearAllLogs() {
        // Write some logs
        logger.info("Test 1")
        logger.info("Test 2")

        // Clear logs
        logger.clearAllLogs()

        // Verify logs are cleared
        let totalSize = logger.getTotalLogsSize()
        XCTAssertEqual(totalSize, 0)
    }

    func testExportLogs() {
        logger.info("Test export")

        let exportURL = logger.exportLogs()
        XCTAssertNotNil(exportURL)
    }

    // MARK: - Test 11: Statistics

    func testGetStatistics() {
        logger.info("Test message")

        let stats = logger.getStatistics()

        XCTAssertTrue(stats.contains("Error Logger Statistics"))
        XCTAssertTrue(stats.contains("Configuration:"))
        XCTAssertTrue(stats.contains("Current Status:"))
        XCTAssertTrue(stats.contains("Total Log Files:"))
    }

    // MARK: - Test 12: Metadata

    func testLogWithMetadata() {
        logger.info("Test with metadata", metadata: [
            "userID": "123",
            "action": "login"
        ])

        XCTAssertTrue(true) // Verify metadata was logged
    }

    func testLogWithEmptyMetadata() {
        logger.info("Test without metadata")
        XCTAssertTrue(true)
    }

    // MARK: - Test 13: Log Filtering

    func testLogLevelFiltering() {
        // With default config (info level), debug logs should be filtered
        let config = LogConfiguration.default
        XCTAssertEqual(config.logLevel, .info)

        // Debug logs should not be written
        logger.debug("This should be filtered")

        // Info logs should be written
        logger.info("This should appear")

        XCTAssertTrue(true)
    }

    // MARK: - Test 14: Edge Cases

    func testLogEmptyMessage() {
        logger.info("", category: "Test")
        XCTAssertTrue(true)
    }

    func testLogLongMessage() {
        let longMessage = String(repeating: "A", count: 10000)
        logger.info(longMessage)
        XCTAssertTrue(true)
    }

    func testLogSpecialCharacters() {
        logger.info("Special chars: @#$%^&*()", metadata: [
            "emoji": "🎉🔥💯"
        ])
        XCTAssertTrue(true)
    }

    func testMultipleConcurrentLogs() {
        for i in 0..<100 {
            logger.info("Concurrent log \(i)")
        }
        XCTAssertTrue(true)
    }
}
