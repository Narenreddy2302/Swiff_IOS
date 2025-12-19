# MVVM Architecture Guidelines

## Purpose
Define the Model-View-ViewModel architecture pattern used throughout the Swiff iOS project, ensuring consistent separation of concerns and maintainable code structure.

## When to Use This Skill
- Designing new features or screens
- Refactoring existing code
- Reviewing architecture decisions
- Understanding data flow between components

---

## Architecture Overview

Swiff uses a modified MVVM pattern where:
- **Model** = Domain models + SwiftData models
- **ViewModel** = Service layer (DataManager, PersistenceService, etc.)
- **View** = SwiftUI views

```
┌─────────────────────────────────────────────────────────────┐
│                         VIEW                                 │
│  SwiftUI Views (@EnvironmentObject, @State, @Binding)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    VIEWMODEL (Services)                      │
│  DataManager (@Published, @MainActor, ObservableObject)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         MODEL                                │
│  DataModels (Codable) ←→ SwiftDataModels (@Model)           │
└─────────────────────────────────────────────────────────────┘
```

---

## Model Layer

### Domain Models (DataModels/)
Plain Swift structs used for business logic and UI:

```swift
// Swiff IOS/Models/DataModels/Subscription.swift
struct Subscription: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var price: Double
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var isActive: Bool = true
    var nextBillingDate: Date
    // ... additional properties
}
```

### Persistence Models (SwiftDataModels/)
@Model classes for SwiftData persistence:

```swift
// Swiff IOS/Models/SwiftDataModels/SubscriptionModel.swift
@Model
final class SubscriptionModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var subscriptionDescription: String
    var price: Double
    var billingCycleRaw: String  // Store enum as String
    var categoryRaw: String
    var isActive: Bool
    var nextBillingDate: Date

    // Convert to domain model
    func toDomain() -> Subscription {
        Subscription(
            id: id,
            name: name,
            description: subscriptionDescription,
            price: price,
            billingCycle: BillingCycle(rawValue: billingCycleRaw) ?? .monthly,
            category: SubscriptionCategory(rawValue: categoryRaw) ?? .other,
            isActive: isActive,
            nextBillingDate: nextBillingDate
        )
    }

    // Initialize from domain model
    convenience init(from subscription: Subscription) {
        self.init()
        self.id = subscription.id
        self.name = subscription.name
        // ... map all properties
    }
}
```

### Key Pattern: Dual Model Architecture
- **Domain models** for business logic, UI binding, and Codable serialization
- **SwiftData models** for persistence only
- **Conversion methods** to translate between them

---

## ViewModel Layer (Services)

### DataManager - Central State Management

```swift
// Swiff IOS/Services/DataManager.swift
@MainActor
class DataManager: ObservableObject {

    // MARK: - Singleton
    static let shared = DataManager()

    // MARK: - Published Properties
    @Published var people: [Person] = []
    @Published var groups: [Group] = []
    @Published var subscriptions: [Subscription] = []
    @Published var transactions: [Transaction] = []

    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties
    private let persistenceService = PersistenceService.shared

    // MARK: - Initialization
    private init() {
        // Private init for singleton
    }

    // MARK: - Data Loading
    func loadAllData() {
        isLoading = true
        error = nil

        do {
            people = try persistenceService.fetchAllPeople()
            subscriptions = try persistenceService.fetchAllSubscriptions()
            // ...
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - CRUD Operations
    func addSubscription(_ subscription: Subscription) throws {
        try persistenceService.saveSubscription(subscription)
        subscriptions.append(subscription)
    }

    func updateSubscription(_ subscription: Subscription) throws {
        try persistenceService.updateSubscription(subscription)
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        }
    }

    func deleteSubscription(id: UUID) throws {
        try persistenceService.deleteSubscription(id: id)
        subscriptions.removeAll { $0.id == id }
    }
}
```

### Key Patterns:
1. **Singleton** - Single source of truth via `static let shared`
2. **@MainActor** - Ensure UI updates on main thread
3. **@Published** - Reactive updates to views
4. **Private init** - Prevent multiple instances

---

## View Layer

### View with Environment Object

