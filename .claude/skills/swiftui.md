# SwiftUI Development Patterns

## Purpose
Guide SwiftUI view development following established project patterns, Apple's Human Interface Guidelines, and modern SwiftUI best practices.

## When to Use This Skill
- Creating new views or screens
- Building reusable components
- Implementing navigation
- Managing view state
- Adding animations

---

## View Composition Patterns

### Unified Design System Components

The project uses a unified component system for consistency:

#### UnifiedListRow - Standard List Item

```swift
// Views/Components/UnifiedListRow.swift
struct UnifiedListRow<IconContent: View>: View {
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color
    @ViewBuilder let iconContent: () -> IconContent

    var body: some View {
        HStack(spacing: 16) {
            iconContent()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.spotifyNumberMedium)
                .foregroundColor(valueColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .subtleShadow()
    }
}
```

#### UnifiedIconCircle - Icon Container

```swift
struct UnifiedIconCircle: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(icon: String, color: Color, size: CGFloat = 48) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(color)
            )
    }
}
```

#### Usage Example

```swift
struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        UnifiedListRow(
            title: subscription.name,
            subtitle: subscription.billingCycle.displayName,
            value: subscription.price.asCurrency,
            valueColor: .primary
        ) {
            UnifiedIconCircle(
                icon: subscription.icon,
                color: Color(hex: subscription.color)
            )
        }
    }
}
```

---

## State Management

### Local State (@State)

```swift
struct AddSubscriptionView: View {
    @State private var name = ""
    @State private var price = ""
    @State private var selectedCategory: SubscriptionCategory = .entertainment
    @State private var showingCategoryPicker = false

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Price", text: $price)
                .keyboardType(.decimalPad)

            Button("Select Category") {
                showingCategoryPicker = true
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selection: $selectedCategory)
        }
    }
}
```

### Binding (@Binding)

```swift
struct PriceTextField: View {
    @Binding var value: Double

    var body: some View {
        TextField("Price", value: $value, format: .currency(code: "USD"))
            .keyboardType(.decimalPad)
    }
}

// Usage
struct ParentView: View {
    @State private var price: Double = 0

    var body: some View {
        PriceTextField(value: $price)
    }
}
```

### Environment Object (@EnvironmentObject)

```swift
struct SubscriptionListView: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        List(dataManager.subscriptions) { subscription in
            SubscriptionRow(subscription: subscription)
        }
    }
}
```

### State Object (@StateObject)

```swift
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
            } else {
                // Content
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}
```

---

## Navigation Patterns

### NavigationStack

```swift
struct SubscriptionsView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(subscriptions) { subscription in
                    NavigationLink(value: subscription) {
                        SubscriptionRow(subscription: subscription)
                    }
                }
            }
            .navigationDestination(for: Subscription.self) { subscription in
                SubscriptionDetailView(subscription: subscription)
            }
            .navigationTitle("Subscriptions")
        }
    }
}
```

### Sheet Presentation

```swift
struct ContentView: View {
    @State private var showAddSheet = false
    @State private var selectedSubscription: Subscription?

    var body: some View {
        List {
            // ...
        }
        .toolbar {
            Button(action: { showAddSheet = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
        }
        .sheet(item: $selectedSubscription) { subscription in
            SubscriptionDetailSheet(subscription: subscription)
        }
    }
}
```

### TabView

```swift
// ContentView.swift - Main app navigation
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
                .tag(1)

            PeopleView()
                .tabItem {
                    Label("People", systemImage: "person.2.fill")
                }
                .tag(2)

            SubscriptionsView()
                .tabItem {
                    Label("Subscriptions", systemImage: "repeat")
                }
                .tag(3)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
                .tag(4)
        }
    }
}
```

---

## Typography & Colors

### Spotify-Inspired Font System

```swift
extension Font {
    // Display fonts
    static let spotifyDisplayLarge = Font.system(size: 32, weight: .bold)
    static let spotifyDisplayMedium = Font.system(size: 24, weight: .bold)

    // Body fonts
    static let spotifyBodyLarge = Font.system(size: 17, weight: .regular)
    static let spotifyBodyMedium = Font.system(size: 15, weight: .regular)
    static let spotifyBodySmall = Font.system(size: 13, weight: .regular)

    // Number fonts (monospaced for alignment)
    static let spotifyNumberLarge = Font.system(size: 24, weight: .semibold).monospacedDigit()
    static let spotifyNumberMedium = Font.system(size: 17, weight: .semibold).monospacedDigit()
}

// Usage
Text(subscription.name)
    .font(.spotifyBodyLarge)

Text(price.asCurrency)
    .font(.spotifyNumberMedium)
```

