//
//  HelpView.swift
//  Swiff IOS
//
//  Created for Agent 16: Polish & Launch Preparation
//  In-app help center with searchable topics
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil

    var body: some View {
        NavigationView {
            List {
                // Search Bar
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.wiseSecondaryText)
                        TextField("Search help topics...", text: $searchText)
                            .font(.spotifyBodyMedium)
                    }
                    .padding(.vertical, 8)
                }

                // Quick Links
                if searchText.isEmpty {
                    Section {
                        QuickHelpLink(
                            icon: "play.circle.fill",
                            title: "Getting Started",
                            subtitle: "New to Swiff? Start here",
                            color: .wiseForestGreen
                        ) {
                            selectedCategory = .gettingStarted
                        }

                        QuickHelpLink(
                            icon: "dollarsign.circle.fill",
                            title: "Managing Subscriptions",
                            subtitle: "Track, edit, and organize",
                            color: .wiseBlue
                        ) {
                            selectedCategory = .subscriptions
                        }

                        QuickHelpLink(
                            icon: "bell.fill",
                            title: "Notifications & Reminders",
                            subtitle: "Never miss a payment",
                            color: .orange
                        ) {
                            selectedCategory = .notifications
                        }

                        QuickHelpLink(
                            icon: "person.2.fill",
                            title: "Sharing & People",
                            subtitle: "Split costs with friends",
                            color: .purple
                        ) {
                            selectedCategory = .sharing
                        }

                        QuickHelpLink(
                            icon: "chart.bar.fill",
                            title: "Analytics & Insights",
                            subtitle: "Understand your spending",
                            color: .wiseForestGreen
                        ) {
                            selectedCategory = .analytics
                        }

                        QuickHelpLink(
                            icon: "lock.shield.fill",
                            title: "Privacy & Security",
                            subtitle: "Your data, your control",
                            color: .red
                        ) {
                            selectedCategory = .privacy
                        }

                        QuickHelpLink(
                            icon: "arrow.down.doc.fill",
                            title: "Backup & Restore",
                            subtitle: "Keep your data safe",
                            color: .wiseBlue
                        ) {
                            selectedCategory = .backup
                        }

                        QuickHelpLink(
                            icon: "wrench.fill",
                            title: "Troubleshooting",
                            subtitle: "Fix common issues",
                            color: .orange
                        ) {
                            selectedCategory = .troubleshooting
                        }
                    } header: {
                        Text("Help Topics")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    // FAQ Section
                    Section {
                        NavigationLink(destination: FAQListView()) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.wiseBlue)
                                Text("Frequently Asked Questions")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }
                    }

                    // Contact Support
                    Section {
                        Button(action: openSupportEmail) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.wiseForestGreen)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Contact Support")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Text("support@swiffapp.com")
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                Spacer()
                            }
                        }

                        Link(destination: URL(string: "https://www.swiffapp.com")!) {
                            HStack {
                                Image(systemName: "safari.fill")
                                    .foregroundColor(.wiseBlue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Visit Website")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Text("www.swiffapp.com")
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Support")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                } else {
                    // Search Results
                    Section {
                        ForEach(filteredTopics, id: \.id) { topic in
                            Button(action: {
                                selectedCategory = topic.category
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(topic.title)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Text(topic.preview)
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        if filteredTopics.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.wiseSecondaryText)
                                Text("No results found")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                Text("Try different keywords")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    } header: {
                        Text("Search Results")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.wiseBackground.ignoresSafeArea())
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
            .sheet(item: $selectedCategory) { category in
                HelpDetailView(category: category)
            }
        }
    }

    var filteredTopics: [HelpTopic] {
        if searchText.isEmpty {
            return []
        }

        let lowercasedSearch = searchText.lowercased()
        return HelpTopic.allTopics.filter { topic in
            topic.title.lowercased().contains(lowercasedSearch) ||
            topic.keywords.contains(where: { $0.lowercased().contains(lowercasedSearch) }) ||
            topic.preview.lowercased().contains(lowercasedSearch)
        }
    }

    func openSupportEmail() {
        if let url = URL(string: "mailto:support@swiffapp.com?subject=Swiff Support Request") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Quick Help Link

struct QuickHelpLink: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text(subtitle)
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Help Category

enum HelpCategory: String, Identifiable, CaseIterable {
    case gettingStarted = "Getting Started"
    case subscriptions = "Subscriptions"
    case notifications = "Notifications"
    case sharing = "Sharing & People"
    case analytics = "Analytics"
    case privacy = "Privacy & Security"
    case backup = "Backup & Restore"
    case troubleshooting = "Troubleshooting"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gettingStarted: return "play.circle.fill"
        case .subscriptions: return "dollarsign.circle.fill"
        case .notifications: return "bell.fill"
        case .sharing: return "person.2.fill"
        case .analytics: return "chart.bar.fill"
        case .privacy: return "lock.shield.fill"
        case .backup: return "arrow.down.doc.fill"
        case .troubleshooting: return "wrench.fill"
        }
    }

    var color: Color {
        switch self {
        case .gettingStarted: return .wiseForestGreen
        case .subscriptions: return .wiseBlue
        case .notifications: return .orange
        case .sharing: return .purple
        case .analytics: return .wiseForestGreen
        case .privacy: return .red
        case .backup: return .wiseBlue
        case .troubleshooting: return .orange
        }
    }
}

// MARK: - Help Topic Model

struct HelpTopic {
    let id = UUID()
    let category: HelpCategory
    let title: String
    let preview: String
    let keywords: [String]

    static let allTopics: [HelpTopic] = [
        // Getting Started
        HelpTopic(category: .gettingStarted, title: "Adding Your First Subscription", preview: "Learn how to add and track subscriptions", keywords: ["add", "subscription", "create", "new"]),
        HelpTopic(category: .gettingStarted, title: "Understanding the Home Screen", preview: "Overview of financial cards and recent activity", keywords: ["home", "dashboard", "overview"]),
        HelpTopic(category: .gettingStarted, title: "Using Sample Data", preview: "Try Swiff with sample subscriptions", keywords: ["sample", "demo", "test", "trial"]),

        // Subscriptions
        HelpTopic(category: .subscriptions, title: "Editing Subscriptions", preview: "Change price, billing cycle, and other details", keywords: ["edit", "change", "modify", "update"]),
        HelpTopic(category: .subscriptions, title: "Pausing vs Cancelling", preview: "Difference between pause and cancel", keywords: ["pause", "cancel", "stop", "delete"]),
        HelpTopic(category: .subscriptions, title: "Tracking Free Trials", preview: "Set trial end dates and get expiration alerts", keywords: ["trial", "free", "expiration"]),
        HelpTopic(category: .subscriptions, title: "Price History", preview: "View how subscription prices changed over time", keywords: ["price", "history", "increase", "change"]),

        // Notifications
        HelpTopic(category: .notifications, title: "Setting Up Reminders", preview: "Get notified before renewals", keywords: ["reminder", "notification", "alert"]),
        HelpTopic(category: .notifications, title: "Fixing Notification Issues", preview: "Not receiving notifications? Try this", keywords: ["notification", "not working", "fix"]),
        HelpTopic(category: .notifications, title: "Customizing Reminder Times", preview: "Choose when to be reminded", keywords: ["time", "when", "schedule"]),

        // Sharing
        HelpTopic(category: .sharing, title: "Adding People", preview: "Track expenses with friends and family", keywords: ["add", "people", "person", "friend"]),
        HelpTopic(category: .sharing, title: "Splitting Expenses", preview: "Divide costs equally or custom amounts", keywords: ["split", "share", "divide"]),
        HelpTopic(category: .sharing, title: "Settling Balances", preview: "Mark payments as received or paid", keywords: ["settle", "pay", "balance"]),
        HelpTopic(category: .sharing, title: "Requesting Payment", preview: "Send payment requests via message", keywords: ["request", "payment", "ask"]),

        // Analytics
        HelpTopic(category: .analytics, title: "Understanding Charts", preview: "View spending trends and breakdowns", keywords: ["chart", "graph", "analytics"]),
        HelpTopic(category: .analytics, title: "Savings Opportunities", preview: "Find ways to reduce subscription costs", keywords: ["save", "savings", "reduce"]),
        HelpTopic(category: .analytics, title: "Forecasting Spending", preview: "See predicted future expenses", keywords: ["forecast", "predict", "future"]),

        // Privacy
        HelpTopic(category: .privacy, title: "Where is My Data Stored?", preview: "All data stays on your device", keywords: ["data", "storage", "privacy", "security"]),
        HelpTopic(category: .privacy, title: "Does Swiff Collect Data?", preview: "No analytics, no tracking, no servers", keywords: ["collect", "tracking", "analytics"]),
        HelpTopic(category: .privacy, title: "Encrypting Backups", preview: "Protect backups with password encryption", keywords: ["encrypt", "password", "secure"]),

        // Backup
        HelpTopic(category: .backup, title: "Creating a Backup", preview: "Export all your data safely", keywords: ["backup", "export", "save"]),
        HelpTopic(category: .backup, title: "Restoring Data", preview: "Import backup on same or different device", keywords: ["restore", "import", "recover"]),
        HelpTopic(category: .backup, title: "Exporting to CSV", preview: "Open data in Excel or Google Sheets", keywords: ["csv", "excel", "export"]),

        // Troubleshooting
        HelpTopic(category: .troubleshooting, title: "App Keeps Crashing", preview: "Steps to fix crashes and freezes", keywords: ["crash", "freeze", "bug"]),
        HelpTopic(category: .troubleshooting, title: "Data Not Saving", preview: "Fix issues with data persistence", keywords: ["save", "not saving", "lost"]),
        HelpTopic(category: .troubleshooting, title: "Import Fails", preview: "Troubleshoot backup restore errors", keywords: ["import", "fail", "error"]),
        HelpTopic(category: .troubleshooting, title: "Performance Issues", preview: "Make Swiff run faster", keywords: ["slow", "lag", "performance"]),
    ]
}

// MARK: - Help Detail View

struct HelpDetailView: View {
    @Environment(\.dismiss) var dismiss
    let category: HelpCategory

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(category.color)

                        Text(category.rawValue)
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(helpContent(for: category), id: \.title) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.spotifyHeadingMedium)
                                    .foregroundColor(.wisePrimaryText)

                                Text(section.content)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.wiseBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }

    func helpContent(for category: HelpCategory) -> [(title: String, content: String)] {
        // Return category-specific help content
        // This would ideally come from a JSON file or database
        // For now, returning placeholder content
        return getCategoryContent(category)
    }
}

