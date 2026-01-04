//
//  TransactionHistoryApp.swift
//  Complete SwiftUI Transaction History App
//
//  Copy this entire file into a new Xcode project (iOS App, SwiftUI)
//  Replace the default ContentView.swift with this file
//  Minimum iOS 16.0 required
//

import SwiftUI

// MARK: - App Entry Point
@main
struct TransactionHistoryApp: App {
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
    static let borderColor = Color(red: 0.886, green: 0.906, blue: 0.925)
    static let pillBg = Color(red: 0.945, green: 0.957, blue: 0.965)
    
    // Badge colors
    static let contactBadgeBg = Color(red: 0.859, green: 0.914, blue: 1.0)
    static let contactBadgeText = Color(red: 0.114, green: 0.306, blue: 0.851)
    static let groupBadgeBg = Color(red: 0.953, green: 0.910, blue: 1.0)
    static let groupBadgeText = Color(red: 0.576, green: 0.200, blue: 0.918)
    static let subscriptionBadgeBg = Color(red: 0.996, green: 0.953, blue: 0.780)
    static let subscriptionBadgeText = Color(red: 0.702, green: 0.263, blue: 0.035)
}

// MARK: - Enums
enum EntityType: String, CaseIterable, Codable {
    case contact = "Contact"
    case group = "Group"
    case subscription = "Subscription"
}

enum TransactionType: String, CaseIterable, Codable {
    case expense = "Expense"
    case income = "Income"
}

enum FilterType: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case sent = "Sent"
    case request = "Request"
    case transfer = "Transfer"
}

enum AvatarColor: String, CaseIterable, Codable {
    case emerald, violet, rose, amber, sky, slate
    
    var background: Color {
        switch self {
        case .emerald: return Color(red: 0.820, green: 0.980, blue: 0.902)
        case .violet: return Color(red: 0.929, green: 0.914, blue: 0.992)
        case .rose: return Color(red: 1.0, green: 0.894, blue: 0.902)
        case .amber: return Color(red: 0.996, green: 0.953, blue: 0.780)
        case .sky: return Color(red: 0.878, green: 0.949, blue: 0.992)
        case .slate: return Color(red: 0.945, green: 0.957, blue: 0.965)
        }
    }
    
    var foreground: Color {
        switch self {
        case .emerald: return Color(red: 0.016, green: 0.471, blue: 0.341)
        case .violet: return Color(red: 0.427, green: 0.157, blue: 0.851)
        case .rose: return Color(red: 0.882, green: 0.114, blue: 0.290)
        case .amber: return Color(red: 0.851, green: 0.463, blue: 0.024)
        case .sky: return Color(red: 0.008, green: 0.518, blue: 0.780)
        case .slate: return Color(red: 0.278, green: 0.333, blue: 0.412)
        }
    }
    
    static func random() -> AvatarColor {
        AvatarColor.allCases.randomElement() ?? .emerald
    }
}

// MARK: - Models
struct GroupMember: Identifiable, Codable {
    var id = UUID()
    let name: String
    let initials: String
    let avatarColor: AvatarColor
}

struct InvolvedEntity: Codable {
    let type: EntityType
    let name: String
    let initials: String
    var members: [GroupMember]?
    var splitType: String?
    var yourShare: Double?
    var billingCycle: String?
    var nextBilling: String?
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    let name: String
    let time: String
    let date: String
    let category: String
    let amount: Double
    let type: TransactionType
    let initials: String
    let avatarColor: AvatarColor
    let createdBy: String
    let involvedEntity: InvolvedEntity
}

