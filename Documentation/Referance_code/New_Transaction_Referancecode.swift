//
//  FinanceQuickActionView.swift
//  PersonalFinanceApp
//
//  A comprehensive Quick Action Button component for creating transactions
//  with support for splitting expenses between friends and groups.
//
//  Features:
//  - Create income/expense transactions
//  - Split transactions with friends or groups
//  - Multiple split methods (equal, amounts, percentages, shares, adjustments)
//  - Inline search for contacts and groups
//  - iOS native design following Apple Human Interface Guidelines
//
//  Created with SwiftUI for iOS 17+
//

import SwiftUI

// MARK: - ============================================================
// MARK: DATA MODELS
// MARK: ============================================================

/// Represents a contact/friend in the app
/// Used for both payers and participants in split transactions
struct Friend: Identifiable, Hashable {
    let id: String                    // Unique identifier
    let name: String                  // Display name
    let initials: String              // Two-letter initials for avatar
    let email: String?                // Optional email for search
    let isCurrentUser: Bool           // Flag to identify the logged-in user
    
    /// Convenience computed property to get display name
    /// Returns "You" for the current user, otherwise returns the full name
    var displayName: String {
        isCurrentUser ? "You" : name
    }
    
    /// Returns the first name only (for compact displays)
    var firstName: String {
        isCurrentUser ? "You" : (name.components(separatedBy: " ").first ?? name)
    }
}

/// Represents a group of friends
/// Groups can be selected to quickly add multiple participants
struct Group: Identifiable, Hashable {
    let id: String                    // Unique identifier
    let name: String                  // Group name (e.g., "Roommates")
    let icon: String                  // Emoji icon for the group
    let memberIds: [String]           // Array of Friend IDs in this group
    let color: Color                  // Theme color for the group
}

/// Supported currencies with their symbols and display information
struct Currency: Identifiable, Hashable {
    let id: String                    // Currency code (e.g., "USD")
    let code: String                  // Same as id, for display
    let symbol: String                // Currency symbol (e.g., "$")
    let name: String                  // Full name (e.g., "US Dollar")
    let flag: String                  // Country flag emoji
}

/// Transaction categories for organizing expenses/income
struct Category: Identifiable, Hashable {
    let id: String                    // Unique identifier
    let name: String                  // Category name
    let icon: String                  // Emoji icon
    let color: Color                  // Theme color
}

/// Available methods for splitting a transaction
enum SplitMethod: String, CaseIterable, Identifiable {
    case equal = "equal"              // Split evenly among all participants
    case amounts = "amounts"          // Each person pays a specific amount
    case percentages = "percentages"  // Each person pays a percentage
    case shares = "shares"            // Split by number of shares
    case adjustment = "adjustment"    // Equal split with +/- adjustments
    
    var id: String { rawValue }
    
    /// Display name for the split method
    var displayName: String {
        switch self {
        case .equal: return "Equally"
        case .amounts: return "By Amount"
        case .percentages: return "By Percent"
        case .shares: return "By Shares"
        case .adjustment: return "Adjustments"
        }
    }
    
    /// Icon/symbol representing the split method
    var icon: String {
        switch self {
        case .equal: return "="
        case .amounts: return "$"
        case .percentages: return "%"
        case .shares: return "÷"
        case .adjustment: return "±"
        }
    }
}

/// Type of transaction
enum TransactionType: String, CaseIterable {
    case expense = "expense"
    case income = "income"
}

/// Stores the calculated split details for each participant
struct SplitDetail {
    var amount: Double = 0            // Calculated amount this person owes/paid
    var percentage: Double = 0        // Percentage of total (for display)
    var shares: Int = 1               // Number of shares (for shares method)
    var adjustment: Double = 0        // Adjustment amount (for adjustment method)
}


// MARK: - ============================================================
// MARK: SAMPLE DATA
// MARK: ============================================================

/// Sample data provider for preview and testing
/// In production, this would be replaced with actual data from your backend
struct SampleData {
    
    /// Sample friends/contacts list
    static let friends: [Friend] = [
        Friend(id: "u1", name: "You", initials: "ME", email: nil, isCurrentUser: true),
        Friend(id: "u2", name: "Sarah Chen", initials: "SC", email: "sarah.chen@email.com", isCurrentUser: false),
        Friend(id: "u3", name: "Mike Johnson", initials: "MJ", email: "mike.j@email.com", isCurrentUser: false),
        Friend(id: "u4", name: "Emma Wilson", initials: "EW", email: "emma.w@email.com", isCurrentUser: false),
        Friend(id: "u5", name: "James Lee", initials: "JL", email: "james.lee@email.com", isCurrentUser: false),
        Friend(id: "u6", name: "Priya Patel", initials: "PP", email: "priya.p@email.com", isCurrentUser: false),
        Friend(id: "u7", name: "David Kim", initials: "DK", email: "david.kim@email.com", isCurrentUser: false),
        Friend(id: "u8", name: "Lisa Wang", initials: "LW", email: "lisa.wang@email.com", isCurrentUser: false),
    ]
    
    /// Sample groups
    static let groups: [Group] = [
        Group(id: "g1", name: "Roommates", icon: "🏠", memberIds: ["u1", "u2", "u3"], color: .orange),
        Group(id: "g2", name: "Trip to Bali", icon: "✈️", memberIds: ["u1", "u4", "u5", "u6"], color: .blue),
        Group(id: "g3", name: "Office Lunch", icon: "🍕", memberIds: ["u1", "u2", "u5"], color: .red),
        Group(id: "g4", name: "Family", icon: "👨‍👩‍👧‍👦", memberIds: ["u1", "u7", "u8"], color: .green),
        Group(id: "g5", name: "Book Club", icon: "📚", memberIds: ["u1", "u2", "u4", "u6"], color: .purple),
    ]
    
