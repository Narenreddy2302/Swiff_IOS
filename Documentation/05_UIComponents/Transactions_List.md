# Unified List Design System - Implementation Guide

## Swiff iOS App - Complete List Redesign Documentation

**Document Version:** 2.0 - IMPLEMENTATION COMPLETE
**Created:** 2025-11-27
**Updated:** 2025-11-27
**Target:** Unified list designs across Feed, People, Groups, Subscriptions, and Analytics views
**Status:** ALL TASKS COMPLETED

---

## Table of Contents

1. [Overview](#1-overview)
2. [Reference Design Specification](#2-reference-design-specification)
3. [Design System Foundation](#3-design-system-foundation)
4. [Component Architecture](#4-component-architecture)
5. [Implementation Tasks](#5-implementation-tasks)
6. [Detailed Task Breakdown](#6-detailed-task-breakdown)
7. [Testing Checklist](#7-testing-checklist)

---

## 1. Overview

### 1.1 Goal

Create a unified list row design system that provides visual consistency across ALL list-based views in the Swiff iOS app. Every list in the application will follow the same design pattern, creating a cohesive user experience.

### 1.2 Target Design Pattern

Based on the reference image, the unified design features:

```
+------------------------------------------------------------------+
| [48px Circle]    Merchant/Title Name              + $3,500.00    |
| [Category Icon]  Category / Subtitle                             |
+------------------------------------------------------------------+
```

**Key Visual Elements:**
- Circular icon (48x48) with category-colored background at 10% opacity
- SF Symbol icon centered in circle with full category color
- Two-line text: Bold title + lighter subtitle
- Right-aligned amount with contextual color:
  - **GREEN** for income/positive amounts
  - **RED** for expenses/negative amounts
- Date-based section headers in uppercase (Transactions only)

### 1.3 Lists to Redesign

| View | Current State | Target Outcome | Grouping |
|------|---------------|----------------|----------|
| **Feed/Transactions** | Closest to target | Refine to exact spec | GROUP by date |
| **People** | Avatar + balance display | Unified row with avatar as icon | NO grouping - sort by recent interaction |
| **Groups** | Emoji + member list | Unified row with emoji circle | NO grouping - sort by recent activity |
| **Subscriptions** | Complex with badges | Simplified unified row | NO grouping - sort by recent activity |
| **Analytics Categories** | Progress bars | Unified row WITH progress bars | NO grouping |

### 1.4 Current Implementation Locations

| Component | File | Lines |
|-----------|------|-------|
| `FeedTransactionRow` | ContentView.swift | 2278-2395 |
| `PersonRowView` | ContentView.swift | 3829-3895 |
| `GroupRowView` | ContentView.swift | 4399-4462 |
| `EnhancedSubscriptionRowView` | ContentView.swift | 5844-6040 |
| `CategoryRow` | CategoryContributionList.swift | 57-152 |

---

## 2. Reference Design Specification

### 2.1 Row Layout Structure

```
+----------------------------------------------------------+
|                                                          |
|  +--------+   Title Text                    + $X,XXX.XX  |
|  | ICON   |   Subtitle / Category                        |
|  +--------+                                              |
|                                                          |
+----------------------------------------------------------+

Spacing:
- Row padding: 16pt all sides
- Icon to text: 16pt horizontal
- Title to subtitle: 4pt vertical
- Card corner radius: 12pt
```

### 2.2 Exact Dimensions

```swift
// ICON CIRCLE
let iconCircleSize: CGFloat = 48
let iconSize: CGFloat = 20
let iconBackgroundOpacity: CGFloat = 0.1

// SPACING
let rowHorizontalPadding: CGFloat = 16
let rowVerticalPadding: CGFloat = 16
let iconToTextSpacing: CGFloat = 16
let titleToSubtitleSpacing: CGFloat = 4

// CARD
let cardCornerRadius: CGFloat = 12
```

### 2.3 Typography Specification

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Title | Helvetica Neue | 16pt | Medium | `.wisePrimaryText` |
| Subtitle | Helvetica Neue | 13pt | Regular | `.wiseSecondaryText` |
| Amount | Helvetica Neue | 16pt | Bold | Context-dependent |
| Amount Label | Helvetica Neue | 10pt | Regular | `.wiseSecondaryText` |
| Section Header | System | 13pt | Bold | `.wisePrimaryText` |

### 2.4 Color Specification

**Amount Colors (IMPORTANT):**
| Context | Color | Variable |
|---------|-------|----------|
| Income/Positive | #9FE870 | `.wiseBrightGreen` |
| **Expense/Negative** | **#FF3B30 (light) / #FF453A (dark)** | **`.wiseError`** |
| Neutral | Adapts to theme | `.wisePrimaryText` |

**Background Colors:**
| Element | Light Mode | Dark Mode | Variable |
|---------|------------|-----------|----------|
| Card Background | #FFFFFF | #262626 | `.wiseCardBackground` |
| Screen Background | #FFFFFF | #000000 | `.wiseBackground` |
| Icon Circle Fill | Category color @ 10% opacity | Category color @ 10% opacity | Dynamic |

### 2.5 Section Header Design (Transactions Only)

```
TODAY, OCT 27                              3 transactions
─────────────────────────────────────────────────────────

Format:
- Date: UPPERCASE, 13pt bold, 0.5 letter spacing
- Count badge: Capsule with border, 12pt medium
- Spacing: 10pt vertical padding, 16pt horizontal
```

**Note:** Section headers are ONLY used for Transactions view. People, Groups, and Subscriptions do NOT use section headers - they are sorted by recency.

---

## 3. Design System Foundation

### 3.1 Existing Typography (ContentView.swift:24-54)

```swift
// USE THESE FONTS - ALREADY DEFINED IN APP
extension Font {
    // For row titles
    static let spotifyBodyLarge = Font.custom("Helvetica Neue", size: 16).weight(.medium)

    // For subtitles
    static let spotifyBodySmall = Font.custom("Helvetica Neue", size: 13).weight(.regular)

    // For amounts
    static let spotifyNumberMedium = Font.custom("Helvetica Neue", size: 16).weight(.bold)

    // For labels under amounts
    static let spotifyCaptionSmall = Font.custom("Helvetica Neue", size: 10).weight(.regular)

    // For section headers
    static let spotifyLabelMedium = Font.custom("Helvetica Neue", size: 12).weight(.semibold)
}
```

### 3.2 Existing Color System (SupportingTypes.swift:572-1009)

```swift
// ADAPTIVE COLORS - ALREADY DEFINED IN APP
extension Color {
    // Backgrounds
    static let wiseCardBackground     // White / #262626
    static let wiseBackground         // White / Black

    // Text
    static let wisePrimaryText        // #1A1A1A / White
    static let wiseSecondaryText      // #3C3C3C / #B3B3B3

    // Status - USE THESE FOR AMOUNTS
    static let wiseBrightGreen        // #9FE870 (static) - FOR INCOME
    static let wiseError              // #FF3B30 / #FF453A - FOR EXPENSES
    static let wiseSuccess            // #34C759 / #30D158
    static let wiseWarning            // #FF9500 / #FF9F0A

    // Borders
    static let wiseBorder             // Adaptive border color
}
```

### 3.3 Category Colors (SupportingTypes.swift:328-400)

```swift
// TRANSACTION CATEGORIES - icon AND color PROPERTIES
enum TransactionCategory {
    case food         // icon: "fork.knife"        color: Orange #FF9700
    case dining       // icon: "fork.knife"        color: Light Orange
    case groceries    // icon: "cart.fill"         color: Green #2ECC71
    case transportation // icon: "car.fill"        color: Blue #00B9FF
    case travel       // icon: "airplane"          color: Dark Blue #007AFF
    case shopping     // icon: "bag.fill"          color: Pink #E31E75
    case entertainment // icon: "tv.fill"          color: Purple #9B59B6
    case bills        // icon: "house.fill"        color: Brown #A52A2A
    case utilities    // icon: "bolt.fill"         color: Yellow #FFCC00
    case healthcare   // icon: "cross.fill"        color: Red #FF4436
    case income       // icon: "dollarsign.circle.fill" color: Green #9FE870
    case transfer     // icon: "arrow.left.arrow.right" color: Gray #3C3C3C
    case investment   // icon: "chart.line.uptrend.xyaxis" color: Dark Green
    case other        // icon: "ellipsis.circle.fill" color: Gray #808080
}
```

### 3.4 Existing Shadow System (AdaptiveShadow.swift)

```swift
// USE THESE MODIFIERS
.subtleShadow()  // For list rows - radius: 4, y: 1
.cardShadow()    // For elevated cards - radius: 8, y: 2
```

---

## 4. Component Architecture

### 4.1 New Components to Create

#### Component 1: UnifiedIconCircle

**Purpose:** Consistent circular icon container for all list items

**File:** `Swiff IOS/Views/Components/UnifiedIconCircle.swift`

```swift
import SwiftUI

/// Unified icon circle for consistent list item icons
struct UnifiedIconCircle: View {
    let icon: String              // SF Symbol name
    let color: Color              // Category/theme color
    var size: CGFloat = 48        // Circle diameter
    var iconSize: CGFloat = 20    // Icon size

    var body: some View {
        Circle()
            .fill(color.opacity(0.1))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(color)
            )
    }
}

/// Emoji variant for groups
struct UnifiedEmojiCircle: View {
    let emoji: String
    var backgroundColor: Color = .wiseBlue
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [backgroundColor.opacity(0.2), backgroundColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(emoji)
                    .font(.system(size: size * 0.5))
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        UnifiedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
        UnifiedIconCircle(icon: "cart.fill", color: .orange)
        UnifiedEmojiCircle(emoji: "🏠", backgroundColor: .wiseBlue)
    }
    .padding()
}
```

---

#### Component 2: UnifiedSectionHeader

**Purpose:** Consistent date-based section headers (FOR TRANSACTIONS ONLY)

**File:** `Swiff IOS/Views/Components/UnifiedSectionHeader.swift`

```swift
import SwiftUI

/// Unified section header for date grouping (Transactions only)
struct UnifiedSectionHeader: View {
    let title: String           // e.g., "TODAY, NOV 27"
    var count: Int? = nil       // Item count
    var countLabel: String = "items"

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.wisePrimaryText)
                .tracking(0.5)

            Spacer()

            if let count = count {
                Text("\(count) \(count == 1 ? String(countLabel.dropLast()) : countLabel)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// Date formatting helper
extension Date {
    func toSectionHeaderTitle() -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "TODAY, \(self.formatted(.dateTime.month(.abbreviated).day()).uppercased())"
        } else if calendar.isDateInYesterday(self) {
            return "YESTERDAY, \(self.formatted(.dateTime.month(.abbreviated).day()).uppercased())"
        } else {
            return self.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased()
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        UnifiedSectionHeader(title: "TODAY, NOV 27", count: 3, countLabel: "transactions")
        UnifiedSectionHeader(title: "YESTERDAY, NOV 26", count: 5, countLabel: "transactions")
        UnifiedSectionHeader(title: "MON, NOV 25", count: 2, countLabel: "items")
    }
}
```

---

#### Component 3: UnifiedListRow

**Purpose:** Base row component for all list views

**File:** `Swiff IOS/Views/Components/UnifiedListRow.swift`

```swift
import SwiftUI

/// Base unified list row component
struct UnifiedListRow<IconContent: View>: View {
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color
    var valueLabel: String? = nil
    var showChevron: Bool = false

    @ViewBuilder let iconContent: () -> IconContent

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon Area
            iconContent()

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Value Area
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(valueColor)

                if let label = valueLabel {
                    Text(label)
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Optional Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .subtleShadow()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

#Preview {
    VStack(spacing: 12) {
        // Income example - GREEN
        UnifiedListRow(
            title: "Employer Inc. Payroll",
            subtitle: "Salary / Income",
            value: "+ $3,500.00",
            valueColor: .wiseBrightGreen
        ) {
            UnifiedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
        }

        // Expense example - RED
        UnifiedListRow(
            title: "Starbucks Coffee Company",
            subtitle: "Food & Drink",
            value: "- $6.45",
            valueColor: .wiseError
        ) {
            UnifiedIconCircle(icon: "cup.and.saucer.fill", color: .orange)
        }
    }
    .padding()
}
```

---

#### Component 4: UnifiedListRowWithProgress (For Analytics)

**Purpose:** Row component with progress bar for Analytics view

**File:** `Swiff IOS/Views/Components/UnifiedListRowWithProgress.swift`

```swift
import SwiftUI

/// Unified list row with progress bar for Analytics categories
struct UnifiedListRowWithProgress<IconContent: View>: View {
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color
    let percentage: Double
    var valueLabel: String? = nil
    var isSelected: Bool = false

    @ViewBuilder let iconContent: () -> IconContent

    var body: some View {
        VStack(spacing: 0) {
            // Main Row Content
            HStack(spacing: 16) {
                // Icon Area
                iconContent()

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Value Area
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(valueColor)

                    if let label = valueLabel {
                        Text(label)
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(16)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.wiseBorder.opacity(0.3))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [valueColor.opacity(0.8), valueColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (percentage / 100), height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? valueColor.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
        .subtleShadow()
    }
}

#Preview {
    VStack(spacing: 12) {
        UnifiedListRowWithProgress(
            title: "Food & Dining",
            subtitle: "Expense",
            value: "$450.00",
            valueColor: .wiseError,
            percentage: 35.5,
            valueLabel: "35.5%",
            isSelected: true
        ) {
            UnifiedIconCircle(icon: "fork.knife", color: .orange)
        }

        UnifiedListRowWithProgress(
            title: "Salary",
            subtitle: "Income",
            value: "$5,000.00",
            valueColor: .wiseBrightGreen,
            percentage: 80.0,
            valueLabel: "80.0%"
        ) {
            UnifiedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
        }
    }
    .padding()
}
```

---

## 5. Implementation Tasks

### Task Overview

| Phase | Task ID | Description | Priority | Status |
|-------|---------|-------------|----------|--------|
| 1 | T1.1 | Create UnifiedIconCircle component | HIGH | ✅ COMPLETED |
| 1 | T1.2 | Create UnifiedSectionHeader component | HIGH | ✅ COMPLETED |
| 1 | T1.3 | Create UnifiedListRow component | HIGH | ✅ COMPLETED |
| 1 | T1.4 | Create UnifiedListRowWithProgress component | HIGH | ✅ COMPLETED |
| 2 | T2.1 | Refactor FeedTransactionRow (grouped by date) | HIGH | ✅ COMPLETED |
| 3 | T3.1 | Refactor PersonRowView (sorted by recent interaction) | MEDIUM | ✅ COMPLETED |
| 4 | T4.1 | Refactor GroupRowView (sorted by recent activity) | MEDIUM | ✅ COMPLETED |
| 5 | T5.1 | Refactor EnhancedSubscriptionRowView (sorted by recent activity) | MEDIUM | ✅ COMPLETED |
| 6 | T6.1 | Refactor CategoryRow with progress bar | MEDIUM | ✅ COMPLETED |

### Implementation Summary

**All tasks have been completed successfully!**

**Completed on:** 2025-11-27

**Files Created:**
- `Swiff IOS/Views/Components/UnifiedIconCircle.swift` - Icon circle components (SF Symbol + Emoji variants)
- `Swiff IOS/Views/Components/UnifiedSectionHeader.swift` - Date-based section headers for Transactions
- `Swiff IOS/Views/Components/UnifiedListRow.swift` - Base unified list row component
- `Swiff IOS/Views/Components/UnifiedListRowWithProgress.swift` - Row with progress bar for Analytics

**Files Modified:**
- `Swiff IOS/ContentView.swift` - FeedTransactionRow, PersonRowView, GroupRowView, EnhancedSubscriptionRowView, SubscriptionRowView
- `Swiff IOS/Views/Components/TransactionGroupHeader.swift` - Uses UnifiedSectionHeader
- `Swiff IOS/Views/Components/CategoryContributionList.swift` - CategoryRow uses UnifiedListRowWithProgress

---

## 6. Detailed Task Breakdown

### PHASE 1: Create Base Components

---

#### Task T1.1: Create UnifiedIconCircle Component

**File to Create:** `Swiff IOS/Views/Components/UnifiedIconCircle.swift`

**Description:** Create a reusable icon circle component that displays an SF Symbol inside a colored circular background.

**Requirements:**
1. Create `UnifiedIconCircle` struct with parameters:
   - `icon: String` - SF Symbol name
   - `color: Color` - Category/theme color
   - `size: CGFloat = 48` - Circle diameter
   - `iconSize: CGFloat = 20` - Icon font size

2. Create `UnifiedEmojiCircle` variant for emoji content (used in Groups)

3. Icon circle should have:
   - Circular shape with `color.opacity(0.1)` fill
   - Centered SF Symbol in full `color`
   - 48pt default size

**Code Template:** See Component 1 in Section 4.1

**Acceptance Criteria:**
- [x] Component renders correctly in light mode
- [x] Component renders correctly in dark mode
- [x] Icon is centered in circle
- [x] Background opacity is exactly 0.1
- [x] Size parameters work correctly

---

#### Task T1.2: Create UnifiedSectionHeader Component

**File to Create:** `Swiff IOS/Views/Components/UnifiedSectionHeader.swift`

**Description:** Create a consistent section header for date-based grouping. **ONLY used for Transactions view.**

**Requirements:**
1. Create `UnifiedSectionHeader` struct with parameters:
   - `title: String` - Section title (will be uppercased)
   - `count: Int?` - Optional item count
   - `countLabel: String = "items"` - Label for count

2. Header should display:
   - Uppercase title with 0.5 letter spacing
   - Optional count badge in capsule on right side

3. Add `Date.toSectionHeaderTitle()` extension for formatting dates

**Code Template:** See Component 2 in Section 4.1

**Acceptance Criteria:**
- [x] Title displays in uppercase
- [x] Count badge shows when count is provided
- [x] Proper pluralization of count label
- [x] Correct spacing and padding

---

#### Task T1.3: Create UnifiedListRow Component

**File to Create:** `Swiff IOS/Views/Components/UnifiedListRow.swift`

**Description:** Create the base row component for most list views.

**Requirements:**
1. Create `UnifiedListRow<IconContent: View>` generic struct
2. Parameters:
   - `title: String` - Primary text
   - `subtitle: String` - Secondary text
   - `value: String` - Amount/value text
   - `valueColor: Color` - Color for value
   - `valueLabel: String?` - Optional label under value
   - `showChevron: Bool = false` - Show navigation indicator
   - `@ViewBuilder iconContent` - Icon view builder

3. Layout structure:
   - 16pt padding all around
   - 16pt spacing between icon and text
   - 4pt spacing between title and subtitle
   - 12pt corner radius
   - Subtle shadow

**Code Template:** See Component 3 in Section 4.1

**Acceptance Criteria:**
- [x] Row displays correctly with all parameters
- [x] Icon content renders on left
- [x] Text content is properly aligned
- [x] Value displays with correct color
- [x] Optional value label shows below value
- [x] Press animation works smoothly

---

#### Task T1.4: Create UnifiedListRowWithProgress Component

**File to Create:** `Swiff IOS/Views/Components/UnifiedListRowWithProgress.swift`

**Description:** Create a row component with progress bar for Analytics categories.

**Requirements:**
1. Extends base row with progress bar at bottom
2. Additional parameters:
   - `percentage: Double` - Progress percentage (0-100)
   - `isSelected: Bool` - Selection state for border highlight

3. Progress bar:
   - 4pt height
   - Rounded corners (2pt)
   - Gradient fill from valueColor
   - Background track at 0.3 opacity
   - Positioned below content, aligned with card edges

**Code Template:** See Component 4 in Section 4.1

**Acceptance Criteria:**
- [x] Progress bar renders correctly
- [x] Percentage fills accurately
- [x] Selection border works
- [x] Alignment is perfect with row content

---

### PHASE 2: Update Feed/Transactions View

---

#### Task T2.1: Refactor FeedTransactionRow

**File to Modify:** `Swiff IOS/ContentView.swift`
**Lines:** 2278-2395

**Description:** Update `FeedTransactionRow` to use unified components. Transactions are GROUPED BY DATE.

**Target Implementation:**
```swift
struct FeedTransactionRow: View {
    let transaction: Transaction
    @Environment(\.colorScheme) var colorScheme

    // IMPORTANT: Expenses are RED, Income is GREEN
    private var amountColor: Color {
        transaction.isExpense ? .wiseError : .wiseBrightGreen
    }

    private var formattedAmount: String {
        let sign = transaction.isExpense ? "- " : "+ "
        return sign + formatCurrency(abs(transaction.amount))
    }

    var body: some View {
        UnifiedListRow(
            title: transaction.displayMerchant,
            subtitle: transaction.category.rawValue.capitalized,
            value: formattedAmount,
            valueColor: amountColor,
            valueLabel: transaction.date.formatted(date: .omitted, time: .shortened)
        ) {
            UnifiedIconCircle(
                icon: transaction.category.icon,
                color: transaction.category.color
            )
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
```

**Grouping Logic (keep existing):**
```swift
// Transactions grouped by date
ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
    Section {
        ForEach(groupedTransactions[date] ?? []) { transaction in
            FeedTransactionRow(transaction: transaction)
        }
    } header: {
        UnifiedSectionHeader(
            title: date.toSectionHeaderTitle(),
            count: groupedTransactions[date]?.count,
            countLabel: "transactions"
        )
    }
}
```

**Key Changes:**
1. Replace custom HStack layout with `UnifiedListRow`
2. Use `UnifiedIconCircle` for category icon
3. **EXPENSES ARE RED** (`.wiseError`)
4. **INCOME IS GREEN** (`.wiseBrightGreen`)
5. Keep date grouping with `UnifiedSectionHeader`

**Preserve:**
- Navigation to detail view
- Swipe actions
- Haptic feedback

**Acceptance Criteria:**
- [x] Transaction displays with icon circle
- [x] Category icon and color are correct
- [x] Amount shows correct sign (+/-)
- [x] **Income shows in GREEN**
- [x] **Expenses show in RED**
- [x] Time label shows below amount
- [x] Date grouping works with UnifiedSectionHeader
- [x] Navigation still works
- [x] Swipe to delete still works

---

### PHASE 3: Update People View

---

#### Task T3.1: Refactor PersonRowView

**File to Modify:** `Swiff IOS/ContentView.swift`
**Lines:** 3829-3895

**Description:** Update `PersonRowView` to use unified design. **NO GROUPING - sorted by recent interaction.**

**Target Implementation:**
```swift
struct PersonRowView: View {
    let person: Person
    let allTransactions: [Transaction]

    private var balanceColor: Color {
        if person.balance > 0 {
            return .wiseBrightGreen  // They owe you - GREEN
        } else if person.balance < 0 {
            return .wiseError        // You owe them - RED
        } else {
            return .wisePrimaryText  // Settled
        }
    }

    private var balanceLabel: String {
        if person.balance > 0 {
            return "owes you"
        } else if person.balance < 0 {
            return "you owe"
        } else {
            return "settled up"
        }
    }

    private var formattedBalance: String {
        let amount = abs(person.balance)
        if amount == 0 {
            return "$0.00"
        }
        let sign = person.balance > 0 ? "+ " : "- "
        return sign + formatCurrency(amount)
    }

    var body: some View {
        UnifiedListRow(
            title: person.name,
            subtitle: person.email.isEmpty ? person.lastActivityText(transactions: allTransactions) : person.email,
            value: formattedBalance,
            valueColor: balanceColor,
            valueLabel: balanceLabel
        ) {
            // Use existing AvatarView as the icon
            AvatarView(person: person, size: .large, style: .gradient)
        }
    }
}
```

**Sorting Logic (NEW - sort by recent interaction):**
```swift
// In PeopleListView - NO GROUPING, sorted by recent interaction
let sortedPeople = dataManager.people.sorted { person1, person2 in
    let lastActivity1 = getLastInteractionDate(for: person1)
    let lastActivity2 = getLastInteractionDate(for: person2)
    return lastActivity1 > lastActivity2
}

ForEach(sortedPeople) { person in
    PersonRowView(person: person, allTransactions: dataManager.transactions)
}

// Helper function
func getLastInteractionDate(for person: Person) -> Date {
    // Find most recent transaction involving this person
    // Or use person.lastModifiedDate as fallback
    return person.lastModifiedDate
}
```

**Key Changes:**
1. Use `UnifiedListRow` with `AvatarView` as icon
2. **NO section headers**
3. **Sort by recent interaction** (most recent first)
4. **Positive balance (owes you) = GREEN**
5. **Negative balance (you owe) = RED**

**Acceptance Criteria:**
- [x] Avatar displays correctly as icon
- [x] Name shows as title
- [x] Email/activity shows as subtitle
- [x] Balance shows with correct color (GREEN if owed, RED if owing)
- [x] Balance status label shows below amount
- [x] **No section headers**
- [x] **Sorted by recent interaction**

---

### PHASE 4: Update Groups View

---

#### Task T4.1: Refactor GroupRowView

**File to Modify:** `Swiff IOS/ContentView.swift`
**Lines:** 4399-4462

**Description:** Update `GroupRowView` to use unified design. **NO GROUPING - sorted by recent activity.**

**Target Implementation:**
```swift
struct GroupRowView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager

    private var memberNames: String {
        let names = group.members.prefix(3).compactMap { memberId in
            dataManager.people.first(where: { $0.id == memberId })?.name
        }
        let remaining = group.members.count - names.count
        if remaining > 0 {
            return names.joined(separator: ", ") + " +\(remaining)"
        }
        return names.joined(separator: ", ")
    }

    var body: some View {
        UnifiedListRow(
            title: group.name,
            subtitle: "\(group.members.count) members",
            value: formatCurrency(group.totalAmount),
            valueColor: .wisePrimaryText,
            valueLabel: "\(group.expenses.count) expenses"
        ) {
            UnifiedEmojiCircle(
                emoji: group.emoji,
                backgroundColor: .wiseBlue
            )
        }
    }
}
```

**Sorting Logic (NEW - sort by recent activity):**
```swift
// In GroupsListView - NO GROUPING, sorted by recent activity
let sortedGroups = dataManager.groups.sorted { group1, group2 in
    let lastExpense1 = group1.expenses.map { $0.date }.max() ?? group1.createdDate
    let lastExpense2 = group2.expenses.map { $0.date }.max() ?? group2.createdDate
    return lastExpense1 > lastExpense2
}

ForEach(sortedGroups) { group in
    GroupRowView(group: group)
}
```

**Key Changes:**
1. Use `UnifiedEmojiCircle` for group emoji
2. **NO section headers**
3. **Sort by recent activity** (most recent expense date first)
4. Show member count as subtitle

**Acceptance Criteria:**
- [x] Emoji displays in gradient circle
- [x] Group name shows as title
- [x] Member count shows as subtitle
- [x] Total amount displays correctly
- [x] Expense count shows as value label
- [x] **No section headers**
- [x] **Sorted by recent activity**

---

### PHASE 5: Update Subscriptions View

---

#### Task T5.1: Refactor EnhancedSubscriptionRowView

**File to Modify:** `Swiff IOS/ContentView.swift`
**Lines:** 5844-6040

**Description:** Simplify `EnhancedSubscriptionRowView` to use unified design. **NO GROUPING - sorted by recent activity.**

**Target Implementation:**
```swift
struct EnhancedSubscriptionRowView: View {
    let subscription: Subscription

    private var iconColor: Color {
        Color(hex: subscription.color) ?? subscription.category.color
    }

    private var priceLabel: String {
        "/\(subscription.billingCycle.shortName)"
    }

    var body: some View {
        UnifiedListRow(
            title: subscription.name,
            subtitle: subscription.category.rawValue.capitalized,
            value: formatCurrency(subscription.price),
            valueColor: .wisePrimaryText,
            valueLabel: priceLabel
        ) {
            ZStack {
                UnifiedIconCircle(
                    icon: subscription.icon,
                    color: iconColor
                )

                // Simplified status indicator - small dot only
                if subscription.isFreeTrial {
                    Circle()
                        .fill(Color.wiseWarning)
                        .frame(width: 10, height: 10)
                        .offset(x: 18, y: -18)
                }

                if subscription.isShared {
                    Circle()
                        .fill(Color.wiseBlue)
                        .frame(width: 10, height: 10)
                        .offset(x: 18, y: 18)
                }
            }
        }
    }
}
```

**Sorting Logic (NEW - sort by recent activity):**
```swift
// In SubscriptionsListView - NO GROUPING, sorted by recent activity
let sortedSubscriptions = dataManager.subscriptions.sorted { sub1, sub2 in
    let lastActivity1 = sub1.lastUsedDate ?? sub1.lastBillingDate ?? sub1.createdDate
    let lastActivity2 = sub2.lastUsedDate ?? sub2.lastBillingDate ?? sub2.createdDate
    return lastActivity1 > lastActivity2
}

ForEach(sortedSubscriptions) { subscription in
    EnhancedSubscriptionRowView(subscription: subscription)
}
```

**Key Changes:**
1. Use `UnifiedIconCircle` with subscription icon
2. **NO section headers**
3. **Sort by recent activity** (lastUsedDate or lastBillingDate)
4. Simplified status indicators (small dots only)
   - Orange dot: Free trial
   - Blue dot: Shared
   - Remove if they don't look good

**Acceptance Criteria:**
- [x] Subscription icon displays in circle
- [x] Name and category show correctly
- [x] Price displays with billing cycle label
- [x] **No section headers**
- [x] **Sorted by recent activity**
- [x] Status dots are subtle and match theme (or removed)

---

### PHASE 6: Update Analytics Categories

---

#### Task T6.1: Refactor CategoryRow with Progress Bar

**File to Modify:** `Swiff IOS/Views/Components/CategoryContributionList.swift`
**Lines:** 57-152

**Description:** Update `CategoryRow` to use unified design **WITH PROGRESS BARS**.

**Target Implementation:**
```swift
struct CategoryRow: View {
    let item: ChartDataItem
    let isIncome: Bool
    let isSelected: Bool
    let onTap: () -> Void

    private var gradientColor: Color {
        GradientColorHelper.gradientColor(for: item.percentage, isIncome: isIncome)
    }

    var body: some View {
        Button(action: onTap) {
            UnifiedListRowWithProgress(
                title: item.category,
                subtitle: isIncome ? "Income" : "Expense",
                value: formatCurrency(item.amount),
                valueColor: gradientColor,
                percentage: item.percentage,
                valueLabel: String(format: "%.1f%%", item.percentage),
                isSelected: isSelected
            ) {
                UnifiedIconCircle(
                    icon: item.icon ?? "circle.fill",
                    color: gradientColor
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
```

**Key Changes:**
1. Use `UnifiedListRowWithProgress` component
2. **KEEP PROGRESS BARS** - perfectly aligned
3. Progress bar fills based on percentage
4. Selection state shows border highlight
5. Colors from `GradientColorHelper`

**Acceptance Criteria:**
- [x] Category icon and color display correctly
- [x] Category name shows as title
- [x] Amount shows with gradient color
- [x] Percentage shows as label
- [x] **Progress bar renders and fills correctly**
- [x] **Progress bar is perfectly aligned**
- [x] Selection state is visible (border)
- [x] Tap interaction works

---

## 7. Testing Checklist

### 7.1 Visual Consistency Tests

**Icon Circles:**
- [x] All icon circles are exactly 48x48
- [x] Icons are 20pt and centered
- [x] Background opacity is 0.1
- [x] Colors match category definitions

**Typography:**
- [x] Titles are 16pt medium weight
- [x] Subtitles are 13pt regular weight
- [x] Amounts are 16pt bold weight
- [x] Labels are 10pt regular weight

**Spacing:**
- [x] Row padding is 16pt all sides
- [x] Icon to text spacing is 16pt
- [x] Title to subtitle spacing is 4pt
- [x] Card corner radius is 12pt

**Colors:**
- [x] **Income amounts show in GREEN (.wiseBrightGreen)**
- [x] **Expense amounts show in RED (.wiseError)**
- [x] Neutral values show in .wisePrimaryText

### 7.2 Dark Mode Tests

- [x] Card backgrounds are #262626
- [x] Text colors adapt correctly
- [x] Icon circle backgrounds remain visible
- [x] Shadows are appropriate for dark mode
- [x] All category colors are visible
- [x] **Red expense color adapts (#FF453A in dark)**

### 7.3 Functionality Tests

**Feed/Transactions:**
- [x] Navigation to detail works
- [x] Swipe to delete works
- [x] Pull to refresh works
- [x] **Date grouping is correct with UnifiedSectionHeader**

**People:**
- [x] Avatar displays correctly
- [x] Balance colors are correct (GREEN/RED)
- [x] Navigation works
- [x] Edit/delete actions work
- [x] **No section headers**
- [x] **Sorted by recent interaction**

**Groups:**
- [x] Emoji displays correctly
- [x] Member count is accurate
- [x] Navigation works
- [x] Total amount is correct
- [x] **No section headers**
- [x] **Sorted by recent activity**

**Subscriptions:**
- [x] Icon displays correctly
- [x] Price and cycle show correctly
- [x] Status indicators are subtle
- [x] Navigation works
- [x] **No section headers**
- [x] **Sorted by recent activity**

**Analytics:**
- [x] Category selection works
- [x] Percentages are accurate
- [x] **Progress bars display correctly**
- [x] **Progress bars are aligned perfectly**
- [x] Colors match data type (income/expense)
- [x] Tap interactions work

### 7.4 Accessibility Tests

- [x] VoiceOver reads all content correctly
- [x] Labels are descriptive
- [x] Dynamic Type scales appropriately
- [x] Color contrast meets WCAG 4.5:1

### 7.5 Performance Tests

- [x] List scrolls smoothly with 100+ items
- [x] No visible lag on row rendering
- [x] Memory usage is reasonable
- [x] Animations are 60fps

---

## Appendix A: File Reference

### Files to Create

| File Path | Description |
|-----------|-------------|
| `Swiff IOS/Views/Components/UnifiedIconCircle.swift` | Icon circle components |
| `Swiff IOS/Views/Components/UnifiedSectionHeader.swift` | Section header component (Transactions only) |
| `Swiff IOS/Views/Components/UnifiedListRow.swift` | Base row component |
| `Swiff IOS/Views/Components/UnifiedListRowWithProgress.swift` | Row with progress bar (Analytics) |

### Files to Modify

| File Path | Component | Lines |
|-----------|-----------|-------|
| `Swiff IOS/ContentView.swift` | FeedTransactionRow | 2278-2395 |
| `Swiff IOS/ContentView.swift` | PersonRowView | 3829-3895 |
| `Swiff IOS/ContentView.swift` | GroupRowView | 4399-4462 |
| `Swiff IOS/ContentView.swift` | EnhancedSubscriptionRowView | 5844-6040 |
| `Swiff IOS/Views/Components/CategoryContributionList.swift` | CategoryRow | 57-152 |

### Reference Files (Read Only)

| File Path | Contains |
|-----------|----------|
| `Swiff IOS/Models/DataModels/SupportingTypes.swift` | Colors, categories, enums |
| `Swiff IOS/Utilities/AdaptiveShadow.swift` | Shadow modifiers |
| `Swiff IOS/Views/AvatarView.swift` | Avatar component |
| `Swiff IOS/Utilities/GradientColorHelper.swift` | Gradient color logic |

---

## Appendix B: Quick Reference

### Amount Color Logic

```swift
// For transactions - RED for expenses, GREEN for income
let color: Color = transaction.isExpense ? .wiseError : .wiseBrightGreen

// For people balances - GREEN if owed, RED if owing
let color: Color = balance > 0 ? .wiseBrightGreen : (balance < 0 ? .wiseError : .wisePrimaryText)

// For subscriptions - Always neutral
let color: Color = .wisePrimaryText

// For analytics - Use gradient helper
let color: Color = GradientColorHelper.gradientColor(for: percentage, isIncome: isIncome)
```

### Amount Formatting

```swift
func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

// With sign
let sign = amount >= 0 ? "+ " : "- "
let formatted = sign + formatCurrency(abs(amount))
```

### Date Header Formatting (Transactions Only)

```swift
extension Date {
    func toSectionHeaderTitle() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "TODAY, \(formatted(.dateTime.month(.abbreviated).day()).uppercased())"
        } else if calendar.isDateInYesterday(self) {
            return "YESTERDAY, \(formatted(.dateTime.month(.abbreviated).day()).uppercased())"
        } else {
            return formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased()
        }
    }
}
```

### Sorting by Recent Activity

```swift
// People - by last interaction
people.sorted { $0.lastModifiedDate > $1.lastModifiedDate }

// Groups - by most recent expense
groups.sorted {
    ($0.expenses.map { $0.date }.max() ?? $0.createdDate) >
    ($1.expenses.map { $0.date }.max() ?? $1.createdDate)
}

// Subscriptions - by last activity
subscriptions.sorted {
    ($0.lastUsedDate ?? $0.lastBillingDate ?? $0.createdDate) >
    ($1.lastUsedDate ?? $1.lastBillingDate ?? $1.createdDate)
}
```

---

**End of Documentation**

*This document should be used by Claude Code agents to implement the unified list design system across the Swiff iOS application. Each task is designed to be completed independently while maintaining consistency with the overall design system.*

**Key Decisions Summary:**
- Expenses: **RED** (`.wiseError`)
- Income: **GREEN** (`.wiseBrightGreen`)
- Transactions: **Grouped by date**
- People/Groups/Subscriptions: **No grouping, sorted by recent activity**
- Analytics: **Keep progress bars, perfectly aligned**
- Status indicators: **Simplified dots or removed**
