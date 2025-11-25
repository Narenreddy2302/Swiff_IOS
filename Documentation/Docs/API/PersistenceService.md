# PersistenceService Documentation

## Overview

The `PersistenceService` is a comprehensive data service layer that provides a clean, type-safe API for all CRUD (Create, Read, Update, Delete) operations in the Swiff iOS application. It acts as an abstraction layer over SwiftData, handling validation, error management, and data persistence.

**File**: `Services/PersistenceService.swift`

## Architecture

### Design Pattern
- **Singleton Pattern**: Ensures single shared instance across the app
- **Repository Pattern**: Abstracts data access logic from business logic
- **Service Layer**: Centralized data operations with validation

### Key Features
- ✅ Full CRUD operations for all models
- ✅ Comprehensive validation before persistence
- ✅ Type-safe error handling with custom errors
- ✅ Thread-safe background task support
- ✅ Built-in analytics and statistics
- ✅ SwiftData integration with ModelContext
- ✅ Singleton and testable design

---

## Usage

### Basic Usage

```swift
import SwiftUI

struct ContentView: View {
    @State private var people: [Person] = []

    var body: some View {
        List(people) { person in
            Text(person.name)
        }
        .onAppear {
            loadPeople()
        }
    }

    private func loadPeople() {
        do {
            people = try PersistenceService.shared.fetchAllPeople()
        } catch {
            print("Error loading people: \(error.localizedDescription)")
        }
    }
}
```

### Accessing the Service

```swift
// Access singleton instance
let service = PersistenceService.shared

// For testing, create custom instance
let testContainer = /* create in-memory container */
let testService = PersistenceService(modelContainer: testContainer)
```

---

## API Reference

### Person Operations

#### Save Person
```swift
func savePerson(_ person: Person) throws
```

**Description**: Saves a new person or updates existing person if ID matches.

**Validation**:
- Name must not be empty
- Email must not be empty
- Email must be valid format

**Example**:
```swift
let person = Person(
    name: "John Doe",
    email: "john@example.com",
    phone: "+1234567890",
    avatarType: .emoji("👨")
)

do {
    try PersistenceService.shared.savePerson(person)
    print("Person saved successfully")
} catch let error as PersistenceError {
    print("Failed to save: \(error.localizedDescription)")
}
```

**Throws**: `PersistenceError.validationFailed`, `PersistenceError.saveFailed`

---

#### Fetch All People
```swift
func fetchAllPeople() throws -> [Person]
```

**Description**: Fetches all people sorted by name in ascending order.

**Example**:
```swift
let people = try PersistenceService.shared.fetchAllPeople()
print("Found \(people.count) people")
```

**Returns**: Array of `Person` domain models

**Throws**: `PersistenceError.fetchFailed`

---

#### Fetch Person by ID
```swift
func fetchPerson(byID id: UUID) throws -> Person?
```

**Description**: Fetches a specific person by their unique ID.

**Example**:
```swift
if let person = try PersistenceService.shared.fetchPerson(byID: personID) {
    print("Found: \(person.name)")
} else {
    print("Person not found")
}
```

**Returns**: Optional `Person` (nil if not found)

**Throws**: `PersistenceError.fetchFailed`

---

#### Update Person
```swift
func updatePerson(_ person: Person) throws
```

**Description**: Updates an existing person. Throws error if person doesn't exist.

**Example**:
```swift
var person = try PersistenceService.shared.fetchPerson(byID: personID)!
person.balance += 50.0
try PersistenceService.shared.updatePerson(person)
```

**Throws**: `PersistenceError.entityNotFound`, `PersistenceError.updateFailed`, `PersistenceError.validationFailed`

---

#### Delete Person
```swift
func deletePerson(id: UUID) throws
```

**Description**: Deletes a person by ID.

**Example**:
```swift
try PersistenceService.shared.deletePerson(id: personID)
```

**Throws**: `PersistenceError.entityNotFound`, `PersistenceError.deleteFailed`

---

#### Fetch People with Balances
```swift
func fetchPeopleWithBalances() throws -> [Person]
```

**Description**: Fetches only people with non-zero balances.

**Example**:
```swift
let peopleWithDebt = try PersistenceService.shared.fetchPeopleWithBalances()
```

---

#### Search People by Name
```swift
func searchPeople(byName searchTerm: String) throws -> [Person]
```

**Description**: Case-insensitive search for people by name.