    /// Supported currencies
    static let currencies: [Currency] = [
        Currency(id: "USD", code: "USD", symbol: "$", name: "US Dollar", flag: "🇺🇸"),
        Currency(id: "EUR", code: "EUR", symbol: "€", name: "Euro", flag: "🇪🇺"),
        Currency(id: "GBP", code: "GBP", symbol: "£", name: "British Pound", flag: "🇬🇧"),
        Currency(id: "INR", code: "INR", symbol: "₹", name: "Indian Rupee", flag: "🇮🇳"),
        Currency(id: "JPY", code: "JPY", symbol: "¥", name: "Japanese Yen", flag: "🇯🇵"),
        Currency(id: "AUD", code: "AUD", symbol: "A$", name: "Australian Dollar", flag: "🇦🇺"),
    ]
    
    /// Transaction categories
    static let categories: [Category] = [
        Category(id: "food", name: "Food & Drinks", icon: "🍽️", color: .orange),
        Category(id: "transport", name: "Transport", icon: "🚗", color: .blue),
        Category(id: "shopping", name: "Shopping", icon: "🛍️", color: .pink),
        Category(id: "entertainment", name: "Entertainment", icon: "🎬", color: .purple),
        Category(id: "bills", name: "Bills", icon: "📄", color: .indigo),
        Category(id: "health", name: "Health", icon: "💊", color: .red),
        Category(id: "travel", name: "Travel", icon: "✈️", color: .green),
        Category(id: "other", name: "Other", icon: "📦", color: .gray),
    ]
    
    /// Helper function to find a friend by ID
    static func friend(byId id: String) -> Friend? {
        friends.first { $0.id == id }
    }
}


// MARK: - ============================================================
// MARK: VIEW MODEL
// MARK: ============================================================

/// Main ViewModel that manages all state for the Quick Action flow
/// Uses @Observable macro (iOS 17+) for automatic SwiftUI updates
@Observable
class QuickActionViewModel {
    
    // MARK: - Sheet State
    
    /// Controls whether the bottom sheet is visible
    var isSheetPresented: Bool = false
    
    /// Current step in the multi-step form (1, 2, or 3)
    var currentStep: Int = 1
    
    // MARK: - Step 1: Basic Transaction Details
    
    /// Type of transaction (expense or income)
    var transactionType: TransactionType = .expense
    
    /// Transaction amount as string (for text field binding)
    var amountString: String = ""
    
    /// Selected currency
    var selectedCurrency: Currency = SampleData.currencies[0]
    
    /// Transaction description/name
    var transactionName: String = ""
    
    /// Selected category (optional)
    var selectedCategory: Category? = nil
    
    /// Controls currency picker visibility
    var showCurrencyPicker: Bool = false
    
    /// Controls category picker visibility
    var showCategoryPicker: Bool = false
    
    // MARK: - Step 2: Split Configuration
    
    /// Whether this transaction should be split with others
    var isSplit: Bool = false
    
    /// ID of the person who paid
    var paidByUserId: String = "u1"
    
    /// IDs of all participants in the split
    var participantIds: Set<String> = ["u1"]
    
    /// Currently selected group (if any)
    var selectedGroup: Group? = nil
    
    // MARK: - Step 2: Search States
    
    /// Search text for "Paid By" search
    var paidBySearchText: String = ""
    
    /// Whether "Paid By" search is active
    var isPaidBySearchFocused: Bool = false
    
    /// Search text for "Split With" search
    var splitWithSearchText: String = ""
    
    /// Whether "Split With" search is active
    var isSplitWithSearchFocused: Bool = false
    
    // MARK: - Step 3: Split Method Details
    
    /// Selected method for splitting the transaction
    var splitMethod: SplitMethod = .equal
    
    /// Custom split details for each participant (for non-equal splits)
    /// Key: User ID, Value: SplitDetail
    var splitDetails: [String: SplitDetail] = [:]
    
    // MARK: - Computed Properties
    
    /// Converts amount string to Double
    var amount: Double {
        Double(amountString) ?? 0
    }
    
    /// Gets the Friend object for the current payer
    var paidByFriend: Friend? {
        SampleData.friend(byId: paidByUserId)
    }
    
