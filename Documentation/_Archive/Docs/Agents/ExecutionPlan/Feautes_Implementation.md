# SWIFF IOS - COMPREHENSIVE IMPLEMENTATION PLAN

## =� OVERVIEW
Current Status: **60-70% Complete** with excellent foundation
-  Solid data architecture with SwiftData
-  Comprehensive CRUD operations
-  Beautiful UI with modern design
-  Advanced error handling
-  Unique group expense sharing
- � Missing critical subscription features (reminders, analytics, trial tracking)

---

## <� PAGE 1: HOME TAB (HomeView)

###  Already Complete
- Top header with profile/search buttons
- Financial overview grid (4 cards: Balance, Subscriptions, Income, Expenses)
- Recent activity feed with transactions
- Filter functionality
- Navigation to SettingsView, SearchView, BalanceDetailView

### =' Tasks to Complete

#### 1.1 Fix Navigation Links
- [x] Add navigation from transaction rows to TransactionDetailView
- [x] Add navigation from subscription card to SubscriptionsView tab (switch to tab 4)
- [x] Add navigation from people balance items to PersonDetailView
- [x] Test all navigation flows work correctly

#### 1.2 Add Quick Action Button
- [x] Add floating "+" button (bottom right corner)
- [x] Create quick action menu sheet with options:
  - Add Transaction
  - Add Subscription
  - Add Person
  - Add Group
- [x] Add haptic feedback on button press
- [x] Implement smooth scale + opacity animation

#### 1.3 Enhance Financial Overview Cards
- [x] Add trend indicators (↑↓ arrows) showing change from last month
- [x] Add percentage change labels (e.g., "+5.2% from last month")
- [x] Add tap gesture to each card for detailed analytics
- [x] Add loading skeleton states while calculating totals
- [x] Add smooth number animation when values change

#### 1.4 Add Analytics Section (Below financial cards)
- [x] Create "Insights" card showing spending trends
- [x] Add "Top Subscriptions" horizontal scroll (5 most expensive)
- [x] Add "Upcoming Renewals" section (next 7 days)
- [x] Add "Savings Opportunities" card (detect unused subscriptions)
- [x] Make all cards tappable to view full analytics page

---

## =� PAGE 2: FEED TAB (RecentActivityView - Transactions)

###  Already Complete
- Add transaction button (green gradient)
- Search functionality with real-time filtering
- Category filtering pills
- Transaction list with category icons
- Swipe to delete with confirmation
- Pull-to-refresh
- Navigation to TransactionDetailView
- Filter sheet (date ranges, expense/income)

### =' Tasks to Complete

#### 2.1 Enhance Transaction Cards
- [x] Add transaction status badges (pending, completed, failed) ✅ COMPLETED
- [x] Add merchant name field and display prominently ✅ COMPLETED
- [x] Add linked subscription indicator (show subscription icon if linked) ✅ COMPLETED
- [x] Add receipt indicator icon (camera icon when receipt attached) ✅ COMPLETED
- [x] Improve date grouping headers with better styling (Today, Yesterday, This Week, Older) ✅ COMPLETED
- [x] Add transaction card tap animation ✅ COMPLETED

#### 2.2 Add Advanced Filtering
- [x] Add date range picker (custom start/end dates) ✅ COMPLETED
- [x] Add amount range filter (min/max sliders) ✅ COMPLETED
- [x] Add multiple category selection (checkboxes instead of single) ✅ COMPLETED
- [x] Add "Has Receipt" toggle filter ✅ COMPLETED
- [x] Add "Recurring Only" toggle filter ✅ COMPLETED
- [x] Add "Linked to Subscription" toggle filter ✅ COMPLETED
- [x] Add payment status filter ✅ COMPLETED
- [x] Add transaction type filter (All/Expenses/Income) ✅ COMPLETED
- [x] Add saved filter presets (create custom filters) ✅ COMPLETED
- [x] Add "Reset Filters" button ✅ COMPLETED
- [x] Add filter badge showing active filter count ✅ COMPLETED

#### 2.3 Add Bulk Actions
- [x] Add "Select" button in navigation bar ✅ COMPLETED
- [x] Enable multi-select mode with checkboxes ✅ COMPLETED
- [x] Add bulk action sheet with operations: ✅ COMPLETED
  - Delete selected
  - Change category
  - Add tags
  - Export selected (CSV)
- [x] Implement bulk operations in DataManager ✅ COMPLETED
- [x] Add selection counter in header ✅ COMPLETED
- [x] Add haptic feedback for selections ✅ COMPLETED

#### 2.4 Enhance Empty States
- [x] Add helpful tips for first-time users ("Track your daily expenses") ✅ COMPLETED
- [x] Add "Add Sample Data" button for testing ✅ COMPLETED
- [x] Add quick action buttons: "Add First Transaction", "Import Data" ✅ COMPLETED
- [x] Add illustration graphic ✅ COMPLETED

#### 2.5 Add Transaction Statistics Header
- [x] Show count of transactions in current view ✅ COMPLETED
- [x] Show total amount (filtered) ✅ COMPLETED
- [x] Show average transaction amount ✅ COMPLETED
- [x] Make collapsible/expandable ✅ COMPLETED

---

## 🎉 PAGE 2 STATUS: FULLY COMPLETED!

**Completion Date:** January 21, 2025
**Status:** ✅ 19 of 19 tasks completed (100%)
**All Features:** ✅ 100% Complete

### What Was Implemented:

#### Phase 1: Data Model Enhancements
1. **PaymentStatus Enum** - 5 status types (pending, completed, failed, refunded, cancelled)
2. **Transaction Model** - Extended with merchant, paymentStatus, receiptData, linkedSubscriptionId
3. **TransactionModel (SwiftData)** - Persistent layer with automatic lightweight migration
4. **Computed Properties** - hasReceipt, isLinkedToSubscription, displayMerchant

#### Phase 2: Visual Components
1. **TransactionStatusBadge** - Reusable badge with 3 sizes
2. **TransactionGroupHeader** - Smart date grouping (Today, Yesterday, This Week, Earlier)
3. **StatisticsHeaderView** - Collapsible stats showing count, totals, averages, income/expenses
4. **EnhancedFeedEmptyState** - Beautiful empty state with quick actions
5. **Enhanced Transaction Rows** - Status badges, merchant display, 3 indicators (recurring, receipt, subscription link)

#### Phase 3: Advanced Filtering System
1. **FilterPreset Model** - Comprehensive filtering with 5 default presets
2. **AdvancedTransactionFilter** - Date ranges, amount ranges, category multi-select, toggle filters, status filters
3. **AdvancedFilterSheet UI** - Complete UI with all filter options
4. **Filter Badge** - Shows active filter count in navigation bar
5. **Array Extension** - applyFilter() method for comprehensive filtering logic

#### Phase 4: Bulk Actions System
1. **Multi-select Mode** - Checkboxes on transaction rows, selection counter in header
2. **BulkActionsSheet** - Delete, change category, add tags, export to CSV
3. **DataManager Methods** - bulkDeleteTransactions, bulkUpdateCategory, bulkAddTags
4. **CSVExportService** - Enhanced with exportTransactions() method for selected transactions

#### Phase 5: Integration & UX Enhancements
1. **RecentActivityView Updates** - Integrated all advanced features
2. **Smart Empty States** - Context-aware messages based on active filters
3. **Haptic Feedback** - Throughout all interactions
4. **Tap Animations** - Spring animations on transaction cards
5. **Header Modes** - Normal mode vs Multi-select mode with different UI

### Files Created/Modified:
- **Created:** PaymentStatus.swift, TransactionStatusBadge.swift, TransactionGroupHeader.swift, StatisticsHeaderView.swift, FilterPreset.swift, AdvancedFilterSheet.swift, BulkActionsSheet.swift
- **Modified:** Transaction.swift, TransactionModel.swift, EditTransactionSheet.swift, ContentView.swift (RecentActivityView, FeedHeaderSection, FeedTransactionRow), EnhancedEmptyState.swift, DataManager.swift, CSVExportService.swift

---

## =e PAGE 3: PEOPLE TAB (PeopleView)

### � Status: NEEDS VERIFICATION - May need to be created/completed

### =' Tasks to Complete

#### 3.1 Create/Verify Main PeopleView Structure
- [x] Verify PeopleView exists in ContentView tab structure ✅ COMPLETED
- [x] Add search bar at top with search icon ✅ COMPLETED
- [x] Create people list with LazyVStack for performance ✅ COMPLETED
- [x] Add pull-to-refresh functionality ✅ COMPLETED
- [x] Add empty state view ✅ COMPLETED

#### 3.2 Design People List Cards
- [x] Show avatar (photo/emoji/initials) - large size ✅ COMPLETED
- [x] Show name as title (bold, large) ✅ COMPLETED
- [x] Show email as subtitle (gray, smaller) ✅ COMPLETED
- [x] Show balance with color coding: ✅ COMPLETED
  - Red/negative: You owe them
  - Green/positive: They owe you
  - Gray/zero: Settled
- [x] Show last transaction date ("Last activity: 2 days ago") ✅ COMPLETED
- [x] Add chevron icon for navigation ✅ COMPLETED
- [x] Add swipe actions: ✅ COMPLETED
  - Left swipe: Delete (red)
  - Right swipe: Edit, Settle Balance

