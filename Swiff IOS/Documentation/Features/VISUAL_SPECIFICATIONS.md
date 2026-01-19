# 📐 Visual Design Specifications

## Component Anatomy

This document provides detailed visual specifications for all conversation view components.

---

## 🎴 Transaction Card Anatomy

```
┌──────────────────────────────────────────────────────┐
│  ┌───┐                                               │ ← 16pt padding
│  │ ● │  Payment to Li Wei                  $250.00  │
│  └───┘  You Lent                                     │
│   40pt                                                │
│                                                       │
│  ───────────────────────────────────────────────────│ ← Divider
│                                                       │
│  Total Bill                               $250.00   │ ← Metadata Row
│  ───────────────────────────────────────────────────│
│  Paid by                                       You   │
│  ───────────────────────────────────────────────────│
│  Split Method                             Equally   │
│  ───────────────────────────────────────────────────│
│  Participants                          You, Li Wei   │
│                                                       │
└──────────────────────────────────────────────────────┘
 12pt corner radius, 1pt border, 2pt shadow
```

### Measurements

**Card Container**:
- Corner radius: 12pt
- Border: 1pt, opacity 0.1
- Shadow: 2pt blur, 1pt Y offset, black at 4% opacity
- Max width: 320pt
- Padding: 16pt all sides

**Header Section**:
- Icon circle: 40pt diameter
- Icon: 20pt SF Symbol
- Title font: 16pt semibold
- Amount font: 17pt semibold
- Label font: 13pt regular
- Spacing: 12pt between elements

**Metadata Rows**:
- Height: 44pt minimum (touch target)
- Label font: 14pt regular, secondary color
- Value font: 14pt medium, primary color
- Padding: 12pt vertical, 16pt horizontal
- Divider: Full width with 16pt leading padding

---

## 💬 Message Bubble Anatomy

```
INCOMING (Left-aligned):
┌──────────────────────────────────┐
│  Hey! Want to grab lunch?        │ ← 14pt H, 10pt V padding
└───┘                               
   Tail (8pt height)

OUTGOING (Right-aligned):
                 ┌──────────────────────────────────┐
                 │        Sure! How about Thursday? │
                                                   └───┘
                                                    Tail
```

### Measurements

**Bubble Container**:
- Corner radius: 18pt
- Max width: 75% of screen
- Tail height: 8pt
- Tail width: 10pt

**Bubble Content**:
- Padding: 14pt horizontal, 10pt vertical
- Font: 16pt regular
- Line spacing: 1.2x

**Spacing**:
- Same sender: 2pt between bubbles
- Different sender: 16pt between groups
- Horizontal margin: 12pt from screen edge

**Colors**:
- Outgoing: #007AFF (iMessage blue)
- Incoming: #E9E9EB (iMessage gray)
- Text (outgoing): White
- Text (incoming): Black/Primary

---

## 🏷️ System Message Anatomy

```
         ┌───────────────────────────────────────┐
         │ ✓  You created the transaction        │ ← 12pt H, 6pt V padding
         └───────────────────────────────────────┘
         11pt icon      12pt semibold text
```

### Measurements

**Container**:
- Corner radius: 12pt
- Background: Secondary text at 6% opacity
- Padding: 12pt horizontal, 6pt vertical
- Centered horizontally

**Content**:
- Icon: 11pt SF Symbol
- Text: 12pt medium
- Color: Secondary text
- Spacing: 8pt between icon and text

---

## 📅 Date Header Anatomy

```
                    January 4
                    11pt semibold
            Secondary label color
```

### Measurements

**Header**:
- Font: 11pt semibold
- Color: Secondary label (system color)
- Padding: 24pt vertical
- Centered horizontally

**Spacing**:
- 24pt above first item
- 24pt below to first item

---

## 🎨 Balance Banner Anatomy

```
┌─────────────────────────────────────────────────────────┐
│  💲  You are owed $500.00                     ─────────│ ← 8% opacity tint
└─────────────────────────────────────────────────────────┘
   14pt icon    14pt semibold text
```

