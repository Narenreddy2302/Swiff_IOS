# Project Context - Swiff iOS

## Purpose
Provide comprehensive project overview, architecture summary, and navigation guide for the Swiff iOS subscription and expense management application.

## When to Use This Skill
- Starting work on any feature or bug fix
- Understanding the overall project structure
- Finding specific files or services
- Understanding dependencies between components

---

## Project Overview

**Swiff iOS** is a comprehensive subscription and expense management app built with:
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Apple's persistence framework (iOS 17+)
- **Combine** - Reactive programming for state management
- **WidgetKit** - Home screen widgets

### Core Features
1. **Subscription Management** - Track recurring subscriptions with renewal reminders
2. **Expense Tracking** - Log and categorize transactions
3. **Group Expenses** - Split bills and track balances with friends
4. **Analytics** - Spending trends, forecasting, and insights
5. **Notifications** - Renewal reminders and price change alerts
6. **Widgets** - Home screen widgets for quick access

---

## Directory Structure

```
Swiff_IOS/
├── Swiff IOS/                      # Main App Target
│   ├── Swiff_IOSApp.swift          # App entry point
│   ├── ContentView.swift           # Main 5-tab navigation
│   │
│   ├── Models/
│   │   ├── DataModels/             # Domain models (Codable)
│   │   │   ├── Subscription.swift
│   │   │   ├── Transaction.swift
│   │   │   ├── Person.swift
│   │   │   ├── Group.swift
│   │   │   └── SupportingTypes.swift
│   │   │
│   │   ├── SwiftDataModels/        # Persistence models (@Model)
│   │   │   ├── SubscriptionModel.swift
│   │   │   ├── TransactionModel.swift
│   │   │   ├── PersonModel.swift
│   │   │   └── GroupModel.swift
│   │   │
│   │   └── AppTheme.swift          # Theme configuration
│   │
│   ├── Services/                   # Business logic layer
│   │   ├── DataManager.swift       # Central state management
│   │   ├── PersistenceService.swift # SwiftData operations
│   │   ├── AnalyticsService.swift  # Spending analytics
│   │   ├── NotificationManager.swift
│   │   ├── BackupService.swift
│   │   └── BiometricAuthenticationService.swift
│   │
│   ├── Views/
│   │   ├── Components/             # Reusable UI components
│   │   │   ├── UnifiedListRow.swift
│   │   │   ├── UnifiedCard.swift
│   │   │   └── AvatarView.swift
│   │   │
│   │   ├── DetailViews/            # Entity detail screens
│   │   ├── Sheets/                 # Modal presentations
│   │   ├── Settings/               # Settings screens
│   │   └── Onboarding/             # Onboarding flow
│   │
│   ├── Utilities/                  # Helpers and extensions
│   │   ├── ComprehensiveErrorTypes.swift
│   │   ├── InputSanitizer.swift
│   │   ├── CurrencyFormatter.swift
│   │   └── HapticManager.swift
│   │
│   └── Persistence/                # Database migrations
│
├── SwiffWidgets/                   # Widget Extension
│   ├── UpcomingRenewalsWidget.swift
│   ├── MonthlySpendingWidget.swift
│   └── WidgetDataService.swift
│
├── Swiff IOSTests/                 # Unit Tests
└── Swiff IOSUITests/               # UI Tests
```

---

## Key Files Quick Reference

### Entry Points
| File | Purpose |
|------|---------|
| `Swiff_IOSApp.swift` | App entry, environment setup, deep link handling |
| `ContentView.swift` | Main TabView with 5 tabs |

### State Management
| File | Purpose |
|------|---------|
| `Services/DataManager.swift` | Central @ObservableObject singleton |
| `Services/PersistenceService.swift` | SwiftData CRUD operations |

### Core Models
| File | Purpose |
|------|---------|
| `Models/DataModels/Subscription.swift` | Subscription domain model |
| `Models/DataModels/Transaction.swift` | Transaction domain model |
| `Models/DataModels/Person.swift` | Person/contact model |
| `Models/DataModels/Group.swift` | Group expense model |

### UI Components
| File | Purpose |
|------|---------|
| `Views/Components/UnifiedListRow.swift` | Standard list row design |
| `Views/Components/UnifiedCard.swift` | Card container component |
| `Views/Components/AvatarView.swift` | Profile picture/emoji display |

---

## Service Dependencies Map

```
┌─────────────────────────────────────────────────────────────┐
│                     SwiftUI Views                           │
│  (ContentView, DetailViews, Sheets, Components)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    DataManager.shared                        │
│  - @Published people, groups, subscriptions, transactions    │
│  - CRUD operations                                           │
│  - Computed analytics                                        │
└─────────────────────────────────────────────────────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Persistence  │ │ Notification │ │  Analytics   │ │   Renewal    │
│   Service    │ │   Manager    │ │   Service    │ │   Service    │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│                     SwiftData                                │
│  ModelContainer → ModelContext → @Model entities             │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture Pattern: MVVM + Services

### Model Layer
- **DataModels/** - Plain Swift structs (Codable) for business logic
- **SwiftDataModels/** - @Model classes for persistence
- Conversion via `toDomain()` and `init(from:)` methods

### ViewModel Layer (Services)
- `DataManager` - Central state management
- Singleton pattern with `@MainActor`
- `@Published` properties for reactive UI

### View Layer
- SwiftUI views with `@EnvironmentObject` for DataManager
- `@State` and `@Binding` for local state
- Components for reusability

---

## Common Development Tasks

### Adding a New Feature
1. Create domain model in `Models/DataModels/`
2. Create SwiftData model in `Models/SwiftDataModels/`
3. Add CRUD operations in `PersistenceService`
4. Add business logic in `DataManager`
5. Create UI in `Views/`

### Adding a New Service
1. Create service class with `@MainActor` and singleton
2. Add `@Published` properties for state
3. Inject into views via environment or direct reference

### Modifying Data Schema
1. Update `@Model` classes
2. Handle migration if needed (see `MigrationPlanV1toV2.swift`)
3. Update `toDomain()` and `init(from:)` methods

---

## Build & Run

### Requirements
- Xcode 15+
- iOS 17+ Simulator or Device
- macOS Sonoma+

### Environment
- `.env` file for API keys (Gemini API placeholder)
- App Groups enabled for widget data sharing

### Testing
```bash
# Run all tests
xcodebuild test -scheme "Swiff IOS" -destination "platform=iOS Simulator,name=iPhone 15"
```

---

## Related Skills
- [mvvm-architecture.md](mvvm-architecture.md) - Architecture patterns
- [swiftdata.md](swiftdata.md) - Persistence patterns
- [service-layer.md](service-layer.md) - Service implementation
- [swiftui.md](swiftui.md) - UI development
