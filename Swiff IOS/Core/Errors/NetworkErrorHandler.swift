//
//  NetworkErrorHandler.swift
//  Swiff IOS
//
//  Created by Claude Code on 11/20/25.
//  Phase 5.4: Comprehensive network error handling
//

import Combine
import Foundation
import Network
import SystemConfiguration

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case offline
    case timeout
    case serverError(statusCode: Int)
    case clientError(statusCode: Int)
    case invalidResponse
    case invalidURL
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case connectionLost
    case dnsLookupFailed
    case sslError
    case requestCancelled
    case rateLimitExceeded
    case maintenanceMode
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "Request timed out. The server took too long to respond."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .clientError(let code):
            return "Request error (\(code)). Please check your request."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidURL:
            return "Invalid URL provided."
        case .decodingFailed:
            return "Failed to decode server response."
        case .encodingFailed:
            return "Failed to encode request data."
        case .connectionLost:
            return "Connection lost. Please check your internet connection."
        case .dnsLookupFailed:
            return "Failed to resolve server address."
        case .sslError:
            return "Secure connection failed. Please check your security settings."
        case .requestCancelled:
            return "Request was cancelled."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .maintenanceMode:
            return "Service is under maintenance. Please try again later."
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .offline:
            return "Turn on WiFi or cellular data in Settings."
        case .timeout:
            return "Check your internet connection and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .clientError:
            return "Check the request parameters and try again."
        case .invalidResponse:
            return "Contact support if this persists."
        case .invalidURL:
            return "Contact support to report this issue."
        case .decodingFailed:
            return "The app may need an update. Check the App Store."
        case .encodingFailed:
            return "Check your input data and try again."
        case .connectionLost:
            return "Move to an area with better signal."
        case .dnsLookupFailed:
            return "Check your DNS settings or try a different network."
        case .sslError:
            return "Check your device's date and time settings."
        case .requestCancelled:
            return "Restart the operation if needed."
        case .rateLimitExceeded:
            return "Wait 60 seconds before trying again."
        case .maintenanceMode:
            return "Check back in a few minutes."
        case .unknown:
            return "Try again or contact support if the issue persists."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .offline, .timeout, .serverError, .connectionLost, .dnsLookupFailed:
            return true
        case .clientError, .invalidURL, .decodingFailed, .encodingFailed, .requestCancelled:
            return false
        case .invalidResponse, .sslError, .rateLimitExceeded, .maintenanceMode, .unknown:
            return true
        }
    }
}

// MARK: - Network Status

enum NetworkStatus {
    case connected
    case disconnected
    case unknown

    var isConnected: Bool {
        return self == .connected
    }
}

// MARK: - Network Connection Type

enum NetworkConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown

    var displayName: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Retry Configuration

struct NetworkRetryConfiguration: Sendable {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    static let `default` = NetworkRetryConfiguration(
        maxRetries: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    static let aggressive = NetworkRetryConfiguration(
        maxRetries: 5,
        baseDelay: 0.5,
        maxDelay: 5.0,
        multiplier: 1.5
    )

    static let conservative = NetworkRetryConfiguration(
        maxRetries: 2,
        baseDelay: 2.0,
        maxDelay: 15.0,
        multiplier: 3.0
    )

    nonisolated func delay(forAttempt attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Network Request Result

struct NetworkRequestResult<T> {
    let data: T?
    let statusCode: Int?
    let error: NetworkError?
    let retryCount: Int
    let totalDuration: TimeInterval

    var isSuccess: Bool {
        return error == nil && data != nil
    }

    var summary: String {
        if isSuccess {
            return
                "✅ Success after \(retryCount) retries in \(String(format: "%.2f", totalDuration))s"
        } else {
            return
                "❌ Failed after \(retryCount) retries in \(String(format: "%.2f", totalDuration))s"
        }
    }
}

// MARK: - Network Error Handler

@MainActor
class NetworkErrorHandler: ObservableObject {

    // MARK: - Properties

    static let shared = NetworkErrorHandler()

    @Published var isConnected: Bool = true
    @Published var connectionType: NetworkConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.swiff.networkmonitor")

    private var retryConfiguration = NetworkRetryConfiguration.default

    // MARK: - Initialization

    nonisolated init() {
        Task { @MainActor in
            self.startMonitoring()
        }
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitoring

    /// Start monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = path.status == .satisfied
                self.connectionType = self.detectConnectionType(from: path)
            }
        }

        monitor.start(queue: monitorQueue)
    }

    /// Stop monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }

    /// Get current network status
    func getNetworkStatus() -> NetworkStatus {
        return isConnected ? .connected : .disconnected
    }

    /// Detect connection type from NWPath
    private func detectConnectionType(from path: NWPath) -> NetworkConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }

