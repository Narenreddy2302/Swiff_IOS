# Error Handling Strategies

## Purpose
Ensure robust error handling throughout the application with consistent patterns, meaningful error messages, and appropriate recovery strategies.

## When to Use This Skill
- Implementing error handling in new code
- Creating custom error types
- Reviewing error propagation
- Adding user-facing error messages
- Implementing retry logic

---

## Error Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ApplicationError                          │
│              (Protocol for all app errors)                   │
└─────────────────────────────────────────────────────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Database    │ │  Validation  │ │  Network     │ │  Permission  │
│    Error     │ │    Error     │ │    Error     │ │    Error     │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

---

## Error Domain Hierarchy

### Error Domains

```swift
// Utilities/ComprehensiveErrorTypes.swift
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
```

### Error Severity Levels

```swift
enum ErrorSeverity: Int, Comparable {
    case info = 0      // Informational, no action needed
    case warning = 1   // Non-blocking issue
    case error = 2     // Operation failed, user should know
    case critical = 3  // Major functionality broken
    case fatal = 4     // App cannot continue

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

    static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

---

## Error Context

```swift
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
            DeviceInfo(
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
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.additionalInfo = additionalInfo
    }
}
```

---

## Domain-Specific Errors

### Persistence Errors

```swift
// Services/PersistenceService.swift
enum PersistenceError: LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case entityNotFound(id: UUID)
    case validationFailed(reason: String)
    case contextError
    case relationshipError(reason: String)
    case migrationFailed(underlying: Error)
    case containerCreationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .entityNotFound(let id):
            return "Entity with ID \(id) not found"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .contextError:
            return "Database context error"
        case .relationshipError(let reason):
            return "Relationship error: \(reason)"
        case .migrationFailed(let error):
            return "Data migration failed: \(error.localizedDescription)"
        case .containerCreationFailed(let error):
            return "Failed to create database: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .updateFailed:
            return "Please try again. If the problem persists, restart the app."
        case .entityNotFound:
            return "The item may have been deleted. Please refresh and try again."
        case .validationFailed:
            return "Please check your input and try again."
        case .migrationFailed:
            return "Your data may need to be restored from a backup."
        default:
            return nil
        }
    }
}
```

### Network Errors

```swift
// Utilities/NetworkErrorHandler.swift
enum NetworkError: LocalizedError {
    case offline
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    case decodingFailed(underlying: Error)
    case sslError
    case rateLimited(retryAfter: TimeInterval?)
    case maintenanceMode
    case dnsFailure

    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingFailed:
            return "Failed to process response"
        case .sslError:
            return "Secure connection failed"
        case .rateLimited:
            return "Too many requests"
        case .maintenanceMode:
            return "Service under maintenance"
        case .dnsFailure:
            return "Cannot reach server"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .offline, .timeout, .rateLimited, .maintenanceMode:
            return true
        case .serverError(let code):
            return code >= 500
        default:
            return false
        }
    }
}
```

### Validation Errors

```swift
enum ValidationError: LocalizedError {
    case emptyField(fieldName: String)
    case invalidFormat(fieldName: String, expected: String)
    case outOfRange(fieldName: String, min: Double?, max: Double?)
    case invalidEmail
    case invalidPhone
    case invalidURL
    case duplicateEntry(fieldName: String)

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidFormat(let field, let expected):
            return "\(field) must be in \(expected) format"
        case .outOfRange(let field, let min, let max):
            if let min = min, let max = max {
                return "\(field) must be between \(min) and \(max)"
            } else if let min = min {
                return "\(field) must be at least \(min)"
            } else if let max = max {
                return "\(field) must be at most \(max)"
            }
            return "\(field) is out of range"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPhone:
            return "Please enter a valid phone number"
        case .invalidURL:
            return "Please enter a valid URL"
        case .duplicateEntry(let field):
            return "A \(field) with this value already exists"
        }
    }
}
```

---

## Error Handling Patterns

### Try-Catch with Re-throw

```swift
func saveSubscription(_ subscription: Subscription) throws {
    // Validate first
    try validateSubscription(subscription)

    do {
        let model = SubscriptionModel(from: subscription)
        modelContext.insert(model)
        try modelContext.save()
    } catch let error as PersistenceError {
        // Re-throw domain errors directly
        throw error
    } catch {
        // Wrap unknown errors
        throw PersistenceError.saveFailed(underlying: error)
    }
}
```

### Async Error Handling

```swift
func loadData() async throws -> [Subscription] {
    isLoading = true
    defer { isLoading = false }

    do {
        let data = try await fetchFromDatabase()
        return data
    } catch {
        self.error = error
        throw error
    }
}
```

### Error Recovery

```swift
func performOperationWithRecovery() async {
    do {
        try await riskyOperation()
    } catch let error as PersistenceError {
        switch error {
        case .entityNotFound:
            // Refresh data and retry
            await refreshData()
            try? await riskyOperation()

        case .validationFailed:
            // Show validation error to user
            showValidationError(error)

        default:
            // Show generic error
            showError(error)
        }
    } catch {
        showError(error)
    }
}
```

---

## Error Logging

```swift
// Utilities/ErrorLogger.swift
class ErrorLogger {
    static let shared = ErrorLogger()