    /// Validates Step 1 can proceed
    /// Requires: valid amount > 0 and non-empty transaction name
    var canProceedStep1: Bool {
        amount > 0 && !transactionName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Validates Step 2 can proceed
    /// For splits: requires at least 2 participants
    var canProceedStep2: Bool {
        !isSplit || participantIds.count >= 2
    }
    
    /// Validates Step 3 / Final submission
    /// Checks if split values add up correctly
    var canSubmit: Bool {
        guard isSplit else { return true }
        
        switch splitMethod {
        case .percentages:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.percentage ?? 0)
            }
            return abs(total - 100) < 0.01
            
        case .amounts:
            let total = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.amount ?? 0)
            }
            return abs(total - amount) < 0.01
            
        default:
            return true
        }
    }
    
    /// Total percentage entered (for percentage split validation)
    var totalPercentage: Double {
        participantIds.reduce(0.0) { sum, id in
            sum + (splitDetails[id]?.percentage ?? 0)
        }
    }
    
    /// Total amount entered (for amount split validation)
    var totalSplitAmount: Double {
        let splits = calculateSplits()
        return splits.values.reduce(0.0) { $0 + $1.amount }
    }
    
    // MARK: - Filtered Search Results
    
    /// Filters friends based on "Paid By" search text
    var filteredPaidByContacts: [Friend] {
        guard !paidBySearchText.isEmpty else { return SampleData.friends }
        
        let search = paidBySearchText.lowercased()
        return SampleData.friends.filter { friend in
            friend.name.lowercased().contains(search) ||
            friend.initials.lowercased().contains(search) ||
            (friend.email?.lowercased().contains(search) ?? false)
        }
    }
    
    /// Filters friends based on "Split With" search text
    var filteredSplitWithContacts: [Friend] {
        guard !splitWithSearchText.isEmpty else { return SampleData.friends }
        
        let search = splitWithSearchText.lowercased()
        return SampleData.friends.filter { friend in
            friend.name.lowercased().contains(search) ||
            friend.initials.lowercased().contains(search) ||
            (friend.email?.lowercased().contains(search) ?? false)
        }
    }
    
    /// Filters groups based on "Split With" search text
    var filteredSplitWithGroups: [Group] {
        guard !splitWithSearchText.isEmpty else { return SampleData.groups }
        
        let search = splitWithSearchText.lowercased()
        return SampleData.groups.filter { group in
            group.name.lowercased().contains(search)
        }
    }
    
    // MARK: - Actions
    
    /// Opens the quick action sheet
    func openSheet() {
        isSheetPresented = true
    }
    
    /// Closes the sheet and resets all form data
    func closeSheet() {
        isSheetPresented = false
        resetForm()
    }
    
    /// Resets all form fields to their default values
    func resetForm() {
        currentStep = 1
        transactionType = .expense
        amountString = ""
        selectedCurrency = SampleData.currencies[0]
        transactionName = ""
        selectedCategory = nil
        showCurrencyPicker = false
        showCategoryPicker = false
        isSplit = false
        paidByUserId = "u1"
        participantIds = ["u1"]
        selectedGroup = nil
        paidBySearchText = ""
        isPaidBySearchFocused = false
        splitWithSearchText = ""
        isSplitWithSearchFocused = false
        splitMethod = .equal
        splitDetails = [:]
    }
    
    /// Navigates to the next step
    func nextStep() {
        if currentStep < 3 {
            currentStep += 1
        }
    }
    
    /// Navigates to the previous step
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    /// Selects a payer from search results
    /// Also adds the payer to participants if not already included
    func selectPayer(_ userId: String) {
        paidByUserId = userId
        paidBySearchText = ""
        isPaidBySearchFocused = false
        
        // Ensure payer is also a participant
        if !participantIds.contains(userId) {
            participantIds.insert(userId)
        }
    }
    
    /// Toggles a participant's inclusion in the split
    func toggleParticipant(_ userId: String) {
        // Prevent removing yourself if you're the only participant
        if userId == "u1" && participantIds.contains("u1") && participantIds.count == 1 {
            return
        }
        
        if participantIds.contains(userId) {
            participantIds.remove(userId)
            splitDetails.removeValue(forKey: userId)
            // Clear selected group when manually deselecting
            selectedGroup = nil
        } else {
            participantIds.insert(userId)
        }
    }
    
    /// Selects a group and adds all its members to participants
    func selectGroup(_ group: Group) {
        selectedGroup = group
        
        // Add all group members to participants
        for memberId in group.memberIds {
            participantIds.insert(memberId)
        }
        
        // Clear search
        splitWithSearchText = ""
        isSplitWithSearchFocused = false
    }
    
    /// Clears the selected group (but keeps individual participants)
    func clearSelectedGroup() {
        selectedGroup = nil
    }
    
    /// Adds a participant from search results
    func addParticipantFromSearch(_ userId: String) {
        participantIds.insert(userId)
        splitWithSearchText = ""
    }
    
    /// Updates split detail for a specific user
    func updateSplitDetail(userId: String, amount: Double? = nil, percentage: Double? = nil, shares: Int? = nil, adjustment: Double? = nil) {
        var detail = splitDetails[userId] ?? SplitDetail()
        
        if let amount = amount { detail.amount = amount }
        if let percentage = percentage { detail.percentage = percentage }
        if let shares = shares { detail.shares = shares }
        if let adjustment = adjustment { detail.adjustment = adjustment }
        
        splitDetails[userId] = detail
    }
    
    /// Calculates the split amounts for all participants based on the selected method
    func calculateSplits() -> [String: SplitDetail] {
        let total = amount
        let count = Double(participantIds.count)
        
        guard count > 0 && total > 0 else { return [:] }
        
        var result: [String: SplitDetail] = [:]
        
        switch splitMethod {
        case .equal:
            // Equal split: everyone pays the same amount
            let equalShare = total / count
            let percentage = 100.0 / count
            for userId in participantIds {
                result[userId] = SplitDetail(amount: equalShare, percentage: percentage, shares: 1, adjustment: 0)
            }
            
        case .amounts:
            // Amount split: use the manually entered amounts
            for userId in participantIds {
                let customAmount = splitDetails[userId]?.amount ?? 0
                let percentage = total > 0 ? (customAmount / total) * 100 : 0
                result[userId] = SplitDetail(amount: customAmount, percentage: percentage, shares: 1, adjustment: 0)
            }
            
        case .percentages:
            // Percentage split: calculate amount from percentage
            for userId in participantIds {
                let percentage = splitDetails[userId]?.percentage ?? 0
                let calculatedAmount = (percentage / 100.0) * total
                result[userId] = SplitDetail(amount: calculatedAmount, percentage: percentage, shares: 1, adjustment: 0)
            }
            
        case .shares:
            // Shares split: proportional to number of shares
            let totalShares = participantIds.reduce(0) { sum, id in
                sum + (splitDetails[id]?.shares ?? 1)
            }
            
            for userId in participantIds {
                let shares = splitDetails[userId]?.shares ?? 1
                let shareAmount = (Double(shares) / Double(totalShares)) * total
                let percentage = (Double(shares) / Double(totalShares)) * 100
                result[userId] = SplitDetail(amount: shareAmount, percentage: percentage, shares: shares, adjustment: 0)
            }
            
        case .adjustment:
            // Adjustment split: equal base + individual adjustments
            let totalAdjustments = participantIds.reduce(0.0) { sum, id in
                sum + (splitDetails[id]?.adjustment ?? 0)
            }
            let adjustedBase = (total - totalAdjustments) / count
            
            for userId in participantIds {
                let adjustment = splitDetails[userId]?.adjustment ?? 0
                let finalAmount = adjustedBase + adjustment
                let percentage = total > 0 ? (finalAmount / total) * 100 : 0
                result[userId] = SplitDetail(amount: finalAmount, percentage: percentage, shares: 1, adjustment: adjustment)
            }
        }
        
        return result
    }
    
    /// Submits the transaction
    /// In production, this would save to your backend
    func submitTransaction() {
        let splits = calculateSplits()
        
        // Build transaction object
        let transaction: [String: Any] = [
            "type": transactionType.rawValue,
            "amount": amount,
            "currency": selectedCurrency.code,
            "name": transactionName,
            "category": selectedCategory?.id ?? "",
            "isSplit": isSplit,
            "paidBy": isSplit ? paidByUserId : "",
            "participants": isSplit ? Array(participantIds) : [],
            "splitMethod": isSplit ? splitMethod.rawValue : "",
            "splits": isSplit ? splits : [:],
            "createdAt": Date()
        ]
        
        // Log for debugging (replace with actual API call)
        print("Transaction created: \(transaction)")
        
        // Close sheet
        closeSheet()
    }
}