#### 3.3 Add Filtering & Sorting
- [x] Add filter pills at top: ✅ COMPLETED
  - All People
  - Owes You (positive balance)
  - You Owe (negative balance)
  - Settled (zero balance)
  - Active (recent transactions)
- [x] Add sort menu (gear icon): ✅ COMPLETED
  - Name (A-Z, Z-A)
  - Balance (High to Low, Low to High)
  - Recent Activity (Most Recent First)
  - Date Added
- [x] Add balance summary header card: ✅ COMPLETED
  - Total Owed to You
  - Total You Owe
  - Net Balance
  - Number of People

#### 3.4 Add Quick Actions
- [x] Add floating "+" button to add new person: ✅ NOT NEEDED (existing Add Person button sufficient) (matches app style)
- [x] Add "Settle All Balances" button: ✅ COMPLETED in navigation bar (if balances exist)
- [x] Add "Send Reminders" bulk action: ✅ COMPLETED (select people, send payment reminders)
- [x] Add "Import from Contacts" option: ✅ COMPLETED

#### 3.5 Enhance PersonDetailView (Already exists but enhance)
- [x] Add transaction history timeline view: ✅ COMPLETED (vertical line with dots)
- [x] Add payment request feature: ✅ COMPLETED
  - "Request Payment" button
  - Generate shareable message
  - Share via Messages/Email/WhatsApp
  - Include amount, reason, payment methods
- [x] Add iOS Contacts integration: ✅ COMPLETED
  - "Link to Contact" button
  - Auto-fill contact info if linked
  - Quick call/message from app
- [x] Add transaction statistics card: ✅ COMPLETED
  - Total transactions with this person
  - Total paid to them
  - Total received from them
  - Average transaction amount
- [x] Add recurring transaction patterns detection: ✅ COMPLETED
- [x] Add payment history chart: ✅ COMPLETED (bar chart over time)
- [x] Add "Export Transactions" (CSV of transactions with this person) ✅ COMPLETED

---

## =� PAGE 4: SUBSCRIPTIONS TAB (SubscriptionsView)

### � Status: NEEDS VERIFICATION - May need to be created/completed

### =' Tasks to Complete

#### 4.1 Create/Verify Main SubscriptionsView Structure ✅ COMPLETED
- [x] Verify SubscriptionsView exists in ContentView tab structure
- [x] Add search bar at top
- [x] Create subscription grid/list view (toggle between views)
- [x] Add pull-to-refresh
- [x] Add view toggle button (grid icon / list icon)

#### 4.2 Design Subscription Cards (Grid View) ✅ COMPLETED
- [x] Large circular icon with gradient background (category color)
- [x] Subscription name (bold, centered)
- [x] Price and billing cycle ("$9.99/month")
- [x] Next billing date with countdown badge ("in 5 days")
- [x] Status badge in corner (Active/Paused/Cancelled/Trial)
- [x] Shared indicator icon (people icon if shared)
- [x] Card shadow and rounded corners
- [x] Tap to navigate to SubscriptionDetailView

#### 4.3 Design Subscription Cards (List View) ✅ COMPLETED
- [x] Icon on left (medium size with gradient)
- [x] Name and description stacked
- [x] Price on right (large, bold)
- [x] Next billing date below name
- [x] Status and shared badges
- [x] Chevron on far right

#### 4.4 Add Filtering & Sorting ✅ COMPLETED
- [x] Add filter pills at top:
  - All Subscriptions
  - Active
  - Paused
  - Cancelled
  - Free Trials ✅ NEW
  - Shared
- [x] Add category filter dropdown:
  - All Categories
  - Entertainment (Netflix, Disney+, etc.)
  - Productivity (Notion, Dropbox, etc.)
  - Fitness & Health
  - Education
  - [All 14 categories]
- [x] Add sort menu:
  - Name (A-Z)
  - Price (High to Low, Low to High)
  - Next Billing (Soonest First)
  - Date Added (Newest First)
  - Most Expensive
- [x] Add monthly cost summary header:
  - Total Monthly Cost (all active) ✅
  - Number of Active Subscriptions ✅
  - Number of Trials Ending Soon ✅ ADDED
  - Potential Savings (paused/cancelled) ✅ ADDED

#### 4.5 Add Category Grouping View
- [ ] Add "Group by Category" toggle
- [ ] Create collapsible category sections
- [ ] Show category icon and name as header
- [ ] Show category totals (count + monthly cost)
- [ ] Sort categories by total cost
- [ ] Allow expanding/collapsing each category

#### 4.6 Add Calendar View Option
- [ ] Add "Calendar" view toggle
- [ ] Create month calendar view showing renewal dates
- [ ] Highlight days with renewals (colored dots)
- [ ] Show number of renewals per day
- [ ] Add month navigation (< previous, next >)
- [ ] Tap date to show list of subscriptions renewing that day
- [ ] Color code by status (active=green, trial=yellow, etc.)

#### 4.7 Enhance SubscriptionDetailView ⚠️ 90% COMPLETE (High-Priority Features Done)
- [ ]  Verify all existing features work perfectly
- [x] Add "Remind Me Before Renewal" section: ✅ COMPLETED
  - Toggle for reminders
  - Day selector (1, 3, 7, 14, 30 days before)
  - Custom date picker option
- [ ] Add price history chart (if price has changed):
  - Line chart showing price over time
  - Highlight increases vs decreases
  - Show percentage changes
- [x] Add usage tracking section: ✅ COMPLETED
  - "Track Usage" toggle
  - "Mark as Used Today" button
  - Last used date display
  - Usage frequency stats
- [ ] Add alternative suggestions section:
  - "Find Alternatives" button
  - Show cheaper competitor suggestions
  - Compare features (manual or web search)
- [ ] Add renewal history timeline:
  - List of past renewals
  - Amount paid each time
  - Payment method used
- [ ] Add "Share Subscription" enhancement:
  - QR code for easy sharing
  - Generate shareable link
  - Track acceptance status

---

## � PAGE 5: SETTINGS TAB (SettingsView)

###  Already Complete
- Profile section with avatar and edit
- System notification permission request
- Notification toggles (renewals, payments)
- Currency picker (7 currencies)
- Backup/restore with conflict resolution
- Export data (JSON/CSV)
- Clear all data with confirmation
- Data summary (counts)
- Privacy Policy and Terms of Service
- App version display

### =' Tasks to Complete

#### 5.1 Add Security Settings Section (New)
- [ ] Add "Security" section header
- [ ] Add Face ID/Touch ID lock toggle:
  - Check if biometrics available
  - Request permission on first toggle
  - Store preference in UserSettings
- [ ] Add PIN lock option:
  - "Set PIN" button
  - 4-digit PIN entry screen
  - Confirm PIN screen
  - Store encrypted PIN
- [ ] Add auto-lock setting:
  - "Lock app immediately" toggle
  - "Lock after" picker (1, 5, 15, 30 minutes, Never)
- [ ] Implement BiometricAuthenticationService

#### 5.2 Enhance Notification Settings
- [ ] Expand notification section with more options
- [ ] Add "Renewal Reminder Timing":
  - Multi-select options: 1 day, 3 days, 7 days, 14 days before
  - Allow custom day count
  - "Send at" time picker (9 AM default)
- [ ] Add "Trial Expiration Reminders" toggle
- [ ] Add "Price Increase Alerts" toggle
- [ ] Add "Unused Subscription Alerts" toggle:
  - Enable toggle
  - "Alert after X days" picker (30, 60, 90 days)
- [ ] Add "Quiet Hours" setting:
  - Enable toggle
  - Start time picker
  - End time picker
  - "Don't send notifications during these hours"
- [ ] Add "Test Notification" button
- [ ] Add "Notification History" link

#### 5.3 Add Appearance Settings Section (New)
- [ ] Add "Appearance" section header
- [ ] Add theme selector:
  - Light mode option
  - Dark mode option
  - System (auto) option [default]
  - Preview of each theme
- [ ] Add color scheme picker:
  - Primary accent color selector
  - Show color palette (8-10 colors)
  - Preview how it affects app
- [ ] Add app icon selector:
  - Show grid of alternate icons
  - Unlock premium icons (if monetizing)
  - Change icon on selection

#### 5.4 Enhance Data Management Section
- [ ] Add "Auto Backup" toggle
- [ ] Add backup frequency selector (Daily, Weekly, Monthly)
- [ ] Add "Last Backup" date display
- [ ] Add "Backup Location" (if iCloud sync implemented)
- [ ] Add iCloud sync toggle (Future feature):
  - Enable/disable iCloud sync
  - Show sync status
  - "Sync Now" button
  - "Resolve Conflicts" button
- [ ] Add backup encryption toggle:
  - Encrypt backups with password
  - Password setup sheet
- [ ] Add "Import from Competitors":
  - CSV template downloads
  - Import guides for Bobby, Truebill, etc.
  - File picker for import
- [ ] Add storage usage section:
  - App size
  - Data size
  - Image/receipt storage size
  - "Clear Cache" button