    enum LogLevel: Int {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4
    }

    private let fileManager = FileManager.default
    private let logDirectory: URL
    private let maxFileSize: Int = 5 * 1024 * 1024 // 5MB
    private let maxFiles: Int = 5

    func log(
        _ message: String,
        level: LogLevel,
        error: Error? = nil,
        context: ErrorContext? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent

        var logEntry = "[\(timestamp)] [\(level)] [\(fileName):\(line)] \(function): \(message)"

        if let error = error {
            logEntry += "\n  Error: \(error.localizedDescription)"
        }

        if let context = context {
            logEntry += "\n  Context: \(context.deviceInfo.model) iOS \(context.deviceInfo.systemVersion)"
        }

        // Console output
        print(logEntry)

        // File output (production)
        appendToLogFile(logEntry)
    }

    func logError(_ error: Error, context: ErrorContext? = nil) {
        log(
            error.localizedDescription,
            level: .error,
            error: error,
            context: context
        )
    }

    private func appendToLogFile(_ entry: String) {
        // Implementation for file logging with rotation
    }

    // Privacy filtering
    private func sanitize(_ text: String) -> String {
        var result = text

        // Redact email addresses
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        result = result.replacingOccurrences(
            of: emailPattern,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )

        // Redact phone numbers
        let phonePattern = "\\+?\\d{10,}"
        result = result.replacingOccurrences(
            of: phonePattern,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )

        return result
    }
}
```

---

## User-Facing Error UI

### Error State View

```swift
struct ErrorStateView: View {
    let error: Error
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(iconColor)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if let suggestion = recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let retry = retryAction, isRetryable {
                Button("Try Again", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var iconName: String {
        if let appError = error as? PersistenceError {
            return "exclamationmark.triangle"
        } else if error is NetworkError {
            return "wifi.slash"
        }
        return "xmark.circle"
    }

    private var iconColor: Color {
        .orange
    }

    private var title: String {
        "Something went wrong"
    }

    private var message: String {
        error.localizedDescription
    }

    private var recoverySuggestion: String? {
        (error as? PersistenceError)?.recoverySuggestion
    }

    private var isRetryable: Bool {
        (error as? NetworkError)?.isRetryable ?? true
    }
}
```

### Toast Error Display

```swift
struct ErrorToast: View {
    let error: Error
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.subheadline)

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
        .padding()
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
```

---

## Retry Logic

```swift
// Utilities/RetryMechanismManager.swift
actor RetryManager {
    func withRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        backoffMultiplier: Double = 2.0,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var currentDelay = delay

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Check if error is retryable
                if let networkError = error as? NetworkError, !networkError.isRetryable {
                    throw error
                }

                if attempt < maxAttempts {
                    // Add jitter to prevent thundering herd
                    let jitter = Double.random(in: 0...0.3) * currentDelay
                    try await Task.sleep(nanoseconds: UInt64((currentDelay + jitter) * 1_000_000_000))
                    currentDelay *= backoffMultiplier
                }
            }
        }

        throw lastError ?? NSError(domain: "RetryManager", code: -1)
    }
}
```

---

## Common Mistakes to Avoid

1. **Swallowing errors silently**
   ```swift
   // BAD
   try? riskyOperation()

   // GOOD
   do {
       try riskyOperation()
   } catch {
       ErrorLogger.shared.logError(error)
       showError(error)
   }
   ```

2. **Generic error messages**
   ```swift
   // BAD
   throw NSError(domain: "", code: -1, userInfo: nil)

   // GOOD
   throw PersistenceError.validationFailed(reason: "Name cannot be empty")
   ```

3. **Not providing recovery suggestions**

4. **Logging sensitive data in errors**

---

## Checklist

- [ ] Error type implements `LocalizedError`
- [ ] `errorDescription` provides clear message
- [ ] `recoverySuggestion` helps user recover
- [ ] Errors are logged appropriately
- [ ] Sensitive data is redacted from logs
- [ ] User-facing UI handles errors gracefully
- [ ] Retry logic for transient failures

---

## Industry Standards

- **Swift Error Handling** - Apple Documentation
- **OWASP** - Secure error handling guidelines
- **Logging best practices** - No PII in logs
- **User experience** - Actionable error messages
