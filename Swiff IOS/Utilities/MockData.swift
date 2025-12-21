//
//  MockData.swift
//  Swiff IOS
//
//  Centralized mock data for SwiftUI previews and testing
//  Provides comprehensive sample data for all models including edge cases
//

import Foundation
import SwiftUI

/// Centralized mock data for SwiftUI previews and testing
struct MockData {

    // MARK: - Stable UUIDs for Consistent References

    private static let personId1 = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let personId2 = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let personId3 = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    private static let personId4 = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    private static let personId5 = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    private static let personId6 = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    private static let personId7 = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!

    private static let subscriptionId1 = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private static let subscriptionId2 = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    private static let subscriptionId3 = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!

    private static let groupId1 = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    private static let groupId2 = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!

    // MARK: - People

    /// All sample people
    static let people: [Person] = [
        personOwedMoney,
        personOwingMoney,
        personSettled,
        personFriend,
        personFamily,
        personCoworker,
        longNamePerson
    ]

    /// Person with positive balance (they owe you money)
    static var personOwedMoney: Person = {
        var person = Person(
            name: "Emma Wilson",
            email: "emma.wilson@email.com",
            phone: "+1 (555) 123-4567",
            avatarType: .emoji("👩‍💼"),
            relationshipType: "Friend"
        )
        person.id = personId1
        person.balance = 78.25
        return person
    }()

    /// Person with negative balance (you owe them money)
    static var personOwingMoney: Person = {
        var person = Person(
            name: "James Chen",
            email: "james.chen@email.com",
            phone: "+1 (555) 234-5678",
            avatarType: .initials("JC", colorIndex: 1),
            relationshipType: "Friend"
        )
        person.id = personId2
        person.balance = -45.50
        return person
    }()

    /// Person with zero balance (settled)
    static var personSettled: Person = {
        var person = Person(
            name: "Aisha Patel",
            email: "aisha.patel@email.com",
            phone: "+1 (555) 345-6789",
            avatarType: .initials("AP", colorIndex: 2),
            relationshipType: "Friend"
        )
        person.id = personId3
        person.balance = 0.0
        return person
    }()

    /// Person categorized as friend
    static var personFriend: Person = {
        var person = Person(
            name: "David Kim",
            email: "david.kim@email.com",
            phone: "+1 (555) 456-7890",
            avatarType: .emoji("👨‍🎤"),
            relationshipType: "Friend",
            notes: "Met at the tech conference"
        )
        person.id = personId4
        person.balance = 120.00
        return person
    }()

    /// Person categorized as family
    static var personFamily: Person = {
        var person = Person(
            name: "Sofia Rodriguez",
            email: "sofia.rodriguez@email.com",
            phone: "+1 (555) 567-8901",
            avatarType: .emoji("👩"),
            relationshipType: "Family"
        )
        person.id = personId5
        person.balance = -32.00
        return person
    }()

    /// Person categorized as coworker
    static var personCoworker: Person = {
        var person = Person(
            name: "Michael Taylor",
            email: "michael.taylor@company.com",
            phone: "+1 (555) 678-9012",
            avatarType: .initials("MT", colorIndex: 4),
            relationshipType: "Coworker"
        )
        person.id = personId6
        person.balance = 15.75
        return person
    }()

    /// Person with very long name (edge case)
    static var longNamePerson: Person = {
        var person = Person(
            name: "Alexandra Christina Montgomery-Fitzgerald III",
            email: "alexandra.montgomery@verylongemail.example.com",
            phone: "+1 (555) 789-0123",
            avatarType: .initials("AM", colorIndex: 5),
            relationshipType: "Friend"
        )
        person.id = personId7
        person.balance = 250.99
        return person
    }()

    // MARK: - Subscriptions

    /// All sample subscriptions
    static let subscriptions: [Subscription] = [
        activeSubscription,
        yearlySubscription,
        inactiveSubscription,
        trialSubscription,
        expiredTrialSubscription,
        sharedSubscription,
        expensiveSubscription,
        cheapSubscription,
        subscriptionDueToday,
        longNameSubscription
    ]

    /// Active monthly subscription
    static var activeSubscription: Subscription = {
        var sub = Subscription(
            name: "Netflix",
            description: "Premium 4K streaming plan",
            price: 19.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )
        sub.id = subscriptionId1
        sub.isActive = true
        sub.usageCount = 45
        sub.lastUsedDate = Date()
        return sub
    }()

    /// Active yearly subscription
    static var yearlySubscription: Subscription = {
        var sub = Subscription(
            name: "Microsoft 365",
            description: "Office suite with cloud storage",
            price: 99.99,
            billingCycle: .annually,
            category: .productivity,
            icon: "doc.fill",
            color: "#0078D4"
        )
        sub.isActive = true
        return sub
    }()

    /// Inactive/cancelled subscription
    static var inactiveSubscription: Subscription = {
        var sub = Subscription(
            name: "HBO Max",
            description: "Cancelled streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.tv.fill",
            color: "#5822B4"
        )
        sub.isActive = false
        sub.cancellationDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        return sub
    }()

    /// Subscription in free trial
    static var trialSubscription: Subscription = {
        var sub = Subscription(
            name: "Spotify Premium",
            description: "3-month free trial",
            price: 10.99,
            billingCycle: .monthly,
            category: .music,
            icon: "music.note",
            color: "#1DB954"
        )
        sub.id = subscriptionId2
        sub.isFreeTrial = true
        sub.trialStartDate = Calendar.current.date(byAdding: .day, value: -21, to: Date())
        sub.trialEndDate = Calendar.current.date(byAdding: .day, value: 69, to: Date())
        sub.trialDuration = 90
        sub.willConvertToPaid = true
        sub.priceAfterTrial = 10.99
        return sub
    }()

    /// Subscription with expired trial
    static var expiredTrialSubscription: Subscription = {
        var sub = Subscription(
            name: "Adobe Creative Cloud",
            description: "Trial expired - decision needed",
            price: 54.99,
            billingCycle: .monthly,
            category: .design,
            icon: "paintbrush.fill",
            color: "#FF0000"
        )
        sub.isFreeTrial = true
        sub.trialStartDate = Calendar.current.date(byAdding: .day, value: -37, to: Date())
        sub.trialEndDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        sub.trialDuration = 30
        sub.willConvertToPaid = false
        sub.priceAfterTrial = 54.99
        return sub
    }()

    /// Shared subscription with members
    static var sharedSubscription: Subscription = {
        var sub = Subscription(
            name: "YouTube Premium Family",
            description: "Shared with 3 family members",
            price: 22.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.rectangle.fill",
            color: "#FF0000"
        )
        sub.id = subscriptionId3
        sub.isShared = true
        sub.sharedWith = [personId1, personId2, personId3]
        return sub
    }()

    /// Very expensive subscription (edge case)
    static var expensiveSubscription: Subscription = {
        var sub = Subscription(
            name: "Enterprise Software Suite",
            description: "Full enterprise license",
            price: 9999.99,
            billingCycle: .annually,
            category: .development,
            icon: "server.rack",
            color: "#1E3A5F"
        )
        sub.isActive = true
        return sub
    }()

    /// Very cheap subscription (edge case)
    static var cheapSubscription: Subscription = {
        var sub = Subscription(
            name: "iCloud+ 50GB",
            description: "Basic cloud storage",
            price: 0.99,
            billingCycle: .monthly,
            category: .cloud,
            icon: "icloud.fill",
            color: "#007AFF"
        )
        sub.isActive = true
        return sub
    }()

    /// Subscription due today
    static var subscriptionDueToday: Subscription = {
        var sub = Subscription(
            name: "Gym Membership",
            description: "Monthly fitness subscription",
            price: 49.99,
            billingCycle: .monthly,
            category: .fitness,
            icon: "figure.walk",
            color: "#FF6B35"
        )
        sub.isActive = true
        sub.nextBillingDate = Date()
        return sub
    }()

    /// Subscription with very long name (edge case)
    static var longNameSubscription: Subscription = {
        var sub = Subscription(
            name: "The New York Times Premium All Access Digital + Print Edition",
            description: "Full access to all NYT content including archives, games, cooking, and print delivery",
            price: 45.00,
            billingCycle: .monthly,
            category: .news,
            icon: "newspaper.fill",
            color: "#000000"
        )
        sub.isActive = true
        return sub
    }()

    // MARK: - Transactions

    /// All sample transactions
    static let transactions: [Transaction] = [
        incomeTransaction,
        expenseTransaction,
        recurringTransaction,
        pendingTransaction,
        transactionWithReceipt,
        linkedTransaction,
        largeTransaction,
        smallTransaction,
        groceryTransaction,
        diningTransaction,
        transportTransaction,
        entertainmentTransaction
    ]

    /// Income transaction
    static let incomeTransaction = Transaction(
        title: "Salary Deposit",
        subtitle: "Monthly paycheck - Tech Corp",
        amount: 5250.00,
        category: .income,
        date: Date(),
        isRecurring: true,
        tags: ["work", "monthly", "salary"],
        merchant: "Tech Corp Inc.",
        paymentStatus: .completed
    )

    /// Expense transaction
    static let expenseTransaction = Transaction(
        title: "Grocery Shopping",
        subtitle: "Weekly groceries at Whole Foods",
        amount: -156.78,
        category: .groceries,
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        isRecurring: false,
        tags: ["food", "essentials"],
        merchant: "Whole Foods Market",
        paymentStatus: .completed,
        location: "San Francisco, CA"
    )

    /// Recurring transaction
    static let recurringTransaction = Transaction(
        title: "Internet Bill",
        subtitle: "Comcast Xfinity",
        amount: -89.99,
        category: .utilities,
        date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        isRecurring: true,
        tags: ["bills", "monthly"],
        merchant: "Comcast",
        paymentStatus: .completed,
        isRecurringCharge: true
    )

    /// Pending transaction
    static let pendingTransaction = Transaction(
        title: "Online Order",
        subtitle: "Amazon - Electronics",
        amount: -299.99,
        category: .shopping,
        date: Date(),
        isRecurring: false,
        tags: ["shopping", "electronics"],
        merchant: "Amazon.com",
        paymentStatus: .pending
    )

