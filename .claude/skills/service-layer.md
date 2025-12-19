# Service Layer Patterns

## Purpose
Guide the implementation of service classes following established project patterns for business logic, data management, and cross-cutting concerns.

## When to Use This Skill
- Creating new services
- Modifying existing service layer code
- Understanding service responsibilities
- Implementing async operations and caching

---

## Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      DataManager                             │
│              (Central Orchestration)                         │
└─────────────────────────────────────────────────────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Persistence  │ │ Notification │ │  Analytics   │ │   Backup     │
│   Service    │ │   Manager    │ │   Service    │ │   Service    │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

---

## Core Service Pattern

### Standard Service Template

```swift
import Foundation
import Combine

@MainActor
class ExampleService: ObservableObject {

    // MARK: - Singleton
    static let shared = ExampleService()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error?
    @Published var data: [SomeType] = []

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let cache = NSCache<NSString, CachedData>()

    // MARK: - Initialization
    private init() {
        setupBindings()
    }

    // MARK: - Public Methods
    func fetchData() async throws -> [SomeType] {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await performFetch()
            self.data = result
            return result
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Private Methods
    private func performFetch() async throws -> [SomeType] {
        // Implementation
    }

    private func setupBindings() {
        // Combine subscriptions
    }
}
```

---

## Project Services Reference

### 1. DataManager - Central State Management

**Location:** `Services/DataManager.swift`

**Responsibilities:**
- Single source of truth for app data
- CRUD operations via PersistenceService
- Computed analytics and statistics
- Coordinates other services

```swift
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var people: [Person] = []
    @Published var subscriptions: [Subscription] = []
    @Published var transactions: [Transaction] = []
    @Published var groups: [Group] = []

    @Published var isLoading = false
    @Published var error: Error?

    private let persistenceService = PersistenceService.shared
    private let renewalService = SubscriptionRenewalService.shared

    func loadAllData() {
        isLoading = true
        do {
            people = try persistenceService.fetchAllPeople()
            subscriptions = try persistenceService.fetchAllSubscriptions()
            transactions = try persistenceService.fetchAllTransactions()
            groups = try persistenceService.fetchAllGroups()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    func addSubscription(_ subscription: Subscription) throws {
        try persistenceService.saveSubscription(subscription)
        subscriptions.append(subscription)

        // Coordinate with notification service
        Task {
            await NotificationManager.shared.updateScheduledReminders(for: subscription)
        }
    }
}
```

### 2. PersistenceService - Data Access Layer

**Location:** `Services/PersistenceService.swift`

**Responsibilities:**
- SwiftData ModelContainer management
- CRUD operations for all entities
- Schema validation and migration
- Data validation

```swift
@MainActor
class PersistenceService {
    static let shared = PersistenceService()

    private(set) var modelContainer: ModelContainer!

    private var modelContext: ModelContext {
        return modelContainer.mainContext
    }

    // Schema definition
    static let appSchema = Schema([
        PersonModel.self,
        GroupModel.self,
        SubscriptionModel.self,
        TransactionModel.self,
        PriceChangeModel.self
    ])

    private init() {
        do {
            self.modelContainer = try Self.createModelContainer()
        } catch {
            // Fallback to in-memory
            self.modelContainer = try! Self.createInMemoryContainer()
        }
    }

    func saveSubscription(_ subscription: Subscription) throws {
        try validateSubscription(subscription)

        let descriptor = FetchDescriptor<SubscriptionModel>(
            predicate: #Predicate { $0.id == subscription.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            // Update existing
            existing.name = subscription.name
            existing.price = subscription.price
            // ...
        } else {
            // Create new
            let model = SubscriptionModel(from: subscription)
            modelContext.insert(model)
        }

        try saveContext()
    }

    private func validateSubscription(_ subscription: Subscription) throws {
        guard !subscription.name.isEmpty else {
            throw PersistenceError.validationFailed(reason: "Name cannot be empty")
        }
        guard subscription.price > 0 else {
            throw PersistenceError.validationFailed(reason: "Price must be positive")
        }
    }
}
```

### 3. AnalyticsService - Business Intelligence

**Location:** `Services/AnalyticsService.swift`

**Responsibilities:**
- Spending trend calculations
- Forecasting
- Category breakdowns
- Caching for performance

```swift
@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published var spendingTrends: [SpendingTrend] = []
    @Published var categoryBreakdown: [CategorySpending] = []

    // Cache with 5-minute expiry
    private var cache: [String: CachedResult] = [:]
    private let cacheTimeout: TimeInterval = 300

    func calculateMonthlySpending(months: Int = 6) -> [MonthlySpending] {
        let cacheKey = "monthly_spending_\(months)"

        if let cached = cache[cacheKey], !cached.isExpired {
            return cached.value as! [MonthlySpending]
        }

        let result = performCalculation(months: months)
        cache[cacheKey] = CachedResult(value: result, expiry: Date().addingTimeInterval(cacheTimeout))

        return result
    }

    func invalidateCache() {
        cache.removeAll()
    }
}
```

### 4. NotificationManager - Local Notifications

