//
//  DataSeeder.swift
//  Swiff IOS
//
//  Created by Agent on 1/7/26.
//  Utilities for generating comprehensive realistic test data for development and testing.
//

import Foundation
import SwiftUI

class DataSeeder {
    static let shared = DataSeeder()

    private init() {}

    // MARK: - Public Methods

    @MainActor
    func seedDataIfNeeded() {
        let manager = DataManager.shared

        if !manager.hasData {
            print("🌱 Seeding test data...")
            Task {
                await generateTestData()
            }
        } else {
            print("🌱 Data already exists, skipping seed.")
        }
    }

    @MainActor
    func forceSeedData() {
        print("🌱 Forcing seed of test data...")
        Task {
            await generateTestData()
        }
    }

    // MARK: - Main Generator

    @MainActor
    private func generateTestData() async {
        let manager = DataManager.shared

        // 1. Generate People (26 with relationship types and balances)
        let people = generatePeople()
        try? await manager.importPeople(people)
        let savedPeople = manager.people
        print("✅ Generated \(savedPeople.count) people")

        // 2. Generate Groups (7 with specific member assignments)
        let groups = generateGroups(with: savedPeople)
        try? await manager.importGroups(groups)
        let savedGroups = manager.groups
        print("✅ Generated \(savedGroups.count) groups")

        // 3. Generate Subscriptions (25 with shared subscription links)
        let subscriptions = generateSubscriptions(with: savedPeople)
        try? await manager.importSubscriptions(subscriptions)
        let savedSubscriptions = manager.subscriptions
        print("✅ Generated \(savedSubscriptions.count) subscriptions")

        // 4. Generate Group Expenses (20 per group = 140 total)
        await generateGroupExpenses(groups: savedGroups, people: savedPeople)
        print("✅ Generated group expenses")

        // 5. Generate Split Bills (15+)
        await generateSplitBills(people: savedPeople, groups: savedGroups)
        print("✅ Generated split bills")

        // 6. Update person balances
        await updatePersonBalances(people: savedPeople)
        print("✅ Updated person balances")

        print(
            "🎉 Seeding complete! Total: \(savedPeople.count) people, \(savedGroups.count) groups, \(savedSubscriptions.count) subscriptions"
        )
    }

    // MARK: - People Generator

    private func generatePeople() -> [Person] {
        let peopleData:
            [(name: String, email: String, phone: String, emoji: String, relationship: String)] = [
                // Friends who owe you (8)
                ("Alice Chen", "alice@example.com", "555-0101", "👩🏻", "Friend"),
                ("Charlie Davis", "charlie@example.com", "555-0103", "👨🏾", "Friend"),
                ("George Miller", "george@example.com", "555-0107", "👨🏽", "Friend"),
                ("Kevin Hart", "kevin@example.com", "555-0111", "👨🏾", "Friend"),
                ("Oscar Isaac", "oscar@example.com", "555-0115", "👨🏽", "Friend"),
                ("Rachel Green", "rachel@example.com", "555-0118", "👩🏻", "Friend"),
                ("Wanda Maximoff", "wanda@example.com", "555-0123", "👩🏻", "Friend"),
                ("Zach Galifianakis", "zach@example.com", "555-0126", "👨🏽", "Friend"),

                // Friends you owe (6)
                ("Bob Smith", "bob@example.com", "555-0102", "👨🏼", "Friend"),
                ("Diana Prince", "diana@example.com", "555-0104", "👩🏽", "Friend"),
                ("Hannah Lee", "hannah@example.com", "555-0108", "👩🏻", "Friend"),
                ("Laura Croft", "laura@example.com", "555-0112", "👩🏼", "Friend"),
                ("Natalie Portman", "natalie@example.com", "555-0114", "👩🏻", "Friend"),
                ("Victor Hugo", "victor@example.com", "555-0122", "👨🏼", "Friend"),

                // Settled friends (12)
                ("Evan Wright", "evan@example.com", "555-0105", "👨🏻", "Friend"),
                ("Fiona Gallagher", "fiona@example.com", "555-0106", "👩🏼", "Friend"),
                ("Ian Malcolm", "ian@example.com", "555-0109", "👨🏼", "Coworker"),
                ("Julia Roberts", "julia@example.com", "555-0110", "👩🏽", "Friend"),
                ("Mike Ross", "mike@example.com", "555-0113", "👨🏻", "Coworker"),
                ("Penny Lane", "penny@example.com", "555-0116", "👩🏼", "Friend"),
                ("Quentin Tarantino", "quentin@example.com", "555-0117", "👨🏼", "Friend"),
                ("Steve Jobs", "steve@example.com", "555-0119", "👨🏻", "Coworker"),
                ("Tina Fey", "tina@example.com", "555-0120", "👩🏽", "Friend"),
                ("Ursula K. Le Guin", "ursula@example.com", "555-0121", "👩🏼", "Family"),
                ("Xavier Charles", "xavier@example.com", "555-0124", "👨🏾", "Family"),
                ("Yvonne Strahovski", "yvonne@example.com", "555-0125", "👩🏼", "Friend"),
            ]

        return peopleData.map { data in
            Person(
                name: data.name,
                email: data.email,
                phone: data.phone,
                avatarType: .emoji(data.emoji),
                relationshipType: data.relationship
            )
        }
    }