    /// Transaction with receipt
    static let transactionWithReceipt = Transaction(
        title: "Business Lunch",
        subtitle: "Client meeting at Nobu",
        amount: -187.50,
        category: .dining,
        date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        isRecurring: false,
        tags: ["business", "client"],
        merchant: "Nobu Restaurant",
        paymentStatus: .completed,
        receiptData: Data() // Placeholder for actual receipt data
    )

    /// Transaction linked to subscription
    static var linkedTransaction: Transaction = {
        var transaction = Transaction(
            title: "Netflix Subscription",
            subtitle: "Monthly streaming service",
            amount: -19.99,
            category: .entertainment,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            isRecurring: true,
            tags: ["subscription", "streaming"],
            merchant: "Netflix Inc.",
            paymentStatus: .completed
        )
        transaction.linkedSubscriptionId = subscriptionId1
        return transaction
    }()

    /// Very large transaction (edge case)
    static let largeTransaction = Transaction(
        title: "Tax Payment",
        subtitle: "Quarterly estimated taxes",
        amount: -15750.00,
        category: .bills,
        date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        isRecurring: false,
        tags: ["taxes", "quarterly"],
        merchant: "IRS",
        paymentStatus: .completed
    )

    /// Very small transaction (edge case)
    static let smallTransaction = Transaction(
        title: "Parking Meter",
        subtitle: "Street parking",
        amount: -0.25,
        category: .transportation,
        date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        isRecurring: false,
        tags: ["parking"],
        merchant: "City Parking",
        paymentStatus: .completed
    )

    /// Grocery transaction
    static let groceryTransaction = Transaction(
        title: "Trader Joe's",
        subtitle: "Weekly groceries",
        amount: -87.34,
        category: .groceries,
        date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
        isRecurring: false,
        tags: ["food", "weekly"],
        merchant: "Trader Joe's",
        paymentStatus: .completed
    )

    /// Dining transaction
    static let diningTransaction = Transaction(
        title: "Dinner with Friends",
        subtitle: "Italian restaurant",
        amount: -65.00,
        category: .dining,
        date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
        isRecurring: false,
        tags: ["social", "dinner"],
        merchant: "Olive Garden",
        paymentStatus: .completed
    )

    /// Transportation transaction
    static let transportTransaction = Transaction(
        title: "Uber Ride",
        subtitle: "Airport to home",
        amount: -42.50,
        category: .transportation,
        date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        isRecurring: false,
        tags: ["travel", "rideshare"],
        merchant: "Uber",
        paymentStatus: .completed
    )

    /// Entertainment transaction
    static let entertainmentTransaction = Transaction(
        title: "Concert Tickets",
        subtitle: "Taylor Swift - Eras Tour",
        amount: -350.00,
        category: .entertainment,
        date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
        isRecurring: false,
        tags: ["concert", "events"],
        merchant: "Ticketmaster",
        paymentStatus: .completed
    )

    // MARK: - Groups

    /// All sample groups
    static let groups: [Group] = [
        groupWithExpenses,
        settledGroup,
        emptyGroup,
        largeGroup
    ]

    /// Group with multiple expenses
    static var groupWithExpenses: Group = {
        var group = Group(
            name: "Beach Vacation",
            description: "Summer trip to Malibu",
            emoji: "🏖️",
            members: [personId1, personId2, personId3]
        )
        group.id = groupId1
        group.expenses = [
            GroupExpense(
                title: "Hotel Booking",
                amount: 450.00,
                paidBy: personId1,
                splitBetween: [personId1, personId2, personId3],
                category: .travel,
                notes: "3 nights at beach resort"
            ),
            GroupExpense(
                title: "Dinner at Seafood Place",
                amount: 180.00,
                paidBy: personId2,
                splitBetween: [personId1, personId2, personId3],
                category: .dining,
                notes: "First night dinner"
            ),
            GroupExpense(
                title: "Surfboard Rentals",
                amount: 90.00,
                paidBy: personId3,
                splitBetween: [personId1, personId2, personId3],
                category: .entertainment,
                notes: "2 boards for the day"
            )
        ]
        group.totalAmount = 720.00
        return group
    }()

    /// Group with all expenses settled
    static var settledGroup: Group = {
        var group = Group(
            name: "Dinner Club",
            description: "Monthly dinner gatherings",
            emoji: "🍽️",
            members: [personId1, personId4, personId5]
        )
        group.id = groupId2
        group.expenses = [
            GroupExpense(
                title: "October Dinner",
                amount: 210.00,
                paidBy: personId1,
                splitBetween: [personId1, personId4, personId5],
                category: .dining,
                isSettled: true
            )
        ]
        group.totalAmount = 210.00
        return group
    }()

    /// Empty group (edge case)
    static var emptyGroup: Group = {
        var group = Group(
            name: "New Project Team",
            description: "Just created - no expenses yet",
            emoji: "🆕",
            members: [personId1, personId2]
        )
        group.expenses = []
        group.totalAmount = 0.0
        return group
    }()

    /// Large group with many members (edge case)
    static var largeGroup: Group = {
        var group = Group(
            name: "Office Party Fund",
            description: "Company holiday party planning",
            emoji: "🎉",
            members: [personId1, personId2, personId3, personId4, personId5, personId6, personId7]
        )
        group.expenses = [
            GroupExpense(
                title: "Venue Deposit",
                amount: 500.00,
                paidBy: personId1,
                splitBetween: [personId1, personId2, personId3, personId4, personId5, personId6, personId7],
                category: .entertainment
            )
        ]
        group.totalAmount = 500.00
        return group
    }()

    // MARK: - Split Bills

    /// All sample split bills
    static let splitBills: [SplitBill] = [
        settledSplitBill,
        pendingSplitBill,
        partiallySplitBill,
        percentageSplitBill
    ]

    /// Fully settled split bill
    static let settledSplitBill: SplitBill = {
        var participant1 = SplitParticipant(personId: personId2, amount: 40.00, hasPaid: true)
        participant1.paymentDate = Date()
        var participant2 = SplitParticipant(personId: personId3, amount: 40.00, hasPaid: true)
        participant2.paymentDate = Date()

        return SplitBill(
            title: "Lunch at Sushi Place",
            totalAmount: 120.00,
            paidById: personId1,
            splitType: .equally,
            participants: [participant1, participant2],
            notes: "Great lunch meeting",
            category: .dining,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        )
    }()

    /// Pending split bill (no one has paid yet)
    static let pendingSplitBill = SplitBill(
        title: "Weekend Cabin Rental",
        totalAmount: 600.00,
        paidById: personId1,
        splitType: .equally,
        participants: [
            SplitParticipant(personId: personId2, amount: 150.00, hasPaid: false),
            SplitParticipant(personId: personId3, amount: 150.00, hasPaid: false),
            SplitParticipant(personId: personId4, amount: 150.00, hasPaid: false)
        ],
        notes: "Mountain cabin for New Year's",
        category: .travel,
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    )

    /// Partially settled split bill
    static let partiallySplitBill: SplitBill = {
        var participant1 = SplitParticipant(personId: personId2, amount: 45.00, hasPaid: true)
        participant1.paymentDate = Date()

        return SplitBill(
            title: "Group Dinner",
            totalAmount: 180.00,
            paidById: personId1,
            splitType: .equally,
            participants: [
                participant1,
                SplitParticipant(personId: personId3, amount: 45.00, hasPaid: false),
                SplitParticipant(personId: personId4, amount: 45.00, hasPaid: false)
            ],
            notes: "Birthday celebration",
            category: .dining,
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        )
    }()

    /// Split bill with percentage split
    static let percentageSplitBill = SplitBill(
        title: "Joint Gift Purchase",
        totalAmount: 200.00,
        paidById: personId1,
        splitType: .percentages,
        participants: [
            SplitParticipant(personId: personId2, amount: 100.00, hasPaid: true, percentage: 50.0),
            SplitParticipant(personId: personId3, amount: 50.00, hasPaid: false, percentage: 25.0)
        ],
        notes: "Wedding gift for Alex",
        category: .shopping,
        date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    )

    // MARK: - Accounts

    /// All sample accounts
    static let accounts: [Account] = [
        defaultAccount,
        checkingAccount,
        creditCardAccount,
        savingsAccount
    ]

    /// Default payment account
    static let defaultAccount = Account(
        name: "Chase Checking",
        number: "••4521",
        type: .bank,
        isDefault: true
    )

    /// Checking account
    static let checkingAccount = Account(
        name: "Wells Fargo",
        number: "••7834",
        type: .bank,
        isDefault: false
    )

    /// Credit card account
    static let creditCardAccount = Account(
        name: "Apple Card",
        number: "••9012",
        type: .creditCard,
        isDefault: false
    )

    /// Savings account
    static let savingsAccount = Account(
        name: "Ally Savings",
        number: "••3456",
        type: .bank,
        isDefault: false
    )

    // MARK: - Price Changes

    /// All sample price changes
    static let priceChanges: [PriceChange] = [
        priceIncrease,
        priceDecrease,
        largePriceIncrease
    ]

    /// Price increase
    static let priceIncrease = PriceChange(
        subscriptionId: subscriptionId1,
        oldPrice: 15.99,
        newPrice: 19.99,
        detectedAutomatically: true
    )

    /// Price decrease
    static let priceDecrease = PriceChange(
        subscriptionId: subscriptionId2,
        oldPrice: 12.99,
        newPrice: 10.99,
        detectedAutomatically: false
    )

    /// Large price increase (edge case)
    static let largePriceIncrease = PriceChange(
        subscriptionId: subscriptionId3,
        oldPrice: 9.99,
        newPrice: 22.99,
        detectedAutomatically: true
    )

    // MARK: - Subscription Events

    /// All sample subscription events
    static let subscriptionEvents: [SubscriptionEvent] = [
        billingEvent,
        priceChangeEvent,
        trialEndingEvent,
        memberAddedEvent
    ]

    /// Billing charged event
    static let billingEvent = SubscriptionEvent(
        subscriptionId: subscriptionId1,
        eventType: .billingCharged,
        eventDate: Date(),
        title: "Netflix charged $19.99",
        amount: 19.99
    )

