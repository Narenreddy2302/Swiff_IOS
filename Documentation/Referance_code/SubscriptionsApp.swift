//
//  SubscriptionsApp.swift
//  Complete SwiftUI Subscriptions App
//
//  Copy this entire file into a new Xcode project (iOS App, SwiftUI)
//  Replace the default ContentView.swift with this file
//  Minimum iOS 16.0 required
//

import SwiftUI

// MARK: - App Entry Point
@main
struct SubscriptionsApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Color Theme
struct AppColors {
    static let bgPrimary = Color.white
    static let bgCard = Color(red: 0.973, green: 0.980, blue: 0.988)
    static let textPrimary = Color(red: 0.059, green: 0.090, blue: 0.165)
    static let textSecondary = Color(red: 0.392, green: 0.455, blue: 0.545)
    static let textTertiary = Color(red: 0.580, green: 0.639, blue: 0.722)
    static let greenPrimary = Color(red: 0.020, green: 0.588, blue: 0.412)
    static let greenLight = Color(red: 0.820, green: 0.980, blue: 0.902)
    static let redPrimary = Color(red: 0.863, green: 0.149, blue: 0.149)
    static let redLight = Color(red: 0.996, green: 0.886, blue: 0.886)
    static let borderColor = Color(red: 0.886, green: 0.906, blue: 0.925)
    static let pillBg = Color(red: 0.945, green: 0.957, blue: 0.965)
}

// MARK: - Enums
enum SubscriptionTab: String, CaseIterable {
    case personal = "Personal"
    case shared = "Shared"
}

enum SubscriptionCategory: String, CaseIterable {
    case all = "All"
    case entertainment = "Entertainment"
    case productivity = "Productivity"
    case health = "Health"
    case utilities = "Utilities"
    case food = "Food"
    
    var color: Color {
        switch self {
        case .all: return AppColors.textTertiary
        case .entertainment: return Color(red: 0.769, green: 0.710, blue: 0.992)
        case .productivity: return Color(red: 0.988, green: 0.827, blue: 0.302)
        case .health: return Color(red: 0.973, green: 0.443, blue: 0.443)
        case .utilities: return Color(red: 0.376, green: 0.647, blue: 0.980)
        case .food: return Color(red: 0.290, green: 0.870, blue: 0.502)
        }
    }
}

enum BalanceStatus: String {
    case owesYou = "owes-you"
    case youOwe = "you-owe"
    case settled = "settled"
    
    var displayText: String {
        switch self {
        case .owesYou: return "They owe you"
        case .youOwe: return "You owe"
        case .settled: return "Settled"
        }
    }
}

enum BillingCycle: String, CaseIterable {
    case monthly = "Monthly"
    case yearly = "Yearly"
    case weekly = "Weekly"
}

enum AvatarColor: String, CaseIterable, Codable {
    case green, violet, gray, yellow, rose, sky, amber, emerald
    
    var background: Color {
        switch self {
        case .green: return Color(red: 0.820, green: 0.980, blue: 0.902)
        case .violet: return Color(red: 0.929, green: 0.914, blue: 0.992)
        case .gray: return Color(red: 0.886, green: 0.910, blue: 0.925)
        case .yellow: return Color(red: 0.996, green: 0.941, blue: 0.541)
        case .rose: return Color(red: 1.0, green: 0.894, blue: 0.902)
        case .sky: return Color(red: 0.878, green: 0.949, blue: 0.992)
        case .amber: return Color(red: 0.996, green: 0.953, blue: 0.780)
        case .emerald: return Color(red: 0.820, green: 0.980, blue: 0.902)
        }
    }
    
    var foreground: Color {
        switch self {
        case .green: return Color(red: 0.016, green: 0.471, blue: 0.341)
        case .violet: return Color(red: 0.427, green: 0.157, blue: 0.851)
        case .gray: return Color(red: 0.392, green: 0.455, blue: 0.545)
        case .yellow: return Color(red: 0.631, green: 0.384, blue: 0.027)
        case .rose: return Color(red: 0.882, green: 0.114, blue: 0.290)
        case .sky: return Color(red: 0.008, green: 0.518, blue: 0.780)
        case .amber: return Color(red: 0.851, green: 0.463, blue: 0.024)
        case .emerald: return Color(red: 0.016, green: 0.471, blue: 0.341)
        }
    }
    
