# Swiff iOS - Complete Documentation

> **Version 1.1** | A comprehensive subscription and expense management application for iOS

Welcome to the complete documentation for Swiff iOS. This documentation provides everything you need to understand, develop, test, and deploy the Swiff iOS application.

---

## Quick Links

- **New to the Project?** Start with [Getting Started](01_GettingStarted/QuickStart.md)
- **Understanding Architecture?** See [Architecture Overview](02_Architecture/Overview.md)
- **Looking for APIs?** Check [API Quick Reference](15_Reference/APIQuickReference.md)
- **Need Help?** See [Troubleshooting Guide](15_Reference/TroubleshootingGuide.md)

---

## Table of Contents

### [01 - Getting Started](01_GettingStarted/)
**Start here if you're new to the project**

| Document | Description |
|----------|-------------|
| [QuickStart.md](01_GettingStarted/QuickStart.md) | 5-minute quick start guide |
| [ProjectSetup.md](01_GettingStarted/ProjectSetup.md) | Complete development environment setup |
| [ProjectStructure.md](01_GettingStarted/ProjectStructure.md) | Understanding the codebase structure |
| [DevelopmentWorkflow.md](01_GettingStarted/DevelopmentWorkflow.md) | Daily development workflow |
| [FAQ.md](01_GettingStarted/FAQ.md) | Frequently asked questions |

**Quick Start:** Clone the project → Open `Swiff IOS.xcodeproj` → Build → Run

---

### [02 - Architecture](02_Architecture/)
**High-level architecture and design patterns**

| Document | Description |
|----------|-------------|
| [Overview.md](02_Architecture/Overview.md) | High-level architecture overview |
| [DataFlow.md](02_Architecture/DataFlow.md) | Data flow and state management |
| [ServiceLayer.md](02_Architecture/ServiceLayer.md) | Service-oriented architecture |
| [PersistenceLayer.md](02_Architecture/PersistenceLayer.md) | SwiftData persistence implementation |
| [MVVMPattern.md](02_Architecture/MVVMPattern.md) | MVVM architecture in Swiff |
| [DependencyInjection.md](02_Architecture/DependencyInjection.md) | Environment-based DI |
| [AsyncConcurrency.md](02_Architecture/AsyncConcurrency.md) | Swift async/await patterns |
| [Diagrams/](02_Architecture/Diagrams/) | Architecture diagrams and flowcharts |

**Key Patterns:** MVVM, Repository Pattern, Service Layer, Dependency Injection

---

### [03 - Data Models](03_DataModels/)
**Complete data model reference (6 SwiftData models, 8 DTOs, 30+ supporting types)**

| Document | Description |
|----------|-------------|
| [Overview.md](03_DataModels/Overview.md) | Data model architecture overview |
| [SwiftDataModels.md](03_DataModels/SwiftDataModels.md) | 6 persistent SwiftData models |
| [DTOs.md](03_DataModels/DTOs.md) | Data Transfer Objects |
| [SupportingTypes.md](03_DataModels/SupportingTypes.md) | Avatar, BillingCycle, Categories, etc. |
| [AnalyticsModels.md](03_DataModels/AnalyticsModels.md) | 30+ analytics-specific models |
| [ModelRelationships.md](03_DataModels/ModelRelationships.md) | Foreign keys and relationships |
| [ValidationRules.md](03_DataModels/ValidationRules.md) | Data validation constraints |
| [ModelConversions.md](03_DataModels/ModelConversions.md) | DTO ↔ SwiftData conversion |
| [Migrations.md](03_DataModels/Migrations.md) | Schema migration guide |
| [SampleData.md](03_DataModels/SampleData.md) | Sample data structure |
| [BestPractices.md](03_DataModels/BestPractices.md) | Model usage guidelines |
| [QuickReference.md](03_DataModels/QuickReference.md) | All models at a glance |

**Core Models:** Subscription, Transaction, Person, Group, PriceChange, GroupExpense

---

### [04 - Services](04_Services/)
**13 core services providing business logic**