// MARK: - Transaction Store
class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        transactions = [
            Transaction(
                name: "Food",
                time: "3:14 AM",
                date: "Jan 4, 2026",
                category: "Food & Dining",
                amount: 99.00,
                type: .expense,
                initials: "FO",
                avatarColor: .emerald,
                createdBy: "You",
                involvedEntity: InvolvedEntity(type: .contact, name: "Sarah Miller", initials: "SM")
            ),
            Transaction(
                name: "Payment from James",
                time: "6:10 PM",
                date: "Jan 4, 2026",
                category: "Transfer",
                amount: 20.00,
                type: .income,
                initials: "JC",
                avatarColor: .sky,
                createdBy: "James Chen",
                involvedEntity: InvolvedEntity(type: .contact, name: "James Chen", initials: "JC")
            ),
            Transaction(
                name: "Bar",
                time: "9:06 PM",
                date: "Jan 3, 2026",
                category: "Entertainment",
                amount: 59.00,
                type: .expense,
                initials: "BA",
                avatarColor: .violet,
                createdBy: "Mike Johnson",
                involvedEntity: InvolvedEntity(
                    type: .group,
                    name: "Friday Night Out",
                    initials: "FN",
                    members: [
                        GroupMember(name: "You", initials: "YO", avatarColor: .emerald),
                        GroupMember(name: "Mike", initials: "MJ", avatarColor: .sky),
                        GroupMember(name: "Sarah", initials: "SM", avatarColor: .rose),
                        GroupMember(name: "Alex", initials: "AW", avatarColor: .amber)
                    ],
                    splitType: "Equal Split",
                    yourShare: 14.75
                )
            ),
            Transaction(
                name: "Salary",
                time: "4:21 PM",
                date: "Jan 3, 2026",
                category: "Income",
                amount: 5000.00,
                type: .income,
                initials: "AC",
                avatarColor: .emerald,
                createdBy: "Acme Corp",
                involvedEntity: InvolvedEntity(type: .contact, name: "Acme Corp", initials: "AC")
            ),
            Transaction(
                name: "Dinner",
                time: "4:21 PM",
                date: "Jan 2, 2026",
                category: "Food & Dining",
                amount: 85.00,
                type: .expense,
                initials: "DN",
                avatarColor: .rose,
                createdBy: "You",
                involvedEntity: InvolvedEntity(
                    type: .group,
                    name: "Family Dinner",
                    initials: "FD",
                    members: [
                        GroupMember(name: "You", initials: "YO", avatarColor: .emerald),
                        GroupMember(name: "Mom", initials: "MO", avatarColor: .rose),
                        GroupMember(name: "Dad", initials: "DA", avatarColor: .sky)
                    ],
                    splitType: "You Paid",
                    yourShare: 85.00
                )
            ),
            Transaction(
                name: "Groceries",
                time: "4:21 PM",
                date: "Jan 2, 2026",
                category: "Groceries",
                amount: 125.50,
                type: .expense,
                initials: "GR",
                avatarColor: .amber,
                createdBy: "You",
                involvedEntity: InvolvedEntity(
                    type: .group,
                    name: "Roommates",
                    initials: "RM",
                    members: [
                        GroupMember(name: "You", initials: "YO", avatarColor: .emerald),
                        GroupMember(name: "Tom", initials: "TB", avatarColor: .violet),
                        GroupMember(name: "Lisa", initials: "LP", avatarColor: .amber)
                    ],
                    splitType: "Equal Split",
                    yourShare: 41.83
                )
            ),
            Transaction(
                name: "Netflix",
                time: "4:21 PM",
                date: "Jan 1, 2026",
                category: "Subscription",
                amount: 15.99,
                type: .expense,
                initials: "NF",
                avatarColor: .rose,
                createdBy: "Auto",
                involvedEntity: InvolvedEntity(
                    type: .subscription,
                    name: "Netflix Premium",
                    initials: "NF",
                    billingCycle: "Monthly",
                    nextBilling: "Feb 1, 2026"
                )
            ),
            Transaction(
                name: "Rent",
                time: "4:21 PM",
                date: "Jan 1, 2026",
                category: "Bills & Utilities",
                amount: 1500.00,
                type: .expense,
                initials: "RT",
                avatarColor: .slate,
                createdBy: "You",
                involvedEntity: InvolvedEntity(type: .contact, name: "John Landlord", initials: "JL")
            ),
            Transaction(
                name: "Spotify",
                time: "2:00 PM",
                date: "Jan 1, 2026",
                category: "Subscription",
                amount: 9.99,
                type: .expense,
                initials: "SP",
                avatarColor: .emerald,
                createdBy: "Auto",
                involvedEntity: InvolvedEntity(
                    type: .subscription,
                    name: "Spotify Family",
                    initials: "SF",
                    billingCycle: "Monthly",
                    nextBilling: "Feb 1, 2026"
                )
            )
        ]
    }
    
    func filteredTransactions(filter: FilterType, searchQuery: String) -> [Transaction] {
        var filtered = transactions
        
        switch filter {
        case .all:
            break
        case .income:
            filtered = filtered.filter { $0.type == .income }
        case .sent:
            filtered = filtered.filter { $0.type == .expense && $0.involvedEntity.type == .contact }
        case .request:
            filtered = filtered.filter { $0.category == "Transfer" }
        case .transfer:
            filtered = filtered.filter { $0.category == "Transfer" || $0.involvedEntity.type == .contact }
        }
        
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.category.lowercased().contains(query) ||
                $0.involvedEntity.name.lowercased().contains(query)
            }
        }
        
        return filtered
    }
    
    func groupedByDate(filter: FilterType, searchQuery: String) -> [(String, [Transaction])] {
        let filtered = filteredTransactions(filter: filter, searchQuery: searchQuery)
        let grouped = Dictionary(grouping: filtered) { $0.date }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        return grouped.sorted { first, second in
            guard let date1 = dateFormatter.date(from: first.key),
                  let date2 = dateFormatter.date(from: second.key) else {
                return first.key > second.key
            }
            return date1 > date2
        }
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }
}

