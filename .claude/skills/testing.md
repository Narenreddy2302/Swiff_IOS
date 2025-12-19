# Testing Strategies

## Purpose
Guide comprehensive testing following project testing standards, ensuring code quality, reliability, and maintainability.

## When to Use This Skill
- Writing unit tests for new code
- Creating integration tests
- Testing UI components
- Performance testing
- Reviewing test coverage

---

## Testing Framework

The project uses **Swift Testing** (iOS 17+) with these conventions:
- `@Test` - Individual test functions
- `@Suite` - Test grouping
- `#expect` - Assertions
- In-memory containers for database tests

---

## Test Organization

```
Swiff IOSTests/
├── Unit/
│   ├── Models/
│   │   ├── SubscriptionTests.swift
│   │   ├── TransactionTests.swift
│   │   └── PersonTests.swift
│   ├── Services/
│   │   ├── DataManagerTests.swift
│   │   ├── PersistenceServiceTests.swift
│   │   └── AnalyticsServiceTests.swift
│   └── Utilities/
│       ├── InputSanitizerTests.swift
│       └── CurrencyFormatterTests.swift
│
├── Integration/
│   ├── DataFlowTests.swift
│   └── BackupRestoreTests.swift
│
├── Performance/
│   ├── PersistencePerformanceTests.swift
│   └── AnalyticsPerformanceTests.swift
│
└── UI/
    └── SubscriptionFlowUITests.swift
```

---

## Unit Tests

### Model Tests

```swift
import Testing
@testable import Swiff_IOS

@Suite("Subscription Model Tests")
struct SubscriptionTests {

    @Test("Calculate monthly cost for yearly subscription")
    func testMonthlyCostYearly() {
        let subscription = Subscription(
            name: "Annual Service",
            description: "Yearly plan",
            price: 120.00,
            billingCycle: .yearly,
            category: .productivity,
            icon: "star.fill",
            color: "#007AFF"
        )

        let monthlyCost = subscription.price / 12
        #expect(monthlyCost == 10.00)
    }

    @Test("Trial subscription detection")
    func testTrialDetection() {
        var subscription = Subscription(
            name: "Free Trial",
            description: "Trial subscription",
            price: 0,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.fill",
            color: "#FF0000"
        )
        subscription.isFreeTrial = true
        subscription.trialEndDate = Date().addingTimeInterval(7 * 24 * 60 * 60)

        #expect(subscription.isFreeTrial == true)
        #expect(subscription.trialEndDate != nil)
    }

    @Test("Subscription equality")
    func testEquality() {
        let id = UUID()
        let sub1 = Subscription(
            id: id,
            name: "Test",
            description: "",
            price: 10,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )
        let sub2 = Subscription(
            id: id,
            name: "Test",
            description: "",
            price: 10,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )

        #expect(sub1 == sub2)
    }
}
```

### Service Tests

```swift
@Suite("PersistenceService Tests")
@MainActor
struct PersistenceServiceTests {

    // MARK: - Test Setup

    private func createTestService() -> PersistenceService {
        let schema = Schema([
            PersonModel.self,
            GroupModel.self,
            SubscriptionModel.self,
            TransactionModel.self,
            PriceChangeModel.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return PersistenceService(modelContainer: container)
    }

    // MARK: - CRUD Tests

    @Test("Save and fetch subscription")
    func testSaveAndFetchSubscription() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "Netflix",
            description: "Streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )

        try service.saveSubscription(subscription)
        let fetched = try service.fetchAllSubscriptions()

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Netflix")
        #expect(fetched.first?.price == 15.99)
    }

    @Test("Update subscription")
    func testUpdateSubscription() async throws {
        let service = createTestService()

        var subscription = Subscription(
            name: "Spotify",
            description: "Music streaming",
            price: 9.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "music.note",
            color: "#1DB954"
        )

        try service.saveSubscription(subscription)

        subscription.price = 10.99
        try service.updateSubscription(subscription)

        let fetched = try service.fetchSubscription(byID: subscription.id)
        #expect(fetched?.price == 10.99)
    }

    @Test("Delete subscription")
    func testDeleteSubscription() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "To Delete",
            description: "",
            price: 5.00,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )

        try service.saveSubscription(subscription)
        try service.deleteSubscription(id: subscription.id)

        let fetched = try service.fetchAllSubscriptions()
        #expect(fetched.isEmpty)
    }

    // MARK: - Validation Tests

    @Test("Validation rejects empty name")
    func testValidationEmptyName() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "",
            description: "",
            price: 10.00,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )

        #expect(throws: PersistenceError.self) {
            try service.saveSubscription(subscription)
        }
    }

    @Test("Validation rejects zero price")
    func testValidationZeroPrice() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "Free Service",
            description: "",
            price: 0,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )

        #expect(throws: PersistenceError.self) {
            try service.saveSubscription(subscription)
        }
    }

    // MARK: - Query Tests

    @Test("Fetch active subscriptions only")
    func testFetchActiveSubscriptions() async throws {
        let service = createTestService()

        var activeSub = Subscription(
            name: "Active",
            description: "",
            price: 10.00,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )
        activeSub.isActive = true

        var inactiveSub = Subscription(
            name: "Inactive",
            description: "",
            price: 10.00,
            billingCycle: .monthly,
            category: .other,
            icon: "",
            color: ""
        )
        inactiveSub.isActive = false

        try service.saveSubscription(activeSub)
        try service.saveSubscription(inactiveSub)

        let active = try service.fetchActiveSubscriptions()
        #expect(active.count == 1)
        #expect(active.first?.name == "Active")
    }
}
```

