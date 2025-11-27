# Swiff iOS UI Design System

## Overview
This document defines the complete UI design system for Swiff iOS, ensuring consistency, quality, and a Spotify-inspired user experience across all screens.

---

## 1. Color Palette

### Primary Colors (Wise Brand)
```swift
wiseForestGreen: RGB(0.086, 0.200, 0.0) - #163300
wiseBrightGreen: RGB(0.624, 0.910, 0.439) - #9FE870
wiseBackground: RGB(1.0, 1.0, 1.0) - #FFFFFF
wisePrimaryText: RGB(0.102, 0.102, 0.102) - #1A1A1A
wiseSecondaryText: RGB(0.235, 0.235, 0.235) - #3C3C3C
```

### Accent Colors
```swift
wiseBlue: RGB(0.0, 0.725, 1.0) - #00B9FF
wiseAccentBlue: RGB(0.0, 0.478, 1.0) - #007AFF
wiseError: RGB(1.0, 0.267, 0.212) - #FF4436
wiseOrange: RGB(1.0, 0.596, 0.0) - #FF9800
wisePurple: RGB(0.612, 0.337, 0.835) - #9C56D5
```

### UI Colors
```swift
wiseBorder: RGB(0.941, 0.945, 0.953) - #F0F1F3
wiseCardBackground: RGB(0.980, 0.984, 0.992) - #FAFBFD
wiseMidGray: RGB(0.600, 0.600, 0.600) - #999999
```

### Color Usage Guidelines
- **Primary Actions**: Use `wiseBrightGreen` for primary buttons and CTAs
- **Headers/Navigation**: Use `wiseForestGreen` for headers and important text
- **Cards**: White background with subtle shadows
- **Success States**: Use `wiseBrightGreen`
- **Error States**: Use `wiseError`
- **Information**: Use `wiseBlue`
- **Neutral**: Use gray scale (wiseMidGray, wiseSecondaryText)

---

## 2. Typography (Spotify-Inspired)

### Font Family
**Primary**: Helvetica Neue (system default weight variants)

### Text Styles

#### Display Styles
- **Display Large**: 32px, Black weight - For main screen titles
- **Display Medium**: 24px, Bold - For section headings

#### Heading Styles
- **Heading Large**: 20px, Bold - For card titles
- **Heading Medium**: 18px, Bold - For subsection titles

#### Body Styles
- **Body Large**: 16px, Medium - For primary content
- **Body Medium**: 14px, Medium - For secondary content

#### Label Styles
- **Label Large**: 14px, Semibold - For button labels
- **Label Small**: 12px, Semibold - For uppercase labels

#### Number Styles
- **Number Large**: 24px, Black - For large amounts (balance, totals)
- **Number Medium**: 18px, Bold - For medium amounts

### Usage Examples
```swift
// Screen Title
Text("Home").font(.spotifyDisplayLarge)

// Card Title
Text("BALANCE").font(.spotifyLabelSmall).textCase(.uppercase)

// Amount
Text("$1,234.56").font(.spotifyNumberLarge)

// Body Text
Text("Last updated 2 hours ago").font(.spotifyBodyMedium)
```

---

## 3. Standardized Card Format

### Base Card Design
All statistics and content cards across the app must follow this standard:

```swift
VStack(alignment: .leading, spacing: 12) {
    // Icon (optional)
    Image(systemName: "iconName")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.wiseForestGreen)

    // Label (uppercase)
    Text("CARD TITLE")
        .font(.spotifyLabelSmall)
        .textCase(.uppercase)
        .foregroundColor(.wiseSecondaryText)

    // Main Value
    Text("$1,234.56")
        .font(.spotifyNumberLarge)
        .foregroundColor(.wisePrimaryText)

    // Trend/Subtitle (optional)
    HStack(spacing: 4) {
        Image(systemName: "arrow.up")
        Text("+5.2%")
    }
    .font(.caption)
    .foregroundColor(.wiseBrightGreen)
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(16)
.background(Color.white)
.cornerRadius(12)
.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
```

