# SwiftData Migration Strategy for Swiff iOS

## Overview

This document outlines the data migration strategy for the Swiff iOS app, which uses **SwiftData** (not Core Data) for persistence. SwiftData provides a modern, type-safe approach to data persistence with built-in migration support.

## Current Schema Version

**Version 1.0.0** (SwiffSchemaV1)

Initial schema with the following models:
- `PersonModel` - User contacts and their balances
- `GroupModel` - Expense sharing groups
- `GroupExpenseModel` - Individual expenses within groups
- `SubscriptionModel` - Subscription tracking
- `SharedSubscriptionModel` - Split subscription management
- `TransactionModel` - Income and expense transactions

## Migration Architecture

### 1. Versioned Schema Approach

SwiftData uses `VersionedSchema` instead of Core Data's NSManagedObjectModel versions. Each schema version is defined as an enum conforming to `VersionedSchema`.

**Location:** `Swiff IOS/Services/PersistenceService.swift`

```swift
enum SwiffSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            PersonModel.self,
            GroupModel.self,
            GroupExpenseModel.self,
            SubscriptionModel.self,
            SharedSubscriptionModel.self,
            TransactionModel.self
        ]
    }
}
```

### 2. Migration Plan

The `SwiffMigrationPlan` defines all schema versions and migration stages.

```swift
enum SwiffMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SwiffSchemaV1.self]
        // Future versions: [SwiffSchemaV1.self, SwiffSchemaV2.self, ...]
    }

    static var stages: [MigrationStage] {
        // Migration stages will be added here
        []
    }
}
```

## Migration Types

### Lightweight Migration (Automatic)

SwiftData automatically handles these changes without custom migration code:

✅ **Supported Changes:**
- Adding new optional properties to existing models
- Adding new models to the schema
- Removing models (with data loss warning)
- Adding @Transient properties (not persisted)
- Changing property defaults
- Adding indexes

**Example: Adding an optional property**

```swift
enum SwiffSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            PersonModelV2.self,  // Updated model
            GroupModel.self,
            // ... other models
        ]
    }
}

@Model
class PersonModelV2 {
    // Existing properties
    var name: String
    var email: String

    // NEW: Optional property (automatic migration)
    var profileImageURL: String?  // ✅ Lightweight migration

    init(name: String, email: String, profileImageURL: String? = nil) {
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
    }
}
```

### Custom Migration (Manual)

Required for complex schema changes that SwiftData cannot infer:

⚠️ **Requires Custom Migration:**
- Renaming properties
- Changing property types
- Making optional properties required (or vice versa)
- Splitting one property into multiple
- Merging multiple properties into one
- Complex data transformations
- Changing relationship cardinality

**Example: Renaming a property**

```swift
enum SwiffMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SwiffSchemaV1.self, SwiffSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SwiffSchemaV1.self,
        toVersion: SwiffSchemaV2.self,
        willMigrate: { context in
            // Pre-migration: Validate data, create backups
            print("🔄 Starting migration from V1 to V2")

            // Optionally trigger backup service
            // await BackupService.shared.createPreMigrationBackup()
        },
        didMigrate: { context in
            // Post-migration: Transform data
            print("🔄 Applying data transformations...")

            // Example: Copy data from old property to new property
            let descriptor = FetchDescriptor<PersonModelV2>()
            let people = try context.fetch(descriptor)

            for person in people {
                // Transform data as needed
                // person.newProperty = person.oldProperty
            }

            try context.save()
            print("✅ Migration V1→V2 completed")
        }
    )
}
```

## Migration Workflow

### When Schema Changes Are Needed

1. **Create New Schema Version**
   ```swift
   enum SwiffSchemaV2: VersionedSchema {
       static var versionIdentifier = Schema.Version(2, 0, 0)
       static var models: [any PersistentModel.Type] {
           // Updated models
       }
   }
   ```

2. **Update Model Files**
   - Modify models in `Swiff IOS/Models/SwiftDataModels/`
   - Ensure backward compatibility where possible

3. **Add to Migration Plan**
   ```swift
   static var schemas: [any VersionedSchema.Type] {
       [SwiffSchemaV1.self, SwiffSchemaV2.self]  // Add new version
   }
   ```

4. **Create Migration Stage (if needed)**
   - Only for complex changes requiring custom logic
   - Add to `stages` array

5. **Test Migration**
   - Create tests in `Swiff IOSTests/MigrationTests.swift`
   - Test upgrade path from all previous versions
   - Verify data integrity

6. **Update Documentation**
   - Document changes in this file
   - Update version history below

## Testing Migrations

### Test Strategy

1. **Unit Tests** - Test individual migration stages
2. **Integration Tests** - Test complete upgrade paths
3. **Manual Testing** - Test on physical devices with real data

### Test Checklist

Before releasing a schema change:

- [ ] All existing data migrates successfully
- [ ] No data loss occurs
- [ ] Relationships remain intact
- [ ] App launches successfully after migration
- [ ] All CRUD operations work post-migration
- [ ] Performance is acceptable (< 2s for typical dataset)
- [ ] Migration can be interrupted and resumed
- [ ] Edge cases handled (empty database, corrupted data)

### Test Code Example

```swift
func testMigrationV1toV2() async throws {
    // 1. Create V1 database with sample data
    let v1Container = try ModelContainer(
        for: Schema(versionedSchema: SwiffSchemaV1.self)
    )

    // 2. Add test data
    let context = v1Container.mainContext
    // ... insert test data

    // 3. Close V1 container
    // Container automatically closed when deallocated

    // 4. Open with V2 (triggers migration)
    let v2Container = try ModelContainer(
        for: Schema(versionedSchema: SwiffSchemaV2.self),
        migrationPlan: SwiffMigrationPlan.self
    )

    // 5. Verify data migrated correctly
    let newContext = v2Container.mainContext
    // ... assert data integrity
}
```

## Error Handling

### Migration Failure Scenarios

1. **Disk Space Insufficient**
   - Show alert to user
   - Offer to free up space
   - Retry migration

2. **Data Corruption**
   - Attempt to restore from backup
   - Offer to reset database
   - Log to analytics

3. **Migration Timeout**
   - Show progress indicator
   - Allow migration to complete in background
   - Prevent app usage until complete

### Recovery Strategy

```swift
private init() {
    do {
        self.modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: SwiffMigrationPlan.self,
            configurations: [modelConfiguration]
        )
    } catch {
        print("❌ Migration failed: \(error)")

        // Recovery options:
        // 1. Restore from backup
        if let backup = BackupService.shared.latestBackup {
            try? BackupService.shared.restore(from: backup)
        }

        // 2. Reset to fresh database (last resort)
        // 3. Show error UI to user
        // 4. Log to crash reporting

        fatalError("Could not create ModelContainer: \(error)")
    }
}
```

## Best Practices

### DO ✅

1. **Always version your schema** - Even if it's V1
2. **Test migrations thoroughly** - On real devices with real data
3. **Create backups before migration** - Use `BackupService`
4. **Use lightweight migrations when possible** - Faster and safer
5. **Document all schema changes** - Update this file
6. **Keep migration code forever** - Users may skip versions
7. **Version in sequence** - V1 → V2 → V3 (never skip)
8. **Test rollback scenarios** - Can user downgrade app?

### DON'T ❌

1. **Don't delete old schema versions** - Users may upgrade from any version
2. **Don't modify existing schema enums** - Create new versions instead
3. **Don't make breaking changes without migration** - Data loss!
4. **Don't assume migration will be instant** - Show progress
5. **Don't ignore migration errors** - Handle gracefully
6. **Don't ship untested migrations** - Critical path!
7. **Don't remove migration stages** - Breaks upgrade path
8. **Don't change version identifiers** - Must be immutable

## Integration with Backup Service

Swiff iOS includes a `BackupService` that automatically backs up data every 7 days. This serves as a safety net for migrations.

**Pre-Migration Backup:**
```swift
// Trigger backup before migration
await BackupService.shared.createPreMigrationBackup()
```

**Post-Migration Verification:**
```swift
// Verify backup can be restored after migration
let restorable = try await BackupService.shared.verifyBackup()
```

## Version History

### Version 1.0.0 (Current)
**Released:** 2025-01-18
**Models:**
- PersonModel (id, name, email, phone, balance, avatar properties)
- GroupModel (id, name, description, emoji, members, expenses)
- GroupExpenseModel (id, title, amount, paidBy, splitBetween, category)
- SubscriptionModel (id, name, price, billingCycle, category, etc.)
- SharedSubscriptionModel (id, subscriptionID, shared users, cost split)
- TransactionModel (id, title, amount, category, date, tags)

**Notes:** Initial schema definition with comprehensive financial tracking.

---

### Future Versions

**Version 2.0.0 (Planned)**
- TBD based on feature requirements

## Additional Resources

### SwiftData Migration Documentation
- [Apple SwiftData Migration Guide](https://developer.apple.com/documentation/swiftdata/migrating-your-app-to-use-swiftdata)
- [Schema Migration in SwiftData](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)

### Related Files
- `PersistenceService.swift` - Migration implementation
- `SchemaEvolutionGuide.md` - Detailed change guidelines
- `MigrationTests.swift` - Test suite

## Support

For questions or issues with migrations:
1. Review `SchemaEvolutionGuide.md` for change examples
2. Check test suite for migration patterns
3. Consult SwiftData documentation
4. Review git history for previous migration examples

---

**Last Updated:** 2025-01-18
**Maintained By:** Swiff iOS Development Team