    static func random() -> AvatarColor {
        AvatarColor.allCases.randomElement() ?? .green
    }
}

// MARK: - Models
struct PaymentHistory: Identifiable, Codable {
    var id = UUID()
    let date: String
    let amount: Double
}

struct SharedMember: Identifiable, Codable {
    var id = UUID()
    let name: String
    let initials: String
    let avatarColor: AvatarColor
}

struct Subscription: Identifiable {
    var id = UUID()
    let name: String
    let initials: String
    let avatarColor: AvatarColor
    let price: Double
    let nextBilling: String
    let nextBillingFull: String
    let cycle: BillingCycle
    let category: SubscriptionCategory
    let payer: String
    let isShared: Bool
    var yourShare: Double?
    var balance: Double?
    var balanceStatus: BalanceStatus?
    var members: [SharedMember]?
    var history: [PaymentHistory]
    
    var cycleAndNextBilling: String {
        "\(cycle.rawValue) · Next: \(nextBilling)"
    }
}

// MARK: - Data Store
class SubscriptionStore: ObservableObject {
    @Published var personalSubscriptions: [Subscription] = []
    @Published var sharedSubscriptions: [Subscription] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        personalSubscriptions = [
            Subscription(
                name: "Netflix",
                initials: "NE",
                avatarColor: .green,
                price: 19.99,
                nextBilling: "Jan 22",
                nextBillingFull: "Jan 22, 2026",
                cycle: .monthly,
                category: .entertainment,
                payer: "You",
                isShared: false,
                history: [
                    PaymentHistory(date: "Dec 22, 2025", amount: 19.99),
                    PaymentHistory(date: "Nov 22, 2025", amount: 19.99),
                    PaymentHistory(date: "Oct 22, 2025", amount: 19.99)
                ]
            ),
            Subscription(
                name: "Moviebox Pro",
                initials: "MP",
                avatarColor: .violet,
                price: 2.50,
                nextBilling: "Nov 28",
                nextBillingFull: "Nov 28, 2025",
                cycle: .monthly,
                category: .entertainment,
                payer: "You",
                isShared: false,
                history: [
                    PaymentHistory(date: "Oct 28, 2025", amount: 2.50),
                    PaymentHistory(date: "Sep 28, 2025", amount: 2.50)
                ]
            ),
            Subscription(
                name: "Gym Membership",
                initials: "GM",
                avatarColor: .yellow,
                price: 49.99,
                nextBilling: "Nov 29",
                nextBillingFull: "Nov 29, 2025",
                cycle: .monthly,
                category: .health,
                payer: "You",
                isShared: false,
                history: [
                    PaymentHistory(date: "Oct 29, 2025", amount: 49.99),
                    PaymentHistory(date: "Sep 29, 2025", amount: 49.99)
                ]
            ),
            Subscription(
                name: "Spotify",
                initials: "SP",
                avatarColor: .gray,
                price: 9.99,
                nextBilling: "Dec 14",
                nextBillingFull: "Dec 14, 2025",
                cycle: .monthly,
                category: .entertainment,
                payer: "You",
                isShared: false,
                history: [
                    PaymentHistory(date: "Nov 14, 2025", amount: 9.99),
                    PaymentHistory(date: "Oct 14, 2025", amount: 9.99)
                ]
            ),
            Subscription(
                name: "Netflix",
                initials: "NE",
                avatarColor: .violet,
                price: 15.99,
                nextBilling: "Dec 9",
                nextBillingFull: "Dec 9, 2025",
                cycle: .monthly,
                category: .entertainment,
                payer: "You",
                isShared: false,
                history: [
                    PaymentHistory(date: "Nov 9, 2025", amount: 15.99)
                ]
            ),
            Subscription(
                name: "iCloud Storage",
                initials: "IC",
                avatarColor: .sky,
                price: 2.99,
                nextBilling: "Jan 1",
                nextBillingFull: "Jan 1, 2026",
                cycle: .monthly,
                category: .utilities,
                payer: "You",
                isShared: false,
                history: [
                    PaymentHistory(date: "Dec 1, 2025", amount: 2.99)
                ]
            )
        ]
        
