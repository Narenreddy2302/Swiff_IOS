//
//  SupportingTypes.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import SwiftUI
import PhotosUI
import Combine
import UIKit

// MARK: - Avatar System

/// Avatar Type - Supports multiple avatar sources
enum AvatarType: Codable, Equatable {
    case photo(Data)           // Photo from library or camera
    case emoji(String)         // Emoji character
    case initials(String, colorIndex: Int)  // Generated from name

    // For backward compatibility with existing emoji avatars
    init(legacyEmoji: String) {
        self = .emoji(legacyEmoji)
    }
}

/// Avatar Sizes
enum AvatarSize {
    case small    // 24x24 - Used in shared subscriptions
    case medium   // 32x32 - Used in group member selection
    case large    // 48x48 - Used in person rows
    case xlarge   // 64x64 - Used in detail views
    case xxlarge  // 80x80 - Used in person detail header

    var dimension: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 48
        case .xlarge: return 64
        case .xxlarge: return 80
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 24
        case .xlarge: return 32
        case .xxlarge: return 40
        }
    }
}

/// Avatar Style
enum AvatarStyle {
    case gradient  // Gradient background (current PersonRowView style)
    case solid     // Flat color background
    case bordered  // White background with border
}

/// Avatar Color Palette - Using Wise brand colors
struct AvatarColorPalette {
    static let colors: [Color] = [
        Color(red: 0.624, green: 0.910, blue: 0.439),  // wiseBrightGreen
        Color(red: 0.000, green: 0.725, blue: 1.000),  // wiseBlue
        Color(red: 0.894, green: 0.506, blue: 0.251),  // Orange
        Color(red: 0.647, green: 0.400, blue: 0.835),  // Purple
        Color(red: 0.976, green: 0.459, blue: 0.529),  // Pink
        Color(red: 0.086, green: 0.200, blue: 0.000),  // wiseForestGreen
    ]

    static func color(for index: Int) -> Color {
        colors[index % colors.count]
    }

    static func colorIndex(for string: String) -> Int {
        abs(string.hashValue) % colors.count
    }
}

// MARK: - Avatar Generator Utilities

struct AvatarGenerator {
    /// Generate initials from a name
    static func generateInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }

    /// Process and compress image data for avatar
    static func processImage(_ image: UIImage, maxSize: CGFloat = 200) -> Data? {
        // Resize to circle and compress
        guard let resizedImage = image.resizeToCircle(size: maxSize) else { return nil}
        return resizedImage.jpegData(compressionQuality: 0.8)
    }

    /// Generate initials avatar image
    static func generateInitialsImage(initials: String, colorIndex: Int, size: CGFloat) -> UIImage? {
        let backgroundColor = AvatarColorPalette.color(for: colorIndex)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        return renderer.image { context in
            // Draw circle background
            UIColor(backgroundColor).setFill()
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            path.fill()

            // Draw initials text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.4, weight: .semibold),
                .foregroundColor: UIColor.white
            ]

            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            initials.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resizeToCircle(size: CGFloat) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        defer { UIGraphicsEndImageContext() }

        let path = UIBezierPath(ovalIn: rect)
        path.addClip()

        // Calculate the aspect ratio and draw
        let aspectWidth = rect.width / self.size.width
        let aspectHeight = rect.height / self.size.height
        let aspectRatio = max(aspectWidth, aspectHeight)

        let scaledWidth = self.size.width * aspectRatio
        let scaledHeight = self.size.height * aspectRatio
        let x = (rect.width - scaledWidth) / 2.0
        let y = (rect.height - scaledHeight) / 2.0

        self.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Subscription Types

enum BillingCycle: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnually = "Semi-annually"
    case yearly = "Yearly"
    case annually = "Annually"
    case lifetime = "Lifetime"

    var displayName: String {
        return self.rawValue
    }

    var displayShort: String {
        switch self {
        case .daily: return "day"
        case .weekly: return "wk"
        case .biweekly: return "2wk"
        case .monthly: return "mo"
        case .quarterly: return "qtr"
        case .semiAnnually: return "6mo"
        case .yearly: return "yr"
        case .annually: return "yr"
        case .lifetime: return "life"
        }
    }

    var shortName: String {
        switch self {
        case .daily: return "day"
        case .weekly: return "week"
        case .biweekly: return "2 weeks"
        case .monthly: return "month"
        case .quarterly: return "quarter"
        case .semiAnnually: return "6 months"
        case .yearly: return "year"
        case .annually: return "year"
        case .lifetime: return "lifetime"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.plus"
        case .semiAnnually: return "calendar.circle"
        case .yearly: return "calendar.circle.fill"
        case .annually: return "calendar.circle.fill"
        case .lifetime: return "infinity"
        }
    }

    func calculateNextBilling(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .semiAnnually:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .annually:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .lifetime:
            return Date.distantFuture
        }
    }
}