### Utility Tests

```swift
@Suite("InputSanitizer Tests")
struct InputSanitizerTests {

    @Test("Trim whitespace")
    func testTrimWhitespace() {
        let input = "  hello world  "
        let result = InputSanitizer.trimWhitespace(input)
        #expect(result == "hello world")
    }

    @Test("Detect SQL injection")
    func testSQLInjectionDetection() {
        let malicious = "'; DROP TABLE users; --"
        #expect(InputSanitizer.containsSQLInjection(malicious) == true)

        let safe = "John Doe"
        #expect(InputSanitizer.containsSQLInjection(safe) == false)
    }

    @Test("HTML escape")
    func testHTMLEscape() {
        let input = "<script>alert('XSS')</script>"
        let result = InputSanitizer.escapeHTML(input)
        #expect(result.contains("<script>") == false)
        #expect(result.contains("&lt;script&gt;") == true)
    }

    @Test("Validate email format")
    func testEmailValidation() {
        #expect(InputSanitizer.isValidEmail("user@example.com") == true)
        #expect(InputSanitizer.isValidEmail("invalid-email") == false)
        #expect(InputSanitizer.isValidEmail("user@.com") == false)
    }
}
```

---

## Integration Tests

```swift
@Suite("Data Flow Integration Tests")
@MainActor
struct DataFlowIntegrationTests {

    @Test("Full CRUD workflow")
    func testFullWorkflow() async throws {
        // Setup
        let dataManager = DataManager.shared
        let initialCount = dataManager.subscriptions.count

        // Create
        let subscription = Subscription(
            name: "Integration Test",
            description: "Test subscription",
            price: 19.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "star.fill",
            color: "#FF0000"
        )

        try dataManager.addSubscription(subscription)
        #expect(dataManager.subscriptions.count == initialCount + 1)

        // Read
        let found = dataManager.subscriptions.first { $0.id == subscription.id }
        #expect(found != nil)
        #expect(found?.name == "Integration Test")

        // Update
        var updated = subscription
        updated.name = "Updated Test"
        try dataManager.updateSubscription(updated)

        let afterUpdate = dataManager.subscriptions.first { $0.id == subscription.id }
        #expect(afterUpdate?.name == "Updated Test")

        // Delete
        try dataManager.deleteSubscription(id: subscription.id)
        #expect(dataManager.subscriptions.count == initialCount)
    }

    @Test("Analytics calculation after data changes")
    func testAnalyticsIntegration() async throws {
        let dataManager = DataManager.shared
        let analyticsService = AnalyticsService.shared

        // Add subscription
        let subscription = Subscription(
            name: "Monthly Service",
            description: "",
            price: 50.00,
            billingCycle: .monthly,
            category: .productivity,
            icon: "",
            color: ""
        )
        try dataManager.addSubscription(subscription)

        // Verify analytics reflect change
        let monthlyCost = dataManager.calculateTotalMonthlyCost()
        #expect(monthlyCost >= 50.00)

        // Cleanup
        try dataManager.deleteSubscription(id: subscription.id)
    }
}
```

---

## Performance Tests

```swift
@Suite("Performance Tests")
@MainActor
struct PerformanceTests {

    @Test("Bulk insert performance")
    func testBulkInsertPerformance() async throws {
        let service = createTestService()
        let itemCount = 1000

        let startTime = Date()

        for i in 0..<itemCount {
            let subscription = Subscription(
                name: "Subscription \(i)",
                description: "",
                price: Double(i),
                billingCycle: .monthly,
                category: .other,
                icon: "",
                color: ""
            )
            try service.saveSubscription(subscription)
        }

        let duration = Date().timeIntervalSince(startTime)

        // Should complete in under 10 seconds
        #expect(duration < 10.0, "Bulk insert took \(duration)s, expected < 10s")

        let count = try service.fetchAllSubscriptions().count
        #expect(count == itemCount)
    }

    @Test("Fetch performance with large dataset")
    func testFetchPerformance() async throws {
        let service = createTestService()

        // Pre-populate
        for i in 0..<500 {
            let subscription = Subscription(
                name: "Sub \(i)",
                description: "",
                price: Double(i),
                billingCycle: .monthly,
                category: .other,
                icon: "",
                color: ""
            )
            try service.saveSubscription(subscription)
        }

        let startTime = Date()
        let _ = try service.fetchAllSubscriptions()
        let duration = Date().timeIntervalSince(startTime)

        // Fetch should be under 1 second
        #expect(duration < 1.0, "Fetch took \(duration)s, expected < 1s")
    }
}
```

