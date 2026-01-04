//
//  ErrorLogger.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 6.2: Comprehensive error logging with rotation and privacy filtering
//

import Foundation
import OSLog

// MARK: - Log Level

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }

    var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔥"
        }
    }
}

// MARK: - Log Entry

struct LogEntry: Codable {
    let timestamp: Date
    let level: String
    let message: String
    let category: String
    let file: String
    let function: String
    let line: Int
    let metadata: [String: String]

    var formattedMessage: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timeStr = dateFormatter.string(from: timestamp)

        var output = "[\(timeStr)] [\(level)] [\(category)] \(message)"

        if !metadata.isEmpty {
            let metaStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            output += " | \(metaStr)"
        }

        output += " (\(file):\(line) \(function))"

        return output
    }

    var fileSize: Int {
        return formattedMessage.utf8.count + 1 // +1 for newline
    }
}

// MARK: - Log Configuration

struct LogConfiguration {
    let maxFileSize: Int64
    let maxLogFiles: Int
    let logLevel: LogLevel
    let enableConsoleLogging: Bool
    let enableFileLogging: Bool
    let privacyFilteringEnabled: Bool

    nonisolated static let `default` = LogConfiguration(
        maxFileSize: 5 * 1024 * 1024, // 5 MB
        maxLogFiles: 5,
        logLevel: .info,
        enableConsoleLogging: true,
        enableFileLogging: true,
        privacyFilteringEnabled: true
    )

    static let debug = LogConfiguration(
        maxFileSize: 10 * 1024 * 1024, // 10 MB
        maxLogFiles: 10,
        logLevel: .debug,
        enableConsoleLogging: true,
        enableFileLogging: true,
        privacyFilteringEnabled: false
    )

    static let production = LogConfiguration(
        maxFileSize: 2 * 1024 * 1024, // 2 MB
        maxLogFiles: 3,
        logLevel: .warning,
        enableConsoleLogging: false,
        enableFileLogging: true,
        privacyFilteringEnabled: true
    )
}

// MARK: - Privacy Filter

class PrivacyFilter {

    private static let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
    private static let phonePattern = "\\+?[1-9]\\d{1,14}"
    private static let creditCardPattern = "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b"
    private static let ssnPattern = "\\b\\d{3}-\\d{2}-\\d{4}\\b"
    private static let ipPattern = "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b"

    static func filter(_ text: String) -> String {
        var filtered = text

        // Email addresses
        filtered = filtered.replacingOccurrences(
            of: emailPattern,
            with: "[EMAIL_REDACTED]",
            options: .regularExpression
        )

        // Phone numbers
        filtered = filtered.replacingOccurrences(
            of: phonePattern,
            with: "[PHONE_REDACTED]",
            options: .regularExpression
        )

        // Credit card numbers
        filtered = filtered.replacingOccurrences(
            of: creditCardPattern,
            with: "[CARD_REDACTED]",
            options: .regularExpression
        )

        // SSN
        filtered = filtered.replacingOccurrences(
            of: ssnPattern,
            with: "[SSN_REDACTED]",
            options: .regularExpression
        )

        // IP addresses
        filtered = filtered.replacingOccurrences(
            of: ipPattern,
            with: "[IP_REDACTED]",
            options: .regularExpression
        )

        return filtered
    }

    static func filterMetadata(_ metadata: [String: String]) -> [String: String] {
        var filtered: [String: String] = [:]

        for (key, value) in metadata {
            let lowerKey = key.lowercased()

            // Filter sensitive keys
            if lowerKey.contains("password") ||
               lowerKey.contains("token") ||
               lowerKey.contains("secret") ||
               lowerKey.contains("key") ||
               lowerKey.contains("auth") {
                filtered[key] = "[REDACTED]"
            } else {
                filtered[key] = filter(value)
            }
        }

        return filtered
    }
}

// MARK: - Error Logger

@MainActor
class ErrorLogger {

    // MARK: - Properties

    nonisolated static let shared = ErrorLogger()

    private let configuration: LogConfiguration
    private let logger = Logger(subsystem: "com.swiff", category: "ErrorLogger")
    private let logDirectory: URL
    private let currentLogFile: URL
    private var fileHandle: FileHandle?

    private var logQueue = DispatchQueue(label: "com.swiff.errorlogger", qos: .utility)
    private var logsWritten: Int64 = 0

    // MARK: - Initialization

