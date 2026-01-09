# Quick Reference - Conversation Transaction Cards

## 🎯 TL;DR - What You Need

```swift
// Simple Payment (You Lent)
ConversationTransactionCardBuilder.payment(
    to: personName,
    amount: "$250.00",
    totalBill: "$250.00",
    paidBy: "You",
    splitMethod: "Equally",
    participants: "You, Li Wei",
    creatorName: "You"
)

// Simple Owe (You Owe)
ConversationTransactionCardBuilder.owe(
    to: personName,
    amount: "$125.00",
    totalBill: "$250.00",
    paidBy: personName,
    splitMethod: "Equally",
    participants: "You, \(personName)",
    creatorName: personName
)
```

---

## 🚀 Common Scenarios

### Scenario 1: You paid for lunch with a friend
```swift
ConversationTransactionCardBuilder.payment(
    to: "Li Wei",
    amount: "$25.00",        // Their half
    totalBill: "$50.00",     // Full bill
    paidBy: "You",
    splitMethod: "Equally",
    participants: "You, Li Wei",
    creatorName: "You"
)
// Result: Green card saying "You Lent"
```

### Scenario 2: Friend paid for movie tickets
```swift
ConversationTransactionCardBuilder.owe(
    to: "Li Wei",
    amount: "$15.00",        // Your share
    totalBill: "$30.00",     // Full bill
    paidBy: "Li Wei",
    splitMethod: "Equally",
    participants: "You, Li Wei",
    creatorName: "Li Wei"
)
// Result: Red card saying "You Owe"
```

### Scenario 3: Split dinner 3 ways, you paid
```swift
ConversationTransactionCardBuilder.split(
    description: "Dinner at Restaurant",
    amount: "$33.33",        // Their share each
    totalBill: "$100.00",    // Full bill
    paidBy: "You",
    splitMethod: "Equally",
    participants: "You, Li Wei, John",
    creatorName: "You",
    isUserPayer: true
)
// Result: Green card saying "You Lent"
```

### Scenario 4: Split dinner 3 ways, friend paid
```swift
ConversationTransactionCardBuilder.split(
    description: "Dinner at Restaurant",
    amount: "$33.33",        // Your share
    totalBill: "$100.00",    // Full bill
    paidBy: "Li Wei",
    splitMethod: "Equally",
    participants: "You, Li Wei, John",
    creatorName: "Li Wei",
    isUserPayer: false
)
// Result: Red card saying "You Owe"
```

---

## 🔄 From Domain Models

### From SplitBill
```swift
let card = splitBill.toConversationCard(
    currentUserId: currentUser.id,
    payerName: "Li Wei",
    participantNames: ["You", "Li Wei", "John"]
)
```

### From Transaction
```swift
let card = transaction.toConversationCard(
    personName: person.name
)
```

### From GroupExpense
```swift
let card = groupExpense.toConversationCard(
    payerName: "Sarah",
    participantNames: ["You", "Sarah", "Li Wei"]
)
```

---

## 💰 Currency Formatting

```swift
// Use the helper
let formatted = ConversationTransactionHelper.formatCurrency(250.0)
// Result: "$250.00"

// Or let the builder handle it
ConversationTransactionCardBuilder.payment(
    amount: ConversationTransactionHelper.formatCurrency(transaction.amount),
    // ...
)
```

---

## 🎨 Color Logic

```swift
// Simple rule:
// - You paid + others owe you = GREEN ("You Lent")
// - Someone paid + you owe them = RED ("You Owe")

if isUserPayer {
    color = .wiseBrightGreen
    label = "You Lent"
} else {
    color = .wiseError
    label = "You Owe"
}
```

---

## 📝 Detail Rows (Always Same 4)

```swift
1. "Total Bill"          → "$250.00"
2. "Paid by"             → "You" or "Li Wei"
3. "Split Method"        → "Equally", "Custom", etc.
4. "Who are all involved" → "You, Li Wei, John"
```

---

## 🔧 Split Method Text

```swift
switch splitType {
case .equally:      "Equally"
case .exactAmounts: "Exact Amounts"
case .percentages:  "By Percentage"
case .shares:       "By Shares"
case .adjustments:  "With Adjustments"
}
```

---

## 🎯 Creator Name Logic