| Document | Description |
|----------|-------------|
| [Overview.md](04_Services/Overview.md) | Service layer architecture |
| [DataManager.md](04_Services/DataManager.md) | Central data management service |
| [PersistenceService.md](04_Services/PersistenceService.md) | SwiftData CRUD operations |
| [AnalyticsService.md](04_Services/AnalyticsService.md) | Analytics calculations (927 lines) |
| [NotificationManager.md](04_Services/NotificationManager.md) | Notification scheduling |
| [BackupService.md](04_Services/BackupService.md) | Backup and restore functionality |
| [CSVExportService.md](04_Services/CSVExportService.md) | CSV import/export |
| [BiometricAuthService.md](04_Services/BiometricAuthService.md) | Face ID/Touch ID authentication |
| [ReminderService.md](04_Services/ReminderService.md) | Smart reminder scheduling |
| [SubscriptionRenewalService.md](04_Services/SubscriptionRenewalService.md) | Automatic renewal processing |
| [SpotlightIndexingService.md](04_Services/SpotlightIndexingService.md) | iOS Spotlight integration |
| [ChartDataService.md](04_Services/ChartDataService.md) | Chart data preparation |
| [ServiceInteractions.md](04_Services/ServiceInteractions.md) | How services work together |
| [BestPractices.md](04_Services/BestPractices.md) | Service usage patterns |

**Most Important:** DataManager (singleton), AnalyticsService (complex calculations)

---

### [05 - UI Components](05_UIComponents/)
**60+ reusable UI components and views**

| Document | Description |
|----------|-------------|
| [Overview.md](05_UIComponents/Overview.md) | UI architecture overview |
| [DesignSystem.md](05_UIComponents/DesignSystem.md) | Colors, typography, spacing, icons |
| [ComponentLibrary.md](05_UIComponents/ComponentLibrary.md) | Complete component catalog (60+) |
| [MainViews.md](05_UIComponents/MainViews.md) | 8 primary tab bar views |
| [DetailViews.md](05_UIComponents/DetailViews.md) | 5 detail screen views |
| [SheetViews.md](05_UIComponents/SheetViews.md) | 11 modal sheet presentations |
| [SettingsViews.md](05_UIComponents/SettingsViews.md) | 8 settings sections |
| [OnboardingViews.md](05_UIComponents/OnboardingViews.md) | Welcome and setup flow |
| [StatisticsComponents.md](05_UIComponents/StatisticsComponents.md) | Stats cards and grids |
| [ChartComponents.md](05_UIComponents/ChartComponents.md) | Pie charts and visualizations |
| [FormComponents.md](05_UIComponents/FormComponents.md) | Input fields with validation |
| [EmptyStates.md](05_UIComponents/EmptyStates.md) | Empty, error, and loading states |
| [ViewModifiers.md](05_UIComponents/ViewModifiers.md) | Custom view modifiers |
| [Animations.md](05_UIComponents/Animations.md) | Animation presets |
| [AccessibilityUI.md](05_UIComponents/AccessibilityUI.md) | Accessibility features |

**Design System:** 15+ Wise brand colors, SF Symbols, adaptive dark mode

---

### [06 - Features](06_Features/)
**12 major features fully documented**

| Document | Description |
|----------|-------------|
| [Overview.md](06_Features/Overview.md) | All features at a glance |
| [SubscriptionManagement.md](06_Features/SubscriptionManagement.md) | Core subscription tracking |
| [TransactionTracking.md](06_Features/TransactionTracking.md) | Expense and income logging |
| [PeopleAndGroups.md](06_Features/PeopleAndGroups.md) | Shared expenses and contacts |
| [AnalyticsDashboard.md](06_Features/AnalyticsDashboard.md) | Insights, charts, and forecasts |
| [SearchAndFiltering.md](06_Features/SearchAndFiltering.md) | Advanced search with filters |
| [ProfileManagement.md](06_Features/ProfileManagement.md) | User profile with avatar system |
| [TrialTracking.md](06_Features/TrialTracking.md) | Free trial monitoring |
| [PriceHistory.md](06_Features/PriceHistory.md) | Price change tracking |
| [RemindersNotifications.md](06_Features/RemindersNotifications.md) | Smart renewal alerts |
| [HomeScreenWidgets.md](06_Features/HomeScreenWidgets.md) | 3 widget types |
| [Onboarding.md](06_Features/Onboarding.md) | New user experience |
| [FeatureRoadmap.md](06_Features/FeatureRoadmap.md) | Future feature planning |

**User Journey:** Onboarding → Add Subscriptions → Track Expenses → View Analytics

---