// MARK: - Category Content Helper

func getCategoryContent(_ category: HelpCategory) -> [(title: String, content: String)] {
    switch category {
    case .gettingStarted:
        return [
            ("Welcome to Swiff!", "Swiff helps you track all your subscriptions, manage expenses, and never miss a payment. Whether you have 5 subscriptions or 50, Swiff keeps everything organized beautifully."),
            ("Adding Your First Subscription", "Tap the '+' button at the top right of any screen, select 'Add Subscription', fill in the details (name, price, billing cycle, next renewal date), and tap 'Save'. That's it!"),
            ("Understanding the Home Screen", "The Home screen shows four financial cards: Balance, Subscriptions, Income, and Expenses. Below that is your recent activity feed. Tap any card for more details."),
            ("Using Sample Data", "Want to try Swiff without adding real data? Go to Settings > Data Management > 'Add Sample Data'. Swiff creates 5-10 sample subscriptions for you to explore.")
        ]

    case .subscriptions:
        return [
            ("Managing Subscriptions", "Track unlimited subscriptions across all categories. See total monthly costs, get renewal reminders, and organize everything beautifully."),
            ("Editing Subscriptions", "Tap any subscription to view details, then tap 'Edit' to change price, billing cycle, category, or any other information. Swiff automatically tracks price changes."),
            ("Free Trials", "Toggle 'Free Trial' when adding a subscription. Set the trial end date and enable reminders to get alerted 3 days, 1 day, and on the expiration day."),
            ("Price History", "Swiff automatically saves old prices when you update subscription costs. View the complete price history chart in subscription detail view.")
        ]

    case .notifications:
        return [
            ("Setting Up Reminders", "Open any subscription, tap 'Edit', and configure reminder settings. Choose how many days before renewal you want to be reminded (1, 3, 7, 14, or 30 days)."),
            ("Notification Types", "Swiff sends: Renewal reminders, trial expiration alerts, price increase notifications, and payment reminders. Enable or disable each type in Settings."),
            ("Fixing Issues", "If notifications aren't working: 1) Check iPhone Settings > Notifications > Swiff, 2) Enable 'Allow Notifications', 3) Check Swiff Settings > Enable Notifications, 4) Send a test notification to verify."),
            ("Quiet Hours", "Set quiet hours in Settings to prevent notifications during specific times (e.g., 10 PM to 8 AM).")
        ]

    case .sharing:
        return [
            ("Adding People", "Go to People tab, tap 'Add Person', enter name and email, optionally link to iOS Contacts, and save. Now you can track expenses with them."),
            ("Splitting Expenses", "When adding a transaction, select 'Split with People', choose who to split with, and pick split method: equal, custom amounts, or percentage-based."),
            ("Understanding Balances", "Green numbers mean they owe you, red means you owe them, gray means settled. View complete transaction history in person detail view."),
            ("Payment Requests", "Open person detail, tap 'Request Payment', enter amount and note, then share via Messages, Email, or any app. The message includes payment details.")
        ]

    case .analytics:
        return [
            ("Spending Trends", "View line charts showing your spending over time. Toggle between all expenses, subscriptions only, or transactions only."),
            ("Category Breakdown", "See pie charts showing spending by category. Tap any category to drill down and view all items in that category."),
            ("Savings Opportunities", "Swiff analyzes your subscriptions and suggests ways to save: unused subscriptions, annual discount opportunities, and cheaper alternatives."),
            ("Forecasting", "Based on your spending history, Swiff predicts future expenses. Accuracy improves with more data (6+ months for best results).")
        ]

    case .privacy:
        return [
            ("Your Data Stays Local", "All your data is stored securely on your iPhone or iPad using Apple's encrypted database. Nothing is sent to servers."),
            ("No Tracking", "Swiff doesn't use analytics, tracking pixels, or telemetry. We have no idea how you use the app - and we like it that way."),
            ("No Account Required", "No login, no password, no email required. Just download and start using Swiff immediately."),
            ("Encrypted Backups", "When creating backups, you can optionally protect them with password encryption for extra security.")
        ]

    case .backup:
        return [
            ("Creating Backups", "Settings > Data Management > 'Create Backup'. Choose location (Files app, iCloud Drive, email, etc.). Backup file (.json) contains all your data."),
            ("When to Backup", "We recommend monthly backups, before app updates, and before switching devices. Set a calendar reminder!"),
            ("Restoring Data", "Settings > Import/Restore > Select backup file. Choose conflict resolution: keep existing, replace with backup, or merge both."),
            ("Exporting to CSV", "Settings > Export Data > Choose CSV format. Open in Excel, Google Sheets, or Numbers for advanced analysis.")
        ]

    case .troubleshooting:
        return [
            ("App Crashing", "Try: 1) Update to latest version, 2) Restart device, 3) Free up storage (need 50MB+), 4) Delete and reinstall (backup first!)."),
            ("Data Not Saving", "Try: 1) Force close and reopen app, 2) Check available storage, 3) Restart device, 4) Restore from backup if corrupted."),
            ("Import Fails", "Check: 1) File format (must be .json for backups), 2) File isn't corrupted, 3) Swiff has access to Files app, 4) File size under 100MB."),
            ("Performance Issues", "If app is slow: 1) Archive old data (export and delete transactions over 1 year old), 2) Close background apps, 3) Restart device.")
        ]
    }
}