```swift
let creatorName = isCurrentUserCreator ? "You" : personName
// Results in:
// "You Created the transaction"
// or
// "Li Wei Created the transaction"
```

---

## 📱 Integration in Timeline

```swift
// In ConversationTimelineView
case .transaction(_, let card, _):
    card
        .padding(.horizontal, 12)
```

---

## 🎪 Preview / Testing

```swift
#Preview {
    VStack(spacing: 16) {
        // Payment
        ConversationTransactionCardBuilder.payment(
            to: "Li Wei",
            amount: "$250.00",
            totalBill: "$250.00",
            paidBy: "You",
            splitMethod: "Equally",
            participants: "You, Li Wei",
            creatorName: "You"
        )
        
        // Owe
        ConversationTransactionCardBuilder.owe(
            to: "Li Wei",
            amount: "$125.00",
            totalBill: "$250.00",
            paidBy: "Li Wei",
            splitMethod: "Equally",
            participants: "You, Li Wei",
            creatorName: "Li Wei"
        )
    }
    .padding()
}
```

---

## ⚠️ Common Mistakes

### ❌ Wrong: Using wrong color for owe
```swift
// Don't do this
ConversationTransactionCardBuilder.payment(  // Wrong method
    to: "Li Wei",
    amount: "$125.00",
    // ... but they paid, not you
)
```

### ✅ Right: Use owe method
```swift
ConversationTransactionCardBuilder.owe(
    to: "Li Wei",
    amount: "$125.00",
    paidBy: "Li Wei",  // Correct
    // ...
)
```

### ❌ Wrong: Manual amount formatting
```swift
amount: "$\(transaction.amount)"  // No decimal places
```

### ✅ Right: Use helper
```swift
amount: ConversationTransactionHelper.formatCurrency(transaction.amount)
```

### ❌ Wrong: Participants as array
```swift
participants: ["You", "Li Wei"]  // Wrong type
```

### ✅ Right: Join with comma
```swift
participants: "You, Li Wei"  // String
// or
participants: ["You", "Li Wei"].joined(separator: ", ")
```

---

## 🏃 Performance Tips

1. **Reuse cards**: Don't recreate unnecessarily
2. **Lazy loading**: Use `LazyVStack` for long lists
3. **Memoization**: Cache formatted strings
4. **Batch updates**: Update multiple items together

---

## 🐛 Debugging

### Card not showing?
- Check padding is applied: `.padding(.horizontal, 12)`
- Verify in ScrollView or List
- Check background color matches theme

### Wrong color?
- Verify `isUserPayer` logic
- Check transaction type (expense vs income)
- Confirm creator detection

### Text truncated?
- Normal for long titles (max 2 lines)
- Normal for long participant lists (max 2 lines)
- Use shorter names if needed

### Tap not working?
- Ensure `onTap` is passed
- Check `contentShape(Rectangle())` is present (it is by default)
- Verify parent view isn't blocking gestures

---

## 📚 Full Documentation

- **Detailed Guide**: `ConversationTransactionCard_README.md`
- **Implementation Summary**: `IMPLEMENTATION_SUMMARY.md`
- **Visual Design**: `VISUAL_DESIGN_COMPARISON.md`
- **Helper Utils**: `ConversationTransactionHelper.swift`

---

## 🎯 Decision Tree

```
Is current user the payer?
├─ YES: Did others participate?
│   ├─ YES: Use .payment() → GREEN "You Lent"
│   └─ NO: Regular transaction
└─ NO: Use .owe() → RED "You Owe"

For group expenses:
- Use .groupExpense() → RED "Your Share"

For generic splits:
- Use .split(isUserPayer: ...)
  ├─ true → GREEN "You Lent"
  └─ false → RED "You Owe"
```

---

## ✅ Checklist for New Implementation

- [ ] Import correct builder method
- [ ] Format currency properly
- [ ] Set correct creator name
- [ ] Set correct payer name
- [ ] Join participants with ", "
- [ ] Pass tap handler
- [ ] Apply horizontal padding
- [ ] Test in light/dark mode
- [ ] Test with long names
- [ ] Test with large amounts

---

**Quick Start**: Copy a working example from the Preview section and modify the values!

🚀 Ready to implement? Start with the simplest case and expand from there!