**Location:** `Services/NotificationManager.swift`

**Responsibilities:**
- Permission management
- Scheduling renewal reminders
- Notification categories and actions
- Foreground handling

```swift
@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        await updateAuthorizationStatus()
        return granted
    }

    func scheduleRenewalReminder(for subscription: Subscription) async {
        guard subscription.enableRenewalReminder else { return }

        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewal"
        content.body = "\(subscription.name) renews in \(subscription.reminderDaysBefore) days"
        content.categoryIdentifier = "SUBSCRIPTION_RENEWAL"

        let triggerDate = Calendar.current.date(
            byAdding: .day,
            value: -subscription.reminderDaysBefore,
            to: subscription.nextBillingDate
        )!

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "renewal_\(subscription.id)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
```

### 5. BiometricAuthenticationService - Security

**Location:** `Services/BiometricAuthenticationService.swift`

```swift
import LocalAuthentication

@MainActor
class BiometricAuthenticationService: ObservableObject {
    static let shared = BiometricAuthenticationService()

    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticated = false

    enum BiometricType {
        case none, faceID, touchID
    }

    private init() {
        checkBiometricAvailability()
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: biometricType = .faceID
            case .touchID: biometricType = .touchID
            default: biometricType = .none
            }
        } else {
            biometricType = .none
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            await MainActor.run { isAuthenticated = success }
            return success
        } catch {
            throw error
        }
    }
}
```

---

## Async/Await Patterns

### Basic Async Operation

```swift
func fetchData() async throws -> [Item] {
    isLoading = true
    defer { isLoading = false }

    return try await withCheckedThrowingContinuation { continuation in
        // Legacy callback-based API
        legacyAPI.fetch { result in
            switch result {
            case .success(let items):
                continuation.resume(returning: items)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

### Parallel Operations

```swift
func loadDashboardData() async throws -> DashboardData {
    async let subscriptions = persistenceService.fetchAllSubscriptions()
    async let transactions = persistenceService.fetchAllTransactions()
    async let analytics = analyticsService.calculateTrends()

    return try await DashboardData(
        subscriptions: subscriptions,
        transactions: transactions,
        analytics: analytics
    )
}
```

### Task Management

```swift
class DataManager {
    private var loadTask: Task<Void, Never>?

    func loadData() {
        // Cancel previous task
        loadTask?.cancel()

        loadTask = Task {
            guard !Task.isCancelled else { return }

            isLoading = true
            do {
                let data = try await fetchData()
                guard !Task.isCancelled else { return }
                self.data = data
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
            }
            isLoading = false
        }
    }
}
```

---

## Caching Strategies

### Time-Based Cache

```swift
struct CachedResult<T> {
    let value: T
    let timestamp: Date
    let timeout: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > timeout
    }
}

class CachingService {
    private var cache: [String: CachedResult<Any>] = [:]

    func get<T>(_ key: String) -> T? {
        guard let cached = cache[key] as? CachedResult<T>,
              !cached.isExpired else {
            return nil
        }
        return cached.value
    }

    func set<T>(_ key: String, value: T, timeout: TimeInterval = 300) {
        cache[key] = CachedResult(value: value, timestamp: Date(), timeout: timeout)
    }

    func invalidate(_ key: String) {
        cache.removeValue(forKey: key)
    }
}
```

---

## Debouncing Pattern

```swift
// Services/Debouncer.swift
actor Debouncer {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func debounce(_ action: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}

// Usage in DataManager
class DataManager {
    private var saveDebouncer: [UUID: Debouncer] = [:]

    func scheduleSave(for subscription: Subscription, delay: TimeInterval = 0.5) {
        if saveDebouncer[subscription.id] == nil {
            saveDebouncer[subscription.id] = Debouncer(delay: delay)
        }

        saveDebouncer[subscription.id]?.debounce {
            do {
                try await self.updateSubscription(subscription)
            } catch {
                self.error = error
            }
        }
    }
}
```

---

## Error Handling in Services

```swift
func performOperation() throws {
    do {
        try riskyOperation()
    } catch let error as PersistenceError {
        // Re-throw domain errors
        throw error
    } catch {
        // Wrap unknown errors
        throw PersistenceError.saveFailed(underlying: error)
    }
}
```

---

## Common Mistakes to Avoid

1. **Not using @MainActor for UI-bound services**
2. **Creating multiple instances instead of singleton**
3. **Blocking main thread with sync operations**
4. **Not handling task cancellation**
5. **Memory leaks from uncancelled subscriptions**

---

## Checklist

- [ ] Service uses `@MainActor` annotation
- [ ] Singleton pattern with `static let shared`
- [ ] Private init to prevent multiple instances
- [ ] `@Published` properties for reactive state
- [ ] Async/await for long-running operations
- [ ] Proper error handling and propagation
- [ ] Cache invalidation strategy (if caching)
- [ ] Task cancellation support

---

## Industry Standards

- **Swift Concurrency** - WWDC 2021-2024
- **Combine Framework** - Apple Documentation
- **Service-Oriented Architecture** principles
- **Repository Pattern** for data access