**Example**:
```swift
let results = try PersistenceService.shared.searchPeople(byName: "John")
```

---

### Subscription Operations

#### Save Subscription
```swift
func saveSubscription(_ subscription: Subscription) throws
```

**Validation**:
- Name must not be empty
- Price must be greater than 0

**Example**:
```swift
let subscription = Subscription(
    name: "Netflix",
    description: "Streaming service",
    price: 15.99,
    billingCycle: .monthly,
    category: .entertainment,
    icon: "tv.fill",
    color: "#E50914"
)

try PersistenceService.shared.saveSubscription(subscription)
```

---

#### Fetch Active Subscriptions
```swift
func fetchActiveSubscriptions() throws -> [Subscription]
```

**Description**: Fetches only active (non-cancelled) subscriptions.

**Example**:
```swift
let activeSubscriptions = try PersistenceService.shared.fetchActiveSubscriptions()
```

---

#### Fetch Subscriptions Renewing Soon
```swift
func fetchSubscriptionsRenewingSoon(days: Int) throws -> [Subscription]
```

**Description**: Fetches active subscriptions renewing within specified days.

**Example**:
```swift
// Get subscriptions renewing in next 7 days
let renewingSoon = try PersistenceService.shared.fetchSubscriptionsRenewingSoon(days: 7)
```

---

### Transaction Operations

#### Save Transaction
```swift
func saveTransaction(_ transaction: Transaction) throws
```

**Validation**:
- Title must not be empty
- Amount must not be 0

**Example**:
```swift
let transaction = Transaction(
    id: UUID(),
    title: "Grocery Shopping",
    subtitle: "Whole Foods",
    amount: -125.50,
    category: .groceries,
    date: Date(),
    isRecurring: false,
    tags: ["food", "weekly"]
)

try PersistenceService.shared.saveTransaction(transaction)
```

---

#### Fetch Transactions in Date Range
```swift
func fetchTransactions(inDateRange range: ClosedRange<Date>) throws -> [Transaction]
```

**Description**: Fetches transactions within a specific date range.

**Example**:
```swift
let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
let endDate = Date()

let lastMonthTransactions = try PersistenceService.shared.fetchTransactions(
    inDateRange: startDate...endDate
)
```

---

#### Fetch Current Month Transactions
```swift
func fetchCurrentMonthTransactions() throws -> [Transaction]
```

**Description**: Convenience method to fetch all transactions for the current month.

**Example**:
```swift
let thisMonth = try PersistenceService.shared.fetchCurrentMonthTransactions()
```

---

#### Fetch Recurring Transactions
```swift
func fetchRecurringTransactions() throws -> [Transaction]
```

**Description**: Fetches all recurring transactions.

**Example**:
```swift
let recurring = try PersistenceService.shared.fetchRecurringTransactions()
```

---

### Group Operations

#### Save Group
```swift
func saveGroup(_ group: Group) throws
```

**Validation**:
- Name must not be empty
- Must have at least one member

**Example**:
```swift
let group = Group(
    name: "Weekend Trip",
    description: "Trip to the mountains",
    emoji: "🏔️",
    members: [person1.id, person2.id]
)

try PersistenceService.shared.saveGroup(group)
```

---

#### Fetch Groups with Unsettled Expenses
```swift
func fetchGroupsWithUnsettledExpenses() throws -> [Group]
```

**Description**: Fetches groups that have at least one unsettled expense.

**Example**:
```swift
let groupsWithDebt = try PersistenceService.shared.fetchGroupsWithUnsettledExpenses()
```

---

### Group Expense Operations

#### Save Group Expense
```swift
func saveGroupExpense(_ expense: GroupExpense, forGroup groupID: UUID) throws
```

**Validation**:
- Title must not be empty
- Amount must be greater than 0
- Must have at least one person to split between

**Example**:
```swift
let expense = GroupExpense(
    title: "Hotel",
    amount: 300.0,
    paidBy: person1.id,
    splitBetween: [person1.id, person2.id],
    category: .travel,
    notes: "2 nights",
    receipt: nil,
    isSettled: false
)

try PersistenceService.shared.saveGroupExpense(expense, forGroup: groupID)
```

---

#### Fetch Unsettled Expenses
```swift
func fetchUnsettledExpenses() throws -> [GroupExpense]
```

**Description**: Fetches all expenses that haven't been settled yet.

