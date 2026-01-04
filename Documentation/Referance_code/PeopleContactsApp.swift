//
//  PeopleContactsApp.swift
//  Complete SwiftUI People/Contacts App
//
//  Copy this entire file into a new Xcode project (iOS App, SwiftUI)
//  Replace the default ContentView.swift with this file
//  Minimum iOS 16.0 required
//

import SwiftUI

// MARK: - App Entry Point
@main
struct PeopleContactsApp: App {
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
enum ContactStatus: String, CaseIterable {
    case owesYou = "owes-you"
    case youOwe = "you-owe"
    case settled = "settled"
    
    var displayText: String {
        switch self {
        case .owesYou: return "Owes you"
        case .youOwe: return "You owe"
        case .settled: return "Settled"
        }
    }
}

enum ContactFilter: String, CaseIterable {
    case all = "All"
    case owesYou = "Owes You"
    case youOwe = "You Owe"
    case settled = "Settled"
    case active = "Active"
}

enum PeopleTab: String, CaseIterable {
    case people = "People"
    case groups = "Groups"
}

enum AvatarColor: String, CaseIterable, Codable {
    case gray, yellow, emerald, violet, rose, amber, sky, slate
    
    var background: Color {
        switch self {
        case .gray: return Color(red: 0.886, green: 0.910, blue: 0.925)
        case .yellow: return Color(red: 0.996, green: 0.941, blue: 0.541)
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
        case .gray: return Color(red: 0.392, green: 0.455, blue: 0.545)
        case .yellow: return Color(red: 0.631, green: 0.384, blue: 0.027)
        case .emerald: return Color(red: 0.016, green: 0.471, blue: 0.341)
        case .violet: return Color(red: 0.427, green: 0.157, blue: 0.851)
        case .rose: return Color(red: 0.882, green: 0.114, blue: 0.290)
        case .amber: return Color(red: 0.851, green: 0.463, blue: 0.024)
        case .sky: return Color(red: 0.008, green: 0.518, blue: 0.780)
        case .slate: return Color(red: 0.278, green: 0.333, blue: 0.412)
        }
    }
    
    static func random() -> AvatarColor {
        AvatarColor.allCases.randomElement() ?? .gray
    }
}

// MARK: - Models
struct RecentTransaction: Identifiable, Codable {
    var id = UUID()
    let name: String
    let date: String
    let amount: Double
}

struct Contact: Identifiable {
    var id = UUID()
    let name: String
    let initials: String
    let avatarColor: AvatarColor
    var balance: Double
    var status: ContactStatus
    var recentTransactions: [RecentTransaction]
    
    var lastTransactionInfo: String {
        if let lastTx = recentTransactions.first {
            let dateParts = lastTx.date.split(separator: ",")
            let shortDate = String(dateParts.first ?? "")
            return "\(shortDate) · \(lastTx.name)"
        }
        return "No activity"
    }
}

struct Group: Identifiable {
    var id = UUID()
    let name: String
    let members: Int
    var balance: Double
    var status: ContactStatus
    var recentTransactions: [RecentTransaction]
    
    var lastTransactionInfo: String {
        if let lastTx = recentTransactions.first {
            let dateParts = lastTx.date.split(separator: ",")
            let shortDate = String(dateParts.first ?? "")
            return "\(shortDate) · \(lastTx.name)"
        }
        return "\(members) members"
    }
}

// MARK: - Data Store
class PeopleStore: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var groups: [Group] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        contacts = [
            Contact(
                name: "James Chen",
                initials: "JC",
                avatarColor: .gray,
                balance: -39.00,
                status: .youOwe,
                recentTransactions: [
                    RecentTransaction(name: "Snapchat Premium", date: "Dec 20, 2025", amount: -39.00)
                ]
            ),
            Contact(
                name: "Emma Wilson",
                initials: "EW",
                avatarColor: .yellow,
                balance: 316.00,
                status: .owesYou,
                recentTransactions: [
                    RecentTransaction(name: "Dinner Split", date: "Dec 28, 2025", amount: 45.00),
                    RecentTransaction(name: "Movie Tickets", date: "Dec 20, 2025", amount: 30.00),
                    RecentTransaction(name: "Concert Tickets", date: "Dec 15, 2025", amount: 120.00),
                    RecentTransaction(name: "Groceries", date: "Dec 10, 2025", amount: 121.00)
                ]
            ),
            Contact(
                name: "Michael Taylor",
                initials: "MT",
                avatarColor: .yellow,
                balance: -92.73,
                status: .youOwe,
                recentTransactions: [
                    RecentTransaction(name: "Uber Ride", date: "Dec 22, 2025", amount: -32.73),
                    RecentTransaction(name: "Lunch", date: "Dec 18, 2025", amount: -60.00)
                ]
            ),
            Contact(
                name: "Sofia Rodriguez",
                initials: "SR",
                avatarColor: .gray,
                balance: 0,
                status: .settled,
                recentTransactions: []
            ),
            Contact(
                name: "David Park",
                initials: "DP",
                avatarColor: .emerald,
                balance: 25.50,
                status: .owesYou,
                recentTransactions: [
                    RecentTransaction(name: "Coffee Run", date: "Dec 27, 2025", amount: 25.50)
                ]
            ),
            Contact(
                name: "Lisa Thompson",
                initials: "LT",
                avatarColor: .violet,
                balance: -15.00,
                status: .youOwe,
                recentTransactions: [
                    RecentTransaction(name: "Parking", date: "Dec 19, 2025", amount: -15.00)
                ]
            )
        ]
        
