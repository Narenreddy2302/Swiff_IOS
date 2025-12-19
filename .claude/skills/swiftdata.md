# SwiftData Persistence Patterns

## Purpose
Guide SwiftData model design, persistence operations, schema management, and migration strategies following Apple's best practices and project conventions.

## When to Use This Skill
- Creating new data models
- Implementing CRUD operations
- Managing schema migrations
- Optimizing database queries
- Understanding the dual-model architecture

---

## SwiftData Overview

SwiftData is Apple's modern persistence framework (iOS 17+) that provides:
- Declarative model definitions with `@Model`
- Automatic persistence and sync
- Type-safe queries with `#Predicate`
- Migration support

---

## Dual Model Architecture

### Why Two Model Types?

The project separates:
- **Domain Models** (DataModels/) - For business logic and UI
- **Persistence Models** (SwiftDataModels/) - For SwiftData storage

This separation provides:
- Clean Codable conformance for domain models
- Flexibility to change persistence without affecting business logic
- Clear conversion boundaries

### Model Relationship

```
┌─────────────────────────────────────────────────────────────┐
│                    Domain Model                              │
│  struct Subscription: Identifiable, Codable, Hashable        │
│  - Used in views, business logic, JSON serialization         │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ toDomain() / init(from:)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  SwiftData Model                             │
│  @Model class SubscriptionModel                              │
│  - Used for SwiftData persistence only                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Domain Model (DataModels/)

```swift
// Models/DataModels/Subscription.swift
struct Subscription: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var price: Double
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var icon: String
    var color: String
    var nextBillingDate: Date
    var isActive: Bool = true
    var isShared: Bool = false
    var sharedWith: [UUID] = []
    var notes: String = ""
    var website: String = ""
    var totalSpent: Double = 0

    // Trial tracking
    var isFreeTrial: Bool = false
    var trialStartDate: Date?
    var trialEndDate: Date?
    var willConvertToPaid: Bool = false

    // Reminder settings
    var enableRenewalReminder: Bool = true
    var reminderDaysBefore: Int = 3
}

// Supporting enums
enum BillingCycle: String, Codable, CaseIterable {
    case daily, weekly, biweekly, monthly
    case quarterly, semiAnnually, yearly, annually, lifetime

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnually: return "Semi-annually"
        case .yearly, .annually: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
}

enum SubscriptionCategory: String, Codable, CaseIterable {
    case entertainment, productivity, health, education
    case news, utilities, gaming, other

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .entertainment: return "tv.fill"
        case .productivity: return "briefcase.fill"
        case .health: return "heart.fill"
        // ...
        }
    }
}
```

---

## SwiftData Model (SwiftDataModels/)

```swift
// Models/SwiftDataModels/SubscriptionModel.swift
import SwiftData

@Model
final class SubscriptionModel {
    // MARK: - Primary Key
    @Attribute(.unique) var id: UUID

    // MARK: - Basic Properties
    var name: String
    var subscriptionDescription: String  // 'description' is reserved
    var price: Double
    var icon: String
    var color: String
    var nextBillingDate: Date
    var isActive: Bool
    var isShared: Bool
    var notes: String
    var website: String
    var totalSpent: Double

    // MARK: - Enum Storage (as raw values)
    var billingCycleRaw: String
    var categoryRaw: String

    // MARK: - Array Storage
    var sharedWithIDs: [UUID]

    // MARK: - Trial Properties
    var isFreeTrial: Bool
    var trialStartDate: Date?
    var trialEndDate: Date?
    var willConvertToPaid: Bool

