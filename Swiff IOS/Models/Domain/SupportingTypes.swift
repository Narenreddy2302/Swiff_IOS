//
//  SupportingTypes.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Extracted from ContentView.swift for better code organization
//

import Combine
import PhotosUI
import SwiftUI
import UIKit

// MARK: - Avatar System

/// Avatar Type - Supports multiple avatar sources
public enum AvatarType: Codable, Equatable {
    case photo(Data)  // Photo from library or camera
    case emoji(String)  // Emoji character
    case initials(String, colorIndex: Int)  // Generated from name

    // For backward compatibility with existing emoji avatars
    init(legacyEmoji: String) {
        self = .emoji(legacyEmoji)
    }

    /// Returns a display-friendly value for use in menus and lists
    var displayValue: String {
        switch self {
        case .emoji(let emoji):
            return emoji
        case .initials(let initials, _):
            return initials
        case .photo:
            return "📷"
        }
    }
}

/// Avatar Sizes
enum AvatarSize {
    case small  // 24x24 - Used in shared subscriptions
    case medium  // 32x32 - Used in group member selection
    case large  // 48x48 - Used in person rows
    case xlarge  // 64x64 - Used in detail views
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
    case solid  // Flat color background
    case bordered  // White background with border
}

/// Avatar Color Palette - Using new 5-tier green palette
public struct AvatarColorPalette {
    static let colors: [Color] = [
        Color(red: 120/255, green: 197/255, blue: 28/255),   // GREEN 3 - Bright lime
        Color(red: 0.000, green: 0.725, blue: 1.000),        // wiseBlue
        Color(red: 0.894, green: 0.506, blue: 0.251),        // Orange
        Color(red: 0.647, green: 0.400, blue: 0.835),        // Purple
        Color(red: 0.976, green: 0.459, blue: 0.529),        // Pink
        Color(red: 4/255, green: 63/255, blue: 46/255),      // GREEN 5 - Primary brand
    ]

    public static func color(for index: Int) -> Color {
        colors[index % colors.count]
    }

    public static func colorIndex(for string: String) -> Int {
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
        guard let resizedImage = image.resizeToCircle(size: maxSize) else { return nil }
        return resizedImage.jpegData(compressionQuality: 0.8)
    }

    /// Generate initials avatar image
    static func generateInitialsImage(initials: String, colorIndex: Int, size: CGFloat) -> UIImage?
    {
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
                .foregroundColor: UIColor.white,
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
        case .productivity: return "hammer.fill"
        case .fitness: return "heart.fill"
        case .health: return "cross.fill"
        case .education: return "book.fill"
        case .news: return "newspaper.fill"
        case .music: return "music.note"
        case .cloud: return "cloud.fill"
        case .gaming: return "gamecontroller.fill"
        case .design: return "paintbrush.fill"
        case .development: return "chevron.left.forwardslash.chevron.right"
        case .finance: return "banknote.fill"
        case .utilities: return "wrench.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .entertainment: return Color(red: 0.608, green: 0.349, blue: 0.714)  // Purple
        case .productivity: return Color(red: 0.0, green: 0.725, blue: 1.0)  // Blue
        case .fitness: return Color(red: 1.0, green: 0.267, blue: 0.212)  // Red
        case .health: return Color(red: 1.0, green: 0.412, blue: 0.380)  // Light Red
        case .education: return Color(red: 1.0, green: 0.592, blue: 0.0)  // Orange
        case .news: return Color(red: 0.235, green: 0.235, blue: 0.235)  // Gray
        case .music: return Color(red: 0.891, green: 0.118, blue: 0.459)  // Pink
        case .cloud: return Theme.Colors.green3  // GREEN 3 #78C51C
        case .gaming: return Color(red: 0.608, green: 0.349, blue: 0.714)  // Purple
        case .design: return Color(red: 0.891, green: 0.118, blue: 0.459)  // Pink
        case .development: return Theme.Colors.green5  // GREEN 5 #043F2E
        case .finance: return Theme.Colors.green3  // GREEN 3 #78C51C
        case .utilities: return Color(red: 0.647, green: 0.165, blue: 0.165)  // Brown
        case .other: return Color(red: 0.5, green: 0.5, blue: 0.5)  // Medium Gray
        }
    }
}

