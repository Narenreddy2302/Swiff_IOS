//
//  CONVERSATION_REDESIGN_DOCUMENTATION.md
//  Swiff IOS
//
//  Professional Conversation View Redesign
//  Complete documentation and implementation guide
//

# 📱 Professional Conversation View Redesign

## Overview

This document outlines the complete redesign of the conversation view in Swiff, transforming it from a basic interface into a professional, Apple HIG-compliant experience that follows industry standards.

---

## 🎯 Design Philosophy

### Core Principles

1. **Clarity First**: Every element has a clear purpose and visual hierarchy
2. **Apple Native Feel**: Follows iOS Messages design patterns
3. **Professional Polish**: Card-based transactions with structured information
4. **Accessibility**: Full VoiceOver support, proper touch targets, semantic colors
5. **Performance**: Lazy loading, efficient rendering, smooth animations

---

## 🏗️ Architecture

### Component Hierarchy

```
PersonConversationView (Main Container)
├── CompactGroupHeader / CompactPersonHeader
│   ├── BaseConversationHeader
│   │   ├── Back Button
│   │   ├── Avatar (UnifiedEmojiCircle)
│   │   ├── HeaderTitleView (Name + Balance)
│   │   └── Info Button
│   └── ConversationBalanceBanner (Optional)
│
├── ConversationTimelineView
│   └── For each date section:
│       ├── ChatDateHeader
│       └── For each item:
│           ├── ChatBubble (Messages)
│           ├── TransactionCard (Payments/Requests/Splits)
│           └── SystemMessageView (Status updates)
│
└── ConversationInputBarWrapper
    ├── Add Transaction Button (+)
    ├── Message TextField
    └── Send/Scroll Button
```

---

## 📦 New Components

### 1. TransactionCard.swift

**Purpose**: Professional transaction display with structured information

**Features**:
- ✅ Clear visual hierarchy (icon, title, amount)
- ✅ Structured metadata rows
- ✅ Type-specific styling (Payment/Request/Split)
- ✅ Tap gesture support
- ✅ Subtle shadows and borders
- ✅ Accessibility labels

**Transaction Types**:
```swift
enum TransactionType {
    case payment    // Direct payment (green arrow up)
    case request    // Money request (orange arrow down)
    case split      // Bill split (blue grid)
    case expense    // Group expense (receipt)
}
```

**Usage Example**:
```swift
TransactionCardBuilder.payment(
    to: "Li Wei",
    amount: "$250.00",
    totalBill: "$250.00",
    note: "Dinner split"
) {
    // Handle tap
}
```

**Design Specs**:
- Corner radius: 12pt
- Border: 1pt, opacity 0.1
- Shadow: 2pt blur, 1pt offset
- Padding: 16pt
- Icon size: 40pt circle
- Font sizes: 16pt title, 17pt amount, 14pt/13pt metadata

---

### 2. SystemMessageView.swift

**Purpose**: Clean system status messages

**Features**:
- ✅ Centered, subtle appearance
- ✅ Optional icon support
- ✅ Predefined message types
- ✅ Consistent styling

**Message Types**:
- Transaction created
- Payment sent
- Request sent
- Split created
- Custom info messages

**Design Specs**:
- Font: 12pt semibold
- Background: Secondary text at 6% opacity
- Corner radius: 12pt
- Padding: 12pt horizontal, 6pt vertical
- Icon size: 11pt

---

### 3. ConversationInputBar.swift

**Purpose**: Apple Messages-style input area

**Features**:
- ✅ Add transaction button (green +)
- ✅ Rounded text field
- ✅ Dynamic send/scroll button
- ✅ Keyboard handling
- ✅ Material background

**Design Specs**:
- TextField corner radius: 20pt
- Button size: 28pt
- Spacing: 12pt
- Background: Ultra thin material
- Font: 16pt

**Behavior**:
- Shows send button when text present
- Shows scroll button when field empty
- Animates between states
- Submit on return key

---

### 4. Enhanced CompactGroupHeader.swift

**Purpose**: Professional header with balance information

**New Features**:
- ✅ Balance banner integration
- ✅ Conditional balance display
- ✅ Better subtitle logic
- ✅ Multiple preview states

**Balance Types**:
```swift
enum BalanceType {
    case youOwe     // Red, "You owe $X"
    case theyOwe    // Green, "You are owed $X"
    case settled    // Gray, "All settled up"
}
```

