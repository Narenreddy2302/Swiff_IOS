//
//  ErrorAnalytics.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 6.4: Error Analytics
//

import Foundation

// MARK: - Error Event

/// Represents a single error occurrence for analytics tracking
struct ErrorEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let errorType: String
    let errorCode: Int
    let errorDomain: String
    let severity: String
    let message: String
    let category: String
    let deviceInfo: String
    let appVersion: String
    let userID: String?
    let sessionID: String?
    let metadata: [String: String]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        errorType: String,
        errorCode: Int,
        errorDomain: String,
        severity: String,
        message: String,
        category: String,
        deviceInfo: String,
        appVersion: String,
        userID: String? = nil,
        sessionID: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.errorType = errorType
        self.errorCode = errorCode
        self.errorDomain = errorDomain
        self.severity = severity
        self.message = message
        self.category = category
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
        self.userID = userID
        self.sessionID = sessionID
        self.metadata = metadata
    }

    /// Create from ApplicationError
    static func from(_ error: ApplicationError, category: String = "General") -> ErrorEvent {
        let deviceInfo = error.context.deviceInfo
        let deviceInfoString = "\(deviceInfo.model) - iOS \(deviceInfo.systemVersion) - \(deviceInfo.locale)"

        // Convert additionalInfo [String: Any] to [String: String]
        let metadata = error.context.additionalInfo.reduce(into: [String: String]()) { result, pair in
            result[pair.key] = String(describing: pair.value)
        }

        return ErrorEvent(
            errorType: String(describing: type(of: error)),
            errorCode: error.code,
            errorDomain: error.domain.rawValue,
            severity: error.severity.displayName,
            message: error.localizedDescription,
            category: category,
            deviceInfo: deviceInfoString,
            appVersion: error.context.appVersion,
            userID: error.context.userID,
            sessionID: error.context.sessionID,
            metadata: metadata
        )
    }
}

// MARK: - Error Pattern

/// Represents a detected pattern in error occurrences
struct ErrorPattern: Identifiable {
    let id = UUID()
    let errorType: String
    let errorCode: Int
    let occurrences: Int
    let firstSeen: Date
    let lastSeen: Date
    let averageFrequency: TimeInterval
    let affectedUsers: Set<String>
    let severity: String

    var description: String {
        """
        Pattern: \(errorType) (Code: \(errorCode))
        Occurrences: \(occurrences)
        First Seen: \(firstSeen.formatted())
        Last Seen: \(lastSeen.formatted())
        Affected Users: \(affectedUsers.count)
        Severity: \(severity)
        """
    }
}

// MARK: - Error Statistics

/// Statistical information about errors
struct ErrorStatistics: Codable {
    let totalErrors: Int
    let errorsByDomain: [String: Int]
    let errorsBySeverity: [String: Int]
    let errorsByCategory: [String: Int]
    let errorsByType: [String: Int]
    let mostCommonErrors: [MostCommonError]
    let recentErrors: Int
    let oldestErrorDate: Date?
    let newestErrorDate: Date?
    let averageErrorsPerDay: Double
    let uniqueErrorTypes: Int
    let affectedUsers: Int

    struct MostCommonError: Codable {
        let errorType: String
        let count: Int
    }

