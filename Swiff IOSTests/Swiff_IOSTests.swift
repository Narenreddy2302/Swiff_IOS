//
//  Swiff_IOSTests.swift
//  Swiff IOSTests
//
//  Created by Naren Reddy on 11/11/25.
//  Updated on 11/18/25 to test SwiftData model conversions
//

import Testing
import SwiftData
@testable import Swiff_IOS

@Suite("SwiftData Model Round-Trip Conversion Tests")
struct ModelConversionTests {

    // MARK: - Test ModelContainer Setup

    /// Creates an in-memory ModelContainer for testing
    private func createTestContainer() -> ModelContainer {
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
            isStoredInMemoryOnly: true // In-memory only for tests
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }
    }

    // MARK: - PersonModel Tests

    @Test("PersonModel round-trip conversion preserves all data")
    func testPersonModelRoundTrip() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        // Create original domain model
        let originalPerson = Person(
            name: "John Doe",
            email: "john@example.com",
            phone: "+1234567890",
            avatarType: .emoji("👨")
        )

        // Set additional properties
        var person = originalPerson
        person.balance = 125.50
        person.createdDate = Date(timeIntervalSince1970: 1700000000)

        // Convert to SwiftData model
        let personModel = PersonModel(from: person)
        context.insert(personModel)

        // Convert back to domain model
        let convertedPerson = personModel.toDomain()

        // Verify all fields are preserved
        #expect(convertedPerson.id == person.id, "ID should be preserved")
        #expect(convertedPerson.name == person.name, "Name should be preserved")
        #expect(convertedPerson.email == person.email, "Email should be preserved")
        #expect(convertedPerson.phone == person.phone, "Phone should be preserved")
        #expect(convertedPerson.balance == person.balance, "Balance should be preserved")
        #expect(convertedPerson.createdDate == person.createdDate, "Created date should be preserved")

        // Verify avatar type
        if case .emoji(let emoji) = convertedPerson.avatarType {
            #expect(emoji == "👨", "Avatar emoji should be preserved")
        } else {
            Issue.record("Avatar type should be emoji")
        }
    }

    @Test("PersonModel with photo avatar preserves data")
    func testPersonModelPhotoAvatar() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        let photoData = Data([0x01, 0x02, 0x03, 0x04])
        let person = Person(
            name: "Jane Smith",
            email: "jane@example.com",
            phone: "+9876543210",
            avatarType: .photo(photoData)
        )

        let personModel = PersonModel(from: person)
        context.insert(personModel)

        let convertedPerson = personModel.toDomain()

        if case .photo(let data) = convertedPerson.avatarType {
            #expect(data == photoData, "Photo data should be preserved")
        } else {
            Issue.record("Avatar type should be photo")
        }
    }

    @Test("PersonModel with initials avatar preserves data")
    func testPersonModelInitialsAvatar() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        let person = Person(
            name: "Alice Johnson",
            email: "alice@example.com",
            phone: "+5555555555",
            avatarType: .initials("AJ", colorIndex: 3)
        )

        let personModel = PersonModel(from: person)
        context.insert(personModel)

        let convertedPerson = personModel.toDomain()

        if case .initials(let initials, let colorIndex) = convertedPerson.avatarType {
            #expect(initials == "AJ", "Initials should be preserved")
            #expect(colorIndex == 3, "Color index should be preserved")
        } else {
            Issue.record("Avatar type should be initials")
        }
    }

    // MARK: - SubscriptionModel Tests

    @Test("SubscriptionModel round-trip conversion preserves all data")
    func testSubscriptionModelRoundTrip() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        var subscription = Subscription(
            name: "Netflix",
            description: "Streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )

        // Set additional properties
        subscription.nextBillingDate = Date(timeIntervalSince1970: 1705000000)
        subscription.isActive = true
        subscription.isShared = true
        subscription.sharedWith = [UUID(), UUID()]
        subscription.notes = "Premium plan"
        subscription.website = "https://netflix.com"
        subscription.totalSpent = 191.88

        let subscriptionModel = SubscriptionModel(from: subscription)
        context.insert(subscriptionModel)

        let converted = subscriptionModel.toDomain()

        #expect(converted.id == subscription.id, "ID should be preserved")
        #expect(converted.name == subscription.name, "Name should be preserved")
        #expect(converted.description == subscription.description, "Description should be preserved")
        #expect(converted.price == subscription.price, "Price should be preserved")
        #expect(converted.billingCycle == subscription.billingCycle, "Billing cycle should be preserved")
        #expect(converted.category == subscription.category, "Category should be preserved")
        #expect(converted.icon == subscription.icon, "Icon should be preserved")
        #expect(converted.color == subscription.color, "Color should be preserved")
        #expect(converted.nextBillingDate == subscription.nextBillingDate, "Next billing date should be preserved")
        #expect(converted.isActive == subscription.isActive, "Active status should be preserved")
        #expect(converted.isShared == subscription.isShared, "Shared status should be preserved")
        #expect(converted.sharedWith == subscription.sharedWith, "Shared with list should be preserved")
        #expect(converted.notes == subscription.notes, "Notes should be preserved")
        #expect(converted.website == subscription.website, "Website should be preserved")
        #expect(converted.totalSpent == subscription.totalSpent, "Total spent should be preserved")
    }

    @Test("SubscriptionModel with all billing cycles")
    func testSubscriptionBillingCycles() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        let cycles: [BillingCycle] = [.weekly, .monthly, .quarterly, .semiAnnually, .annually, .lifetime]

        for cycle in cycles {
            let subscription = Subscription(
                name: "Test \(cycle.rawValue)",
                description: "Test",
                price: 9.99,
                billingCycle: cycle,
                category: .other,
                icon: "star.fill",
                color: "#FF0000"
            )

            let model = SubscriptionModel(from: subscription)
            context.insert(model)

            let converted = model.toDomain()
            #expect(converted.billingCycle == cycle, "\(cycle.rawValue) should be preserved")
        }
    }

    // MARK: - TransactionModel Tests

    @Test("TransactionModel round-trip conversion preserves all data")
    func testTransactionModelRoundTrip() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        let transaction = Transaction(
            id: UUID(),
            title: "Grocery Shopping",
            subtitle: "Whole Foods",
            amount: -125.50,
            category: .groceries,
            date: Date(timeIntervalSince1970: 1700500000),
            isRecurring: false,
            tags: ["food", "weekly"]
        )

        let transactionModel = TransactionModel(from: transaction)
        context.insert(transactionModel)

        let converted = transactionModel.toDomain()

        #expect(converted.id == transaction.id, "ID should be preserved")
        #expect(converted.title == transaction.title, "Title should be preserved")
        #expect(converted.subtitle == transaction.subtitle, "Subtitle should be preserved")
        #expect(converted.amount == transaction.amount, "Amount should be preserved")
        #expect(converted.category == transaction.category, "Category should be preserved")
        #expect(converted.date == transaction.date, "Date should be preserved")
        #expect(converted.isRecurring == transaction.isRecurring, "Recurring status should be preserved")
        #expect(converted.tags == transaction.tags, "Tags should be preserved")
    }

    @Test("TransactionModel with all transaction categories")
    func testTransactionCategories() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        let categories: [TransactionCategory] = [
            .groceries, .dining, .transport, .utilities,
            .entertainment, .shopping, .health, .education,
            .travel, .income, .other
        ]

        for category in categories {
            let transaction = Transaction(
                id: UUID(),
                title: "Test \(category.rawValue)",
                subtitle: "Test",
                amount: 50.0,
                category: category,
                date: Date(),
                isRecurring: false,
                tags: []
            )

            let model = TransactionModel(from: transaction)
            context.insert(model)

            let converted = model.toDomain()
            #expect(converted.category == category, "\(category.rawValue) should be preserved")
        }
    }

    // MARK: - GroupModel Tests

    @Test("GroupModel round-trip conversion preserves all data")
    func testGroupModelRoundTrip() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        // Create test people first
        let person1 = Person(name: "Alice", email: "alice@test.com", phone: "111", avatarType: .emoji("👩"))
        let person2 = Person(name: "Bob", email: "bob@test.com", phone: "222", avatarType: .emoji("👨"))

        let personModel1 = PersonModel(from: person1)
        let personModel2 = PersonModel(from: person2)
        context.insert(personModel1)
        context.insert(personModel2)

        // Create group
        var group = Group(
            name: "Weekend Trip",
            description: "Trip to the mountains",
            emoji: "🏔️",
            members: [person1.id, person2.id]
        )
        group.totalAmount = 500.0
        group.createdDate = Date(timeIntervalSince1970: 1700000000)

        // Create group expense
        let expense = GroupExpense(
            title: "Hotel",
            amount: 300.0,
            paidBy: person1.id,
            splitBetween: [person1.id, person2.id],
            category: .travel,
            notes: "2 nights",
            receipt: nil,
            isSettled: false
        )
        group.expenses = [expense]

        // Convert to SwiftData model
        let groupModel = GroupModel(from: group, context: context)
        context.insert(groupModel)

        // Convert back to domain model
        let converted = groupModel.toDomain()

        #expect(converted.id == group.id, "ID should be preserved")
        #expect(converted.name == group.name, "Name should be preserved")
        #expect(converted.description == group.description, "Description should be preserved")
        #expect(converted.emoji == group.emoji, "Emoji should be preserved")
        #expect(converted.totalAmount == group.totalAmount, "Total amount should be preserved")
        #expect(converted.createdDate == group.createdDate, "Created date should be preserved")
        #expect(converted.members.count == 2, "Should have 2 members")
        #expect(converted.members.contains(person1.id), "Should contain person1")
        #expect(converted.members.contains(person2.id), "Should contain person2")
        #expect(converted.expenses.count == 1, "Should have 1 expense")
        #expect(converted.expenses.first?.title == "Hotel", "Expense title should be preserved")
    }

    @Test("GroupExpenseModel round-trip conversion preserves all data")
    func testGroupExpenseModelRoundTrip() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        // Create test people
        let person1 = Person(name: "Charlie", email: "charlie@test.com", phone: "333", avatarType: .emoji("🧑"))
        let person2 = Person(name: "Dana", email: "dana@test.com", phone: "444", avatarType: .emoji("👤"))

        let personModel1 = PersonModel(from: person1)
        let personModel2 = PersonModel(from: person2)
        context.insert(personModel1)
        context.insert(personModel2)

        // Create expense
        var expense = GroupExpense(
            title: "Dinner",
            amount: 85.50,
            paidBy: person1.id,
            splitBetween: [person1.id, person2.id],
            category: .dining,
            notes: "Italian restaurant",
            receipt: "/path/to/receipt.jpg",
            isSettled: false
        )
        expense.date = Date(timeIntervalSince1970: 1700600000)

        // Convert to SwiftData model
        let expenseModel = GroupExpenseModel(from: expense, context: context)
        context.insert(expenseModel)

        // Convert back to domain model
        let converted = expenseModel.toDomain()

        #expect(converted.id == expense.id, "ID should be preserved")
        #expect(converted.title == expense.title, "Title should be preserved")
        #expect(converted.amount == expense.amount, "Amount should be preserved")
        #expect(converted.paidBy == expense.paidBy, "PaidBy should be preserved")
        #expect(converted.splitBetween == expense.splitBetween, "SplitBetween should be preserved")
        #expect(converted.category == expense.category, "Category should be preserved")
        #expect(converted.date == expense.date, "Date should be preserved")
        #expect(converted.notes == expense.notes, "Notes should be preserved")
        #expect(converted.receipt == expense.receipt, "Receipt path should be preserved")
        #expect(converted.isSettled == expense.isSettled, "Settled status should be preserved")
    }

    // MARK: - Batch Conversion Tests

    @Test("ModelConverter batch insertion works correctly")
    func testBatchInsertion() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        // Create multiple people
        let people = [
            Person(name: "Person 1", email: "p1@test.com", phone: "111", avatarType: .emoji("1️⃣")),
            Person(name: "Person 2", email: "p2@test.com", phone: "222", avatarType: .emoji("2️⃣")),
            Person(name: "Person 3", email: "p3@test.com", phone: "333", avatarType: .emoji("3️⃣"))
        ]

        // Insert using batch method
        ModelConverter.insertPeople(people, into: context)

        // Fetch all people
        let descriptor = FetchDescriptor<PersonModel>()
        let fetchedModels = try context.fetch(descriptor)

        #expect(fetchedModels.count == 3, "Should have 3 people inserted")

        // Convert back and verify
        let converted = fetchedModels.map { $0.toDomain() }
        #expect(converted.count == 3, "Should convert 3 people back")

        for (original, converted) in zip(people, converted.sorted(by: { $0.name < $1.name })) {
            #expect(converted.name == original.name, "Names should match")
            #expect(converted.email == original.email, "Emails should match")
        }
    }

    @Test("Database stats calculation works correctly")
    func testDatabaseStats() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        // Insert sample data
        let person = Person(name: "Test User", email: "test@test.com", phone: "555", avatarType: .emoji("👤"))
        ModelConverter.insertPeople([person], into: context)

        let subscription = Subscription(
            name: "Test Sub",
            description: "Test",
            price: 9.99,
            billingCycle: .monthly,
            category: .other,
            icon: "star.fill",
            color: "#FF0000"
        )
        ModelConverter.insertSubscriptions([subscription], into: context)

        let transaction = Transaction(
            id: UUID(),
            title: "Test Transaction",
            subtitle: "Test",
            amount: 50.0,
            category: .other,
            date: Date(),
            isRecurring: false,
            tags: []
        )
        let transactionModel = TransactionModel(from: transaction)
        context.insert(transactionModel)

        // Get stats
        let stats = try ModelConverter.getDatabaseStats(context: context)

        #expect(stats.peopleCount == 1, "Should have 1 person")
        #expect(stats.subscriptionsCount == 1, "Should have 1 subscription")
        #expect(stats.transactionsCount == 1, "Should have 1 transaction")
        #expect(stats.totalRecords == 3, "Should have 3 total records")
    }

    @Test("Clear all data works correctly")
    func testClearAllData() async throws {
        let container = createTestContainer()
        let context = ModelContext(container)

        // Insert sample data
        let person = Person(name: "Test", email: "test@test.com", phone: "555", avatarType: .emoji("👤"))
        ModelConverter.insertPeople([person], into: context)

        // Verify data exists
        var isEmpty = try ModelConverter.isDatabaseEmpty(context: context)
        #expect(!isEmpty, "Database should not be empty")

        // Clear all data
        try ModelConverter.clearAllData(context: context)

        // Verify database is empty
        isEmpty = try ModelConverter.isDatabaseEmpty(context: context)
        #expect(isEmpty, "Database should be empty after clearing")
    }
}