// MARK: - ============================================================
// MARK: MAIN VIEW
// MARK: ============================================================

/// Main container view that displays the app content and floating action button
/// This is the entry point for the Quick Action feature
struct FinanceQuickActionView: View {
    
    /// ViewModel instance managing all state
    @State private var viewModel = QuickActionViewModel()
    
    var body: some View {
        ZStack {
            // MARK: Background App Content
            // This represents your main app content behind the FAB
            AppBackgroundView(currency: viewModel.selectedCurrency)
            
            // MARK: Floating Action Button
            // Positioned at bottom-right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        viewModel.openSheet()
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        // MARK: Bottom Sheet Presentation
        .sheet(isPresented: $viewModel.isSheetPresented) {
            QuickActionSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(14)
                .interactiveDismissDisabled(false)
        }
    }
}


// MARK: - ============================================================
// MARK: FLOATING ACTION BUTTON
// MARK: ============================================================

/// The main floating action button (FAB) that triggers the quick action sheet
/// Styled as a circular blue button with a plus icon
struct FloatingActionButton: View {
    
    /// Action to perform when tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - ============================================================
// MARK: APP BACKGROUND VIEW
// MARK: ============================================================

/// Simulates the main app content behind the quick action sheet
/// Shows a wallet-style interface with balance and recent transactions
struct AppBackgroundView: View {
    