    /// Price change event
    static let priceChangeEvent = SubscriptionEvent(
        subscriptionId: subscriptionId1,
        eventType: .priceIncrease,
        eventDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        title: "Price increased from $15.99 to $19.99",
        amount: 4.00
    )

    /// Trial ending event
    static let trialEndingEvent = SubscriptionEvent(
        subscriptionId: subscriptionId2,
        eventType: .trialEnding,
        eventDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
        title: "Trial ending in 3 days",
        subtitle: "Will convert to $10.99/month"
    )

    /// Member added event
    static let memberAddedEvent = SubscriptionEvent(
        subscriptionId: subscriptionId3,
        eventType: .memberAdded,
        eventDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        title: "Emma Wilson joined",
        relatedPersonId: personId1
    )

    // MARK: - Empty States (Edge Cases)

    /// Empty people array
    static let emptyStatePeople: [Person] = []

    /// Empty subscriptions array
    static let emptyStateSubscriptions: [Subscription] = []

    /// Empty transactions array
    static let emptyStateTransactions: [Transaction] = []

    /// Empty groups array
    static let emptyStateGroups: [Group] = []

    /// Empty split bills array
    static let emptyStateSplitBills: [SplitBill] = []

    // MARK: - Preview DataManager

    /// Pre-configured DataManager for previews with all mock data loaded
    static var previewDataManager: DataManager {
        let manager = DataManager.shared

        // Clear existing data and load mock data
        // Note: In actual implementation, you may want to create a separate instance
        // for previews to avoid affecting real data

        return manager
    }

    /// Creates a fresh DataManager instance with mock data for isolated testing
    static func createPreviewDataManager() -> DataManager {
        let manager = DataManager.shared
        // The DataManager should be pre-populated with sample data
        // which matches our mock data
        return manager
    }
}

// MARK: - Preview Helpers

extension MockData {

    /// Get a random person for previews
    static var randomPerson: Person {
        people.randomElement() ?? personOwedMoney
    }

    /// Get a random subscription for previews
    static var randomSubscription: Subscription {
        subscriptions.randomElement() ?? activeSubscription
    }

    /// Get a random transaction for previews
    static var randomTransaction: Transaction {
        transactions.randomElement() ?? expenseTransaction
    }

    /// Get a random group for previews
    static var randomGroup: Group {
        groups.randomElement() ?? groupWithExpenses
    }

    /// Get a random split bill for previews
    static var randomSplitBill: SplitBill {
        splitBills.randomElement() ?? pendingSplitBill
    }

    /// Get recent transactions (last 7 days)
    static var recentTransactions: [Transaction] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return transactions.filter { $0.date >= sevenDaysAgo }
    }

    /// Get active subscriptions only
    static var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    /// Get shared subscriptions only
    static var sharedSubscriptions: [Subscription] {
        subscriptions.filter { $0.isShared }
    }

    /// Get trial subscriptions only
    static var trialSubscriptions: [Subscription] {
        subscriptions.filter { $0.isFreeTrial }
    }

    /// Get people with positive balance (they owe you)
    static var peopleOwingYou: [Person] {
        people.filter { $0.balance > 0 }
    }

    /// Get people with negative balance (you owe them)
    static var peopleYouOwe: [Person] {
        people.filter { $0.balance < 0 }
    }

    /// Get unsettled split bills
    static var unsettledSplitBills: [SplitBill] {
        splitBills.filter { !$0.isFullySettled }
    }

    /// Calculate total monthly subscription cost
    static var totalMonthlySubscriptionCost: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    /// Calculate total balance across all people
    static var totalBalance: Double {
        people.reduce(0) { $0 + $1.balance }
    }
}

// MARK: - Heavy Test Data Extension

extension MockData {

    // MARK: - Stable UUIDs for Heavy Testing

    // People UUIDs (20 people)
    private static let htPersonId01 = UUID(uuidString: "A0000001-0001-0001-0001-000000000001")!
    private static let htPersonId02 = UUID(uuidString: "A0000002-0002-0002-0002-000000000002")!
    private static let htPersonId03 = UUID(uuidString: "A0000003-0003-0003-0003-000000000003")!
    private static let htPersonId04 = UUID(uuidString: "A0000004-0004-0004-0004-000000000004")!
    private static let htPersonId05 = UUID(uuidString: "A0000005-0005-0005-0005-000000000005")!
    private static let htPersonId06 = UUID(uuidString: "A0000006-0006-0006-0006-000000000006")!
    private static let htPersonId07 = UUID(uuidString: "A0000007-0007-0007-0007-000000000007")!
    private static let htPersonId08 = UUID(uuidString: "A0000008-0008-0008-0008-000000000008")!
    private static let htPersonId09 = UUID(uuidString: "A0000009-0009-0009-0009-000000000009")!
    private static let htPersonId10 = UUID(uuidString: "A0000010-0010-0010-0010-000000000010")!
    private static let htPersonId11 = UUID(uuidString: "A0000011-0011-0011-0011-000000000011")!
    private static let htPersonId12 = UUID(uuidString: "A0000012-0012-0012-0012-000000000012")!
    private static let htPersonId13 = UUID(uuidString: "A0000013-0013-0013-0013-000000000013")!
    private static let htPersonId14 = UUID(uuidString: "A0000014-0014-0014-0014-000000000014")!
    private static let htPersonId15 = UUID(uuidString: "A0000015-0015-0015-0015-000000000015")!
    private static let htPersonId16 = UUID(uuidString: "A0000016-0016-0016-0016-000000000016")!
    private static let htPersonId17 = UUID(uuidString: "A0000017-0017-0017-0017-000000000017")!
    private static let htPersonId18 = UUID(uuidString: "A0000018-0018-0018-0018-000000000018")!
    private static let htPersonId19 = UUID(uuidString: "A0000019-0019-0019-0019-000000000019")!
    private static let htPersonId20 = UUID(uuidString: "A0000020-0020-0020-0020-000000000020")!

    // Subscription UUIDs (25 subscriptions)
    private static let htSubId01 = UUID(uuidString: "B0000001-0001-0001-0001-000000000001")!
    private static let htSubId02 = UUID(uuidString: "B0000002-0002-0002-0002-000000000002")!
    private static let htSubId03 = UUID(uuidString: "B0000003-0003-0003-0003-000000000003")!
    private static let htSubId04 = UUID(uuidString: "B0000004-0004-0004-0004-000000000004")!
    private static let htSubId05 = UUID(uuidString: "B0000005-0005-0005-0005-000000000005")!
    private static let htSubId06 = UUID(uuidString: "B0000006-0006-0006-0006-000000000006")!
    private static let htSubId07 = UUID(uuidString: "B0000007-0007-0007-0007-000000000007")!
    private static let htSubId08 = UUID(uuidString: "B0000008-0008-0008-0008-000000000008")!
    private static let htSubId09 = UUID(uuidString: "B0000009-0009-0009-0009-000000000009")!
    private static let htSubId10 = UUID(uuidString: "B0000010-0010-0010-0010-000000000010")!
    private static let htSubId11 = UUID(uuidString: "B0000011-0011-0011-0011-000000000011")!
    private static let htSubId12 = UUID(uuidString: "B0000012-0012-0012-0012-000000000012")!
    private static let htSubId13 = UUID(uuidString: "B0000013-0013-0013-0013-000000000013")!
    private static let htSubId14 = UUID(uuidString: "B0000014-0014-0014-0014-000000000014")!
    private static let htSubId15 = UUID(uuidString: "B0000015-0015-0015-0015-000000000015")!
    private static let htSubId16 = UUID(uuidString: "B0000016-0016-0016-0016-000000000016")!
    private static let htSubId17 = UUID(uuidString: "B0000017-0017-0017-0017-000000000017")!
    private static let htSubId18 = UUID(uuidString: "B0000018-0018-0018-0018-000000000018")!
    private static let htSubId19 = UUID(uuidString: "B0000019-0019-0019-0019-000000000019")!
    private static let htSubId20 = UUID(uuidString: "B0000020-0020-0020-0020-000000000020")!
    private static let htSubId21 = UUID(uuidString: "B0000021-0021-0021-0021-000000000021")!
    private static let htSubId22 = UUID(uuidString: "B0000022-0022-0022-0022-000000000022")!
    private static let htSubId23 = UUID(uuidString: "B0000023-0023-0023-0023-000000000023")!
    private static let htSubId24 = UUID(uuidString: "B0000024-0024-0024-0024-000000000024")!
    private static let htSubId25 = UUID(uuidString: "B0000025-0025-0025-0025-000000000025")!

    // Group UUIDs (8 groups)
    private static let htGroupId01 = UUID(uuidString: "C0000001-0001-0001-0001-000000000001")!
    private static let htGroupId02 = UUID(uuidString: "C0000002-0002-0002-0002-000000000002")!
    private static let htGroupId03 = UUID(uuidString: "C0000003-0003-0003-0003-000000000003")!
    private static let htGroupId04 = UUID(uuidString: "C0000004-0004-0004-0004-000000000004")!
    private static let htGroupId05 = UUID(uuidString: "C0000005-0005-0005-0005-000000000005")!
    private static let htGroupId06 = UUID(uuidString: "C0000006-0006-0006-0006-000000000006")!
    private static let htGroupId07 = UUID(uuidString: "C0000007-0007-0007-0007-000000000007")!
    private static let htGroupId08 = UUID(uuidString: "C0000008-0008-0008-0008-000000000008")!

    // MARK: - Heavy Test People (20 People)

    /// All heavy test people for stress testing
    static let heavyTestPeople: [Person] = [
        htFriend1, htFriend2, htFriend3, htFriend4, htFriend5, htFriend6, htFriend7,
        htFamily1, htFamily2, htFamily3, htFamily4, htFamily5,
        htCoworker1, htCoworker2, htCoworker3, htCoworker4, htCoworker5,
        htOther1, htOther2, htOther3
    ]

