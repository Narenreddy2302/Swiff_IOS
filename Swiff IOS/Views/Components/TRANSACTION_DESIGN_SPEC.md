//
//  TRANSACTION_DESIGN_SPEC.md
//  Swiff IOS
//
//  Detailed specification for the new transaction design
//

# Transaction Design Specification

## Visual Layout

```
┌─────────────────────────────────────────────────────┐
│  TODAY                                              │  ← Section Header (13pt, uppercase, gray)
│  ┌───────────────────────────────────────────────┐ │
│  │ ┌────┐  Mikel Borle           +$350.00       │ │  ← Transaction Row
│  │ │ MB │  10:30 AM               Receive        │ │
│  │ └────┘                                        │ │
│  │ ─────────────────────────────────────────────│ │  ← Divider (84pt left offset)
│  │ ┌────┐  Uber                   -$10.00       │ │
│  │ │ [U]│  08:25 AM               Transfer      │ │
│  │ └────┘                                        │ │
│  │ ─────────────────────────────────────────────│ │
│  │ ┌────┐  Ryan Scott             -$124.00      │ │
│  │ │ RS │  09:45 AM               Send          │ │
│  │ └────┘                                        │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Yesterday                                          │
│  ┌───────────────────────────────────────────────┐ │
│  │ ... more transactions ...                     │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Measurements

### Avatar
- **Size**: 56 × 56 pt
- **Shape**: Circle
- **Content**: 2-letter initials
- **Font**: System Semibold 20pt
- **Text Color**: White (always)
- **Background**: Hash-based color from palette

### Spacing
```
Horizontal Layout:
[16pt]─[Avatar 56pt]─[12pt]─[Text Content]─[flexible]─[Amount Content]─[16pt]

Vertical Layout:
[12pt]
  [Title 17pt]
  [4pt]
  [Subtitle 15pt]
[12pt]
```

### Typography Scale
| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Transaction Name | 17pt | Semibold | Black |
| Time | 15pt | Regular | Gray (142,142,147) |
| Amount | 17pt | Semibold | Green/Black |
| Status | 15pt | Regular | Gray (142,142,147) |
| Section Header | 13pt | Semibold | Gray (142,142,147) |

### Color Palette

#### Avatar Colors (Hash-based)
```swift
let colors: [Color] = [
    Color(red: 52/255, green: 120/255, blue: 120/255),   // Teal
    Color(red: 28/255, green: 28/255, blue: 30/255),     // Black
    Color(red: 233/255, green: 30/255, blue: 99/255),    // Pink
    Color(red: 76/255, green: 76/255, blue: 76/255),     // Gray
    Color(red: 88/255, green: 86/255, blue: 214/255),    // Purple
    Color(red: 255/255, green: 149/255, blue: 0/255),    // Orange
]
```

#### Text Colors
```swift
// Primary Text (Transaction Names)
Color.black  // rgb(0, 0, 0)

// Secondary Text (Time, Status)
Color(red: 142/255, green: 142/255, blue: 147/255)  // iOS Gray

// Income Amount
Color(red: 52/255, green: 199/255, blue: 89/255)  // iOS Green

// Expense Amount
Color.black  // rgb(0, 0, 0)
```

#### Background Colors
```swift
// Card Background
Color.white  // rgb(255, 255, 255)

// Page Background
Color(red: 242/255, green: 242/255, blue: 247/255)  // iOS Grouped Background
```

## Component Hierarchy

```
TransactionSection
├── TransactionGroupHeader
│   └── Text (Section Date)
└── Card Container
    └── ForEach(transactions)
        ├── UniversalListRow
        │   ├── Avatar (Circle + Initials)
        │   ├── VStack (Title + Time)
        │   └── VStack (Amount + Status)
        └── Divider (if not last)
```

## State Management

### Transaction Properties Used
```swift
struct Transaction {
    let title: String           // → Transaction Name
    let date: Date             // → Time (10:30 AM)
    let amount: Double         // → Amount (±$350.00)
    let isExpense: Bool        // → Color (Green/Black)
    let category: Category     // → Status Label Logic
    let merchant: String?      // → Avatar Text Source
}
```

### Computed Values
```swift
// Avatar
let initials = InitialsGenerator.generate(from: title)
let color = avatarColorForTransaction(transaction)

// Time
let formatter = DateFormatter()
formatter.dateFormat = "hh:mm a"  // "10:30 AM"
let time = formatter.string(from: date)

// Amount
let sign = isExpense ? "-" : "+"
let formatted = formatCurrency(abs(amount))
let display = "\(sign)$\(formatted)"

// Status
let status = isExpense ? statusForCategory(category) : "Receive"
```

## Interaction States

### Default State
- White background
- Black/Gray text
- No shadow

### Tap/Press State
- Brief opacity change (0.7)
- Haptic feedback (light)
- Transition to detail view

### Swipe State (Future)
- Reveal actions on left/right swipe
- Delete, Edit, Share options

## Accessibility

### VoiceOver
```
"Mikel Borle, received $350.00 at 10:30 AM, today"
"Uber, paid $10.00 at 8:25 AM, today"
```

### Dynamic Type
- Respects user text size preferences
- Layout adjusts for larger text
- Minimum avatar size: 44pt (if scaled down)

### Color Contrast
- All text meets WCAG AA standards
- 4.5:1 contrast ratio minimum
- Avatar text always white on colored background

## Animation Guidelines

### List Animations
```swift
// Appear
.transition(.opacity.combined(with: .move(edge: .top)))
.animation(.easeOut(duration: 0.3))

// Delete
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .move(edge: .leading)
))
.animation(.spring(response: 0.3, dampingFraction: 0.8))
```

### Scroll Behavior
- Smooth 60fps scrolling
- Section headers stick on scroll
- Pull-to-refresh indicator at top

## Platform Variations

### iOS
- White cards on gray background (current design)
- Section headers uppercase
- 12pt corner radius

### iPadOS
- Same design, larger content area
- Multi-column layout in landscape
- Sidebar navigation integration

### macOS (Future)
- Light border instead of shadow
- Hover states
- Click for detail

## Implementation Checklist

✅ UniversalListRow component updated
✅ ListRowFactory logic updated
✅ TransactionSection component created
✅ TransactionGroupHeader redesigned
✅ Color palette implemented
✅ Typography scale applied
✅ Spacing measurements correct
✅ Time formatting (hh:mm a)
✅ Status labels contextual
✅ Avatar system with initials
✅ White cards on gray background
✅ Divider alignment (84pt)
✅ Section header styling
✅ Preview updates

## Testing Scenarios

### Visual Tests
1. **Single transaction**: Proper spacing, alignment
2. **Multiple transactions**: Dividers align correctly
3. **Long names**: Text truncation works
4. **Large amounts**: Number formatting correct
5. **Section headers**: Date formatting accurate

### Edge Cases
1. **Empty state**: No transactions to display
2. **Single item**: No divider shown
3. **Many items**: Smooth scrolling maintained
4. **Mixed dates**: Sections group correctly
5. **Midnight transactions**: Time displays correctly

### Interaction Tests
1. **Tap transaction**: Detail view opens
2. **Scroll list**: Smooth 60fps
3. **Pull to refresh**: Updates data
4. **VoiceOver**: Reads correctly
5. **Dark mode**: Colors adapt (if supported)

---

**This specification ensures consistent, professional transaction displays across the entire app.**
