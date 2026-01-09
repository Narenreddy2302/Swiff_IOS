//
//  MockDataProvider.swift
//  Swiff IOS
//
//  Comprehensive mock data provider for DEBUG builds and SwiftUI previews
//  Provides realistic data across all app domains with proper relationships
//  Created for real-world test scenarios across all pages
//

import Foundation
import SwiftUI

/// Comprehensive mock data provider for DEBUG builds and SwiftUI previews
/// Provides realistic data across all app domains with proper relationships
@MainActor
public final class MockDataProvider {

    // MARK: - Singleton

    public static let shared = MockDataProvider()

    private init() {}

    // MARK: - Stable UUIDs for Cross-References

    /// Person UUIDs
    public enum PersonUUIDs {
        public static let emma = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        public static let james = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        public static let aisha = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        public static let david = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        public static let sofia = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        public static let michael = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        public static let alexandra = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        public static let liWei = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        public static let priya = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        public static let carlos = UUID(uuidString: "AAAAAAAA-1111-1111-1111-111111111111")!
    }

    /// Subscription UUIDs
    public enum SubscriptionUUIDs {
        public static let netflix = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        public static let microsoft365 = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
        public static let hboMax = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
        public static let spotify = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        public static let adobeCreative = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
        public static let iCloud = UUID(uuidString: "11111111-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        public static let enterprise = UUID(uuidString: "22222222-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        public static let gym = UUID(uuidString: "33333333-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
        public static let nyt = UUID(uuidString: "44444444-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
        public static let appleMusic = UUID(uuidString: "55555555-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        // Shared subscriptions
        public static let youtubeFamily = UUID(uuidString: "66666666-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
        public static let disneyBundle = UUID(uuidString: "77777777-1111-2222-3333-444444444444")!
        public static let appleOneFamily = UUID(uuidString: "88888888-2222-3333-4444-555555555555")!
        public static let huluLive = UUID(uuidString: "99999999-3333-4444-5555-666666666666")!
        public static let paramount = UUID(uuidString: "AAAAAAAA-4444-5555-6666-777777777777")!
    }

    /// Group UUIDs
    public enum GroupUUIDs {
        public static let beachVacation = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
        public static let dinnerClub = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        public static let projectTeam = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF01")!
        public static let officeParty = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF02")!
        public static let roommates = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFF03")!
    }

    /// Current user UUID (for split bills)
    public static let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    // MARK: - Date Helpers

    private static func date(daysAgo: Int, hoursAgo: Int = 0) -> Date {
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        date = calendar.date(byAdding: .hour, value: -hoursAgo, to: date) ?? date
        return date
    }

    private static func date(daysFromNow: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }

    // MARK: - People (10 entries)

    var allPeople: [Person] {
        [
            personEmma,
            personJames,
            personAisha,
            personDavid,
            personSofia,
            personMichael,
            personAlexandra,
            personLiWei,
            personPriya,
            personCarlos
        ]
    }

    /// Emma Wilson - Positive balance, emoji avatar
    var personEmma: Person {
        var person = Person(
            name: "Emma Wilson",
            email: "emma.wilson@email.com",
            phone: "+1 (555) 123-4567",
            avatarType: .emoji("👩‍💼"),
            relationshipType: "Friend"
        )
        person.id = PersonUUIDs.emma
        person.balance = 78.25
        person.personSource = .contact
        return person
    }

    /// James Chen - Negative balance, initials avatar
    var personJames: Person {
        var person = Person(
            name: "James Chen",
            email: "james.chen@email.com",
            phone: "+1 (555) 234-5678",
            avatarType: .initials("JC", colorIndex: 1),
            relationshipType: "Friend"
        )
        person.id = PersonUUIDs.james
        person.balance = -45.50
        person.personSource = .appUser
        return person
    }

    /// Aisha Patel - Zero balance (settled)
    var personAisha: Person {
        var person = Person(
            name: "Aisha Patel",
            email: "aisha.patel@email.com",
            phone: "+1 (555) 345-6789",
            avatarType: .initials("AP", colorIndex: 2),
            relationshipType: "Friend"
        )
        person.id = PersonUUIDs.aisha
        person.balance = 0.0
        return person
    }

    /// David Kim - Large positive balance
    var personDavid: Person {
        var person = Person(
            name: "David Kim",
            email: "david.kim@email.com",
            phone: "+1 (555) 456-7890",
            avatarType: .emoji("👨‍🎤"),
            relationshipType: "Friend",
            notes: "Met at the tech conference"
        )
        person.id = PersonUUIDs.david
        person.balance = 120.00
        return person
    }

    /// Sofia Rodriguez - Family member, negative balance
    var personSofia: Person {
        var person = Person(
            name: "Sofia Rodriguez",
            email: "sofia.rodriguez@email.com",
            phone: "+1 (555) 567-8901",
            avatarType: .emoji("👩"),
            relationshipType: "Family"
        )
        person.id = PersonUUIDs.sofia
        person.balance = -32.00
        return person
    }

    /// Michael Taylor - Coworker
    var personMichael: Person {
        var person = Person(
            name: "Michael Taylor",
            email: "michael.taylor@company.com",
            phone: "+1 (555) 678-9012",
            avatarType: .initials("MT", colorIndex: 4),
            relationshipType: "Coworker"
        )
        person.id = PersonUUIDs.michael
        person.balance = 15.75
        return person
    }

    /// Alexandra Montgomery III - Long name edge case
    var personAlexandra: Person {
        var person = Person(
            name: "Alexandra Christina Montgomery-Fitzgerald III",
            email: "alexandra.montgomery@verylongemail.example.com",
            phone: "+1 (555) 789-0123",
            avatarType: .initials("AM", colorIndex: 5),
            relationshipType: "Friend"
        )
        person.id = PersonUUIDs.alexandra
        person.balance = 250.99
        return person
    }

    /// Li Wei - Large negative balance
    var personLiWei: Person {
        var person = Person(
            name: "Li Wei",
            email: "li.wei@email.com",
            phone: "+1 (555) 890-1234",
            avatarType: .initials("LW", colorIndex: 0),
            relationshipType: "Friend"
        )
        person.id = PersonUUIDs.liWei
        person.balance = -500.00
        return person
    }

    /// Priya Sharma - Small positive balance
    var personPriya: Person {
        var person = Person(
            name: "Priya Sharma",
            email: "priya@email.com",
            phone: "+1 (555) 901-2345",
            avatarType: .emoji("👩‍🔬"),
            relationshipType: "Friend"
        )
        person.id = PersonUUIDs.priya
        person.balance = 5.00
        return person
    }

    /// Carlos Mendez - Zero balance, Other category
    var personCarlos: Person {
        var person = Person(
            name: "Carlos Mendez",
            email: "carlos.mendez@email.com",
            phone: "+1 (555) 012-3456",
            avatarType: .initials("CM", colorIndex: 3),
            relationshipType: "Other"
        )
        person.id = PersonUUIDs.carlos
        person.balance = 0.0
        return person
    }

    // MARK: - Transactions (50+ entries)

    var allTransactions: [Transaction] {
        (receiveTransactions + sendTransactions + paymentTransactions + transferTransactions + requestTransactions)
            .sorted { $0.date > $1.date }
    }

    /// 10 Receive/Income transactions
    var receiveTransactions: [Transaction] {
        [
            Transaction(
                title: "Salary Deposit",
                subtitle: "Monthly salary from TechCorp",
                amount: 5250.00,
                category: .income,
                date: Self.date(daysAgo: 0, hoursAgo: 2),
                isRecurring: true,
                tags: ["salary", "income"],
                merchant: "TechCorp Inc.",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Freelance Payment",
                subtitle: "Website design project",
                amount: 850.00,
                category: .income,
                date: Self.date(daysAgo: 1, hoursAgo: 4),
                isRecurring: false,
                tags: ["freelance"],
                merchant: "DesignClient LLC",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Refund from Amazon",
                subtitle: "Return of electronics",
                amount: 89.99,
                category: .income,
                date: Self.date(daysAgo: 3),
                isRecurring: false,
                tags: ["refund"],
                merchant: "Amazon",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Payment from Emma",
                subtitle: "Dinner split",
                amount: 35.00,
                category: .income,
                date: Self.date(daysAgo: 4),
                isRecurring: false,
                tags: ["personal"],
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Interest Earned",
                subtitle: "Savings account interest",
                amount: 12.45,
                category: .income,
                date: Self.date(daysAgo: 5),
                isRecurring: true,
                tags: ["interest", "savings"],
                merchant: "Chase Bank",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Birthday Gift",
                subtitle: "From parents",
                amount: 200.00,
                category: .income,
                date: Self.date(daysAgo: 7),
                isRecurring: false,
                tags: ["gift"],
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Cash Back Reward",
                subtitle: "Credit card rewards",
                amount: 45.67,
                category: .income,
                date: Self.date(daysAgo: 10),
                isRecurring: false,
                tags: ["rewards"],
                merchant: "Visa Rewards",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Reimbursement",
                subtitle: "Work expense reimbursement",
                amount: 156.78,
                category: .income,
                date: Self.date(daysAgo: 12),
                isRecurring: false,
                tags: ["work", "reimbursement"],
                merchant: "TechCorp Inc.",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Stock Dividend",
                subtitle: "AAPL quarterly dividend",
                amount: 89.50,
                category: .investment,
                date: Self.date(daysAgo: 15),
                isRecurring: true,
                tags: ["investment", "dividend"],
                merchant: "Fidelity",
                paymentStatus: .completed,
                transactionType: .receive
            ),
            Transaction(
                title: "Tax Refund",
                subtitle: "Federal tax refund 2024",
                amount: 1250.00,
                category: .income,
                date: Self.date(daysAgo: 20),
                isRecurring: false,
                tags: ["tax"],
                merchant: "IRS",
                paymentStatus: .completed,
                transactionType: .receive
            )
        ]
    }

    /// 10 Send transactions
    var sendTransactions: [Transaction] {
        [
            Transaction(
                title: "Payment to James",
                subtitle: "Concert tickets share",
                amount: -78.25,
                category: .entertainment,
                date: Self.date(daysAgo: 0, hoursAgo: 5),
                isRecurring: false,
                tags: ["personal"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Payment to Sofia",
                subtitle: "Grocery split",
                amount: -45.00,
                category: .groceries,
                date: Self.date(daysAgo: 2),
                isRecurring: false,
                tags: ["family"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Birthday Gift",
                subtitle: "Gift for David",
                amount: -75.00,
                category: .shopping,
                date: Self.date(daysAgo: 5),
                isRecurring: false,
                tags: ["gift"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Rent Share",
                subtitle: "Monthly rent to landlord",
                amount: -1200.00,
                category: .bills,
                date: Self.date(daysAgo: 1),
                isRecurring: true,
                tags: ["rent", "housing"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Payment to Li Wei",
                subtitle: "Trip expenses",
                amount: -250.00,
                category: .travel,
                date: Self.date(daysAgo: 8),
                isRecurring: false,
                tags: ["travel"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Charity Donation",
                subtitle: "Red Cross monthly",
                amount: -50.00,
                category: .other,
                date: Self.date(daysAgo: 10),
                isRecurring: true,
                tags: ["donation", "charity"],
                merchant: "American Red Cross",
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Payment to Priya",
                subtitle: "Book club dues",
                amount: -25.00,
                category: .entertainment,
                date: Self.date(daysAgo: 14),
                isRecurring: false,
                tags: ["personal"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Loan Payment",
                subtitle: "Student loan payment",
                amount: -450.00,
                category: .bills,
                date: Self.date(daysAgo: 15),
                isRecurring: true,
                tags: ["loan"],
                merchant: "Sallie Mae",
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Split Dinner",
                subtitle: "Restaurant with friends",
                amount: -65.00,
                category: .dining,
                date: Self.date(daysAgo: 2, hoursAgo: 8),
                isRecurring: false,
                tags: ["dining", "friends"],
                paymentStatus: .completed,
                transactionType: .send
            ),
            Transaction(
                title: "Wedding Gift",
                subtitle: "Michael's wedding",
                amount: -150.00,
                category: .shopping,
                date: Self.date(daysAgo: 21),
                isRecurring: false,
                tags: ["gift", "wedding"],
                paymentStatus: .completed,
                transactionType: .send
            )
        ]
    }

    /// 10 Payment transactions (merchant purchases)
    var paymentTransactions: [Transaction] {
        [
            Transaction(
                title: "Coffee Shop",
                subtitle: "Morning coffee",
                amount: -5.75,
                category: .food,
                date: Self.date(daysAgo: 0, hoursAgo: 8),
                isRecurring: false,
                tags: ["coffee"],
                merchant: "Starbucks",
                paymentStatus: .completed,
                paymentMethod: .applePay,
                location: "San Francisco, CA",
                transactionType: .payment
            ),
            Transaction(
                title: "Grocery Shopping",
                subtitle: "Weekly groceries",
                amount: -156.78,
                category: .groceries,
                date: Self.date(daysAgo: 1, hoursAgo: 3),
                isRecurring: false,
                tags: ["groceries", "weekly"],
                merchant: "Whole Foods",
                paymentStatus: .completed,
                paymentMethod: .creditCard,
                transactionType: .payment
            ),
            Transaction(
                title: "Netflix Subscription",
                subtitle: "Monthly streaming",
                amount: -19.99,
                category: .entertainment,
                date: Self.date(daysAgo: 2),
                isRecurring: true,
                tags: ["subscription", "streaming"],
                merchant: "Netflix",
                paymentStatus: .completed,
                linkedSubscriptionId: SubscriptionUUIDs.netflix,
                isRecurringCharge: true,
                transactionType: .payment
            ),
            Transaction(
                title: "Uber Ride",
                subtitle: "Airport transfer",
                amount: -42.50,
                category: .transportation,
                date: Self.date(daysAgo: 2, hoursAgo: 12),
                isRecurring: false,
                tags: ["transportation"],
                merchant: "Uber",
                paymentStatus: .completed,
                transactionType: .payment
            ),
            Transaction(
                title: "Gas Station",
                subtitle: "Fuel for car",
                amount: -65.00,
                category: .transportation,
                date: Self.date(daysAgo: 4),
                isRecurring: false,
                tags: ["gas", "car"],
                merchant: "Shell",
                paymentStatus: .completed,
                transactionType: .payment
            ),
            Transaction(
                title: "Electric Bill",
                subtitle: "Monthly utility",
                amount: -125.43,
                category: .utilities,
                date: Self.date(daysAgo: 5),
                isRecurring: true,
                tags: ["utilities", "electric"],
                merchant: "PG&E",
                paymentStatus: .completed,
                transactionType: .payment
            ),
            Transaction(
                title: "Doctor Visit",
                subtitle: "Annual checkup copay",
                amount: -30.00,
                category: .healthcare,
                date: Self.date(daysAgo: 7),
                isRecurring: false,
                tags: ["health", "medical"],
                merchant: "Kaiser Permanente",
                paymentStatus: .completed,
                transactionType: .payment
            ),
            Transaction(
                title: "Phone Bill",
                subtitle: "Monthly cellular",
                amount: -85.00,
                category: .bills,
                date: Self.date(daysAgo: 8),
                isRecurring: true,
                tags: ["phone", "utilities"],
                merchant: "Verizon",
                paymentStatus: .completed,
                transactionType: .payment
            ),
            Transaction(
                title: "Movie Tickets",
                subtitle: "Weekend movie",
                amount: -32.00,
                category: .entertainment,
                date: Self.date(daysAgo: 3),
                isRecurring: false,
                tags: ["entertainment", "movies"],
                merchant: "AMC Theaters",
                paymentStatus: .completed,
                transactionType: .payment
            ),
            Transaction(
                title: "Online Shopping",
                subtitle: "Electronics purchase",
                amount: -249.99,
                category: .shopping,
                date: Self.date(daysAgo: 6),
                isRecurring: false,
                tags: ["shopping", "electronics"],
                merchant: "Amazon",
                paymentStatus: .completed,
                transactionType: .payment
            )
        ]
    }

    /// 10 Transfer transactions
    var transferTransactions: [Transaction] {
        [
            Transaction(
                title: "Bank Transfer",
                subtitle: "To savings account",
                amount: -500.00,
                category: .transfer,
                date: Self.date(daysAgo: 1),
                isRecurring: false,
                tags: ["transfer", "savings"],
                merchant: "Chase Bank",
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Investment Transfer",
                subtitle: "Monthly investment",
                amount: -300.00,
                category: .transfer,
                date: Self.date(daysAgo: 5),
                isRecurring: true,
                tags: ["investment"],
                merchant: "Fidelity",
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Emergency Fund",
                subtitle: "Monthly contribution",
                amount: -200.00,
                category: .transfer,
                date: Self.date(daysAgo: 7),
                isRecurring: true,
                tags: ["savings", "emergency"],
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Credit Card Payment",
                subtitle: "Monthly payment",
                amount: -1500.00,
                category: .transfer,
                date: Self.date(daysAgo: 10),
                isRecurring: true,
                tags: ["credit card", "payment"],
                merchant: "Visa",
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "HSA Contribution",
                subtitle: "Health savings",
                amount: -150.00,
                category: .transfer,
                date: Self.date(daysAgo: 12),
                isRecurring: true,
                tags: ["hsa", "health"],
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "401k Transfer",
                subtitle: "Retirement contribution",
                amount: -400.00,
                category: .transfer,
                date: Self.date(daysAgo: 15),
                isRecurring: true,
                tags: ["retirement", "401k"],
                merchant: "Fidelity 401k",
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Joint Account",
                subtitle: "Household expenses",
                amount: -800.00,
                category: .transfer,
                date: Self.date(daysAgo: 1),
                isRecurring: true,
                tags: ["household"],
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Vacation Fund",
                subtitle: "Monthly savings",
                amount: -100.00,
                category: .transfer,
                date: Self.date(daysAgo: 18),
                isRecurring: true,
                tags: ["vacation", "savings"],
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Brokerage Transfer",
                subtitle: "Stock purchase funds",
                amount: -250.00,
                category: .transfer,
                date: Self.date(daysAgo: 20),
                isRecurring: false,
                tags: ["investment", "stocks"],
                merchant: "Robinhood",
                paymentStatus: .completed,
                transactionType: .transfer
            ),
            Transaction(
                title: "Tax Payment",
                subtitle: "Quarterly estimated taxes",
                amount: -2500.00,
                category: .transfer,
                date: Self.date(daysAgo: 25),
                isRecurring: true,
                tags: ["tax"],
                merchant: "IRS",
                paymentStatus: .completed,
                transactionType: .transfer
            )
        ]
    }

    /// 10 Request transactions (pending money requests)
    var requestTransactions: [Transaction] {
        [
            Transaction(
                title: "Money Request from James",
                subtitle: "Concert tickets",
                amount: -45.50,
                category: .other,
                date: Self.date(daysAgo: 0, hoursAgo: 3),
                isRecurring: false,
                tags: ["request"],
                paymentStatus: .pending,
                transactionType: .request
            ),
            Transaction(
                title: "Money Request from David",
                subtitle: "Dinner last week",
                amount: -32.00,
                category: .dining,
                date: Self.date(daysAgo: 1),
                isRecurring: false,
                tags: ["request"],
                paymentStatus: .pending,
                transactionType: .request
            ),
            Transaction(
                title: "Request from Sofia",
                subtitle: "Birthday gift contribution",
                amount: -25.00,
                category: .other,
                date: Self.date(daysAgo: 2),
                isRecurring: false,
                tags: ["request", "gift"],
                paymentStatus: .pending,
                transactionType: .request
            ),
            Transaction(
                title: "Overdue Request",
                subtitle: "Trip expenses from last month",
                amount: -150.00,
                category: .travel,
                date: Self.date(daysAgo: 35),
                isRecurring: false,
                tags: ["request", "overdue"],
                paymentStatus: .pending,
                notes: "Overdue payment request",
                transactionType: .request
            ),
            Transaction(
                title: "Request from Michael",
                subtitle: "Office lunch",
                amount: -18.50,
                category: .food,
                date: Self.date(daysAgo: 3),
                isRecurring: false,
                tags: ["request", "work"],
                paymentStatus: .pending,
                transactionType: .request
            ),
            Transaction(
                title: "Failed Payment Request",
                subtitle: "Card declined",
                amount: -75.00,
                category: .other,
                date: Self.date(daysAgo: 5),
                isRecurring: false,
                tags: ["failed"],
                paymentStatus: .failed,
                transactionType: .request
            ),
            Transaction(
                title: "Request from Priya",
                subtitle: "Book club membership",
                amount: -40.00,
                category: .entertainment,
                date: Self.date(daysAgo: 4),
                isRecurring: false,
                tags: ["request"],
                paymentStatus: .pending,
                transactionType: .request
            ),
            Transaction(
                title: "Cancelled Request",
                subtitle: "No longer needed",
                amount: -50.00,
                category: .other,
                date: Self.date(daysAgo: 10),
                isRecurring: false,
                tags: ["cancelled"],
                paymentStatus: .cancelled,
                transactionType: .request
            ),
            Transaction(
                title: "Small Request",
                subtitle: "Coffee last week",
                amount: -5.00,
                category: .food,
                date: Self.date(daysAgo: 6),
                isRecurring: false,
                tags: ["request"],
                paymentStatus: .pending,
                transactionType: .request
            ),
            Transaction(
                title: "Large Request from Li Wei",
                subtitle: "Shared vacation rental",
                amount: -500.00,
                category: .travel,
                date: Self.date(daysAgo: 7),
                isRecurring: false,
                tags: ["request", "vacation"],
                paymentStatus: .pending,
                transactionType: .request
            )
        ]
    }

    // MARK: - Subscriptions (15 total: 10 personal + 5 shared)

    var allSubscriptions: [Subscription] {
        personalSubscriptions + sharedSubscriptionBase
    }

    /// 10 Personal subscriptions
    var personalSubscriptions: [Subscription] {
        [
            subscriptionNetflix,
            subscriptionMicrosoft365,
            subscriptionHBOMax,
            subscriptionSpotify,
            subscriptionAdobeCreative,
            subscriptionICloud,
            subscriptionEnterprise,
            subscriptionGym,
            subscriptionNYT,
            subscriptionAppleMusic
        ]
    }

    /// Netflix - Active monthly
    var subscriptionNetflix: Subscription {
        var sub = Subscription(
            name: "Netflix",
            description: "Premium 4K streaming plan",
            price: 19.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "tv.fill",
            color: "#E50914"
        )
        sub.id = SubscriptionUUIDs.netflix
        sub.isActive = true
        sub.usageCount = 45
        sub.lastUsedDate = Date()
        sub.nextBillingDate = Self.date(daysFromNow: 15)
        return sub
    }

    /// Microsoft 365 - Yearly billing
    var subscriptionMicrosoft365: Subscription {
        var sub = Subscription(
            name: "Microsoft 365",
            description: "Office suite with cloud storage",
            price: 99.99,
            billingCycle: .annually,
            category: .productivity,
            icon: "doc.fill",
            color: "#0078D4"
        )
        sub.id = SubscriptionUUIDs.microsoft365
        sub.isActive = true
        sub.nextBillingDate = Self.date(daysFromNow: 120)
        return sub
    }

    /// HBO Max - Cancelled
    var subscriptionHBOMax: Subscription {
        var sub = Subscription(
            name: "HBO Max",
            description: "Cancelled streaming service",
            price: 15.99,
            billingCycle: .monthly,
            category: .entertainment,
            icon: "play.tv.fill",
            color: "#8F00FF"
        )
        sub.id = SubscriptionUUIDs.hboMax
        sub.isActive = false
        sub.cancellationDate = Self.date(daysAgo: 30)
        return sub
    }

    /// Spotify - Free trial ending in 3 days
    var subscriptionSpotify: Subscription {
        var sub = Subscription(
            name: "Spotify Premium",
            description: "Ad-free music streaming",
            price: 10.99,
            billingCycle: .monthly,
            category: .music,
            icon: "music.note",
            color: "#1DB954"
        )
        sub.id = SubscriptionUUIDs.spotify
        sub.isActive = true
        sub.isFreeTrial = true
        sub.trialStartDate = Self.date(daysAgo: 27)
        sub.trialEndDate = Self.date(daysFromNow: 3)
        sub.trialDuration = 30
        sub.willConvertToPaid = true
        sub.priceAfterTrial = 10.99
        return sub
    }

    /// Adobe Creative - Trial expired
    var subscriptionAdobeCreative: Subscription {
        var sub = Subscription(
            name: "Adobe Creative Cloud",
            description: "Design and creative tools",
            price: 54.99,
            billingCycle: .monthly,
            category: .design,
            icon: "paintbrush.fill",
            color: "#FF0000"
        )
        sub.id = SubscriptionUUIDs.adobeCreative
        sub.isActive = false
        sub.isFreeTrial = true
        sub.trialStartDate = Self.date(daysAgo: 45)
        sub.trialEndDate = Self.date(daysAgo: 15)
        sub.trialDuration = 30
        return sub
    }

    /// iCloud - Cheap subscription
    var subscriptionICloud: Subscription {
        var sub = Subscription(
            name: "iCloud+ 50GB",
            description: "Apple cloud storage",
            price: 0.99,
            billingCycle: .monthly,
            category: .cloud,
            icon: "icloud.fill",
            color: "#007AFF"
        )
        sub.id = SubscriptionUUIDs.iCloud
        sub.isActive = true
        sub.nextBillingDate = Self.date(daysFromNow: 22)
        return sub
    }

    /// Enterprise Suite - Expensive
    var subscriptionEnterprise: Subscription {
        var sub = Subscription(
            name: "Enterprise Suite",
            description: "Full business software suite",
            price: 9999.99,
            billingCycle: .annually,
            category: .development,
            icon: "building.2.fill",
            color: "#2C3E50"
        )
        sub.id = SubscriptionUUIDs.enterprise
        sub.isActive = true
        sub.nextBillingDate = Self.date(daysFromNow: 200)
        return sub
    }

    /// Gym Membership - Due today
    var subscriptionGym: Subscription {
        var sub = Subscription(
            name: "Gym Membership",
            description: "24 Hour Fitness",
            price: 49.99,
            billingCycle: .monthly,
            category: .fitness,
            icon: "figure.run",
            color: "#FF6B00"
        )
        sub.id = SubscriptionUUIDs.gym
        sub.isActive = true
        sub.nextBillingDate = Date()
        sub.lastUsedDate = Self.date(daysAgo: 2)
        sub.usageCount = 12
        return sub
    }

    /// NYT - Long name
    var subscriptionNYT: Subscription {
        var sub = Subscription(
            name: "The New York Times Premium All Access Digital + Print Edition",
            description: "News subscription with all features",
            price: 45.00,
            billingCycle: .monthly,
            category: .news,
            icon: "newspaper.fill",
            color: "#000000"
        )
        sub.id = SubscriptionUUIDs.nyt
        sub.isActive = true
        sub.nextBillingDate = Self.date(daysFromNow: 8)
        return sub
    }

    /// Apple Music - Paused
    var subscriptionAppleMusic: Subscription {
        var sub = Subscription(
            name: "Apple Music",
            description: "Music streaming (paused)",
            price: 10.99,
            billingCycle: .monthly,
            category: .music,
            icon: "music.note.list",
            color: "#FA243C"
        )
        sub.id = SubscriptionUUIDs.appleMusic
        sub.isActive = false
        return sub
    }

    /// Base subscriptions for shared (5 shared subscriptions)
    var sharedSubscriptionBase: [Subscription] {
        [
            {
                var sub = Subscription(
                    name: "YouTube Premium Family",
                    description: "Ad-free YouTube for family",
                    price: 22.99,
                    billingCycle: .monthly,
                    category: .entertainment,
                    icon: "play.rectangle.fill",
                    color: "#FF0000"
                )
                sub.id = SubscriptionUUIDs.youtubeFamily
                sub.isActive = true
                sub.isShared = true
                sub.sharedWith = [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha]
                sub.nextBillingDate = Self.date(daysFromNow: 10)
                return sub
            }(),
            {
                var sub = Subscription(
                    name: "Disney+ Bundle",
                    description: "Disney, Hulu, ESPN+",
                    price: 19.99,
                    billingCycle: .monthly,
                    category: .entertainment,
                    icon: "sparkles.tv.fill",
                    color: "#113CCF"
                )
                sub.id = SubscriptionUUIDs.disneyBundle
                sub.isActive = true
                sub.isShared = true
                sub.sharedWith = [PersonUUIDs.david, PersonUUIDs.sofia]
                sub.nextBillingDate = Self.date(daysFromNow: 5)
                return sub
            }(),
            {
                var sub = Subscription(
                    name: "Apple One Family",
                    description: "All Apple services bundle",
                    price: 32.95,
                    billingCycle: .monthly,
                    category: .entertainment,
                    icon: "apple.logo",
                    color: "#000000"
                )
                sub.id = SubscriptionUUIDs.appleOneFamily
                sub.isActive = true
                sub.isShared = true
                sub.sharedWith = [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.david]
                sub.nextBillingDate = Self.date(daysFromNow: 18)
                return sub
            }(),
            {
                var sub = Subscription(
                    name: "Hulu + Live TV",
                    description: "Live TV streaming",
                    price: 69.99,
                    billingCycle: .monthly,
                    category: .entertainment,
                    icon: "tv",
                    color: "#1CE783"
                )
                sub.id = SubscriptionUUIDs.huluLive
                sub.isActive = true
                sub.isShared = true
                sub.sharedWith = [PersonUUIDs.michael]
                sub.nextBillingDate = Self.date(daysFromNow: 12)
                return sub
            }(),
            {
                var sub = Subscription(
                    name: "Paramount+",
                    description: "Streaming service",
                    price: 11.99,
                    billingCycle: .monthly,
                    category: .entertainment,
                    icon: "mountain.2.fill",
                    color: "#0064FF"
                )
                sub.id = SubscriptionUUIDs.paramount
                sub.isActive = true
                sub.isShared = true
                sub.sharedWith = [PersonUUIDs.priya]
                sub.nextBillingDate = Self.date(daysFromNow: 25)
                return sub
            }()
        ]
    }

    // MARK: - Shared Subscriptions (5)

    var allSharedSubscriptions: [SharedSubscription] {
        [
            sharedYouTube,
            sharedDisney,
            sharedAppleOne,
            sharedHulu,
            sharedParamount
        ]
    }

    /// YouTube Premium Family - They owe you
    var sharedYouTube: SharedSubscription {
        var shared = SharedSubscription(
            subscriptionId: SubscriptionUUIDs.youtubeFamily,
            sharedBy: Self.currentUserId,
            sharedWith: [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha],
            costSplit: .equal
        )
        shared.individualCost = 5.75
        shared.isAccepted = true
        shared.balance = 17.25 // 3 people owe $5.75 each
        shared.balanceStatus = .owesYou
        shared.billingCycle = .monthly
        shared.nextBillingDate = Self.date(daysFromNow: 10)
        shared.members = [
            SharedMember(name: "Emma Wilson"),
            SharedMember(name: "James Chen"),
            SharedMember(name: "Aisha Patel")
        ]
        return shared
    }

    /// Disney+ Bundle - You owe
    var sharedDisney: SharedSubscription {
        var shared = SharedSubscription(
            subscriptionId: SubscriptionUUIDs.disneyBundle,
            sharedBy: PersonUUIDs.david,
            sharedWith: [Self.currentUserId, PersonUUIDs.sofia],
            costSplit: .equal
        )
        shared.individualCost = 6.66
        shared.isAccepted = true
        shared.balance = -6.66
        shared.balanceStatus = .youOwe
        shared.billingCycle = .monthly
        shared.nextBillingDate = Self.date(daysFromNow: 5)
        shared.members = [
            SharedMember(name: "David Kim"),
            SharedMember(name: "Sofia Rodriguez")
        ]
        return shared
    }

    /// Apple One Family - Settled
    var sharedAppleOne: SharedSubscription {
        var shared = SharedSubscription(
            subscriptionId: SubscriptionUUIDs.appleOneFamily,
            sharedBy: Self.currentUserId,
            sharedWith: [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.david],
            costSplit: .equal
        )
        shared.individualCost = 6.59
        shared.isAccepted = true
        shared.balance = 0.0
        shared.balanceStatus = .settled
        shared.billingCycle = .monthly
        shared.nextBillingDate = Self.date(daysFromNow: 18)
        shared.members = [
            SharedMember(name: "Emma Wilson"),
            SharedMember(name: "James Chen"),
            SharedMember(name: "Aisha Patel"),
            SharedMember(name: "David Kim")
        ]
        return shared
    }

    /// Hulu + Live TV - Large balance
    var sharedHulu: SharedSubscription {
        var shared = SharedSubscription(
            subscriptionId: SubscriptionUUIDs.huluLive,
            sharedBy: Self.currentUserId,
            sharedWith: [PersonUUIDs.michael],
            costSplit: .equal
        )
        shared.individualCost = 34.99
        shared.isAccepted = true
        shared.balance = 34.99
        shared.balanceStatus = .owesYou
        shared.billingCycle = .monthly
        shared.nextBillingDate = Self.date(daysFromNow: 12)
        shared.members = [
            SharedMember(name: "Michael Taylor")
        ]
        return shared
    }

    /// Paramount+ - Pending/unaccepted
    var sharedParamount: SharedSubscription {
        var shared = SharedSubscription(
            subscriptionId: SubscriptionUUIDs.paramount,
            sharedBy: Self.currentUserId,
            sharedWith: [PersonUUIDs.priya],
            costSplit: .equal
        )
        shared.individualCost = 5.99
        shared.isAccepted = false
        shared.balance = 5.99
        shared.balanceStatus = .owesYou
        shared.billingCycle = .monthly
        shared.nextBillingDate = Self.date(daysFromNow: 25)
        shared.members = [
            SharedMember(name: "Priya Sharma")
        ]
        return shared
    }

    // MARK: - Groups (5)

    var allGroups: [Group] {
        [
            groupBeachVacation,
            groupDinnerClub,
            groupProjectTeam,
            groupOfficeParty,
            groupRoommates
        ]
    }

    /// Beach Vacation - Unsettled expenses
    var groupBeachVacation: Group {
        var group = Group(
            name: "Beach Vacation 2024",
            description: "Summer trip to Miami",
            emoji: "🏖️",
            members: [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha]
        )
        group.id = GroupUUIDs.beachVacation
        group.totalAmount = 720.00
        group.expenses = [
            GroupExpense(
                title: "Airbnb Rental",
                amount: 450.00,
                paidBy: PersonUUIDs.emma,
                splitBetween: [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha],
                category: .travel,
                notes: "3 nights beach house"
            ),
            GroupExpense(
                title: "Groceries",
                amount: 120.00,
                paidBy: PersonUUIDs.james,
                splitBetween: [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha],
                category: .groceries
            ),
            GroupExpense(
                title: "Dinner at Seafood Place",
                amount: 150.00,
                paidBy: PersonUUIDs.aisha,
                splitBetween: [PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha],
                category: .dining
            )
        ]
        return group
    }

    /// Dinner Club - Fully settled
    var groupDinnerClub: Group {
        var group = Group(
            name: "Dinner Club",
            description: "Monthly dinner gatherings",
            emoji: "🍽️",
            members: [PersonUUIDs.david, PersonUUIDs.sofia, PersonUUIDs.michael]
        )
        group.id = GroupUUIDs.dinnerClub
        group.totalAmount = 85.00
        group.expenses = [
            GroupExpense(
                title: "Italian Restaurant",
                amount: 85.00,
                paidBy: PersonUUIDs.david,
                splitBetween: [PersonUUIDs.david, PersonUUIDs.sofia, PersonUUIDs.michael],
                category: .dining,
                isSettled: true
            )
        ]
        return group
    }

    /// Project Team - Empty (no expenses)
    var groupProjectTeam: Group {
        var group = Group(
            name: "New Project Team",
            description: "Q1 project expenses",
            emoji: "🆕",
            members: [PersonUUIDs.michael, PersonUUIDs.priya]
        )
        group.id = GroupUUIDs.projectTeam
        group.totalAmount = 0.0
        return group
    }

    /// Office Party Fund - Large group
    var groupOfficeParty: Group {
        var group = Group(
            name: "Office Party Fund",
            description: "Holiday party expenses",
            emoji: "🎉",
            members: [
                PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha,
                PersonUUIDs.david, PersonUUIDs.sofia, PersonUUIDs.michael,
                PersonUUIDs.priya
            ]
        )
        group.id = GroupUUIDs.officeParty
        group.totalAmount = 500.00
        group.expenses = [
            GroupExpense(
                title: "Party Supplies",
                amount: 500.00,
                paidBy: PersonUUIDs.emma,
                splitBetween: [
                    PersonUUIDs.emma, PersonUUIDs.james, PersonUUIDs.aisha,
                    PersonUUIDs.david, PersonUUIDs.sofia, PersonUUIDs.michael,
                    PersonUUIDs.priya
                ],
                category: .entertainment
            )
        ]
        return group
    }

    /// Roommates - Mixed settled/unsettled
    var groupRoommates: Group {
        var group = Group(
            name: "Roommates",
            description: "Shared apartment expenses",
            emoji: "🏠",
            members: [PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.liWei, PersonUUIDs.priya]
        )
        group.id = GroupUUIDs.roommates
        group.totalAmount = 1200.00
        group.expenses = [
            GroupExpense(
                title: "Internet Bill",
                amount: 80.00,
                paidBy: PersonUUIDs.james,
                splitBetween: [PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.liWei, PersonUUIDs.priya],
                category: .utilities,
                isSettled: true
            ),
            GroupExpense(
                title: "Cleaning Supplies",
                amount: 45.00,
                paidBy: PersonUUIDs.aisha,
                splitBetween: [PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.liWei, PersonUUIDs.priya],
                category: .shopping,
                isSettled: true
            ),
            GroupExpense(
                title: "Gas Bill",
                amount: 120.00,
                paidBy: PersonUUIDs.liWei,
                splitBetween: [PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.liWei, PersonUUIDs.priya],
                category: .utilities
            ),
            GroupExpense(
                title: "Electric Bill",
                amount: 155.00,
                paidBy: PersonUUIDs.priya,
                splitBetween: [PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.liWei, PersonUUIDs.priya],
                category: .utilities
            ),
            GroupExpense(
                title: "Common Area Furniture",
                amount: 800.00,
                paidBy: PersonUUIDs.james,
                splitBetween: [PersonUUIDs.james, PersonUUIDs.aisha, PersonUUIDs.liWei, PersonUUIDs.priya],
                category: .shopping
            )
        ]
        return group
    }

    // MARK: - Split Bills (10)

    var allSplitBills: [SplitBill] {
        [
            splitBillFullySettled,
            splitBillFullyPending,
            splitBillPartiallySettled,
            splitBillPercentage,
            splitBillShares,
            splitBillLarge,
            splitBillSmall,
            splitBillWithNotes,
            splitBillGroupLinked,
            splitBillOverdue
        ]
    }

    /// Fully settled split bill
    var splitBillFullySettled: SplitBill {
        SplitBill(
            title: "Team Lunch",
            totalAmount: 120.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.emma, amount: 40.00, hasPaid: true, paymentDate: Self.date(daysAgo: 5)),
                SplitParticipant(personId: PersonUUIDs.james, amount: 40.00, hasPaid: true, paymentDate: Self.date(daysAgo: 3)),
                SplitParticipant(personId: PersonUUIDs.aisha, amount: 40.00, hasPaid: true, paymentDate: Self.date(daysAgo: 2))
            ],
            category: .dining,
            date: Self.date(daysAgo: 7)
        )
    }

    /// Fully pending split bill
    var splitBillFullyPending: SplitBill {
        SplitBill(
            title: "Weekend Brunch",
            totalAmount: 95.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.david, amount: 31.67, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.sofia, amount: 31.67, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.michael, amount: 31.66, hasPaid: false)
            ],
            category: .dining,
            date: Self.date(daysAgo: 2)
        )
    }

    /// Partially settled (1 of 3 paid)
    var splitBillPartiallySettled: SplitBill {
        SplitBill(
            title: "Concert Tickets",
            totalAmount: 300.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.emma, amount: 100.00, hasPaid: true, paymentDate: Self.date(daysAgo: 1)),
                SplitParticipant(personId: PersonUUIDs.james, amount: 100.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.priya, amount: 100.00, hasPaid: false)
            ],
            category: .entertainment,
            date: Self.date(daysAgo: 5)
        )
    }

    /// Percentage-based split
    var splitBillPercentage: SplitBill {
        SplitBill(
            title: "Business Dinner",
            totalAmount: 250.00,
            paidById: Self.currentUserId,
            splitType: .percentages,
            participants: [
                SplitParticipant(personId: PersonUUIDs.michael, amount: 125.00, hasPaid: false, percentage: 50),
                SplitParticipant(personId: PersonUUIDs.david, amount: 75.00, hasPaid: true, paymentDate: Self.date(daysAgo: 2), percentage: 30),
                SplitParticipant(personId: PersonUUIDs.priya, amount: 50.00, hasPaid: false, percentage: 20)
            ],
            category: .dining,
            date: Self.date(daysAgo: 4)
        )
    }

    /// Shares-based split
    var splitBillShares: SplitBill {
        SplitBill(
            title: "Vacation Rental",
            totalAmount: 600.00,
            paidById: Self.currentUserId,
            splitType: .shares,
            participants: [
                SplitParticipant(personId: PersonUUIDs.emma, amount: 300.00, hasPaid: false, shares: 2), // 2 shares
                SplitParticipant(personId: PersonUUIDs.james, amount: 150.00, hasPaid: false, shares: 1), // 1 share
                SplitParticipant(personId: PersonUUIDs.aisha, amount: 150.00, hasPaid: true, paymentDate: Self.date(daysAgo: 3), shares: 1) // 1 share
            ],
            category: .travel,
            date: Self.date(daysAgo: 10)
        )
    }

    /// Large split ($2,000+)
    var splitBillLarge: SplitBill {
        SplitBill(
            title: "Group Trip Expenses",
            totalAmount: 2400.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.emma, amount: 600.00, hasPaid: true, paymentDate: Self.date(daysAgo: 5)),
                SplitParticipant(personId: PersonUUIDs.james, amount: 600.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.aisha, amount: 600.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.david, amount: 600.00, hasPaid: false)
            ],
            notes: "Annual group trip - flights, hotel, activities",
            category: .travel,
            date: Self.date(daysAgo: 14)
        )
    }

    /// Small split (<$20)
    var splitBillSmall: SplitBill {
        SplitBill(
            title: "Coffee Run",
            totalAmount: 18.50,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.michael, amount: 9.25, hasPaid: true, paymentDate: Self.date(daysAgo: 1)),
                SplitParticipant(personId: PersonUUIDs.priya, amount: 9.25, hasPaid: true, paymentDate: Self.date(daysAgo: 1))
            ],
            category: .food,
            date: Self.date(daysAgo: 1)
        )
    }