    // Friends (7)
    static var htFriend1: Person = {
        var p = Person(name: "Emma Wilson", email: "emma.wilson@email.com", phone: "+1 (555) 010-1001", avatarType: .emoji("👩‍💼"), relationshipType: "Friend")
        p.id = htPersonId01; p.balance = 78.25; p.notes = "College roommate"
        return p
    }()

    static var htFriend2: Person = {
        var p = Person(name: "James Chen", email: "james.chen@email.com", phone: "+1 (555) 010-1002", avatarType: .initials("JC", colorIndex: 1), relationshipType: "Friend")
        p.id = htPersonId02; p.balance = -45.50; p.notes = "Basketball buddy"
        return p
    }()

    static var htFriend3: Person = {
        var p = Person(name: "Aisha Patel", email: "aisha.p@email.com", phone: "+1 (555) 010-1003", avatarType: .initials("AP", colorIndex: 2), relationshipType: "Friend")
        p.id = htPersonId03; p.balance = 0.0; p.notes = "Settled up"
        return p
    }()

    static var htFriend4: Person = {
        var p = Person(name: "David Kim", email: "david.kim@email.com", phone: "+1 (555) 010-1004", avatarType: .emoji("👨‍🎤"), relationshipType: "Friend")
        p.id = htPersonId04; p.balance = 120.00; p.notes = "Owes from trip"
        return p
    }()

    static var htFriend5: Person = {
        var p = Person(name: "Olivia Martinez", email: "olivia.m@email.com", phone: "+1 (555) 010-1005", avatarType: .emoji("👩‍🎨"), relationshipType: "Friend")
        p.id = htPersonId05; p.balance = -89.75; p.notes = "Concert tickets"
        return p
    }()

    static var htFriend6: Person = {
        var p = Person(name: "Lucas Brown", email: "lucas.b@email.com", phone: "+1 (555) 010-1006", avatarType: .initials("LB", colorIndex: 3), relationshipType: "Friend")
        p.id = htPersonId06; p.balance = 32.50; p.notes = "Dinner split"
        return p
    }()

    static var htFriend7: Person = {
        var p = Person(name: "Sophia Anderson", email: "sophia.a@email.com", phone: "+1 (555) 010-1007", avatarType: .emoji("👩‍🔬"), relationshipType: "Friend")
        p.id = htPersonId07; p.balance = -15.00; p.notes = "Coffee runs"
        return p
    }()

    // Family (5)
    static var htFamily1: Person = {
        var p = Person(name: "Patricia (Mom)", email: "mom@family.com", phone: "+1 (555) 020-2001", avatarType: .emoji("👩‍👧"), relationshipType: "Family")
        p.id = htPersonId08; p.balance = 0.0; p.notes = "Family account"
        return p
    }()

    static var htFamily2: Person = {
        var p = Person(name: "Robert (Dad)", email: "dad@family.com", phone: "+1 (555) 020-2002", avatarType: .emoji("👨‍👧"), relationshipType: "Family")
        p.id = htPersonId09; p.balance = 500.00; p.notes = "Holiday gift"
        return p
    }()

    static var htFamily3: Person = {
        var p = Person(name: "Jennifer (Sister)", email: "jen@family.com", phone: "+1 (555) 020-2003", avatarType: .emoji("👩"), relationshipType: "Family")
        p.id = htPersonId10; p.balance = -75.00; p.notes = "Shared Netflix"
        return p
    }()

    static var htFamily4: Person = {
        var p = Person(name: "Michael (Brother)", email: "mike@family.com", phone: "+1 (555) 020-2004", avatarType: .emoji("👨"), relationshipType: "Family")
        p.id = htPersonId11; p.balance = 150.00; p.notes = "Borrowed money"
        return p
    }()

    static var htFamily5: Person = {
        var p = Person(name: "Rachel (Cousin)", email: "rachel@family.com", phone: "+1 (555) 020-2005", avatarType: .initials("RC", colorIndex: 4), relationshipType: "Family")
        p.id = htPersonId12; p.balance = -25.00; p.notes = "Birthday dinner"
        return p
    }()

    // Coworkers (5)
    static var htCoworker1: Person = {
        var p = Person(name: "Sarah Johnson", email: "sarah.j@work.com", phone: "+1 (555) 030-3001", avatarType: .initials("SJ", colorIndex: 5), relationshipType: "Coworker")
        p.id = htPersonId13; p.balance = 23.45; p.notes = "Lunch buddy"
        return p
    }()

    static var htCoworker2: Person = {
        var p = Person(name: "Alex Thompson", email: "alex.t@work.com", phone: "+1 (555) 030-3002", avatarType: .emoji("👨‍💻"), relationshipType: "Coworker")
        p.id = htPersonId14; p.balance = -67.80; p.notes = "Team lunch"
        return p
    }()

    static var htCoworker3: Person = {
        var p = Person(name: "Chris Williams", email: "chris.w@work.com", phone: "+1 (555) 030-3003", avatarType: .initials("CW", colorIndex: 6), relationshipType: "Coworker")
        p.id = htPersonId15; p.balance = 0.0; p.notes = "Settled"
        return p
    }()

    static var htCoworker4: Person = {
        var p = Person(name: "Morgan Lee", email: "morgan.l@work.com", phone: "+1 (555) 030-3004", avatarType: .emoji("👩‍💼"), relationshipType: "Coworker")
        p.id = htPersonId16; p.balance = 42.00; p.notes = "Coffee fund"
        return p
    }()

    static var htCoworker5: Person = {
        var p = Person(name: "Taylor Davis", email: "taylor.d@work.com", phone: "+1 (555) 030-3005", avatarType: .initials("TD", colorIndex: 7), relationshipType: "Coworker")
        p.id = htPersonId17; p.balance = -18.50; p.notes = "Snack run"
        return p
    }()

    // Others (3)
    static var htOther1: Person = {
        var p = Person(name: "Dr. Amanda Foster", email: "dr.foster@clinic.com", phone: "+1 (555) 040-4001", avatarType: .emoji("👩‍⚕️"), relationshipType: "Other")
        p.id = htPersonId18; p.balance = -200.00; p.notes = "Medical copay"
        return p
    }()

    static var htOther2: Person = {
        var p = Person(name: "Jake (Personal Trainer)", email: "jake@fitgym.com", phone: "+1 (555) 040-4002", avatarType: .emoji("🏋️"), relationshipType: "Other")
        p.id = htPersonId19; p.balance = -150.00; p.notes = "Session fee"
        return p
    }()

    static var htOther3: Person = {
        var p = Person(name: "Mr. Chen (Landlord)", email: "landlord@building.com", phone: "+1 (555) 040-4003", avatarType: .initials("MC", colorIndex: 0), relationshipType: "Other")
        p.id = htPersonId20; p.balance = 0.0; p.notes = "Rent always on time"
        return p
    }()

    // MARK: - Heavy Test Subscriptions (25 Subscriptions)

    /// All heavy test subscriptions for stress testing
    static let heavyTestSubscriptions: [Subscription] = [
        // Entertainment (8)
        htSub01, htSub02, htSub03, htSub04, htSub05, htSub06, htSub07, htSub08,
        // Productivity (6)
        htSub09, htSub10, htSub11, htSub12, htSub13, htSub14,
        // Health & Fitness (4)
        htSub15, htSub16, htSub17, htSub18,
        // Utilities & Storage (4)
        htSub19, htSub20, htSub21, htSub22,
        // News & Learning (3)
        htSub23, htSub24, htSub25
    ]

    // Entertainment (8)
    static var htSub01: Subscription = {
        var s = Subscription(name: "Netflix Premium", description: "4K streaming with 4 screens", price: 22.99, billingCycle: .monthly, category: .entertainment, icon: "tv.fill", color: "#E50914")
        s.id = htSubId01; s.isActive = true; s.isShared = true; s.sharedWith = [htPersonId01, htPersonId02, htPersonId03]
        s.createdDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 45
        return s
    }()

    static var htSub02: Subscription = {
        var s = Subscription(name: "Spotify Family", description: "Premium family plan - 6 accounts", price: 16.99, billingCycle: .monthly, category: .music, icon: "music.note", color: "#1DB954")
        s.id = htSubId02; s.isActive = true; s.isShared = true; s.sharedWith = [htPersonId08, htPersonId09, htPersonId10, htPersonId11]
        s.createdDate = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 120
        return s
    }()

    static var htSub03: Subscription = {
        var s = Subscription(name: "Disney+ Bundle", description: "Disney+, Hulu, ESPN+", price: 13.99, billingCycle: .monthly, category: .entertainment, icon: "sparkles.tv", color: "#113CCF")
        s.id = htSubId03; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!; s.usageCount = 28
        return s
    }()

    static var htSub04: Subscription = {
        var s = Subscription(name: "HBO Max", description: "Ad-free streaming", price: 15.99, billingCycle: .monthly, category: .entertainment, icon: "play.tv", color: "#5822B4")
        s.id = htSubId04; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -4, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!; s.usageCount = 15
        return s
    }()

    static var htSub05: Subscription = {
        var s = Subscription(name: "Apple TV+", description: "Original shows", price: 9.99, billingCycle: .monthly, category: .entertainment, icon: "appletv", color: "#000000")
        s.id = htSubId05; s.isActive = true; s.isShared = true; s.sharedWith = [htPersonId04, htPersonId05]
        s.createdDate = Calendar.current.date(byAdding: .month, value: -10, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!; s.usageCount = 35
        return s
    }()

    static var htSub06: Subscription = {
        var s = Subscription(name: "YouTube Premium", description: "Ad-free videos + music", price: 13.99, billingCycle: .monthly, category: .entertainment, icon: "play.rectangle.fill", color: "#FF0000")
        s.id = htSubId06; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -18, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 200
        return s
    }()

    static var htSub07: Subscription = {
        var s = Subscription(name: "Hulu", description: "Cancelled streaming", price: 17.99, billingCycle: .monthly, category: .entertainment, icon: "play.circle", color: "#1CE783")
        s.id = htSubId07; s.isActive = false; s.cancellationDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        s.createdDate = Calendar.current.date(byAdding: .month, value: -14, to: Date())!
        return s
    }()

    static var htSub08: Subscription = {
        var s = Subscription(name: "Paramount+", description: "7-day free trial", price: 5.99, billingCycle: .monthly, category: .entertainment, icon: "star.circle.fill", color: "#0064FF")
        s.id = htSubId08; s.isFreeTrial = true; s.trialStartDate = Date(); s.trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()); s.trialDuration = 7; s.willConvertToPaid = true; s.priceAfterTrial = 5.99
        s.createdDate = Date()
        return s
    }()