enum SubscriptionCategory: String, CaseIterable, Codable {
    case entertainment = "Entertainment"
    case productivity = "Productivity"
    case fitness = "Fitness & Health"
    case health = "Health"
    case education = "Education"
    case news = "News & Media"
    case music = "Music & Audio"
    case cloud = "Cloud Storage"
    case gaming = "Gaming"
    case design = "Design & Creative"
    case development = "Development"
    case finance = "Finance"
    case utilities = "Utilities"
    case other = "Other"

    var icon: String {
        switch self {
        case .entertainment: return "tv.fill"
        case .productivity: return "macbook"
        case .fitness: return "heart.fill"
        case .health: return "cross.fill"
        case .education: return "graduationcap.fill"
        case .news: return "newspaper.fill"
        case .music: return "music.note"
        case .cloud: return "icloud.fill"
        case .gaming: return "gamecontroller.fill"
        case .design: return "paintbrush.fill"
        case .development: return "hammer.fill"
        case .finance: return "dollarsign.circle.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .other: return "app.fill"
        }
    }

    var color: Color {
        switch self {
        case .entertainment: return Color(red: 0.608, green: 0.349, blue: 0.714) // Purple
        case .productivity: return Color(red: 0.0, green: 0.725, blue: 1.0) // Blue
        case .fitness: return Color(red: 1.0, green: 0.267, blue: 0.212) // Red
        case .health: return Color(red: 1.0, green: 0.412, blue: 0.380) // Light Red
        case .education: return Color(red: 1.0, green: 0.592, blue: 0.0) // Orange
        case .news: return Color(red: 0.235, green: 0.235, blue: 0.235) // Gray
        case .music: return Color(red: 0.891, green: 0.118, blue: 0.459) // Pink
        case .cloud: return Color(red: 0.624, green: 0.910, blue: 0.439) // Green
        case .gaming: return Color(red: 0.608, green: 0.349, blue: 0.714) // Purple
        case .design: return Color(red: 0.891, green: 0.118, blue: 0.459) // Pink
        case .development: return Color(red: 0.086, green: 0.200, blue: 0.0) // Dark Green
        case .finance: return Color(red: 0.624, green: 0.910, blue: 0.439) // Green
        case .utilities: return Color(red: 0.647, green: 0.165, blue: 0.165) // Brown
        case .other: return Color(red: 0.5, green: 0.5, blue: 0.5) // Medium Gray
        }
    }
}

enum PaymentMethod: String, CaseIterable, Codable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case paypal = "PayPal"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
    case bankTransfer = "Bank Transfer"
    case other = "Other"

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .paypal: return "p.circle.fill"
        case .applePay: return "apple.logo"
        case .googlePay: return "g.circle.fill"
        case .bankTransfer: return "building.columns.fill"
        case .other: return "dollarsign.circle.fill"
        }
    }
}

enum CostSplitType: String, CaseIterable, Codable {
    case equal = "Split Equally"
    case percentage = "By Percentage"
    case fixed = "Fixed Amount"
    case free = "Free Access"
}

// MARK: - Transaction Types