    nonisolated init(configuration: LogConfiguration = .default) {
        self.configuration = configuration

        // Setup log directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.logDirectory = documentsPath.appendingPathComponent("Logs", isDirectory: true)

        // Current log file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        self.currentLogFile = logDirectory.appendingPathComponent("swiff-\(dateStr).log")

        // Perform initialization on the main actor
        Task { @MainActor in
            // Create log directory if needed
            self.createLogDirectoryIfNeeded()

            // Open current log file
            self.openLogFile()
        }
    }

    deinit {
        // Close file handle synchronously in deinit
        try? fileHandle?.close()
    }

    // MARK: - File Management

    private func createLogDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: logDirectory.path) {
            try? FileManager.default.createDirectory(
                at: logDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func openLogFile() {
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: currentLogFile.path) {
            FileManager.default.createFile(atPath: currentLogFile.path, contents: nil)
        }

        // Open file handle
        fileHandle = try? FileHandle(forWritingTo: currentLogFile)
        fileHandle?.seekToEndOfFile()

        // Get current file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: currentLogFile.path),
           let fileSize = attributes[.size] as? Int64 {
            logsWritten = fileSize
        }
    }

    private func closeLogFile() {
        try? fileHandle?.close()
        fileHandle = nil
    }

    private func rotateLogsIfNeeded() {
        guard logsWritten >= configuration.maxFileSize else { return }

        // Close current file
        closeLogFile()

        // Get all log files
        guard let logFiles = try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        // Sort by creation date (oldest first)
        let sortedFiles = logFiles.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 < date2
        }

        // Delete old files if exceeding max count
        if sortedFiles.count >= configuration.maxLogFiles {
            let filesToDelete = sortedFiles.prefix(sortedFiles.count - configuration.maxLogFiles + 1)
            for file in filesToDelete {
                try? FileManager.default.removeItem(at: file)
            }
        }

        // Reset and open new log file
        logsWritten = 0
        openLogFile()
    }

    // MARK: - Logging Methods

    func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String] = [:]
    ) {
        // Check if level is enabled
        guard level >= configuration.logLevel else { return }

        // Filter message and metadata for privacy
        let filteredMessage = configuration.privacyFilteringEnabled ? PrivacyFilter.filter(message) : message
        let filteredMetadata = configuration.privacyFilteringEnabled ? PrivacyFilter.filterMetadata(metadata) : metadata

        // Create log entry
        let entry = LogEntry(
            timestamp: Date(),
            level: level.displayName,
            message: filteredMessage,
            category: category,
            file: URL(fileURLWithPath: file).lastPathComponent,
            function: function,
            line: line,
            metadata: filteredMetadata
        )

        // Console logging
        if configuration.enableConsoleLogging {
            logToConsole(entry, level: level)
        }

        // File logging
        if configuration.enableFileLogging {
            logToFile(entry)
        }
    }

    private func logToConsole(_ entry: LogEntry, level: LogLevel) {
        let message = "\(level.icon) \(entry.formattedMessage)"

        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }

    private func logToFile(_ entry: LogEntry) {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            let message = entry.formattedMessage + "\n"
            guard let data = message.data(using: .utf8) else { return }

            // Write to file
            Task { @MainActor in
                self.fileHandle?.write(data)
                self.logsWritten += Int64(data.count)

                // Rotate if needed
                self.rotateLogsIfNeeded()
            }
        }
    }

    // MARK: - Convenience Methods

    func debug(_ message: String, category: String = "General", metadata: [String: String] = [:]) {
        log(message, level: .debug, category: category, metadata: metadata)
    }

    func info(_ message: String, category: String = "General", metadata: [String: String] = [:]) {
        log(message, level: .info, category: category, metadata: metadata)
    }

    func warning(_ message: String, category: String = "General", metadata: [String: String] = [:]) {
        log(message, level: .warning, category: category, metadata: metadata)
    }

    func error(_ message: String, category: String = "General", metadata: [String: String] = [:]) {
        log(message, level: .error, category: category, metadata: metadata)
    }

    func critical(_ message: String, category: String = "General", metadata: [String: String] = [:]) {
        log(message, level: .critical, category: category, metadata: metadata)
    }

    // MARK: - Error Logging

    func logError(_ error: Error, category: String = "Error", metadata: [String: String] = [:]) {
        var meta: [String: String] = metadata

        if let appError = error as? ApplicationError {
            meta["domain"] = appError.domain.rawValue
            meta["code"] = String(appError.code)
            meta["severity"] = appError.severity.displayName
            meta["retryable"] = String(appError.isRetryable)

            log(
                appError.localizedDescription,
                level: .error,
                category: category,
                metadata: meta
            )
        } else {
            meta["errorType"] = String(describing: type(of: error))

            log(
                error.localizedDescription,
                level: .error,
                category: category,
                metadata: meta
            )
        }
    }

    // MARK: - Performance Logging

    func logPerformance(
        operation: String,
        duration: TimeInterval,
        success: Bool,
        metadata: [String: String] = [:]
    ) {
        var meta = metadata
        meta["duration"] = String(format: "%.3f", duration)
        meta["success"] = String(success)

        let level: LogLevel = success ? .info : .warning

        log(
            "Performance: \(operation)",
            level: level,
            category: "Performance",
            metadata: meta
        )
    }

    // MARK: - Log Retrieval

    func getAllLogFiles() -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 > date2
        }
    }

    func readLogFile(_ url: URL) -> String? {
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func getLogFileSize(_ url: URL) -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }

    func getTotalLogsSize() -> Int64 {
        let files = getAllLogFiles()
        return files.reduce(Int64(0)) { $0 + getLogFileSize($1) }
    }

    // MARK: - Log Management

    func clearAllLogs() {
        closeLogFile()

        let files = getAllLogFiles()
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }

        logsWritten = 0
        openLogFile()
    }

    func exportLogs() -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        _ = tempDirectory.appendingPathComponent("swiff-logs-\(Date().timeIntervalSince1970).zip")

        // In a real implementation, you would zip the log files here
        // For now, we'll just return the log directory
        return logDirectory
    }

    // MARK: - Statistics

    func getStatistics() -> String {
        let files = getAllLogFiles()
        let totalSize = getTotalLogsSize()
        let sizeMB = Double(totalSize) / 1_048_576

        var stats = "=== Error Logger Statistics ===\n\n"
        stats += "Configuration:\n"
        stats += "  Log Level: \(configuration.logLevel.displayName)\n"
        stats += "  Max File Size: \(configuration.maxFileSize / 1_048_576) MB\n"
        stats += "  Max Files: \(configuration.maxLogFiles)\n"
        stats += "  Console Logging: \(configuration.enableConsoleLogging ? "Enabled" : "Disabled")\n"
        stats += "  File Logging: \(configuration.enableFileLogging ? "Enabled" : "Disabled")\n"
        stats += "  Privacy Filtering: \(configuration.privacyFilteringEnabled ? "Enabled" : "Disabled")\n\n"

        stats += "Current Status:\n"
        stats += "  Total Log Files: \(files.count)\n"
        stats += "  Total Size: \(String(format: "%.2f", sizeMB)) MB\n"
        stats += "  Current File Size: \(String(format: "%.2f", Double(logsWritten) / 1_048_576)) MB\n\n"

        stats += "Log Files:\n"
        for file in files {
            let size = getLogFileSize(file)
            let sizeMB = Double(size) / 1_048_576
            stats += "  \(file.lastPathComponent): \(String(format: "%.2f", sizeMB)) MB\n"
        }

        return stats
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Basic logging:
 ```swift
 let logger = ErrorLogger.shared

 logger.debug("Debug message")
 logger.info("Info message")
 logger.warning("Warning message")
 logger.error("Error message")
 logger.critical("Critical message")
 ```

 2. Log with metadata:
 ```swift
 logger.info("User logged in", category: "Authentication", metadata: [
     "userID": "12345",
     "method": "email"
 ])
 ```

 3. Log errors:
 ```swift
 do {
     try performOperation()
 } catch {
     logger.logError(error, category: "Database", metadata: [
         "operation": "insert",
         "table": "users"
     ])
 }
 ```

 4. Performance logging:
 ```swift
 let start = Date()
 performExpensiveOperation()
 let duration = Date().timeIntervalSince(start)

 logger.logPerformance(
     operation: "Data Export",
     duration: duration,
     success: true,
     metadata: ["rows": "1000"]
 )
 ```

 5. Retrieve logs:
 ```swift
 let logFiles = logger.getAllLogFiles()
 for file in logFiles {
     if let content = logger.readLogFile(file) {
         print(content)
     }
 }
 ```

 6. Get statistics:
 ```swift
 let stats = logger.getStatistics()
 print(stats)
 ```

 7. Clear logs:
 ```swift
 logger.clearAllLogs()
 ```

 8. Privacy filtering (automatic):
 ```swift
 // This will automatically redact sensitive data
 logger.info("User email: test@example.com") // Logs: "User email: [EMAIL_REDACTED]"
 logger.info("Phone: +1234567890") // Logs: "Phone: [PHONE_REDACTED]"
 ```
 */
