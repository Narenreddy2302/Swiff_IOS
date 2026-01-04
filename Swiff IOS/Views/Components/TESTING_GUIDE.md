# Implementation Examples: Testing Transaction Redesign

## How to Test the Changes

### Option 1: In Your Feed View

If your feed view uses `ListRowFactory`, the changes will automatically apply. No code changes needed!

```swift
// Your existing code should work as-is
ForEach(transactions) { transaction in
    ListRowFactory.row(for: transaction) {
        // Handle tap
    }
}
```

### Option 2: Create Test Data

Add this to your test/preview code to verify all transaction types:

```swift
extension Transaction {
    static let testTransactions: [Transaction] = [
        // Income from person (should show green + and "Receive")
        Transaction(
            title: "Mikel Borle",
            subtitle: "Payment received",
            amount: 350.00,
            category: .income,
            date: Date(),
            isRecurring: false,
            tags: [],
            merchant: "Mikel Borle"
        ),
        
        // Uber transfer (should show black Uber text, black -, "Transfer")
        Transaction(
            title: "Uber",
            subtitle: "Ride to airport",
            amount: -10.00,
            category: .transportation,
            date: Date().addingTimeInterval(-2 * 3600), // 2 hours ago
            isRecurring: false,
            tags: [],
            merchant: "Uber"
        ),
        
        // Person payment (should show initials, black -, "Send")
        Transaction(
            title: "Ryan Scott",
            subtitle: "Dinner split",
            amount: -124.00,
            category: .other,
            date: Date().addingTimeInterval(-5 * 3600), // 5 hours ago
            isRecurring: false,
            tags: []
        ),
        
        // Food Panda (should show panda emoji, black -, "Payment")
        Transaction(
            title: "Food Panda",
            subtitle: "Food delivery",
            amount: -21.56,
            category: .food,
            date: Date().addingTimeInterval(-86400), // Yesterday
            isRecurring: false,
            tags: [],
            merchant: "Food Panda"
        ),
        
        // Bank transfer (should show initials, black -, "Transfer")
        Transaction(
            title: "Chase Bank",
            subtitle: "Account transfer",
            amount: -500.00,
            category: .transfer,
            date: Date().addingTimeInterval(-86400 - 3600), // Yesterday
            isRecurring: false,
            tags: [],
            merchant: "Chase Bank"
        ),
    ]
}
```

### Option 3: SwiftUI Preview

Add this preview to any file to see the redesigned rows:

```swift
#Preview("Transaction Rows - Redesigned") {
    ScrollView {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("TODAY")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Income transaction
            ListRowFactory.row(
                for: Transaction(
                    title: "Mikel Borle",
                    subtitle: "Payment",
                    amount: 350.00,
                    category: .income,
                    date: Date(timeIntervalSinceNow: -2 * 3600), // 10:30 AM today
                    isRecurring: false,
                    tags: [],
                    merchant: "Mikel Borle"
                )
            )
            Divider().padding(.leading, 76)
            
            // Uber transaction
            ListRowFactory.row(
                for: Transaction(
                    title: "Uber",
                    subtitle: "Ride",
                    amount: -10.00,
                    category: .transportation,
                    date: Date(timeIntervalSinceNow: -4.5 * 3600), // 08:25 AM today
                    isRecurring: false,
                    tags: [],
                    merchant: "Uber"
                )
            )
            Divider().padding(.leading, 76)
            
            // Person payment
            ListRowFactory.row(
                for: Transaction(
                    title: "Ryan Scott",
                    subtitle: "Dinner",
                    amount: -124.00,
                    category: .other,
                    date: Date(timeIntervalSinceNow: -3 * 3600), // 09:45 AM today
                    isRecurring: false,
                    tags: []
                )
            )
            
            // Yesterday Section
            HStack {
                Text("YESTERDAY")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Income transaction
            ListRowFactory.row(
                for: Transaction(
                    title: "Mikel Borle",
                    subtitle: "Payment",
                    amount: 350.00,
                    category: .income,
                    date: Date(timeIntervalSinceNow: -86400 - 2 * 3600), // Yesterday 10:30 AM
                    isRecurring: false,
                    tags: [],
                    merchant: "Mikel Borle"
                )
            )
            Divider().padding(.leading, 76)
            
            // Food Panda transaction
            ListRowFactory.row(
                for: Transaction(
                    title: "Food Panda",
                    subtitle: "Food delivery",
                    amount: -21.56,
                    category: .food,
                    date: Date(timeIntervalSinceNow: -86400 - 3 * 3600), // Yesterday 09:45 AM
                    isRecurring: false,
                    tags: [],
                    merchant: "Food Panda"
                )
            )
            Divider().padding(.leading, 76)
            
            // Uber transaction
            ListRowFactory.row(
                for: Transaction(
                    title: "Uber",
                    subtitle: "Ride",
                    amount: -25.00,
                    category: .transportation,
                    date: Date(timeIntervalSinceNow: -86400 - 12.5 * 3600), // Yesterday 08:25 PM
                    isRecurring: false,
                    tags: [],
                    merchant: "Uber"
                )
            )
        }
        .background(Color.white)
    }
    .background(Color(red: 242/255, green: 242/255, blue: 247/255)) // iOS system background
}
```