    // MARK: - Error Classification

    /// Classify URLError into NetworkError
    nonisolated func classifyError(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return .offline
            case .timedOut:
                return .timeout
            case .networkConnectionLost:
                return .connectionLost
            case .cannotFindHost, .dnsLookupFailed:
                return .dnsLookupFailed
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return .sslError
            case .cancelled:
                return .requestCancelled
            case .badURL:
                return .invalidURL
            default:
                return .unknown(underlying: error)
            }
        }

        if let decodingError = error as? DecodingError {
            return .decodingFailed(underlying: decodingError)
        }

        if let encodingError = error as? EncodingError {
            return .encodingFailed(underlying: encodingError)
        }

        return .unknown(underlying: error)
    }

    /// Classify HTTP status code
    nonisolated func classifyStatusCode(_ statusCode: Int) -> NetworkError? {
        switch statusCode {
        case 200...299:
            return nil  // Success
        case 400...499:
            if statusCode == 429 {
                return .rateLimitExceeded
            }
            return .clientError(statusCode: statusCode)
        case 500...599:
            if statusCode == 503 {
                return .maintenanceMode
            }
            return .serverError(statusCode: statusCode)
        default:
            return .invalidResponse
        }
    }

    // MARK: - Retry Logic

    /// Perform request with automatic retry
    nonisolated func performWithRetry<T>(
        retryConfig: NetworkRetryConfiguration = .default,
        operation: @escaping () async throws -> T
    ) async throws -> NetworkRequestResult<T> {
        let startTime = Date()
        var lastError: NetworkError?
        var retryCount = 0

        for attempt in 1...(retryConfig.maxRetries + 1) {
            retryCount = attempt - 1

            do {
                let result = try await operation()
                let duration = Date().timeIntervalSince(startTime)

                return NetworkRequestResult(
                    data: result,
                    statusCode: nil,
                    error: nil,
                    retryCount: retryCount,
                    totalDuration: duration
                )

            } catch {
                let networkError = classifyError(error)
                lastError = networkError

                // Don't retry if error is not retryable
                if !networkError.isRetryable {
                    break
                }

                // Don't retry if this was the last attempt
                if attempt > retryConfig.maxRetries {
                    break
                }

                // Wait before retrying
                let delay = retryConfig.delay(forAttempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        return NetworkRequestResult(
            data: nil,
            statusCode: nil,
            error: lastError,
            retryCount: retryCount,
            totalDuration: duration
        )
    }

    /// Perform HTTP request with retry and error handling
    nonisolated func performHTTPRequest<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30,
        retryConfig: NetworkRetryConfiguration = .default
    ) async throws -> NetworkRequestResult<T> {
        let startTime = Date()
        var lastError: NetworkError?
        var lastStatusCode: Int?
        var retryCount = 0

        for attempt in 1...(retryConfig.maxRetries + 1) {
            retryCount = attempt - 1

            do {
                // Check if offline
                let connected = await MainActor.run { isConnected }
                if !connected {
                    throw NetworkError.offline
                }

                // Create request
                var request = URLRequest(url: url, timeoutInterval: timeout)
                request.httpMethod = method
                request.httpBody = body

                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }

                // Perform request
                let (data, response) = try await URLSession.shared.data(for: request)

                // Check HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                lastStatusCode = httpResponse.statusCode

                // Check status code
                if let error = classifyStatusCode(httpResponse.statusCode) {
                    throw error
                }

                // Decode response
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(T.self, from: data)

                let duration = Date().timeIntervalSince(startTime)

                return NetworkRequestResult(
                    data: decoded,
                    statusCode: httpResponse.statusCode,
                    error: nil,
                    retryCount: retryCount,
                    totalDuration: duration
                )

            } catch {
                let networkError: NetworkError
                if let netError = error as? NetworkError {
                    networkError = netError
                } else {
                    networkError = classifyError(error)
                }

                lastError = networkError

                // Don't retry if error is not retryable
                if !networkError.isRetryable {
                    break
                }

                // Don't retry if this was the last attempt
                if attempt > retryConfig.maxRetries {
                    break
                }

                // Wait before retrying
                let delay = retryConfig.delay(forAttempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        return NetworkRequestResult(
            data: nil,
            statusCode: lastStatusCode,
            error: lastError,
            retryCount: retryCount,
            totalDuration: duration
        )
    }

    // MARK: - Timeout Handling

    /// Execute operation with timeout
    func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add operation task
            group.addTask {
                return try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NetworkError.timeout
            }

            // Return first result
            let result = try await group.next()!

            // Cancel remaining tasks
            group.cancelAll()

            return result
        }
    }

    // MARK: - Connectivity Check

    /// Check if we can reach a specific host
    func canReachHost(_ host: String) async -> Bool {
        guard let url = URL(string: "https://\(host)") else {
            return false
        }

        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.httpMethod = "HEAD"

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }

            return false
        } catch {
            return false
        }
    }

    /// Check internet connectivity by pinging common servers
    func checkInternetConnectivity() async -> Bool {
        let hosts = ["www.google.com", "www.apple.com", "www.cloudflare.com"]

        for host in hosts {
            if await canReachHost(host) {
                return true
            }
        }

        return false
    }

    // MARK: - Error Feedback

    /// Get user-friendly error message
    func getUserFriendlyMessage(for error: NetworkError) -> String {
        return error.errorDescription ?? "Network error occurred"
    }

    /// Get recovery suggestion
    func getRecoverySuggestion(for error: NetworkError) -> String? {
        return error.recoverySuggestion
    }

    /// Should show retry button
    func shouldShowRetry(for error: NetworkError) -> Bool {
        return error.isRetryable
    }

    // MARK: - Statistics

    /// Get network statistics summary
    func getNetworkStatistics() -> String {
        var stats = "=== Network Statistics ===\n\n"
        stats += "Status: \(isConnected ? "✅ Connected" : "❌ Disconnected")\n"
        stats += "Connection Type: \(connectionType.displayName)\n"

        return stats
    }
}