    // MARK: - Groups Generator

    private func generateGroups(with people: [Person]) -> [Group] {
        guard people.count >= 8 else { return [] }

        // Specific member assignments for realistic groups
        let groupConfigs: [(name: String, desc: String, emoji: String, memberIndices: [Int])] = [
            ("Roommates", "House expenses and rent", "🏠", [0, 1, 2, 4]),  // Alice, Bob, Charlie, Evan
            ("Vegas Trip", "Weekend getaway expenses", "🎰", [0, 2, 6, 10, 11]),  // Alice, Charlie, George, Kevin, Laura
            ("Lunch Bunch", "Daily lunch splits", "🍔", [8, 12, 17, 19, 22]),  // Ian, Mike, Steve, Tina, Xavier
            ("Project Team", "Office snacks and supplies", "💼", [8, 12, 17]),  // Ian, Mike, Steve
            ("Family Plan", "Shared subscriptions", "👨‍👩‍👧‍👦", [20, 21, 23]),  // Ursula, Xavier, Yvonne
            ("Ski Trip", "Cabin and lift tickets", "⛷️", [0, 1, 5, 6, 7, 14]),  // Alice, Bob, Fiona, George, Hannah, Oscar
            ("Book Club", "Books and wine", "📚", [3, 9, 15, 16, 18]),  // Diana, Julia, Penny, Quentin, Rachel
        ]

        return groupConfigs.compactMap { config in
            let memberIds = config.memberIndices.compactMap { idx -> UUID? in
                guard idx < people.count else { return nil }
                return people[idx].id
            }
            guard !memberIds.isEmpty else { return nil }

            return Group(
                name: config.name,
                description: config.desc,
                emoji: config.emoji,
                members: memberIds
            )
        }
    }

    // MARK: - Subscriptions Generator