public enum PaymentMethod: String, CaseIterable, Codable {
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
        case .food: return "fork.knife"
        case .dining: return "fork.knife"
        case .groceries: return "cart.fill"
        case .transportation: return "car.fill"
        case .travel: return "airplane"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .bills: return "house.fill"
        case .utilities: return "bolt.fill"
        case .healthcare: return "cross.fill"
        case .income: return "dollarsign.circle.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return Color(red: 1.0, green: 0.592, blue: 0.0)  // Orange
        case .dining: return Color(red: 1.0, green: 0.647, blue: 0.0)  // Light Orange
        case .groceries: return Color(red: 0.180, green: 0.800, blue: 0.443)  // Green
        case .transportation: return Color(red: 0.0, green: 0.725, blue: 1.0)  // Blue
        case .travel: return Color(red: 0.0, green: 0.478, blue: 1.0)  // Dark Blue
        case .shopping: return Color(red: 0.891, green: 0.118, blue: 0.459)  // Pink
        case .entertainment: return Color(red: 0.608, green: 0.349, blue: 0.714)  // Purple
        case .bills: return Color(red: 0.647, green: 0.165, blue: 0.165)  // Brown
        case .utilities: return Color(red: 1.0, green: 0.800, blue: 0.0)  // Yellow
        case .healthcare: return Color(red: 1.0, green: 0.267, blue: 0.212)  // Red
        case .income: return Theme.Colors.green3  // GREEN 3 #78C51C
        case .transfer: return Color(red: 0.235, green: 0.235, blue: 0.235)  // Gray
        case .investment: return Theme.Colors.green5  // GREEN 5 #043F2E
        case .other: return Color(red: 0.5, green: 0.5, blue: 0.5)  // Medium Gray
        }
    }

    var hexColor: String {
        switch self {
        case .food: return "#FF9700"  // Orange
        case .dining: return "#FFA500"  // Light Orange
        case .groceries: return "#2ECC71"  // Green
        case .transportation: return "#00B9FF"  // Blue
        case .travel: return "#007AFF"  // Dark Blue
        case .shopping: return "#E31E75"  // Pink
        case .entertainment: return "#9B59B6"  // Purple
        case .bills: return "#A52A2A"  // Brown
        case .utilities: return "#FFCC00"  // Yellow
        case .healthcare: return "#FF4436"  // Red
        case .income: return "#78C51C"  // GREEN 3
        case .transfer: return "#3C3C3C"  // Gray
        case .investment: return "#043F2E"  // GREEN 5
        case .other: return "#808080"  // Medium Gray
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
    case income = "Income"
    case sent = "Sent"
    case request = "Request"
    case transfer = "Transfer"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case expenses = "Expenses"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .income: return "arrow.down.left"
        case .sent: return "arrow.up.right"
        case .request: return "person.badge.clock"
        case .transfer: return "arrow.left.arrow.right"
        case .today: return "calendar"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar.badge.plus"
        case .expenses: return "arrow.up.left"
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
public enum ContactMethod: String, CaseIterable, Codable, Sendable {
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
public struct NotificationPreferences: Codable, Equatable, Sendable {
    public var enableReminders: Bool
    public var reminderFrequency: Int  // days between reminders
    public var preferredContactMethod: ContactMethod

    public init(
        enableReminders: Bool = true,
        reminderFrequency: Int = 7,
        preferredContactMethod: ContactMethod = .inApp
    ) {
        self.enableReminders = enableReminders
        self.reminderFrequency = reminderFrequency
        self.preferredContactMethod = preferredContactMethod
    }
}

// MARK: - Wise Color System (Dark Mode Enhanced)

extension Color {
    // MARK: - Background Colors (Adaptive)

    // App Background - adapts to color scheme
    public static let wiseBackground = Theme.Colors.background

    // Card Background - adapts to color scheme
    public static let wiseCardBackground = Theme.Colors.cardBackground

    // Tertiary Background - for nested cards
    public static let wiseTertiaryBackground = Theme.Colors.secondaryBackground

    // Elevated Background - for modals/sheets
    public static let wiseElevatedBackground = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.173, green: 0.173, blue: 0.18, alpha: 1.0)
                :  // #2C2C2E for dark
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)  // #FFFFFF for light
        })

    // Grouped Background - for list backgrounds
    public static let wiseGroupedBackground = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                :  // #000000 for dark
                UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1.0)  // #F2F2F7 for light
        })

    // MARK: - Text Colors (Adaptive)
    // NOTE: These are defined directly to avoid circular references with Theme.Colors

    public static let wisePrimaryText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0)
        })

    public static let wiseSecondaryText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.92, green: 0.92, blue: 0.96, alpha: 1.0)
                : UIColor(red: 0.235, green: 0.235, blue: 0.235, alpha: 1.0)
        })

    public static let wiseBodyText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
                :  // #E6E6E6 for dark
                UIColor(red: 0.125, green: 0.129, blue: 0.137, alpha: 1.0)  // #202123 for light
        })

    // Tertiary Text - for hints/disabled text
    public static let wiseTertiaryText = Theme.Colors.textTertiary

    // Link Text - for clickable links
    public static let wiseLinkText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.039, green: 0.518, blue: 1.0, alpha: 1.0)
                :  // #0A84FF for dark
                UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)  // #007AFF for light
        })

    // Placeholder Text - for input placeholders
    public static let wisePlaceholderText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.282, green: 0.282, blue: 0.29, alpha: 1.0)
                :  // #48484A for dark
                UIColor(red: 0.78, green: 0.78, blue: 0.8, alpha: 1.0)  // #C7C7CC for light
        })

    // MARK: - Brand Colors (Static - New 5-tier Green Palette)

    public static let wiseBrightGreen = Theme.Colors.green3  // #78C51C - Bright lime for positive indicators
    public static let wiseForestGreen = Theme.Colors.green5  // #043F2E - Primary brand (darkest green)
    public static let wiseCharcoal = Theme.Colors.textPrimary  // Mapping to primary text
    public static let wiseOrange = Theme.Colors.brandAccent
    // wisePurple is defined below with adaptive dark mode support
    public static let wiseMidGray = Theme.Colors.textTertiary

    // MARK: - New Palette Access
    public static let wiseGreen1 = Theme.Colors.green1  // #EEF2E3 - Light backgrounds
    public static let wiseGreen2 = Theme.Colors.green2  // #C8F169 - Highlights, hover states
    public static let wiseGreen3 = Theme.Colors.green3  // #78C51C - Success, active states
    public static let wiseGreen4 = Theme.Colors.green4  // #2A6F2B - Secondary, positive amounts
    public static let wiseGreen5 = Theme.Colors.green5  // #043F2E - Primary brand

    // MARK: - Pastel Avatar Colors (New Unified Design)

    /// Pastel green for avatars - used for income, positive
    public static let pastelAvatarGreen = Theme.Colors.green5  // #043F2E (New primary green)

    /// Pastel gray for avatars - used for neutral, services
    public static let pastelAvatarGray = Color(red: 212 / 255, green: 212 / 255, blue: 212 / 255)  // #D4D4D4

    /// Pastel pink for avatars - used for personal
    public static let pastelAvatarPink = Color(red: 255 / 255, green: 177 / 255, blue: 200 / 255)  // #FFB1C8

    /// Pastel yellow for avatars - used for shopping, retail
    public static let pastelAvatarYellow = Color(red: 255 / 255, green: 229 / 255, blue: 102 / 255)  // #FFE566

    /// Pastel purple for avatars - used for entertainment
    public static let pastelAvatarPurple = Color(red: 196 / 255, green: 177 / 255, blue: 255 / 255)  // #C4B1FF

    // MARK: - Amount Display Colors (Updated to new palette)

    /// Positive amount color - green for income/owes you
    public static let amountPositive = Theme.Colors.amountPositive  // GREEN 4 #2A6F2B

    /// Negative amount color - red for expense/you owe
    public static let amountNegative = Theme.Colors.amountNegative  // Red #D92D20

    // MARK: - List Design Colors (New Unified Design)

    /// Description text gray
    public static let listDescriptionGray = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)  // #666666

    /// Secondary/time text gray
    public static let listSecondaryGray = Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255)  // #999999

    /// Divider color
    public static let listDivider = Color(red: 238 / 255, green: 238 / 255, blue: 238 / 255)  // #EEEEEE

    // MARK: - New Semantic Colors (for hardcoded color replacement)

    /// Description text - adaptive for dark mode
    public static let wiseDescriptionText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.6, alpha: 1.0)  // Lighter gray for dark mode
                : UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)  // #666666 for light
        })

    /// Time/tertiary info text - adaptive for dark mode
    public static let wiseTimeText = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.5, alpha: 1.0)  // Mid gray for dark mode
                : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)  // #999999 for light
        })

    /// Skeleton loading base color - adaptive for dark mode
    public static let wiseSkeletonBase = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.2, alpha: 1.0)  // Dark gray for dark mode
                : UIColor(white: 0.9, alpha: 1.0)  // Light gray for light mode
        })

    // MARK: - Status Colors (Adaptive)

    // Success - green
    public static let wiseSuccess = Theme.Colors.success

    // Warning - orange
    public static let wiseWarning = Theme.Colors.warning

    // Error - red (adaptive)
    public static let wiseError = Theme.Colors.statusError

    // Info - blue
    public static let wiseInfo = Theme.Colors.info

    // MARK: - Button Colors (Adaptive)

    // Primary Button Background
    public static let wisePrimaryButton = Theme.Colors.buttonPrimary

    // Primary Button Text
    public static let wisePrimaryButtonText = Theme.Colors.buttonPrimaryText

    // Secondary Button Background
    public static let wiseSecondaryButton = Theme.Colors.buttonSecondary

    // Secondary Button Text
    public static let wiseSecondaryButtonText = Theme.Colors.buttonSecondaryText

    // Destructive Button
    public static let wiseDestructiveButton = Theme.Colors.statusError

    // Disabled Button
    public static let wiseDisabledButton = Theme.Colors.buttonDisabled

    // MARK: - Border & Divider Colors (Adaptive)

    // Primary Border
    public static let wiseBorder = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
                :  // #4D4D4D for dark
                UIColor(red: 0.941, green: 0.945, blue: 0.953, alpha: 1.0)  // #F0F1F3 for light
        })

    // Secondary Border - for subtle borders
    public static let wiseSecondaryBorder = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.22, green: 0.22, blue: 0.227, alpha: 1.0)
                :  // #38383A for dark
                UIColor(red: 0.898, green: 0.898, blue: 0.918, alpha: 1.0)  // #E5E5EA for light
        })

    // Separator - for dividers
    public static let wiseSeparator = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.22, green: 0.22, blue: 0.227, alpha: 1.0)
                :  // #38383A for dark
                UIColor(red: 0.776, green: 0.776, blue: 0.784, alpha: 1.0)  // #C6C6C8 for light
        })

    // Focus Border - for focus states
    public static let wiseFocusBorder = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.039, green: 0.518, blue: 1.0, alpha: 1.0)
                :  // #0A84FF for dark
                UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)  // #007AFF for light
        })

    // MARK: - Effect Colors

    // Shadow Color - use with shadowOpacity helper
    public static let wiseShadowLight = Color.black.opacity(0.1)
    public static let wiseShadowDark = Color.black.opacity(0.3)

    // Overlay Color - for dimming overlays
    public static let wiseOverlayLight = Color.black.opacity(0.4)
    public static let wiseOverlayDark = Color.black.opacity(0.6)

    // MARK: - System Colors (Static)

    public static let wiseBlue = Color(red: 0.0, green: 0.478, blue: 1.0)  // #007AFF - iMessage blue
    public static let wiseAccentBlue = Color(red: 0.0, green: 0.478, blue: 1.0)  // #007AFF
    public static let wiseAccentOrange = Color(red: 1.0, green: 0.596, blue: 0.0)  // #FF9800

    // MARK: - iMessage Bubble Colors

    /// iMessage sent bubble blue (#007AFF)
    public static let iMessageBlue = Color(red: 0.0, green: 0.478, blue: 1.0)  // #007AFF

    /// iMessage received bubble gray (#E9E9EB)
    public static let iMessageGray = Color(red: 0.914, green: 0.914, blue: 0.922)  // #E9E9EB

    /// Transaction amount yellow for sent bubbles (#FFD60A)
    public static let transactionYellow = Color(red: 1.0, green: 0.839, blue: 0.039)  // #FFD60A

    /// Transaction amount orange for received bubbles (#FF6B35)
    public static let transactionOrange = Color(red: 1.0, green: 0.420, blue: 0.208)  // #FF6B35

    // Additional UI Colors
    public static let wiseGray = Color(red: 0.557, green: 0.557, blue: 0.576)  // #8E8E93
    public static let wiseGreen = Color(red: 0.204, green: 0.780, blue: 0.349)  // #34C759

    // Purple - adaptive for dark mode
    public static let wisePurple = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.733, green: 0.522, blue: 0.851, alpha: 1.0)
                :  // #BB85D9 lighter for dark
                UIColor(red: 0.608, green: 0.349, blue: 0.714, alpha: 1.0)  // #9B59B6 for light
        })

    // Shadow color - adaptive for dark mode
    static let wiseShadowColor = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.0, alpha: 0.5)
                :  // darker shadow for dark mode
                UIColor(white: 0.0, alpha: 0.2)  // lighter shadow for light mode
        })

    // Overlay color - adaptive for dark mode
    static let wiseOverlayColor = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.0, alpha: 0.6)
                :  // darker overlay for dark mode
                UIColor(white: 0.0, alpha: 0.4)  // lighter overlay for light mode
        })

    // MARK: - Category Colors (Dark Mode Enhanced)
    // Each category has light/dark variants with reduced saturation for dark mode

    // Entertainment - Purple
    static let wiseCategoryEntertainment = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.733, green: 0.522, blue: 0.851, alpha: 1.0)
                :  // #BB85D9 lighter for dark
                UIColor(red: 0.608, green: 0.349, blue: 0.714, alpha: 1.0)  // #9B59B6 for light
        })

    // Productivity - Blue
    static let wiseCategoryProductivity = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.431, green: 0.851, blue: 0.82, alpha: 1.0)
                :  // #6ED9D1 lighter for dark
                UIColor(red: 0.306, green: 0.804, blue: 0.769, alpha: 1.0)  // #4ECDC4 for light
        })

    // Fitness & Health - Green/Mint
    static let wiseCategoryFitness = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.659, green: 0.91, blue: 0.863, alpha: 1.0)
                :  // #A8E8DC lighter for dark
                UIColor(red: 0.584, green: 0.882, blue: 0.827, alpha: 1.0)  // #95E1D3 for light
        })

    // Education - Coral
    static let wiseCategoryEducation = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.961, green: 0.608, blue: 0.608, alpha: 1.0)
                :  // #F59B9B lighter for dark
                UIColor(red: 0.953, green: 0.506, blue: 0.506, alpha: 1.0)  // #F38181 for light
        })

    // News & Media - Lavender
    static let wiseCategoryNews = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.729, green: 0.651, blue: 0.894, alpha: 1.0)
                :  // #BAA6E4 lighter for dark
                UIColor(red: 0.667, green: 0.588, blue: 0.855, alpha: 1.0)  // #AA96DA for light
        })

    // Music & Audio - Pink
    static let wiseCategoryMusic = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.992, green: 0.78, blue: 0.859, alpha: 1.0)
                :  // #FDC7DB lighter for dark
                UIColor(red: 0.988, green: 0.729, blue: 0.827, alpha: 1.0)  // #FCBAD3 for light
        })

    // Cloud Storage - Sky Blue
    static let wiseCategoryCloud = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.722, green: 0.886, blue: 0.933, alpha: 1.0)
                :  // #B8E2EE lighter for dark
                UIColor(red: 0.659, green: 0.847, blue: 0.918, alpha: 1.0)  // #A8D8EA for light
        })

    // Gaming - Yellow
    static let wiseCategoryGaming = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.882, blue: 0.341, alpha: 1.0)
                :  // #FFE157 lighter for dark
                UIColor(red: 1.0, green: 0.851, blue: 0.239, alpha: 1.0)  // #FFD93D for light
        })

    // Design & Creative - Green
    static let wiseCategoryDesign = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.522, green: 0.851, blue: 0.6, alpha: 1.0)
                :  // #85D999 lighter for dark
                UIColor(red: 0.42, green: 0.812, blue: 0.498, alpha: 1.0)  // #6BCF7F for light
        })

    // Development - Blue
    static let wiseCategoryDevelopment = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.404, green: 0.667, blue: 1.0, alpha: 1.0)
                :  // #67AAFF lighter for dark
                UIColor(red: 0.302, green: 0.588, blue: 1.0, alpha: 1.0)  // #4D96FF for light
        })

    // Finance - Orange/Gold
    static let wiseCategoryFinance = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.773, blue: 0.404, alpha: 1.0)
                :  // #FFC567 lighter for dark
                UIColor(red: 1.0, green: 0.722, blue: 0.302, alpha: 1.0)  // #FFB84D for light
        })

    // Utilities - Light Blue
    static let wiseCategoryUtilities = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.706, green: 0.816, blue: 1.0, alpha: 1.0)
                :  // #B4D0FF lighter for dark
                UIColor(red: 0.627, green: 0.769, blue: 1.0, alpha: 1.0)  // #A0C4FF for light
        })

    // Food & Dining - Salmon
    static let wiseCategoryFood = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.706, blue: 0.706, alpha: 1.0)
                :  // #FFB4B4 lighter for dark
                UIColor(red: 1.0, green: 0.643, blue: 0.643, alpha: 1.0)  // #FFA4A4 for light
        })

    // Transportation - Purple/Lavender
    static let wiseCategoryTransportation = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.769, green: 0.718, blue: 0.902, alpha: 1.0)
                :  // #C4B7E6 lighter for dark
                UIColor(red: 0.706, green: 0.655, blue: 0.839, alpha: 1.0)  // #B4A7D6 for light
        })

    // Other - Gray
    static let wiseCategoryOther = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)
                :  // #8E8E93 for dark
                UIColor(red: 0.776, green: 0.776, blue: 0.784, alpha: 1.0)  // #C6C6C8 for light
        })

    // MARK: - Chart Colors (Dark Mode Enhanced)
    // Lighter, less saturated versions for dark mode charts

    static let chartColorsLight: [Color] = [
        Color(hexString: "#FF6B6B"),  // Red
        Color(hexString: "#4ECDC4"),  // Teal
        Color(hexString: "#95E1D3"),  // Mint
        Color(hexString: "#F38181"),  // Coral
        Color(hexString: "#AA96DA"),  // Lavender
        Color(hexString: "#FCBAD3"),  // Pink
        Color(hexString: "#A8D8EA"),  // Sky Blue
        Color(hexString: "#FFD93D"),  // Yellow
        Color(hexString: "#6BCF7F"),  // Green
        Color(hexString: "#4D96FF"),  // Blue
        Color(hexString: "#FFB84D"),  // Orange
        Color(hexString: "#A0C4FF"),  // Light Blue
        Color(hexString: "#FFA4A4"),  // Salmon
        Color(hexString: "#B4A7D6"),  // Purple
        Color(hexString: "#C6C6C8"),  // Gray
    ]

    static let chartColorsDark: [Color] = [
        Color(hexString: "#FF8585"),  // Red (lighter)
        Color(hexString: "#6ED9D1"),  // Teal (lighter)
        Color(hexString: "#A8E8DC"),  // Mint (lighter)
        Color(hexString: "#F59B9B"),  // Coral (lighter)
        Color(hexString: "#BAA6E4"),  // Lavender (lighter)
        Color(hexString: "#FDC7DB"),  // Pink (lighter)
        Color(hexString: "#B8E2EE"),  // Sky Blue (lighter)
        Color(hexString: "#FFE157"),  // Yellow (lighter)
        Color(hexString: "#85D999"),  // Green (lighter)
        Color(hexString: "#67AAFF"),  // Blue (lighter)
        Color(hexString: "#FFC567"),  // Orange (lighter)
        Color(hexString: "#B4D0FF"),  // Light Blue (lighter)
        Color(hexString: "#FFB4B4"),  // Salmon (lighter)
        Color(hexString: "#C4B7E6"),  // Purple (lighter)
        Color(hexString: "#8E8E93"),  // Gray
    ]

    /// Get chart color for index based on color scheme
    static func chartColor(at index: Int, colorScheme: ColorScheme) -> Color {
        let colors = colorScheme == .dark ? chartColorsDark : chartColorsLight
        return colors[index % colors.count]
    }

    /// Get category color with dark mode support
    static func categoryColor(for category: String, colorScheme: ColorScheme? = nil) -> Color {
        // These colors automatically adapt based on trait collection
        switch category.lowercased() {
        case "entertainment": return wiseCategoryEntertainment
        case "productivity": return wiseCategoryProductivity
        case "fitness", "fitness & health": return wiseCategoryFitness
        case "education": return wiseCategoryEducation
        case "news", "news & media": return wiseCategoryNews
        case "music", "music & audio": return wiseCategoryMusic
        case "cloud", "cloud storage": return wiseCategoryCloud
        case "gaming": return wiseCategoryGaming
        case "design", "design & creative": return wiseCategoryDesign
        case "development": return wiseCategoryDevelopment
        case "finance": return wiseCategoryFinance
        case "utilities": return wiseCategoryUtilities
        case "food", "food & dining": return wiseCategoryFood
        case "transportation": return wiseCategoryTransportation
        default: return wiseCategoryOther
        }
    }

    // MARK: - Hex Color Initializer

    /// Initialize Color from hex string (custom implementation)
    /// Use `Color(hexString:)` to avoid conflicts with system-provided initializers
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)  // Default gray
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