## Expected Output Verification

Run the preview and verify:

### ✅ Checklist for "Mikel Borle" (Income)
- [ ] Teal circle with "MB" initials in white
- [ ] Title: "Mikel Borle" in bold black
- [ ] Time: "10:30 AM" in gray
- [ ] Amount: "+$350.00" in green
- [ ] Status: "Receive" in gray

### ✅ Checklist for "Uber" 
- [ ] Black circle with "Uber" text (not "U") in white
- [ ] Title: "Uber" in bold black
- [ ] Time: "08:25 AM" in gray
- [ ] Amount: "-$10.00" in black
- [ ] Status: "Transfer" in gray

### ✅ Checklist for "Ryan Scott"
- [ ] Colored circle with "RS" initials in white (purple from color hash)
- [ ] Title: "Ryan Scott" in bold black
- [ ] Time: "09:45 AM" in gray
- [ ] Amount: "-$124.00" in black
- [ ] Status: "Send" in gray

### ✅ Checklist for "Food Panda"
- [ ] Pink circle with 🐼 emoji
- [ ] Title: "Food Panda" in bold black
- [ ] Time: "09:45 AM" in gray
- [ ] Amount: "-$21.56" in black
- [ ] Status: "Payment" in gray

### ✅ Layout Measurements (use Xcode view debugger)
- [ ] Avatar size: 56pt × 56pt
- [ ] Horizontal padding: 16pt
- [ ] Vertical padding: 10pt
- [ ] Avatar-to-text spacing: 12pt
- [ ] Title-to-time spacing: 2pt
- [ ] Amount-to-status spacing: 2pt

## Common Issues & Solutions

### Issue 1: "Uber" shows "U" instead of full word
**Cause**: Transaction title or merchant field doesn't contain "uber"  
**Solution**: Ensure transaction has `merchant: "Uber"` or `title: "Uber"`

```swift
// ✅ Correct
Transaction(
    title: "Uber",
    merchant: "Uber",
    ...
)

// ❌ Won't trigger special handling
Transaction(
    title: "Ride from airport",
    merchant: nil,
    ...
)
```

### Issue 2: Food Panda doesn't show emoji
**Cause**: Name doesn't match pattern "food" + "panda"  
**Solution**: Check merchant/title contains both words

```swift
// ✅ Correct (any of these work)
merchant: "Food Panda"
merchant: "FoodPanda"
merchant: "food panda"

// ❌ Won't trigger special handling
merchant: "Food Delivery Service"
```

### Issue 3: Wrong status label showing
**Cause**: Category or merchant field not set correctly  
**Solution**: Set appropriate category and merchant

```swift
// For "Payment" status
category: .food,           // OR .transportation, .utilities, .bills, .shopping, .entertainment
merchant: "Some Merchant"  // Must have merchant field

// For "Transfer" status
category: .transfer        // OR title contains "transfer"

// For "Send" status
category: .other           // No merchant field, no transfer category
merchant: nil
```

### Issue 4: Colors not matching screenshot
**Cause**: Hash distribution might assign different colors  
**Solution**: Colors are deterministic based on name hash. Same name = same color always.

To test specific colors:
```swift
// Mikel Borle should get teal (first in array)
// Ryan Scott should get purple (5th in array)
// etc.

// You can verify with:
let name = "Mikel Borle"
let hash = abs(name.hashValue)
let colorIndex = hash % 8
print("Color index for \(name): \(colorIndex)")
```

### Issue 5: Time not showing correctly
**Cause**: Date might be in different timezone  
**Solution**: Ensure dates are in user's local timezone

```swift
// ✅ Correct - relative to current time
date: Date(timeIntervalSinceNow: -2 * 3600) // 2 hours ago

// ❌ May show wrong time
date: Date(timeIntervalSince1970: 0) // January 1, 1970
```

## Integration with Existing Feed View

If you have a feed view, minimal changes needed:

### Before
```swift
struct FeedView: View {
    @State var transactions: [Transaction] = []
    
    var body: some View {
        List {
            ForEach(transactions) { transaction in
                TransactionRow(transaction: transaction) // Old custom row
            }
        }
    }
}
```

### After
```swift
struct FeedView: View {
    @State var transactions: [Transaction] = []
    
    var body: some View {
        List {
            ForEach(transactions) { transaction in
                ListRowFactory.row(for: transaction) {
                    // Handle tap
                    print("Tapped: \(transaction.title)")
                }
            }
        }
        .listStyle(.plain)
    }
}
```

