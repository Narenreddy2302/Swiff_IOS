# Schema Evolution Guide - Swiff iOS

## Overview

This guide provides practical examples and best practices for evolving the SwiftData schema in Swiff iOS. Use this as a reference when you need to make changes to the data models.

## Quick Reference

| Change Type | Migration Type | Complexity | Example |
|-------------|---------------|------------|---------|
| Add optional property | Lightweight | ✅ Easy | `var notes: String?` |
| Add new model | Lightweight | ✅ Easy | `TagModel` |
| Remove unused property | Lightweight | ⚠️ Medium | Remove `oldField` |
| Rename property | Custom | ⚠️ Medium | `email` → `emailAddress` |
| Change property type | Custom | 🔴 Hard | `String` → `URL` |
| Add required property | Custom | 🔴 Hard | `var country: String` |
| Change relationship | Custom | 🔴 Hard | One-to-many → Many-to-many |

## Lightweight Migrations

### 1. Adding Optional Properties

**Scenario:** Add a profile photo URL to PersonModel

**✅ Safe - Automatic Migration**

```swift
// BEFORE (V1)
@Model
class PersonModel {
    var id: UUID
    var name: String
    var email: String
    var balance: Double
}

// AFTER (V2) - Add optional property
@Model
class PersonModel {
    var id: UUID
    var name: String
    var email: String
    var balance: Double

    // NEW: Automatically migrated, defaults to nil
    var profilePhotoURL: String?

    init(id: UUID, name: String, email: String, balance: Double, profilePhotoURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.balance = balance
        self.profilePhotoURL = profilePhotoURL
    }
}
```

**Migration Steps:**
1. Add property to model
2. Update `SwiffSchemaV2` with new version identifier
3. Add `SwiffSchemaV2` to migration plan schemas array
4. **No custom migration stage needed** - SwiftData handles it automatically

```swift
enum SwiffSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PersonModel.self, /* other models */]
    }
}

enum SwiffMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SwiffSchemaV1.self, SwiffSchemaV2.self]  // ✅ Just add V2
    }

    static var stages: [MigrationStage] {
        []  // ✅ Empty - lightweight migration
    }
}
```

### 2. Adding New Models

**Scenario:** Add a BudgetModel for budget tracking

**✅ Safe - Automatic Migration**

```swift
// NEW MODEL (V2)
@Model
class BudgetModel {
    var id: UUID
    var name: String
    var amount: Double
    var categoryRaw: String
    var startDate: Date
    var endDate: Date

    init(id: UUID, name: String, amount: Double, categoryRaw: String, startDate: Date, endDate: Date) {
        self.id = id
        self.name = name
        self.amount = amount
        self.categoryRaw = categoryRaw
        self.startDate = startDate
        self.endDate = endDate
    }
}
```

**Migration Steps:**
1. Create new model file in `Swiff IOS/Models/SwiftDataModels/`
2. Add corresponding domain model in `Swiff IOS/Models/DataModels/`
3. Add conversion methods (`toDomain()`, `init(from:)`)
4. Update schema version:

```swift
enum SwiffSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            PersonModel.self,
            GroupModel.self,
            GroupExpenseModel.self,
            SubscriptionModel.self,
            SharedSubscriptionModel.self,
            TransactionModel.self,
            BudgetModel.self  // ✅ Add new model
        ]
    }
}
```

### 3. Removing Unused Properties

**Scenario:** Remove deprecated `phone` field from PersonModel

**⚠️ Data Loss - Automatic Migration**

```swift
// BEFORE (V1)
@Model
class PersonModel {
    var id: UUID
    var name: String
    var email: String
    var phone: String  // ❌ To be removed
    var balance: Double
}

// AFTER (V2)
@Model
class PersonModel {
    var id: UUID
    var name: String
    var email: String
    // phone removed - data will be lost
    var balance: Double
}
```

