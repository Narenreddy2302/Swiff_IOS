//
//  ProfileView.swift
//  Swiff IOS
//
//  Main profile screen with header, statistics, quick actions, preferences, and account sections
//

import SwiftUI

struct ProfileView: View {
    // MARK: - State Objects

    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var toastManager = ToastManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Sheet State Variables

    @State private var showingEditProfile = false
    @State private var showingAnalytics = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteDataAlert = false

    // MARK: - Developer Options State

    @State private var versionTapCount = 0
    @State private var developerOptionsUnlocked = false

    // MARK: - Notification Badge State

    @State private var pendingNotificationsCount = 0
    @State private var securityAlertsCount = 0

    // MARK: - App Version String

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (Build \(build))"
    }

    // MARK: - Computed Properties

    private var subscriptionsCount: Int {
        dataManager.subscriptions.count
    }

    private var monthlySpending: Double {
        dataManager.subscriptions
            .filter { $0.billingCycle == .monthly || $0.billingCycle == .annually }
            .reduce(0.0) { total, subscription in
                if subscription.billingCycle == .monthly {
                    return total + subscription.price
                } else if subscription.billingCycle == .annually {
                    return total + (subscription.price / 12.0)
                }
                return total
            }
    }

    private var peopleCount: Int {
        dataManager.people.count
    }

    private var groupsCount: Int {
        dataManager.groups.count
    }

    // MARK: - Recent Activity Data

    private var recentSubscriptions: [Subscription] {
        let sortedSubscriptions = dataManager.subscriptions
            .sorted { $0.createdDate > $1.createdDate }
        return Array(sortedSubscriptions.prefix(3))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // TASK 7.1: HEADER WITH TITLE
                VStack(spacing: 0) {
                    HStack {
                        Text("Account")
                            .font(.spotifyDisplayLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .background(Color.wiseBackground)

                ScrollView {
                    VStack(spacing: 24) {
                        // TASK 7.2: PROFILE HEADER CARD
                        profileHeaderCard

                        // TASK 7.10: PROFILE STATISTICS GRID
                        profileStatisticsSection

                        // TASK 7.11: RECENT ACTIVITY SUMMARY SECTION
                        recentActivitySection

                        // TASK 7.3-7.7: MENU OPTIONS LIST
                        menuOptionsSection

                        // TASK 7.12: LOGOUT/DATA MANAGEMENT SECTION
                        dataManagementSection

                        // TASK 7.8: APP VERSION FOOTER WITH TAP COUNTER
                        versionFooter
                    }
                }
            }
            .background(Color.wiseBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditProfile) {
                UserProfileEditView()
            }
            .sheet(isPresented: $showingAnalytics) {
                AnalyticsView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to logout? You will need to sign in again.")
            }
            .alert("Delete All Data", isPresented: $showingDeleteDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    performDeleteAllData()
                }
            } message: {
                Text("This will permanently delete all your subscriptions, people, groups, and transactions. This action cannot be undone.")
            }
        }
        .onAppear {
            updateNotificationBadges()
        }
    }

    // MARK: - Profile Header Card (Task 7.2)

    private var profileHeaderCard: some View {
        HStack(spacing: 16) {
            // Profile Avatar
            Button(action: {
                HapticManager.shared.impact(.light)
                showingEditProfile = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.wiseBlue.opacity(0.15))
                        .frame(width: 64, height: 64)

                    if case .initials(let initials, _) = profileManager.profile.avatarType {
                        Text(initials)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.wiseBlue)
                    } else if case .emoji(let emoji) = profileManager.profile.avatarType {
                        Text(emoji)
                            .font(.system(size: 32))
                    } else if case .photo(let data) = profileManager.profile.avatarType, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    }
                }
            }
            .accessibilityLabel("Profile avatar")
            .accessibilityHint("Double tap to edit profile")

            // Profile Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profileManager.profile.name)
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(profileManager.profile.email)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // More button
            Button(action: {
                HapticManager.shared.impact(.light)
                showingEditProfile = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.wisePrimaryText)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("More options")
            .accessibilityHint("Double tap to edit profile")
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Profile Statistics Section (Task 7.10)

    private var profileStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("OVERVIEW")

            ProfileStatisticsGrid(
                subscriptionsCount: subscriptionsCount,
                monthlySpending: monthlySpending,
                peopleCount: peopleCount,
                groupsCount: groupsCount
            ) { statType in
                handleStatisticTap(statType)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Recent Activity Section (Task 7.11)

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("RECENT ACTIVITY")
                Spacer()
                if !recentSubscriptions.isEmpty {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        // Navigate to subscriptions list
                    }) {
                        Text("See All")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseBlue)
                    }
                    .padding(.trailing, 16)
                }
            }

            VStack(spacing: 0) {
                if recentSubscriptions.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundColor(.wiseSecondaryText.opacity(0.5))

                        Text("No recent activity")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Text("Your recent subscriptions will appear here")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(recentSubscriptions.enumerated()), id: \.element.id) { index, subscription in
                            RecentActivityRow(subscription: subscription)

                            if index < recentSubscriptions.count - 1 {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .background(Color.wiseCardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Menu Options Section (Tasks 7.3-7.7)

    private var menuOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SETTINGS")

            VStack(spacing: 0) {
                // TASK 7.4: General option linking to profile edit
                MenuOptionRow(
                    icon: "person.circle",
                    title: "General",
                    subtitle: "Profile, notifications & storage",
                    iconColor: .wisePrimaryText,
                    badgeCount: pendingNotificationsCount,
                    action: {
                        HapticManager.shared.impact(.medium)
                        showingEditProfile = true
                    }
                )

                Divider()
                    .padding(.leading, 72)

                // TASK 7.5: Security option linking to security settings
                MenuOptionRow(
                    icon: "lock.shield",
                    title: "Security",
                    subtitle: "Control how you access Pleo & your card",
                    iconColor: .wisePrimaryText,
                    badgeCount: securityAlertsCount,
                    action: {
                        HapticManager.shared.impact(.medium)
                        showingSettings = true
                    }
                )

                Divider()
                    .padding(.leading, 72)

                // TASK 7.6: Power ups option for integrations (links to Analytics)
                MenuOptionRow(
                    icon: "arrow.up.right.square",
                    title: "Power ups",
                    subtitle: "Pair Pleo with other software",
                    iconColor: .wisePrimaryText,
                    action: {
                        HapticManager.shared.impact(.medium)
                        showingAnalytics = true
                    }
                )

                Divider()
                    .padding(.leading, 72)

                // TASK 7.7: Chat/Help option for support access
                MenuOptionRow(
                    icon: "message.circle",
                    title: "Chat with Pleo",
                    subtitle: "Get help using Pleo",
                    iconColor: .wisePrimaryText,
                    action: {
                        HapticManager.shared.impact(.medium)
                        showingHelp = true
                    }
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Data Management Section (Task 7.12)

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ACCOUNT ACTIONS")

            VStack(spacing: 0) {
                // Export Data
                MenuOptionRow(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Download your data as JSON",
                    iconColor: .wiseBlue,
                    showChevron: false,
                    action: {
                        HapticManager.shared.impact(.medium)
                        exportUserData()
                    }
                )

                Divider()
                    .padding(.leading, 72)

                // Clear Cache
                MenuOptionRow(
                    icon: "trash",
                    title: "Clear Cache",
                    subtitle: "Free up storage space",
                    iconColor: .wiseOrange,
                    showChevron: false,
                    action: {
                        HapticManager.shared.impact(.medium)
                        clearCache()
                    }
                )

                Divider()
                    .padding(.leading, 72)

                // Delete All Data
                MenuOptionRow(
                    icon: "exclamationmark.triangle",
                    title: "Delete All Data",
                    subtitle: "Permanently remove all your data",
                    iconColor: .wiseError,
                    showChevron: false,
                    action: {
                        HapticManager.shared.impact(.heavy)
                        showingDeleteDataAlert = true
                    }
                )

                Divider()
                    .padding(.leading, 72)

                // Logout
                MenuOptionRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Logout",
                    subtitle: "Sign out of your account",
                    iconColor: .wiseError,
                    showChevron: false,
                    action: {
                        HapticManager.shared.impact(.medium)
                        showingLogoutAlert = true
                    }
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Version Footer (Task 7.8)

    private var versionFooter: some View {
        VStack(spacing: 8) {
            Button(action: {
                handleVersionTap()
            }) {
                Text(appVersion)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText.opacity(0.6))
            }
            .accessibilityLabel("App version \(appVersion)")
            .accessibilityHint("Tap multiple times to unlock developer options")

            if developerOptionsUnlocked {
                Text("Developer Options Unlocked")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSuccess)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 100)
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.spotifyLabelSmall)
            .textCase(.uppercase)
            .foregroundColor(.wiseSecondaryText)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Helper Functions

    // TASK 7.8: Handle version tap for developer options
    private func handleVersionTap() {
        HapticManager.shared.impact(.light)
        versionTapCount += 1

        if versionTapCount >= 10 && !developerOptionsUnlocked {
            developerOptionsUnlocked = true
            HapticManager.shared.notification(.success)
            toastManager.showSuccess("Developer options unlocked!")
            versionTapCount = 0
        }

        // Reset counter after 3 seconds of no taps
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if versionTapCount < 10 {
                versionTapCount = 0
            }
        }
    }

    // TASK 7.9: Update notification badges
    private func updateNotificationBadges() {
        // In a real app, these would come from notification manager
        // For now, using mock data
        pendingNotificationsCount = 0
        securityAlertsCount = 0
    }

    // Handle statistics tap
    private func handleStatisticTap(_ statType: StatType) {
        switch statType {
        case .subscriptions:
            // Navigate to subscriptions
            break
        case .spending:
            showingAnalytics = true
        case .people:
            // Navigate to people
            break
        case .groups:
            // Navigate to groups
            break
        }
    }

    // Data management actions
    private func exportUserData() {
        // Export data logic
        toastManager.showSuccess("Data exported successfully!")
    }

    private func clearCache() {
        // Clear cache logic
        toastManager.showSuccess("Cache cleared successfully!")
    }

    private func performDeleteAllData() {
        // Delete all data
        do {
            try dataManager.clearAllData()
            toastManager.showSuccess("All data deleted successfully!")
        } catch {
            toastManager.showError("Failed to delete data: \(error.localizedDescription)")
        }
    }

    private func performLogout() {
        // Logout logic
        toastManager.showInfo("Logged out successfully!")
    }
}

// MARK: - Menu Option Row (Task 7.3)

struct MenuOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var badgeCount: Int = 0
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container (40pt circle)
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                // TASK 7.9: Notification badge
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.wiseError)
                        .clipShape(Capsule())
                }

                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Row (Task 7.11)

struct RecentActivityRow: View {
    let subscription: Subscription

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: subscription.createdDate, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(subscription.category.color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: subscription.category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(subscription.category.color)
            }

            // Subscription info
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                Text("Added \(timeAgo)")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            // Amount
            Text(String(format: "$%.2f", subscription.price))
                .font(.spotifyBodyLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Profile View") {
    ProfileView()
}

#Preview("Profile View - Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
}

#Preview("Profile View - With Data") {
    let profileManager = UserProfileManager.shared

    // Configure with sample data
    profileManager.profile = UserProfile(
        name: "John Doe",
        email: "john.doe@example.com",
        phone: "+1 (555) 123-4567",
        avatarType: .initials("JD", colorIndex: 0),
        createdDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    )

    return ProfileView()
}