### [07 - Utilities](07_Utilities/)
**35+ utility classes and helpers**

| Document | Description |
|----------|-------------|
| [Overview.md](07_Utilities/Overview.md) | Complete utilities inventory |
| [FormattingHelpers.md](07_Utilities/FormattingHelpers.md) | Currency, date/time formatters |
| [ValidationUtilities.md](07_Utilities/ValidationUtilities.md) | Input validation and sanitization |
| [DatabaseUtilities.md](07_Utilities/DatabaseUtilities.md) | Transaction mgmt, recovery |
| [UIUtilities.md](07_Utilities/UIUtilities.md) | View extensions, animations, haptics |
| [SystemIntegration.md](07_Utilities/SystemIntegration.md) | Permissions, deep linking |
| [SafetyUtilities.md](07_Utilities/SafetyUtilities.md) | Thread-safe operations |
| [ConversionHelpers.md](07_Utilities/ConversionHelpers.md) | Model conversion utilities |
| [ToastAndHaptics.md](07_Utilities/ToastAndHaptics.md) | User feedback systems |
| [UtilityBestPractices.md](07_Utilities/UtilityBestPractices.md) | Usage guidelines |

**Most Used:** CurrencyFormatter, DateTimeHelper, BillingCycleCalculator, ToastManager

---

### [08 - Integration](08_Integration/)
**External system integrations**

| Document | Description |
|----------|-------------|
| [Overview.md](08_Integration/Overview.md) | Integration architecture |
| [WidgetIntegration.md](08_Integration/WidgetIntegration.md) | Widget ↔ Main app communication |
| [SpotlightSearch.md](08_Integration/SpotlightSearch.md) | Spotlight indexing setup |
| [DeepLinking.md](08_Integration/DeepLinking.md) | URL scheme handling |
| [LocalNotifications.md](08_Integration/LocalNotifications.md) | Notification configuration |
| [BiometricAuth.md](08_Integration/BiometricAuth.md) | Face ID/Touch ID flow |
| [PhotoLibrary.md](08_Integration/PhotoLibrary.md) | Avatar photo access |
| [AppGroupSharing.md](08_Integration/AppGroupSharing.md) | Data sharing between targets |

**Key Integration:** Widgets use App Groups to access shared data container

---

### [09 - Security](09_Security/)
**Security architecture and compliance**

| Document | Description |
|----------|-------------|
| [Overview.md](09_Security/Overview.md) | Security architecture overview |
| [AuthenticationFlow.md](09_Security/AuthenticationFlow.md) | Biometric + PIN authentication |
| [DataEncryption.md](09_Security/DataEncryption.md) | Backup encryption strategy |
| [PermissionHandling.md](09_Security/PermissionHandling.md) | System permission requests |
| [SecureCoding.md](09_Security/SecureCoding.md) | Security best practices |
| [PrivacyCompliance.md](09_Security/PrivacyCompliance.md) | Privacy policy alignment |

**Security Features:** Biometric auth, PIN lock, encrypted backups, no server communication

---

### [10 - Testing](10_Testing/)
**Testing strategy and implementation**

| Document | Description |
|----------|-------------|
| [TestStrategy.md](10_Testing/TestStrategy.md) | Overall testing approach |
| [UnitTesting.md](10_Testing/UnitTesting.md) | Unit test patterns and examples |
| [IntegrationTesting.md](10_Testing/IntegrationTesting.md) | Service integration tests |
| [UITesting.md](10_Testing/UITesting.md) | UI/UX test automation |
| [AccessibilityTesting.md](10_Testing/AccessibilityTesting.md) | VoiceOver compliance testing |
| [TestCoverage.md](10_Testing/TestCoverage.md) | Coverage reports and goals |

**Test Types:** Unit (services, utilities), Integration (service interactions), UI (user flows)

---

### [11 - Edge Cases](11_EdgeCases/)
**Edge case handling documentation**