        groups = [
            Group(
                name: "Friday Night Out",
                members: 4,
                balance: -14.75,
                status: .youOwe,
                recentTransactions: [
                    RecentTransaction(name: "Bar Tab", date: "Jan 3, 2026", amount: -14.75)
                ]
            ),
            Group(
                name: "Roommates",
                members: 3,
                balance: 45.00,
                status: .owesYou,
                recentTransactions: [
                    RecentTransaction(name: "Groceries Split", date: "Jan 2, 2026", amount: 45.00)
                ]
            ),
            Group(
                name: "Family Dinner",
                members: 3,
                balance: 0,
                status: .settled,
                recentTransactions: [
                    RecentTransaction(name: "Restaurant Bill", date: "Dec 25, 2025", amount: 0)
                ]
            )
        ]
    }
    
    var totalOwedToYou: Double {
        contacts.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
    }
    
    var totalYouOwe: Double {
        contacts.filter { $0.balance < 0 }.reduce(0) { $0 + abs($1.balance) }
    }
    
    func filteredContacts(filter: ContactFilter, searchQuery: String) -> [Contact] {
        var filtered = contacts
        
        switch filter {
        case .all:
            break
        case .owesYou:
            filtered = filtered.filter { $0.status == .owesYou }
        case .youOwe:
            filtered = filtered.filter { $0.status == .youOwe }
        case .settled:
            filtered = filtered.filter { $0.status == .settled }
        case .active:
            filtered = filtered.filter { $0.status != .settled }
        }
        
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }
        
        return filtered
    }
    
    func filteredGroups(filter: ContactFilter) -> [Group] {
        switch filter {
        case .all:
            return groups
        case .owesYou:
            return groups.filter { $0.status == .owesYou }
        case .youOwe:
            return groups.filter { $0.status == .youOwe }
        case .settled:
            return groups.filter { $0.status == .settled }
        case .active:
            return groups.filter { $0.status != .settled }
        }
    }
    
    func addContact(_ contact: Contact) {
        contacts.insert(contact, at: 0)
    }
    
    func settleContact(id: UUID) {
        if let index = contacts.firstIndex(where: { $0.id == id }) {
            contacts[index].balance = 0
            contacts[index].status = .settled
        }
    }
}

// MARK: - Helper Functions
func formatBalance(_ balance: Double) -> String {
    let abs = abs(balance)
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    let formatted = formatter.string(from: NSNumber(value: abs)) ?? String(format: "%.2f", abs)
    
    if balance > 0 { return "+$\(formatted)" }
    if balance < 0 { return "-$\(formatted)" }
    return "$\(formatted)"
}

