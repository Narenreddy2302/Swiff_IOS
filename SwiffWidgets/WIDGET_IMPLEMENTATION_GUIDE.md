# Swiff Widgets Implementation Guide

## Overview

This guide explains how to set up and integrate the Swiff home screen widgets into the iOS app.

## Table of Contents

1. [Widget Extension Setup](#widget-extension-setup)
2. [App Groups Configuration](#app-groups-configuration)
3. [Widget Files](#widget-files)
4. [Deep Link Integration](#deep-link-integration)
5. [Testing Widgets](#testing-widgets)
6. [Troubleshooting](#troubleshooting)

---

## Widget Extension Setup

### Step 1: Create Widget Extension Target

1. In Xcode, go to **File → New → Target**
2. Select **Widget Extension**
3. Name it **"SwiffWidgets"**
4. Enable **"Include Configuration Intent"** ✅
5. Click **Finish**

### Step 2: Configure Widget Target

1. Select the **SwiffWidgets** target in Xcode
2. Set the following:
   - **Bundle Identifier**: `com.yourcompany.swiff.SwiffWidgets`
   - **Deployment Target**: iOS 16.0 or later (iOS 17.0+ for interactive widgets)
   - **Swift Language Version**: Swift 5.9+

### Step 3: Add Widget Files

Copy all widget files from this directory to the SwiffWidgets target:

```
SwiffWidgets/
├── SwiffWidgets.swift              # Main widget bundle
├── WidgetDataService.swift         # Data service for widgets
├── UpcomingRenewalsWidget.swift    # Renewals widget
├── MonthlySpendingWidget.swift     # Spending analytics widget
├── QuickActionsWidget.swift        # Quick actions widget
├── WidgetAppIntents.swift          # App Intents for iOS 17+
└── Info.plist                      # Widget extension configuration
```

### Step 4: Link Widget Files to Target

1. Select all widget `.swift` files
2. In the **File Inspector** (right panel), ensure **SwiffWidgets** target is checked
3. Also ensure **Swiff IOS** target is unchecked (except for shared models)

---

## App Groups Configuration

### Step 1: Enable App Groups in Main App

1. Select the **Swiff IOS** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** to add a new group
6. Enter: `group.com.yourcompany.swiff`
7. Check the checkbox to enable it

### Step 2: Enable App Groups in Widget Extension

1. Select the **SwiffWidgets** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Select the **same group**: `group.com.yourcompany.swiff`
6. Check the checkbox to enable it

### Step 3: Update App Group Identifier

If you use a different app group identifier, update it in:

**SwiffWidgets/SwiffWidgets.swift**:
```swift
struct WidgetConfiguration {
    static let appGroupIdentifier = "group.com.yourcompany.swiff"
    // ... rest of configuration
}
```

---

## Widget Files

### 1. SwiffWidgets.swift
- Main widget bundle that registers all widgets
- Contains widget configuration constants
- Defines deep link actions
- Provides color scheme and styling

### 2. WidgetDataService.swift
- Manages data sharing between app and widgets using App Groups
- Provides mock data for testing
- Handles widget timeline refresh
- Contains data models (WidgetSubscription, WidgetMonthlySpending)

### 3. UpcomingRenewalsWidget.swift
- Shows upcoming subscription renewals
- **Small Widget (2x2)**: Next renewal with icon, countdown, price
- **Medium Widget (4x2)**: Next 3 renewals in list
- **Large Widget (4x4)**: Next 7 renewals with monthly total
- Refreshes daily at midnight

### 4. MonthlySpendingWidget.swift
- Displays monthly spending analytics
- **Small Widget**: Monthly total with trend indicator
- **Medium Widget**: Total + 6-month chart + top 3 categories
- **Large Widget**: Full 12-month chart + category breakdown
- Refreshes hourly

### 5. QuickActionsWidget.swift
- Provides quick action buttons
- **Medium Widget**: 2x2 grid of 4 action buttons
- **Large Widget**: Expanded list of actions with descriptions
- Actions: Add Transaction, Add Subscription, View Subscriptions, View Analytics

### 6. WidgetAppIntents.swift
- App Intents for iOS 17+ interactive widgets
- Allows buttons to trigger actions without opening app
- Configurable widget options (filter, sort, date range)

---

## Deep Link Integration

### Step 1: Update Info.plist (Main App)

Add URL scheme to the main app's Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>swiff</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.swiff</string>
    </dict>
</array>
```

### Step 2: Add DeepLinkHandler to Main App

The `DeepLinkHandler.swift` file is already created in:
```
Swiff IOS/Utilities/DeepLinkHandler.swift
```

Make sure it's added to the **Swiff IOS** target.

### Step 3: Deep Link URL Scheme

All widget deep links use the format:
```
swiff://action/{action-name}[/{parameter}]
```

**Available Actions:**
- `swiff://action/add-transaction` - Open add transaction sheet
- `swiff://action/add-subscription` - Open add subscription sheet
- `swiff://action/view-subscriptions` - Navigate to subscriptions tab
- `swiff://action/view-analytics` - Navigate to analytics tab
- `swiff://action/view-subscription/{id}` - View specific subscription
- `swiff://action/mark-as-paid/{id}` - Mark subscription as paid

### Step 4: Handle Deep Links in ContentView

Update `ContentView.swift` to respond to deep link state changes:

```swift
@EnvironmentObject var deepLinkHandler: DeepLinkHandler

var body: some View {
    TabView(selection: $deepLinkHandler.selectedTab) {
        // ... tabs
    }
    .sheet(isPresented: $deepLinkHandler.showAddTransaction) {
        AddTransactionSheet()
    }
    .sheet(isPresented: $deepLinkHandler.showAddSubscription) {
        AddSubscriptionSheet()
    }
}
```

---

## Testing Widgets

### Method 1: Widget Gallery (Simulator/Device)

1. Run the app on simulator or device
2. Long press on home screen
3. Tap **+** in top left
4. Search for **"Swiff"**
5. Select widget size
6. Tap **Add Widget**

### Method 2: Widget Previews (Xcode Canvas)

1. Open any widget file (e.g., `UpcomingRenewalsWidget.swift`)
2. Enable Canvas (Editor → Canvas)
3. Click **Resume** to see live preview
4. Test all widget sizes

### Method 3: Deep Link Testing

Test deep links using Safari on simulator/device:

1. Open Safari
2. Enter URL: `swiff://action/add-transaction`
3. Tap **Open** when prompted
4. Verify app opens to correct screen

### Method 4: Interactive Widgets (iOS 17+)

For iOS 17+ interactive buttons:

1. Add widget to home screen
2. Tap action buttons directly
3. Verify actions execute without opening app (where supported)

---

## Widget Data Flow

### From App to Widgets

```swift
// In main app (Swiff_IOSApp.swift)
WidgetDataService.shared.saveUpcomingRenewals(subscriptions)
WidgetDataService.shared.saveMonthlySpending(spending)
WidgetCenter.shared.reloadAllTimelines()
```

### From Widgets to App

```swift
// In widget (any Link or Button)
Link(destination: WidgetDeepLink.addTransaction.url!) {
    // Widget content
}
```

---

## Troubleshooting

### Widget Not Showing Data

**Problem**: Widget shows "No data" or placeholder

**Solutions**:
1. Verify App Groups are enabled in both targets
2. Check App Group identifier is identical in both targets
3. Ensure `WidgetDataService.shared.saveUpcomingRenewals()` is called from main app
4. Manually reload widgets: `WidgetCenter.shared.reloadAllTimelines()`

### Deep Links Not Working

**Problem**: Tapping widget doesn't open app

**Solutions**:
1. Verify URL scheme is registered in Info.plist
2. Check deep link URL format: `swiff://action/{action}`
3. Ensure `DeepLinkHandler` is added as environment object
4. Test URL scheme in Safari first

### Widget Not Refreshing

**Problem**: Widget shows old data

**Solutions**:
1. Check timeline refresh policy in widget provider
2. Verify `WidgetCenter.shared.reloadAllTimelines()` is called
3. For upcoming renewals: Should refresh daily at midnight
4. For monthly spending: Should refresh hourly

### Build Errors

**Problem**: Widget extension won't build

**Solutions**:
1. Ensure all widget files are added to SwiffWidgets target only
2. Check deployment target is iOS 16.0+
3. Verify Swift version is 5.9+
4. Clean build folder (Cmd + Shift + K)

---

## Production Checklist

Before releasing widgets to production:

- [ ] Replace all mock data with real data from DataManager
- [ ] Configure proper App Group with your team identifier
- [ ] Update bundle identifiers with your company domain
- [ ] Test all widget sizes on multiple devices
- [ ] Test light and dark mode
- [ ] Verify deep links work correctly
- [ ] Test widget refresh after app data changes
- [ ] Add analytics tracking for widget usage
- [ ] Test widgets on iPad (if supported)
- [ ] Verify App Store screenshots show widgets
- [ ] Update app description to mention widgets

---

## Widget Refresh Strategy

### Upcoming Renewals Widget
- **Refresh**: Daily at midnight
- **Trigger**: When subscriptions are added/modified/deleted
- **Data**: Next 7 days of renewals

### Monthly Spending Widget
- **Refresh**: Hourly
- **Trigger**: When transactions are added/modified
- **Data**: Current month spending + trends

### Quick Actions Widget
- **Refresh**: Daily (static content)
- **Trigger**: Manual refresh only

---

## Performance Optimization

### Best Practices

1. **Keep widget bundle size small**
   - Use SF Symbols instead of custom images
   - Minimize dependencies
   - Use lightweight data models

2. **Efficient timeline generation**
   - Cache expensive calculations
   - Limit data fetching to what's needed
   - Use background contexts for data operations

3. **Battery-friendly refresh**
   - Don't refresh too frequently
   - Use appropriate timeline policies
   - Only reload changed widgets

4. **Memory management**
   - Release resources after timeline generation
   - Use structs instead of classes where possible
   - Avoid retain cycles in closures

---

## Advanced Features (Future)

### Widget Configuration (iOS 16+)

Allow users to customize widgets:
- Filter subscriptions by category
- Choose date range for spending
- Select sort order

### Widget Animations (iOS 17+)

Add subtle animations:
- Countdown timers for renewals
- Chart transitions
- Progress indicators

### Lock Screen Widgets (iOS 16+)

Create smaller widgets for lock screen:
- Next renewal (circular)
- Monthly total (rectangular)

---

## Support

For questions or issues with widget implementation:

1. Check this guide first
2. Review Apple's WidgetKit documentation
3. Test with mock data in preview
4. Use Xcode debugger with widget extension scheme

---

## Version History

- **v1.0** (2025-11-21): Initial widget implementation
  - Upcoming Renewals Widget (Small, Medium, Large)
  - Monthly Spending Widget (Small, Medium, Large)
  - Quick Actions Widget (Medium, Large)
  - Deep link support
  - iOS 17+ App Intents

---

**Last Updated**: November 21, 2025
**Created By**: Agent 10