| Document | Description |
|----------|-------------|
| [Overview.md](11_EdgeCases/Overview.md) | Edge case philosophy |
| [DataValidation.md](11_EdgeCases/DataValidation.md) | Input validation edge cases |
| [StateManagement.md](11_EdgeCases/StateManagement.md) | UI state edge cases |
| [ConcurrencyEdgeCases.md](11_EdgeCases/ConcurrencyEdgeCases.md) | Race conditions and threading |
| [DateTimeEdgeCases.md](11_EdgeCases/DateTimeEdgeCases.md) | Timezone, leap years, DST |
| [BillingCycleEdgeCases.md](11_EdgeCases/BillingCycleEdgeCases.md) | Complex billing scenarios |
| [NetworkEdgeCases.md](11_EdgeCases/NetworkEdgeCases.md) | Offline and connectivity issues |
| [PermissionDenials.md](11_EdgeCases/PermissionDenials.md) | Denied permission handling |

**Common Cases:** Leap year billing, timezone changes, concurrent updates

---

### [12 - Error Handling](12_ErrorHandling/)
**Comprehensive error management**

| Document | Description |
|----------|-------------|
| [Overview.md](12_ErrorHandling/Overview.md) | Error handling philosophy |
| [ErrorTypes.md](12_ErrorHandling/ErrorTypes.md) | Complete error type catalog |
| [ErrorRecovery.md](12_ErrorHandling/ErrorRecovery.md) | Recovery strategies |
| [ErrorLogging.md](12_ErrorHandling/ErrorLogging.md) | Logging and diagnostics |
| [UserFacingErrors.md](12_ErrorHandling/UserFacingErrors.md) | User-friendly error messages |
| [RetryMechanisms.md](12_ErrorHandling/RetryMechanisms.md) | Automatic retry logic |
| [ErrorBestPractices.md](12_ErrorHandling/ErrorBestPractices.md) | Error handling guidelines |

**Error Categories:** Database, Validation, Network, Permission, File System, Business Logic

---

### [13 - Business Logic](13_BusinessLogic/)
**Business rules and calculations**

| Document | Description |
|----------|-------------|
| [Overview.md](13_BusinessLogic/Overview.md) | Business rules overview |
| [SubscriptionRules.md](13_BusinessLogic/SubscriptionRules.md) | Subscription business logic |
| [BillingCycleCalculations.md](13_BusinessLogic/BillingCycleCalculations.md) | Billing cycle math |
| [TrialManagement.md](13_BusinessLogic/TrialManagement.md) | Free trial logic |
| [GroupExpenseRules.md](13_BusinessLogic/GroupExpenseRules.md) | Expense splitting algorithms |
| [PriceChangeRules.md](13_BusinessLogic/PriceChangeRules.md) | Price update logic |
| [ReminderLogic.md](13_BusinessLogic/ReminderLogic.md) | Reminder scheduling rules |
| [AnalyticsCalculations.md](13_BusinessLogic/AnalyticsCalculations.md) | Analytics formulas |
| [ValidationRules.md](13_BusinessLogic/ValidationRules.md) | Business validation constraints |

**Complex Logic:** 9 billing cycles, expense splitting, analytics forecasting

---

### [14 - Deployment](14_Deployment/)
**Build and release management**

| Document | Description |
|----------|-------------|
| [BuildProcess.md](14_Deployment/BuildProcess.md) | Xcode build configuration |
| [AppStoreSubmission.md](14_Deployment/AppStoreSubmission.md) | App Store checklist |
| [VersionManagement.md](14_Deployment/VersionManagement.md) | Versioning strategy |
| [ReleaseChecklist.md](14_Deployment/ReleaseChecklist.md) | Pre-release validation |
| [ContinuousIntegration.md](14_Deployment/ContinuousIntegration.md) | CI/CD pipeline setup |
| [ReleaseNotes.md](14_Deployment/ReleaseNotes.md) | Release notes template |

**Current Version:** 1.1 (Build 2) - Ready for App Store submission

---

### [15 - Reference](15_Reference/)
**Quick reference guides**

| Document | Description |
|----------|-------------|
| [APIQuickReference.md](15_Reference/APIQuickReference.md) | All APIs at a glance |
| [ModelQuickReference.md](15_Reference/ModelQuickReference.md) | All models summary |
| [ComponentQuickReference.md](15_Reference/ComponentQuickReference.md) | UI component catalog |
| [CodeStyleGuide.md](15_Reference/CodeStyleGuide.md) | Swift style conventions |
| [GitWorkflow.md](15_Reference/GitWorkflow.md) | Git branching strategy |
| [TroubleshootingGuide.md](15_Reference/TroubleshootingGuide.md) | Common issues and fixes |
| [Glossary.md](15_Reference/Glossary.md) | Technical terminology |
| [ExternalResources.md](15_Reference/ExternalResources.md) | Links to external docs |