### Wise Color Palette

```swift
extension Color {
    static let wiseBrightGreen = Color(red: 159/255, green: 232/255, blue: 112/255)
    static let wiseForestGreen = Color(red: 22/255, green: 51/255, blue: 0/255)
    static let wiseBlue = Color(red: 0/255, green: 185/255, blue: 255/255)

    static let wiseCardBackground = Color(.systemBackground).opacity(0.8)
    static let wiseSecondaryBackground = Color(.secondarySystemBackground)

    // Expense colors
    static let expenseRed = Color.red
    static let incomeGreen = Color.green
}
```

---

## Animation Patterns

### Respecting Reduce Motion

```swift
struct AnimatedCard: View {
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        CardContent()
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}
```

### List Item Animations

```swift
struct ListItemAnimation: ViewModifier {
    let delay: Double

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(
                reduceMotion ? .none : .bouncy.delay(delay),
                value: isVisible
            )
            .onAppear { isVisible = true }
    }
}

extension View {
    func listItemAnimation(delay: Double) -> some View {
        modifier(ListItemAnimation(delay: delay))
    }
}

// Usage
ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, subscription in
    SubscriptionRow(subscription: subscription)
        .listItemAnimation(delay: Double(index) * 0.05)
}
```

---

## View Modifiers

### Custom Shadow

```swift
struct SubtleShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func subtleShadow() -> some View {
        modifier(SubtleShadow())
    }
}
```

### Card Style

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
            )
            .subtleShadow()
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
```

---

## Empty, Loading, Error States

### Loading State

```swift
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.spotifyBodyMedium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### Empty State

```swift
struct EnhancedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.spotifyDisplaySmall)

                Text(message)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
}
```

### Error State

```swift
struct ErrorStateView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.spotifyDisplaySmall)

            Text(error.localizedDescription)
                .font(.spotifyBodyMedium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retryAction)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

---

## List Patterns

### Grouped List with Headers

```swift
struct SubscriptionsList: View {
    let subscriptions: [Subscription]

    var groupedByCategory: [SubscriptionCategory: [Subscription]] {
        Dictionary(grouping: subscriptions, by: { $0.category })
    }

    var body: some View {
        List {
            ForEach(Array(groupedByCategory.keys), id: \.self) { category in
                Section {
                    ForEach(groupedByCategory[category] ?? []) { subscription in
                        SubscriptionRow(subscription: subscription)
                    }
                } header: {
                    Text(category.displayName)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
```

### Swipe Actions

```swift
struct SubscriptionRow: View {
    let subscription: Subscription
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        // Row content
        UnifiedListRow(...)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    try? dataManager.deleteSubscription(id: subscription.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    // Edit action
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }
}
```

---

## Forms

```swift
struct EditSubscriptionForm: View {
    @Binding var subscription: Subscription
    @FocusState private var focusedField: Field?

    enum Field {
        case name, price
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $subscription.name)
                    .focused($focusedField, equals: .name)

                HStack {
                    Text("$")
                    TextField("Price", value: $subscription.price, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .price)
                }
            }

            Section("Billing") {
                Picker("Cycle", selection: $subscription.billingCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Text(cycle.displayName).tag(cycle)
                    }
                }

                DatePicker("Next Billing", selection: $subscription.nextBillingDate, displayedComponents: .date)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}
```

---

## Common Mistakes to Avoid

1. **Heavy computation in body**
   ```swift
   // BAD
   var body: some View {
       let sorted = items.sorted { ... } // Computed every render
   }

   // GOOD
   var sortedItems: [Item] {
       items.sorted { ... }
   }
   ```

2. **Not using @ViewBuilder for conditionals**

3. **Creating views inside closures without extracting**

4. **Not respecting accessibility settings (reduce motion)**

---

## Checklist

- [ ] Use design system components (UnifiedListRow, UnifiedCard)
- [ ] Apply correct typography (spotifyFonts)
- [ ] Use project color palette (wiseColors)
- [ ] Handle empty, loading, error states
- [ ] Respect accessibility (reduce motion, VoiceOver)
- [ ] Use appropriate state management
- [ ] Extract reusable components

---

## Industry Standards

- **Apple Human Interface Guidelines**
- **WWDC 2023-2024** - SwiftUI best practices
- **Declarative UI** principles
- **Composition over inheritance**