    /// Split with notes
    var splitBillWithNotes: SplitBill {
        SplitBill(
            title: "Birthday Dinner",
            totalAmount: 180.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.sofia, amount: 60.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.carlos, amount: 60.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.liWei, amount: 60.00, hasPaid: false)
            ],
            notes: "Emma's birthday celebration at Nobu. Includes appetizers, main courses, and dessert. Tips already included.",
            category: .dining,
            date: Self.date(daysAgo: 3)
        )
    }

    /// Split linked to group
    var splitBillGroupLinked: SplitBill {
        SplitBill(
            title: "Group Dinner",
            totalAmount: 240.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.emma, amount: 80.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.james, amount: 80.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.aisha, amount: 80.00, hasPaid: false)
            ],
            category: .dining,
            date: Self.date(daysAgo: 6),
            groupId: GroupUUIDs.beachVacation
        )
    }

    /// Overdue split (30+ days old, unpaid)
    var splitBillOverdue: SplitBill {
        SplitBill(
            title: "Old Dinner Split",
            totalAmount: 150.00,
            paidById: Self.currentUserId,
            splitType: .equally,
            participants: [
                SplitParticipant(personId: PersonUUIDs.liWei, amount: 75.00, hasPaid: false),
                SplitParticipant(personId: PersonUUIDs.alexandra, amount: 75.00, hasPaid: false)
            ],
            notes: "OVERDUE - Please settle soon!",
            category: .dining,
            date: Self.date(daysAgo: 45)
        )
    }

    // MARK: - Accounts (6)

    var allAccounts: [Account] {
        [
            accountChase,
            accountWellsFargo,
            accountAppleCard,
            accountAlly,
            accountPayPal,
            accountVenmo
        ]
    }

    var accountChase: Account {
        Account(name: "Chase Checking", number: "••4521", type: .bank, isDefault: true)
    }

    var accountWellsFargo: Account {
        Account(name: "Wells Fargo", number: "••7834", type: .bank)
    }

    var accountAppleCard: Account {
        Account(name: "Apple Card", number: "••9012", type: .creditCard)
    }

    var accountAlly: Account {
        Account(name: "Ally Savings", number: "••3456", type: .bank)
    }

    var accountPayPal: Account {
        Account(name: "PayPal", number: "", type: .wallet)
    }

    var accountVenmo: Account {
        Account(name: "Venmo", number: "", type: .wallet)
    }

    // MARK: - Summary Statistics (for Home tab)

    struct MockStatistics {
        let monthlyIncome: Double = 6100.00
        let monthlyExpenses: Double = 2847.53
        var netIncome: Double { monthlyIncome - monthlyExpenses }

        let activeSubscriptionCount: Int = 8
        let monthlySubscriptionCost: Double = 187.91
        let annualSubscriptionCost: Double = 2254.92

        let totalOwedToYou: Double = 469.99
        let totalYouOwe: Double = 577.50
        var netBalance: Double { totalOwedToYou - totalYouOwe }

        let recentTransactionCount: Int = 10
        let pendingRequestCount: Int = 3
        let unsettledSplitCount: Int = 4
    }

    var statistics: MockStatistics { MockStatistics() }

    // MARK: - Auto-Seed Methods

    /// Seeds mock data only if the database is empty (first launch or reset)
    public func seedIfEmpty() async {
        let dataManager = DataManager.shared

        // Check if data already exists
        guard dataManager.people.isEmpty &&
              dataManager.transactions.isEmpty &&
              dataManager.subscriptions.isEmpty else {
            print("📊 MockDataProvider: Data exists, skipping auto-seed")
            return
        }

        print("🌱 MockDataProvider: Seeding mock data for DEBUG mode...")

        do {
            // Seed in order to maintain relationships
            try seedPeople()
            try seedAccounts()
            try seedGroups()
            try seedSubscriptions()
            try seedSharedSubscriptions()
            try seedTransactions()
            try seedSplitBills()

            print("✅ MockDataProvider: Mock data seeded successfully")
        } catch {
            print("❌ MockDataProvider: Seeding failed - \(error)")
        }
    }

    /// Force re-seed (clears existing and adds fresh mock data)
    public func forceSeed() async {
        print("🔄 MockDataProvider: Force seeding mock data...")

        // Note: In a real implementation, you'd clear existing data first
        // For now, we just seed new data

        do {
            try seedPeople()
            try seedAccounts()
            try seedGroups()
            try seedSubscriptions()
            try seedSharedSubscriptions()
            try seedTransactions()
            try seedSplitBills()

            print("✅ MockDataProvider: Force seed completed")
        } catch {
            print("❌ MockDataProvider: Force seed failed - \(error)")
        }
    }

    private func seedPeople() throws {
        let dataManager = DataManager.shared
        for person in allPeople {
            try dataManager.addPerson(person)
        }
        print("  ✓ Seeded \(allPeople.count) people")
    }

    private func seedAccounts() throws {
        let dataManager = DataManager.shared
        for account in allAccounts {
            try dataManager.addAccount(account)
        }
        print("  ✓ Seeded \(allAccounts.count) accounts")
    }

    private func seedGroups() throws {
        let dataManager = DataManager.shared
        for group in allGroups {
            try dataManager.addGroup(group)
        }
        print("  ✓ Seeded \(allGroups.count) groups")
    }

    private func seedSubscriptions() throws {
        let dataManager = DataManager.shared
        for subscription in allSubscriptions {
            try dataManager.addSubscription(subscription)
        }
        print("  ✓ Seeded \(allSubscriptions.count) subscriptions")
    }

    private func seedSharedSubscriptions() throws {
        let dataManager = DataManager.shared
        for sharedSub in allSharedSubscriptions {
            try dataManager.addSharedSubscription(sharedSub)
        }
        print("  ✓ Seeded \(allSharedSubscriptions.count) shared subscriptions")
    }

    private func seedTransactions() throws {
        let dataManager = DataManager.shared
        for transaction in allTransactions {
            try dataManager.addTransaction(transaction)
        }
        print("  ✓ Seeded \(allTransactions.count) transactions")
    }

    private func seedSplitBills() throws {
        let dataManager = DataManager.shared
        for splitBill in allSplitBills {
            try dataManager.addSplitBill(splitBill)
        }
        print("  ✓ Seeded \(allSplitBills.count) split bills")
    }
}