        sharedSubscriptions = [
            Subscription(
                name: "YouTube Premium",
                initials: "YT",
                avatarColor: .rose,
                price: 22.99,
                nextBilling: "Jan 15",
                nextBillingFull: "Jan 15, 2026",
                cycle: .monthly,
                category: .entertainment,
                payer: "Family",
                isShared: true,
                yourShare: 5.75,
                balance: 0,
                balanceStatus: .settled,
                members: [
                    SharedMember(name: "You", initials: "YO", avatarColor: .green),
                    SharedMember(name: "Mom", initials: "MO", avatarColor: .rose),
                    SharedMember(name: "Dad", initials: "DA", avatarColor: .sky),
                    SharedMember(name: "Sis", initials: "SI", avatarColor: .violet)
                ],
                history: [
                    PaymentHistory(date: "Dec 15, 2025", amount: 22.99)
                ]
            ),
            Subscription(
                name: "Disney+",
                initials: "D+",
                avatarColor: .sky,
                price: 13.99,
                nextBilling: "Jan 20",
                nextBillingFull: "Jan 20, 2026",
                cycle: .monthly,
                category: .entertainment,
                payer: "Shared",
                isShared: true,
                yourShare: 4.66,
                balance: 4.66,
                balanceStatus: .owesYou,
                members: [
                    SharedMember(name: "You", initials: "YO", avatarColor: .green),
                    SharedMember(name: "James", initials: "JC", avatarColor: .gray),
                    SharedMember(name: "Emma", initials: "EW", avatarColor: .yellow)
                ],
                history: [
                    PaymentHistory(date: "Dec 20, 2025", amount: 13.99)
                ]
            ),
            Subscription(
                name: "Spotify Family",
                initials: "SF",
                avatarColor: .green,
                price: 16.99,
                nextBilling: "Jan 5",
                nextBillingFull: "Jan 5, 2026",
                cycle: .monthly,
                category: .entertainment,
                payer: "Shared",
                isShared: true,
                yourShare: 3.40,
                balance: -3.40,
                balanceStatus: .youOwe,
                members: [
                    SharedMember(name: "Mike", initials: "MJ", avatarColor: .sky),
                    SharedMember(name: "You", initials: "YO", avatarColor: .green),
                    SharedMember(name: "Sarah", initials: "SM", avatarColor: .rose),
                    SharedMember(name: "Alex", initials: "AW", avatarColor: .amber),
                    SharedMember(name: "Tom", initials: "TB", avatarColor: .violet)
                ],
                history: [
                    PaymentHistory(date: "Dec 5, 2025", amount: 16.99)
                ]
            ),
            Subscription(
                name: "Netflix",
                initials: "NF",
                avatarColor: .rose,
                price: 22.99,
                nextBilling: "Jan 12",
                nextBillingFull: "Jan 12, 2026",
                cycle: .monthly,
                category: .entertainment,
                payer: "Shared",
                isShared: true,
                yourShare: 7.66,
                balance: 7.66,
                balanceStatus: .owesYou,
                members: [
                    SharedMember(name: "You", initials: "YO", avatarColor: .green),
                    SharedMember(name: "Lisa", initials: "LT", avatarColor: .violet),
                    SharedMember(name: "David", initials: "DP", avatarColor: .emerald)
                ],
                history: [
                    PaymentHistory(date: "Dec 12, 2025", amount: 22.99)
                ]
            )
        ]
    }
    
    var totalPersonalSubscriptions: Int {
        personalSubscriptions.count
    }
    
    var monthlySpend: Double {
        personalSubscriptions.reduce(0) { total, sub in
            switch sub.cycle {
            case .monthly: return total + sub.price
            case .yearly: return total + (sub.price / 12)
            case .weekly: return total + (sub.price * 4)
            }
        }
    }
    
    func filteredPersonalSubscriptions(category: SubscriptionCategory, searchQuery: String) -> [Subscription] {
        var filtered = personalSubscriptions
        
        if category != .all {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }
        
        return filtered
    }
    
    func filteredSharedSubscriptions(category: SubscriptionCategory, searchQuery: String) -> [Subscription] {
        var filtered = sharedSubscriptions
        
        if category != .all {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }
        
        return filtered
    }
    
    func addSubscription(_ subscription: Subscription) {
        if subscription.isShared {
            sharedSubscriptions.insert(subscription, at: 0)
        } else {
            personalSubscriptions.insert(subscription, at: 0)
        }
    }
    
    func removeSubscription(id: UUID, isShared: Bool) {
        if isShared {
            sharedSubscriptions.removeAll { $0.id == id }
        } else {
            personalSubscriptions.removeAll { $0.id == id }
        }
    }
}

