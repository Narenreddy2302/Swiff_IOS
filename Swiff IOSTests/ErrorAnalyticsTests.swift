//
//  ErrorAnalyticsTests.swift
//  Swiff IOSTests
//
//  Created by Claude Code on 11/20/25.
//  Tests for ErrorAnalytics - Phase 6.4
//

import XCTest
@testable import Swiff_IOS

@MainActor
final class ErrorAnalyticsTests: XCTestCase {

    var analytics: ErrorAnalytics!

    override func setUp() async throws {
        try await super.setUp()
        analytics = ErrorAnalytics(configuration: .debug)
        analytics.clearAllData()
    }

    override func tearDown() async throws {
        analytics.clearAllData()
        analytics = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Configuration

    func testDefaultConfiguration() {
        let config = AnalyticsConfiguration.default

        XCTAssertEqual(config.maxEventsStored, 10000)
        XCTAssertEqual(config.retentionDays, 30)
        XCTAssertEqual(config.patternDetectionThreshold, 5)
        XCTAssertTrue(config.enableAutoCleanup)
        XCTAssertTrue(config.trackUserIDs)
        XCTAssertTrue(config.trackSessionIDs)
    }

    func testDebugConfiguration() {
        let config = AnalyticsConfiguration.debug

        XCTAssertEqual(config.maxEventsStored, 1000)
        XCTAssertEqual(config.retentionDays, 7)
        XCTAssertEqual(config.patternDetectionThreshold, 3)
        XCTAssertFalse(config.enableAutoCleanup)
    }

    func testProductionConfiguration() {
        let config = AnalyticsConfiguration.production

        XCTAssertEqual(config.maxEventsStored, 50000)
        XCTAssertEqual(config.retentionDays, 90)
        XCTAssertEqual(config.patternDetectionThreshold, 10)
        XCTAssertTrue(config.enableAutoCleanup)
        XCTAssertFalse(config.trackUserIDs)
        XCTAssertFalse(config.trackSessionIDs)
    }

    // MARK: - Test 2: Error Event

    func testErrorEventCreation() {
        let event = ErrorEvent(
            errorType: "DatabaseError",
            errorCode: 1001,
            errorDomain: "com.swiff.error.database",
            severity: "Error",
            message: "Test error",
            category: "Database",
            deviceInfo: "iPhone 15",
            appVersion: "1.0.0"
        )

        XCTAssertEqual(event.errorType, "DatabaseError")
        XCTAssertEqual(event.errorCode, 1001)
        XCTAssertEqual(event.errorDomain, "com.swiff.error.database")
        XCTAssertEqual(event.severity, "Error")
        XCTAssertEqual(event.message, "Test error")
        XCTAssertNotNil(event.id)
        XCTAssertNotNil(event.timestamp)
    }

    func testErrorEventFromApplicationError() {
        let error = DatabaseError.corruptedData(reason: "Test corruption")
        let event = ErrorEvent.from(error, category: "Database")

        XCTAssertEqual(event.errorCode, error.code)
        XCTAssertEqual(event.errorDomain, error.domain.rawValue)
        XCTAssertEqual(event.severity, error.severity.displayName)
        XCTAssertEqual(event.category, "Database")
    }

    // MARK: - Test 3: Event Tracking

    func testTrackError() {
        let error = DatabaseError.queryFailed(
            query: "SELECT * FROM users",
            underlying: NSError(domain: "test", code: 1)
        )

        analytics.trackError(error, category: "Database")

        XCTAssertEqual(analytics.getTotalEventsCount(), 1)
    }

    func testTrackMultipleErrors() {
        for i in 0..<10 {
            let error = ValidationError.requiredFieldMissing(field: "field\(i)")
            analytics.trackError(error)
        }

        XCTAssertEqual(analytics.getTotalEventsCount(), 10)
    }

    func testTrackStandardError() {
        let error = NSError(domain: "test", code: 123, userInfo: [
            NSLocalizedDescriptionKey: "Test error"
        ])

        analytics.trackStandardError(error, category: "General", severity: .warning)

        XCTAssertEqual(analytics.getTotalEventsCount(), 1)
        let events = analytics.getRecentEvents(limit: 1)
        XCTAssertEqual(events.first?.errorCode, 123)
    }

    func testMaxEventsLimit() {
        let config = AnalyticsConfiguration(
            maxEventsStored: 5,
            retentionDays: 30,
            patternDetectionThreshold: 3,
            enableAutoCleanup: false,
            trackUserIDs: true,
            trackSessionIDs: true
        )
        let limitedAnalytics = ErrorAnalytics(configuration: config)

        // Track more than max
        for i in 0..<10 {
            let error = ValidationError.requiredFieldMissing(field: "field\(i)")
            limitedAnalytics.trackError(error)
        }

        // Should only keep the last 5
        XCTAssertEqual(limitedAnalytics.getTotalEventsCount(), 5)
    }

    // MARK: - Test 4: Statistics

    func testGetStatistics() {
        // Track diverse errors
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"))
        analytics.trackError(DatabaseError.queryFailed(query: "SELECT", underlying: NSError(domain: "test", code: 1)))
        analytics.trackError(ValidationError.invalidEmail("test@"))
        analytics.trackError(StorageError.quotaExceeded(used: 100, limit: 50))

        let stats = analytics.getStatistics()

        XCTAssertEqual(stats.totalErrors, 4)
        XCTAssertGreaterThan(stats.errorsByDomain.count, 0)
        XCTAssertGreaterThan(stats.errorsBySeverity.count, 0)
        XCTAssertGreaterThan(stats.uniqueErrorTypes, 0)
    }

    func testGetStatisticsForPeriod() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let period = DateInterval(start: yesterday, end: now)

        analytics.trackError(DatabaseError.diskFull)

        let stats = analytics.getStatistics(for: period)

        XCTAssertEqual(stats.totalErrors, 1)
    }