**⚠️ Warning:** Data in removed fields is permanently deleted. Consider:
1. Export data before removal
2. Archive in a different model if needed later
3. Communicate change to users

**No custom migration needed** - SwiftData drops the column automatically.

## Custom Migrations

### 4. Renaming Properties

**Scenario:** Rename `email` to `emailAddress` for clarity

**⚠️ Requires Custom Migration**

```swift
// V1
@Model
class PersonModel {
    var email: String  // Old name
}

// V2
@Model
class PersonModel {
    var emailAddress: String  // New name
}
```

**Custom Migration Stage:**

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SwiffSchemaV1.self,
    toVersion: SwiffSchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        print("🔄 Migrating: Renaming email to emailAddress")

        // Fetch all PersonModel instances
        let descriptor = FetchDescriptor<PersonModelV2>()
        let people = try context.fetch(descriptor)

        for person in people {
            // The data from 'email' is automatically in 'emailAddress'
            // SwiftData handles the data transfer if you use lightweight migration
            // This is just for validation/logging
            print("Migrated person: \(person.name) - \(person.emailAddress)")
        }

        try context.save()
        print("✅ Email rename migration complete")
    }
)

enum SwiffMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SwiffSchemaV1.self, SwiffSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]  // ✅ Add migration stage
    }
}
```

**Alternative Approach:** Use lightweight migration with both fields temporarily:

```swift
// V1.5 (Transition)
@Model
class PersonModel {
    var email: String
    var emailAddress: String  // Copy of email
}

// V2 (Final)
@Model
class PersonModel {
    var emailAddress: String  // Keep only new name
}
```

### 5. Changing Property Types

**Scenario:** Change `icon` from `String` to `Data` in SubscriptionModel

**🔴 Complex - Requires Custom Migration**

```swift
// V1
@Model
class SubscriptionModel {
    var icon: String  // SF Symbol name
}

// V2
@Model
class SubscriptionModel {
    var iconData: Data?  // PNG/JPEG data
    var iconName: String?  // Keep as fallback
}
```

**Custom Migration:**

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SwiffSchemaV1.self,
    toVersion: SwiffSchemaV2.self,
    willMigrate: { context in
        print("🔄 Starting icon migration")
    },
    didMigrate: { context in
        print("🔄 Converting String icons to Data")

        let descriptor = FetchDescriptor<SubscriptionModelV2>()
        let subscriptions = try context.fetch(descriptor)

        for subscription in subscriptions {
            // Preserve the old string icon as fallback
            // subscription.iconName = subscription.icon (old value)

            // Convert to Data if needed
            // For SF Symbols, keep as string initially
            subscription.iconName = "star.fill"  // Default
        }

        try context.save()
        print("✅ Icon migration complete")
    }
)
```

### 6. Adding Required Properties with Default Values

**Scenario:** Add required `currency` field to all transactions

**🔴 Complex - Requires Custom Migration**

```swift
// V1
@Model
class TransactionModel {
    var amount: Double
}

// V2
@Model
class TransactionModel {
    var amount: Double
    var currency: String  // NEW: Required field
}
```

**Custom Migration:**

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SwiffSchemaV1.self,
    toVersion: SwiffSchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        print("🔄 Adding currency to existing transactions")

        let descriptor = FetchDescriptor<TransactionModelV2>()
        let transactions = try context.fetch(descriptor)

        for transaction in transactions {
            // Set default currency for existing transactions
            transaction.currency = "USD"  // Or get from user settings
        }

        try context.save()
        print("✅ Currency migration complete")
    }
)
```

**Better Approach:** Make it optional initially:

```swift
// V2 - Better approach
@Model
class TransactionModel {
    var amount: Double
    var currency: String? = "USD"  // Optional with default
}

