# DataManager Documentation

## Overview

The `DataManager` is a centralized, observable state manager that bridges the persistence layer (PersistenceService) with the UI layer (SwiftUI Views). It manages all app data in memory while keeping it synchronized with SwiftData persistence.

**File**: `Services/DataManager.swift`

## Purpose

- **Single Source of Truth**: Centralized data management for the entire app
- **Reactive Updates**: SwiftUI views automatically update when data changes
- **Persistence Integration**: Seamlessly syncs with SwiftData through PersistenceService
- **First Launch Handling**: Automatically populates sample data on first app launch
- **Error Management**: Centralized error handling for data operations

---

## Architecture

```
┌─────────────────┐
│  SwiftUI Views  │
│   (ContentView) │
└────────┬────────┘
         │ @EnvironmentObject
         │
┌────────▼────────┐
│   DataManager   │ ← @MainActor, ObservableObject
│                 │ ← @Published properties
└────────┬────────┘
         │ Uses
         │
┌────────▼──────────────┐
│  PersistenceService   │
└────────┬──────────────┘
         │ Uses
         │
┌────────▼────────┐
│    SwiftData    │
│  (ModelContext) │
└─────────────────┘
```

---

## Key Features

### 1. Published Properties
All data is automatically reactive:
```swift
@Published var people: [Person] = []
@Published var groups: [Group] = []
@Published var subscriptions: [Subscription] = []
@Published var transactions: [Transaction] = []
@Published var isLoading = false
@Published var error: Error?
```

### 2. First Launch Detection
```swift
private let firstLaunchKey = "HasLaunchedBefore"
@Published var isFirstLaunch = false
```

Automatically detects first launch and populates sample data.

### 3. CRUD Operations for All Models
Complete create, read, update, delete operations for:
- People
- Groups
- Subscriptions
- Transactions
- Group Expenses

### 4. Statistics & Analytics
- Monthly subscription costs
- Monthly income/expenses
- Net monthly income
- Unsettled group expenses

---

## Usage

### App-Wide Setup

In `Swiff_IOSApp.swift`:
```swift
@main
struct Swiff_IOSApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onAppear {
                    dataManager.loadAllData()
                }
        }
    }
}
```

### In Views

```swift
struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        List(dataManager.people) { person in
            Text(person.name)
        }
    }
}
```

---

## API Reference

### Data Loading

#### `loadAllData()`
```swift
func loadAllData()
```

**Description**: Loads all data from persistence. If database is empty and it's first launch, populates sample data.

**Usage**:
```swift
dataManager.loadAllData()
```

**Side Effects**:
- Sets `isLoading = true` during load
- Sets `error` if loading fails
- Populates sample data on first launch with empty database
- Updates all `@Published` arrays

**Console Output**:
```
✅ Data loaded successfully:
   - People: 5
   - Groups: 2
   - Subscriptions: 3
   - Transactions: 4
```

---

#### `refreshAllData()`
```swift
func refreshAllData()
```

**Description**: Alias for `loadAllData()`. Useful for pull-to-refresh functionality.

---

### Person Operations

#### `addPerson(_:)`
```swift
func addPerson(_ person: Person) throws
```

**Usage**:
```swift
let person = Person(name: "John", email: "john@email.com", phone: "123", avatarType: .emoji("👨"))
try dataManager.addPerson(person)
```

**Side Effects**:
- Saves to persistence via PersistenceService
- Appends to `people` array
- Triggers SwiftUI update

---

#### `updatePerson(_:)`
```swift
func updatePerson(_ person: Person) throws
```

**Usage**:
```swift
var person = dataManager.people[0]
person.balance += 50
try dataManager.updatePerson(person)
```

---

#### `deletePerson(id:)`
```swift
func deletePerson(id: UUID) throws
```

**Usage**:
```swift
try dataManager.deletePerson(id: personID)
```

---

#### `searchPeople(byName:)`
```swift
func searchPeople(byName searchTerm: String) -> [Person]
```

**Description**: In-memory search (case-insensitive).

**Usage**:
```swift
let results = dataManager.searchPeople(byName: "John")
```

---

### Group Operations

#### `addGroup(_:)`
```swift
func addGroup(_ group: Group) throws
```

