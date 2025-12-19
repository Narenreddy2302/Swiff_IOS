# Code Review Standards

## Purpose
Establish code review criteria and quality standards to ensure maintainable, secure, and performant code following Swift best practices and project conventions.

## When to Use This Skill
- Reviewing pull requests
- Preparing code for review
- Self-reviewing before committing
- Ensuring code quality

---

## Code Organization

### File Structure

```swift
//
//  SubscriptionDetailView.swift
//  Swiff IOS
//
//  Created by [Author] on [Date].
//  [Brief description of purpose]
//

import SwiftUI

// MARK: - Main View

struct SubscriptionDetailView: View {

    // MARK: - Environment & State

    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var isEditing = false
    @State private var showDeleteAlert = false

    // MARK: - Properties

    let subscription: Subscription

    // MARK: - Computed Properties

    private var formattedPrice: String {
        subscription.price.asCurrency
    }

    // MARK: - Body

    var body: some View {
        // Implementation
    }

    // MARK: - View Components

    private var headerSection: some View {
        // Implementation
    }

    private var detailsSection: some View {
        // Implementation
    }

    // MARK: - Actions

    private func deleteSubscription() {
        // Implementation
    }
}

// MARK: - Preview

#Preview {
    SubscriptionDetailView(subscription: .sample)
        .environmentObject(DataManager.shared)
}
```

### MARK Comments

Use these standard MARK sections:
- `// MARK: - Properties`
- `// MARK: - Initialization`
- `// MARK: - Body` (for SwiftUI views)
- `// MARK: - Public Methods`
- `// MARK: - Private Methods`
- `// MARK: - Helpers`
- `// MARK: - Preview`

---

## Naming Conventions

### Swift API Design Guidelines

```swift
// GOOD: Clear, descriptive names
func fetchSubscription(byID id: UUID) -> Subscription?
func calculateMonthlyCost() -> Double
var isSubscriptionActive: Bool
var subscriptionCount: Int

// BAD: Abbreviated or unclear names
func fetch(id: UUID) -> Subscription?  // What are we fetching?
func calc() -> Double                   // What are we calculating?
var active: Bool                        // Active what?
var cnt: Int                            // Count of what?
```

### Naming Patterns

| Type | Convention | Example |
|------|------------|---------|
| Types/Classes | UpperCamelCase | `SubscriptionModel` |
| Functions/Methods | lowerCamelCase | `fetchAllSubscriptions()` |
| Variables | lowerCamelCase | `subscriptionCount` |
| Constants | lowerCamelCase | `let maxRetries = 3` |
| Booleans | is/has/can prefix | `isActive`, `hasData` |
| Protocols | -able/-ible suffix | `Identifiable`, `Codable` |
| Enums | UpperCamelCase | `BillingCycle` |
| Enum cases | lowerCamelCase | `.monthly`, `.yearly` |

---

## Documentation

### Function Documentation

```swift
/// Fetches all subscriptions for the current user.
///
/// - Parameters:
///   - includeInactive: Whether to include inactive subscriptions
///   - sortBy: The field to sort results by
/// - Returns: Array of subscriptions matching the criteria
/// - Throws: `PersistenceError.fetchFailed` if database query fails
func fetchSubscriptions(
    includeInactive: Bool = false,
    sortBy: SortField = .name
) throws -> [Subscription] {
    // Implementation
}
```

### When to Document

- Public APIs and methods
- Complex algorithms
- Non-obvious business logic
- Parameters with specific requirements
- Thrown errors

### When NOT to Document

- Self-explanatory code
- Private implementation details
- Simple getters/setters
- Obvious initializers

---

## Error Handling Review

### Checklist

- [ ] All throwing functions have `throws` keyword
- [ ] Errors are caught and handled appropriately
- [ ] User-facing errors have clear messages
- [ ] Errors are logged for debugging
- [ ] Recovery suggestions provided where possible

### Patterns

```swift
// GOOD: Proper error handling
func saveSubscription(_ subscription: Subscription) throws {
    do {
        try validateSubscription(subscription)
        try persistenceService.save(subscription)
    } catch let error as ValidationError {
        throw error // Re-throw validation errors
    } catch {
        ErrorLogger.shared.log(error)
        throw PersistenceError.saveFailed(underlying: error)
    }
}

// BAD: Swallowing errors silently
func saveSubscription(_ subscription: Subscription) {
    try? persistenceService.save(subscription) // Error lost!
}
```