    // Productivity (6)
    static var htSub09: Subscription = {
        var s = Subscription(name: "Microsoft 365", description: "Office apps + 1TB OneDrive", price: 99.99, billingCycle: .annually, category: .productivity, icon: "doc.fill", color: "#0078D4")
        s.id = htSubId09; s.isActive = true; s.isShared = true; s.sharedWith = [htPersonId08, htPersonId09, htPersonId10, htPersonId11, htPersonId12]
        s.createdDate = Calendar.current.date(byAdding: .month, value: -24, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 300
        return s
    }()

    static var htSub10: Subscription = {
        var s = Subscription(name: "Adobe Creative Cloud", description: "Full creative suite", price: 54.99, billingCycle: .monthly, category: .design, icon: "paintbrush.fill", color: "#FF0000")
        s.id = htSubId10; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -18, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!; s.usageCount = 85
        return s
    }()

    static var htSub11: Subscription = {
        var s = Subscription(name: "Notion Pro", description: "Unlimited workspace", price: 8.00, billingCycle: .monthly, category: .productivity, icon: "doc.text", color: "#000000")
        s.id = htSubId11; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 150
        return s
    }()

    static var htSub12: Subscription = {
        var s = Subscription(name: "Figma Pro", description: "Design collaboration", price: 15.00, billingCycle: .monthly, category: .design, icon: "pencil.and.ruler", color: "#F24E1E")
        s.id = htSubId12; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!; s.usageCount = 60
        return s
    }()

    static var htSub13: Subscription = {
        var s = Subscription(name: "Slack Pro", description: "Team communication", price: 8.75, billingCycle: .monthly, category: .productivity, icon: "bubble.left.and.bubble.right", color: "#4A154B")
        s.id = htSubId13; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -20, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 500
        return s
    }()

    static var htSub14: Subscription = {
        var s = Subscription(name: "Zoom Pro", description: "Video conferencing - Paused", price: 15.99, billingCycle: .monthly, category: .productivity, icon: "video.fill", color: "#2D8CFF")
        s.id = htSubId14; s.isActive = false
        s.createdDate = Calendar.current.date(byAdding: .month, value: -15, to: Date())!
        return s
    }()

    // Health & Fitness (4)
    static var htSub15: Subscription = {
        var s = Subscription(name: "Gym Membership", description: "24 Hour Fitness access", price: 49.99, billingCycle: .monthly, category: .fitness, icon: "figure.walk", color: "#FF6B35")
        s.id = htSubId15; s.isActive = true; s.usageCount = 18
        s.createdDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return s
    }()

    static var htSub16: Subscription = {
        var s = Subscription(name: "Headspace", description: "Meditation & mindfulness", price: 12.99, billingCycle: .monthly, category: .health, icon: "brain.head.profile", color: "#FF6B00")
        s.id = htSubId16; s.isActive = true; s.usageCount = 25
        s.createdDate = Calendar.current.date(byAdding: .month, value: -5, to: Date())!
        s.lastUsedDate = Date()
        return s
    }()

    static var htSub17: Subscription = {
        var s = Subscription(name: "Strava Premium", description: "Advanced running analytics", price: 11.99, billingCycle: .monthly, category: .fitness, icon: "figure.run", color: "#FC4C02")
        s.id = htSubId17; s.isActive = true; s.usageCount = 12
        s.createdDate = Calendar.current.date(byAdding: .month, value: -4, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        return s
    }()

    static var htSub18: Subscription = {
        var s = Subscription(name: "MyFitnessPal Premium", description: "Nutrition tracking", price: 79.99, billingCycle: .annually, category: .health, icon: "fork.knife", color: "#0066CC")
        s.id = htSubId18; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -10, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 200
        return s
    }()

    // Utilities & Storage (4)
    static var htSub19: Subscription = {
        var s = Subscription(name: "iCloud+ 200GB", description: "Family sharing enabled", price: 2.99, billingCycle: .monthly, category: .cloud, icon: "icloud.fill", color: "#007AFF")
        s.id = htSubId19; s.isActive = true; s.isShared = true; s.sharedWith = [htPersonId08, htPersonId09, htPersonId10, htPersonId11, htPersonId12]
        s.createdDate = Calendar.current.date(byAdding: .month, value: -36, to: Date())!
        return s
    }()

    static var htSub20: Subscription = {
        var s = Subscription(name: "Google One 2TB", description: "Cloud storage + VPN", price: 9.99, billingCycle: .monthly, category: .cloud, icon: "externaldrive.fill.badge.icloud", color: "#4285F4")
        s.id = htSubId20; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -24, to: Date())!
        return s
    }()

    static var htSub21: Subscription = {
        var s = Subscription(name: "Dropbox Plus", description: "2TB cloud storage", price: 11.99, billingCycle: .monthly, category: .cloud, icon: "externaldrive.fill", color: "#0061FF")
        s.id = htSubId21; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -30, to: Date())!
        return s
    }()

    static var htSub22: Subscription = {
        var s = Subscription(name: "1Password Family", description: "Password manager for family", price: 4.99, billingCycle: .monthly, category: .utilities, icon: "lock.fill", color: "#1A8CFF")
        s.id = htSubId22; s.isActive = true; s.isShared = true; s.sharedWith = [htPersonId08, htPersonId09, htPersonId10, htPersonId11, htPersonId12]
        s.createdDate = Calendar.current.date(byAdding: .month, value: -18, to: Date())!
        return s
    }()