    private func generateSubscriptions(with people: [Person]) -> [Subscription] {
        let calendar = Calendar.current
        let now = Date()

        let subData:
            [(
                name: String, desc: String, price: Double, cat: SubscriptionCategory, icon: String,
                color: String, shared: Bool
            )] = [
                // Entertainment (shared)
                ("Netflix", "Premium streaming", 22.99, .entertainment, "📺", "#E50914", true),
                ("Spotify Family", "Family music plan", 16.99, .music, "🎵", "#1DB954", true),
                ("Disney+", "Disney streaming bundle", 13.99, .entertainment, "🐭", "#113CCF", true),
                ("HBO Max", "Premium streaming", 15.99, .entertainment, "🎬", "#5822b4", true),
                ("YouTube Premium", "Ad-free video", 13.99, .entertainment, "▶️", "#FF0000", true),

                // Entertainment (personal)
                ("Apple Music", "Individual plan", 10.99, .music, "🎵", "#FA243C", false),
                ("Hulu", "Basic streaming", 7.99, .entertainment, "📺", "#1CE783", false),
                ("PlayStation Plus", "Gaming subscription", 9.99, .gaming, "🎮", "#003791", false),
                ("Xbox Game Pass", "Gaming library", 14.99, .gaming, "🎮", "#107C10", false),
                ("Audible", "Audiobooks monthly", 14.95, .entertainment, "🎧", "#F8991C", false),

                // Software/Productivity
                ("iCloud+", "200GB storage", 2.99, .cloud, "☁️", "#007AFF", false),
                ("Adobe CC", "Creative Cloud all apps", 54.99, .design, "🎨", "#FF0000", false),
                ("Notion", "Team workspace", 8.00, .productivity, "📝", "#000000", false),
                ("Dropbox", "Professional storage", 11.99, .cloud, "📦", "#0061FF", false),
                ("ChatGPT Plus", "AI assistant", 20.00, .productivity, "🤖", "#10A37F", false),
                (
                    "Github Copilot", "AI pair programmer", 10.00, .development, "💻", "#000000",
                    false
                ),
                ("Slack Pro", "Team communication", 8.75, .productivity, "💬", "#4A154B", false),
                ("Zoom Pro", "Video conferencing", 15.99, .productivity, "📹", "#2D8CFF", false),

                // Education
                ("New York Times", "Digital subscription", 4.00, .news, "📰", "#000000", false),
                ("Duolingo Plus", "Language learning", 6.99, .education, "🦉", "#58CC02", false),
                ("Chegg Study", "Homework help", 14.95, .education, "🎓", "#F37021", false),
                ("MasterClass", "Expert lessons", 15.00, .education, "🎬", "#000000", false),

                // Health & Fitness
                ("Gym Membership", "24 Hour Fitness", 49.99, .fitness, "💪", "#FF5733", false),
                ("Headspace", "Meditation app", 12.99, .health, "🧘", "#F47D31", false),

                // Utilities
                ("Amazon Prime", "Shopping & streaming", 14.99, .utilities, "📦", "#00A8E1", true),
            ]

        var subscriptions: [Subscription] = []

        for (idx, data) in subData.enumerated() {
            var sub = Subscription(
                name: data.name,
                description: data.desc,
                price: data.price,
                billingCycle: idx % 5 == 0 ? .yearly : .monthly,
                category: data.cat,
                icon: data.icon,
                color: data.color
            )

            // Set billing dates
            let daysUntilNext = Int.random(in: 1...28)
            if let nextDate = calendar.date(byAdding: .day, value: daysUntilNext, to: now) {
                sub.nextBillingDate = nextDate
            }
            if let lastDate = calendar.date(byAdding: .month, value: -1, to: sub.nextBillingDate) {
                sub.lastBillingDate = lastDate
            }

            // Set shared subscriptions
            if data.shared && !people.isEmpty {
                let shareCount = Int.random(in: 2...4)
                let shuffledPeople = people.shuffled()
                sub.isShared = true
                sub.sharedWith = Array(shuffledPeople.prefix(shareCount)).map { $0.id }
            }

            // Add trial to some subscriptions
            if idx % 7 == 0 {
                sub.isFreeTrial = true
                sub.trialStartDate = calendar.date(byAdding: .day, value: -7, to: now)
                sub.trialEndDate = calendar.date(byAdding: .day, value: 7, to: now)
                sub.trialDuration = 14
            }

            subscriptions.append(sub)
        }

        return subscriptions
    }

    // MARK: - Group Expenses (20 per group)