// V3 - Later make required after data migration
@Model
class TransactionModel {
    var amount: Double
    var currency: String  // Now required, all data has values
}
```

### 7. Changing Relationships

**Scenario:** Change `PersonModel` → `GroupModel` from many-to-many to one-to-many

**🔴 Very Complex - Requires Custom Migration**

```swift
// V1 - Many-to-many
@Model
class PersonModel {
    var groups: [GroupModel]?  // Many groups
}

@Model
class GroupModel {
    var members: [PersonModel]?  // Many people
}

// V2 - One-to-many (person has one primary group)
@Model
class PersonModel {
    var primaryGroup: GroupModel?  // One group
    var additionalGroups: [UUID]  // Store as IDs for other groups
}

@Model
class GroupModel {
    var members: [PersonModel]?  // Still many people
}
```

**Custom Migration:**

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SwiffSchemaV1.self,
    toVersion: SwiffSchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        print("🔄 Migrating group relationships")

        let personDescriptor = FetchDescriptor<PersonModelV2>()
        let people = try context.fetch(personDescriptor)

        for person in people {
            // Old data: person.groups (array)
            // New data: person.primaryGroup (single) + additionalGroups (IDs)

            // Strategy: Make first group primary, rest additional
            if let groups = person.groups, !groups.isEmpty {
                person.primaryGroup = groups.first
                person.additionalGroups = groups.dropFirst().map(\.id)
            }
        }

        try context.save()
        print("✅ Group relationship migration complete")
    }
)
```

## Common Patterns

### Pattern 1: Additive Changes Only (Safest)

When possible, only add new fields and models:

```swift
// V1
@Model class PersonModel {
    var name: String
}

// V2 - Only additions
@Model class PersonModel {
    var name: String
    var nickname: String?  // ✅ Added
    var notes: String?     // ✅ Added
}
```

### Pattern 2: Deprecate Then Remove (Two-Step)

For removing fields, use a two-version approach:

```swift
// V1
@Model class PersonModel {
    var oldField: String
}

// V2 - Mark as deprecated, add replacement
@Model class PersonModel {
    var oldField: String?  // Make optional (deprecated)
    var newField: String   // Add replacement
}

// V3 - Remove deprecated field
@Model class PersonModel {
    var newField: String  // Only new field remains
}
```

### Pattern 3: Parallel Fields (During Transition)

Keep both old and new fields temporarily:

```swift
// V2 - Transition version
@Model class SubscriptionModel {
    var price: Double           // Old: Simple double
    var priceComponents: [PriceComponent]?  // New: Detailed breakdown

    var effectivePrice: Double {
        priceComponents?.reduce(0) { $0 + $1.amount } ?? price
    }
}

// V3 - Remove old field
@Model class SubscriptionModel {
    var priceComponents: [PriceComponent]  // Only new field
}
```

## Testing Schema Changes

### Test Template

```swift
import XCTest
import SwiftData

final class SchemaEvolutionTests: XCTestCase {

    func testMigrationV1toV2_AddsOptionalProperty() async throws {
        // 1. Setup V1 database
        let v1Container = try ModelContainer(
            for: Schema(versionedSchema: SwiffSchemaV1.self)
        )

        let v1Context = v1Container.mainContext

        // 2. Insert V1 data
        let person = PersonModelV1(
            id: UUID(),
            name: "John Doe",
            email: "john@example.com",
            balance: 100.0
        )
        v1Context.insert(person)
        try v1Context.save()

        let personID = person.id

        // 3. Close V1 container (simulate app restart)
        // Container deallocated

        // 4. Open V2 (triggers migration)
        let v2Container = try ModelContainer(
            for: Schema(versionedSchema: SwiffSchemaV2.self),
            migrationPlan: SwiffMigrationPlan.self
        )

        let v2Context = v2Container.mainContext

        // 5. Verify migration
        let descriptor = FetchDescriptor<PersonModelV2>(
            predicate: #Predicate { $0.id == personID }
        )

        let migratedPerson = try v2Context.fetch(descriptor).first
        XCTAssertNotNil(migratedPerson)
        XCTAssertEqual(migratedPerson?.name, "John Doe")
        XCTAssertNil(migratedPerson?.profilePhotoURL)  // New field defaults to nil

        print("✅ Migration test passed")
    }

    func testMigrationPreservesRelationships() async throws {
        // Test that relationships remain intact after migration
        // Similar structure to above
    }

    func testMigrationWithLargeDataset() async throws {
        // Test performance with 10,000+ records
    }
}
```