#### 5.5 Add Advanced Settings Section (New)
- [ ] Add "Advanced" section header
- [ ] Add "Default Billing Cycle" picker:
  - Used when creating new subscriptions
  - Monthly [default], Weekly, Annually, etc.
- [ ] Add "Default Currency" picker:
  - Used for new subscriptions
  - Separate from display currency
- [ ] Add "First Day of Week" picker:
  - Sunday [default] or Monday
  - Affects calendar views
- [ ] Add "Date Format" picker:
  - MM/DD/YYYY [US]
  - DD/MM/YYYY [EU]
  - YYYY-MM-DD [ISO]
- [ ] Add "Transaction Auto-Categorization" toggle:
  - Auto-suggest categories based on title/merchant
  - Machine learning categorization
- [ ] Add "Developer Options" (hidden, access via 10 taps on version):
  - Enable debug logs
  - Clear all data without confirmation
  - Reset onboarding
  - Test crash reporting

#### 5.6 Add Help & Support Section (New)
- [ ] Add "Help & Support" section
- [ ] Add "FAQ" button � Opens FAQ view
- [ ] Add "Contact Support" button:
  - Email template
  - Include device info
  - Include app version
- [ ] Add "Rate App" button � Opens App Store
- [ ] Add "Share App" button � Share sheet with App Store link
- [ ] Add "What's New" button � Shows changelog
- [ ] Add "Tutorial" button � Replay onboarding

---

## <� NEW FEATURE: ANALYTICS DASHBOARD

### 6.1 Create AnalyticsView (New Tab or Accessible from Home)
- [ ] Add new "Analytics" tab (5th tab) OR
- [ ] Add "Analytics" button in Home tab header
- [ ] Create AnalyticsView structure with ScrollView
- [ ] Add navigation bar with "Analytics" title
- [ ] Add date range selector (Last 7 days, 30 days, 3 months, 6 months, Year, All Time)

### 6.2 Create AnalyticsService
- [ ] Create new file: `Services/AnalyticsService.swift`
- [ ] Add method: `calculateSpendingTrends(for dateRange:) -> [DateValue]`
- [ ] Add method: `calculateCategoryBreakdown() -> [CategorySpending]`
- [ ] Add method: `calculateYearOverYear() -> YearComparison`
- [ ] Add method: `detectUnusedSubscriptions() -> [Subscription]`
- [ ] Add method: `calculateSavingsOpportunities() -> [SavingsSuggestion]`
- [ ] Add method: `forecastSpending(months: Int) -> [ForecastValue]`
- [ ] Integrate with DataManager

### 6.3 Spending Trends Chart (Swift Charts)
- [ ] Import Charts framework
- [ ] Create spending trends line chart:
  - X-axis: Months (or weeks/days based on range)
  - Y-axis: Amount spent
  - Show all spending line (default)
  - Toggle for Subscriptions only
  - Toggle for Transactions only
- [ ] Add interactive data point selection:
  - Tap to see exact amount
  - Show date and breakdown
  - Highlight selected point
- [ ] Add trend line (linear regression):
  - Show if spending is increasing/decreasing
  - Display percentage change
  - Show projection
- [ ] Add annotations for significant events (large expenses, new subscriptions)

### 6.4 Category Breakdown Charts
- [ ] Create category pie chart:
  - Show all categories with spending
  - Color code by category colors
  - Show percentage labels
  - Interactive segment selection
- [ ] Create category bar chart (alternative view):
  - Horizontal bars
  - Sorted by amount (highest first)
  - Show amount and percentage
- [ ] Add drill-down functionality:
  - Tap category to see all items
  - Navigate to filtered view
  - Show category statistics

### 6.5 Subscription Analytics Section
- [ ] Create subscription comparison bar chart:
  - Show top 10 subscriptions
  - Compare monthly costs
  - Highlight most expensive
- [ ] Add "Monthly vs Annual" toggle:
  - Show both monthly and yearly equivalent
  - Highlight potential savings with annual plans
- [ ] Add rankings section:
  - "Most Expensive" top 5
  - "Least Used" top 5 (if usage tracking implemented)
  - "Recently Added" top 5
  - "Trials Ending Soon"
- [ ] Add subscription totals:
  - Total active subscriptions count
  - Total monthly cost
  - Total annual cost (projected)
  - Average subscription cost

### 6.6 Insights & Recommendations Section
- [ ] Create "Potential Savings" card:
  - Calculate unused subscriptions
  - Calculate if switching to annual saves money
  - Show total potential savings
- [ ] Add "Unused Subscriptions" detection:
  - Find subscriptions with no linked transactions
  - Find subscriptions marked as unused (if tracking)
  - Show days since last use
  - "Cancel" quick action button
- [ ] Add "Trials Expiring Soon" card:
  - Show trials ending in next 7 days
  - Show date of expiration
  - Estimated cost if converted
  - "Cancel" or "Keep" quick actions
- [ ] Add "Price Increases Detected" card:
  - Show subscriptions with recent price increases
  - Show old vs new price
  - Show percentage increase
  - Link to price history
- [ ] Add "Spending vs Budget" comparison:
  - Set monthly budget (new setting)
  - Show current spending vs budget
  - Progress bar visualization
  - Alert if over budget

### 6.7 Year-over-Year Comparison
- [ ] Create comparison view:
  - This Year vs Last Year (if enough data)
  - Show percentage increase/decrease
  - Highlight months with significant changes
- [ ] Add comparison metrics:
  - Total spending (YoY)
  - Average monthly spending (YoY)
  - Number of subscriptions (YoY)
  - Top growing categories
  - Top declining categories
- [ ] Make exportable:
  - "Export Report" button
  - Generate PDF with all charts
  - Share via email/Messages

---

## = NEW FEATURE: COMPREHENSIVE REMINDERS & NOTIFICATIONS

### 7.1 Enhance NotificationManager Service
- [ ] Open `Services/NotificationManager.swift`
- [ ] Add method: `scheduleRenewalReminder(for subscription: Subscription, daysBefore: Int)`
  - Calculate reminder date (next billing date - days before)
  - Create notification content with subscription details
  - Add custom actions (View, Snooze, Cancel Sub)
  - Schedule notification
  - Store scheduled notification ID
- [ ] Add method: `scheduleTrialExpirationReminder(for subscription: Subscription)`
  - Calculate trial expiration dates (3 days, 1 day, same day)
  - Schedule multiple notifications
  - Add custom actions
- [ ] Add method: `schedulePriceChangeAlert(for subscription: Subscription, oldPrice: Double, newPrice: Double)`
  - Create price increase notification
  - Show old vs new price
  - Add "View Details" action
- [ ] Add method: `scheduleUnusedSubscriptionAlert(for subscription: Subscription, daysUnused: Int)`
  - Schedule after X days of no usage
  - Suggest cancellation
  - Add "Still Using" action to reset timer
- [ ] Add method: `updateScheduledReminders(for subscription: Subscription)`
  - Cancel old reminders
  - Reschedule with new settings
- [ ] Add method: `cancelAllReminders(for subscription: Subscription)`
  - Called when subscription is deleted
- [ ] Add notification action handling:
  - "View" � Open subscription detail
  - "Snooze" � Reschedule for tomorrow
  - "Cancel Sub" � Open cancellation confirmation

### 7.2 Update Subscription Model
- [ ] Open `Models/DataModels/Subscription.swift`
- [ ] Add field: `var reminderDaysBefore: Int = 3`
- [ ] Add field: `var enableRenewalReminder: Bool = true`
- [ ] Add field: `var lastReminderSent: Date?`
- [ ] Add field: `var reminderTime: Date? // Time of day for reminders (e.g., 9 AM)`
- [ ] Update SwiftData model: `Models/SwiftDataModels/SubscriptionModel.swift`
- [ ] Create schema migration (V1 � V2)

### 7.3 Update EditSubscriptionSheet
- [ ] Open `Views/Sheets/EditSubscriptionSheet.swift`
- [ ] Add "Reminders" section:
  - "Enable Renewal Reminders" toggle
  - "Remind me" picker (1, 3, 7, 14, 30 days before)
  - "Reminder time" time picker (default 9:00 AM)
  - "Test Reminder" button (sends test notification)
- [ ] Save reminder settings when subscription is saved
- [ ] Call `NotificationManager.updateScheduledReminders()` on save

### 7.4 Create Notification Scheduling Logic
- [ ] Update `DataManager.addSubscription()`:
  - Schedule notifications after creating subscription
- [ ] Update `DataManager.updateSubscription()`:
  - Cancel old notifications
  - Schedule new notifications with updated settings
- [ ] Update `DataManager.deleteSubscription()`:
  - Cancel all notifications for subscription
- [ ] Update `SubscriptionRenewalService.processOverdueRenewals()`:
  - Reschedule notifications for new billing cycle
  - Update lastReminderSent date

### 7.5 Add Rich Notification Content
- [ ] Create custom notification content:
  - Title: "{Subscription Name} renews in {X} days"
  - Body: "${amount} will be charged on {date}"
  - Subtitle: Category name
  - Badge: Number of upcoming renewals
- [ ] Add subscription icon/image to notification (if possible)
- [ ] Add custom sound for subscription reminders
- [ ] Add action buttons:
  - "View" (default action)
  - "Remind Me Tomorrow"
  - "Cancel Subscription" (destructive)