// MARK: - Helper Functions
func formatPrice(_ price: Double) -> String {
    return String(format: "$%.2f", price)
}

func formatBalance(_ balance: Double) -> String {
    if balance > 0 {
        return String(format: "+$%.2f", balance)
    } else if balance < 0 {
        return String(format: "-$%.2f", abs(balance))
    }
    return "$0.00"
}

func getInitials(_ name: String) -> String {
    let words = name.split(separator: " ")
    let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    return initials.uppercased()
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var store = SubscriptionStore()
    @State private var selectedTab: Tab = .subscriptions
    @State private var showAddSheet = false
    
    enum Tab: Int {
        case home, people, add, subscriptions, feed
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    PlaceholderPageView(
                        icon: "house",
                        title: "Home",
                        description: "Your dashboard overview and quick actions will appear here."
                    )
                case .people:
                    PlaceholderPageView(
                        icon: "person.2",
                        title: "People",
                        description: "Manage your contacts and see who you've transacted with."
                    )
                case .subscriptions, .add:
                    SubscriptionsView()
                        .environmentObject(store)
                case .feed:
                    PlaceholderPageView(
                        icon: "square.grid.2x2.fill",
                        title: "Feed",
                        description: "View your transaction history and activity feed."
                    )
                }
            }
            
            BottomNavBar(selectedTab: $selectedTab, showAddSheet: $showAddSheet)
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
                .environmentObject(store)
        }
    }
}

// MARK: - Placeholder Page View
struct PlaceholderPageView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppColors.textTertiary.opacity(0.5))
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bgPrimary)
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Binding var showAddSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.borderColor)
                .frame(height: 1)
            
            HStack(spacing: 0) {
                NavBarItem(icon: "house", label: "Home", isSelected: selectedTab == .home) {
                    selectedTab = .home
                }
                
                NavBarItem(icon: "person.2", label: "People", isSelected: selectedTab == .people) {
                    selectedTab = .people
                }
                
                Button(action: { showAddSheet = true }) {
                    ZStack {
                        Circle()
                            .stroke(AppColors.borderColor, lineWidth: 2)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(AppColors.bgPrimary))
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .offset(y: -4)
                
                NavBarItem(icon: "creditcard", label: "Subscriptions", isSelected: selectedTab == .subscriptions) {
                    selectedTab = .subscriptions
                }
                
                NavBarItem(icon: "square.grid.2x2.fill", label: "Feed", isSelected: selectedTab == .feed) {
                    selectedTab = .feed
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            RoundedRectangle(cornerRadius: 100)
                .fill(AppColors.textPrimary)
                .frame(width: 134, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .background(AppColors.bgPrimary)
    }
}

struct NavBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? AppColors.greenPrimary : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Subscriptions View
struct SubscriptionsView: View {
    @EnvironmentObject var store: SubscriptionStore
    @State private var selectedTab: SubscriptionTab = .personal
    @State private var selectedCategory: SubscriptionCategory = .all
    @State private var searchQuery = ""
    @State private var showSearch = false
    @State private var showAddSheet = false
    @State private var selectedSubscription: Subscription?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("Subscriptions")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSearch.toggle()
                            if !showSearch { searchQuery = "" }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 40, height: 40)
                    }
                    
                    Button(action: { showAddSheet = true }) {
                        Circle()
                            .fill(AppColors.greenPrimary)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)
                
                // Tab Toggle
                SubscriptionTabToggle(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Summary Cards
                SummaryCardsView(
                    subscriptionCount: store.totalPersonalSubscriptions,
                    monthlySpend: store.monthlySpend
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Search Bar
                if showSearch {
                    SearchBarView(searchQuery: $searchQuery, placeholder: "Search subscriptions...")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([SubscriptionCategory.all, .entertainment, .productivity, .health, .utilities], id: \.self) { category in
                            CategoryPillView(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }
            .background(AppColors.bgPrimary)
            
            // Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    if selectedTab == .personal {
                        let filtered = store.filteredPersonalSubscriptions(category: selectedCategory, searchQuery: searchQuery)
                        
                        if filtered.isEmpty {
                            EmptyStateView(icon: "creditcard", message: "No subscriptions found")
                                .padding(.top, 40)
                        } else {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, subscription in
                                PersonalSubscriptionRow(
                                    subscription: subscription,
                                    isLast: index == filtered.count - 1
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSubscription = subscription
                                }
                            }
                        }
                    } else {
                        let filtered = store.filteredSharedSubscriptions(category: selectedCategory, searchQuery: searchQuery)
                        
                        if filtered.isEmpty {
                            EmptyStateView(icon: "person.3", message: "No shared subscriptions")
                                .padding(.top, 40)
                        } else {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, subscription in
                                SharedSubscriptionRow(
                                    subscription: subscription,
                                    isLast: index == filtered.count - 1
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSubscription = subscription
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(AppColors.bgPrimary)
        }
        .background(AppColors.bgPrimary)
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedSubscription) { subscription in
            SubscriptionDetailSheet(subscription: subscription)
                .environmentObject(store)
        }
    }
}

// MARK: - Subscription Tab Toggle
struct SubscriptionTabToggle: View {
    @Binding var selectedTab: SubscriptionTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SubscriptionTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab == .personal ? "person" : "person.2")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab ? .white : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? AppColors.textPrimary : Color.clear)
                    .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(AppColors.pillBg)
        .cornerRadius(12)
    }
}