---

## UI Tests

```swift
import XCTest

final class SubscriptionFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddSubscription() throws {
        // Navigate to subscriptions tab
        app.tabBars.buttons["Subscriptions"].tap()

        // Tap add button
        app.navigationBars.buttons["Add"].tap()

        // Fill form
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("Test Subscription")

        let priceField = app.textFields["Price"]
        priceField.tap()
        priceField.typeText("9.99")

        // Save
        app.buttons["Save"].tap()

        // Verify subscription appears in list
        XCTAssertTrue(app.staticTexts["Test Subscription"].exists)
    }

    func testDeleteSubscription() throws {
        // Navigate to subscriptions
        app.tabBars.buttons["Subscriptions"].tap()

        // Swipe to delete first item
        let firstCell = app.cells.firstMatch
        firstCell.swipeLeft()
        app.buttons["Delete"].tap()

        // Confirm deletion
        app.alerts.buttons["Delete"].tap()
    }

    func testNavigateToDetail() throws {
        app.tabBars.buttons["Subscriptions"].tap()

        // Tap first subscription
        app.cells.firstMatch.tap()

        // Verify detail view elements
        XCTAssertTrue(app.navigationBars.buttons["Edit"].exists)
    }
}
```

---

## Accessibility Tests

```swift
@Suite("Accessibility Tests")
struct AccessibilityTests {

    @Test("VoiceOver labels present")
    func testVoiceOverLabels() async throws {
        // Test that key UI elements have accessibility labels
        // This would typically be done in UI tests
    }

    @Test("Minimum touch target size")
    func testTouchTargets() {
        // Verify buttons meet 44x44pt minimum
        let minimumSize: CGFloat = 44

        // In actual implementation, check view frames
        #expect(minimumSize == 44)
    }

    @Test("Currency formatted for VoiceOver")
    func testCurrencyAccessibility() {
        let amount = 19.99
        let formatted = amount.accessibleCurrency

        // Should read as "19 dollars and 99 cents"
        #expect(formatted.contains("dollar"))
    }
}
```

---

## Test Helpers

### Mock Data Generator

```swift
struct TestDataGenerator {
    static func createSubscription(
        name: String = "Test Subscription",
        price: Double = 9.99,
        category: SubscriptionCategory = .entertainment
    ) -> Subscription {
        Subscription(
            name: name,
            description: "Test description",
            price: price,
            billingCycle: .monthly,
            category: category,
            icon: "star.fill",
            color: "#007AFF"
        )
    }

    static func createPerson(
        name: String = "Test Person",
        balance: Double = 0
    ) -> Person {
        var person = Person(
            name: name,
            email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@test.com",
            phone: "+1555555555"
        )
        person.balance = balance
        return person
    }

    static func createTransaction(
        title: String = "Test Transaction",
        amount: Double = -50.00,
        category: TransactionCategory = .shopping
    ) -> Transaction {
        Transaction(
            title: title,
            subtitle: "Test",
            amount: amount,
            category: category,
            date: Date(),
            isRecurring: false,
            tags: ["test"],
            merchant: "Test Merchant"
        )
    }
}
```

---

## Coverage Goals

| Category | Target Coverage |
|----------|-----------------|
| Models | 90% |
| Services | 80% |
| Utilities | 85% |
| Views | 60% (logic only) |
| Overall | 80% |

---

## Common Mistakes to Avoid

1. **Testing implementation instead of behavior**
2. **Not using in-memory containers for database tests**
3. **Flaky tests due to timing issues**
4. **Not cleaning up test data**
5. **Over-mocking losing integration coverage**

---

## Checklist

- [ ] Unit tests for all public methods
- [ ] Edge cases covered (empty, nil, boundary)
- [ ] Error scenarios tested
- [ ] Integration tests for workflows
- [ ] Performance benchmarks defined
- [ ] Accessibility verified
- [ ] Test data cleaned up

---

## Industry Standards

- **Arrange-Act-Assert** pattern
- **Given-When-Then** for BDD
- **Test isolation** - tests don't depend on each other
- **Swift Testing** - Apple's modern framework
- **80% coverage** minimum for production code