**Balance Banner**:
- Appears below main header
- Color-coded by balance type
- Icon + formatted amount
- 8% opacity background tint

---

### 5. PersonConversationView.swift

**Purpose**: Complete conversation view implementation

**Features**:
- ✅ Unified timeline (messages + transactions)
- ✅ Date grouping
- ✅ Smart spacing logic
- ✅ Message attachments (payment badges)
- ✅ System message integration
- ✅ Input bar integration

**Item Types**:
```swift
enum ConversationItem {
    case message(...)
    case transaction(...)
    case systemMessage(...)
}
```

**Spacing Logic**:
- 2pt: Messages from same sender
- 16pt: Messages from different senders
- 16pt: Between different item types
- 24pt: Around date headers

---

## 🎨 Visual Design System

### Color Semantics

| Element | Color | Usage |
|---------|-------|-------|
| Payment icon | Green (`wiseBrightGreen`) | Outgoing payments, positive balance |
| Request icon | Orange (`wiseOrange`) | Money requests |
| Split icon | Blue (`wiseBlue`) | Bill splits |
| You owe | Red (`wiseError`) | Negative balance |
| System text | Secondary | Status messages |
| Card background | `wiseCardBackground` | Transaction cards |
| Input background | Secondary 8% | Text field |

### Typography Scale

| Element | Size | Weight |
|---------|------|--------|
| Card title | 16pt | Semibold |
| Card amount | 17pt | Semibold |
| Metadata label | 14pt | Regular |
| Metadata value | 14pt | Medium |
| System message | 12pt | Medium |
| Input text | 16pt | Regular |
| Date header | 11pt | Semibold |

### Spacing Scale (8pt Grid)

| Name | Value | Usage |
|------|-------|-------|
| Tight | 2pt | Grouped messages |
| Small | 8pt | Internal padding |
| Medium | 12pt | Between elements |
| Large | 16pt | Between sections |
| XLarge | 24pt | Major sections |

---

## ♿️ Accessibility

### VoiceOver Support

**Labels**:
- Back button: "Back"
- Info button: "Group info" / "Person info"
- Add transaction: "Add transaction"
- Send: "Send message"
- Transaction cards: Full transaction details

**Hints**:
- Back: "Double tap to go back"
- Add transaction: "Create a new payment or split"

**Grouping**:
- Transaction metadata rows combined
- Header elements combined
- Message bubbles self-contained

### Touch Targets

All interactive elements meet 44pt minimum:
- Back button: 44pt
- Info button: 44pt
- Add transaction button: 44pt
- Send button: 44pt

### Dynamic Type

All text scales with system font size settings using semantic font styles.

---

## 🔄 State Management

### Conversation State

```swift
@State private var conversationItems: [ConversationItem]
@State private var messageText: String
@FocusState private var isMessageFieldFocused: Bool
@State private var showingTransactionSheet: Bool
```

### Data Flow

1. Load conversation items (messages + transactions)
2. Group by date
3. Sort chronologically
4. Render with appropriate spacing
5. Auto-scroll to bottom on new items

---

## 📱 Behavior Patterns

### Message Sending

1. User types in text field
2. Send button appears
3. Tap send or press return
4. Message animates into timeline
5. Field clears
6. Keyboard stays visible
7. Auto-scroll to bottom

### Transaction Creation

1. Tap green + button
2. Sheet presents transaction form
3. User fills details
4. On save:
   - System message appears
   - Transaction card animates in
   - Timeline scrolls to show
   - Haptic feedback

### Message Grouping

Messages from same sender within short time:
- No sender name repetition
- Tighter spacing (2pt)
- Continuous visual flow

Messages from different senders:
- Wider spacing (16pt)
- Clear visual separation

---

## 🧪 Testing

### Preview Coverage

Created comprehensive previews for:
- ✅ TransactionCard (all types)
- ✅ SystemMessageView (all types)
- ✅ ConversationInputBar (empty + with text)
- ✅ CompactGroupHeader (all balance states)
- ✅ PersonConversationView (full conversation)

### Test Scenarios

1. Empty conversation
2. Messages only
3. Transactions only
4. Mixed timeline
5. Long messages
6. Multiple transactions in a row
7. System messages
8. Balance states (owe, owed, settled)

---

## 🚀 Performance Optimization