    /// Currently selected currency (for formatting)
    let currency: Currency
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: Navigation Title
                Text("Wallet")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                
                // MARK: Balance Card
                // Apple Card-style dark gradient card
                VStack(alignment: .leading, spacing: 4) {
                    // Card header
                    HStack {
                        Text("◉ Apple Card")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("💳")
                            .font(.system(size: 24))
                    }
                    .padding(.bottom, 24)
                    
                    // Balance amount
                    Text("$12,458.50")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Balance label
                    Text("Available Balance")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // MARK: Section Header
                HStack {
                    Text("Latest Transactions")
                        .font(.system(size: 20, weight: .semibold))
                    Spacer()
                    Text("See All")
                        .font(.system(size: 17))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // MARK: Transaction List
                VStack(spacing: 0) {
                    TransactionRowView(
                        icon: "🍎",
                        name: "Apple Store",
                        date: "Today",
                        amount: -999.00,
                        currency: currency
                    )
                    
                    Divider()
                        .padding(.leading, 72)
                    
                    TransactionRowView(
                        icon: "☕",
                        name: "Starbucks",
                        date: "Today",
                        amount: -6.50,
                        currency: currency
                    )
                    
                    Divider()
                        .padding(.leading, 72)
                    
                    TransactionRowView(
                        icon: "🏦",
                        name: "Salary Deposit",
                        date: "Yesterday",
                        amount: 5200.00,
                        currency: currency
                    )
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 120)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

/// Individual transaction row in the background view
struct TransactionRowView: View {
    let icon: String
    let name: String
    let date: String
    let amount: Double
    let currency: Currency
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Color(UIColor.systemGroupedBackground))
                .clipShape(Circle())
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                Text(date)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text("\(amount >= 0 ? "+" : "")\(currency.symbol)\(abs(amount), specifier: "%.2f")")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(amount >= 0 ? .green : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}


// MARK: - ============================================================
// MARK: QUICK ACTION SHEET
// MARK: ============================================================

/// Main bottom sheet container that hosts the multi-step form
/// Contains header with navigation and step indicator
struct QuickActionSheet: View {
    
    /// Shared ViewModel
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: Step Indicator Dots
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { step in
                        Circle()
                            .fill(step <= viewModel.currentStep ? Color.blue : Color(UIColor.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // MARK: Step Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.currentStep {
                        case 1:
                            Step1BasicDetailsView(viewModel: viewModel)
                        case 2:
                            Step2SplitConfigView(viewModel: viewModel)
                        case 3:
                            Step3SplitMethodView(viewModel: viewModel)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            // MARK: Navigation Bar
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button (left)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.closeSheet()
                    }
                }
                
                // Done button (right) - only shown on final step
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.currentStep == 3 || (viewModel.currentStep == 2 && !viewModel.isSplit) {
                        Button("Done") {
                            viewModel.submitTransaction()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    /// Dynamic navigation title based on current step
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case 1: return "New Transaction"
        case 2: return "Split Options"
        case 3: return "Split Details"
        default: return ""
        }
    }
}


// MARK: - ============================================================
// MARK: STEP 1: BASIC DETAILS
// MARK: ============================================================

/// First step of the form: basic transaction details
/// Includes: transaction type, amount, currency, description, category
struct Step1BasicDetailsView: View {
    
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: Transaction Type Segmented Control
            // Allows switching between Expense and Income
            Picker("Transaction Type", selection: $viewModel.transactionType) {
                Text("Expense").tag(TransactionType.expense)
                Text("Income").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            
            // MARK: Amount Input Section
            // Contains currency selector and amount text field
            HStack(spacing: 12) {
                // Currency selector button
                Button {
                    viewModel.showCurrencyPicker.toggle()
                    viewModel.showCategoryPicker = false
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.selectedCurrency.flag)
                            .font(.system(size: 20))
                        Text(viewModel.selectedCurrency.symbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGroupedBackground))
                    .cornerRadius(8)
                }
                
                // Amount text field
                TextField("0.00", text: $viewModel.amountString)
                    .font(.system(size: 48, weight: .regular))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            
            // MARK: Currency Picker (Expandable)
            if viewModel.showCurrencyPicker {
                CurrencyPickerView(
                    currencies: SampleData.currencies,
                    selectedCurrency: $viewModel.selectedCurrency,
                    isPresented: $viewModel.showCurrencyPicker
                )
            }
            
            // MARK: Description & Category Fields
            VStack(spacing: 0) {
                // Description input row
                HStack {
                    Text("Description")
                        .font(.system(size: 17))
                    Spacer()
                    TextField("What's this for?", text: $viewModel.transactionName)
                        .font(.system(size: 17))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.leading, 16)
                
                // Category selector row
                Button {
                    viewModel.showCategoryPicker.toggle()
                    viewModel.showCurrencyPicker = false
                } label: {
                    HStack {
                        Text("Category")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                        Spacer()
                        if let category = viewModel.selectedCategory {
                            HStack(spacing: 6) {
                                Text(category.icon)
                                Text(category.name)
                                    .foregroundColor(category.color)
                            }
                            .font(.system(size: 17))
                        } else {
                            Text("Select")
                                .font(.system(size: 17))
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGray3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            
            // MARK: Category Picker (Expandable Grid)
            if viewModel.showCategoryPicker {
                CategoryPickerView(
                    categories: SampleData.categories,
                    selectedCategory: $viewModel.selectedCategory,
                    isPresented: $viewModel.showCategoryPicker
                )
            }
            
            // MARK: Continue Button
            Button {
                if viewModel.canProceedStep1 {
                    viewModel.nextStep()
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .opacity(viewModel.canProceedStep1 ? 1 : 0.5)
                    )
            }
            .disabled(!viewModel.canProceedStep1)
        }
    }
}


// MARK: - ============================================================
// MARK: STEP 2: SPLIT CONFIGURATION
// MARK: ============================================================

/// Second step: configure whether to split and with whom
/// Includes: personal/split toggle, payer selection, participant selection
struct Step2SplitConfigView: View {
    
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: Personal or Split Toggle
            VStack(spacing: 0) {
                // Personal option
                SplitOptionRow(
                    icon: "👤",
                    title: "Personal",
                    subtitle: "Just for you",
                    isSelected: !viewModel.isSplit
                ) {
                    viewModel.isSplit = false
                }
                
                Divider()
                    .padding(.leading, 72)
                
                // Split option
                SplitOptionRow(
                    icon: "👥",
                    title: "Split",
                    subtitle: "Share with friends or groups",
                    isSelected: viewModel.isSplit
                ) {
                    viewModel.isSplit = true
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            
            // MARK: Split Configuration (only shown when splitting)
            if viewModel.isSplit {
                
                // MARK: Paid By Section
                SectionHeader(title: "PAID BY")
                
                // Show selected payer or search interface
                if viewModel.isPaidBySearchFocused {
                    // Search mode
                    PaidBySearchView(viewModel: viewModel)
                } else {
                    // Display selected payer with change button
                    SelectedPayerCard(viewModel: viewModel)
                }
                
                // MARK: Split With Section
                SectionHeader(title: "SPLIT WITH (\(viewModel.participantIds.count))")
                
                // Search bar for adding participants
                SearchBarView(
                    placeholder: "Search contacts or groups...",
                    text: $viewModel.splitWithSearchText,
                    onFocus: {
                        viewModel.isSplitWithSearchFocused = true
                    }
                )
                
                // Show search results or participant list
                if viewModel.isSplitWithSearchFocused && !viewModel.splitWithSearchText.isEmpty {
                    // Search results
                    SplitWithSearchResultsView(viewModel: viewModel)
                } else {
                    // Selected group badge (if any)
                    if let group = viewModel.selectedGroup {
                        SelectedGroupBadge(group: group) {
                            viewModel.clearSelectedGroup()
                        }
                    }
                    
                    // Participants list
                    ParticipantsListView(viewModel: viewModel)
                }
            }
            
            // MARK: Navigation Buttons
            HStack(spacing: 12) {
                // Back button
                Button {
                    viewModel.previousStep()
                } label: {
                    Text("Back")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemGray6))
                        )
                }
                
                // Continue/Save button
                Button {
                    if !viewModel.isSplit {
                        viewModel.submitTransaction()
                    } else if viewModel.canProceedStep2 {
                        viewModel.nextStep()
                    }
                } label: {
                    Text(viewModel.isSplit ? "Continue" : "Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .opacity(viewModel.canProceedStep2 ? 1 : 0.5)
                        )
                }
                .disabled(!viewModel.canProceedStep2)
            }
        }
    }
}


// MARK: - ============================================================
// MARK: STEP 3: SPLIT METHOD
// MARK: ============================================================

/// Third step: configure how to split the transaction
/// Includes: method selection, per-person amounts, summary
struct Step3SplitMethodView: View {
    
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: Split Method Picker
            // Horizontal scrolling method selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SplitMethod.allCases) { method in
                        SplitMethodChip(
                            method: method,
                            isSelected: viewModel.splitMethod == method
                        ) {
                            viewModel.splitMethod = method
                            viewModel.splitDetails = [:] // Reset details when method changes
                        }
                    }
                }
            }
            