    @MainActor
    private func generateGroupExpenses(groups: [Group], people: [Person]) async {
        let manager = DataManager.shared
        let calendar = Calendar.current
        let now = Date()

        // Group-specific expense templates
        let groupExpenseTemplates:
            [String: [(
                title: String, minAmt: Double, maxAmt: Double, category: TransactionCategory
            )]] = [
                "Roommates": [
                    ("Rent - January", 1200, 1800, .bills),
                    ("Rent - February", 1200, 1800, .bills),
                    ("Rent - March", 1200, 1800, .bills),
                    ("Electric bill", 80, 150, .utilities),
                    ("Water bill", 40, 80, .utilities),
                    ("Gas bill", 50, 100, .utilities),
                    ("Internet", 60, 90, .utilities),
                    ("Groceries", 100, 200, .groceries),
                    ("Costco run", 150, 300, .groceries),
                    ("Cleaning supplies", 30, 60, .shopping),
                    ("Paper towels & TP", 25, 50, .shopping),
                    ("Kitchen items", 40, 100, .shopping),
                    ("Netflix share", 20, 25, .entertainment),
                    ("Couch repair", 100, 200, .bills),
                    ("Plumber visit", 150, 300, .utilities),
                    ("AC filter", 30, 50, .bills),
                    ("Welcome mat", 25, 40, .shopping),
                    ("Shared dinner", 60, 100, .food),
                    ("BBQ supplies", 80, 150, .food),
                    ("House party snacks", 50, 100, .food),
                ],
                "Vegas Trip": [
                    ("Hotel deposit", 300, 500, .travel),
                    ("Hotel final payment", 400, 700, .travel),
                    ("Resort fee", 100, 200, .travel),
                    ("Uber from airport", 40, 60, .transportation),
                    ("Uber to airport", 40, 60, .transportation),
                    ("Club entry", 100, 200, .entertainment),
                    ("Show tickets", 150, 300, .entertainment),
                    ("Pool cabana", 200, 400, .entertainment),
                    ("Dinner at steakhouse", 200, 400, .dining),
                    ("Lunch buffet", 100, 180, .dining),
                    ("Late night pizza", 40, 70, .food),
                    ("Room service breakfast", 80, 150, .food),
                    ("Mini bar", 50, 100, .food),
                    ("Souvenirs", 50, 100, .shopping),
                    ("Rental car", 150, 250, .transportation),
                    ("Gas for rental", 40, 60, .transportation),
                    ("Casino chips (shared)", 100, 200, .entertainment),
                    ("Spa treatment", 150, 300, .healthcare),
                    ("Golf round", 200, 350, .entertainment),
                    ("Helicopter tour", 300, 500, .entertainment),
                ],
                "Lunch Bunch": [
                    ("Thai Palace", 60, 100, .dining),
                    ("Pho Vietnam", 50, 80, .dining),
                    ("Sushi Ko", 80, 150, .dining),
                    ("Chipotle run", 50, 80, .food),
                    ("Sweetgreen", 60, 90, .food),
                    ("Pizza Friday", 40, 70, .food),
                    ("Burger joint", 50, 80, .dining),
                    ("Indian buffet", 70, 100, .dining),
                    ("Dim sum", 80, 120, .dining),
                    ("Ramen shop", 50, 80, .dining),
                    ("Korean BBQ", 100, 150, .dining),
                    ("Taco Tuesday", 40, 60, .food),
                    ("Greek place", 50, 80, .dining),
                    ("Coffee run", 25, 40, .food),
                    ("Bubble tea", 30, 50, .food),
                    ("Bakery treats", 20, 40, .food),
                    ("Ice cream outing", 25, 45, .food),
                    ("Happy hour", 60, 100, .food),
                    ("Food truck festival", 40, 70, .food),
                    ("Birthday lunch", 100, 150, .dining),
                ],
                "Project Team": [
                    ("Team lunch", 80, 120, .dining),
                    ("Coffee supplies", 30, 50, .food),
                    ("Snack drawer", 40, 60, .food),
                    ("Team dinner", 150, 250, .dining),
                    ("Office supplies", 50, 100, .shopping),
                    ("Whiteboard markers", 20, 30, .shopping),
                    ("Celebration cake", 40, 60, .food),
                    ("Happy hour", 100, 150, .food),
                    ("Team building activity", 150, 300, .entertainment),
                    ("Conference snacks", 50, 80, .food),
                    ("Pizza for late night", 60, 100, .food),
                    ("Energy drinks", 30, 50, .food),
                    ("Team t-shirts", 100, 200, .shopping),
                    ("Celebration dinner", 200, 350, .dining),
                    ("Retirement gift", 100, 200, .shopping),
                ],
                "Family Plan": [
                    ("Netflix annual", 180, 180, .entertainment),
                    ("Spotify family", 200, 200, .entertainment),
                    ("Disney+ bundle", 160, 160, .entertainment),
                    ("Apple One family", 250, 250, .entertainment),
                    ("Amazon Prime", 140, 140, .shopping),
                    ("iCloud family", 36, 36, .utilities),
                    ("YouTube Premium family", 170, 170, .entertainment),
                    ("HBO Max", 180, 180, .entertainment),
                    ("Paramount+", 100, 100, .entertainment),
                    ("Hulu bundle", 180, 180, .entertainment),
                    ("Family dinner out", 150, 250, .dining),
                    ("Holiday gifts", 200, 400, .shopping),
                    ("Family photo session", 150, 300, .entertainment),
                    ("Thanksgiving groceries", 200, 350, .groceries),
                    ("Christmas decorations", 100, 200, .shopping),
                ],
                "Ski Trip": [
                    ("Cabin deposit", 400, 600, .travel),
                    ("Cabin balance", 500, 800, .travel),
                    ("Lift tickets Day 1", 400, 600, .entertainment),
                    ("Lift tickets Day 2", 400, 600, .entertainment),
                    ("Lift tickets Day 3", 400, 600, .entertainment),
                    ("Equipment rental", 200, 400, .entertainment),
                    ("Ski lessons", 300, 500, .entertainment),
                    ("Groceries for cabin", 200, 350, .groceries),
                    ("Dinner on mountain", 150, 250, .dining),
                    ("Apres ski drinks", 100, 180, .food),
                    ("Hot cocoa", 30, 50, .food),
                    ("Gas to resort", 80, 120, .transportation),
                    ("Toll roads", 20, 40, .transportation),
                    ("Parking", 30, 50, .transportation),
                    ("Hot tub rental", 100, 200, .entertainment),
                    ("Firewood", 40, 60, .shopping),
                    ("Breakfast supplies", 80, 120, .groceries),
                    ("Lunch on slopes", 100, 150, .food),
                    ("Souvenirs", 50, 100, .shopping),
                    ("First aid kit", 30, 50, .healthcare),
                ],
                "Book Club": [
                    ("January book", 60, 100, .shopping),
                    ("February book", 60, 100, .shopping),
                    ("March book", 60, 100, .shopping),
                    ("Wine for meeting", 40, 80, .food),
                    ("Cheese platter", 30, 60, .food),
                    ("Snacks", 25, 45, .food),
                    ("April book", 60, 100, .shopping),
                    ("Hosting supplies", 30, 50, .shopping),
                    ("May book", 60, 100, .shopping),
                    ("Author event tickets", 100, 200, .entertainment),
                    ("Bookstore gift cards", 100, 200, .shopping),
                    ("June book", 60, 100, .shopping),
                    ("Summer reading list", 150, 250, .shopping),
                    ("Library fundraiser", 50, 100, .other),
                    ("Book-themed party", 80, 150, .entertainment),
                ],
            ]

        for group in groups {
            let templates =
                groupExpenseTemplates[group.name] ?? groupExpenseTemplates["Lunch Bunch"]!

            for (index, template) in templates.prefix(20).enumerated() {
                guard let payerId = group.members.randomElement() else { continue }

                let amount = Double.random(in: template.minAmt...template.maxAmt)
                let daysAgo = Int.random(in: 0...90)
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!

                // Mix of settled and unsettled (70% settled)
                let isSettled = index < 14 || Bool.random()

                var expense = GroupExpense(
                    title: template.title,
                    amount: amount,
                    paidBy: payerId,
                    splitBetween: group.members,
                    category: template.category,
                    isSettled: isSettled
                )
                expense.date = date

                try? manager.addGroupExpense(expense, toGroup: group.id)
            }
        }
    }

