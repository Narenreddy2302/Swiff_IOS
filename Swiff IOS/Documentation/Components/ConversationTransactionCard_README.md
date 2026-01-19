# Conversation Transaction Card - Implementation Guide

## Overview

The Conversation Transaction Card system provides a clean, professional way to display transaction information in conversation views. It matches the reference design with proper layout, spacing, and visual hierarchy.

## Components

### 1. ConversationTransactionCard (View)
The main card component that displays transaction details.

**Key Features:**
- Header text outside the card (e.g., "You Created the transaction")
- Title and amount in the top section with proper alignment
- Detail rows showing transaction metadata
- Clean rectangular design with subtle borders
- Proper color coding (green for lent, red for owe)

### 2. ConversationTransactionCardBuilder (Helper)
Factory methods for creating different types of transaction cards.

**Available Methods:**
- `payment()` - For when you lent money
- `request()` - For money requests
- `owe()` - For when you owe money
- `split()` - For split expenses
- `groupExpense()` - For group expenses

### 3. ConversationTransactionHelper (Utilities)
Advanced utilities for converting domain models to cards.

**Capabilities:**
- Convert SplitBill, GroupExpense, and Transaction models to cards
- Handle currency formatting
- Determine transaction relationships (who paid, who owes)
- Support for TransactionDisplayData protocol

## Usage Examples

### Basic Usage - Payment Card

```swift
let card = ConversationTransactionCardBuilder.payment(
    to: "Li Wei",
    amount: "$250.00",
    totalBill: "$250.00",
    paidBy: "You",
    splitMethod: "Equally",
    participants: "You, Li Wei",
    creatorName: "You",
    onTap: {
        // Handle tap - navigate to detail view
        print("Tapped payment card")
    }
)
```

### Basic Usage - Owe Card

```swift
let card = ConversationTransactionCardBuilder.owe(
    to: "Li Wei",
    amount: "$125.00",
    totalBill: "$250.00",
    paidBy: "Li Wei",
    splitMethod: "Equally",
    participants: "You, Li Wei",
    creatorName: "Li Wei",
    onTap: {
        // Handle tap
    }
)
```

### Advanced Usage - From Domain Model

```swift
// With SplitBill model
let card = splitBill.toConversationCard(
    currentUserId: currentUser.id,
    payerName: payer.name,
    participantNames: participants.map { $0.name },
    onTap: {
        // Navigate to split bill detail
    }
)

// With Transaction model
let card = transaction.toConversationCard(
    personName: person.name,
    onTap: {
        // Navigate to transaction detail
    }
)
```

### Advanced Usage - Custom Logic

```swift
// For complex scenarios with custom logic
let card = ConversationTransactionHelper.createPersonTransactionCard(
    amount: 250.0,
    personName: "Li Wei",
    title: "Lunch at Restaurant",
    isCurrentUserCreator: true,
    isCurrentUserPayer: true,
    splitMethod: "Equally",
    participants: ["You", "Li Wei"],
    onTap: {
        // Handle tap
    }
)
```

## Integration in ConversationView

### Step 1: Define Conversation Items

```swift
enum ConversationItem: Identifiable {
    case message(id: UUID, text: String, timestamp: Date, isFromCurrentUser: Bool)
    case transaction(id: UUID, card: ConversationTransactionCard, timestamp: Date)
    case systemMessage(id: UUID, message: String, icon: String?, timestamp: Date)
    
    var id: UUID {
        switch self {
        case .message(let id, _, _, _): return id
        case .transaction(let id, _, _): return id
        case .systemMessage(let id, _, _, _): return id
        }
    }
}
```

### Step 2: Render Cards in Timeline

```swift
@ViewBuilder
private func conversationItemView(for item: ConversationItem) -> some View {
    switch item {
    case .message(_, let text, _, let isFromCurrentUser, _):
        ChatBubble(
            direction: isFromCurrentUser ? .outgoing : .incoming,
            timestamp: Date()
        ) {
            Text(text)
        }
        
    case .transaction(_, let card, _):
        card
            .padding(.horizontal, 12)
        
    case .systemMessage(_, let message, let icon, _):
        SystemMessageView(message: message, icon: icon)
    }
}
```

### Step 3: Load Real Data

```swift
private func loadTransactions() {
    // Fetch transactions from data manager
    let transactions = dataManager.getTransactions(for: person.id)
    
    conversationItems = transactions.map { transaction in
        let card = transaction.toConversationCard(
            personName: person.name,
            onTap: {
                navigateToTransactionDetail(transaction)
            }
        )
        
        return ConversationItem.transaction(
            id: transaction.id,
            card: card,
            timestamp: transaction.date
        )
    }
}
```

## Design Specifications