    func testStatisticsSummary() {
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"))
        analytics.trackError(ValidationError.invalidEmail("test"))

        let stats = analytics.getStatistics()
        let summary = stats.summary

        XCTAssertTrue(summary.contains("Error Statistics"))
        XCTAssertTrue(summary.contains("Total Errors"))
        XCTAssertTrue(summary.contains("Errors by Domain"))
    }

    // MARK: - Test 5: Pattern Detection

    func testDetectPatterns() {
        // Create pattern by repeating same error
        for _ in 0..<5 {
            analytics.trackError(DatabaseError.corruptedData(reason: "Same issue"))
        }

        let patterns = analytics.detectPatterns(minimumOccurrences: 3)

        XCTAssertGreaterThan(patterns.count, 0)
        XCTAssertEqual(patterns.first?.occurrences, 5)
    }

    func testDetectPatternsWithThreshold() {
        // Create one pattern above threshold
        for _ in 0..<5 {
            analytics.trackError(DatabaseError.corruptedData(reason: "Frequent"))
        }

        // Create one below threshold
        for _ in 0..<2 {
            analytics.trackError(ValidationError.invalidEmail("rare"))
        }

        let patterns = analytics.detectPatterns(minimumOccurrences: 4)

        // Should only detect the first pattern
        XCTAssertEqual(patterns.count, 1)
        XCTAssertEqual(patterns.first?.errorType, "DatabaseError")
    }

    func testPatternDescription() {
        for _ in 0..<3 {
            analytics.trackError(StorageError.fileNotFound(path: "/test"))
        }

        let patterns = analytics.detectPatterns(minimumOccurrences: 2)
        guard let pattern = patterns.first else {
            XCTFail("No pattern detected")
            return
        }

        let description = pattern.description

        XCTAssertTrue(description.contains("Pattern:"))
        XCTAssertTrue(description.contains("Occurrences:"))
        XCTAssertTrue(description.contains("First Seen:"))
        XCTAssertTrue(description.contains("Severity:"))
    }

    func testGetTrendingErrors() {
        // Add errors in recent period
        for _ in 0..<5 {
            analytics.trackError(ValidationError.invalidEmail("trending"))
        }

        let trending = analytics.getTrendingErrors(days: 7)

        XCTAssertGreaterThan(trending.count, 0)
    }

    // MARK: - Test 6: Report Generation