### 7.6 Create Notification History View (New)
- [ ] Create `Views/NotificationHistoryView.swift`
- [ ] Show list of all sent notifications:
  - Subscription name
  - Notification type (renewal, trial, price change)
  - Date sent
  - Actions taken (if any)
- [ ] Add filtering: All, Renewals, Trials, Price Changes
- [ ] Add "Clear History" button
- [ ] Link from Settings � Notifications � "History"

### 7.7 Add Notification Testing
- [ ] Add "Send Test Notification" in Settings
- [ ] Create sample notification with current data
- [ ] Verify notification appears correctly
- [ ] Test notification actions work

---

## <� NEW FEATURE: FREE TRIAL TRACKING

### 8.1 Update Subscription Data Model
- [ ] Open `Models/DataModels/Subscription.swift`
- [ ] Add fields:
  ```swift
  var isFreeTrial: Bool = false
  var trialStartDate: Date?
  var trialEndDate: Date?
  var trialDuration: Int? // days
  var willConvertToPaid: Bool = true // Auto-renew
  var trialPrice: Double = 0.0 // Usually free
  ```
- [ ] Add computed properties:
  ```swift
  var daysUntilTrialEnd: Int? {
    guard let end = trialEndDate else { return nil }
    return Calendar.current.dateComponents([.day], from: Date(), to: end).day
  }
  var isTrialExpired: Bool {
    guard let end = trialEndDate else { return false }
    return Date() > end
  }
  var trialStatus: String {
    // Returns: "Active", "Expires in X days", "Expired"
  }
  ```
- [ ] Update SwiftData model `SubscriptionModel.swift`
- [ ] Create schema migration V2 � V3

### 8.2 Update EditSubscriptionSheet for Trials
- [ ] Open `Views/Sheets/EditSubscriptionSheet.swift`
- [ ] Add "Free Trial" section (before price section):
  - "This is a free trial" toggle
  - When enabled, show:
    - Trial start date picker (default: today)
    - Trial end date picker (or duration in days)
    - Trial duration calculator (auto-calculate from dates)
    - "Will convert to paid" toggle (default: ON)
    - "Cancel before" date display (trial end date - 1 day)
    - Price after trial field (separate from regular price)
- [ ] Update form validation:
  - If trial, allow price to be 0
  - Require trial end date if trial toggle is on
  - Show warning if trial end < 3 days away
- [ ] Update save logic:
  - If trial and willConvertToPaid, schedule trial expiration reminder
  - Set isActive based on trial status
  - Update next billing date (trial end date if trial)

### 8.3 Add Trial Indicators in UI
- [ ] Update subscription card views:
  - Add "FREE TRIAL" badge (yellow/gold color) in top-left
  - Show trial end countdown instead of next billing for trials
  - Use different icon/color scheme for trial subscriptions
  - Add "Expires in X days" subtitle
- [ ] Update SubscriptionDetailView:
  - Add prominent "Trial Status" section at top
  - Show trial timeline (start � end with progress bar)
  - Show days remaining
  - Show "Will convert to paid on {date}" if enabled
  - Show action buttons: "Convert Now", "Cancel Before Trial Ends"
  - Change colors: Yellow/gold for active trials, Red for expiring soon
- [ ] Update SubscriptionsView list/grid:
  - Sort trials to top (optional setting)
  - Group trials separately if using category grouping

### 8.4 Add Trial Expiration Warnings
- [ ] In SubscriptionsView, add "Trials Ending Soon" header section:
  - Show trials expiring within 7 days
  - Red/orange highlighting for < 3 days
  - Quick action buttons: "Cancel" or "Keep"
- [ ] In HomeView, add "Trial Alerts" card:
  - Count of trials expiring soon
  - Next trial to expire with countdown
  - Tap to view all trials
- [ ] Send notifications for trial expiration:
  - 3 days before: "Your {name} trial ends in 3 days"
  - 1 day before: "Last day of your {name} trial"
  - On trial end day: "{name} trial expired. Charged ${amount} today"
  - Include actions: "Cancel Now", "Keep", "Remind Tomorrow"

### 8.5 Update SubscriptionRenewalService for Trials
- [ ] Open `Services/SubscriptionRenewalService.swift`
- [ ] Add method: `processTrialExpirations()`
  - Check for expired trials today
  - If willConvertToPaid:
    - Convert to paid subscription
    - Update isFreeTrial = false
    - Update price to post-trial price
    - Calculate next billing date
    - Send "Trial Converted" notification
  - If !willConvertToPaid:
    - Mark as cancelled
    - Send "Trial Ended" notification
- [ ] Call this method daily (in app delegate or via background task)
- [ ] Add method: `getTrialsEndingSoon(within days: Int) -> [Subscription]`
- [ ] Add method: `convertTrialToPaid(subscription: Subscription)`

### 8.6 Add Trial Statistics
- [ ] In AnalyticsView, add "Trial Tracking" section:
  - Active trials count
  - Trials converted to paid (success rate)
  - Trials cancelled before end
  - Average trial duration
  - Money saved from cancelled trials
  - Chart showing trial conversions over time

---

## =� NEW FEATURE: PRICE HISTORY TRACKING

### 9.1 Create PriceChange Model
- [ ] Create `Models/DataModels/PriceChange.swift`:
  ```swift
  struct PriceChange: Identifiable, Codable {
    var id: UUID = UUID()
    var subscriptionId: UUID
    var oldPrice: Double
    var newPrice: Double
    var changeDate: Date = Date()
    var changePercentage: Double // Calculated
    var reason: String? // Optional user note
    var detectedAutomatically: Bool = false
  }
  ```
- [ ] Create SwiftData model: `Models/SwiftDataModels/PriceChangeModel.swift`
- [ ] Update Subscription model:
  - Add field: `var priceHistory: [UUID] = []` (PriceChange IDs)
  - Or: Add relationship in SwiftData
- [ ] Update schema migration

### 9.2 Update Subscription Edit Logic
- [ ] Open `Services/DataManager.swift`
- [ ] Modify `updateSubscription()` method:
  - Compare new price with old price
  - If price changed:
    - Create PriceChange record
    - Save to persistence
    - Add to subscription.priceHistory
    - If price increased, call NotificationManager.schedulePriceChangeAlert()
    - Update subscription.lastPriceChange date
- [ ] Add optional "Reason for Price Change" parameter
- [ ] Add method: `addPriceChange(for subscription:, oldPrice:, newPrice:, reason:)`

### 9.3 Add Price History UI in SubscriptionDetailView
- [ ] Open `Views/DetailViews/SubscriptionDetailView.swift`
- [ ] Add "Price History" section (after Overview):
  - Only show if priceHistory.count > 0
  - Section header: "Price History"
  - List of price changes:
    - Old price � New price (with arrow)
    - Change percentage (red for increase, green for decrease)
    - Date of change
    - Reason (if provided)
  - Sort by date (most recent first)
- [ ] Add "View Price Chart" button:
  - Navigate to PriceHistoryChartView
  - Show line chart of price over time
  - X-axis: Date
  - Y-axis: Price
  - Mark increases/decreases with colors
  - Show annotations for each change

### 9.4 Create PriceHistoryChartView
- [ ] Create `Views/PriceHistoryChartView.swift`
- [ ] Use Swift Charts to create line chart
- [ ] Show all price points over time
- [ ] Color code: Green line for decreases, Red for increases
- [ ] Add interactive markers:
  - Tap point to see exact date and amount
  - Show percentage change from previous
- [ ] Add statistics:
  - Current price
  - Original price (when first added)
  - Total change ($ and %)
  - Number of changes
  - Average price

### 9.5 Add Price Increase Alerts
- [ ] In NotificationManager, implement `schedulePriceChangeAlert()`:
  - Send immediate notification
  - Title: "{Subscription} price increased"
  - Body: "${oldPrice} � ${newPrice} (+X%)"
  - Actions: "View Details", "Cancel Subscription"
- [ ] In SubscriptionDetailView, add "Price Increased" badge:
  - Show for 30 days after price increase
  - Yellow/orange color
  - Dismissible (but shows again on next increase)
- [ ] In SubscriptionsView, add filter: "Recent Price Increases"
- [ ] In AnalyticsView, add "Price Changes" section:
  - List all subscriptions with recent increases
  - Total additional cost per month
  - Chart of price changes over time

### 9.6 Add Price Change Confirmation (Optional Enhancement)
- [ ] Add "Confirm Price Change" sheet when editing:
  - "Did the price really change, or are you correcting an error?"
  - Options: "Yes, price changed" / "No, correcting error"
  - If real change, create PriceChange record
  - If correction, don't create record

---

## <� NEW FEATURE: HOME SCREEN WIDGETS

### 10.1 Create Widget Extension
- [ ] Add Widget Extension target to project:
  - File � New � Target � Widget Extension
  - Name: "SwiffWidgets"
  - Enable "Include Configuration Intent"
- [ ] Set up widget bundle structure
- [ ] Configure widget entitlements
- [ ] Link to main app data (App Groups)

