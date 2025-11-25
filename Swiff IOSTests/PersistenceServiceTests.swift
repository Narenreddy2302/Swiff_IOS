//
//  PersistenceServiceTests.swift
//  Swiff IOSTests
//
//  Created by Naren Reddy on 11/18/25.
//  Comprehensive tests for PersistenceService
//

import Testing
import SwiftData
@testable import Swiff_IOS

@Suite("PersistenceService Tests")
@MainActor
struct PersistenceServiceTests {

    // MARK: - Test Setup

    /// Creates an in-memory ModelContainer and PersistenceService for testing
    private func createTestService() -> PersistenceService {
        let schema = Schema([
            PersonModel.self,
            GroupModel.self,
            GroupExpenseModel.self,
            SubscriptionModel.self,
            SharedSubscriptionModel.self,
            TransactionModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return PersistenceService(modelContainer: container)
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }
    }

    // MARK: - Person CRUD Tests

    @Test("Save and fetch person")
    func testSaveAndFetchPerson() async throws {
        let service = createTestService()

        let person = Person(
            name: "John Doe",
            email: "john@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👨")
        )

        // Save person
        try service.savePerson(person)

        // Fetch all people
        let fetchedPeople = try service.fetchAllPeople()
        #expect(fetchedPeople.count == 1, "Should have 1 person")
        #expect(fetchedPeople.first?.name == "John Doe", "Name should match")
        #expect(fetchedPeople.first?.email == "john@example.com", "Email should match")
    }

    @Test("Fetch person by ID")
    func testFetchPersonByID() async throws {
        let service = createTestService()

        let person = Person(
            name: "Jane Smith",
            email: "jane@example.com",
            phone: "+9876543210",
            avatarType: .emoji("👩")
        )

        try service.savePerson(person)

        // Fetch by ID
        let fetchedPerson = try service.fetchPerson(byID: person.id)
        #expect(fetchedPerson != nil, "Should find person")
        #expect(fetchedPerson?.id == person.id, "ID should match")
        #expect(fetchedPerson?.name == "Jane Smith", "Name should match")
    }

    @Test("Update person")
    func testUpdatePerson() async throws {
        let service = createTestService()

        var person = Person(
            name: "Alice",
            email: "alice@example.com",
            phone: "111",
            avatarType: .emoji("👤")
        )

        try service.savePerson(person)

        // Update person
        person.name = "Alice Updated"
        person.balance = 100.50
        try service.updatePerson(person)

        // Fetch and verify
        let fetchedPerson = try service.fetchPerson(byID: person.id)
        #expect(fetchedPerson?.name == "Alice Updated", "Name should be updated")
        #expect(fetchedPerson?.balance == 100.50, "Balance should be updated")
    }

    @Test("Delete person")
    func testDeletePerson() async throws {
        let service = createTestService()

        let person = Person(
            name: "Bob",
            email: "bob@example.com",
            phone: "222",
            avatarType: .emoji("👨")
        )

        try service.savePerson(person)

        // Delete person
        try service.deletePerson(id: person.id)

        // Verify deletion
        let fetchedPerson = try service.fetchPerson(byID: person.id)
        #expect(fetchedPerson == nil, "Person should be deleted")
    }

    @Test("Search people by name")
    func testSearchPeopleByName() async throws {
        let service = createTestService()

        let person1 = Person(name: "Alice Johnson", email: "alice@test.com", phone: "111", avatarType: .emoji("👩"))
        let person2 = Person(name: "Bob Smith", email: "bob@test.com", phone: "222", avatarType: .emoji("👨"))
        let person3 = Person(name: "Alice Brown", email: "alice2@test.com", phone: "333", avatarType: .emoji("👤"))

        try service.savePerson(person1)
        try service.savePerson(person2)
        try service.savePerson(person3)

        // Search for "Alice"
        let results = try service.searchPeople(byName: "Alice")
        #expect(results.count == 2, "Should find 2 people named Alice")
    }