// MARK: - Summary Cards View
struct SummaryCardsView: View {
    let subscriptionCount: Int
    let monthlySpend: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Subscriptions Card
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.greenLight)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "creditcard")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.greenPrimary)
                        )
                    
                    Spacer()
                    
                    // Down badge
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                        Text("2.1%")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppColors.redPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.redLight)
                    .cornerRadius(100)
                }
                .padding(.bottom, 12)
                
                Text("SUBSCRIPTIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .tracking(0.5)
                    .padding(.bottom, 4)
                
                Text("\(subscriptionCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppColors.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.borderColor, lineWidth: 1)
            )
            
            // Monthly Spend Card
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.greenLight)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.greenPrimary)
                        )
                    
                    Spacer()
                    
                    // Up badge
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8, weight: .bold))
                        Text("5.2%")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppColors.greenPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.greenLight)
                    .cornerRadius(100)
                }
                .padding(.bottom, 12)
                
                Text("MONTHLY SPEND")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .tracking(0.5)
                    .padding(.bottom, 4)
                
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("$\(Int(monthlySpend))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("/mo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppColors.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchQuery: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 16))
            
            TextField(placeholder, text: $searchQuery)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Category Pill View
struct CategoryPillView: View {
    let category: SubscriptionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if category == .all {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14, weight: .medium))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color)
                        .frame(width: 18, height: 18)
                }
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? AppColors.textPrimary : AppColors.bgPrimary)
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(isSelected ? Color.clear : AppColors.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Personal Subscription Row
struct PersonalSubscriptionRow: View {
    let subscription: Subscription
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Avatar
                Circle()
                    .fill(subscription.avatarColor.background)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(subscription.initials)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(subscription.avatarColor.foreground)
                    )
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subscription.cycleAndNextBilling)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatPrice(subscription.price))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subscription.payer)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 16)
            
            if !isLast {
                Rectangle()
                    .fill(AppColors.borderColor)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Shared Subscription Row
struct SharedSubscriptionRow: View {
    let subscription: Subscription
    let isLast: Bool
    
    var balanceColor: Color {
        guard let status = subscription.balanceStatus else { return AppColors.textTertiary }
        switch status {
        case .owesYou: return AppColors.greenPrimary
        case .youOwe: return AppColors.textPrimary
        case .settled: return AppColors.textTertiary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Avatar
                Circle()
                    .fill(subscription.avatarColor.background)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(subscription.initials)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(subscription.avatarColor.foreground)
                    )
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subscription.cycleAndNextBilling)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                // Balance and Members
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatBalance(subscription.balance ?? 0))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(balanceColor)
                    
                    // Member Avatars
                    if let members = subscription.members {
                        SharedMembersView(members: members)
                    }
                }
            }
            .padding(.vertical, 16)
            
            if !isLast {
                Rectangle()
                    .fill(AppColors.borderColor)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Shared Members View
struct SharedMembersView: View {
    let members: [SharedMember]
    let maxVisible = 3
    
    var body: some View {
        HStack(spacing: -6) {
            ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.element.id) { index, member in
                Circle()
                    .fill(member.avatarColor.background)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(member.initials)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(member.avatarColor.foreground)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            if members.count > maxVisible {
                Text("+\(members.count - maxVisible)")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50, weight: .light))
                .foregroundColor(AppColors.textTertiary.opacity(0.5))
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Subscription Detail Sheet
struct SubscriptionDetailSheet: View {
    let subscription: Subscription
    @EnvironmentObject var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 100)
                    .fill(AppColors.borderColor)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Subscription Details")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(AppColors.pillBg)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Profile Card
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(subscription.avatarColor.background)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Text(subscription.initials)
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(subscription.avatarColor.foreground)
                                    )
                                    .padding(.bottom, 12)
                                
                                Text(subscription.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.bottom, 4)
                                
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(subscription.category.color)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(subscription.category.rawValue)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(AppColors.bgCard)
                            .cornerRadius(16)
                            
                            // Billing Cards
                            HStack(spacing: 12) {
                                BillingCardView(label: "Monthly Cost", value: formatPrice(subscription.price))
                                BillingCardView(label: "Yearly Cost", value: formatPrice(subscription.price * 12))
                            }
                            
                            // Details Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                DetailItemView(label: "Next Billing", value: subscription.nextBillingFull)
                                DetailItemView(label: "Billing Cycle", value: subscription.cycle.rawValue)
                                DetailItemView(label: "Paid By", value: subscription.payer)
                                DetailItemView(label: "Status", value: "Active", isSuccess: true)
                            }
                            
                            // Payment History
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PAYMENT HISTORY")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textTertiary)
                                    .tracking(0.5)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(subscription.history.prefix(3).enumerated()), id: \.element.id) { index, payment in
                                        VStack(spacing: 0) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(payment.date)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(AppColors.textPrimary)
                                                    
                                                    Text("Paid")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(AppColors.greenPrimary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(formatPrice(payment.amount))
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(AppColors.textPrimary)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 12)
                                            
                                            if index < min(subscription.history.count, 3) - 1 {
                                                Rectangle()
                                                    .fill(AppColors.borderColor)
                                                    .frame(height: 1)
                                            }
                                        }
                                    }
                                }
                                .background(AppColors.bgCard)
                                .cornerRadius(12)
                            }
                            
                            // Action Buttons
                            HStack(spacing: 10) {
                                Button(action: {
                                    store.removeSubscription(id: subscription.id, isShared: subscription.isShared)
                                    toastMessage = "Subscription cancelled"
                                    showToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        showToast = false
                                        dismiss()
                                    }
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.redPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppColors.redLight)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    toastMessage = "Edit feature coming soon"
                                    showToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showToast = false
                                    }
                                }) {
                                    Text("Edit")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppColors.greenPrimary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(AppColors.bgPrimary)
            
            if showToast {
                ToastView(message: toastMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .presentationDetents([.height(640)])
        .presentationDragIndicator(.hidden)
    }
}

struct BillingCardView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.3)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.bgCard)
        .cornerRadius(12)
    }
}