### 10.2 Set Up App Groups for Data Sharing
- [ ] Enable App Groups capability in main app
- [ ] Enable App Groups capability in widget extension
- [ ] Create group: `group.com.yourcompany.swiff`
- [ ] Update PersistenceService to use shared container:
  ```swift
  let container = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.yourcompany.swiff"
  )
  ```
- [ ] Test data accessibility from widget

### 10.3 Create Upcoming Renewals Widget
- [ ] Create `UpcomingRenewalsWidget.swift`
- [ ] Design Small Widget (2x2):
  - Show next subscription to renew
  - Subscription icon and name
  - "In X days" countdown
  - Price
- [ ] Design Medium Widget (4x2):
  - Show next 3 subscriptions
  - Compact list view
  - Icons, names, prices, countdown
- [ ] Design Large Widget (4x4):
  - Show next 7 subscriptions
  - Monthly total at top
  - Full list with details
  - "View All" link
- [ ] Add configuration intent:
  - Filter by category (optional)
  - Sort order (date, price)
- [ ] Implement widget timeline:
  - Refresh daily at midnight
  - Refresh when subscription changes (via widget reload)

### 10.4 Create Monthly Spending Widget
- [ ] Create `MonthlySpendingWidget.swift`
- [ ] Design Small Widget:
  - Monthly total (large number)
  - Trend arrow (��)
  - Percentage change from last month
- [ ] Design Medium Widget:
  - Monthly total at top
  - Mini bar chart (last 6 months)
  - Top 3 categories with percentages
- [ ] Design Large Widget:
  - Monthly total
  - Full spending chart (last 12 months)
  - Category breakdown (pie chart or list)
  - Comparison: This month vs last month
- [ ] Add configuration intent:
  - Date range (This month, Last 30 days, Year to date)
  - Show subscriptions only vs all transactions

### 10.5 Create Quick Actions Widget
- [ ] Create `QuickActionsWidget.swift`
- [ ] Design Medium Widget:
  - Grid of 4 buttons:
    - "Add Transaction" � Opens app with AddTransactionSheet
    - "Add Subscription" � Opens app with AddSubscriptionSheet
    - "View Subscriptions" � Opens app to subscriptions tab
    - "View Analytics" � Opens app to analytics
  - Custom icons and labels
- [ ] Implement deep linking:
  - Create URL scheme: `swiff://action/add-transaction`
  - Handle URLs in app delegate
  - Navigate to appropriate view

### 10.6 Add Widget Interactivity (iOS 17+)
- [ ] Add interactive buttons to widgets (if targeting iOS 17+)
- [ ] Create App Intents for widget actions:
  - `AddTransactionIntent`
  - `ViewSubscriptionsIntent`
  - `MarkAsPaidIntent` (for renewals)
- [ ] Test interactive functionality

### 10.7 Widget Polish
- [ ] Design widget previews for Widget Gallery
- [ ] Add widget descriptions
- [ ] Test all widget sizes and configurations
- [ ] Test widget on different devices (iPhone, iPad)
- [ ] Test widget in light and dark mode
- [ ] Optimize widget performance (fast loading)

---

## <� UI/UX ENHANCEMENTS

### 11.1 Create Onboarding Flow
- [ ] Create `Views/OnboardingView.swift`
- [ ] Design welcome screen:
  - App logo and name
  - Tagline: "Track subscriptions, manage expenses, save money"
  - "Get Started" button
  - "Sign In" button (if adding authentication later)
- [ ] Design feature showcase (3-4 screens with swipe):
  - Screen 1: "Track All Subscriptions" (visual: subscription cards)
  - Screen 2: "Never Miss a Payment" (visual: notifications)
  - Screen 3: "Visualize Your Spending" (visual: charts)
  - Screen 4: "Split Expenses with Friends" (visual: group expenses)
  - Pagination dots, Next/Skip buttons
- [ ] Design quick setup wizard:
  - Step 1: Choose default currency
  - Step 2: Enable notifications (request permission)
  - Step 3: Import existing data OR start fresh
  - Step 4: Add first subscription (optional)
- [ ] Add "Import Data" option:
  - Import from CSV
  - Import from competitors (templates)
  - Import from backup file
- [ ] Add "Start with Sample Data" option:
  - Creates 5-10 sample subscriptions
  - Creates sample people and transactions
  - Shows "This is sample data" banner
  - "Clear Sample Data" button in Settings
- [ ] Add "Skip" button on each screen
- [ ] Save onboarding completion status: `UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")`
- [ ] Show onboarding only on first launch

### 11.2 Implement Loading States
- [ ] Verify SkeletonView is used in all lists:
  - HomeView transaction list
  - RecentActivityView (Feed)
  - PeopleView list
  - SubscriptionsView grid/list
  - SearchView results
- [ ] Add loading indicators for async operations:
  - DataManager operations
  - Backup creation/restoration
  - CSV export
  - Notification scheduling
- [ ] Add progress bars for bulk operations:
  - Bulk import (show X of Y imported)
  - Bulk delete (show X of Y deleted)
  - Backup creation (show progress percentage)
- [ ] Add shimmer animation to skeletons:
  - Use gradient overlay
  - Animate left to right
  - Match app theme colors

### 11.3 Enhance Error States
- [ ] Verify all errors are caught and displayed:
  - Check all DataManager methods have try-catch
  - Check all PersistenceService calls have error handling
  - Check all async operations have error handling
- [ ] Design error view component:
  - Error icon (SF Symbol: exclamationmark.triangle)
  - Error title (short, user-friendly)
  - Error message (explain what went wrong)
  - "Retry" button (attempts operation again)
  - "Cancel" or "Dismiss" button
- [ ] Add helpful error messages:
  - Instead of: "Persistence error"
  - Use: "Couldn't save subscription. Please try again."
- [ ] Add error illustrations:
  - Use SF Symbols or custom illustrations
  - Match app theme
  - Add subtle animation (shake, bounce)
- [ ] Add error logging:
  - Log errors to console (dev mode)
  - Optionally: Send to crash reporting service (production)

### 11.4 Add Haptic Feedback
- [ ] Import HapticManager utility (already exists)
- [ ] Add haptics to button presses:
  - Primary buttons: Medium impact (`.medium`)
  - Destructive buttons: Heavy impact (`.heavy`)
  - Selection (tabs, pills): Light impact (`.light`)
- [ ] Add haptics to interactions:
  - Success haptic on save: `.success`
  - Warning haptic on delete confirmation: `.warning`
  - Error haptic on validation failure: `.error`
  - Selection haptic on list item tap: `.selection`
- [ ] Add haptics to swipe actions:
  - Light haptic when swipe reveals actions
  - Medium haptic when action threshold reached
- [ ] Respect "Reduce Motion" setting:
  - Check UIAccessibility.isReduceMotionEnabled
  - Reduce or disable haptics if enabled

### 11.5 Enhance Animations
- [ ] Use AnimationPresets utility (already exists)
- [ ] Add smooth transitions between views:
  - Use `.transition(.slide)` for navigation
  - Use `.transition(.opacity)` for modals
  - Use `.transition(.scale)` for cards
- [ ] Add card flip animation for edits:
  - When tapping edit, flip card to show edit form
  - When saving, flip back to detail view
- [ ] Add bounce animation for new items:
  - When adding new subscription, animate card entry
  - Use `.spring(response: 0.3, dampingFraction: 0.6)`
- [ ] Add fade animation for deletions:
  - When deleting, fade out and slide away
  - Use `.transition(.opacity.combined(with: .move(edge: .trailing)))`
- [ ] Add number animation for value changes:
  - Animate financial totals (count up/down)
  - Use withAnimation(.easeInOut)
- [ ] Respect "Reduce Motion" setting:
  - Check UIAccessibility.isReduceMotionEnabled
  - Simplify or disable animations if enabled

### 11.6 Accessibility Audit
- [ ] Add VoiceOver labels to all interactive elements:
  - Buttons: `.accessibilityLabel("Add subscription")`
  - Images: `.accessibilityLabel("Netflix icon")`
  - Icons: `.accessibilityLabel("Settings")`
  - Custom controls: Add custom accessibility traits
- [ ] Test with VoiceOver enabled:
  - Enable VoiceOver: Settings � Accessibility � VoiceOver
  - Navigate through all views
  - Verify all elements are announced correctly
  - Verify navigation order is logical
  - Verify actions work with VoiceOver
- [ ] Support Dynamic Type (text scaling):
  - Use `.font(.body)`, `.font(.title)` instead of fixed sizes
  - Test with largest accessibility size
  - Ensure text doesn't overlap or truncate
  - Use `.minimumScaleFactor()` for critical text
  - Use `.lineLimit(nil)` for expandable text
- [ ] Ensure minimum touch target size:
  - All buttons/taps should be at least 44x44 points
  - Add `.contentShape(Rectangle())` if needed
  - Increase padding around small icons
- [ ] Add accessibility hints for complex interactions:
  - Swipe actions: `.accessibilityHint("Swipe left to delete")`
  - Long press: `.accessibilityHint("Long press to edit")`
  - Drag & drop: `.accessibilityHint("Double tap to select, then drag")`
- [ ] Test color contrast (WCAG AA compliance):
  - Use online contrast checker tools
  - Ensure text has minimum 4.5:1 contrast ratio
  - Ensure interactive elements have 3:1 contrast
  - Test in both light and dark mode