enum TransactionCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case dining = "Dining"
    case groceries = "Groceries"
    case transportation = "Transportation"
    case travel = "Travel"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case utilities = "Utilities"
    case healthcare = "Healthcare"
    case income = "Income"
    case transfer = "Transfer"
    case investment = "Investment"
    case other = "Other"

    var icon: String {
        switch self {
        case .food: return "fork.knife.circle.fill"
        case .dining: return "fork.knife"
        case .groceries: return "cart.fill"
        case .transportation: return "car.circle.fill"
        case .travel: return "airplane.circle.fill"
        case .shopping: return "bag.circle.fill"
        case .entertainment: return "tv.circle.fill"
        case .bills: return "house.circle.fill"
        case .utilities: return "bolt.circle.fill"
        case .healthcare: return "cross.circle.fill"
        case .income: return "dollarsign.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .investment: return "chart.line.uptrend.xyaxis.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return Color(red: 1.0, green: 0.592, blue: 0.0) // Orange
        case .dining: return Color(red: 1.0, green: 0.647, blue: 0.0) // Light Orange
        case .groceries: return Color(red: 0.180, green: 0.800, blue: 0.443) // Green
        case .transportation: return Color(red: 0.0, green: 0.725, blue: 1.0) // Blue
        case .travel: return Color(red: 0.0, green: 0.478, blue: 1.0) // Dark Blue
        case .shopping: return Color(red: 0.891, green: 0.118, blue: 0.459) // Pink
        case .entertainment: return Color(red: 0.608, green: 0.349, blue: 0.714) // Purple
        case .bills: return Color(red: 0.647, green: 0.165, blue: 0.165) // Brown
        case .utilities: return Color(red: 1.0, green: 0.800, blue: 0.0) // Yellow
        case .healthcare: return Color(red: 1.0, green: 0.267, blue: 0.212) // Red
        case .income: return Color(red: 0.624, green: 0.910, blue: 0.439) // Green
        case .transfer: return Color(red: 0.235, green: 0.235, blue: 0.235) // Gray
        case .investment: return Color(red: 0.086, green: 0.200, blue: 0.0) // Dark Green
        case .other: return Color(red: 0.5, green: 0.5, blue: 0.5) // Medium Gray
        }
    }

    var hexColor: String {
        switch self {
        case .food: return "#FF9700" // Orange
        case .dining: return "#FFA500" // Light Orange
        case .groceries: return "#2ECC71" // Green
        case .transportation: return "#00B9FF" // Blue
        case .travel: return "#007AFF" // Dark Blue
        case .shopping: return "#E31E75" // Pink
        case .entertainment: return "#9B59B6" // Purple
        case .bills: return "#A52A2A" // Brown
        case .utilities: return "#FFCC00" // Yellow
        case .healthcare: return "#FF4436" // Red
        case .income: return "#9FE870" // Green
        case .transfer: return "#3C3C3C" // Gray
        case .investment: return "#163300" // Dark Green
        case .other: return "#808080" // Medium Gray
        }
    }
}

// MARK: - Filter Options

enum SubscriptionFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case paused = "Paused"
    case cancelled = "Cancelled"
    case freeTrials = "Free Trials"
    case shared = "Shared"
    case expiringSoon = "Expiring Soon"

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .freeTrials: return "gift.fill"
        case .shared: return "person.2.fill"
        case .expiringSoon: return "clock.fill"
        }
    }
}

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case expenses = "Expenses"
    case income = "Income"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .today: return "calendar"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar.badge.plus"
        case .expenses: return "arrow.down.circle"
        case .income: return "arrow.up.circle"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Subscription Supporting Types (Agent 13)