func getInitials(_ name: String) -> String {
    let words = name.split(separator: " ")
    let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    return initials.uppercased()
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var store = PeopleStore()
    @State private var selectedTab: Tab = .people
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
                    PeopleView()
                        .environmentObject(store)
                case .subscriptions:
                    PlaceholderPageView(
                        icon: "creditcard",
                        title: "Subscriptions",
                        description: "Track and manage your recurring payments and subscriptions."
                    )
                case .feed, .add:
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
            AddContactSheet()
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
                
                NavBarItem(icon: "person.2.fill", label: "People", isSelected: selectedTab == .people) {
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

// MARK: - People View
struct PeopleView: View {
    @EnvironmentObject var store: PeopleStore
    @State private var selectedTab: PeopleTab = .people
    @State private var selectedFilter: ContactFilter = .all
    @State private var searchQuery = ""
    @State private var showSearch = false
    @State private var showAddSheet = false
    @State private var selectedContact: Contact?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("People")
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
                TabToggleView(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Summary Cards
                SummaryCardsView(owedToYou: store.totalOwedToYou, youOwe: store.totalYouOwe)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Search Bar
                if showSearch {
                    SearchBarView(searchQuery: $searchQuery)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ContactFilter.allCases, id: \.self) { filter in
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
                .padding(.bottom, 8)
            }
            .background(AppColors.bgPrimary)
            
            // Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    if selectedTab == .people {
                        let filteredContacts = store.filteredContacts(filter: selectedFilter, searchQuery: searchQuery)
                        
                        if filteredContacts.isEmpty {
                            EmptyStateView(icon: "person.2", message: "No contacts found")
                                .padding(.top, 40)
                        } else {
                            ForEach(Array(filteredContacts.enumerated()), id: \.element.id) { index, contact in
                                ContactRowView(
                                    contact: contact,
                                    isLast: index == filteredContacts.count - 1
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedContact = contact
                                }
                            }
                        }
                    } else {
                        let filteredGroups = store.filteredGroups(filter: selectedFilter)
                        
                        if filteredGroups.isEmpty {
                            EmptyStateView(icon: "person.3", message: "No groups found")
                                .padding(.top, 40)
                        } else {
                            ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { index, group in
                                GroupRowView(
                                    group: group,
                                    isLast: index == filteredGroups.count - 1
                                )
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
            AddContactSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedContact) { contact in
            ContactDetailSheet(contact: contact)
                .environmentObject(store)
        }
    }
}

// MARK: - Tab Toggle View
struct TabToggleView: View {
    @Binding var selectedTab: PeopleTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PeopleTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab == .people ? "person.2" : "person.3")
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
    let owedToYou: Double
    let youOwe: Double
    
    var body: some View {
        HStack(spacing: 12) {
            SummaryCardView(
                icon: "arrow.down",
                iconBgColor: AppColors.greenLight,
                iconColor: AppColors.greenPrimary,
                label: "OWED TO YOU",
                amount: owedToYou
            )
            
            SummaryCardView(
                icon: "arrow.up",
                iconBgColor: AppColors.redLight,
                iconColor: AppColors.redPrimary,
                label: "YOU OWE",
                amount: youOwe
            )
        }
    }
}

struct SummaryCardView: View {
    let icon: String
    let iconBgColor: Color
    let iconColor: Color
    let label: String
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Circle()
                .fill(iconBgColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(iconColor)
                )
                .padding(.bottom, 12)
            
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.5)
                .padding(.bottom, 4)
            
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 24, weight: .bold))
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
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchQuery: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 16))
            
            TextField("Search contacts...", text: $searchQuery)
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

// MARK: - Contact Row View
struct ContactRowView: View {
    let contact: Contact
    let isLast: Bool
    
    var balanceColor: Color {
        switch contact.status {
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
                    .fill(contact.avatarColor.background)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(contact.initials)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(contact.avatarColor.foreground)
                    )
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(contact.lastTransactionInfo)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                // Balance
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatBalance(contact.balance))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(balanceColor)
                    
                    Text(contact.status.displayText)
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

// MARK: - Group Row View
struct GroupRowView: View {
    let group: Group
    let isLast: Bool
    
    var balanceColor: Color {
        switch group.status {
        case .owesYou: return AppColors.greenPrimary
        case .youOwe: return AppColors.textPrimary
        case .settled: return AppColors.textTertiary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Group Avatar
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.greenLight)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.greenPrimary)
                    )
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(group.lastTransactionInfo)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                // Balance
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatBalance(group.balance))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(balanceColor)
                    
                    Text(group.status.displayText)
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

// MARK: - Contact Detail Sheet
struct ContactDetailSheet: View {
    let contact: Contact
    @EnvironmentObject var store: PeopleStore
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var owesYou: Double { contact.balance > 0 ? contact.balance : 0 }
    var youOwe: Double { contact.balance < 0 ? abs(contact.balance) : 0 }
    
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
                        Text("Contact Details")
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
                    
                    // Profile Card
                    VStack(spacing: 0) {
                        Circle()
                            .fill(contact.avatarColor.background)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(contact.initials)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(contact.avatarColor.foreground)
                            )
                            .padding(.bottom, 12)
                        
                        Text(contact.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 4)
                        