- [ ] Add "Reduce Motion" support:
  - Check UIAccessibility.isReduceMotionEnabled
  - Simplify or disable animations
  - Use fade transitions instead of sliding
- [ ] Add support for other accessibility features:
  - Reduce Transparency
  - Increase Contrast
  - Button Shapes
  - On/Off Labels

---

## = SEARCH ENHANCEMENTS

### 12.1 Improve Global SearchView
- [ ] Open `Views/SearchView.swift`
- [ ] Add search history feature:
  - Store last 10 searches in UserDefaults
  - Show below search bar when empty
  - Tap to repeat search
  - "Clear History" button
- [ ] Add search suggestions/autocomplete:
  - As user types, show matching items
  - Show recent items first
  - Group by type (People, Subscriptions, etc.)
- [ ] Add "Search within Category" filter:
  - After searching, add filter: "Search in Entertainment only"
  - Narrow results by category
- [ ] Add advanced search filters sheet:
  - Date range (for transactions)
  - Amount range
  - Status (active, paused, cancelled)
  - Tags (for transactions)
  - Payment method
  - "Apply Filters" button
- [ ] Add search results sorting:
  - Relevance (default)
  - Date (newest first)
  - Amount (highest first)
  - Name (A-Z)
- [ ] Add "No Results" state:
  - Show helpful message
  - Show search tips
  - "Clear Search" button

### 12.2 Add Spotlight Integration
- [ ] Import CoreSpotlight framework
- [ ] Create search indexing service: `Services/SpotlightIndexingService.swift`
- [ ] Index subscriptions:
  - Create CSSearchableItem for each subscription
  - Add attributes: name, category, price, billing cycle
  - Add keywords for better search
- [ ] Index people:
  - Create CSSearchableItem for each person
  - Add attributes: name, email, balance
- [ ] Index transactions:
  - Create CSSearchableItem for each transaction
  - Add attributes: title, category, amount, date
- [ ] Update index when data changes:
  - On add: Index new item
  - On update: Update index
  - On delete: Remove from index
- [ ] Handle Spotlight results:
  - Implement application(_:continue:restorationHandler:)
  - Parse CSSearchableItem identifier
  - Navigate to appropriate view

### 12.3 Add Siri Suggestions (Future Enhancement)
- [ ] Create Siri intent definitions:
  - "Show my subscriptions"
  - "How much do I spend on subscriptions?"
  - "When is my next payment?"
- [ ] Donate intents when user performs actions
- [ ] Handle Siri shortcuts in app

### 12.4 Add Quick Search from Home Screen
- [ ] Add pull-down gesture on Home tab
- [ ] Show compact search bar
- [ ] Search across all data
- [ ] Show inline results

---

## =� DATA MODEL ENHANCEMENTS

### 13.1 Update Transaction Model
- [ ] Open `Models/DataModels/Transaction.swift`
- [ ] Add fields:
  ```swift
  var relatedSubscriptionId: UUID? // Link to subscription
  var merchant: String? // e.g., "Netflix", "Uber"
  var merchantCategory: String? // MCC code or category
  var isRecurringCharge: Bool = false
  var paymentStatus: PaymentStatus = .completed
  var paymentMethod: PaymentMethod? // Which card/account used
  var location: String? // Where transaction occurred
  var notes: String // Already exists
  ```
- [ ] Create PaymentStatus enum:
  ```swift
  enum PaymentStatus: String, Codable {
    case pending
    case completed
    case failed
    case refunded
    case cancelled
  }
  ```
- [ ] Update TransactionModel (SwiftData)
- [ ] Create schema migration
- [ ] Update AddTransactionSheet to include new fields (optional)

### 13.2 Update Person Model
- [ ] Open `Models/DataModels/Person.swift`
- [ ] Add fields:
  ```swift
  var contactId: String? // iOS Contacts identifier
  var preferredPaymentMethod: PaymentMethod?
  var notificationPreferences: NotificationPreferences
  var relationshipType: String? // Friend, Family, Coworker, etc.
  var notes: String?
  ```
- [ ] Create NotificationPreferences struct:
  ```swift
  struct NotificationPreferences: Codable {
    var enableReminders: Bool = true
    var reminderFrequency: Int = 7 // days
    var preferredContactMethod: ContactMethod = .inApp
  }
  enum ContactMethod: String, Codable {
    case inApp, email, sms, whatsapp
  }
  ```
- [ ] Update PersonModel (SwiftData)
- [ ] Create schema migration

### 13.3 Update Subscription Model
- [ ] Open `Models/DataModels/Subscription.swift`
- [ ] Add all fields from previous sections:
  - Trial fields (section 8.1)
  - Reminder fields (section 7.2)
  - Price history fields (section 9.1)
- [ ] Add additional fields:
  ```swift
  var autoRenew: Bool = true
  var cancellationDeadline: Date? // Must cancel by this date
  var cancellationInstructions: String? // How to cancel
  var cancellationDifficulty: CancellationDifficulty?
  var lastUsedDate: Date? // For usage tracking
  var usageCount: Int = 0 // How many times marked as used
  var alternativeSuggestions: [String]? // Competitor names
  var retentionOffers: [RetentionOffer] = []
  var documents: [SubscriptionDocument] = [] // Contracts, receipts
  ```
- [ ] Create supporting types:
  ```swift
  enum CancellationDifficulty: String, Codable {
    case easy, medium, hard
  }
  struct RetentionOffer: Codable {
    var offerDescription: String
    var discountedPrice: Double
    var offerDate: Date
    var accepted: Bool
  }
  struct SubscriptionDocument: Codable {
    var id: UUID
    var type: DocumentType
    var name: String
    var data: Data // PDF or image
    var dateAdded: Date
  }
  enum DocumentType: String, Codable {
    case contract, receipt, confirmation, cancellation
  }
  ```
- [ ] Update SubscriptionModel (SwiftData)
- [ ] Create schema migration

### 13.4 Create Comprehensive Migration Plan
- [ ] Create `Persistence/SchemaV2.swift`:
  - Define all new model versions with added fields
  - Ensure default values for new fields
- [ ] Create `Persistence/MigrationPlanV1toV2.swift`:
  - Define migration strategy: .lightweight or .custom
  - Handle data transformations if needed
- [ ] Test migration:
  - Create test database with V1 schema
  - Add sample data
  - Run migration to V2
  - Verify all data preserved
  - Verify new fields have default values
- [ ] Create unit tests for migration: `SwiffIOSTests/MigrationV1toV2Tests.swift`
- [ ] Document migration in `Docs/DatabaseMigration.md`

---

## <� CREATE NEW SERVICES

### 14.1 Create AnalyticsService
- [ ] Create `Services/AnalyticsService.swift`
- [ ] Define as singleton or injectable
- [ ] Implement methods:
  ```swift
  class AnalyticsService {
    // Spending trends
    func calculateSpendingTrends(for dateRange: DateRange) -> [DateValue]
    func calculateMonthlyAverage() -> Double
    func calculateYearOverYearChange() -> Double

    // Category analysis
    func calculateCategoryBreakdown() -> [CategorySpending]
    func getTopCategories(limit: Int) -> [CategorySpending]

    // Subscription analytics
    func getTotalMonthlyCost() -> Double
    func getAverageCostPerSubscription() -> Double
    func getMostExpensiveSubscriptions(limit: Int) -> [Subscription]

    // Forecasting
    func forecastSpending(months: Int) -> [ForecastValue]
    func predictNextMonthSpending() -> Double

    // Detection algorithms
    func detectUnusedSubscriptions(threshold: Int) -> [Subscription]
    func detectPriceIncreases(within days: Int) -> [Subscription]
    func detectTrialsEndingSoon(within days: Int) -> [Subscription]

    // Recommendations
    func generateSavingsOpportunities() -> [SavingsSuggestion]
    func suggestCancellations() -> [Subscription]
    func suggestAnnualConversions() -> [AnnualSuggestion]
  }

  struct CategorySpending {
    var category: SubscriptionCategory
    var totalAmount: Double
    var percentage: Double
    var count: Int
  }

  struct ForecastValue {
    var date: Date
    var predictedAmount: Double
    var confidence: Double // 0.0 to 1.0
  }

  struct SavingsSuggestion {
    var type: SuggestionType
    var subscription: Subscription
    var potentialSavings: Double
    var description: String
  }

  enum SuggestionType {
    case unused, annualConversion, priceIncrease, alternative
  }
  ```
- [ ] Integrate with DataManager for data access
- [ ] Add caching for expensive calculations
- [ ] Add unit tests

