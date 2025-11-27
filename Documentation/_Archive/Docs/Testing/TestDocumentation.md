# SwiftData Model Conversion Testing Documentation

## Overview

This document describes the comprehensive test suite created to verify round-trip conversions between domain models and SwiftData persistence models for the Swiff iOS application.

**Test File**: `Swiff IOSTests/Swiff_IOSTests.swift`

## Test Coverage

### 1. PersonModel Tests

#### Test: `testPersonModelRoundTrip()`
**Purpose**: Verifies that PersonModel preserves all critical data during domain → SwiftData → domain conversion.

**What it tests**:
- ID preservation (critical fix from Task 1.1.3)
- Name, email, phone preservation
- Balance preservation (critical fix)
- Created date preservation (critical fix)
- Avatar emoji type conversion

**Test data**:
```swift
Person(name: "John Doe", email: "john@example.com", phone: "+1234567890", avatarType: .emoji("👨"))
balance: 125.50
createdDate: Date(timeIntervalSince1970: 1700000000)
```

**Verification**:
- All fields match after round-trip conversion
- No data loss occurs
- UUIDs remain consistent

#### Test: `testPersonModelPhotoAvatar()`
**Purpose**: Verifies photo avatar data is preserved correctly.

**What it tests**:
- Photo data storage and retrieval
- Binary data integrity
- Avatar type discrimination

**Test data**: `Data([0x01, 0x02, 0x03, 0x04])`

#### Test: `testPersonModelInitialsAvatar()`
**Purpose**: Verifies initials avatar with color index preservation.

**What it tests**:
- Initials string preservation
- Color index preservation
- Avatar type with associated values

**Test data**: `.initials("AJ", colorIndex: 3)`

---

### 2. SubscriptionModel Tests

#### Test: `testSubscriptionModelRoundTrip()`
**Purpose**: Comprehensive test of all subscription properties.

**What it tests**:
- Basic properties: id, name, description, price
- Billing cycle enum conversion
- Category enum conversion
- UI properties: icon, color
- Date properties: nextBillingDate, lastBillingDate, createdDate, cancellationDate
- Boolean flags: isActive, isShared
- Arrays: sharedWith UUIDs
- Optional strings: notes, website
- Calculated values: totalSpent

**Test data**:
```swift
Subscription(
    name: "Netflix",
    price: 15.99,
    billingCycle: .monthly,
    category: .entertainment,
    icon: "tv.fill",
    color: "#E50914"
)
+ 10 additional properties
```

#### Test: `testSubscriptionBillingCycles()`
**Purpose**: Verify all billing cycle enums convert correctly.

**What it tests**:
- `.weekly` conversion
- `.monthly` conversion
- `.quarterly` conversion
- `.semiAnnually` conversion
- `.annually` conversion
- `.lifetime` conversion

**Verification**: Each enum case preserves its value through round-trip conversion.

---

### 3. TransactionModel Tests

#### Test: `testTransactionModelRoundTrip()`
**Purpose**: Verify transaction data preservation.

**What it tests**:
- ID, title, subtitle preservation
- Negative amounts (expenses) preservation
- Category enum conversion
- Date preservation
- Boolean flags: isRecurring
- String arrays: tags

**Test data**:
```swift
Transaction(
    title: "Grocery Shopping",
    subtitle: "Whole Foods",
    amount: -125.50,
    category: .groceries,
    date: Date(timeIntervalSince1970: 1700500000),
    isRecurring: false,
    tags: ["food", "weekly"]
)
```

#### Test: `testTransactionCategories()`
**Purpose**: Verify all transaction category enums.

**What it tests**: All 11 categories:
- `.groceries`, `.dining`, `.transport`, `.utilities`
- `.entertainment`, `.shopping`, `.health`, `.education`
- `.travel`, `.income`, `.other`

---

### 4. GroupModel Tests

#### Test: `testGroupModelRoundTrip()`
**Purpose**: Verify complex group model with relationships.

**What it tests**:
- Group basic properties: id, name, description, emoji
- Numeric properties: totalAmount
- Date properties: createdDate
- **Many-to-many relationships**: members array resolution
- **Nested conversions**: expenses array with GroupExpenseModel
- **Context-aware initialization**: UUID → PersonModel resolution

**Test data**:
```swift
Group(
    name: "Weekend Trip",
    description: "Trip to the mountains",
    emoji: "🏔️",
    members: [person1.id, person2.id]
)
+ 1 GroupExpense
```

**Verification**:
- 2 members correctly resolved from UUIDs
- 1 expense correctly converted
- Nested data preserved

#### Test: `testGroupExpenseModelRoundTrip()`
**Purpose**: Verify group expense with participant relationships.

**What it tests**:
- Expense properties: id, title, amount
- **Relationship resolution**: paidBy UUID → PersonModel
- **Many-to-many resolution**: splitBetween UUIDs → PersonModel array
- Category enum conversion
- Optional receipt path
- Boolean settled status

**Test data**:
```swift
GroupExpense(
    title: "Dinner",
    amount: 85.50,
    paidBy: person1.id,
    splitBetween: [person1.id, person2.id],
    category: .dining,
    notes: "Italian restaurant",
    receipt: "/path/to/receipt.jpg",
    isSettled: false
)
```

---

### 5. Batch Conversion Tests

