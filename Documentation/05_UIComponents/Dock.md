# Swiff iOS - Comprehensive UI/UX Task List & Documentation

> **Purpose**: Complete task-by-task documentation for implementing professional UI/UX improvements across all screens, focusing on colors, backgrounds, symbols, animations, haptics, and page transitions.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Global Design System](#global-design-system)
3. [Tab Bar / Dock Implementation](#tab-bar--dock-implementation)
4. [Screen-by-Screen Tasks](#screen-by-screen-tasks)
5. [Animation System Tasks](#animation-system-tasks)
6. [Haptic Feedback Tasks](#haptic-feedback-tasks)
7. [Page Transition Tasks](#page-transition-tasks)
8. [Color Consistency Tasks](#color-consistency-tasks)
9. [Symbol & Icon Tasks](#symbol--icon-tasks)
10. [Implementation Priority](#implementation-priority)

---

## Project Overview

**Swiff iOS** is a subscription and expense management application featuring:
- 5 main tabs: Home, Feed, People, Subscriptions, Analytics
- Wise-inspired color palette with full dark mode support
- Spotify-inspired typography system
- Comprehensive animation and haptic feedback systems

**Current Theme Colors**:
- Primary Brand: `wiseForestGreen` (#163300)
- Accent: `wiseBrightGreen` (#9FE870)
- Info/Blue: `wiseBlue` (#00B9FF)
- Warning: `wiseOrange` (#FF9800)
- Error: `wiseError` (#FF453A dark / #FF3B30 light)
- Success: `wiseSuccess` (#30D158 dark / #34C759 light)

---

## Global Design System

### Current Color System Status
| Color Type | Dark Mode | Light Mode | Status |
|------------|-----------|------------|--------|
| Background | #000000 | #FFFFFF |  Implemented |
| Card Background | #262626 | #FFFFFF |  Implemented |
| Primary Text | #FFFFFF | #1A1A1A |  Implemented |
| Secondary Text | #B3B3B3 | #3C3C3C |  Implemented |
| Separator | #38383A | #C6C6C8 |  Implemented |
| Tab Bar Background | #1C1C1E | System |  Implemented |

---

## Tab Bar / Dock Implementation

### Current Implementation (ContentView.swift)
```
Location: Swiff IOS/ContentView.swift (Lines 62-118)
```

### Task List for Tab Bar/Dock

#### TASK D-001: Tab Bar Visual Enhancement
- [x] **Background Color Refinement** ✅ Implemented
  - Current: Solid dark (#1C1C1E in dark mode) - optimal for visibility
  - Uses adaptive colors for dark/light mode
  - File: `ContentView.swift` (init method)

#### TASK D-002: Tab Bar Icon States
- [x] **Unselected State** ✅ Implemented
  - Icon Color: `wiseSecondaryText` with 0.6 opacity
  - Size: 24pt SF Symbol
  - Weight: Regular

- [x] **Selected State** ✅ Implemented
  - Icon Color: `wiseBrightGreen` (consistent brand accent)
  - Size: 24pt SF Symbol (no size change on selection)
  - Weight: Semibold
  - Add subtle glow effect using shadow

#### TASK D-003: Tab Bar Selection Animation
- [x] Add spring animation on tab selection ✅ Implemented via UIKit appearance
  - Animation: `.spring(response: 0.3, dampingFraction: 0.7)`
  - Scale effect: 1.0 → 1.1 → 1.0 on selection
  - Duration: 0.25s

#### TASK D-004: Tab Bar Haptic Feedback
- [x] Implement selection haptic on tab change ✅ Implemented
  - Type: `UISelectionFeedbackGenerator` (via HapticManager.shared.selection())
  - Trigger: On tab selection (not on scroll)
  - File: `.onChange(of: selectedTab)` modifier in ContentView.swift

#### TASK D-005: Tab Bar Icons Update
| Tab | Current Icon | Recommended Icon | Color When Selected | Status |
|-----|--------------|------------------|---------------------|--------|
| Home | `house.fill` | `house.fill` | `wiseBrightGreen` | ✅ |
| Feed | `rectangle.stack.fill` | `rectangle.stack.fill` | `wiseBrightGreen` | ✅ Updated |
| People | `person.2.fill` | `person.2.fill` | `wiseBrightGreen` | ✅ |
| Subscriptions | `creditcard.fill` | `creditcard.fill` | `wiseBrightGreen` | ✅ |
| Analytics | `chart.pie.fill` | `chart.pie.fill` | `wiseBrightGreen` | ✅ Updated |

#### TASK D-006: Tab Bar Label Visibility ✅
- [x] Tab bar style setting added to UserSettings
  - Option A: "labels" (default with labels)
  - Option B: "iconsOnly" (icons only)
  - Option C: "selectedOnly" (labels on selected only)
  - Setting: `UserSettings.shared.tabBarStyle`
- [x] Tab bar style functionality implemented in ContentView
- [x] Settings UI added in AppearanceSettingsSection with visual previews

#### TASK D-007: Floating Dock Style (Optional Premium Feature)
- [ ] Create floating dock variant (deferred - premium feature)
  - Position: 20pt from bottom edge
  - Background: Blur + subtle border
  - Corner Radius: 28pt (pill shape)
  - Shadow: `wiseShadowColor` with 8pt blur

---

## Screen-by-Screen Tasks

### 1. HOME VIEW (Tab 0)

```
Location: Swiff IOS/ContentView.swift (HomeView struct, Line 183+)
```

#### TASK H-001: Home Background ✅
- [x] Background Color: `Color.wiseBackground`
- [x] Ensure safe area coverage with `.ignoresSafeArea()`

#### TASK H-002: Header Section Colors ✅
- [x] Profile Avatar: Use `AvatarView` with adaptive colors
- [x] Logo "Swiff.": `wiseForestGreen` (brand color)
- [x] Add Button: `wiseForestGreen` with `plus.circle.fill`

#### TASK H-003: Today Section Styling ✅
- [x] "Today" Text: `wisePrimaryText` with `spotifyDisplayLarge`
- [x] Date Text: `wiseSecondaryText` with `spotifyBodyLarge`

#### TASK H-004: Financial Cards Grid ✅
- [x] Balance Card Icon: `wiseBrightGreen` (positive indicator)
- [x] Subscriptions Card Icon: `wiseBlue` (info indicator)
- [x] Income Card Icon: `wiseBrightGreen` (positive)
- [x] Expenses Card Icon: `wiseError` (negative/spending)
- [x] Card Background: `wiseCardBackground`
- [x] Trend Arrows: Green (up) / Red (down)

#### TASK H-005: Home View Animations ✅
- [x] Card entry animation with staggered delay
- [x] Number counting animation on financial amounts
- [x] Pull-to-refresh with haptic feedback

#### TASK H-006: Home View Haptics ✅
- [x] Profile button tap: Medium impact
- [x] Add button tap: Medium impact
- [x] Card tap: Light impact
- [x] Pull-to-refresh: Medium impact on threshold

---

### 2. FEED VIEW (Tab 1)

```
Location: Swiff IOS/ContentView.swift (RecentActivityView)
```

#### TASK F-001: Feed Background ✅
- [x] Background: `Color.wiseBackground`
- [x] Ensure consistent with other tabs

#### TASK F-002: Feed Header ✅
- [x] Title: "Feed" with `spotifyDisplayLarge`
- [x] Color: `wisePrimaryText`

#### TASK F-003: Transaction Row Colors ✅
- [x] Income transactions: `wiseBrightGreen` amount
- [x] Expense transactions: `wiseError` amount
- [x] Category icons: Use category-specific colors
- [x] Row background: `wiseCardBackground`

#### TASK F-004: Feed List Animations ✅
- [x] List item animations with scale effect
- [x] List item deletion: Slide with fade
- [x] Tap animations with spring return

#### TASK F-005: Feed Haptics ✅
- [x] Swipe action haptic: Light impact
- [x] Delete action haptic: Heavy impact (destructive)
- [x] Refresh haptic: Medium impact

#### TASK F-006: Empty State ✅
- [x] Icon: `rectangle.stack` with 0.5 opacity
- [x] Text: `wiseSecondaryText`
- [x] Background: `wiseCardBackground`

---

### 3. PEOPLE VIEW (Tab 2)

```
Location: Swiff IOS/Views/ (PeopleView)
```

#### TASK P-001: People Background ✅
- [x] Background: `Color.wiseBackground`
- [x] Navigation bar: Blend with background

#### TASK P-002: People Header ✅
- [x] Title: "People" with `spotifyDisplayLarge`
- [x] Add Person Button: `wiseForestGreen`

#### TASK P-003: Person Card Colors ✅
- [x] Avatar: Dynamic colors based on person name hash
- [x] Name: `wisePrimaryText`
- [x] Balance positive: `wiseBrightGreen`
- [x] Balance negative: `wiseError`
- [x] Balance zero: `wiseForestGreen`
- [x] Card background: `wiseCardBackground`

#### TASK P-004: Person Card Symbols ✅
- [x] Owed to you indicator shown with green color
- [x] You owe indicator shown with red color
- [x] Settled indicator with appropriate styling

#### TASK P-005: People Animations ✅
- [x] Card tap: Scale animations
- [x] List entry: Cascade animation
- [x] Avatar appear: Proper sizing

#### TASK P-006: People Haptics ✅
- [x] Card tap: Light impact
- [x] Add person: Medium impact
- [x] Delete person: Heavy impact
- [x] Balance update: Success notification

---

### 4. SUBSCRIPTIONS VIEW (Tab 3)

```
Location: Swiff IOS/Views/ (SubscriptionsView)
```

#### TASK S-001: Subscriptions Background ✅
- [x] Background: `Color.wiseBackground`
- [x] Consistent safe area handling

#### TASK S-002: Subscriptions Header ✅
- [x] Title: "Subscriptions" with `spotifyDisplayLarge`
- [x] Total monthly cost: `wiseSecondaryText`
- [x] Add Subscription: `wiseForestGreen`

#### TASK S-003: Subscription Card Colors ✅
- [x] Active subscription icon: Category color
- [x] Paused subscription: `wiseOrange` badge
- [x] Cancelled subscription: `wiseError` badge
- [x] Trial subscription: `wisePurple` badge
- [x] Price text: `wisePrimaryText`
- [x] Next billing: `wiseSecondaryText`
- [x] Card background: `wiseCardBackground`

#### TASK S-004: Subscription Status Badges ✅
| Status | Background Color | Text Color | Icon | Status |
|--------|-----------------|------------|------|--------|
| Active | `wiseBrightGreen.opacity(0.15)` | `wiseBrightGreen` | `checkmark.circle.fill` | ✅ |
| Paused | `wiseOrange.opacity(0.15)` | `wiseOrange` | `pause.circle.fill` | ✅ |
| Cancelled | `wiseError.opacity(0.15)` | `wiseError` | `xmark.circle.fill` | ✅ |
| Trial | `wisePurple.opacity(0.15)` | `wisePurple` | `clock.fill` | ✅ |
| Expiring Soon | `wiseWarning.opacity(0.15)` | `wiseWarning` | `exclamationmark.triangle.fill` | ✅ |

#### TASK S-005: Subscription List Animations ✅
- [x] Card entry: Fade + slide animations
- [x] Status change: Color transitions
- [x] View mode switch: Smooth animations

#### TASK S-006: Subscription Haptics ✅
- [x] Card tap: Light impact
- [x] Add subscription: Medium impact
- [x] Delete subscription: Heavy impact (destructive)
- [x] Refresh: Medium impact

---

### 5. ANALYTICS VIEW (Tab 4)

```
Location: Swiff IOS/Views/AnalyticsView.swift
```

#### TASK A-001: Analytics Background ✅
- [x] Background: `Color.wiseBackground`

#### TASK A-002: Analytics Header ✅
- [x] Title: "Analytics." with `spotifyDisplayLarge`
- [x] Date picker button: `wiseCardBackground` with `wisePrimaryText`
- [x] Chevron: `wiseSecondaryText`

#### TASK A-003: Circular Progress Ring Colors ✅
- [x] Ring segments: Use category-specific colors
- [x] Background ring: `wiseSeparator.opacity(0.3)`
- [x] Ring thickness: 16pt

#### TASK A-004: Amount Display ✅
- [x] Dollar sign: `wisePrimaryText`
- [x] Integer part: `wisePrimaryText` (large)
- [x] Decimal part: `wiseSecondaryText`
- [x] Period label: `wiseSecondaryText`

#### TASK A-005: Income/Expense Tab Switcher ✅
- [x] Selected tab: `wiseForestGreen` background, white text
- [x] Unselected tab: Clear background, `wiseBodyText`
- [x] Container: `wiseBorder.opacity(0.5)`

#### TASK A-006: Category Row Colors ✅
- [x] Icon background: Category color with 0.15 opacity
- [x] Icon: Category color
- [x] Category name: `wisePrimaryText`
- [x] Percentage badge: Category color background, white text
- [x] Row background: `wiseCardBackground`

#### TASK A-007: Analytics Animations ✅
- [x] Ring segments: Animate from 0 with spring (1.0s response)
- [x] Amount: Scale + fade entrance
- [x] Category rows: Cascade with 0.08s delays
- [x] Tab switch: Reset and replay all animations

#### TASK A-008: Analytics Haptics
- [x] Tab switch: Selection feedback ✅ Implemented
- [x] Date range change: Light impact ✅ Implemented
- [x] Pull-to-refresh: Medium impact ✅ Implemented

---

## Animation System Tasks

### Global Animation Presets

```
Location: Swiff IOS/Utilities/AnimationPresets.swift
```

#### TASK AN-001: Review Animation Consistency ✅
- [x] All views use centralized presets in AnimationPresets.swift
- [x] Standard spring: `response: 0.3, dampingFraction: 0.7` (Animation.smooth)
- [x] Bouncy spring: `response: 0.4, dampingFraction: 0.6` (Animation.bouncy)
- [x] Snappy spring: `response: 0.25, dampingFraction: 0.8` (Animation.snappy)

#### TASK AN-002: Card Entry Animations ✅
- [x] Scale animations implemented
- [x] Opacity transitions implemented
- [x] Animation.cardAppear preset available

#### TASK AN-003: List Item Animations ✅
- [x] Insert: Slide from trailing edge + fade (AnyTransition.slideAndFade)
- [x] Remove: Slide to leading edge + fade
- [x] Push transition available for navigation

#### TASK AN-004: Number Animations ✅
- [x] Number counting animations implemented in FinancialOverviewGrid
- [x] Animated with easeOut duration
- [x] Respects system settings

#### TASK AN-005: Loading State Animations ✅
- [x] ShimmerEffect modifier available
- [x] SpinnerView with 1s rotation cycle
- [x] PulseModifier for scale animations
- [x] LoadingDotsView for loading states

#### TASK AN-006: Reduce Motion Support ✅
- [x] Animation presets respect system preferences
- [x] Fallback animations available
- [x] No motion-triggered state changes

---

## Haptic Feedback Tasks

### Global Haptic System

```
Location: Swiff IOS/Utilities/HapticManager.swift
```

#### TASK HP-001: Haptic Mapping Review ✅
| Action | Haptic Type | Intensity | Status |
|--------|-------------|-----------|--------|
| Button tap | Light impact | Standard | ✅ |
| Card tap | Light impact | Standard | ✅ |
| Tab change | Selection | Standard | ✅ |
| Add item | Medium impact | Standard | ✅ |
| Delete item | Heavy impact | Standard | ✅ |
| Success | Success notification | Standard | ✅ |
| Error | Error notification | Standard | ✅ |
| Warning | Warning notification | Standard | ✅ |
| Pull-to-refresh | Medium impact | On threshold | ✅ |
| Swipe action | Soft impact | Standard | ✅ |
| Long press | Medium impact | Standard | ✅ |

#### TASK HP-002: Tab Bar Haptics
- [x] Add `.onChange(of: selectedTab)` with selection haptic ✅ Implemented
- [x] File: `ContentView.swift` ✅ Done

#### TASK HP-003: Card Interaction Haptics ✅
- [x] Tap: Light impact
- [x] Long press: Medium impact
- [x] Swipe: Soft impact

#### TASK HP-004: Destructive Action Haptics ✅
- [x] Delete button tap: Heavy impact
- [x] Confirm delete: Error notification
- [x] Cancel subscription: Heavy impact

#### TASK HP-005: Success State Haptics ✅
- [x] Save successful: Success notification
- [x] Payment recorded: Success notification
- [x] Subscription added: Success notification

---

## Page Transition Tasks

### Navigation Transitions

#### TASK PT-001: Tab Switch Transitions ✅
- [x] Tab switching with proper animations
- [x] Smooth transitions between tabs
- [x] Haptic feedback on tab change

#### TASK PT-002: Sheet Presentation ✅
- [x] Use `.sheet(isPresented:)` with spring animation
- [x] Entry: Slide up with system animation
- [x] Exit: Slide down
- [x] Background: Dimmed overlay

#### TASK PT-003: Navigation Push/Pop ✅
- [x] Standard iOS push animation (system default)
- [x] Navigation bar color matches background

#### TASK PT-004: Detail View Transitions ✅
- [x] Card to detail navigation
- [x] Scale animations on card tap
- [x] Smooth transitions

#### TASK PT-005: Onboarding Flow Transitions ✅
- [x] Welcome → Features: Slide right with fade
- [x] Features → Setup: Slide right with fade
- [x] Respect reduce motion

---

## Color Consistency Tasks

### Cross-Screen Color Audit

#### TASK CC-001: Background Consistency ✅
- [x] All main views: `Color.wiseBackground`
- [x] All cards: `Color.wiseCardBackground`
- [x] All modals: `Color.wiseElevatedBackground`

#### TASK CC-002: Text Color Consistency ✅
- [x] Primary headings: `wisePrimaryText`
- [x] Body text: `wiseBodyText`
- [x] Secondary/captions: `wiseSecondaryText`
- [x] Tertiary/hints: `wiseTertiaryText`
- [x] Links: `wiseLinkText`
- [x] Placeholders: `wisePlaceholderText`

#### TASK CC-003: Status Color Consistency ✅
- [x] Positive amounts/success: `wiseBrightGreen`
- [x] Negative amounts/error: `wiseError`
- [x] Warnings/attention: `wiseWarning`
- [x] Info/neutral: `wiseBlue`
- [x] Premium/special: `wisePurple`

#### TASK CC-004: Interactive Element Colors ✅
- [x] Primary buttons: `wiseForestGreen` / `wiseBrightGreen`
- [x] Secondary buttons: `wiseSecondaryButton`
- [x] Destructive buttons: `wiseDestructiveButton`
- [x] Disabled buttons: `wiseDisabledButton`

#### TASK CC-005: Border & Divider Colors ✅
- [x] Card borders: `wiseBorder`
- [x] Input borders: `wiseSecondaryBorder`
- [x] Dividers: `wiseSeparator`
- [x] Focus state: `wiseFocusBorder`

---

## Symbol & Icon Tasks

### SF Symbol Audit

#### TASK SI-001: Tab Bar Icons ✅
| Tab | Icon | Weight | Size | Status |
|-----|------|--------|------|--------|
| Home | `house.fill` | Regular | 24pt | ✅ |
| Feed | `rectangle.stack.fill` | Regular | 24pt | ✅ |
| People | `person.2.fill` | Regular | 24pt | ✅ |
| Subscriptions | `creditcard.fill` | Regular | 24pt | ✅ |
| Analytics | `chart.pie.fill` | Regular | 24pt | ✅ |

#### TASK SI-002: Action Icons ✅
| Action | Icon | Color | Status |
|--------|------|-------|--------|
| Add | `plus.circle.fill` | `wiseForestGreen` | ✅ |
| Edit | `pencil` | `wisePrimaryText` | ✅ |
| Delete | `trash` | `wiseError` | ✅ |
| Settings | `gear` | `wisePrimaryText` | ✅ |
| Search | `magnifyingglass` | `wisePrimaryText` | ✅ |
| Filter | `line.3.horizontal.decrease.circle` | `wisePrimaryText` | ✅ |
| Share | `square.and.arrow.up` | `wisePrimaryText` | ✅ |
| Close | `xmark` | `wisePrimaryText` | ✅ |

#### TASK SI-003: Status Icons ✅
| Status | Icon | Color | Status |
|--------|------|-------|--------|
| Active | `checkmark.circle.fill` | `wiseBrightGreen` | ✅ |
| Paused | `pause.circle.fill` | `wiseOrange` | ✅ |
| Cancelled | `xmark.circle.fill` | `wiseError` | ✅ |
| Warning | `exclamationmark.triangle.fill` | `wiseWarning` | ✅ |
| Info | `info.circle.fill` | `wiseBlue` | ✅ |
| Trial | `clock.fill` | `wisePurple` | ✅ |

#### TASK SI-004: Category Icons ✅
All subscription categories updated in SupportingTypes.swift:
- Entertainment: `tv.fill` ✅
- Productivity: `hammer.fill` ✅
- Fitness & Health: `heart.fill` ✅
- Education: `book.fill` ✅
- News & Media: `newspaper.fill` ✅
- Music & Audio: `music.note` ✅
- Cloud Storage: `cloud.fill` ✅
- Gaming: `gamecontroller.fill` ✅
- Design & Creative: `paintbrush.fill` ✅
- Development: `chevron.left.forwardslash.chevron.right` ✅
- Finance: `banknote.fill` ✅
- Utilities: `wrench.fill` ✅
- Food & Dining: `fork.knife` ✅
- Shopping: `bag.fill` ✅
- Travel: `airplane` ✅
- Other: `ellipsis.circle.fill` ✅

#### TASK SI-005: Navigation Icons ✅
| Navigation | Icon | Status |
|------------|------|--------|
| Back | `chevron.left` | ✅ |
| Forward | `chevron.right` | ✅ |
| Up | `chevron.up` | ✅ |
| Down | `chevron.down` | ✅ |
| More | `ellipsis` | ✅ |
| Expand | `chevron.up.chevron.down` | ✅ |

---

## Implementation Priority

### Phase 1: Critical (High Impact, Foundation)
1. **TASK D-002**: Tab Bar Icon States
2. **TASK D-004**: Tab Bar Haptic Feedback
3. **TASK CC-001**: Background Consistency
4. **TASK CC-002**: Text Color Consistency

### Phase 2: Important (User Experience)
5. **TASK D-003**: Tab Bar Selection Animation
6. **TASK AN-001**: Animation Consistency Review
7. **TASK HP-001**: Haptic Mapping Review
8. **TASK PT-002**: Sheet Presentation

### Phase 3: Enhancement (Polish)
9. **TASK D-001**: Tab Bar Visual Enhancement
10. **TASK SI-001-005**: Symbol Audit Tasks
11. **TASK CC-003-005**: Color Consistency Tasks
12. **TASK PT-004**: Detail View Transitions

### Phase 4: Optional (Premium Features)
13. **TASK D-007**: Floating Dock Style
14. **TASK D-006**: Tab Bar Label Visibility Options

---

## Files to Modify

### Primary Files
| File | Tasks |
|------|-------|
| `ContentView.swift` | D-001 to D-006, H-001 to H-006 |
| `AnalyticsView.swift` | A-001 to A-008 |
| `HapticManager.swift` | HP-001 to HP-005 |
| `AnimationPresets.swift` | AN-001 to AN-006 |
| `SupportingTypes.swift` | CC-001 to CC-005 |

### Secondary Files
| File | Tasks |
|------|-------|
| `PeopleView.swift` | P-001 to P-006 |
| `SubscriptionsView.swift` | S-001 to S-006 |
| `RecentActivityView.swift` | F-001 to F-006 |
| All Detail Views | PT-004 |
| All Sheet Views | PT-002 |

---

## Testing Checklist

### Visual Testing
- [ ] Test all screens in Light Mode
- [ ] Test all screens in Dark Mode
- [ ] Test with Dynamic Type (all sizes)
- [ ] Test with High Contrast mode
- [ ] Test with Reduce Transparency

### Animation Testing
- [ ] Test with Reduce Motion enabled
- [ ] Verify 60fps performance on all animations
- [ ] Test animation interruption handling

### Haptic Testing
- [ ] Verify haptics on physical device
- [ ] Test haptic intensity levels
- [ ] Ensure no excessive haptic feedback

### Accessibility Testing
- [ ] VoiceOver navigation
- [ ] Color contrast ratios (WCAG AA minimum)
- [ ] Touch target sizes (44x44pt minimum)

---

## Notes

### Design Philosophy
- **Consistency**: Same interaction = same feedback
- **Subtlety**: Haptics and animations should enhance, not distract
- **Performance**: 60fps minimum, no jank
- **Accessibility**: Respect user preferences always

### Color Usage Guidelines
- Green (`wiseBrightGreen`): Positive, income, success, active
- Red (`wiseError`): Negative, expenses, errors, destructive
- Blue (`wiseBlue`): Info, neutral, subscriptions
- Orange (`wiseOrange`): Warnings, paused states
- Purple (`wisePurple`): Premium, trials, special features

---

*Document Version: 1.0*
*Last Updated: 2025-11-27*
*Author: Claude Code Assistant*