// MARK: - Helper Functions
func formatAmount(_ amount: Double, type: TransactionType) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    return type == .income ? "+$\(formatted)" : "-$\(formatted)"
}

func getInitials(_ name: String) -> String {
    let words = name.split(separator: " ")
    let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    return initials.uppercased()
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var store = TransactionStore()
    @State private var selectedTab: Tab = .feed
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
                case .subscriptions:
                    PlaceholderPageView(
                        icon: "creditcard",
                        title: "Subscriptions",
                        description: "Track and manage your recurring payments and subscriptions."
                    )
                case .feed, .add:
                    FeedView()
                        .environmentObject(store)
                }
            }
            
            BottomNavBar(selectedTab: $selectedTab, showAddSheet: $showAddSheet)
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionSheet()
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

// MARK: - Feed View
struct FeedView: View {
    @EnvironmentObject var store: TransactionStore
    @State private var selectedFilter: FilterType = .all
    @State private var searchQuery = ""
    @State private var showSearch = false
    @State private var showAddSheet = false
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Feed")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSearch.toggle()
                            if !showSearch {
                                searchQuery = ""
                            }
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
                            .shadow(color: AppColors.greenPrimary.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)
                
                if showSearch {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.system(size: 16))
                        
                        TextField("Search transactions...", text: $searchQuery)
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            FilterPillView(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
            }
            .background(AppColors.bgPrimary)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    let groupedTransactions = store.groupedByDate(filter: selectedFilter, searchQuery: searchQuery)
                    
                    if groupedTransactions.isEmpty {
                        EmptyStateView()
                            .padding(.top, 40)
                    } else {
                        ForEach(groupedTransactions, id: \.0) { date, transactions in
                            DateHeaderView(date: date)
                            
                            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                                TransactionRowView(
                                    transaction: transaction,
                                    isLastInGroup: index == transactions.count - 1
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTransaction = transaction
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
            AddTransactionSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailSheet(transaction: transaction)
                .environmentObject(store)
        }
    }
}

// MARK: - Filter Pill View
struct FilterPillView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? AppColors.textPrimary : AppColors.pillBg)
                .cornerRadius(100)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date Header View
struct DateHeaderView: View {
    let date: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(date.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.5)
            
            Rectangle()
                .fill(AppColors.borderColor)
                .frame(height: 1)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: Transaction
    let isLastInGroup: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Circle()
                    .fill(transaction.avatarColor.background)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(transaction.initials)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(transaction.avatarColor.foreground)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(transaction.time)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("·")
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text(transaction.category)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .font(.system(size: 13))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatAmount(transaction.amount, type: transaction.type))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(transaction.type == .income ? AppColors.greenPrimary : AppColors.textPrimary)
                    
                    Text(transaction.involvedEntity.name)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 16)
            
            if !isLastInGroup {
                Rectangle()
                    .fill(AppColors.borderColor)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(AppColors.textTertiary.opacity(0.5))
            
            Text("No transactions found")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Transaction Detail Sheet
struct TransactionDetailSheet: View {
    let transaction: Transaction
    @EnvironmentObject var store: TransactionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 100)
                    .fill(AppColors.borderColor)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Transaction Details")
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
                    
                    // Summary Card
                    SummaryCardView(transaction: transaction)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Info Card
                    InfoCardView(transaction: transaction)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Details Grid
                    DetailsGridView(transaction: transaction)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    
                    // Buttons
                    HStack(spacing: 10) {
                        Button(action: {
                            toastMessage = "Link copied!"
                            showToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showToast = false
                            }
                        }) {
                            Text("Share")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.pillBg)
                                .cornerRadius(12)
                        }
                        
                        Button(action: repeatTransaction) {
                            Text("Repeat")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.greenPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
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
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.hidden)
    }
    
    private func repeatTransaction() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let currentTime = timeFormatter.string(from: Date())
        
        let newTransaction = Transaction(
            name: transaction.name,
            time: currentTime,
            date: currentDate,
            category: transaction.category,
            amount: transaction.amount,
            type: transaction.type,
            initials: transaction.initials,
            avatarColor: transaction.avatarColor,
            createdBy: "You",
            involvedEntity: transaction.involvedEntity
        )
        
        store.addTransaction(newTransaction)
        toastMessage = "Repeated!"
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showToast = false
            dismiss()
        }
    }
}

