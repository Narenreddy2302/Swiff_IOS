//
//  ContentView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/11/25.
//

import SwiftUI
import CoreData
import PhotosUI

// MARK: - Avatar System

// Avatar Type - Supports multiple avatar sources
enum AvatarType: Codable, Equatable {
    case photo(Data)           // Photo from library or camera
    case emoji(String)         // Emoji character
    case initials(String, colorIndex: Int)  // Generated from name

    // For backward compatibility with existing emoji avatars
    init(legacyEmoji: String) {
        self = .emoji(legacyEmoji)
    }
}

// Avatar Sizes
enum AvatarSize {
    case small   // 24x24 - Used in shared subscriptions
    case medium  // 32x32 - Used in group member selection
    case large   // 48x48 - Used in person rows
    case xlarge  // 64x64 - Used in detail views

    var dimension: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 48
        case .xlarge: return 64
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 24
        case .xlarge: return 32
        }
    }
}

// Avatar Style
enum AvatarStyle {
    case gradient  // Gradient background (current PersonRowView style)
    case solid     // Flat color background
    case bordered  // White background with border
}

// Avatar Color Palette - Using Wise brand colors
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
    // Generate initials from a name
    static func generateInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }

    // Process and compress image data for avatar
    static func processImage(_ image: UIImage, maxSize: CGFloat = 200) -> Data? {
        // Resize to circle and compress
        guard let resizedImage = image.resizeToCircle(size: maxSize) else { return nil}
        return resizedImage.jpegData(compressionQuality: 0.8)
    }

    // Generate initials avatar image
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

// UIImage Extension for avatar processing
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

// MARK: - AvatarView Component

struct AvatarView: View {
    let avatarType: AvatarType
    let size: AvatarSize
    let style: AvatarStyle

    init(avatarType: AvatarType, size: AvatarSize = .large, style: AvatarStyle = .gradient) {
        self.avatarType = avatarType
        self.size = size
        self.style = style
    }

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            contentView
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(Circle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .gradient:
            LinearGradient(
                colors: [
                    Color.wiseBrightGreen.opacity(0.2),
                    Color.wiseBrightGreen.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .solid:
            if case .initials(_, let colorIndex) = avatarType {
                AvatarColorPalette.color(for: colorIndex)
            } else {
                Color.wiseBrightGreen.opacity(0.1)
            }

        case .bordered:
            Color.white
                .overlay(
                    Circle()
                        .strokeBorder(Color.wiseBorder, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch avatarType {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size.fontSize))

        case .photo(let imageData):
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
            } else {
                placeholderView
            }

        case .initials(let initials, let colorIndex):
            Text(initials)
                .font(.system(size: size.fontSize, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var placeholderView: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray.opacity(0.5))
            .frame(width: size.dimension * 0.6, height: size.dimension * 0.6)
    }

    private var accessibilityDescription: String {
        switch avatarType {
        case .emoji(let emoji):
            return "Avatar: \(emoji)"
        case .photo:
            return "Profile photo"
        case .initials(let initials, _):
            return "Avatar with initials \(initials)"
        }
    }
}

// Convenience initializer for Person avatars
extension AvatarView {
    init(person: Person, size: AvatarSize = .large, style: AvatarStyle = .gradient) {
        self.init(avatarType: person.avatarType, size: size, style: style)
    }
}

// MARK: - Person Model
struct Person: Identifiable, Codable {
    var id = UUID()
    var name: String
    var email: String
    var phone: String
    var avatarType: AvatarType  // New flexible avatar system
    var balance: Double // Overall balance with this person
    var createdDate: Date

    // Legacy support for emoji string
    @available(*, deprecated, message: "Use avatarType instead")
    var avatar: String {
        get {
            if case .emoji(let emoji) = avatarType {
                return emoji
            }
            return "👤"
        }
        set {
            avatarType = .emoji(newValue)
        }
    }

    init(name: String, email: String, phone: String, avatarType: AvatarType) {
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarType = avatarType
        self.balance = 0.0
        self.createdDate = Date()
    }

    // Convenience init for emoji (backward compatibility)
    init(name: String, email: String, phone: String, avatar: String) {
        self.init(name: name, email: email, phone: phone, avatarType: .emoji(avatar))
    }

    // Generate initials from name
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }

    // Get avatar color index
    var avatarColorIndex: Int {
        AvatarColorPalette.colorIndex(for: name)
    }
}

// MARK: - Group Model
struct Group: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var emoji: String
    var members: [UUID] // Person IDs
    var expenses: [GroupExpense]
    var createdDate: Date
    var totalAmount: Double
    
    init(name: String, description: String, emoji: String, members: [UUID] = []) {
        self.name = name
        self.description = description
        self.emoji = emoji
        self.members = members
        self.expenses = []
        self.createdDate = Date()
        self.totalAmount = 0.0
    }
}

// MARK: - Group Expense Model
struct GroupExpense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var paidBy: UUID // Person ID
    var splitBetween: [UUID] // Person IDs
    var category: TransactionCategory
    var date: Date
    var notes: String
    var receipt: String? // Receipt image path
    var isSettled: Bool
    
    init(title: String, amount: Double, paidBy: UUID, splitBetween: [UUID], category: TransactionCategory, notes: String = "", receipt: String? = nil, isSettled: Bool = false) {
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.splitBetween = splitBetween
        self.category = category
        self.date = Date()
        self.notes = notes
        self.receipt = receipt
        self.isSettled = isSettled
    }
    
    var amountPerPerson: Double {
        splitBetween.isEmpty ? 0 : amount / Double(splitBetween.count)
    }
}

// MARK: - Bill Split Model
struct BillSplit: Identifiable {
    let id = UUID()
    var title: String
    var totalAmount: Double
    var paidBy: Person
    var participants: [BillParticipant]
    var category: TransactionCategory
    var date: Date
    var notes: String
    var isSettled: Bool
    
    var amountPerPerson: Double {
        participants.isEmpty ? 0 : totalAmount / Double(participants.count)
    }
}

struct BillParticipant: Identifiable {
    let id = UUID()
    let person: Person
    var amountOwed: Double
    var hasPaid: Bool
}

// MARK: - Subscription Models
struct Subscription: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var price: Double
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var icon: String // SF Symbol name
    var color: String // Hex color code
    var nextBillingDate: Date
    var isActive: Bool
    var isShared: Bool
    var sharedWith: [UUID] // Person or Group IDs
    var paymentMethod: PaymentMethod
    var createdDate: Date
    var lastBillingDate: Date?
    var totalSpent: Double
    var notes: String
    var website: String?
    var cancellationDate: Date?
    
    init(name: String, description: String, price: Double, billingCycle: BillingCycle, category: SubscriptionCategory, icon: String = "app.fill", color: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.price = price
        self.billingCycle = billingCycle
        self.category = category
        self.icon = icon
        self.color = color
        self.nextBillingDate = billingCycle.calculateNextBilling(from: Date())
        self.isActive = true
        self.isShared = false
        self.sharedWith = []
        self.paymentMethod = .creditCard
        self.createdDate = Date()
        self.lastBillingDate = nil
        self.totalSpent = 0.0
        self.notes = ""
        self.website = nil
        self.cancellationDate = nil
    }
    
    var monthlyEquivalent: Double {
        switch billingCycle {
        case .weekly: return price * 4.33
        case .monthly: return price
        case .quarterly: return price / 3
        case .semiAnnually: return price / 6
        case .annually: return price / 12
        case .lifetime: return 0
        }
    }
    
    var nextBillingAmount: Double {
        return price
    }
    
    var costPerPerson: Double {
        if isShared && !sharedWith.isEmpty {
            return price / Double(sharedWith.count + 1) // +1 for the owner
        }
        return price
    }
}

enum BillingCycle: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly" 
    case quarterly = "Quarterly"
    case semiAnnually = "Semi-annually"
    case annually = "Annually"
    case lifetime = "Lifetime"
    
    var shortName: String {
        switch self {
        case .weekly: return "week"
        case .monthly: return "month"
        case .quarterly: return "quarter"
        case .semiAnnually: return "6 months"
        case .annually: return "year"
        case .lifetime: return "lifetime"
        }
    }
    
    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.plus"
        case .semiAnnually: return "calendar.circle"
        case .annually: return "calendar.circle.fill"
        case .lifetime: return "infinity"
        }
    }
    
    func calculateNextBilling(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .semiAnnually:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
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

// MARK: - Shared Subscription Model
struct SharedSubscription: Identifiable, Codable {
    var id = UUID()
    let subscriptionId: UUID
    var sharedBy: UUID // Person ID
    var sharedWith: [UUID] // Person or Group IDs
    var costSplit: CostSplitType
    var individualCost: Double
    var isAccepted: Bool
    var createdDate: Date
    var notes: String
    
    init(subscriptionId: UUID, sharedBy: UUID, sharedWith: [UUID], costSplit: CostSplitType) {
        self.subscriptionId = subscriptionId
        self.sharedBy = sharedBy
        self.sharedWith = sharedWith
        self.costSplit = costSplit
        self.individualCost = 0.0
        self.isAccepted = false
        self.createdDate = Date()
        self.notes = ""
    }
}

enum CostSplitType: String, CaseIterable, Codable {
    case equal = "Split Equally"
    case percentage = "By Percentage"
    case fixed = "Fixed Amount"
    case free = "Free Access"
}

// MARK: - Subscription Filter Options
enum SubscriptionFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case paused = "Paused"
    case cancelled = "Cancelled"
    case shared = "Shared"
    case expiringSoon = "Expiring Soon"
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .shared: return "person.2.fill"
        case .expiringSoon: return "clock.fill"
        }
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
    
    // System Colors
    static let wiseError = Color(red: 1.0, green: 0.267, blue: 0.212) // #FF4436
    static let wiseBlue = Color(red: 0.0, green: 0.725, blue: 1.0) // #00B9FF
    
    // Borders/Dividers
    static let wiseBorder = Color(red: 0.941, green: 0.945, blue: 0.953) // #F0F1F3
}

// MARK: - Spotify Font System
extension Font {
    // Large Display Fonts - Bold and impactful
    static let spotifyDisplayLarge = Font.custom("Helvetica Neue", size: 32).weight(.black)
    static let spotifyDisplayMedium = Font.custom("Helvetica Neue", size: 24).weight(.bold)
    