**Usage**:
```swift
let group = Group(
    name: "Weekend Trip",
    description: "Hiking",
    emoji: "🏔️",
    members: [person1.id, person2.id]
)
try dataManager.addGroup(group)
```

---

#### `updateGroup(_:)`
```swift
func updateGroup(_ group: Group) throws
```

---

#### `deleteGroup(id:)`
```swift
func deleteGroup(id: UUID) throws
```

---

#### `fetchGroupsWithUnsettledExpenses()`
```swift
func fetchGroupsWithUnsettledExpenses() -> [Group]
```

**Description**: Returns groups that have at least one unsettled expense.

**Usage**:
```swift
let groupsWithDebt = dataManager.fetchGroupsWithUnsettledExpenses()
```

---

### Subscription Operations

#### `addSubscription(_:)`
```swift
func addSubscription(_ subscription: Subscription) throws
```

**Usage**:
```swift
let subscription = Subscription(
    name: "Netflix",
    description: "Streaming",
    price: 15.99,
    billingCycle: .monthly,
    category: .entertainment,
    icon: "tv.fill",
    color: "#E50914"
)
try dataManager.addSubscription(subscription)
```

---

#### `updateSubscription(_:)`
```swift
func updateSubscription(_ subscription: Subscription) throws
```

---

#### `deleteSubscription(id:)`
```swift
func deleteSubscription(id: UUID) throws
```

---

#### `getActiveSubscriptions()`
```swift
func getActiveSubscriptions() -> [Subscription]
```

**Description**: Returns only active subscriptions (in-memory filter).

**Usage**:
```swift
let activeSubscriptions = dataManager.getActiveSubscriptions()
```

---

#### `getInactiveSubscriptions()`
```swift
func getInactiveSubscriptions() -> [Subscription]
```

---

### Transaction Operations

#### `addTransaction(_:)`
```swift
func addTransaction(_ transaction: Transaction) throws
```

**Usage**:
```swift
let transaction = Transaction(
    id: UUID(),
    title: "Grocery Shopping",
    subtitle: "Whole Foods",
    amount: -125.50,
    category: .groceries,
    date: Date(),
    isRecurring: false,
    tags: ["food"]
)
try dataManager.addTransaction(transaction)
```

**Note**: Automatically keeps transactions sorted by date (newest first).

---

#### `updateTransaction(_:)`
```swift
func updateTransaction(_ transaction: Transaction) throws
```

---

#### `deleteTransaction(id:)`
```swift
func deleteTransaction(id: UUID) throws
```

---

#### `getCurrentMonthTransactions()`
```swift
func getCurrentMonthTransactions() -> [Transaction]
```

**Description**: Returns transactions for current calendar month (in-memory filter).

**Usage**:
```swift
let thisMonth = dataManager.getCurrentMonthTransactions()
```

---

#### `getRecurringTransactions()`
```swift
func getRecurringTransactions() -> [Transaction]
```

---

### Group Expense Operations

#### `addGroupExpense(_:toGroup:)`
```swift
func addGroupExpense(_ expense: GroupExpense, toGroup groupID: UUID) throws
```

**Usage**:
```swift
let expense = GroupExpense(
    title: "Hotel",
    amount: 300.00,
    paidBy: person1.id,
    splitBetween: [person1.id, person2.id],
    category: .travel,
    notes: "2 nights",
    receipt: nil,
    isSettled: false
)
try dataManager.addGroupExpense(expense, toGroup: groupID)
```

**Side Effects**:
- Saves to persistence
- Appends to group's expenses array
- Updates group's totalAmount

---

#### `settleExpense(id:inGroup:)`
```swift
func settleExpense(id: UUID, inGroup groupID: UUID) throws
```

**Description**: Marks an expense as settled.

**Usage**:
```swift
try dataManager.settleExpense(id: expenseID, inGroup: groupID)
```

---

### Statistics & Analytics

#### `calculateTotalMonthlyCost()`
```swift
func calculateTotalMonthlyCost() -> Double
```

**Description**: Calculates total monthly cost of all active subscriptions, normalizing different billing cycles.

**Usage**:
```swift
let monthlyCost = dataManager.calculateTotalMonthlyCost()
// Returns: 45.99 (for example)
```