**Example**:
```swift
let unsettled = try PersistenceService.shared.fetchUnsettledExpenses()
```

---

#### Settle Expense
```swift
func settleExpense(id: UUID) throws
```

**Description**: Marks an expense as settled.

**Example**:
```swift
try PersistenceService.shared.settleExpense(id: expenseID)
```

---

### Statistics and Analytics

#### Calculate Total Monthly Cost
```swift
func calculateTotalMonthlyCost() throws -> Double
```

**Description**: Calculates the total monthly cost of all active subscriptions, normalizing different billing cycles to monthly equivalents.

**Example**:
```swift
let monthlyCost = try PersistenceService.shared.calculateTotalMonthlyCost()
print("Total monthly subscriptions: $\(monthlyCost)")
```

**Calculation**:
- Weekly: `price * 4.33`
- Monthly: `price`
- Quarterly: `price / 3`
- Semi-annually: `price / 6`
- Annually: `price / 12`
- Lifetime: `0`

---

#### Calculate Monthly Income
```swift
func calculateMonthlyIncome() throws -> Double
```

**Description**: Calculates total income for the current month (positive transactions).

**Example**:
```swift
let income = try PersistenceService.shared.calculateMonthlyIncome()
```

---

#### Calculate Monthly Expenses
```swift
func calculateMonthlyExpenses() throws -> Double
```

**Description**: Calculates total expenses for the current month (negative transactions, returned as positive value).

**Example**:
```swift
let expenses = try PersistenceService.shared.calculateMonthlyExpenses()
let income = try PersistenceService.shared.calculateMonthlyIncome()
let netIncome = income - expenses
```

---

### Context Management

#### Save Context
```swift
func saveContext() throws
```

**Description**: Manually saves the ModelContext. Usually called internally after operations.

**Throws**: `PersistenceError.saveFailed`

---

#### Perform Background Task
```swift
func performBackgroundTask<T>(_ block: @escaping @Sendable (ModelContext) throws -> T) async throws -> T
```

**Description**: Performs a task on a background context, useful for expensive operations.

**Example**:
```swift
let stats = try await PersistenceService.shared.performBackgroundTask { context in
    // Perform expensive calculation
    let descriptor = FetchDescriptor<PersonModel>()
    let people = try context.fetch(descriptor)
    return people.count
}
```

---

## Error Handling

### PersistenceError Enum

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
}
```

### Error Descriptions

| Error | Description | When It Occurs |
|-------|-------------|----------------|
| `saveFailed` | Failed to save data | Context save fails |
| `fetchFailed` | Failed to fetch data | Fetch operation fails |
| `deleteFailed` | Failed to delete data | Delete operation fails |
| `updateFailed` | Failed to update data | Update operation fails |
| `entityNotFound` | Entity with ID not found | Update/delete non-existent entity |
| `validationFailed` | Validation failed | Invalid data before save |
| `contextError` | Context error | ModelContext issues |
| `relationshipError` | Relationship error | Invalid relationship setup |

### Error Handling Pattern

```swift
do {
    try PersistenceService.shared.savePerson(person)
} catch let error as PersistenceError {
    switch error {
    case .validationFailed(let reason):
        showAlert("Validation Error", message: reason)
    case .saveFailed(let underlying):
        showAlert("Save Failed", message: underlying.localizedDescription)
    case .entityNotFound(let id):
        showAlert("Not Found", message: "Entity \(id) not found")
    default:
        showAlert("Error", message: error.localizedDescription)
    }
} catch {
    showAlert("Unexpected Error", message: error.localizedDescription)
}
```

---

## Validation Rules

### Person Validation
- ✅ Name: Must not be empty or whitespace
- ✅ Email: Must not be empty
- ✅ Email: Must match valid email regex pattern
- ✅ Phone: No validation (optional field)

### Subscription Validation
- ✅ Name: Must not be empty or whitespace
- ✅ Price: Must be greater than 0
- ✅ Description: No validation
- ✅ Other fields: No validation

### Transaction Validation
- ✅ Title: Must not be empty or whitespace
- ✅ Amount: Must not be 0
- ✅ Subtitle: No validation
- ✅ Tags: No validation

### Group Validation
- ✅ Name: Must not be empty or whitespace
- ✅ Members: Must have at least one member
- ✅ Description: No validation

### GroupExpense Validation
- ✅ Title: Must not be empty or whitespace
- ✅ Amount: Must be greater than 0
- ✅ SplitBetween: Must have at least one person
- ✅ Notes: No validation

---

## Testing

### Unit Tests

Comprehensive test suite in `PersistenceServiceTests.swift`:

**Coverage**:
- ✅ CRUD operations for all models
- ✅ Validation error handling
- ✅ Search and query operations
- ✅ Statistics calculations
- ✅ Error cases (not found, invalid data)
- ✅ Date range queries
- ✅ Relationship handling

**Test Count**: 30+ test methods

**How to Run**:
```bash
# Via Xcode
⌘U