    // Headings - Strong hierarchy
    static let spotifyHeadingLarge = Font.custom("Helvetica Neue", size: 20).weight(.bold)
    static let spotifyHeadingMedium = Font.custom("Helvetica Neue", size: 18).weight(.bold)
    static let spotifyHeadingSmall = Font.custom("Helvetica Neue", size: 16).weight(.bold)
    
    // Body Text - Clean and readable
    static let spotifyBodyLarge = Font.custom("Helvetica Neue", size: 16).weight(.medium)
    static let spotifyBodyMedium = Font.custom("Helvetica Neue", size: 14).weight(.medium)
    static let spotifyBodySmall = Font.custom("Helvetica Neue", size: 13).weight(.regular)
    
    // Labels - For cards and metadata
    static let spotifyLabelLarge = Font.custom("Helvetica Neue", size: 14).weight(.semibold)
    static let spotifyLabelMedium = Font.custom("Helvetica Neue", size: 12).weight(.semibold)
    static let spotifyLabelSmall = Font.custom("Helvetica Neue", size: 11).weight(.semibold)
    
    // Captions - Supporting information
    static let spotifyCaptionLarge = Font.custom("Helvetica Neue", size: 12).weight(.medium)
    static let spotifyCaptionMedium = Font.custom("Helvetica Neue", size: 11).weight(.regular)
    static let spotifyCaptionSmall = Font.custom("Helvetica Neue", size: 10).weight(.regular)
    
    // Numbers - For financial amounts
    static let spotifyNumberLarge = Font.custom("Helvetica Neue", size: 24).weight(.black)
    static let spotifyNumberMedium = Font.custom("Helvetica Neue", size: 16).weight(.bold)
    static let spotifyNumberSmall = Font.custom("Helvetica Neue", size: 14).weight(.bold)
}

struct ContentView: View {
    init() {
        // Configure tab bar appearance with transparent background
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Set transparent background
        appearance.backgroundColor = UIColor.clear
        
        // Configure unselected tab item appearance - pitch black
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.black.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.black.opacity(0.6))
        ]
        
        // Configure selected tab item appearance - pitch black
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.black)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.black)
        ]
        
        // Remove separator line
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Set transparent background and enable translucency
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = UIColor.clear
        
        // Set the tint color for selected items
        UITabBar.appearance().tintColor = UIColor(Color.black)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.black.opacity(0.6))
    }
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            RecentActivityView()
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("Feed")
                }
            
            PeopleView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("People")
                }
            
            SubscriptionsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Subscriptions")
                }
        }
        .accentColor(.black)
    }
}

// MARK: - Home View
struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Header with Profile and Actions
                    TopHeaderSection()
                    
                    // Main Content Section
                    VStack(spacing: 20) {
                        // Today Section (moved down)
                        TodaySection()
                        
                        // Four Card Grid
                        FinancialOverviewGrid()
                        
                        // Recent Group Activity Section
                        RecentGroupActivitySection()
                        
                        // Recent Transactions Section
                        RecentActivitySection()
                        
                        Spacer(minLength: 100) // Bottom padding for tab bar
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
            .background(Color.wiseBackground)
        }
    }
}

// MARK: - Top Header Section
struct TopHeaderSection: View {
    var body: some View {
        HStack {
            // Profile Icon (left corner)
            Button(action: {}) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.wisePrimaryText)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Logo in center
            Text("Swiff.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.wiseForestGreen)
            
            Spacer()
            
            // Search Button (right corner)
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.wisePrimaryText)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

// MARK: - Today Section
struct TodaySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Today")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
            }
            
            HStack {
                Text("Sat, 4 February")
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wiseSecondaryText)
                
                Spacer()
            }
        }
    }
}

// MARK: - Financial Overview Grid
struct FinancialOverviewGrid: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            // Balance Card
            FinancialCard(
                icon: "dollarsign.circle.fill",
                iconColor: .wiseBrightGreen,
                title: "BALANCE",
                amount: "$1,234"
            )
            
            // Subscriptions Card (replaced Difference)
            SubscriptionsCard()
            
            // Income Card
            FinancialCard(
                icon: "arrow.up.circle.fill",
                iconColor: .wiseBrightGreen,
                title: "INCOME",
                amount: "$1,234"
            )
            
            // Expenses Card (moved to bottom right)
            FinancialCard(
                icon: "arrow.down.circle.fill",
                iconColor: .wiseError,
                title: "EXPENSES",
                amount: "$934"
            )
        }
    }
}

// MARK: - Financial Card
struct FinancialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(amount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Subscriptions Card
struct SubscriptionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.wiseBlue)
                
                Spacer()
            }
            
            Text("SUBSCRIPTIONS")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text("$89/mo")
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Recent Group Activity Section
struct RecentGroupActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent activity")
                    .fontWeight(.bold)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wiseSecondaryText)
                
                Spacer()
                
                Button("See all") {
                    // Action
                }
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseForestGreen)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // John added a new bill
                    FriendActivityCard(
                        friendMemoji: "👨🏼‍💼",
                        friendName: "John",
                        activityType: "added bill",
                        amount: "$45.60",
                        timeAgo: "2m ago",
                        avatarColor: .wiseBrightGreen
                    )
                    
                    // Sarah paid you back
                    FriendActivityCard(
                        friendMemoji: "🧑🏻‍🦰",
                        friendName: "Sarah",
                        activityType: "paid you",
                        amount: "$25.00",
                        timeAgo: "1h ago",
                        avatarColor: .wiseBrightGreen
                    )
                    
                    // Group "Weekend Trip" has new expense
                    FriendActivityCard(
                        friendMemoji: "🏖️",
                        friendName: "Weekend Trip",
                        activityType: "new expense",
                        amount: "$120.50",
                        timeAgo: "3h ago",
                        avatarColor: .wiseBlue
                    )
                    
                    // Mike requested money
                    FriendActivityCard(
                        friendMemoji: "👨🏻‍💻",
                        friendName: "Mike",
                        activityType: "requested",
                        amount: "$18.75",
                        timeAgo: "5h ago",
                        avatarColor: Color(red: 1.0, green: 0.592, blue: 0.0) // Orange
                    )
                    
                    // Alex settled up
                    FriendActivityCard(
                        friendMemoji: "🧑🏼‍🎨",
                        friendName: "Alex",
                        activityType: "settled up",
                        amount: "$32.40",
                        timeAgo: "1d ago",
                        avatarColor: .wiseBrightGreen
                    )
                    
                    // Group "Roommates" split grocery bill
                    FriendActivityCard(
                        friendMemoji: "🏠",
                        friendName: "Roommates",
                        activityType: "split bill",
                        amount: "$89.20",
                        timeAgo: "2d ago",
                        avatarColor: .wiseForestGreen
                    )
                    
                    // Emma joined group
                    FriendActivityCard(
                        friendMemoji: "👩🏽‍🎓",
                        friendName: "Emma",
                        activityType: "joined group",
                        amount: "$0.00",
                        timeAgo: "3d ago",
                        avatarColor: .wiseBlue
                    )
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Friend Activity Card
struct FriendActivityCard: View {
    let friendMemoji: String
    let friendName: String
    let activityType: String
    let amount: String
    let timeAgo: String
    let avatarColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Friend/Group Avatar with Memoji and activity indicator
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [avatarColor.opacity(0.2), avatarColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(friendMemoji)
                            .font(.system(size: 24))
                    )
                
                // Activity indicator (small dot)
                Circle()
                    .fill(getActivityColor())
                    .frame(width: 12, height: 12)
                    .offset(x: 18, y: -18)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .offset(x: 18, y: -18)
                    )
            }
            
            // Activity details
            VStack(spacing: 2) {
                if amount != "$0.00" {
                    Text(amount)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                
                Text(activityType)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                
                Text(timeAgo)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .frame(width: 80)
    }
    
    // Activity indicator color based on type
    private func getActivityColor() -> Color {
        switch activityType {
        case "paid you", "settled up":
            return .wiseBrightGreen
        case "requested":
            return Color(red: 1.0, green: 0.592, blue: 0.0) // Orange
        case "added bill", "new expense", "split bill":
            return .wiseBlue
        case "joined group":
            return .wiseBlue
        default:
            return .wiseSecondaryText
        }
    }
}

// MARK: - Subscription Spending Section
struct SubscriptionSpendingSection: View {
    // Sample subscription data - in a real app, this would come from your data store
    let samplePersonalSubscriptions = SubscriptionsView.samplePersonalSubscriptions
    let sampleSharedSubscriptions = SubscriptionsView.sampleSharedSubscriptions
    
    var personalMonthlySpend: Double {
        samplePersonalSubscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyEquivalent }
    }
    
    var sharedMonthlySpend: Double {
        sampleSharedSubscriptions.filter { $0.isAccepted }.reduce(0) { $0 + $1.individualCost }
    }
    
    var totalSubscriptionSpend: Double {
        personalMonthlySpend + sharedMonthlySpend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Subscription Spending")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
                
                Button(action: {
                    // Navigate to subscriptions tab - you can implement this
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.spotifyLabelMedium)
                        Image(systemName: "chevron.right")
                            .font(.spotifyCaptionMedium)
                    }
                    .foregroundColor(.wiseBodyText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.wiseBorder)
                    .clipShape(Capsule())
                }
            }
            
            // Subscription spending cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                // Personal Subscriptions Card
                SubscriptionSpendingCard(
                    icon: "person.fill",
                    iconColor: .wiseForestGreen,
                    title: "PERSONAL",
                    amount: String(format: "$%.0f/mo", personalMonthlySpend),
                    subtitle: "\(samplePersonalSubscriptions.filter { $0.isActive }.count) active"
                )
                
                // Shared Subscriptions Card
                SubscriptionSpendingCard(
                    icon: "person.2.fill",
                    iconColor: .wiseBlue,
                    title: "SHARED",
                    amount: String(format: "$%.0f/mo", sharedMonthlySpend),
                    subtitle: "\(sampleSharedSubscriptions.filter { $0.isAccepted }.count) accepted"
                )
            }
            
            // Total spending summary
            HStack {
                Text("Total monthly spending:")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                
                Spacer()
                
                Text(String(format: "$%.0f", totalSubscriptionSpend))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
    }
}