**Calculation**:
- Weekly: `price * 4.33`
- Monthly: `price`
- Quarterly: `price / 3`
- Semi-annually: `price / 6`
- Annually: `price / 12`
- Lifetime: `0`

---

#### `calculateMonthlyIncome()`
```swift
func calculateMonthlyIncome() -> Double
```

**Description**: Sum of positive transactions in current month.

**Usage**:
```swift
let income = dataManager.calculateMonthlyIncome()
```

---

#### `calculateMonthlyExpenses()`
```swift
func calculateMonthlyExpenses() -> Double
```

**Description**: Absolute sum of negative transactions in current month.

**Usage**:
```swift
let expenses = dataManager.calculateMonthlyExpenses()
```

---

#### `getNetMonthlyIncome()`
```swift
func getNetMonthlyIncome() -> Double
```

**Description**: Monthly income minus monthly expenses.

**Usage**:
```swift
let netIncome = dataManager.getNetMonthlyIncome()
// Positive = surplus, Negative = deficit
```

---

### Utility Methods

#### `clearAllData()`
```swift
func clearAllData() throws
```

**Description**: Clears all in-memory data arrays.

**Note**: Currently only clears memory. Persistence clearing not yet implemented.

---

#### `resetToSampleData()`
```swift
func resetToSampleData() throws
```

**Description**: Clears all data and repopulates with sample data.

**Usage**:
```swift
try dataManager.resetToSampleData()
```

---

## Computed Properties

### `hasData: Bool`
```swift
var hasData: Bool
```

Returns `true` if any data exists in memory.

---

### Data Counts
```swift
var peopleCount: Int
var groupsCount: Int
var subscriptionsCount: Int
var transactionsCount: Int
```

Convenient count properties.

---

## First Launch Flow

### First Launch Detection

1. **App Launch**: `checkFirstLaunch()` called in `init()`
2. **Check UserDefaults**: Reads `HasLaunchedBefore` key
3. **Set Flag**: `isFirstLaunch = true` if not found

### Data Loading with First Launch

1. **Load Data**: `loadAllData()` fetches from persistence
2. **Check Empty**: If `!hasData && isFirstLaunch`
3. **Populate**: Calls `populateSampleData()`
4. **Reload**: Fetches data again to populate arrays
5. **Mark Complete**: Sets `HasLaunchedBefore = true`

### Sample Data Included

**People** (5):
- Emma Wilson (👩‍💼)
- James Chen (👨‍💻)
- Sofia Rodriguez (👩‍🎨)
- Michael Taylor (👨‍🍳)
- Aisha Patel (👩‍⚕️)

**Subscriptions** (3):
- Netflix ($15.99/month)
- Spotify ($9.99/month)
- Gym Membership ($49.99/month)

**Transactions** (4):
- Salary ($5000 - Income)
- Rent (-$1500 - Utilities)
- Grocery Shopping (-$125.50 - Groceries)
- Dinner (-$85 - Dining)

**Groups** (2):
- Weekend Trip (3 members, 1 expense)
- Dinner Club (3 members, 1 settled expense)

---

## Integration with ContentView

### Before (Old Approach)
```swift
struct ContentView: View {
    @State private var people: [Person] = Person.samplePeople
    @State private var groups: [Group] = []
    @State private var subscriptions: [Subscription] = Subscription.sampleSubscriptions

    var body: some View {
        // Use local @State variables
    }
}
```

### After (New Approach)
```swift
struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        // Use dataManager.people, dataManager.subscriptions, etc.
        List(dataManager.people) { person in
            PersonRow(person: person)
        }
    }

    func addPerson() {
        do {
            try dataManager.addPerson(newPerson)
        } catch {
            // Handle error
        }
    }
}
```

---

## Error Handling

### Error Property
```swift
@Published var error: Error?
```

**Usage in Views**:
```swift
if let error = dataManager.error {
    Text("Error: \(error.localizedDescription)")
        .foregroundColor(.red)
}
```

### Try-Catch Pattern
```swift
do {
    try dataManager.addPerson(person)
} catch let error as PersistenceError {
    switch error {
    case .validationFailed(let reason):
        showAlert("Validation Error", message: reason)
    case .saveFailed:
        showAlert("Save Failed", message: "Could not save person")
    default:
        showAlert("Error", message: error.localizedDescription)
    }
} catch {
    showAlert("Unexpected Error", message: error.localizedDescription)
}
```