## Advanced: Custom Merchant Handling

Want to add more merchants with special handling? Easy!

```swift
// In ListRowFactory.swift, update avatarConfig():

private static func avatarConfig(for transaction: Transaction) -> UniversalIconConfig {
    let displayName = transaction.merchant ?? transaction.title
    
    switch displayName.lowercased() {
    case let name where name.contains("uber"):
        return .initials(text: "Uber", backgroundColor: Color(red: 28/255, green: 28/255, blue: 30/255))
        
    case let name where name.contains("food") && name.contains("panda"):
        return .emoji(text: "🐼", backgroundColor: Color(red: 233/255, green: 30/255, blue: 99/255))
        
    // ADD YOUR CUSTOM MERCHANTS HERE:
    
    case let name where name.contains("starbucks"):
        return .emoji(text: "☕️", backgroundColor: Color(red: 0/255, green: 112/255, blue: 74/255)) // Starbucks green
        
    case let name where name.contains("netflix"):
        return .initials(text: "N", backgroundColor: Color(red: 229/255, green: 9/255, blue: 20/255)) // Netflix red
        
    case let name where name.contains("spotify"):
        return .emoji(text: "🎵", backgroundColor: Color(red: 30/255, green: 215/255, blue: 96/255)) // Spotify green
        
    default:
        let color = avatarColorForTransaction(displayName)
        return .initials(text: displayName, backgroundColor: color)
    }
}
```

## Performance Testing

Test with large datasets to ensure smooth scrolling:

```swift
#Preview("Performance Test - 100 Transactions") {
    let testTransactions = (0..<100).map { i in
        Transaction(
            title: ["Mikel Borle", "Uber", "Ryan Scott", "Food Panda", "Amazon", "Apple", "Google"][i % 7],
            subtitle: "Test transaction \(i)",
            amount: Double([-350.0, -10.0, -124.0, -21.56, 50.0, -99.99, 1000.0][i % 7]),
            category: [.income, .transportation, .other, .food, .shopping, .entertainment, .transfer][i % 7],
            date: Date(timeIntervalSinceNow: TimeInterval(-i * 3600)),
            isRecurring: false,
            tags: [],
            merchant: ["Mikel Borle", "Uber", nil, "Food Panda", "Amazon", "Apple", "Google"][i % 7]
        )
    }
    
    ScrollView {
        LazyVStack(spacing: 0) {
            ForEach(testTransactions) { transaction in
                ListRowFactory.row(for: transaction)
                Divider().padding(.leading, 76)
            }
        }
    }
}
```

Expected performance:
- ✅ Smooth 60 FPS scrolling
- ✅ No stuttering or dropped frames
- ✅ Instant color assignment
- ✅ Fast initial render

## Debugging Tips

### Enable View Debugging
1. Run your app in Simulator
2. Click **Debug** → **View Debugging** → **Capture View Hierarchy**
3. Verify:
   - Avatar circles are perfectly round
   - Text alignment is correct
   - Spacing matches specifications

### Print Debug Info
Add temporary logging:

```swift
// In ListRowFactory.row()
print("🎨 Transaction: \(transaction.title)")
print("   Avatar: \(iconConfig)")
print("   Status: \(statusString)")
print("   Value: \(value)")
print("   Color: \(valueColor)")
```

### Test Edge Cases
```swift
// Very long names
Transaction(title: "This is a very long merchant name that should truncate", ...)

// Very large amounts
Transaction(amount: 999999.99, ...)

// Zero amount
Transaction(amount: 0, ...)

// Negative income (shouldn't happen but test anyway)
Transaction(amount: -100, category: .income, ...)

// Missing merchant
Transaction(merchant: nil, ...)

// Empty title
Transaction(title: "", ...)
```

## Final Checklist Before Merging

- [ ] All preview tests pass
- [ ] Colors match screenshot exactly
- [ ] Special merchants (Uber, Food Panda) render correctly
- [ ] Status labels accurate for all transaction types
- [ ] Time formatting shows 12-hour format
- [ ] Amount formatting includes + or – prefix
- [ ] Layout spacing matches specifications (10pt vertical, 2pt text)
- [ ] Avatar size is 56pt
- [ ] No compiler warnings
- [ ] No force unwraps or unsafe code
- [ ] Performance is smooth with 100+ transactions
- [ ] Code is well-documented
- [ ] Backward compatible with existing data

## Need Help?

If something doesn't match the screenshot:

1. **Check transaction data**: Verify merchant, category, amount fields
2. **Review color hash**: Same name should always give same color
3. **Verify date formatting**: Should be in local timezone
4. **Test in Xcode preview first**: Faster iteration than full app
5. **Use view debugger**: Measure exact spacing and sizes
6. **Check for typos**: "Uber" vs "uber" vs "UBER" (case-insensitive matching)

Good luck! 🚀