---

## Security Review

### Input Validation Checklist

- [ ] User input sanitized before storage
- [ ] SQL injection patterns blocked
- [ ] XSS patterns blocked
- [ ] Path traversal prevented
- [ ] Email/phone formats validated

### Sensitive Data Checklist

- [ ] No hardcoded secrets or API keys
- [ ] Sensitive data uses Keychain (not UserDefaults)
- [ ] PII redacted from logs
- [ ] Secure communication (HTTPS)

---

## Performance Review

### Memory Management

- [ ] No retain cycles (use `[weak self]` in closures)
- [ ] Large images resized/compressed
- [ ] Subscriptions cancelled in `deinit`
- [ ] No memory leaks (check with Instruments)

### UI Performance

- [ ] Heavy work off main thread
- [ ] Lists use `LazyVStack`/`LazyHStack`
- [ ] Animations respect Reduce Motion
- [ ] No unnecessary view redraws

### Data Operations

- [ ] Database queries use predicates (not fetch-all-then-filter)
- [ ] Batch operations for bulk changes
- [ ] Caching for expensive calculations
- [ ] Debouncing for rapid state changes

---

## Accessibility Review

- [ ] All interactive elements have accessibility labels
- [ ] Touch targets minimum 44x44 points
- [ ] Dynamic Type supported
- [ ] Reduce Motion respected
- [ ] Color contrast meets 4.5:1 ratio
- [ ] Information not conveyed by color alone

---

## SwiftUI Review

### State Management

```swift
// GOOD: Appropriate state wrapper
@State private var isEditing = false           // View-local
@Binding var selection: Item                   // Two-way from parent
@StateObject private var viewModel = VM()      // Owned observable
@ObservedObject var dataManager: DataManager   // Passed observable
@EnvironmentObject var settings: Settings      // Environment-injected
```

### View Composition

```swift
// GOOD: Extracted subviews
var body: some View {
    VStack {
        headerSection
        contentSection
        footerSection
    }
}

private var headerSection: some View {
    // ...
}

// BAD: Monolithic body
var body: some View {
    VStack {
        // 200 lines of code...
    }
}
```

---

## Testing Review

- [ ] Unit tests for business logic
- [ ] Edge cases covered (empty, nil, boundary values)
- [ ] Error scenarios tested
- [ ] Tests are independent (no shared state)
- [ ] Test names describe expected behavior

---

## Common Issues to Flag

### Critical

- Security vulnerabilities (injection, sensitive data exposure)
- Memory leaks or retain cycles
- Blocking main thread
- Data loss scenarios
- Crash-causing code

### High

- Missing error handling
- No input validation
- Performance issues
- Missing accessibility support
- Breaking existing tests

### Medium

- Code duplication
- Complex functions (>50 lines)
- Missing documentation for complex logic
- Inconsistent naming
- Magic numbers/strings

### Low

- Minor style inconsistencies
- Verbose code that could be simplified
- Missing preview providers
- Commented-out code

---

## Review Feedback Templates

### Approval

```
Looks good! Clean implementation following project patterns.

Minor suggestions (optional):
- Consider extracting [X] into a separate component
- Could add accessibility label to [Y]
```

### Request Changes

```
Good progress, but needs some changes before merging:

Required:
- [ ] Add error handling for [X]
- [ ] Fix memory leak in [Y] closure

Suggestions:
- Consider using [Z] pattern for consistency
```

### Questions

```
I have some questions about the implementation:

1. Why did you choose [approach A] over [approach B]?
2. Have you considered the edge case where [X]?
3. How does this interact with [existing feature Y]?
```

---

## Pre-Commit Checklist

Before submitting for review:

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] Self-reviewed all changes
- [ ] Removed debug code/print statements
- [ ] Updated relevant documentation
- [ ] Followed project naming conventions
- [ ] No sensitive data committed
- [ ] Commit message is clear and descriptive

---

## Industry Standards

- **Swift API Design Guidelines**
- **Clean Code** principles
- **SOLID** principles
- **DRY** (Don't Repeat Yourself)
- **KISS** (Keep It Simple)
- **YAGNI** (You Aren't Gonna Need It)