/// Cancellation difficulty for a subscription
enum CancellationDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var icon: String {
        switch self {
        case .easy: return "checkmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .hard: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

/// Retention offer from a subscription service
struct RetentionOffer: Identifiable, Codable, Equatable {
    var id = UUID()
    var offerDescription: String
    var discountedPrice: Double
    var offerDate: Date
    var accepted: Bool

    init(
        id: UUID = UUID(),
        offerDescription: String,
        discountedPrice: Double,
        offerDate: Date = Date(),
        accepted: Bool = false
    ) {
        self.id = id
        self.offerDescription = offerDescription
        self.discountedPrice = discountedPrice
        self.offerDate = offerDate
        self.accepted = accepted
    }
}

/// Document type for subscription documents
enum DocumentType: String, CaseIterable, Codable {
    case contract = "Contract"
    case receipt = "Receipt"
    case confirmation = "Confirmation"
    case cancellation = "Cancellation"

    var icon: String {
        switch self {
        case .contract: return "doc.text.fill"
        case .receipt: return "doc.richtext.fill"
        case .confirmation: return "checkmark.seal.fill"
        case .cancellation: return "xmark.seal.fill"
        }
    }
}

/// Subscription document (receipt, contract, etc.)
struct SubscriptionDocument: Identifiable, Codable, Equatable {
    var id: UUID
    var type: DocumentType
    var name: String
    var data: Data  // PDF or image data
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        type: DocumentType,
        name: String,
        data: Data,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.data = data
        self.dateAdded = dateAdded
    }
}

// MARK: - Person Notification Types (Agent 13)

/// Contact method for notifications to a person
enum ContactMethod: String, CaseIterable, Codable {
    case inApp = "In-App"
    case email = "Email"
    case sms = "SMS"
    case whatsapp = "WhatsApp"

    var icon: String {
        switch self {
        case .inApp: return "app.badge"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .whatsapp: return "message.badge.filled.fill"
        }
    }
}

/// Notification preferences for a person
struct NotificationPreferences: Codable, Equatable {
    var enableReminders: Bool
    var reminderFrequency: Int  // days between reminders
    var preferredContactMethod: ContactMethod

    init(
        enableReminders: Bool = true,
        reminderFrequency: Int = 7,
        preferredContactMethod: ContactMethod = .inApp
    ) {
        self.enableReminders = enableReminders
        self.reminderFrequency = reminderFrequency
        self.preferredContactMethod = preferredContactMethod
    }
}

// MARK: - Wise Color System

extension Color {
    // App Background
    static let wiseBackground = Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF

    // Text Colors
    static let wisePrimaryText = Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A
    static let wiseSecondaryText = Color(red: 0.235, green: 0.235, blue: 0.235) // #3C3C3C
    static let wiseBodyText = Color(red: 0.125, green: 0.129, blue: 0.137) // #202123

    // Brand Colors
    static let wiseBrightGreen = Color(red: 0.624, green: 0.910, blue: 0.439) // #9FE870
    static let wiseForestGreen = Color(red: 0.086, green: 0.200, blue: 0.0) // #163300
    static let wiseCharcoal = Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A (alias for primary text)
    static let wiseOrange = Color(red: 1.0, green: 0.596, blue: 0.0) // #FF9800 (alias for accent orange)
    static let wisePurple = Color(red: 0.612, green: 0.337, blue: 0.835) // #9C56D5
    static let wiseMidGray = Color(red: 0.600, green: 0.600, blue: 0.600) // #999999

    // System Colors
    static let wiseError = Color(red: 1.0, green: 0.267, blue: 0.212) // #FF4436
    static let wiseBlue = Color(red: 0.0, green: 0.725, blue: 1.0) // #00B9FF
    static let wiseAccentBlue = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
    static let wiseAccentOrange = Color(red: 1.0, green: 0.596, blue: 0.0) // #FF9800

    // Borders/Dividers
    static let wiseBorder = Color(red: 0.941, green: 0.945, blue: 0.953) // #F0F1F3

    // Additional UI Colors
    static let wiseCardBackground = Color(red: 0.980, green: 0.984, blue: 0.992) // #FAFBFD
    static let wiseGray = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    static let wiseGreen = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759

    // MARK: - Hex Color Initializer
    
    /// Initialize Color from hex string
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