    @Test("Validation - Empty person name")
    func testValidationEmptyName() async throws {
        let service = createTestService()

        let person = Person(
            name: "",
            email: "test@example.com",
            phone: "123",
            avatarType: .emoji("👤")
        )

        // Should throw validation error
        do {
            try service.savePerson(person)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("name"), "Error should mention name")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    @Test("Validation - Invalid email format")
    func testValidationInvalidEmail() async throws {
        let service = createTestService()

        let person = Person(
            name: "Test User",
            email: "invalid-email",
            phone: "123",
            avatarType: .emoji("👤")
        )

        // Should throw validation error
        do {
            try service.savePerson(person)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("email"), "Error should mention email")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    // MARK: - Subscription CRUD Tests

    @Test("Save and fetch subscription")
    func testSaveAndFetchSubscription() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "Netflix",
            description: "Streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )

        try service.saveSubscription(subscription)

        let fetchedSubscriptions = try service.fetchAllSubscriptions()
        #expect(fetchedSubscriptions.count == 1, "Should have 1 subscription")
        #expect(fetchedSubscriptions.first?.name == "Netflix", "Name should match")
        #expect(fetchedSubscriptions.first?.price == 15.99, "Price should match")
    }

    @Test("Fetch active subscriptions")
    func testFetchActiveSubscriptions() async throws {
        let service = createTestService()

        var sub1 = Subscription(name: "Active Sub", description: "Test", price: 9.99, billingCycle: .monthly, category: .other, icon: "star", color: "#FF0000")
        sub1.isActive = true

        var sub2 = Subscription(name: "Inactive Sub", description: "Test", price: 19.99, billingCycle: .monthly, category: .other, icon: "star", color: "#FF0000")
        sub2.isActive = false

        try service.saveSubscription(sub1)
        try service.saveSubscription(sub2)

        let activeSubscriptions = try service.fetchActiveSubscriptions()
        #expect(activeSubscriptions.count == 1, "Should have 1 active subscription")
        #expect(activeSubscriptions.first?.name == "Active Sub", "Should be the active one")
    }

    @Test("Update subscription")
    func testUpdateSubscription() async throws {
        let service = createTestService()

        var subscription = Subscription(
            name: "Spotify",
            description: "Music streaming",
            price: 9.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "music.note",
            color: "#1DB954"
        )

        try service.saveSubscription(subscription)

        // Update subscription
        subscription.price = 12.99
        subscription.isActive = false
        try service.updateSubscription(subscription)

        // Fetch and verify
        let fetched = try service.fetchSubscription(byID: subscription.id)
        #expect(fetched?.price == 12.99, "Price should be updated")
        #expect(fetched?.isActive == false, "Should be inactive")
    }

    @Test("Delete subscription")
    func testDeleteSubscription() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "Test Sub",
            description: "Test",
            price: 5.99,
            billingCycle: .monthly,
            category: .other,
            icon: "star",
            color: "#FF0000"
        )

        try service.saveSubscription(subscription)
        try service.deleteSubscription(id: subscription.id)