```swift
// Example view consuming DataManager
struct SubscriptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddSheet = false
    @State private var selectedFilter: SubscriptionFilter = .all

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSubscriptions) { subscription in
                    SubscriptionRow(subscription: subscription)
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSubscriptionSheet()
            }
        }
    }

    private var filteredSubscriptions: [Subscription] {
        // Filter logic using dataManager.subscriptions
        switch selectedFilter {
        case .all: return dataManager.subscriptions
        case .active: return dataManager.subscriptions.filter { $0.isActive }
        // ...
        }
    }
}
```

### App Entry Point - Environment Injection

```swift
// Swiff_IOSApp.swift
@main
struct Swiff_IOSApp: App {
    @StateObject private var dataManager = DataManager.shared

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

---

## State Management Patterns

### Local State (@State)
For view-specific, ephemeral state:

```swift
struct SubscriptionDetailView: View {
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var editedName: String = ""
}
```

### Binding (@Binding)
For two-way data flow to child views:

```swift
struct PriceInputField: View {
    @Binding var price: Double

    var body: some View {
        TextField("Price", value: $price, format: .currency(code: "USD"))
    }
}
```

### Environment Object (@EnvironmentObject)
For shared state across view hierarchy:

```swift
struct GroupDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    let group: Group

    var groupMembers: [Person] {
        dataManager.people.filter { group.members.contains($0.id) }
    }
}
```

### State Object (@StateObject)
For owning observable objects:

```swift
struct AnalyticsView: View {
    @StateObject private var analyticsService = AnalyticsService()

    var body: some View {
        // Use analyticsService
    }
}
```

---

## Dependency Injection

### Via Environment

```swift
// Inject at app level
ContentView()
    .environmentObject(DataManager.shared)
    .environmentObject(NotificationManager.shared)
```

### Via Initializer

```swift
struct PersonDetailView: View {
    let person: Person
    let onSave: (Person) -> Void

    init(person: Person, onSave: @escaping (Person) -> Void) {
        self.person = person
        self.onSave = onSave
    }
}
```

---

## Common Mistakes to Avoid

1. **Business Logic in Views**
   ```swift
   // BAD - Logic in view
   Button("Save") {
       if subscription.price > 0 && !subscription.name.isEmpty {
           try? persistenceService.saveSubscription(subscription)
       }
   }

   // GOOD - Logic in DataManager
   Button("Save") {
       try? dataManager.addSubscription(subscription)
   }
   ```

2. **Multiple Sources of Truth**
   ```swift
   // BAD - Separate arrays
   @State var localSubscriptions: [Subscription] = []

   // GOOD - Single source from DataManager
   @EnvironmentObject var dataManager: DataManager
   var subscriptions: [Subscription] { dataManager.subscriptions }
   ```

3. **Direct Persistence Access from Views**
   ```swift
   // BAD
   Button("Delete") {
       try? PersistenceService.shared.deleteSubscription(id: subscription.id)
   }

   // GOOD
   Button("Delete") {
       try? dataManager.deleteSubscription(id: subscription.id)
   }
   ```

---

## Checklist

- [ ] Domain model created in `Models/DataModels/`
- [ ] SwiftData model created with `toDomain()` method
- [ ] CRUD operations added to `PersistenceService`
- [ ] Business logic added to `DataManager`
- [ ] Views use `@EnvironmentObject` for DataManager
- [ ] Local state uses `@State` or `@Binding`
- [ ] No business logic in view layer

---

## Project References

| File | Purpose |
|------|---------|
| [DataManager.swift](../../Swiff%20IOS/Services/DataManager.swift) | Central ViewModel |
| [PersistenceService.swift](../../Swiff%20IOS/Services/PersistenceService.swift) | Data access layer |
| [Subscription.swift](../../Swiff%20IOS/Models/DataModels/Subscription.swift) | Domain model example |
| [SubscriptionModel.swift](../../Swiff%20IOS/Models/SwiftDataModels/SubscriptionModel.swift) | Persistence model example |

---

## Industry Standards

- **Apple WWDC 2023** - Data Flow Through SwiftUI
- **Clean Architecture** - Robert C. Martin
- **SOLID Principles** - Single Responsibility, Dependency Inversion
- **Swift API Design Guidelines** - Naming conventions