---

## Loading States

### Using isLoading
```swift
@Published var isLoading = false
```

**Usage in Views**:
```swift
if dataManager.isLoading {
    ProgressView("Loading data...")
} else {
    // Show content
}
```

**Pull-to-Refresh Example**:
```swift
List(dataManager.people) { person in
    PersonRow(person: person)
}
.refreshable {
    dataManager.refreshAllData()
}
```

---

## Console Logging

DataManager provides helpful console output:

### On Load Success
```
✅ Data loaded successfully:
   - People: 5
   - Groups: 2
   - Subscriptions: 3
   - Transactions: 4
```

### On First Launch
```
📝 Populating sample data...
✅ Sample data populated successfully!
✅ First launch complete
```

### On CRUD Operations
```
✅ Person added: John Doe
✅ Subscription updated: Netflix
✅ Group deleted
✅ Transaction added: Grocery Shopping
```

### On Errors
```
❌ Error loading data: [error description]
```

---

## Best Practices

### 1. Always Access Data Through DataManager
```swift
// ✅ Good
List(dataManager.people) { person in ... }

// ❌ Bad
@State private var localPeople = dataManager.people // Breaks reactivity
```

### 2. Handle Errors Appropriately
```swift
// ✅ Good
do {
    try dataManager.addPerson(person)
} catch {
    showErrorAlert(error)
}

// ❌ Bad
try? dataManager.addPerson(person) // Silent failure
```

### 3. Use EnvironmentObject for Deep View Hierarchies
```swift
// ✅ Good
@EnvironmentObject var dataManager: DataManager

// ❌ Bad (for deep hierarchies)
// Passing dataManager through 5+ view levels as @Binding or parameter
```

### 4. Leverage Computed Methods
```swift
// ✅ Good
let activeSubscriptions = dataManager.getActiveSubscriptions()

// ❌ Less efficient
let activeSubscriptions = dataManager.subscriptions.filter { $0.isActive }
```

---

## Migration Guide

### Updating Existing Views

**Step 1**: Add `@EnvironmentObject`
```swift
@EnvironmentObject var dataManager: DataManager
```

**Step 2**: Remove `@State` arrays
```swift
// Remove these:
// @State private var people: [Person] = []
// @State private var subscriptions: [Subscription] = []
```

**Step 3**: Replace references
```swift
// Before:
List(people) { person in ... }

// After:
List(dataManager.people) { person in ... }
```

**Step 4**: Update mutations
```swift
// Before:
people.append(newPerson)

// After:
try dataManager.addPerson(newPerson)
```

---

## Performance Considerations

### In-Memory Operations
Most filter/search operations happen in-memory for fast performance:
- `searchPeople(byName:)` - In-memory search
- `getActiveSubscriptions()` - In-memory filter
- `getCurrentMonthTransactions()` - In-memory filter

### Persistence Operations
All CRUD operations sync with persistence:
- `addPerson()` - Saves to SwiftData
- `updateGroup()` - Updates SwiftData
- `deleteTransaction()` - Removes from SwiftData

### Optimization Tips
1. Use computed methods instead of re-filtering
2. Batch operations when possible
3. Avoid unnecessary `loadAllData()` calls

---

## Future Enhancements

Potential additions:
- [ ] Search caching
- [ ] Pagination for large datasets
- [ ] Undo/redo support
- [ ] Export/import functionality
- [ ] iCloud sync integration
- [ ] Background refresh
- [ ] Data validation before persistence
- [ ] Optimistic UI updates

---

## Conclusion

The `DataManager` provides a clean, reactive, and centralized way to manage all app data. It seamlessly integrates SwiftData persistence with SwiftUI's reactive programming model, handling first launch, sample data, error management, and CRUD operations for all models.

**Key Benefits**:
- ✅ Single source of truth
- ✅ Automatic SwiftUI updates
- ✅ Persistent data storage
- ✅ First launch handling
- ✅ Comprehensive error management
- ✅ Built-in analytics
- ✅ Clean API for views