    // MARK: - Split Bills (15+)

    @MainActor
    private func generateSplitBills(people: [Person], groups: [Group]) async {
        let manager = DataManager.shared
        let calendar = Calendar.current
        let now = Date()

        let splitBillData:
            [(
                title: String, amount: Double, category: TransactionCategory, participantCount: Int,
                groupName: String?, settlementStatus: String
            )] = [
                ("Thai dinner downtown", 120, .dining, 4, nil, "partial"),
                ("Sunday brunch", 180, .dining, 6, nil, "pending"),
                ("Vegas hotel room", 850, .travel, 5, "Vegas Trip", "partial"),
                ("Ski lift tickets", 400, .entertainment, 4, "Ski Trip", "settled"),
                ("Uber to concert", 45, .transportation, 3, nil, "pending"),
                ("Birthday dinner for Mike", 320, .dining, 8, nil, "partial"),
                ("Weekly grocery run", 95, .groceries, 3, "Roommates", "settled"),
                ("Netflix annual split", 180, .entertainment, 4, "Family Plan", "partial"),
                ("Road trip gas", 120, .transportation, 4, nil, "pending"),
                ("Escape room adventure", 180, .entertainment, 6, nil, "settled"),
                ("Wine tasting tour", 200, .food, 5, nil, "partial"),
                ("Airbnb ski cabin", 600, .travel, 6, "Ski Trip", "partial"),
                ("Game night snacks", 60, .food, 4, nil, "settled"),
                ("Costco bulk buy", 220, .groceries, 3, "Roommates", "pending"),
                ("Taylor Swift tickets", 480, .entertainment, 4, nil, "partial"),
                ("Happy hour Friday", 150, .food, 5, nil, "settled"),
                ("Beach day supplies", 90, .shopping, 4, nil, "partial"),
                ("Camping gear rental", 200, .entertainment, 5, nil, "partial"),
            ]

        for data in splitBillData {
            // Select random participants
            let shuffledPeople = people.shuffled()
            let participantPeople = Array(shuffledPeople.prefix(data.participantCount))
            guard let payer = participantPeople.first else { continue }

            // Create participants with payment status
            let amountPerPerson = data.amount / Double(data.participantCount)
            var participants: [SplitParticipant] = []

            for (index, person) in participantPeople.enumerated() {
                let hasPaid: Bool
                switch data.settlementStatus {
                case "settled":
                    hasPaid = true
                case "pending":
                    hasPaid = index == 0  // Only payer has "paid"
                case "partial":
                    hasPaid = index < data.participantCount / 2
                default:
                    hasPaid = false
                }

                let participant = SplitParticipant(
                    personId: person.id,
                    amount: amountPerPerson,
                    hasPaid: hasPaid,
                    percentage: 100.0 / Double(data.participantCount)
                )
                participants.append(participant)
            }

            // Find group ID if specified
            let groupId = data.groupName.flatMap { name in
                groups.first { $0.name == name }?.id
            }

            let daysAgo = Int.random(in: 0...60)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!

            let splitBill = SplitBill(
                title: data.title,
                totalAmount: data.amount,
                paidById: payer.id,
                createdById: UserProfileManager.shared.profile.id,
                splitType: .equally,
                participants: participants,
                notes: "Split \(data.participantCount) ways",
                category: data.category,
                date: date,
                groupId: groupId
            )

            try? manager.addSplitBill(splitBill)
        }
    }

    // MARK: - Update Person Balances

    @MainActor
    private func updatePersonBalances(people: [Person]) async {
        let manager = DataManager.shared

        // Balance distribution: 8 owe you, 6 you owe, 12 settled
        let balances: [Double] = [
            // 8 people who owe you (positive)
            78.25, 145.50, 92.00, 210.75, 55.00, 167.30, 88.45, 125.00,
            // 6 people you owe (negative)
            -45.50, -89.00, -32.75, -156.20, -67.00, -112.50,
            // 12 people who are settled (zero)
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]

        for (index, person) in people.enumerated() {
            guard index < balances.count else { continue }
            var updatedPerson = person
            updatedPerson.balance = balances[index]
            try? manager.updatePerson(updatedPerson)
        }
    }
}
