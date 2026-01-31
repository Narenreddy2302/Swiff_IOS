# Swiff iOS Development Assistant

## Description
Expert assistant for the Swiff iOS subscription and expense management application. This skill provides comprehensive knowledge of the project's architecture, patterns, and best practices for iOS development with SwiftUI, SwiftData, and WidgetKit.

## Purpose
Use this skill when working on the Swiff iOS project to ensure consistency with established patterns, architecture, and coding standards. The skill includes expertise in:

- SwiftUI declarative UI development
- SwiftData persistence and migrations
- MVVM architecture with service layer
- WidgetKit home screen widgets
- iOS notifications and background tasks
- Subscription and expense management features
- Group expense splitting and calculations
- Security best practices for financial apps
- Accessibility standards
- Performance optimization

## When to Use This Skill

Invoke this skill when:
- Starting work on any Swiff iOS feature or bug fix
- Understanding the project architecture and structure
- Implementing new views, models, or services
- Working with subscriptions, transactions, or group expenses
- Adding widgets or notifications
- Performing code reviews
- Handling data migrations
- Implementing security or accessibility features
- Optimizing performance
- Writing tests

## Project Context

**Swiff iOS** is a comprehensive subscription and expense management app built with:
- SwiftUI for modern declarative UI
- SwiftData for data persistence (iOS 17+)
- Combine for reactive programming
- WidgetKit for home screen widgets

### Core Features
1. Subscription Management - Track recurring subscriptions with renewal reminders
2. Expense Tracking - Log and categorize transactions
3. Group Expenses - Split bills and track balances
4. Analytics - Spending trends and forecasting
5. Notifications - Renewal reminders and alerts
6. Widgets - Quick access home screen widgets

## Architecture Pattern

The project follows **MVVM + Services** pattern:
- **Models**: DataModels (domain) + SwiftDataModels (persistence)
- **ViewModels**: Service layer (DataManager, PersistenceService, etc.)
- **Views**: SwiftUI views with reusable components

## Key Guidelines

### Code Style
- Use `@MainActor` for services that interact with UI
- Prefer `@Published` properties in services for reactive updates
- Follow Swift naming conventions (PascalCase for types, camelCase for variables)
- Use comprehensive error handling with typed errors

### Architecture
- Keep business logic in Services layer, not in Views
- Use domain models (DataModels) for business logic
- Convert between domain and persistence models explicitly
- Inject DataManager via `@EnvironmentObject`

### Testing
- Write unit tests for business logic and calculations
- Test error conditions and edge cases
- Mock services for isolated testing
- Use SwiftUI previews for UI testing

### Security
- Sanitize all user inputs
- Use biometric authentication for sensitive operations
- Encrypt sensitive data at rest
- Follow OWASP mobile security guidelines

### Performance
- Use lazy loading for lists
- Implement efficient SwiftData queries
- Minimize view updates with proper state management
- Profile and optimize widget updates

## Available Detailed Skills

The project includes specialized skills in `.claude/skills/`:
- `project-context.md` - Project overview and navigation
- `mvvm-architecture.md` - Architecture patterns and guidelines
- `swiftui.md` - SwiftUI best practices
- `swiftdata.md` - Data persistence patterns
- `service-layer.md` - Service implementation guidelines
- `subscription-expense.md` - Business logic for subscriptions/expenses
- `widgets.md` - WidgetKit implementation
- `notifications.md` - Notification handling
- `security.md` - Security best practices
- `accessibility.md` - Accessibility standards
- `performance.md` - Performance optimization
- `testing.md` - Testing strategies
- `error-handling.md` - Error management
- `ui-design.md` - UI/UX guidelines
- `code-review.md` - Code review checklist

## Example Usage

When adding a new feature:
1. Review project-context.md for structure
2. Follow patterns in mvvm-architecture.md
3. Implement using swiftui.md and swiftdata.md guidelines
4. Add tests per testing.md
5. Ensure accessibility.md compliance
6. Review against code-review.md checklist