// MARK: - Spotify Font System (Legacy Support)
// Mapped to Swiff Design System
extension Font {
    // Large Display Fonts - Bold and impactful
    static let spotifyDisplayLarge = Theme.Fonts.displayLarge
    static let spotifyDisplayMedium = Theme.Fonts.displayMedium

    // Headings - Strong hierarchy
    static let spotifyHeadingLarge = Theme.Fonts.headerLarge
    static let spotifyHeadingMedium = Theme.Fonts.headerMedium
    static let spotifyHeadingSmall = Theme.Fonts.headerSmall

    // Body Text - Clean and readable (SF Font)
    static let spotifyBodyLarge = Theme.Fonts.bodyLarge
    static let spotifyBodyMedium = Theme.Fonts.bodyMedium
    static let spotifyBodySmall = Theme.Fonts.bodySmall

    // Labels - For cards and metadata (SF Font)
    static let spotifyLabelLarge = Theme.Fonts.labelLarge
    static let spotifyLabelMedium = Theme.Fonts.labelMedium
    static let spotifyLabelSmall = Theme.Fonts.labelSmall

    // Captions - Supporting information (SF Font)
    static let spotifyCaptionLarge = Theme.Fonts.labelMedium
    static let spotifyCaptionMedium = Theme.Fonts.labelSmall  // Mapping to labelSmall as generic caption
    static let spotifyCaptionSmall = Theme.Fonts.labelSmall.weight(.regular)  // Custom tweak or map to new type if needed

    // Numbers - For financial amounts
    static let spotifyNumberLarge = Theme.Fonts.numberLarge
    static let spotifyNumberMedium = Theme.Fonts.numberMedium
    static let spotifyNumberSmall = Theme.Fonts.labelLarge  // Mapping closest equivalent
}