// MARK: - Subscription Spending Card
struct SubscriptionSpendingCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(amount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
            
            Text(subtitle)
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("All")
                            .font(.spotifyLabelMedium)
                        Image(systemName: "chevron.down")
                            .font(.spotifyCaptionMedium)
                    }
                    .foregroundColor(.wiseBodyText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.wiseBorder)
                    .clipShape(Capsule())
                }
            }
            
            // Recent transactions
            VStack(spacing: 12) {
                TransactionItemRow(
                    icon: "cart.fill",
                    iconColor: .wiseBrightGreen,
                    title: "Grocery Shopping",
                    subtitle: "Whole Foods • 2 hours ago",
                    amount: "-$45.67",
                    isExpense: true
                )
                
                TransactionItemRow(
                    icon: "dollarsign.circle.fill",
                    iconColor: .wiseBrightGreen,
                    title: "Salary Deposit",
                    subtitle: "Company Inc • Yesterday",
                    amount: "+$2,500.00",
                    isExpense: false
                )
                
                TransactionItemRow(
                    icon: "car.fill",
                    iconColor: Color(red: 1.0, green: 0.592, blue: 0.0), // Orange
                    title: "Gas Station",
                    subtitle: "Shell • 2 days ago",
                    amount: "-$32.45",
                    isExpense: true
                )
                
                TransactionItemRow(
                    icon: "cup.and.saucer.fill",
                    iconColor: Color(red: 0.647, green: 0.165, blue: 0.165), // Brown
                    title: "Coffee Shop",
                    subtitle: "Starbucks • 3 days ago",
                    amount: "-$5.40",
                    isExpense: true
                )
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Transaction Item Row
struct TransactionItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let isExpense: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                )
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Text(subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            // Amount
            Text(amount)
                .font(.spotifyNumberMedium)
                .foregroundColor(isExpense ? .wiseError : .wiseBrightGreen)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views for Other Tabs
// MARK: - Transaction Category
enum TransactionCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transportation = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case healthcare = "Healthcare"
    case income = "Income"
    case transfer = "Transfer"
    case investment = "Investment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife.circle.fill"
        case .transportation: return "car.circle.fill"
        case .shopping: return "bag.circle.fill"
        case .entertainment: return "tv.circle.fill"
        case .bills: return "house.circle.fill"
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
        case .transportation: return Color(red: 0.0, green: 0.725, blue: 1.0) // Blue
        case .shopping: return Color(red: 0.891, green: 0.118, blue: 0.459) // Pink
        case .entertainment: return Color(red: 0.608, green: 0.349, blue: 0.714) // Purple
        case .bills: return Color(red: 0.647, green: 0.165, blue: 0.165) // Brown
        case .healthcare: return Color(red: 1.0, green: 0.267, blue: 0.212) // Red
        case .income: return Color(red: 0.624, green: 0.910, blue: 0.439) // Green
        case .transfer: return Color(red: 0.235, green: 0.235, blue: 0.235) // Gray
        case .investment: return Color(red: 0.086, green: 0.200, blue: 0.0) // Dark Green
        case .other: return Color(red: 0.5, green: 0.5, blue: 0.5) // Medium Gray
        }
    }
}

// MARK: - Transaction Model
struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: Double
    let category: TransactionCategory
    let date: Date
    let isRecurring: Bool
    let tags: [String]
    
    var isExpense: Bool {
        return amount < 0
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
    
    var amountWithSign: String {
        let sign = isExpense ? "-" : "+"
        return "\(sign)\(formattedAmount)"
    }
}

// MARK: - Filter Options
enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case expenses = "Expenses"
    case income = "Income"
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .today: return "calendar"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar.badge.plus"
        case .expenses: return "arrow.down.circle"
        case .income: return "arrow.up.circle"
        }
    }
}

// MARK: - Recent Activity View (Feed)
struct RecentActivityView: View {
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedCategory: TransactionCategory? = nil
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var userTransactions: [Transaction] = []
    
    // Sample transaction data
    let sampleTransactions: [Transaction] = [
        Transaction(title: "Starbucks Coffee", subtitle: "Downtown Location", amount: -5.47, category: .food, date: Date(), isRecurring: false, tags: ["Coffee", "Quick"]),
        Transaction(title: "Salary Deposit", subtitle: "Tech Company Inc", amount: 2500.00, category: .income, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), isRecurring: true, tags: ["Salary", "Monthly"]),
        Transaction(title: "Uber Ride", subtitle: "Airport to Home", amount: -32.45, category: .transportation, date: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(), isRecurring: false, tags: ["Airport", "Ride"]),
        Transaction(title: "Netflix Subscription", subtitle: "Monthly Plan", amount: -15.99, category: .entertainment, date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), isRecurring: true, tags: ["Streaming", "Entertainment"]),
        Transaction(title: "Grocery Shopping", subtitle: "Whole Foods Market", amount: -87.23, category: .food, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), isRecurring: false, tags: ["Groceries", "Weekly"]),
        Transaction(title: "Electric Bill", subtitle: "City Electric Company", amount: -124.56, category: .bills, date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(), isRecurring: true, tags: ["Utilities", "Monthly"]),
        Transaction(title: "Amazon Purchase", subtitle: "Electronics & Books", amount: -45.99, category: .shopping, date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), isRecurring: false, tags: ["Online", "Electronics"]),
        Transaction(title: "Investment Transfer", subtitle: "Stock Portfolio", amount: -500.00, category: .investment, date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), isRecurring: false, tags: ["Stocks", "Investment"]),
    ]
    
    var filteredTransactions: [Transaction] {
        var filtered = sampleTransactions + userTransactions
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply time and type filters
        switch selectedFilter {
        case .all:
            break
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.date) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= monthAgo }
        case .expenses:
            filtered = filtered.filter { $0.isExpense }
        case .income:
            filtered = filtered.filter { !$0.isExpense }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Search and Filter
                FeedHeaderSection(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    showingFilterSheet: $showingFilterSheet,
                    showingAddTransactionSheet: $showingAddTransactionSheet
                )
                
                // Category Filter Pills
                CategoryFilterSection(
                    selectedCategory: $selectedCategory
                )
                
                // Transaction List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTransactions) { transaction in
                            FeedTransactionRow(transaction: transaction)
                        }
                        
                        // Bottom padding for tab bar
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .background(Color.wiseBackground)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FeedFilterSheet(selectedFilter: $selectedFilter, showingFilterSheet: $showingFilterSheet)
        }
        .sheet(isPresented: $showingAddTransactionSheet) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddTransactionSheet,
                onTransactionAdded: { newTransaction in
                    userTransactions.append(newTransaction)
                }
            )
        }
    }
}

// MARK: - Feed Header Section
struct FeedHeaderSection: View {
    @Binding var searchText: String
    @Binding var selectedFilter: TransactionFilter
    @Binding var showingFilterSheet: Bool
    @Binding var showingAddTransactionSheet: Bool
    