# Via command line
xcodebuild test -scheme "Swiff IOS" -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Example Test
```swift
@Test("Save and fetch person")
func testSaveAndFetchPerson() async throws {
    let service = createTestService()

    let person = Person(
        name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        avatarType: .emoji("👨")
    )

    try service.savePerson(person)

    let fetchedPeople = try service.fetchAllPeople()
    #expect(fetchedPeople.count == 1)
    #expect(fetchedPeople.first?.name == "John Doe")
}
```

---

## Best Practices

### 1. Always Handle Errors
```swift
// ✅ Good
do {
    try PersistenceService.shared.savePerson(person)
} catch {
    handleError(error)
}

// ❌ Bad
try? PersistenceService.shared.savePerson(person) // Silently fails
```

### 2. Use Specific Fetch Methods
```swift
// ✅ Good - Use specific methods
let activeSubscriptions = try PersistenceService.shared.fetchActiveSubscriptions()

// ❌ Less efficient - Filter after fetching
let allSubscriptions = try PersistenceService.shared.fetchAllSubscriptions()
let active = allSubscriptions.filter { $0.isActive }
```

### 3. Validate Before Saving
The service automatically validates, but pre-validate in UI for better UX:
```swift
// ✅ Good - Validate in UI
guard isValidEmail(email) else {
    showError("Invalid email")
    return
}
try PersistenceService.shared.savePerson(person)
```

### 4. Use Background Tasks for Heavy Operations
```swift
// ✅ Good - Use background task for expensive work
let result = try await PersistenceService.shared.performBackgroundTask { context in
    // Heavy calculation
    return result
}

// ❌ Bad - Block main thread
let result = try PersistenceService.shared.fetchAllTransactions() // If very large
```

### 5. Update vs Save
```swift
// For existing entities, use update:
try PersistenceService.shared.updatePerson(person)

// For new or uncertain, use save:
try PersistenceService.shared.savePerson(person) // Upsert behavior
```

---

## Integration with SwiftUI

### Using with @State
```swift
struct PeopleListView: View {
    @State private var people: [Person] = []
    @State private var errorMessage: String?

    var body: some View {
        List(people) { person in
            PersonRow(person: person)
        }
        .onAppear(perform: loadPeople)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadPeople() {
        do {
            people = try PersistenceService.shared.fetchAllPeople()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Using with Observable Object
```swift
@MainActor
class PeopleViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var errorMessage: String?

    private let service = PersistenceService.shared

    func loadPeople() {
        do {
            people = try service.fetchAllPeople()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addPerson(_ person: Person) {
        do {
            try service.savePerson(person)
            loadPeople() // Refresh
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## Performance Considerations

1. **Batch Operations**: For bulk inserts, use `ModelConverter.insertPeople()` instead of looping `savePerson()`

2. **Lazy Loading**: Fetch only what you need using specific methods (e.g., `fetchActiveSubscriptions()`)

3. **Background Tasks**: Use `performBackgroundTask()` for heavy operations

4. **Caching**: Consider caching frequently accessed data in ViewModels

---

## Future Enhancements

Potential future additions:
- [ ] Batch delete operations
- [ ] Transaction support (rollback capabilities)
- [ ] Query builder pattern
- [ ] Pagination support for large datasets
- [ ] iCloud sync support
- [ ] Data export/import
- [ ] Undo/redo support

---

## Conclusion

The `PersistenceService` provides a robust, type-safe, and validated data access layer for the Swiff iOS application. It follows best practices for error handling, validation, and SwiftData integration, making it easy to work with persisted data throughout the app.

**Key Takeaways**:
- ✅ Single source of truth for all data operations
- ✅ Comprehensive validation before persistence
- ✅ Clear error handling with custom errors
- ✅ Extensive test coverage
- ✅ Thread-safe background task support
- ✅ Built-in analytics and statistics
