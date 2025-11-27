# Profile Page Testing Checklist
## Swiff iOS App - Phase 7 Testing (Tasks 18-21)

**Version:** 1.0
**Created:** 2025-11-24
**Status:** Ready for QA
**Test Type:** Manual Testing Checklist

---

## Table of Contents
1. [Testing Overview](#testing-overview)
2. [Task 18: Unit Testing (6 Tests)](#task-18-unit-testing-6-tests)
3. [Task 19: UI Testing (7 Tests)](#task-19-ui-testing-7-tests)
4. [Task 20: Edge Case Testing (8 Tests)](#task-20-edge-case-testing-8-tests)
5. [Task 21: Visual QA (8 Tests)](#task-21-visual-qa-8-tests)
6. [Summary & Sign-off](#summary--sign-off)

---

## Testing Overview

### Purpose
This document provides a comprehensive testing checklist for the Profile Page implementation. Since we cannot run automated tests in the current environment, this serves as a manual QA guide for testing all 29 test scenarios across Phase 7 tasks.

### Test Environment Requirements
- **Devices:** iPhone SE, iPhone 15, iPhone 15 Pro Max, iPad (optional)
- **iOS Versions:** iOS 17.0+
- **Network:** Online and offline modes
- **Accessibility:** VoiceOver, Dynamic Type, Reduce Motion
- **Display Modes:** Light mode, Dark mode, System mode

### Files Under Test
- `/Swiff IOS/Views/ProfileView.swift`
- `/Swiff IOS/Views/Components/ProfileHeaderView.swift`
- `/Swiff IOS/Views/Components/ProfileStatisticsGrid.swift`
- `/Swiff IOS/Views/Components/QuickActionRow.swift`
- `/Swiff IOS/Views/Sheets/UserProfileEditView.swift`
- `/Swiff IOS/Models/DataModels/UserProfile.swift`
- `/Swiff IOS/ContentView.swift` (integration)

### How to Use This Checklist
1. Execute each test in order
2. Mark PASS or FAIL for each test
3. Document any issues found
4. Take screenshots for visual tests
5. Record device/OS version for failures
6. Complete the summary section at the end

---

## Task 18: Unit Testing (6 Tests)

### Test 18.1: Statistics Calculations

**Objective:** Verify that all statistics are calculated correctly with various data sets.

#### Test 18.1.1: Total Subscriptions Count
- [ ] **Test Case:** Verify `totalSubscriptions` counts only active subscriptions
- **Setup:** Create mix of active and inactive subscriptions
- **Expected:** Only `isActive = true` subscriptions counted
- **Test Data:**
  - 0 subscriptions → Count: 0
  - 1 active subscription → Count: 1
  - 5 active, 3 inactive → Count: 5
  - 10 subscriptions all active → Count: 10
  - 1000+ subscriptions → Count: formatted with comma (e.g., "1,234")

**Test Steps:**
1. Open app with no subscriptions
2. Verify ProfileView shows "0" subscriptions
3. Add 1 active subscription
4. Open ProfileView, verify count = 1
5. Add 5 more active subscriptions
6. Add 3 inactive subscriptions (toggle isActive = false)
7. Open ProfileView, verify count = 6 (not 9)
8. Create test with 1234 subscriptions
9. Verify display shows "1,234" with comma separator

**Pass Criteria:**
- [ ] Zero subscriptions displays "0"
- [ ] Single subscription displays "1"
- [ ] Only active subscriptions counted
- [ ] Large numbers formatted with commas
- [ ] No crashes with 0, 1, 10, or 1000+ items

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.1.2: Monthly Spending Calculation
- [ ] **Test Case:** Verify `monthlySpending` sums `monthlyEquivalent` correctly
- **Expected:** Sum of all active subscriptions' monthly equivalents
- **Test Data:**
  - 0 subscriptions → $0
  - Netflix $15.99/month → $15.99
  - Netflix $15.99 + Spotify $9.99 → $25.98
  - Mix of monthly/yearly (yearly divided by 12)
  - Edge: $0.99 subscription
  - Edge: $999.99 subscription

**Test Steps:**
1. Open app with no subscriptions
2. Verify monthly spending = "$0"
3. Add Netflix at $15.99/month
4. Verify display = "$16" (no decimals)
5. Add Spotify at $9.99/month
6. Verify display = "$26" (sum rounded)
7. Add yearly subscription $119.88/year
8. Verify adds $9.99/month to total
9. Test with very small ($0.99) and large ($999.99) amounts
10. Verify no calculation errors

**Pass Criteria:**
- [ ] Zero spending displays "$0"
- [ ] Single subscription displays correctly
- [ ] Multiple subscriptions sum correctly
- [ ] Yearly subscriptions divided by 12
- [ ] No decimal places shown
- [ ] Large amounts (>$1000) display with comma: "$1,234"
- [ ] Currency symbol always present

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.1.3: Total People Count
- [ ] **Test Case:** Verify `totalPeople` counts all people correctly
- **Expected:** `dataManager.people.count`
- **Test Data:**
  - 0 people → 0
  - 1 person → 1
  - 10 people → 10
  - 1000+ people → formatted

**Test Steps:**
1. Fresh app with no people
2. Verify count = 0
3. Add 1 person
4. Verify count = 1
5. Add 10 more people
6. Verify count = 11
7. Test with 1234 people
8. Verify display = "1,234"

**Pass Criteria:**
- [ ] Accurate count at all data sizes
- [ ] Comma formatting for 1000+
- [ ] No performance issues with large counts

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.1.4: Total Groups Count
- [ ] **Test Case:** Verify `totalGroups` counts all groups correctly
- **Expected:** `dataManager.groups.count`
- **Test Data:** Same as people test

**Test Steps:**
1. Fresh app with no groups
2. Verify count = 0
3. Add 1 group
4. Verify count = 1
5. Add 10 more groups
6. Verify count = 11
7. Test with 1234 groups
8. Verify display = "1,234"

**Pass Criteria:**
- [ ] Accurate count at all data sizes
- [ ] Comma formatting for 1000+
- [ ] No performance issues

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 18.2: Date Formatting

**Objective:** Verify "Member since" date displays correctly in all locales.

#### Test 18.2.1: Date Format Validation
- [ ] **Test Case:** Verify date formatting follows expected pattern
- **Expected:** "Member since [Month Day, Year]" format

**Test Steps:**
1. Set device to US locale (Settings > General > Language & Region)
2. Create profile with date: January 1, 2024
3. Open ProfileView
4. Verify displays: "Member since Jan 1, 2024"
5. Create profile with today's date
6. Verify displays correctly
7. Create profile with date 1 year ago
8. Verify displays correctly
9. Create profile with date 10 years ago
10. Verify displays correctly

**Pass Criteria:**
- [ ] Format: "Member since [Month Day, Year]"
- [ ] Month abbreviated (Jan, Feb, etc.)
- [ ] Day without leading zero (1, not 01)
- [ ] Full 4-digit year
- [ ] All dates display without errors

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.2.2: Locale Handling
- [ ] **Test Case:** Verify date adapts to device locale
- **Expected:** Date format follows locale settings

**Test Steps:**
1. Test with US locale (English)
   - Expected: "Member since Jan 1, 2024"
2. Change to UK locale (Settings > Language > British English)
   - Expected: "Member since 1 Jan 2024"
3. Change to German locale
   - Expected: Date in German format
4. Verify no crashes with locale changes

**Pass Criteria:**
- [ ] Date respects device locale
- [ ] No hardcoded date formats
- [ ] All locales display correctly
- [ ] No crashes on locale change

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 18.3: Currency Formatting

**Objective:** Verify currency amounts display correctly with proper formatting.

#### Test 18.3.1: Currency Display Validation
- [ ] **Test Case:** Verify currency formatting for various amounts
- **Expected:** USD symbol, no decimals, comma for thousands

**Test Data & Expected Results:**
| Amount | Expected Display |
|--------|------------------|
| $0 | $0 |
| $1 | $1 |
| $10 | $10 |
| $99 | $99 |
| $999 | $999 |
| $1,000 | $1,000 |
| $1,234 | $1,234 |
| $10,000 | $10,000 |
| $99,999 | $99,999 |
| $100,000 | $100,000 |
| $999,999 | $999,999 |

**Test Steps:**
1. For each amount in test data:
   - Create subscriptions totaling that amount
   - Open ProfileView
   - Verify display matches expected
2. Verify USD symbol always present
3. Verify no decimal places
4. Verify comma thousands separator
5. Verify no scientific notation for large numbers

**Pass Criteria:**
- [ ] USD symbol ($) always displayed
- [ ] Zero decimals for all amounts
- [ ] Comma separator for amounts ≥ $1,000
- [ ] No overflow or truncation
- [ ] Consistent formatting across all amounts

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 18.4: Empty States

**Objective:** Verify UI handles empty/missing data gracefully.

#### Test 18.4.1: Empty Profile Data
- [ ] **Test Case:** Profile with no name/email/phone
- **Expected:** Fallback text and hidden fields

**Test Steps:**
1. Reset profile to default (empty)
2. Open ProfileView
3. Verify name shows "Add Your Name"
4. Verify email field is hidden (not blank)
5. Verify phone field is hidden (not blank)
6. Verify no empty spaces where fields should be
7. Verify "Member since" still shows (with created date)
8. Verify Edit Profile button still works

**Pass Criteria:**
- [ ] "Add Your Name" displays for empty name
- [ ] Empty email doesn't show (field hidden)
- [ ] Empty phone doesn't show (field hidden)
- [ ] No visual gaps or weird spacing
- [ ] Date still displays
- [ ] Edit button accessible

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.4.2: Zero Statistics
- [ ] **Test Case:** All counts at zero
- **Expected:** Display "0" for all statistics

**Test Steps:**
1. Fresh app install (no data)
2. Open ProfileView
3. Verify Subscriptions shows "0"
4. Verify Monthly Spending shows "$0"
5. Verify People shows "0"
6. Verify Groups shows "0"
7. Tap each card - verify no crashes
8. Verify cards still look correct with zeros

**Pass Criteria:**
- [ ] All statistics display "0" not blank
- [ ] Spending shows "$0" not "$" or "0"
- [ ] No division by zero errors
- [ ] Cards maintain proper layout
- [ ] Tapping cards doesn't crash
- [ ] Icons and colors still display

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 18.5: Large Numbers

**Objective:** Verify UI handles large numbers without breaking.

#### Test 18.5.1: Large Subscription Count
- [ ] **Test Case:** 1000+ subscriptions
- **Expected:** Number formatted with commas, no UI overflow

**Test Steps:**
1. Create 1,234 subscriptions in test data
2. Open ProfileView
3. Verify displays "1,234" with comma
4. Verify card doesn't overflow or clip
5. Verify card maintains proper size
6. Test with 10,000 subscriptions
7. Verify displays "10,000"
8. Test with 999,999 subscriptions
9. Verify displays correctly
10. Verify no performance degradation

**Pass Criteria:**
- [ ] Comma separators for thousands
- [ ] No text clipping or overflow
- [ ] Card maintains layout
- [ ] Font size remains readable
- [ ] No performance issues
- [ ] Tapping still works

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.5.2: Large Spending Amount
- [ ] **Test Case:** $100,000+ monthly spending
- **Expected:** Currency formatted with commas

**Test Steps:**
1. Create subscriptions totaling $125,432/month
2. Open ProfileView
3. Verify displays "$125,432" with commas
4. Verify card layout maintained
5. Test with $999,999
6. Verify displays correctly
7. Verify no overflow

**Pass Criteria:**
- [ ] Commas for thousands
- [ ] $ symbol present
- [ ] No decimals
- [ ] No overflow
- [ ] Readable font size

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 18.6: Very Long Names

**Objective:** Verify UI handles long text strings properly.

#### Test 18.6.1: Long Profile Name
- [ ] **Test Case:** Name with 50+ characters
- **Expected:** Truncation or wrapping, no overflow

**Test Data:**
- Short: "John Doe"
- Medium: "Christopher Alexander Washington"
- Long: "Jean-Baptiste Pierre Antoine de Monet, Chevalier de Lamarck"
- Very Long: "Wolfeschlegelsteinhausenbergerdorff-Weltkriege" (50+ chars)

**Test Steps:**
1. Set profile name to "John Doe"
2. Verify displays fully
3. Set name to 30-character name
4. Verify displays without truncation
5. Set name to 50-character name
6. Open ProfileView
7. Check if name:
   - Wraps to multiple lines, OR
   - Truncates with ellipsis (...), OR
   - Scales font size down
8. Verify no horizontal overflow
9. Verify avatar still visible
10. Verify Edit button still accessible

**Pass Criteria:**
- [ ] Short names display fully
- [ ] Long names don't overflow screen
- [ ] Text either wraps or truncates gracefully
- [ ] Avatar not obscured
- [ ] Edit button accessible
- [ ] Layout remains functional
- [ ] Readable at all lengths

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 18.6.2: Long Email Address
- [ ] **Test Case:** Email with 50+ characters
- **Expected:** Truncation or wrapping

**Test Data:**
- Short: "test@example.com"
- Long: "firstname.lastname.with.many.dots@very-long-company-domain-name.com"

**Test Steps:**
1. Set short email
2. Verify displays fully
3. Set very long email (50+ chars)
4. Open ProfileView
5. Verify email displays appropriately:
   - Wraps to multiple lines, OR
   - Truncates with ellipsis
6. Verify no horizontal overflow
7. Verify still readable

**Pass Criteria:**
- [ ] Short emails display fully
- [ ] Long emails don't overflow
- [ ] Truncation/wrapping is graceful
- [ ] Still readable
- [ ] Layout maintained

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

## Task 19: UI Testing (7 Tests)

### Test 19.1: Profile View Opens

**Objective:** Verify ProfileView opens correctly from ContentView.

#### Test 19.1.1: Sheet Presentation
- [ ] **Test Case:** Profile button opens ProfileView
- **Expected:** Sheet presents with animation

**Test Steps:**
1. Launch app to home screen
2. Locate profile avatar button (top-left corner)
3. Verify avatar displays (not generic icon)
4. Tap profile avatar button
5. Observe sheet presentation
6. Verify ProfileView appears
7. Verify animation is smooth (spring animation)
8. Verify no lag or stutter
9. Verify no crashes

**Pass Criteria:**
- [ ] Avatar button visible on home screen
- [ ] Tapping avatar opens ProfileView
- [ ] Sheet presents from bottom with animation
- [ ] Animation is smooth (spring effect)
- [ ] No delay > 100ms
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 19.2: Avatar Displays

**Objective:** Verify AvatarView displays correct avatar type.

#### Test 19.2.1: Avatar Type Display
- [ ] **Test Case:** All avatar types display correctly
- **Expected:** Photo, emoji, and initials all render properly

**Test Steps:**
1. **Test Initials Avatar:**
   - Set profile name to "John Doe"
   - Set avatar type to initials
   - Open ProfileView
   - Verify displays "JD" on colored background
   - Verify circle shape
   - Verify proper size (80x80pt in header)

2. **Test Emoji Avatar:**
   - Edit profile
   - Select emoji avatar
   - Choose emoji (e.g., 😀)
   - Save
   - Verify ProfileView shows emoji
   - Verify emoji is centered and sized properly

3. **Test Photo Avatar:**
   - Edit profile
   - Select photo from library
   - Grant photo permissions if needed
   - Save
   - Verify ProfileView shows photo
   - Verify photo is circular
   - Verify photo fills circle (no white space)

**Pass Criteria:**
- [ ] Initials display correctly
- [ ] Emoji displays correctly
- [ ] Photo displays correctly
- [ ] All avatars are circular
- [ ] Proper size in ProfileView (80x80pt)
- [ ] No distortion or stretching

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.2.2: Avatar Size Consistency
- [ ] **Test Case:** Avatar sizes correct in all locations
- **Expected:** Different sizes in different contexts

**Test Steps:**
1. Open ProfileView
2. Measure/verify avatar in header = 80x80pt (xxlarge)
3. Close ProfileView
4. Verify avatar in ContentView = 44x44pt tap target
5. Open Edit Profile
6. Verify avatar in edit view = 80x80pt
7. Check all avatars maintain circular shape
8. Verify no pixelation or quality loss

**Pass Criteria:**
- [ ] ProfileView header: 80x80pt (xxlarge)
- [ ] ContentView button: 44x44pt minimum tap area
- [ ] Edit view: 80x80pt
- [ ] All avatars circular
- [ ] No quality loss at any size

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 19.3: Statistics Accuracy

**Objective:** Verify statistics match actual data from DataManager.

#### Test 19.3.1: Statistics Match Real Data
- [ ] **Test Case:** Numbers in ProfileView match actual counts
- **Expected:** 100% accurate data display

**Test Steps:**
1. Before opening ProfileView, count actual data:
   - Count active subscriptions manually
   - Calculate total monthly spending
   - Count total people
   - Count total groups
   - Write down expected values

2. Open ProfileView
3. Compare displayed values to expected:
   - Subscriptions count matches
   - Monthly spending matches
   - People count matches
   - Groups count matches

4. Add new subscription
5. Close and reopen ProfileView
6. Verify count increased by 1
7. Verify spending increased by subscription amount

8. Delete a subscription
9. Close and reopen ProfileView
10. Verify count decreased by 1

**Pass Criteria:**
- [ ] Subscriptions count 100% accurate
- [ ] Monthly spending 100% accurate
- [ ] People count 100% accurate
- [ ] Groups count 100% accurate
- [ ] Statistics update when data changes
- [ ] No stale/cached data shown

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.3.2: Statistics Tap Actions
- [ ] **Test Case:** Tapping statistics cards doesn't crash
- **Expected:** Currently logs to console (navigation TBD)

**Test Steps:**
1. Open ProfileView
2. Tap Subscriptions card
3. Verify no crash (currently just logs)
4. Tap Monthly Spending card
5. Verify no crash
6. Tap People card
7. Verify no crash
8. Tap Groups card
9. Verify no crash
10. Verify haptic feedback on each tap

**Pass Criteria:**
- [ ] No crashes on any card tap
- [ ] Haptic feedback fires (light impact)
- [ ] Visual feedback (scale animation)
- [ ] Console logs show tap detected

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 19.4: Navigation Flows

**Objective:** Verify all 5 quick action buttons work correctly.

#### Test 19.4.1: Edit Profile Navigation
- [ ] **Test Case:** Edit Profile button opens UserProfileEditView
- **Expected:** Sheet presents edit view

**Test Steps:**
1. Open ProfileView
2. Locate "Edit Profile" row (first in Quick Actions)
3. Verify row shows:
   - Green icon (person.crop.circle)
   - "Edit Profile" text
   - Chevron indicator
4. Tap "Edit Profile"
5. Verify haptic feedback (medium impact)
6. Verify UserProfileEditView sheet presents
7. Verify can edit name, email, phone
8. Tap Cancel
9. Verify returns to ProfileView
10. Verify ProfileView still open

**Pass Criteria:**
- [ ] Row displays correctly
- [ ] Tap opens UserProfileEditView
- [ ] Haptic feedback fires
- [ ] Sheet animation smooth
- [ ] Cancel returns to ProfileView
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.4.2: View Analytics Navigation
- [ ] **Test Case:** View Analytics button opens AnalyticsView
- **Expected:** Sheet presents analytics view

**Test Steps:**
1. In ProfileView, tap "View Analytics"
2. Verify blue icon (chart.bar.fill)
3. Verify haptic feedback
4. Verify AnalyticsView opens
5. Verify analytics content displays
6. Close analytics
7. Verify returns to ProfileView

**Pass Criteria:**
- [ ] Row displays correctly
- [ ] Opens AnalyticsView
- [ ] Haptic feedback fires
- [ ] Analytics data displays
- [ ] Can navigate back
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.4.3: Backup & Export Navigation
- [ ] **Test Case:** Backup & Export button opens sheet
- **Expected:** Placeholder sheet displays (feature TBD)

**Test Steps:**
1. In ProfileView, tap "Backup & Export"
2. Verify orange icon (arrow.down.doc.fill)
3. Verify haptic feedback
4. Verify placeholder sheet opens
5. Verify shows "Backup & Export" title
6. Verify shows "coming soon" message
7. Tap Close button
8. Verify returns to ProfileView

**Pass Criteria:**
- [ ] Row displays correctly
- [ ] Opens placeholder sheet
- [ ] Haptic feedback fires
- [ ] Placeholder UI displays
- [ ] Close button works
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.4.4: Help & Support Navigation
- [ ] **Test Case:** Help & Support button opens HelpView
- **Expected:** Sheet presents help content

**Test Steps:**
1. In ProfileView, tap "Help & Support"
2. Verify purple icon (questionmark.circle.fill)
3. Verify haptic feedback
4. Verify HelpView opens
5. Verify help content displays
6. Close help
7. Verify returns to ProfileView

**Pass Criteria:**
- [ ] Row displays correctly
- [ ] Opens HelpView
- [ ] Haptic feedback fires
- [ ] Help content displays
- [ ] Can navigate back
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.4.5: All Settings Navigation
- [ ] **Test Case:** All Settings button opens SettingsView
- **Expected:** Sheet presents full settings

**Test Steps:**
1. In ProfileView, tap "All Settings"
2. Verify gray icon (gearshape.fill)
3. Verify haptic feedback
4. Verify SettingsView opens
5. Verify settings content displays
6. Close settings
7. Verify returns to ProfileView

**Pass Criteria:**
- [ ] Row displays correctly
- [ ] Opens SettingsView
- [ ] Haptic feedback fires
- [ ] Settings display correctly
- [ ] Can navigate back
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 19.5: Edit Profile Flow

**Objective:** Verify edit profile flow works end-to-end.

#### Test 19.5.1: Edit Profile Complete Flow
- [ ] **Test Case:** User can edit and save profile
- **Expected:** Changes persist after saving

**Test Steps:**
1. Open ProfileView
2. Note current name, email, phone
3. Tap "Edit Profile"
4. Change name to "Test User Updated"
5. Change email to "updated@test.com"
6. Change phone to "+1 (555) 999-8888"
7. Verify "Save Changes" button enabled
8. Tap "Save Changes"
9. Verify returns to ProfileView
10. Verify ProfileView shows updated name
11. Verify ProfileView shows updated email
12. Close ProfileView
13. Reopen ProfileView
14. Verify changes persisted

**Pass Criteria:**
- [ ] Can edit all fields
- [ ] Save button enables when changed
- [ ] Saves successfully
- [ ] Returns to ProfileView
- [ ] Changes display immediately
- [ ] Changes persist after closing/reopening

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.5.2: Edit Profile Discard Changes
- [ ] **Test Case:** Cancel discards unsaved changes
- **Expected:** Confirmation alert, changes not saved

**Test Steps:**
1. Open ProfileView
2. Note current name
3. Tap "Edit Profile"
4. Change name to "Temporary Name"
5. Tap "Cancel" button
6. Verify alert appears: "Discard Changes?"
7. Tap "Keep Editing"
8. Verify stays in edit view
9. Verify changes still present
10. Tap "Cancel" again
11. Tap "Discard"
12. Verify returns to ProfileView
13. Verify original name displayed (not changed)

**Pass Criteria:**
- [ ] Cancel shows confirmation alert
- [ ] "Keep Editing" stays in edit mode
- [ ] "Discard" returns to ProfileView
- [ ] Changes not saved after discard
- [ ] Original values retained

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 19.6: Theme Switching

**Objective:** Verify theme mode selection works correctly.

#### Test 19.6.1: Light Mode Selection
- [ ] **Test Case:** User can switch to light mode
- **Expected:** UI updates to light theme

**Test Steps:**
1. Set device to dark mode (Settings > Display)
2. Open app (should be in dark mode)
3. Open ProfileView
4. Locate "Theme Mode" row in Preferences
5. Verify shows current mode (e.g., "System")
6. Tap "Theme Mode"
7. Verify theme picker sheet opens
8. Verify 3 options: Light, Dark, System
9. Tap "Light"
10. Verify checkmark appears on Light
11. Verify sheet dismisses
12. Verify ProfileView switches to light mode
13. Close ProfileView
14. Verify entire app in light mode
15. Close and relaunch app
16. Verify light mode persisted

**Pass Criteria:**
- [ ] Theme picker displays correctly
- [ ] Light option selectable
- [ ] Checkmark shows on selected
- [ ] UI switches to light immediately
- [ ] Entire app affected
- [ ] Setting persists after relaunch

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.6.2: Dark Mode Selection
- [ ] **Test Case:** User can switch to dark mode
- **Expected:** UI updates to dark theme

**Test Steps:**
1. Set app to light mode (using theme picker)
2. Open ProfileView
3. Tap "Theme Mode"
4. Tap "Dark"
5. Verify UI switches to dark mode
6. Verify checkmark on Dark
7. Close ProfileView
8. Verify entire app in dark mode
9. Relaunch app
10. Verify dark mode persisted

**Pass Criteria:**
- [ ] Dark option selectable
- [ ] UI switches to dark immediately
- [ ] All colors adapt correctly
- [ ] Setting persists

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.6.3: System Mode Selection
- [ ] **Test Case:** System mode follows device setting
- **Expected:** UI matches device appearance

**Test Steps:**
1. Set device to light mode
2. Open app
3. Set app theme to "System"
4. Verify app in light mode
5. Go to device Settings > Display
6. Switch device to dark mode
7. Return to app
8. Verify app switched to dark mode
9. Switch device back to light mode
10. Verify app switches to light mode

**Pass Criteria:**
- [ ] System option selectable
- [ ] App follows device setting
- [ ] Switches automatically with device
- [ ] No manual refresh needed

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 19.7: Close/Dismiss

**Objective:** Verify ProfileView dismisses correctly.

#### Test 19.7.1: X Button Dismiss
- [ ] **Test Case:** X button dismisses ProfileView
- **Expected:** Sheet dismisses with animation

**Test Steps:**
1. Open ProfileView
2. Locate X button (top-left, custom nav bar)
3. Verify button visible and tappable
4. Tap X button
5. Verify sheet dismisses smoothly
6. Verify returns to ContentView/HomeView
7. Verify no crashes
8. Open ProfileView again
9. Verify state preserved (scroll position, etc.)

**Pass Criteria:**
- [ ] X button visible
- [ ] X button tappable (44x44pt)
- [ ] Sheet dismisses smoothly
- [ ] Returns to previous view
- [ ] No crashes
- [ ] State preserved on reopen

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

#### Test 19.7.2: Swipe-Down Gesture Dismiss
- [ ] **Test Case:** Swipe down dismisses sheet
- **Expected:** Sheet dismisses with swipe gesture

**Test Steps:**
1. Open ProfileView
2. Swipe down from top of sheet
3. Verify sheet follows finger
4. Release swipe (drag down > 50%)
5. Verify sheet dismisses
6. Verify returns to previous view
7. Open ProfileView again
8. Swipe down partially (< 50%)
9. Release
10. Verify sheet bounces back (doesn't dismiss)

**Pass Criteria:**
- [ ] Swipe down gesture recognized
- [ ] Sheet follows finger
- [ ] Dismisses on full swipe
- [ ] Bounces back on partial swipe
- [ ] Smooth animation
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

## Task 20: Edge Case Testing (8 Tests)

### Test 20.1: Empty Profile

**Objective:** Verify app handles empty profile data gracefully.

#### Test 20.1.1: No Name/Email Profile
- [ ] **Test Case:** Profile with no name or email
- **Expected:** Fallback text, no crashes

**Test Steps:**
1. Reset app or create new profile
2. Leave name field empty (delete default)
3. Leave email field empty
4. Leave phone field empty
5. Save
6. Open ProfileView
7. Verify name shows "Add Your Name" in placeholder style
8. Verify email line is hidden (not showing blank)
9. Verify phone line is hidden
10. Verify "Member since" still displays
11. Verify avatar shows initials "U" or default
12. Verify Edit Profile button still works
13. Tap Edit Profile
14. Verify can add name/email

**Pass Criteria:**
- [ ] "Add Your Name" displays for empty name
- [ ] Empty email completely hidden
- [ ] Empty phone completely hidden
- [ ] No blank spaces where fields should be
- [ ] Date still displays
- [ ] Avatar displays fallback
- [ ] Edit button functional
- [ ] No crashes
- [ ] Layout looks intentional, not broken

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.2: No Subscriptions

**Objective:** Verify app handles zero subscriptions.

#### Test 20.2.1: Zero Subscription Count
- [ ] **Test Case:** Profile with 0 subscriptions
- **Expected:** Displays "0" and "$0"

**Test Steps:**
1. Delete all subscriptions from app
2. Verify no active subscriptions exist
3. Open ProfileView
4. Verify Subscriptions card shows "0"
5. Verify Monthly Spending shows "$0"
6. Verify cards still look normal (not broken)
7. Tap Subscriptions card
8. Verify no crash
9. Verify no error messages
10. Verify no "divide by zero" errors

**Pass Criteria:**
- [ ] Subscriptions displays "0"
- [ ] Spending displays "$0"
- [ ] Cards maintain layout
- [ ] No crashes on tap
- [ ] No error messages
- [ ] No visual glitches
- [ ] Colors and icons still display

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.3: No People or Groups

**Objective:** Verify app handles zero people and groups.

#### Test 20.3.1: Zero People and Groups
- [ ] **Test Case:** No people or groups in app
- **Expected:** Displays "0" for both

**Test Steps:**
1. Delete all people from app
2. Delete all groups from app
3. Open ProfileView
4. Verify People card shows "0"
5. Verify Groups card shows "0"
6. Tap People card
7. Verify no crash
8. Tap Groups card
9. Verify no crash
10. Verify layout maintained

**Pass Criteria:**
- [ ] People displays "0"
- [ ] Groups displays "0"
- [ ] No crashes on tap
- [ ] Layout maintained
- [ ] Cards look normal

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.4: Very Long Name

**Objective:** Verify UI handles extremely long names.

#### Test 20.4.1: 100+ Character Name
- [ ] **Test Case:** Name with 100+ characters
- **Expected:** Truncation or wrapping, no overflow

**Test Data:**
```
"This is an extremely long name with more than one hundred characters to test the truncation and wrapping behavior of the user interface"
```

**Test Steps:**
1. Open Edit Profile
2. Paste 100+ character name
3. Save
4. Open ProfileView
5. Verify name displays without:
   - Horizontal overflow (no text off screen)
   - Breaking layout
   - Obscuring other elements
6. Check name display method:
   - Truncated with ellipsis (...)?
   - Wrapped to multiple lines?
   - Font scaled down?
7. Verify avatar still visible
8. Verify Edit button accessible
9. Verify scrolling works if needed
10. Test on small device (iPhone SE)

**Pass Criteria:**
- [ ] No horizontal overflow
- [ ] Text handled gracefully (truncate/wrap/scale)
- [ ] Avatar not obscured
- [ ] Edit button accessible
- [ ] Layout functional
- [ ] Works on small screens
- [ ] Readable (not microscopic)

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.5: 1000+ Subscriptions

**Objective:** Verify UI handles very large data sets.

#### Test 20.5.1: Large Subscription Count
- [ ] **Test Case:** 1000+ subscriptions in app
- **Expected:** Number formatted, UI functional

**Test Steps:**
1. Create test data with 1234 subscriptions
   - Use test/mock data if available
2. Open app
3. Verify app launches normally
4. Open ProfileView
5. Verify Subscriptions shows "1,234"
6. Verify comma separator present
7. Verify number fits in card
8. Verify no font size issues
9. Verify no performance lag
10. Verify app remains responsive

**Pass Criteria:**
- [ ] Displays "1,234" with comma
- [ ] Number fits in card
- [ ] No overflow
- [ ] Font remains readable
- [ ] No performance issues
- [ ] App responsive
- [ ] Can still tap card
- [ ] No crashes

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.6: Missing Avatar Data

**Objective:** Verify app handles invalid or missing avatar data.

#### Test 20.6.1: Invalid Avatar Data
- [ ] **Test Case:** Avatar with nil or corrupted data
- **Expected:** Fallback to initials

**Test Steps:**
1. **Test nil photo data:**
   - Manually set avatar to .photo(Data()) (empty)
   - Open ProfileView
   - Verify displays fallback (initials or placeholder)

2. **Test corrupted photo data:**
   - Set avatar to .photo with invalid data
   - Verify fallback displays

3. **Test invalid emoji:**
   - Set avatar to .emoji("") (empty string)
   - Verify fallback displays

4. **Test invalid initials:**
   - Set avatar to .initials("", colorIndex: 0)
   - Verify fallback displays

5. Verify no crashes in any case
6. Verify fallback is user-friendly

**Pass Criteria:**
- [ ] Nil photo shows fallback
- [ ] Corrupted photo shows fallback
- [ ] Empty emoji shows fallback
- [ ] Empty initials show fallback
- [ ] Fallback is appropriate (not error icon)
- [ ] No crashes
- [ ] User can fix via Edit Profile

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.7: Offline Mode

**Objective:** Verify ProfileView works without network.

#### Test 20.7.1: Offline Functionality
- [ ] **Test Case:** Use ProfileView with no network
- **Expected:** Full functionality (all data local)

**Test Steps:**
1. Enable Airplane Mode on device
2. Verify no WiFi/cellular connection
3. Open app
4. Open ProfileView
5. Verify all sections load:
   - Header with avatar
   - Statistics (all 4 cards)
   - Quick Actions
   - Preferences
   - Account
6. Tap Edit Profile
7. Edit name
8. Save changes
9. Verify changes persist
10. Close and reopen ProfileView
11. Verify changes saved locally

**Pass Criteria:**
- [ ] ProfileView opens offline
- [ ] All data displays (locally stored)
- [ ] No "network error" messages
- [ ] Can edit profile offline
- [ ] Changes save locally
- [ ] No features broken
- [ ] No loading spinners stuck

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

### Test 20.8: Low Memory

**Objective:** Document memory usage and check for leaks.

#### Test 20.8.1: Memory Usage
- [ ] **Test Case:** Profile view memory usage
- **Expected:** No memory leaks, reasonable usage

**Test Steps:**
1. Launch app
2. Open Xcode > Debug > Memory Report (if available)
3. Note baseline memory usage
4. Open ProfileView
5. Note memory increase
6. Close ProfileView
7. Note memory after close
8. Repeat open/close 10 times
9. Check memory after 10 cycles
10. Memory should return near baseline

**Expected Memory:**
- Baseline: ~50-100 MB
- ProfileView open: +5-10 MB
- After close: Returns to baseline
- After 10 cycles: No significant increase

**Pass Criteria:**
- [ ] Memory usage reasonable (<100 MB total)
- [ ] No memory leaks (returns to baseline)
- [ ] No crashes from memory pressure
- [ ] Images released when dismissed
- [ ] No retain cycles

**Status:** ⬜ PASS / ⬜ FAIL
**Memory Baseline:** _______ MB
**Memory with ProfileView:** _______ MB
**Memory after 10 cycles:** _______ MB
**Notes:** _______________________________________

---

## Task 21: Visual QA (8 Tests)

### Test 21.1: iPhone SE (Small Screen)

**Objective:** Verify layout works on smallest iPhone screen.

#### Test 21.1.1: iPhone SE Layout
- [ ] **Test Case:** ProfileView on iPhone SE (375pt width)
- **Expected:** All content fits, no clipping

**Device:** iPhone SE (2nd/3rd gen)
**Screen Size:** 375 x 667 pt
**Test Date:** ___________

**Test Steps:**
1. Run app on iPhone SE or simulator
2. Open ProfileView
3. Verify avatar displays fully (80x80pt)
4. Verify name doesn't clip
5. Verify email doesn't overflow
6. Verify statistics grid:
   - 2 columns
   - Both cards visible
   - Icons visible
   - Numbers visible
   - No horizontal scrolling
7. Verify all quick action rows:
   - Icon visible
   - Text visible
   - Chevron visible
   - No text truncation
8. Scroll to bottom
9. Verify all sections accessible
10. Verify no overlap of elements
11. Test Edit Profile button
12. Verify Edit Profile fits on screen

**Pass Criteria:**
- [ ] All content fits 375pt width
- [ ] No horizontal scrolling
- [ ] No clipping or overflow
- [ ] All buttons reachable
- [ ] Text readable (not too small)
- [ ] Statistics cards sized properly
- [ ] Navigation smooth
- [ ] All interactive elements tappable

**Status:** ⬜ PASS / ⬜ FAIL
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.2: iPhone 15 (Standard)

**Objective:** Verify layout looks good on standard iPhone.

#### Test 21.2.1: iPhone 15 Layout
- [ ] **Test Case:** ProfileView on iPhone 15 (393pt width)
- **Expected:** Optimal spacing, no excessive white space

**Device:** iPhone 15 / 15 Pro
**Screen Size:** 393 x 852 pt
**Test Date:** ___________

**Test Steps:**
1. Run app on iPhone 15 or simulator
2. Open ProfileView
3. Verify layout looks balanced
4. Verify spacing between sections (24pt)
5. Verify statistics cards:
   - Good proportions
   - Not too small
   - Not too large
   - Centered in grid
6. Verify all text readable
7. Verify no excessive white space
8. Verify avatar size appropriate (80x80pt)
9. Compare to design specs
10. Verify matches intended design

**Pass Criteria:**
- [ ] Layout balanced
- [ ] Proper spacing (16pt horizontal, 24pt vertical)
- [ ] Cards proportioned well
- [ ] No excessive white space
- [ ] Matches design specifications
- [ ] Looks polished and professional

**Status:** ⬜ PASS / ⬜ FAIL
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.3: iPhone 15 Pro Max (Large)

**Objective:** Verify layout on largest iPhone screen.

#### Test 21.3.1: iPhone 15 Pro Max Layout
- [ ] **Test Case:** ProfileView on Pro Max (430pt width)
- **Expected:** No excessive white space, good use of space

**Device:** iPhone 15 Pro Max / 15 Plus
**Screen Size:** 430 x 932 pt
**Test Date:** ___________

**Test Steps:**
1. Run app on Pro Max or simulator
2. Open ProfileView
3. Verify elements scale appropriately
4. Check for excessive white space:
   - Around avatar
   - Between cards
   - On sides of content
5. Verify statistics cards:
   - Not stretched too wide
   - Maintain square proportions
   - Content centered
6. Verify text doesn't look tiny
7. Verify buttons easily tappable
8. Verify overall aesthetic pleasing

**Pass Criteria:**
- [ ] No excessive white space
- [ ] Cards sized appropriately
- [ ] Text readable (not too small)
- [ ] Layout uses available space well
- [ ] Doesn't look "stretched"
- [ ] Maintains visual hierarchy

**Status:** ⬜ PASS / ⬜ FAIL
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.4: iPad (If Supported)

**Objective:** Test iPad layout if supported.

#### Test 21.4.1: iPad Layout
- [ ] **Test Case:** ProfileView on iPad
- **Expected:** Sheet looks appropriate or document not supported

**Device:** iPad (any size)
**Test Date:** ___________

**Test Steps:**
1. Run app on iPad
2. Open ProfileView
3. Observe sheet presentation:
   - Does it fill screen?
   - Does it show as centered sheet?
   - Does it look appropriate?
4. If supported:
   - Verify layout adapts to larger screen
   - Verify no awkward stretching
   - Verify readable and usable
5. If not supported:
   - Document that iPad not currently supported
   - App should still be usable in iPhone compatibility mode

**Pass Criteria:**
- [ ] Sheet presentation appropriate for iPad
- [ ] Layout adapts or scales reasonably
- [ ] OR: Document iPad not supported (OK)
- [ ] No crashes on iPad
- [ ] Usable even if not optimized

**Status:** ⬜ PASS / ⬜ FAIL / ⬜ NOT SUPPORTED
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.5: Landscape Orientation

**Objective:** Test landscape mode if supported.

#### Test 21.5.1: Landscape Mode
- [ ] **Test Case:** ProfileView in landscape
- **Expected:** Layout adapts or portrait-only

**Test Steps:**
1. Open ProfileView
2. Rotate device to landscape
3. Observe behavior:
   - Does layout adapt?
   - Does orientation lock to portrait?
   - Does it look broken?
4. If adapts:
   - Verify all content visible
   - Verify layout reasonable
5. If locked to portrait:
   - Document portrait-only design decision

**Pass Criteria:**
- [ ] Landscape works well
- [ ] OR: Locked to portrait (acceptable)
- [ ] No broken layouts
- [ ] No crashes on rotation
- [ ] Clear user experience

**Status:** ⬜ PASS / ⬜ FAIL / ⬜ PORTRAIT ONLY
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.6: Light Mode Appearance

**Objective:** Verify all colors correct in light mode.

#### Test 21.6.1: Light Mode Visual Inspection
- [ ] **Test Case:** ProfileView in light mode
- **Expected:** Matches design system colors

**Device:** ___________
**Test Date:** ___________

**Test Steps:**
1. Set device to light mode
2. Set app theme to Light
3. Open ProfileView
4. Inspect each section:

**Header:**
- [ ] Background: White (#FFFFFF)
- [ ] Name text: Black (#1A1A1A)
- [ ] Email text: Gray (#3C3C3C)
- [ ] Avatar: Appropriate colors

**Statistics Cards:**
- [ ] Card background: White
- [ ] Icons: Correct colors (green, orange, blue, purple)
- [ ] Title text: Gray uppercase
- [ ] Value text: Black
- [ ] Shadows: Subtle (opacity 0.05)

**Quick Action Rows:**
- [ ] Row background: White
- [ ] Icon circles: Colored backgrounds
- [ ] Text: Black
- [ ] Chevrons: Gray

**General:**
- [ ] Screen background: wiseBackground
- [ ] All text readable
- [ ] Shadows visible but subtle
- [ ] Borders visible
- [ ] Colors match design system

**Pass Criteria:**
- [ ] All colors match specifications
- [ ] Text readable (contrast ≥ 4.5:1)
- [ ] Shadows visible
- [ ] Icons clear
- [ ] No washed out colors
- [ ] Professional appearance

**Status:** ⬜ PASS / ⬜ FAIL
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.7: Dark Mode Appearance

**Objective:** Verify all colors adapt in dark mode.

#### Test 21.7.1: Dark Mode Visual Inspection
- [ ] **Test Case:** ProfileView in dark mode
- **Expected:** Matches dark mode design system

**Device:** ___________
**Test Date:** ___________

**Test Steps:**
1. Set device to dark mode
2. Set app theme to Dark
3. Open ProfileView
4. Inspect each section:

**Header:**
- [ ] Background: Black (#000000)
- [ ] Name text: White (#FFFFFF)
- [ ] Email text: Light gray (#AEAEB2)
- [ ] Avatar: Appropriate colors

**Statistics Cards:**
- [ ] Card background: Dark gray (#1C1C1E)
- [ ] Icons: Same colors (still visible)
- [ ] Title text: Light gray
- [ ] Value text: White
- [ ] Shadows: Stronger (opacity 0.2)

**Quick Action Rows:**
- [ ] Row background: Dark gray (#1C1C1E)
- [ ] Icon circles: Colored backgrounds
- [ ] Text: White
- [ ] Chevrons: Light gray

**General:**
- [ ] Screen background: Black
- [ ] All text readable
- [ ] Shadows visible
- [ ] Borders visible (#38383A)
- [ ] Colors adapted correctly

**Pass Criteria:**
- [ ] All colors adapted for dark mode
- [ ] Text readable (contrast ≥ 4.5:1)
- [ ] Shadows visible (stronger than light mode)
- [ ] Icons still clear
- [ ] No blinding bright elements
- [ ] Professional dark appearance
- [ ] Cards distinguishable from background

**Status:** ⬜ PASS / ⬜ FAIL
**Screenshot:** [ ] Attached
**Notes:** _______________________________________

---

### Test 21.8: Transitions Between Modes

**Objective:** Verify smooth transitions when switching themes.

#### Test 21.8.1: Theme Transition Animation
- [ ] **Test Case:** Switch between light and dark modes
- **Expected:** Smooth transition, no flashing

**Test Steps:**
1. Open ProfileView in light mode
2. Tap Theme Mode
3. Select Dark
4. Observe transition:
   - Is it smooth?
   - Any flashing?
   - Any elements that don't update?
5. Switch back to Light
6. Observe transition again
7. Switch to System mode
8. Toggle device appearance
9. Observe app follows smoothly
10. Repeat switches multiple times
11. Verify no glitches

**Pass Criteria:**
- [ ] Transition is smooth
- [ ] No jarring flashes
- [ ] All elements update together
- [ ] No visual glitches
- [ ] Colors fade/morph nicely
- [ ] Avatar updates smoothly
- [ ] Text updates smoothly
- [ ] No "pop-in" of elements
- [ ] Feels polished

**Status:** ⬜ PASS / ⬜ FAIL
**Notes:** _______________________________________

---

## Summary & Sign-off

### Test Execution Summary

**Testing Period:** __________ to __________
**Tester Name:** __________
**Device(s) Used:** __________
**iOS Version(s):** __________

### Results Overview

| Task | Test Name | Total Tests | Passed | Failed | Not Tested |
|------|-----------|-------------|--------|--------|------------|
| 18 | Unit Testing | 6 | __ | __ | __ |
| 19 | UI Testing | 7 | __ | __ | __ |
| 20 | Edge Case Testing | 8 | __ | __ | __ |
| 21 | Visual QA | 8 | __ | __ | __ |
| **TOTAL** | **All Tests** | **29** | __ | __ | __ |

**Pass Rate:** _____ %

### Critical Issues Found

**Priority 1 (Blocking):**
1. _______________________________________
2. _______________________________________
3. _______________________________________

**Priority 2 (High):**
1. _______________________________________
2. _______________________________________
3. _______________________________________

**Priority 3 (Medium):**
1. _______________________________________
2. _______________________________________
3. _______________________________________

**Priority 4 (Low):**
1. _______________________________________
2. _______________________________________

### Issues by Category

**Unit Testing Issues:**
- _______________________________________
- _______________________________________

**UI Testing Issues:**
- _______________________________________
- _______________________________________

**Edge Case Issues:**
- _______________________________________
- _______________________________________

**Visual QA Issues:**
- _______________________________________
- _______________________________________

### Code Fixes Required

Based on testing, the following code changes are recommended:

#### High Priority Fixes
1. **File:** _______________________
   **Issue:** _______________________
   **Fix:** _______________________

2. **File:** _______________________
   **Issue:** _______________________
   **Fix:** _______________________

#### Medium Priority Fixes
1. **File:** _______________________
   **Issue:** _______________________
   **Fix:** _______________________

#### Low Priority Enhancements
1. **File:** _______________________
   **Enhancement:** _______________________

### Recommendations

**Immediate Actions:**
- _______________________________________
- _______________________________________

**Before Launch:**
- _______________________________________
- _______________________________________

**Future Improvements:**
- _______________________________________
- _______________________________________

### Sign-off

**Tested By:** __________
**Date:** __________
**Signature:** __________

**Reviewed By:** __________
**Date:** __________
**Signature:** __________

**Approved for Release:** ⬜ YES / ⬜ NO / ⬜ WITH CONDITIONS

**Conditions (if applicable):**
_______________________________________
_______________________________________

---

## Appendix A: Test Data Setup

### How to Create Test Data

#### Large Subscription Count (Test 20.5)
```swift
// Add to DataManager or create test file
for i in 1...1234 {
    let subscription = Subscription(
        name: "Test Subscription \(i)",
        cost: 9.99,
        billingCycle: .monthly,
        isActive: true
    )
    dataManager.addSubscription(subscription)
}
```

#### Empty Profile (Test 20.1)
```swift
// Reset profile
UserProfileManager.shared.resetProfile()
// Or manually clear fields in Edit Profile
```

#### Long Name (Test 20.4)
```swift
let longName = "This is an extremely long name with more than one hundred characters to test the truncation and wrapping behavior of the user interface"
profile.name = longName
```

---

## Appendix B: Known Limitations

### Current Implementation Limitations

1. **Statistics Navigation:** Tapping statistics cards currently only logs to console. Navigation to specific tabs/views is not yet implemented.

2. **Backup & Export:** Placeholder UI only. Feature not yet implemented.

3. **Notification Permission:** Permission check exists but full notification setup may not be complete.

4. **iPad Optimization:** App is iPhone-first. iPad may show iPhone UI scaled.

5. **Landscape Mode:** May be portrait-only by design. Landscape not optimized.

---

## Appendix C: Accessibility Testing

### VoiceOver Testing Script

1. Enable VoiceOver: Settings > Accessibility > VoiceOver
2. Open ProfileView
3. Swipe right to navigate through elements
4. Verify each element announces correctly:
   - "Profile picture"
   - "[Name]"
   - "[Email]"
   - "Member since [date]"
   - "Edit Profile, button"
   - "Subscriptions, [count], button"
   - etc.
5. Double-tap to activate buttons
6. Verify all functionality accessible via VoiceOver

### Dynamic Type Testing

1. Settings > Accessibility > Display & Text Size > Larger Text
2. Drag slider to maximum
3. Open ProfileView
4. Verify all text scales
5. Verify no truncation
6. Verify layout adapts
7. Test at various sizes

---

## Appendix D: Performance Benchmarks

### Expected Performance Metrics

| Metric | Target | Acceptable | Unacceptable |
|--------|--------|------------|--------------|
| Profile Open Time | < 100ms | < 250ms | > 500ms |
| Statistics Calculation | < 50ms | < 100ms | > 200ms |
| Sheet Animation | 60 FPS | 55 FPS | < 50 FPS |
| Memory Usage | < 80 MB | < 120 MB | > 150 MB |
| Edit Save Time | < 100ms | < 200ms | > 500ms |

### How to Measure

1. **Time Measurements:** Use Xcode Instruments > Time Profiler
2. **FPS:** Use Xcode Debug > View Debugging > Rendering
3. **Memory:** Use Xcode Debug > Memory Report

---

## End of Checklist

**Document Version:** 1.0
**Last Updated:** 2025-11-24
**Author:** Development Team

This checklist is designed to be comprehensive yet practical. Execute tests in order, document all findings, and ensure all critical issues are resolved before release.

For questions or clarifications, refer to:
- [PROFILE_PAGE.md](./PROFILE_PAGE.md) - Implementation guide
- Apple Human Interface Guidelines
- Swiff iOS Design System documentation