    @State private var isAddButtonPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Header
            HStack {
                Text("Feed")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
                
                // Add Transaction Button - Enhanced
                Button(action: { 
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showingAddTransactionSheet = true 
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add Transaction")
                            .font(.spotifyLabelLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                isAddButtonPressed ? Color(red: 0.066, green: 0.180, blue: 0.0) : .wiseForestGreen,
                                isAddButtonPressed ? Color(red: 0.086, green: 0.200, blue: 0.0) : Color(red: 0.106, green: 0.220, blue: 0.020)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .wiseForestGreen.opacity(isAddButtonPressed ? 0.4 : 0.3), radius: isAddButtonPressed ? 6 : 4, x: 0, y: isAddButtonPressed ? 3 : 2)
                }
                .scaleEffect(isAddButtonPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isAddButtonPressed)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    isAddButtonPressed = pressing
                }, perform: {})
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wiseSecondaryText)
                    .font(.system(size: 16))
                
                TextField("Search transactions...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.wiseSecondaryText)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Feed Stats Section
struct FeedStatsSection: View {
    let transactions: [Transaction]
    
    var totalIncome: Double {
        transactions.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        abs(transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount })
    }
    
    var netAmount: Double {
        totalIncome - totalExpenses
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Net Amount Card
                FeedStatCard(
                    title: "Net Amount",
                    amount: netAmount,
                    icon: "plus.minus.circle.fill",
                    color: netAmount >= 0 ? .wiseBrightGreen : .wiseError
                )
                
                // Total Income Card
                FeedStatCard(
                    title: "Total Income",
                    amount: totalIncome,
                    icon: "arrow.up.circle.fill",
                    color: .wiseBrightGreen
                )
                
                // Total Expenses Card
                FeedStatCard(
                    title: "Total Expenses",
                    amount: totalExpenses,
                    icon: "arrow.down.circle.fill",
                    color: .wiseError
                )
                
                // Transaction Count Card
                FeedStatCard(
                    title: "Transactions",
                    amount: Double(transactions.count),
                    icon: "list.bullet.circle.fill",
                    color: .wiseBlue,
                    isCount: true
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Feed Stat Card
struct FeedStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let isCount: Bool
    
    init(title: String, amount: Double, icon: String, color: Color, isCount: Bool = false) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.isCount = isCount
    }
    
    var formattedAmount: String {
        if isCount {
            return String(Int(amount))
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(formattedAmount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(width: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Category Filter Section
struct CategoryFilterSection: View {
    @Binding var selectedCategory: TransactionCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories Button
                Button(action: { selectedCategory = nil }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(selectedCategory == nil ? .white : .wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedCategory == nil ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                }
                
                // Category Pills
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    Button(action: { 
                        selectedCategory = selectedCategory == category ? nil : category 
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(category.color)
                            Text(category.rawValue)
                                .font(.spotifyLabelSmall)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color : Color.wiseBorder)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Feed Transaction Row
struct FeedTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Circle()
                .fill(transaction.category.color.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(transaction.category.color)
                )
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                    
                    Spacer()
                    
                    if transaction.isRecurring {
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseBlue)
                    }
                }
                
                Text(transaction.subtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(transaction.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.wiseBorder.opacity(0.5))
                                )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Amount and Date
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amountWithSign)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(transaction.isExpense ? .wiseError : .wiseBrightGreen)
                
                Text(transaction.date, style: .time)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Feed Filter Sheet
struct FeedFilterSheet: View {
    @Binding var selectedFilter: TransactionFilter
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        showingFilterSheet = false
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.wiseForestGreen)
                                .frame(width: 24)
                            
                            Text(filter.rawValue)
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.wiseBrightGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Add Transaction Sheet
struct AddTransactionSheet: View {
    @Binding var showingAddTransactionSheet: Bool
    let onTransactionAdded: (Transaction) -> Void
    
    @State private var title = ""
    @State private var subtitle = ""
    @State private var amount = ""
    @State private var selectedCategory: TransactionCategory = .other
    @State private var transactionType: TransactionType = .expense
    @State private var isRecurring = false
    @State private var selectedDate = Date()
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingCategoryPicker = false
    
    enum TransactionType: String, CaseIterable {
        case expense = "Expense"
        case income = "Income"
        
        var color: Color {
            switch self {
            case .expense: return .wiseError
            case .income: return .wiseBrightGreen
            }
        }
        
        var icon: String {
            switch self {
            case .expense: return "arrow.down.circle.fill"
            case .income: return "arrow.up.circle.fill"
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subtitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !amount.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transaction Type")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        HStack(spacing: 12) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Button(action: { transactionType = type }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16))
                                        Text(type.rawValue)
                                            .font(.spotifyBodyMedium)
                                    }
                                    .foregroundColor(transactionType == type ? .white : type.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(transactionType == type ? type.color : type.color.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }
                    
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., Coffee at Starbucks", text: $title)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Subtitle
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., Downtown Location", text: $subtitle)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Amount
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Amount *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("0.00", text: $amount)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        Button(action: { showingCategoryPicker = true }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(selectedCategory.color.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: selectedCategory.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(selectedCategory.color)
                                    )
                                
                                Text(selectedCategory.rawValue)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }
                    }
                    
                    // Date and Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Options")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Recurring Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recurring Transaction")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("Mark as recurring expense/income")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isRecurring)
                                .tint(.wiseBrightGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                    }
                    
                    // Tags Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tags")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Add Tag Input
                        HStack {
                            TextField("Add a tag", text: $newTag)
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wisePrimaryText)
                            
                            Button(action: addTag) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.wiseBrightGreen)
                            }
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                        
                        // Tags Display
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.spotifyCaptionSmall)
                                                .foregroundColor(.wisePrimaryText)
                                            
                                            Button(action: { removeTag(tag) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.wiseSecondaryText)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.wiseBorder)
                                        )
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddTransactionSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTransaction()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(
                selectedCategory: $selectedCategory,
                showingCategoryPicker: $showingCategoryPicker
            )
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func addTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let finalAmount = transactionType == .expense ? -abs(amountValue) : abs(amountValue)
        
        let newTransaction = Transaction(
            title: title.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            amount: finalAmount,
            category: selectedCategory,
            date: selectedDate,
            isRecurring: isRecurring,
            tags: tags
        )
        
        onTransactionAdded(newTransaction)
        showingAddTransactionSheet = false
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    @Binding var selectedCategory: TransactionCategory
    @Binding var showingCategoryPicker: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            showingCategoryPicker = false
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(category.color.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(category.color)
                                    )
                                
                                Text(category.rawValue)
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wisePrimaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.white)
                                    .stroke(selectedCategory == category ? category.color : Color.wiseBorder, lineWidth: selectedCategory == category ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingCategoryPicker = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - People View
struct PeopleView: View {
    @State private var selectedTab: PeopleTab = .people
    @State private var showingAddPersonSheet = false
    @State private var showingAddGroupSheet = false
    @State private var people: [Person] = samplePeople
    @State private var groups: [Group] = sampleGroups
    
    enum PeopleTab: String, CaseIterable {
        case people = "People"
        case groups = "Groups"
        
        var icon: String {
            switch self {
            case .people: return "person.2.fill"
            case .groups: return "person.3.fill"
            }
        }
    }
    
    // Sample data with Apple Memoji
    static let samplePeople: [Person] = [
        {
            // Using emoji avatar
            var person = Person(name: "Sarah Wilson", email: "sarah@example.com", phone: "+1234567890", avatar: "🧑🏻‍🦰")
            person.balance = 25.50 // They owe me money
            return person
        }(),
        {
            // Using initials avatar with color
            var person = Person(
                name: "John Smith",
                email: "john@example.com",
                phone: "+1234567891",
                avatarType: .initials("JS", colorIndex: 0)
            )
            person.balance = -15.75 // I owe them money
            return person
        }(),
        {
            // Using emoji avatar
            var person = Person(name: "Mike Chen", email: "mike@example.com", phone: "+1234567892", avatar: "👨🏻‍💻")
            person.balance = 0.0 // Settled up
            return person
        }(),
        {
            // Using initials avatar with different color
            var person = Person(
                name: "Emma Davis",
                email: "emma@example.com",
                phone: "+1234567893",
                avatarType: .initials("ED", colorIndex: 3)
            )
            person.balance = 45.20 // They owe me money
            return person
        }(),
        {
            // Using emoji avatar
            var person = Person(name: "Alex Johnson", email: "alex@example.com", phone: "+1234567894", avatar: "🧑🏼‍🎨")
            person.balance = -8.30 // I owe them money
            return person
        }()
    ]
    
    static let sampleGroups: [Group] = [
        Group(name: "Weekend Trip", description: "Beach vacation with friends", emoji: "🏖️", members: [samplePeople[0].id, samplePeople[1].id, samplePeople[2].id]),
        Group(name: "Roommates", description: "Monthly household expenses", emoji: "🏠", members: [samplePeople[0].id, samplePeople[3].id]),
        Group(name: "Office Team", description: "Work lunch and coffee expenses", emoji: "💼", members: [samplePeople[1].id, samplePeople[2].id, samplePeople[4].id])
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                PeopleHeaderSection(
                    selectedTab: $selectedTab,
                    showingAddPersonSheet: $showingAddPersonSheet,
                    showingAddGroupSheet: $showingAddGroupSheet
                )
                
                // Content
                TabView(selection: $selectedTab) {
                    // People Tab
                    PeopleListView(people: $people)
                        .tag(PeopleTab.people)
                    
                    // Groups Tab
                    GroupsListView(groups: $groups, people: people)
                        .tag(PeopleTab.groups)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(Color.wiseBackground)
        }
        .sheet(isPresented: $showingAddPersonSheet) {
            AddPersonSheet(
                showingAddPersonSheet: $showingAddPersonSheet,
                onPersonAdded: { newPerson in
                    people.append(newPerson)
                }
            )
        }
        .sheet(isPresented: $showingAddGroupSheet) {
            AddGroupSheet(
                showingAddGroupSheet: $showingAddGroupSheet,
                people: people,
                onGroupAdded: { newGroup in
                    groups.append(newGroup)
                }
            )
        }
    }
}

// MARK: - People Header Section
struct PeopleHeaderSection: View {
    @Binding var selectedTab: PeopleView.PeopleTab
    @Binding var showingAddPersonSheet: Bool
    @Binding var showingAddGroupSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Header
            HStack {
                Text("People")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
                
                // Add Button
                Button(action: {
                    if selectedTab == .people {
                        showingAddPersonSheet = true
                    } else {
                        showingAddGroupSheet = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text(selectedTab == .people ? "Add Person" : "Add Group")
                            .font(.spotifyLabelLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.wiseForestGreen, Color(red: 0.106, green: 0.220, blue: 0.020)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .wiseForestGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            
            // Segmented Control
            HStack(spacing: 0) {
                ForEach(PeopleView.PeopleTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.spotifyLabelLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .wiseBodyText)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTab == tab ? Color.wiseForestGreen : Color.clear)
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationView {
            Text("Groups View")
                .navigationTitle("Groups")
        }
    }
}

struct SubscriptionsView: View {
    @State private var selectedTab: SubscriptionsTab = .personal
    @State private var showingAddSubscriptionSheet = false
    @State private var personalSubscriptions: [Subscription] = samplePersonalSubscriptions
    @State private var sharedSubscriptions: [SharedSubscription] = sampleSharedSubscriptions
    @State private var selectedFilter: SubscriptionFilter = .all
    @State private var selectedCategory: SubscriptionCategory? = nil
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var showingInsightsSheet = false
    @State private var showingRenewalCalendarSheet = false
    
    enum SubscriptionsTab: String, CaseIterable {
        case personal = "Personal"
        case shared = "Shared"
        
        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .shared: return "person.2.fill"
            }
        }
    }
    
    // Sample data with more realistic subscriptions
    static let samplePersonalSubscriptions: [Subscription] = [
        {
            var sub = Subscription(name: "Netflix", description: "Premium streaming plan", price: 17.99, billingCycle: .monthly, category: .entertainment, icon: "tv.fill", color: "#E50914")
            sub.totalSpent = 215.88
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
            sub.website = "netflix.com"
            sub.notes = "Family plan - 4 screens"
            return sub
        }(),
        {
            var sub = Subscription(name: "Spotify Premium", description: "Music streaming", price: 10.99, billingCycle: .monthly, category: .music, icon: "music.note", color: "#1DB954")
            sub.totalSpent = 131.88
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -12, to: Date())
            sub.website = "spotify.com"
            sub.isShared = true
            sub.sharedWith = [UUID(), UUID()] // Mock shared with 2 people
            return sub
        }(),
        {
            var sub = Subscription(name: "Adobe Creative Cloud", description: "Photography plan", price: 20.99, billingCycle: .monthly, category: .design, icon: "camera.fill", color: "#FF0000")
            sub.totalSpent = 251.88
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
            sub.website = "adobe.com"
            sub.notes = "20GB cloud storage included"
            return sub
        }(),
        {
            var sub = Subscription(name: "GitHub Pro", description: "Advanced collaboration features", price: 4.00, billingCycle: .monthly, category: .development, icon: "chevron.left.forwardslash.chevron.right", color: "#181717")
            sub.totalSpent = 48.00
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -18, to: Date())
            sub.website = "github.com"
            return sub
        }(),
        {
            var sub = Subscription(name: "iCloud+", description: "2TB storage plan", price: 9.99, billingCycle: .monthly, category: .cloud, icon: "icloud.fill", color: "#007AFF")
            sub.totalSpent = 119.88
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())
            sub.website = "apple.com"
            sub.isShared = true
            sub.sharedWith = [UUID(), UUID(), UUID()] // Mock family sharing
            return sub
        }(),
        {
            var sub = Subscription(name: "Figma Professional", description: "Design collaboration", price: 15.00, billingCycle: .monthly, category: .design, icon: "paintbrush.fill", color: "#FF7262")
            sub.totalSpent = 180.00
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
            sub.website = "figma.com"
            return sub
        }(),
        {
            var sub = Subscription(name: "Disney+", description: "Streaming service", price: 7.99, billingCycle: .monthly, category: .entertainment, icon: "play.rectangle.fill", color: "#113CCF")
            sub.totalSpent = 95.88
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
            sub.website = "disneyplus.com"
            return sub
        }(),
        {
            var sub = Subscription(name: "The New York Times", description: "Digital subscription", price: 4.25, billingCycle: .weekly, category: .news, icon: "newspaper.fill", color: "#000000")
            sub.totalSpent = 221.00
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
            sub.website = "nytimes.com"
            return sub
        }(),
        {
            var sub = Subscription(name: "Notion Pro", description: "Workspace and wiki", price: 8.00, billingCycle: .monthly, category: .productivity, icon: "doc.text.fill", color: "#000000")
            sub.isActive = false
            sub.cancellationDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
            sub.totalSpent = 96.00
            sub.website = "notion.so"
            sub.notes = "Cancelled due to lack of use"
            return sub
        }(),
        {
            var sub = Subscription(name: "Headspace", description: "Meditation and mindfulness", price: 12.99, billingCycle: .monthly, category: .fitness, icon: "brain.head.profile", color: "#FF6B35")
            sub.totalSpent = 155.88
            sub.lastBillingDate = Calendar.current.date(byAdding: .day, value: -9, to: Date())
            sub.website = "headspace.com"
            return sub
        }()
    ]
    
    static let sampleSharedSubscriptions: [SharedSubscription] = [
        {
            var shared = SharedSubscription(subscriptionId: UUID(), sharedBy: PeopleView.samplePeople[0].id, sharedWith: [PeopleView.samplePeople[1].id, PeopleView.samplePeople[2].id], costSplit: .equal)
            shared.individualCost = 6.00
            shared.isAccepted = true
            shared.notes = "Netflix Family Plan"
            return shared
        }(),
        {
            var shared = SharedSubscription(subscriptionId: UUID(), sharedBy: PeopleView.samplePeople[2].id, sharedWith: [PeopleView.samplePeople[0].id, PeopleView.samplePeople[3].id], costSplit: .equal)
            shared.individualCost = 3.67
            shared.isAccepted = true
            shared.notes = "Spotify Family"
            return shared
        }(),
        {
            var shared = SharedSubscription(subscriptionId: UUID(), sharedBy: PeopleView.samplePeople[1].id, sharedWith: [PeopleView.samplePeople[0].id], costSplit: .percentage)
            shared.individualCost = 8.00
            shared.isAccepted = false
            shared.notes = "YouTube Premium - waiting for acceptance"
            return shared
        }()
    ]
    
    var filteredPersonalSubscriptions: [Subscription] {
        var filtered = personalSubscriptions
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .paused:
            filtered = filtered.filter { !$0.isActive && $0.cancellationDate == nil }
        case .cancelled:
            filtered = filtered.filter { $0.cancellationDate != nil }
        case .shared:
            filtered = filtered.filter { $0.isShared }
        case .expiringSoon:
            let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            filtered = filtered.filter { $0.nextBillingDate <= nextWeek && $0.isActive }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var totalMonthlySpend: Double {
        personalSubscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyEquivalent }
    }
    
    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }
    
    var nextBillingDate: Date? {
        personalSubscriptions
            .filter { $0.isActive }
            .map { $0.nextBillingDate }
            .min()
    }
    
    var upcomingBills: [Subscription] {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return personalSubscriptions
            .filter { $0.isActive && $0.nextBillingDate <= nextWeek }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with enhanced stats
                SubscriptionsHeaderSectionEnhanced(
                    selectedTab: $selectedTab,
                    showingAddSubscriptionSheet: $showingAddSubscriptionSheet,
                    showingInsightsSheet: $showingInsightsSheet,
                    showingRenewalCalendarSheet: $showingRenewalCalendarSheet,
                    totalMonthlySpend: totalMonthlySpend,
                    totalAnnualSpend: totalAnnualSpend,
                    nextBillingDate: nextBillingDate,
                    upcomingBillsCount: upcomingBills.count
                )
                
                // Quick Stats Cards
                SubscriptionQuickStatsView(
                    subscriptions: personalSubscriptions,
                    sharedSubscriptions: sharedSubscriptions
                )
                
                // Category Filter Pills
                SubscriptionsCategoryFilterSection(
                    selectedCategory: $selectedCategory
                )
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Personal Subscriptions Tab
                    EnhancedPersonalSubscriptionsView(
                        subscriptions: filteredPersonalSubscriptions,
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        showingFilterSheet: $showingFilterSheet
                    )
                    .tag(SubscriptionsTab.personal)
                    
                    // Shared Subscriptions Tab
                    EnhancedSharedSubscriptionsView(
                        sharedSubscriptions: $sharedSubscriptions,
                        searchText: $searchText,
                        people: PeopleView.samplePeople
                    )
                    .tag(SubscriptionsTab.shared)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(Color.wiseBackground)
        }
        .sheet(isPresented: $showingAddSubscriptionSheet) {
            EnhancedAddSubscriptionSheet(
                showingAddSubscriptionSheet: $showingAddSubscriptionSheet,
                onSubscriptionAdded: { newSubscription in
                    personalSubscriptions.append(newSubscription)
                }
            )
        }
        .sheet(isPresented: $showingFilterSheet) {
            SubscriptionsFilterSheet(
                selectedFilter: $selectedFilter,
                showingFilterSheet: $showingFilterSheet
            )
        }
        .sheet(isPresented: $showingInsightsSheet) {
            SubscriptionInsightsSheet(
                subscriptions: personalSubscriptions,
                showingInsightsSheet: $showingInsightsSheet
            )
        }
        .sheet(isPresented: $showingRenewalCalendarSheet) {
            RenewalCalendarSheet(
                subscriptions: personalSubscriptions,
                showingRenewalCalendarSheet: $showingRenewalCalendarSheet
            )
        }
    }
}

struct InsightsView: View {
    var body: some View {
        NavigationView {
            Text("Insights View")
                .navigationTitle("Insights")
        }
    }
}

// MARK: - People List View
struct PeopleListView: View {
    @Binding var people: [Person]
    @State private var searchText = ""
    
    var filteredPeople: [Person] {
        if searchText.isEmpty {
            return people
        }
        return people.filter { person in
            person.name.localizedCaseInsensitiveContains(searchText) ||
            person.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wiseSecondaryText)
                    .font(.system(size: 16))
                
                TextField("Search people...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.wiseSecondaryText)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // People List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredPeople) { person in
                        PersonRowView(person: person)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Person Row View
struct PersonRowView: View {
    let person: Person
    
    // Computed properties for balance display
    private var balanceColor: Color {
        if person.balance > 0 {
            return .wiseBrightGreen // They owe me money - green
        } else if person.balance < 0 {
            return .wiseError // I owe them money - red
        } else {
            return .wiseForestGreen // No one owes anything - dark green
        }
    }
    
    private var balanceText: String {
        if person.balance > 0 {
            return "owes you"
        } else if person.balance < 0 {
            return "you owe"
        } else {
            return "settled up"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar - Using new AvatarView component
            AvatarView(person: person, size: .large, style: .gradient)

            // Person Details
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Text(person.email)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", abs(person.balance)))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(balanceColor)
                
                Text(balanceText)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Groups List View
struct GroupsListView: View {
    @Binding var groups: [Group]
    let people: [Person]
    @State private var searchText = ""
    
    var filteredGroups: [Group] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wiseSecondaryText)
                    .font(.system(size: 16))
                
                TextField("Search groups...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.wiseSecondaryText)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Groups List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredGroups) { group in
                        GroupRowView(group: group, people: people)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Group Row View
struct GroupRowView: View {
    let group: Group
    let people: [Person]
    
    var memberNames: String {
        let names = group.members.compactMap { memberID in
            people.first { $0.id == memberID }?.name
        }
        return names.prefix(3).joined(separator: ", ") + (names.count > 3 ? " +\(names.count - 3)" : "")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Group Emoji
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.wiseBlue.opacity(0.2), Color.wiseBlue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(group.emoji)
                        .font(.system(size: 24))
                )
            
            // Group Details
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Text(memberNames)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                
                Text("\(group.expenses.count) expenses")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            // Total Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", group.totalAmount))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("total")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Avatar Picker Sheet

struct AvatarPickerSheet: View {
    @Binding var selectedAvatarType: AvatarType
    @Binding var isPresented: Bool
    let personName: String  // For generating initials

    @State private var selectedTab = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedEmoji = "👨🏻‍💼"
    @State private var selectedColorIndex = 0
    @State private var isProcessingImage = false

    // Expanded emoji list with diverse options
    private let availableEmojis = [
        "👨🏻‍💼", "👩🏻‍💼", "👨🏼‍💼", "👩🏼‍💼", "👨🏽‍💼", "👩🏽‍💼",
        "👨🏾‍💼", "👩🏾‍💼", "👨🏿‍💼", "👩🏿‍💼", "🧑🏻‍💻", "🧑🏼‍💻",
        "🧑🏽‍💻", "🧑🏾‍💻", "🧑🏿‍💻", "👨🏻‍🎓", "👩🏻‍🎓", "👨🏼‍🎓",
        "👩🏼‍🎓", "👨🏽‍🎓", "👩🏽‍🎓", "👨🏾‍🎓", "👩🏾‍🎓", "👨🏿‍🎓",
        "👩🏿‍🎓", "🧑🏻‍🎨", "🧑🏼‍🎨", "🧑🏽‍🎨", "🧑🏾‍🎨", "🧑🏿‍🎨",
        "👨🏻‍⚕️", "👩🏻‍⚕️", "👨🏼‍⚕️", "👩🏼‍⚕️", "👨🏽‍⚕️", "👩🏽‍⚕️",
        "😊", "😎", "🤓", "😇", "🥳", "🤗", "😍", "🤩", "😺", "🐶",
        "🦊", "🐼", "🦁", "🐯", "🐸", "🐙", "🦋", "🌸", "⭐️", "🔥"
    ]

    private var previewAvatarType: AvatarType {
        switch selectedTab {
        case 0: // Photo
            if case .photo(let data) = selectedAvatarType, selectedPhotoItem == nil {
                return .photo(data)
            }
            return .initials(AvatarGenerator.generateInitials(from: personName), colorIndex: 0)
        case 1: // Emoji
            return .emoji(selectedEmoji)
        case 2: // Initials
            return .initials(AvatarGenerator.generateInitials(from: personName), colorIndex: selectedColorIndex)
        default:
            return .emoji("👤")
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Preview Section
                VStack(spacing: 16) {
                    ZStack {
                        // Preview avatar
                        AvatarView(avatarType: previewAvatarType, size: .xlarge, style: .solid)

                        // Loading overlay
                        if isProcessingImage {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 64, height: 64)

                            ProgressView()
                                .tint(.white)
                        }
                    }

                    Text("Choose Your Avatar")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .background(Color.wiseBorder.opacity(0.3))

                // Tab Selector
                Picker("Avatar Source", selection: $selectedTab) {
                    Label("Photo", systemImage: "photo").tag(0)
                    Label("Emoji", systemImage: "face.smiling").tag(1)
                    Label("Initials", systemImage: "textformat").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Photo Tab
                    photoPickerView.tag(0)

                    // Emoji Tab
                    emojiGridView.tag(1)

                    // Initials Tab
                    initialsBuilderView.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Select Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAvatar()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.wiseForestGreen)
                    )
                    .disabled(isProcessingImage)
                }
            }
        }
    }

    // MARK: - Photo Picker View
    private var photoPickerView: some View {
        VStack(spacing: 20) {
            Spacer()

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseForestGreen)

                    Text("Choose from Photos")
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)

                    Text("Select any photo or saved Memoji from your library")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.wiseBrightGreen.opacity(0.1))
                        .stroke(Color.wiseBrightGreen.opacity(0.3), lineWidth: 2)
                        .shadow(color: .wiseBrightGreen.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 20)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    await loadPhoto(from: newValue)
                }
            }

            Spacer()
        }
    }

    // MARK: - Emoji Grid View
    private var emojiGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    Button(action: { selectedEmoji = emoji }) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.3))
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedEmoji == emoji ? Color.wiseForestGreen : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Initials Builder View
    private var initialsBuilderView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Show generated initials
            VStack(spacing: 12) {
                Text("Your Initials")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)

                Text(AvatarGenerator.generateInitials(from: personName))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.wisePrimaryText)
            }

            // Color selection
            VStack(spacing: 12) {
                Text("Choose Color")
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: 16) {
                    ForEach(0..<AvatarColorPalette.colors.count, id: \.self) { index in
                        Button(action: { selectedColorIndex = index }) {
                            Circle()
                                .fill(AvatarColorPalette.color(for: index))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColorIndex == index ? Color.wisePrimaryText : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .shadow(
                                    color: selectedColorIndex == index ? Color.black.opacity(0.2) : Color.clear,
                                    radius: 4, x: 0, y: 2
                                )
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Methods
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isProcessingImage = true
        defer { isProcessingImage = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let processedData = AvatarGenerator.processImage(uiImage) {
                selectedAvatarType = .photo(processedData)
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    private func saveAvatar() {
        switch selectedTab {
        case 0: // Photo - already set in loadPhoto
            break
        case 1: // Emoji
            selectedAvatarType = .emoji(selectedEmoji)
        case 2: // Initials
            selectedAvatarType = .initials(
                AvatarGenerator.generateInitials(from: personName),
                colorIndex: selectedColorIndex
            )
        default:
            break
        }

        isPresented = false
    }
}

// MARK: - Add Person Sheet
struct AddPersonSheet: View {
    @Binding var showingAddPersonSheet: Bool
    let onPersonAdded: (Person) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedAvatarType: AvatarType = .initials("", colorIndex: 0)
    @State private var showingAvatarPicker = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Auto-update initials when name changes
    private var currentInitials: String {
        AvatarGenerator.generateInitials(from: name)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Avatar")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Button(action: { showingAvatarPicker = true }) {
                            HStack(spacing: 16) {
                                // Show current avatar or default initials
                                if case .initials = selectedAvatarType, !currentInitials.isEmpty {
                                    AvatarView(
                                        avatarType: .initials(currentInitials, colorIndex: AvatarColorPalette.colorIndex(for: name)),
                                        size: .large,
                                        style: .solid
                                    )
                                } else {
                                    AvatarView(avatarType: selectedAvatarType, size: .large, style: .solid)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choose Avatar")
                                        .font(.spotifyHeadingSmall)
                                        .foregroundColor(.wisePrimaryText)

                                    Text("Select photo, emoji, or use initials")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.3))
                            )
                        }
                    }

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., John Smith", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: name) { oldValue, newValue in
                                    // Auto-generate initials avatar as default
                                    if case .initials = selectedAvatarType, !newValue.isEmpty {
                                        selectedAvatarType = .initials(
                                            AvatarGenerator.generateInitials(from: newValue),
                                            colorIndex: AvatarColorPalette.colorIndex(for: newValue)
                                        )
                                    } else if case .initials = selectedAvatarType {
                                        selectedAvatarType = .initials("", colorIndex: 0)
                                    }
                                }
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., john@example.com", text: $email)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Phone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., +1 234 567 8900", text: $phone)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.phonePad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddPersonSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPerson()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerSheet(
                    selectedAvatarType: $selectedAvatarType,
                    isPresented: $showingAvatarPicker,
                    personName: name.isEmpty ? "User" : name
                )
            }
        }
        .onAppear {
            // Initialize with initials avatar
            if !name.isEmpty {
                selectedAvatarType = .initials(
                    AvatarGenerator.generateInitials(from: name),
                    colorIndex: AvatarColorPalette.colorIndex(for: name)
                )
            }
        }
    }

    private func addPerson() {
        // Ensure we have the latest initials if still using initials avatar
        var finalAvatarType = selectedAvatarType
        if case .initials = selectedAvatarType {
            finalAvatarType = .initials(
                AvatarGenerator.generateInitials(from: name),
                colorIndex: AvatarColorPalette.colorIndex(for: name)
            )
        }

        let newPerson = Person(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            avatarType: finalAvatarType
        )

        onPersonAdded(newPerson)
        showingAddPersonSheet = false
    }
}