struct DetailItemView: View {
    let label: String
    let value: String
    var isSuccess: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppColors.textTertiary)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSuccess ? AppColors.greenPrimary : AppColors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.bgCard)
        .cornerRadius(10)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.textPrimary)
            .cornerRadius(10)
    }
}

// MARK: - Add Subscription Sheet
struct AddSubscriptionSheet: View {
    @EnvironmentObject var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var price = ""
    @State private var cycle: BillingCycle = .monthly
    @State private var category: SubscriptionCategory = .entertainment
    @State private var nextBillingDate = Date()
    @State private var isShared = false
    @State private var showToast = false
    
    private var isFormValid: Bool {
        !name.isEmpty && !price.isEmpty && Double(price) != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 100)
                    .fill(AppColors.borderColor)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Add Subscription")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(AppColors.pillBg)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 14) {
                            // Name
                            FormSectionView(label: "Name") {
                                TextField("e.g., Netflix, Spotify", text: $name)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColors.bgPrimary)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                            }
                            
                            // Price & Cycle
                            HStack(spacing: 10) {
                                FormSectionView(label: "Price") {
                                    TextField("0.00", text: $price)
                                        .font(.system(size: 14))
                                        .keyboardType(.decimalPad)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                }
                                
                                FormSectionView(label: "Billing Cycle") {
                                    Menu {
                                        ForEach(BillingCycle.allCases, id: \.self) { c in
                                            Button(c.rawValue) { cycle = c }
                                        }
                                    } label: {
                                        HStack {
                                            Text(cycle.rawValue)
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                    }
                                }
                            }
                            
                            // Category & Next Billing
                            HStack(spacing: 10) {
                                FormSectionView(label: "Category") {
                                    Menu {
                                        ForEach([SubscriptionCategory.entertainment, .productivity, .health, .utilities, .food], id: \.self) { cat in
                                            Button(cat.rawValue) { category = cat }
                                        }
                                    } label: {
                                        HStack {
                                            Text(category.rawValue)
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textPrimary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                    }
                                }
                                
                                FormSectionView(label: "Next Billing") {
                                    DatePicker("", selection: $nextBillingDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                }
                            }
                            
                            // Type
                            FormSectionView(label: "Type") {
                                HStack(spacing: 0) {
                                    Button(action: { isShared = false }) {
                                        Text("Personal")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(!isShared ? AppColors.textPrimary : AppColors.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(!isShared ? AppColors.bgPrimary : Color.clear)
                                            .cornerRadius(8)
                                            .shadow(color: !isShared ? Color.black.opacity(0.1) : .clear, radius: 2, y: 1)
                                    }
                                    
                                    Button(action: { isShared = true }) {
                                        Text("Shared")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(isShared ? AppColors.textPrimary : AppColors.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(isShared ? AppColors.bgPrimary : Color.clear)
                                            .cornerRadius(8)
                                            .shadow(color: isShared ? Color.black.opacity(0.1) : .clear, radius: 2, y: 1)
                                    }
                                }
                                .padding(3)
                                .background(AppColors.pillBg)
                                .cornerRadius(10)
                            }
                            
                            // Submit
                            Button(action: addSubscription) {
                                Text("Add Subscription")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isFormValid ? AppColors.greenPrimary : AppColors.greenPrimary.opacity(0.5))
                                    .cornerRadius(12)
                            }
                            .disabled(!isFormValid)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(AppColors.bgPrimary)
            
            if showToast {
                ToastView(message: "Subscription added!")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.hidden)
    }
    
    private func addSubscription() {
        guard let priceValue = Double(price) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let shortDate = dateFormatter.string(from: nextBillingDate)
        
        dateFormatter.dateFormat = "MMM d, yyyy"
        let fullDate = dateFormatter.string(from: nextBillingDate)
        
        let newSubscription = Subscription(
            name: name,
            initials: getInitials(name),
            avatarColor: AvatarColor.random(),
            price: priceValue,
            nextBilling: shortDate,
            nextBillingFull: fullDate,
            cycle: cycle,
            category: category,
            payer: isShared ? "Shared" : "You",
            isShared: isShared,
            yourShare: isShared ? priceValue : nil,
            balance: isShared ? 0 : nil,
            balanceStatus: isShared ? .settled : nil,
            members: isShared ? [SharedMember(name: "You", initials: "YO", avatarColor: .green)] : nil,
            history: []
        )
        
        store.addSubscription(newSubscription)
        
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showToast = false
            dismiss()
        }
    }
}

// MARK: - Form Section View
struct FormSectionView<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            content()
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