### 14.2 Create ReminderService
- [ ] Create `Services/ReminderService.swift`
- [ ] Define service:
  ```swift
  class ReminderService {
    private let notificationManager: NotificationManager

    // Scheduling
    func scheduleAllReminders(for subscription: Subscription)
    func rescheduleReminders(for subscription: Subscription)
    func cancelReminders(for subscription: Subscription)

    // Smart timing
    func calculateOptimalReminderTime(for subscription: Subscription) -> Date
    func shouldSendReminder(for subscription: Subscription) -> Bool

    // Reminder management
    func getScheduledReminders() -> [ScheduledReminder]
    func snoozeReminder(for subscription: Subscription, until: Date)
    func dismissReminder(for subscription: Subscription)

    // Batch operations
    func scheduleAllPendingReminders()
    func cleanupExpiredReminders()
  }

  struct ScheduledReminder {
    var id: String
    var subscriptionId: UUID
    var type: ReminderType
    var scheduledDate: Date
    var status: ReminderStatus
  }

  enum ReminderType {
    case renewal, trialExpiration, priceChange, unused
  }

  enum ReminderStatus {
    case scheduled, sent, snoozed, dismissed
  }
  ```
- [ ] Integrate with NotificationManager
- [ ] Add persistence for reminder state
- [ ] Add unit tests

### 14.3 Create ChartDataService
- [ ] Create `Services/ChartDataService.swift`
- [ ] Define service to format data for Swift Charts:
  ```swift
  class ChartDataService {
    // Line chart data
    func prepareSpendingTrendData(for range: DateRange) -> [TrendDataPoint]
    func preparePriceHistoryData(for subscription: Subscription) -> [PriceDataPoint]

    // Bar chart data
    func prepareCategoryData() -> [CategoryData]
    func prepareSubscriptionComparisonData() -> [SubscriptionData]
    func prepareMonthlyComparisonData() -> [MonthlyData]

    // Pie chart data
    func prepareCategoryDistributionData() -> [CategoryShare]

    // Data aggregation
    func aggregateByMonth(transactions: [Transaction]) -> [MonthlyTotal]
    func aggregateByCategory(transactions: [Transaction]) -> [CategoryTotal]

    // Caching
    func clearCache()
  }

  struct TrendDataPoint {
    var date: Date
    var amount: Double
  }

  struct CategoryData {
    var category: String
    var amount: Double
    var color: Color
  }
  ```
- [ ] Add caching for performance (important for charts)
- [ ] Add data transformation helpers
- [ ] Add unit tests

---

## >� TESTING & QUALITY ASSURANCE

### 15.1 Create UI Test Target
- [ ] Add UI Testing target if not exists:
  - File � New � Target � UI Testing Bundle
  - Name: "SwiffUITests"
- [ ] Configure test target with main app access
- [ ] Create base test class with common setup

### 15.2 Write UI Tests
- [ ] Test main navigation flows:
  - `testTabBarNavigation()` - Switch between all tabs
  - `testSubscriptionDetailNavigation()` - Home � Subscription detail
  - `testPersonDetailNavigation()` - People � Person detail
  - `testSearchNavigation()` - Open search, perform search, tap result
- [ ] Test add/edit/delete operations:
  - `testAddSubscription()` - Add new subscription end-to-end
  - `testEditSubscription()` - Edit existing subscription
  - `testDeleteSubscription()` - Delete subscription with confirmation
  - `testAddTransaction()` - Add new transaction
  - `testAddPerson()` - Add new person
- [ ] Test search functionality:
  - `testGlobalSearch()` - Search across all types
  - `testSearchFiltering()` - Apply category filters
  - `testSearchResults()` - Verify results display correctly
- [ ] Test filters and sorting:
  - `testTransactionFilters()` - Apply date range, category filters
  - `testSubscriptionFilters()` - Filter by status, category
  - `testSortingOptions()` - Test all sort options
- [ ] Test error scenarios:
  - `testInvalidInput()` - Enter invalid data, verify error
  - `testDeleteConfirmation()` - Cancel delete, verify not deleted
  - `testEmptyStates()` - Verify empty states display

### 15.3 Create Integration Tests
- [ ] Test DataManager + PersistenceService:
  - `testDataManagerPersistence()` - Add data, restart app, verify persisted
  - `testBulkOperations()` - Import 100 items, verify all saved
  - `testConcurrentAccess()` - Multiple simultaneous operations
- [ ] Test notification scheduling:
  - `testReminderScheduling()` - Add subscription, verify notification scheduled
  - `testReminderCancellation()` - Delete subscription, verify notification cancelled
  - `testNotificationActions()` - Simulate notification action, verify behavior
- [ ] Test backup/restore workflows:
  - `testBackupCreation()` - Create backup, verify file exists and valid
  - `testBackupRestore()` - Restore backup, verify data restored correctly
  - `testBackupConflictResolution()` - Test merge, replace, keep existing
- [ ] Test data migration:
  - `testSchemaV1toV2Migration()` - Migrate old data, verify integrity
  - `testMigrationDefaults()` - Verify new fields have defaults

### 15.4 Performance Testing
- [ ] Test with large datasets:
  - `testLargeSubscriptionList()` - 500+ subscriptions, measure scroll performance
  - `testLargeTransactionList()` - 5000+ transactions, measure load time
  - `testSearchPerformance()` - Search across 10,000 items
- [ ] Profile memory usage:
  - Use Instruments � Allocations
  - Check for memory leaks
  - Verify memory doesn't grow unbounded
  - Test on older devices (iPhone SE)
- [ ] Profile app launch time:
  - Use Instruments � Time Profiler
  - Optimize slow initialization
  - Target < 2 seconds cold launch
  - Target < 0.5 seconds warm launch
- [ ] Optimize slow operations:
  - Identify bottlenecks with profiling
  - Add caching where appropriate
  - Use background threads for heavy work
  - Lazy load images and data

### 15.5 Accessibility Testing
- [ ] Test with VoiceOver:
  - Enable VoiceOver
  - Navigate through entire app
  - Verify all elements are reachable
  - Verify all labels are meaningful
  - Verify actions work correctly
- [ ] Test with Dynamic Type:
  - Settings � Accessibility � Display & Text Size � Larger Text
  - Set to largest size (AX5)
  - Navigate through app
  - Verify text doesn't overlap or truncate
  - Verify layouts adapt correctly
- [ ] Test with Reduce Motion:
  - Settings � Accessibility � Motion � Reduce Motion
  - Verify animations are simplified
  - Verify app is still usable
- [ ] Test with High Contrast:
  - Settings � Accessibility � Display & Text Size � Increase Contrast
  - Verify colors have sufficient contrast
  - Verify borders are visible
- [ ] Test with Color Blindness simulator:
  - Use Xcode Accessibility Inspector
  - Test Protanopia, Deuteranopia, Tritanopia
  - Verify information isn't conveyed by color alone

---

## =� POLISH & LAUNCH PREPARATION

### 16.1 Create App Store Assets
- [ ] Design app icon (1024x1024 PNG):
  - Follow Apple Human Interface Guidelines
  - No transparency or rounded corners (iOS adds them)
  - Export in all required sizes
  - Add to Assets.xcassets
- [ ] Create alternate app icons:
  - Design 3-5 alternate icons
  - Add to Assets.xcassets
  - Implement icon picker in Settings
- [ ] Create screenshots for App Store:
  - iPhone 6.9" (iPhone 16 Pro Max)
  - iPhone 6.7" (iPhone 15 Plus)
  - iPhone 6.5" (iPhone 14 Pro Max)
  - iPad Pro 12.9" (6th gen)
  - iPad Pro 13" (M4)
  - Localize for major markets (if applicable)
- [ ] Design screenshot content:
  - Screenshot 1: Home screen with financial overview
  - Screenshot 2: Subscriptions grid view
  - Screenshot 3: Analytics dashboard with charts
  - Screenshot 4: Subscription detail view
  - Screenshot 5: Notifications example
  - Add device frames and captions
- [ ] Write app description:
  - Compelling headline (30 chars)
  - Promotional text (170 chars)
  - Description (4000 chars):
    - What is Swiff?
    - Key features (bullet points)
    - Benefits
    - Call to action
  - Keywords (100 chars, comma-separated)
- [ ] Create promotional text:
  - Highlight newest features
  - Updated without new version
- [ ] Design App Store banner (1200x600 optional)
- [ ] Create app preview video (30 seconds):
  - Show key features
  - Add captions and voiceover
  - Follow Apple guidelines
  - Export in required formats

### 16.2 Write Documentation
- [ ] Create user guide:
  - "Getting Started" section
  - "Features" section (with screenshots)
  - "Tips & Tricks" section
  - "Troubleshooting" section
  - "FAQ" section
  - Export as PDF or web page
- [ ] Create in-app help:
  - Add "Help" button in Settings
  - Create HelpView with searchable topics
  - Add contextual help hints (? icons)
- [ ] Review Privacy Policy:
  - Already exists in `Views/LegalDocuments/PrivacyPolicyView.swift`
  - Verify content is up-to-date
  - Add sections for new features (notifications, analytics)
  - Ensure GDPR compliance if targeting EU
  - Add privacy nutrition label info for App Store
- [ ] Review Terms of Service:
  - Already exists in `Views/LegalDocuments/TermsOfServiceView.swift`
  - Verify content is appropriate
  - Update version and date
- [ ] Create support resources:
  - Set up support email (support@swiffapp.com)
  - Create auto-reply with common solutions
  - Create support portal or knowledge base (optional)

### 16.3 Optimize Performance
- [ ] Optimize image loading:
  - Implement image caching service
  - Lazy load images in lists
  - Compress large images (receipts)
  - Use proper image formats (HEIC, WebP)