    // MARK: - Reminder Properties
    var enableRenewalReminder: Bool
    var reminderDaysBefore: Int

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade)
    var sharedSubscriptions: [SharedSubscriptionModel]?

    // MARK: - Initialization
    init() {
        self.id = UUID()
        self.name = ""
        self.subscriptionDescription = ""
        self.price = 0
        self.billingCycleRaw = BillingCycle.monthly.rawValue
        self.categoryRaw = SubscriptionCategory.other.rawValue
        self.icon = "star.fill"
        self.color = "#007AFF"
        self.nextBillingDate = Date()
        self.isActive = true
        self.isShared = false
        self.sharedWithIDs = []
        self.notes = ""
        self.website = ""
        self.totalSpent = 0
        self.isFreeTrial = false
        self.willConvertToPaid = false
        self.enableRenewalReminder = true
        self.reminderDaysBefore = 3
    }

    // MARK: - Conversion from Domain Model
    convenience init(from subscription: Subscription) {
        self.init()
        self.id = subscription.id
        self.name = subscription.name
        self.subscriptionDescription = subscription.description
        self.price = subscription.price
        self.billingCycleRaw = subscription.billingCycle.rawValue
        self.categoryRaw = subscription.category.rawValue
        self.icon = subscription.icon
        self.color = subscription.color
        self.nextBillingDate = subscription.nextBillingDate
        self.isActive = subscription.isActive
        self.isShared = subscription.isShared
        self.sharedWithIDs = subscription.sharedWith
        self.notes = subscription.notes
        self.website = subscription.website
        self.totalSpent = subscription.totalSpent
        self.isFreeTrial = subscription.isFreeTrial
        self.trialStartDate = subscription.trialStartDate
        self.trialEndDate = subscription.trialEndDate
        self.willConvertToPaid = subscription.willConvertToPaid
        self.enableRenewalReminder = subscription.enableRenewalReminder
        self.reminderDaysBefore = subscription.reminderDaysBefore
    }

    // MARK: - Conversion to Domain Model
    func toDomain() -> Subscription {
        var subscription = Subscription(
            id: id,
            name: name,
            description: subscriptionDescription,
            price: price,
            billingCycle: BillingCycle(rawValue: billingCycleRaw) ?? .monthly,
            category: SubscriptionCategory(rawValue: categoryRaw) ?? .other,
            icon: icon,
            color: color,
            nextBillingDate: nextBillingDate,
            isActive: isActive,
            isShared: isShared,
            sharedWith: sharedWithIDs,
            notes: notes,
            website: website,
            totalSpent: totalSpent
        )
        subscription.isFreeTrial = isFreeTrial
        subscription.trialStartDate = trialStartDate
        subscription.trialEndDate = trialEndDate
        subscription.willConvertToPaid = willConvertToPaid
        subscription.enableRenewalReminder = enableRenewalReminder
        subscription.reminderDaysBefore = reminderDaysBefore
        return subscription
    }
}
```

---

## Schema Definition

```swift
// PersistenceService.swift
@MainActor
class PersistenceService {
    // MARK: - Schema Definition (Single Source of Truth)
    static let appSchema = Schema([
        PersonModel.self,
        GroupModel.self,
        GroupExpenseModel.self,
        SubscriptionModel.self,
        SharedSubscriptionModel.self,
        TransactionModel.self,
        PriceChangeModel.self
    ])

    // MARK: - Container Creation
    private static func createModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(
            for: appSchema,
            configurations: [configuration]
        )
    }

    // MARK: - In-Memory Container (for testing)
    static func createInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: appSchema,
            configurations: [configuration]
        )
    }
}
```

---

## CRUD Operations

### Create (Save)

```swift
func saveSubscription(_ subscription: Subscription) throws {
    // Validate first
    try validateSubscription(subscription)

    // Check if exists (upsert pattern)
    let descriptor = FetchDescriptor<SubscriptionModel>(
        predicate: #Predicate { $0.id == subscription.id }
    )

    if let existing = try modelContext.fetch(descriptor).first {
        // Update existing
        existing.name = subscription.name
        existing.price = subscription.price
        // ... update all fields
    } else {
        // Create new
        let model = SubscriptionModel(from: subscription)
        modelContext.insert(model)
    }

    try saveContext()
}
```

### Read (Fetch)

```swift
// Fetch all with sorting
func fetchAllSubscriptions() throws -> [Subscription] {
    let descriptor = FetchDescriptor<SubscriptionModel>(
        sortBy: [SortDescriptor(\SubscriptionModel.name, order: .forward)]
    )

    let models = try modelContext.fetch(descriptor)
    return models.map { $0.toDomain() }
}

// Fetch by ID
func fetchSubscription(byID id: UUID) throws -> Subscription? {
    let descriptor = FetchDescriptor<SubscriptionModel>(
        predicate: #Predicate { $0.id == id }
    )

    return try modelContext.fetch(descriptor).first?.toDomain()
}

// Fetch with filter
func fetchActiveSubscriptions() throws -> [Subscription] {
    let descriptor = FetchDescriptor<SubscriptionModel>(
        predicate: #Predicate { $0.isActive == true }
    )

    return try modelContext.fetch(descriptor).map { $0.toDomain() }
}