// MARK: - Usage Examples (Documentation)

/*
 USAGE EXAMPLES:

 1. Perform request with automatic retry:
 ```swift
 let handler = NetworkErrorHandler.shared

 let result = try await handler.performWithRetry { () -> [String] in
     // Your network operation here
     let data = try await fetchData()
     return data
 }

 if result.isSuccess {
     print(result.summary)
     // Use result.data
 } else {
     print("Error: \(result.error?.localizedDescription ?? "Unknown")")
 }
 ```

 2. Perform HTTP request with retry:
 ```swift
 struct User: Codable {
     let id: Int
     let name: String
 }

 let url = URL(string: "https://api.example.com/users")!

 let result: NetworkRequestResult<User> = try await handler.performHTTPRequest(
     url: url,
     method: "GET",
     timeout: 30
 )

 if let user = result.data {
     print("User: \(user.name)")
 } else if let error = result.error {
     print("Error: \(error.localizedDescription)")
 }
 ```

 3. Execute with timeout:
 ```swift
 do {
     let data = try await handler.withTimeout(seconds: 10) {
         return try await performLongOperation()
     }
 } catch NetworkError.timeout {
     print("Operation timed out")
 }
 ```

 4. Monitor network status in SwiftUI:
 ```swift
 struct ContentView: View {
     @StateObject private var networkHandler = NetworkErrorHandler.shared

     var body: some View {
         VStack {
             if networkHandler.isConnected {
                 Text("✅ Connected via \(networkHandler.connectionType.displayName)")
             } else {
                 Text("❌ No Internet Connection")
                     .foregroundColor(.red)
             }
         }
     }
 }
 ```

 5. Check connectivity:
 ```swift
 let isOnline = await handler.checkInternetConnectivity()

 if !isOnline {
     showOfflineAlert()
 }
 ```

 6. Custom retry configuration:
 ```swift
 let config = NetworkRetryConfiguration(
     maxRetries: 5,
     baseDelay: 0.5,
     maxDelay: 5.0,
     multiplier: 1.5
 )

 let result = try await handler.performWithRetry(retryConfig: config) {
     return try await fetchCriticalData()
 }
 ```

 7. Classify and handle errors:
 ```swift
 do {
     let data = try await fetchData()
 } catch {
     let networkError = handler.classifyError(error)

     let message = handler.getUserFriendlyMessage(for: networkError)
     let suggestion = handler.getRecoverySuggestion(for: networkError)

     showAlert(message: message, suggestion: suggestion)

     if handler.shouldShowRetry(for: networkError) {
         showRetryButton()
     }
 }
 ```
 */