    var summary: String {
        var lines = [
            "=== Error Statistics ===",
            "Total Errors: \(totalErrors)",
            "Unique Error Types: \(uniqueErrorTypes)",
            "Affected Users: \(affectedUsers)",
            ""
        ]

        if let oldest = oldestErrorDate, let newest = newestErrorDate {
            lines.append("Date Range: \(oldest.formatted(date: .abbreviated, time: .omitted)) - \(newest.formatted(date: .abbreviated, time: .omitted))")
            lines.append("Average Errors/Day: \(String(format: "%.2f", averageErrorsPerDay))")
            lines.append("")
        }

        lines.append("Errors by Domain:")
        for (domain, count) in errorsByDomain.sorted(by: { $0.value > $1.value }) {
            lines.append("  \(domain): \(count)")
        }
        lines.append("")

        lines.append("Errors by Severity:")
        for (severity, count) in errorsBySeverity.sorted(by: { $0.value > $1.value }) {
            lines.append("  \(severity): \(count)")
        }
        lines.append("")

        lines.append("Top 10 Most Common Errors:")
        for (index, error) in mostCommonErrors.prefix(10).enumerated() {
            lines.append("  \(index + 1). \(error.errorType): \(error.count)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Error Report

/// Comprehensive error report
struct ErrorReport: Codable {
    let id: UUID
    let generatedAt: Date
    let reportPeriod: DateInterval
    let statistics: ErrorStatistics
    let topPatterns: [String]
    let recommendations: [String]
    let affectedSystems: [String]

    var formattedReport: String {
        var lines = [
            "=== ERROR ANALYTICS REPORT ===",
            "Report ID: \(id.uuidString)",
            "Generated: \(generatedAt.formatted(date: .complete, time: .complete))",
            "Period: \(reportPeriod.start.formatted(date: .abbreviated, time: .omitted)) - \(reportPeriod.end.formatted(date: .abbreviated, time: .omitted))",
            "",
            statistics.summary,
            ""
        ]

        if !topPatterns.isEmpty {
            lines.append("=== Top Error Patterns ===")
            for (index, pattern) in topPatterns.enumerated() {
                lines.append("\(index + 1). \(pattern)")
            }
            lines.append("")
        }

        if !affectedSystems.isEmpty {
            lines.append("=== Affected Systems ===")
            for system in affectedSystems {
                lines.append("  • \(system)")
            }
            lines.append("")
        }

        if !recommendations.isEmpty {
            lines.append("=== Recommendations ===")
            for (index, rec) in recommendations.enumerated() {
                lines.append("\(index + 1). \(rec)")
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Export Format

/// Supported export formats for error data
enum ExportFormat {
    case json
    case csv
    case text

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .text: return "txt"
        }
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .text: return "text/plain"
        }
    }
}

// MARK: - Analytics Configuration

/// Configuration for error analytics
struct AnalyticsConfiguration: Sendable {
    let maxEventsStored: Int
    let retentionDays: Int
    let patternDetectionThreshold: Int
    let enableAutoCleanup: Bool
    let trackUserIDs: Bool
    let trackSessionIDs: Bool

    nonisolated(unsafe) static let `default` = AnalyticsConfiguration(
        maxEventsStored: 10000,
        retentionDays: 30,
        patternDetectionThreshold: 5,
        enableAutoCleanup: true,
        trackUserIDs: true,
        trackSessionIDs: true
    )

    nonisolated(unsafe) static let debug = AnalyticsConfiguration(
        maxEventsStored: 1000,
        retentionDays: 7,
        patternDetectionThreshold: 3,
        enableAutoCleanup: false,
        trackUserIDs: true,
        trackSessionIDs: true
    )

    nonisolated(unsafe) static let production = AnalyticsConfiguration(
        maxEventsStored: 50000,
        retentionDays: 90,
        patternDetectionThreshold: 10,
        enableAutoCleanup: true,
        trackUserIDs: false,
        trackSessionIDs: false
    )
}

// MARK: - Error Analytics Manager

/// Main analytics manager for tracking and analyzing errors
@MainActor
class ErrorAnalytics {

    // MARK: - Singleton

    nonisolated static let shared = ErrorAnalytics()

    // MARK: - Properties

    private var events: [ErrorEvent] = []
    private let configuration: AnalyticsConfiguration
    private let storageURL: URL
    private var logger: ErrorLogger?
    private var lastCleanupDate: Date?

    // MARK: - Initialization

    nonisolated init(configuration: AnalyticsConfiguration = .default) {
        self.configuration = configuration

        // Setup storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.storageURL = documentsPath.appendingPathComponent("ErrorAnalytics")

        // Create directory
        try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)

        // Load existing events and perform cleanup on the main actor
        Task { @MainActor in
            self.loadEvents()

            // Perform cleanup if needed
            if configuration.enableAutoCleanup {
                self.performCleanup()
            }
        }
    }

    // MARK: - Event Tracking

    /// Track an error event
    func trackError(_ error: ApplicationError, category: String = "General") {
        let event = ErrorEvent.from(error, category: category)
        trackEvent(event)

        logger?.debug("Tracked error event: \(error.localizedDescription)", category: "Analytics")
    }

    /// Track a custom error event
    func trackEvent(_ event: ErrorEvent) {
        events.append(event)

        // Enforce max events limit
        if events.count > configuration.maxEventsStored {
            let removeCount = events.count - configuration.maxEventsStored
            events.removeFirst(removeCount)
        }

        // Save to disk
        saveEvents()

        // Check if cleanup needed
        if configuration.enableAutoCleanup {
            let daysSinceCleanup = Calendar.current.dateComponents(
                [.day],
                from: lastCleanupDate ?? Date.distantPast,
                to: Date()
            ).day ?? Int.max

            if daysSinceCleanup >= 1 {
                performCleanup()
            }
        }
    }

    /// Track a standard Swift error
    func trackStandardError(_ error: Error, category: String = "General", severity: ErrorSeverity = .error) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let deviceInfo = ErrorContext.DeviceInfo.current
        let deviceInfoString = "\(deviceInfo.model) - iOS \(deviceInfo.systemVersion) - \(deviceInfo.locale)"

        let event = ErrorEvent(
            errorType: String(describing: type(of: error)),
            errorCode: (error as NSError).code,
            errorDomain: (error as NSError).domain,
            severity: severity.displayName,
            message: error.localizedDescription,
            category: category,
            deviceInfo: deviceInfoString,
            appVersion: appVersion
        )

        trackEvent(event)
    }

    // MARK: - Statistics

    /// Get comprehensive statistics
    func getStatistics(for period: DateInterval? = nil) -> ErrorStatistics {
        let filteredEvents = filterEvents(by: period)

        var errorsByDomain: [String: Int] = [:]
        var errorsBySeverity: [String: Int] = [:]
        var errorsByCategory: [String: Int] = [:]
        var errorsByType: [String: Int] = [:]
        var affectedUsers = Set<String>()

        for event in filteredEvents {
            errorsByDomain[event.errorDomain, default: 0] += 1
            errorsBySeverity[event.severity, default: 0] += 1
            errorsByCategory[event.category, default: 0] += 1
            errorsByType[event.errorType, default: 0] += 1

            if let userID = event.userID {
                affectedUsers.insert(userID)
            }
        }

        let mostCommon = errorsByType.sorted { $0.value > $1.value }
            .map { ErrorStatistics.MostCommonError(errorType: $0.key, count: $0.value) }

        let oldest = filteredEvents.min(by: { $0.timestamp < $1.timestamp })?.timestamp
        let newest = filteredEvents.max(by: { $0.timestamp < $1.timestamp })?.timestamp

        var averagePerDay: Double = 0
        if let oldest = oldest, let newest = newest {
            let days = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 1
            averagePerDay = Double(filteredEvents.count) / Double(max(days, 1))
        }

        return ErrorStatistics(
            totalErrors: filteredEvents.count,
            errorsByDomain: errorsByDomain,
            errorsBySeverity: errorsBySeverity,
            errorsByCategory: errorsByCategory,
            errorsByType: errorsByType,
            mostCommonErrors: mostCommon,
            recentErrors: filteredEvents.filter { $0.timestamp > Date().addingTimeInterval(-86400) }.count,
            oldestErrorDate: oldest,
            newestErrorDate: newest,
            averageErrorsPerDay: averagePerDay,
            uniqueErrorTypes: errorsByType.count,
            affectedUsers: affectedUsers.count
        )
    }

    // MARK: - Pattern Detection

    /// Detect common error patterns
    func detectPatterns(minimumOccurrences: Int? = nil) -> [ErrorPattern] {
        let threshold = minimumOccurrences ?? configuration.patternDetectionThreshold

        // Group by error type and code
        var grouped: [String: [ErrorEvent]] = [:]
        for event in events {
            let key = "\(event.errorType):\(event.errorCode)"
            grouped[key, default: []].append(event)
        }

        // Find patterns
        var patterns: [ErrorPattern] = []
        for (_, groupEvents) in grouped {
            guard groupEvents.count >= threshold else { continue }

            let sorted = groupEvents.sorted { $0.timestamp < $1.timestamp }
            guard let first = sorted.first, let last = sorted.last else { continue }

            var affectedUsers = Set<String>()
            for event in groupEvents {
                if let userID = event.userID {
                    affectedUsers.insert(userID)
                }
            }

            let timeSpan = last.timestamp.timeIntervalSince(first.timestamp)
            let avgFrequency = timeSpan / Double(groupEvents.count)

            let pattern = ErrorPattern(
                errorType: first.errorType,
                errorCode: first.errorCode,
                occurrences: groupEvents.count,
                firstSeen: first.timestamp,
                lastSeen: last.timestamp,
                averageFrequency: avgFrequency,
                affectedUsers: affectedUsers,
                severity: first.severity
            )

            patterns.append(pattern)
        }

        return patterns.sorted { $0.occurrences > $1.occurrences }
    }

    /// Get trending errors (increasing frequency)
    func getTrendingErrors(days: Int = 7) -> [ErrorPattern] {
        let cutoff = Date().addingTimeInterval(-TimeInterval(days * 86400))
        let recentEvents = events.filter { $0.timestamp > cutoff }

        // Group by error type
        var grouped: [String: [ErrorEvent]] = [:]
        for event in recentEvents {
            let key = "\(event.errorType):\(event.errorCode)"
            grouped[key, default: []].append(event)
        }

        var patterns: [ErrorPattern] = []
        for (_, groupEvents) in grouped {
            guard groupEvents.count >= 3 else { continue }

            let sorted = groupEvents.sorted { $0.timestamp < $1.timestamp }
            guard let first = sorted.first, let last = sorted.last else { continue }

            var affectedUsers = Set<String>()
            for event in groupEvents {
                if let userID = event.userID {
                    affectedUsers.insert(userID)
                }
            }

            let pattern = ErrorPattern(
                errorType: first.errorType,
                errorCode: first.errorCode,
                occurrences: groupEvents.count,
                firstSeen: first.timestamp,
                lastSeen: last.timestamp,
                averageFrequency: 0,
                affectedUsers: affectedUsers,
                severity: first.severity
            )

            patterns.append(pattern)
        }

        return patterns.sorted { $0.occurrences > $1.occurrences }
    }

    // MARK: - Report Generation

    /// Generate comprehensive error report
    func generateReport(for period: DateInterval? = nil) -> ErrorReport {
        let reportPeriod: DateInterval
        if let period = period {
            reportPeriod = period
        } else {
            let end = Date()
            let start = end.addingTimeInterval(-TimeInterval(30 * 86400)) // Last 30 days
            reportPeriod = DateInterval(start: start, end: end)
        }

        let stats = getStatistics(for: reportPeriod)
        let patterns = detectPatterns()

        // Generate pattern descriptions
        let topPatterns = patterns.prefix(10).map { pattern in
            "\(pattern.errorType) - \(pattern.occurrences) occurrences, \(pattern.affectedUsers.count) users affected"
        }

        // Generate recommendations
        var recommendations: [String] = []

        // High error count recommendation
        if stats.totalErrors > 1000 {
            recommendations.append("High error volume detected. Review and address top error patterns.")
        }

        // Critical errors recommendation
        if let criticalCount = stats.errorsBySeverity["Critical"], criticalCount > 0 {
            recommendations.append("Address \(criticalCount) critical errors immediately.")
        }

        // Pattern-based recommendations
        for pattern in patterns.prefix(5) {
            if pattern.severity == "Critical" || pattern.severity == "Fatal" {
                recommendations.append("Investigate recurring \(pattern.errorType) (\(pattern.occurrences) occurrences)")
            }
        }

        // User impact recommendation
        if stats.affectedUsers > 100 {
            recommendations.append("Errors affecting \(stats.affectedUsers) users. Prioritize fixes for user-facing issues.")
        }

        // Identify affected systems
        let affectedSystems = Array(stats.errorsByDomain.keys.sorted())

        return ErrorReport(
            id: UUID(),
            generatedAt: Date(),
            reportPeriod: reportPeriod,
            statistics: stats,
            topPatterns: topPatterns,
            recommendations: recommendations,
            affectedSystems: affectedSystems
        )
    }

    // MARK: - Export

    /// Export error events to file
    func exportEvents(format: ExportFormat = .json, period: DateInterval? = nil) -> URL? {
        let filteredEvents = filterEvents(by: period)

        let filename = "error_events_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let exportURL = storageURL.appendingPathComponent(filename)

        do {
            let data: Data

            switch format {
            case .json:
                data = try JSONEncoder().encode(filteredEvents)

            case .csv:
                var csv = "ID,Timestamp,Error Type,Code,Domain,Severity,Message,Category,Device,Version\n"
                for event in filteredEvents {
                    csv += "\(event.id),\(event.timestamp),\(event.errorType),\(event.errorCode),\(event.errorDomain),\(event.severity),\"\(event.message)\",\(event.category),\(event.deviceInfo),\(event.appVersion)\n"
                }
                data = csv.data(using: .utf8) ?? Data()

            case .text:
                let text = filteredEvents.map { event in
                    """
                    [\(event.timestamp)] \(event.severity) - \(event.errorType)
                    Domain: \(event.errorDomain) | Code: \(event.errorCode)
                    Message: \(event.message)
                    Category: \(event.category)
                    Device: \(event.deviceInfo)
                    ---
                    """
                }.joined(separator: "\n")
                data = text.data(using: .utf8) ?? Data()
            }

            try data.write(to: exportURL)
            logger?.info("Exported \(filteredEvents.count) events to \(format.fileExtension.uppercased())", category: "Analytics")
            return exportURL

        } catch {
            logger?.error("Failed to export events: \(error.localizedDescription)", category: "Analytics")
            return nil
        }
    }

    /// Export report to file
    func exportReport(_ report: ErrorReport) -> URL? {
        let filename = "error_report_\(report.generatedAt.timeIntervalSince1970).txt"
        let exportURL = storageURL.appendingPathComponent(filename)

        do {
            try report.formattedReport.write(to: exportURL, atomically: true, encoding: .utf8)
            logger?.info("Exported report to file", category: "Analytics")
            return exportURL

        } catch {
            logger?.error("Failed to export report: \(error.localizedDescription)", category: "Analytics")
            return nil
        }
    }

    // MARK: - Querying

    /// Get events by domain
    func getEvents(byDomain domain: ErrorDomain) -> [ErrorEvent] {
        return events.filter { $0.errorDomain == domain.rawValue }
    }

    /// Get events by severity
    func getEvents(bySeverity severity: ErrorSeverity) -> [ErrorEvent] {
        return events.filter { $0.severity == severity.displayName }
    }

    /// Get events by category
    func getEvents(byCategory category: String) -> [ErrorEvent] {
        return events.filter { $0.category == category }
    }

    /// Get events by error type
    func getEvents(byType type: String) -> [ErrorEvent] {
        return events.filter { $0.errorType == type }
    }

    /// Get recent events
    func getRecentEvents(limit: Int = 100) -> [ErrorEvent] {
        return Array(events.suffix(limit).reversed())
    }

    // MARK: - Management

    /// Clear all analytics data
    func clearAllData() {
        events.removeAll()
        saveEvents()
        logger?.info("Cleared all analytics data", category: "Analytics")
    }

    /// Remove old events
    func performCleanup() {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(configuration.retentionDays * 86400))
        let beforeCount = events.count

        events.removeAll { $0.timestamp < cutoffDate }

        let removedCount = beforeCount - events.count
        if removedCount > 0 {
            saveEvents()
            logger?.info("Cleaned up \(removedCount) old events", category: "Analytics")
        }

        lastCleanupDate = Date()
    }

    /// Get total events count
    func getTotalEventsCount() -> Int {
        return events.count
    }

    /// Get storage size
    func getStorageSize() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }

        return totalSize
    }