    func testGenerateReport() {
        // Add diverse errors
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"))
        analytics.trackError(ValidationError.invalidEmail("test"))
        analytics.trackError(StorageError.quotaExceeded(used: 100, limit: 50))

        let report = analytics.generateReport()

        XCTAssertNotNil(report.id)
        XCTAssertEqual(report.statistics.totalErrors, 3)
        XCTAssertNotNil(report.generatedAt)
    }

    func testReportFormattedOutput() {
        analytics.trackError(DatabaseError.diskFull)

        let report = analytics.generateReport()
        let formatted = report.formattedReport

        XCTAssertTrue(formatted.contains("ERROR ANALYTICS REPORT"))
        XCTAssertTrue(formatted.contains("Report ID:"))
        XCTAssertTrue(formatted.contains("Generated:"))
        XCTAssertTrue(formatted.contains("Error Statistics"))
    }

    func testReportRecommendations() {
        // Add critical errors to trigger recommendations
        for _ in 0..<10 {
            analytics.trackError(DatabaseError.corruptedData(reason: "Critical issue"))
        }

        let report = analytics.generateReport()

        XCTAssertGreaterThan(report.recommendations.count, 0)
    }

    // MARK: - Test 7: Export Formats

    func testExportFormatProperties() {
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.text.fileExtension, "txt")

        XCTAssertEqual(ExportFormat.json.mimeType, "application/json")
        XCTAssertEqual(ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(ExportFormat.text.mimeType, "text/plain")
    }

    // MARK: - Test 8: Export Functionality