### Measurements

**Banner**:
- Height: Flexible (content + padding)
- Padding: 16pt horizontal, 10pt vertical
- Background: Balance color at 8% opacity
- Full width

**Content**:
- Icon: 14pt SF Symbol
- Text: 14pt semibold
- Spacing: 8pt between icon and text

**Colors**:
- You owe: Red background tint, red text
- They owe: Green background tint, green text
- Settled: Gray background tint, gray text

---

## 🎛️ Input Bar Anatomy

```
┌─────────────────────────────────────────────────────────┐ ← Ultra thin material
│                                                           │
│  ⊕  ┌─────────────────────────────┐  ↑                 │
│ 28pt│  iMessage                   │ 28pt               │
│     └─────────────────────────────┘                     │
│  12pt spacing    20pt corner radius                     │
└─────────────────────────────────────────────────────────┘
```

### Measurements

**Container**:
- Background: Ultra thin material
- Padding: 12pt horizontal, 8pt vertical
- Top divider: 1pt

**Buttons**:
- Size: 28pt SF Symbols
- Touch target: 44pt minimum
- Add button: Green (#00C853)
- Send button: Blue (#007AFF)
- Scroll button: Gray (secondary)

**Text Field**:
- Corner radius: 20pt
- Background: Secondary at 8% opacity
- Padding: 12pt horizontal, 8pt vertical
- Font: 16pt regular
- Placeholder: "iMessage"

**Spacing**:
- Between elements: 12pt

---

## 📏 Spacing System

### 8pt Grid System

All spacing follows multiples of 8pt:

```
Spacing Scale:
2pt   ▪        Grouped messages (exception to 8pt rule)
8pt   ▪▪       Small spacing (button padding)
12pt  ▪▪▪      Standard spacing (between elements)
16pt  ▪▪▪▪     Large spacing (sections)
24pt  ▪▪▪▪▪▪   Extra large (date headers)
```

### Vertical Rhythm

```
Date Header           ← 24pt padding
Message               ← 2pt (same sender)
Message               ← 16pt (different sender)
Transaction Card      ← 16pt
System Message        ← 16pt
Transaction Card      ← 16pt
Message               ← 16pt
Date Header           ← 24pt padding
```

---

## 🎨 Color Palette

### Transaction Types

```
Payment:  ● #00C853  wiseBrightGreen   (Sent money)
Request:  ● #FF9800  wiseOrange         (Requesting)
Split:    ● #2196F3  wiseBlue           (Bill split)
Expense:  ● #1976D2  wiseAccentBlue     (Group expense)
```

### Balance States

```
Positive: ● #00C853  wiseBrightGreen   (They owe you)
Negative: ● #F44336  wiseError          (You owe them)
Settled:  ● #757575  wiseSecondaryText  (All settled)
```

### Message Bubbles

```
Outgoing: ● #007AFF  iMessageBlue      (Your messages)
Incoming: ● #E9E9EB  iMessageGray      (Their messages)
```

### Semantic Colors

```
Primary Text:    ● #000000/#FFFFFF  (Light/Dark adaptive)
Secondary Text:  ● #666666/#AAAAAA  (Light/Dark adaptive)
Card Background: ● #FFFFFF/#1C1C1E  (Light/Dark adaptive)
Divider:         ● #E0E0E0/#38383A  (Light/Dark adaptive)
```

---

## 🎭 States & Interactions

### Transaction Card

**States**:
- Default: White background, subtle shadow
- Pressed: Scale 0.98, opacity 0.8
- Disabled: Opacity 0.5

**Animations**:
- Appear: Scale from 0.95, fade in, 0.3s ease-out
- Tap: Spring animation, response 0.3, damping 0.7

### Input Bar

**States**:
- Empty field: Shows scroll button
- With text: Shows send button
- Focused: Keyboard visible

**Animations**:
- Button swap: Scale + opacity, 0.2s ease-in-out
- Send: Scale pulse, haptic feedback

### Balance Banner

**States**:
- You owe: Red tint background
- They owe: Green tint background
- Settled: Gray tint background

**Animations**:
- Update: Crossfade 0.3s

---

## ♿️ Accessibility Specs

### Touch Targets

All interactive elements: **44pt minimum**

```
Back button:        44×44pt ✓
Info button:        44×44pt ✓
Add button:         44×44pt ✓
Send button:        44×44pt ✓
Transaction card:   Full card area ✓
```

### VoiceOver Labels

**Header**:
- Back: "Back. Button. Double tap to go back."
- Info: "Group info. Button. Double tap to show details."

**Input**:
- Add: "Add transaction. Button. Create a new payment or split."
- Send: "Send message. Button. Double tap to send."

**Transaction Card**:
- Full context: "Payment to Li Wei. $250.00. You lent. Total bill $250.00..."

### Dynamic Type

All text scales with system font size:
- Use `.font(.system(size:))` for absolute
- Use semantic styles where possible
- Maintain minimum touch targets

### Color Contrast

All color combinations meet WCAG AA:
- Primary text: 4.5:1 minimum
- Secondary text: 4.5:1 minimum
- Interactive elements: 3:1 minimum

---

## 📱 Responsive Behavior

### Screen Sizes

**iPhone SE (375pt width)**:
- Transaction cards: Full width minus 24pt margin
- Message bubbles: Max 75% width
- Input bar: Full width

**iPhone Pro Max (428pt width)**:
- Transaction cards: Max 320pt centered
- Message bubbles: Max 75% width
- Input bar: Full width

**iPad (768pt width)**:
- Transaction cards: Max 400pt
- Message bubbles: Max 600pt
- Consider two-column layout

---

## 🌓 Dark Mode

### Automatic Adaptation

All colors use semantic naming:
- `Color.wisePrimaryText` → Black/White
- `Color.wiseCardBackground` → White/Dark Gray
- `Color.wiseDivider` → Light/Dark variant

### Specific Adjustments

**Transaction Cards**:
- Border opacity: 0.1 (light), 0.2 (dark)
- Shadow: Invisible in dark mode

**Message Bubbles**:
- Incoming: #E9E9EB (light), #2C2C2E (dark)
- Outgoing: #007AFF (both modes)

---

## 🎬 Animation Curves

### Standard Animations

```swift
// Fade in
.animation(.easeOut(duration: 0.3))

// Button tap
.animation(.spring(response: 0.3, dampingFraction: 0.7))

// Card appear
.animation(.easeOut(duration: 0.2))

// Transition
.transition(.scale.combined(with: .opacity))
```

### Haptic Feedback

```swift
// Button tap
HapticManager.shared.impact(.light)

// Success
HapticManager.shared.notification(.success)

// Error
HapticManager.shared.notification(.error)
```

---

## 📐 Layout Grid

### Base Unit: 8pt

```
┌─────────────────────────────────────────────────┐
│ 16pt margin                                     │
│  ┌───────────────────────────────────────────┐ │
│  │ Card content                              │ │
│  │  ┌─────────────────────────────────────┐ │ │
│  │  │ Nested element (8pt padding)        │ │ │
│  │  └─────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

All measurements are multiples of 8pt:
- Margins: 16pt, 24pt
- Padding: 8pt, 12pt, 16pt
- Spacing: 8pt, 12pt, 16pt, 24pt
- Corner radius: 8pt, 12pt, 16pt, 20pt

---

## ✅ Implementation Checklist

When implementing any component, ensure:

- [ ] Follows 8pt grid
- [ ] Uses semantic colors
- [ ] Has 44pt touch targets
- [ ] Includes VoiceOver labels
- [ ] Works in light/dark mode
- [ ] Has animation specified
- [ ] Includes preview code
- [ ] Uses Theme constants
- [ ] Handles edge cases
- [ ] Performance optimized

---

**Reference Date**: January 9, 2026  
**Version**: 1.0