### Card Specifications
- **Background**: Pure white (#FFFFFF)
- **Corner Radius**: 12px
- **Padding**: 16px internal
- **Shadow**: Black 0.05 opacity, 8px radius, (0, 2) offset
- **Border**: None (use shadow only)

### Card Layouts

#### 2x2 Grid Layout (Home Screen Standard)
```swift
LazyVGrid(columns: [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
], spacing: 12) {
    // 4 cards
}
.padding(.horizontal, 16)
```

#### Horizontal Scroll Cards
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        // Multiple cards
    }
    .padding(.horizontal, 16)
}
```

#### Full-Width Cards
```swift
VStack(spacing: 12) {
    // Stacked cards
}
.padding(.horizontal, 16)
```

---

## 4. Button System (Spotify-Inspired)

### Primary Action Button
Large, prominent button for main actions

```swift
Button(action: {}) {
    HStack(spacing: 8) {
        Image(systemName: "plus.circle.fill")
            .font(.system(size: 18, weight: .semibold))
        Text("Add")
            .font(.spotifyLabelLarge)
    }
    .foregroundColor(.white)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(
        LinearGradient(
            gradient: Gradient(colors: [.wiseForestGreen, Color(red: 0.05, green: 0.15, blue: 0.0)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .cornerRadius(25)
    .shadow(color: Color.wiseForestGreen.opacity(0.3), radius: 4, x: 0, y: 2)
}
.scaleEffect(isPressed ? 0.96 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
```

**Specifications**:
- Height: 44px (minimum touch target)
- Padding: 20px horizontal, 12px vertical
- Icon size: 18px
- Text: spotifyLabelLarge
- Background: Gradient (wiseForestGreen to darker)
- Shadow: wiseForestGreen 0.3 opacity
- Animation: Scale 0.96 on press

### Header Action Button
Smaller button for header placement (next to search)

```swift
Button(action: {}) {
    Image(systemName: "plus.circle.fill")
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(.wiseForestGreen)
}
.scaleEffect(isPressed ? 0.9 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
```

**Specifications**:
- Icon size: 24px
- Color: wiseForestGreen
- No background (transparent)
- Animation: Scale 0.9 on press

### Floating Action Button (FAB)
Prominent circular button for primary screen action

```swift
Button(action: {}) {
    Image(systemName: "plus")
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(.white)
}
.frame(width: 60, height: 60)
.background(
    LinearGradient(
        gradient: Gradient(colors: [.wiseForestGreen, .wiseBrightGreen]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
.clipShape(Circle())
.shadow(color: Color.wiseBrightGreen.opacity(0.4), radius: 8, x: 0, y: 4)
.scaleEffect(isPressed ? 0.9 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
```

**Specifications**:
- Size: 60x60px circle
- Background: Gradient (wiseForestGreen to wiseBrightGreen)
- Icon: Plus, 24px, white
- Shadow: wiseBrightGreen 0.4 opacity, 8px radius
- Position: 24px from trailing edge, 90px from bottom
- Animation: Scale 0.9 on press

### Filter Pill Button
Capsule-shaped button for filters and categories

```swift
Button(action: {}) {
    Text("Filter")
        .font(.spotifyBodyMedium)
        .foregroundColor(isSelected ? .white : .wisePrimaryText)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.5))
        .cornerRadius(20)
}
.animation(.easeInOut(duration: 0.2), value: isSelected)
```

**Specifications**:
- Capsule shape (corner radius: 20px)
- Padding: 16px horizontal, 8px vertical
- Selected: wiseForestGreen background, white text
- Unselected: wiseBorder background, wisePrimaryText
- Smooth transition: 0.2s easeInOut

---

## 5. Screen Layout Standards

### Navigation Header
Every screen should have consistent header layout:

```swift
HStack {
    // Left: Profile/Back button (optional)
    Button(action: {}) {
        Image(systemName: "person.circle")
            .font(.system(size: 24))
    }

    Spacer()

    // Center: Logo or Title
    Text("Swiff.")
        .font(.custom("Helvetica Neue", size: 28))
        .fontWeight(.bold)
        .foregroundColor(.wiseForestGreen)

    Spacer()

    // Right: Search + Action buttons
    HStack(spacing: 16) {
        Button(action: {}) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
        }

        Button(action: {}) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
        }
    }
}
.padding(.horizontal, 16)
.padding(.vertical, 12)
```

**Specifications**:
- Height: ~50px
- Horizontal padding: 16px
- Vertical padding: 12px
- Icon sizes: 20-24px
- Spacing between right icons: 16px

### Content Area
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 20) {
        // Screen content sections
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 100) // Space for tab bar
}
```

**Specifications**:
- Horizontal padding: 16px
- Top padding: 8px
- Bottom padding: 100px (tab bar clearance)
- Section spacing: 20px

### Tab Bar
```swift
TabView(selection: $selectedTab) {
    // Tab content
}
.accentColor(.wisePrimaryText)
```

**Specifications**:
- Background: Transparent
- Selected color: wisePrimaryText (black)
- Unselected: wisePrimaryText opacity 0.6
- Icon size: 24px
- Label: spotifyLabelSmall

---

## 6. Statistics Card Types

### Type A: Balance/Amount Card
Shows monetary value with trend

**Components**:
- Icon (16px, wiseForestGreen)
- Label (UPPERCASE, spotifyLabelSmall, wiseSecondaryText)
- Amount (spotifyNumberLarge, wisePrimaryText)
- Trend badge (optional: icon + percentage)

### Type B: Count Card
Shows numerical count

**Components**:
- Icon (16px, colored)
- Label (UPPERCASE)
- Count (spotifyNumberLarge)
- Subtitle (optional: additional info)

### Type C: Status Card
Shows status with badge

**Components**:
- Icon (16px, colored background circle)
- Label (UPPERCASE)
- Value (spotifyNumberLarge)
- Status badge (capsule, colored)

---

## 7. Chart Design Standards

### Pie Chart Specifications
For Analytics/Statistics page

```swift
Chart {
    ForEach(data) { item in
        SectorMark(
            angle: .value("Amount", item.amount),
            innerRadius: .ratio(0.5),
            angularInset: 2.0
        )
        .cornerRadius(4)
        .foregroundStyle(by: .value("Category", item.category))
    }
}
.chartForegroundStyleScale([
    "Category1": Color.wiseBlue,
    "Category2": Color.wiseBrightGreen,
    "Category3": Color.wiseOrange,
    "Category4": Color.wisePurple
])
.frame(height: 220)
```

**Specifications**:
- Inner radius: 0.5 (donut style)
- Angular inset: 2.0 (spacing between sections)
- Corner radius: 4px
- Height: 220px
- Colors: Use Wise brand accent colors
- Legend: Bottom or side, spotifyBodyMedium

### Chart Color Palette
```swift
let chartColors: [Color] = [
    .wiseBlue,
    .wiseBrightGreen,
    .wiseOrange,
    .wisePurple,
    Color(red: 0.3, green: 0.7, blue: 0.9), // Light blue
    Color(red: 0.8, green: 0.4, blue: 0.6), // Pink
]
```

---

## 8. Animation Standards

### Spring Animation
Default for interactive elements

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
```

**Specifications**:
- Response: 0.3 seconds
- Damping: 0.7 (slightly bouncy)
- Use for: Button presses, selections

### Ease Animation
For state transitions

```swift
.animation(.easeInOut(duration: 0.2), value: state)
```

**Specifications**:
- Duration: 0.2 seconds
- Use for: Color changes, opacity, filter selections

### Scale Effects
```swift
.scaleEffect(isPressed ? 0.96 : 1.0)
```

**Specifications**:
- Button press: 0.96 (subtle)
- FAB press: 0.9 (more pronounced)
- Small icons: 0.9

---

## 9. Spacing System

### Padding Scale
```swift
4px  - Tiny (between icon and text in small components)
8px  - Small (within compact elements)
12px - Medium (card internal spacing)
16px - Large (screen horizontal padding, between cards)
20px - Extra Large (between major sections)
24px - Huge (special spacing for FAB positioning)
```

### Margin Scale
```swift
8px  - Between related elements
12px - Between cards in grid
16px - Screen edges
20px - Between major sections
```

---

## 10. Icon System

### Icon Sizes
```swift
16px - Small icons in cards
20px - Medium icons in headers
24px - Large icons for primary actions
28px - Extra large for important actions
48px - Avatar size
```

### Icon Weights
- Use `.semibold` for most icons
- Use `.regular` for decorative icons
- Use `.bold` for emphasis

### Icon Colors
- Primary actions: wiseForestGreen
- Secondary actions: wisePrimaryText
- Destructive: wiseError
- Success: wiseBrightGreen
- Information: wiseBlue

---

## 11. Shadow System

### Card Shadow
```swift
.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
```

### Button Shadow
```swift
.shadow(color: Color.wiseForestGreen.opacity(0.3), radius: 4, x: 0, y: 2)
```

### FAB Shadow
```swift
.shadow(color: Color.wiseBrightGreen.opacity(0.4), radius: 8, x: 0, y: 4)
```

---

## 12. Screen-Specific Guidelines

### Home Screen
- 2x2 grid of statistics cards (Balance, Subscriptions, Income, Expenses)
- Floating action button: bottom-right, 24px from edge
- Recent activity section with horizontal scroll
- Top subscriptions list
- Insights card

### Feed Screen
- Header with search + add button (NO Select button)
- Statistics cards (Balances, Subscriptions, Common Expenses) - same format as home
- Category filter pills
- Transaction list grouped by date

### People Screen
- Header with search + add button (NO floating button)
- Balance summary cards (Owed to You, You Owe, People Count)
- Segmented control (People/Groups)
- Filter pills
- Person/Group list

### Subscriptions Screen
- Header with search + add button (NO floating button)
- Segmented control (Personal/Shared)
- Quick stats cards (2x2 grid)
- Category filter pills
- Subscription list with status badges

### Analytics/Statistics Screen
- Date range selector (pills)
- Pie charts ONLY (no line graphs)
- Charts: Income breakdown, Expense breakdown, Bill splitting
- Detailed statistics cards
- Savings opportunities section
- NO overlapping icons or elements

---

## 13. Accessibility

### Touch Targets
- Minimum size: 44x44px
- Spacing: 8px minimum between targets

### Contrast
- Text on white: Use wisePrimaryText (black)
- Text on dark: Use white
- Ensure WCAG AA compliance

### Dynamic Type
- Support system font scaling
- Use `.font(.spotifyBodyMedium)` (scales automatically)

---

## 14. Component Reusability

### Created Components
1. **StatisticsCardComponent** - Reusable card for all screens
2. **SpotifyButtonComponent** - Standardized buttons
3. **CustomPieChartView** - Pie chart for analytics
4. **HeaderActionButton** - Header "+" buttons
5. **FilterPillButton** - Filter pills
6. **TrendBadge** - Trend indicators

### Usage
Import and use across all views for consistency:
```swift
StatisticsCardComponent(
    icon: "dollarsign.circle",
    title: "BALANCE",
    value: "$1,234.56",
    trend: .positive(5.2)
)
```

---

## 15. Quality Checklist

Before marking any screen complete, verify:

- [ ] All cards use standardized format
- [ ] Buttons match Spotify-inspired design
- [ ] Colors match Wise brand palette exactly
- [ ] Fonts use Helvetica Neue with correct weights
- [ ] Animations are smooth (0.3s spring)
- [ ] No overlapping UI elements
- [ ] Proper spacing (16px screen edges, 12px between cards)
- [ ] All interactive elements have touch targets ≥44px
- [ ] Shadows applied correctly
- [ ] Icons sized appropriately (16-24px)
- [ ] All functionality works
- [ ] Tested on multiple device sizes

---

## Version
**Document Version**: 1.0
**Last Updated**: 2025-01-22
**Status**: Active Design System