        let fetched = try service.fetchSubscription(byID: subscription.id)
        #expect(fetched == nil, "Subscription should be deleted")
    }

    @Test("Validation - Empty subscription name")
    func testValidationEmptySubscriptionName() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "",
            description: "Test",
            price: 9.99,
            billingCycle: .monthly,
            category: .other,
            icon: "star",
            color: "#FF0000"
        )

        do {
            try service.saveSubscription(subscription)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("name"), "Error should mention name")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    @Test("Validation - Invalid subscription price")
    func testValidationInvalidSubscriptionPrice() async throws {
        let service = createTestService()

        let subscription = Subscription(
            name: "Test Sub",
            description: "Test",
            price: -5.99,
            billingCycle: .monthly,
            category: .other,
            icon: "star",
            color: "#FF0000"
        )

        do {
            try service.saveSubscription(subscription)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("price"), "Error should mention price")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    // MARK: - Transaction CRUD Tests

    @Test("Save and fetch transaction")
    func testSaveAndFetchTransaction() async throws {
        let service = createTestService()

        let transaction = Transaction(
            id: UUID(),
            title: "Grocery Shopping",
            subtitle: "Whole Foods",
            amount: -125.50,
            category: .groceries,
            date: Date(),
            isRecurring: false,
            tags: ["food", "weekly"]
        )

        try service.saveTransaction(transaction)

        let fetchedTransactions = try service.fetchAllTransactions()
        #expect(fetchedTransactions.count == 1, "Should have 1 transaction")
        #expect(fetchedTransactions.first?.title == "Grocery Shopping", "Title should match")
        #expect(fetchedTransactions.first?.amount == -125.50, "Amount should match")
    }

    @Test("Fetch transactions in date range")
    func testFetchTransactionsInDateRange() async throws {
        let service = createTestService()

        let date1 = Date(timeIntervalSince1970: 1700000000) // Nov 14, 2023
        let date2 = Date(timeIntervalSince1970: 1700500000) // Nov 20, 2023
        let date3 = Date(timeIntervalSince1970: 1701000000) // Nov 26, 2023

        let txn1 = Transaction(id: UUID(), title: "Txn 1", subtitle: "", amount: 50, category: .other, date: date1, isRecurring: false, tags: [])
        let txn2 = Transaction(id: UUID(), title: "Txn 2", subtitle: "", amount: 75, category: .other, date: date2, isRecurring: false, tags: [])
        let txn3 = Transaction(id: UUID(), title: "Txn 3", subtitle: "", amount: 100, category: .other, date: date3, isRecurring: false, tags: [])

        try service.saveTransaction(txn1)
        try service.saveTransaction(txn2)
        try service.saveTransaction(txn3)

        // Fetch transactions in range
        let startDate = Date(timeIntervalSince1970: 1700000000)
        let endDate = Date(timeIntervalSince1970: 1700600000)

        let results = try service.fetchTransactions(inDateRange: startDate...endDate)
        #expect(results.count == 2, "Should find 2 transactions in range")
    }

    @Test("Update transaction")
    func testUpdateTransaction() async throws {
        let service = createTestService()

        var transaction = Transaction(
            id: UUID(),
            title: "Coffee",
            subtitle: "Starbucks",
            amount: -5.50,
            category: .dining,
            date: Date(),
            isRecurring: false,
            tags: []
        )

        try service.saveTransaction(transaction)

        // Update transaction
        transaction.title = "Coffee Updated"
        transaction.amount = -6.50
        try service.updateTransaction(transaction)

        // Fetch and verify
        let fetched = try service.fetchTransaction(byID: transaction.id)
        #expect(fetched?.title == "Coffee Updated", "Title should be updated")
        #expect(fetched?.amount == -6.50, "Amount should be updated")
    }

    @Test("Delete transaction")
    func testDeleteTransaction() async throws {
        let service = createTestService()

        let transaction = Transaction(
            id: UUID(),
            title: "Test Transaction",
            subtitle: "",
            amount: 100,
            category: .other,
            date: Date(),
            isRecurring: false,
            tags: []
        )

        try service.saveTransaction(transaction)
        try service.deleteTransaction(id: transaction.id)

        let fetched = try service.fetchTransaction(byID: transaction.id)
        #expect(fetched == nil, "Transaction should be deleted")
    }

    @Test("Validation - Empty transaction title")
    func testValidationEmptyTransactionTitle() async throws {
        let service = createTestService()

        let transaction = Transaction(
            id: UUID(),
            title: "",
            subtitle: "Test",
            amount: 50,
            category: .other,
            date: Date(),
            isRecurring: false,
            tags: []
        )

        do {
            try service.saveTransaction(transaction)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("title"), "Error should mention title")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    // MARK: - Group CRUD Tests

    @Test("Save and fetch group")
    func testSaveAndFetchGroup() async throws {
        let service = createTestService()

        // Create test people first
        let person1 = Person(name: "Alice", email: "alice@test.com", phone: "111", avatarType: .emoji("👩"))
        let person2 = Person(name: "Bob", email: "bob@test.com", phone: "222", avatarType: .emoji("👨"))

        try service.savePerson(person1)
        try service.savePerson(person2)

        // Create group
        let group = Group(
            name: "Weekend Trip",
            description: "Trip to the mountains",
            emoji: "🏔️",
            members: [person1.id, person2.id]
        )

        try service.saveGroup(group)

        let fetchedGroups = try service.fetchAllGroups()
        #expect(fetchedGroups.count == 1, "Should have 1 group")
        #expect(fetchedGroups.first?.name == "Weekend Trip", "Name should match")
        #expect(fetchedGroups.first?.members.count == 2, "Should have 2 members")
    }

    @Test("Update group")
    func testUpdateGroup() async throws {
        let service = createTestService()

        let person = Person(name: "Charlie", email: "charlie@test.com", phone: "333", avatarType: .emoji("🧑"))
        try service.savePerson(person)

        var group = Group(
            name: "Dinner Group",
            description: "Weekly dinners",
            emoji: "🍽️",
            members: [person.id]
        )

        try service.saveGroup(group)

        // Update group
        group.name = "Updated Dinner Group"
        group.totalAmount = 500.0
        try service.updateGroup(group)

        // Fetch and verify
        let fetched = try service.fetchGroup(byID: group.id)
        #expect(fetched?.name == "Updated Dinner Group", "Name should be updated")
        #expect(fetched?.totalAmount == 500.0, "Total amount should be updated")
    }

    @Test("Delete group")
    func testDeleteGroup() async throws {
        let service = createTestService()

        let person = Person(name: "Dana", email: "dana@test.com", phone: "444", avatarType: .emoji("👤"))
        try service.savePerson(person)

        let group = Group(
            name: "Test Group",
            description: "Test",
            emoji: "📝",
            members: [person.id]
        )

        try service.saveGroup(group)
        try service.deleteGroup(id: group.id)

        let fetched = try service.fetchGroup(byID: group.id)
        #expect(fetched == nil, "Group should be deleted")
    }

    @Test("Validation - Empty group name")
    func testValidationEmptyGroupName() async throws {
        let service = createTestService()

        let person = Person(name: "Test", email: "test@test.com", phone: "555", avatarType: .emoji("👤"))
        try service.savePerson(person)

        let group = Group(
            name: "",
            description: "Test",
            emoji: "📝",
            members: [person.id]
        )

        do {
            try service.saveGroup(group)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("name"), "Error should mention name")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    @Test("Validation - Group with no members")
    func testValidationGroupNoMembers() async throws {
        let service = createTestService()

        let group = Group(
            name: "Empty Group",
            description: "Test",
            emoji: "📝",
            members: []
        )

        do {
            try service.saveGroup(group)
            Issue.record("Should have thrown validation error")
        } catch let error as PersistenceError {
            if case .validationFailed(let reason) = error {
                #expect(reason.contains("member"), "Error should mention member")
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    // MARK: - Statistics Tests

    @Test("Calculate total monthly cost")
    func testCalculateTotalMonthlyCost() async throws {
        let service = createTestService()

        var sub1 = Subscription(name: "Monthly Sub", description: "Test", price: 10.00, billingCycle: .monthly, category: .other, icon: "star", color: "#FF0000")
        sub1.isActive = true

        var sub2 = Subscription(name: "Yearly Sub", description: "Test", price: 120.00, billingCycle: .annually, category: .other, icon: "star", color: "#FF0000")
        sub2.isActive = true

        try service.saveSubscription(sub1)
        try service.saveSubscription(sub2)

        let totalMonthlyCost = try service.calculateTotalMonthlyCost()
        // Monthly: 10.00 + Yearly: 120/12 = 10 + 10 = 20.00
        #expect(totalMonthlyCost == 20.00, "Total monthly cost should be 20.00")
    }

    @Test("Calculate monthly income and expenses")
    func testCalculateMonthlyIncomeAndExpenses() async throws {
        let service = createTestService()

        let now = Date()

        let income = Transaction(id: UUID(), title: "Salary", subtitle: "", amount: 5000, category: .income, date: now, isRecurring: false, tags: [])
        let expense1 = Transaction(id: UUID(), title: "Rent", subtitle: "", amount: -1500, category: .utilities, date: now, isRecurring: false, tags: [])
        let expense2 = Transaction(id: UUID(), title: "Groceries", subtitle: "", amount: -300, category: .groceries, date: now, isRecurring: false, tags: [])

        try service.saveTransaction(income)
        try service.saveTransaction(expense1)
        try service.saveTransaction(expense2)

        let monthlyIncome = try service.calculateMonthlyIncome()
        let monthlyExpenses = try service.calculateMonthlyExpenses()

        #expect(monthlyIncome == 5000, "Monthly income should be 5000")
        #expect(monthlyExpenses == 1800, "Monthly expenses should be 1800")
    }

    // MARK: - Error Handling Tests

    @Test("Fetch non-existent person returns nil")
    func testFetchNonExistentPerson() async throws {
        let service = createTestService()

        let randomID = UUID()
        let person = try service.fetchPerson(byID: randomID)
        #expect(person == nil, "Should return nil for non-existent person")
    }

    @Test("Update non-existent person throws error")
    func testUpdateNonExistentPerson() async throws {
        let service = createTestService()

        let person = Person(
            name: "Test",
            email: "test@test.com",
            phone: "123",
            avatarType: .emoji("👤")
        )

        do {
            try service.updatePerson(person)
            Issue.record("Should have thrown entity not found error")
        } catch let error as PersistenceError {
            if case .entityNotFound = error {
                // Expected error
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    @Test("Delete non-existent person throws error")
    func testDeleteNonExistentPerson() async throws {
        let service = createTestService()

        let randomID = UUID()

        do {
            try service.deletePerson(id: randomID)
            Issue.record("Should have thrown entity not found error")
        } catch let error as PersistenceError {
            if case .entityNotFound = error {
                // Expected error
            } else {
                Issue.record("Wrong error type")
            }
        }
    }
}