    // MARK: - Persistence

    private func loadEvents() {
        let eventsFile = storageURL.appendingPathComponent("events.json")

        guard FileManager.default.fileExists(atPath: eventsFile.path) else {
            logger?.debug("No existing events file found", category: "Analytics")
            return
        }

        do {
            let data = try Data(contentsOf: eventsFile)
            events = try JSONDecoder().decode([ErrorEvent].self, from: data)
            logger?.info("Loaded \(events.count) events from storage", category: "Analytics")
        } catch {
            logger?.error("Failed to load events: \(error.localizedDescription)", category: "Analytics")
        }
    }

    private func saveEvents() {
        let eventsFile = storageURL.appendingPathComponent("events.json")

        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: eventsFile, options: .atomic)
        } catch {
            logger?.error("Failed to save events: \(error.localizedDescription)", category: "Analytics")
        }
    }

    private func filterEvents(by period: DateInterval?) -> [ErrorEvent] {
        guard let period = period else {
            return events
        }

        return events.filter { event in
            event.timestamp >= period.start && event.timestamp <= period.end
        }
    }
}

// MARK: - Analytics Extensions

extension ErrorAnalytics {

    /// Get summary string
    func getSummary() -> String {
        let stats = getStatistics()
        let patterns = detectPatterns()

        var lines = [
            "=== ERROR ANALYTICS SUMMARY ===",
            "Total Events: \(events.count)",
            "Configuration: Max=\(configuration.maxEventsStored), Retention=\(configuration.retentionDays)d",
            "Storage Size: \(ByteCountFormatter.string(fromByteCount: getStorageSize(), countStyle: .file))",
            "",
            "Statistics:",
            "  Total Errors: \(stats.totalErrors)",
            "  Unique Types: \(stats.uniqueErrorTypes)",
            "  Affected Users: \(stats.affectedUsers)",
            "  Recent (24h): \(stats.recentErrors)",
            "",
            "Top Patterns:",
        ]

        for (index, pattern) in patterns.prefix(5).enumerated() {
            lines.append("  \(index + 1). \(pattern.errorType): \(pattern.occurrences) occurrences")
        }

        return lines.joined(separator: "\n")
    }
}