// MARK: - Add Group Sheet
struct AddGroupSheet: View {
    @Binding var showingAddGroupSheet: Bool
    let people: [Person]
    let onGroupAdded: (Group) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedEmoji = "👥"
    @State private var selectedMembers: Set<UUID> = []
    
    // Group emoji options that work well with Memoji people
    let availableEmojis = ["👥", "🏖️", "🏠", "💼", "🎉", "🍕", "✈️", "🏃‍♂️", "📚", "🎵", "🎮", "⚽", "🍽️", "🏛️", "🎭", "🎪", "🎨", "📱"]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedMembers.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Emoji Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Emoji")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Button(action: { selectedEmoji = emoji }) {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedEmoji == emoji ? Color.wiseBlue.opacity(0.2) : Color.wiseBorder.opacity(0.5))
                                                .stroke(selectedEmoji == emoji ? Color.wiseBlue : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Group Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., Weekend Trip", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., Beach vacation with friends", text: $description)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                    }
                    
                    // Members Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Members *")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        VStack(spacing: 8) {
                            ForEach(people) { person in
                                Button(action: {
                                    if selectedMembers.contains(person.id) {
                                        selectedMembers.remove(person.id)
                                    } else {
                                        selectedMembers.insert(person.id)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        // Avatar - Using new AvatarView component
                                        AvatarView(person: person, size: .medium, style: .solid)
                                        
                                        // Person Details
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(person.name)
                                                .font(.spotifyBodyMedium)
                                                .foregroundColor(.wisePrimaryText)
                                            
                                            Text(person.email)
                                                .font(.spotifyBodySmall)
                                                .foregroundColor(.wiseSecondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        // Selection Indicator
                                        Image(systemName: selectedMembers.contains(person.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(selectedMembers.contains(person.id) ? .wiseBrightGreen : .wiseSecondaryText)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedMembers.contains(person.id) ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseBorder.opacity(0.5))
                                            .stroke(selectedMembers.contains(person.id) ? Color.wiseBrightGreen : Color.wiseBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddGroupSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        addGroup()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func addGroup() {
        let newGroup = Group(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            emoji: selectedEmoji,
            members: Array(selectedMembers)
        )
        
        onGroupAdded(newGroup)
        showingAddGroupSheet = false
    }
}

// MARK: - Subscriptions Filter Sheet  
struct SubscriptionsFilterSheet: View {
    @Binding var selectedFilter: SubscriptionFilter
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(SubscriptionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        showingFilterSheet = false
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.wiseForestGreen)
                                .frame(width: 24)
                            
                            Text(filter.rawValue)
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.wiseBrightGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Filter Subscriptions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - Enhanced Subscriptions Header Section
struct SubscriptionsHeaderSectionEnhanced: View {
    @Binding var selectedTab: SubscriptionsView.SubscriptionsTab
    @Binding var showingAddSubscriptionSheet: Bool
    @Binding var showingInsightsSheet: Bool
    @Binding var showingRenewalCalendarSheet: Bool
    let totalMonthlySpend: Double
    let totalAnnualSpend: Double
    let nextBillingDate: Date?
    let upcomingBillsCount: Int
    
    @State private var isAddButtonPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Header
            HStack {
                Text("Subscriptions")
                    .font(.spotifyDisplayLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Spacer()
                
                // Add Subscription Button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showingAddSubscriptionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add")
                            .font(.spotifyLabelLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                isAddButtonPressed ? Color(red: 0.066, green: 0.180, blue: 0.0) : .wiseForestGreen,
                                isAddButtonPressed ? Color(red: 0.086, green: 0.200, blue: 0.0) : Color(red: 0.106, green: 0.220, blue: 0.020)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .wiseForestGreen.opacity(isAddButtonPressed ? 0.4 : 0.3), radius: isAddButtonPressed ? 6 : 4, x: 0, y: isAddButtonPressed ? 3 : 2)
                }
                .scaleEffect(isAddButtonPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isAddButtonPressed)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    isAddButtonPressed = pressing
                }, perform: {})
            }
            .padding(.horizontal, 16)
            
            // Segmented Control
            HStack(spacing: 0) {
                ForEach(SubscriptionsView.SubscriptionsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.spotifyLabelLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .wiseBodyText)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTab == tab ? Color.wiseForestGreen : Color.clear)
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Subscription Quick Stats View
struct SubscriptionQuickStatsView: View {
    let subscriptions: [Subscription]
    let sharedSubscriptions: [SharedSubscription]
    
    var totalMonthlySpend: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyEquivalent }
    }
    
    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            // Monthly Spend Card
            FinancialCard(
                icon: "calendar.circle.fill",
                iconColor: .wiseBrightGreen,
                title: "MONTHLY",
                amount: String(format: "$%.1f", totalMonthlySpend)
            )
            
            // Annual Spend Card  
            FinancialCard(
                icon: "calendar.badge.plus",
                iconColor: .wiseBlue,
                title: "ANNUAL",
                amount: String(format: "$%.0f", totalAnnualSpend)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Subscription Stat Card
struct SubscriptionStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let isAmount: Bool
    let isCount: Bool
    
    init(title: String, amount: Double, icon: String, color: Color, isAmount: Bool = false, isCount: Bool = false) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.isAmount = isAmount
        self.isCount = isCount
    }
    
    var formattedAmount: String {
        if isCount {
            return String(Int(amount))
        } else if isAmount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.maximumFractionDigits = amount >= 1000 ? 0 : 2
            return formatter.string(from: NSNumber(value: amount)) ?? "$0"
        }
        return String(format: "%.2f", amount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(formattedAmount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(width: 110, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Subscriptions Category Filter Section
struct SubscriptionsCategoryFilterSection: View {
    @Binding var selectedCategory: SubscriptionCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories Button
                Button(action: { selectedCategory = nil }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(selectedCategory == nil ? .white : .wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedCategory == nil ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                }
                
                // Category Pills
                ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                    Button(action: { 
                        selectedCategory = selectedCategory == category ? nil : category 
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(category.color)
                            Text(category.rawValue)
                                .font(.spotifyLabelSmall)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .wisePrimaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color : Color.wiseBorder)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Enhanced Personal Subscriptions View
struct EnhancedPersonalSubscriptionsView: View {
    let subscriptions: [Subscription]
    @Binding var searchText: String
    @Binding var selectedFilter: SubscriptionFilter
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            HStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.wiseSecondaryText)
                        .font(.system(size: 16))
                    
                    TextField("Search subscriptions...", text: $searchText)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.wiseSecondaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseBorder.opacity(0.5))
                )
                
                // Filter Button
                Button(action: { showingFilterSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedFilter.icon)
                            .font(.system(size: 14))
                        Text(selectedFilter == .all ? "All" : selectedFilter.rawValue)
                            .font(.spotifyLabelSmall)
                    }
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedFilter == .all ? Color.wiseBorder.opacity(0.5) : Color.wiseForestGreen.opacity(0.1))
                            .stroke(selectedFilter == .all ? Color.clear : Color.wiseForestGreen, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Subscriptions List
            if subscriptions.isEmpty {
                EmptySubscriptionsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(subscriptions) { subscription in
                            EnhancedSubscriptionRowView(subscription: subscription)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Enhanced Subscription Row View
struct EnhancedSubscriptionRowView: View {
    let subscription: Subscription
    @State private var showingDetails = false
    
    var statusColor: Color {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return .wiseError
            } else {
                return Color.orange
            }
        }
        return .wiseBrightGreen
    }
    
    var statusText: String {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return "Cancelled"
            } else {
                return "Paused"
            }
        }
        return "Active"
    }
    
    var nextBillingText: String {
        if subscription.billingCycle == .lifetime {
            return "Lifetime"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: subscription.nextBillingDate, relativeTo: Date())
    }
    
    var isExpiringSoon: Bool {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return subscription.isActive && subscription.nextBillingDate <= nextWeek
    }
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack(spacing: 16) {
                // App Icon with better styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: subscription.color).opacity(0.2), Color(hex: subscription.color).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: subscription.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: subscription.color))
                    
                    // Status indicator
                    if isExpiringSoon {
                        Circle()
                            .fill(Color.wiseError)
                            .frame(width: 12, height: 12)
                            .offset(x: 18, y: -18)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 12, height: 12)
                                    .offset(x: 18, y: -18)
                            )
                    }
                }
                
                // Subscription Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(subscription.name)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                        
                        Spacer()
                        
                        // Status Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(statusText)
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(statusColor)
                        }
                    }
                    
                    Text(subscription.description)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                    
                    HStack {
                        // Category tag
                        HStack(spacing: 4) {
                            Image(systemName: subscription.category.icon)
                                .font(.system(size: 10))
                                .foregroundColor(subscription.category.color)
                            
                            Text(subscription.category.rawValue)
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(subscription.category.color.opacity(0.1))
                        )
                        
                        Spacer()
                        
                        // Next billing with better formatting
                        if subscription.isActive {
                            Text(nextBillingText)
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(isExpiringSoon ? .wiseError : .wiseSecondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Price with enhanced styling
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", subscription.price))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                    
                    Text("/\(subscription.billingCycle.shortName)")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                    
                    if subscription.isShared {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.wiseBlue)
                            
                            Text("Shared")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseBlue)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.wiseBlue.opacity(0.1))
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isExpiringSoon ? Color.wiseError.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Extension for Hex Support

// MARK: - Subscription Row View
struct SubscriptionRowView: View {
    let subscription: Subscription
    @State private var showingDetails = false
    
    var statusColor: Color {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return .wiseError
            } else {
                return Color.orange
            }
        }
        return .wiseBrightGreen
    }
    
    var statusText: String {
        if !subscription.isActive {
            if subscription.cancellationDate != nil {
                return "Cancelled"
            } else {
                return "Paused"
            }
        }
        return "Active"
    }
    
    var nextBillingText: String {
        if subscription.billingCycle == .lifetime {
            return "Lifetime"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Next: \(formatter.string(from: subscription.nextBillingDate))"
    }
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack(spacing: 16) {
                // App Icon
                Circle()
                    .fill(Color(hex: subscription.color).opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: subscription.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: subscription.color))
                    )
                
                // Subscription Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(subscription.name)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                        
                        Spacer()
                        
                        // Status Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(statusText)
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    
                    Text(subscription.description)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                    
                    HStack {
                        // Category
                        HStack(spacing: 4) {
                            Image(systemName: subscription.category.icon)
                                .font(.system(size: 12))
                                .foregroundColor(subscription.category.color)
                            
                            Text(subscription.category.rawValue)
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        
                        Spacer()
                        
                        // Next billing
                        Text(nextBillingText)
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", subscription.price))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                    
                    Text("/\(subscription.billingCycle.shortName)")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                    
                    if subscription.isShared {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.wiseBlue)
                            
                            Text("Shared")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseBlue)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Subscriptions View
struct EmptySubscriptionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Subscriptions Yet")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("Add your first subscription to start tracking your monthly expenses")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Enhanced Shared Subscriptions View
struct EnhancedSharedSubscriptionsView: View {
    @Binding var sharedSubscriptions: [SharedSubscription]
    @Binding var searchText: String
    let people: [Person]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wiseSecondaryText)
                    .font(.system(size: 16))
                
                TextField("Search shared subscriptions...", text: $searchText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.wiseSecondaryText)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseBorder.opacity(0.5))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Shared Subscriptions List
            if sharedSubscriptions.isEmpty {
                EmptySharedSubscriptionsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sharedSubscriptions) { sharedSub in
                            EnhancedSharedSubscriptionRowView(
                                sharedSubscription: sharedSub,
                                people: people
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Enhanced Shared Subscription Row View
struct EnhancedSharedSubscriptionRowView: View {
    let sharedSubscription: SharedSubscription
    let people: [Person]
    
    var sharedByPerson: Person? {
        people.first { $0.id == sharedSubscription.sharedBy }
    }
    
    var sharedWithPeople: [Person] {
        sharedSubscription.sharedWith.compactMap { id in
            people.first { $0.id == id }
        }
    }
    
    var statusColor: Color {
        sharedSubscription.isAccepted ? .wiseBrightGreen : Color.orange
    }
    
    var statusText: String {
        sharedSubscription.isAccepted ? "Accepted" : "Pending"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Shared subscription icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.wiseBlue.opacity(0.2), Color.wiseBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.wiseBlue)
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .offset(x: 18, y: -18)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .offset(x: 18, y: -18)
                    )
            }
            
            // Subscription Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sharedSubscription.notes.isEmpty ? "Shared Subscription" : sharedSubscription.notes)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                    
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(statusColor)
                    }
                }
                
                if let sharedBy = sharedByPerson {
                    Text("Shared by \(sharedBy.name)")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
                
                HStack {
                    // Shared with avatars
                    HStack(spacing: -8) {
                        ForEach(sharedWithPeople.prefix(3), id: \.id) { person in
                            AvatarView(person: person, size: .small, style: .bordered)
                        }
                        
                        if sharedWithPeople.count > 3 {
                            Text("+\(sharedWithPeople.count - 3)")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.wiseBorder)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Split type
                    Text(sharedSubscription.costSplit.rawValue)
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.wiseBorder.opacity(0.5))
                        )
                }
            }
            
            Spacer()
            
            // Individual Cost
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", sharedSubscription.individualCost))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("your share")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(!sharedSubscription.isAccepted ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Empty Shared Subscriptions View
struct EmptySharedSubscriptionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Shared Subscriptions")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("Share your subscriptions with friends and family to split costs")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Shared Subscription Row View
struct SharedSubscriptionRowView: View {
    let sharedSubscription: SharedSubscription
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder for shared subscription content
            Circle()
                .fill(Color.wiseBlue.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.wiseBlue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Shared Subscription")
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                
                Text("Split with friends")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            Text("$0.00")
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Enhanced Add Subscription Sheet
struct EnhancedAddSubscriptionSheet: View {
    @Binding var showingAddSubscriptionSheet: Bool
    let onSubscriptionAdded: (Subscription) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var selectedBillingCycle: BillingCycle = .monthly
    @State private var selectedCategory: SubscriptionCategory = .other
    @State private var selectedIcon = "app.fill"
    @State private var selectedColor = "#007AFF"
    @State private var isShared = false
    @State private var selectedPaymentMethod: PaymentMethod = .creditCard
    @State private var website = ""
    @State private var notes = ""
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    let availableIcons = [
        "app.fill", "tv.fill", "music.note", "camera.fill", "icloud.fill",
        "paintbrush.fill", "doc.text.fill", "brain.head.profile", "gamecontroller.fill",
        "newspaper.fill", "creditcard.fill", "car.fill", "house.fill",
        "heart.fill", "graduationcap.fill", "wrench.and.screwdriver.fill"
    ]
    
    let availableColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#5AC8FA", "#AF52DE", "#FF2D92", "#A2845E", "#8E8E93",
        "#E50914", "#1DB954", "#FF0000", "#181717", "#FF7262",
        "#113CCF", "#000000", "#FF6B35"
    ]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !price.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(price) != nil && Double(price)! > 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Visual Preview
                    VStack(spacing: 16) {
                        Text("Preview")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Subscription Preview Card
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(Color(hex: selectedColor))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name.isEmpty ? "Subscription Name" : name)
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text(description.isEmpty ? "Description" : description)
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                                    .lineLimit(1)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: selectedCategory.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(selectedCategory.color)
                                    
                                    Text(selectedCategory.rawValue)
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(price.isEmpty ? "$0.00" : "$\(price)")
                                    .font(.spotifyNumberMedium)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("/\(selectedBillingCycle.shortName)")
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Service Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., Netflix", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., Premium streaming plan", text: $description)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Price and Billing Cycle Row
                        HStack(spacing: 12) {
                            // Price
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Price *")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                
                                TextField("0.00", text: $price)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.wiseBorder.opacity(0.5))
                                            .stroke(Color.wiseBorder, lineWidth: 1)
                                    )
                            }
                            
                            // Billing Cycle
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Billing")
                                    .font(.spotifyLabelMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                
                                Picker("Billing Cycle", selection: $selectedBillingCycle) {
                                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                        Text(cycle.rawValue).tag(cycle)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Appearance
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: { selectedIcon = icon }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .wiseSecondaryText)
                                            .frame(width: 32, height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.1) : Color.wiseBorder.opacity(0.5))
                                                    .stroke(selectedIcon == icon ? Color(hex: selectedColor) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                                ForEach(availableColors, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == color ? Color.wisePrimaryText : Color.clear, lineWidth: 2)
                                                    .frame(width: 32, height: 32)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(category.color)
                                        
                                        Text(category.rawValue)
                                            .font(.spotifyBodySmall)
                                            .foregroundColor(.wisePrimaryText)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.wiseBorder.opacity(0.5))
                                            .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Additional Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Options")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                        
                        // Payment Method
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Payment Method")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            Picker("Payment Method", selection: $selectedPaymentMethod) {
                                ForEach(PaymentMethod.allCases, id: \.self) { method in
                                    HStack {
                                        Image(systemName: method.icon)
                                        Text(method.rawValue)
                                    }.tag(method)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                        }
                        
                        // Website
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Website")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("e.g., netflix.com", text: $website)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                        
                        // Shared Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shared Subscription")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("Share with friends and family")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isShared)
                                .tint(.wiseBrightGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            
                            TextField("Additional notes...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddSubscriptionSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSubscription()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func addSubscription() {
        guard let priceValue = Double(price) else { return }
        
        var newSubscription = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: priceValue,
            billingCycle: selectedBillingCycle,
            category: selectedCategory,
            icon: selectedIcon,
            color: selectedColor
        )
        
        newSubscription.isShared = isShared
        newSubscription.paymentMethod = selectedPaymentMethod
        newSubscription.website = website.isEmpty ? nil : website.trimmingCharacters(in: .whitespaces)
        newSubscription.notes = notes.trimmingCharacters(in: .whitespaces)
        
        onSubscriptionAdded(newSubscription)
        showingAddSubscriptionSheet = false
    }
}