                        Text(contact.lastTransactionInfo)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppColors.bgCard)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Balance Summary
                    HStack(spacing: 12) {
                        BalanceCardView(
                            label: "They Owe You",
                            amount: owesYou,
                            amountColor: owesYou > 0 ? AppColors.greenPrimary : AppColors.textTertiary
                        )
                        
                        BalanceCardView(
                            label: "You Owe Them",
                            amount: youOwe,
                            amountColor: youOwe > 0 ? AppColors.textPrimary : AppColors.textTertiary
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT ACTIVITY")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textTertiary)
                            .tracking(0.5)
                        
                        VStack(spacing: 0) {
                            if contact.recentTransactions.isEmpty {
                                HStack {
                                    Text("No recent activity")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textTertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            } else {
                                ForEach(Array(contact.recentTransactions.prefix(3).enumerated()), id: \.element.id) { index, transaction in
                                    VStack(spacing: 0) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(transaction.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(AppColors.textPrimary)
                                                
                                                Text(transaction.date)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppColors.textTertiary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(formatBalance(transaction.amount))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(transaction.amount > 0 ? AppColors.greenPrimary : AppColors.textPrimary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        
                                        if index < min(contact.recentTransactions.count, 3) - 1 {
                                            Rectangle()
                                                .fill(AppColors.borderColor)
                                                .frame(height: 1)
                                        }
                                    }
                                }
                            }
                        }
                        .background(AppColors.bgCard)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Action Buttons
                    HStack(spacing: 10) {
                        if contact.status != .settled {
                            Button(action: {
                                toastMessage = "Reminder sent!"
                                showToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showToast = false
                                }
                            }) {
                                Text(contact.status == .owesYou ? "Remind" : "Request Reminder")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.pillBg)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            store.settleContact(id: contact.id)
                            toastMessage = "Settled up!"
                            showToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showToast = false
                                dismiss()
                            }
                        }) {
                            Text(contact.status == .settled ? "Add Transaction" : (contact.status == .owesYou ? "Settle Up" : "Pay Now"))
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
        .presentationDetents([.height(580)])
        .presentationDragIndicator(.hidden)
    }
}

struct BalanceCardView: View {
    let label: String
    let amount: Double
    let amountColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.3)
            
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(amountColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.bgCard)
        .cornerRadius(12)
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

// MARK: - Add Contact Sheet
struct AddContactSheet: View {
    @EnvironmentObject var store: PeopleStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var balance = ""
    @State private var direction = "settled"
    @State private var showToast = false
    
    private var isFormValid: Bool {
        !name.isEmpty
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
                        Text("Add Contact")
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
                                TextField("Enter contact name", text: $name)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColors.bgPrimary)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                            }
                            
                            // Email
                            FormSectionView(label: "Email (Optional)") {
                                TextField("Enter email address", text: $email)
                                    .font(.system(size: 14))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColors.bgPrimary)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                            }
                            
                            // Phone
                            FormSectionView(label: "Phone (Optional)") {
                                TextField("Enter phone number", text: $phone)
                                    .font(.system(size: 14))
                                    .keyboardType(.phonePad)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColors.bgPrimary)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                            }
                            
                            // Balance & Direction
                            HStack(spacing: 10) {
                                FormSectionView(label: "Initial Balance") {
                                    TextField("0.00", text: $balance)
                                        .font(.system(size: 14))
                                        .keyboardType(.decimalPad)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.bgPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderColor, lineWidth: 1))
                                }
                                
                                FormSectionView(label: "Direction") {
                                    Menu {
                                        Button("Settled") { direction = "settled" }
                                        Button("They Owe You") { direction = "owes-you" }
                                        Button("You Owe Them") { direction = "you-owe" }
                                    } label: {
                                        HStack {
                                            Text(direction == "settled" ? "Settled" : (direction == "owes-you" ? "They Owe You" : "You Owe Them"))
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
                            
                            // Submit
                            Button(action: addContact) {
                                Text("Add Contact")
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
                ToastView(message: "Contact added!")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.hidden)
    }
    
    private func addContact() {
        let balanceValue = Double(balance) ?? 0
        var finalBalance: Double = 0
        var status: ContactStatus = .settled
        
        if direction == "owes-you" && balanceValue > 0 {
            finalBalance = balanceValue
            status = .owesYou
        } else if direction == "you-owe" && balanceValue > 0 {
            finalBalance = -balanceValue
            status = .youOwe
        }
        
        let newContact = Contact(
            name: name,
            initials: getInitials(name),
            avatarColor: AvatarColor.random(),
            balance: finalBalance,
            status: status,
            recentTransactions: []
        )
        
        store.addContact(newContact)
        
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