// MARK: - Summary Card View
struct SummaryCardView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(transaction.avatarColor.background)
                .frame(width: 52, height: 52)
                .overlay(
                    Text(transaction.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(transaction.avatarColor.foreground)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(transaction.involvedEntity.name)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text(formatAmount(transaction.amount, type: transaction.type))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(transaction.type == .income ? AppColors.greenPrimary : AppColors.textPrimary)
        }
        .padding(14)
        .background(AppColors.bgCard)
        .cornerRadius(14)
    }
}

// MARK: - Info Card View
struct InfoCardView: View {
    let transaction: Transaction
    
    private var badgeColors: (bg: Color, text: Color) {
        switch transaction.involvedEntity.type {
        case .contact: return (AppColors.contactBadgeBg, AppColors.contactBadgeText)
        case .group: return (AppColors.groupBadgeBg, AppColors.groupBadgeText)
        case .subscription: return (AppColors.subscriptionBadgeBg, AppColors.subscriptionBadgeText)
        }
    }
    
    private var iconName: String {
        switch transaction.involvedEntity.type {
        case .contact: return "person.fill"
        case .group: return "person.3.fill"
        case .subscription: return "arrow.triangle.2.circlepath"
        }
    }
    
    private var labelText: String {
        if transaction.type == .income { return "Received From" }
        switch transaction.involvedEntity.type {
        case .contact: return "Payment To"
        case .group: return "Group Expense"
        case .subscription: return "Subscription"
        }
    }
    
    private var fromInfo: (initials: String, name: String, role: String) {
        if transaction.type == .income {
            return (transaction.involvedEntity.initials, transaction.involvedEntity.name, "Sender")
        }
        return ("You", "You", transaction.createdBy == "You" ? "Paid by You" : "Your Share")
    }
    
    private var toInfo: (initials: String, name: String, role: String) {
        if transaction.type == .income {
            return ("You", "You", "Recipient")
        }
        return (String(transaction.involvedEntity.initials.prefix(1)), transaction.involvedEntity.name, "Recipient")
    }
    