// MARK: - Subscription Insights Sheet
struct SubscriptionInsightsSheet: View {
    let subscriptions: [Subscription]
    @Binding var showingInsightsSheet: Bool
    
    var totalMonthlySpend: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyEquivalent }
    }
    
    var totalAnnualSpend: Double {
        totalMonthlySpend * 12
    }
    
    var averageSubscriptionCost: Double {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        guard !activeSubscriptions.isEmpty else { return 0 }
        return totalMonthlySpend / Double(activeSubscriptions.count)
    }
    
    var categoryBreakdown: [(category: SubscriptionCategory, amount: Double, count: Int)] {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        let grouped = Dictionary(grouping: activeSubscriptions) { $0.category }
        return grouped.map { (category, subs) in
            let totalAmount = subs.reduce(0) { $0 + $1.monthlyEquivalent }
            return (category: category, amount: totalAmount, count: subs.count)
        }.sorted { $0.amount > $1.amount }
    }
    
    var mostExpensiveSubscription: Subscription? {
        subscriptions.filter { $0.isActive }.max { $0.monthlyEquivalent < $1.monthlyEquivalent }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            InsightStatCard(
                                title: "Monthly Spend",
                                value: String(format: "$%.2f", totalMonthlySpend),
                                icon: "calendar.circle.fill",
                                color: .wiseBrightGreen
                            )
                            
                            InsightStatCard(
                                title: "Annual Spend",
                                value: String(format: "$%.0f", totalAnnualSpend),
                                icon: "calendar.badge.plus",
                                color: .wiseBlue
                            )
                            
                            InsightStatCard(
                                title: "Active Subscriptions",
                                value: "\(subscriptions.filter { $0.isActive }.count)",
                                icon: "checkmark.circle.fill",
                                color: .wiseBrightGreen
                            )
                            
                            InsightStatCard(
                                title: "Average Cost",
                                value: String(format: "$%.2f", averageSubscriptionCost),
                                icon: "chart.bar.fill",
                                color: .wiseError
                            )
                        }
                    }
                    
                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending by Category")
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)
                        
                        VStack(spacing: 12) {
                            ForEach(categoryBreakdown, id: \.category) { item in
                                CategoryBreakdownRow(
                                    category: item.category,
                                    amount: item.amount,
                                    count: item.count,
                                    percentage: totalMonthlySpend > 0 ? (item.amount / totalMonthlySpend) : 0
                                )
                            }
                        }
                    }
                    
                    // Most Expensive
                    if let mostExpensive = mostExpensiveSubscription {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Highest Cost")
                                .font(.spotifyHeadingLarge)
                                .foregroundColor(.wisePrimaryText)
                            
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color(hex: mostExpensive.color).opacity(0.1))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: mostExpensive.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(Color(hex: mostExpensive.color))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mostExpensive.name)
                                        .font(.spotifyBodyLarge)
                                        .foregroundColor(.wisePrimaryText)
                                    
                                    Text("Your most expensive subscription")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(String(format: "$%.2f", mostExpensive.monthlyEquivalent))
                                        .font(.spotifyNumberMedium)
                                        .foregroundColor(.wiseError)
                                    
                                    Text("per month")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                            )
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Subscription Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingInsightsSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Insight Stat Card
struct InsightStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)
            
            Text(value)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let category: SubscriptionCategory
    let amount: Double
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(category.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text("\(count) subscription\(count == 1 ? "" : "s")")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", amount))
                    .font(.spotifyNumberSmall)
                    .foregroundColor(.wisePrimaryText)
                
                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(category.color)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Renewal Calendar Sheet
struct RenewalCalendarSheet: View {
    let subscriptions: [Subscription]
    @Binding var showingRenewalCalendarSheet: Bool
    
    var upcomingRenewals: [(date: Date, subscriptions: [Subscription])] {
        let activeSubscriptions = subscriptions.filter { $0.isActive && $0.billingCycle != .lifetime }
        let grouped = Dictionary(grouping: activeSubscriptions) { subscription in
            Calendar.current.startOfDay(for: subscription.nextBillingDate)
        }
        
        return grouped
            .map { (date: $0.key, subscriptions: $0.value) }
            .sorted { $0.date < $1.date }
            .prefix(30)
            .map { $0 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if upcomingRenewals.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 64))
                                .foregroundColor(.wiseSecondaryText.opacity(0.5))
                            
                            VStack(spacing: 8) {
                                Text("No Upcoming Renewals")
                                    .font(.spotifyHeadingMedium)
                                    .foregroundColor(.wisePrimaryText)
                                
                                Text("All your subscriptions are up to date")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(upcomingRenewals, id: \.date) { renewalGroup in
                            RenewalDateSection(
                                date: renewalGroup.date,
                                subscriptions: renewalGroup.subscriptions
                            )
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Renewal Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingRenewalCalendarSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// MARK: - Renewal Date Section
struct RenewalDateSection: View {
    let date: Date
    let subscriptions: [Subscription]
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isWithinWeek: Bool {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return date <= nextWeek
    }
    
    private var totalAmount: Double {
        subscriptions.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date, style: .date)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(isToday ? .wiseError : .wisePrimaryText)
                    
                    Text(date, style: .relative)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", totalAmount))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(isWithinWeek ? .wiseError : .wisePrimaryText)
                    
                    Text("\(subscriptions.count) renewal\(subscriptions.count == 1 ? "" : "s")")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            
            // Subscriptions List
            VStack(spacing: 8) {
                ForEach(subscriptions) { subscription in
                    RenewalSubscriptionRow(subscription: subscription)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWithinWeek ? Color.wiseError.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Renewal Subscription Row
struct RenewalSubscriptionRow: View {
    let subscription: Subscription
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: subscription.color))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                
                Text(subscription.billingCycle.rawValue)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", subscription.price))
                .font(.spotifyNumberSmall)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.vertical, 4)
    }
}
