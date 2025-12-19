# Performance Optimization

## Purpose
Guide performance optimization strategies, monitoring, and best practices to ensure smooth user experience and efficient resource usage.

## When to Use This Skill
- Optimizing slow operations
- Implementing caching
- Profiling performance issues
- Handling large datasets
- Reducing memory usage

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Cold launch | < 2 seconds |
| Warm launch | < 0.5 seconds |
| List scroll | 60 fps with 500+ items |
| Import 5000 items | < 60 seconds |
| Memory growth | < 100MB over time |
| Analytics calculation | < 500ms |

---

## Caching Strategies

### Time-Based Cache (AnalyticsService)

```swift
// Services/AnalyticsService.swift
@MainActor
class AnalyticsService: ObservableObject {
    // Cache with 5-minute timeout
    private var cache: [String: CachedResult] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    struct CachedResult {
        let value: Any
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }

    func calculateMonthlySpending(months: Int = 6) -> [MonthlySpending] {
        let cacheKey = "monthly_spending_\(months)"

        // Check cache first
        if let cached = cache[cacheKey], !cached.isExpired {
            return cached.value as! [MonthlySpending]
        }

        // Perform expensive calculation
        let result = performExpensiveCalculation(months: months)

        // Store in cache
        cache[cacheKey] = CachedResult(value: result, timestamp: Date())

        return result
    }

    func invalidateCache() {
        cache.removeAll()
    }

    // Invalidate specific keys when data changes
    func invalidateSpendingCache() {
        cache.removeValue(forKey: "monthly_spending_6")
        cache.removeValue(forKey: "monthly_spending_12")
    }
}
```

### Memory Cache with NSCache

```swift
class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 100 // Max 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, for key: String) {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func removeImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
```

---

## Debouncing

### Debouncer Class

```swift
// Services/Debouncer.swift
actor Debouncer {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func debounce(_ action: @escaping () async -> Void) {
        // Cancel previous task
        task?.cancel()

        // Schedule new task
        task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await action()
            } catch {
                // Task was cancelled
            }
        }
    }
}
```

### DebouncedState Property Wrapper

```swift
// Utilities/DebouncedState.swift
@propertyWrapper
struct DebouncedState<Value>: DynamicProperty {
    @State private var currentValue: Value
    @State private var debouncedValue: Value
    private let delay: TimeInterval

    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        _currentValue = State(initialValue: wrappedValue)
        _debouncedValue = State(initialValue: wrappedValue)
        self.delay = delay
    }

    var wrappedValue: Value {
        get { currentValue }
        nonmutating set {
            currentValue = newValue
            debounce()
        }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { currentValue },
            set: { newValue in
                currentValue = newValue
                debounce()
            }
        )
    }

    private func debounce() {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            debouncedValue = currentValue
        }
    }
}

// Usage in search
struct SearchView: View {
    @DebouncedState(delay: 0.3) private var searchText = ""

    var body: some View {
        TextField("Search", text: $searchText)
            .onChange(of: searchText) { _, newValue in
                performSearch(newValue)
            }
    }
}
```

---

## Lazy Loading

### LazyVStack for Lists

```swift
struct SubscriptionsList: View {
    let subscriptions: [Subscription]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(subscriptions) { subscription in
                    SubscriptionRow(subscription: subscription)
                }
            }
            .padding()
        }
    }
}
```

### Pagination

```swift
struct PaginatedList: View {
    @State private var items: [Item] = []
    @State private var isLoading = false
    @State private var hasMore = true
    private let pageSize = 20

    var body: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)
                    .onAppear {
                        loadMoreIfNeeded(currentItem: item)
                    }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func loadMoreIfNeeded(currentItem: Item) {
        guard !isLoading, hasMore else { return }

        // Load more when near end
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if let currentIndex = items.firstIndex(where: { $0.id == currentItem.id }),
           currentIndex >= thresholdIndex {
            loadNextPage()
        }
    }

    private func loadNextPage() {
        isLoading = true
        Task {
            let newItems = await fetchItems(offset: items.count, limit: pageSize)
            items.append(contentsOf: newItems)
            hasMore = newItems.count == pageSize
            isLoading = false
        }
    }
}
```

---

## Task Management

### Task Cancellation

```swift
// Utilities/TaskCancellationManager.swift
actor TaskCancellationManager {
    private var tasks: [String: Task<Void, Never>] = [:]

    func register(_ task: Task<Void, Never>, for key: String) {
        // Cancel existing task with same key
        tasks[key]?.cancel()
        tasks[key] = task
    }

    func cancel(key: String) {
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
    }

    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

// Usage in service
class DataService {
    private let taskManager = TaskCancellationManager()

    func search(_ query: String) {
        let task = Task {
            guard !Task.isCancelled else { return }
            let results = await performSearch(query)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.searchResults = results
            }
        }

        Task {
            await taskManager.register(task, for: "search")
        }
    }
}
```