            // MARK: Total Summary Bar
            SplitSummaryBar(viewModel: viewModel)
            
            // MARK: Per-Person Split Details
            VStack(spacing: 0) {
                let splits = viewModel.calculateSplits()
                let participantArray = Array(viewModel.participantIds)
                
                ForEach(Array(participantArray.enumerated()), id: \.element) { index, userId in
                    if let friend = SampleData.friend(byId: userId) {
                        let split = splits[userId] ?? SplitDetail()
                        let isLast = index == participantArray.count - 1
                        let isPayer = viewModel.paidByUserId == userId
                        
                        SplitPersonRow(
                            friend: friend,
                            split: split,
                            isPayer: isPayer,
                            currency: viewModel.selectedCurrency,
                            splitMethod: viewModel.splitMethod,
                            currentDetail: viewModel.splitDetails[userId] ?? SplitDetail(),
                            onUpdate: { detail in
                                viewModel.splitDetails[userId] = detail
                            }
                        )
                        
                        if !isLast {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            
            // MARK: Who Owes Whom Summary
            OwesSummaryView(viewModel: viewModel)
            
            // MARK: Navigation Buttons
            HStack(spacing: 12) {
                // Back button
                Button {
                    viewModel.previousStep()
                } label: {
                    Text("Back")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemGray6))
                        )
                }
                
                // Save button
                Button {
                    if viewModel.canSubmit {
                        viewModel.submitTransaction()
                    }
                } label: {
                    Text("Save Transaction")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .opacity(viewModel.canSubmit ? 1 : 0.5)
                        )
                }
                .disabled(!viewModel.canSubmit)
            }
        }
    }
}


// MARK: - ============================================================
// MARK: REUSABLE COMPONENTS
// MARK: ============================================================

// MARK: Section Header

/// Section label styled like iOS Settings
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}


// MARK: Search Bar

/// iOS-style search bar
struct SearchBarView: View {
    let placeholder: String
    @Binding var text: String
    var onFocus: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            // Text field
            TextField(placeholder, text: $text, onEditingChanged: { isEditing in
                if isEditing {
                    onFocus?()
                }
            })
            .font(.system(size: 17))
            
            // Clear button
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}


// MARK: Currency Picker