**Most Used:** API Quick Reference, Troubleshooting Guide

---

## Project Statistics

| Metric | Value |
|--------|-------|
| **Version** | 1.1 (Build 2) |
| **Platform** | iOS 17.0+ |
| **Language** | Swift 5.9+ |
| **Framework** | SwiftUI + SwiftData |
| **Total Swift Files** | 157 (149 main + 8 widgets) |
| **SwiftData Models** | 6 persistent models |
| **DTOs** | 8 data transfer objects |
| **Services** | 13 core services |
| **Utilities** | 35+ utility classes |
| **UI Components** | 60+ reusable components |
| **Main Views** | 8 tab bar views |
| **Features** | 12 major features |
| **Documentation Files** | 140+ markdown files |
| **Test Coverage** | Unit, Integration, UI tests |
| **App Store Status** | Ready for submission |

---

## Technology Stack

**Core Technologies:**
- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern persistence layer (iOS 17+)
- **Combine** - Reactive programming
- **Swift Concurrency** - Async/await for asynchronous operations
- **WidgetKit** - Home screen widgets
- **Core Data** - Legacy support (migrated to SwiftData)
- **Local Notifications** - Reminder system
- **Spotlight** - iOS search integration
- **Biometric Authentication** - Face ID / Touch ID
- **PhotoKit** - Avatar photo selection

**Design Patterns:**
- MVVM (Model-View-ViewModel)
- Repository Pattern
- Service Layer
- Dependency Injection
- Observer Pattern
- Factory Pattern
- Strategy Pattern

---

## Key Features at a Glance

**Core Features:**
1. Subscription Management with 9 billing cycles
2. Transaction Tracking with categorization
3. People & Groups for shared expenses
4. Analytics Dashboard with charts and insights
5. Advanced Search with filters
6. Profile Management with avatar system
7. Free Trial Tracking with alerts
8. Price History visualization
9. Smart Reminders and Notifications
10. Home Screen Widgets (3 types)
11. Onboarding flow for new users
12. Comprehensive Settings

**Advanced Features:**
- Biometric authentication (Face ID/Touch ID)
- PIN lock security
- Dark mode support
- CSV export/import
- Backup and restore
- Accessibility features
- Haptic feedback
- Toast notifications
- Deep linking
- Spotlight search

---

## Documentation Standards

All documentation in this project follows these standards:

1. **Clarity** - Clear, concise language for developers of all levels
2. **Completeness** - Comprehensive coverage of all features and APIs
3. **Code Examples** - Real-world code snippets and usage examples
4. **Visual Aids** - Diagrams, flowcharts, and screenshots where helpful
5. **Cross-References** - Links between related documentation
6. **Versioning** - Documentation version matches code version
7. **Maintenance** - Updated with every feature addition or change

---

## Contributing to Documentation

When adding new features or making changes:

1. Update relevant documentation files
2. Add code examples
3. Update diagrams if architecture changes
4. Add entries to Quick Reference guides
5. Update the master README if needed
6. Cross-reference related documentation

---

## Getting Help

**Documentation Issues?**
- Check the [FAQ](01_GettingStarted/FAQ.md)
- See the [Troubleshooting Guide](15_Reference/TroubleshootingGuide.md)
- Review specific feature documentation in [Features](06_Features/)

**Code Issues?**
- Check [Error Handling](12_ErrorHandling/) documentation
- Review [Edge Cases](11_EdgeCases/) documentation
- See [API Reference](15_Reference/APIQuickReference.md)

**Architecture Questions?**
- Start with [Architecture Overview](02_Architecture/Overview.md)
- Review [Service Layer](02_Architecture/ServiceLayer.md)
- Check [Data Flow](02_Architecture/DataFlow.md)

---

## Archive

Older documentation has been archived in the [_Archive](_Archive/) folder for reference. These documents may be outdated but are preserved for historical context.

---

## Documentation Version

**Version:** 1.1
**Last Updated:** November 25, 2024
**Status:** Complete and comprehensive
**Coverage:** 100% of implemented features

---

## License

This documentation is part of the Swiff iOS project.
See the project LICENSE file for details.

---

**Ready to get started?** Begin with the [QuickStart Guide](01_GettingStarted/QuickStart.md) →