    func testExportEventsJSON() {
        analytics.trackError(DatabaseError.diskFull)

        let exportURL = analytics.exportEvents(format: .json)

        XCTAssertNotNil(exportURL)
        if let url = exportURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".json"))
        }
    }

    func testExportEventsCSV() {
        analytics.trackError(ValidationError.invalidEmail("test"))

        let exportURL = analytics.exportEvents(format: .csv)

        XCTAssertNotNil(exportURL)
        if let url = exportURL {
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".csv"))
        }
    }

    func testExportEventsText() {
        analytics.trackError(StorageError.fileNotFound(path: "/test"))

        let exportURL = analytics.exportEvents(format: .text)

        XCTAssertNotNil(exportURL)
        if let url = exportURL {
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".txt"))
        }
    }

    func testExportReport() {
        analytics.trackError(DatabaseError.queryFailed(query: "SELECT", underlying: NSError(domain: "test", code: 1)))

        let report = analytics.generateReport()
        let exportURL = analytics.exportReport(report)

        XCTAssertNotNil(exportURL)
        if let url = exportURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    // MARK: - Test 9: Querying

    func testGetEventsByDomain() {
        analytics.trackError(DatabaseError.diskFull)
        analytics.trackError(ValidationError.invalidEmail("test"))
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"))

        let dbEvents = analytics.getEvents(byDomain: .database)

        XCTAssertEqual(dbEvents.count, 2)
    }

    func testGetEventsBySeverity() {
        analytics.trackError(DatabaseError.corruptedData(reason: "Critical")) // Critical
        analytics.trackError(ValidationError.invalidEmail("test")) // Warning
        analytics.trackError(StorageError.quotaExceeded(used: 100, limit: 50)) // Error

        let criticalEvents = analytics.getEvents(bySeverity: .critical)

        XCTAssertGreaterThan(criticalEvents.count, 0)
    }

    func testGetEventsByCategory() {
        analytics.trackError(DatabaseError.diskFull, category: "Database")
        analytics.trackError(ValidationError.invalidEmail("test"), category: "Validation")
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"), category: "Database")

        let dbEvents = analytics.getEvents(byCategory: "Database")

        XCTAssertEqual(dbEvents.count, 2)
    }

    func testGetEventsByType() {
        analytics.trackError(DatabaseError.diskFull)
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"))
        analytics.trackError(ValidationError.invalidEmail("test"))

        let dbErrorEvents = analytics.getEvents(byType: "DatabaseError")

        XCTAssertEqual(dbErrorEvents.count, 2)
    }

    func testGetRecentEvents() {
        for i in 0..<20 {
            analytics.trackError(ValidationError.requiredFieldMissing(field: "field\(i)"))
        }

        let recent = analytics.getRecentEvents(limit: 10)

        XCTAssertEqual(recent.count, 10)
        // Should be in reverse chronological order (newest first)
    }

    // MARK: - Test 10: Management

    func testClearAllData() {
        analytics.trackError(DatabaseError.diskFull)
        analytics.trackError(ValidationError.invalidEmail("test"))

        XCTAssertEqual(analytics.getTotalEventsCount(), 2)

        analytics.clearAllData()

        XCTAssertEqual(analytics.getTotalEventsCount(), 0)
    }

    func testPerformCleanup() {
        // This test is limited since we can't easily create old events
        // Just verify cleanup runs without error
        analytics.trackError(DatabaseError.diskFull)

        analytics.performCleanup()

        // Should still have the recent event
        XCTAssertEqual(analytics.getTotalEventsCount(), 1)
    }

    func testGetTotalEventsCount() {
        XCTAssertEqual(analytics.getTotalEventsCount(), 0)

        analytics.trackError(DatabaseError.diskFull)
        XCTAssertEqual(analytics.getTotalEventsCount(), 1)

        analytics.trackError(ValidationError.invalidEmail("test"))
        XCTAssertEqual(analytics.getTotalEventsCount(), 2)
    }

    func testGetStorageSize() {
        analytics.trackError(DatabaseError.diskFull)

        let size = analytics.getStorageSize()

        XCTAssertGreaterThanOrEqual(size, 0)
    }

    // MARK: - Test 11: Summary

    func testGetSummary() {
        analytics.trackError(DatabaseError.corruptedData(reason: "Test"))
        analytics.trackError(ValidationError.invalidEmail("test"))

        let summary = analytics.getSummary()

        XCTAssertTrue(summary.contains("ERROR ANALYTICS SUMMARY"))
        XCTAssertTrue(summary.contains("Total Events:"))
        XCTAssertTrue(summary.contains("Configuration:"))
        XCTAssertTrue(summary.contains("Statistics:"))
        XCTAssertTrue(summary.contains("Top Patterns:"))
    }

    // MARK: - Test 12: Integration

    func testFullWorkflow() {
        // 1. Track various errors
        for _ in 0..<5 {
            analytics.trackError(DatabaseError.corruptedData(reason: "Data issue"))
        }

        for _ in 0..<3 {
            analytics.trackError(ValidationError.invalidEmail("bad email"))
        }

        analytics.trackError(StorageError.quotaExceeded(used: 100, limit: 50))

        // 2. Get statistics
        let stats = analytics.getStatistics()
        XCTAssertEqual(stats.totalErrors, 9)
        XCTAssertGreaterThan(stats.uniqueErrorTypes, 0)

        // 3. Detect patterns
        let patterns = analytics.detectPatterns(minimumOccurrences: 3)
        XCTAssertEqual(patterns.count, 2) // DatabaseError and ValidationError

        // 4. Generate report
        let report = analytics.generateReport()
        XCTAssertEqual(report.statistics.totalErrors, 9)
        XCTAssertGreaterThan(report.topPatterns.count, 0)

        // 5. Export
        let exportURL = analytics.exportEvents(format: .json)
        XCTAssertNotNil(exportURL)

        // 6. Query
        let dbEvents = analytics.getEvents(byDomain: .database)
        XCTAssertEqual(dbEvents.count, 5)

        // 7. Cleanup
        analytics.clearAllData()
        XCTAssertEqual(analytics.getTotalEventsCount(), 0)
    }

    // MARK: - Test 13: Edge Cases

    func testEmptyStatistics() {
        let stats = analytics.getStatistics()

        XCTAssertEqual(stats.totalErrors, 0)
        XCTAssertEqual(stats.uniqueErrorTypes, 0)
        XCTAssertEqual(stats.errorsByDomain.count, 0)
    }

    func testNoPatternsDetected() {
        // Add different errors, none repeated enough
        analytics.trackError(DatabaseError.diskFull)
        analytics.trackError(ValidationError.invalidEmail("test"))
        analytics.trackError(StorageError.fileNotFound(path: "/test"))

        let patterns = analytics.detectPatterns(minimumOccurrences: 5)

        XCTAssertEqual(patterns.count, 0)
    }

    func testExportWithNoData() {
        let exportURL = analytics.exportEvents(format: .json)

        XCTAssertNotNil(exportURL)
        // Should create file even with no data
    }
}