    private var infoRows: [(String, String)] {
        switch transaction.involvedEntity.type {
        case .contact:
            return [
                (transaction.type == .income ? "From" : "To", transaction.involvedEntity.name),
                ("Initiated By", transaction.createdBy)
            ]
        case .group:
            return [
                ("Created By", transaction.createdBy),
                ("Split Type", transaction.involvedEntity.splitType ?? "Equal Split"),
                ("Your Share", "$\(String(format: "%.2f", transaction.involvedEntity.yourShare ?? 0))")
            ]
        case .subscription:
            return [
                ("Billing", transaction.involvedEntity.billingCycle ?? "Monthly"),
                ("Next Billing", transaction.involvedEntity.nextBilling ?? "-")
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(badgeColors.bg)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: iconName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(badgeColors.text)
                        )
                    
                    Text(labelText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Text(transaction.involvedEntity.type.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(badgeColors.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColors.bg)
                    .cornerRadius(100)
            }
            .padding(.bottom, 12)
            
            Rectangle()
                .fill(AppColors.borderColor)
                .frame(height: 1)
                .padding(.bottom, 12)
            
            // Flow Row
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppColors.greenLight)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(fromInfo.initials)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.greenPrimary)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(fromInfo.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(fromInfo.role)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("$\(String(format: "%.2f", transaction.amount))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(toInfo.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(toInfo.role)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Circle()
                        .fill(Color(red: 0.878, green: 0.949, blue: 0.992))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(toInfo.initials)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.008, green: 0.518, blue: 0.780))
                        )
                }
            }
            
            // Info Rows
            VStack(spacing: 8) {
                Rectangle()
                    .fill(AppColors.borderColor)
                    .frame(height: 1)
                    .padding(.top, 12)
                
                ForEach(infoRows, id: \.0) { row in
                    HStack {
                        Text(row.0)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text(row.1)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            
            // Group Members
            if transaction.involvedEntity.type == .group,
               let members = transaction.involvedEntity.members {
                Rectangle()
                    .fill(AppColors.borderColor)
                    .frame(height: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                HStack(spacing: 8) {
                    HStack(spacing: -6) {
                        ForEach(members.prefix(4)) { member in
                            Circle()
                                .fill(member.avatarColor.background)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(member.initials)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(member.avatarColor.foreground)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.bgCard, lineWidth: 2)
                                )
                        }
                    }
                    
                    Text("\(members.count) members")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(AppColors.bgCard)
        .cornerRadius(14)
    }
}

// MARK: - Details Grid View
struct DetailsGridView: View {
    let transaction: Transaction
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            DetailItemView(label: "Date", value: transaction.date)
            DetailItemView(label: "Time", value: transaction.time)
            DetailItemView(label: "Category", value: transaction.category)
            DetailItemView(label: "Status", value: "Completed", isSuccess: true)
        }
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
        .padding(10)
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

// MARK: - Add Transaction Sheet
struct AddTransactionSheet: View {
    @EnvironmentObject var store: TransactionStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var transactionType: TransactionType = .expense
    @State private var name = ""
    @State private var amount = ""
    @State private var category = "Food & Dining"
    @State private var entityType: EntityType = .contact
    @State private var entityName = ""
    @State private var showToast = false
    
    let categories = ["Food & Dining", "Entertainment", "Transfer", "Income", "Groceries", "Subscription", "Bills & Utilities"]
    
    private var placeholderText: String {
        switch entityType {
        case .contact: return "Enter contact name"
        case .group: return "Enter group name"
        case .subscription: return "Enter subscription name"
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 100)
                    .fill(AppColors.borderColor)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("New Transaction")
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
                            // Type Toggle
                            FormSectionView(label: "Type") {
                                HStack(spacing: 0) {
                                    ForEach(TransactionType.allCases, id: \.self) { type in
                                        Button(action: { transactionType = type }) {
                                            Text(type.rawValue)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(transactionType == type ? AppColors.textPrimary : AppColors.textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(transactionType == type ? AppColors.bgPrimary : Color.clear)
                                                .cornerRadius(8)
                                                .shadow(color: transactionType == type ? Color.black.opacity(0.1) : .clear, radius: 2, y: 1)
                                        }
                                    }
                                }
                                .padding(3)
                                .background(AppColors.pillBg)
                                .cornerRadius(10)
                            }
                            
                            // Name
                            FormSectionView(label: "Name") {
                                TextField("e.g., Coffee, Salary", text: $name)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColors.bgPrimary)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                            }
                            
                            // Amount & Category
                            HStack(spacing: 10) {
                                FormSectionView(label: "Amount") {
                                    TextField("0.00", text: $amount)
                                        .font(.system(size: 14))
                                        .keyboardType(.decimalPad)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                }
                                
                                FormSectionView(label: "Category") {
                                    Menu {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(cat) { category = cat }
                                        }
                                    } label: {
                                        HStack {
                                            Text(category)
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
                            }
                            
                            // Transaction With
                            FormSectionView(label: "Transaction With") {
                                VStack(spacing: 10) {
                                    HStack(spacing: 6) {
                                        ForEach(EntityType.allCases, id: \.self) { type in
                                            Button(action: { entityType = type }) {
                                                Text(type.rawValue)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(entityType == type ? AppColors.greenPrimary : AppColors.textSecondary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(entityType == type ? AppColors.greenLight : AppColors.bgPrimary)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(entityType == type ? AppColors.greenPrimary : AppColors.borderColor, lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    
                                    TextField(placeholderText, text: $entityName)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                }
                            }
                            
                            // Submit
                            Button(action: addTransaction) {
                                Text("Add Transaction")
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
                ToastView(message: "Transaction added!")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.hidden)
    }
    
    private func addTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let currentTime = timeFormatter.string(from: Date())
        
        let finalEntityName = entityName.isEmpty ? "Personal" : entityName
        
        var involvedEntity = InvolvedEntity(
            type: entityType,
            name: finalEntityName,
            initials: getInitials(finalEntityName)
        )
        
        if entityType == .group {
            involvedEntity.members = [GroupMember(name: "You", initials: "YO", avatarColor: .emerald)]
            involvedEntity.splitType = "Equal Split"
            involvedEntity.yourShare = amountValue
        } else if entityType == .subscription {
            involvedEntity.billingCycle = "Monthly"
            involvedEntity.nextBilling = "Next month"
        }
        
        let newTransaction = Transaction(
            name: name,
            time: currentTime,
            date: currentDate,
            category: category,
            amount: amountValue,
            type: transactionType,
            initials: getInitials(name),
            avatarColor: AvatarColor.random(),
            createdBy: entityType == .subscription ? "Auto" : "You",
            involvedEntity: involvedEntity
        )
        
        store.addTransaction(newTransaction)
        
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
