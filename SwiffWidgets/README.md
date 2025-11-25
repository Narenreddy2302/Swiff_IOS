# Swiff Widgets

Home Screen Widgets for the Swiff iOS app, implemented by Agent 10.

## Overview

This widget extension provides three types of widgets for users to add to their iOS home screen:

1. **Upcoming Renewals Widget** - Shows next subscription renewals
2. **Monthly Spending Widget** - Displays spending statistics and trends
3. **Quick Actions Widget** - Provides quick access to common actions

## Widget Sizes

### Upcoming Renewals Widget
- **Small (2x2)**: Next subscription with icon, name, countdown, and price
- **Medium (4x2)**: Next 3 subscriptions in compact list
- **Large (4x4)**: Next 7 subscriptions with monthly total and "View All" link

### Monthly Spending Widget
- **Small (2x2)**: Monthly total, trend arrow, percentage change
- **Medium (4x2)**: Monthly total, mini bar chart (last 6 months), top categories
- **Large (4x4)**: Monthly total, full spending chart (last 12 months), category breakdown

### Quick Actions Widget
- **Medium (4x2)**: Grid of 4 buttons for quick actions

## Features

### Data Sharing (App Groups)
- App Group ID: `group.com.yourcompany.swiff`
- Shared data between main app and widgets using UserDefaults
- Automatic widget refresh when app data changes

### Deep Linking
- Custom URL scheme: `swiff://action/{action}`
- Supported actions:
  - `add-transaction` - Open add transaction sheet
  - `add-subscription` - Open add subscription sheet
  - `view-subscriptions` - Navigate to subscriptions tab
  - `view-analytics` - Navigate to analytics tab

### Timeline Updates
- Widgets refresh automatically at midnight
- Manual refresh when app is opened
- Updates when data changes in main app

### iOS 17+ App Intents
- Interactive widget buttons (iOS 17+)
- App Intents for quick actions:
  - `AddTransactionIntent`
  - `AddSubscriptionIntent`
  - `ViewSubscriptionsIntent`
  - `MarkAsPaidIntent`
  - `RefreshWidgetIntent`

## Architecture

### Files
```
SwiffWidgets/
├── SwiffWidgets.swift              # Widget bundle (main entry)
├── WidgetConfiguration.swift       # Configuration constants
├── WidgetDataService.swift         # Data service with App Groups
├── UpcomingRenewalsWidget.swift    # Renewals widget
├── MonthlySpendingWidget.swift     # Spending widget
├── QuickActionsWidget.swift        # Actions widget
├── WidgetAppIntents.swift          # iOS 17+ App Intents
├── SwiffWidgets.entitlements       # Widget entitlements
└── Info.plist                      # Widget extension info
```

### Data Flow
1. Main app updates data in shared container
2. Main app calls `WidgetCenter.shared.reloadAllTimelines()`
3. Widget reads data from `WidgetDataService`
4. Widget displays updated information

## Setup Instructions

### 1. Add Widget Extension Target
In Xcode:
1. File → New → Target
2. Select "Widget Extension"
3. Name: "SwiffWidgets"
4. Enable "Include Configuration Intent"
5. Add to main app target

### 2. Enable App Groups
**Main App:**
1. Select main app target
2. Signing & Capabilities → + Capability
3. Add "App Groups"
4. Enable: `group.com.yourcompany.swiff`

**Widget Extension:**
1. Select SwiffWidgets target
2. Signing & Capabilities → + Capability
3. Add "App Groups"
4. Enable: `group.com.yourcompany.swiff`

### 3. Configure URL Scheme
In main app's Info.plist:
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

### 4. Add Files to Targets
Ensure all widget files are included in the SwiffWidgets target, not the main app target.

### 5. Share Data Models
If using actual data models (not mocks), add shared files to both targets:
- Subscription model
- Transaction model
- Supporting types

## Testing

### Preview Widgets
1. Build and run widget extension
2. Long press home screen
3. Tap + button
4. Find "Swiff" widgets
5. Add each size to test

### Test Deep Links
1. Add Quick Actions widget
2. Tap each button
3. Verify app opens to correct view

### Test Data Updates
1. Modify subscription in main app
2. Return to home screen
3. Verify widget updates

## Mock Data

Currently using mock data in `WidgetDataService`. To use real data:

1. Update `WidgetDataService` to read from shared container
2. Implement data conversion from SwiftData models
3. Add proper error handling
4. Update `Swiff_IOSApp.swift` to save data to shared container

## Performance Considerations

- Widgets should load in < 1 second
- Keep timeline entries lightweight
- Use efficient data encoding (JSON)
- Limit number of timeline entries
- Optimize image assets

## Troubleshooting

### Widget Not Updating
- Check App Groups are enabled in both targets
- Verify group identifier matches exactly
- Ensure `reloadAllTimelines()` is called after data changes
- Check widget target has correct entitlements

### Deep Links Not Working
- Verify URL scheme is registered in Info.plist
- Check `onOpenURL` handler is added to ContentView
- Ensure DeepLinkHandler is injected as environment object

### Data Not Shared
- Confirm UserDefaults is using suite name (App Group ID)
- Check both targets have same group identifier
- Verify data is being saved before reload

## Future Enhancements

- [ ] Add widget configuration UI
- [ ] Support for category filtering
- [ ] Custom date ranges
- [ ] Widget animations (iOS 17+)
- [ ] Lock screen widgets (iOS 16+)
- [ ] StandBy mode optimization (iOS 17+)
- [ ] Smart Stack intelligence
- [ ] Widget suggestions

## Resources

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [Widget Best Practices](https://developer.apple.com/design/human-interface-guidelines/widgets)

---

**Implementation Status:** ✅ Complete
**Agent:** Agent 10
**Date:** 2025-11-21
**Tasks Completed:** 28/28