    // News & Learning (3)
    static var htSub23: Subscription = {
        var s = Subscription(name: "NY Times Digital", description: "All Access subscription", price: 17.00, billingCycle: .monthly, category: .news, icon: "newspaper.fill", color: "#000000")
        s.id = htSubId23; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -9, to: Date())!
        s.lastUsedDate = Date(); s.usageCount = 45
        return s
    }()

    static var htSub24: Subscription = {
        var s = Subscription(name: "The Athletic", description: "Sports journalism", price: 9.99, billingCycle: .monthly, category: .news, icon: "sportscourt", color: "#C4122E")
        s.id = htSubId24; s.isActive = true
        s.createdDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        s.lastUsedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!; s.usageCount = 30
        return s
    }()

    static var htSub25: Subscription = {
        var s = Subscription(name: "Skillshare Premium", description: "14-day trial - Online classes", price: 168.00, billingCycle: .annually, category: .education, icon: "book.fill", color: "#00FF84")
        s.id = htSubId25; s.isFreeTrial = true; s.trialStartDate = Date(); s.trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()); s.trialDuration = 14; s.willConvertToPaid = false; s.priceAfterTrial = 168.00
        s.createdDate = Date()
        return s
    }()

    // MARK: - Heavy Test Transactions (200+ Transactions over 12 months)

    /// All heavy test transactions for stress testing
    static var heavyTestTransactions: [Transaction] {
        var transactions: [Transaction] = []
        let calendar = Calendar.current
        let today = Date()

        // Transaction templates
        let merchants = [
            ("Chipotle", "Lunch", -14.50, TransactionCategory.dining),
            ("Starbucks", "Coffee", -6.75, TransactionCategory.dining),
            ("Amazon", "Online shopping", -89.99, TransactionCategory.shopping),
            ("Target", "Household items", -67.45, TransactionCategory.shopping),
            ("Uber", "Ride to downtown", -24.50, TransactionCategory.transportation),
            ("Lyft", "Airport ride", -42.00, TransactionCategory.transportation),
            ("Shell Gas", "Gas fill-up", -52.30, TransactionCategory.transportation),
            ("Whole Foods", "Groceries", -127.45, TransactionCategory.groceries),
            ("Trader Joe's", "Weekly groceries", -87.34, TransactionCategory.groceries),
            ("Costco", "Bulk shopping", -215.67, TransactionCategory.groceries),
            ("Netflix", "Streaming", -19.99, TransactionCategory.entertainment),
            ("Spotify", "Music", -10.99, TransactionCategory.entertainment),
            ("AMC Theatres", "Movie tickets", -32.00, TransactionCategory.entertainment),
            ("AT&T", "Phone bill", -85.00, TransactionCategory.bills),
            ("Comcast", "Internet", -89.99, TransactionCategory.bills),
            ("PG&E", "Electricity", -145.00, TransactionCategory.bills),
            ("Best Buy", "Electronics", -299.99, TransactionCategory.shopping),
            ("Apple Store", "Accessories", -49.00, TransactionCategory.shopping),
            ("Walgreens", "Pharmacy", -23.45, TransactionCategory.healthcare),
            ("CVS", "Health supplies", -34.56, TransactionCategory.healthcare)
        ]

        // Generate 200+ transactions over 12 months
        for monthOffset in 0..<12 {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today)!
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)!.count

            // 15-20 transactions per month
            let transactionCount = Int.random(in: 15...20)

            for i in 0..<transactionCount {
                let dayOffset = Int.random(in: 1...daysInMonth)
                let transactionDate = calendar.date(byAdding: .day, value: -dayOffset, to: monthDate)!

                let template = merchants[i % merchants.count]
                let variation = Double.random(in: 0.8...1.2)
                let amount = template.2 * variation

                let transaction = Transaction(
                    title: template.0,
                    subtitle: template.1,
                    amount: amount,
                    category: template.3,
                    date: transactionDate,
                    isRecurring: template.3 == TransactionCategory.bills || template.3 == TransactionCategory.entertainment,
                    tags: [template.3.rawValue.lowercased()],
                    merchant: template.0,
                    paymentStatus: .completed
                )
                transactions.append(transaction)
            }

            // Add monthly income
            let salaryDate = calendar.date(byAdding: .day, value: -15, to: monthDate)!
            let salary = Transaction(
                title: "Salary Deposit",
                subtitle: "Monthly paycheck - Tech Corp",
                amount: 5250.00,
                category: .income,
                date: salaryDate,
                isRecurring: true,
                tags: ["work", "monthly", "salary"],
                merchant: "Tech Corp Inc.",
                paymentStatus: .completed
            )
            transactions.append(salary)

            // Add rent (first of month)
            let rentDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: monthDate), month: calendar.component(.month, from: monthDate), day: 1))!
            let rent = Transaction(
                title: "Rent Payment",
                subtitle: "Monthly apartment rent",
                amount: -1800.00,
                category: .bills,
                date: rentDate,
                isRecurring: true,
                tags: ["housing", "monthly"],
                merchant: "Property Management",
                paymentStatus: .completed
            )
            transactions.append(rent)
        }

        return transactions
    }

    // MARK: - Heavy Test Groups (8 Groups)

    /// All heavy test groups for stress testing
    static let heavyTestGroups: [Group] = [
        htGroup01, htGroup02, htGroup03, htGroup04, htGroup05, htGroup06, htGroup07, htGroup08
    ]

    static var htGroup01: Group = {
        var g = Group(name: "Beach Vacation 2024", description: "Summer trip to Malibu with friends", emoji: "🏖️", members: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05])
        g.id = htGroupId01
        g.expenses = [
            GroupExpense(title: "Airbnb Beach House", amount: 1200.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05], category: .travel, notes: "4 nights"),
            GroupExpense(title: "Surfboard Rentals", amount: 250.00, paidBy: htPersonId02, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05], category: .entertainment),
            GroupExpense(title: "Seafood Dinner", amount: 350.00, paidBy: htPersonId03, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05], category: .dining),
            GroupExpense(title: "Groceries", amount: 180.00, paidBy: htPersonId04, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05], category: .groceries),
            GroupExpense(title: "Beach Equipment", amount: 120.00, paidBy: htPersonId05, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05], category: .shopping),
            GroupExpense(title: "Gas for Trip", amount: 150.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05], category: .transportation)
        ]
        g.totalAmount = 2250.00
        return g
    }()

    static var htGroup02: Group = {
        var g = Group(name: "Monthly Dinner Club", description: "Friends who love food", emoji: "🍽️", members: [htPersonId01, htPersonId06, htPersonId07, htPersonId03])
        g.id = htGroupId02
        g.expenses = [
            GroupExpense(title: "Italian Restaurant", amount: 220.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId06, htPersonId07, htPersonId03], category: .dining),
            GroupExpense(title: "Sushi Night", amount: 280.00, paidBy: htPersonId06, splitBetween: [htPersonId01, htPersonId06, htPersonId07, htPersonId03], category: .dining),
            GroupExpense(title: "Thai Cuisine", amount: 195.00, paidBy: htPersonId07, splitBetween: [htPersonId01, htPersonId06, htPersonId07, htPersonId03], category: .dining),
            GroupExpense(title: "French Bistro", amount: 195.00, paidBy: htPersonId03, splitBetween: [htPersonId01, htPersonId06, htPersonId07, htPersonId03], category: .dining)
        ]
        g.totalAmount = 890.00
        return g
    }()

    static var htGroup03: Group = {
        var g = Group(name: "Office Lunch Group", description: "Daily lunch crew", emoji: "💼", members: [htPersonId13, htPersonId14, htPersonId15, htPersonId16, htPersonId17, htPersonId01])
        g.id = htGroupId03
        g.expenses = [
            GroupExpense(title: "Monday Pizza", amount: 85.00, paidBy: htPersonId13, splitBetween: [htPersonId13, htPersonId14, htPersonId15, htPersonId16, htPersonId17, htPersonId01], category: .dining),
            GroupExpense(title: "Tuesday Tacos", amount: 72.00, paidBy: htPersonId14, splitBetween: [htPersonId13, htPersonId14, htPersonId15, htPersonId16, htPersonId17, htPersonId01], category: .dining),
            GroupExpense(title: "Wednesday Salads", amount: 68.00, paidBy: htPersonId15, splitBetween: [htPersonId13, htPersonId14, htPersonId15, htPersonId16, htPersonId17, htPersonId01], category: .dining),
            GroupExpense(title: "Thursday Burgers", amount: 92.00, paidBy: htPersonId16, splitBetween: [htPersonId13, htPersonId14, htPersonId15, htPersonId16, htPersonId17, htPersonId01], category: .dining)
        ]
        g.totalAmount = 317.00
        return g
    }()

    static var htGroup04: Group = {
        var g = Group(name: "Road Trip Crew", description: "Cross-country adventure", emoji: "🚗", members: [htPersonId01, htPersonId02, htPersonId04, htPersonId06])
        g.id = htGroupId04
        g.expenses = [
            GroupExpense(title: "Car Rental", amount: 450.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId04, htPersonId06], category: .transportation, isSettled: true),
            GroupExpense(title: "Gas - Leg 1", amount: 120.00, paidBy: htPersonId02, splitBetween: [htPersonId01, htPersonId02, htPersonId04, htPersonId06], category: .transportation, isSettled: true),
            GroupExpense(title: "Motel Stays", amount: 360.00, paidBy: htPersonId04, splitBetween: [htPersonId01, htPersonId02, htPersonId04, htPersonId06], category: .travel, isSettled: true),
            GroupExpense(title: "Food & Snacks", amount: 270.00, paidBy: htPersonId06, splitBetween: [htPersonId01, htPersonId02, htPersonId04, htPersonId06], category: .dining, isSettled: true)
        ]
        g.totalAmount = 1200.00
        return g
    }()

    static var htGroup05: Group = {
        var g = Group(name: "Game Night", description: "Weekly board game sessions", emoji: "🎮", members: [htPersonId01, htPersonId02, htPersonId03, htPersonId05, htPersonId07])
        g.id = htGroupId05
        g.expenses = [
            GroupExpense(title: "New Board Games", amount: 65.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId05, htPersonId07], category: .entertainment),
            GroupExpense(title: "Snacks & Drinks", amount: 45.00, paidBy: htPersonId02, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId05, htPersonId07], category: .dining)
        ]
        g.totalAmount = 110.00
        return g
    }()

    static var htGroup06: Group = {
        var g = Group(name: "Birthday Planning", description: "Surprise party for Alex", emoji: "🎂", members: [htPersonId01, htPersonId03, htPersonId05])
        g.id = htGroupId06
        g.expenses = [
            GroupExpense(title: "Venue Deposit", amount: 150.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId03, htPersonId05], category: .entertainment),
            GroupExpense(title: "Cake Order", amount: 85.00, paidBy: htPersonId03, splitBetween: [htPersonId01, htPersonId03, htPersonId05], category: .dining),
            GroupExpense(title: "Decorations", amount: 55.00, paidBy: htPersonId05, splitBetween: [htPersonId01, htPersonId03, htPersonId05], category: .shopping),
            GroupExpense(title: "Gift", amount: 60.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId03, htPersonId05], category: .shopping)
        ]
        g.totalAmount = 350.00
        return g
    }()

    static var htGroup07: Group = {
        var g = Group(name: "Apartment Expenses", description: "Shared living costs", emoji: "🏠", members: [htPersonId01, htPersonId02, htPersonId07])
        g.id = htGroupId07
        g.expenses = [
            GroupExpense(title: "December Rent Share", amount: 1800.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId07], category: .bills),
            GroupExpense(title: "Utilities - Dec", amount: 145.00, paidBy: htPersonId02, splitBetween: [htPersonId01, htPersonId02, htPersonId07], category: .bills),
            GroupExpense(title: "Internet - Dec", amount: 89.99, paidBy: htPersonId07, splitBetween: [htPersonId01, htPersonId02, htPersonId07], category: .bills),
            GroupExpense(title: "Cleaning Supplies", amount: 45.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId07], category: .shopping),
            GroupExpense(title: "November Rent", amount: 1800.00, paidBy: htPersonId02, splitBetween: [htPersonId01, htPersonId02, htPersonId07], category: .bills, isSettled: true),
            GroupExpense(title: "Utilities - Nov", amount: 132.00, paidBy: htPersonId07, splitBetween: [htPersonId01, htPersonId02, htPersonId07], category: .bills, isSettled: true)
        ]
        g.totalAmount = 4011.99
        return g
    }()

    static var htGroup08: Group = {
        var g = Group(name: "Ski Trip 2025", description: "Planning for Colorado trip", emoji: "⛷️", members: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05, htPersonId06])
        g.id = htGroupId08
        g.expenses = [
            GroupExpense(title: "Cabin Deposit", amount: 800.00, paidBy: htPersonId01, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05, htPersonId06], category: .travel, notes: "50% deposit - remaining due Jan 1"),
            GroupExpense(title: "Lift Tickets (Group)", amount: 1800.00, paidBy: htPersonId02, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05, htPersonId06], category: .entertainment),
            GroupExpense(title: "Equipment Rental Deposit", amount: 600.00, paidBy: htPersonId03, splitBetween: [htPersonId01, htPersonId02, htPersonId03, htPersonId04, htPersonId05, htPersonId06], category: .entertainment)
        ]
        g.totalAmount = 3200.00
        return g
    }()

    // MARK: - Heavy Test Split Bills (30+ Split Bills)

    /// All heavy test split bills for stress testing
    static var heavyTestSplitBills: [SplitBill] {
        var bills: [SplitBill] = []
        let calendar = Calendar.current
        let today = Date()

        // Fully Settled (10)
        bills.append(contentsOf: [
            createSplitBill(title: "Sushi Dinner", amount: 180.00, paidBy: htPersonId01, participants: [htPersonId02, htPersonId03, htPersonId04, htPersonId05], allPaid: true, daysAgo: 30),
            createSplitBill(title: "Grocery Run", amount: 95.00, paidBy: htPersonId02, participants: [htPersonId01, htPersonId03], allPaid: true, daysAgo: 28),
            createSplitBill(title: "Team Lunch", amount: 156.00, paidBy: htPersonId13, participants: [htPersonId14, htPersonId15, htPersonId16, htPersonId17, htPersonId01], allPaid: true, daysAgo: 25),
            createSplitBill(title: "Coffee Run", amount: 35.00, paidBy: htPersonId03, participants: [htPersonId01, htPersonId02], allPaid: true, daysAgo: 22),
            createSplitBill(title: "Pizza Night", amount: 78.00, paidBy: htPersonId04, participants: [htPersonId01, htPersonId02, htPersonId05], allPaid: true, daysAgo: 20),
            createSplitBill(title: "Movie Tickets", amount: 64.00, paidBy: htPersonId05, participants: [htPersonId01, htPersonId02, htPersonId03], allPaid: true, daysAgo: 18),
            createSplitBill(title: "Brunch", amount: 120.00, paidBy: htPersonId06, participants: [htPersonId01, htPersonId07, htPersonId03], allPaid: true, daysAgo: 15),
            createSplitBill(title: "Happy Hour", amount: 95.00, paidBy: htPersonId07, participants: [htPersonId01, htPersonId02, htPersonId06], allPaid: true, daysAgo: 12),
            createSplitBill(title: "Takeout Thai", amount: 68.00, paidBy: htPersonId01, participants: [htPersonId02, htPersonId03], allPaid: true, daysAgo: 10),
            createSplitBill(title: "Game Night Snacks", amount: 45.00, paidBy: htPersonId02, participants: [htPersonId01, htPersonId05, htPersonId07], allPaid: true, daysAgo: 8)
        ])

        // Partially Settled (10)
        bills.append(contentsOf: [
            createSplitBill(title: "Weekend Cabin", amount: 800.00, paidBy: htPersonId01, participants: [htPersonId02, htPersonId03, htPersonId04], partiallyPaid: [htPersonId02, htPersonId03], daysAgo: 7),
            createSplitBill(title: "Birthday Gift", amount: 200.00, paidBy: htPersonId03, participants: [htPersonId01, htPersonId04, htPersonId05], partiallyPaid: [htPersonId01, htPersonId04], daysAgo: 6),
            createSplitBill(title: "Group Dinner", amount: 180.00, paidBy: htPersonId04, participants: [htPersonId01, htPersonId02, htPersonId03], partiallyPaid: [htPersonId01], daysAgo: 5),
            createSplitBill(title: "Concert Tickets", amount: 450.00, paidBy: htPersonId01, participants: [htPersonId05, htPersonId06, htPersonId07], partiallyPaid: [htPersonId05], daysAgo: 5),
            createSplitBill(title: "Airbnb Booking", amount: 1200.00, paidBy: htPersonId02, participants: [htPersonId01, htPersonId03, htPersonId04], partiallyPaid: [htPersonId01], daysAgo: 4),
            createSplitBill(title: "Uber Pool", amount: 35.00, paidBy: htPersonId06, participants: [htPersonId01, htPersonId07], partiallyPaid: [htPersonId01], daysAgo: 4),
            createSplitBill(title: "Lunch Meeting", amount: 92.00, paidBy: htPersonId13, participants: [htPersonId14, htPersonId15, htPersonId16], partiallyPaid: [htPersonId14, htPersonId15], daysAgo: 3),
            createSplitBill(title: "Drinks After Work", amount: 78.00, paidBy: htPersonId14, participants: [htPersonId13, htPersonId15, htPersonId17], partiallyPaid: [htPersonId13], daysAgo: 3),
            createSplitBill(title: "Sports Bar Tab", amount: 145.00, paidBy: htPersonId01, participants: [htPersonId02, htPersonId04, htPersonId06], partiallyPaid: [htPersonId02], daysAgo: 2),
            createSplitBill(title: "Grocery Shopping", amount: 167.00, paidBy: htPersonId07, participants: [htPersonId01, htPersonId02], partiallyPaid: [htPersonId01], daysAgo: 2)
        ])

        // All Pending (10)
        bills.append(contentsOf: [
            createSplitBill(title: "Italian Dinner", amount: 220.00, paidBy: htPersonId01, participants: [htPersonId02, htPersonId03, htPersonId04, htPersonId05], allPaid: false, daysAgo: 1),
            createSplitBill(title: "Karaoke Night", amount: 180.00, paidBy: htPersonId05, participants: [htPersonId01, htPersonId02, htPersonId07], allPaid: false, daysAgo: 1),
            createSplitBill(title: "Bowling", amount: 95.00, paidBy: htPersonId06, participants: [htPersonId01, htPersonId03, htPersonId05], allPaid: false, daysAgo: 1),
            createSplitBill(title: "Escape Room", amount: 150.00, paidBy: htPersonId02, participants: [htPersonId01, htPersonId04, htPersonId07], allPaid: false, daysAgo: 0),
            createSplitBill(title: "Brunch Spot", amount: 135.00, paidBy: htPersonId03, participants: [htPersonId01, htPersonId02, htPersonId05], allPaid: false, daysAgo: 0),
            createSplitBill(title: "Office Supplies", amount: 67.00, paidBy: htPersonId13, participants: [htPersonId14, htPersonId15], allPaid: false, daysAgo: 0),
            createSplitBill(title: "Coffee Subscription", amount: 45.00, paidBy: htPersonId16, participants: [htPersonId13, htPersonId17], allPaid: false, daysAgo: 0),
            createSplitBill(title: "Streaming Gift", amount: 120.00, paidBy: htPersonId01, participants: [htPersonId08, htPersonId09], allPaid: false, daysAgo: 0),
            createSplitBill(title: "Family Dinner", amount: 280.00, paidBy: htPersonId08, participants: [htPersonId01, htPersonId09, htPersonId10, htPersonId11], allPaid: false, daysAgo: 0),
            createSplitBill(title: "Holiday Decorations", amount: 95.00, paidBy: htPersonId10, participants: [htPersonId01, htPersonId08, htPersonId11], allPaid: false, daysAgo: 0)
        ])

        return bills
    }

    /// Helper function to create split bills
    private static func createSplitBill(
        title: String,
        amount: Double,
        paidBy: UUID,
        participants: [UUID],
        allPaid: Bool = false,
        partiallyPaid: [UUID] = [],
        daysAgo: Int
    ) -> SplitBill {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let splitAmount = amount / Double(participants.count + 1)

        var splitParticipants: [SplitParticipant] = []
        for personId in participants {
            var participant = SplitParticipant(personId: personId, amount: splitAmount, hasPaid: allPaid || partiallyPaid.contains(personId))
            if participant.hasPaid {
                participant.paymentDate = calendar.date(byAdding: .hour, value: -Int.random(in: 1...48), to: Date())
            }
            splitParticipants.append(participant)
        }

        return SplitBill(
            title: title,
            totalAmount: amount,
            paidById: paidBy,
            splitType: .equally,
            participants: splitParticipants,
            notes: "",
            category: .dining,
            date: date
        )
    }

    // MARK: - Combined Heavy Test Data

    /// All people (original + heavy test)
    static var allPeople: [Person] {
        people + heavyTestPeople
    }

    /// All subscriptions (original + heavy test)
    static var allSubscriptions: [Subscription] {
        subscriptions + heavyTestSubscriptions
    }

    /// All transactions (original + heavy test)
    static var allTransactions: [Transaction] {
        transactions + heavyTestTransactions
    }

    /// All groups (original + heavy test)
    static var allGroups: [Group] {
        groups + heavyTestGroups
    }

    /// All split bills (original + heavy test)
    static var allSplitBills: [SplitBill] {
        splitBills + heavyTestSplitBills
    }

    // MARK: - Person Timeline Items

    /// Helper function for date creation
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    /// Get timeline items for a person by ID
    static func timelineItems(for personId: UUID) -> [PersonTimelineItem] {
        switch personId {
        // Original MockData people (personId1-7)
        case personId1: return emmaWilsonTimelineItems      // Emma Wilson
        case personId2: return jamesChenTimelineItems       // James Chen
        case personId3: return aishaPatelTimelineItems      // Aisha Patel
        case personId4: return davidKimTimelineItems        // David Kim
        case personId5: return oliviaMartinezTimelineItems  // Olivia (personFamily)
        case personId6: return lucasBrownTimelineItems      // Lucas (personCoworker)
        case personId7: return sophiaAndersonTimelineItems  // Long name person

        // Heavy test people (htPersonId01-20)
        case htPersonId01: return emmaWilsonTimelineItems
        case htPersonId02: return jamesChenTimelineItems
        case htPersonId03: return aishaPatelTimelineItems
        case htPersonId04: return davidKimTimelineItems
        case htPersonId05: return oliviaMartinezTimelineItems
        case htPersonId06: return lucasBrownTimelineItems
        case htPersonId07: return sophiaAndersonTimelineItems
        case htPersonId08: return patriciaTimelineItems
        case htPersonId09: return robertTimelineItems
        case htPersonId10: return jenniferTimelineItems
        case htPersonId11: return michaelTimelineItems
        case htPersonId12: return rachelTimelineItems
        case htPersonId13: return sarahJohnsonTimelineItems
        case htPersonId14: return alexThompsonTimelineItems
        case htPersonId15: return chrisWilliamsTimelineItems
        case htPersonId16: return morganLeeTimelineItems
        case htPersonId17: return taylorDavisTimelineItems
        case htPersonId18: return drAmandaFosterTimelineItems
        case htPersonId19: return jakeTrainerTimelineItems
        case htPersonId20: return mrChenLandlordTimelineItems
        default: return []
        }
    }

    /// Generate personalized timeline items using the person's actual name
    /// This is the main entry point - it checks for predefined items first, then generates defaults
    static func timelineItems(for personId: UUID, personName: String) -> [PersonTimelineItem] {
        // First check if we have specific items for this person
        let specificItems = timelineItems(for: personId)
        if !specificItems.isEmpty {
            return specificItems
        }

        // Generate personalized items for unknown people
        return [
            .message(id: UUID(), text: "Hey! Want to grab lunch this week?", isFromPerson: true, date: daysAgo(7)),
            .message(id: UUID(), text: "Sure! How about Thursday?", isFromPerson: false, date: daysAgo(7)),
            .payment(id: UUID(), amount: 8.50, direction: .outgoing, description: "Coffee last week", date: daysAgo(5)),
            .paidBill(id: UUID(), personName: personName, date: daysAgo(2)),
            .splitRequest(id: UUID(), title: "Dinner at Restaurant", message: "Hey! I covered dinner last night. Can you send me your share when you get a chance?", billTotal: 97.50, paidBy: personName, youOwe: 48.75, date: daysAgo(2))
        ]
    }

    // MARK: - Friends Timeline Items

    /// Timeline items for Emma Wilson - owes $78.25
    static var emmaWilsonTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Dinner at Italian Place", message: "Hey! Can you send your share when you get a chance?", billTotal: 90.00, paidBy: "You", youOwe: 0, date: daysAgo(3)),
            .payment(id: UUID(), amount: 25.00, direction: .incoming, description: "Coffee reimbursement", date: daysAgo(5)),
            .message(id: UUID(), text: "Thanks for covering lunch yesterday!", isFromPerson: true, date: daysAgo(7)),
            .splitRequest(id: UUID(), title: "Concert tickets", message: nil, billTotal: 116.50, paidBy: "You", youOwe: 0, date: daysAgo(14))
        ]
    }

    /// Timeline items for James Chen - you owe $45.50
    static var jamesChenTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Basketball game tickets", message: "Got the tickets! Let me know when you can pay.", billTotal: 91.00, paidBy: "James Chen", youOwe: 45.50, date: daysAgo(2)),
            .message(id: UUID(), text: "No rush on the payment!", isFromPerson: true, date: daysAgo(2)),
            .paidBill(id: UUID(), personName: "James Chen", date: daysAgo(10))
        ]
    }

    /// Timeline items for Aisha Patel - settled up
    static var aishaPatelTimelineItems: [PersonTimelineItem] {
        [
            .settlement(id: UUID(), date: daysAgo(1)),
            .payment(id: UUID(), amount: 35.00, direction: .outgoing, description: "Movie tickets", date: daysAgo(3)),
            .message(id: UUID(), text: "All settled! Thanks for dinner last week.", isFromPerson: true, date: daysAgo(5))
        ]
    }

    /// Timeline items for David Kim - owes $120.00
    static var davidKimTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Vegas trip expenses", message: "Here's the breakdown from our trip!", billTotal: 360.00, paidBy: "You", youOwe: 0, date: daysAgo(5)),
            .reminder(id: UUID(), date: daysAgo(2)),
            .message(id: UUID(), text: "Will pay you back after payday!", isFromPerson: true, date: daysAgo(4))
        ]
    }

    /// Timeline items for Olivia Martinez - you owe $89.75
    static var oliviaMartinezTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Taylor Swift concert", message: "Had such an amazing time! Here's your share.", billTotal: 269.25, paidBy: "Olivia Martinez", youOwe: 89.75, date: daysAgo(7)),
            .payment(id: UUID(), amount: 50.00, direction: .outgoing, description: "Partial payment for concert", date: daysAgo(5)),
            .message(id: UUID(), text: "Thanks for organizing everything!", isFromPerson: false, date: daysAgo(6))
        ]
    }

    /// Timeline items for Lucas Brown - owes $32.50
    static var lucasBrownTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Sushi dinner", message: "Great catching up last night!", billTotal: 97.50, paidBy: "You", youOwe: 0, date: daysAgo(4)),
            .message(id: UUID(), text: "That was delicious! Same place next month?", isFromPerson: true, date: daysAgo(3))
        ]
    }

    /// Timeline items for Sophia Anderson - you owe $15.00
    static var sophiaAndersonTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Weekly coffee runs", message: "Coffee fund for this week", billTotal: 45.00, paidBy: "Sophia Anderson", youOwe: 15.00, date: daysAgo(1)),
            .payment(id: UUID(), amount: 15.00, direction: .outgoing, description: "Last week's coffee", date: daysAgo(8)),
            .message(id: UUID(), text: "Same order tomorrow?", isFromPerson: true, date: daysAgo(2))
        ]
    }

    // MARK: - Family Timeline Items

    /// Timeline items for Patricia (Mom)
    static var patriciaTimelineItems: [PersonTimelineItem] {
        [
            .message(id: UUID(), text: "Don't forget to call grandma this weekend!", isFromPerson: true, date: daysAgo(1)),
            .settlement(id: UUID(), date: daysAgo(30)),
            .message(id: UUID(), text: "Love you, see you at Thanksgiving!", isFromPerson: false, date: daysAgo(5))
        ]
    }

    /// Timeline items for Robert (Dad) - owes $500.00
    static var robertTimelineItems: [PersonTimelineItem] {
        [
            .payment(id: UUID(), amount: 500.00, direction: .incoming, description: "Holiday gift", date: daysAgo(10)),
            .message(id: UUID(), text: "Thanks Dad! You didn't have to!", isFromPerson: false, date: daysAgo(10)),
            .message(id: UUID(), text: "Merry Christmas! Use it for something fun.", isFromPerson: true, date: daysAgo(10))
        ]
    }

    /// Timeline items for Jennifer (Sister) - you owe $75.00
    static var jenniferTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Netflix family plan", message: "Your share for the year", billTotal: 225.00, paidBy: "Jennifer (Sister)", youOwe: 75.00, date: daysAgo(15)),
            .message(id: UUID(), text: "Added you to the account!", isFromPerson: true, date: daysAgo(15)),
            .message(id: UUID(), text: "Thanks sis! Will Venmo you.", isFromPerson: false, date: daysAgo(14))
        ]
    }

    /// Timeline items for Michael (Brother) - owes $150.00
    static var michaelTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Borrowed money", message: "Just until next paycheck", billTotal: 150.00, paidBy: "You", youOwe: 0, date: daysAgo(20)),
            .message(id: UUID(), text: "Thanks for helping out! Will pay you back soon.", isFromPerson: true, date: daysAgo(19)),
            .reminder(id: UUID(), date: daysAgo(5))
        ]
    }

    /// Timeline items for Rachel (Cousin) - you owe $25.00
    static var rachelTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Birthday dinner for Aunt Lisa", message: "Your share of the celebration", billTotal: 100.00, paidBy: "Rachel (Cousin)", youOwe: 25.00, date: daysAgo(8)),
            .message(id: UUID(), text: "Such a fun party! Great seeing everyone.", isFromPerson: false, date: daysAgo(7))
        ]
    }

    // MARK: - Coworkers Timeline Items

    /// Timeline items for Sarah Johnson - owes $23.45
    static var sarahJohnsonTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Lunch at the new Thai place", message: "Great find for our lunch spot rotation!", billTotal: 46.90, paidBy: "You", youOwe: 0, date: daysAgo(2)),
            .message(id: UUID(), text: "That pad thai was amazing!", isFromPerson: true, date: daysAgo(2)),
            .paidBill(id: UUID(), personName: "You", date: daysAgo(9))
        ]
    }

    /// Timeline items for Alex Thompson - you owe $67.80
    static var alexThompsonTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Team lunch - quarterly celebration", message: "Thanks everyone for a great Q4!", billTotal: 339.00, paidBy: "Alex Thompson", youOwe: 67.80, date: daysAgo(3)),
            .paidBill(id: UUID(), personName: "Alex Thompson", date: daysAgo(3)),
            .message(id: UUID(), text: "Great team effort this quarter!", isFromPerson: false, date: daysAgo(3))
        ]
    }

    /// Timeline items for Chris Williams - settled up
    static var chrisWilliamsTimelineItems: [PersonTimelineItem] {
        [
            .settlement(id: UUID(), date: daysAgo(7)),
            .payment(id: UUID(), amount: 25.00, direction: .incoming, description: "Coffee run reimbursement", date: daysAgo(7)),
            .message(id: UUID(), text: "All squared up! Thanks!", isFromPerson: true, date: daysAgo(7))
        ]
    }

    /// Timeline items for Morgan Lee - owes $42.00
    static var morganLeeTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Office coffee fund", message: "Monthly contribution for the good beans", billTotal: 84.00, paidBy: "You", youOwe: 0, date: daysAgo(5)),
            .message(id: UUID(), text: "Best investment we've made!", isFromPerson: true, date: daysAgo(4))
        ]
    }

    /// Timeline items for Taylor Davis - you owe $18.50
    static var taylorDavisTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Snack run", message: "Grabbed some afternoon snacks for the team", billTotal: 55.50, paidBy: "Taylor Davis", youOwe: 18.50, date: daysAgo(1)),
            .message(id: UUID(), text: "Thanks for thinking of us!", isFromPerson: false, date: daysAgo(1))
        ]
    }

    // MARK: - Others Timeline Items

    /// Timeline items for Dr. Amanda Foster - you owe $200.00
    static var drAmandaFosterTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Medical copay", message: "Copay for annual checkup", billTotal: 200.00, paidBy: "Dr. Amanda Foster", youOwe: 200.00, date: daysAgo(14)),
            .message(id: UUID(), text: "Please pay at your earliest convenience.", isFromPerson: true, date: daysAgo(7))
        ]
    }

    /// Timeline items for Jake (Personal Trainer) - you owe $150.00
    static var jakeTrainerTimelineItems: [PersonTimelineItem] {
        [
            .splitRequest(id: UUID(), title: "Personal training session", message: "Great workout today! Keep it up!", billTotal: 150.00, paidBy: "Jake (Personal Trainer)", youOwe: 150.00, date: daysAgo(3)),
            .message(id: UUID(), text: "Same time next week?", isFromPerson: true, date: daysAgo(2)),
            .message(id: UUID(), text: "Yes! I'll be there.", isFromPerson: false, date: daysAgo(2))
        ]
    }

    /// Timeline items for Mr. Chen (Landlord) - settled up
    static var mrChenLandlordTimelineItems: [PersonTimelineItem] {
        [
            .payment(id: UUID(), amount: 1800.00, direction: .outgoing, description: "December rent", date: daysAgo(1)),
            .settlement(id: UUID(), date: daysAgo(1)),
            .payment(id: UUID(), amount: 1800.00, direction: .outgoing, description: "November rent", date: daysAgo(31))
        ]
    }
}