// Fetch with date range
func fetchSubscriptionsRenewingSoon(days: Int) throws -> [Subscription] {
    let now = Date()
    let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now)!

    let descriptor = FetchDescriptor<SubscriptionModel>(
        predicate: #Predicate { subscription in
            subscription.isActive &&
            subscription.nextBillingDate >= now &&
            subscription.nextBillingDate <= futureDate
        }
    )

    return try modelContext.fetch(descriptor).map { $0.toDomain() }
}
```

### Update

```swift
func updateSubscription(_ subscription: Subscription) throws {
    try validateSubscription(subscription)

    let descriptor = FetchDescriptor<SubscriptionModel>(
        predicate: #Predicate { $0.id == subscription.id }
    )

    guard let existing = try modelContext.fetch(descriptor).first else {
        throw PersistenceError.entityNotFound(id: subscription.id)
    }

    // Update all fields
    existing.name = subscription.name
    existing.price = subscription.price
    existing.isActive = subscription.isActive
    // ... other fields

    try saveContext()
}
```

### Delete

```swift
func deleteSubscription(id: UUID) throws {
    let descriptor = FetchDescriptor<SubscriptionModel>(
        predicate: #Predicate { $0.id == id }
    )

    guard let subscription = try modelContext.fetch(descriptor).first else {
        throw PersistenceError.entityNotFound(id: id)
    }

    modelContext.delete(subscription)
    try saveContext()
}
```

---

## Relationships

### One-to-Many

```swift
@Model
final class GroupModel {
    @Attribute(.unique) var id: UUID
    var name: String

    // One group has many expenses
    @Relationship(deleteRule: .cascade)
    var expenses: [GroupExpenseModel] = []

    // One group has many members (reference by ID)
    var memberIDs: [UUID] = []
}

@Model
final class GroupExpenseModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double

    // Back-reference to parent
    var group: GroupModel?
}
```

### Delete Rules

- `.cascade` - Delete children when parent deleted
- `.nullify` - Set relationship to nil
- `.deny` - Prevent deletion if children exist

---

## Validation

```swift
private func validateSubscription(_ subscription: Subscription) throws {
    guard !subscription.name.trimmingCharacters(in: .whitespaces).isEmpty else {
        throw PersistenceError.validationFailed(reason: "Name cannot be empty")
    }

    guard subscription.price > 0 else {
        throw PersistenceError.validationFailed(reason: "Price must be greater than 0")
    }
}

private func validateTransaction(_ transaction: Transaction) throws {
    guard !transaction.title.trimmingCharacters(in: .whitespaces).isEmpty else {
        throw PersistenceError.validationFailed(reason: "Title cannot be empty")
    }

    guard transaction.amount != 0 else {
        throw PersistenceError.validationFailed(reason: "Amount cannot be 0")
    }
}
```

---

## Error Handling

```swift
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

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .entityNotFound(let id):
            return "Entity with ID \(id) not found"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        // ...
        }
    }
}
```

---

## Schema Migration

### Detecting Schema Changes

```swift
private static func isSchemaError(_ error: Error) -> Bool {
    let description = error.localizedDescription.lowercased()
    return description.contains("schema") ||
           description.contains("model") ||
           description.contains("metadata")
}

private init() {
    do {
        self.modelContainer = try Self.createModelContainer()
    } catch {
        if Self.isSchemaError(error) {
            // Delete old database and retry
            Self.deleteDatabase()
            self.modelContainer = try! Self.createModelContainer()
        } else {
            // Fallback to in-memory
            self.modelContainer = try! Self.createInMemoryContainer()
        }
    }
}
```

### Versioned Migration (Future)

```swift
// Persistence/MigrationPlanV1toV2.swift
enum SchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [SubscriptionModelV1.self]
    }
}

enum SchemaV2: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [SubscriptionModel.self]  // Current version
    }
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

---

## Testing with In-Memory Container

```swift
@Suite("PersistenceService Tests")
@MainActor
struct PersistenceServiceTests {

    private func createTestService() -> PersistenceService {
        let container = try! PersistenceService.createInMemoryContainer()
        return PersistenceService(modelContainer: container)
    }

    @Test("Save and fetch subscription")
    func testSaveAndFetch() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "Test",
            description: "Test subscription",
            price: 9.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "star.fill",
            color: "#FF0000"
        )

        try service.saveSubscription(subscription)
        let fetched = try service.fetchAllSubscriptions()

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Test")
    }
}
```

---

## Common Mistakes to Avoid

1. **Using reserved words** (use `subscriptionDescription` not `description`)
2. **Storing enums directly** (store as raw String value)
3. **Not handling schema changes** (causes crashes)
4. **Fetching without predicates** (performance issue for large datasets)
5. **Forgetting to call saveContext()**

---

## Checklist

- [ ] Domain model created in `Models/DataModels/`
- [ ] SwiftData model created with `@Model`
- [ ] `@Attribute(.unique)` on ID field
- [ ] `toDomain()` method implemented
- [ ] `init(from:)` convenience initializer
- [ ] Schema updated in `PersistenceService.appSchema`
- [ ] Validation method added
- [ ] CRUD operations in `PersistenceService`

---

## Industry Standards

- **Apple WWDC 2023** - Meet SwiftData
- **Apple WWDC 2024** - What's new in SwiftData
- **Database normalization** principles
- **Repository pattern** for data access