## Checklist for Schema Changes

### Before Making Changes

- [ ] Review existing schema in `PersistenceService.swift`
- [ ] Determine if change is lightweight or custom migration
- [ ] Plan backward compatibility strategy
- [ ] Consider impact on existing users' data
- [ ] Check if related domain models need updates

### During Implementation

- [ ] Create new `SwiffSchemaVX` version
- [ ] Update all affected models
- [ ] Add custom migration stage if needed
- [ ] Update domain models and conversion methods
- [ ] Update `PersistenceService` CRUD operations if needed
- [ ] Add migration to `SwiffMigrationPlan`

### After Implementation

- [ ] Write migration tests
- [ ] Test on device with existing data
- [ ] Verify backup/restore works
- [ ] Update `DataMigrations.md` with changes
- [ ] Document in version history
- [ ] Test upgrade path from all previous versions

## Common Pitfalls

### ❌ Pitfall 1: Changing Existing Schema Versions

```swift
// WRONG - Never modify existing schema versions
enum SwiffSchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [PersonModel.self]  // ❌ Don't add/remove models here
    }
}
```

**✅ Correct:** Always create a new version

```swift
enum SwiffSchemaV2: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [PersonModel.self, NewModel.self]  // ✅ Add in new version
    }
}
```

### ❌ Pitfall 2: Skipping Versions

```swift
// WRONG
static var schemas: [any VersionedSchema.Type] {
    [SwiffSchemaV1.self, SwiffSchemaV3.self]  // ❌ Skipped V2
}
```

**✅ Correct:** Include all versions in sequence

```swift
static var schemas: [any VersionedSchema.Type] {
    [SwiffSchemaV1.self, SwiffSchemaV2.self, SwiffSchemaV3.self]  // ✅ Complete chain
}
```

### ❌ Pitfall 3: Not Testing Migration

```swift
// WRONG - Shipping without testing
// ❌ No tests for migration

// ✅ CORRECT - Always test
func testMigrationV1toV2() async throws {
    // Test migration logic
}
```

### ❌ Pitfall 4: Breaking Domain Model Compatibility

```swift
// WRONG - Changing domain model breaks existing code
struct Person {  // Domain model
    let name: String
    // ❌ Removed email field - breaks existing code
}

// ✅ CORRECT - Keep domain model compatible
struct Person {
    let name: String
    let email: String
    let profilePhotoURL: String?  // Add new optional fields
}
```

## Reference Architecture

```
Swiff IOS/
├── Models/
│   ├── DataModels/              # Domain models (pure Swift)
│   │   ├── Person.swift
│   │   ├── Transaction.swift
│   │   └── Subscription.swift
│   └── SwiftDataModels/         # SwiftData models (@Model)
│       ├── PersonModel.swift
│       ├── TransactionModel.swift
│       └── SubscriptionModel.swift
├── Services/
│   └── PersistenceService.swift # Migration plan + schemas
└── Docs/
    ├── DataMigrations.md        # This guide
    └── SchemaEvolutionGuide.md  # Practical examples

Tests/
└── MigrationTests.swift         # Migration test suite
```

## Additional Resources

- [DataMigrations.md](./DataMigrations.md) - Overall migration strategy
- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [VersionedSchema Protocol](https://developer.apple.com/documentation/swiftdata/versionedschema)
- [SchemaMigrationPlan Protocol](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)

---

**Last Updated:** 2025-01-18
**Version:** 1.0.0
**Maintained By:** Swiff iOS Development Team