- [ ] Implement pagination:
  - Add pagination to transaction list (load 50 at a time)
  - Add pagination to search results
  - Add "Load More" button or infinite scroll
- [ ] Add image caching:
  - Cache avatar images
  - Cache subscription icons
  - Cache receipt images
  - Use URLCache or custom cache
- [ ] Optimize database queries:
  - Add indexes to frequently queried fields
  - Use predicates efficiently (AND before OR)
  - Limit result sets with fetchLimit
  - Profile slow queries with Instruments
- [ ] Reduce app size:
  - Remove unused images and resources
  - Use App Thinning (automatic)
  - Consider On-Demand Resources for infrequent features
  - Compress assets
  - Target < 50 MB download size

### 16.4 Final QA Pass
- [ ] Test on physical devices:
  - iPhone SE (smallest screen)
  - iPhone 15/16 (standard)
  - iPhone 15/16 Plus (large)
  - iPhone 15/16 Pro Max (largest)
  - iPad (10th gen)
  - iPad Pro
- [ ] Test on iOS versions:
  - iOS 16.0 (minimum supported)
  - iOS 17.x
  - iOS 18.x (latest)
- [ ] Test dark mode:
  - Verify all views render correctly
  - Check color contrast
  - Check custom colors adapt
  - Test switching between modes
- [ ] Test rotation (iPad):
  - Verify all views support rotation
  - Check layouts adapt correctly
  - Test split-screen multitasking
- [ ] Test localizations (if applicable):
  - Export strings for translation
  - Import translated strings
  - Test RTL languages (Arabic, Hebrew)
  - Verify layouts adapt to longer text
- [ ] Regression testing:
  - Test all features one final time
  - Verify bug fixes haven't broken anything
  - Check edge cases
  - Test error scenarios
- [ ] Create bug tracking sheet:
  - Document all found issues
  - Prioritize: Critical, High, Medium, Low
  - Assign to team members
  - Track resolution status
  - Re-test after fixes

### 16.5 Prepare for App Store Submission
- [ ] Create App Store Connect listing:
  - App name
  - Subtitle
  - Primary language
  - Category (Finance)
  - Content rights
  - Age rating (4+)
- [ ] Upload build to App Store Connect:
  - Archive app in Xcode
  - Upload to App Store Connect
  - Wait for processing
  - Select build for submission
- [ ] Fill out App Store information:
  - Screenshots
  - App preview video
  - Description
  - Keywords
  - Support URL
  - Marketing URL (optional)
- [ ] Set pricing and availability:
  - Free (with optional IAP)
  - Available countries
  - Release date (manual or automatic)
- [ ] Fill out App Privacy details:
  - Data collection disclosure
  - Data usage
  - Data sharing (none for Swiff)
- [ ] Submit for review:
  - Add App Review Information
  - Contact information
  - Demo account (if needed)
  - Notes for reviewer
  - Submit

---

## =� IMPLEMENTATION PRIORITY & TIMELINE

### **PHASE 1: MVP - CRITICAL FEATURES** (2-3 weeks)
**Goal:** Make app production-ready with essential subscription features

**Week 1:**
- [ ] 3.1-3.5: Complete/verify People Tab (if missing)
- [ ] 4.1-4.4: Complete/verify Subscriptions Tab (if missing)
- [ ] 1.1: Fix all navigation links
- [ ] 7.1-7.3: Add basic billing reminders system

**Week 2:**
- [ ] 8.1-8.4: Add free trial tracking
- [ ] 6.1-6.3: Add basic analytics (spending trends chart)
- [ ] 11.1: Create onboarding flow
- [ ] 11.2-11.3: Implement loading/error states

**Week 3:**
- [ ] Testing and bug fixes
- [ ] Performance optimization
- [ ] UI polish
- [ ] Documentation
- [ ] Prepare for beta testing

**Deliverables:**
- Fully functional People and Subscriptions tabs
- Working billing reminders
- Free trial tracking
- Basic analytics dashboard
- Smooth user experience
- Ready for beta testing

---

### **PHASE 2: COMPETITIVE PARITY** (3-4 weeks)
**Goal:** Match features of top competitors

**Week 4:**
- [ ] 9.1-9.5: Add price history tracking
- [ ] 6.4-6.6: Complete analytics dashboard
- [ ] 7.4-7.6: Enhance notification system
- [ ] 10.1-10.4: Create home screen widgets

**Week 5:**
- [ ] 1.2-1.4: Enhance Home tab (quick actions, trends)
- [ ] 2.1-2.3: Enhance Feed tab (advanced filtering, bulk actions)
- [ ] 5.1-5.5: Add security and advanced settings
- [ ] 12.1-12.2: Enhance search (history, Spotlight)

**Week 6:**
- [ ] 11.4-11.6: Add haptics, animations, accessibility
- [ ] 3.5: Enhance PersonDetailView (payment requests, statistics)
- [ ] 4.6-4.7: Enhance SubscriptionDetailView (reminders, alternatives)

**Week 7:**
- [ ] 14.1-14.3: Create new services (Analytics, Reminder, ChartData)
- [ ] 13.1-13.4: Complete data model enhancements and migration
- [ ] Integration testing
- [ ] Bug fixes

**Deliverables:**
- Advanced analytics with charts
- Price history tracking
- Rich notifications
- Home screen widgets
- Enhanced search
- Security features
- Competitive feature set

---

### **PHASE 3: POLISH & LAUNCH** (4-5 weeks)

**Week 8:**
- [ ] 15.1-15.2: Create and run UI tests
- [ ] 15.3: Integration testing
- [ ] 15.4: Performance testing and optimization
- [ ] 15.5: Accessibility testing and fixes

**Week 9:**
- [ ] 16.1: Create App Store assets
- [ ] 16.2: Write documentation
- [ ] 16.3: Final performance optimization
- [ ] Bug fixes from testing

**Week 10:**
- [ ] 16.4: Comprehensive QA pass on all devices
- [ ] Fix all critical and high-priority bugs
- [ ] Final regression testing
- [ ] Beta testing with select users

**Week 11:**
- [ ] Address beta feedback
- [ ] Final bug fixes
- [ ] Final polish
- [ ] 16.5: Prepare App Store submission
- [ ] Submit to App Store

**Week 12:**
- [ ] Address App Review feedback (if any)
- [ ] Final approval
- [ ] **LAUNCH!** =�

**Deliverables:**
- Fully tested app
- Complete documentation
- App Store ready
- Launched on App Store

---

## =� CURRENT STATUS SUMMARY

### **What's Working Great** 
- **Data Architecture:** SwiftData with versioning and migrations
- **Core CRUD Operations:** All add/edit/delete functionality
- **Beautiful UI:** Modern design with Wise-inspired components
- **Error Handling:** 15+ specialized error handling utilities
- **Backup System:** Comprehensive backup/restore with conflict resolution
- **Group Expenses:** Unique feature for sharing costs
- **Documentation:** Comprehensive docs in `/Docs`
- **Test Suite:** 40+ test files covering various scenarios

### **Critical Missing Features** L
1. **Billing Reminders** - MUST HAVE for subscription app
2. **Analytics & Charts** - Users expect visual insights
3. **Free Trial Tracking** - Standard feature in all competitors
4. **Complete Tab Navigation** - Need to verify/complete People & Subscriptions tabs
5. **Home Screen Widgets** - Modern iOS feature
6. **Price History** - Track subscription cost changes

### **Estimated Completion**
- **MVP Ready (Phase 1):** 2-3 weeks
- **Competitive (Phase 2):** 5-7 weeks (cumulative)
- **App Store Launch (Phase 3):** 10-12 weeks (cumulative)

### **Competitive Position**
| Feature | Status |
|---------|--------|
| Core subscription tracking |  Excellent |
| Group expense sharing |  Unique strength |
| Data backup/restore |  Excellent |
| UI/UX design |  Beautiful |
| Billing reminders | L Missing |
| Analytics/charts | L Missing |
| Free trial tracking | L Missing |
| Home screen widgets | L Missing |
| Bank integration | L Not planned (Phase 4+) |
| Cloud sync | L Not planned (Phase 4+) |

---

## =� FINAL NOTES

This implementation plan covers **every** feature, **every** button, and **every** piece of logic needed to build a production-ready, competitive subscription management app.

**Key Principles:**
1. **User First:** Every feature should solve a real user problem
2. **Quality Over Speed:** Better to do fewer things well than many things poorly
3. **Test Everything:** Don't ship untested features
4. **Accessibility Matters:** Make app usable for everyone
5. **Performance Counts:** Fast, responsive app = happy users
6. **Iterate Based on Feedback:** Listen to users, adapt quickly

**Success Metrics:**
- App Store rating: 4.5+ stars
- User retention: 70%+ after 30 days
- Crash-free rate: 99%+
- Launch downloads: 10,000+ in first month
- User reviews: "Best subscription tracker I've used"

**Next Steps:**
1. Review this plan with team
2. Set up project management (GitHub Projects, Jira, etc.)
3. Assign tasks and timelines
4. Begin Phase 1 implementation
5. Schedule weekly progress reviews
6. **Build an amazing app!** =�

---

*Last Updated: [Current Date]*
*Version: 1.0*
*Author: Development Team*