### Async Timeout

```swift
// Utilities/AsyncTimeoutManager.swift
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }

        guard let result = try await group.next() else {
            throw TimeoutError()
        }

        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {}

// Usage
let data = try await withTimeout(seconds: 10) {
    try await fetchData()
}
```

---

## Memory Optimization

### Avoiding Retain Cycles

```swift
class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: .dataDidChange)
            .sink { [weak self] _ in
                self?.handleDataChange()
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
```

### Image Optimization

```swift
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func compressed(quality: CGFloat = 0.7) -> Data? {
        jpegData(compressionQuality: quality)
    }
}

// Usage for avatars
func processAvatarImage(_ image: UIImage) -> Data? {
    let maxSize = CGSize(width: 200, height: 200)
    let resized = image.resized(to: maxSize)
    return resized.compressed(quality: 0.8)
}
```

---

## SwiftUI Performance

### Computed Properties vs Methods

```swift
struct SubscriptionListView: View {
    @EnvironmentObject var dataManager: DataManager

    // GOOD: Computed property evaluated only when needed
    var activeSubscriptions: [Subscription] {
        dataManager.subscriptions.filter { $0.isActive }
    }

    // GOOD: Use id for ForEach
    var body: some View {
        List {
            ForEach(activeSubscriptions, id: \.id) { subscription in
                SubscriptionRow(subscription: subscription)
            }
        }
    }
}
```

### Avoiding Unnecessary Redraws

```swift
// Use EquatableView for expensive views
struct ExpensiveChartView: View, Equatable {
    let data: [ChartDataPoint]

    var body: some View {
        // Complex chart rendering
    }

    static func == (lhs: ExpensiveChartView, rhs: ExpensiveChartView) -> Bool {
        lhs.data == rhs.data
    }
}

// Usage with .equatable()
ExpensiveChartView(data: chartData)
    .equatable()
```

### Extract Subviews

```swift
// BAD: Inline everything
var body: some View {
    VStack {
        // 100 lines of code
    }
}

// GOOD: Extract components
var body: some View {
    VStack {
        HeaderView(title: title)
        ContentView(items: items)
        FooterView(action: action)
    }
}
```

---

## Database Performance

### Batch Operations

```swift
func importSubscriptions(_ subscriptions: [Subscription]) async throws {
    // Process in batches
    let batchSize = 50

    for batch in subscriptions.chunked(into: batchSize) {
        try autoreleasepool {
            for subscription in batch {
                let model = SubscriptionModel(from: subscription)
                modelContext.insert(model)
            }
            try modelContext.save()
        }

        // Allow UI updates
        await Task.yield()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

### Efficient Predicates

```swift
// BAD: Fetch all then filter
let all = try modelContext.fetch(FetchDescriptor<SubscriptionModel>())
let active = all.filter { $0.isActive }

// GOOD: Filter in query
let descriptor = FetchDescriptor<SubscriptionModel>(
    predicate: #Predicate { $0.isActive == true }
)
let active = try modelContext.fetch(descriptor)
```

---

## Profiling with Instruments

### Key Instruments

1. **Time Profiler** - Find slow code paths
2. **Allocations** - Track memory usage
3. **Leaks** - Find memory leaks
4. **Core Animation** - Profile UI performance
5. **Network** - Analyze network calls

### Adding Signposts

```swift
import os.signpost

let log = OSLog(subsystem: "com.swiff", category: "performance")

func expensiveOperation() {
    let signpostID = OSSignpostID(log: log)

    os_signpost(.begin, log: log, name: "Expensive Operation", signpostID: signpostID)

    // Perform operation
    calculateAnalytics()

    os_signpost(.end, log: log, name: "Expensive Operation", signpostID: signpostID)
}
```

---

## Common Mistakes to Avoid

1. **Fetching all data when filtering in memory**
2. **Not using lazy loading for lists**
3. **Heavy computation on main thread**
4. **Not cancelling tasks when views disappear**
5. **Retain cycles in closures**
6. **Storing full-resolution images**

---

## Checklist

- [ ] Use `LazyVStack`/`LazyHStack` for lists
- [ ] Implement caching for expensive calculations
- [ ] Debounce user input (search, form fields)
- [ ] Cancel tasks when views disappear
- [ ] Use weak references in closures
- [ ] Batch database operations
- [ ] Compress and resize images
- [ ] Profile with Instruments

---

## Industry Standards

- **Apple WWDC** - Performance optimization sessions
- **Instruments** profiling
- **60 fps** UI target
- **<100ms** perceived latency
- **Lazy evaluation** principles