### Visual Hierarchy
1. **Header Text**: 11pt, medium weight, system gray
2. **Title**: 17pt, semibold, primary color
3. **Amount**: 17pt, bold, colored (green/red)
4. **Amount Label**: 13pt, regular, colored with 75% opacity
5. **Detail Labels**: 13pt, medium, secondary color
6. **Detail Values**: 13pt, semibold, primary color

### Colors
- **You Lent**: `.wiseBrightGreen` (positive balance)
- **You Owe**: `.wiseError` (negative balance)
- **Background**: `secondarySystemGroupedBackground`
- **Border**: `separator` with 0.5 opacity

### Spacing
- Card padding: 14pt
- Header to card: 4pt
- Row spacing: 9pt vertical
- Corner radius: 16pt

### Metadata Rows
Standard rows include:
1. **Total Bill**: Full transaction amount
2. **Paid by**: Name of person who paid
3. **Split Method**: How the bill was divided (Equally, Custom, etc.)
4. **Who are all involved**: Comma-separated participant names

## Logic Reference

### Determining Transaction Type

```swift
// Basic logic for person-to-person transactions
if isCurrentUserPayer && participantsCount > 1 {
    // You Lent - use payment card
    color = .wiseBrightGreen
    label = "You Lent"
} else if !isCurrentUserPayer {
    // You Owe - use owe card
    color = .wiseError
    label = "You Owe"
}
```

### Creator Name Logic

```swift
let creatorName = isCurrentUserCreator ? "You" : personName
let headerText = "\(creatorName) Created the transaction"
```

### Split Method Display

```swift
switch splitType {
case .equally: return "Equally"
case .exactAmounts: return "Exact Amounts"
case .percentages: return "By Percentage"
case .shares: return "By Shares"
case .adjustments: return "With Adjustments"
}
```

## Testing

### Preview Provider

Use the built-in preview to test different card types:

```swift
#Preview("Conversation Transaction Cards") {
    ScrollView {
        VStack(spacing: 16) {
            // Payment Card
            ConversationTransactionCardBuilder.payment(...)
            
            // Owe Card
            ConversationTransactionCardBuilder.owe(...)
            
            // Split Card
            ConversationTransactionCardBuilder.split(...)
        }
    }
}
```

### Key Test Cases
1. ✅ Payment card with "You Lent" label
2. ✅ Owe card with "You Owe" label
3. ✅ Proper creator name in header
4. ✅ Correct color coding (green/red)
5. ✅ All metadata rows displayed
6. ✅ Tap handling works
7. ✅ Long names truncate properly
8. ✅ Large amounts display correctly

## Common Patterns

### Pattern 1: Real-time Updates
```swift
@Published var conversationItems: [ConversationItem] = []

func handleNewTransaction(_ transaction: Transaction) {
    let card = transaction.toConversationCard(
        personName: person.name,
        onTap: { /* ... */ }
    )
    
    let item = ConversationItem.transaction(
        id: transaction.id,
        card: card,
        timestamp: transaction.date
    )
    
    conversationItems.append(item)
}
```

### Pattern 2: Mixed Timeline
```swift
// Combine messages and transactions in chronological order
let allItems = (messages + transactions).sorted { $0.timestamp < $1.timestamp }
```

### Pattern 3: Navigation
```swift
onTap: {
    // Navigate to detail view
    if let splitBill = transaction as? SplitBill {
        navigationPath.append(DetailDestination.splitBill(splitBill))
    }
}
```

## Troubleshooting

### Issue: Wrong Color
**Solution**: Check if `isUserPayer` logic is correct. User should see green when they lent, red when they owe.

### Issue: Wrong Creator Name
**Solution**: Verify `isCurrentUserCreator` parameter is set correctly based on who initiated the transaction.

### Issue: Incorrect Amount
**Solution**: Use `ConversationTransactionHelper.formatCurrency()` for consistent formatting.

### Issue: Participants Not Showing
**Solution**: Ensure participant names are joined with ", " separator.

## Best Practices

1. **Always use the builder methods** - They handle proper initialization
2. **Handle tap actions** - Enable navigation to detail views
3. **Validate data** - Check for nil values and provide defaults
4. **Test edge cases** - Long names, large amounts, many participants
5. **Use helpers for domain models** - Leverage extension methods
6. **Maintain consistency** - Use same formatting across all cards
7. **Consider accessibility** - Ensure proper contrast and tap targets

## Future Enhancements

Potential improvements:
- Settlement status indicators
- Photo/receipt attachments
- Category icons
- Currency conversion support
- Settlement animations
- Swipe actions
- Long-press menus

---

**Last Updated**: January 9, 2026
**Compatibility**: iOS 17.0+
**Framework**: SwiftUI