// MARK: - FAQ List View

struct FAQListView: View {
    var body: some View {
        List {
            Section("General") {
                FAQRow(question: "Is Swiff free?", answer: "Yes! Swiff is completely free with all features included. Future premium features may have optional pricing.")
                FAQRow(question: "Do I need an account?", answer: "No! Swiff works entirely on your device. No account, login, or password required.")
                FAQRow(question: "Where is my data stored?", answer: "All data is stored securely on your iPhone/iPad using Apple's encrypted database.")
            }

            Section("Features") {
                FAQRow(question: "How many subscriptions can I track?", answer: "Unlimited! Track as many subscriptions as you need.")
                FAQRow(question: "Can I track free trials?", answer: "Yes! Mark subscriptions as free trials and get expiration alerts.")
                FAQRow(question: "Can I share subscriptions?", answer: "Yes! Split subscription costs with friends and track who owes what.")
            }

            Section("Support") {
                FAQRow(question: "How do I get help?", answer: "Email support@swiffapp.com or visit www.swiffapp.com for help.")
                FAQRow(question: "How do I report a bug?", answer: "Email support@swiffapp.com with device model, iOS version, and steps to reproduce.")
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Text(answer)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.vertical, 8)
            },
            label: {
                Text(question)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
            }
        )
    }
}

// MARK: - Preview

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
