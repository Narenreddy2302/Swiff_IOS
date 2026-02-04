//
//  FeedDataService.swift
//  Swiff IOS
//
//  Service to convert real DataManager data to FeedTransaction models
//  Bridges the gap between CoreData and the Twitter-style feed UI
//  Created: 2026-02-04
//

import Combine
import SwiftUI

// MARK: - Feed Data Service

/// Converts and manages real transaction data for the Twitter-style feed
/// Handles sorting, filtering, and enrichment with person/split details
@MainActor
class FeedDataService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var feedTransactions: [FeedTransaction] = []
    @Published var isLoading = false
    
    private var dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    static let shared = FeedDataService(dataManager: .shared)
    
    // MARK: - Init
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        setupObservers()
        loadTransactions()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe data changes
        dataManager.dataChangeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                switch change {
                case .transactionAdded, .transactionUpdated, .transactionDeleted,
                     .personUpdated, .allDataReloaded:
                    self?.loadTransactions()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Also observe the arrays directly
        dataManager.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadTransactions()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Transactions
    
    func loadTransactions() {
        isLoading = true
        
        // Convert real transactions to feed transactions
        feedTransactions = dataManager.transactions
            .sorted { $0.date > $1.date }
            .compactMap { transaction -> FeedTransaction? in
                return convertToFeedTransaction(transaction)
            }
        
        // If no real transactions, use mock data for demo
        if feedTransactions.isEmpty {
            feedTransactions = FeedTransaction.mockData
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        loadTransactions()
        isLoading = false
    }
    
    // MARK: - Conversion
    
    /// Convert a real Transaction to a FeedTransaction for display
    private func convertToFeedTransaction(_ transaction: Transaction) -> FeedTransaction? {
        // Find associated person if this is a person transaction
        let person = findAssociatedPerson(for: transaction)
        let splitBill = findSplitBill(for: transaction)
        
        // Determine balance type
        let balanceType: FeedTransaction.BalanceType = {
            if transaction.paymentStatus == .completed {
                return .neutral
            }
            if transaction.amount < 0 {
                return .youOwe
            } else if transaction.amount > 0 {
                return .theyOwe
            }
            return .neutral
        }()
        
        // Get avatar color from person or derive from category
        let avatarColor = colorForCategory(transaction.category)
        
        // Get person name or merchant
        let displayName = person?.name ?? transaction.merchant ?? transaction.title
        let initials = getInitials(from: displayName)
        
        // Get participants from split bill if available
        let participants: [String] = {
            guard let split = splitBill else { return [] }
            let participantIds = split.participants.map { $0.personId }
            return dataManager.people
                .filter { participantIds.contains($0.id) }
                .map { $0.name }
        }()
        
        // Split method
        let splitMethod: String? = {
            guard let split = splitBill else { return nil }
            return split.splitType.rawValue
        }()
        
        return FeedTransaction(
            id: transaction.id,
            personName: displayName,
            initials: initials,
            avatarColor: avatarColor,
            isVerified: person?.personSource == .appUser,
            category: transaction.category.rawValue.capitalized,
            description: transaction.notes.isEmpty ? transaction.subtitle : transaction.notes,
            amount: transaction.amount,
            balanceType: balanceType,
            isSettled: transaction.paymentStatus == .completed,
            splitMethod: splitMethod,
            participants: participants,
            timestamp: transaction.date,
            isLiked: false,
            likeCount: Int.random(in: 0...5), // Demo: random engagement
            commentCount: Int.random(in: 0...3)
        )
    }
    
    // MARK: - Helpers
    
    private func findAssociatedPerson(for transaction: Transaction) -> Person? {
        // Check if title or subtitle matches a person name
        return dataManager.people.first { person in
            transaction.title.contains(person.name) || 
            transaction.subtitle.contains(person.name)
        }
    }
    
    private func findSplitBill(for transaction: Transaction) -> SplitBill? {
        guard let splitId = transaction.splitBillId else { return nil }
        return dataManager.splitBills.first { $0.id == splitId }
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private func colorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food, .groceries:
            return Theme.Colors.success
        case .shopping:
            return Theme.Colors.brandPrimary
        case .transportation:
            return Theme.Colors.info
        case .entertainment:
            return Theme.Colors.warning
        case .bills, .utilities:
            return Theme.Colors.amountNegative
        case .healthcare:
            return .pink
        case .income:
            return Theme.Colors.amountPositive
        case .transfer:
            return Theme.Colors.info
        case .other:
            return Theme.Colors.textSecondary
        }
    }
}

// Extension removed - using SplitType.rawValue directly