#### Test: `testBatchInsertion()`
**Purpose**: Verify ModelConverter utility methods work correctly.

**What it tests**:
- `ModelConverter.insertPeople()` batch insertion
- Multiple domain models → SwiftData models
- Array-based operations
- Data integrity across batch operations

**Test data**: 3 Person objects inserted in batch

**Verification**:
- All 3 people inserted
- All 3 people convert back correctly
- Names and emails match originals

---

### 6. Database Management Tests

#### Test: `testDatabaseStats()`
**Purpose**: Verify database statistics calculation.

**What it tests**:
- `ModelConverter.getDatabaseStats()` accuracy
- Count calculations for each model type
- Total records calculation
- Multi-model database state

**Test data**:
- 1 Person
- 1 Subscription
- 1 Transaction

**Expected results**:
```swift
stats.peopleCount == 1
stats.subscriptionsCount == 1
stats.transactionsCount == 1
stats.totalRecords == 3
```

#### Test: `testClearAllData()`
**Purpose**: Verify database clearing functionality.

**What it tests**:
- `ModelConverter.clearAllData()` deletes all records
- `ModelConverter.isDatabaseEmpty()` correctly reports state
- Database state before and after clearing

**Verification**:
- Database not empty after insertion
- Database empty after clearing

---

## Test Infrastructure

### In-Memory Testing
All tests use an in-memory ModelContainer to:
- Avoid modifying production database
- Enable fast, isolated tests
- Allow concurrent test execution
- Ensure clean state for each test

```swift
private func createTestContainer() -> ModelContainer {
    let schema = Schema([
        PersonModel.self,
        GroupModel.self,
        GroupExpenseModel.self,
        SubscriptionModel.self,
        SharedSubscriptionModel.self,
        TransactionModel.self
    ])

    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true
    )

    return try ModelContainer(for: schema, configurations: [configuration])
}
```

### Test Framework
Using Apple's modern Swift Testing framework:
- `@Test` macro for individual tests
- `@Suite` for test organization
- `#expect()` for assertions
- `Issue.record()` for custom failures

---

## How to Run Tests

### Via Xcode
1. Open `Swiff IOS.xcodeproj`
2. Select "Swiff IOS" scheme
3. Press ⌘U or Product → Test
4. View results in Test Navigator (⌘6)

### Via Command Line
```bash
cd "/Users/narenreddyagula/Documents/[11] Swiff IOS /Swiff IOS"
xcodebuild test -scheme "Swiff IOS" -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Via Xcode Cloud / CI
Tests are compatible with Xcode Cloud and CI/CD pipelines.

---

## What This Testing Verifies

### ✅ Critical Bug Fix Verification
The tests verify the critical bug fix from Task 1.1.3:
- **Before**: PersonModel.toDomain() was losing id, balance, and createdDate
- **After**: All fields preserved (verified by `testPersonModelRoundTrip()`)

### ✅ Round-Trip Conversion Integrity
Every test follows the pattern:
1. Create domain model with test data
2. Convert to SwiftData model using `init(from:)`
3. Convert back to domain using `toDomain()`
4. Assert all fields match original

### ✅ Relationship Resolution
Tests verify complex relationship resolution:
- UUID arrays → PersonModel arrays (GroupModel members)
- Single UUID → PersonModel (GroupExpense paidBy)
- Nested model conversions (Group with Expenses)

### ✅ Enum Storage and Retrieval
Tests verify enum conversions for:
- AvatarType (with associated values)
- BillingCycle (6 cases)
- TransactionCategory (11 cases)
- SubscriptionCategory

### ✅ Optional Field Handling
Tests verify optional fields:
- receiptPath in GroupExpense
- notes, website, cancellationDate in Subscription
- All optionals preserved correctly

### ✅ Utility Method Functionality
Tests verify ModelConverter helper methods:
- Batch insertion methods
- Database statistics calculation
- Database clearing
- Empty state detection

---

## Test Results Summary

**Total Tests**: 12 test methods
**Models Covered**: 6 SwiftData models
**Domain Models Covered**: 5 domain models
**Enum Cases Tested**: 18 enum cases
**Relationship Tests**: 4 relationship resolution scenarios

### Expected Results
When all tests pass:
- ✅ All 12 tests pass
- ✅ No data loss in round-trip conversions
- ✅ All enums convert correctly
- ✅ All relationships resolve correctly
- ✅ Utility methods function as expected

---

## Future Test Enhancements

### Performance Tests
- Large batch insertion performance
- Query performance with indexes
- Relationship resolution performance

### Concurrency Tests
- Concurrent insertions
- Thread-safe model access
- ModelContext concurrency

### Edge Cases
- Empty arrays/optionals
- Very large data sets
- Unicode and emoji handling
- Invalid enum rawValues (defensive)

### Integration Tests
- Full app flow tests
- UI → Persistence → UI tests
- Migration tests (when migration is implemented)

---

## Conclusion

This comprehensive test suite provides confidence that:
1. The critical PersonModel bug is fixed
2. All convenience initializers work correctly
3. Round-trip conversions preserve data integrity
4. Relationship resolution works as expected
5. Utility methods function properly

**Task 1.1.3 Status**: ✅ COMPLETE
- All code implemented
- All tests written
- Documentation provided