/// Expandable list of currencies
struct CurrencyPickerView: View {
    let currencies: [Currency]
    @Binding var selectedCurrency: Currency
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(currencies.enumerated()), id: \.element.id) { index, currency in
                Button {
                    selectedCurrency = currency
                    isPresented = false
                } label: {
                    HStack(spacing: 12) {
                        Text(currency.flag)
                            .font(.system(size: 20))
                        Text(currency.name)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(currency.code)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                        if selectedCurrency.id == currency.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                if index < currencies.count - 1 {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}


// MARK: Category Picker

/// Grid of category options
struct CategoryPickerView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Binding var isPresented: Bool
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(categories) { category in
                Button {
                    selectedCategory = category
                    isPresented = false
                } label: {
                    VStack(spacing: 6) {
                        Text(category.icon)
                            .font(.system(size: 28))
                        Text(category.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory?.id == category.id ? category.color : .primary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedCategory?.id == category.id ? category.color : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                }
            }
        }
    }
}


// MARK: Split Option Row

/// Row for Personal/Split selection
struct SplitOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                Text(icon)
                    .font(.system(size: 32))
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Radio button
                Circle()
                    .strokeBorder(isSelected ? Color.blue : Color(UIColor.systemGray3), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}


// MARK: Selected Payer Card

/// Displays the currently selected payer with a change button
struct SelectedPayerCard: View {
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            PersonAvatar(
                initials: viewModel.paidByFriend?.initials ?? "",
                isCurrentUser: viewModel.paidByFriend?.isCurrentUser ?? false,
                isSelected: true,
                size: 48
            )
            
            // Name
            Text(viewModel.paidByFriend?.displayName ?? "")
                .font(.system(size: 17, weight: .medium))
            
            Spacer()
            
            // Change button
            Button {
                viewModel.isPaidBySearchFocused = true
            } label: {
                Text("Change")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(12)
    }
}


// MARK: Paid By Search View

/// Search interface for changing the payer
struct PaidBySearchView: View {
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            SearchBarView(
                placeholder: "Search contacts...",
                text: $viewModel.paidBySearchText
            )
            
            // Results list
            VStack(spacing: 0) {
                ForEach(Array(viewModel.filteredPaidByContacts.enumerated()), id: \.element.id) { index, friend in
                    Button {
                        viewModel.selectPayer(friend.id)
                    } label: {
                        ContactSearchRow(
                            friend: friend,
                            isSelected: viewModel.paidByUserId == friend.id
                        )
                    }
                    
                    if index < viewModel.filteredPaidByContacts.count - 1 {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
                
                // Empty state
                if viewModel.filteredPaidByContacts.isEmpty {
                    Text("No contacts found")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            
            // Cancel button
            Button {
                viewModel.isPaidBySearchFocused = false
                viewModel.paidBySearchText = ""
            } label: {
                Text("Cancel")
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
            }
        }
    }
}


// MARK: Split With Search Results

/// Search results for contacts and groups
struct SplitWithSearchResultsView: View {
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Groups section
            if !viewModel.filteredSplitWithGroups.isEmpty {
                // Section header
                HStack {
                    Text("GROUPS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGroupedBackground))
                
                // Group rows
                ForEach(viewModel.filteredSplitWithGroups) { group in
                    Button {
                        viewModel.selectGroup(group)
                    } label: {
                        GroupSearchRow(
                            group: group,
                            isSelected: viewModel.selectedGroup?.id == group.id
                        )
                    }
                }
            }
            
            // Contacts section
            if !viewModel.filteredSplitWithContacts.isEmpty {
                // Section header
                HStack {
                    Text("CONTACTS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGroupedBackground))
                
                // Contact rows
                ForEach(viewModel.filteredSplitWithContacts) { friend in
                    Button {
                        viewModel.addParticipantFromSearch(friend.id)
                    } label: {
                        ContactSearchRow(
                            friend: friend,
                            isSelected: viewModel.participantIds.contains(friend.id)
                        )
                    }
                }
            }
            
            // Empty state
            if viewModel.filteredSplitWithGroups.isEmpty && viewModel.filteredSplitWithContacts.isEmpty {
                Text("No results found")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}


// MARK: Contact Search Row

/// Individual contact row in search results
struct ContactSearchRow: View {
    let friend: Friend
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            PersonAvatar(
                initials: friend.initials,
                isCurrentUser: friend.isCurrentUser,
                isSelected: isSelected,
                size: 44
            )
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                if let email = friend.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Checkmark
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


// MARK: Group Search Row

/// Individual group row in search results
struct GroupSearchRow: View {
    let group: Group
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Group icon
            Text(group.icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(group.color.opacity(0.2))
                .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                
                // Member preview
                let memberNames = group.memberIds.compactMap { id -> String? in
                    if let friend = SampleData.friend(byId: id) {
                        return friend.firstName
                    }
                    return nil
                }.joined(separator: ", ")
                
                Text("\(group.memberIds.count) members • \(memberNames)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Checkmark
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


// MARK: Selected Group Badge

/// Shows the currently selected group with a dismiss button
struct SelectedGroupBadge: View {
    let group: Group
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(group.icon)
                .font(.system(size: 18))
            
            Text(group.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.blue)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(20)
    }
}


// MARK: Participants List

/// List of all participants with checkboxes
struct ParticipantsListView: View {
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(SampleData.friends.enumerated()), id: \.element.id) { index, friend in
                let isSelected = viewModel.participantIds.contains(friend.id)
                let isFromGroup = viewModel.selectedGroup?.memberIds.contains(friend.id) ?? false
                
                Button {
                    viewModel.toggleParticipant(friend.id)
                } label: {
                    HStack(spacing: 12) {
                        // Avatar
                        PersonAvatar(
                            initials: friend.initials,
                            isCurrentUser: friend.isCurrentUser,
                            isSelected: isSelected,
                            size: 40
                        )
                        
                        // Name and group tag
                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.displayName)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            
                            if isFromGroup, let group = viewModel.selectedGroup {
                                Text("from \(group.name)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        // Checkbox
                        Circle()
                            .strokeBorder(isSelected ? Color.blue : Color(UIColor.systemGray3), lineWidth: 2)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.blue : Color.clear)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(isSelected ? 1 : 0)
                            )
                            .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                if index < SampleData.friends.count - 1 {
                    Divider()
                        .padding(.leading, 68)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}


// MARK: Person Avatar

/// Circular avatar component for displaying user initials
struct PersonAvatar: View {
    let initials: String
    let isCurrentUser: Bool
    let isSelected: Bool
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color(UIColor.systemGray5))
            
            if isCurrentUser {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(isSelected ? .white : .secondary)
            } else {
                Text(initials)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
        }
        .frame(width: size, height: size)
    }
}


// MARK: Split Method Chip

/// Selectable chip for split methods
struct SplitMethodChip: View {
    let method: SplitMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon
                Text(method.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color(UIColor.systemGray6))
                    )
                
                // Label
                Text(method.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}


// MARK: Split Summary Bar

/// Shows total amount and validation status
struct SplitSummaryBar: View {
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        HStack {
            Text("Total")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
            
            Text("\(viewModel.selectedCurrency.symbol)\(viewModel.amount, specifier: "%.2f")")
                .font(.system(size: 20, weight: .semibold))
            
            Spacer()
            
            // Validation indicator
            if viewModel.splitMethod == .percentages {
                let isValid = abs(viewModel.totalPercentage - 100) < 0.01
                Text("\(viewModel.totalPercentage, specifier: "%.0f")%")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(isValid ? .green : .red)
            } else if viewModel.splitMethod == .amounts {
                let isValid = abs(viewModel.totalSplitAmount - viewModel.amount) < 0.01
                Text("\(viewModel.selectedCurrency.symbol)\(viewModel.totalSplitAmount, specifier: "%.2f")")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(isValid ? .green : .red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(12)
    }
}


// MARK: Split Person Row

/// Individual row in the split details list
struct SplitPersonRow: View {
    let friend: Friend
    let split: SplitDetail
    let isPayer: Bool
    let currency: Currency
    let splitMethod: SplitMethod
    let currentDetail: SplitDetail
    let onUpdate: (SplitDetail) -> Void
    
    @State private var amountText: String = ""
    @State private var percentageText: String = ""
    @State private var shares: Int = 1
    @State private var adjustmentText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            PersonAvatar(
                initials: friend.initials,
                isCurrentUser: friend.isCurrentUser,
                isSelected: false,
                size: 40
            )
            
            // Name and amount
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(friend.displayName)
                        .font(.system(size: 17, weight: .medium))
                    
                    // Payer badge
                    if isPayer {
                        Text("Paid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                
                Text("\(currency.symbol)\(split.amount, specifier: "%.2f")")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Input control based on split method
            splitInputView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear {
            // Initialize local state from current detail
            amountText = currentDetail.amount > 0 ? String(format: "%.2f", currentDetail.amount) : ""
            percentageText = currentDetail.percentage > 0 ? String(format: "%.0f", currentDetail.percentage) : ""
            shares = currentDetail.shares > 0 ? currentDetail.shares : 1
            adjustmentText = currentDetail.adjustment != 0 ? String(format: "%.2f", currentDetail.adjustment) : ""
        }
    }
    
    /// Returns the appropriate input view based on split method
    @ViewBuilder
    private var splitInputView: some View {
        switch splitMethod {
        case .equal:
            // Just show the percentage
            Text("\(100.0 / Double(max(1, split.shares)), specifier: "%.0f")%")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
            
        case .amounts:
            // Amount text field
            HStack(spacing: 4) {
                Text(currency.symbol)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                TextField("0", text: $amountText)
                    .font(.system(size: 17))
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .onChange(of: amountText) { _, newValue in
                        var detail = currentDetail
                        detail.amount = Double(newValue) ?? 0
                        onUpdate(detail)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
        case .percentages:
            // Percentage text field
            HStack(spacing: 4) {
                TextField("0", text: $percentageText)
                    .font(.system(size: 17))
                    .keyboardType(.decimalPad)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .onChange(of: percentageText) { _, newValue in
                        var detail = currentDetail
                        detail.percentage = Double(newValue) ?? 0
                        onUpdate(detail)
                    }
                Text("%")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
        case .shares:
            // Stepper for shares
            HStack(spacing: 4) {
                Button {
                    if shares > 1 {
                        shares -= 1
                        var detail = currentDetail
                        detail.shares = shares
                        onUpdate(detail)
                    }
                } label: {
                    Text("−")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                }
                
                Text("\(shares)")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 40)
                
                Button {
                    shares += 1
                    var detail = currentDetail
                    detail.shares = shares
                    onUpdate(detail)
                } label: {
                    Text("+")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                }
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
        case .adjustment:
            // Adjustment text field
            HStack(spacing: 4) {
                Text("±\(currency.symbol)")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                TextField("0", text: $adjustmentText)
                    .font(.system(size: 17))
                    .keyboardType(.numbersAndPunctuation)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .onChange(of: adjustmentText) { _, newValue in
                        var detail = currentDetail
                        detail.adjustment = Double(newValue) ?? 0
                        onUpdate(detail)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
}


// MARK: Owes Summary View

/// Shows who owes whom and how much
struct OwesSummaryView: View {
    @Bindable var viewModel: QuickActionViewModel
    
    var body: some View {
        let splits = viewModel.calculateSplits()
        let payer = SampleData.friend(byId: viewModel.paidByUserId)
        let nonPayerParticipants = viewModel.participantIds.filter { $0 != viewModel.paidByUserId }
        
        if !nonPayerParticipants.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(nonPayerParticipants), id: \.self) { userId in
                    if let friend = SampleData.friend(byId: userId) {
                        let split = splits[userId] ?? SplitDetail()
                        
                        HStack {
                            Text("\(friend.firstName) owes \(payer?.firstName ?? "")")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(viewModel.selectedCurrency.symbol)\(split.amount, specifier: "%.2f")")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color.blue.opacity(0.08))
            .cornerRadius(12)
        }
    }
}


// MARK: - ============================================================
// MARK: HELPER EXTENSIONS
// MARK: ============================================================

/// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// MARK: - ============================================================
// MARK: PREVIEW
// MARK: ============================================================

/// Preview provider for Xcode canvas
#Preview {
    FinanceQuickActionView()
}