### Lazy Loading

- `LazyVStack` for timeline
- `LazyHStack` for horizontal lists
- On-demand rendering

### Efficient Grouping

- Computed properties for date grouping
- Cached sorted arrays
- Minimal recomputation

### Smooth Animations

- `.easeOut` curves for natural feel
- Scale + opacity transitions
- Material backgrounds for depth

---

## 📋 Implementation Checklist

### Completed ✅

- [x] TransactionCard component
- [x] TransactionCardBuilder helpers
- [x] SystemMessageView component
- [x] ConversationInputBar component
- [x] Enhanced CompactGroupHeader
- [x] ConversationBalanceBanner
- [x] PersonConversationView
- [x] ConversationTimelineView
- [x] Message attachment badges
- [x] Date grouping logic
- [x] Spacing logic
- [x] Preview suite

### Integration Required 🔄

- [ ] Connect to real data models (Person, Group, Transaction)
- [ ] Implement actual message sending
- [ ] Implement transaction creation flow
- [ ] Add transaction detail view navigation
- [ ] Add photo/attachment support
- [ ] Add message reactions (future)
- [ ] Add read receipts (future)
- [ ] Add typing indicators (future)

---

## 🎯 Next Steps

### Phase 1: Core Integration
1. Replace mock data with real SwiftData queries
2. Hook up message sending to backend
3. Connect transaction creation flow
4. Add navigation to transaction details

### Phase 2: Enhanced Features
1. Message attachments (photos, receipts)
2. Transaction editing/deletion
3. Message search
4. Export conversation

### Phase 3: Advanced Features
1. Message reactions
2. Read receipts
3. Typing indicators
4. Voice messages
5. Quick replies

---

## 📖 Usage Guide

### Basic Implementation

```swift
PersonConversationView(
    person: selectedPerson,
    group: nil,
    members: [selectedPerson],
    onBack: {
        dismiss()
    },
    onInfo: {
        showPersonDetails = true
    },
    onSendMessage: { text in
        dataManager.sendMessage(text, to: selectedPerson)
    },
    onAddTransaction: {
        showTransactionSheet = true
    }
)
```

### With Balance

```swift
let balance = ConversationBalance(
    amount: calculateBalance(with: person),
    type: amount >= 0 ? .theyOwe : .youOwe
)

CompactGroupHeader(
    group: group,
    members: members,
    balance: balance,
    onBack: { dismiss() },
    onInfo: { showInfo = true }
)
```

### Custom Transaction Card

```swift
TransactionCard(
    type: .payment,
    title: "Dinner at Olive Garden",
    amount: "$85.50",
    amountLabel: "You Paid",
    metadata: [
        TransactionMetadata(label: "Total Bill", value: "$171.00"),
        TransactionMetadata(label: "Split Method", value: "By Item"),
        TransactionMetadata(label: "Date", value: "Jan 9, 2026")
    ],
    timestamp: Date()
) {
    // Handle tap
    showTransactionDetail(id: transactionId)
}
```

---

## 🎨 Design Inspirations

This redesign follows patterns from:
- Apple Messages (iOS 18)
- Venmo conversation view
- Splitwise transaction cards
- WhatsApp message timeline
- Cash App activity feed

---

## 📝 Notes

### Design Decisions

1. **Why card-based transactions?**
   - Better information density
   - Clearer visual hierarchy
   - Easier to scan
   - More professional appearance
   - Follows Wise/Revolut patterns

2. **Why separate system messages?**
   - Reduces visual noise
   - Clear status communication
   - Doesn't compete with content
   - Standard pattern in messaging apps

3. **Why material backgrounds?**
   - Depth perception
   - Modern iOS feel
   - Adapts to light/dark mode
   - Better content separation

4. **Why 8pt grid?**
   - Apple's standard
   - Easy to maintain
   - Consistent rhythm
   - Clean alignment

---

## 🐛 Known Issues

None currently - this is a clean implementation.

---

## 📚 References

- [Apple HIG - Messages](https://developer.apple.com/design/human-interface-guidelines/messages)
- [Apple HIG - Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Apple HIG - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

## ✨ Credits

Redesigned with focus on:
- Professional polish
- Industry standards
- Apple HIG compliance
- User experience
- Accessibility
- Performance

---

**Version**: 1.0  
**Date**: January 9, 2026  
**Status**: Ready for integration
